"""Stateless Streamable HTTP with request-local authorization and bounded I/O."""
import asyncio
from contextlib import asynccontextmanager
import json
import logging
from pathlib import Path
import re
import time
from urllib.parse import urlsplit
import uuid

import httpx
from jsonschema import Draft202012Validator, FormatChecker
import mcp.types as types
from mcp.server.lowlevel import Server
from mcp.server.streamable_http_manager import StreamableHTTPSessionManager
from mcp.server.transport_security import TransportSecuritySettings
from starlette.applications import Starlette
from starlette.responses import JSONResponse
from starlette.routing import Route

from api_client import ApiClient, ToolError
from auth import AccessDenied, TokenVerifier, identity, request_id
from service_tokens import ServiceTokens, ServiceUnavailable
from tool_catalog import make_tool

logger = logging.getLogger('nutrition.audit')


def error_result(message):
    return types.CallToolResult(isError=True, content=[types.TextContent(type='text', text=message)])


class Tools:
    def __init__(self, settings, api):
        self.settings, self.api = settings, api
        self.cache, self.locks = {}, {}

    async def catalog(self):
        user = identity.get()
        if self.settings.diagnostic_only:
            return {}
        profile = tuple(sorted(user.scopes))
        async with self.locks.setdefault(profile, asyncio.Lock()):
            cached = self.cache.get(profile)
            if cached and cached[1] > time.monotonic():
                data = cached[0]
            else:
                data = await self.api.request('/queries', user.scopes)
                self.cache[profile] = (data, time.monotonic() + 30)
        return {entry['id']: entry for entry in data['data'] if entry['ability'] in user.scopes and (entry['id'] in self.settings.operations or (not self.settings.operations and entry['ability'] == 'nutrition:read'))}

    async def list(self):
        diagnostic = types.Tool(name='nutrition_status', description='Verifica autenticazione e disponibilità del processo, senza leggere il database.', inputSchema={'type': 'object', 'properties': {}, 'additionalProperties': False}, annotations=types.ToolAnnotations(readOnlyHint=True, destructiveHint=False, idempotentHint=True, openWorldHint=False), securitySchemes=[{'type': 'oauth2', 'scopes': sorted(identity.get().scopes)}], _meta={'securitySchemes': [{'type': 'oauth2', 'scopes': sorted(identity.get().scopes)}]})
        return [diagnostic] + [make_tool(entry) for entry in (await self.catalog()).values()]

    async def call(self, name, arguments):
        start = time.monotonic()
        operation_id, outcome = 'unknown', 'error'
        try:
            if Path(self.settings.disabled_file).exists():
                return error_result('Accesso disabilitato.')
            if name == 'nutrition_status':
                if arguments:
                    return error_result('Il tool diagnostico non accetta parametri.')
                outcome = 'ok'
                return {'status': 'ok', 'diagnostic_only': self.settings.diagnostic_only}
            if not re.fullmatch(r'nutrition_\d+_\d+', name):
                return error_result('Tool non autorizzato.')
            operation_id = name.removeprefix('nutrition_').replace('_', '.')
            entry = (await self.catalog()).get(operation_id)
            if entry is None:
                return error_result('Tool non autorizzato.')
            tool = make_tool(entry)
            if not Draft202012Validator(tool.inputSchema, format_checker=FormatChecker()).is_valid(arguments):
                return error_result('Parametri mancanti o non validi; fornire tutti i valori richiesti esplicitamente.')
            parameters = dict(arguments)
            confirm = parameters.pop('confirm', None)
            payload = {'parameters': parameters}
            if confirm is not None:
                payload['confirm'] = confirm
            result = await self.api.request('/queries/' + operation_id + '/execute', {entry['ability']}, payload, mutation=entry['ability'] != 'nutrition:read')
            outcome = 'ok'
            return result
        except (ToolError, ServiceUnavailable) as exc:
            return error_result(str(exc))
        except Exception:
            return error_result('Servizio temporaneamente indisponibile.')
        finally:
            logger.info(json.dumps({'request_id': request_id.get(), 'actor': identity.get().audit_id, 'service': self.settings.client_id, 'operation': operation_id, 'outcome': outcome, 'duration_ms': round((time.monotonic() - start) * 1000)}))


