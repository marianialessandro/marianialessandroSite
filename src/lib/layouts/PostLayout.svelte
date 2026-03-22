<script lang="ts">
	import type { ComponentType } from 'svelte';
	import { onDestroy, onMount } from 'svelte';
	import TableOfContents from '$lib/components/TableOfContents.svelte';

	export let Content: ComponentType | null = null;
	export let meta: { title?: string; description?: string; date?: string } = {};
	export let showTitleFromMeta = true;

	type Heading = { id: string; text: string; level: number };

	let articleElement: HTMLElement | null = null;
	let headings: Heading[] = [];
	let activeId = '';
	let observer: IntersectionObserver | null = null;

	$: hasTOC = headings.length > 0;

	const slugify = (value: string) =>
		value
			.toLowerCase()
			.normalize('NFD')
			.replace(/\s*\(h[1-6]\)\s*$/i, '')
			.replace(/[\u0300-\u036f]/g, '')
			.replace(/[^a-z0-9\s-]/g, '')
			.trim()
			.replace(/\s+/g, '-')
			.replace(/-+/g, '-');

	const collectHeadings = () => {
		if (!articleElement) return [];

		const nodes = Array.from(articleElement.querySelectorAll<HTMLElement>('h2, h3, h4'));
		const used: string[] = [];

		return nodes
			.map((element) => {
				const text = element.textContent?.trim() ?? '';
				const base = slugify(text || 'section') || 'section';

				let id = element.id || base;
				let suffix = 2;

				while (used.includes(id)) {
					id = `${base}-${suffix++}`;
				}

				used.push(id);

				if (!element.id) {
					element.id = id;
				}

				return {
					id,
					text: text || 'Section',
					level: Number(element.tagName.slice(1))
				};
			})
			.filter((heading) => heading.text.length > 0);
	};

	const setupObserver = () => {
		observer?.disconnect();

		if (!articleElement || headings.length === 0) return;

		const nodes = Array.from(articleElement.querySelectorAll<HTMLElement>('h2, h3, h4'));

		observer = new IntersectionObserver(
			(entries) => {
				const visible = entries
					.filter((entry) => entry.isIntersecting)
					.sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top);

				if (visible.length > 0) {
					activeId = (visible[0].target as HTMLElement).id;
				}
			},
			{
				rootMargin: '0px 0px -70% 0px',
				threshold: [0, 0.1, 0.25, 0.5, 1]
			}
		);

		nodes.forEach((node) => observer?.observe(node));
	};

	onMount(() => {
		headings = collectHeadings();
		activeId = window.location.hash ? decodeURIComponent(window.location.hash.slice(1)) : '';
		setupObserver();
	});

	onDestroy(() => {
		observer?.disconnect();
	});
</script>

<div class={`post-layout ${hasTOC ? '' : 'no-toc'}`}>
	{#if hasTOC}
		<aside class="toc-wrap" aria-label="Indice laterale">
			<TableOfContents {headings} {activeId} />
		</aside>
	{/if}

	<article class="post" aria-label="Articolo" bind:this={articleElement}>
		{#if showTitleFromMeta && meta.title}
			<h1 class="post-title">{meta.title}</h1>
		{/if}

		{#if Content}
			<svelte:component this={Content} />
		{/if}
	</article>
</div>

<style>
	:root {
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

		--toc-w: 260px;
		--gap: 32px;
	}

	.post-layout {
		display: grid;
		grid-template-columns: minmax(0, 1fr);
		max-width: calc(var(--post-max-width) + 48px);
		margin: 0 auto;
		padding: clamp(16px, 2.5vw, 28px) 16px 80px;
	}

	.toc-wrap {
		display: none;
	}

	.post {
		color: var(--post-text);
		font-family: var(--post-font-serif);
		font-size: clamp(1.02rem, 0.9rem + 0.5vw, 1.18rem);
		line-height: 1.65;
		max-width: var(--post-max-width);
		margin: 0 auto;
		text-rendering: optimizeLegibility;
		-webkit-font-smoothing: antialiased;
		font-kerning: normal;
		word-break: normal;
		overflow-wrap: anywhere;
	}

	.post :global(p),
	.post :global(ul),
	.post :global(ol),
	.post :global(pre),
	.post :global(blockquote),
	.post :global(table),
	.post :global(figure) {
		margin: 0 0 1.1em 0;
	}

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

	.post h1.post-title {
		text-align: center;
		margin: 0 0 0.6em 0;
	}

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

	.post :global(a) {
		color: var(--post-link);
		text-decoration: underline;
		text-decoration-thickness: from-font;
		text-underline-offset: 2px;
	}

	.post :global(a:hover) {
		opacity: 0.9;
	}

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

	.post :global(blockquote) {
		color: var(--post-quote);
		font-style: italic;
		padding: 0.1em 1.1em;
		border-left: 3px solid var(--post-quote-bar);
		margin: 1.4em 0;
	}

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

	.post :global(hr) {
		border: 0;
		height: 1px;
		background: var(--post-hr);
		margin: 2em 0;
	}

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
			left: max(env(safe-area-inset-left), var(--toc-outer-margin));
			right: auto;
			width: var(--toc-w);
			overflow: auto;
			padding-right: 16px;
			border-right: 1px solid var(--post-border);
			display: block;
		}
	}

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

	@media (max-width: 1023.98px) {
		.toc-wrap {
			display: none;
		}
	}
</style>
