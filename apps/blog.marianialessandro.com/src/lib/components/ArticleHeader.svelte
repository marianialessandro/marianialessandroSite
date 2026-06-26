<script lang="ts">
	import PostMeta from './PostMeta.svelte';
	import TagList from './TagList.svelte';

	type Props = {
		title?: string;
		description?: string;
		date?: string;
		tags?: string[];
	};

	let { title, description, date, tags = [] }: Props = $props();
</script>

<header class="article-header">
	{#if title}
		<h1>{title}</h1>
	{/if}

	{#if description}
		<p>{description}</p>
	{/if}

	<div class="meta-row">
		<PostMeta {date} />
		<TagList {tags} />
	</div>
</header>

<style>
	.article-header {
		margin: 0 auto clamp(1.5rem, 3vw, 2.25rem);
		max-width: var(--post-max-width);
		text-align: center;
	}

	h1 {
		margin: 0;
		font-size: clamp(2rem, 5vw, 3.4rem);
		line-height: 1.04;
		font-weight: 700;
		letter-spacing: 0;
		text-wrap: balance;
	}

	p {
		margin: 0.9rem auto 0;
		max-width: 60ch;
		color: var(--muted);
		font-size: clamp(1rem, 1.6vw, 1.15rem);
		line-height: 1.7;
		text-wrap: balance;
	}

	.meta-row {
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 0.85rem 1rem;
		flex-wrap: wrap;
		margin-top: 1rem;
	}
</style>
