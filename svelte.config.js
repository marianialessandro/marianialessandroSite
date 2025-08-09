// svelte.config.js
import adapter from '@sveltejs/adapter-auto';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';
import { mdsvex } from 'mdsvex';

const mdsvexConfig = {
  extensions: ['.md', '.svx'],
  // Se vuoi wrappare tutti i post in un layout dedicato, scommenta la riga sotto
  // e crea il file corrispondente.
  // layout: './src/lib/layouts/PostLayout.svelte'
};

/** @type {import('@sveltejs/kit').Config} */
const config = {
  // abilita .md/.svx come componenti Svelte
  extensions: ['.svelte', ...mdsvexConfig.extensions],
  // applichiamo sia vitePreprocess che mdsvex
  preprocess: [vitePreprocess(), mdsvex(mdsvexConfig)],
  kit: {
    adapter: adapter()
  }
};

export default config;
