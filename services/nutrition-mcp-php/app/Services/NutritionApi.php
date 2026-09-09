<?php

namespace App\Services;

use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Http;
use RuntimeException;
use Throwable;

class NutritionApi
{

    public static function decode(string $json): array
    {
        // Preserve decimal lexemes while skipping JSON strings, including nested JSON stored in text columns.
        $json = preg_replace_callback('/"(?:\\\\.|[^"\\\\])*"(*SKIP)(*F)|-?(?:0|[1-9][0-9]*)(?:\.[0-9]+(?:[eE][+-]?[0-9]+)?|[eE][+-]?[0-9]+)/', fn ($match) => json_encode($match[0]), $json);
        $data = json_decode($json, true, 512, JSON_THROW_ON_ERROR | JSON_BIGINT_AS_STRING);
        array_walk_recursive($data, function (&$value) {
            if (is_int($value) && abs($value) > 9007199254740991) {
                $value = (string) $value;
            }
        });
        return $data;
    }

    public function request(string $path, array $scopes, ?array $payload = null, bool $mutation = false): array
    {
        $base = config('mcp_nutrition.api_url');
        $url = parse_url($base);
        if (($url['scheme'] ?? '') !== 'https' || empty($url['host']) || isset($url['user']) || isset($url['query']) || isset($url['fragment'])) {
            throw new RuntimeException('Configurazione API non valida.');
        }
        $token = JWT::encode(['iss' => config('app.url'), 'aud' => config('mcp_nutrition.api_audience'), 'sub' => config('mcp_nutrition.service_subject'), 'gty' => 'mcp-service', 'scope' => implode(' ', $scopes), 'iat' => time(), 'exp' => time() + 300], SigningKeys::privateKey(), 'RS256', SigningKeys::kid());
        $actor = substr(hash_hmac('sha256', (string) request()->user()->id, config('app.key')), 0, 32);
        try {
            $request = Http::withToken($token)->acceptJson()->timeout(20)->connectTimeout(5)->withoutRedirecting()->withHeaders(['X-Request-ID' => request()->attributes->get('request_id'), 'X-Nutrition-Actor' => $actor])->withOptions(['progress' => function ($total, $downloaded) {
                if ($downloaded > 1048576) {
                    throw new RuntimeException('Risposta troppo grande.');
                }
            }]);
            $response = $payload === null ? $request->get(rtrim($base, '/').$path) : $request->post(rtrim($base, '/').$path, $payload);
        } catch (Throwable $exception) {
            throw new RuntimeException($mutation ? 'Esito non determinato: verificare con una lettura prima di ripetere.' : 'API non disponibile.');
        }
        if (!$response->successful()) {
            $message = match ($response->status()) { 401 => 'Credenziale del servizio API rifiutata: verificare la configurazione del servizio.', 403 => 'Permessi API insufficienti.', 404 => 'Operazione non disponibile.', 422 => 'Parametri rifiutati.', 429 => 'Limite API raggiunto.', default => 'API non disponibile.' };
            if (in_array($response->status(), [429, 503], true) && ctype_digit($response->header('Retry-After') ?? '')) {
                $message .= ' Riprovare dopo '.min(3600, (int) $response->header('Retry-After')).' secondi.';
            }
            if ($mutation && $response->status() >= 500) {
                $message .= ' Esito non determinato: verificare con una lettura prima di ripetere.';
            }
            throw new RuntimeException($message);
        }
        if (strlen($response->body()) > ($path === '/queries' ? 1048576 : 262144)) {
            throw new RuntimeException('Risposta troppo grande: ridurre filtri o pagine.'.($mutation ? ' Verificare la scrittura con una lettura prima di ripetere.' : ''));
        }
        try {
            return self::decode($response->body());
        } catch (Throwable $exception) {
            throw new RuntimeException('Risposta API non valida.'.($mutation ? ' Verificare la scrittura prima di ripetere.' : ''));
        }
    }
}
