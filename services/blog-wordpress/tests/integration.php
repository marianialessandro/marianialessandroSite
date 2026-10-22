<?php

// Run exclusively in the isolated compose database; never against a real installation.
define('WP_INSTALLING', true);
require '/var/www/html/wp-load.php';
require_once ABSPATH . 'wp-admin/includes/upgrade.php';
if (DB_NAME !== 'blog_wordpress_local') {
    throw new RuntimeException('Integration tests require the isolated blog_wordpress_local database.');
}

function verify(bool $condition, string $message): void
{
    if (!$condition) {
        throw new RuntimeException($message);
    }
    echo "PASS {$message}\n";
}

if (!is_blog_installed()) {
    wp_install('Local WordPress integration test', 'setup-admin', 'setup@example.test', true, '', 'local-setup-password-only');
}
$setup = get_user_by('login', 'setup-admin');
wp_set_current_user($setup->ID);
global $wpdb;
$wpdb->query('CREATE TABLE IF NOT EXISTS users (id BIGINT PRIMARY KEY, name VARCHAR(255), email VARCHAR(255), password VARCHAR(255), is_admin TINYINT NOT NULL)');
$wpdb->query('CREATE TABLE IF NOT EXISTS posts (id BIGINT PRIMARY KEY, slug VARCHAR(255), title VARCHAR(255), description VARCHAR(255), content LONGTEXT, date DATE, tags JSON, draft TINYINT, cover VARCHAR(255), featured TINYINT, featured_rank INT)');
$hash = password_hash('legacy-password-only-for-test', PASSWORD_BCRYPT);
$wpdb->query($wpdb->prepare('INSERT IGNORE INTO users VALUES (41, %s, %s, %s, 1), (42, %s, %s, %s, 0)', 'Legacy admin', 'legacy@example.test', $hash, 'Regular user', 'reader@example.test', $hash));
foreach ([71 => ['legacy-published', '2026-01-10', 0], 72 => ['legacy-draft', '2026-01-10', 1], 73 => ['legacy-future', '2099-01-10', 0]] as $id => [$slug, $date, $draft]) {
    $wpdb->query($wpdb->prepare('INSERT IGNORE INTO posts VALUES (%d, %s, %s, %s, %s, %s, %s, %d, %s, 1, 2)', $id, $slug, 'Legacy & WordPress', 'Test summary', "## Heading\n\n**Bold** and a footnote[^1].\n\n[^1]: A note.\n\n<details><summary>More</summary>Safe HTML</details>", $date, '["WordPress","Testing"]', $draft, 'https://example.test/cover.jpg'));
}
$source_hash = $wpdb->get_var('SELECT password FROM users WHERE id = 41');
$before = $wpdb->get_var('SELECT content FROM posts WHERE id = 71');
delete_option('portfolio_legacy_import');
for ($batch = 0; $batch < 10; $batch++) {
    $state = portfolio_import_legacy_batch();
    if ($state['done']) {
        break;
    }
}
verify($state['done'], 'bounded legacy import completes');
$user = get_user_by('email', 'legacy@example.test');
verify((bool) $user && in_array('administrator', $user->roles, true), 'legacy administrator role is preserved');
verify(!get_user_by('email', 'reader@example.test'), 'non-admin accounts are not elevated or imported');
$login = wp_authenticate('legacy@example.test', 'legacy-password-only-for-test');
verify(!is_wp_error($login), 'real WordPress authentication accepts the existing Laravel BCrypt password');
verify(is_wp_error(wp_authenticate('legacy@example.test', 'wrong-password')), 'wrong password is rejected');
$post = get_page_by_path('legacy-published', OBJECT, 'post');
verify($post && $post->post_status === 'publish', 'published article keeps its slug and status');
verify(str_contains($post->post_content, '<strong>Bold</strong>') && str_contains($post->post_content, '<details>') && str_contains($post->post_content, 'footnote'), 'Markdown, safe HTML and footnotes migrate to editable HTML');
verify(str_contains($post->post_content, 'href="#fn-1"') && str_contains($post->post_content, 'id="fn-1"'), 'footnote anchors survive WordPress URL sanitization');
verify(get_page_by_path('legacy-draft', OBJECT, 'post')->post_status === 'draft', 'draft stays private');
verify(get_page_by_path('legacy-future', OBJECT, 'post')->post_status === 'future', 'future article stays scheduled');
verify(is_sticky($post->ID) && (int) get_post_meta($post->ID, 'blog_featured_rank', true) === 2, 'featured status and ordering survive');
verify(wp_get_post_tags($post->ID, ['fields' => 'names']) === ['Testing', 'WordPress'], 'article tags survive');
verify(get_post_meta($post->ID, 'blog_cover', true) === 'https://example.test/cover.jpg', 'legacy cover URL survives');
verify($wpdb->get_var('SELECT password FROM users WHERE id = 41') === $source_hash && $wpdb->get_var('SELECT content FROM posts WHERE id = 71') === $before, 'legacy tables are unchanged');
wp_update_post(['ID' => $post->ID, 'post_title' => 'Edited in WordPress']);
delete_option('portfolio_legacy_import');
do {
    $state = portfolio_import_legacy_batch();
} while (!$state['done']);
verify(get_post($post->ID)->post_title === 'Edited in WordPress', 're-import preserves edits and does not duplicate articles');
verify(count(get_posts(['post_status' => 'any', 'meta_key' => '_portfolio_legacy_post_id', 'numberposts' => -1])) === 3, 're-import is idempotent');
wp_set_current_user(0);
$response = rest_do_request(new WP_REST_Request('GET', '/wp/v2/posts'));
$published = array_column($response->get_data(), 'id');
verify(in_array($post->ID, $published, true) && !in_array(get_page_by_path('legacy-draft', OBJECT, 'post')->ID, $published, true), 'anonymous REST API exposes published posts only');
try {
    portfolio_import_legacy_batch();
    throw new RuntimeException('Anonymous import unexpectedly succeeded');
} catch (RuntimeException $error) {
    verify($error->getMessage() === 'Accesso negato.', 'anonymous import is denied');
}
verify(!wp_next_scheduled('portfolio_deploy_blog'), 'publishing does not queue a GitHub rebuild');
verify(!has_action('portfolio_deploy_blog'), 'no GitHub dispatch handler is registered');
echo "Integration suite passed.\n";
