"""Fixed-origin REST client with bounded responses and no mutation retries."""
import json
from decimal import Decimal

import httpx

from auth import identity, request_id


class ToolError(Exception):
    pass


def safe_numbers(value):
    if isinstance(value, Decimal):
        return str(value)
    if isinstance(value, int) and not isinstance(value, bool) and abs(value) > 9007199254740991:
        return str(value)
    if isinstance(value, list):
        return [safe_numbers(item) for item in value]
    if isinstance(value, dict):
        return {key: safe_numbers(item) for key, item in value.items()}
    return value


class ApiClient:
    def __init__(self, settings, http, tokens):
        self.settings, self.http, self.tokens = settings, http, tokens

    async def request(self, path, scopes, payload=None, mutation=False):
        token = await self.tokens.get(scopes)
        user = identity.get()
        headers = {'Authorization': 'Bearer ' + token, 'Accept': 'application/json', 'X-Request-ID': request_id.get(), 'X-Nutrition-Actor': user.audit_id}
        try:
            async with self.http.stream('GET' if payload is None else 'POST', self.settings.api_url.rstrip('/') + path, headers=headers, json=payload) as response:
                if response.status_code >= 300:
                    if response.status_code == 401:
                        self.tokens.invalidate(scopes)
                    messages = {401: 'Credenziale del servizio API rifiutata; verificare il servizio.', 403: 'Permessi API insufficienti.', 404: 'Operazione non disponibile.', 422: 'Parametri rifiutati dalla API.', 429: 'Limite API raggiunto.', 503: 'API temporaneamente indisponibile.'}
                    message = messages.get(response.status_code, 'Risposta API non valida.')
                    retry = response.headers.get('Retry-After', '')
                    if response.status_code in {429, 503} and retry.isdigit():
                        message += f' Riprovare dopo {min(int(retry), 3600)} secondi.'
                    if mutation and response.status_code >= 500:
                        message += ' Esito non determinato: verificare lo stato con una lettura prima di ripetere.'
                    raise ToolError(message)
                body = bytearray()
                async for chunk in response.aiter_bytes():
                    body.extend(chunk)
                    if len(body) > (self.settings.max_output if path == '/queries' else self.settings.max_output // 3):
                        raise ToolError('Risposta troppo grande: usare filtri o pagine più piccole.' + (' La scrittura potrebbe essere completata; verificarla con una lettura.' if mutation else ''))
            return safe_numbers(json.loads(body, parse_float=Decimal))
        except httpx.HTTPError:
            raise ToolError('Esito non determinato: verificare lo stato con una lettura prima di ripetere.' if mutation else 'API non raggiungibile; riprovare più tardi.') from None
        except (ValueError, TypeError):
            raise ToolError('Risposta API non valida.' + (' Verificare lo stato con una lettura prima di ripetere.' if mutation else '')) from None


async def legacy_request(path, payload=None):
    url, token = legacy_configuration()
    async with httpx.AsyncClient(timeout=30, follow_redirects=False) as client:
        response = await client.request('GET' if payload is None else 'POST', url + path, headers={'Authorization': 'Bearer ' + token, 'Accept': 'application/json'}, json=payload)
    if response.status_code >= 300:
        raise ValueError(f'Nutrition API returned HTTP {response.status_code}; verify token, permissions and parameters.')
    return response.json()


def legacy_configuration():
    import os
    from configuration import secure_url
    url = os.environ['NUTRITION_API_URL'].rstrip('/')
    secure_url(url, loopback=True)
    return url, os.environ['NUTRITION_API_TOKEN']
