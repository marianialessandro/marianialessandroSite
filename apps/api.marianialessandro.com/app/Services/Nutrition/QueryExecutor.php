<?php

namespace App\Services\Nutrition;

use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;
use PDO;
use PDOException;

class QueryExecutor
{
    public function execute(array $operation, array $parameters): array
    {
        $unknown = array_diff(array_keys($parameters), array_keys($operation['parameters']));
        if ($unknown) {
            throw ValidationException::withMessages(['parameters' => 'Unknown parameters: '.implode(', ', $unknown)]);
        }
        $rules = [];
        foreach ($operation['parameters'] as $name => $spec) {
            $rules[$name] = [array_key_exists('default', $spec) ? 'sometimes' : 'required', ...(array_key_exists('default', $spec) && $spec['default'] === null ? ['nullable'] : []), match (is_array($spec['type']) ? $spec['type'][0] : $spec['type']) { 'integer' => 'integer', 'number' => 'numeric', default => 'string' }];
            if ((is_array($spec['type']) ? $spec['type'][0] : $spec['type']) === 'string') {
                $rules[$name][] = 'max:10000';
            }
            if (str_ends_with($name, '_id') || $name === 'ultimo_id') {
                $rules[$name][] = 'min:1';
            }
            if (in_array($name, ['data_rif', 'data_da', 'data_a'], true)) {
                $rules[$name][] = 'date_format:Y-m-d';
            }
            if ($name === 'page_size') {
                $rules[$name] = ['required', 'integer', 'min:1', 'max:500'];
            }
            if (in_array($name, ['n_giorni', 'quantita_g', 'soglia_sazieta', 'soglia_kcal'], true)) {
                $rules[$name][] = 'min:0';
            }
            if ($name === 'offset') {
                $rules[$name] = ['required', 'integer', 'min:0', 'max:1000000'];
            }
            if (array_key_exists('default', $spec)) {
                if (!array_key_exists($name, $parameters)) {
                    $parameters[$name] = $spec['default'];
                }
            }
        }
        Validator::make($parameters, $rules)->validate();
        foreach ($operation['parameters'] as $name => $spec) {
            if ($spec['type'] === 'integer' && isset($parameters[$name])) {
                $parameters[$name] = (int) $parameters[$name];
            }
        }
        $connection = DB::connection('nutrition');
        $run = function () use ($connection, $operation, $parameters): array {
            $pdo = $connection->getPdo();
            $results = [];
            $outputs = [];
            foreach ($operation['steps'] as $step) {
                $statement = $pdo->prepare($step['sql']);
                foreach ($step['bindings'] as $index => $name) {
                    $value = $outputs[$name] ?? $parameters[$name] ?? null;
                    $statement->bindValue($index + 1, $value, is_int($value) ? PDO::PARAM_INT : ($value === null ? PDO::PARAM_NULL : PDO::PARAM_STR));
                }
                $statement->execute();
                if ($step['capture']) {
                    $outputs[$step['capture']] = $statement->fetchColumn();
                } elseif ($statement->columnCount() > 0) {
                    $rows = [];
                    while (count($rows) < 501 && ($row = $statement->fetch(PDO::FETCH_ASSOC)) !== false) {
                        $rows[] = $row;
                    }
                    $results[] = ['rows' => array_slice($rows, 0, 500), 'truncated' => count($rows) > 500];
                } else {
                    $results[] = ['affected_rows' => $statement->rowCount(), 'last_insert_id' => str_starts_with($step['sql'], 'INSERT ') && $statement->rowCount() > 0 ? $pdo->lastInsertId() : null];
                }
                $statement->closeCursor();
            }
            return ['operation' => $operation['id'], 'results' => $results, 'outputs' => (object) $outputs];
        };
        try {
            // ANALYZE TABLE implicitly commits in MySQL and must run outside a transaction.
            return $operation['id'] === '18.8' ? $run() : $connection->transaction($run);
        } catch (PDOException|QueryException $exception) {
            $state = (string) $exception->getCode();
            if (str_starts_with($state, '23') || str_starts_with($state, '22') || $state === '45000') {
                abort(422, 'The values violate a nutrition database constraint.');
            }
            abort(503, 'Nutrition database operation unavailable.');
        }
    }
}
