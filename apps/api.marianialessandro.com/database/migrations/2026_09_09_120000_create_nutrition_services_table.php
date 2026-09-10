<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nutrition_services', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('issuer');
            $table->string('subject');
            $table->foreignId('admin_user_id')->constrained('users')->cascadeOnDelete();
            $table->json('scopes');
            $table->boolean('active')->default(false);
            $table->timestamps();
            $table->unique(['issuer', 'subject']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('nutrition_services');
    }
};
