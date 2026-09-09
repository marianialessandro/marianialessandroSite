<?php

namespace App\Http\Controllers;

use App\Services\Nutrition\NutritionAccessPolicy;
use App\Services\Nutrition\QueryCatalog;
use App\Services\Nutrition\QueryExecutor;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NutritionController extends Controller
{
    public function index(Request $request, QueryCatalog $catalog): JsonResponse
    {
        $operations = array_filter($catalog->all(), fn ($operation) => app(NutritionAccessPolicy::class)->allows($request, $operation['ability']));
        return response()->json(['data' => array_values(array_map($catalog->describe(...), $operations))])->header('Cache-Control', 'no-store');
    }

    public function openapi(Request $request, QueryCatalog $catalog): JsonResponse
    {
        $paths = [];
        foreach ($catalog->all() as $id => $operation) {
            if (!app(NutritionAccessPolicy::class)->allows($request, $operation['ability'])) {
                continue;
            }
            $confirmation = in_array($operation['ability'], ['nutrition:delete', 'nutrition:maintenance'], true);
            $schema = ['type' => 'object', 'properties' => ['parameters' => $catalog->describe($operation)['inputSchema'], 'confirm' => ['type' => 'boolean', 'const' => true]], 'required' => $confirmation ? ['parameters', 'confirm'] : ['parameters'], 'additionalProperties' => false];
            $paths['/queries/'.$id.'/execute'] = ['post' => ['operationId' => 'nutrition_'.str_replace('.', '_', $id), 'summary' => $operation['description'], 'x-token-ability' => $operation['ability'], 'requestBody' => ['required' => true, 'content' => ['application/json' => ['schema' => $schema]]], 'responses' => ['200' => ['description' => 'Results, affected rows and captured IDs. Result sets contain at most 500 rows and a truncated flag.'], '401' => ['description' => 'Unauthenticated'], '403' => ['description' => 'Insufficient privileges'], '422' => ['description' => 'Invalid parameters or constraint violation'], '429' => ['description' => 'Rate limited'], '503' => ['description' => 'Database unavailable']]]];
        }
        return response()->json(['openapi' => '3.1.0', 'info' => ['title' => 'Nutrition API', 'version' => '1.0.0'], 'servers' => [['url' => '/api/nutrition']], 'security' => [['bearerAuth' => []], ['sessionAuth' => []]], 'components' => ['securitySchemes' => ['bearerAuth' => ['type' => 'http', 'scheme' => 'bearer'], 'sessionAuth' => ['type' => 'apiKey', 'in' => 'cookie', 'name' => config('session.cookie')]]], 'paths' => $paths])->header('Cache-Control', 'no-store');
    }

    public function show(Request $request, string $operation, QueryCatalog $catalog): JsonResponse
    {
        $entry = $catalog->get($operation);
        abort_unless(app(NutritionAccessPolicy::class)->allows($request, $entry['ability']), 403);
        return response()->json($catalog->describe($entry))->header('Cache-Control', 'no-store');
    }

    public function execute(Request $request, string $operation, QueryCatalog $catalog, QueryExecutor $executor): JsonResponse
    {
        $entry = $catalog->get($operation);
        abort_unless(app(NutritionAccessPolicy::class)->allows($request, $entry['ability']), 403);
        $request->validate(['parameters' => ['sometimes', 'array'], 'confirm' => [$entry['ability'] === 'nutrition:delete' || $entry['ability'] === 'nutrition:maintenance' ? 'required' : 'sometimes', 'accepted']]);
        $parameters = $request->input('parameters', []);
        return response()->json($executor->execute($entry, $parameters))->header('Cache-Control', 'no-store');
    }
}
