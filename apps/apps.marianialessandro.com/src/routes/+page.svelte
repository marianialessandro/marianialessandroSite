<script lang="ts">
	import { onMount } from 'svelte';
	import {
		loadPlaygroundState,
		resetPlaygroundState,
		savePlaygroundState,
		type PlaygroundCheckpoint
	} from '$lib/indexeddb';

	let draft = $state('');
	let checkpoints = $state<PlaygroundCheckpoint[]>([]);
	let updatedAt = $state<string | null>(null);
	let isLoading = $state(true);
	let isSaving = $state(false);
	let errorMessage = $state<string | null>(null);

	onMount(async () => {
		try {
			const state = await loadPlaygroundState();
			draft = state.draft;
			checkpoints = state.checkpoints;
			updatedAt = state.updatedAt;
		} catch (error) {
			errorMessage =
				error instanceof Error ? error.message : 'Errore inatteso durante il caricamento.';
		} finally {
			isLoading = false;
		}
	});

	async function persistState(nextDraft: string, nextCheckpoints: PlaygroundCheckpoint[]) {
		isSaving = true;
		errorMessage = null;

		const nextUpdatedAt = new Date().toISOString();

		try {
			await savePlaygroundState({
				draft: nextDraft,
				checkpoints: nextCheckpoints,
				updatedAt: nextUpdatedAt
			});

			draft = nextDraft;
			checkpoints = nextCheckpoints;
			updatedAt = nextUpdatedAt;
		} catch (error) {
			errorMessage =
				error instanceof Error ? error.message : 'Errore inatteso durante il salvataggio.';
		} finally {
			isSaving = false;
		}
	}

	async function handleDraftInput(event: Event) {
		const target = event.currentTarget as HTMLTextAreaElement;
		await persistState(target.value, checkpoints);
	}

	async function createCheckpoint() {
		const label = draft.trim();

		if (!label) {
			errorMessage = 'Scrivi qualcosa prima di salvare uno snapshot.';
			return;
		}

		const nextCheckpoint: PlaygroundCheckpoint = {
			id: crypto.randomUUID(),
			label,
			createdAt: new Date().toISOString()
		};

		await persistState(draft, [nextCheckpoint, ...checkpoints]);
	}

	async function clearIndexedDbState() {
		isSaving = true;
		errorMessage = null;

		try {
			const state = await resetPlaygroundState();
			draft = state.draft;
			checkpoints = state.checkpoints;
			updatedAt = state.updatedAt;
		} catch (error) {
			errorMessage =
				error instanceof Error ? error.message : 'Errore inatteso durante il reset.';
		} finally {
			isSaving = false;
		}
	}

	function formatDate(value: string | null): string {
		if (!value) {
			return 'Nessun salvataggio ancora disponibile.';
		}

		return new Intl.DateTimeFormat('it-IT', {
			dateStyle: 'medium',
			timeStyle: 'short'
		}).format(new Date(value));
	}
</script>

<svelte:head>
	<title>apps.marianialessandro.com</title>
	<meta
		name="description"
		content="Hub applicazioni di Alessandro Mariani su apps.marianialessandro.com con persistenza IndexedDB lato browser."
	/>
</svelte:head>

