# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Before merging or committing to `main`

Before merging or pushing a commit to `main`, make sure every test that runs in this repo's GitHub Actions workflows passes locally first:

- `php artisan test` in `apps/api.marianialessandro.com` (Laravel feature/unit tests)
- `npm test --workspace @marianialessandro/blog.marianialessandro.com` (Vitest)
- The full `npm run build` (a broken prerender build fails CI just like a failing test — see the SvelteKit gotcha below)

These are exactly the checks `CI - Build Check` (`.github/workflows/ci-check.yml`) runs on every PR into `main`. Don't merge if any of them fail.

## Repository structure

`npm` workspaces monorepo: three static SvelteKit frontends and one Laravel JSON API, plus a shared Svelte package.

```
apps/marianialessandro.com    — main personal site (SvelteKit, adapter-static)
apps/files.marianialessandro.com — files subdomain (SvelteKit, adapter-static)
apps/blog.marianialessandro.com  — blog frontend + admin CMS UI (SvelteKit, adapter-static)
apps/api.marianialessandro.com   — Laravel API backing the blog (JSON only, no views)
packages/shared                  — shared Svelte components, assets, global stylesheet
```

Workspace package names are scoped as `@marianialessandro/<dir-name>` (e.g. `@marianialessandro/blog.marianialessandro.com`), used in `npm run <script> --workspace <name>` commands.

## Commands

Run from the repo root unless noted.

```bash
npm install                                                    # install all workspaces
composer install --working-dir apps/api.marianialessandro.com  # install API deps

npm run dev            # site + files + blog dev servers concurrently
npm run dev:site        # apps/marianialessandro.com    (port 5173)
npm run dev:files       # apps/files.marianialessandro.com (port 5174)
npm run dev:blog        # apps/blog.marianialessandro.com  (port 5175)
npm run dev:api         # Laravel API via `composer dev`
docker compose up -d --build   # API + MySQL via Docker instead

npm run build           # build all workspaces
npm run build:site / build:files / build:blog

npm run check            # svelte-check across all workspaces
npm run lint              # prettier --check . && eslint .
npm run format             # prettier --write .

npm test --workspace @marianialessandro/blog.marianialessandro.com   # blog Vitest suite
npm run test:api                                                      # composer test (Laravel)
php artisan test --filter=TestName    # single Laravel test (run inside apps/api.marianialessandro.com)
```

The API has no frontend build step — it's JSON-only.

## Architecture

### Blog is a static site backed by an API — content changes require a rebuild

`apps/blog.marianialessandro.com` is prerendered with `adapter-static` (`fallback: '200.html'` for the admin SPA routes). Post content lives in the Laravel API's database, not in the blog repo. `src/lib/posts.ts` fetches from `PUBLIC_API_BASE_URL` at build time — the deployed HTML is a point-in-time snapshot, not live-rendered.

Because of this, publishing/editing a post through the admin panel doesn't change the live site by itself: `PostController::store()` (`apps/api.marianialessandro.com/app/Http/Controllers/PostController.php`) calls `App\Services\BlogDeployTrigger`, which fires a `workflow_dispatch` against `deploy-blog.yml` via the GitHub API (needs `GITHUB_DEPLOY_TOKEN` / `GITHUB_REPOSITORY` configured in the API's `.env`) so the blog rebuilds and redeploys. `deploy-blog.yml` also runs on an hourly cron as a safety net for scheduled/future-dated posts that need to go live with no admin action that day.

`/[slug]/+page.ts` prerenders every published post. SvelteKit only discovers `/[slug]` instances by crawling links from other prerendered pages (home, archive) *or* via the route's `entries` export — with zero published posts there's nothing to crawl, which used to hard-fail the production build (fixed by adding `entries` to fetch slugs directly from the API, plus `handleUnseenRoutes` in `svelte.config.js` that only tolerates `/[slug]` being unseen, not any other route). Keep this in mind if adding other API-backed dynamic routes to any of the SvelteKit apps.

The public `/api/posts` and `/api/posts/{post}` endpoints only return posts where `draft = false` and `date <= now()` (`PostController::index`/`show`); the admin panel uses separate `adminIndex`/`adminShow` endpoints to see everything.

### Auth: session-based, shared across subdomains

The API uses Laravel's `web` session guard, not token auth — `AuthController::login` calls `Auth::guard('web')->login()`. Session cookies are shared across `*.marianialessandro.com` via `SESSION_DOMAIN=.marianialessandro.com`, and CORS (`config/cors.php`) is locked to the exact blog origin (`CORS_ALLOWED_ORIGINS`) with `supports_credentials: true`. Admin access additionally requires `is_admin` on the `User` model, enforced via the `admin` middleware group (`EnsureUserIsAdmin`) wrapping all mutating `/admin/*`, `/posts` (write), and `/users` routes in `routes/api.php`.

### Deployment pipeline and its ordering dependency

Each app deploys independently via FTP to shared hosting on push to `main`, except the blog, which is intentionally chained after the API:

- `deploy.yml`, `deploy-files.yml` — independent, push-triggered.
- `deploy-api.yml` — deploys the API, then runs a `deploy-blog` job (job name **"Deploy blog after API"**) that calls `deploy-blog.yml` via `workflow_call` only `needs: deploy-api`. This exists because the blog build fetches from the live API — deploying blog before an API change ships can prerender against stale/broken data. The `deploy-api` job also polls `/api/health` after the FTP sync and verifies private paths (`.env`, `config/app.php`, etc.) 403/404 before letting the blog job start.
- `deploy-blog.yml` is also independently callable (`workflow_dispatch`, hourly `schedule`) for the scheduled-post safety net described above.

### API shared-hosting deployment shape

The API isn't deployed as a normal Laravel app root — the hosting provider fixes the document root to `/public/api.marianialessandro.com`, so `deploy/shared-hosting/build.sh` produces an artifact that places `index.php`/`.htaccess`/etc. directly in that directory while keeping `app/`, `config/`, `database/`, etc. alongside but blocked by rewrite rules and deny-all `.htaccess` files (see `deploy/shared-hosting/root.htaccess`, `deny-all.htaccess`). The FTP deploy step can't run artisan commands — DB schema changes need a manually-imported SQL file via phpMyAdmin (see README's "API production configuration" section for the first-install and admin-bootstrap procedure).

### Shared package

`packages/shared` (`@marianialessandro/shared`) exports Svelte components (`Header`, `Footer`, `TableOfContents`, `FileArchive*`), a global stylesheet (`@marianialessandro/shared/styles.css`), and image assets, consumed by all three SvelteKit apps.
