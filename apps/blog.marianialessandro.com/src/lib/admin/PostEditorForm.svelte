<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { beforeNavigate } from '$app/navigation';
	import EasyMDE from 'easymde';
	import 'easymde/dist/easymde.min.css';
	import '@fortawesome/fontawesome-free/css/all.min.css';
	import { renderMarkdown } from '$lib/markdown';
	import { slugify } from '$lib/admin/slug';
	import { pickImageFile, uploadImage } from '$lib/admin/uploads';
	import { getAvailableTags, type PostInput, type PostSummary } from '$lib/posts';
	import { ApiValidationError } from '$lib/admin/errors';

	export let initial: Partial<PostInput> = {};
	export let submitting = false;
	export let onSave: (input: PostInput, draft: boolean) => Promise<void>;
	export let onDelete: (() => Promise<void>) | null = null;
	export let existingPosts: PostSummary[] = [];
	export let currentPostId: number | null = null;

	let title = initial.title ?? '';
	let slug = initial.slug ?? '';
	let slugTouched = Boolean(initial.slug);
	let description = initial.description ?? '';
	let date = initial.date ?? new Date().toISOString().slice(0, 10);
	let tags: string[] = initial.tags ?? [];
	let tagInput = '';
	let cover = initial.cover ?? '';
	let uploadingCover = false;
	let featured = initial.featured ?? false;
	let featuredRank: number | '' = initial.featuredRank ?? '';
	let content = initial.content ?? '';

	let textareaEl: HTMLTextAreaElement;
	let easyMDE: EasyMDE | null = null;
	let topError = '';
	let fieldErrors: Record<string, string> = {};
	let suppressGuard = false;
	let initialSnapshot = '';

	$: if (!slugTouched) slug = slugify(title);

	$: slugConflict = existingPosts.some(
		(post) => post.slug === slug.trim() && post.id !== currentPostId
	);

	$: tagSuggestions = getAvailableTags(existingPosts)
		.filter(
			(tag) =>
				!tags.some((existing) => existing.toLowerCase() === tag.value) &&
				(tagInput.trim() ? tag.value.includes(tagInput.trim().toLowerCase()) : true)
		)
		.slice(0, 8);

	$: otherFeatured = existingPosts
		.filter((post) => post.featured && post.id !== currentPostId)
		.sort((a, b) => (a.featuredRank ?? 999) - (b.featuredRank ?? 999));

	function snapshot() {
		return JSON.stringify({
			title,
			slug,
			description,
			date,
			tags,
			cover,
			featured,
			featuredRank,
			content
		});
	}

	onMount(() => {
		easyMDE = new EasyMDE({
			element: textareaEl,
			initialValue: content,
			autofocus: false,
			spellChecker: false,
			status: ['autosave', 'lines', 'words', 'cursor'],
			autosave: {
				enabled: true,
				uniqueId: 'admin-post-' + (initial.slug ?? 'new'),
				delay: 2000
			},
			previewRender: (plainText) => renderMarkdown(plainText),
			toolbar: [
				'bold',
				'italic',
				'heading',
				'|',
				'quote',
				'unordered-list',
				'ordered-list',
				'|',
				'link',
				'image',
				{
					name: 'upload-image',
					action: handleContentImageUpload,
					className: 'fa fa-upload',
					title: 'Carica immagine'
				},
				'table',
				'horizontal-rule',
				'|',
				'preview',
				'side-by-side',
				'fullscreen',
				'|',
				'guide'
			]
		});

		easyMDE.codemirror.on('change', () => {
			content = easyMDE!.value();
		});

		// EasyMDE's autosave may restore a different draft than `initial`;
		// snapshot only after it has settled so the unsaved-changes guard
		// compares against what's actually in the editor.
		content = easyMDE.value();
		initialSnapshot = snapshot();
	});

	onDestroy(() => {
		easyMDE?.toTextArea();
		easyMDE = null;
	});

	async function handleContentImageUpload(editor: EasyMDE) {
		const file = await pickImageFile();
		if (!file) return;

		try {
			const url = await uploadImage(file);
			editor.codemirror.getDoc().replaceSelection(`![](${url})`);
		} catch (err) {
			topError = err instanceof Error ? err.message : 'Caricamento immagine non riuscito.';
		}
	}

	async function handleCoverUpload() {
		const file = await pickImageFile();
		if (!file) return;

		uploadingCover = true;
		try {
			cover = await uploadImage(file);
		} catch (err) {
			topError = err instanceof Error ? err.message : 'Caricamento immagine non riuscito.';
		} finally {
			uploadingCover = false;
		}
	}

	function handleSlugInput() {
		slugTouched = true;
	}

	function addTag(raw: string) {
		const value = raw.trim();
		if (value && !tags.some((tag) => tag.toLowerCase() === value.toLowerCase())) {
			tags = [...tags, value];
		}
		tagInput = '';
	}

	function removeTag(value: string) {
		tags = tags.filter((tag) => tag !== value);
	}

	function handleTagKeydown(event: KeyboardEvent) {
		if (event.key === 'Enter' || event.key === ',') {
			event.preventDefault();
			addTag(tagInput);
		} else if (event.key === 'Backspace' && !tagInput && tags.length > 0) {
			tags = tags.slice(0, -1);
		}
	}

	function buildInput(draft: boolean): PostInput {
		return {
			slug: slug.trim(),
			title: title.trim(),
			description: description.trim() || undefined,
			content: easyMDE?.value() ?? content,
			date,
			tags,
			draft,
			cover: cover.trim() || undefined,
			featured,
			featuredRank: featured && featuredRank !== '' ? Number(featuredRank) : undefined
		};
	}

	async function handleSaveClick(draft: boolean) {
		topError = '';
		fieldErrors = {};
		suppressGuard = true;

		try {
			await onSave(buildInput(draft), draft);
			initialSnapshot = snapshot();
		} catch (err) {
			suppressGuard = false;
			if (err instanceof ApiValidationError) {
				fieldErrors = err.fieldErrors;
			} else {
				topError = err instanceof Error ? err.message : 'Errore imprevisto.';
			}
		}
	}

	async function handleDeleteClick() {
		if (!onDelete) return;

		suppressGuard = true;
		try {
			await onDelete();
		} catch (err) {
			suppressGuard = false;
			topError = err instanceof Error ? err.message : 'Eliminazione non riuscita.';
		}
	}

	function handlePreview() {
		localStorage.setItem(
			'admin_preview_draft',
			JSON.stringify({
				title,
				description,
				date,
				tags,
				content: easyMDE?.value() ?? content
			})
		);
		window.open('/preview', '_blank');
	}

	beforeNavigate((navigation) => {
		if (suppressGuard) return;
		if (snapshot() === initialSnapshot) return;
		if (!confirm('Ci sono modifiche non salvate. Vuoi davvero uscire?')) {
			navigation.cancel();
		}
	});

	function handleBeforeUnload(event: BeforeUnloadEvent) {
		if (suppressGuard || snapshot() === initialSnapshot) return;
		event.preventDefault();
		event.returnValue = '';
	}
