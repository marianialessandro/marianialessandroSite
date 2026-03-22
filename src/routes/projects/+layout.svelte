<script lang="ts">
	import { page } from '$app/state';

	let { children } = $props();

	const nav = [
		{ href: '/', label: 'home' },
		{ href: '/projects', label: 'projects' }
	];

	const isActive = (href: string) => {
		const pathname = page.url.pathname;

		if (href === '/projects') {
			return pathname === '/projects' || pathname.startsWith('/projects/');
		}

		return pathname === href;
	};
</script>

<header class="projects-header">
	<div class="header-inner container">
		<a class="brand" href="/">Alessandro Mariani</a>

		<nav class="nav" aria-label="Primary">
			{#each nav as item (item.href)}
				<a
					class="nav-link"
					href={item.href}
					aria-current={isActive(item.href) ? 'page' : undefined}
					data-active={isActive(item.href)}
				>
					{item.label}
				</a>
			{/each}
		</nav>
	</div>
</header>

{@render children()}

<style>
	.projects-header {
		position: sticky;
		top: 0;
		z-index: 30;
		background: rgba(255, 255, 255, 0.85);
		backdrop-filter: blur(8px);
		border-bottom: 1px solid var(--line);
	}

	.header-inner {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 0.9rem 1.25rem;
	}

	.brand {
		text-decoration: none;
		color: var(--fg);
		font-weight: 700;
		letter-spacing: -0.02em;
		font-size: 1.25rem;
		line-height: 1.1;
	}

	.nav {
		display: flex;
		gap: 0.35rem;
		align-items: center;
	}

	.nav-link {
		text-decoration: none;
		color: var(--muted);
		padding: 0.45rem 0.75rem;
		border-radius: 999px;
		transition:
			transform 0.18s ease,
			background 0.18s ease,
			color 0.18s ease;
	}

	.nav-link:hover {
		color: var(--fg);
		background: rgba(0, 0, 0, 0.04);
		transform: translateY(-1px);
	}

	@media (max-width: 520px) {
		.header-inner {
			padding: 0.75rem 1rem;
		}

		.brand {
			font-size: 1.1rem;
		}

		.nav-link {
			padding: 0.4rem 0.6rem;
		}
	}
</style>
