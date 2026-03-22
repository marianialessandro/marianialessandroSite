// src/routes/blog/[slug]/+page.ts
import { allPosts } from '$lib/posts';
import { error } from '@sveltejs/kit';
import type { PageLoad } from './$types';

export const prerender = true;

export const load: PageLoad = ({ params }) => {
	const post = allPosts.find((entry) => entry.slug === params.slug);

	if (!post) {
		throw error(404, 'Articolo non trovato');
	}

	return {
		meta: post.meta,
		Content: post.component
	};
};
