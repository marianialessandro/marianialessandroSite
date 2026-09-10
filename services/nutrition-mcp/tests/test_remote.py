import asyncio
from dataclasses import replace
import json
from pathlib import Path
import time

from cryptography.hazmat.primitives.asymmetric import rsa
import httpx
import jwt
import mcp.types as types
from mcp import ClientSession
from mcp.client.streamable_http import streamable_http_client
import pytest

from api_client import ApiClient, ToolError, safe_numbers
from auth import AccessDenied, Identity, TokenVerifier, identity
from configuration import Settings
from http_app import Tools, create_app
from service_tokens import ServiceTokens, ServiceUnavailable
from tool_catalog import make_tool

KEY = rsa.generate_private_key(public_exponent=65537, key_size=2048)
JWK = dict(json.loads(jwt.algorithms.RSAAlgorithm.to_jwk(KEY.public_key())), kid='one', alg='RS256', use='sig')
SETTINGS = Settings(resource='https://mcp.example/mcp', issuer='https://id.example/', jwks_url='https://id.example/jwks', subject='personal-user', api_url='https://api.example/nutrition', api_audience='https://api.example/nutrition', token_url='https://id.example/token', client_id='machine', client_secret='synthetic-secret', disabled_file='/tmp/nutrition-test-unlikely.disabled')


def token(**changes):
    now = int(time.time())
    claims = dict(iss=SETTINGS.issuer, sub=SETTINGS.subject, aud=SETTINGS.resource, iat=now, exp=now + 600, scope='nutrition:read', token_use='access')
    claims.update(changes)
    return jwt.encode(claims, KEY, algorithm='RS256', headers={'kid': 'one'})


@pytest.mark.asyncio
async def test_jwt_validation_rotation_and_kill_switch(tmp_path):
    current = [JWK]
    async def respond(request):
        return httpx.Response(200, json={'keys': current})
    settings = replace(SETTINGS, disabled_file=str(tmp_path / 'disabled'))
    async with httpx.AsyncClient(transport=httpx.MockTransport(respond)) as http:
        verifier = TokenVerifier(settings, http)
        assert (await verifier.verify(token())).subject == SETTINGS.subject
        for changes in ({'sub': 'another-user'}, {'iss': 'https://wrong.example/'}, {'aud': SETTINGS.api_audience}, {'exp': int(time.time()) - 30}, {'iat': int(time.time()) + 90}, {'scope': 'nutrition:write'}, {'token_use': 'id'}, {'exp': int(time.time()) + 3600}):
            with pytest.raises(AccessDenied):
                await verifier.verify(token(**changes))
        wrong = rsa.generate_private_key(public_exponent=65537, key_size=2048)
        forged = jwt.encode(jwt.decode(token(), options={'verify_signature': False}), wrong, algorithm='RS256', headers={'kid': 'one'})
        with pytest.raises(AccessDenied):
            await verifier.verify(forged)
        new_jwk = dict(json.loads(jwt.algorithms.RSAAlgorithm.to_jwk(wrong.public_key())), kid='two', alg='RS256')
        current[:] = [new_jwk]
        verifier.next_refresh = 0
        rotated = jwt.encode(jwt.decode(token(), options={'verify_signature': False}), wrong, algorithm='RS256', headers={'kid': 'two'})
        assert await verifier.verify(rotated)
        Path(settings.disabled_file).touch()
        with pytest.raises(AccessDenied):
            await verifier.verify(rotated)


@pytest.mark.asyncio
async def test_token_refresh_coalesces_concurrency_and_separates_profiles():
    calls = []
    async def respond(request):
        from urllib.parse import parse_qs
        form = parse_qs(request.content.decode())
        calls.append(form)
        await asyncio.sleep(0.01)
        return httpx.Response(200, json={'token_type': 'Bearer', 'access_token': 'machine-' + form['scope'][0], 'scope': form['scope'][0], 'expires_in': 300})
    async with httpx.AsyncClient(transport=httpx.MockTransport(respond)) as http:
        tokens = ServiceTokens(replace(SETTINGS, scopes=frozenset({'nutrition:read', 'nutrition:write'})), http)
        await asyncio.gather(*(tokens.get({'nutrition:read'}) for _ in range(20)))
        assert len(calls) == 1
        assert await tokens.get({'nutrition:write'}) == 'machine-nutrition:write'
        assert len(calls) == 2
        tokens.cache[('nutrition:read',)] = ('old', time.monotonic() + 10)
        assert await tokens.get({'nutrition:read'}) == 'machine-nutrition:read'
        assert len(calls) == 3
        assert 'refresh_token' not in calls[0]
        assert calls[0]['resource'] == [SETTINGS.api_audience]


