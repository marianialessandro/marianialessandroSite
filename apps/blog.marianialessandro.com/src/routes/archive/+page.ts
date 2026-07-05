import { getAllPostSummaries, getAvailableTags, getAvailableYears } from '$lib/posts';
import type { PageLoad } from './$types';

export const prerender = true;

export const load: PageLoad = async ({ fetch }) => {
	const posts = await getAllPostSummaries(fetch);

	return {
		posts,
		availableYears: getAvailableYears(posts),
		availableTags: getAvailableTags(posts),
		postCount: posts.length
	};
};
