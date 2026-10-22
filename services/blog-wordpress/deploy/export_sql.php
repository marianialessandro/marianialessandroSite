<?php

/** Generate the phpMyAdmin bootstrap from the pinned WordPress core in an isolated database. */
if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}
$options = getopt('', ['output:', 'wordpress-root:', 'help']);
if (isset($options['help']) || !isset($options['output'])) {
    echo "Usage: php export_sql.php --output=NEW_SQL_FILE [--wordpress-root=/var/www/html]\nRequires a NEW isolated MySQL database named blog_wordpress_sql_export, selected through WORDPRESS_DB_NAME. Never run against production. Generates the complete WordPress schema, default options and SQL copying existing Laravel admin accounts without embedding credentials.\n";
    exit(isset($options['help']) ? 0 : 64);
}
if (getenv('WORDPRESS_DB_NAME') !== 'blog_wordpress_sql_export' || file_exists($options['output'])) {
    fwrite(STDERR, "Requires the isolated export database and a new output file.\n");
    exit(65);
}
define('WP_INSTALLING', true);
define('DISABLE_WP_CRON', true);
require rtrim($options['wordpress-root'] ?? '/var/www/html', '/') . '/wp-load.php';
require_once ABSPATH . 'wp-admin/includes/upgrade.php';
global $wpdb, $wp_version, $wp_db_version;
if ($wpdb->prefix !== 'wp_blog_' || $wpdb->get_var('SHOW TABLES')) {
    throw new RuntimeException('The export database must be empty and use the wp_blog_ prefix.');
}
wp_install('Alessandro Mariani — Blog', 'export-only-do-not-use', 'export-only@example.invalid', false, '', wp_generate_password(64), 'it_IT');
update_option('siteurl', 'https://blog.marianialessandro.com/cms');
update_option('home', 'https://blog.marianialessandro.com/cms');
update_option('timezone_string', 'Europe/Rome');
update_option('blogdescription', '');
update_option('wp_page_for_privacy_policy', 0);

function sql_text(string $value): string
{
    return "'" . str_replace(['\\', "'"], ['\\\\', "''"], $value) . "'";
}

// Each statement becomes a no-op if the preflight rejects the selected database.
function guarded_sql(string $statement): string
{
    return "SET @blog_wp_statement = IF(@blog_wp_can_install, " . sql_text($statement) . ", 'DO 0');\nPREPARE blog_wp_step FROM @blog_wp_statement;\nEXECUTE blog_wp_step;\nDEALLOCATE PREPARE blog_wp_step;\n\n";
}

$sql = "-- INSTALLAZIONE WORDPRESS BLOG — phpMyAdmin\n-- WordPress {$wp_version}; database schema {$wp_db_version}; prefisso wp_blog_.\n-- Seleziona LO STESSO database MySQL dell’API Laravel e importa questo file intero.\n-- Prima esporta un backup da phpMyAdmin. Non importare nuovamente 000-initial-schema.sql.\n-- Nessuna password in chiaro e nessun dato personale sono contenuti in questo file.\n-- Le credenziali vengono copiate tramite SELECT da users; vengono importati SOLO is_admin = 1.\n-- Le tabelle Laravel users/posts e tutte le altre tabelle esistenti restano intatte.\n-- Gli articoli saranno convertiti dal successivo importatore WordPress, senza altro SQL manuale.\n-- Se esistono già tabelle wp_blog_, tutti i cambiamenti vengono saltati: non cancellare nulla.\n-- Al termine controlla la riga esito: deve essere PRONTO e account_copiati deve essere > 0.\n\nSET NAMES utf8mb4;\nSET @blog_wp_saved_sql_mode = @@SESSION.sql_mode;\nSET SESSION sql_mode = 'NO_ENGINE_SUBSTITUTION';\nSET @blog_wp_existing = (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND LEFT(TABLE_NAME, 8) = 'wp_blog_');\nSET @blog_wp_source_ok = (SELECT COUNT(*) = 2 FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN ('users', 'posts'));\nSET @blog_wp_admin_count = 0;\nSET @blog_wp_invalid_admin_count = 0;\n";
$preflight = "SELECT COUNT(*), COALESCE(SUM(CHAR_LENGTH(email) > 100 OR email = '' OR password IS NULL OR NOT (LEFT(password, 4) IN ('$2y$', '$2a$', '$2b$') OR password LIKE '$" . "argon2id$%' OR password LIKE '$" . "argon2i$%')), 0) INTO @blog_wp_admin_count, @blog_wp_invalid_admin_count FROM users WHERE is_admin = 1";
$sql .= 'SET @blog_wp_statement = IF(@blog_wp_source_ok, ' . sql_text($preflight) . ", 'DO 0');\nPREPARE blog_wp_step FROM @blog_wp_statement;\nEXECUTE blog_wp_step;\nDEALLOCATE PREPARE blog_wp_step;\nSET @blog_wp_can_install = DATABASE() IS NOT NULL AND @blog_wp_source_ok AND @blog_wp_existing = 0 AND @blog_wp_admin_count > 0 AND @blog_wp_invalid_admin_count = 0;\nSELECT DATABASE() AS database_selezionato, @blog_wp_existing AS tabelle_wordpress_preesistenti, @blog_wp_admin_count AS amministratori_legacy, @blog_wp_invalid_admin_count AS account_non_compatibili, IF(@blog_wp_can_install, 'PROCEDO', 'NON ESEGUITO: database errato, WordPress gia presente, nessun amministratore o account non compatibili') AS controllo_preliminare;\n\n";

