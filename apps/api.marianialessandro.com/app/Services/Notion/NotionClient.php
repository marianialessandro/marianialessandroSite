<?php

namespace App\Services\Notion;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\PendingRequest;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Http;

class NotionClient
{
    /**
     * @return array<string, mixed>
     */
    public function retrieveDataSource(string $dataSourceId): array
    {
        $response = $this->sendWithRetry(
            fn (): Response => $this->request()->get('data_sources/'.rawurlencode($dataSourceId)),
        );

        return $this->decode($response);
    }

    /**
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    public function queryDataSource(string $dataSourceId, array $payload): array
    {
        $response = $this->sendWithRetry(
            fn (): Response => $this->request()->post(
                'data_sources/'.rawurlencode($dataSourceId).'/query',
                $payload,
            ),
        );

        return $this->decode($response);
    }

    private function request(): PendingRequest
    {
        $token = config('notion.token');
        $version = config('notion.version');
        $baseUrl = rtrim((string) config('notion.base_url', 'https://api.notion.com/v1'), '/');

        if (! is_string($token) || trim($token) === '') {
            throw new NotionConfigurationException('NOTION_TOKEN is not configured.');
        }

        if (! is_string($version) || trim($version) === '') {
            throw new NotionConfigurationException('NOTION_VERSION is not configured.');
        }

        return Http::baseUrl($baseUrl)
            ->withToken(trim($token))
            ->withHeaders([
                'Notion-Version' => trim($version),
            ])
            ->acceptJson()
            ->asJson()
            ->connectTimeout(max(1, (int) config('notion.connect_timeout', 3)))
            ->timeout(max(1, (int) config('notion.timeout', 10)));
    }

    /**
     * @param  callable(): Response  $send
     */
    private function sendWithRetry(callable $send): Response
    {
        $maxRetries = max(0, (int) config('notion.max_retries', 1));
        $attempt = 0;

        while (true) {
            try {
                $response = $send();
            } catch (ConnectionException $exception) {
                if ($attempt >= $maxRetries) {
                    throw new NotionApiException(
                        0,
                        'connection_error',
                        'Unable to connect to the Notion API.',
                        previous: $exception,
                    );
                }

                $this->sleepBeforeRetry($attempt, null);
                $attempt++;

                continue;
            }

            if (! $this->shouldRetry($response) || $attempt >= $maxRetries) {
                return $response;
            }

            $retryAfter = $response->header('Retry-After');
            $this->sleepBeforeRetry(
                $attempt,
                is_numeric($retryAfter) ? (int) $retryAfter : null,
            );
            $attempt++;
        }
    }

    private function shouldRetry(Response $response): bool
    {
        return $response->status() === 429 || $response->serverError();
    }

    private function sleepBeforeRetry(int $attempt, ?int $retryAfterSeconds): void
    {
        if ($retryAfterSeconds !== null && $retryAfterSeconds > 0) {
            sleep(min($retryAfterSeconds, 5));

            return;
        }

        usleep(min(250 * (2 ** $attempt), 2000) * 1000);
    }

    /**
     * @return array<string, mixed>
     */
    private function decode(Response $response): array
    {
        if ($response->failed()) {
            throw NotionApiException::fromResponse($response);
        }

        $payload = $response->json();

        if (! is_array($payload)) {
            throw new NotionApiException(
                $response->status(),
                'invalid_response',
                'Notion returned an invalid JSON response.',
            );
        }

        return $payload;
    }
}
