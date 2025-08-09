<script>
  export let data;
</script>

<svelte:head>
  <title>Blog</title>
  <meta name="description" content="Articoli e appunti" />
</svelte:head>

<section class="max-w-3xl mx-auto py-10">
  <h1 class="text-3xl font-bold mb-6">Blog</h1>

  <ul class="space-y-6">
    {#each data.posts as post}
      <li class="border-b border-black/10 pb-6">
        <a class="block group" href={`/blog/${post.slug}`} sveltekit:prefetch>
          <h2 class="text-xl font-semibold group-hover:underline">{post.title}</h2>
          {#if post.date}
            <p class="text-sm opacity-70 mt-1">
              {new Date(post.date).toLocaleDateString('it-IT', {
                day: '2-digit', month: '2-digit', year: 'numeric'
              })}
            </p>
          {/if}
          <!-- {#if post.description}
            <p class="mt-2">{post.description}</p>
          {/if} -->
          {#if post.tags?.length}
            <div class="mt-3 flex gap-2 flex-wrap">
              {#each post.tags as t}
                <span class="text-xs px-2 py-1 bg-black/5 rounded-full">{t}</span>
              {/each}
            </div>
          {/if}
        </a>
      </li>
    {/each}
  </ul>
</section>
