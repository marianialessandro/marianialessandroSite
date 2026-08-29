<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { fetchMe, loginUrl, logout, type AuthUser } from '$lib/auth';

	let { children } = $props();

	let user: AuthUser | null = $state(null);
	let checked = $state(false);
	let authError = $state('');

	onMount(checkSession);

	async function checkSession() {
		checked = false;
		authError = '';

		try {
			user = await fetchMe();
			if (!user) {
				await goto(loginUrl());
			}
		} catch (error) {
			authError = error instanceof Error ? error.message : 'Impossibile verificare la sessione.';
		} finally {
			checked = true;
		}
	}

	async function handleLogout() {
		authError = '';

		try {
			await logout();
			await goto('/login');
		} catch (error) {
			authError = error instanceof Error ? error.message : 'Disconnessione non riuscita.';
		}
	}
</script>

{#if checked && authError}
	<section class="auth-state" role="alert">
		<p>{authError}</p>
		<button type="button" onclick={checkSession}>Riprova</button>
	</section>
{:else if checked && user}
	<div class="protected-shell">
		<div class="protected-toolbar">
			<div>
				<span class="badge">Area protetta</span>
				<span class="user-name">{user.name}</span>
			</div>
			<button type="button" onclick={handleLogout}>Esci</button>
		</div>

		{@render children()}
	</div>
{:else if checked}
	<!-- Redirecting to login. -->
{:else}
	<section class="auth-state" aria-live="polite">Verifica sessione…</section>
{/if}

<style>
	.auth-state {
		display: grid;
		place-items: center;
		align-content: center;
		gap: 0.8rem;
		min-height: 55vh;
		color: var(--muted);
		text-align: center;
	}

	.auth-state p {
		margin: 0;
		color: #b91c1c;
	}

	.auth-state button,
	.protected-toolbar button {
		min-height: 2.35rem;
		border: 1px solid var(--line);
		border-radius: 999px;
		background: #fff;
		padding: 0 0.95rem;
		font: inherit;
		font-size: 0.86rem;
		font-weight: 700;
		color: var(--fg);
		cursor: pointer;
	}

	.protected-shell {
		padding-bottom: 4rem;
	}

	.protected-toolbar {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1rem;
		margin-bottom: 1.5rem;
		padding: 0.85rem 0;
		border-bottom: 1px solid var(--line);
	}

	.protected-toolbar > div {
		display: flex;
		align-items: center;
		gap: 0.7rem;
		min-width: 0;
	}

	.badge {
		border-radius: 999px;
		background: rgba(212, 74, 32, 0.1);
		padding: 0.28rem 0.6rem;
		color: var(--accent);
		font-size: 0.75rem;
		font-weight: 700;
	}

	.user-name {
		overflow: hidden;
		color: var(--muted);
		font-size: 0.86rem;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
</style>
