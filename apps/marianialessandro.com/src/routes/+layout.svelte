<script lang="ts">
	import { Footer } from '@marianialessandro/shared';
	import '@marianialessandro/shared/styles.css';

	type Props = {
		children: import('svelte').Snippet;
	};

	let { children }: Props = $props();
</script>

<div class="app">
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
		padding: 1rem;
		width: 100%;
		max-width: 64rem;
		margin: 0 auto;
		box-sizing: border-box;
	}
</style>
