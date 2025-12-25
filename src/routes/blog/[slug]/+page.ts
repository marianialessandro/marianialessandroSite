// src/routes/blog/[slug]/+page.ts
import { allPosts } from '$lib/posts';
import { error } from '@sveltejs/kit';

export const prerender = true;

export function load({ params }) {
  const post = allPosts.find((p) => p.slug === params.slug);
  if (!post) throw error(404, 'Articolo non trovato');
  return {
    meta: post.meta,
    Content: post.component
  };
}
