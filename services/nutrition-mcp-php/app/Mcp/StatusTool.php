<?php

namespace App\Mcp;

use Laravel\Mcp\Request;
use Laravel\Mcp\Response;
use Laravel\Mcp\Server\Tool;

class StatusTool extends Tool
{
    protected string $name = 'nutrition_status';
    protected string $description = 'Verifica autenticazione e processo senza leggere il database nutrizionale.';

    public function toArray(): array
    {
        $security = [['type' => 'oauth2', 'scopes' => config('mcp_nutrition.scopes')]];
        return ['name' => $this->name, 'description' => $this->description, 'inputSchema' => ['type' => 'object', 'properties' => (object) [], 'additionalProperties' => false], 'annotations' => ['readOnlyHint' => true, 'destructiveHint' => false, 'idempotentHint' => true, 'openWorldHint' => false], 'securitySchemes' => $security, '_meta' => ['securitySchemes' => $security]];
    }

    public function handle(Request $request)
    {
        return $request->all() ? Response::error('Il tool non accetta parametri.') : Response::structured(['status' => 'ok', 'diagnostic_only' => config('mcp_nutrition.diagnostic_only')]);
    }
}
