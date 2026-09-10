<?php

namespace App\Services;

use Firebase\JWT\JWT;

class SigningKeys
{
    public static function privateKey(): string
    {
        return config('passport.private_key') ?: file_get_contents(storage_path('oauth-private.key'));
    }

    public static function publicKey(): string
    {
        return config('passport.public_key') ?: file_get_contents(storage_path('oauth-public.key'));
    }

    public static function kid(): string
    {
        return substr(hash('sha256', self::publicKey()), 0, 32);
    }

    public static function jwks(): array
    {
        $details = openssl_pkey_get_details(openssl_pkey_get_public(self::publicKey()));
        return ['keys' => [['kty' => 'RSA', 'use' => 'sig', 'alg' => 'RS256', 'kid' => self::kid(), 'n' => JWT::urlsafeB64Encode($details['rsa']['n']), 'e' => JWT::urlsafeB64Encode($details['rsa']['e'])]]];
    }
}
