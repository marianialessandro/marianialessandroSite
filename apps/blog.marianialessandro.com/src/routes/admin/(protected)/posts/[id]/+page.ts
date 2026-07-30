// The post id is only known at runtime; this route is client-only (ssr is
// already disabled by the admin layout) and cannot be prerendered.
export const prerender = false;
