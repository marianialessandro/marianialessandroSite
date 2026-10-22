<?php

// Secrets live in a server-only file preserved by FTP, or in environment variables for Docker.
$configuration = is_file(__DIR__ . '/blog-config.php') ? require __DIR__ . '/blog-config.php' : [];
$setting = static function (string $name, $default = '') use ($configuration) {
    $value = getenv($name);
    return $value !== false ? $value : ($configuration[$name] ?? $default);
};
foreach (['DB_NAME' => 'WORDPRESS_DB_NAME', 'DB_USER' => 'WORDPRESS_DB_USER', 'DB_PASSWORD' => 'WORDPRESS_DB_PASSWORD', 'DB_HOST' => 'WORDPRESS_DB_HOST'] as $constant => $environment) {
    define($constant, $setting($environment));
}
if (!DB_NAME || !DB_USER || !DB_HOST) {
    http_response_code(503);
    exit('CMS configuration is missing.');
}
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');
$table_prefix = $setting('WORDPRESS_TABLE_PREFIX', 'wp_blog_');
if (!preg_match('/^[a-zA-Z0-9_]+$/D', $table_prefix) || in_array($table_prefix, ['users', 'posts'], true)) {
    http_response_code(503);
    exit('Invalid CMS table prefix.');
}
foreach (['AUTH_KEY', 'SECURE_AUTH_KEY', 'LOGGED_IN_KEY', 'NONCE_KEY', 'AUTH_SALT', 'SECURE_AUTH_SALT', 'LOGGED_IN_SALT', 'NONCE_SALT'] as $constant) {
    $value = $setting($constant);
    if (!$value) {
        http_response_code(503);
        exit('CMS authentication keys are missing.');
    }
    define($constant, $value);
}
define('WP_SITEURL', rtrim($setting('WORDPRESS_URL', 'https://blog.marianialessandro.com/cms'), '/'));
define('WP_HOME', WP_SITEURL);
define('BLOG_FRONTEND_URL', rtrim($setting('BLOG_FRONTEND_URL', 'https://blog.marianialessandro.com'), '/'));
define('BLOG_ALLOW_LEGACY_IMPORT', filter_var($setting('BLOG_ALLOW_LEGACY_IMPORT', false), FILTER_VALIDATE_BOOLEAN));
define('BLOG_LEGACY_TABLE_PREFIX', $setting('BLOG_LEGACY_TABLE_PREFIX', ''));
define('DISALLOW_FILE_EDIT', true);
define('WP_DEBUG', false);
define('FORCE_SSL_ADMIN', str_starts_with(WP_SITEURL, 'https://'));
if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}
require_once ABSPATH . 'wp-settings.php';