</script>

<svelte:window on:beforeunload={handleBeforeUnload} />

<div class="editor">
	{#if topError}
		<p class="banner-error" role="alert">{topError}</p>
	{/if}

	<div class="fields">
		<label class="field-title">
			<span>Titolo</span>
			<input type="text" bind:value={title} placeholder="Titolo del post" required />
		</label>

		<label>
			<span>Slug</span>
			<input type="text" bind:value={slug} on:input={handleSlugInput} required />
			{#if slugConflict}
				<span class="field-warning">Questo slug è già in uso da un altro post.</span>
			{/if}
			{#if fieldErrors.slug}
				<span class="field-error">{fieldErrors.slug}</span>
			{/if}
		</label>

		<label>
			<span>Data</span>
			<input type="date" bind:value={date} required />
			<span class="field-hint">Una data futura programma la pubblicazione.</span>
			{#if fieldErrors.date}
				<span class="field-error">{fieldErrors.date}</span>
			{/if}
		</label>

		<label class="field-wide">
			<span>Descrizione</span>
			<input type="text" bind:value={description} placeholder="Breve sommario per l'archivio" />
		</label>

		<div class="field-wide">
			<span class="tags-label">Tag</span>
			<div class="tags-input">
				{#each tags as tag (tag)}
					<span class="tag-chip">
						{tag}
						<button type="button" aria-label={`Rimuovi tag ${tag}`} on:click={() => removeTag(tag)}
							>×</button
						>
					</span>
				{/each}
				<input
					type="text"
					bind:value={tagInput}
					on:keydown={handleTagKeydown}
					placeholder="Aggiungi un tag…"
				/>
			</div>
			{#if tagSuggestions.length}
				<div class="tag-suggestions">
					{#each tagSuggestions as suggestion (suggestion.value)}
						<button type="button" on:click={() => addTag(suggestion.label)}>
							{suggestion.label}
						</button>
					{/each}
				</div>
			{/if}
		</div>

		<label>
			<span>Copertina (URL)</span>
			<div class="cover-row">
				<input type="text" bind:value={cover} placeholder="https://…" />
				<button type="button" disabled={uploadingCover} on:click={handleCoverUpload}>
					{uploadingCover ? 'Carico…' : 'Carica'}
				</button>
			</div>
		</label>

		<label class="field-checkbox">
			<input type="checkbox" bind:checked={featured} />
			<span>In evidenza in home</span>
		</label>

		{#if featured}
			<label>
				<span>Ordine in evidenza</span>
				<input type="number" bind:value={featuredRank} min="0" />
				{#if otherFeatured.length}
					<span class="field-hint">
						Altri in evidenza:
						{#each otherFeatured as post, i (post.id)}
							{i > 0 ? ', ' : ''}{post.featuredRank ?? '—'}·{post.title}
						{/each}
					</span>
				{/if}
			</label>
		{/if}
	</div>

	{#if fieldErrors.content}
		<p class="field-error">{fieldErrors.content}</p>
	{/if}

	<textarea bind:this={textareaEl} class="markdown-source"></textarea>

	<div class="actions">
		<button type="button" on:click={handlePreview}>Anteprima</button>

		{#if onDelete}
			<button type="button" class="danger" disabled={submitting} on:click={handleDeleteClick}>
				Elimina
			</button>
		{/if}

		<div class="save-actions">
			<button type="button" disabled={submitting} on:click={() => handleSaveClick(true)}>
				Salva come bozza
			</button>
			<button
				type="button"
				class="primary"
				disabled={submitting}
				on:click={() => handleSaveClick(false)}
			>
				Pubblica
			</button>
		</div>
	</div>
</div>

<style>
	.editor {
		display: grid;
		gap: 1.5rem;
	}

	.banner-error {
		margin: 0;
		border-radius: 10px;
		background: rgba(220, 38, 38, 0.08);
		color: #b91c1c;
		font-size: 0.9rem;
		padding: 0.6rem 0.75rem;
	}

	.fields {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(11rem, 1fr));
		gap: 1rem;
	}

	.field-title,
	.field-wide {
		grid-column: 1 / -1;
	}

	label {
		display: grid;
		gap: 0.35rem;
		font-size: 0.85rem;
		color: var(--muted, #4b5563);
	}

	.field-checkbox {
		display: flex;
		flex-direction: row;
		align-items: center;
		gap: 0.5rem;
		font-size: 0.9rem;
	}

	.field-warning {
		color: #b45309;
		font-size: 0.8rem;
	}

	.field-error {
		color: #b91c1c;
		font-size: 0.8rem;
	}

	.field-hint {
		color: var(--muted, #4b5563);
		font-size: 0.78rem;
	}

	input[type='text'],
	input[type='date'],
	input[type='number'] {
		min-height: 2.5rem;
		border: 1px solid rgba(0, 0, 0, 0.12);
		border-radius: var(--radius, 16px);
		padding: 0 0.75rem;
		font: inherit;
		color: var(--fg, #0b0f14);
	}

	.field-title input {
		font-size: 1.15rem;
		font-weight: 700;
	}

	.cover-row {
		display: flex;
		gap: 0.5rem;
	}

	.cover-row input {
		flex: 1;
	}

	.cover-row button {
		min-height: 2.5rem;
		border: 1px solid var(--line, #e5e7eb);
		border-radius: var(--radius, 16px);
		padding: 0 1rem;
		background: #fff;
		color: var(--fg, #0b0f14);
		font-weight: 600;
		cursor: pointer;
		white-space: nowrap;
	}

	.tags-label {
		display: block;
		margin-bottom: 0.35rem;
	}

	.tags-input {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: 0.4rem;
		min-height: 2.5rem;
		border: 1px solid rgba(0, 0, 0, 0.12);
		border-radius: var(--radius, 16px);
		padding: 0.35rem 0.6rem;
	}

	.tags-input input {
		flex: 1;
		min-width: 8rem;
		border: none;
		padding: 0.25rem;
		font: inherit;
		color: var(--fg, #0b0f14);
	}

	.tags-input input:focus {
		outline: none;
	}

	.tag-chip {
		display: inline-flex;
		align-items: center;
		gap: 0.35rem;
		border-radius: 999px;
		padding: 0.15rem 0.35rem 0.15rem 0.7rem;
		background: rgba(255, 62, 0, 0.08);
		color: var(--fg, #0b0f14);
		font-size: 0.85rem;
	}

	.tag-chip button {
		border: none;
		background: transparent;
		color: var(--muted, #4b5563);
		font-size: 1rem;
		line-height: 1;
		cursor: pointer;
		padding: 0.1rem 0.3rem;
	}

	.tag-suggestions {
		display: flex;
		flex-wrap: wrap;
		gap: 0.4rem;
		margin-top: 0.4rem;
	}

	.tag-suggestions button {
		border: 1px dashed var(--line, #e5e7eb);
		border-radius: 999px;
		padding: 0.15rem 0.65rem;
		background: #fff;
		color: var(--muted, #4b5563);
		font-size: 0.8rem;
		cursor: pointer;
	}

	.tag-suggestions button:hover {
		border-color: rgba(255, 62, 0, 0.4);
		color: var(--accent, #ff3e00);
	}

	.markdown-source {
		display: none;
	}

	.actions {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		justify-content: space-between;
		gap: 0.75rem;
		border-top: 1px solid var(--line, #e5e7eb);
		padding-top: 1rem;
	}

	.save-actions {
		display: flex;
		gap: 0.6rem;
		margin-left: auto;
	}

	.actions button {
		min-height: 2.5rem;
		border: 1px solid var(--line, #e5e7eb);
		border-radius: 999px;
		padding: 0 1.1rem;
		background: #fff;
		color: var(--fg, #0b0f14);
		font-weight: 600;
		cursor: pointer;
	}

	.actions button.primary {
		border-color: transparent;
		background: var(--accent, #ff3e00);
		color: #fff;
	}

	.actions button.danger {
		border-color: rgba(220, 38, 38, 0.3);
		color: #b91c1c;
	}

	.actions button:disabled {
		opacity: 0.6;
		cursor: default;
	}
</style>
