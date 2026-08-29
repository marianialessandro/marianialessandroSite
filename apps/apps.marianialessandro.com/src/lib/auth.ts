import { browser } from '$app/environment';
import { goto } from '$app/navigation';
import { PUBLIC_API_BASE_URL } from '$env/static/public';

const API_BASE_URL = PUBLIC_API_BASE_URL.replace(/\/+$/, '');
const CSRF_COOKIE_URL = `${new URL(API_BASE_URL).origin}/sanctum/csrf-cookie`;

let csrfRequest: Promise<void> | null = null;

export type AuthUser = {
	id: number;
	name: string;
	email: string;
	is_admin: boolean;
	created_at: string;
};

function readCookie(name: string): string | null {
	if (!browser) return null;

	const prefix = `${name}=`;
	const cookie = document.cookie
		.split(';')
		.map((value) => value.trim())
		.find((value) => value.startsWith(prefix));

	return cookie ? decodeURIComponent(cookie.slice(prefix.length)) : null;
}

async function ensureCsrfCookie(force = false): Promise<void> {
	if (!browser) throw new Error('Autenticazione disponibile solo nel browser.');
	if (!force && readCookie('XSRF-TOKEN')) return;

	if (!csrfRequest || force) {
		csrfRequest = fetch(CSRF_COOKIE_URL, {
			method: 'GET',
			credentials: 'include',
			headers: {
				Accept: 'application/json',
				'X-Requested-With': 'XMLHttpRequest'
			}
		}).then((response) => {
			if (!response.ok) throw new Error('Impossibile inizializzare la sessione sicura.');
		});
	}

	try {
		await csrfRequest;
	} finally {
		csrfRequest = null;
	}
}

function isReadRequest(method: string): boolean {
	return ['GET', 'HEAD', 'OPTIONS'].includes(method);
}

async function apiFetch(path: string, init: RequestInit = {}, retryCsrf = true): Promise<Response> {
	const method = (init.method ?? 'GET').toUpperCase();
	const headers = new Headers(init.headers);

	headers.set('Accept', 'application/json');
	headers.set('X-Requested-With', 'XMLHttpRequest');

	if (init.body && !(init.body instanceof FormData) && !headers.has('Content-Type')) {
		headers.set('Content-Type', 'application/json');
	}

	if (!isReadRequest(method)) {
		await ensureCsrfCookie();
		const token = readCookie('XSRF-TOKEN');
		if (!token) throw new Error('Token CSRF non disponibile.');
		headers.set('X-XSRF-TOKEN', token);
	}

	const response = await fetch(`${API_BASE_URL}${path}`, {
		...init,
		method,
		headers,
		credentials: 'include'
	});

	if (response.status === 419 && !isReadRequest(method) && retryCsrf) {
		await ensureCsrfCookie(true);
		return apiFetch(path, init, false);
	}

	return response;
}

export async function login(email: string, password: string): Promise<AuthUser> {
	const response = await apiFetch('/auth/login', {
		method: 'POST',
		body: JSON.stringify({ email, password })
	});
	const body = await response.json().catch(() => null);

	if (!response.ok) {
		const message = body?.errors
			? Object.values(body.errors).flat().join(' ')
			: (body?.message ?? 'Accesso non riuscito.');
		throw new Error(message);
	}

	return body.user;
}

export async function logout(): Promise<void> {
	const response = await apiFetch('/auth/logout', { method: 'POST' });

	if (!response.ok && response.status !== 401) {
		throw new Error('Disconnessione non riuscita. Riprova.');
	}
}

export async function fetchMe(): Promise<AuthUser | null> {
	const response = await apiFetch('/auth/me');

	if (response.status === 401) return null;
	if (!response.ok) throw new Error('Impossibile verificare la sessione.');

	const body = await response.json();
	return body.data;
}

function currentProtectedLocation(): string {
	if (!browser) return '/protected';
	return `${window.location.pathname}${window.location.search}${window.location.hash}`;
}

export function loginUrl(redirectTo = currentProtectedLocation()): string {
	return `/login?redirect=${encodeURIComponent(redirectTo)}`;
}

/**
 * Fetch helper for session-authenticated application API calls. The session
 * cookie is HttpOnly; mutating requests automatically include Laravel's CSRF
 * token. A 401 sends the user to the app login and preserves the current URL.
 */
export async function authedFetch(path: string, init: RequestInit = {}): Promise<Response> {
	const response = await apiFetch(path, init);

	if (response.status === 401 && browser) {
		await goto(loginUrl());
	}

	return response;
}
