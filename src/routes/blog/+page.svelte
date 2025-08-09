<script>
	export let data;
</script>

<svelte:head>
	<title>Blog</title>
	<meta name="description" content="Articoli e appunti" />
</svelte:head>

<section class="mx-auto max-w-3xl py-10">
	<h1 class="mb-6 text-3xl font-bold">Blog</h1>

	<ul class="space-y-6">
		{#each data.posts as post}
			<li class="border-b border-black/10 pb-6">
				<a class="group block" href={`/blog/${post.slug}`} data-sveltekit-preload-data="hover">
					<h2 class="text-xl font-semibold group-hover:underline">{post.title}</h2>
					{#if post.date}
						<p class="mt-1 text-sm opacity-70">
							{new Date(post.date).toLocaleDateString('it-IT', {
								day: '2-digit',
								month: '2-digit',
								year: 'numeric'
							})}
						</p>
					{/if}
					<!-- {#if post.description}
            <p class="mt-2">{post.description}</p>
          {/if} -->
					{#if post.tags?.length}
						<div class="mt-3 flex flex-wrap gap-2">
							{#each post.tags as t}
								<span class="rounded-full bg-black/5 px-2 py-1 text-xs">{t}</span>
							{/each}
						</div>
					{/if}
				</a>
			</li>
		{/each}
	</ul>
</section>
