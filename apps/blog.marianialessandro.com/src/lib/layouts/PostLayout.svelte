<!-- src/lib/components/PostLayout.svelte -->
<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { TableOfContents } from '@marianialessandro/shared';
	import ArticleHeader from '$lib/components/ArticleHeader.svelte';

	export let contentHtml: string;
	export let meta: { title?: string; description?: string; date?: string; tags?: string[] } = {};
	export let showTitleFromMeta: boolean = true;

	type H = { id: string; text: string; level: number };
	let headings: H[] = [];
	let activeId = '';
	let observer: IntersectionObserver | null = null;

	$: hasTOC = headings.length > 0;

	const slugify = (str: string) =>
		str
			.toLowerCase()
			.normalize('NFD')
			.replace(/[\u0300-\u036f]/g, '')
			.replace(/[^a-z0-9\s-]/g, '')
			.trim()
			.replace(/\s+/g, '-');

	onMount(() => {
		const article = document.querySelector('.post');
		if (!article) return;

		const nodes = Array.from(article.querySelectorAll('h1, h2, h3, h4')) as HTMLElement[];
		const tocNodes = nodes.filter((el) => !el.classList.contains('post-title'));

		headings = tocNodes.map((el) => {
			if (!el.id) {
				const base = slugify(el.textContent || 'sezione');
				let id = base,
					i = 2;
				while (document.getElementById(id)) id = `${base}-${i++}`;
				el.id = id;
			}
			return { id: el.id, text: el.textContent ?? '', level: parseInt(el.tagName.slice(1), 10) };
		});

		// No headings means no observer and no ToC.
		if (headings.length === 0) return;

		observer = new IntersectionObserver(
			(entries) => {
				for (const entry of entries) {
					if (entry.isIntersecting) activeId = (entry.target as HTMLElement).id;
				}
			},
			{ rootMargin: '0px 0px -70% 0px', threshold: 0.1 }
		);

		tocNodes.forEach((el) => observer!.observe(el));
	});

	onDestroy(() => observer?.disconnect());
</script>

