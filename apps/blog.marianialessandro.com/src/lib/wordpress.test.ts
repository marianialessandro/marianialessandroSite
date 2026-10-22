import { describe, expect, it, vi } from 'vitest';
import { fromWordPress, getWordPressPost, getWordPressSummaries, type WordPressPost } from './wordpress';
import { sanitizeContentHtml } from './markdown';

const fixture: WordPressPost = {
	id: 7,
	slug: 'hello-world',
	date_gmt: '2026-01-10T10:00:00',
	status: 'publish',
	sticky: true,
	title: { rendered: 'Hello &amp; <em>world</em>' },
	excerpt: { rendered: '<p>Summary</p>' },
	content: { rendered: '<figure class="wp-block-image"><img src="https://example.com/image.jpg" onerror="alert(1)"></figure><script>alert(1)</script>', protected: false },
	meta: { blog_featured_rank: 2, blog_cover: 'https://example.com/legacy.jpg' },
	_embedded: { 'wp:term': [[{ taxonomy: 'category', name: 'General' }], [{ taxonomy: 'post_tag', name: 'C&#43;&#43;' }]], 'wp:featuredmedia': [{ source_url: 'https://example.com/cover.jpg' }] }
};

describe('WordPress content provider', () => {
	it('maps public metadata, taxonomy, cover and UTC publication date', () => {
		expect(fromWordPress(fixture)).toMatchObject({ title: 'Hello & world', description: 'Summary', tags: ['C++'], date: '2026-01-10T10:00:00Z', featured: true, featuredRank: 2, cover: 'https://example.com/cover.jpg' });
	});
	it('loads every page and hides password-protected posts', async () => {
		const fetcher = vi.fn().mockResolvedValueOnce(new Response(JSON.stringify([fixture]), { headers: { 'X-WP-TotalPages': '2' } })).mockResolvedValueOnce(new Response(JSON.stringify([{ ...fixture, id: 8 }, { ...fixture, id: 9, content: { rendered: '', protected: true } }])));
		expect((await getWordPressSummaries(fetcher, 'https://example.com/cms')).map((post) => post.id)).toEqual([7, 8]);
		expect(new URL(fetcher.mock.calls[1][0]).searchParams.get('page')).toBe('2');
		expect(new URL(fetcher.mock.calls[0][0]).searchParams.get('rest_route')).toBe('/wp/v2/posts');
	});
	it('keeps block HTML separate from Markdown and strips executable markup', async () => {
		const result = await getWordPressPost(vi.fn().mockResolvedValue(new Response(JSON.stringify(fixture))), 'https://example.com/cms', 7);
		expect(result.contentFormat).toBe('html');
		const html = sanitizeContentHtml(result.content);
		expect(html).toContain('class="wp-block-image"');
		expect(html).not.toMatch(/<script|onerror/);
	});
	it('fails a rebuild on CMS failures instead of publishing an empty blog', async () => {
		await expect(getWordPressSummaries(vi.fn().mockResolvedValue(new Response('', { status: 503 })), 'https://example.com/cms')).rejects.toThrow('503');
	});
	it('rejects drafts and password-protected single posts', async () => {
		for (const post of [{ ...fixture, status: 'draft' }, { ...fixture, content: { rendered: '', protected: true } }]) {
			await expect(getWordPressPost(vi.fn().mockResolvedValue(new Response(JSON.stringify(post))), 'https://example.com/cms', 7)).rejects.toThrow('not public');
		}
	});
});
