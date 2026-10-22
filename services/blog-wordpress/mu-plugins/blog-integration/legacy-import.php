<?php

defined('ABSPATH') || exit;

/** Import one bounded batch; source tables and already imported records stay untouched. */
function portfolio_import_legacy_batch(): array
{
    global $wpdb;
    if (!current_user_can('manage_options')) {
        throw new RuntimeException('Accesso negato.');
    }
    if (!defined('BLOG_ALLOW_LEGACY_IMPORT') || !BLOG_ALLOW_LEGACY_IMPORT) {
        throw new RuntimeException('Importazione disabilitata nella configurazione del CMS.');
    }
    $prefix = defined('BLOG_LEGACY_TABLE_PREFIX') ? BLOG_LEGACY_TABLE_PREFIX : '';
    if (!preg_match('/^[a-zA-Z0-9_]*$/D', $prefix) || $prefix === $wpdb->prefix) {
        throw new RuntimeException('Prefisso delle tabelle legacy non valido.');
    }
    $state = get_option('portfolio_legacy_import', ['users' => 0, 'posts' => 0, 'users_done' => false, 'done' => false]);
    if ($state['done']) {
        return $state;
    }
    require_once __DIR__ . '/vendor/autoload.php';
    $converter = new League\CommonMark\GithubFlavoredMarkdownConverter(['html_input' => 'allow', 'allow_unsafe_links' => false, 'footnote' => ['ref_id_prefix' => 'fnref-', 'footnote_id_prefix' => 'fn-']]);
    $converter->getEnvironment()->addExtension(new League\CommonMark\Extension\Footnote\FootnoteExtension());
    $table = $state['users_done'] ? 'posts' : 'users';
    $filter = $table === 'users' ? ' AND is_admin = 1' : '';
    $rows = $wpdb->get_results($wpdb->prepare("SELECT * FROM `{$prefix}{$table}` WHERE id > %d{$filter} ORDER BY id LIMIT 20", $state[$table]));
    if ($wpdb->last_error) {
        throw new RuntimeException('Lettura delle tabelle legacy fallita. Verifica che il CMS usi lo stesso database dell’API e il prefisso corretto.');
    }
    foreach ($rows as $row) {
        if ($table === 'users') {
            portfolio_import_legacy_user($row);
        } else {
            portfolio_import_legacy_post($row, $converter);
        }
        $state[$table] = (int) $row->id;
        update_option('portfolio_legacy_import', $state, false);
    }
    if (count($rows) < 20) {
        $state[$table === 'users' ? 'users_done' : 'done'] = true;
        update_option('portfolio_legacy_import', $state, false);
    }
    return $state;
}

function portfolio_import_legacy_user(object $row): void
{
    global $wpdb;
    $mapped = get_users(['meta_key' => '_portfolio_legacy_user_id', 'meta_value' => (int) $row->id, 'number' => 1]);
    if ($mapped) {
        return;
    }
    if (email_exists($row->email)) {
        throw new RuntimeException('Esiste già un utente WordPress con la stessa email di un account legacy. Usa un’email diversa per l’amministratore temporaneo di installazione.');
    }
    if (!preg_match('/^\$2[aby]\$|^\$argon2(id|i)\$/', $row->password)) {
        throw new RuntimeException('Hash password legacy non compatibile per l’utente ' . (int) $row->id . '. Nessuna credenziale è stata modificata.');
    }
    $login = 'legacy-' . (int) $row->id;
    if (username_exists($login)) {
        throw new RuntimeException('Nome utente riservato all’importazione già occupato: ' . $login);
    }
    $id = wp_insert_user(['user_login' => $login, 'user_email' => $row->email, 'display_name' => $row->name, 'user_pass' => wp_generate_password(64), 'role' => 'administrator']);
    if (is_wp_error($id)) {
        throw new RuntimeException('Creazione utente legacy fallita: ' . $id->get_error_message());
    }
    // wp_insert_user hashes input, so copy the existing one-way hash directly afterwards.
    if ($wpdb->update($wpdb->users, ['user_pass' => $row->password], ['ID' => $id]) === false) {
        require_once ABSPATH . 'wp-admin/includes/user.php';
        wp_delete_user($id);
        throw new RuntimeException('Copia hash password fallita. Puoi riprovare l’importazione.');
    }
    clean_user_cache($id);
    update_user_meta($id, '_portfolio_legacy_user_id', (int) $row->id);
}

