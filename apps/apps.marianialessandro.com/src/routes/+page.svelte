<svelte:head>
	<title>Apps — Alessandro Mariani</title>
	<meta
		name="description"
		content="Applicazioni e strumenti digitali creati da Alessandro Mariani."
	/>
	<meta property="og:title" content="Apps — Alessandro Mariani" />
	<meta
		property="og:description"
		content="Applicazioni e strumenti digitali creati da Alessandro Mariani."
	/>
	<meta property="og:type" content="website" />
	<meta property="og:url" content="https://apps.marianialessandro.com/" />
	<meta property="og:image" content="https://apps.marianialessandro.com/og.png" />
	<meta property="og:image:width" content="1200" />
	<meta property="og:image:height" content="630" />
	<meta property="og:image:alt" content="Apps — Alessandro Mariani" />
	<meta name="twitter:card" content="summary_large_image" />
	<meta name="twitter:title" content="Apps — Alessandro Mariani" />
	<meta
		name="twitter:description"
		content="Applicazioni e strumenti digitali creati da Alessandro Mariani."
	/>
	<meta name="twitter:image" content="https://apps.marianialessandro.com/og.png" />
</svelte:head>

<section class="hero">
	<p class="eyebrow">Workspace digitale</p>
	<h1>Strumenti semplici.<br />Pensati per essere utili.</h1>
	<p class="intro">
		Questo è lo spazio dedicato alle applicazioni di Alessandro Mariani. Nuovi strumenti verranno
		pubblicati qui e saranno accessibili da un unico posto.
	</p>
</section>

<section class="applications" aria-labelledby="applications-title">
	<div class="section-heading">
		<h2 id="applications-title">Applicazioni</h2>
		<span class="status"><span aria-hidden="true"></span> In costruzione</span>
	</div>

	<div class="empty-state">
		<div class="empty-icon" aria-hidden="true">
			<span></span><span></span><span></span><span></span>
		</div>
		<div>
			<h3>Il primo strumento sta arrivando</h3>
			<p>Questa area raccoglierà applicazioni, utility e progetti interattivi.</p>
		</div>
	</div>
</section>

<style>
	.hero {
		padding: clamp(5rem, 12vw, 9rem) 0 clamp(4rem, 9vw, 7rem);
	}

	.eyebrow {
		margin: 0 0 1.25rem;
		color: var(--accent);
		font-family: var(--font-mono);
		font-size: 0.78rem;
		font-weight: 700;
		letter-spacing: 0.13em;
		text-transform: uppercase;
	}

	h1 {
		max-width: 900px;
		margin: 0;
		font-size: clamp(3rem, 8vw, 6.75rem);
		font-weight: 650;
		letter-spacing: -0.065em;
		line-height: 0.94;
	}

	.intro {
		max-width: 620px;
		margin: 2rem 0 0 auto;
		color: var(--muted);
		font-size: clamp(1.05rem, 2vw, 1.3rem);
		line-height: 1.6;
	}

	.applications {
		padding-bottom: 6rem;
	}

	.section-heading {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1rem;
		padding-bottom: 1rem;
		border-bottom: 1px solid var(--line);
	}

	h2 {
		margin: 0;
		font-size: 1rem;
		font-weight: 700;
		letter-spacing: -0.02em;
	}

	.status {
		display: inline-flex;
		align-items: center;
		gap: 0.5rem;
		color: var(--muted);
		font-size: 0.82rem;
	}

	.status span {
		width: 0.5rem;
		height: 0.5rem;
		border-radius: 50%;
		background: var(--accent);
		box-shadow: 0 0 0 4px rgba(212, 74, 32, 0.12);
	}

	.empty-state {
		display: grid;
		grid-template-columns: auto 1fr;
		align-items: center;
		gap: clamp(1.5rem, 4vw, 3rem);
		min-height: 250px;
		padding: clamp(1.5rem, 4vw, 3rem);
		border-bottom: 1px solid var(--line);
	}

	.empty-icon {
		display: grid;
		grid-template-columns: repeat(2, 1fr);
		gap: 0.45rem;
		width: 4.5rem;
	}

	.empty-icon span {
		aspect-ratio: 1;
		border: 1px solid var(--fg);
		border-radius: 0.55rem;
	}

	.empty-icon span:first-child {
		background: var(--fg);
	}

	h3 {
		margin: 0 0 0.5rem;
		font-size: clamp(1.35rem, 3vw, 2rem);
		font-weight: 600;
		letter-spacing: -0.035em;
	}

	.empty-state p {
		margin: 0;
		color: var(--muted);
	}

	@media (max-width: 600px) {
		.hero {
			padding-top: 3.75rem;
		}

		.intro {
			margin-left: 0;
		}

		.empty-state {
			grid-template-columns: 1fr;
			min-height: 290px;
		}
	}
</style>
