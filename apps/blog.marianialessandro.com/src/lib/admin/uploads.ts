// src/lib/admin/uploads.ts
import { authedFetch } from './auth';

export async function uploadImage(file: File): Promise<string> {
	const formData = new FormData();
	formData.append('file', file);

	const res = await authedFetch('/uploads', { method: 'POST', body: formData });

	if (!res.ok) {
		const body = await res.json().catch(() => null);
		throw new Error(body?.message ?? 'Caricamento immagine non riuscito.');
	}

	const body: { url: string } = await res.json();
	return body.url;
}

export function pickImageFile(): Promise<File | null> {
	return new Promise((resolve) => {
		const input = document.createElement('input');
		input.type = 'file';
		input.accept = 'image/*';
		input.onchange = () => resolve(input.files?.[0] ?? null);
		input.click();
	});
}
