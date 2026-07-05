<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PostSummaryResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'slug' => $this->slug,
            'title' => $this->title,
            'description' => $this->description,
            'date' => $this->date->toDateString(),
            'tags' => $this->tags,
            'draft' => $this->draft,
            'cover' => $this->cover,
            'featured' => $this->featured,
            'featured_rank' => $this->featured_rank,
        ];
    }
}
