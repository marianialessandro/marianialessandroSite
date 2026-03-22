import type { ComponentType } from 'svelte';

export type PostMeta = {
	title: string;
	date: string;
	description?: string;
	tags?: string[];
	draft?: boolean;
	cover?: string;
};

type Module = {
	metadata: PostMeta;
	default: ComponentType;
};

const modules = import.meta.glob<Module>('/src/posts/**/*.md', { eager: true });

export type Post = {
	slug: string;
	meta: PostMeta;
	component: ComponentType;
	path: string;
};

const isValidDate = (value: string | undefined) => {
	if (!value) return false;
	return !Number.isNaN(new Date(value).getTime());
};

export const allPosts: Post[] = Object.entries(modules)
	.map(([path, mod]) => {
		const slug = path.split('/').pop()?.replace(/\.md$/, '') ?? '';

		return {
			slug,
			meta: mod.metadata,
			component: mod.default,
			path
		};
	})
	.filter((post) => post.slug.length > 0)
	.filter((post) => !post.meta.draft)
	.filter((post) => isValidDate(post.meta.date))
	.sort((a, b) => new Date(b.meta.date).getTime() - new Date(a.meta.date).getTime());
