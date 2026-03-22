import type { PageServerLoad } from './$types';
import matter from 'gray-matter';

export const prerender = true;

const isPublishedProject = (data: Record<string, unknown>) =>
	data.draft === false && data.publish === true;

export const load: PageServerLoad = async () => {
	const modules = import.meta.glob<string>('../../projects/*.md', {
		eager: true,
		import: 'default',
		query: '?raw'
	});

	const projects = Object.entries(modules).flatMap(([path, raw]) => {
		if (typeof raw !== 'string') return [];

		const slug = path.split('/').pop()?.replace(/\.md$/, '');

		if (!slug) return [];

		const { data } = matter(raw);
		const meta = data as Record<string, unknown>;

		if (!isPublishedProject(meta)) return [];

		return [
			{
				slug,
				title: typeof meta.title === 'string' && meta.title.trim() ? meta.title.trim() : slug,
				date: typeof meta.date === 'string' && meta.date.trim() ? meta.date.trim() : null,
				description:
					typeof meta.description === 'string' && meta.description.trim()
						? meta.description.trim()
						: null
			}
		];
	});

	projects.sort((a, b) => (b.date ?? '').localeCompare(a.date ?? ''));

	return { projects };
};
