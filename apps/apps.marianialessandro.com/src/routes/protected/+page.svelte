<svelte:head>
	<title>Area protetta — Apps</title>
</svelte:head>

<section class="protected-home">
	<p class="eyebrow">Area privata</p>
	<h1>Applicazioni protette</h1>
	<p>
		Tutto ciò che vive sotto <code>/protected</code> richiede una sessione autenticata. Le
		applicazioni pubblicate fuori da questo namespace restano invece accessibili senza login.
	</p>
</section>

<style>
	.protected-home {
		padding: clamp(2.5rem, 7vw, 5rem) 0;
	}

	.eyebrow {
		margin: 0 0 0.8rem;
		color: var(--accent);
		font-family: var(--font-mono);
		font-size: 0.78rem;
		font-weight: 700;
		letter-spacing: 0.13em;
		text-transform: uppercase;
	}

	h1 {
		margin: 0;
		font-size: clamp(2.5rem, 7vw, 5rem);
		letter-spacing: -0.055em;
		line-height: 0.98;
	}

	p:last-child {
		max-width: 42rem;
		margin: 1.5rem 0 0;
		color: var(--muted);
		font-size: 1.05rem;
		line-height: 1.65;
	}

	code {
		font-family: var(--font-mono);
		font-size: 0.92em;
	}
</style>
