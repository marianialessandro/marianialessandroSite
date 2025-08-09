<script lang="ts">
	import { page } from '$app/state';
</script>

<header class="site-header">
	<div class="container">
		<a class="brand" href="/" aria-label="Home">LB</a>

		<nav aria-label="Primary">
			<ul>
				<li aria-current={page.url.pathname === '/' ? 'page' : undefined}>
					<a href="/">Home</a>
				</li>
				<li aria-current={page.url.pathname.startsWith('/blog') ? 'page' : undefined}>
					<a href="/blog">Blog</a>
				</li>
				<li aria-current={page.url.pathname === '/about' ? 'page' : undefined}>
					<a href="/about">About</a>
				</li>
			</ul>
		</nav>
	</div>
</header>

<style>
	:root {
		color-scheme: light;
	}

	.site-header {
		position: sticky;
		top: 0;
		z-index: 50;
		background: var(--color-bg, #fff);
		border-bottom: 1px solid var(--color-border, #e5e7eb);
	}

	.container {
		max-width: var(--column-width, 44rem);
		margin: 0 auto;
		padding: 0.9rem 1.2rem;
		display: flex;
		align-items: center;
		gap: 1rem;
	}
	/* centra il nav tra brand e lato destro */
	.container nav {
		margin-inline: auto;
	}

	/* brand */
	.brand {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 2.25rem;
		height: 2.25rem;
		border: 1px solid var(--color-border, #e5e7eb);
		border-radius: 8px;
		font-weight: 700;
		letter-spacing: -0.01em;
		color: var(--color-text, #0a0a0a);
		text-decoration: none;
	}
	.brand:hover {
		background: #f9fafb;
	}

	/* NAV — box uniformi e allineamento perfetto */
	nav ul {
		display: flex;
		align-items: center;
		gap: 1.1rem;
		list-style: none;
		margin: 0;
		padding: 0;
	}
	nav li {
		display: flex;
		height: 2.25rem; /* altezza fissa per ogni voce */
	}
	nav a {
		/* box stabile + centrato */
		position: relative;
		display: grid;
		place-items: center;
		height: 100%;
		padding: 0 0.5rem;
		line-height: 1;
		font-weight: 500;
		color: var(--color-text, #0a0a0a);
		text-decoration: none; /* niente underline nativa */
	}

	/* “underline” disegnata a mano, identica per tutti */
	nav a::after {
		content: '';
		position: absolute;
		left: 0.5rem;
		right: 0.5rem;
		bottom: 0;
		height: 1px;
		background: transparent;
	}
	/* hover: mostra la linea */
	nav a:hover::after {
		background: rgba(0, 0, 0, 0.35);
	}

	/* pagina corrente: bold + linea piena */
	li[aria-current='page'] a {
		font-weight: 700;
	}
	li[aria-current='page'] a::after {
		background: currentColor;
	}

	@media (max-width: 640px) {
		nav ul {
			gap: 0.75rem;
		}
	}
</style>
