<script lang="ts">
	import { TagOutline } from 'flowbite-svelte-icons';

	type Props = {
		tags?: string[];
		compact?: boolean;
		label?: string;
	};

	let { tags = [], compact = false, label = 'Post tags' }: Props = $props();
</script>

{#if tags.length}
	<div class:compact class="tag-list" aria-label={label}>
		{#each tags as tag (tag)}
			<span class="tag">
				<TagOutline width="0.8rem" height="0.8rem" ariaLabel="Tag" />
				{tag}
			</span>
		{/each}
	</div>
{/if}

<style>
	.tag-list {
		display: flex;
		flex-wrap: wrap;
		gap: 0.5rem;
	}

	.tag {
		display: inline-flex;
		align-items: center;
		gap: 0.3rem;
		max-width: 100%;
		border: 1px solid var(--line);
		border-radius: 6px;
		padding: 0.32rem 0.55rem;
		background: var(--surface-alt);
		color: var(--muted);
		font-size: 0.78rem;
		line-height: 1;
		font-weight: 600;
		letter-spacing: 0;
		overflow-wrap: anywhere;
	}

	.compact .tag {
		padding: 0.24rem 0.48rem;
		font-size: 0.7rem;
	}

	.tag :global(svg) {
		flex: 0 0 auto;
		color: var(--accent);
	}
</style>
