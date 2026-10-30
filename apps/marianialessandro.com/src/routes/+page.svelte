<script lang="ts">
	import { asset } from '$app/paths';
</script>

<svelte:head>
	<title>Alessandro Mariani — Software Engineer</title>
	<meta
		name="description"
		content="Alessandro Mariani — Software Engineer. Explore selected software engineering projects, open-source contributions, and experience."
	/>
	<meta name="color-scheme" content="light" />
	<meta name="theme-color" content="#fafafa" />
</svelte:head>

<a href="#main" class="skip">Skip to content</a>
<header class="header" id="top">
	<div class="header-inner container">
		<a class="brand" href="#top" aria-label="Alessandro Mariani — back to top">
			<span class="brand-mark" aria-hidden="true">am.</span>
			<span class="brand-name">Alessandro Mariani</span>
		</a>
		<nav class="nav" aria-label="Main navigation">
			<a class="nav-link" href="#work">Work</a>
			<a class="nav-link" href="#about">About</a>
			<a class="nav-link" href="#contact">Contact</a>
		</nav>
	</div>
</header>

<main id="main">
	<div class="container">
		<section class="hero" aria-labelledby="hero-title">
			<div class="hero-copy">
				<h1 id="hero-title">Hi, I'm <span>Alessandro Mariani.</span></h1>
				<p class="hero-subhead">Software engineering, from products to algorithms.</p>
				<p class="hero-description">
					I'm a software engineer based in Italy, working on full-stack applications, open-source
					software and algorithmic systems. I'm currently pursuing an M.Sc. in Computer Science at
					the University of Pisa.
				</p>
				<div class="inline-links">
					<a href="https://github.com/marianialessandro" target="_blank" rel="noopener noreferrer"
						>GitHub <span aria-hidden="true">↗</span></a
					>
					<a
						href="https://www.linkedin.com/in/alessandro-mariani-7a53981aa/"
						target="_blank"
						rel="noopener noreferrer">LinkedIn <span aria-hidden="true">↗</span></a
					>
					<a href="mailto:alessandro@marianialessandro.com"
						>Email <span aria-hidden="true">↗</span></a
					>
				</div>
			</div>
			<div class="hero-media" aria-label="Portrait">
				<div class="portrait">
					<span class="portrait-fallback" aria-hidden="true">am.</span>
					<img
						src="/images/laureaMeSquare.png"
						alt="Portrait of Alessandro Mariani"
						width="800"
						height="800"
						loading="eager"
						fetchpriority="high"
					/>
				</div>
			</div>
		</section>

		<section class="section" id="work" aria-labelledby="work-title">
			<div class="section-header">
				<div>
					<h2 class="section-title" id="work-title">A few things I've built.</h2>
					<p class="section-intro">
						A selection of work across open source, product development and academic research.
					</p>
				</div>
			</div>

			<article class="featured" aria-labelledby="sossoldi-title">
				<div class="feature-content">
					<span class="project-meta">Open-source contributor</span>
					<h3 id="sossoldi-title">Sossoldi</h3>
					<p>
						An open-source personal finance app built with Flutter. As a core contributor, I work on
						product features, database design and user interfaces, helping develop a tool used by
						more than 15,000 people.
					</p>
					<div class="tech-list" aria-label="Technologies">
						<span>Flutter</span><span>Dart</span>
					</div>
					<a
						class="text-link"
						href="https://github.com/RIP-Comm/sossoldi"
						target="_blank"
						rel="noopener noreferrer">Explore the project <span aria-hidden="true">↗</span></a
					>
				</div>
				<div class="feature-visual">
					<img
						class="sossoldi-mockup"
						src="/images/sossoldi/project-cover.jpg"
						alt="Official Sossoldi mockups showing the dashboard, transactions and budget screens"
						width="4944"
						height="1720"
						loading="lazy"
					/>
				</div>
			</article>

			<div class="project-grid">
				<article class="project-card" aria-labelledby="ecom-title">
					<div class="project-illustration dashboard-art" aria-hidden="true">
						<div class="dashboard">
							<div class="dash-sidebar"><i></i><i></i><i></i><i></i><i></i></div>
							<div class="dash-main">
								<div class="dash-heading"></div>
								<div class="dash-stats">
									<div class="dash-stat"><i></i><b></b></div>
									<div class="dash-stat"><i></i><b></b></div>
									<div class="dash-stat"><i></i><b></b></div>
								</div>
								<div class="dash-body">
									<div class="dash-plot">
										<svg viewBox="0 0 150 75" preserveAspectRatio="none"
											><path d="M0 70H150M0 36H150M0 4H150" stroke="#eeeeee" /><path
												d="M0 58L24 45 45 49 63 19 86 31 108 20 128 25 150 8"
												fill="none"
												stroke="#848484"
												stroke-width="3"
											/></svg
										>
									</div>
									<div class="dash-list"><i></i><i></i><i></i><i></i></div>
								</div>
							</div>
						</div>
					</div>
					<div class="card-content">
						<span class="project-meta">Professional work</span>
						<h3 id="ecom-title">E-commerce &amp; internal tools</h3>
						<div class="project-context">Freelance software engineer · Feb 2024–Jan 2025</div>
						<p>
							Built a company landing page, a custom CMS and a lead-tracking dashboard for a premium
							coffee and liquor e-commerce business. Configured the production environment and
							managed deployment.
						</p>
						<div class="tech-list" aria-label="Technologies"><span>Next.js</span></div>
					</div>
				</article>

				<article class="project-card" aria-labelledby="network-title">
					<div class="project-illustration network-art" aria-hidden="true">
						<svg class="network-svg" viewBox="0 0 500 220" role="presentation">
							<defs
								><linearGradient id="routeLine" x1="0" x2="1"
									><stop offset="0" stop-color="#d1d1d1" /><stop
										offset="1"
										stop-color="#989898"
									/></linearGradient
								></defs
							>
							<g stroke="#a4a4a4" stroke-width="1.5" opacity=".37" fill="none"
								><path
									d="M44 116L146 46 245 108 354 54 450 117M44 116L162 176 245 108 351 181 450 117M146 46L162 176M354 54L351 181M245 108L146 46M245 108L450 117"
								/></g
							>
							<path
								d="M44 116L146 46 245 108 351 181 450 117"
								stroke="url(#routeLine)"
								stroke-width="4"
								fill="none"
								stroke-linejoin="round"
								stroke-linecap="round"
								stroke-dasharray="1 0"
							/>
							<g fill="#4a4a4a" stroke="#9e9e9e" stroke-width="2"
								><circle cx="162" cy="176" r="13" /><circle cx="354" cy="54" r="13" /></g
							>
							<g fill="#cfcfcf" stroke="#3a3a3a" stroke-width="4"
								><circle cx="44" cy="116" r="17" /><circle cx="146" cy="46" r="16" /><circle
									cx="245"
									cy="108"
									r="17"
								/><circle cx="351" cy="181" r="16" /><circle cx="450" cy="117" r="17" /></g
							>
							<g font-size="10" font-family="monospace" fill="#dadada"
								><text x="25" y="156">SOURCE</text><text x="427" y="158">TARGET</text><text
									x="195"
									y="91">latency ≤ L</text
								></g
							>
						</svg>
					</div>
					<div class="card-content">
						<span class="project-meta">Research · B.Sc. thesis</span>
						<h3 id="network-title">Carbon-aware networking</h3>
						<div class="project-context">University of Pisa · Apr–Dec 2025</div>
						<p>
							Developed Green dgLBF for carbon- and cost-aware network routing under latency and
							bandwidth constraints. Compared heuristic and Branch and Bound strategies, evaluating
							scalability, execution times, emissions and energy costs.
						</p>
						<div class="tech-list" aria-label="Technologies">
							<span>Prolog</span><span>Python</span>
						</div>
						<a
							href="https://github.com/marianialessandro/green_dgLBF"
							target="_blank"
							rel="noopener noreferrer"
							class="text-link">View research code <span aria-hidden="true">↗</span></a
						>
					</div>
				</article>
			</div>
		</section>

		<!-- Temporarily hidden. Remove this comment and restore the More projects CSS to show the section again.
		<section class="section more-projects" id="more-work" aria-labelledby="more-title">
			<div class="section-header">
				<div>
					<span class="section-index">More engineering work</span>
					<h2 class="section-title" id="more-title">Other things I've explored.</h2>
				</div>
				<a
					class="text-link"
					href="https://github.com/marianialessandro?tab=repositories"
					target="_blank"
					rel="noopener noreferrer">GitHub repositories <span aria-hidden="true">↗</span></a
				>
			</div>
			<div class="other-list">
				<details class="other-item">
					<summary
						><span class="other-name">Multithreaded PageRank</span><span class="other-tech"
							>C · Parallelism · Graph algorithms</span
						><span class="other-arrow" aria-hidden="true">＋</span></summary
					>
					<div class="other-details">
						A concurrent implementation of the PageRank algorithm in C, designed to process large
						graph datasets efficiently. Reported a 1.4× speedup over baseline implementations in
						project measurements.
					</div>
				</details>
				<details class="other-item">
					<summary
						><span class="other-name">MyCAML interpreter</span><span class="other-tech"
							>TypeScript · Interpreters · Languages</span
						><span class="other-arrow" aria-hidden="true">＋</span></summary
					>
					<div class="other-details">
						Designed a small programming language inspired by OCaml, implementing a dynamically
						type-checked interpreter in TypeScript.
					</div>
				</details>
				<details class="other-item">
					<summary
						><span class="other-name">School evaluation portal</span><span class="other-tech"
							>PHP · Authentication · Backend</span
						><span class="other-arrow" aria-hidden="true">＋</span></summary
					>
					<div class="other-details">
						Built a back-end system with Google authentication to help teachers manage end-of-year
						evaluations and reporting.
					</div>
				</details>
				<details class="other-item">
					<summary
						><span class="other-name">Full-stack crypto exchange</span><span class="other-tech"
							>Java · Concurrency · Transactions</span
						><span class="other-arrow" aria-hidden="true">＋</span></summary
					>
					<div class="other-details">
						A Java-based project involving concurrent offer processing and transaction consistency
						in a multi-user trading environment.
					</div>
				</details>
			</div>
		</section>
		-->

		<section class="section about-section" id="about" aria-labelledby="about-title">
			<div class="about-wrap">
				<div class="about-main">
					<h2 class="section-title" id="about-title">Curious about<br />how things work.</h2>
					<p>
						My interests range from building software products to understanding the systems and
						algorithms behind them. I've worked on collaborative open-source development, business
						applications and academic research.
					</p>
					<p>
						I enjoy translating a problem into a clear technical design, reasoning about trade-offs
						and working through the details of implementation.
					</p>
				</div>
				<div class="about-education">
					<div class="degree">
						<div class="degree-bar"></div>
						<div>
							<h3>M.Sc. in Computer Science</h3>
							<p>University of Pisa</p>
							<small>2025 — 2027 (expected)</small>
						</div>
					</div>
					<div class="degree">
						<div class="degree-bar"></div>
						<div>
							<h3>B.Sc. in Computer Science</h3>
							<p>University of Pisa</p>
							<small>2022 — 2025</small>
						</div>
					</div>
				</div>
			</div>
		</section>

		<section class="contact-section" id="contact" aria-labelledby="contact-title">
			<div class="contact">
				<div class="contact-copy">
					<h2 id="contact-title">Let's get in touch.</h2>
					<p>
						For software engineering opportunities or technical conversations, feel free to get in
						touch.
					</p>
					<a href="mailto:alessandro@marianialessandro.com" class="contact-email"
						>alessandro@marianialessandro.com <span aria-hidden="true">↗</span></a
					>
				</div>
				<div class="contact-social">
					<a
						href="https://www.linkedin.com/in/alessandro-mariani-7a53981aa/"
						target="_blank"
						rel="noopener noreferrer">LinkedIn ↗</a
					>
				</div>
			</div>
		</section>

		<section class="cv-section" id="cv" aria-labelledby="cv-title">
			<div>
				<h2 id="cv-title">Download my CV.</h2>
			</div>
			<div class="cv-links" aria-label="CV downloads">
				<a href={asset('/documents/cveng.pdf')} target="_blank" rel="noopener noreferrer"
					>English PDF <span aria-hidden="true">↗</span></a
				>
				<a href={asset('/documents/cvita.pdf')} target="_blank" rel="noopener noreferrer"
					>Italiano PDF <span aria-hidden="true">↗</span></a
				>
			</div>
		</section>
	</div>
