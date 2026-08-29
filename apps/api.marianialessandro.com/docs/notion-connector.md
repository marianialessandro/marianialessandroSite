# Notion database connector

The API contains a read-only Notion connector for a fixed allowlist of Notion data sources.
It intentionally does **not** expose an endpoint that accepts an arbitrary Notion data source ID.

## Security model

- The Notion installation token exists only in the API server environment.
- Only aliases listed in `NOTION_DATA_SOURCES` can be queried.
- Every connector endpoint is protected by the existing `auth:web` middleware and therefore requires an authenticated Laravel session.
- The Notion connector does not require the `admin` middleware: any authenticated user can use it.
- The connector only calls read endpoints (`retrieve data source` and `query data source`).
- The list endpoint exposes aliases, not Notion IDs or credentials.
- Requests are rate limited before reaching Notion.

## Notion configuration

Create an internal connection in the Notion developer portal and enable only the content capability needed by this connector: **Read content**.
Grant the connection access only to the databases/pages the API is allowed to read.

Notion API versions from `2025-09-03` onward distinguish a database container from its data sources. Query operations use a `data_source_id`, not a `database_id`.
This connector targets API version `2026-03-11` by default.

## Environment variables

```dotenv
NOTION_TOKEN=ntn_...
NOTION_VERSION=2026-03-11
NOTION_DATA_SOURCES='{"university":"<data-source-id>","habits":"<data-source-id>"}'
NOTION_TIMEOUT=10
NOTION_CONNECT_TIMEOUT=3
NOTION_MAX_RETRIES=1
NOTION_RATE_LIMIT_PER_MINUTE=120
```

`NOTION_DATA_SOURCES` is a JSON object where the key is the stable alias exposed by this API and the value is the corresponding Notion `data_source_id`.
Changing the allowlist therefore does not require a code change.

Do not commit a real `NOTION_TOKEN` or real private IDs to the repository. Configure them in the deployed server's `.env` file.
The current FTP deployment intentionally excludes `.env`, so production secrets remain server-side across deployments.

After changing production environment values, clear Laravel's cached configuration if configuration caching is enabled:

```bash
php artisan config:clear
```

## Authentication

All endpoints below require an authenticated Laravel `web` session. An unauthenticated request returns `401` before any request is sent to Notion.

The connector deliberately uses only `auth:web`, not the `admin` middleware. This means the authorization boundary is "logged in", as opposed to "logged in and administrator".

At the moment the application's login controller accepts only users with `is_admin = true`; if that restriction is relaxed later, authenticated non-admin users will automatically be able to use these Notion endpoints.

## API

### List configured aliases

```http
GET /api/notion/sources
```

Example response:

```json
{
  "data": [
    { "alias": "habits" },
    { "alias": "university" }
  ]
}
```

### Retrieve a configured data-source schema

```http
GET /api/notion/{source}
```

The response is the Notion data-source object.

### Query a configured data source

```http
POST /api/notion/{source}/query
Content-Type: application/json
```

Supported body fields:

```json
{
  "page_size": 50,
  "start_cursor": null,
  "filter": {
    "property": "Done",
    "checkbox": {
      "equals": true
    }
  },
  "sorts": [
    {
      "timestamp": "last_edited_time",
      "direction": "descending"
    }
  ],
  "in_trash": false,
  "result_type": "page"
}
```

The connector validates the outer request shape, then forwards Notion-compatible `filter` and `sorts` structures to the configured data source.
Pagination is preserved through Notion's `next_cursor` / `start_cursor` mechanism.

## Error handling

- Unauthenticated requests return `401` without contacting Notion.
- Unknown aliases return `404` without contacting Notion.
- Invalid query envelopes return Laravel validation errors (`422`).
- Notion `400` query errors are mapped to `422` so invalid filters/sorts can be diagnosed.
- Notion `429` is retried according to `NOTION_MAX_RETRIES`; if still rate-limited the API returns `503` and preserves `Retry-After`.
- Notion authentication/access failures and upstream 5xx failures are returned as gateway errors without exposing the API token.

## Extending the connector

Keep generic Notion access authenticated. If a frontend needs public data, add a domain-specific endpoint that reads a specific configured alias and transforms the Notion response into a stable application DTO/resource. Do not make the generic connector public merely to support a single frontend use case.

If write support is added later, create separate write methods/routes and explicitly enable Notion's write capabilities. Do not broaden the existing read-only connector implicitly.
