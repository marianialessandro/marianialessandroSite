// src/lib/posts.ts
export type PostMeta = {
	title: string;
	date: string; // ISO string
	description?: string;
	tags?: string[];
	draft?: boolean;
	cover?: string;
	featured?: boolean;
	featuredRank?: number;
};

type Module = {
	metadata: PostMeta;
	default: unknown; // componente svelte mdsvex
};

const modules = import.meta.glob<Module>('/src/posts/**/*.md', { eager: true });

export type Post = {
	slug: string;
	meta: PostMeta;
	component: unknown;
	path: string;
};

export type PostSummary = PostMeta & {
	slug: string;
};

export function toPostSummary({ slug, meta }: Post): PostSummary {
	return { slug, ...meta };
}

export function selectHomePosts(posts: PostSummary[]) {
	const sortedByDate = [...posts].sort(
		(a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()
	);

	const explicitFeatured = sortedByDate
		.filter((post) => post.featured)
		.sort((a, b) => {
			const rankA = a.featuredRank ?? Number.POSITIVE_INFINITY;
			const rankB = b.featuredRank ?? Number.POSITIVE_INFINITY;
			if (rankA !== rankB) return rankA - rankB;
			return new Date(b.date).getTime() - new Date(a.date).getTime();
		});

	const [heroPost, ...supportingPosts] = explicitFeatured.length ? explicitFeatured : sortedByDate;
	const featuredPosts = supportingPosts.slice(0, 2);
	const promotedSlugs = new Set([heroPost?.slug, ...featuredPosts.map((post) => post.slug)]);
	const latestPosts = sortedByDate.filter((post) => !promotedSlugs.has(post.slug)).slice(0, 6);

	return {
		heroPost,
		featuredPosts,
		latestPosts
	};
}

export const allPosts: Post[] = Object.entries(modules)
	.map(([path, mod]) => {
		const slug = path.split('/').pop()!.replace(/\.md$/, '');
		return { slug, meta: mod.metadata, component: mod.default, path };
	})
	.filter((p) => !p.meta.draft)
	.sort((a, b) => new Date(b.meta.date).getTime() - new Date(a.meta.date).getTime());
