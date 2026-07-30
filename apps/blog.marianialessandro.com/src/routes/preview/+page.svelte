<script lang="ts">
	import { onMount } from 'svelte';
	import PostLayout from '$lib/layouts/PostLayout.svelte';
	import { renderMarkdown } from '$lib/markdown';

	type Draft = {
		title: string;
		description?: string;
		date: string;
		tags: string[];
		content: string;
	};

	let draft: Draft | null = null;
	let checked = false;

	onMount(() => {
		const raw = localStorage.getItem('admin_preview_draft');
		draft = raw ? JSON.parse(raw) : null;
		checked = true;
	});
</script>

<svelte:head>
	<title>{draft ? `Anteprima: ${draft.title}` : 'Anteprima'}</title>
</svelte:head>

{#if checked}
	{#if draft}
		<div class="preview-banner">Anteprima — non pubblicato</div>
		<PostLayout contentHtml={renderMarkdown(draft.content)} meta={draft} />
	{:else}
		<div class="empty-state">
			<p>Nessuna bozza da visualizzare.</p>
			<p class="muted">Torna all'editor e clicca "Anteprima" per vedere qui il post.</p>
		</div>
	{/if}
{/if}

<style>
	.preview-banner {
		position: sticky;
		top: 0;
		z-index: 60;
		background: #1d4ed8;
		color: #fff;
		text-align: center;
		font-size: 0.85rem;
		font-weight: 700;
		letter-spacing: 0.02em;
		padding: 0.5rem;
	}

	.empty-state {
		display: grid;
		place-items: center;
		min-height: 50vh;
		text-align: center;
		gap: 0.35rem;
	}

	.muted {
		color: var(--muted, #4b5563);
	}
</style>
