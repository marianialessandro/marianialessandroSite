<script lang="ts">
	import {
		ArrowRightAltOutline,
		FileImageSolid,
		FileLinesSolid,
		FilePdfSolid,
		FileSolid,
		FileZipSolid
	} from 'flowbite-svelte-icons';
	import {
		formatBytes,
		formatDate,
		getDisplayName,
		getExtensionLabel,
		getFileKind,
		type FilesApiEntry
	} from '../files/archive';

	type Props = {
		file: FilesApiEntry;
	};

	let { file }: Props = $props();

	const title = $derived(getDisplayName(file.name));
	const extensionLabel = $derived(getExtensionLabel(file.name));
	const fileKind = $derived(getFileKind(file.name));
	const sizeLabel = $derived(
		file.size_human && file.size_human.trim() !== ''
			? file.size_human
			: formatBytes(file.size_bytes ?? 0)
	);
	const modifiedLabel = $derived(file.modified_iso ? formatDate(file.modified_iso) : 'Non disponibile');
</script>

<a
	class="card"
	href={file.url}
	target="_blank"
	rel="noopener noreferrer"
	title={file.name}
	aria-label={`Apri ${title}`}
>
	<div class="card-top">
		<div class="file-icon" aria-hidden="true">
			{#if fileKind === 'image'}
				<FileImageSolid width="1.45rem" height="1.45rem" />
			{:else if fileKind === 'pdf'}
				<FilePdfSolid width="1.45rem" height="1.45rem" />
			{:else if fileKind === 'text'}
				<FileLinesSolid width="1.45rem" height="1.45rem" />
			{:else if fileKind === 'archive'}
				<FileZipSolid width="1.45rem" height="1.45rem" />
			{:else}
				<FileSolid width="1.45rem" height="1.45rem" />
			{/if}
		</div>

		<div class="ext">{extensionLabel}</div>
	</div>

	<div class="card-body">
		<h3 class="name">{title}</h3>

		<div class="spacer"></div>

		<div class="meta">
			<div class="meta-row">
				<span class="meta-label">Dimensione</span>
				<span class="meta-value">{sizeLabel}</span>
			</div>

			<div class="meta-row">
				<span class="meta-label">Modificato</span>
				<span class="meta-value">{modifiedLabel}</span>
			</div>
		</div>

		<div class="card-arrow">
			Apri file
			<span class="arrow-icon">
				<ArrowRightAltOutline width="0.95rem" height="0.95rem" ariaLabel="Apri file" />
			</span>
		</div>
	</div>
</a>

<style>
	.card {
		position: relative;
		display: flex;
		flex-direction: column;
		min-height: 220px;
		padding: 1.15rem;
		border-radius: 1.5rem;
		border: 1px solid var(--line);
		background:
			linear-gradient(180deg, rgba(255, 255, 255, 0.96) 0%, rgba(252, 252, 251, 0.98) 100%);
		box-shadow: var(--shadow);
		overflow: hidden;
		text-decoration: none;
		transition:
			transform 160ms ease,
			box-shadow 160ms ease,
			border-color 160ms ease;
	}

	.card::after {
		content: '';
		position: absolute;
		inset: 0;
		background: linear-gradient(
			135deg,
			rgba(255, 62, 0, 0.03),
			transparent 34%,
			transparent 68%,
			rgba(0, 0, 0, 0.035)
		);
		pointer-events: none;
	}

	.card:hover {
		transform: translateY(-4px);
		box-shadow:
			0 18px 36px rgba(11, 15, 20, 0.08),
			0 6px 18px rgba(255, 62, 0, 0.08);
		border-color: color-mix(in srgb, var(--accent) 24%, var(--line));
	}

	.card-top,
	.card-body {
		position: relative;
		z-index: 1;
	}

	.card-top {
		display: flex;
		align-items: flex-start;
		justify-content: space-between;
		gap: 0.9rem;
		margin-bottom: 1.4rem;
	}

	.file-icon {
		display: grid;
		place-items: center;
		width: 3.1rem;
		height: 3.1rem;
		border-radius: 1rem;
		border: 1px solid color-mix(in srgb, var(--accent) 12%, var(--line));
		background: color-mix(in srgb, white 84%, #fff0ea);
	}

	.ext {
		padding: 0.45rem 0.7rem;
		border: 1px solid var(--line);
		border-radius: 999px;
		background: rgba(255, 255, 255, 0.9);
		font-size: 0.7rem;
		font-weight: 800;
		letter-spacing: 0.08em;
		color: var(--muted);
	}

	.card-body {
		display: flex;
		flex: 1;
		flex-direction: column;
	}

	.name {
		margin: 0;
		font-size: clamp(1.15rem, 2vw, 1.35rem);
		line-height: 1.15;
		letter-spacing: -0.03em;
		word-break: break-word;
		overflow-wrap: anywhere;
	}

	.spacer {
		flex: 1;
		min-height: 1rem;
	}

	.meta {
		display: grid;
		gap: 0.65rem;
		padding-top: 1rem;
		border-top: 1px solid color-mix(in srgb, var(--line) 74%, white);
	}

	.meta-row {
		display: flex;
		align-items: flex-start;
		justify-content: space-between;
		gap: 0.75rem;
		font-size: 0.92rem;
	}

	.meta-label {
		color: var(--muted);
	}

	.meta-value {
		font-weight: 600;
		text-align: right;
	}

	.card-arrow {
		display: inline-flex;
		align-items: center;
		gap: 0.45rem;
		margin-top: 1rem;
		font-size: 0.84rem;
		font-weight: 600;
		color: var(--muted);
	}

	.arrow-icon {
		display: inline-grid;
		place-items: center;
		transition: transform 160ms ease;
	}

	.card:hover .arrow-icon {
		transform: translateX(2px);
	}

	@media (max-width: 640px) {
		.card {
			min-height: auto;
			padding: 1rem;
			border-radius: 1.25rem;
		}

		.meta-row {
			flex-direction: column;
			gap: 0.2rem;
		}

		.meta-value {
			text-align: left;
		}
	}
</style>
