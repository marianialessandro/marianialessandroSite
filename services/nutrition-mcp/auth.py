"""Offline access-token validation using only an explicitly trusted JWKS endpoint."""
import asyncio
from contextvars import ContextVar
from dataclasses import dataclass
import hashlib
import hmac
from pathlib import Path
import time

import jwt

identity = ContextVar('nutrition_identity')
request_id = ContextVar('nutrition_request_id', default='')


@dataclass(frozen=True)
class Identity:
    subject: str
    scopes: frozenset
    audit_id: str


class AccessDenied(Exception):
    pass


class TokenVerifier:
    def __init__(self, settings, http):
        self.settings = settings
        self.http = http
        self.keys = {}
        self.expires = 0
        self.next_refresh = 0
        self.lock = asyncio.Lock()

    async def key(self, kid):
        async with self.lock:
            now = time.monotonic()
            if now >= self.expires or kid not in self.keys:
                if now < self.next_refresh:
                    raise AccessDenied()
                self.next_refresh = now + 10
                try:
                    async with self.http.stream('GET', self.settings.jwks_url) as response:
                        response.raise_for_status()
                        body = bytearray()
                        async for chunk in response.aiter_bytes():
                            body.extend(chunk)
                            if len(body) > 65536:
                                raise AccessDenied()
                    import json
                    entries = json.loads(body)['keys']
                    if not isinstance(entries, list) or not 1 <= len(entries) <= 20:
                        raise AccessDenied()
                    keys = {}
                    for entry in entries:
                        if entry.get('kty') == 'RSA' and entry.get('alg', 'RS256') == 'RS256' and entry.get('use', 'sig') == 'sig':
                            key = jwt.PyJWK.from_dict(entry, algorithm='RS256').key
                            if key.key_size < 2048 or entry['kid'] in keys:
                                raise AccessDenied()
                            keys[entry['kid']] = key
                    self.keys, self.expires = keys, now + 300
                except Exception:
                    raise AccessDenied() from None
            if kid not in self.keys:
                raise AccessDenied()
            return self.keys[kid]

    async def verify(self, token):
        s = self.settings
        if Path(s.disabled_file).exists() or len(token) > 16384:
            raise AccessDenied()
        try:
            header = jwt.get_unverified_header(token)
            if header.get('alg') != 'RS256' or header.get('typ') not in {'JWT', 'at+jwt'} or header.get('crit'):
                raise AccessDenied()
            key = await self.key(header['kid'])
            claims = jwt.decode(token, key, algorithms=['RS256'], audience=s.resource, issuer=s.issuer, leeway=15, options={'require': ['exp', 'iat', 'iss', 'aud', 'sub', 'scope']})
            if claims['sub'] != s.subject or claims.get(s.access_claim) != s.access_value:
                raise AccessDenied()
            if not isinstance(claims['scope'], str) or not isinstance(claims['exp'], int) or not isinstance(claims['iat'], int) or claims['exp'] - claims['iat'] > 600:
                raise AccessDenied()
            scopes = frozenset(claims['scope'].split()) & s.scopes
            if not scopes:
                raise AccessDenied()
            audit = hmac.new(s.client_secret.encode(), (s.issuer + '\0' + claims['sub']).encode(), hashlib.sha256).hexdigest()[:32]
            return Identity(claims['sub'], scopes, audit)
        except Exception:
            raise AccessDenied() from None
