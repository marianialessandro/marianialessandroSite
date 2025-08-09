<script lang="ts">
	export let headings: { id: string; text: string; level: number }[] = [];
	export let activeId: string = '';

	const go = (id: string) => {
		const el = document.getElementById(id);
		if (!el) return;
		el.scrollIntoView({ behavior: 'smooth', block: 'start' });
		history.replaceState(null, '', `#${id}`);
	};
</script>

<nav class="toc" aria-label="Indice dell’articolo">
	<h2 class="toc-title">In questa pagina</h2>

	{#if headings.length === 0}
		<p class="toc-empty">Nessun titolo trovato.</p>
	{:else}
		<ul class="toc-list">
			{#each headings as h}
				<li class={`item lvl-${h.level} ${activeId === h.id ? 'active' : ''}`}>
					<button
						type="button"
						class="link"
						aria-current={activeId === h.id ? 'true' : undefined}
						on:click={() => go(h.id)}
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
		position: sticky;
		top: 96px; /* regola se hai una topbar */
		max-height: calc(100vh - 96px);
		overflow: auto;
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

	/* indentazione per livello (ora con H1) */
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
