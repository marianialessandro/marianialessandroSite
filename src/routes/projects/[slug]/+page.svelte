<script lang="ts">
	export let data: {
		meta: {
			title: string;
			date: string | null;
			repo?: string | null;
			description?: string | null;
			articleLink?: string | null;
		};
		html: string;
	};

	const toHref = (url?: string | null) => {
		if (!url) return null;
		return /^https?:\/\//i.test(url) ? url : `https://${url}`;
	};

	const formatDate = (value: string | null) => {
		if (!value) return null;

		const parsed = new Date(value);
		if (Number.isNaN(parsed.getTime())) return value;

		return parsed.toLocaleDateString('it-IT', {
			day: '2-digit',
			month: '2-digit',
			year: 'numeric'
		});
	};

	const enhanceHtml = (html: string) => {
		if (!html) return '';

		let output = html;

		output = output.replace(
			/<table([\s\S]*?)>([\s\S]*?)<\/table>/g,
			'<div class="table-wrap"><table$1>$2</table></div>'
		);

		output = output.replace(
			/<img(?![^>]*\bloading=)(?![^>]*\bdecoding=)([^>]*?)>/g,
			'<img loading="lazy" decoding="async"$1>'
		);

		return output;
	};

	$: renderedHtml = enhanceHtml(data.html);

	const metaAny = data.meta as Record<string, unknown>;

	const repoLink =
		(data.meta.repo ??
			(metaAny.repolink as string | null | undefined) ??
			(metaAny.repoLink as string | null | undefined) ??
			null) ||
		null;

	const articleLink =
		(data.meta.articleLink ??
			(metaAny.articlelink as string | null | undefined) ??
			(metaAny.articleLink as string | null | undefined) ??
			null) ||
		null;
</script>

