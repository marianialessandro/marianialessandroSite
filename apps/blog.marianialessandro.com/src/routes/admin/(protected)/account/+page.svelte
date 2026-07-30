<script lang="ts">
	import { onMount } from 'svelte';
	import { authedFetch } from '$lib/admin/auth';

	type AccountUser = { id: number; name: string; email: string; created_at: string };

	let users: AccountUser[] = [];
	let loading = true;
	let error = '';
	let busyId: number | null = null;

	let showCreate = false;
	let createName = '';
	let createEmail = '';
	let createPassword = '';
	let creating = false;

	let editingId: number | null = null;
	let editName = '';
	let editEmail = '';
	let editPassword = '';
	let saving = false;

	async function loadUsers() {
		loading = true;
		error = '';
		try {
			const res = await authedFetch('/users');
			if (!res.ok) throw new Error('Impossibile caricare gli account.');
			const { data } = await res.json();
			users = data;
		} catch (err) {
			error = err instanceof Error ? err.message : 'Errore imprevisto.';
		} finally {
			loading = false;
		}
	}

	onMount(loadUsers);

	async function handleCreate() {
		creating = true;
		error = '';
		try {
			const res = await authedFetch('/users', {
				method: 'POST',
				body: JSON.stringify({ name: createName, email: createEmail, password: createPassword })
			});
			if (!res.ok) {
				const body = await res.json().catch(() => null);
				const message = body?.errors
					? Object.values(body.errors).flat().join(' ')
					: (body?.message ?? 'Creazione non riuscita.');
				throw new Error(message);
			}
			createName = '';
			createEmail = '';
			createPassword = '';
			showCreate = false;
			await loadUsers();
		} catch (err) {
			error = err instanceof Error ? err.message : 'Errore imprevisto.';
		} finally {
			creating = false;
		}
	}

	function startEdit(user: AccountUser) {
		editingId = user.id;
		editName = user.name;
		editEmail = user.email;
		editPassword = '';
	}

	function cancelEdit() {
		editingId = null;
	}

	async function saveEdit(userId: number) {
		saving = true;
		error = '';
		try {
			const payload: Record<string, string> = { name: editName, email: editEmail };
			if (editPassword) payload.password = editPassword;

			const res = await authedFetch(`/users/${userId}`, {
				method: 'PUT',
				body: JSON.stringify(payload)
			});
			if (!res.ok) {
				const body = await res.json().catch(() => null);
				const message = body?.errors
					? Object.values(body.errors).flat().join(' ')
					: (body?.message ?? 'Aggiornamento non riuscito.');
				throw new Error(message);
			}
			editingId = null;
			await loadUsers();
		} catch (err) {
			error = err instanceof Error ? err.message : 'Errore imprevisto.';
		} finally {
			saving = false;
		}
	}

	async function deleteUser(user: AccountUser) {
		if (!confirm(`Eliminare l'account "${user.name}"?`)) return;

		busyId = user.id;
		try {
			const res = await authedFetch(`/users/${user.id}`, { method: 'DELETE' });
			if (!res.ok) {
				const body = await res.json().catch(() => null);
				throw new Error(body?.message ?? 'Eliminazione non riuscita.');
			}
			await loadUsers();
		} catch (err) {
			error = err instanceof Error ? err.message : 'Errore imprevisto.';
		} finally {
			busyId = null;
		}
	}
</script>

<svelte:head>
	<title>Account - Admin</title>
</svelte:head>

<div class="account-header">
	<h1>Account</h1>
	<button type="button" on:click={() => (showCreate = !showCreate)}>
		{showCreate ? 'Annulla' : 'Nuovo account'}
	</button>
</div>

