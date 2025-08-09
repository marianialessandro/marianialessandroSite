<!-- src/routes/blog/[slug]/+page.svelte -->
<script lang="ts">
  export let data;
  import PostLayout from '$lib/layouts/PostLayout.svelte';
</script>

<svelte:head>
  <title>{data.meta.title}</title>
  {#if data.meta.description}
    <meta name="description" content={data.meta.description} />
  {/if}
</svelte:head>

<PostLayout {data} Content={data.Content} meta={data.meta} />
