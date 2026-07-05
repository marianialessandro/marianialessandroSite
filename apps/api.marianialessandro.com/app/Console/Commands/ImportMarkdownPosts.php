<?php

namespace App\Console\Commands;

use App\Models\Post;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Spatie\YamlFrontMatter\YamlFrontMatter;
use Symfony\Component\Finder\Finder;

#[Signature('posts:import-markdown {--path= : Directory containing the .md post files}')]
#[Description('Import blog posts from Markdown files (with YAML front matter) into the database')]
class ImportMarkdownPosts extends Command
{
    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $path = $this->option('path');

        if (! $path || ! is_dir($path)) {
            $this->error("Directory not found: {$path}");

            return self::FAILURE;
        }

        $files = Finder::create()->files()->name('*.md')->in($path);

        $imported = 0;

        foreach ($files as $file) {
            $document = YamlFrontMatter::parse($file->getContents());
            $matter = $document->matter();
            $slug = $file->getFilenameWithoutExtension();

            Post::updateOrCreate(
                ['slug' => $slug],
                [
                    'title' => $matter['title'],
                    'description' => $matter['description'] ?? null,
                    'content' => trim($document->body()),
                    'date' => $matter['date'],
                    'tags' => $matter['tags'] ?? [],
                    'draft' => $matter['draft'] ?? false,
                    'cover' => $matter['cover'] ?? null,
                    'featured' => $matter['featured'] ?? false,
                    'featured_rank' => $matter['featuredRank'] ?? null,
                ]
            );

            $imported++;
            $this->info("Imported: {$slug}");
        }

        $this->info("Done. {$imported} post(s) imported from {$path}.");

        return self::SUCCESS;
    }
}
