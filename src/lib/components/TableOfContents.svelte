<script lang="ts">
	import { goto } from '$app/navigation';

	export let headings: { id: string; text: string; level: number }[] = [];
	export let activeId = '';

	const go = async (id: string) => {
		const element = document.getElementById(id);
		if (!element) return;

		element.scrollIntoView({ behavior: 'smooth', block: 'start' });
		await goto(`#${id}`, {
			replaceState: true,
			noScroll: true,
			keepFocus: true
		});
	};
</script>

<nav class="toc" aria-label="Indice dell’articolo">
	<h2 class="toc-title">In questa pagina</h2>

	{#if headings.length === 0}
		<p class="toc-empty">Nessun titolo trovato.</p>
	{:else}
		<ul class="toc-list">
			{#each headings as h (h.id)}
				<li class={`item lvl-${h.level} ${activeId === h.id ? 'active' : ''}`}>
					<a
						class="link"
						href={`#${h.id}`}
						aria-current={activeId === h.id ? 'location' : undefined}
						on:click|preventDefault={() => go(h.id)}
					>
						{h.text}
					</a>
				</li>
			{/each}
		</ul>
	{/if}
</nav>

<style>
	.toc {
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
		display: block;
		padding: 0.2rem;
		color: var(--post-text);
		text-decoration: none;
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
