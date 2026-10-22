<?php

// This suite is only for the disposable database prepared by the phpMyAdmin SQL test.
if (getenv('WORDPRESS_DB_NAME') !== 'blog_wordpress_sql_test') {
    throw new RuntimeException('Requires the isolated SQL test database.');
}
define('WP_INSTALLING', true);
define('DISABLE_WP_CRON', true);
require '/var/www/html/wp-load.php';

function sql_bootstrap_verify(bool $condition, string $message): void
{
    if (!$condition) {
        throw new RuntimeException($message);
    }
    echo "PASS {$message}\n";
}

global $wpdb, $wp_db_version;
sql_bootstrap_verify(is_blog_installed(), 'SQL bootstrap is recognized as an installed WordPress site');
sql_bootstrap_verify((int) get_option('db_version') === $wp_db_version, 'schema version matches the pinned WordPress core');
sql_bootstrap_verify(get_option('timezone_string') === 'Europe/Rome', 'production timezone is configured');
sql_bootstrap_verify((bool) term_exists(1, 'category'), 'default category is available');
$before = $wpdb->get_results('SELECT * FROM users ORDER BY id', ARRAY_A);
$before_posts = $wpdb->get_results('SELECT * FROM posts ORDER BY id', ARRAY_A);
$user = wp_authenticate('sql-admin@example.test', 'sql-fixture-password');
sql_bootstrap_verify(!is_wp_error($user), 'SQL-copied BCrypt hash accepts the original password');
sql_bootstrap_verify(in_array('administrator', $user->roles, true), 'SQL-copied account has the administrator role');
sql_bootstrap_verify((int) get_user_meta($user->ID, '_portfolio_legacy_user_id', true) === 41, 'SQL copy is recognized by the PHP importer');
sql_bootstrap_verify(!get_user_by('email', 'sql-reader@example.test'), 'SQL does not import non-admin accounts');
wp_set_current_user($user->ID);
for ($batch = 0; $batch < 10; $batch++) {
    $state = portfolio_import_legacy_batch();
    if ($state['done']) {
        break;
    }
}
sql_bootstrap_verify($state['done'], 'PHP importer completes after the manual SQL bootstrap');
$post = get_page_by_path('sql-fixture-post', OBJECT, 'post');
sql_bootstrap_verify($post && str_contains($post->post_content, '<strong>SQL migration</strong>'), 'legacy article converts correctly after SQL installation');
sql_bootstrap_verify((int) $wpdb->get_var("SELECT COUNT(*) FROM {$wpdb->users}") === 1, 'PHP import does not duplicate the SQL-copied account');
sql_bootstrap_verify($before === $wpdb->get_results('SELECT * FROM users ORDER BY id', ARRAY_A) && $before_posts === $wpdb->get_results('SELECT * FROM posts ORDER BY id', ARRAY_A), 'all legacy rows remain unchanged');
echo "SQL bootstrap suite passed.\n";
