<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { authedFetch } from '$lib/admin/auth';
	import { throwIfError } from '$lib/admin/errors';
	import {
		fromApiSummary,
		toApiPayload,
		type ApiPostSummary,
		type PostInput,
		type PostSummary
	} from '$lib/posts';
	import PostEditorForm from '$lib/admin/PostEditorForm.svelte';

	const id = Number(page.params.id);

	let loading = true;
	let loadError = '';
	let submitting = false;
	let initial: Partial<PostInput> | null = null;
	let existingPosts: PostSummary[] = [];

	onMount(async () => {
		try {
			const [postRes, allRes] = await Promise.all([
				authedFetch(`/admin/posts/${id}`),
				authedFetch('/admin/posts')
			]);

			if (!postRes.ok) throw new Error('Post non trovato.');
			const { data } = await postRes.json();

			initial = {
				slug: data.slug,
				title: data.title,
				description: data.description ?? undefined,
				content: data.content,
				date: data.date,
				tags: data.tags ?? [],
				draft: data.draft,
				cover: data.cover ?? undefined,
				featured: data.featured,
				featuredRank: data.featured_rank ?? undefined
			};

			if (allRes.ok) {
				const { data: all }: { data: ApiPostSummary[] } = await allRes.json();
				existingPosts = all.map(fromApiSummary);
			}
		} catch (err) {
			loadError = err instanceof Error ? err.message : 'Errore imprevisto.';
		} finally {
			loading = false;
		}
	});

	async function handleSave(input: PostInput) {
		submitting = true;
		try {
			const res = await authedFetch(`/posts/${id}`, {
				method: 'PUT',
				body: JSON.stringify(toApiPayload(input))
			});
			await throwIfError(res);
			await goto(resolve('/admin'));
		} finally {
			submitting = false;
		}
	}

	async function handleDelete() {
		if (!confirm('Eliminare definitivamente questo post?')) return;

		submitting = true;
		try {
			const res = await authedFetch(`/posts/${id}`, { method: 'DELETE' });
			await throwIfError(res);
			await goto(resolve('/admin'));
		} finally {
			submitting = false;
		}
	}
</script>

<svelte:head>
	<title>Modifica post - Admin</title>
</svelte:head>

<div class="page-header">
	<h1>Modifica post</h1>
</div>

{#if loadError}
	<p class="error" role="alert">{loadError}</p>
{/if}

{#if loading}
	<p class="muted">Caricamento…</p>
{:else if initial}
	<PostEditorForm
		{initial}
		{submitting}
		{existingPosts}
		currentPostId={id}
		onSave={handleSave}
		onDelete={handleDelete}
	/>
{/if}

<style>
	.page-header {
		margin-bottom: 1.25rem;
	}

	.page-header h1 {
		margin: 0;
		font-size: 1.6rem;
	}

	.muted {
		color: var(--muted, #4b5563);
	}

	.error {
		margin-bottom: 1rem;
		border-radius: 10px;
		background: rgba(220, 38, 38, 0.08);
		color: #b91c1c;
		font-size: 0.9rem;
		padding: 0.6rem 0.75rem;
	}
</style>
