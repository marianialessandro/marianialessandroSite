<script lang="ts">
	import { onMount } from 'svelte';
	import { resolve } from '$app/paths';
	import { authedFetch } from '$lib/admin/auth';
	import { fromApiSummary, type ApiPostSummary, type PostSummary } from '$lib/posts';

	let posts: PostSummary[] = [];
	let loading = true;
	let error = '';
	let busyId: number | null = null;

	async function loadPosts() {
		loading = true;
		error = '';

		try {
			const res = await authedFetch('/admin/posts');
			if (!res.ok) throw new Error('Impossibile caricare i post.');
			const { data }: { data: ApiPostSummary[] } = await res.json();
			posts = data.map(fromApiSummary);
		} catch (err) {
			error = err instanceof Error ? err.message : 'Errore imprevisto.';
		} finally {
			loading = false;
		}
	}

	onMount(loadPosts);

	function postStatus(post: PostSummary): 'draft' | 'scheduled' | 'published' {
		if (post.draft) return 'draft';
		return new Date(post.date).getTime() > Date.now() ? 'scheduled' : 'published';
	}

	const statusLabel: Record<'draft' | 'scheduled' | 'published', string> = {
		draft: 'Bozza',
		scheduled: 'Programmato',
		published: 'Pubblicato'
	};

	async function togglePublish(post: PostSummary) {
		busyId = post.id;
		try {
			const current = await authedFetch(`/posts/${post.id}`);
			if (!current.ok) throw new Error('Impossibile leggere il post.');
			const { data: full } = await current.json();

			const res = await authedFetch(`/posts/${post.id}`, {
				method: 'PUT',
				body: JSON.stringify({
					slug: full.slug,
					title: full.title,
					description: full.description,
					date: full.date,
					tags: full.tags,
					draft: !post.draft,
					cover: full.cover,
					featured: full.featured,
					featured_rank: full.featured_rank,
					content: full.content
				})
			});
			if (!res.ok) throw new Error('Aggiornamento non riuscito.');
			await loadPosts();
		} catch (err) {
			error = err instanceof Error ? err.message : 'Errore imprevisto.';
		} finally {
			busyId = null;
		}
	}

	async function deletePost(post: PostSummary) {
		if (!confirm(`Eliminare definitivamente "${post.title}"?`)) return;

		busyId = post.id;
		try {
			const res = await authedFetch(`/posts/${post.id}`, { method: 'DELETE' });
			if (!res.ok) throw new Error('Eliminazione non riuscita.');
			await loadPosts();
		} catch (err) {
			error = err instanceof Error ? err.message : 'Errore imprevisto.';
		} finally {
			busyId = null;
		}
	}
</script>

<svelte:head>
	<title>Post - Admin</title>
</svelte:head>

<div class="dashboard">
	<header class="dashboard-header">
		<h1>Post</h1>
		<a class="new-post" href={resolve('/admin/(protected)/posts/new')}>Nuovo post</a>
	</header>

	{#if error}
		<p class="error" role="alert">{error}</p>
	{/if}

	{#if loading}
		<p class="muted">Caricamento…</p>
	{:else if posts.length === 0}
		<p class="muted">Nessun post ancora. Crea il primo.</p>
	{:else}
		<div class="post-table">
			{#each posts as post (post.id)}
				<div class="post-row">
					<div class="post-main">
						<span class="badge {postStatus(post)}">
							{statusLabel[postStatus(post)]}
						</span>
						<strong>{post.title}</strong>
						<span class="muted">/{post.slug} · {post.date}</span>
					</div>

					<div class="post-actions">
						<button
							type="button"
							disabled={busyId === post.id}
							on:click={() => togglePublish(post)}
						>
							{post.draft ? 'Pubblica' : 'Nascondi'}
						</button>
						<a href={resolve('/admin/(protected)/posts/[id]', { id: String(post.id) })}>Modifica</a>
						<button
							type="button"
							class="danger"
							disabled={busyId === post.id}
							on:click={() => deletePost(post)}
						>
							Elimina
						</button>
					</div>
				</div>
			{/each}
		</div>
	{/if}
</div>

<style>
	.dashboard {
		display: grid;
		gap: 1.25rem;
	}

	.dashboard-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1rem;
	}

	.dashboard-header h1 {
		margin: 0;
		font-size: 1.6rem;
	}

	.new-post {
		display: inline-flex;
		align-items: center;
		min-height: 2.4rem;
		border-radius: 999px;
		padding: 0 1rem;
		background: var(--accent, #ff3e00);
		color: #fff;
		font-weight: 700;
		text-decoration: none;
		font-size: 0.9rem;
	}

	.muted {
		color: var(--muted, #4b5563);
	}

	.error {
		border-radius: 10px;
		background: rgba(220, 38, 38, 0.08);
		color: #b91c1c;
		font-size: 0.9rem;
		padding: 0.6rem 0.75rem;
	}

	.post-table {
		display: grid;
		gap: 0.65rem;
	}

	.post-row {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		justify-content: space-between;
		gap: 0.75rem;
		border: 1px solid var(--line, #e5e7eb);
		border-radius: var(--radius, 16px);
		padding: 0.9rem 1rem;
		background: #fff;
	}

	.post-main {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: 0.6rem;
		min-width: 0;
	}

	.badge {
		display: inline-flex;
		border-radius: 999px;
		padding: 0.15rem 0.6rem;
		font-size: 0.72rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		background: rgba(16, 185, 129, 0.12);
		color: #047857;
	}

	.badge.draft {
		background: rgba(217, 119, 6, 0.12);
		color: #b45309;
	}

	.badge.scheduled {
		background: rgba(37, 99, 235, 0.12);
		color: #1d4ed8;
	}

	.post-actions {
		display: flex;
		align-items: center;
		gap: 0.5rem;
	}

	.post-actions button,
	.post-actions a {
		display: inline-flex;
		align-items: center;
		min-height: 2.1rem;
		border: 1px solid var(--line, #e5e7eb);
		border-radius: 999px;
		padding: 0 0.85rem;
		background: #fff;
		color: var(--fg, #0b0f14);
		font-size: 0.85rem;
		font-weight: 600;
		text-decoration: none;
		cursor: pointer;
	}

	.post-actions button:hover,
	.post-actions a:hover {
		border-color: rgba(255, 62, 0, 0.3);
		color: var(--accent, #ff3e00);
	}

	.post-actions button.danger:hover {
		border-color: rgba(220, 38, 38, 0.4);
		color: #b91c1c;
	}

	.post-actions button:disabled {
		opacity: 0.6;
		cursor: default;
	}
</style>
