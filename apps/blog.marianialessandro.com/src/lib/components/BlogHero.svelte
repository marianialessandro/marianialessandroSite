<script lang="ts">
	import { ArrowRightAltOutline } from 'flowbite-svelte-icons';

	type Props = {
		postCount: number;
	};

	let { postCount }: Props = $props();
</script>

<section class="hero" aria-labelledby="blog-title">
	<div class="copy">
		<p class="eyebrow">Notes and articles</p>
		<h1 id="blog-title">marianialessandro.com</h1>
		<p class="lede">
			Technical notes, experiments, and reflections on systems, networking, programming, and
			sustainability.
		</p>
	</div>

	<div class="summary" aria-label="Blog information">
		<p class="count">{postCount}</p>
		<p class="label">{postCount === 1 ? 'published post' : 'published posts'}</p>
		<a href="/archive/">
			Archive
			<ArrowRightAltOutline width="1rem" height="1rem" ariaLabel="Open archive" />
		</a>
	</div>
</section>

<style>
	.hero {
		width: var(--container);
		margin: 0 auto;
		display: grid;
		grid-template-columns: minmax(0, 1fr);
		gap: 1.25rem;
		align-items: end;
		padding: clamp(1.7rem, 4vw, 3rem) 0 clamp(1.4rem, 3vw, 2.2rem);
		border-bottom: 1px solid var(--line);
	}

	.eyebrow,
	.lede,
	.summary p {
		margin: 0;
	}

	.eyebrow {
		color: var(--muted);
		font-size: 0.94rem;
	}

	h1 {
		margin: 0.2rem 0 0;
		font-size: clamp(1.75rem, 7vw, 4.4rem);
		line-height: 0.98;
		letter-spacing: 0;
		overflow-wrap: anywhere;
	}

	.lede {
		margin-top: 0.9rem;
		max-width: 60ch;
		color: var(--fg);
		font-size: clamp(1rem, 1.5vw, 1.12rem);
		line-height: 1.75;
	}

	.summary {
		display: flex;
		align-items: center;
		gap: 0.9rem;
		flex-wrap: wrap;
		justify-content: flex-start;
		border-left: 2px solid var(--accent);
		padding: 0.1rem 0 0.1rem 1rem;
	}

	.count {
		font-size: 2rem;
		line-height: 1;
		font-weight: 700;
	}

	.label {
		flex: 1 1 9rem;
		color: var(--muted);
		font-size: 0.9rem;
	}

	.summary a {
		display: inline-flex;
		align-items: center;
		gap: 0.3rem;
		min-height: 2.15rem;
		border: 1px solid var(--line);
		border-radius: 999px;
		padding: 0 0.7rem;
		background: #fff;
		color: var(--fg);
		font-size: 0.88rem;
		text-decoration: none;
	}

	@media (min-width: 820px) {
		.hero {
			grid-template-columns: minmax(0, 1fr) minmax(15rem, 19rem);
		}
	}
</style>
