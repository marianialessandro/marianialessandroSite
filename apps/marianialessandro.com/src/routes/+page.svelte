<script lang="ts">
	const name = 'Alessandro Mariani';
	const role = 'Computer Science Student';
	const bio =
		'Currently an M.Sc. student in Computer Science at the University of Pisa, following my undergraduate studies there. I specialize in systems programming, networking, sustainable computing, and algorithmics. I am deeply interested in exploring how thoughtful design and optimization can drive both performance and energy efficiency. I enjoy the technical challenge of engineering efficient, working code.';

	const thesisTitle = 'Guaranteed-latency network traffic: a declarative and sustainable approach';
	const thesisDescription =
		'For my B.Sc. thesis, I investigated a declarative approach to network routing that secures timing guarantees while simultaneously minimizing energy costs and carbon footprint.';

	const photo = '/images/laureaMeSquare.png';
	const cvIt = '/documents/cvita.pdf';
	const cvEn = '/documents/cveng.pdf';
	const email = 'mailto:alessandro@marianialessandro.com';
	const github = 'https://github.com/marianialessandro';
	const linkedin = 'https://www.linkedin.com/in/alessandro-mariani-7a53981aa/';
	const sossoldi = 'https://github.com/RIP-Comm/sossoldi';
</script>

<svelte:head>
	<title>{name} — Portfolio</title>
	<meta
		name="description"
		content={`${name} · ${role}. Portfolio, open source projects, research and contacts.`}
	/>
</svelte:head>

<a class="skip-link" href="#content">Skip to content</a>

<main id="content" class="page-shell">
	<section class="hero" aria-labelledby="hero-title">
		<div class="hero-copy">
			<p class="eyebrow">Hi! 👋 I&apos;m</p>
			<h1 id="hero-title">{name}</h1>
			<p class="role">{role}</p>
			<p class="lede">{bio}</p>

			<nav class="social" aria-label="Social links">
				<a class="text-link" href={github} target="_blank" rel="noreferrer">
					GitHub <span class="arrow" aria-hidden="true">↗</span>
				</a>
				<a class="text-link" href={linkedin} target="_blank" rel="noreferrer">
					LinkedIn <span class="arrow" aria-hidden="true">↗</span>
				</a>
				<a class="text-link" href={email}>
					Email <span class="arrow" aria-hidden="true">↗</span>
				</a>
			</nav>
		</div>

		<figure class="portrait">
			<img src={photo} alt={name} width="640" height="800" loading="eager" />
		</figure>
	</section>

	<section class="work" aria-labelledby="work-title">
		<header class="work-intro">
			<p class="section-kicker">Projects &amp; research</p>
			<h2 id="work-title">A few things I&apos;ve worked on.</h2>
			<p>Selected work across open source software, product development and academic research.</p>
		</header>

		<div class="work-list">
			<article class="work-item">
				<div class="work-item-topline">
					<p class="work-item-type">Open source project</p>
					<span class="work-item-index" aria-hidden="true">01</span>
				</div>

				<h3 class="work-item-title">Sossoldi</h3>

				<div class="work-meta" aria-label="Project details">
					<span>FLUTTER</span>
					<span>CORE CONTRIBUTOR</span>
					<span>15K+ USERS</span>
				</div>

				<div class="work-copy">
					<p>
						Sossoldi is an open-source personal finance application focused on making everyday
						financial management simple and accessible.
					</p>
					<p>
						As a core contributor, I work across feature ideation, database design and UI
						development. I am also contributing to the Open Banking integration through Enable
						Banking, with the goal of synchronizing bank accounts, transactions and net worth
						automatically.
					</p>
				</div>

				<div class="work-actions">
					<a class="text-link" href={sossoldi} target="_blank" rel="noreferrer">
						View on GitHub <span class="arrow" aria-hidden="true">↗</span>
					</a>
				</div>
			</article>

			<article class="work-item">
				<div class="work-item-topline">
					<p class="work-item-type">B.Sc. Thesis</p>
					<span class="work-item-index" aria-hidden="true">02</span>
				</div>

				<h3 class="work-item-title">{thesisTitle}</h3>

				<div class="work-meta" aria-label="Research topics">
					<span>NETWORKING</span>
					<span>DECLARATIVE SYSTEMS</span>
					<span>SUSTAINABILITY</span>
				</div>

				<div class="work-copy">
					<p>{thesisDescription}</p>
				</div>
			</article>
		</div>
	</section>

	<section class="contact-cv" aria-label="Contact and curriculum vitae">
		<section class="final-block" aria-labelledby="contact-title">
			<h2 id="contact-title">Get in touch</h2>
			<p>Want to chat or collaborate? Message me on LinkedIn or send an email.</p>
			<div class="actions">
				<a class="text-link" href={email}>
					Email me <span class="arrow" aria-hidden="true">→</span>
				</a>
				<a class="text-link" href={linkedin} target="_blank" rel="noreferrer">
					LinkedIn <span class="arrow" aria-hidden="true">↗</span>
				</a>
			</div>
		</section>

		<section class="final-block" aria-labelledby="cv-title">
			<h2 id="cv-title">Curriculum vitae</h2>
			<p>Available as PDF in Italian and English.</p>
			<div class="actions">
				<a class="text-link" href={cvIt} target="_blank" rel="noreferrer">
					Open CV (IT) <span class="arrow" aria-hidden="true">↗</span>
				</a>
				<a class="text-link" href={cvEn} target="_blank" rel="noreferrer">
					Open CV (EN) <span class="arrow" aria-hidden="true">↗</span>
				</a>
			</div>
		</section>
	</section>
