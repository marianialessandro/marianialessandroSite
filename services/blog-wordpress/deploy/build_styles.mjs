import { parseArgs } from 'node:util';
import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import postcss from 'postcss';

const { values } = parseArgs({ options: { output: { type: 'string' }, help: { type: 'boolean' } } });
if (values.help || !values.output) {
	console.log('Usage: node build_styles.mjs --output=FILE\nExtract the existing blog styles for the dynamic PHP frontend.');
	process.exit(values.help ? 0 : 64);
}

const blog = 'apps/blog.marianialessandro.com/src';
const components = [
	[`${blog}/routes/+layout.svelte`, 'portfolio-site'],
	[`${blog}/lib/components/BlogHeader.svelte`, 'portfolio-header'],
	[`${blog}/routes/+page.svelte`, 'portfolio-home'],
	[`${blog}/routes/archive/+page.svelte`, 'portfolio-archive'],
	[`${blog}/lib/components/BlogHero.svelte`, 'portfolio-hero'],
	[`${blog}/lib/components/PostCard.svelte`, 'portfolio-card'],
	[`${blog}/lib/components/PostMeta.svelte`, 'portfolio-meta'],
	[`${blog}/lib/components/TagList.svelte`, 'portfolio-tags'],
	[`${blog}/lib/components/ArticleHeader.svelte`, 'portfolio-article-header'],
	[`${blog}/lib/layouts/PostLayout.svelte`, 'portfolio-post-layout'],
	['packages/shared/src/lib/components/TableOfContents.svelte', 'portfolio-toc']
];
const base = postcss.parse(await readFile('packages/shared/src/styles/app.css', 'utf8'));
base.walkAtRules((rule) => { if (['import', 'plugin'].includes(rule.name)) rule.remove(); });
const styles = [base.toString(), await readFile(`${blog}/lib/styles/blog.css`, 'utf8'), await readFile('services/blog-wordpress/frontend/blog-assets/books.css', 'utf8')];
for (const [path, scope] of components) {
	const source = await readFile(path, 'utf8');
	const css = source.match(/<style[^>]*>([\s\S]*?)<\/style>/)?.[1];
	if (!css) throw new Error(`Missing component styles: ${path}`);
	const root = postcss.parse(css, { from: path });
	root.walkRules((rule) => {
		rule.selectors = rule.selectors.map((selector) => {
			const unscoped = selector.replace(/:global\(([^)]+)\)/g, '$1');
			return unscoped === ':root' ? unscoped : `.${scope} ${unscoped}`;
		});
	});
	styles.push(`/* Styles from ${path}. */\n${root.toString()}`);
}
styles.push('@font-face { font-family: "Fira Mono"; font-style: normal; font-weight: 400; font-display: swap; src: url("./fira-mono-latin-400-normal.woff2") format("woff2"); } .portfolio-card { height: 100%; } .portfolio-toc a.link { display: block; text-decoration: none; }');
await writeFile(resolve(values.output), styles.join('\n\n'));