function portfolio_import_legacy_post(object $row, League\CommonMark\GithubFlavoredMarkdownConverter $converter): void
{
    $mapped = get_posts(['post_type' => 'post', 'post_status' => 'any', 'meta_key' => '_portfolio_legacy_post_id', 'meta_value' => (int) $row->id, 'numberposts' => 1]);
    if ($mapped) {
        return;
    }
    $collision = get_page_by_path($row->slug, OBJECT, 'post');
    if ($collision || in_array($row->slug, ['admin', 'archive', 'preview', 'cms'], true)) {
        throw new RuntimeException('Slug già occupato o riservato: ' . $row->slug . '. Risolvi il conflitto prima di riprovare.');
    }
    $date = substr($row->date, 0, 10) . ' 00:00:00';
    $status = $row->draft ? 'draft' : ($date > current_time('mysql') ? 'future' : 'publish');
    $tags = json_decode($row->tags, true, 512, JSON_THROW_ON_ERROR);
    $payload = [
        'post_type' => 'post',
        'post_author' => get_current_user_id(),
        'post_title' => $row->title,
        'post_name' => $row->slug,
        'post_status' => $status,
        'post_date' => $date,
        'post_date_gmt' => get_gmt_from_date($date),
        'post_excerpt' => $row->description ?? '',
        'post_content' => '<!-- wp:freeform -->' . wp_kses_post((string) $converter->convert($row->content)) . '<!-- /wp:freeform -->',
        'meta_input' => ['_portfolio_legacy_post_id' => (int) $row->id, '_portfolio_legacy_markdown' => $row->content, 'blog_description' => $row->description ?? '', 'blog_cover' => $row->cover ?? '', 'blog_featured_rank' => (int) ($row->featured_rank ?? 0)],
    ];
    $id = wp_insert_post(wp_slash($payload), true);
    if (is_wp_error($id)) {
        throw new RuntimeException('Importazione articolo fallita: ' . $id->get_error_message());
    }
    $result = wp_set_post_tags($id, $tags, false);
    if (is_wp_error($result)) {
        wp_delete_post($id, true);
        throw new RuntimeException('Importazione tag fallita. Puoi riprovare il lotto.');
    }
    if ($row->featured) {
        stick_post($id);
    }
}

add_action('admin_menu', function () {
    add_management_page('Importa blog Laravel', 'Importa blog Laravel', 'manage_options', 'portfolio-import', function () {
        if (!current_user_can('manage_options')) {
            wp_die('Accesso negato.', '', ['response' => 403]);
        }
        echo '<div class="wrap"><h1>Importa blog Laravel</h1><p>Importa gli amministratori con la loro password attuale e gli articoli a lotti di 20. I dati Laravel restano intatti. Gli account e gli articoli già importati non vengono sovrascritti.</p>';
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            check_admin_referer('portfolio_import');
            try {
                $state = portfolio_import_legacy_batch();
                echo '<div class="notice notice-success"><p>' . ($state['done'] ? 'Importazione completata. Verifica gli articoli e il login con email e password attuali, poi disabilita BLOG_ALLOW_LEGACY_IMPORT.' : 'Lotto completato. Continua con il prossimo lotto.') . '</p></div>';
            } catch (Throwable $error) {
                echo '<div class="notice notice-error"><p>' . esc_html($error->getMessage()) . '</p></div>';
            }
        }
        echo '<form method="post">';
        wp_nonce_field('portfolio_import');
        submit_button('Importa il prossimo lotto');
        echo '</form></div>';
    });
});
