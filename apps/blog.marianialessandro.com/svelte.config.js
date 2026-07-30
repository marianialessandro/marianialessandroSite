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
		})
	}
};

export default config;