</main>

<footer>
	<div class="page-shell footer-row">
		<span>{name}</span>
		<span>marianialessandro.com</span>
	</div>
</footer>

<style>
	:global(:root) {
		--portfolio-page-width: 1280px;
		--portfolio-gutter: clamp(1.25rem, 4vw, 4.5rem);
		--portfolio-section-y: clamp(4.5rem, 9vw, 8rem);
	}

	:global(html) {
		scroll-behavior: smooth;
	}

	.skip-link {
		position: fixed;
		top: 1rem;
		left: 1rem;
		z-index: 10;
		padding: 0.7rem 1rem;
		background: var(--bg);
		border: 1px solid var(--line);
		border-radius: 0.5rem;
		transform: translateY(calc(-100% - 2rem));
		transition: transform 160ms ease;
	}

	.skip-link:focus {
		transform: translateY(0);
	}

	.page-shell {
		width: min(calc(100% - (var(--portfolio-gutter) * 2)), var(--portfolio-page-width));
		margin-inline: auto;
	}

	.section-kicker {
		margin: 0;
		font-size: 0.78rem;
		font-weight: 700;
		letter-spacing: 0.12em;
		text-transform: uppercase;
		color: var(--muted);
	}

	.text-link {
		display: inline-flex;
		align-items: center;
		gap: 0.4rem;
		font-weight: 600;
		letter-spacing: -0.02em;
		text-decoration: none;
	}

	.arrow {
		display: inline-block;
		transition: transform 160ms ease;
	}

	.text-link:hover .arrow {
		transform: translate(3px, -2px);
	}

	.hero {
		min-height: min(860px, 88vh);
		display: grid;
		grid-template-columns: repeat(12, minmax(0, 1fr));
		align-items: center;
		gap: clamp(1.5rem, 3vw, 3rem);
		padding-block: clamp(3rem, 8vw, 7rem);
		border-bottom: 1px solid var(--line);
	}

	.hero-copy {
		grid-column: 1 / span 8;
		max-width: none;
		min-width: 0;
	}

	.eyebrow {
		margin: 0 0 1.5rem;
		font-size: 0.92rem;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		color: var(--muted);
	}

	h1 {
		margin: 0;
		max-width: none;
		font-size: clamp(3.8rem, 6.7vw, 6.5rem);
		line-height: 0.94;
		letter-spacing: -0.065em;
		font-weight: 650;
		white-space: nowrap;
	}

	.role {
		margin: 1.6rem 0 0;
		font-size: clamp(1.15rem, 1.7vw, 1.5rem);
		color: var(--muted);
		letter-spacing: -0.025em;
	}

	.lede {
		margin: 1.6rem 0 0;
		max-width: 65ch;
		font-size: clamp(1rem, 1.2vw, 1.08rem);
		line-height: 1.75;
		color: #222832;
	}

	.social {
		display: flex;
		flex-wrap: wrap;
		gap: 1.4rem;
		margin-top: 1.8rem;
	}

	.portrait {
		grid-column: 9 / span 4;
		margin: 0;
		min-width: 0;
	}

	.portrait img {
		display: block;
		width: 100%;
		aspect-ratio: 4 / 5;
		object-fit: cover;
		border-radius: 22px;
	}

	.work {
		padding-block: var(--portfolio-section-y);
		border-bottom: 1px solid var(--line);
	}

	.work-intro {
		max-width: 1040px;
		margin-bottom: clamp(3.5rem, 7vw, 6rem);
	}

	.work-intro h2 {
		margin: 0.9rem 0 0;
		font-size: clamp(2.5rem, 5vw, 5rem);
		line-height: 0.98;
		letter-spacing: -0.055em;
		font-weight: 620;
	}

	.work-intro p:last-child {
		margin: 1.35rem 0 0;
		max-width: 55ch;
		font-size: clamp(1rem, 1.35vw, 1.12rem);
		line-height: 1.75;
		color: var(--muted);
	}

	.work-list {
		max-width: 1120px;
	}

	.work-item {
		padding-block: clamp(3.5rem, 7vw, 6rem);
		border-top: 1px solid var(--line);
	}

	.work-item:first-child {
		padding-top: 0;
		border-top: 0;
	}

	.work-item-topline {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1.5rem;
		margin-bottom: 1.1rem;
	}

	.work-item-type {
		margin: 0;
		font-size: 0.78rem;
		font-weight: 700;
		letter-spacing: 0.12em;
		text-transform: uppercase;
		color: var(--muted);
	}

	.work-item-index,
	.work-meta {
		font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace;
	}

	.work-item-index {
		font-size: 0.78rem;
		color: var(--muted);
	}

	.work-item-title {
		margin: 0;
		max-width: 1100px;
		font-size: clamp(2.4rem, 3.6vw, 3.75rem);
		line-height: 1.02;
		letter-spacing: -0.045em;
		font-weight: 620;
		text-wrap: balance;
	}

	.work-meta {
		display: flex;
		flex-wrap: wrap;
		gap: 0.5rem 1rem;
		margin-top: 1.45rem;
		font-size: 0.77rem;
		color: var(--muted);
	}

	.work-copy {
		max-width: 700px;
		margin-top: 2rem;
	}

	.work-copy p {
		margin: 0;
		font-size: clamp(1rem, 1.3vw, 1.1rem);
		line-height: 1.8;
		color: #303640;
	}

	.work-copy p + p {
		margin-top: 1.15rem;
	}

	.work-actions {
		margin-top: 1.8rem;
	}

	.contact-cv {
		display: grid;
		grid-template-columns: 1fr 1fr;
		padding-block: var(--portfolio-section-y);
		border-bottom: 1px solid var(--line);
	}

	.final-block:first-child {
		padding-right: clamp(2rem, 5vw, 5rem);
	}

	.final-block:last-child {
		padding-left: clamp(2rem, 5vw, 5rem);
		border-left: 1px solid var(--line);
	}

	.final-block h2 {
		margin: 0;
		font-size: clamp(2rem, 4vw, 4.1rem);
		line-height: 1.02;
		letter-spacing: -0.055em;
		font-weight: 600;
	}

	.final-block p {
		max-width: 48ch;
		margin: 1.5rem 0 0;
		font-size: clamp(1rem, 1.35vw, 1.12rem);
		line-height: 1.75;
		color: #292f38;
	}

	.actions {
		display: flex;
		flex-wrap: wrap;
		gap: 1.25rem 1.6rem;
		margin-top: 2rem;
	}

	footer {
		padding-block: 2rem 3rem;
	}

	.footer-row {
		display: flex;
		justify-content: space-between;
		gap: 1rem;
		color: var(--muted);
		font-size: 0.9rem;
	}

	@media (max-width: 980px) {
		.hero {
			min-height: auto;
			grid-template-columns: minmax(0, 1fr);
			padding-top: 3rem;
		}

		.hero-copy,
		.portrait {
			grid-column: auto;
		}

		.portrait {
			width: 100%;
			max-width: 520px;
			margin-top: 1rem;
		}

		.portrait img {
			aspect-ratio: 5 / 4;
		}
	}

	@media (max-width: 720px) {
		:global(:root) {
			--portfolio-gutter: 1.15rem;
			--portfolio-section-y: 4rem;
		}

		h1 {
			font-size: clamp(2.2rem, 11.5vw, 5rem);
		}

		.work-intro {
			margin-bottom: 3rem;
		}

		.work-item-title {
			font-size: clamp(2.2rem, 10vw, 3.4rem);
		}

		.work-item-topline {
			align-items: flex-start;
		}

		.contact-cv {
			grid-template-columns: 1fr;
		}

		.final-block:first-child {
			padding-right: 0;
			padding-bottom: 3.5rem;
		}

		.final-block:last-child {
			padding-top: 3.5rem;
			padding-left: 0;
			border-top: 1px solid var(--line);
			border-left: 0;
		}

		.footer-row {
			flex-direction: column;
		}
	}

	@media (prefers-reduced-motion: reduce) {
		:global(html) {
			scroll-behavior: auto;
		}

		.skip-link,
		.arrow {
			transition: none;
		}

		.text-link:hover .arrow {
			transform: none;
		}
	}
</style>
