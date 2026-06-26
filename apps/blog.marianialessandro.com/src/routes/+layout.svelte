<script lang="ts">
	import { Footer } from '@marianialessandro/shared';
	import '@marianialessandro/shared/styles.css';
	import BlogHeader from '$lib/components/BlogHeader.svelte';

	type Props = {
		children: import('svelte').Snippet;
	};

	let { children }: Props = $props();
</script>

<div class="app">
	<BlogHeader />

	<main>
		{@render children()}
	</main>

	<Footer name="Alessandro Mariani"></Footer>
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
