<?php

namespace Tests\Unit;

use App\Services\Nutrition\QueryCatalog;
use Tests\TestCase;

class NutritionCatalogTest extends TestCase
{
    public function test_catalog_covers_every_numbered_source_query_and_three_procedures(): void
    {
        preg_match_all('/^-- (\d+\.\d+) /m', file_get_contents(resource_path('nutrition/nutrizionista_query_catalog_mysql.sql')), $matches);
        $expected = [...$matches[1], '23.1', '23.2', '23.3'];
        $catalog = app(QueryCatalog::class)->all();
        $this->assertSame($expected, array_keys($catalog));
        foreach ($catalog as $operation) {
            $available = array_keys($operation['parameters']);
            $this->assertNotEmpty($operation['steps']);
            foreach ($operation['steps'] as $step) {
                $this->assertSame(count($step['bindings']), substr_count($step['sql'], '?'));
                $this->assertSame([], array_values(array_diff($step['bindings'], $available)));
                $this->assertDoesNotMatchRegularExpression('/^(DROP|CREATE|TRUNCATE|GRANT|USE)\s/i', $step['sql']);
                if ($step['capture']) {
                    $available[] = $step['capture'];
                }
            }
        }
    }
}
