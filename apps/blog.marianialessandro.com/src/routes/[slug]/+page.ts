// src/routes/[slug]/+page.ts
import { getAllPostSummaries, getPostById } from '$lib/posts';
import { renderMarkdown } from '$lib/markdown';
import { error } from '@sveltejs/kit';
import type { PageLoad } from './$types';

export const prerender = true;

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
