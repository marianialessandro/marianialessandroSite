// src/routes/blog/+page.ts
import { allPosts } from '$lib/posts';

export const prerender = true;

export function load() {
  return {
    posts: allPosts.map(({ slug, meta }) => ({ slug, ...meta }))
  };
}
