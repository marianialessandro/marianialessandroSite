<script lang="ts">
	import { Footer } from '@marianialessandro/shared';
	import '@marianialessandro/shared/styles.css';
	import BlogHeader from '$lib/components/BlogHeader.svelte';
	import { page } from '$app/state';

	type Props = {
		children: import('svelte').Snippet;
	};

	let { children }: Props = $props();

	let isAdmin = $derived(page.url.pathname.startsWith('/admin'));
</script>

<div class="app">
	{#if !isAdmin}
		<BlogHeader />
	{/if}

	<main>
		{@render children()}
	</main>

	{#if !isAdmin}
		<Footer name="Alessandro Mariani"></Footer>
	{/if}
</div>

<style>
	.app {
		display: flex;
		flex-direction: column;
		min-height: 100vh;
	}

	main {
		flex: 1;
		display: flex;
		flex-direction: column;
		width: 100%;
		margin: 0 auto;
		box-sizing: border-box;
	}
</style>
