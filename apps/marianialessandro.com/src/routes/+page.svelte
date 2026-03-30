<!-- src/routes/+page.svelte -->
<script lang="ts">
	import { EnvelopeSolid, GithubSolid, LinkedinSolid } from 'flowbite-svelte-icons';

	// Personalizza qui
	const name = 'Alessandro Mariani';
	const role = 'Computer Science Student';

	const bio =
		'Currently an M.Sc. student in Computer Science at the University of Pisa, following my undergraduate studies there. I specialize in systems programming, networking, sustainable computing, and algorithmics. I am deeply interested in exploring how thoughtful design and optimization can drive both performance and energy efficiency. I enjoy the technical challenge of engineering efficient, working code.';

	// Tesi
	const bscThesisTitle =
		'Guaranteed-latency network traffic: a declarative and sustainable approach';
	const bscThesisPassage = `For my B.Sc. thesis, I investigated a declarative approach to network routing that secures timing guarantees while simultaneously minimizing energy costs and carbon footprint.`;

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
					<GithubSolid width={18} height={18} ariaLabel="GitHub" />
				</a>

				<a href={linkedin} target="_blank" rel="noreferrer" aria-label="LinkedIn" class="icon">
					<LinkedinSolid width={18} height={18} ariaLabel="LinkedIn" />
				</a>

				<a href={email} aria-label="Email" class="icon">
					<EnvelopeSolid width={18} height={18} ariaLabel="Email" />
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
		transition:
			transform 140ms ease,
			box-shadow 140ms ease,
			border-color 140ms ease;
	}

	.icon:hover {
		transform: translateY(-1px);
		box-shadow: 0 10px 20px rgba(0, 0, 0, 0.06);
		border-color: rgba(0, 0, 0, 0.18);
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
		background:
			radial-gradient(circle at 30% 20%, rgba(255, 62, 0, 0.22), transparent 45%),
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
		transition:
			transform 140ms ease,
			box-shadow 140ms ease,
			border-color 140ms ease;
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
		.icon {
			transition: none;
		}
		.btn:hover,
		.icon:hover {
			transform: none;
		}
	}
</style>
