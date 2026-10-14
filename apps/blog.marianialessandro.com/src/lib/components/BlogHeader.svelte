<script lang="ts">
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
</script>

<header class="blog-header">
	<div class="inner">
		<a class="brand" href={resolve('/')} aria-label="Alessandro Mariani — blog home">
			<span class="brand-mark" aria-hidden="true">am.</span>
			<span class="brand-name">Alessandro Mariani</span>
		</a>
		<nav aria-label="Blog navigation">
			<a
				class:active={page.url.pathname === '/'}
				aria-current={page.url.pathname === '/' ? 'page' : undefined}
				href={resolve('/')}>Blog</a
			>
			<a
				class:active={page.url.pathname.startsWith('/archive')}
				aria-current={page.url.pathname.startsWith('/archive') ? 'page' : undefined}
				href={resolve('/archive')}>Archive</a
			>
			<a href="https://marianialessandro.com">Portfolio <span aria-hidden="true">↗</span></a>
		</nav>
	</div>
</header>

<style>
	.blog-header {
		position: sticky;
		top: 0;
		z-index: 50;
		border-bottom: 1px solid var(--line);
		background: rgba(248, 248, 248, 0.92);
		backdrop-filter: blur(18px);
	}
	.inner {
		width: var(--container);
		margin: 0 auto;
		min-height: 82px;
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 25px;
	}
	.brand {
		display: flex;
		align-items: center;
		gap: 13px;
		text-decoration: none;
	}
	.brand-mark {
		display: grid;
		place-items: center;
		width: 38px;
		height: 38px;
		color: #fff;
		background: var(--accent-strong);
		border-radius: 12px;
		font-size: 15px;
		letter-spacing: -0.9px;
		font-weight: 800;
	}
	.brand-name {
		font-size: 15px;
		font-weight: 760;
		letter-spacing: -0.55px;
	}
	nav {
		display: flex;
		align-items: center;
		gap: 32px;
	}
	nav a {
		display: inline-flex;
		align-items: center;
		min-height: 44px;
		color: var(--muted);
		font-size: 13px;
		font-weight: 620;
		text-decoration: none;
	}
	nav a:hover,
	nav a.active {
		color: var(--fg);
	}
	nav a.active {
		text-decoration: underline;
		text-underline-offset: 6px;
	}
	@media (max-width: 560px) {
		.inner {
			flex-wrap: wrap;
			gap: 8px;
			padding-block: 16px;
		}
		nav {
			width: 100%;
			justify-content: space-between;
			gap: 16px;
		}
	}
</style>
