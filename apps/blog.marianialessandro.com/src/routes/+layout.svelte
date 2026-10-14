<script lang="ts">
	import '@marianialessandro/shared/styles.css';
	import '$lib/styles/blog.css';
	import BlogHeader from '$lib/components/BlogHeader.svelte';
	import { page } from '$app/state';

	type Props = {
		children: import('svelte').Snippet;
	};

	let { children }: Props = $props();

	let isAdmin = $derived(page.url.pathname.startsWith('/admin'));
</script>

<svelte:head>
	<meta name="color-scheme" content="light" />
	<meta name="theme-color" content="#fafafa" />
</svelte:head>

<a class="skip" href="#main">Skip to content</a>
<div class="app">
	{#if !isAdmin}
		<BlogHeader />
	{/if}

	<main id="main" tabindex="-1">
		{@render children()}
	</main>

	{#if !isAdmin}
		<footer class="blog-footer">© {new Date().getFullYear()} Alessandro Mariani</footer>
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