@pytest.mark.asyncio
async def test_provider_failure_backoff_and_excessive_scope():
    calls = []
    async def respond(request):
        calls.append(1)
        return httpx.Response(200, json={'token_type': 'Bearer', 'access_token': 'token', 'scope': 'nutrition:read nutrition:write', 'expires_in': 300})
    async with httpx.AsyncClient(transport=httpx.MockTransport(respond)) as http:
        tokens = ServiceTokens(SETTINGS, http)
        for _ in range(3):
            with pytest.raises(ServiceUnavailable):
                await tokens.get({'nutrition:read'})
        assert len(calls) == 1


@pytest.mark.asyncio
async def test_http_protocol_and_authentication():
    async with httpx.AsyncClient(transport=httpx.MockTransport(lambda request: httpx.Response(200, json={'keys': [JWK]}))) as provider:
        app = create_app(SETTINGS, provider)
        async with app.transport_app.router.lifespan_context(app.transport_app):
            transport = httpx.ASGITransport(app=app)
            async with httpx.AsyncClient(transport=transport, base_url='https://mcp.example') as http:
                metadata = await http.get('/.well-known/oauth-protected-resource/mcp')
                assert metadata.json()['resource'] == SETTINGS.resource
                denied = await http.post('/mcp')
                assert denied.status_code == 401 and 'resource_metadata' in denied.headers['WWW-Authenticate']
                for path in ['/mcp']:
                    for method in ['GET', 'POST', 'DELETE']:
                        assert (await http.request(method, path)).status_code == 401
                assert (await http.post('/mcp', headers={'Authorization': 'Bearer ' + token(aud=SETTINGS.api_audience)})).status_code == 401
                assert (await http.get('/health', headers={'Host': 'evil.example'})).status_code == 421
                assert (await http.get('/health', headers={'Origin': 'https://evil.example'})).status_code == 403
                assert (await http.post('/mcp', content=b'x' * (SETTINGS.max_input + 1), headers={'Authorization': 'Bearer ' + token()})).status_code == 413
            async with httpx.AsyncClient(transport=transport, headers={'Authorization': 'Bearer ' + token()}) as client:
                async with streamable_http_client(SETTINGS.resource, http_client=client) as (read, write, _):
                    async with ClientSession(read, write) as session:
                        assert (await session.initialize()).serverInfo.name == 'nutrition-api'
                        listed = await session.list_tools()
                        assert [tool.name for tool in listed.tools] == ['nutrition_status']
                        result = await session.call_tool('nutrition_status', {})
                        assert result.structuredContent['status'] == 'ok'
                        assert (await session.call_tool('nutrition_17_12', {'confirm': True})).isError



def catalog_fixture():
    source = Path(__file__).resolve().parents[1] / 'contracts/catalog.json'
    return {entry['id']: entry for entry in json.loads(source.read_text())}



def test_all_182_contracts_and_mutation_defaults():
    operations = catalog_fixture()
    assert len(operations) == 182
    counts = {}
    for entry in operations.values():
        tool = make_tool(entry)
        counts[entry['ability']] = counts.get(entry['ability'], 0) + 1
        assert tool.name == 'nutrition_' + entry['id'].replace('.', '_')
        assert tool.annotations.readOnlyHint == (entry['ability'] == 'nutrition:read')
        assert tool.annotations.destructiveHint == (entry['ability'] != 'nutrition:read')
        if entry['ability'] != 'nutrition:read':
            assert all('default' not in spec for spec in tool.inputSchema['properties'].values())
            assert set(tool.inputSchema['required']) == set(tool.inputSchema['properties'])
        if entry['ability'] in {'nutrition:delete', 'nutrition:maintenance'}:
            assert tool.inputSchema['properties']['confirm']['const'] is True
    assert counts == {'nutrition:write': 38, 'nutrition:read': 122, 'nutrition:delete': 14, 'nutrition:maintenance': 8}


