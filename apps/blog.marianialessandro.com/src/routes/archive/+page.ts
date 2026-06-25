import { allPosts, getAvailableTags, getAvailableYears, toPostSummary } from '$lib/posts';

export const prerender = true;

export function load() {
	const posts = allPosts.map(toPostSummary);

	return {
		posts,
		availableYears: getAvailableYears(posts),
		availableTags: getAvailableTags(posts),
		postCount: posts.length
	};
}
