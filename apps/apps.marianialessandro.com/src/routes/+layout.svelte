<script lang="ts">
	import { Footer } from '@marianialessandro/shared';
	import '@marianialessandro/shared/styles.css';

	let { children } = $props();
</script>

<div class="app-shell">
	<header class="site-header">
		<a class="brand" href="/" aria-label="Apps di Alessandro Mariani, pagina iniziale">
			<span class="brand-mark" aria-hidden="true">A</span>
			<span>apps.marianialessandro.com</span>
		</a>
		<a class="home-link" href="https://marianialessandro.com">Sito principale</a>
	</header>

	<main>
		{@render children()}
	</main>

	<Footer name="Alessandro Mariani" />
</div>

<style>
	:global(:root) {
		--bg: #f5f4f0;
		--fg: #151515;
		--muted: #62605a;
		--line: #d9d6ce;
		--accent: #d44a20;
	}

	.app-shell {
		display: flex;
		flex-direction: column;
		min-height: 100vh;
		background:
			radial-gradient(circle at 85% 0%, rgba(212, 74, 32, 0.1), transparent 28rem), var(--bg);
	}

	.site-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1rem;
		width: min(1120px, calc(100% - 2rem));
		margin: 0 auto;
		padding: 1.25rem 0;
	}

	.brand {
		display: inline-flex;
		align-items: center;
		gap: 0.7rem;
		font-weight: 700;
		letter-spacing: -0.02em;
		text-decoration: none;
	}

	.brand-mark {
		display: grid;
		width: 2rem;
		height: 2rem;
		place-items: center;
		border-radius: 0.65rem;
		background: var(--fg);
		color: var(--bg);
		font-size: 0.85rem;
	}

	.home-link {
		color: var(--muted);
		font-size: 0.9rem;
		font-weight: 600;
	}

	main {
		flex: 1;
		width: min(1120px, calc(100% - 2rem));
		margin: 0 auto;
	}

	@media (max-width: 560px) {
		.brand span:last-child {
			display: none;
		}
	}
</style>