@pytest.mark.asyncio
async def test_authorization_is_rechecked_and_contexts_do_not_mix():
    catalog = catalog_fixture()
    executed = []
    class FakeApi:
        async def request(self, path, scopes, payload=None, mutation=False):
            await asyncio.sleep(0)
            if payload is None:
                return {'data': list(catalog.values())}
            executed.append((path, scopes, identity.get().subject))
            return {'results': []}
    settings = replace(SETTINGS, diagnostic_only=False, scopes=frozenset({'nutrition:read', 'nutrition:write'}), operations=frozenset({'6.1', '5.1'}))
    handler = Tools(settings, FakeApi())
    async def request(subject, scopes):
        reset = identity.set(Identity(subject, frozenset(scopes), 'audit'))
        try:
            tools = await handler.list()
            result = await handler.call('nutrition_5_1', {})
            assert result.isError
            return [tool.name for tool in tools]
        finally:
            identity.reset(reset)
    read, write = await asyncio.gather(request('reader', {'nutrition:read'}), request('writer', {'nutrition:write'}))
    assert read == ['nutrition_status', 'nutrition_6_1']
    assert write == ['nutrition_status', 'nutrition_5_1']
    assert not executed


@pytest.mark.asyncio
async def test_ambiguous_mutation_never_retried_and_secrets_not_forwarded():
    calls = []
    class Tokens:
        async def get(self, scopes):
            return 'separate-machine-token'
    async def respond(request):
        calls.append(request)
        raise httpx.ReadTimeout('sensitive internal detail')
    reset = identity.set(Identity('user', frozenset({'nutrition:write'}), 'pseudonym'))
    try:
        async with httpx.AsyncClient(transport=httpx.MockTransport(respond)) as http:
            api = ApiClient(SETTINGS, http, Tokens())
            with pytest.raises(ToolError, match='Esito non determinato'):
                await api.request('/queries/5.1/execute', {'nutrition:write'}, {'parameters': {}}, mutation=True)
        assert len(calls) == 1
        assert calls[0].headers['Authorization'] == 'Bearer separate-machine-token'
    finally:
        identity.reset(reset)


def test_precision():
    from decimal import Decimal
    assert safe_numbers({'id': 9223372036854775807, 'amount': Decimal('123.4500'), 'results': [], 'truncated': False}) == {'id': '9223372036854775807', 'amount': '123.4500', 'results': [], 'truncated': False}


@pytest.mark.parametrize('change', [{'resource': 'http://mcp.example/mcp'}, {'subject': ''}, {'scopes': frozenset({'*'})}, {'api_audience': SETTINGS.resource}, {'concurrency': 0}, {'jwks_url': 'https://evil.example/?url=other'}])
def test_invalid_configuration_fails_closed(change):
    with pytest.raises(ValueError):
        replace(SETTINGS, **change)


@pytest.mark.asyncio
async def test_all_operations_execute_only_with_allowed_profile_and_explicit_values():
    from configuration import SCOPES
    catalog = catalog_fixture()
    executed = []
    class FakeApi:
        async def request(self, path, scopes, payload=None, mutation=False):
            if payload is None:
                return {'data': list(catalog.values())}
            executed.append((path, scopes, payload, mutation))
            return {'operation': path.split('/')[-2], 'results': [], 'outputs': {}, 'truncated': False}
    handler = Tools(replace(SETTINGS, scopes=SCOPES, operations=frozenset(catalog), diagnostic_only=False), FakeApi())
    reset = identity.set(Identity('personal-user', SCOPES, 'audit'))
    try:
        assert len(await handler.list()) == 183
        for entry in catalog.values():
            arguments = {}
            for name, spec in entry['inputSchema']['properties'].items():
                if spec.get('format') == 'date':
                    value = '2026-09-09'
                elif 'default' in spec:
                    value = spec['default']
                elif spec['type'] in ['integer', 'number']:
                    value = spec.get('minimum', 1)
                else:
                    value = 'test'
                arguments[name] = value
            if entry['ability'] in {'nutrition:delete', 'nutrition:maintenance'}:
                denied = await handler.call('nutrition_' + entry['id'].replace('.', '_'), arguments)
                assert denied.isError
                arguments['confirm'] = True
            result = await handler.call('nutrition_' + entry['id'].replace('.', '_'), arguments)
            assert isinstance(result, dict), entry['id']
            assert result['operation'] == entry['id']
        assert len(executed) == 182
        assert all(scopes == {catalog[path.split('/')[-2]]['ability']} for path, scopes, _, _ in executed)
    finally:
        identity.reset(reset)


