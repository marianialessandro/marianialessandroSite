<?php

namespace App\Http\Controllers;

use App\Http\Resources\PostResource;
use App\Http\Resources\PostSummaryResource;
use App\Models\Post;
use Illuminate\Http\Request;

class PostController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $posts = Post::where('draft', false)
            ->orderByDesc('date')
            ->get();

        return PostSummaryResource::collection($posts);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $this->validated($request);

        $post = Post::create($validated)->fresh();

        return (new PostResource($post))->response()->setStatusCode(201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Post $post)
    {
        return new PostResource($post);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Post $post)
    {
        $validated = $this->validated($request, $post);

        $post->update($validated);

        return new PostResource($post);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Post $post)
    {
        $post->delete();

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
