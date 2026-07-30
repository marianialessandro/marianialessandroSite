<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class UploadSecurityTest extends TestCase
{
    use RefreshDatabase;

    private const FRONTEND_ORIGIN = 'http://localhost:5175';

    public function test_svg_uploads_are_rejected(): void
    {
        Storage::fake('public');
        $admin = User::factory()->create();
        $svg = UploadedFile::fake()->createWithContent(
            'payload.svg',
            '<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>'
        );

        $this
            ->actingAs($admin, 'web')
            ->withHeaders(['Origin' => self::FRONTEND_ORIGIN])
            ->postJson('/api/uploads', ['file' => $svg])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('file');
    }

    public function test_public_upload_route_is_limited_to_the_posts_directory(): void
    {
        Storage::fake('public');
        Storage::disk('public')->put('private.txt', 'secret');

        $this->get('/api/uploads/private.txt')->assertNotFound();
    }
}
