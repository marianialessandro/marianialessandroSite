<?php

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}
$options = getopt('', ['api-env:', 'output:', 'cms-url:', 'frontend-url:', 'repository:', 'ref:', 'allow-legacy-import', 'help']);
if (isset($options['help']) || !isset($options['api-env'], $options['output'])) {
    echo "Usage: php configure.php --api-env=PATH --output=NEW_FILE [--cms-url=URL] [--frontend-url=URL] [--repository=OWNER/REPO] [--ref=BRANCH] [--allow-legacy-import]\nCreates a private PHP configuration using the existing Laravel database credentials. No GitHub token is needed. --repository and --ref remain accepted for CLI compatibility and have no effect. Never overwrites a file or prints secrets.\n";
    exit(isset($options['help']) ? 0 : 64);
}
require dirname(__DIR__, 3) . '/apps/api.marianialessandro.com/vendor/autoload.php';
$path = realpath($options['api-env']);
if (!$path) {
    fwrite(STDERR, "API environment file not found.\n");
    exit(66);
}
$legacy = Dotenv\Dotenv::createArrayBacked(dirname($path), basename($path))->load();
foreach (['DB_DATABASE', 'DB_USERNAME', 'DB_HOST'] as $required) {
    if (empty($legacy[$required])) {
        fwrite(STDERR, "Missing required database setting: {$required}\n");
        exit(65);
    }
}
if (($legacy['DB_CONNECTION'] ?? 'mysql') !== 'mysql') {
    fwrite(STDERR, "WordPress requires the production MySQL/MariaDB configuration.\n");
    exit(65);
}
$configuration = [
    'WORDPRESS_DB_NAME' => $legacy['DB_DATABASE'],
    'WORDPRESS_DB_USER' => $legacy['DB_USERNAME'],
    'WORDPRESS_DB_PASSWORD' => $legacy['DB_PASSWORD'] ?? '',
    'WORDPRESS_DB_HOST' => $legacy['DB_HOST'] . ':' . ($legacy['DB_PORT'] ?? '3306'),
    'WORDPRESS_TABLE_PREFIX' => 'wp_blog_',
    'WORDPRESS_URL' => $options['cms-url'] ?? 'https://blog.marianialessandro.com/cms',
    'BLOG_FRONTEND_URL' => $options['frontend-url'] ?? 'https://blog.marianialessandro.com',
    'BLOG_ALLOW_LEGACY_IMPORT' => isset($options['allow-legacy-import']),
];
foreach (['AUTH_KEY', 'SECURE_AUTH_KEY', 'LOGGED_IN_KEY', 'NONCE_KEY', 'AUTH_SALT', 'SECURE_AUTH_SALT', 'LOGGED_IN_SALT', 'NONCE_SALT'] as $key) {
    $configuration[$key] = bin2hex(random_bytes(48));
}
$old_mask = umask(0077);
$file = fopen($options['output'], 'x');
umask($old_mask);
if (!$file) {
    fwrite(STDERR, "Cannot create configuration; the output must be a new file.\n");
    exit(73);
}
fwrite($file, "<?php\nreturn " . var_export($configuration, true) . ";\n");
fclose($file);
echo "Private CMS configuration created. Upload it to cms/blog-config.php using your hosting file manager.\n";
