<script lang="ts">
	import type { FilesApiEntry } from '../files/archive';
	import FileArchiveCard from './FileArchiveCard.svelte';

	type Props = {
		files?: FilesApiEntry[];
		errorMessage?: string | null;
		isLoading?: boolean;
	};

	let { files = [], errorMessage = null, isLoading = false }: Props = $props();
</script>

<section class="archive" aria-labelledby="files-section-title">
	{#if errorMessage}
		<div class="state state-error" role="alert">
			<h2>Errore nel caricamento</h2>
			<p>{errorMessage}</p>
		</div>
	{:else if isLoading}
		<div class="state state-loading" aria-live="polite">
			<h2>Caricamento archivio</h2>
			<p>Sto recuperando i file disponibili dal backend.</p>
		</div>
	{:else if files.length === 0}
		<div class="state state-empty">
			<h2>Nessun file presente</h2>
			<p>Non ci sono file disponibili in questo momento.</p>
		</div>
	{:else}
		<div class="section-head">
			<div>
				<p class="section-kicker">Archivio</p>
				<h2 id="files-section-title" class="section-title">Documenti disponibili</h2>
			</div>
			<p class="section-caption">Ordine: file modificati più recentemente</p>
		</div>

		<div class="grid">
			{#each files as file (file.name)}
				<FileArchiveCard {file} />
			{/each}
		</div>
	{/if}
</section>

<style>
	.archive {
		display: grid;
		gap: 1rem;
	}

	.section-head {
		display: flex;
		align-items: end;
		justify-content: space-between;
		gap: 1rem;
	}

	.section-kicker {
		margin: 0 0 0.3rem;
		font-size: 0.8rem;
		font-weight: 700;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		color: var(--muted);
	}

	.section-title {
		margin: 0;
		font-size: clamp(1.3rem, 2.2vw, 1.7rem);
		letter-spacing: -0.03em;
	}

	.section-caption {
		margin: 0;
		font-size: 0.92rem;
		color: var(--muted);
	}

	.grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
		gap: 1rem;
	}

	.state {
		padding: clamp(1.7rem, 4vw, 3rem);
		border-radius: 1.75rem;
		text-align: center;
		border: 1px solid var(--line);
		background:
			linear-gradient(180deg, rgba(255, 255, 255, 0.96) 0%, rgba(252, 252, 251, 0.98) 100%);
		box-shadow: var(--shadow);
	}

	.state-error {
		border-color: color-mix(in srgb, #d44 28%, var(--line));
		background:
			linear-gradient(180deg, rgba(255, 255, 255, 1) 0%, rgba(255, 247, 247, 0.98) 100%);
	}

	.state-loading {
		border-style: dashed;
	}

	.state h2 {
		margin: 0 0 0.6rem;
		font-size: clamp(1.4rem, 2.4vw, 1.8rem);
		letter-spacing: -0.03em;
	}

	.state p {
		margin: 0;
		color: var(--muted);
	}

	@media (max-width: 720px) {
		.section-head {
			align-items: start;
			flex-direction: column;
		}

		.grid {
			grid-template-columns: 1fr;
		}
	}
</style>
