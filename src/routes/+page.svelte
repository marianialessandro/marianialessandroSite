<script lang="ts">
	// Personalizza qui
	const name = 'Alessandro Mariani';
	const role = 'Software Engineer';
	/* const bio =
		'Progetto interfacce semplici, veloci e accessibili. Lavoro con SvelteKit e design system leggeri.'; */

    const bio =
		'I am a Computer Science student from the University of Pisa with a long-standing passion for algorithms and software engineering. I have always engaged in challenging my skills with personal projects that could potentially have a real-world impact, beyond academic theory.';

	const photo = 'https://marianialessandro.com/static/Profile.JPG';
	const email = 'mailto:alessandro@marianialessandro.com';
	const github = 'https://github.com/marianialessandro';
	const linkedin = 'https://www.linkedin.com/in/alessandro-mariani-7a53981aa/';
</script>

<svelte:head>
	<title>{name} — Portfolio</title>
	<meta name="description" content={`${name} · ${role}. Portfolio, progetti e contatti.`} />
</svelte:head>

<section class="hero">
	<div class="copy">
		<p class="eyebrow">Hi! 👋 I'm</p>
		<h1>{name}</h1>
		<p class="role">{role}</p>
		<p class="lede">{bio}</p>

		<nav class="social" aria-label="Social">
			<a href={github} target="_blank" rel="noreferrer" aria-label="GitHub" class="icon">
				<svg viewBox="0 0 24 24" aria-hidden="true"
					><path
						d="M12 .5a12 12 0 0 0-3.79 23.4c.6.11.82-.26.82-.58v-2.03c-3.34.73-4.04-1.61-4.04-1.61-.55-1.39-1.34-1.76-1.34-1.76-1.09-.75.08-.73.08-.73 1.2.08 1.83 1.24 1.83 1.24 1.07 1.83 2.81 1.3 3.49.99.11-.78.42-1.31.76-1.61-2.66-.3-5.47-1.33-5.47-5.93 0-1.31.47-2.39 1.24-3.23-.12-.3-.54-1.52.12-3.17 0 0 1.01-.32 3.31 1.23a11.5 11.5 0 0 1 6.02 0c2.3-1.55 3.31-1.23 3.31-1.23.66 1.65.24 2.87.12 3.17.77.84 1.24 1.92 1.24 3.23 0 4.61-2.81 5.62-5.49 5.92.43.37.81 1.1.81 2.22v3.29c0 .32.21.69.83.57A12 12 0 0 0 12 .5z"
					/></svg
				>
			</a>
			<a href={linkedin} target="_blank" rel="noreferrer" aria-label="LinkedIn" class="icon">
				<svg viewBox="0 0 24 24" aria-hidden="true"
					><path
						d="M4.98 3.5a2.5 2.5 0 1 1 0 5.001 2.5 2.5 0 0 1 0-5zM3 9h4v12H3zM14.5 9A4.5 4.5 0 0 1 19 13.5V21h-4v-6c0-1.38-1.12-2.5-2.5-2.5S10 13.62 10 15v6H6v-12h4v1.6c.7-1 1.95-1.6 3.5-1.6z"
					/></svg
				>
			</a>
		</nav>
	</div>

	<div class="portrait">
		<img src={photo} alt={`Foto di ${name}`} width="320" height="320" loading="eager" />
	</div>
</section>

<section class="contact" id="contact">
	<h2>Get in Touch</h2>
	<p>
		Want to chat or collaborate? Just shoot me a message
		<a href={linkedin} target="_blank" rel="noreferrer" class="no-arrow">on LinkedIn</a>
		or <a href={email} class="no-arrow">via email</a>,
		and I’ll respond whenever I can.
	</p>
</section>

