import type { RequestHandler } from './$types';
import { allPosts } from '$lib/posts';

export const prerender = true;

const escapeCdata = (value: string) => value.replaceAll(']]>', ']]]]><![CDATA[>');

export const GET: RequestHandler = async ({ url }) => {
	const site = url.origin;

	const items = allPosts
		.map((post) => {
			const link = new URL(`/blog/${post.slug}`, site).toString();

			return `
				<item>
					<title><![CDATA[${escapeCdata(post.meta.title)}]]></title>
					<link>${link}</link>
					<guid isPermaLink="true">${link}</guid>
					<pubDate>${new Date(post.meta.date).toUTCString()}</pubDate>
					<description><![CDATA[${escapeCdata(post.meta.description ?? '')}]]></description>
				</item>
			`;
		})
		.join('');

	const xml = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
	<channel>
		<title>Blog</title>
		<link>${new URL('/blog', site).toString()}</link>
		<description>Ultimi articoli</description>
		${items}
	</channel>
</rss>`;

	return new Response(xml, {
		headers: {
			'Content-Type': 'application/rss+xml; charset=utf-8'
		}
	});
};
