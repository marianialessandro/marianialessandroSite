// src/lib/markdown.ts
import MarkdownIt from 'markdown-it';
import footnote from 'markdown-it-footnote';
import taskLists from 'markdown-it-task-lists';

const md: MarkdownIt = new MarkdownIt({ html: true, linkify: true, typographer: false });
md.use(footnote);
md.use(taskLists, { enabled: true, label: true });

export function renderMarkdown(content: string): string {
	return md.render(content);
}
