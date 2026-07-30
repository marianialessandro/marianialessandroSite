// src/routes/+page.ts
import { getAllPostSummaries, selectHomePosts } from '$lib/posts';
import type { PageLoad } from './$types';

export const prerender = true;

export const load: PageLoad = async ({ fetch }) => {
	const posts = await getAllPostSummaries(fetch);
	const { heroPost, featuredPosts, latestPosts } = selectHomePosts(posts);

	return {
		heroPost,
		featuredPosts,
		latestPosts,
		postCount: posts.length
	};
};
