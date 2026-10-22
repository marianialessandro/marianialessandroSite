import * as publicEnv from '$env/static/public';

// Optional settings preserve existing local environments and the Laravel build path.
const settings = publicEnv as Record<string, string>;
export const cmsProvider = settings.PUBLIC_CMS_PROVIDER || 'laravel';
export const wordpressUrl = (settings.PUBLIC_WORDPRESS_URL || 'https://blog.marianialessandro.com/cms').replace(/\/$/, '');

if (!['laravel', 'wordpress'].includes(cmsProvider)) {
	throw new Error(`Unsupported CMS provider: ${cmsProvider}`);
}
