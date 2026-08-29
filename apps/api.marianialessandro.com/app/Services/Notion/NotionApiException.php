<?php

namespace App\Services\Notion;

use Illuminate\Http\Client\Response;
use RuntimeException;
use Throwable;

class NotionApiException extends RuntimeException
{
    public function __construct(
        public readonly int $status,
        public readonly ?string $notionCode,
        string $message,
        public readonly ?int $retryAfter = null,
        ?Throwable $previous = null,
    ) {
        parent::__construct($message, 0, $previous);
    }

    public static function fromResponse(Response $response): self
    {
        $payload = $response->json();
        $message = is_array($payload) && is_string($payload['message'] ?? null)
            ? $payload['message']
            : 'Notion API request failed.';
        $code = is_array($payload) && is_string($payload['code'] ?? null)
            ? $payload['code']
            : null;
        $retryAfter = $response->header('Retry-After');

        return new self(
            $response->status(),
            $code,
            $message,
            is_numeric($retryAfter) ? max(0, (int) $retryAfter) : null,
        );
    }
}
