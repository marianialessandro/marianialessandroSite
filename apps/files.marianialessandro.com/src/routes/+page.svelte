<svelte:head>
	<title>files.marianialessandro.com</title>
	<meta
		name="description"
		content="Workspace test app for files.marianialessandro.com using the shared package."
	/>
</svelte:head>

<section class="page">
	<p class="eyebrow">files.marianialessandro.com</p>
	<h1>Shared workspace is active</h1>
	<p>
		This app imports the shared stylesheet and shared footer from
		<code>@marianialessandro/shared</code>.
	</p>
</section>

<style>
	.page {
		width: min(100%, 48rem);
		margin: 0 auto;
		padding: 4rem 0;
	}

	.eyebrow {
		margin: 0 0 0.5rem;
		color: var(--muted);
		letter-spacing: 0.06em;
		text-transform: uppercase;
	}

	h1 {
		margin: 0 0 1rem;
	}
</style>
