<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\Nutrition\QueryCatalog;
use App\Services\Nutrition\QueryExecutor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NutritionApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_every_operation_and_discovery_require_authentication(): void
    {
        $this->getJson('/api/nutrition/queries')->assertUnauthorized();
        $this->getJson('/api/nutrition/openapi.json')->assertUnauthorized();
        foreach (app(QueryCatalog::class)->all() as $id => $operation) {
            $this->postJson('/api/nutrition/queries/'.$id.'/execute')->assertUnauthorized();
        }
        $this->getJson('/api/nutrition/queries/6.1')->assertUnauthorized();
        $this->getJson('/api/nutrition/tokens')->assertUnauthorized();
        $this->postJson('/api/nutrition/tokens')->assertUnauthorized();
        $this->deleteJson('/api/nutrition/tokens/1')->assertUnauthorized();
    }

    public function test_session_admin_can_discover_all_operations_and_non_admin_cannot(): void
    {
        $this->actingAs(User::factory()->create())->getJson('/api/nutrition/queries')->assertOk()->assertJsonCount(182, 'data');
        $this->actingAs(User::factory()->nonAdmin()->create())->getJson('/api/nutrition/queries')->assertForbidden();
    }

    public function test_real_bearer_token_is_scoped_and_cannot_mint_tokens(): void
    {
        $token = User::factory()->create()->createToken('mcp', ['nutrition:read'], now()->addHour())->plainTextToken;
        $this->withToken($token)->getJson('/api/nutrition/queries')->assertOk();
        $this->withToken($token)->getJson('/api/nutrition/openapi.json')->assertOk()->assertJsonPath('openapi', '3.1.0');
        $this->withToken($token)->getJson('/api/nutrition/queries/5.1')->assertForbidden();
        $this->withToken($token)->postJson('/api/nutrition/queries/17.10/execute', ['confirm' => true])->assertForbidden();
        $this->withToken($token)->postJson('/api/nutrition/tokens')->assertUnauthorized();
    }

    public function test_expired_revoked_invalid_and_non_admin_tokens_are_rejected(): void
    {
        $user = User::factory()->create();
        $expired = $user->createToken('expired', ['nutrition:read'], now()->subMinute());
        $revoked = $user->createToken('revoked', ['nutrition:read']);
        $revoked->accessToken->delete();
        foreach ([$expired->plainTextToken, $revoked->plainTextToken, 'invalid'] as $token) {
            $this->app['auth']->forgetGuards();
            $this->withToken($token)->getJson('/api/nutrition/queries')->assertUnauthorized();
        }
        $this->app['auth']->forgetGuards();
        $token = User::factory()->nonAdmin()->create()->createToken('reader', ['nutrition:read'])->plainTextToken;
        $this->withToken($token)->getJson('/api/nutrition/queries')->assertForbidden();
    }

    public function test_validation_and_destructive_confirmation_run_before_database_access(): void
    {
        $this->actingAs(User::factory()->create());
        $this->postJson('/api/nutrition/queries/17.10/execute', ['parameters' => ['giornata_id' => 1]])->assertUnprocessable();
        $this->postJson('/api/nutrition/queries/6.2/execute')->assertUnprocessable();
        $this->postJson('/api/nutrition/queries/6.1/execute', ['parameters' => ['sql' => 'DROP DATABASE nutrizionista']])->assertUnprocessable();
        $this->postJson('/api/nutrition/queries/19.5/execute', ['parameters' => ['ultimo_id' => 10, 'page_size' => 501]])->assertUnprocessable();
        $this->postJson('/api/nutrition/queries/unknown/execute')->assertNotFound();
    }

    public function test_external_bearer_executes_using_the_shared_service(): void
    {
        $this->mock(QueryExecutor::class)->shouldReceive('execute')->once()->withArgs(fn ($operation, $parameters) => $operation['id'] === '6.1' && $parameters === [])->andReturn(['results' => []]);
        $token = User::factory()->create()->createToken('external', ['nutrition:read'])->plainTextToken;
        $this->withToken($token)->postJson('/api/nutrition/queries/6.1/execute')->assertOk();
    }

    public function test_token_lifecycle_and_cross_owner_revocation(): void
    {
        $this->actingAs(User::factory()->create());
        $created = $this->postJson('/api/nutrition/tokens', ['name' => 'MCP', 'abilities' => ['nutrition:read'], 'expires_in_minutes' => 60])->assertCreated();
        $this->postJson('/api/nutrition/tokens', ['name' => 'MCP', 'abilities' => ['*'], 'expires_in_minutes' => 60])->assertUnprocessable();
        $this->getJson('/api/nutrition/tokens')->assertOk()->assertJsonMissingPath('data.0.token');
        $other = User::factory()->create()->createToken('other', ['nutrition:read']);
        $this->deleteJson('/api/nutrition/tokens/'.$other->accessToken->id)->assertNotFound();
        $this->deleteJson('/api/nutrition/tokens/'.$created->json('id'))->assertOk();
        $this->assertDatabaseMissing('personal_access_tokens', ['id' => $created->json('id')]);
    }

    public function test_session_mutations_require_csrf_in_runtime(): void
    {
        $this->actingAs(User::factory()->create());
        $this->app->instance('env', 'local');
        $this->withHeaders(['Origin' => 'http://localhost:5175'])->postJson('/api/nutrition/queries/5.1/execute', ['parameters' => ['data_rif' => '2026-09-09']])->assertStatus(419);
        $this->withHeaders(['Origin' => 'http://localhost:5175'])->postJson('/api/nutrition/tokens', ['name' => 'MCP', 'abilities' => ['nutrition:read'], 'expires_in_minutes' => 60])->assertStatus(419);
    }

    public function test_cors_allows_authorization_for_configured_browser_origins(): void
    {
        $this->withHeaders(['Origin' => 'http://localhost:5175', 'Access-Control-Request-Method' => 'POST', 'Access-Control-Request-Headers' => 'Authorization,Content-Type'])->options('/api/nutrition/queries/6.1/execute')->assertNoContent()->assertHeader('Access-Control-Allow-Origin', 'http://localhost:5175');
    }
}