class Boundary:
    def __init__(self, app, settings, verifier):
        self.app, self.settings, self.verifier = app, settings, verifier
        self.active = 0

    async def __call__(self, scope, receive, send):
        if scope['type'] != 'http':
            return await self.app(scope, receive, send)
        s = self.settings
        headers = dict(scope['headers'])
        host = urlsplit(s.resource).netloc
        if headers.get(b'host', b'').decode('latin1') != host:
            return await JSONResponse({'error': 'invalid_host'}, 421)(scope, receive, send)
        origin = headers.get(b'origin')
        if origin is not None and origin.decode('latin1') not in s.origins:
            return await JSONResponse({'error': 'invalid_origin'}, 403)(scope, receive, send)
        if scope['path'] in {'/.well-known/oauth-protected-resource', '/.well-known/oauth-protected-resource/mcp', '/health', '/ready'}:
            return await self.app(scope, receive, send)
        if scope['path'] != '/mcp':
            return await JSONResponse({'error': 'not_found'}, 404)(scope, receive, send)
        if self.active >= s.concurrency:
            return await JSONResponse({'error': 'busy'}, 503, headers={'Retry-After': '1'})(scope, receive, send)
        self.active += 1
        identity_token = rid_token = None
        try:
            try:
                authorization = headers.get(b'authorization', b'').decode('ascii')
                scheme, token = authorization.split(' ', 1)
                if scheme.lower() != 'bearer':
                    raise AccessDenied()
                user = await self.verifier.verify(token)
            except (AccessDenied, ValueError, UnicodeError):
                challenge = 'Bearer resource_metadata="' + s.resource.rsplit('/', 1)[0] + '/.well-known/oauth-protected-resource/mcp"'
                return await JSONResponse({'error': 'invalid_token'}, 401, headers={'WWW-Authenticate': challenge, 'Cache-Control': 'no-store'})(scope, receive, send)
            identity_token = identity.set(user)
            rid_token = request_id.set(str(uuid.uuid4()))
            body = bytearray()
            try:
                async with asyncio.timeout(15):
                    while True:
                        event = await receive()
                        if event['type'] == 'http.disconnect':
                            return
                        body.extend(event.get('body', b''))
                        if len(body) > s.max_input:
                            return await JSONResponse({'error': 'request_too_large'}, 413)(scope, receive, send)
                        if not event.get('more_body', False):
                            break
            except TimeoutError:
                return await JSONResponse({'error': 'request_timeout'}, 408)(scope, receive, send)
            delivered = False

            async def bounded_receive():
                nonlocal delivered
                if not delivered:
                    delivered = True
                    return {'type': 'http.request', 'body': bytes(body), 'more_body': False}
                return await receive()

            events, size = [], 0

            async def buffered_send(event):
                nonlocal size
                size += len(event.get('body', b''))
                if size > s.max_output:
                    raise ToolError('response_too_large')
                events.append(event)

            try:
                await self.app(scope, bounded_receive, buffered_send)
            except ToolError:
                return await JSONResponse({'error': 'response_too_large', 'message': 'Ridurre filtri o pagine. Se era una scrittura, verificarne lo stato prima di ripetere.'}, 413)(scope, receive, send)
            except Exception:
                return await JSONResponse({'error': 'service_unavailable'}, 503)(scope, receive, send)
            for event in events:
                if event['type'] == 'http.response.start':
                    event['headers'] = list(event.get('headers', [])) + [(b'cache-control', b'no-store'), (b'x-request-id', request_id.get().encode())]
                await send(event)
        finally:
            if identity_token is not None:
                identity.reset(identity_token)
            if rid_token is not None:
                request_id.reset(rid_token)
            self.active -= 1


def create_app(settings, http=None):
    owned = http is None
    http = http or httpx.AsyncClient(timeout=20, follow_redirects=False, limits=httpx.Limits(max_connections=settings.concurrency * 2))
    verifier = TokenVerifier(settings, http)
    tokens = ServiceTokens(settings, http)
    handlers = Tools(settings, ApiClient(settings, http, tokens))
    server = Server('nutrition-api')
    server.list_tools()(handlers.list)
    server.call_tool(validate_input=False)(handlers.call)
    manager = StreamableHTTPSessionManager(server, json_response=True, stateless=True, security_settings=TransportSecuritySettings(enable_dns_rebinding_protection=True, allowed_hosts=[urlsplit(settings.resource).netloc], allowed_origins=list(settings.origins)))

    @asynccontextmanager
    async def lifespan(app):
        try:
            async with manager.run():
                yield
        finally:
            if owned:
                await http.aclose()

    async def discovery(request):
        return JSONResponse({'resource': settings.resource, 'authorization_servers': [settings.issuer], 'scopes_supported': sorted(settings.scopes), 'bearer_methods_supported': ['header']})

    async def health(request):
        disabled = Path(settings.disabled_file).exists()
        return JSONResponse({'status': 'unavailable' if disabled else 'ok'}, 503 if disabled else 200)

    class Transport:
        async def __call__(self, scope, receive, send):
            await manager.handle_request(scope, receive, send)

    app = Starlette(routes=[Route('/.well-known/oauth-protected-resource', discovery), Route('/.well-known/oauth-protected-resource/mcp', discovery), Route('/health', health), Route('/ready', health), Route('/mcp', Transport(), methods=['GET', 'POST', 'DELETE'])], lifespan=lifespan)
    wrapped = Boundary(app, settings, verifier)
    wrapped.transport_app, wrapped.handlers, wrapped.tokens = app, handlers, tokens
    return wrapped
