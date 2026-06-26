// src/routes/+page.ts
import { allPosts, selectHomePosts, toPostSummary } from '$lib/posts';

export const prerender = true;

export function load() {
	const posts = allPosts.map(toPostSummary);
	const { heroPost, featuredPosts, latestPosts } = selectHomePosts(posts);

	return {
		heroPost,
		featuredPosts,
		latestPosts,
		postCount: posts.length
	};
}
