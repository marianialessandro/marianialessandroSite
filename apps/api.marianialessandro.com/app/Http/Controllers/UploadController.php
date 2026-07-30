<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class UploadController extends Controller
{
    /**
     * Store an uploaded image and return its publicly reachable URL.
     */
    public function store(Request $request)
    {
        $request->validate([
            'file' => ['required', 'file', 'mimes:jpg,jpeg,png,gif,webp', 'max:8192'],
        ]);

        $path = $request->file('file')->store('posts', 'public');

        return response()->json([
            'url' => url("/api/uploads/{$path}"),
            'path' => $path,
        ], 201);
    }

    /**
     * Serve a previously uploaded file publicly. Images embedded in
     * published posts must be loadable by any visitor, not just admins.
     * Deliberately not relying on `storage:link`, since symlinks often
     * don't survive plain FTP deploys on shared hosting.
     */
    public function show(string $path): StreamedResponse
    {
        abort_unless(str_starts_with($path, 'posts/'), 404);
        abort_unless(Storage::disk('public')->exists($path), 404);

        $response = Storage::disk('public')->response($path);
        $response->headers->set('X-Content-Type-Options', 'nosniff');
        $response->headers->set(
            'Content-Security-Policy',
            "default-src 'none'; img-src 'self' data:; style-src 'unsafe-inline'; sandbox"
        );

        return $response;
    }
}
