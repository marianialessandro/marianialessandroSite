<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import { login } from '$lib/auth';

	let email = '';
	let password = '';
	let error = '';
	let loading = false;

	function safeRedirect(): string {
		const requested = page.url.searchParams.get('redirect') ?? '/protected';
		return requested.startsWith('/protected') ? requested : '/protected';
	}

	async function handleSubmit() {
		error = '';
		loading = true;

		try {
			await login(email, password);
			await goto(safeRedirect());
		} catch (err) {
			error = err instanceof Error ? err.message : 'Accesso non riuscito.';
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head>
	<title>Accedi — Apps</title>
</svelte:head>

<section class="login-page">
	<form class="login-card" on:submit|preventDefault={handleSubmit}>
		<p class="eyebrow">apps.marianialessandro.com</p>
		<h1>Accedi alle applicazioni protette</h1>
		<p class="intro">Usa le stesse credenziali dell'area amministrativa del blog.</p>

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
</section>

<style>
	.login-page {
		display: grid;
		place-items: center;
		min-height: calc(100vh - 9rem);
		padding: 3rem 0 5rem;
	}

	.login-card {
		display: grid;
		gap: 0.9rem;
		width: min(26rem, 100%);
		border: 1px solid var(--line);
		border-radius: 1rem;
		background: rgba(255, 255, 255, 0.72);
		padding: clamp(1.5rem, 4vw, 2rem);
		box-shadow: 0 1.25rem 4rem rgba(21, 21, 21, 0.08);
	}

	.eyebrow {
		margin: 0;
		color: var(--accent);
		font-family: var(--font-mono);
		font-size: 0.76rem;
		font-weight: 700;
		letter-spacing: 0.12em;
		text-transform: uppercase;
	}

	h1 {
		margin: 0;
		font-size: clamp(1.7rem, 5vw, 2.3rem);
		letter-spacing: -0.04em;
		line-height: 1.05;
	}

	.intro {
		margin: 0 0 0.4rem;
		color: var(--muted);
		line-height: 1.55;
	}

	label {
		display: grid;
		gap: 0.35rem;
		font-size: 0.9rem;
		color: var(--muted);
	}

	input {
		min-height: 2.75rem;
		border: 1px solid var(--line);
		border-radius: 0.75rem;
		background: #fff;
		padding: 0 0.85rem;
		font: inherit;
		color: var(--fg);
	}

	.error {
		margin: 0;
		border-radius: 0.75rem;
		background: rgba(185, 28, 28, 0.08);
		color: #b91c1c;
		font-size: 0.88rem;
		padding: 0.7rem 0.8rem;
	}

	button {
		min-height: 2.8rem;
		border: 0;
		border-radius: 999px;
		background: var(--fg);
		color: var(--bg);
		font-weight: 700;
		cursor: pointer;
	}

	button:disabled {
		opacity: 0.6;
		cursor: default;
	}
</style>
