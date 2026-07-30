<script lang="ts">
	type Heading = { id: string; text: string; level: number };
	type Props = {
		headings?: Heading[];
		activeId?: string;
	};

	let { headings = [], activeId = '' }: Props = $props();

	const go = (id: string) => {
		const el = document.getElementById(id);
		if (!el) return;
		el.scrollIntoView({ behavior: 'smooth', block: 'start' });
		history.replaceState(null, '', `#${id}`);
	};
</script>

<nav class="toc" aria-label="Post table of contents">
	<h2 class="toc-title">On this page</h2>

	{#if headings.length === 0}
		<p class="toc-empty">No headings found.</p>
	{:else}
		<ul class="toc-list">
			{#each headings as h (h.id)}
				<li class={`item lvl-${h.level} ${activeId === h.id ? 'active' : ''}`}>
					<button
						type="button"
						class="link"
						aria-current={activeId === h.id ? 'true' : undefined}
						onclick={() => go(h.id)}
					>
						{h.text}
					</button>
				</li>
			{/each}
		</ul>
	{/if}
</nav>

<style>
	.toc {
		/* Sticky positioning is handled by the aside. */
		max-height: none;
		overflow: visible;
		padding: 12px 8px;
		font-family: var(--post-font-sans, system-ui, sans-serif);
	}

	.toc-title {
		margin: 0 0 0.6rem 0;
		font-size: 0.9rem;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: var(--post-muted);
	}

	.toc-empty {
		color: var(--post-muted);
		font-size: 0.95rem;
	}

	.toc-list {
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.item {
		margin: 0.2rem 0;
	}

	/* Level indentation, now including H1. */
	.lvl-1 {
		padding-left: 0;
	}
	.lvl-2 {
		padding-left: 0.8rem;
	}
	.lvl-3 {
		padding-left: 1.6rem;
	}
	.lvl-4 {
		padding-left: 2.4rem;
	}

	.link {
		background: none;
		border: 0;
		padding: 0.2rem 0.2rem;
		cursor: pointer;
		text-align: left;
		width: 100%;
		font: inherit;
		color: var(--post-text);
		opacity: 0.9;
	}
	.link:hover {
		opacity: 1;
		text-decoration: underline;
	}

	.active > .link {
		font-weight: 600;
		opacity: 1;
	}
</style>
