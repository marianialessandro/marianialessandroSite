// svelte.config.js
import adapter from '@sveltejs/adapter-static';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';
import { mdsvex } from 'mdsvex';

const mdsvexConfig = {
  extensions: ['.md', '.svx'],
  // layout: './src/lib/layouts/PostLayout.svelte'
};

/** @type {import('@sveltejs/kit').Config} */
const config = {
  extensions: ['.svelte', ...mdsvexConfig.extensions],
  preprocess: [vitePreprocess(), mdsvex(mdsvexConfig)],
  kit: {
    adapter: adapter(),
    /* // prerendera tutto ciò che è raggiungibile (perfetto per blog statico)
    prerender: { entries: ['*'] },
    // se pubblichi sotto sottocartella (es. GitHub Pages), imposta BASE_PATH
    // es: BASE_PATH=/nome-repo
    paths: { base: process.env.BASE_PATH ?? '' },
    trailingSlash: 'ignore' */
  }
};

export default config;
