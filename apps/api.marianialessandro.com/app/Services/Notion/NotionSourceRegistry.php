<?php

namespace App\Services\Notion;

class NotionSourceRegistry
{
    /**
     * @return list<string>
     */
    public function aliases(): array
    {
        $sources = $this->configuredSources();
        $aliases = [];

        foreach ($sources as $alias => $dataSourceId) {
            if (is_string($alias) && is_string($dataSourceId) && trim($dataSourceId) !== '') {
                $aliases[] = $alias;
            }
        }

        sort($aliases);

        return $aliases;
    }

    public function resolve(string $alias): ?string
    {
        $sources = $this->configuredSources();
        $dataSourceId = $sources[$alias] ?? null;

        if (! is_string($dataSourceId) || trim($dataSourceId) === '') {
            return null;
        }

        return trim($dataSourceId);
    }

    /**
     * @return array<string, mixed>
     */
    private function configuredSources(): array
    {
        $sources = config('notion.data_sources', []);

        return is_array($sources) ? $sources : [];
    }
}