<div class={`post-layout ${hasTOC ? '' : 'no-toc'}`}>
	{#if hasTOC}
		<aside class="toc-wrap" aria-label="Side table of contents">
			<TableOfContents {headings} {activeId} />
		</aside>
	{/if}

	<article class="post-shell" aria-label="Post">
		{#if showTitleFromMeta && meta.title}
			<ArticleHeader
				title={meta.title}
				description={meta.description}
				date={meta.date}
				tags={meta.tags}
			/>
		{/if}

		<div class="post">
			<!-- eslint-disable-next-line svelte/no-at-html-tags -- renderMarkdown sanitizes contentHtml -->
			{@html contentHtml}
		</div>
	</article>
</div>

<style>
	:global(:root) {
		--post-max-width: 70ch;
		--post-font-serif: inherit;
		--post-font-sans: inherit;
		--post-font-mono: var(--font-mono);

		--post-text: var(--fg);
		--post-muted: #666;
		--post-border: #e5e5e5;
		--post-link: var(--accent);
		--post-code-bg: var(--surface-alt);
		--post-quote: #444;
		--post-quote-bar: #ddd;
		--post-hr: #efefef;
		--post-figcap: #777;
		--post-mark: #e8e8e8;
	}

	/* ——— Layout a due colonne ——— */
	.post-layout {
		display: grid;
		grid-template-columns: minmax(0, 1fr);
		max-width: calc(var(--post-max-width) + 48px);
		margin: 0 auto; /* ← centro pagina */
		padding: clamp(3rem, 6vw, 5rem) 0 80px;
		width: var(--container);
	}

	.toc-wrap {
		display: none; /* hidden on mobile */
	}

	/* ——— Contenitore ——— */
	.post-shell {
		max-width: var(--post-max-width);
		min-width: 0;
		width: 100%;
		margin: 0 auto;
	}

	.post {
		color: var(--post-text);
		font-family: var(--post-font-serif);
		font-size: clamp(1.02rem, 0.9rem + 0.5vw, 1.18rem);
		line-height: 1.65;
		/* Padding is handled by .post-layout. */
		text-rendering: optimizeLegibility;
		-webkit-font-smoothing: antialiased;
		font-kerning: normal;
		word-break: normal;
		overflow-wrap: anywhere;
	}

	/* Spaziatura blocchi */
	.post :global(p),
	.post :global(ul),
	.post :global(ol),
	.post :global(pre),
	.post :global(blockquote),
	.post :global(table),
	.post :global(figure) {
		margin: 0 0 1.1em 0;
	}

	/* ——— Headings ——— */
	.post :global(h1),
	.post :global(h2),
	.post :global(h3),
	.post :global(h4) {
		font-family: var(--post-font-serif);
		line-height: 1.25;
		font-weight: 700;
		letter-spacing: -0.01em;
		margin: 1.6em 0 0.6em;
		text-align: left;
	}
	.post :global(h1) {
		font-size: clamp(2rem, 1.5rem + 1.8vw, 3rem);
	}
	.post :global(h2) {
		font-size: clamp(1.6rem, 1.3rem + 1.2vw, 2.2rem);
	}
	.post :global(h3) {
		font-size: clamp(1.3rem, 1.1rem + 0.8vw, 1.6rem);
	}
	.post :global(h4) {
		font-size: 1.1rem;
	}

	/* Paragrafi e testo */
	.post :global(p) {
		color: var(--post-text);
	}
	.post :global(p + p) {
		margin-top: 0.2em;
	}
	.post :global(em) {
		font-style: italic;
	}
	.post :global(strong) {
		font-weight: 700;
	}
	.post :global(mark) {
		background: var(--post-mark);
		padding: 0 0.15em;
	}

	/* Link */
	.post :global(a) {
		color: var(--post-link);
		text-decoration: underline;
		text-decoration-thickness: from-font;
		text-underline-offset: 2px;
	}
	.post :global(a:hover) {
		opacity: 0.9;
	}

	/* Lists */
	.post :global(ul),
	.post :global(ol) {
		padding-left: 1.25em;
	}
	.post :global(li) {
		margin: 0.3em 0;
	}
	.post :global(ul) {
		list-style: disc;
	}
	.post :global(ol) {
		list-style: decimal;
	}

	/* Citazioni */
	.post :global(blockquote) {
		color: var(--post-quote);
		font-style: italic;
		padding: 0.1em 1.1em;
		border-left: 3px solid var(--post-quote-bar);
		margin: 1.4em 0;
	}

	/* Code */
	.post :global(code) {
		font-family: var(--post-font-mono);
		font-size: 0.92em;
		background: var(--post-code-bg);
		padding: 0.15em 0.35em;
		border-radius: 4px;
	}
	.post :global(pre) {
		background: var(--post-code-bg);
		padding: 1em;
		border-radius: 8px;
		overflow: auto;
	}
	.post :global(pre code) {
		background: transparent;
		padding: 0;
	}

	/* Images / figures */
	.post :global(img) {
		display: block;
		max-width: 100%;
		height: auto;
		margin: 1.2em auto;
		border-radius: 8px;
	}
	.post :global(figure) {
		text-align: center;
	}
	.post :global(figcaption) {
		font-family: var(--post-font-sans);
		color: var(--post-figcap);
		font-size: 0.9rem;
		margin-top: 0.4em;
	}

	/* Tables */
	.post :global(table) {
		width: 100%;
		border-collapse: collapse;
		font-variant-numeric: tabular-nums;
	}
	.post :global(th),
	.post :global(td) {
		border-bottom: 1px solid var(--post-border);
		padding: 0.6em 0.4em;
		text-align: left;
		vertical-align: top;
	}
	.post :global(thead th) {
		font-family: var(--post-font-sans);
		font-size: 0.9rem;
		color: var(--post-muted);
		font-weight: 600;
	}

	/* HR */
	.post :global(hr) {
		border: 0;
		height: 1px;
		background: var(--post-hr);
		margin: 2em 0;
	}

	/* Footnotes */
	.post :global(sup[id^='fnref'] a),
	.post :global(a.footnote-ref) {
		text-decoration: none;
		font-variant-position: super;
	}
	.post :global(section.footnotes) {
		border-top: 1px solid var(--post-hr);
		margin-top: 2em;
		padding-top: 1em;
		font-size: 0.95em;
	}

	/* Improve anchor jumps when a fixed navbar is present. */
	/* Svelte: niente liste dentro :global() */
	.post :global(h1[id]),
	.post :global(h2[id]),
	.post :global(h3[id]),
	.post :global(h4[id]) {
		scroll-margin-top: 96px;
	}

	.post-layout.no-toc {
		grid-template-columns: minmax(0, 1fr);
		max-width: calc(var(--post-max-width) + 48px);
	}

	@media (min-width: 1024px) {
		.post-layout {
			grid-template-columns: 220px minmax(0, 72ch);
			max-width: 1152px;
			gap: clamp(32px, 5vw, 72px);
			justify-content: center;
			align-items: start;
		}
		.toc-wrap {
			position: sticky;
			top: 112px;
			max-height: calc(100vh - 144px);
			overflow: auto;
			display: block;
			border-right: 1px solid var(--line);
			padding-right: 16px;
		}
	}
</style>
