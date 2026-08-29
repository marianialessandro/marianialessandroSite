<?php

namespace App\Http\Controllers;

use App\Services\Notion\NotionApiException;
use App\Services\Notion\NotionClient;
use App\Services\Notion\NotionConfigurationException;
use App\Services\Notion\NotionSourceRegistry;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Throwable;

class NotionController extends Controller
{
    public function sources(NotionSourceRegistry $registry): JsonResponse
    {
        return response()->json([
            'data' => array_map(
                fn (string $alias): array => ['alias' => $alias],
                $registry->aliases(),
            ),
        ]);
    }

    public function show(
        string $source,
        NotionSourceRegistry $registry,
        NotionClient $notion,
    ): JsonResponse {
        $dataSourceId = $this->resolveSource($source, $registry);

        try {
            return response()->json($notion->retrieveDataSource($dataSourceId));
        } catch (Throwable $exception) {
            return $this->notionErrorResponse($exception);
        }
    }

    public function query(
        Request $request,
        string $source,
        NotionSourceRegistry $registry,
        NotionClient $notion,
    ): JsonResponse {
        $dataSourceId = $this->resolveSource($source, $registry);
        $payload = $request->validate([
            'filter' => ['sometimes', 'array'],
            'sorts' => ['sometimes', 'array', 'max:100'],
            'sorts.*' => ['array'],
            'start_cursor' => ['sometimes', 'nullable', 'string', 'max:2048'],
            'page_size' => ['sometimes', 'integer', 'between:1,100'],
            'in_trash' => ['sometimes', 'boolean'],
            'result_type' => ['sometimes', 'string', 'in:page,data_source'],
        ]);

        try {
            return response()->json($notion->queryDataSource($dataSourceId, $payload));
        } catch (Throwable $exception) {
            return $this->notionErrorResponse($exception);
        }
    }

    private function resolveSource(string $source, NotionSourceRegistry $registry): string
    {
        $dataSourceId = $registry->resolve($source);

        abort_if($dataSourceId === null, 404, 'Unknown Notion data source.');

        return $dataSourceId;
    }

    private function notionErrorResponse(Throwable $exception): JsonResponse
    {
        if ($exception instanceof NotionConfigurationException) {
            $payload = [
                'message' => 'The Notion connector is not configured.',
            ];

            if (config('app.debug')) {
                $payload['detail'] = $exception->getMessage();
            }

            return response()->json($payload, 500);
        }

        if (! $exception instanceof NotionApiException) {
            report($exception);

            return response()->json([
                'message' => 'Unexpected Notion connector error.',
            ], 500);
        }

        $status = match (true) {
            $exception->status === 400 => 422,
            $exception->status === 429 => 503,
            $exception->status >= 500 || $exception->status === 0 => 502,
            default => 502,
        };

        $payload = [
            'message' => 'Notion API request failed.',
            'notion_code' => $exception->notionCode,
        ];

        if ($exception->status === 400 || config('app.debug')) {
            $payload['detail'] = $exception->getMessage();
        }

        $response = response()->json($payload, $status);

        if ($exception->retryAfter !== null && $exception->retryAfter > 0) {
            $response->headers->set('Retry-After', (string) $exception->retryAfter);
        }

        return $response;
    }
}
