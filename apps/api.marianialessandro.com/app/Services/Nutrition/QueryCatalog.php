<?php

namespace App\Services\Nutrition;

class QueryCatalog
{
    public function all(): array
    {
        return json_decode(file_get_contents(resource_path('nutrition/catalog.json')), true, 512, JSON_THROW_ON_ERROR);
    }

    public function get(string $id): array
    {
        return $this->all()[$id] ?? abort(404, 'Unknown nutrition operation.');
    }

    public function describe(array $operation): array
    {
        unset($operation['steps']);
        $properties = [];
        $required = [];
        foreach ($operation['parameters'] as $name => $parameter) {
            $properties[$name] = $parameter;
            if ($name === 'page_size') {
                $properties[$name] += ['minimum' => 1, 'maximum' => 500];
            }
            if ($name === 'offset') {
                $properties[$name] += ['minimum' => 0, 'maximum' => 1000000];
            }
            if (in_array($name, ['data_rif', 'data_da', 'data_a'], true)) {
                $properties[$name]['format'] = 'date';
            }
            if (!array_key_exists('default', $parameter)) {
                $required[] = $name;
            }
        }
        $operation['inputSchema'] = ['type' => 'object', 'properties' => (object) $properties, 'required' => $required, 'additionalProperties' => false];
        return $operation;
    }
}
