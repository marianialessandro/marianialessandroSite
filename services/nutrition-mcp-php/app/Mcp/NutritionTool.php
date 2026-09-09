<?php

namespace App\Mcp;

use App\Services\NutritionApi;
use Illuminate\Support\Facades\Log;
use Laravel\Mcp\Request;
use Laravel\Mcp\Response;
use Laravel\Mcp\Server\Tool;
use Throwable;

class NutritionTool extends Tool
{
    public function __construct(private array $entry)
    {
        $this->name = 'nutrition_'.str_replace('.', '_', $entry['id']);
        $this->description = $entry['description'];
    }

    public static function allowed(array $entry): bool
    {
        $operations = config('mcp_nutrition.operations');
        return config('mcp_nutrition.enabled') && in_array($entry['ability'], request()->attributes->get('nutrition_scopes', []), true) && in_array($entry['ability'], config('mcp_nutrition.scopes'), true) && ($operations ? in_array($entry['id'], $operations, true) : $entry['ability'] === 'nutrition:read');
    }

    public function toArray(): array
    {
        $schema = $this->entry['inputSchema'];
        $read = $this->entry['ability'] === 'nutrition:read';
        $properties = (array) $schema['properties'];
        foreach ($properties as $name => &$spec) {
            $spec['description'] = str_replace('_', ' ', $name);
            if (!$read) {
                unset($spec['default']);
            }
        }
        unset($spec);
        if (!$read) {
            $schema['required'] = array_keys($properties);
        }
        if (in_array($this->entry['ability'], ['nutrition:delete', 'nutrition:maintenance'], true)) {
            $properties['confirm'] = ['type' => 'boolean', 'const' => true];
            $schema['required'][] = 'confirm';
        }
        $schema['properties'] = $properties ?: (object) [];
        $schema['additionalProperties'] = false;
        $security = [['type' => 'oauth2', 'scopes' => [$this->entry['ability']]]];
        return ['name' => $this->name, 'description' => $this->description, 'inputSchema' => $schema, 'annotations' => ['readOnlyHint' => $read, 'destructiveHint' => !$read, 'idempotentHint' => $read, 'openWorldHint' => false], 'securitySchemes' => $security, '_meta' => ['securitySchemes' => $security]];
    }

    private function valid(array $arguments): bool
    {
        $schema = $this->toArray()['inputSchema'];
        $properties = (array) $schema['properties'];
        if (array_diff(array_keys($arguments), array_keys($properties)) || array_diff($schema['required'], array_keys($arguments))) {
            return false;
        }
        foreach ($arguments as $name => $value) {
            $spec = $properties[$name];
            $types = (array) $spec['type'];
            $type = match (true) { is_null($value) => 'null', is_bool($value) => 'boolean', is_int($value) => 'integer', is_float($value) => 'number', is_string($value) => 'string', default => 'invalid' };
            if (!in_array($type, $types, true) && !($type === 'integer' && in_array('number', $types, true))) {
                return false;
            }
            if ((array_key_exists('const', $spec) && $value !== $spec['const']) || (isset($spec['minimum']) && $value < $spec['minimum']) || (isset($spec['maximum']) && $value > $spec['maximum'])) {
                return false;
            }
            if (($spec['format'] ?? '') === 'date' && (!is_string($value) || !preg_match('/\A(\d{4})-(\d{2})-(\d{2})\z/', $value, $parts) || !checkdate((int) $parts[2], (int) $parts[3], (int) $parts[1]))) {
                return false;
            }
        }
        return true;
    }

    public function handle(Request $request)
    {
        $started = microtime(true);
        $outcome = 'error';
        try {
            if (!self::allowed($this->entry)) {
                return Response::error('Operazione non autorizzata.');
            }
            $arguments = $request->all();
            if (!$this->valid($arguments)) {
                return Response::error('Parametri mancanti o non validi: fornire tutti i valori richiesti.');
            }
            $payload = ['parameters' => $arguments];
            if (array_key_exists('confirm', $arguments)) {
                $payload['confirm'] = $arguments['confirm'];
                unset($payload['parameters']['confirm']);
            }
            $data = app(NutritionApi::class)->request('/queries/'.$this->entry['id'].'/execute', [$this->entry['ability']], $payload, $this->entry['ability'] !== 'nutrition:read');
            $outcome = 'ok';
            return Response::structured($data);
        } catch (\RuntimeException $exception) {
            return Response::error($exception->getMessage());
        } catch (Throwable $exception) {
            return Response::error('Servizio temporaneamente indisponibile.');
        } finally {
            Log::info('nutrition.mcp', ['request_id' => request()->attributes->get('request_id'), 'actor' => substr(hash_hmac('sha256', (string) request()->user()->id, config('app.key')), 0, 32), 'operation' => $this->entry['id'], 'outcome' => $outcome, 'duration_ms' => round((microtime(true) - $started) * 1000)]);
        }
    }
}