// SHOW CREATE TABLE exports the schema really installed by this core, including indexes and collation.
foreach ($wpdb->tables('all') as $table) {
    $definition = $wpdb->get_row("SHOW CREATE TABLE `{$table}`", ARRAY_N);
    $create = preg_replace('/ AUTO_INCREMENT=\d+/', '', $definition[1]);
    $sql .= '-- Tabella ' . $table . ".\n" . guarded_sql($create);
}
$sql .= "START TRANSACTION;\n\n";
$excluded = ['admin_email', 'new_admin_email', 'cron', 'rewrite_rules', 'recently_edited', 'auto_updater.lock', 'core_updater.lock'];
foreach ($wpdb->get_results("SELECT option_name, option_value, autoload FROM {$wpdb->options} ORDER BY option_id") as $option) {
    if (in_array($option->option_name, $excluded, true) || str_starts_with($option->option_name, '_transient_') || str_starts_with($option->option_name, '_site_transient_') || str_starts_with($option->option_name, 'portfolio_')) {
        continue;
    }
    $sql .= '-- Opzione ' . $option->option_name . ".\n" . guarded_sql('INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (' . sql_text($option->option_name) . ', ' . sql_text($option->option_value) . ', ' . sql_text($option->autoload) . ')');
}
$sql .= guarded_sql("INSERT INTO wp_blog_terms (term_id, name, slug, term_group) VALUES (1, 'Senza categoria', 'senza-categoria', 0)");
$sql .= guarded_sql("INSERT INTO wp_blog_term_taxonomy (term_taxonomy_id, term_id, taxonomy, description, parent, count) VALUES (1, 1, 'category', '', 0, 0)");
$sql .= guarded_sql("INSERT INTO wp_blog_options (option_name, option_value, autoload) SELECT 'admin_email', email, 'on' FROM users WHERE is_admin = 1 ORDER BY id LIMIT 1");
$sql .= guarded_sql("INSERT INTO wp_blog_users (ID, user_login, user_pass, user_nicename, user_email, user_url, user_registered, user_activation_key, user_status, display_name) SELECT id, CONCAT('legacy-', id), password, CONCAT('legacy-', id), email, '', UTC_TIMESTAMP(), '', 0, LEFT(name, 250) FROM users WHERE is_admin = 1 ORDER BY id");
$sql .= guarded_sql("INSERT INTO wp_blog_usermeta (user_id, meta_key, meta_value) SELECT ID, 'wp_blog_capabilities', 'a:1:{s:13:\"administrator\";b:1;}' FROM wp_blog_users");
$sql .= guarded_sql("INSERT INTO wp_blog_usermeta (user_id, meta_key, meta_value) SELECT ID, 'wp_blog_user_level', '10' FROM wp_blog_users");
$sql .= guarded_sql("INSERT INTO wp_blog_usermeta (user_id, meta_key, meta_value) SELECT ID, '_portfolio_legacy_user_id', CAST(ID AS CHAR) FROM wp_blog_users");
$sql .= guarded_sql("INSERT INTO wp_blog_usermeta (user_id, meta_key, meta_value) SELECT ID, 'nickname', display_name FROM wp_blog_users");
$sql .= "COMMIT;\nSET SESSION sql_mode = @blog_wp_saved_sql_mode;\n\n";
$summary = "SELECT 'PRONTO' AS esito, (SELECT COUNT(*) FROM wp_blog_users) AS account_copiati, (SELECT COUNT(*) FROM wp_blog_posts) AS articoli_wordpress, 'Tabelle Laravel conservate. Ora avvisa per proseguire con configurazione CMS e importazione articoli.' AS prossimo_passo";
$sql .= 'SET @blog_wp_statement = IF(@blog_wp_can_install, ' . sql_text($summary) . ", 'SELECT ''NON ESEGUITO'' AS esito, ''Controlla il risultato del controllo preliminare. Nessuna tabella esistente e stata modificata.'' AS prossimo_passo');\nPREPARE blog_wp_step FROM @blog_wp_statement;\nEXECUTE blog_wp_step;\nDEALLOCATE PREPARE blog_wp_step;\n";
if (file_put_contents($options['output'], $sql, LOCK_EX) === false) {
    throw new RuntimeException('Cannot write SQL export.');
}
echo "Generated WordPress {$wp_version} phpMyAdmin bootstrap.\n";
