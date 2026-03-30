<script lang="ts">
	type Props = {
		name?: string;
		year?: number;
	};

	let { name = 'Alessandro Mariani', year = new Date().getFullYear() }: Props = $props();
</script>

<footer class="site-footer">
	<p>Copyright © {year} {name} All rights reserved</p>
</footer>

<style>
	.site-footer {
		display: flex;
		flex-direction: column;
		justify-content: center;
		align-items: center;
		padding: 12px;
	}

	p {
		margin: 0;
		text-align: center;
		text-wrap: balance;
	}

	@media (min-width: 480px) {
		.site-footer {
			padding: 12px 0;
		}
	}
</style>
