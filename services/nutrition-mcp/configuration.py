"""Validated server configuration; secrets are never part of tool arguments."""
from dataclasses import dataclass, field
import os
from urllib.parse import urlsplit

SCOPES = frozenset({'nutrition:read', 'nutrition:write', 'nutrition:delete', 'nutrition:maintenance'})


def secure_url(value, loopback=False):
    parsed = urlsplit(value)
    if not parsed.hostname or parsed.username or parsed.password or parsed.query or parsed.fragment:
        raise ValueError('Invalid configured URL.')
    if parsed.scheme != 'https' and not (loopback and parsed.scheme == 'http' and parsed.hostname in {'localhost', '127.0.0.1', '::1'}):
        raise ValueError('Configured URL requires HTTPS.')
    return value


@dataclass(frozen=True)
class Settings:
    resource: str
    issuer: str
    jwks_url: str
    subject: str
    api_url: str
    api_audience: str
    token_url: str
    client_id: str
    client_secret: str = field(repr=False)
    scopes: frozenset = frozenset({'nutrition:read'})
    operations: frozenset = frozenset()
    origins: frozenset = frozenset()
    disabled_file: str = '/tmp/nutrition-mcp.disabled'
    diagnostic_only: bool = True
    max_input: int = 262144
    max_output: int = 1048576
    concurrency: int = 8
    audience_parameter: str = 'resource'
    access_claim: str = 'token_use'
    access_value: str = 'access'

    def __post_init__(self):
        for value in (self.resource, self.issuer, self.jwks_url, self.api_audience, self.token_url):
            secure_url(value)
        secure_url(self.api_url, loopback=True)
        if urlsplit(self.resource).path != '/mcp' or self.resource == self.api_audience:
            raise ValueError('Separate audiences and /mcp resource required.')
        if not all((self.subject, self.client_id, self.client_secret, self.access_claim, self.access_value)):
            raise ValueError('Identity and service configuration required.')
        if not self.scopes or not self.scopes <= SCOPES or not (1 <= self.concurrency <= 64):
            raise ValueError('Invalid scopes or concurrency.')
        if not (1024 <= self.max_input <= 1048576 and 4096 <= self.max_output <= 16777216):
            raise ValueError('Invalid request/response limits.')
        if self.audience_parameter not in {'resource', 'audience'}:
            raise ValueError('Unsupported token audience parameter.')
        for origin in self.origins:
            secure_url(origin)

    @classmethod
    def from_env(cls):
        required = {name: os.environ[key] for name, key in {'resource': 'MCP_RESOURCE', 'issuer': 'OAUTH_ISSUER', 'jwks_url': 'OAUTH_JWKS_URL', 'subject': 'MCP_ALLOWED_SUBJECT', 'api_url': 'NUTRITION_API_URL', 'api_audience': 'NUTRITION_API_AUDIENCE', 'token_url': 'OAUTH_TOKEN_URL', 'client_id': 'SERVICE_CLIENT_ID', 'client_secret': 'SERVICE_CLIENT_SECRET'}.items()}
        return cls(**required, scopes=frozenset(os.getenv('MCP_SCOPES', 'nutrition:read').split()), operations=frozenset(os.getenv('MCP_OPERATIONS', '').split()), origins=frozenset(os.getenv('MCP_ORIGINS', '').split()), diagnostic_only=os.getenv('MCP_DIAGNOSTIC_ONLY', 'true').lower() != 'false', disabled_file=os.getenv('MCP_DISABLED_FILE', '/tmp/nutrition-mcp.disabled'), max_input=int(os.getenv('MCP_MAX_INPUT', '262144')), max_output=int(os.getenv('MCP_MAX_OUTPUT', '1048576')), concurrency=int(os.getenv('MCP_CONCURRENCY', '8')), audience_parameter=os.getenv('OAUTH_AUDIENCE_PARAMETER', 'resource'), access_claim=os.getenv('OAUTH_ACCESS_CLAIM', 'token_use'), access_value=os.getenv('OAUTH_ACCESS_VALUE', 'access'))
