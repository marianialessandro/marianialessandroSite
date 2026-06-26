<script lang="ts">
	import { page } from '$app/state';
	import {
		ArchiveOutline,
		GlobeOutline,
		HomeOutline,
		NewspaperOutline
	} from 'flowbite-svelte-icons';

	const siteUrl = 'https://marianialessandro.com';
</script>

<header class="blog-header">
	<div class="inner">
		<a class="brand" href="/" aria-label="Home blog marianialessandro.com">
			<span class="brand-mark" aria-hidden="true">
				<NewspaperOutline width="1rem" height="1rem" ariaLabel="marianialessandro.com" />
			</span>
			<span>marianialessandro.com</span>
		</a>

		<nav aria-label="Blog navigation">
			<a class:active={page.url.pathname === '/'} href="/">
				<HomeOutline width="0.95rem" height="0.95rem" ariaLabel="Blog home" />
				Home
			</a>
			<a class:active={page.url.pathname.startsWith('/archive')} href="/archive/">
				<ArchiveOutline width="0.95rem" height="0.95rem" ariaLabel="Archive" />
				Archive
			</a>
			<a href={siteUrl}>
				<GlobeOutline width="0.95rem" height="0.95rem" ariaLabel="Main website" />
				About Me
			</a>
		</nav>
	</div>
</header>

<style>
	.blog-header {
		position: sticky;
		top: 0;
		z-index: 50;
		border-bottom: 1px solid rgba(0, 0, 0, 0.08);
		background: rgba(255, 255, 255, 0.92);
		backdrop-filter: blur(14px);
	}

	.inner {
		width: var(--container);
		margin: 0 auto;
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1rem;
		padding: 0.85rem 0;
	}

	.brand,
	nav a {
		display: inline-flex;
		align-items: center;
		text-decoration: none;
		color: var(--fg);
	}

	.brand {
		gap: 0.55rem;
		font-weight: 700;
		letter-spacing: 0;
		min-width: 0;
	}

	.brand span:last-child {
		overflow-wrap: anywhere;
	}

	.brand-mark {
		display: inline-grid;
		place-items: center;
		width: 2rem;
		height: 2rem;
		border: 1px solid rgba(0, 0, 0, 0.1);
		border-radius: 999px;
		background: #fff;
		color: var(--accent);
	}

	nav {
		display: flex;
		align-items: center;
		justify-content: flex-end;
		gap: 0.35rem;
	}

	nav a {
		gap: 0.35rem;
		min-height: 2rem;
		border-radius: 999px;
		padding: 0 0.65rem;
		font-size: 0.92rem;
		color: var(--muted);
		white-space: nowrap;
	}

	nav a:hover,
	nav a.active {
		background: rgba(255, 62, 0, 0.08);
		color: var(--fg);
	}

	@media (max-width: 560px) {
		.inner {
			align-items: flex-start;
			flex-direction: column;
			padding: 0.75rem 0;
		}

		nav {
			width: 100%;
			justify-content: space-between;
		}
	}
</style>
