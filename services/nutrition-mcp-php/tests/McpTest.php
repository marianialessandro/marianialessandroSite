<?php

namespace Tests;

use App\Models\User;
use App\Services\SigningKeys;
use Firebase\JWT\JWT;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Foundation\Testing\TestCase;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;
use Laravel\Passport\ClientRepository;
use Laravel\Passport\Passport;

class McpTest extends TestCase
{
    protected $user;
    protected $client;
    protected $private;

    public function createApplication()
    {
        $app = require __DIR__.'/../bootstrap/app.php';
        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();
        return $app;
    }

    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email');
            $table->string('password');
            $table->boolean('is_admin')->default(false);
            $table->rememberToken();
            $table->timestamps();
        });
        foreach (glob(base_path('vendor/laravel/passport/database/migrations/*.php')) as $path) {
            (require $path)->up();
        }
        $key = openssl_pkey_new(['private_key_bits' => 2048]);
        openssl_pkey_export($key, $this->private);
        config(['passport.private_key' => $this->private, 'passport.public_key' => openssl_pkey_get_details($key)['key']]);
        $this->user = User::forceCreate(['name' => 'Owner', 'email' => 'owner@example.test', 'password' => Hash::make('test-password'), 'is_admin' => true]);
        $this->client = app(ClientRepository::class)->createAuthorizationCodeGrantClient('ChatGPT test', ['https://chatgpt.com/connector/oauth/test'], confidential: false);
        config(['mcp_nutrition.enabled' => true, 'mcp_nutrition.allowed_user_id' => $this->user->id, 'mcp_nutrition.client_id' => $this->client->id]);
        Http::preventStrayRequests();
        $this->withServerVariables(['HTTP_HOST' => 'mcp.marianialessandro.com', 'HTTPS' => 'on']);
    }

    private function token(array $changes = []): string
    {
        $id = bin2hex(random_bytes(40));
        Passport::token()->forceFill(['id' => $id, 'user_id' => $this->user->id, 'client_id' => $this->client->id, 'scopes' => ['nutrition:read'], 'revoked' => false, 'expires_at' => now()->addMinutes(10)])->save();
        return JWT::encode(array_merge(['iss' => config('app.url'), 'aud' => [$this->client->id, config('mcp_nutrition.resource')], 'sub' => (string) $this->user->id, 'jti' => $id, 'iat' => time(), 'exp' => time() + 600, 'scopes' => ['nutrition:read'], 'token_use' => 'access'], $changes), $this->private, 'RS256', SigningKeys::kid());
    }

    private function rpc(string $method, array $params = [])
    {
        return $this->postJson('/mcp', ['jsonrpc' => '2.0', 'id' => 1, 'method' => $method, 'params' => $params]);
    }

    public function test_discovery_health_and_all_mcp_methods_require_auth(): void
    {
        $this->getJson('/health')->assertOk();
        $this->getJson('/.well-known/oauth-protected-resource/mcp')->assertOk()->assertJsonPath('resource', config('mcp_nutrition.resource'));
        $this->getJson('/.well-known/oauth-authorization-server')->assertOk()->assertJsonPath('code_challenge_methods_supported.0', 'S256');
        $this->getJson('/mcp')->assertUnauthorized();
        $this->deleteJson('/mcp')->assertUnauthorized();
        $this->rpc('tools/list')->assertUnauthorized()->assertHeader('WWW-Authenticate');
    }

    public function test_initialize_list_call_and_hidden_tools(): void
    {
        $this->withToken($this->token());
        $this->rpc('initialize', ['protocolVersion' => '2025-11-25', 'capabilities' => (object) [], 'clientInfo' => ['name' => 'test', 'version' => '1']])->assertOk()->assertJsonPath('result.serverInfo.name', 'Nutrition');
        $this->rpc('tools/list')->assertOk()->assertJsonPath('result.tools.0.name', 'nutrition_status');
        $this->rpc('tools/call', ['name' => 'nutrition_status', 'arguments' => (object) []])->assertOk()->assertJsonPath('result.structuredContent.status', 'ok');
        $this->rpc('tools/call', ['name' => 'nutrition_17_12', 'arguments' => ['confirm' => true]])->assertJsonPath('error.code', -32602);
        Http::assertNothingSent();
    }

    public function test_wrong_claims_revocation_and_role_are_rejected(): void
    {
        foreach ([['aud' => ['https://api.marianialessandro.com/nutrition']], ['iss' => 'https://wrong.example'], ['sub' => '99'], ['token_use' => 'id'], ['exp' => time() - 1]] as $changes) {
            Auth::forgetGuards();
            $this->withToken($this->token($changes))->rpc('tools/list')->assertUnauthorized();
        }
        Auth::forgetGuards();
        $jwt = $this->token();
        DB::table('oauth_access_tokens')->update(['revoked' => true]);
        $this->withToken($jwt)->rpc('tools/list')->assertUnauthorized();
        Auth::forgetGuards();
        $this->user->forceFill(['is_admin' => false])->save();
        $this->withToken($this->token())->rpc('tools/list')->assertUnauthorized();
    }

    public function test_oauth_authorization_code_pkce_and_refresh_round_trip(): void
    {
        $verifier = str_repeat('a', 64);
        $query = ['response_type' => 'code', 'client_id' => $this->client->id, 'redirect_uri' => 'https://chatgpt.com/connector/oauth/test', 'resource' => config('mcp_nutrition.resource'), 'scope' => 'nutrition:read', 'state' => 'random-test-state', 'code_challenge_method' => 'S256', 'code_challenge' => JWT::urlsafeB64Encode(hash('sha256', $verifier, true))];
        $this->actingAs($this->user)->get('/oauth/authorize?'.http_build_query($query))->assertOk()->assertSee('Autorizza');
        $authToken = session('authToken');
        $approval = $this->post('/oauth/authorize', ['auth_token' => $authToken])->assertRedirect();
        parse_str(parse_url($approval->headers->get('Location'), PHP_URL_QUERY), $params);
        $this->assertSame('random-test-state', $params['state']);
        $payload = ['grant_type' => 'authorization_code', 'client_id' => $this->client->id, 'redirect_uri' => $query['redirect_uri'], 'resource' => $query['resource'], 'code' => $params['code'], 'code_verifier' => $verifier];
        $issued = $this->postJson('/oauth/token', $payload)->assertOk();
        $claims = (array) JWT::decode($issued->json('access_token'), new \Firebase\JWT\Key(SigningKeys::publicKey(), 'RS256'));
        $this->assertContains(config('mcp_nutrition.resource'), $claims['aud']);
        $this->assertSame('access', $claims['token_use']);
        $this->assertSame(config('app.url'), $claims['iss']);
        $this->assertLessThanOrEqual(600, $claims['exp'] - $claims['iat']);
        $refresh = $issued->json('refresh_token');
        $refreshed = $this->postJson('/oauth/token', ['grant_type' => 'refresh_token', 'client_id' => $this->client->id, 'resource' => $query['resource'], 'refresh_token' => $refresh])->assertOk();
        $this->assertNotSame($refresh, $refreshed->json('refresh_token'));
        $this->postJson('/oauth/token', ['grant_type' => 'refresh_token', 'client_id' => $this->client->id, 'resource' => $query['resource'], 'refresh_token' => $refresh])->assertStatus(400);
        Auth::forgetGuards();
        $this->withToken($refreshed->json('access_token'))->rpc('tools/list')->assertOk();
    }

    public function test_pkce_and_resource_are_required_and_other_users_cannot_authorize(): void
    {
        $this->actingAs($this->user)->get('/oauth/authorize?'.http_build_query(['client_id' => $this->client->id, 'resource' => config('mcp_nutrition.resource'), 'code_challenge_method' => 'plain']))->assertStatus(400);
        $this->postJson('/oauth/token', ['client_id' => $this->client->id, 'resource' => 'https://wrong.example', 'grant_type' => 'client_credentials'])->assertStatus(400);
        $other = User::forceCreate(['name' => 'Other', 'email' => 'other@example.test', 'password' => Hash::make('test-password'), 'is_admin' => true]);
        $this->actingAs($other)->post('/oauth/authorize', ['auth_token' => 'fake'])->assertForbidden();
    }

    public function test_real_password_login_and_csrf(): void
    {
        $this->post('/login', ['email' => 'owner@example.test', 'password' => 'wrong'])->assertSessionHasErrors('email');
        $this->post('/login', ['email' => 'owner@example.test', 'password' => 'test-password'])->assertRedirect();
        $this->assertAuthenticatedAs($this->user);
        $this->app->instance('env', 'production');
        $this->post('/oauth/authorize', ['auth_token' => 'fake'])->assertStatus(419);
    }

    public function test_data_tools_keep_machine_and_user_credentials_separate(): void
    {
        config(['mcp_nutrition.diagnostic_only' => false]);
        $catalog = json_decode(file_get_contents(__DIR__.'/../../nutrition-mcp/contracts/catalog.json'), true);
        $requests = [];
        Http::fake(function ($request) use ($catalog, &$requests) {
            $requests[] = $request;
            if (str_ends_with($request->url(), '/queries')) {
                return Http::response(['data' => $catalog]);
            }
            return Http::response('{"operation":"6.1","results":[{"id":9223372036854775807,"kcal":123.4500}],"outputs":{},"truncated":false}', 200, ['Content-Type' => 'application/json']);
        });
        $userJwt = $this->token();
        $this->withToken($userJwt)->rpc('tools/list')->assertOk()->assertJsonCount(123, 'result.tools');
        $this->rpc('tools/call', ['name' => 'nutrition_6_1', 'arguments' => (object) []])->assertJsonPath('result.structuredContent.results.0.id', '9223372036854775807')->assertJsonPath('result.structuredContent.results.0.kcal', '123.4500');
        foreach ($requests as $request) {
            $machine = substr($request->header('Authorization')[0], 7);
            $this->assertNotSame($userJwt, $machine);
            $claims = (array) JWT::decode($machine, new \Firebase\JWT\Key(SigningKeys::publicKey(), 'RS256'));
            $this->assertSame(config('mcp_nutrition.api_audience'), $claims['aud']);
            $this->assertSame('nutrition-mcp-php', $claims['sub']);
            $this->assertSame('mcp-service', $claims['gty']);
            $this->assertSame('nutrition:read', $claims['scope']);
            $this->assertLessThanOrEqual(300, $claims['exp'] - $claims['iat']);
        }
    }

    public function test_all_182_descriptors_and_explicit_mutation_values(): void
    {
        $catalog = json_decode(file_get_contents(__DIR__.'/../../nutrition-mcp/contracts/catalog.json'), true);
        $this->assertCount(182, $catalog);
        $this->actingAs($this->user);
        request()->setUserResolver(fn () => $this->user);
        request()->attributes->set('nutrition_scopes', ['nutrition:read', 'nutrition:write', 'nutrition:delete', 'nutrition:maintenance']);
        config(['mcp_nutrition.scopes' => ['nutrition:read', 'nutrition:write', 'nutrition:delete', 'nutrition:maintenance'], 'mcp_nutrition.operations' => array_column($catalog, 'id')]);
        foreach ($catalog as $entry) {
            $tool = new \App\Mcp\NutritionTool($entry);
            $descriptor = $tool->toArray();
            $this->assertSame('nutrition_'.str_replace('.', '_', $entry['id']), $descriptor['name']);
            $this->assertSame($entry['ability'] === 'nutrition:read', $descriptor['annotations']['readOnlyHint']);
            if ($entry['ability'] !== 'nutrition:read') {
                $this->assertEqualsCanonicalizing(array_keys($descriptor['inputSchema']['properties']), $descriptor['inputSchema']['required']);
                foreach ($descriptor['inputSchema']['properties'] as $spec) {
                    $this->assertArrayNotHasKey('default', $spec);
                }
            }
        }
        Http::assertNothingSent();
    }

    public function test_read_profile_cannot_call_write_and_errors_do_not_expose_sql(): void
    {
        $entry = ['id' => '5.1', 'ability' => 'nutrition:write', 'description' => 'Inserire giornata', 'inputSchema' => ['type' => 'object', 'properties' => ['data_rif' => ['type' => 'string', 'format' => 'date']], 'required' => ['data_rif']]];
        $this->actingAs($this->user);
        request()->setUserResolver(fn () => $this->user);
        request()->attributes->set('nutrition_scopes', ['nutrition:read']);
        $tool = new \App\Mcp\NutritionTool($entry);
        $this->assertTrue($tool->handle(new \Laravel\Mcp\Request(['data_rif' => '2026-09-09']))->isError());
        Http::assertNothingSent();
        config(['mcp_nutrition.scopes' => ['nutrition:write'], 'mcp_nutrition.operations' => ['5.1']]);
        request()->attributes->set('nutrition_scopes', ['nutrition:write']);
        $this->assertTrue($tool->handle(new \Laravel\Mcp\Request([]))->isError());
        Http::fake(['*' => Http::response(['sql' => 'secret SQL'], 503)]);
        $response = $tool->handle(new \Laravel\Mcp\Request(['data_rif' => '2026-09-09']));
        $this->assertTrue($response->isError());
        Http::assertSentCount(1);
    }

    public function test_json_decimal_parser_does_not_modify_strings_or_booleans(): void
    {
        $this->assertSame(['amount' => '12.3400', 'large' => '9007199254740992', 'text' => 'price 12.3400 and "123.45"', 'small' => 10, 'flag' => false, 'scientific' => '1e20'], \App\Services\NutritionApi::decode('{"amount":12.3400,"large":9007199254740992,"text":"price 12.3400 and \"123.45\"","small":10,"flag":false,"scientific":1e20}'));
    }
}
