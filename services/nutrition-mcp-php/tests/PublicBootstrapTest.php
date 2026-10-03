<?php

namespace Tests;

use Illuminate\Http\Request;
use PHPUnit\Framework\Attributes\PreserveGlobalState;
use PHPUnit\Framework\Attributes\RunInSeparateProcess;
use PHPUnit\Framework\TestCase;

class PublicBootstrapTest extends TestCase
{
    #[RunInSeparateProcess]
    #[PreserveGlobalState(false)]
    public function test_health_and_resource_metadata_boot_without_private_configuration(): void
    {
        putenv('APP_KEY=');
        putenv('MCP_ENABLED=false');
        $_ENV['APP_KEY'] = '';
        $_ENV['MCP_ENABLED'] = 'false';
        $_SERVER['APP_KEY'] = '';
        $_SERVER['MCP_ENABLED'] = 'false';

        $app = require __DIR__.'/../bootstrap/app.php';

        $health = $app->handle(Request::create('/health', 'GET', [], [], [], ['HTTP_HOST' => 'mcp.marianialessandro.com', 'HTTPS' => 'on']));
        $this->assertSame(200, $health->getStatusCode());
        $this->assertSame(['status' => 'ok'], json_decode($health->getContent(), true));

        $metadata = $app->handle(Request::create('/.well-known/oauth-protected-resource/mcp', 'GET', [], [], [], ['HTTP_HOST' => 'mcp.marianialessandro.com', 'HTTPS' => 'on']));
        $this->assertSame(200, $metadata->getStatusCode());
        $this->assertSame('https://mcp.marianialessandro.com/mcp', json_decode($metadata->getContent(), true)['resource']);

        $disabled = $app->handle(Request::create('/mcp', 'POST', [], [], [], ['HTTP_HOST' => 'mcp.marianialessandro.com', 'HTTPS' => 'on', 'CONTENT_TYPE' => 'application/json'], '{}'));
        $this->assertSame(503, $disabled->getStatusCode());
    }
}
