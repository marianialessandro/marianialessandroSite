<?php

namespace App\Console\Commands;

use App\Models\NutritionService;
use App\Models\User;
use App\Services\Nutrition\NutritionAccessPolicy;
use Illuminate\Console\Command;

class NutritionServiceCommand extends Command
{
    protected $signature = 'nutrition:service {subject : Verified machine identity claim} {--issuer= : Exact trusted issuer} {--admin= : Owner admin user ID} {--name=MCP : Audit display name} {--scope=* : Maximum scope; repeat for multiple scopes} {--revoke : Immediately disable the registration}';

    protected $description = 'Provision or revoke a nutrition service using server administrator access; no IdP secrets are stored.';

    public function handle(): int
    {
        $issuer = $this->option('issuer') ?: config('nutrition_oauth.issuer');
        if (!$issuer || strlen($issuer) > 255 || strlen($this->argument('subject')) > 255) {
            $this->error('Valid issuer and subject required.');
            return self::FAILURE;
        }
        $identity = ['issuer' => $issuer, 'subject' => $this->argument('subject')];
        if ($this->option('revoke')) {
            NutritionService::where($identity)->update(['active' => false]);
            $this->info('Service disabled.');
            return self::SUCCESS;
        }
        $admin = User::find($this->option('admin'));
        $scopes = $this->option('scope') ?: ['nutrition:read'];
        if (!$admin?->is_admin || array_diff($scopes, NutritionAccessPolicy::SCOPES)) {
            $this->error('An existing admin and valid nutrition scopes are required.');
            return self::FAILURE;
        }
        NutritionService::updateOrCreate($identity, ['name' => $this->option('name'), 'admin_user_id' => $admin->id, 'scopes' => array_values(array_unique($scopes)), 'active' => true]);
        $this->info('Service registration saved.');
        return self::SUCCESS;
    }
}