</main>

<footer class="container">
	<span>© {new Date().getFullYear()} Alessandro Mariani</span>
</footer>

<style>
	:global(html:root) {
		--bg: #fafafa;
		--surface: #ffffff;
		--surface-alt: #f5f5f5;
		--ink: #202020;
		--ink-2: #383838;
		--muted: #666666;
		--quiet: #898989;
		--line: #e4e4e4;
		--accent: #303030;
		--accent-strong: #222222;
		--accent-soft: #f1f1f1;
		--radius: 16px;
		--max: 1152px;
		--shadow: 0 16px 50px rgba(0, 0, 0, 0.04);
	}

	*,
	*::before,
	*::after {
		box-sizing: border-box;
	}
	:global(html) {
		scroll-behavior: smooth;
		scroll-padding-top: 98px;
	}
	:global(body) {
		margin: 0;
		color: var(--ink);
		background: var(--bg);
		font-family:
			Inter,
			ui-sans-serif,
			-apple-system,
			BlinkMacSystemFont,
			'Segoe UI',
			Helvetica,
			Arial,
			sans-serif;
		font-size: 16px;
		line-height: 1.6;
		-webkit-font-smoothing: antialiased;
	}
	a {
		color: inherit;
		text-decoration: none;
	}
	a:hover {
		color: var(--accent);
	}
	/* Restore summary:focus-visible alongside this selector when enabling More projects. */
	a:focus-visible {
		outline: 3px solid #909090;
		outline-offset: 4px;
		border-radius: 4px;
	}
	::selection {
		color: var(--accent-strong);
		background: #d8d8d8;
	}
	.container {
		width: min(var(--max), calc(100% - 88px));
		margin-inline: auto;
	}
	.skip {
		position: fixed;
		z-index: 100;
		top: 12px;
		left: 12px;
		padding: 10px 15px;
		background: var(--ink);
		color: #ffffff;
		transform: translateY(-170%);
	}
	.skip:focus {
		transform: translateY(0);
	}

	/* Header */
	.header {
		position: sticky;
		top: 0;
		z-index: 50;
		background: rgba(248, 248, 248, 0.92);
		backdrop-filter: blur(18px);
		-webkit-backdrop-filter: blur(18px);
		border-bottom: 1px solid rgba(51, 51, 51, 0.08);
	}
	.header-inner {
		height: 82px;
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 25px;
	}
	.brand {
		display: flex;
		align-items: center;
		gap: 13px;
		flex-shrink: 0;
	}
	.brand-mark {
		display: grid;
		place-items: center;
		width: 38px;
		height: 38px;
		color: #ffffff;
		background: var(--accent-strong);
		border-radius: 12px;
		font-size: 15px;
		line-height: 1;
		letter-spacing: -0.9px;
		font-weight: 800;
	}
	.brand-name {
		font-weight: 760;
		font-size: 15px;
		letter-spacing: -0.55px;
	}
	.nav {
		display: flex;
		align-items: center;
		gap: 37px;
	}
	.nav-link {
		font-weight: 620;
		color: var(--ink-2);
		font-size: 13px;
		transition: color 0.15s;
	}

	/* Hero */
	.hero {
		display: grid;
		grid-template-columns: minmax(0, 1.25fr) minmax(320px, 0.75fr);
		gap: 55px;
		align-items: center;
		min-height: 616px;
		padding-block: 82px 74px;
	}
	h1,
	h2,
	h3,
	p {
		margin: 0;
	}
	p {
		line-height: inherit;
	}
	.hero h1 {
		font-size: clamp(47px, 5.4vw, 77px);
		font-weight: 780;
		line-height: 1.055;
		letter-spacing: -0.075em;
		max-width: 720px;
		margin-top: 21px;
	}
	.hero h1 span {
		color: var(--ink);
	}
	.hero-subhead {
		margin-top: 21px;
		color: var(--ink-2);
		font-weight: 700;
		font-size: 18px;
		letter-spacing: -0.025em;
	}
	.hero-description {
		max-width: 575px;
		margin-top: 16px;
		color: var(--muted);
		line-height: 1.85;
		font-size: 16px;
	}
	.inline-links {
		display: flex;
		gap: 23px;
		margin-top: 27px;
		align-items: center;
	}
	.inline-links a {
		display: inline-flex;
		gap: 7px;
		align-items: center;
		font-size: 12px;
		color: var(--muted);
		font-weight: 720;
	}
	.inline-links a:hover {
		color: var(--accent);
	}
	.hero-media {
		position: relative;
		padding: 0;
	}
	.portrait {
		position: relative;
		overflow: hidden;
		aspect-ratio: 0.94;
		background: linear-gradient(143deg, #e2e2e2, #d1d1d1 45%, #b0b0b0);
		display: flex;
		align-items: center;
		justify-content: center;
	}
	.portrait::after {
		content: '';
		position: absolute;
		inset: 0;
		pointer-events: none;
		background: linear-gradient(to top, rgba(49, 49, 49, 0.09), transparent 40%);
	}
	.portrait img {
		width: 100%;
		height: 100%;
		object-fit: cover;
		display: block;
		position: relative;
		z-index: 2;
	}
	.portrait-fallback {
		position: absolute;
		color: #7d7d7d;
		font-size: clamp(80px, 13vw, 170px);
		line-height: 1;
		letter-spacing: -0.11em;
		font-weight: 800;
		transform: translateX(-5%);
	}

	/* Sections */
	.section {
		padding-block: 112px 0;
	}
	.section-header {
		display: flex;
		align-items: end;
		justify-content: space-between;
		gap: 32px;
		margin-bottom: 36px;
	}
	.section-title {
		font-size: clamp(32px, 3.7vw, 49px);
		line-height: 1.18;
		font-weight: 775;
		letter-spacing: -0.065em;
	}
	.section-intro {
		max-width: 430px;
		color: var(--muted);
		font-size: 14px;
		line-height: 1.8;
	}
	#work .section-intro {
		margin-top: 14px;
		max-width: 650px;
	}
	.text-link {
		font-size: 12px;
		font-weight: 770;
		display: inline-flex;
		align-items: center;
		gap: 9px;
		color: var(--accent-strong);
		padding-bottom: 3px;
		border-bottom: 1px solid #b0b0b0;
		white-space: nowrap;
	}
	.text-link:hover {
		gap: 13px;
	}
	.tech-list {
		display: flex;
		flex-wrap: wrap;
		gap: 4px 0;
		color: #646464;
		font-size: 12px;
		font-weight: 400;
		line-height: 1.6;
	}
	.tech-list span + span::before {
		content: '·';
		margin-inline: 8px;
	}

	/* Featured work */
	.featured {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 48px;
		min-height: 360px;
		align-items: center;
		overflow: hidden;
	}
	.feature-content {
		padding: 24px 0;
		display: flex;
		flex-direction: column;
		align-items: flex-start;
	}
	.project-meta {
		text-transform: uppercase;
		color: var(--accent);
		font-size: 10px;
		font-weight: 820;
		letter-spacing: 0.13em;
	}
	.featured h3 {
		margin-top: 17px;
		font-size: 39px;
		letter-spacing: -0.06em;
		line-height: 1.1;
		font-weight: 780;
	}
	.featured p {
		margin-top: 17px;
		color: #585858;
		max-width: 420px;
		font-size: 14px;
		line-height: 1.85;
	}
	.feature-content .tech-list {
		margin-top: 23px;
	}
	.feature-content .text-link {
		margin-top: 28px;
	}
	.feature-visual {
		min-height: 360px;
		position: relative;
		min-width: 0;
		overflow: hidden;
		background: #f0f5fa;
	}
	.sossoldi-mockup {
		position: absolute;
		inset: 0;
		display: block;
		width: 100%;
		height: 100%;
		object-fit: cover;
	}

	.project-grid {
		display: grid;
		grid-template-columns: 1fr;
		gap: 80px;
		margin-top: 80px;
	}
	.project-card {
		min-width: 0;
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 48px;
		align-items: center;
		min-height: 360px;
	}
	.project-card:nth-child(even) .project-illustration {
		grid-column: 2;
		grid-row: 1;
	}
	.project-card:nth-child(even) .card-content {
		grid-column: 1;
		grid-row: 1;
	}
	.project-illustration {
		min-height: 360px;
		height: 360px;
		overflow: hidden;
		position: relative;
		display: grid;
		place-items: center;
	}
	.dashboard-art {
		background: #ececec;
		padding: 27px 27px 0;
	}
	.dashboard {
		display: grid;
		grid-template-columns: 49px 1fr;
		width: 100%;
		max-width: 450px;
		height: 215px;
		border: 1px solid #dbdbdb;
		border-radius: 10px 10px 0 0;
		background: #ffffff;
		box-shadow: 0 22px 35px rgba(69, 69, 69, 0.15);
		overflow: hidden;
		transform: rotate(-2deg) translateY(10px);
	}
	.dash-sidebar {
		background: #383838;
		padding: 13px 11px;
		display: flex;
		flex-direction: column;
		gap: 14px;
	}
	.dash-sidebar i {
		display: block;
		width: 15px;
		height: 5px;
		border-radius: 2px;
		background: #828282;
	}
	.dash-sidebar i:first-child {
		width: 19px;
		height: 11px;
		background: #bdbdbd;
		border-radius: 4px;
		margin-bottom: 10px;
	}
	.dash-main {
		padding: 13px 17px;
	}
	.dash-heading {
		height: 7px;
		width: 86px;
		background: #464646;
		border-radius: 2px;
		margin: 2px 0 15px;
	}
	.dash-stats {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 8px;
	}
	.dash-stat {
		border: 1px solid #eeeeee;
		border-radius: 6px;
		height: 43px;
		padding: 8px;
	}
	.dash-stat i {
		display: block;
		height: 5px;
		width: 65%;
		background: #d5d5d5;
		border-radius: 2px;
	}
	.dash-stat b {
		display: block;
		height: 9px;
		width: 42%;
		background: #575757;
		margin-top: 8px;
		border-radius: 2px;
	}
	.dash-body {
		display: grid;
		grid-template-columns: 1.5fr 1fr;
		gap: 10px;
		margin-top: 11px;
	}
	.dash-plot,
	.dash-list {
		border: 1px solid #eeeeee;
		height: 99px;
		border-radius: 6px;
		padding: 10px;
	}
	.dash-plot svg {
		height: 100%;
		width: 100%;
	}
	.dash-list i {
		display: block;
		height: 6px;
		margin-bottom: 13px;
		width: 100%;
		border-radius: 3px;
		background: #eeeeee;
	}
	.dash-list i:nth-child(even) {
		width: 72%;
	}
	.network-art {
		background: #323232;
	}
	.network-art::before {
		content: '';
		position: absolute;
		inset: 0;
		opacity: 0.3;
		background-image:
			linear-gradient(#747474 1px, transparent 1px),
			linear-gradient(90deg, #747474 1px, transparent 1px);
		background-size: 29px 29px;
		mask-image: linear-gradient(90deg, transparent, #000000 40%, #000000 70%, transparent);
	}
	.network-svg {
		position: relative;
		width: min(100%, 500px);
		height: 100%;
		padding: 16px;
		overflow: visible;
	}
	.card-content {
		padding: 24px 0;
		display: flex;
		flex-direction: column;
		flex: 1;
		align-items: flex-start;
	}
	.card-content h3 {
		font-weight: 760;
		font-size: 39px;
		letter-spacing: -0.05em;
		line-height: 1.23;
		margin: 12px 0 10px;
	}
	.card-content p {
		font-size: 14px;
		color: var(--muted);
		line-height: 1.8;
		margin-bottom: 21px;
	}
	.project-context {
		color: var(--muted);
		font-size: 12px;
		line-height: 1.7;
		margin-bottom: 14px;
	}
	.card-content .tech-list {
		margin-top: 2px;
	}
	.card-content .text-link {
		margin-top: 24px;
	}

	/* More projects. Restore these styles when enabling the section.

	.more-projects {
		padding-top: 108px;
	}
	.other-list {
		border-top: 1px solid var(--line);
	}
	.other-item {
		border-bottom: 1px solid var(--line);
	}
	.other-item summary {
		cursor: pointer;
		display: grid;
		align-items: center;
		grid-template-columns: minmax(0, 1fr) auto 24px;
		gap: 22px;
		padding: 21px 4px;
		list-style: none;
	}
	.other-item summary::-webkit-details-marker {
		display: none;
	}
	.other-name {
		font-size: 19px;
		font-weight: 730;
		letter-spacing: -0.035em;
	}
	.other-tech {
		color: var(--muted);
		font-size: 12px;
	}
	.other-arrow {
		color: var(--accent);
		justify-self: end;
		transition: transform 0.2s;
	}
	details[open] .other-arrow {
		transform: rotate(45deg);
	}
	.other-details {
		padding: 0 40px 23px 4px;
		color: var(--muted);
		font-size: 13px;
		line-height: 1.85;
		max-width: 700px;
	}

	*/

	/* About */
	.about-section {
		padding-top: 113px;
	}
	.about-wrap {
		display: grid;
		grid-template-columns: 1.08fr 0.92fr;
		gap: 64px;
		padding-top: 48px;
		border-top: 1px solid var(--line);
		overflow: hidden;
	}
	.about-main {
		padding: 0;
	}
	.about-main h2 {
		margin-bottom: 21px;
	}
	.about-main p {
		color: #646464;
		font-size: 14px;
		line-height: 1.95;
		margin-top: 14px;
		max-width: 540px;
	}
	.about-education {
		display: flex;
		flex-direction: column;
		justify-content: center;
		padding: 0;
	}
	.degree {
		display: flex;
		gap: 13px;
		padding-bottom: 25px;
		margin-bottom: 25px;
		border-bottom: 1px solid #d6d6d6;
	}
	.degree:last-child {
		border-bottom: 0;
		margin-bottom: 0;
		padding-bottom: 0;
	}
	.degree-bar {
		width: 3px;
		border-radius: 3px;
		flex: 0 0 auto;
		background: #8d8d8d;
	}
	.degree h3 {
		font-size: 16px;
		font-weight: 780;
		letter-spacing: -0.035em;
	}
	.degree p {
		font-size: 12px;
		color: var(--muted);
		margin-top: 4px;
	}
	.degree small {
		color: #7a7a7a;
		font-size: 11px;
		margin-top: 9px;
		display: block;
	}

	/* Contact and CV: no large calls-to-action or coloured banners. */
	.contact-section {
		padding-top: 105px;
	}
	.contact {
		border-top: 1px solid var(--line);
		padding: 53px 0 58px;
		display: flex;
		align-items: end;
		justify-content: space-between;
		gap: 40px;
	}
	.contact-copy {
		max-width: 700px;
	}
	.contact h2 {
		font-size: clamp(32px, 4vw, 49px);
		font-weight: 775;
		line-height: 1.16;
		letter-spacing: -0.06em;
	}
	.contact p {
		margin-top: 16px;
		font-size: 14px;
		color: var(--muted);
		line-height: 1.8;
	}
	.contact-email {
		margin-top: 22px;
		font-weight: 650;
		font-size: 15px;
		display: inline-block;
		border-bottom: 1px solid #a6a6a6;
		padding-bottom: 3px;
		overflow-wrap: anywhere;
	}
	.contact-email:hover {
		color: var(--ink);
		border-color: var(--ink);
	}
	.contact-social {
		display: flex;
		gap: 23px;
		padding-bottom: 5px;
		flex: 0 0 auto;
	}
	.contact-social a {
		font-size: 13px;
		font-weight: 600;
		color: var(--muted);
	}
	.contact-social a:hover {
		color: var(--ink);
	}
	.cv-section {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 35px;
		border-top: 1px solid var(--line);
		padding: 42px 0 58px;
	}
	.cv-section h2 {
		font-size: clamp(24px, 2.8vw, 35px);
		line-height: 1.18;
		font-weight: 730;
		letter-spacing: -0.05em;
	}
	.cv-links {
		display: flex;
		gap: 28px;
		flex-wrap: wrap;
	}
	.cv-links a {
		font-size: 13px;
		font-weight: 650;
		color: var(--ink-2);
		border-bottom: 1px solid #c7c7c7;
		padding-bottom: 5px;
	}
	.cv-links a:hover {
		color: var(--ink);
		border-color: var(--ink);
	}
	footer {
		display: flex;
		justify-content: center;
		align-items: center;
		text-align: center;
		gap: 20px;
		padding-block: 25px 36px;
		color: var(--quiet);
		font-size: 11px;
	}

	/* Responsive */
	@media (max-width: 1060px) {
		.container {
			width: min(var(--max), calc(100% - 64px));
		}
		.hero {
			gap: 32px;
			min-height: unset;
			padding-block: 76px 66px;
		}
		.hero h1 {
			font-size: clamp(50px, 5.7vw, 66px);
		}
		.feature-content {
			padding: 24px 0;
		}
	}
	@media (max-width: 760px) {
		.container {
			width: calc(100% - 40px);
		}
		.header-inner {
			height: 68px;
		}
		.brand-name {
			font-size: 13px;
		}
		.brand-mark {
			width: 34px;
			height: 34px;
			border-radius: 10px;
			font-size: 13px;
		}
		.nav {
			display: none;
		}
		.hero {
			grid-template-columns: minmax(0, 1fr);
			padding-block: 63px 36px;
			gap: 35px;
		}
		.hero h1 {
			font-size: clamp(43px, 9vw, 67px);
			max-width: 620px;
		}
		.hero-description {
			max-width: 620px;
		}
		.hero-media {
			width: min(100%, 355px);
			justify-self: center;
			padding: 0;
		}
		.portrait {
			aspect-ratio: 1.25;
		}
		.portrait-fallback {
			font-size: 120px;
		}
		.section {
			padding-top: 85px;
		}
		.section-header {
			align-items: start;
			flex-direction: column;
			gap: 17px;
			margin-bottom: 28px;
		}
		.featured,
		.project-card {
			grid-template-columns: 1fr;
			gap: 28px;
		}
		.feature-content {
			min-height: unset;
		}
		.feature-content .text-link {
			margin-top: 15px;
		}
		.feature-visual {
			grid-row: 1;
			min-height: 290px;
		}

		.project-grid {
			gap: 56px;
			margin-top: 56px;
		}
		.project-illustration {
			height: 290px;
			min-height: 290px;
		}
		.project-card:nth-child(even) .project-illustration,
		.project-card:nth-child(even) .card-content {
			grid-column: auto;
			grid-row: auto;
		}
		.card-content {
			padding: 0;
		}
		.card-content h3 {
			font-size: 34px;
		}
		.about-wrap {
			grid-template-columns: 1fr;
			gap: 36px;
		}
		.about-main {
			padding: 0;
		}
		.about-education {
			padding: 0;
		}
		.contact {
			align-items: start;
			flex-direction: column;
			gap: 23px;
		}
		.cv-section {
			align-items: start;
			flex-direction: column;
			gap: 24px;
		}
	}
	@media (max-width: 530px) {
		.container {
			width: calc(100% - 36px);
		}
		.header-inner {
			gap: 9px;
		}
		.nav {
			gap: 15px;
		}

		.hero {
			padding-top: 51px;
		}
		.hero h1 {
			letter-spacing: -0.064em;
			font-size: clamp(40px, 10.3vw, 53px);
		}
		.hero-subhead {
			font-size: 16px;
		}
		.hero-description {
			font-size: 14px;
			line-height: 1.85;
		}
		.inline-links {
			gap: 19px;
		}
		.portrait {
			aspect-ratio: 1.13;
		}
		.section {
			padding-top: 74px;
		}
		.section-title {
			font-size: 36px;
		}
		.featured h3 {
			font-size: 34px;
		}
		.feature-content {
			padding: 0;
		}
		.feature-visual {
			min-height: 255px;
		}

		.project-grid {
			grid-template-columns: 1fr;
		}
		.project-illustration {
			height: 205px;
			min-height: 205px;
		}
		.card-content h3 {
			font-size: 34px;
		}
		/*
		.other-item summary {
			grid-template-columns: minmax(0, 1fr) 19px;
			gap: 9px;
			padding-block: 19px;
		}
		*/
		/*
		.other-name {
			font-size: 16px;
		}
		*/
		/*
		.other-tech {
			grid-column: 1;
			grid-row: 2;
			font-size: 11px;
		}
		*/
		/*
		.other-arrow {
			grid-column: 2;
			grid-row: 1;
		}
		*/
		/*
		.other-details {
			padding: 0 12px 20px 4px;
		}
		*/
		.about-main,
		.about-education {
			padding-inline: 0;
		}
		.contact {
			padding-block: 38px 46px;
			gap: 23px;
		}
		.contact h2 {
			font-size: 36px;
		}
		.contact-social {
			gap: 22px;
		}
		.cv-section {
			padding-block: 34px 44px;
		}
		footer {
			flex-direction: column;
			align-items: center;
			gap: 8px;
		}
	}
	@media (prefers-reduced-motion: reduce) {
		:global(html) {
			scroll-behavior: auto;
		}
		*,
		*::before,
		*::after {
			transition: none !important;
			animation: none !important;
		}
	}
</style>
