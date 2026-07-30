<?php

namespace Tests\Feature;

use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PostVisibilityTest extends TestCase
{
    use RefreshDatabase;

    private const FRONTEND_ORIGIN = 'http://localhost:5175';

    public function test_public_endpoint_only_exposes_published_posts_that_are_due(): void
    {
        $published = $this->createPost([
            'slug' => 'published',
            'date' => today(),
        ]);
        $draft = $this->createPost([
            'slug' => 'draft',
            'draft' => true,
            'date' => today(),
        ]);
        $scheduled = $this->createPost([
            'slug' => 'scheduled',
            'date' => today()->addDay(),
        ]);

        $this->getJson("/api/posts/{$published->id}")->assertOk();
        $this->getJson("/api/posts/{$draft->id}")->assertNotFound();
        $this->getJson("/api/posts/{$scheduled->id}")->assertNotFound();
    }

    public function test_admin_endpoint_can_read_drafts_and_scheduled_posts(): void
    {
        $admin = User::factory()->create();
        $draft = $this->createPost([
            'slug' => 'private-draft',
            'draft' => true,
            'date' => today()->addDay(),
        ]);

        $this
            ->actingAs($admin, 'web')
            ->withHeaders(['Origin' => self::FRONTEND_ORIGIN])
            ->getJson("/api/admin/posts/{$draft->id}")
            ->assertOk()
            ->assertJsonPath('data.slug', 'private-draft');
    }

    private function createPost(array $overrides = []): Post
    {
        return Post::create(array_merge([
            'slug' => 'post-'.fake()->unique()->slug(),
            'title' => 'Test post',
            'description' => 'Test description',
            'content' => '# Test',
            'date' => today(),
            'tags' => ['test'],
            'draft' => false,
            'featured' => false,
        ], $overrides));
    }
}
