<?php

use Illuminate\Support\Facades\Artisan;
use Laravel\Passport\ClientRepository;

Artisan::command('nutrition:client {callback : Exact HTTPS callback shown by ChatGPT}', function () {
    $callback = $this->argument('callback');
    if (parse_url($callback, PHP_URL_SCHEME) !== 'https' || parse_url($callback, PHP_URL_HOST) !== 'chatgpt.com') {
        $this->error('The callback must be an exact HTTPS ChatGPT URL.');
        return 1;
    }
    $client = app(ClientRepository::class)->createAuthorizationCodeGrantClient('Nutrition ChatGPT', [$callback], confidential: false);
    $this->info('Set MCP_CLIENT_ID='.$client->id.' in the private .env. This public PKCE client has no secret.');
});
