<script lang="ts">
	import '@marianialessandro/shared/styles.css';

	type Props = {
		children: import('svelte').Snippet;
	};

	let { children }: Props = $props();
</script>

{@render children()}
