<?php

namespace App\Http\Controllers;

use App\Http\Resources\PostResource;
use App\Http\Resources\PostSummaryResource;
use App\Models\Post;
use App\Services\BlogDeployTrigger;
use Illuminate\Http\Request;

class PostController extends Controller
{
    public function __construct(private readonly BlogDeployTrigger $deployTrigger) {}

    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $posts = Post::where('draft', false)
            ->where('date', '<=', now())
            ->orderByDesc('date')
            ->get();

        return PostSummaryResource::collection($posts);
    }

    /**
     * Display a listing of all posts, including drafts and scheduled posts, for the admin panel.
     */
    public function adminIndex()
    {
        $posts = Post::orderByDesc('date')->get();

        return PostSummaryResource::collection($posts);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $this->validated($request);

        $post = Post::create($validated)->fresh();

        if (! $post->draft) {
            $this->deployTrigger->trigger();
        }

        return (new PostResource($post))->response()->setStatusCode(201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Post $post)
    {
        abort_if($post->draft || $post->date->isFuture(), 404);

        return new PostResource($post);
    }

    /**
     * Display any post, including drafts and scheduled posts, to administrators.
     */
    public function adminShow(Post $post)
    {
        return new PostResource($post);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Post $post)
    {
        $wasPublic = ! $post->draft;

        $validated = $this->validated($request, $post);

        $post->update($validated);

        if ($wasPublic || ! $post->draft) {
            $this->deployTrigger->trigger();
        }

        return new PostResource($post);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Post $post)
    {
        $wasPublic = ! $post->draft;

        $post->delete();

        if ($wasPublic) {
            $this->deployTrigger->trigger();
        }

        return response()->json(null, 204);
    }

    /**
     * @return array<string, mixed>
     */
    private function validated(Request $request, ?Post $post = null): array
    {
        return $request->validate([
            'slug' => [
                'required',
                'string',
                'max:255',
                'alpha_dash',
                $post
                    ? "unique:posts,slug,{$post->id}"
                    : 'unique:posts,slug',
            ],
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'content' => ['required', 'string'],
            'date' => ['required', 'date'],
            'tags' => ['present', 'array'],
            'tags.*' => ['string'],
            'draft' => ['boolean'],
            'cover' => ['nullable', 'string', 'max:255'],
            'featured' => ['boolean'],
            'featured_rank' => ['nullable', 'integer'],
        ]);
    }
}
