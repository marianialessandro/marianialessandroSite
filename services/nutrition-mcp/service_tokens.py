"""Short-lived credentials cached independently for each exact scope profile."""
import asyncio
import json
import time


class ServiceUnavailable(Exception):
    pass


class ServiceTokens:
    def __init__(self, settings, http):
        self.settings, self.http = settings, http
        self.cache, self.locks, self.backoff = {}, {}, {}

    async def get(self, scopes):
        profile = tuple(sorted(scopes))
        if not profile or not set(profile) <= self.settings.scopes:
            raise ServiceUnavailable('Profilo del servizio non autorizzato.')
        async with self.locks.setdefault(profile, asyncio.Lock()):
            now = time.monotonic()
            cached = self.cache.get(profile)
            if cached and cached[1] > now + 30:
                return cached[0]
            if self.backoff.get(profile, 0) > now:
                raise ServiceUnavailable('Provider temporaneamente indisponibile; riprovare più tardi.')
            s = self.settings
            try:
                async with self.http.stream('POST', s.token_url, data={'grant_type': 'client_credentials', 'client_id': s.client_id, 'client_secret': s.client_secret, s.audience_parameter: s.api_audience, 'scope': ' '.join(profile)}) as response:
                    response.raise_for_status()
                    body = bytearray()
                    async for chunk in response.aiter_bytes():
                        body.extend(chunk)
                        if len(body) > 32768:
                            raise ValueError()
                data = json.loads(body)
                lifetime = data['expires_in']
                if data.get('token_type', '').lower() != 'bearer' or not isinstance(lifetime, int) or not 60 <= lifetime <= 300:
                    raise ValueError()
                if set(data.get('scope', '').split()) != set(profile):
                    raise ValueError()
                token = data['access_token']
                if not isinstance(token, str) or not token or len(token) > 16384:
                    raise ValueError()
                self.cache[profile] = (token, now + lifetime)
                return token
            except Exception:
                self.backoff[profile] = now + 30
                raise ServiceUnavailable('Rinnovo credenziale API fallito; intervento sul servizio necessario, non sul login ChatGPT.') from None

    def invalidate(self, scopes):
        self.cache.pop(tuple(sorted(scopes)), None)
