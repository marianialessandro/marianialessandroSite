<!-- src/lib/components/PostLayout.svelte -->
<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import TableOfContents from '$lib/components/TableOfContents.svelte';

	export let Content: any;
	export let meta: { title?: string; description?: string; date?: string } = {};
	export let showTitleFromMeta: boolean = true;
	/* export let data: any; */

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
		const article = document.querySelector('article.post');
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

		// Se non ci sono titoli, esci: niente observer, niente ToC
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
		<aside class="toc-wrap" aria-label="Indice laterale">
			<TableOfContents {headings} {activeId} />
		</aside>
	{/if}

	<article class="post" aria-label="Articolo">
		{#if showTitleFromMeta && meta.title}
			<h1 class="post-title">{meta.title}</h1>
		{/if}
		<svelte:component this={Content} />
	</article>
</div>

<style>
	:root {
		/* margine esterno sinistro della sidebar (modifica a piacere) */
		--toc-outer-margin: clamp(16px, 2vw, 32px);
	}

	:global(:root) {
		--post-max-width: 70ch;
		--post-font-serif: inherit;
		--post-font-sans: inherit;
		--post-font-mono: inherit;

		--post-text: #121212;
		--post-muted: #666;
		--post-border: #e5e5e5;
		--post-link: #0a66c2;
		--post-code-bg: #f6f8fa;
		--post-quote: #444;
		--post-quote-bar: #ddd;
		--post-hr: #efefef;
		--post-figcap: #777;
		--post-mark: #fff6a8;

		/* larghezza sidebar indice */
		--toc-w: 260px;
		--gap: 32px;
	}

	/* ——— Layout a due colonne ——— */
	.post-layout {
		display: grid;
		grid-template-columns: minmax(0, 1fr);
		max-width: calc(var(--post-max-width) + 48px);
		margin: 0 auto; /* ← centro pagina */
		padding: clamp(16px, 2.5vw, 28px) 16px 80px;
	}

	.toc-wrap {
		display: none; /* mobile: nascosto */
	}

	/* ——— Contenitore ——— */
	.post {
		color: var(--post-text);
		font-family: var(--post-font-serif);
		font-size: clamp(1.02rem, 0.9rem + 0.5vw, 1.18rem);
		line-height: 1.65;
		max-width: var(--post-max-width);
		margin: 0 auto;
		/* padding rimosso perché lo gestisce .post-layout */
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

	/* Titolo pagina (da meta.title) centrato */
	.post h1.post-title {
		text-align: center;
		margin: 0 0 0.6em 0;
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

	/* Liste */
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

	/* Codice */
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

	/* Immagini / figure */
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

	/* Tabelle */
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

	/* Migliora il salto su anchor (se hai una navbar fissa, aumenta il valore) */
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

	/* Responsive: allarga un filo su desktop */
	@media (min-width: 1100px) {
		:global(:root) {
			--post-max-width: 72ch;
		}
	}

	@media (min-width: 1200px) {
		.toc-wrap {
			position: fixed;
			top: 96px;
			bottom: 24px;
			left: max(env(safe-area-inset-left), var(--toc-outer-margin)); /* ← margine dal bordo */
			right: auto;
			width: var(--toc-w);
			overflow: auto;
			padding-right: 16px;
			border-right: 1px solid var(--post-border);
			display: block;
		}
	}

	/* desktop “medio”: fallback sticky dentro al grid */
	@media (min-width: 1024px) and (max-width: 1199.98px) {
		.post-layout {
			grid-template-columns: var(--toc-w) minmax(0, 1fr);
			max-width: calc(var(--post-max-width) + var(--toc-w) + var(--gap) + 48px);
			gap: var(--gap);
		}
		.toc-wrap {
			position: sticky;
			top: 96px;
			max-height: calc(100vh - 96px);
			overflow: auto;
			display: block;
			border-right: 1px solid var(--post-border);
			padding-right: 16px;
		}
	}

	/* mobile: nascondi ToC */
	@media (max-width: 1023.98px) {
		.toc-wrap {
			display: none;
		}
	}
</style>
