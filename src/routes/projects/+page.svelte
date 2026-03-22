<script lang="ts">
	export let data: {
		projects: Array<{
			slug: string;
			title: string;
			date: string | null;
			description: string | null;
		}>;
	};

	const formatDate = (value: string | null) => {
		if (!value) return null;

		const parsed = new Date(value);
		if (Number.isNaN(parsed.getTime())) return value;

		return parsed.toLocaleDateString('it-IT', {
			day: '2-digit',
			month: '2-digit',
			year: 'numeric'
		});
	};
</script>

<section class="page">
	<div class="container">
		<header class="projects-header">
			<h1>Projects</h1>
			<p class="projects-subtitle">
				Una selezione dei progetti più recenti. Clicca una card per aprire il dettaglio.
			</p>
		</header>

		{#if data.projects.length === 0}
			<p class="projects-empty">Nessun progetto pubblicato al momento.</p>
		{:else}
			<ul class="projects-list">
				{#each data.projects as p (p.slug)}
					<li class="card lift">
						<a class="projects-link" href={`/projects/${p.slug}`}>
							<div class="projects-main">
								<div class="projects-title">{p.title}</div>

								{#if p.description}
									<div class="projects-desc">{p.description}</div>
								{/if}
							</div>

							{#if p.date}
								<time class="projects-date" datetime={p.date}>
									{formatDate(p.date)}
								</time>
							{/if}
						</a>
					</li>
				{/each}
			</ul>
		{/if}
	</div>
</section>

<style>
	.projects-header {
		margin-bottom: 1.5rem;
	}

	.projects-subtitle {
		margin: 0.5rem 0 0;
		max-width: 60ch;
		color: var(--muted);
		line-height: 1.6;
	}

	.projects-empty {
		color: var(--muted);
	}

	.projects-list {
		list-style: none;
		padding: 0;
		margin: 0;
		display: grid;
		gap: 0.9rem;
	}

	.projects-link {
		display: flex;
		gap: 1.25rem;
		justify-content: space-between;
		align-items: flex-start;
		padding: 1rem 1.125rem;
		text-decoration: none;
		color: inherit;
		border-radius: var(--radius);
	}

	.projects-link:hover {
		color: inherit;
	}

	.projects-link:hover .projects-title {
		color: var(--accent);
	}

	.projects-title {
		font-weight: 600;
		letter-spacing: -0.01em;
	}

	.projects-desc {
		margin-top: 0.4rem;
		color: var(--muted);
		line-height: 1.6;
	}

	.projects-date {
		color: var(--muted);
		font-size: 0.9rem;
		white-space: nowrap;
		padding-top: 0.15rem;
	}

	@media (max-width: 520px) {
		.projects-link {
			flex-direction: column;
			gap: 0.65rem;
		}

		.projects-date {
			padding-top: 0;
		}
	}
</style>
