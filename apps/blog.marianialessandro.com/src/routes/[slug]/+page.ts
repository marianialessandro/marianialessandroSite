// src/routes/[slug]/+page.ts
import { getAllPostSummaries, getPostById } from '$lib/posts';
import { renderMarkdown } from '$lib/markdown';
import { error } from '@sveltejs/kit';
import type { EntryGenerator, PageLoad } from './$types';

export const prerender = true;

// Without this, SvelteKit only discovers /[slug] pages by crawling links
// from other prerendered pages (home, archive). If there are zero public
// posts at build time, nothing links here and the build fails with
// "marked as prerenderable, but not found while crawling". Fetching the
// slugs directly from the API makes prerendering work regardless of what
// links exist, and correctly no-ops when there are no posts yet.
export const entries: EntryGenerator = async () => {
	const posts = await getAllPostSummaries(fetch);
	return posts.map((post) => ({ slug: post.slug }));
};

export const load: PageLoad = async ({ params, fetch }) => {
	const posts = await getAllPostSummaries(fetch);
	const summary = posts.find((p) => p.slug === params.slug);
	if (!summary) throw error(404, 'Post not found');

	const { content, ...meta } = await getPostById(fetch, summary.id);

	return {
		meta,
		contentHtml: renderMarkdown(content)
	};
};
