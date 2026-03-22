import type { PageServerLoad } from './$types';
import { error } from '@sveltejs/kit';
import matter from 'gray-matter';
import { renderMarkdown } from '$lib/markdown';

export const prerender = true;

const modules = import.meta.glob<string>('../../../projects/*.md', {
	eager: true,
	import: 'default',
	query: '?raw'
});

const pickString = (...values: unknown[]): string | null => {
	for (const value of values) {
		if (typeof value === 'string' && value.trim().length > 0) {
			return value.trim();
		}
	}

	return null;
};

const isPublishedProject = (data: Record<string, unknown>) =>
	data.draft === false && data.publish === true;

export const load: PageServerLoad = async ({ params }) => {
	const targetPath = Object.keys(modules).find((path) => path.endsWith(`/${params.slug}.md`));

	if (!targetPath) {
		throw error(404, 'Project not found');
	}

	const raw = modules[targetPath];

	if (typeof raw !== 'string') {
		throw error(500, 'Invalid project source');
	}

	const { data, content } = matter(raw);
	const meta = data as Record<string, unknown>;

	if (!isPublishedProject(meta)) {
		throw error(404, 'Project not found');
	}

	const { html } = renderMarkdown(content);

	const title = pickString(meta.title) ?? params.slug;
	const date = pickString(meta.date);
	const repo = pickString(meta.repo, meta.repolink, meta.repoLink);
	const articleLink = pickString(meta.articleLink, meta.articlelink);
	const description = pickString(meta.description);

	return {
		slug: params.slug,
		meta: {
			title,
			date: date ?? null,
			repo: repo ?? null,
			articleLink: articleLink ?? null,
			description: description ?? null
		},
		html
	};
};