@pytest.mark.asyncio
@pytest.mark.parametrize('status', [401, 403, 404, 422, 429, 503, 302])
async def test_downstream_errors_are_safe_and_redirects_are_not_followed(status):
    calls = []
    class Tokens:
        async def get(self, scopes):
            return 'machine-token'
        def invalidate(self, scopes):
            pass
    async def respond(request):
        calls.append(request)
        return httpx.Response(status, json={'secret': 'sensitive SQL'}, headers={'Retry-After': '42', 'Location': 'https://evil.example/'})
    reset = identity.set(Identity('user', frozenset({'nutrition:read'}), 'audit'))
    try:
        async with httpx.AsyncClient(transport=httpx.MockTransport(respond), follow_redirects=False) as http:
            with pytest.raises(ToolError) as error:
                await ApiClient(SETTINGS, http, Tokens()).request('/queries/6.1/execute', {'nutrition:read'}, {'parameters': {}})
            assert 'sensitive' not in str(error.value)
            if status in {429, 503}:
                assert '42' in str(error.value)
        assert len(calls) == 1
    finally:
        identity.reset(reset)


@pytest.mark.asyncio
async def test_large_response_is_rejected_without_partial_json():
    class Tokens:
        async def get(self, scopes):
            return 'machine-token'
    reset = identity.set(Identity('user', frozenset({'nutrition:read'}), 'audit'))
    try:
        async with httpx.AsyncClient(transport=httpx.MockTransport(lambda request: httpx.Response(200, json={'data': 'x' * 5000}))) as http:
            with pytest.raises(ToolError, match='pagine più piccole'):
                await ApiClient(replace(SETTINGS, max_output=4096), http, Tokens()).request('/queries/6.1/execute', {'nutrition:read'}, {'parameters': {}})
    finally:
        identity.reset(reset)


@pytest.mark.asyncio
async def test_busy_limit_and_jwks_outage_fail_closed():
    async with httpx.AsyncClient(transport=httpx.MockTransport(lambda request: httpx.Response(503))) as provider:
        app = create_app(SETTINGS, provider)
        async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url='https://mcp.example') as http:
            assert (await http.post('/mcp', headers={'Authorization': 'Bearer ' + token()})).status_code == 401
            app.active = SETTINGS.concurrency
            response = await http.post('/mcp', headers={'Authorization': 'Bearer ' + token()})
            assert response.status_code == 503
            assert response.headers['Retry-After'] == '1'
            assert (await http.get('/health')).status_code == 200


@pytest.mark.asyncio
async def test_concurrent_http_clients_keep_scope_profiles_separate():
    from urllib.parse import parse_qs
    catalog = list(catalog_fixture().values())
    async def respond(request):
        await asyncio.sleep(0)
        if request.url.path == '/jwks':
            return httpx.Response(200, json={'keys': [JWK]})
        if request.url.path == '/token':
            form = parse_qs(request.content.decode())
            scope = form['scope'][0]
            return httpx.Response(200, json={'token_type': 'Bearer', 'scope': scope, 'expires_in': 300, 'access_token': 'machine:' + scope})
        assert request.headers['Authorization'] in {'Bearer machine:nutrition:read', 'Bearer machine:nutrition:write'}
        return httpx.Response(200, json={'data': catalog})
    settings = replace(SETTINGS, diagnostic_only=False, scopes=frozenset({'nutrition:read', 'nutrition:write'}), operations=frozenset({'6.1', '5.1'}))
    async with httpx.AsyncClient(transport=httpx.MockTransport(respond)) as provider:
        app = create_app(settings, provider)
        async with app.transport_app.router.lifespan_context(app.transport_app):
            async def connect(scope):
                async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), headers={'Authorization': 'Bearer ' + token(scope=scope)}) as client:
                    async with streamable_http_client(settings.resource, http_client=client) as (read, write, _):
                        async with ClientSession(read, write) as session:
                            await session.initialize()
                            listed = await session.list_tools()
                            assert (await session.call_tool('nutrition_17_12', {'confirm': True})).isError
                            return [tool.name for tool in listed.tools]
            read, write = await asyncio.gather(connect('nutrition:read'), connect('nutrition:write'))
            assert read == ['nutrition_status', 'nutrition_6_1']
            assert write == ['nutrition_status', 'nutrition_5_1']
