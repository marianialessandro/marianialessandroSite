import type { RequestHandler } from './$types';
import { allPosts } from '$lib/posts';

export const prerender = true;

export const GET: RequestHandler = async () => {
  const site = 'https://tuodominio.it'; // <-- aggiorna!

  const items = allPosts.map((p) => `
    <item>
      <title><![CDATA[${p.meta.title}]]></title>
      <link>${site}/blog/${p.slug}</link>
      <guid isPermaLink="true">${site}/blog/${p.slug}</guid>
      <pubDate>${new Date(p.meta.date).toUTCString()}</pubDate>
      <description><![CDATA[${p.meta.description ?? ''}]]></description>
    </item>
  `).join('');

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0">
    <channel>
      <title>Blog</title>
      <link>${site}/blog</link>
      <description>Ultimi articoli</description>
      ${items}
    </channel>
  </rss>`;

  return new Response(xml, {
    headers: { 'Content-Type': 'application/rss+xml; charset=utf-8' }
  });
};