<style>
	:root {
		--bg: #ffffff;
		--fg: #000000; /* TESTO SEMPRE NERO */
		--muted: #6b7280;
		--line: #e5e7eb;
		--brand: #ff3e00;
	}

	section.hero {
		display: grid;
		grid-template-columns: 1fr;
		gap: 2.5rem;
		align-items: center;
		max-width: 1000px;
		margin: 0 auto;
		padding: clamp(2rem, 6vw, 5rem) 1.25rem;
		min-height: 60vh;
		color: var(--fg);
	}
	@media (min-width: 880px) {
		section.hero {
			grid-template-columns: 1.1fr 0.9fr; /* testo | foto */
		}
	}

	.copy .eyebrow {
		font-size: 0.9rem;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		color: var(--muted);
		margin: 0 0 0.5rem 0;
	}

	h1 {
		font-size: clamp(2rem, 6vw, 3.5rem);
		line-height: 1.05;
		margin: 0 0 0.25rem 0;
	}

	.role {
		font-size: clamp(1.05rem, 2.2vw, 1.2rem);
		color: var(--muted);
		margin: 0 0 1.25rem 0;
	}

	.lede {
		font-size: clamp(1rem, 1.6vw, 1.125rem);
		line-height: 1.6;
		max-width: 60ch;
		margin: 0 0 1.25rem 0;
	}
	.social {
		display: flex;
		gap: 0.75rem;
		margin-top: 0.25rem;
	}
	.icon {
		width: 40px;
		height: 40px;
		border-radius: 999px;
		display: grid;
		place-items: center;
		border: 1px solid var(--line);
		color: var(--fg);
		text-decoration: none;
	}
	.icon svg {
		width: 20px;
		height: 20px;
		fill: currentColor;
	}
	.icon:hover {
		transform: translateY(-1px);
	}

	.portrait {
		display: grid;
		place-items: center;
	}
	.portrait img {
		border-radius: 50%;
		width: clamp(160px, 28vw, 320px);
		height: clamp(160px, 28vw, 320px);
		object-fit: cover;
		box-shadow: 0 10px 30px rgba(0, 0, 0, 0.12);
		border: 1px solid var(--line);
	}

	/* --- Get in Touch --- */
	section.contact {
		max-width: 900px;
		margin: 0 auto;
		padding: clamp(2rem, 6vw, 5rem) 1.25rem;
		border-top: 1px solid var(--line);
	}

	section.contact h2 {
		font-size: clamp(1.25rem, 2.4vw, 1.5rem);
		margin: 0 0 0.75rem 0;
		letter-spacing: 0.02em;
		text-wrap: balance;
	}

	section.contact p {
		font-size: clamp(1rem, 1.7vw, 1.125rem);
		line-height: 1.7;
		max-width: 60ch;
		margin: 0;
		color: var(--fg); /* sempre nero */
	}

	/* Link “cta” con sottolineatura accent color e freccia */
	section.contact a {
		color: var(--fg);
		font-weight: 600;
		text-decoration: underline;
		text-decoration-thickness: 2px;
		text-underline-offset: 0.2em;
		text-decoration-color: rgba(255, 62, 0, 0.45); /* var(--brand) soft */
		transition:
			text-decoration-color 140ms ease,
			transform 140ms ease;
		position: relative;
	}

	section.contact a::after {
		content: '↗';
		margin-left: 0.25rem;
		opacity: 0.6;
		transition:
			transform 140ms ease,
			opacity 140ms ease;
	}

	/* section.contact a:hover {
		text-decoration-color: var(--brand);
		transform: translateY(-1px);
	}
	section.contact a:hover::after {
		transform: translateY(-1px);
		opacity: 1;
	} */

	section.contact a:focus-visible {
		outline: 2px solid var(--brand);
		outline-offset: 3px;
	}

	/* opzionale: centratura su schermi piccoli */
	@media (max-width: 520px) {
		section.contact {
			text-align: center;
		}
		section.contact p {
			margin-left: auto;
			margin-right: auto;
		}
	}

	/* rispetto per chi riduce le animazioni */
	@media (prefers-reduced-motion: reduce) {
		section.contact a {
			transition: none;
		}
	}

    section.contact .no-arrow::after { content: none; }

</style>
