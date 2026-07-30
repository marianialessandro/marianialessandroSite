<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthSecurityTest extends TestCase
{
    use RefreshDatabase;

    private const FRONTEND_ORIGIN = 'http://localhost:5175';

    public function test_admin_can_log_in_with_a_server_side_session_and_log_out(): void
    {
        $user = User::factory()->create([
            'email' => 'admin@example.com',
        ]);

        $login = $this
            ->withHeaders(['Origin' => self::FRONTEND_ORIGIN])
            ->postJson('/api/auth/login', [
                'email' => '  ADMIN@example.com ',
                'password' => 'password',
            ]);

        $login
            ->assertOk()
            ->assertJsonPath('user.id', $user->id)
            ->assertJsonMissingPath('token')
            ->assertCookie(config('session.cookie'));

        $this->assertAuthenticatedAs($user, 'web');

        $this
            ->withHeaders(['Origin' => self::FRONTEND_ORIGIN])
            ->getJson('/api/auth/me')
            ->assertOk()
            ->assertJsonPath('data.is_admin', true);

        $this
            ->withHeaders(['Origin' => self::FRONTEND_ORIGIN])
            ->postJson('/api/auth/logout')
            ->assertNoContent();

        $this->assertGuest('web');
    }

    public function test_invalid_credentials_and_non_admin_accounts_receive_the_same_error(): void
    {
        $user = User::factory()->nonAdmin()->create([
            'email' => 'reader@example.com',
        ]);

        $nonAdmin = $this
            ->withHeaders(['Origin' => self::FRONTEND_ORIGIN])
            ->postJson('/api/auth/login', [
                'email' => $user->email,
                'password' => 'password',
            ]);

        $unknown = $this
            ->withHeaders(['Origin' => self::FRONTEND_ORIGIN])
            ->postJson('/api/auth/login', [
                'email' => 'unknown@example.com',
                'password' => 'password',
            ]);

        $nonAdmin
            ->assertUnprocessable()
            ->assertJsonPath('errors.email.0', 'Le credenziali fornite non sono corrette.');
        $unknown
            ->assertUnprocessable()
            ->assertJsonPath('errors.email.0', 'Le credenziali fornite non sono corrette.');
        $this->assertGuest('web');
    }

    public function test_admin_routes_require_both_authentication_and_admin_privilege(): void
    {
        $this
            ->withHeaders(['Origin' => self::FRONTEND_ORIGIN])
            ->getJson('/api/admin/posts')
            ->assertUnauthorized();

        $reader = User::factory()->nonAdmin()->create();

        $this
            ->actingAs($reader, 'web')
            ->withHeaders(['Origin' => self::FRONTEND_ORIGIN])
            ->getJson('/api/admin/posts')
            ->assertForbidden();
    }

    public function test_login_is_rate_limited_per_email_and_ip(): void
    {
        for ($attempt = 1; $attempt <= 5; $attempt++) {
            $this
                ->withHeaders(['Origin' => self::FRONTEND_ORIGIN])
                ->postJson('/api/auth/login', [
                    'email' => 'limited@example.com',
                    'password' => 'wrong-password',
                ])
                ->assertUnprocessable();
        }

        $this
            ->withHeaders(['Origin' => self::FRONTEND_ORIGIN])
            ->postJson('/api/auth/login', [
                'email' => 'limited@example.com',
                'password' => 'wrong-password',
            ])
            ->assertTooManyRequests();
    }

    public function test_csrf_cookie_endpoint_is_available_to_the_trusted_frontend(): void
    {
        $this
            ->withHeaders(['Origin' => self::FRONTEND_ORIGIN])
            ->get('/sanctum/csrf-cookie')
            ->assertNoContent()
            ->assertCookie('XSRF-TOKEN');
    }
}
