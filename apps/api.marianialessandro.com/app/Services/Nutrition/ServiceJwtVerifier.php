<?php

namespace App\Services\Nutrition;

use Firebase\JWT\JWK;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class ServiceJwtVerifier
{
    public function verify(string $token): array
    {
        $config = config('nutrition_oauth');
        if (!$config['enabled'] || strlen($token) > 16384) {
            throw new RuntimeException('Invalid service token.');
        }
        foreach (['issuer', 'audience', 'jwks_url'] as $name) {
            $url = parse_url($config[$name] ?? '');
            if (!$url || ($url['scheme'] ?? '') !== 'https' || empty($url['host']) || isset($url['user']) || isset($url['pass']) || isset($url['query']) || isset($url['fragment'])) {
                throw new RuntimeException('Invalid OAuth configuration.');
            }
        }
        $header = json_decode(JWT::urlsafeB64Decode(explode('.', $token)[0]), true, 32, JSON_THROW_ON_ERROR);
        if (($header['alg'] ?? '') !== 'RS256' || !in_array($header['typ'] ?? '', ['JWT', 'at+jwt'], true) || isset($header['crit']) || !is_string($header['kid'] ?? null)) {
            throw new RuntimeException('Invalid service token.');
        }
        $cacheKey = 'nutrition:jwks:'.hash('sha256', $config['jwks_url']);
        $keys = Cache::get($cacheKey, []);
        if (!isset($keys[$header['kid']])) {
            if (!Cache::add($cacheKey.':refresh', true, 10)) {
                throw new RuntimeException('JWKS refresh limited.');
            }
            $response = Http::timeout(5)->connectTimeout(3)->withoutRedirecting()->withOptions(['on_headers' => function ($response) {
                if ((int) $response->getHeaderLine('Content-Length') > 65536) {
                    throw new RuntimeException('Invalid JWKS size.');
                }
            }, 'progress' => function ($total, $downloaded) {
                if ($downloaded > 65536) {
                    throw new RuntimeException('Invalid JWKS size.');
                }
            }])->get($config['jwks_url']);
            if ($response->status() !== 200 || strlen($response->body()) > 65536) {
                throw new RuntimeException('JWKS unavailable.');
            }
            $entries = $response->json('keys');
            if (!is_array($entries) || count($entries) < 1 || count($entries) > 20) {
                throw new RuntimeException('Invalid JWKS.');
            }
            $keys = [];
            foreach ($entries as $entry) {
                if (($entry['kty'] ?? '') === 'RSA' && ($entry['alg'] ?? 'RS256') === 'RS256' && ($entry['use'] ?? 'sig') === 'sig' && is_string($entry['kid'] ?? null)) {
                    if (isset($keys[$entry['kid']]) || strlen(JWT::urlsafeB64Decode($entry['n'] ?? '')) < 256) {
                        throw new RuntimeException('Invalid signing key.');
                    }
                    $keys[$entry['kid']] = $entry;
                }
            }
            Cache::put($cacheKey, $keys, 300);
        }
        if (!isset($keys[$header['kid']])) {
            throw new RuntimeException('Unknown signing key.');
        }
        $claims = (array) JWT::decode($token, JWK::parseKey($keys[$header['kid']], 'RS256'));
        if (($claims['iss'] ?? '') !== $config['issuer'] || !in_array($config['audience'], (array) ($claims['aud'] ?? []), true) || ($claims[$config['access_claim']] ?? null) !== $config['access_value']) {
            throw new RuntimeException('Invalid service claims.');
        }
        if (!is_int($claims['exp'] ?? null) || !is_int($claims['iat'] ?? null) || $claims['exp'] - $claims['iat'] > 300 || $claims['iat'] > time() || !is_string($claims['scope'] ?? null) || !is_string($claims[$config['service_claim']] ?? null)) {
            throw new RuntimeException('Invalid service claims.');
        }
        return ['issuer' => $claims['iss'], 'subject' => $claims[$config['service_claim']], 'scopes' => preg_split('/\s+/', trim($claims['scope']), -1, PREG_SPLIT_NO_EMPTY)];
    }
}
