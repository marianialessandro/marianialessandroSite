<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Post extends Model
{
    protected $fillable = [
        'slug',
        'title',
        'description',
        'content',
        'date',
        'tags',
        'draft',
        'cover',
        'featured',
        'featured_rank',
    ];

    protected $casts = [
        'date' => 'date',
        'tags' => 'array',
        'draft' => 'boolean',
        'featured' => 'boolean',
        'featured_rank' => 'integer',
    ];
}
