# marianialessandro Monorepo

This repository is now an `npm` workspace monorepo with three SvelteKit apps and one shared package.

## Structure

```text
.
├── apps
│   ├── files.marianialessandro.com
│   ├── apps.marianialessandro.com
│   └── marianialessandro.com
├── packages
│   └── shared
├── package.json
└── package-lock.json
```

- `apps/marianialessandro.com`: the main personal website.
- `apps/files.marianialessandro.com`: the secondary SvelteKit app.
- `apps/apps.marianialessandro.com`: the applications hub, bootstrapped to reuse shared components.
- `packages/shared`: shared Svelte components, shared assets, and the global stylesheet.

## MacOS Commands

Install all workspace dependencies from the repo root:

```bash
cd /Users/marianialessandro/repository/marianialessandroSite
npm install
```

Run all development servers concurrently:

```bash
npm run dev
```

Run each app individually from the repo root:

```bash
npm run dev:site
npm run dev:files
npm run dev:apps
```

Run each app directly from its own directory:

```bash
cd /Users/marianialessandro/repository/marianialessandroSite/apps/marianialessandro.com
npm run dev

cd /Users/marianialessandro/repository/marianialessandroSite/apps/files.marianialessandro.com
npm run dev

cd /Users/marianialessandro/repository/marianialessandroSite/apps/apps.marianialessandro.com
npm run dev
```

Build all projects for production:

```bash
cd /Users/marianialessandro/repository/marianialessandroSite
npm run build
```

Build each app individually:

```bash
npm run build:site
npm run build:files
npm run build:apps
```

Run workspace checks:

```bash
npm run check
```

## Shared Package Usage

The shared workspace package is `@marianialessandro/shared`.

```ts
import { Footer, Header, TableOfContents } from '@marianialessandro/shared';
import '@marianialessandro/shared/styles.css';
```

Assets can be imported through the shared package exports:

```ts
import githubIcon from '@marianialessandro/shared/images/github.svg';
```

## Notes

- The footer used across apps lives in `packages/shared/src/lib/components/Footer.svelte`.
- The shared global stylesheet lives in `packages/shared/src/styles/app.css`.
- The `CD - Deploy marianialessandro.com` workflow publishes `apps/marianialessandro.com/build/` to `public_html/`.
- The `CD - Deploy files.marianialessandro.com` workflow publishes `apps/files.marianialessandro.com/build/` to `files.marianialessandro.com/`.
