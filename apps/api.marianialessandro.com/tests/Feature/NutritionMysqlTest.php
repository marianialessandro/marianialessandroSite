<?php

namespace Tests\Feature;

use App\Services\Nutrition\QueryCatalog;
use App\Services\Nutrition\QueryExecutor;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class NutritionMysqlTest extends TestCase
{
    public function test_complete_catalog_and_transactional_invariants_on_mysql(): void
    {
        if (getenv('NUTRITION_MYSQL_TEST') !== '1') {
            $this->markTestSkipped('Run scripts/test_nutrition_mysql.py to use a disposable MySQL 8 database.');
        }
        config(['database.connections.nutrition.host' => '127.0.0.1', 'database.connections.nutrition.port' => getenv('NUTRITION_MYSQL_TEST_PORT'), 'database.connections.nutrition.username' => 'root', 'database.connections.nutrition.password' => '', 'database.connections.nutrition.database' => 'nutrizionista', 'database.connections.nutrition.options' => [\PDO::ATTR_EMULATE_PREPARES => false]]);
        $db = DB::connection('nutrition');
        $catalog = app(QueryCatalog::class)->all();
        $executor = app(QueryExecutor::class);
        $db->beginTransaction();
        try {
            $db->table('diario_giornaliero')->insert([['id' => 1, 'giorno' => 'Fixture', 'data' => '2026-09-08'], ['id' => 2, 'giorno' => 'Other', 'data' => '2026-09-07']]);
            $db->table('pasti')->insert(['id' => 1, 'pasto' => 'Fixture', 'giornata_id' => 1]);
            $db->table('alimenti_prodotti')->insert(['id' => 1, 'alimento_prodotto' => 'Fixture', 'kcal_100g' => 100, 'proteine_100g' => 20]);
            $db->table('voci_alimentari')->insert(['id' => 1, 'voce' => 'Fixture', 'giornata_id' => 1, 'pasto_id' => 1, 'prodotto_id' => 1, 'quantita' => 100, 'unita' => 'g']);
            $db->table('integratori')->insert(['id' => 1, 'integratore' => 'Fixture']);
            $db->table('peso_misure')->insert(['id' => 1, 'rilevazione' => 'Fixture', 'data' => '2026-09-08', 'giornata_id' => 1]);
            $db->table('attivita_allenamenti')->insert(['id' => 1, 'attivita' => 'Fixture', 'giornata_id' => 1]);
            $db->table('assunzioni')->insert(['id' => 1, 'assunzione' => 'Fixture', 'data_ora' => '2026-09-08 10:00:00', 'integratore_id' => 1, 'giornata_id' => 1]);
            $db->table('osservazioni_apprendimenti')->insert(['id' => 1, 'osservazione' => 'Fixture', 'giornata_id' => 1, 'pasto_id' => 1]);
            foreach ($catalog as $id => $operation) {
                if ($id === '18.8') {
                    continue;
                }
                $parameters = [];
                foreach ($operation['parameters'] as $name => $spec) {
                    if (!array_key_exists('default', $spec)) {
                        $parameters[$name] = match (true) { str_contains($name, 'data') => '2026-09-09', $spec['type'] === 'integer' => 1, $spec['type'] === 'number' => 170, default => '%' };
                    }
                }
                $db->beginTransaction();
                try {
                    $result = $executor->execute($operation, $parameters);
                    $this->assertSame($id, $result['operation']);
                } finally {
                    $db->rollBack();
                }
            }
            $executor->execute($catalog['16.8'], ['nuova_giornata_id' => 2, 'pasto_id' => 1]);
            foreach (['pasti', 'voci_alimentari', 'osservazioni_apprendimenti'] as $table) {
                $this->assertEquals(2, $db->table($table)->where('id', 1)->value('giornata_id'));
            }
            $executor->execute($catalog['16.10'], ['voce_id' => 1]);
            $this->assertEquals(100, $db->table('voci_alimentari')->where('id', 1)->value('kcal'));
            $json = $executor->execute($catalog['19.8'], ['giornata_id' => 2]);
            $this->assertEquals(1, json_decode($json['results'][0]['rows'][0]['giornata_json'], true)['pasti'][0]['id']);
            $injection = "x'); DROP TABLE pasti; --";
            $executor->execute($catalog['5.4'], ['data_rif' => '2026-09-09', 'alimento_prodotto' => $injection]);
            $this->assertSame(1, $db->table('alimenti_prodotti')->where('alimento_prodotto', $injection)->count());
            $this->assertSame(1, $db->table('pasti')->count());
            $broken = $catalog['5.12'];
            $broken['steps'][] = ['sql' => "INSERT INTO pasti (pasto, giornata_id) VALUES ('bad', 999999)", 'bindings' => [], 'capture' => null];
            $before = $db->table('diario_giornaliero')->count();
            try {
                $executor->execute($broken, []);
                $this->fail('Expected foreign key failure.');
            } catch (\Symfony\Component\HttpKernel\Exception\HttpException $exception) {
                $this->assertSame(422, $exception->getStatusCode());
            }
            $this->assertSame($before, $db->table('diario_giornaliero')->count());
            $executor->execute($catalog['17.12'], ['giornata_id' => 2]);
            $this->assertSame(0, $db->table('pasti')->count());
            $this->assertSame(0, $db->table('voci_alimentari')->count());
        } finally {
            $db->rollBack();
        }
        $this->assertSame('18.8', $executor->execute($catalog['18.8'], [])['operation']);
    }
}
