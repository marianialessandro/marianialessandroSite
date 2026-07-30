<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { login } from '$lib/admin/auth';

	let email = '';
	let password = '';
	let error = '';
	let loading = false;

	async function handleSubmit() {
		error = '';
		loading = true;

		try {
			await login(email, password);
			await goto(resolve('/admin'));
		} catch (err) {
			error = err instanceof Error ? err.message : 'Accesso non riuscito.';
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head>
	<title>Accedi - Admin</title>
</svelte:head>

<div class="login-page">
	<form class="login-card" on:submit|preventDefault={handleSubmit}>
		<p class="eyebrow">marianialessandro.com</p>
		<h1>Accedi all'area admin</h1>

		<label>
			<span>Email</span>
			<input type="email" bind:value={email} autocomplete="username" required />
		</label>

		<label>
			<span>Password</span>
			<input type="password" bind:value={password} autocomplete="current-password" required />
		</label>

		{#if error}
			<p class="error" role="alert">{error}</p>
		{/if}

		<button type="submit" disabled={loading}>
			{loading ? 'Accesso in corso…' : 'Accedi'}
		</button>
	</form>
</div>

<style>
	.login-page {
		display: grid;
		place-items: center;
		min-height: 100vh;
		padding: 1.5rem;
		background: var(--bg, #fff);
	}

	.login-card {
		display: grid;
		gap: 0.9rem;
		width: min(24rem, 100%);
		border: 1px solid var(--line, #e5e7eb);
		border-radius: var(--radius, 16px);
		box-shadow: var(--shadow, 0 1px 2px rgba(0, 0, 0, 0.06));
		background: #fff;
		padding: clamp(1.5rem, 4vw, 2rem);
	}

	.eyebrow {
		margin: 0;
		color: var(--muted, #4b5563);
		font-size: 0.85rem;
		font-weight: 700;
		letter-spacing: 0.08em;
		text-transform: uppercase;
	}

	h1 {
		margin: 0 0 0.25rem;
		font-size: 1.5rem;
		font-weight: 700;
		letter-spacing: 0;
	}

	label {
		display: grid;
		gap: 0.35rem;
		font-size: 0.9rem;
		color: var(--muted, #4b5563);
	}

	input {
		min-height: 2.65rem;
		border: 1px solid rgba(0, 0, 0, 0.12);
		border-radius: var(--radius, 16px);
		padding: 0 0.85rem;
		font: inherit;
		color: var(--fg, #0b0f14);
	}

	.error {
		margin: 0;
		border-radius: 10px;
		background: rgba(220, 38, 38, 0.08);
		color: #b91c1c;
		font-size: 0.88rem;
		padding: 0.6rem 0.75rem;
	}

	button {
		min-height: 2.75rem;
		border: none;
		border-radius: 999px;
		background: var(--accent, #ff3e00);
		color: #fff;
		font-weight: 700;
		cursor: pointer;
		transition: opacity 140ms ease;
	}

	button:disabled {
		opacity: 0.6;
		cursor: default;
	}

	button:not(:disabled):hover {
		opacity: 0.9;
	}
</style>
