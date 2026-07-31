// svelte.config.js
import adapter from '@sveltejs/adapter-static';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	preprocess: [vitePreprocess()],
	kit: {
		adapter: adapter({
			// Lets a direct/refreshed request to a non-prerendered admin route
			// (e.g. /admin/posts/123) resolve client-side if the static host
			// rewrites unmatched paths here; navigating from within the admin
			// panel itself always works via client-side routing regardless.
			fallback: '200.html'
		}),
		prerender: {
			handleUnseenRoutes: (details) => {
				// /[slug] has zero instances when the blog has no published
				// posts yet (a valid state, not a build error). Any other
				// unreached prerenderable route is still a real failure.
				const unexpected = details.routes.filter((id) => id !== '/[slug]');
				if (unexpected.length) {
					throw new Error(
						`Routes marked prerenderable but not reached while crawling:\n${unexpected.map((id) => `  - ${id}`).join('\n')}`
					);
				}
			}
		}
	}
};

export default config;
