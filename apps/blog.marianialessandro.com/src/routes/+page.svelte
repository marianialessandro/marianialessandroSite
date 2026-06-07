<script lang="ts">
	import { ArrowRightAltOutline } from 'flowbite-svelte-icons';
	import PostCard from '$lib/components/PostCard.svelte';
	import PostMeta from '$lib/components/PostMeta.svelte';
	import TagList from '$lib/components/TagList.svelte';
	import type { PostSummary } from '$lib/posts';

	export let data: {
		heroPost?: PostSummary;
		featuredPosts?: PostSummary[];
		latestPosts?: PostSummary[];
		postCount?: number;
	};
	const heroPost = data?.heroPost;
	const featuredPosts = data?.featuredPosts ?? [];
	const latestPosts = data?.latestPosts ?? [];
	const postCount = data?.postCount ?? 0;
</script>

<svelte:head>
	<title>marianialessandro.com - Alessandro Mariani</title>
	<meta name="description" content="Articles and notes" />
</svelte:head>

<section class="page" aria-labelledby="blog-title">
	<h1 id="blog-title" class="visually-hidden">marianialessandro.com</h1>

	{#if postCount === 0}
		<div class="empty-state">
			<h2>No posts yet</h2>
			<p>Check back soon for new notes.</p>
		</div>
	{:else}
		{#if heroPost}
			<section class="section spotlight" aria-labelledby="featured-title">
				<header class="section-heading">
					<p>Featured</p>
					<h2 id="featured-title">Start here</h2>
				</header>

				<div class="spotlight-grid">
					<a class="lead-post" href={`/${heroPost.slug}`} data-sveltekit-preload-data="hover">
						{#if heroPost.cover}
							<img class="lead-cover" src={heroPost.cover} alt="" loading="eager" />
						{:else}
							<div class="lead-visual" aria-hidden="true">
								<span>Notes</span>
								<strong>{heroPost.tags?.[0] ?? 'Article'}</strong>
							</div>
						{/if}

						<div class="lead-copy">
							<PostMeta date={heroPost.date} />
							<h2>{heroPost.title}</h2>
							{#if heroPost.description}
								<p>{heroPost.description}</p>
							{/if}
							<div class="lead-footer">
								<TagList tags={heroPost.tags} />
								<span class="read-more">
									Read article
									<ArrowRightAltOutline width="1rem" height="1rem" ariaLabel="Read featured post" />
								</span>
							</div>
						</div>
					</a>

					{#if featuredPosts.length}
						<div class="supporting-posts" aria-label="More selected posts">
							{#each featuredPosts as post (post.slug)}
								<PostCard {post} />
							{/each}
						</div>
					{/if}
				</div>
			</section>
		{/if}

		{#if latestPosts.length}
			<section class="section latest" aria-labelledby="latest-title">
				<header class="section-heading row">
					<div>
						<p>Recent</p>
						<h2 id="latest-title">Latest notes</h2>
					</div>
					<a class="archive-link" href="/archive/">
						All posts
						<ArrowRightAltOutline width="1rem" height="1rem" ariaLabel="Open archive" />
					</a>
				</header>

				<div class="latest-grid">
					{#each latestPosts as post (post.slug)}
						<a class="latest-card" href={`/${post.slug}`} data-sveltekit-preload-data="hover">
							<div class="latest-copy">
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
		{/if}
	{/if}
</section>

<style>
	.page {
		width: var(--container);
		margin: 0 auto;
		padding: clamp(1.4rem, 3vw, 2.2rem) 0 clamp(3rem, 6vw, 4.5rem);
	}

	.section {
		padding-top: clamp(1.5rem, 3vw, 2.4rem);
	}

	.section:first-of-type {
		padding-top: 0;
	}

	.section-heading {
		margin-bottom: 1rem;
	}

	.section-heading.row {
		display: flex;
		align-items: end;
		justify-content: space-between;
		gap: 1rem;
	}

	.section-heading p,
	.section-heading h2,
	.latest-copy h3,
	.latest-copy p,
	.empty-state h2,
	.empty-state p {
		margin: 0;
	}

	.section-heading p {
		color: var(--muted);
		font-size: 0.85rem;
		font-weight: 700;
		letter-spacing: 0.08em;
		text-transform: uppercase;
	}

	.section-heading h2,
	.empty-state h2 {
		margin-top: 0.2rem;
		font-size: clamp(1.35rem, 2.4vw, 1.8rem);
		line-height: 1.2;
		font-weight: 700;
		letter-spacing: 0;
	}

	.spotlight-grid {
		display: grid;
		grid-template-columns: 1fr;
		gap: 1rem;
	}

	.lead-post {
		display: grid;
		grid-template-columns: 1fr;
		min-height: 100%;
		overflow: hidden;
		border: 1px solid rgba(0, 0, 0, 0.1);
		border-radius: var(--radius);
		background: #fff;
		color: var(--fg);
		text-decoration: none;
		box-shadow: var(--shadow);
		transition:
			transform 140ms ease,
			border-color 140ms ease;
	}

	.lead-post:hover {
		transform: translateY(-1px);
		border-color: rgba(255, 62, 0, 0.34);
		color: var(--fg);
	}

	.lead-cover,
	.lead-visual {
		width: 100%;
		aspect-ratio: 16 / 9;
	}

	.lead-cover {
		display: block;
		object-fit: cover;
		background: var(--line);
	}

	.lead-visual {
		display: flex;
		flex-direction: column;
		justify-content: space-between;
		padding: clamp(1rem, 3vw, 1.5rem);
		background:
			linear-gradient(135deg, rgba(255, 62, 0, 0.14), rgba(64, 117, 166, 0.18)),
			#f8fafc;
	}

	.lead-visual span {
		color: var(--muted);
		font-size: 0.85rem;
		font-weight: 700;
		text-transform: uppercase;
	}

	.lead-visual strong {
		max-width: 14ch;
		font-size: clamp(2.1rem, 7vw, 4.8rem);
		line-height: 0.95;
		font-weight: 800;
		letter-spacing: 0;
		overflow-wrap: anywhere;
	}

	.lead-copy {
		display: flex;
		flex-direction: column;
		padding: clamp(1.1rem, 3vw, 1.6rem);
	}

	.lead-copy h2 {
		margin: 0.75rem 0 0;
		max-width: 15ch;
		font-size: clamp(2rem, 5vw, 3.8rem);
		line-height: 0.98;
		font-weight: 800;
		letter-spacing: 0;
		text-wrap: balance;
	}

	.lead-copy p {
		margin: 0.85rem 0 0;
		max-width: 58ch;
		color: var(--muted);
		font-size: clamp(1rem, 1.4vw, 1.08rem);
		line-height: 1.7;
	}

	.lead-footer {
		display: flex;
		align-items: end;
		justify-content: space-between;
		gap: 1rem;
		flex-wrap: wrap;
		margin-top: auto;
		padding-top: 1.4rem;
	}

	.supporting-posts {
		display: grid;
		grid-template-columns: 1fr;
		gap: 1rem;
	}

	.read-more,
	.archive-link {
		display: inline-flex;
		align-items: center;
		gap: 0.3rem;
		font-weight: 700;
		text-decoration: none;
		white-space: nowrap;
	}

	.read-more {
		color: var(--accent);
	}

	.archive-link {
		min-height: 2.25rem;
		border: 1px solid var(--line);
		border-radius: 999px;
		padding: 0 0.75rem;
		background: #fff;
		color: var(--fg);
		font-size: 0.9rem;
	}

	.latest-grid {
		display: grid;
		grid-template-columns: 1fr;
		gap: 0.85rem;
	}

	.latest-card {
		display: flex;
		flex-direction: column;
		justify-content: space-between;
		gap: 1.2rem;
		min-height: 11rem;
		border: 1px solid var(--line);
		border-radius: var(--radius);
		padding: 1rem;
		background: #fff;
		color: var(--fg);
		text-decoration: none;
		box-shadow: 0 1px 2px rgba(0, 0, 0, 0.04);
		transition:
			transform 140ms ease,
			border-color 140ms ease,
			box-shadow 140ms ease;
	}

	.latest-card:hover {
		transform: translateY(-1px);
		border-color: rgba(255, 62, 0, 0.3);
		box-shadow: var(--shadow);
		color: var(--fg);
	}

	.latest-copy h3 {
		margin-top: 0.65rem;
		font-size: clamp(1.08rem, 1.8vw, 1.28rem);
		line-height: 1.25;
		font-weight: 700;
		letter-spacing: 0;
	}

	.latest-card:hover .latest-copy h3 {
		color: var(--accent);
	}

	.latest-copy p {
		margin-top: 0.35rem;
		color: var(--muted);
		line-height: 1.6;
	}

	.empty-state {
		margin-top: 1.5rem;
		border: 1px solid var(--line);
		border-radius: var(--radius);
		background: #fff;
		padding: clamp(1rem, 3vw, 1.5rem);
		box-shadow: var(--shadow);
	}

	.empty-state p {
		margin-top: 0.35rem;
		color: var(--muted);
	}

	@media (min-width: 760px) {
		.spotlight-grid {
			grid-template-columns: minmax(0, 1.55fr) minmax(18rem, 0.9fr);
			align-items: stretch;
		}

		.lead-post {
			grid-template-columns: minmax(13rem, 0.75fr) minmax(0, 1fr);
		}

		.lead-cover,
		.lead-visual {
			height: 100%;
			aspect-ratio: auto;
		}

		.latest-grid {
			grid-template-columns: repeat(2, minmax(0, 1fr));
		}
	}

	@media (max-width: 640px) {
		.section-heading.row {
			align-items: stretch;
			flex-direction: column;
		}

		.archive-link {
			width: fit-content;
		}
	}
</style>
