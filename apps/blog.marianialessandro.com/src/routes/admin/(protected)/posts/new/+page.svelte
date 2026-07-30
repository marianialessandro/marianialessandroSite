<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
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

	let submitting = false;
	let existingPosts: PostSummary[] = [];

	onMount(async () => {
		const res = await authedFetch('/admin/posts');
		if (res.ok) {
			const { data }: { data: ApiPostSummary[] } = await res.json();
			existingPosts = data.map(fromApiSummary);
		}
	});

	async function handleSave(input: PostInput) {
		submitting = true;
		try {
			const res = await authedFetch('/posts', {
				method: 'POST',
				body: JSON.stringify(toApiPayload(input))
			});
			await throwIfError(res);
			await goto(resolve('/admin'));
		} finally {
			submitting = false;
		}
	}
</script>

<svelte:head>
	<title>Nuovo post - Admin</title>
</svelte:head>

<div class="page-header">
	<h1>Nuovo post</h1>
</div>

<PostEditorForm {submitting} {existingPosts} onSave={handleSave} />

<style>
	.page-header {
		margin-bottom: 1.25rem;
	}

	.page-header h1 {
		margin: 0;
		font-size: 1.6rem;
	}
</style>
