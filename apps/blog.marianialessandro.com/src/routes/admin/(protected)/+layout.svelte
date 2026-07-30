<script lang="ts">
	import '@marianialessandro/shared/styles.css';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { fetchMe, logout, type AuthUser } from '$lib/admin/auth';

	type Props = { children: import('svelte').Snippet };
	let { children }: Props = $props();

	let user: AuthUser | null = $state(null);
	let checked = $state(false);
	let authError = $state('');

	onMount(checkSession);

	async function checkSession() {
		checked = false;
		authError = '';

		try {
			user = await fetchMe();
			if (!user) await goto(resolve('/admin/login'));
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
			await goto(resolve('/admin/login'));
		} catch (error) {
			authError = error instanceof Error ? error.message : 'Disconnessione non riuscita.';
		}
	}

	function isActive(path: string) {
		return page.url.pathname.replace(/\/$/, '') === path;
	}
</script>

{#if checked && authError}
	<div class="admin-auth-error" role="alert">
		<p>{authError}</p>
		<button type="button" onclick={checkSession}>Riprova</button>
	</div>
{:else if checked && user}
	<div class="admin-shell">
		<header class="admin-header">
			<div class="inner">
				<a class="brand" href={resolve('/admin')}>Admin · marianialessandro.com</a>

				<nav aria-label="Admin navigation">
					<a class:active={isActive('/admin')} href={resolve('/admin')}>Post</a>
					<a
						class:active={isActive('/admin/posts/new')}
						href={resolve('/admin/(protected)/posts/new')}>Nuovo post</a
					>
					<a class:active={isActive('/admin/account')} href={resolve('/admin/(protected)/account')}
						>Account</a
					>
				</nav>

				<div class="user-area">
					<span class="user-name">{user.name}</span>
					<button type="button" onclick={handleLogout}>Esci</button>
				</div>
			</div>
		</header>

		<main class="admin-main">
			{@render children()}
		</main>
	</div>
{:else if checked}
	<!-- redirecting to login, render nothing -->
{:else}
	<div class="admin-loading">Verifica sessione…</div>
{/if}

<style>
	.admin-loading {
		display: grid;
		place-items: center;
		min-height: 100vh;
		color: var(--muted, #4b5563);
	}

	.admin-auth-error {
		display: grid;
		place-items: center;
		align-content: center;
		gap: 0.75rem;
		min-height: 100vh;
		padding: 1.5rem;
		text-align: center;
	}

	.admin-auth-error p {
		margin: 0;
		color: #b91c1c;
	}

	.admin-auth-error button {
		min-height: 2.5rem;
		border: 0;
		border-radius: 999px;
		padding: 0 1rem;
		background: var(--accent, #ff3e00);
		color: #fff;
		font-weight: 700;
		cursor: pointer;
	}

	.admin-shell {
		display: flex;
		flex-direction: column;
		min-height: 100vh;
	}

	.admin-header {
		position: sticky;
		top: 0;
		z-index: 50;
		border-bottom: 1px solid var(--line, #e5e7eb);
		background: rgba(255, 255, 255, 0.94);
		backdrop-filter: blur(14px);
	}

	.inner {
		width: var(--container, min(1120px, calc(100% - 2rem)));
		margin: 0 auto;
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		justify-content: space-between;
		gap: 0.75rem 1rem;
		padding: 0.85rem 0;
	}

	.brand {
		font-weight: 700;
		text-decoration: none;
		color: var(--fg, #0b0f14);
	}

	nav {
		display: flex;
		align-items: center;
		gap: 0.35rem;
	}

	nav a {
		display: inline-flex;
		align-items: center;
		min-height: 2rem;
		border-radius: 999px;
		padding: 0 0.75rem;
		font-size: 0.92rem;
		text-decoration: none;
		color: var(--muted, #4b5563);
		white-space: nowrap;
	}

	nav a:hover,
	nav a.active {
		background: rgba(255, 62, 0, 0.08);
		color: var(--fg, #0b0f14);
	}

	.user-area {
		display: flex;
		align-items: center;
		gap: 0.6rem;
	}

	.user-name {
		color: var(--muted, #4b5563);
		font-size: 0.88rem;
	}

	.user-area button {
		min-height: 2.1rem;
		border: 1px solid var(--line, #e5e7eb);
		border-radius: 999px;
		padding: 0 0.9rem;
		background: #fff;
		color: var(--fg, #0b0f14);
		font-size: 0.88rem;
		font-weight: 600;
		cursor: pointer;
	}

	.user-area button:hover {
		border-color: rgba(255, 62, 0, 0.3);
		color: var(--accent, #ff3e00);
	}

	.admin-main {
		flex: 1;
		width: var(--container, min(1120px, calc(100% - 2rem)));
		margin: 0 auto;
		padding: clamp(1.5rem, 4vw, 2.25rem) 0 3.5rem;
	}
</style>
