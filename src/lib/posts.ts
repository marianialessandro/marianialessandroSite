// src/lib/posts.ts
export type PostMeta = {
  title: string;
  date: string;           // ISO string
  description?: string;
  tags?: string[];
  draft?: boolean;
  cover?: string;
};

type Module = {
  metadata: PostMeta;
  default: unknown; // componente svelte mdsvex
};

const modules = import.meta.glob<Module>('/src/posts/**/*.md', { eager: true });

export type Post = {
  slug: string;
  meta: PostMeta;
  component: unknown;
  path: string;
};

export const allPosts: Post[] = Object.entries(modules)
  .map(([path, mod]) => {
    const slug = path.split('/').pop()!.replace(/\.md$/, '');
    return { slug, meta: mod.metadata, component: mod.default, path };
  })
  .filter((p) => !p.meta.draft)
  .sort(
    (a, b) =>
      new Date(b.meta.date).getTime() - new Date(a.meta.date).getTime()
  );