{#if error}
	<p class="error" role="alert">{error}</p>
{/if}

{#if showCreate}
	<form class="create-form" on:submit|preventDefault={handleCreate}>
		<label>
			<span>Nome</span>
			<input type="text" bind:value={createName} required />
		</label>
		<label>
			<span>Email</span>
			<input type="email" bind:value={createEmail} required />
		</label>
		<label>
			<span>Password</span>
			<input
				type="password"
				bind:value={createPassword}
				minlength="12"
				autocomplete="new-password"
				required
			/>
		</label>
		<button type="submit" class="primary" disabled={creating}>
			{creating ? 'Creazione…' : 'Crea account'}
		</button>
	</form>
{/if}

{#if loading}
	<p class="muted">Caricamento…</p>
{:else}
	<div class="user-table">
		{#each users as user (user.id)}
			<div class="user-row">
				{#if editingId === user.id}
					<form class="edit-form" on:submit|preventDefault={() => saveEdit(user.id)}>
						<label>
							<span>Nome</span>
							<input type="text" bind:value={editName} required />
						</label>
						<label>
							<span>Email</span>
							<input type="email" bind:value={editEmail} required />
						</label>
						<label>
							<span>Nuova password (opzionale)</span>
							<input
								type="password"
								bind:value={editPassword}
								minlength="12"
								autocomplete="new-password"
							/>
						</label>
						<div class="edit-actions">
							<button type="button" on:click={cancelEdit}>Annulla</button>
							<button type="submit" class="primary" disabled={saving}>
								{saving ? 'Salvataggio…' : 'Salva'}
							</button>
						</div>
					</form>
				{:else}
					<div class="user-main">
						<strong>{user.name}</strong>
						<span class="muted">{user.email}</span>
					</div>
					<div class="user-actions">
						<button type="button" on:click={() => startEdit(user)}>Modifica</button>
						<button
							type="button"
							class="danger"
							disabled={busyId === user.id}
							on:click={() => deleteUser(user)}
						>
							Elimina
						</button>
					</div>
				{/if}
			</div>
		{/each}
	</div>
{/if}

<style>
	.account-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1rem;
		margin-bottom: 1.25rem;
	}

	.account-header h1 {
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

	.create-form,
	.edit-form {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(11rem, 1fr));
		gap: 0.75rem;
		align-items: end;
		border: 1px solid var(--line, #e5e7eb);
		border-radius: var(--radius, 16px);
		padding: 1rem;
		margin-bottom: 1rem;
	}

	label {
		display: grid;
		gap: 0.3rem;
		font-size: 0.85rem;
		color: var(--muted, #4b5563);
	}

	input {
		min-height: 2.5rem;
		border: 1px solid rgba(0, 0, 0, 0.12);
		border-radius: var(--radius, 16px);
		padding: 0 0.75rem;
		font: inherit;
		color: var(--fg, #0b0f14);
	}

	.edit-actions {
		display: flex;
		gap: 0.5rem;
	}

	.user-table {
		display: grid;
		gap: 0.65rem;
	}

	.user-row {
		border: 1px solid var(--line, #e5e7eb);
		border-radius: var(--radius, 16px);
		padding: 0.9rem 1rem;
		background: #fff;
	}

	.user-row:has(.user-main) {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		justify-content: space-between;
		gap: 0.75rem;
	}

	.user-main {
		display: flex;
		flex-direction: column;
		gap: 0.15rem;
	}

	.user-actions {
		display: flex;
		gap: 0.5rem;
	}

	button {
		min-height: 2.4rem;
		border: 1px solid var(--line, #e5e7eb);
		border-radius: 999px;
		padding: 0 1rem;
		background: #fff;
		color: var(--fg, #0b0f14);
		font-weight: 600;
		cursor: pointer;
	}

	button.primary {
		border-color: transparent;
		background: var(--accent, #ff3e00);
		color: #fff;
	}

	button.danger {
		color: #b91c1c;
	}

	button.danger:hover {
		border-color: rgba(220, 38, 38, 0.4);
	}

	button:disabled {
		opacity: 0.6;
		cursor: default;
	}
</style>
