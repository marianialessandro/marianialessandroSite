<?php

namespace Tests\Feature;

use App\Models\NutritionService;
use App\Models\User;
use Firebase\JWT\JWT;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class NutritionServiceTest extends TestCase
{
    use RefreshDatabase;

    private $key;
    private NutritionService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->key = openssl_pkey_new(['private_key_bits' => 2048, 'private_key_type' => OPENSSL_KEYTYPE_RSA]);
        $details = openssl_pkey_get_details($this->key);
        $jwk = ['kid' => 'one', 'kty' => 'RSA', 'alg' => 'RS256', 'use' => 'sig', 'n' => JWT::urlsafeB64Encode($details['rsa']['n']), 'e' => JWT::urlsafeB64Encode($details['rsa']['e'])];
        config(['nutrition_oauth.enabled' => true, 'nutrition_oauth.issuer' => 'https://id.example/', 'nutrition_oauth.audience' => 'https://api.example/nutrition', 'nutrition_oauth.jwks_url' => 'https://id.example/jwks']);
        Http::preventStrayRequests();
        Http::fake(['https://id.example/jwks' => Http::response(['keys' => [$jwk]])]);
        $this->service = NutritionService::create(['name' => 'MCP', 'issuer' => 'https://id.example/', 'subject' => 'machine', 'admin_user_id' => User::factory()->create()->id, 'scopes' => ['nutrition:read'], 'active' => true]);
    }

    private function token(array $changes = []): string
    {
        return JWT::encode(array_merge(['iss' => 'https://id.example/', 'aud' => 'https://api.example/nutrition', 'sub' => 'machine', 'gty' => 'client-credentials', 'scope' => 'nutrition:read', 'iat' => time(), 'exp' => time() + 300], $changes), $this->key, 'RS256', 'one');
    }

    public function test_machine_reads_only_authorized_contracts_and_cannot_manage_tokens(): void
    {
        $this->withToken($this->token())->getJson('/api/nutrition/queries')->assertOk()->assertJsonCount(122, 'data');
        $this->getJson('/api/nutrition/openapi.json')->assertOk()->assertJsonMissingPath('paths./queries/5.1/execute');
        $this->getJson('/api/nutrition/queries/5.1')->assertForbidden();
        $this->postJson('/api/nutrition/queries/5.1/execute')->assertForbidden();
        $this->postJson('/api/nutrition/tokens')->assertUnauthorized();
    }

    public function test_invalid_jwts_never_fall_back_to_an_admin_session(): void
    {
        $this->actingAs(User::factory()->create());
        foreach ([['iss' => 'https://evil.example/'], ['aud' => 'https://mcp.example/mcp'], ['gty' => 'authorization_code'], ['exp' => time() - 1], ['iat' => time() + 60], ['exp' => time() + 3600], ['scope' => null]] as $changes) {
            $this->withToken($this->token($changes))->getJson('/api/nutrition/queries')->assertUnauthorized();
        }
        $this->withToken('malformed.jwt.value')->getJson('/api/nutrition/queries')->assertUnauthorized();
        $old = $this->key;
        $this->key = openssl_pkey_new(['private_key_bits' => 2048, 'private_key_type' => OPENSSL_KEYTYPE_RSA]);
        $this->withToken($this->token())->getJson('/api/nutrition/queries')->assertUnauthorized();
        $this->key = $old;
    }

    public function test_revocation_scope_excess_and_admin_role_are_checked_each_time(): void
    {
        $this->withToken($this->token(['sub' => 'unknown']))->getJson('/api/nutrition/queries')->assertForbidden();
        $this->withToken($this->token(['scope' => 'nutrition:read nutrition:write']))->getJson('/api/nutrition/queries')->assertForbidden();
        $jwt = $this->token();
        $this->withToken($jwt)->getJson('/api/nutrition/queries')->assertOk();
        $this->service->update(['active' => false]);
        $this->getJson('/api/nutrition/queries')->assertForbidden();
        $this->service->update(['active' => true]);
        $this->service->admin->update(['is_admin' => false]);
        $this->getJson('/api/nutrition/queries')->assertForbidden();
    }

    public function test_service_permissions_do_not_inherit_an_admin_session(): void
    {
        $this->actingAs($this->service->admin);
        $this->withToken($this->token())->getJson('/api/nutrition/queries/5.1')->assertForbidden();
    }

    public function test_jwks_outage_and_disabled_configuration_fail_closed(): void
    {
        Http::swap(new \Illuminate\Http\Client\Factory());
        Http::fake(['https://id.example/jwks' => Http::response([], 503)]);
        $this->withToken($this->token())->getJson('/api/nutrition/queries')->assertUnauthorized();
        Cache::flush();
        config(['nutrition_oauth.enabled' => false]);
        $this->getJson('/api/nutrition/queries')->assertUnauthorized();
    }

    public function test_artisan_provision_and_immediate_revocation(): void
    {
        $this->artisan('nutrition:service', ['subject' => 'new-machine', '--admin' => $this->service->admin_user_id, '--scope' => ['nutrition:read']])->assertSuccessful();
        $this->assertDatabaseHas('nutrition_services', ['subject' => 'new-machine', 'active' => true]);
        $this->artisan('nutrition:service', ['subject' => 'new-machine', '--revoke' => true])->assertSuccessful();
        $this->assertDatabaseHas('nutrition_services', ['subject' => 'new-machine', 'active' => false]);
        $this->artisan('nutrition:service', ['subject' => 'bad', '--admin' => $this->service->admin_user_id, '--scope' => ['*']])->assertFailed();
    }
}
