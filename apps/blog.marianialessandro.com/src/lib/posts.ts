// src/lib/posts.ts
import { PUBLIC_API_BASE_URL } from '$env/static/public';

export type PostMeta = {
	title: string;
	date: string; // ISO string
	description?: string;
	tags: string[];
	draft?: boolean;
	cover?: string;
	featured?: boolean;
	featuredRank?: number;
};

export type PostSummary = PostMeta & {
	id: number;
	slug: string;
};

export type Post = PostSummary & {
	content: string;
};

type ApiPostSummary = {
	id: number;
	slug: string;
	title: string;
	description: string | null;
	date: string;
	tags: string[];
	draft: boolean;
	cover: string | null;
	featured: boolean;
	featured_rank: number | null;
};

type ApiPost = ApiPostSummary & { content: string };

function fromApiSummary(api: ApiPostSummary): PostSummary {
	return {
		id: api.id,
		slug: api.slug,
		title: api.title,
		date: api.date,
		description: api.description ?? undefined,
		tags: api.tags ?? [],
		draft: api.draft,
		cover: api.cover ?? undefined,
		featured: api.featured,
		featuredRank: api.featured_rank ?? undefined
	};
}

let summariesCache: Promise<PostSummary[]> | null = null;
const postCache = new Map<number, Promise<Post>>();

export function getAllPostSummaries(fetchFn: typeof fetch): Promise<PostSummary[]> {
	if (!summariesCache) {
		summariesCache = fetchFn(`${PUBLIC_API_BASE_URL}/posts`).then(async (res) => {
			if (!res.ok) throw new Error(`Failed to load posts (${res.status})`);
			const { data }: { data: ApiPostSummary[] } = await res.json();
			return data.map(fromApiSummary);
		});
	}
	return summariesCache;
}

export function getPostById(fetchFn: typeof fetch, id: number): Promise<Post> {
	if (!postCache.has(id)) {
		postCache.set(
			id,
			fetchFn(`${PUBLIC_API_BASE_URL}/posts/${id}`).then(async (res) => {
				if (!res.ok) throw new Error(`Failed to load post ${id} (${res.status})`);
				const { data: api }: { data: ApiPost } = await res.json();
				return { ...fromApiSummary(api), content: api.content };
			})
		);
	}
	return postCache.get(id)!;
}

export function normalizeTag(tag: string) {
	return tag.trim().toLocaleLowerCase();
}

export function getPostYear(post: Pick<PostSummary, 'date'>) {
	return new Date(post.date).getFullYear().toString();
}

export function groupPostsByYear(posts: PostSummary[]) {
	return posts.reduce<Array<{ year: string; posts: PostSummary[] }>>((groups, post) => {
		const year = getPostYear(post);
		const group = groups.find((item) => item.year === year);

		if (group) {
			group.posts.push(post);
		} else {
			groups.push({ year, posts: [post] });
		}

		return groups;
	}, []);
}

export function getAvailableYears(posts: PostSummary[]) {
	return Array.from(new Set(posts.map(getPostYear))).sort((a, b) => Number(b) - Number(a));
}

export function getAvailableTags(posts: PostSummary[]) {
	const tagsByKey = new Map<string, string>();

	for (const post of posts) {
		for (const tag of post.tags) {
			const key = normalizeTag(tag);
			if (key && !tagsByKey.has(key)) {
				tagsByKey.set(key, tag);
			}
		}
	}

	return Array.from(tagsByKey.entries())
		.sort(([tagA], [tagB]) => tagA.localeCompare(tagB))
		.map(([value, label]) => ({ value, label }));
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
