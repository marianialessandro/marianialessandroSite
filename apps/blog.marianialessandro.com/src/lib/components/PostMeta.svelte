<script lang="ts">
	import { CalendarMonthOutline, BookOpenOutline } from 'flowbite-svelte-icons';

	type Props = {
		date?: string;
		compact?: boolean;
	};

	let { date, compact = false }: Props = $props();

	function formatDate(value: string | null | undefined): string | null {
		if (!value) return null;
		const parsed = new Date(value);
		if (Number.isNaN(parsed.getTime())) return null;

		return parsed.toLocaleDateString('en-US', {
			month: 'short',
			day: 'numeric',
			year: 'numeric'
		});
	}

	const formattedDate = $derived(formatDate(date));
	const isoDate = $derived(
		date && !Number.isNaN(new Date(date).getTime()) ? new Date(date).toISOString() : null
	);
</script>

<div class:compact class="post-meta">
	{#if formattedDate && isoDate}
		<span class="meta-item">
			<CalendarMonthOutline width="0.95rem" height="0.95rem" ariaLabel="Publication date" />
			<time datetime={isoDate}>{formattedDate}</time>
		</span>
	{/if}

	<span class="meta-item">
		<BookOpenOutline width="0.95rem" height="0.95rem" ariaLabel="Post" />
		<span>Post</span>
	</span>
</div>

<style>
	.post-meta {
		display: flex;
		align-items: center;
		flex-wrap: wrap;
		gap: 0.6rem 0.9rem;
		color: var(--muted);
		font-size: 0.9rem;
	}

	.post-meta.compact {
		gap: 0.45rem 0.75rem;
		font-size: 0.82rem;
	}

	.meta-item {
		display: inline-flex;
		align-items: center;
		gap: 0.35rem;
		min-width: 0;
	}

	.meta-item :global(svg) {
		flex: 0 0 auto;
	}
</style>
