<script lang="ts">
	import { onMount } from 'svelte';
	import {
		FileArchive,
		resolveFilesSiteUrl,
		type FilesApiEntry,
		type FilesApiResponse
	} from '@marianialessandro/shared';

	let files = $state<FilesApiEntry[]>([]);
	let errorMessage = $state<string | null>(null);
	let isLoading = $state(true);

	onMount(async () => {
		try {
			const response = await fetch(resolveApiUrl(), {
				headers: {
					accept: 'application/json'
				}
			});

			if (!response.ok) {
				throw new Error(`Errore API HTTP ${response.status}.`);
			}

			const payload = (await response.json()) as FilesApiResponse;

			if (!payload.success) {
				throw new Error(payload.error || 'Errore sconosciuto.');
			}

			files = Array.isArray(payload.files)
				? payload.files.map((file) => ({
						...file,
						url: resolveFilesSiteUrl(file.url)
					}))
				: [];
		} catch (error) {
			errorMessage =
				error instanceof Error ? error.message : 'Impossibile contattare l’API.';
		} finally {
			isLoading = false;
		}
	});

	function resolveApiUrl(): string {
		if (typeof window === 'undefined') {
			return '/api/';
		}

		if (
			window.location.hostname === 'localhost' ||
			window.location.hostname === '127.0.0.1'
		) {
			return 'https://files.marianialessandro.com/api/';
		}

		return '/api/';
	}
</script>

<svelte:head>
	<title>files.marianialessandro.com</title>
	<meta
		name="description"
		content="Archivio documenti e appunti disponibile su files.marianialessandro.com."
	/>
</svelte:head>

<section class="page">
	<header class="hero">
		<div class="hero-grid">
			<div class="hero-copy">
				<p class="eyebrow">
					<span class="eyebrow-dot"></span>
					Notes Archive
				</p>
				<h1>files.marianialessandro.com</h1>
				<p class="lede">
					Una versione SvelteKit dell’archivio file, costruita sul backend PHP gi&agrave;
					esistente e allineata allo stile del progetto principale.
				</p>
			</div>

			<div class="hero-meta">
				<div class="stat-card">
					<span class="stat-label">File trovati</span>
					<strong>{files.length}</strong>
				</div>
				<div class="stat-card">
					<span class="stat-label">Sorgente dati</span>
					<strong>/api/</strong>
				</div>
			</div>
		</div>
	</header>

	<FileArchive {files} {errorMessage} {isLoading} />
</section>

<style>
	.page {
		width: var(--container);
		margin: 0 auto;
		padding: clamp(1.25rem, 3vw, 2rem) 0 3.5rem;
	}

	.hero {
		position: relative;
		overflow: hidden;
		padding: clamp(1.5rem, 4vw, 2rem);
		margin-bottom: 1.5rem;
		border: 1px solid var(--line);
		border-radius: 2rem;
		background:
			linear-gradient(180deg, rgba(255, 255, 255, 0.95) 0%, rgba(252, 252, 251, 0.98) 100%);
		box-shadow: var(--shadow);
	}

	.hero::before {
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

	.hero-grid {
		position: relative;
		z-index: 1;
		display: grid;
		gap: 1.25rem;
	}

	.eyebrow {
		display: inline-flex;
		align-items: center;
		gap: 0.5rem;
		margin: 0 0 0.9rem;
		padding: 0.45rem 0.8rem;
		border: 1px solid var(--line);
		border-radius: 999px;
		background: rgba(255, 255, 255, 0.8);
		font-size: 0.76rem;
		font-weight: 700;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		color: var(--muted);
	}

	.eyebrow-dot {
		width: 0.45rem;
		height: 0.45rem;
		border-radius: 999px;
		background: var(--accent);
		display: inline-block;
	}

	h1 {
		margin: 0;
		font-size: clamp(2.1rem, 5vw, 3.5rem);
		line-height: 0.96;
		letter-spacing: -0.05em;
		word-break: break-word;
	}

	.lede {
		max-width: 60ch;
		margin: 0.9rem 0 0;
		font-size: clamp(1rem, 1.7vw, 1.12rem);
		color: var(--muted);
	}

	.hero-meta {
		display: grid;
		grid-template-columns: repeat(2, minmax(0, 1fr));
		gap: 0.85rem;
	}

	.stat-card {
		display: grid;
		gap: 0.25rem;
		padding: 0.95rem 1rem;
		border: 1px solid var(--line);
		border-radius: 1.25rem;
		background: rgba(255, 255, 255, 0.82);
	}

	.stat-label {
		font-size: 0.82rem;
		color: var(--muted);
	}

	.stat-card strong {
		font-size: clamp(1.1rem, 2.2vw, 1.4rem);
		letter-spacing: -0.03em;
	}

	@media (min-width: 900px) {
		.hero-grid {
			grid-template-columns: 1.4fr 0.6fr;
			align-items: end;
		}
	}

	@media (max-width: 640px) {
		.hero {
			border-radius: 1.5rem;
		}

		.hero-meta {
			grid-template-columns: 1fr;
		}
	}
</style>
