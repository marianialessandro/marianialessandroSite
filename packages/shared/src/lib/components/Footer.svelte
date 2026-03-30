<script lang="ts">
	export let name = 'Alessandro Mariani';
	export let year = new Date().getFullYear();
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

	@media (min-width: 480px) {
		.site-footer {
			padding: 12px 0;
		}
	}
</style>
