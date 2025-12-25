<!-- src/routes/+page.svelte -->
<script lang="ts">
	// Personalizza qui
	const name = 'Alessandro Mariani';
	const role = 'Computer Science Student';

	const bio =
		'After completing my B.Sc. in Computer Science at the University of Pisa, I am currently pursuing an M.Sc. in Computer Science there. I enjoy building real-world software solutions, with a strong interest in systems programming, networking, and sustainability. I like exploring how thoughtful design and optimization can improve both performance and energy efficiency. My goal is to keep learning, experimenting, and creating projects that are technically solid and have real-world impact beyond academic theory.';

	// Tesi
	const bscThesisTitle = 'Guaranteed-latency network traffic: a declarative and sustainable approach';
	const bscThesisPassage =
		`In my B.Sc. thesis, “${bscThesisTitle}”, I explored how to route low-latency traffic through constrained networks while providing end-to-end latency guarantees, using a declarative approach. ` +
		`The work also considers sustainability goals, optimizing routing decisions to reduce energy costs and carbon footprint without compromising timing constraints.`;

	// PROGETTI: modifica liberamente questa lista
	type Project = {
		title: string;
		description: string;
		tags?: string[];
		links?: { label: string; href: string }[];
	};

	const projects: Project[] = [
		{
			title: 'Project One',
			description:
				'Short description of what it does, why you built it, and what makes it interesting (2–3 lines).',
			tags: ['SvelteKit', 'TypeScript', 'Web'],
			links: [
				{ label: 'GitHub', href: 'https://github.com/marianialessandro' },
				{ label: 'Live demo', href: 'https://example.com' }
			]
		},
		{
			title: 'Project Two',
			description:
				'Another project: highlight the core idea, the hardest part, or a measurable result (performance, features, etc.).',
			tags: ['Networking', 'C', 'Linux'],
			links: [{ label: 'GitHub', href: 'https://github.com/marianialessandro' }]
		},
		{
			title: 'Project Three',
			description:
				'If you have a thesis-related prototype or tool, this is a great place to show it with a concise explanation.',
			tags: ['Research', 'Sustainability'],
			links: [{ label: 'Read more', href: 'https://example.com' }]
		}
	];

	const photo = '/images/laureaMeSquare.png';
	const email = 'mailto:alessandro@marianialessandro.com';
	const github = 'https://github.com/marianialessandro';
	const linkedin = 'https://www.linkedin.com/in/alessandro-mariani-7a53981aa/';
</script>

<svelte:head>
	<title>{name} — Portfolio</title>
	<meta name="description" content={`${name} · ${role}. Portfolio, progetti e contatti.`} />
</svelte:head>

<a class="skip" href="#content">Skip to content</a>

<main id="content">
	<section class="hero" aria-labelledby="hero-title">
		<div class="hero-copy">
			<p class="eyebrow">Hi! 👋 I&apos;m</p>
			<h1 id="hero-title">{name}</h1>
			<p class="role">{role}</p>
			<p class="lede">{bio}</p>

			<nav class="social" aria-label="Social links">
				<a href={github} target="_blank" rel="noreferrer" aria-label="GitHub" class="icon">
					<svg viewBox="0 0 24 24" aria-hidden="true">
						<path
							d="M12 .5a12 12 0 0 0-3.79 23.4c.6.11.82-.26.82-.58v-2.03c-3.34.73-4.04-1.61-4.04-1.61-.55-1.39-1.34-1.76-1.34-1.76-1.09-.75.08-.74.08-.74 1.2.08 1.83 1.24 1.83 1.24 1.07 1.84 2.81 1.31 3.5 1 .11-.78.42-1.31.76-1.61-2.66-.3-5.46-1.33-5.46-5.93 0-1.31.47-2.38 1.24-3.22-.12-.3-.54-1.52.12-3.18 0 0 1.01-.32 3.3 1.23a11.5 11.5 0 0 1 3-.4c1.02 0 2.05.14 3 .4 2.28-1.55 3.29-1.23 3.29-1.23.66 1.66.24 2.88.12 3.18.77.84 1.24 1.91 1.24 3.22 0 4.61-2.8 5.62-5.47 5.92.43.38.81 1.1.81 2.22v3.29c0 .32.21.69.83.57A12 12 0 0 0 12 .5z"
						/>
					</svg>
				</a>

				<a href={linkedin} target="_blank" rel="noreferrer" aria-label="LinkedIn" class="icon">
					<svg viewBox="0 0 24 24" aria-hidden="true">
						<path
							d="M4.98 3.5a2.5 2.5 0 1 1 0 5.001 2.5 2.5 0 0 1 0-5zM3 9h4v12H3V9zm7 0h3.8v1.7h.05c.53-1 1.83-2.05 3.77-2.05C21 8.65 22 10.82 22 13.62V21h-4v-6.19c0-1.47-.03-3.37-2.06-3.37-2.06 0-2.38 1.6-2.38 3.26V21H10V9z"
						/>
					</svg>
				</a>

				<a href={email} aria-label="Email" class="icon">
					<svg viewBox="0 0 24 24" aria-hidden="true">
						<path
							d="M20 4H4a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V6a2 2 0 0 0-2-2zm0 4-8 5-8-5V6l8 5 8-5v2z"
						/>
					</svg>
				</a>
			</nav>
		</div>

		<figure class="portrait" aria-label="Portrait">
			<div class="portrait-frame">
				<img src={photo} alt={`Foto di ${name}`} width="320" height="320" loading="eager" />
			</div>
		</figure>
	</section>

	<section class="thesis" id="thesis" aria-labelledby="thesis-title">
		<div class="card">
			<p class="kicker">B.Sc. Thesis</p>
			<h2 id="thesis-title">{bscThesisTitle}</h2>
			<p class="thesis-lede">{bscThesisPassage}</p>

			<div class="meta" aria-label="Topics">
				<span class="chip">Networking</span>
				<span class="chip">Declarative systems</span>
				<span class="chip">Sustainability</span>
			</div>
		</div>
	</section>

	<section class="contact" id="contact" aria-labelledby="contact-title">
		<div class="card">
			<h2 id="contact-title">Get in touch</h2>
			<p>Want to chat or collaborate? Message me on LinkedIn or send an email.</p>

			<div class="cta-row contact-cta">
				<a class="btn primary" href={email}>Email me</a>
				<a class="btn ghost" href={linkedin} target="_blank" rel="noreferrer">LinkedIn</a>
			</div>
		</div>
	</section>
