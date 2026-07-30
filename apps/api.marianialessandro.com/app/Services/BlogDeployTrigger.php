<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

class BlogDeployTrigger
{
    /**
     * Fire a workflow_dispatch event for the blog's deploy workflow.
     * Never throws: a failure here must not break the caller's request.
     */
    public function trigger(): bool
    {
        $token = config('services.github.deploy_token');
        $repository = config('services.github.repository');

        if (! $token || ! $repository) {
            Log::info('Blog deploy trigger skipped: GITHUB_DEPLOY_TOKEN or GITHUB_REPOSITORY not configured.');

            return false;
        }

        try {
            $response = Http::withToken($token)
                ->acceptJson()
                ->post("https://api.github.com/repos/{$repository}/actions/workflows/deploy-blog.yml/dispatches", [
                    'ref' => 'main',
                ]);

            if ($response->failed()) {
                Log::warning('Blog deploy trigger failed.', [
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);

                return false;
            }

            return true;
        } catch (Throwable $exception) {
            Log::warning('Blog deploy trigger raised an exception.', [
                'message' => $exception->getMessage(),
            ]);

            return false;
        }
    }
}
