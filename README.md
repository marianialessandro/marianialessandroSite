# marianialessandro Monorepo

This repository is an `npm` workspace monorepo for the public site, related SvelteKit apps, a Laravel API, and shared frontend code.

## Structure

```text
.
├── apps
│   ├── api.marianialessandro.com
│   ├── blog.marianialessandro.com
│   ├── files.marianialessandro.com
│   └── marianialessandro.com
├── packages
│   └── shared
├── docker-compose.yml
├── package.json
└── package-lock.json
```

- `apps/marianialessandro.com`: the main SvelteKit personal website.
- `apps/files.marianialessandro.com`: the SvelteKit files subdomain.
- `apps/blog.marianialessandro.com`: the SvelteKit blog frontend.
- `apps/api.marianialessandro.com`: the Laravel API service — JSON endpoints only, no frontend/UI.
- `packages/shared`: shared Svelte components, shared assets, and the global stylesheet.

## Setup

Install workspace dependencies from the repository root:

```bash
npm install
```

The Laravel API also needs Composer dependencies inside its app directory:

```bash
composer install --working-dir apps/api.marianialessandro.com
```

## Development

Run the SvelteKit development servers for the main site, files app, and blog:

```bash
npm run dev
```

Run individual frontend apps:

```bash
npm run dev:site
npm run dev:files
npm run dev:blog
```

Run the Laravel API locally:

```bash
npm run dev:api
```

Run the Laravel API with MySQL through Docker:

```bash
docker compose up -d --build
curl http://localhost:8000/api/health
```

Stop the Docker services:

```bash
docker compose down
```

## Build And Check

Build all workspace projects:

```bash
npm run build
```

Build individual projects:

```bash
npm run build:site
npm run build:files
npm run build:blog
```

The API is a JSON-only Laravel application and has no frontend build step.

Run workspace checks:

```bash
npm run check
```

Run Laravel API tests:

```bash
npm run test:api
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

## Deployment

- `CD - Deploy marianialessandro.com` publishes `apps/marianialessandro.com/build/` to `public_html/`.
- `CD - Deploy files.marianialessandro.com` publishes `apps/files.marianialessandro.com/build/` to `files.marianialessandro.com/`.
- `CD - Deploy blog.marianialessandro.com` publishes `apps/blog.marianialessandro.com/build/` to `blog.marianialessandro.com/`.
- `CD - Deploy api.marianialessandro.com` builds a hardened shared-hosting
  artifact and publishes it to `api.marianialessandro.com/`.

### API production configuration

The hosting provider fixes the document root for `api.marianialessandro.com` to
`/public/api.marianialessandro.com`. The deploy artifact therefore places
Laravel's public `index.php`, `.htaccess`, favicon, and `robots.txt` directly in
that directory. Application directories are present in the same provider-owned
webroot but are blocked both by the root rewrite rules and by a deny-all
`.htaccess` inside every private top-level directory.

Put the non-versioned production `.env` at
`/public/api.marianialessandro.com/.env`, beside the deployed `index.php`. The
deployment never uploads or deletes this file, and Apache explicitly denies
HTTP access to it.

Configure the API’s non-versioned production `.env` with at least:

```dotenv
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.marianialessandro.com

DB_CONNECTION=mysql
DB_HOST=localhost
DB_PORT=3306
DB_DATABASE=nome_database
DB_USERNAME=utente_database
DB_PASSWORD=password_database

SESSION_DRIVER=database
SESSION_DOMAIN=.marianialessandro.com
SESSION_SECURE_COOKIE=true
SESSION_HTTP_ONLY=true
SESSION_SAME_SITE=lax
SESSION_ENCRYPT=true
SESSION_EXPIRE_ON_CLOSE=true

CORS_ALLOWED_ORIGINS=https://blog.marianialessandro.com
SANCTUM_STATEFUL_DOMAINS=blog.marianialessandro.com
```

The FTP workflow uploads the application but cannot execute database migrations.
For the first installation on hosting without a server console:

1. Create an empty MySQL/MariaDB database from the hosting panel.
2. Open that database in phpMyAdmin.
3. Select **Import**, choose
   `apps/api.marianialessandro.com/database/phpmyadmin/000-initial-schema.sql`,
   and run the import once.
4. Put the database credentials in the server-side `.env`.
5. Create the first administrator from phpMyAdmin with an `INSERT` into
   `users`, setting `is_admin` to `1` and using a BCrypt password hash
   (`$2y$...`). MySQL `MD5()`, `SHA1()`, and `PASSWORD()` are not compatible
   with Laravel authentication. Change the temporary credentials immediately
   from **Admin → Account** after the first login.

The SQL file creates the complete schema and registers every current migration
in Laravel’s `migrations` table. It must not be imported again over an existing
database. Future schema changes require a numbered upgrade SQL file imported
through phpMyAdmin; uploading files via FTP alone never changes the database.

If server console access becomes available later, use Laravel normally after
each API deployment:

```bash
php artisan migrate --force
php artisan optimize:clear
php artisan optimize
```

The `is_admin` migration preserves all existing accounts as administrators;
new accounts are unprivileged by default unless created through the protected
admin account interface or `php artisan users:create-admin`.
