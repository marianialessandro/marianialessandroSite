<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Passport\Contracts\OAuthenticatable;
use Laravel\Passport\HasApiTokens;

class User extends Authenticatable implements OAuthenticatable
{
    use HasApiTokens;

    protected $hidden = ['password', 'remember_token'];

    protected function casts(): array
    {
        return ['is_admin' => 'boolean'];
    }
}
