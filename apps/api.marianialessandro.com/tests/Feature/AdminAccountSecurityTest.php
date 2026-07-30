<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminAccountSecurityTest extends TestCase
{
    use RefreshDatabase;

    private const FRONTEND_ORIGIN = 'http://localhost:5175';

    public function test_new_accounts_are_admins_and_require_a_strong_password(): void
    {
        $admin = User::factory()->create();

        $this
            ->actingAs($admin, 'web')
            ->withHeaders(['Origin' => self::FRONTEND_ORIGIN])
            ->postJson('/api/users', [
                'name' => 'Weak password',
                'email' => 'weak@example.com',
                'password' => 'password',
            ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('password');

        $this
            ->actingAs($admin, 'web')
            ->withHeaders(['Origin' => self::FRONTEND_ORIGIN])
            ->postJson('/api/users', [
                'name' => 'Second admin',
                'email' => 'SECOND@EXAMPLE.COM',
                'password' => 'Correct-Horse-42!',
            ])
            ->assertCreated()
            ->assertJsonPath('data.email', 'second@example.com')
            ->assertJsonPath('data.is_admin', true);
    }

    public function test_current_account_cannot_delete_itself(): void
    {
        $admin = User::factory()->create();

        $this
            ->actingAs($admin, 'web')
            ->withHeaders(['Origin' => self::FRONTEND_ORIGIN])
            ->deleteJson("/api/users/{$admin->id}")
            ->assertUnprocessable();

        $this->assertDatabaseHas('users', ['id' => $admin->id]);
    }
}
