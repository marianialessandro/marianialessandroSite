import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import { bunny } from 'laravel-vite-plugin/fonts';
import tailwindcss from '@tailwindcss/vite';

const appDir = path.dirname(fileURLToPath(import.meta.url));

function readEnvFile(fileName) {
	const filePath = path.join(appDir, fileName);

	if (!fs.existsSync(filePath)) {
		return {};
	}

	const env = {};

	for (const line of fs.readFileSync(filePath, 'utf8').split(/\r?\n/)) {
		const trimmed = line.trim();

		if (!trimmed || trimmed.startsWith('#')) {
			continue;
		}

		const separatorIndex = trimmed.indexOf('=');

		if (separatorIndex === -1) {
			continue;
		}

		const key = trimmed.slice(0, separatorIndex).trim();
		let value = trimmed.slice(separatorIndex + 1).trim();

		if (
			(value.startsWith('"') && value.endsWith('"')) ||
			(value.startsWith("'") && value.endsWith("'"))
		) {
			value = value.slice(1, -1);
		}

		env[key] = value;
	}

	for (const [key, value] of Object.entries(env)) {
		env[key] = value.replace(
			/\${([A-Z0-9_]+)}/g,
			(_, name) => env[name] ?? process.env[name] ?? ''
		);
	}

	return env;
}

export default defineConfig(({ command }) => {
	const env = readEnvFile(command === 'serve' ? '.env.local' : '.env');
	const viteEnv = Object.fromEntries(
		Object.entries(env).filter(([key]) => key.startsWith('VITE_'))
	);

	for (const [key, value] of Object.entries(viteEnv)) {
		process.env[key] = value;
	}

	return {
		envDir: false,
		define: Object.fromEntries(
			Object.entries(viteEnv).map(([key, value]) => [
				`import.meta.env.${key}`,
				JSON.stringify(value)
			])
		),
		plugins: [
			laravel({
				input: ['resources/css/app.css', 'resources/js/app.js'],
				refresh: true,
				fonts: [
					bunny('Instrument Sans', {
						weights: [400, 500, 600]
					})
				]
			}),
			tailwindcss()
		],
		server: {
			watch: {
				ignored: ['**/storage/framework/views/**']
			}
		}
	};
});
