<?php
/**
 * Plugin Name: Portfolio Blog Integration
 * Description: Public blog metadata and Laravel import for the dynamic PHP frontend.
 */

defined('ABSPATH') || exit;

require_once __DIR__ . '/blog-integration/legacy-import.php';

add_action('rest_api_init', function () {
    $definition = [
        'methods' => 'GET',
        'permission_callback' => '__return_true',
        'callback' => function () {
            global $wp_db_version;
            $ready = PHP_VERSION_ID >= 80300 && class_exists('DOMDocument') && extension_loaded('mbstring') && (int) get_option('db_version') === $wp_db_version && (bool) get_role('administrator');
            return new WP_REST_Response(['status' => $ready ? 'ok' : 'not_ready'], $ready ? 200 : 503);
        },
    ];
    register_rest_route('portfolio/v1', '/health', $definition);
});

add_action('init', function () {
    foreach (['blog_description' => 'string', 'blog_cover' => 'string', 'blog_featured_rank' => 'integer'] as $key => $type) {
        $definition = [
            'type' => $type,
            'single' => true,
            'show_in_rest' => true,
            'sanitize_callback' => $type === 'integer' ? 'absint' : ($key === 'blog_cover' ? 'esc_url_raw' : 'sanitize_text_field'),
            'auth_callback' => function ($allowed, $meta_key, $post_id) { return current_user_can('edit_post', $post_id); },
        ];
        register_post_meta('post', $key, $definition);
    }
});

add_action('add_meta_boxes', function () {
    add_meta_box('portfolio-blog', 'Portfolio blog', function ($post) {
        wp_nonce_field('portfolio_blog_meta', 'portfolio_blog_nonce');
        foreach (['blog_description' => 'Descrizione breve', 'blog_cover' => 'URL copertina (alternativa all’immagine in evidenza)', 'blog_featured_rank' => 'Ordine in evidenza (1 = primo, 0 = automatico)'] as $key => $label) {
            echo '<p><label>' . esc_html($label) . '<br><input class="widefat" name="' . esc_attr($key) . '" value="' . esc_attr(get_post_meta($post->ID, $key, true)) . '" type="' . ($key === 'blog_featured_rank' ? 'number' : 'text') . '"></label></p>';
        }
        echo '<p>Per mettere un articolo in evidenza usa l’opzione WordPress “Fissa in cima al blog”.</p>';
    }, 'post', 'side');
});

add_action('save_post_post', function ($post_id) {
    if (wp_is_post_revision($post_id) || !current_user_can('edit_post', $post_id) || !isset($_POST['portfolio_blog_nonce']) || !wp_verify_nonce(sanitize_text_field(wp_unslash($_POST['portfolio_blog_nonce'])), 'portfolio_blog_meta')) {
        return;
    }
    foreach (['blog_description', 'blog_cover', 'blog_featured_rank'] as $key) {
        if (isset($_POST[$key])) {
            update_post_meta($post_id, $key, wp_unslash($_POST[$key]));
        }
    }
}, 10);

add_filter('post_link', function ($url, $post) {
    if (defined('BLOG_FRONTEND_URL') && $post->post_status === 'publish') {
        return rtrim(BLOG_FRONTEND_URL, '/') . '/' . $post->post_name . '/';
    }
    return $url;
}, 10, 2);

add_action('template_redirect', function () {
    if (defined('BLOG_FRONTEND_URL') && !is_preview()) {
        $target = is_singular('post') ? get_permalink() : rtrim(BLOG_FRONTEND_URL, '/') . '/';
        wp_redirect($target, 302);
        exit;
    }
}, 1);

// Retire queued rebuilds from the previous static integration without contacting GitHub.
add_action('init', function () {
    if (wp_next_scheduled('portfolio_deploy_blog')) {
        wp_clear_scheduled_hook('portfolio_deploy_blog');
    }
    delete_option('portfolio_deploy_error');
});
