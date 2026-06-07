<script lang="ts">
	import { ArrowRightAltOutline } from 'flowbite-svelte-icons';
	import PostMeta from './PostMeta.svelte';
	import TagList from './TagList.svelte';

	type PostSummary = {
		title: string;
		slug: string;
		date?: string;
		description?: string;
		tags?: string[];
	};

	type Props = {
		post: PostSummary;
		featured?: boolean;
	};

	let { post, featured = false }: Props = $props();
</script>

<a class:featured class="post-card" href={`/${post.slug}`} data-sveltekit-preload-data="hover">
	<div class="content">
		<PostMeta date={post.date} compact={!featured} />
		<h2>{post.title}</h2>

		{#if post.description}
			<p>{post.description}</p>
		{/if}
	</div>

	<div class="footer">
		<TagList tags={post.tags} compact={!featured} />
		<span class="read-more">
			Read
			<ArrowRightAltOutline width="1rem" height="1rem" ariaLabel="Read post" />
		</span>
	</div>
</a>

<style>
	.post-card {
		display: flex;
		flex-direction: column;
		justify-content: space-between;
		gap: 1.1rem;
		min-height: 100%;
		border: 1px solid rgba(0, 0, 0, 0.1);
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

	.post-card:hover {
		transform: translateY(-1px);
		border-color: rgba(255, 62, 0, 0.3);
		box-shadow: var(--shadow);
	}

	.post-card.featured {
		padding: clamp(1.1rem, 2vw, 1.35rem);
	}

	h2 {
		margin: 0.65rem 0 0;
		font-size: 1.15rem;
		line-height: 1.25;
		font-weight: 700;
		letter-spacing: 0;
		text-wrap: balance;
	}

	.featured h2 {
		font-size: clamp(1.25rem, 2vw, 1.55rem);
	}

	p {
		margin: 0.6rem 0 0;
		color: var(--muted);
		line-height: 1.65;
	}

	.footer {
		display: flex;
		align-items: flex-end;
		justify-content: space-between;
		gap: 0.8rem;
		flex-wrap: wrap;
	}

	.read-more {
		display: inline-flex;
		align-items: center;
		gap: 0.25rem;
		margin-left: auto;
		color: var(--accent);
		font-weight: 700;
		font-size: 0.9rem;
		white-space: nowrap;
	}
</style>
