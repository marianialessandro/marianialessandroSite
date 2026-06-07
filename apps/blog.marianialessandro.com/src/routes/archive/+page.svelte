<script lang="ts">
	import PostMeta from '$lib/components/PostMeta.svelte';
	import TagList from '$lib/components/TagList.svelte';
	import type { PostSummary } from '$lib/posts';

	export let data: {
		groupedPosts?: Array<{
			year: string;
			posts: PostSummary[];
		}>;
		postCount?: number;
	};

	const groupedPosts = data?.groupedPosts ?? [];
	const postCount = data?.postCount ?? 0;
</script>

<svelte:head>
	<title>Archive - marianialessandro.com</title>
	<meta name="description" content="All articles and notes from marianialessandro.com" />
</svelte:head>

<section class="page" aria-labelledby="archive-title">
	<header class="archive-header">
		<p>Archive</p>
		<h1 id="archive-title">All posts</h1>
		<span>{postCount} {postCount === 1 ? 'article' : 'articles'}</span>
	</header>

	{#if groupedPosts.length === 0}
		<div class="empty-state">
			<h2>No posts yet</h2>
			<p>Check back soon for new notes.</p>
		</div>
	{:else}
		<div class="year-groups">
			{#each groupedPosts as group (group.year)}
				<section class="year-group" aria-labelledby={`year-${group.year}`}>
					<h2 id={`year-${group.year}`}>{group.year}</h2>

					<div class="post-list">
						{#each group.posts as post (post.slug)}
							<a class="post-row" href={`/${post.slug}`} data-sveltekit-preload-data="hover">
								<div class="post-main">
									<PostMeta date={post.date} compact />
									<h3>{post.title}</h3>
									{#if post.description}
										<p>{post.description}</p>
									{/if}
								</div>

								<TagList tags={post.tags} compact />
							</a>
						{/each}
					</div>
				</section>
			{/each}
		</div>
	{/if}
</section>

<style>
	.page {
		width: var(--container);
		margin: 0 auto;
		padding: clamp(1.5rem, 4vw, 2.5rem) 0 3.5rem;
	}

	.archive-header {
		display: grid;
		grid-template-columns: minmax(0, 1fr);
		gap: 0.35rem;
		padding-bottom: clamp(1.25rem, 3vw, 1.75rem);
		border-bottom: 1px solid var(--line);
	}

	.archive-header p,
	.archive-header h1,
	.archive-header span,
	.empty-state h2,
	.empty-state p {
		margin: 0;
	}

	.archive-header p {
		color: var(--muted);
		font-size: 0.9rem;
		font-weight: 700;
		letter-spacing: 0.08em;
		text-transform: uppercase;
	}

	.archive-header h1 {
		font-size: clamp(2rem, 5vw, 3.5rem);
		line-height: 1;
		font-weight: 700;
		letter-spacing: 0;
	}

	.archive-header span {
		color: var(--muted);
		font-size: 0.98rem;
	}

	.year-groups {
		display: grid;
		gap: clamp(1.5rem, 4vw, 2.25rem);
		padding-top: clamp(1.5rem, 4vw, 2.25rem);
	}

	.year-group {
		display: grid;
		grid-template-columns: 1fr;
		gap: 0.85rem;
	}

	.year-group h2 {
		margin: 0;
		color: var(--muted);
		font-size: 1rem;
		font-weight: 700;
		letter-spacing: 0;
	}

	.post-list {
		display: grid;
		gap: 0.65rem;
	}

	.post-row {
		display: grid;
		grid-template-columns: minmax(0, 1fr);
		gap: 0.8rem;
		border: 1px solid rgba(0, 0, 0, 0.09);
		border-radius: var(--radius);
		padding: 1rem;
		background: #fff;
		color: var(--fg);
		text-decoration: none;
		box-shadow: 0 1px 2px rgba(0, 0, 0, 0.04);
		transition:
			transform 140ms ease,
			box-shadow 140ms ease,
			border-color 140ms ease;
	}

	.post-row:hover {
		transform: translateY(-1px);
		border-color: rgba(255, 62, 0, 0.3);
		box-shadow: var(--shadow);
	}

	.post-main {
		min-width: 0;
	}

	.post-main h3 {
		margin: 0.35rem 0 0;
		font-size: clamp(1.05rem, 2vw, 1.25rem);
		line-height: 1.3;
		font-weight: 700;
		letter-spacing: 0;
	}

	.post-main p {
		margin: 0.45rem 0 0;
		color: var(--muted);
		line-height: 1.55;
	}

	.empty-state {
		margin-top: 1.5rem;
		border: 1px solid var(--line);
		border-radius: var(--radius);
		background: #fff;
		padding: clamp(1rem, 3vw, 1.5rem);
		box-shadow: var(--shadow);
	}

	.empty-state h2 {
		font-size: clamp(1.35rem, 2.4vw, 1.8rem);
		line-height: 1.2;
		font-weight: 700;
		letter-spacing: 0;
	}

	.empty-state p {
		margin-top: 0.35rem;
		color: var(--muted);
	}

	@media (min-width: 760px) {
		.year-group {
			grid-template-columns: 7rem minmax(0, 1fr);
			align-items: start;
		}

		.post-row {
			grid-template-columns: minmax(0, 1fr) auto;
			align-items: center;
		}
	}
</style>
