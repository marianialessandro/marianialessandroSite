<script lang="ts">
	import { page } from '$app/state';
	import { Footer } from '@marianialessandro/shared';
	import '@marianialessandro/shared/styles.css';

	let { children } = $props();
</script>

<div class="app-shell">
	<main class:wide={page.url.pathname.startsWith('/promptmanager')}>
		{@render children()}
	</main>

	<Footer name="Alessandro Mariani" />
</div>

<style>
	.app-shell {
		display: flex;
		flex-direction: column;
		min-height: 100vh;
	}

	main {
		flex: 1;
		display: flex;
		flex-direction: column;
		padding: 1rem;
		width: 100%;
		max-width: 64rem;
		margin: 0 auto;
		box-sizing: border-box;
	}

	main.wide {
		max-width: min(96rem, 100%);
	}
</style>
