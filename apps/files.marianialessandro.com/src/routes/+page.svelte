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
		<h1>marianialessandro.com</h1>
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

	h1 {
		position: relative;
		z-index: 1;
		margin: 0;
		font-size: clamp(2.1rem, 5vw, 3.5rem);
		line-height: 0.96;
		letter-spacing: -0.05em;
		word-break: break-word;
	}

	@media (max-width: 640px) {
		.hero {
			border-radius: 1.5rem;
		}
	}
</style>
