<?php

namespace App\Services;

use Firebase\JWT\JWT;
use Laravel\Passport\Bridge\AccessToken;

class ResourceAccessToken extends AccessToken
{
    public function toString(): string
    {
        return JWT::encode(['iss' => config('app.url'), 'aud' => [$this->getClient()->getIdentifier(), config('mcp_nutrition.resource')], 'jti' => $this->getIdentifier(), 'iat' => time(), 'nbf' => time(), 'exp' => $this->getExpiryDateTime()->getTimestamp(), 'sub' => $this->getUserIdentifier(), 'scopes' => $this->getScopes(), 'token_use' => 'access'], SigningKeys::privateKey(), 'RS256', SigningKeys::kid(), ['typ' => 'at+jwt']);
    }
}
