<script lang="ts">
	import { page } from '$app/state';
	import { Footer } from '@marianialessandro/shared';
	import '@marianialessandro/shared/styles.css';

	let { children } = $props();
	const isPromptManager = $derived(page.url.pathname.startsWith('/promptmanager'));
</script>

<div class:fullscreen={isPromptManager} class="app-shell">
	<main class:wide={isPromptManager} class:fullscreen={isPromptManager}>
		{@render children()}
	</main>

	{#if !isPromptManager}
		<Footer name="Alessandro Mariani" />
	{/if}
</div>

<style>
	.app-shell {
		display: flex;
		flex-direction: column;
		min-height: 100vh;
	}

	.app-shell.fullscreen {
		height: 100vh;
		overflow: hidden;
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
		max-width: none;
		padding: 0;
	}

	main.fullscreen {
		height: 100vh;
		min-height: 0;
		overflow: hidden;
	}
</style>
