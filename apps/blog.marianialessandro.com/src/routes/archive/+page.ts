import { allPosts, toPostSummary } from '$lib/posts';

export const prerender = true;

export function load() {
	const posts = allPosts.map(toPostSummary);
	const groupedPosts = posts.reduce<Array<{ year: string; posts: typeof posts }>>(
		(groups, post) => {
			const year = new Date(post.date).getFullYear().toString();
			const group = groups.find((item) => item.year === year);

			if (group) {
				group.posts.push(post);
			} else {
				groups.push({ year, posts: [post] });
			}

			return groups;
		},
		[]
	);

	return {
		groupedPosts,
		postCount: posts.length
	};
}
