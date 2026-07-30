// src/lib/admin/errors.ts
export class ApiValidationError extends Error {
	fieldErrors: Record<string, string>;

	constructor(fieldErrors: Record<string, string>, message = 'Dati non validi.') {
		super(message);
		this.name = 'ApiValidationError';
		this.fieldErrors = fieldErrors;
	}
}

/**
 * Throws ApiValidationError (with per-field messages) for a 422 response,
 * or a generic Error for any other non-ok response. No-op when res.ok.
 */
export async function throwIfError(res: Response): Promise<void> {
	if (res.ok) return;

	const body = await res.json().catch(() => null);

	if (res.status === 422 && body?.errors) {
		const fieldErrors: Record<string, string> = {};
		for (const [field, messages] of Object.entries(body.errors as Record<string, string[]>)) {
			fieldErrors[field] = messages.join(' ');
		}
		throw new ApiValidationError(fieldErrors, body.message);
	}

	throw new Error(body?.message ?? `Richiesta non riuscita (${res.status}).`);
}