</main>

<style>
	.skip {
		position: absolute;
		left: -999px;
		top: 0.75rem;
		z-index: 9999;
		padding: 0.6rem 0.9rem;
		background: var(--bg);
		border: 1px solid var(--line);
		border-radius: 999px;
		box-shadow: var(--shadow);
	}

	.skip:focus {
		left: 0.75rem;
	}

	main {
		width: var(--container);
		margin: 0 auto;
		padding: clamp(1.25rem, 3vw, 2rem) 0 3.5rem;
	}

	.hero {
		display: grid;
		gap: clamp(1.5rem, 5vw, 3rem);
		align-items: center;
		padding: clamp(1.5rem, 5vw, 3rem) 0;
		border-bottom: 1px solid var(--line);
	}

	@media (min-width: 900px) {
		.hero {
			grid-template-columns: 1.2fr 0.8fr;
		}
	}

	.eyebrow {
		margin: 0 0 0.5rem 0;
		font-size: 0.95rem;
		color: var(--muted);
		letter-spacing: 0.02em;
	}

	h1 {
		margin: 0;
		font-size: clamp(2.1rem, 4vw, 3.2rem);
		line-height: 1.06;
		letter-spacing: -0.04em;
		text-wrap: balance;
	}

	.role {
		margin: 0.6rem 0 0 0;
		font-size: clamp(1.05rem, 2vw, 1.2rem);
		color: var(--muted);
	}

	.lede {
		margin: 1rem 0 0 0;
		font-size: clamp(1rem, 1.6vw, 1.125rem);
		line-height: 1.75;
		max-width: 62ch;
		color: var(--fg);
	}

	.social {
		margin-top: 1.1rem;
		display: flex;
		gap: 0.5rem;
		align-items: center;
	}

	.icon {
		display: inline-grid;
		place-items: center;
		width: 42px;
		height: 42px;
		border-radius: 999px;
		border: 1px solid rgba(0, 0, 0, 0.12);
		background: #fff;
		text-decoration: none;
		transition: transform 140ms ease, box-shadow 140ms ease, border-color 140ms ease;
	}

	.icon:hover {
		transform: translateY(-1px);
		box-shadow: 0 10px 20px rgba(0, 0, 0, 0.06);
		border-color: rgba(0, 0, 0, 0.18);
	}

	.icon svg {
		width: 18px;
		height: 18px;
		fill: currentColor;
	}

	.portrait {
		margin: 0;
		display: grid;
		place-items: center;
	}

	.portrait-frame {
		position: relative;
		width: min(320px, 72vw);
		aspect-ratio: 1 / 1;
		border-radius: 28px;
		overflow: hidden;
		border: 1px solid rgba(0, 0, 0, 0.1);
		box-shadow: var(--shadow);
	}

	.portrait-frame::before {
		content: '';
		position: absolute;
		inset: -40%;
		background: radial-gradient(circle at 30% 20%, rgba(255, 62, 0, 0.22), transparent 45%),
			radial-gradient(circle at 80% 70%, rgba(0, 0, 0, 0.12), transparent 55%);
		transform: rotate(10deg);
		pointer-events: none;
	}

	.portrait img {
		position: relative;
		width: 100%;
		height: 100%;
		object-fit: cover;
		display: block;
	}

	section.thesis,
	section.projects,
	section.contact {
		padding: clamp(1.25rem, 3vw, 2rem) 0;
	}

	.card {
		background: #fff;
		border: 1px solid var(--line);
		border-radius: var(--radius);
		box-shadow: var(--shadow);
		padding: clamp(1.25rem, 3vw, 2rem);
	}

	.kicker {
		margin: 0 0 0.5rem 0;
		font-size: 0.9rem;
		font-weight: 700;
		letter-spacing: 0.06em;
		text-transform: uppercase;
		color: var(--muted);
	}

	h2 {
		margin: 0;
		font-size: clamp(1.35rem, 2.2vw, 1.75rem);
		line-height: 1.2;
		letter-spacing: -0.03em;
		text-wrap: balance;
	}

	.thesis-lede {
		margin: 0.9rem 0 0 0;
		font-size: clamp(1rem, 1.6vw, 1.125rem);
		line-height: 1.75;
		max-width: 75ch;
		color: var(--fg);
	}

	.meta {
		margin-top: 1.1rem;
		display: flex;
		gap: 0.5rem;
		flex-wrap: wrap;
	}

	.chip {
		display: inline-flex;
		align-items: center;
		padding: 0.35rem 0.6rem;
		border-radius: 999px;
		border: 1px solid rgba(0, 0, 0, 0.1);
		color: var(--muted);
		font-size: 0.9rem;
		background: rgba(0, 0, 0, 0.02);
	}

	/* Projects */
	.section-head {
		margin-bottom: 1rem;
	}

	.section-lede {
		margin: 0.75rem 0 0 0;
		font-size: clamp(1rem, 1.6vw, 1.125rem);
		line-height: 1.75;
		max-width: 75ch;
		color: var(--fg);
	}

	.projects-grid {
		display: grid;
		gap: 1rem;
		grid-template-columns: 1fr;
	}

	@media (min-width: 800px) {
		.projects-grid {
			grid-template-columns: repeat(2, 1fr);
		}
	}

	@media (min-width: 1100px) {
		.projects-grid {
			grid-template-columns: repeat(3, 1fr);
		}
	}

	.project-card {
		display: flex;
		flex-direction: column;
		min-height: 100%;
	}

	.project-title {
		margin: 0;
		font-size: 1.05rem;
		letter-spacing: -0.02em;
	}

	.project-desc {
		margin: 0.6rem 0 0 0;
		color: var(--fg);
		line-height: 1.7;
	}

	.project-links {
		margin-top: 1rem;
		display: flex;
		flex-wrap: wrap;
		gap: 0.5rem;
	}

	.project-link {
		display: inline-flex;
		align-items: center;
		padding: 0.45rem 0.7rem;
		border-radius: 999px;
		border: 1px solid rgba(0, 0, 0, 0.12);
		text-decoration: none;
		color: var(--fg);
		background: #fff;
		transition: transform 140ms ease, box-shadow 140ms ease, border-color 140ms ease;
	}

	.project-link:hover {
		transform: translateY(-1px);
		box-shadow: 0 10px 20px rgba(0, 0, 0, 0.06);
		border-color: rgba(0, 0, 0, 0.18);
		color: var(--accent);
	}

	/* Contact */
	.contact p {
		margin: 0.8rem 0 0 0;
		font-size: clamp(1rem, 1.6vw, 1.125rem);
		line-height: 1.75;
		max-width: 65ch;
		color: var(--fg);
	}

	.contact-cta {
		margin-top: 1.2rem;
	}

	.cta-row {
		margin-top: 1.35rem;
		display: flex;
		gap: 0.75rem;
		flex-wrap: wrap;
	}

	.btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		padding: 0.75rem 1rem;
		border-radius: 999px;
		font-weight: 700;
		letter-spacing: -0.01em;
		text-decoration: none;
		border: 1px solid rgba(0, 0, 0, 0.12);
		background: #fff;
		color: var(--fg);
		transition: transform 140ms ease, box-shadow 140ms ease, border-color 140ms ease;
	}

	.btn:hover {
		transform: translateY(-1px);
		box-shadow: 0 10px 20px rgba(0, 0, 0, 0.06);
		border-color: rgba(0, 0, 0, 0.18);
	}

	.btn.primary {
		background: var(--fg);
		border-color: var(--fg);
		color: #fff;
	}

	.btn.primary:hover {
		box-shadow: 0 12px 24px rgba(0, 0, 0, 0.12);
	}

	.btn.ghost {
		background: #fff;
	}

	@media (prefers-reduced-motion: reduce) {
		.btn,
		.icon,
		.project-link {
			transition: none;
		}
		.btn:hover,
		.icon:hover,
		.project-link:hover {
			transform: none;
		}
	}
</style>