<section class="page">
	<header class="hero">
		<p class="eyebrow">Apps</p>
		<h1>apps.marianialessandro.com</h1>
		<p class="copy">
			Questa app usa IndexedDB nel browser per mantenere una bozza locale e una cronologia di
			snapshot anche dopo refresh o riapertura della pagina.
		</p>
	</header>

	<section class="panel">
		<div class="panel-header">
			<div>
				<p class="label">Playground IndexedDB</p>
				<h2>Persistenza locale pronta</h2>
			</div>
			<p class="status">{isLoading ? 'Caricamento...' : isSaving ? 'Salvataggio...' : 'Pronto'}</p>
		</div>

		<p class="meta">Ultimo aggiornamento: {formatDate(updatedAt)}</p>

		<label class="field">
			<span>Bozza persistita in IndexedDB</span>
			<textarea
				rows="8"
				value={draft}
				oninput={handleDraftInput}
				placeholder="Scrivi qui: il contenuto viene salvato localmente nel database del browser."
				disabled={isLoading}
			></textarea>
		</label>

		<div class="actions">
			<button type="button" class="primary" onclick={createCheckpoint} disabled={isLoading || isSaving}>
				Salva snapshot
			</button>
			<button type="button" class="secondary" onclick={clearIndexedDbState} disabled={isLoading || isSaving}>
				Resetta storage
			</button>
		</div>

		{#if errorMessage}
			<p class="error">{errorMessage}</p>
		{/if}
	</section>

	<section class="panel">
		<div class="panel-header">
			<div>
				<p class="label">Snapshot</p>
				<h2>Cronologia salvata nel browser</h2>
			</div>
			<p class="count">{checkpoints.length}</p>
		</div>

		{#if checkpoints.length === 0}
			<p class="empty">Nessuno snapshot presente. Il primo salvataggio finirà in IndexedDB.</p>
		{:else}
			<ul class="checkpoint-list">
				{#each checkpoints as checkpoint (checkpoint.id)}
					<li>
						<p>{checkpoint.label}</p>
						<span>{formatDate(checkpoint.createdAt)}</span>
					</li>
				{/each}
			</ul>
		{/if}
	</section>
</section>

<style>
	.page {
		width: var(--container);
		margin: 0 auto;
		padding: clamp(1.25rem, 3vw, 2rem) 0 3.5rem;
		display: grid;
		gap: 1.5rem;
	}

	.hero,
	.panel {
		position: relative;
		overflow: hidden;
		padding: clamp(1.5rem, 4vw, 2rem);
		border: 1px solid var(--line);
		border-radius: 2rem;
		background:
			linear-gradient(180deg, rgba(255, 255, 255, 0.95) 0%, rgba(252, 252, 251, 0.98) 100%);
		box-shadow: var(--shadow);
	}

	.hero::before,
	.panel::before {
		content: '';
		position: absolute;
		inset: 0;
		background:
			linear-gradient(90deg, rgba(0, 0, 0, 0.03) 1px, transparent 1px),
			linear-gradient(rgba(0, 0, 0, 0.03) 1px, transparent 1px);
		background-size: 24px 24px;
		mask-image: linear-gradient(to bottom, rgba(0, 0, 0, 0.18), rgba(0, 0, 0, 0));
		pointer-events: none;
	}

	.eyebrow,
	h1,
	.copy,
	.panel-header,
	.meta,
	.field,
	.actions,
	.error,
	.empty,
	.checkpoint-list {
		position: relative;
		z-index: 1;
	}

	.eyebrow,
	.label,
	.status,
	.count,
	.meta,
	.checkpoint-list span {
		color: var(--muted);
	}

	.eyebrow,
	.label {
		margin: 0 0 0.75rem;
		font-size: 0.875rem;
		font-weight: 700;
		letter-spacing: 0.16em;
		text-transform: uppercase;
	}

	h1,
	h2 {
		margin: 0;
		line-height: 0.96;
		letter-spacing: -0.05em;
		word-break: break-word;
	}

	h1 {
		font-size: clamp(2.1rem, 5vw, 3.5rem);
	}

	h2 {
		font-size: clamp(1.35rem, 3vw, 1.9rem);
	}

	.copy {
		max-width: 42rem;
		margin: 1.25rem 0 0;
		font-size: clamp(1rem, 2vw, 1.1rem);
		line-height: 1.65;
		color: var(--muted);
	}

	.panel-header {
		display: flex;
		align-items: start;
		justify-content: space-between;
		gap: 1rem;
	}

	.status,
	.count,
	.meta,
	.checkpoint-list span,
	.empty,
	.error {
		font-size: 0.95rem;
	}

	.meta {
		margin: 1rem 0 0;
	}

	.field {
		display: grid;
		gap: 0.75rem;
		margin-top: 1.25rem;
	}

	.field span {
		font-weight: 600;
	}

	textarea {
		width: 100%;
		border: 1px solid var(--line);
		border-radius: 1rem;
		padding: 1rem;
		resize: vertical;
		background: rgba(255, 255, 255, 0.92);
	}

	.actions {
		display: flex;
		flex-wrap: wrap;
		gap: 0.75rem;
		margin-top: 1rem;
	}

	button {
		border: 1px solid var(--line);
		border-radius: 999px;
		padding: 0.8rem 1.15rem;
		font-weight: 600;
		cursor: pointer;
		transition:
			transform 120ms ease,
			border-color 120ms ease,
			background-color 120ms ease;
	}

	button:hover:enabled {
		transform: translateY(-1px);
	}

	.primary {
		background: var(--fg);
		color: var(--bg);
		border-color: var(--fg);
	}

	.secondary {
		background: transparent;
		color: var(--fg);
	}

	button:disabled {
		cursor: wait;
		opacity: 0.65;
	}

	.error {
		margin: 1rem 0 0;
		color: #b42318;
	}

	.empty {
		position: relative;
		z-index: 1;
		margin: 1rem 0 0;
	}

	.checkpoint-list {
		list-style: none;
		padding: 0;
		margin: 1rem 0 0;
		display: grid;
		gap: 0.75rem;
	}

	.checkpoint-list li {
		display: grid;
		gap: 0.35rem;
		padding: 1rem;
		border-radius: 1rem;
		background: rgba(255, 255, 255, 0.7);
		border: 1px solid rgba(11, 15, 20, 0.08);
	}

	.checkpoint-list p {
		margin: 0;
		font-weight: 600;
	}

	@media (max-width: 640px) {
		.hero,
		.panel {
			border-radius: 1.5rem;
		}

		h1 {
			font-size: clamp(1.55rem, 7vw, 2rem);
			letter-spacing: -0.035em;
		}

		.panel-header {
			flex-direction: column;
		}
	}
</style>
