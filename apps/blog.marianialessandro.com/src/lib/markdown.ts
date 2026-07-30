// src/lib/markdown.ts
import MarkdownIt from 'markdown-it';
import footnote from 'markdown-it-footnote';
import taskLists from 'markdown-it-task-lists';
import sanitizeHtml from 'sanitize-html';

const md: MarkdownIt = new MarkdownIt({ html: true, linkify: true, typographer: false });
md.use(footnote);
md.use(taskLists, { enabled: true, label: true });

export function renderMarkdown(content: string): string {
	return sanitizeHtml(md.render(content), {
		allowedTags: [
			...sanitizeHtml.defaults.allowedTags,
			'details',
			'figcaption',
			'figure',
			'input',
			'section',
			'summary'
		],
		allowedAttributes: {
			a: ['aria-label', 'href', 'id', 'name', 'rel', 'target', 'title'],
			blockquote: ['cite'],
			code: ['class'],
			details: ['open'],
			hr: ['class'],
			img: ['alt', 'height', 'loading', 'src', 'title', 'width'],
			input: ['checked', 'class', 'disabled', 'type'],
			li: ['class', 'id'],
			ol: ['class', 'start'],
			section: ['class'],
			sup: ['class'],
			table: ['class'],
			td: ['colspan', 'rowspan'],
			th: ['colspan', 'rowspan'],
			ul: ['class']
		},
		allowedSchemes: ['http', 'https', 'mailto'],
		allowProtocolRelative: false,
		transformTags: {
			a: (_tagName, attribs) => ({
				tagName: 'a',
				attribs: {
					...attribs,
					rel: 'noopener noreferrer'
				}
			})
		}
	});
}
