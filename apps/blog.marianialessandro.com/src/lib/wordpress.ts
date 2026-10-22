import type { Post, PostSummary } from './posts';
import { sanitizeContentHtml } from './markdown';
import { decodeHTML } from 'entities';

export type WordPressPost = {
	id: number;
	slug: string;
	date_gmt: string;
	date?: string;
	status: string;
	sticky: boolean;
	title: { rendered: string };
	excerpt: { rendered: string };
	content?: { rendered: string; protected: boolean };
	meta: { blog_description?: string; blog_cover?: string; blog_featured_rank?: number };
	_embedded?: {
		'wp:term'?: Array<Array<{ taxonomy: string; name: string }>>;
		'wp:featuredmedia'?: Array<{ source_url: string }>;
	};
};

function plainText(html: string) {
	return decodeHTML(sanitizeContentHtml(html).replace(/<[^>]*>/g, ' ')).replace(/\s+/g, ' ').trim();
}

export function fromWordPress(post: WordPressPost): PostSummary {
	return {
		id: post.id,
		slug: post.slug,
		title: plainText(post.title.rendered),
		date: post.date ? post.date.slice(0, 10) : `${post.date_gmt}Z`,
		description: post.meta.blog_description || plainText(post.excerpt.rendered),
		tags: (post._embedded?.['wp:term'] ?? []).flat().filter((term) => term.taxonomy === 'post_tag').map((term) => plainText(term.name)),
		draft: false,
		cover: post._embedded?.['wp:featuredmedia']?.[0]?.source_url || post.meta.blog_cover || undefined,
		featured: post.sticky,
		featuredRank: post.meta.blog_featured_rank || undefined
	};
}

export function wordpressEndpoint(baseUrl: string, route: string) {
	const url = new URL(`${baseUrl.replace(/\/$/, '')}/`);
	// The query form also works on shared hosting before pretty permalinks are enabled.
	url.searchParams.set('rest_route', `/wp/v2/${route}`);
	return url;
}

export async function getWordPressSummaries(fetchFn: typeof fetch, baseUrl: string): Promise<PostSummary[]> {
	const posts: PostSummary[] = [];
	let totalPages = 1;
	for (let page = 1; page <= totalPages; page++) {
		const url = wordpressEndpoint(baseUrl, 'posts');
		url.searchParams.set('per_page', '100');
		url.searchParams.set('page', String(page));
		url.searchParams.set('_embed', 'wp:term,wp:featuredmedia');
		url.searchParams.set('status', 'publish');
		const response = await fetchFn(url);
		if (!response.ok) throw new Error(`Failed to load WordPress posts (${response.status})`);
		totalPages = Number(response.headers.get('X-WP-TotalPages') || 1);
		const data: WordPressPost[] = await response.json();
		posts.push(...data.filter((post) => !post.content?.protected).map(fromWordPress));
	}
	return posts;
}

export async function getWordPressPost(fetchFn: typeof fetch, baseUrl: string, id: number): Promise<Post> {
	const url = wordpressEndpoint(baseUrl, `posts/${id}`);
	url.searchParams.set('_embed', 'wp:term,wp:featuredmedia');
	const response = await fetchFn(url);
	if (!response.ok) throw new Error(`Failed to load WordPress post ${id} (${response.status})`);
	const post: WordPressPost = await response.json();
	if (post.status !== 'publish' || post.content?.protected) throw new Error('Post is not public');
	return { ...fromWordPress(post), content: post.content?.rendered ?? '', contentFormat: 'html' };
}
