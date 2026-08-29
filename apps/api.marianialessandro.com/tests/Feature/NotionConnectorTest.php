<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class NotionConnectorTest extends TestCase
{
    use RefreshDatabase;

    private const DATA_SOURCE_ID = '11111111-2222-3333-4444-555555555555';

    protected function setUp(): void
    {
        parent::setUp();

        config()->set('notion.token', 'test-notion-token');
        config()->set('notion.version', '2026-03-11');
        config()->set('notion.base_url', 'https://api.notion.com/v1');
        config()->set('notion.max_retries', 0);
        config()->set('notion.data_sources', [
            'university' => self::DATA_SOURCE_ID,
        ]);
    }

    public function test_notion_routes_require_authentication(): void
    {
        $this
            ->postJson('/api/notion/university/query')
            ->assertUnauthorized();
    }

    public function test_authenticated_non_admin_user_can_access_notion_routes(): void
    {
        $reader = User::factory()->nonAdmin()->create();

        $response = $this
            ->actingAs($reader, 'web')
            ->getJson('/api/notion/sources')
            ->assertOk()
            ->assertJsonPath('data.0.alias', 'university');

        $this->assertStringNotContainsString(self::DATA_SOURCE_ID, $response->getContent());
        $this->assertStringNotContainsString('test-notion-token', $response->getContent());
    }

    public function test_authenticated_user_can_query_a_configured_notion_data_source(): void
    {
        Http::fake([
            'https://api.notion.com/v1/data_sources/*/query' => Http::response([
                'object' => 'list',
                'results' => [],
                'next_cursor' => null,
                'has_more' => false,
                'type' => 'page_or_data_source',
                'page_or_data_source' => new \stdClass(),
            ]),
        ]);

        $user = User::factory()->nonAdmin()->create();

        $this
            ->actingAs($user, 'web')
            ->postJson('/api/notion/university/query', [
                'page_size' => 25,
                'filter' => [
                    'property' => 'Done',
                    'checkbox' => [
                        'equals' => true,
                    ],
                ],
                'sorts' => [
                    [
                        'timestamp' => 'last_edited_time',
                        'direction' => 'descending',
                    ],
                ],
            ])
            ->assertOk()
            ->assertJsonPath('has_more', false);

        Http::assertSent(function (Request $request): bool {
            $data = $request->data();

            return $request->url() === 'https://api.notion.com/v1/data_sources/'.self::DATA_SOURCE_ID.'/query'
                && $request->hasHeader('Authorization', 'Bearer test-notion-token')
                && $request->hasHeader('Notion-Version', '2026-03-11')
                && ($data['page_size'] ?? null) === 25
                && ($data['filter']['property'] ?? null) === 'Done';
        });
    }

    public function test_unknown_alias_is_rejected_before_calling_notion(): void
    {
        Http::fake();
        $user = User::factory()->nonAdmin()->create();

        $this
            ->actingAs($user, 'web')
            ->postJson('/api/notion/not-configured/query')
            ->assertNotFound();

        Http::assertNothingSent();
    }

    public function test_query_validation_rejects_invalid_page_size_before_calling_notion(): void
    {
        Http::fake();
        $user = User::factory()->nonAdmin()->create();

        $this
            ->actingAs($user, 'web')
            ->postJson('/api/notion/university/query', [
                'page_size' => 101,
            ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('page_size');

        Http::assertNothingSent();
    }

    public function test_upstream_rate_limit_is_exposed_as_service_unavailable_with_retry_after(): void
    {
        Http::fake([
            'https://api.notion.com/v1/data_sources/*/query' => Http::response([
                'object' => 'error',
                'status' => 429,
                'code' => 'rate_limited',
                'message' => 'Rate limited.',
            ], 429, [
                'Retry-After' => '2',
            ]),
        ]);

        $user = User::factory()->nonAdmin()->create();

        $this
            ->actingAs($user, 'web')
            ->postJson('/api/notion/university/query')
            ->assertStatus(503)
            ->assertHeader('Retry-After', '2')
            ->assertJsonPath('notion_code', 'rate_limited');
    }
}
