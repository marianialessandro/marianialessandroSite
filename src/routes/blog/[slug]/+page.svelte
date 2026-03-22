<!-- src/routes/blog/[slug]/+page.svelte -->
<script lang="ts">
	import PostLayout from '$lib/layouts/PostLayout.svelte';
	import type { PageData } from './$types';

	export let data: PageData;
</script>

<svelte:head>
	<title>{data.meta.title}</title>
	{#if data.meta.description}
		<meta name="description" content={data.meta.description} />
	{/if}
</svelte:head>

<PostLayout Content={data.Content} meta={data.meta} />
