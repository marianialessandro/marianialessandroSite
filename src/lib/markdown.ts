import { marked } from 'marked';

export type MarkdownHeading = {
	id: string;
	text: string;
	level: 1 | 2 | 3 | 4 | 5 | 6;
};

const slugify = (value: string) =>
	value
		.toLowerCase()
		.normalize('NFD')
		.replace(/\s*\(h[1-6]\)\s*$/i, '')
		.replace(/[\u0300-\u036f]/g, '')
		.replace(/&[a-z0-9#]+;/gi, ' ')
		.replace(/[^a-z0-9\s-]/g, '')
		.trim()
		.replace(/\s+/g, '-')
		.replace(/-+/g, '-');

const stripHtml = (value: string) => value.replace(/<[^>]*>/g, '');

const decodeEntities = (value: string) =>
	value
		.replace(/&amp;/g, '&')
		.replace(/&lt;/g, '<')
		.replace(/&gt;/g, '>')
		.replace(/&quot;/g, '"')
		.replace(/&#39;/g, "'")
		.replace(/&nbsp;/g, ' ');

const escapeAttribute = (value: string) => value.replace(/&/g, '&amp;').replace(/"/g, '&quot;');

export function addHeadingIds(html: string): { html: string; headings: MarkdownHeading[] } {
	const seen = new Map<string, number>();
	const headings: MarkdownHeading[] = [];

	const output = html.replace(/<h([1-6])>([\s\S]*?)<\/h\1>/g, (_match, rawLevel, innerHtml) => {
		const level = Number(rawLevel) as MarkdownHeading['level'];
		const text = decodeEntities(stripHtml(innerHtml)).trim() || 'section';
		const base = slugify(text) || 'section';

		const count = (seen.get(base) ?? 0) + 1;
		seen.set(base, count);

		const id = count === 1 ? base : `${base}-${count}`;
		headings.push({ id, text, level });

		return `<h${level} id="${escapeAttribute(id)}">${innerHtml}</h${level}>`;
	});

	return { html: output, headings };
}

export function renderMarkdown(markdown: string) {
	const rawHtml = marked.parse(markdown, {
		async: false,
		breaks: true,
		gfm: true
	});

	return addHeadingIds(rawHtml);
}