<svelte:head>
	<title>{data.meta.title}</title>
	{#if data.meta.description}
		<meta name="description" content={data.meta.description} />
	{/if}
</svelte:head>

<section class="page">
	<div class="container">
		<header class="post-header">
			<h1 class="post-title">{data.meta.title}</h1>

			{#if data.meta.date || repoLink || articleLink}
				<div class="post-meta-bar">
					{#if data.meta.date}
						<time class="post-date" datetime={data.meta.date}>
							{formatDate(data.meta.date)}
						</time>
					{/if}

					{#if repoLink || articleLink}
						<nav class="meta-actions" aria-label="Link utili">
							{#if repoLink}
								<a
									class="meta-btn"
									href={toHref(repoLink)}
									target="_blank"
									rel="noopener noreferrer"
								>
									<span class="meta-ico" aria-hidden="true">
										<svg viewBox="0 0 24 24" width="16" height="16" fill="none">
											<path
												d="M9 18 3 12l6-6"
												stroke="currentColor"
												stroke-width="1.6"
												stroke-linecap="round"
												stroke-linejoin="round"
											/>
											<path
												d="m15 6 6 6-6 6"
												stroke="currentColor"
												stroke-width="1.6"
												stroke-linecap="round"
												stroke-linejoin="round"
											/>
										</svg>
									</span>
									Repo
								</a>
							{/if}

							{#if articleLink}
								<a
									class="meta-btn"
									href={toHref(articleLink)}
									target="_blank"
									rel="noopener noreferrer"
								>
									<span class="meta-ico" aria-hidden="true">
										<svg viewBox="0 0 24 24" width="16" height="16" fill="none">
											<path
												d="M14 5h5v5"
												stroke="currentColor"
												stroke-width="1.6"
												stroke-linecap="round"
												stroke-linejoin="round"
											/>
											<path
												d="M10 14 19 5"
												stroke="currentColor"
												stroke-width="1.6"
												stroke-linecap="round"
											/>
											<path
												d="M19 14v5a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2h5"
												stroke="currentColor"
												stroke-width="1.6"
												stroke-linecap="round"
												stroke-linejoin="round"
											/>
										</svg>
									</span>
									Articolo
								</a>
							{/if}
						</nav>
					{/if}
				</div>

				<hr class="post-divider" />
			{/if}
		</header>

		<article class="post">
			<div class="markdown">
				<!-- eslint-disable-next-line svelte/no-at-html-tags -->
				{@html renderedHtml}
			</div>
		</article>
	</div>
</section>

<style>
	.post-header {
		max-width: 48rem;
		margin: 0 auto 1rem;
	}

	.post-title {
		margin: 0;
		font-size: clamp(2.1rem, 4.6vw, 2.9rem);
		line-height: 1.15;
		letter-spacing: -0.02em;
		font-weight: 600;
	}

	.post-meta-bar {
		margin-top: 0.6rem;
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.75rem;
		flex-wrap: wrap;
	}

	.post-date {
		font-size: 0.95rem;
		color: var(--muted);
	}

	.meta-actions {
		display: flex;
		gap: 0.5rem;
		flex-wrap: wrap;
	}

	.meta-btn {
		display: inline-flex;
		align-items: center;
		gap: 0.4rem;
		padding: 0.35rem 0.6rem;
		border-radius: 999px;
		border: 1px solid var(--line);
		color: var(--muted);
		text-decoration: none;
		font-size: 0.92rem;
		transition:
			transform 120ms ease,
			box-shadow 120ms ease,
			border-color 120ms ease,
			color 120ms ease,
			background 120ms ease;
		background: rgba(255, 255, 255, 0.02);
	}

	.meta-ico {
		display: inline-flex;
		opacity: 0.9;
	}

	.meta-btn:hover {
		color: var(--fg);
		border-color: color-mix(in srgb, var(--accent) 35%, var(--line));
		transform: translateY(-1px);
	}

	.meta-btn:focus-visible {
		outline: 2px solid color-mix(in srgb, var(--accent) 55%, transparent);
		outline-offset: 2px;
	}

	.post-divider {
		margin: 1rem 0 0;
		border: 0;
		height: 1px;
		background: var(--line);
		opacity: 0.9;
	}

	.post {
		max-width: 48rem;
		margin: 0 auto;
		padding: 0;
		border: 0;
		border-radius: 0;
		background: transparent;
		box-shadow: none;
	}

	.markdown {
		color: var(--fg);
		font-size: 1rem;
		line-height: 1.75;
	}

	:global(.markdown > :first-child) {
		margin-top: 0;
	}

	:global(.markdown > :last-child) {
		margin-bottom: 0;
	}

	.markdown :global(h1),
	.markdown :global(h2),
	.markdown :global(h3),
	.markdown :global(h4),
	.markdown :global(h5),
	.markdown :global(h6) {
		font-weight: 600;
		line-height: 1.25;
		letter-spacing: -0.01em;
		scroll-margin-top: 96px;
	}

	.markdown :global(h1) {
		font-size: 1.55rem;
		margin: 2.1rem 0 0.8rem;
	}

	.markdown :global(h2) {
		font-size: 1.3rem;
		margin: 1.7rem 0 0.7rem;
	}

	.markdown :global(h3) {
		font-size: 1.12rem;
		margin: 1.35rem 0 0.6rem;
	}

	.markdown :global(h4) {
		font-size: 1.02rem;
		margin: 1.15rem 0 0.55rem;
	}

	.markdown :global(h5) {
		font-size: 0.96rem;
		margin: 1rem 0 0.5rem;
	}

	.markdown :global(h6) {
		font-size: 0.9rem;
		margin: 0.9rem 0 0.45rem;
	}

	.markdown :global(p) {
		margin: 0 0 1rem;
	}

	.markdown :global(ul) {
		list-style: disc;
	}

	.markdown :global(ol) {
		list-style: decimal;
	}

	.markdown :global(ul),
	.markdown :global(ol) {
		margin: 0 0 1rem;
		padding-left: 1.2rem;
	}

	.markdown :global(li) {
		margin: 0.35rem 0;
	}

	.markdown :global(blockquote) {
		margin: 1.1rem 0;
		padding: 0.75rem 1rem;
		border-left: 3px solid color-mix(in srgb, var(--accent) 45%, var(--line));
		border-radius: 14px;
		background: rgba(0, 0, 0, 0.03);
		color: color-mix(in srgb, var(--fg) 80%, var(--muted));
	}

	.markdown :global(a) {
		color: var(--accent);
		text-decoration: underline;
		text-underline-offset: 0.15em;
		text-decoration-thickness: 1px;
		word-break: break-word;
	}

	.markdown :global(a:hover) {
		text-decoration-thickness: 2px;
	}

	.markdown :global(code) {
		font-family:
			ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New',
			monospace;
		font-size: 0.92em;
		background: rgba(0, 0, 0, 0.05);
		border: 1px solid var(--line);
		padding: 0.12rem 0.35rem;
		border-radius: 10px;
	}

	.markdown :global(pre) {
		margin: 1.1rem 0;
		padding: 0.9rem 1rem;
		overflow: auto;
		border-radius: 16px;
		border: 1px solid var(--line);
		background: rgba(0, 0, 0, 0.03);
	}

	.markdown :global(pre code) {
		background: transparent;
		border: 0;
		padding: 0;
		font-size: 0.9em;
	}

	.markdown :global(.table-wrap) {
		margin: 1.25rem 0;
		overflow-x: auto;
		border: 1px solid var(--line);
		border-radius: 14px;
		background: rgba(0, 0, 0, 0.02);
	}

	.markdown :global(table) {
		width: 100%;
		min-width: 34rem;
		border-collapse: collapse;
	}

	.markdown :global(th),
	.markdown :global(td) {
		padding: 0.65rem 0.8rem;
		border-bottom: 1px solid var(--line);
		vertical-align: top;
	}

	.markdown :global(thead th) {
		font-weight: 600;
		text-align: left;
		background: rgba(0, 0, 0, 0.03);
	}

	.markdown :global(tr:last-child td) {
		border-bottom: 0;
	}

	.markdown :global(dl) {
		margin: 1.25rem 0;
	}

	.markdown :global(dt) {
		font-weight: 600;
	}

	.markdown :global(dd) {
		margin: 0.25rem 0 0.9rem 1.25rem;
		color: var(--muted);
	}

	.markdown :global(.footnotes) {
		margin-top: 2.5rem;
		font-size: 0.95em;
		color: var(--muted);
	}

	.markdown :global(.footnotes-sep) {
		margin: 2rem 0 1rem;
	}

	.markdown :global(.footnote-ref),
	.markdown :global(.footnote-backref) {
		text-decoration: none;
	}

	.markdown :global(abbr[title]) {
		text-decoration: underline dotted;
		cursor: help;
	}

	.markdown :global(ins) {
		text-decoration: none;
		border-bottom: 2px solid currentColor;
	}

	.markdown :global(mark) {
		padding: 0 0.2em;
		border-radius: 6px;
	}

	.markdown :global(sup),
	.markdown :global(sub) {
		font-size: 0.8em;
		line-height: 0;
	}

	.markdown :global(.warning) {
		margin: 1.25rem 0;
		padding: 0.85rem 1rem;
		border: 1px solid var(--line);
		border-left-width: 4px;
		border-radius: 14px;
		background: rgba(0, 0, 0, 0.02);
	}

	.markdown :global(.warning > :first-child) {
		margin-top: 0;
	}

	.markdown :global(.warning > :last-child) {
		margin-bottom: 0;
	}

	@media (max-width: 520px) {
		.post-title {
			font-size: clamp(1.9rem, 8vw, 2.4rem);
		}

		.markdown :global(h1) {
			font-size: 1.4rem;
		}
	}
</style>
