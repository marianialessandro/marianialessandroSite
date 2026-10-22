// src/routes/admin/+layout.ts
import { browser } from '$app/environment';
import { redirect } from '@sveltejs/kit';
import { cmsProvider, wordpressUrl } from '$lib/cms';

export const ssr = false;
export const prerender = true;

export function load() {
	if (browser && cmsProvider === 'wordpress') redirect(302, `${wordpressUrl}/wp-admin/`);
}
