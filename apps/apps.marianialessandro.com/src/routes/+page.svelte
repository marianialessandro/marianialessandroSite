<svelte:head>
	<title>apps.marianialessandro.com</title>
	<meta
		name="description"
		content="Hub applicazioni di Alessandro Mariani su apps.marianialessandro.com."
	/>
</svelte:head>

<section class="page">
	<header class="hero">
		<p class="eyebrow">Apps</p>
		<h1>apps.marianialessandro.com</h1>
		<p class="copy">
			Nuovo progetto SvelteKit inizializzato nel monorepo e pronto a usare i componenti condivisi
			di <code>@marianialessandro/shared</code>.
		</p>
	</header>
</section>

<style>
	.page {
		width: var(--container);
		margin: 0 auto;
		padding: clamp(1.25rem, 3vw, 2rem) 0 3.5rem;
	}

	.hero {
		position: relative;
		overflow: hidden;
		padding: clamp(1.5rem, 4vw, 2rem);
		border: 1px solid var(--line);
		border-radius: 2rem;
		background:
			linear-gradient(180deg, rgba(255, 255, 255, 0.95) 0%, rgba(252, 252, 251, 0.98) 100%);
		box-shadow: var(--shadow);
	}

	.hero::before {
		content: '';
		position: absolute;
		inset: 0;
		background:
			linear-gradient(90deg, rgba(0, 0, 0, 0.03) 1px, transparent 1px),
			linear-gradient(rgba(0, 0, 0, 0.03) 1px, transparent 1px);
		background-size: 24px 24px;
		mask-image: linear-gradient(to bottom, rgba(0, 0, 0, 0.18), rgba(0, 0, 0, 0));
		pointer-events: none;
	}

	.eyebrow,
	h1,
	.copy {
		position: relative;
		z-index: 1;
	}

	.eyebrow {
		margin: 0 0 0.75rem;
		font-size: 0.875rem;
		font-weight: 700;
		letter-spacing: 0.16em;
		text-transform: uppercase;
		color: var(--muted);
	}

	h1 {
		margin: 0;
		font-size: clamp(2.1rem, 5vw, 3.5rem);
		line-height: 0.96;
		letter-spacing: -0.05em;
		word-break: break-word;
	}

	.copy {
		max-width: 42rem;
		margin: 1.25rem 0 0;
		font-size: clamp(1rem, 2vw, 1.1rem);
		line-height: 1.65;
		color: var(--muted);
	}

	code {
		font-size: 0.95em;
	}

	@media (max-width: 640px) {
		.hero {
			border-radius: 1.5rem;
		}

		h1 {
			font-size: clamp(1.55rem, 7vw, 2rem);
			letter-spacing: -0.035em;
		}
	}
</style>
