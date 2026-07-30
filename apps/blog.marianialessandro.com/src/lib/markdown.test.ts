import { describe, expect, it } from 'vitest';
import { renderMarkdown } from './markdown';

describe('renderMarkdown', () => {
	it('removes executable HTML and unsafe URL schemes', () => {
		const rendered = renderMarkdown(`
<script>alert('xss')</script>
<img src="x" onerror="alert('xss')">
<a href="javascript:alert('xss')">raw unsafe link</a>
[unsafe](javascript:alert('xss'))
`);

		expect(rendered).not.toContain('<script');
		expect(rendered).not.toContain('onerror');
		expect(rendered).not.toContain('href="javascript:');
	});

	it('keeps the safe HTML used by article content', () => {
		const rendered = renderMarkdown(`
<details open>
<summary>More</summary>
Safe content
</details>

[Example](https://example.com)
`);

		expect(rendered).toContain('<details open>');
		expect(rendered).toContain('<summary>More</summary>');
		expect(rendered).toContain('href="https://example.com"');
		expect(rendered).toContain('rel="noopener noreferrer"');
	});

	it('preserves footnote targets used by prerendered links', () => {
		const rendered = renderMarkdown('Reference[^1]\n\n[^1]: Footnote text');

		expect(rendered).toContain('href="#fn1"');
		expect(rendered).toContain('id="fn1"');
		expect(rendered).toContain('id="fnref1"');
	});
});
