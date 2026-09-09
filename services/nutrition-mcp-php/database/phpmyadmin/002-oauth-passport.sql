-- OAuth schema aligned with laravel/passport v13.8.0. Existing users and Sanctum tables are preserved.
CREATE TABLE IF NOT EXISTS oauth_auth_codes (
  id CHAR(80) NOT NULL PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  client_id CHAR(36) NOT NULL,
  scopes TEXT NULL,
  revoked TINYINT(1) NOT NULL,
  expires_at DATETIME NULL,
  KEY oauth_auth_codes_user_id_index (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS oauth_access_tokens (
  id CHAR(80) NOT NULL PRIMARY KEY,
  user_id BIGINT UNSIGNED NULL,
  client_id CHAR(36) NOT NULL,
  name VARCHAR(255) NULL,
  scopes TEXT NULL,
  revoked TINYINT(1) NOT NULL,
  created_at TIMESTAMP NULL,
  updated_at TIMESTAMP NULL,
  expires_at DATETIME NULL,
  KEY oauth_access_tokens_user_id_index (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS oauth_refresh_tokens (
  id CHAR(80) NOT NULL PRIMARY KEY,
  access_token_id CHAR(80) NOT NULL,
  revoked TINYINT(1) NOT NULL,
  expires_at DATETIME NULL,
  KEY oauth_refresh_tokens_access_token_id_index (access_token_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS oauth_clients (
  id CHAR(36) NOT NULL PRIMARY KEY,
  owner_type VARCHAR(255) NULL,
  owner_id BIGINT UNSIGNED NULL,
  name VARCHAR(255) NOT NULL,
  secret VARCHAR(255) NULL,
  provider VARCHAR(255) NULL,
  redirect_uris TEXT NOT NULL,
  grant_types TEXT NOT NULL,
  revoked TINYINT(1) NOT NULL,
  created_at TIMESTAMP NULL,
  updated_at TIMESTAMP NULL,
  KEY oauth_clients_owner_type_owner_id_index (owner_type, owner_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS oauth_device_codes (
  id CHAR(80) NOT NULL PRIMARY KEY,
  user_id BIGINT UNSIGNED NULL,
  client_id CHAR(36) NOT NULL,
  user_code CHAR(8) NOT NULL,
  scopes TEXT NOT NULL,
  revoked TINYINT(1) NOT NULL,
  user_approved_at DATETIME NULL,
  last_polled_at DATETIME NULL,
  expires_at DATETIME NULL,
  KEY oauth_device_codes_user_id_index (user_id),
  KEY oauth_device_codes_client_id_index (client_id),
  UNIQUE KEY oauth_device_codes_user_code_unique (user_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

INSERT INTO migrations (migration, batch)
SELECT expected.migration, (SELECT COALESCE(MAX(batch), 0) + 1 FROM migrations)
FROM (
  SELECT '2016_06_01_000001_create_oauth_auth_codes_table' AS migration
  UNION ALL SELECT '2016_06_01_000002_create_oauth_access_tokens_table'
  UNION ALL SELECT '2016_06_01_000003_create_oauth_refresh_tokens_table'
  UNION ALL SELECT '2016_06_01_000004_create_oauth_clients_table'
  UNION ALL SELECT '2024_06_01_000001_create_oauth_device_codes_table'
) expected
WHERE NOT EXISTS (SELECT 1 FROM migrations existing WHERE existing.migration = expected.migration);
