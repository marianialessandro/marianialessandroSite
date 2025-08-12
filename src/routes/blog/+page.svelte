<script lang="ts">
  export let data: { posts?: Array<{ title: string; slug: string; date?: string; description?: string; tags?: string[] }> };
  const posts = data?.posts ?? [];

  function fmtDate(s: string | number | Date | null | undefined): string | null {
    if (!s) return null;
    const d = new Date(s);
    return Number.isNaN(d.getTime())
      ? null
      : d.toLocaleDateString('it-IT', { day: '2-digit', month: '2-digit', year: 'numeric' });
  }

  const sortedByDate = posts
    .filter((p) => p?.date && !Number.isNaN(new Date(p.date!).getTime()))
    .sort((a, b) => new Date(b.date!).getTime() - new Date(a.date!).getTime());

  const featured = sortedByDate.slice(0, 3);
  const featuredSlugs = new Set(featured.map((p) => p.slug));
  const remaining = posts.filter((p) => !featuredSlugs.has(p.slug));
</script>


<svelte:head>
	<title>Blog</title>
	<meta name="description" content="Articoli e appunti" />
</svelte:head>

<section class="mx-auto max-w-3xl md:max-w-4xl lg:max-w-5xl px-4 sm:px-6 lg:px-0 py-12">
	<header class="mb-8">
		<p class="mt-2 text-sm opacity-70">Articoli e appunti</p>
	</header>

	{#if posts.length === 0}
		<p class="opacity-70">Nessun articolo ancora. Torna presto ✌️</p>
	{:else}
		{#if featured.length}
			<div class="mb-10">
				<h2 class="text-sm uppercase tracking-wide opacity-60 mb-3">Ultimi articoli</h2>

				<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
					{#each featured as post (post.slug)}
						<a
							class="group block rounded-2xl border border-[var(--border)] p-4 md:p-5 transition-all motion-safe:duration-200 hover:bg-[var(--card-hover)] hover:shadow-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--accent)] no-underline hover:no-underline"
							href={`/blog/${post.slug}`}
							data-sveltekit-preload-data="hover"
						>
							<div class="flex items-start justify-between gap-4">
								<h3 class="text-base font-medium leading-snug">
									<span class="transition-colors group-hover:text-[var(--accent)]">{post.title}</span>
								</h3>
								{#if post.date}
									<time
										class="text-xs opacity-60 tabular-nums shrink-0 self-center"
										datetime={new Date(post.date).toISOString()}
									>
										{fmtDate(post.date)}
									</time>
								{/if}
							</div>

							{#if post.description}
								<p class="mt-2 text-sm opacity-80 line-clamp-3">{post.description}</p>
							{/if}

							{#if post.tags?.length}
								<div class="mt-3 flex flex-wrap gap-2">
									{#each post.tags as t}
										<span class="rounded-full border border-[var(--border)] px-2 py-0.5 text-[11px] uppercase tracking-wide opacity-80 transition-colors hover:border-[var(--accent)] hover:text-[var(--accent)]">{t}</span>
									{/each}
								</div>
							{/if}
						</a>
					{/each}
				</div>
			</div>
		{/if}

		<ul class="space-y-4" role="list">
			{#each remaining as post (post.slug)}
				<li>
					<a
						class="group block rounded-xl border border-[var(--border)] p-4 transition-all motion-safe:duration-200 hover:bg-[var(--card-hover)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--accent)] no-underline hover:no-underline"
						href={`/blog/${post.slug}`}
						data-sveltekit-preload-data="hover"
					>
						<div class="flex items-start justify-between gap-4">
							<h2 class="text-lg font-medium leading-snug">
								<span class="transition-colors group-hover:text-[var(--accent)]">{post.title}</span>
							</h2>
							<div class="flex items-center gap-2 shrink-0 self-center">
								{#if post.date}
									<time
										class="text-xs opacity-60 tabular-nums"
										datetime={new Date(post.date).toISOString()}
									>
										{fmtDate(post.date)}
									</time>
								{/if}
							</div>
						</div>

						{#if post.description}
							<p class="mt-2 text-sm opacity-80 line-clamp-2">{post.description}</p>
						{/if}

						{#if post.tags?.length}
							<div class="mt-3 flex flex-wrap gap-2">
								{#each post.tags as t}
									<span class="rounded-full border border-[var(--border)] px-2 py-0.5 text-[11px] uppercase tracking-wide opacity-80 transition-colors hover:border-[var(--accent)] hover:text-[var(--accent)]">{t}</span>
								{/each}
							</div>
						{/if}
					</a>
				</li>
			{/each}
		</ul>
	{/if}
</section>

<style>
	:global(:root){
		--accent:#0ea5a0;
		--border: rgba(0,0,0,0.10);
		--card-hover: rgba(14,165,160,0.06);
	}
	:global(html.dark){
		--border: rgba(255,255,255,0.15);
		--card-hover: rgba(14,165,160,0.10);
	}

	/* Link neutri */
	:global(a){ color: inherit; text-decoration: none; }
	:global(a:visited){ color: inherit; text-decoration: none; }
	:global(a:hover){ text-decoration: none; }

	/* Underline accessibile su focus tastiera */
	:global(a:focus-visible){ text-decoration: underline; text-decoration-color: var(--accent); text-underline-offset: 4px; }

	/* Selezione con accento leggero */
	:global(::selection){ background: rgba(14,165,160,0.18); color: inherit; }
	:global(html.dark ::selection){ background: rgba(14,165,160,0.22); }
</style>
