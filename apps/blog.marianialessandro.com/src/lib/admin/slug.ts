// src/lib/admin/slug.ts
const DIACRITICS_RANGE = String.fromCharCode(0x0300) + '-' + String.fromCharCode(0x036f);
const DIACRITICS_REGEX = new RegExp('[' + DIACRITICS_RANGE + ']', 'g');

export function slugify(input: string): string {
	return input
		.toLowerCase()
		.normalize('NFD')
		.replace(DIACRITICS_REGEX, '')
		.replace(/[^a-z0-9\s-]/g, '')
		.trim()
		.replace(/\s+/g, '-')
		.replace(/-+/g, '-');
}
