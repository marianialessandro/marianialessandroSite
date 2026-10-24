<?php

defined('ABSPATH') || exit;

add_action('init', function () {
    register_post_type('portfolio_book', [
        'labels' => ['name' => 'Books', 'singular_name' => 'Book', 'add_new_item' => 'Add book', 'edit_item' => 'Edit book', 'menu_name' => 'Books'],
        'public' => false,
        'show_ui' => true,
        'show_in_rest' => true,
        'menu_icon' => 'dashicons-book',
        'supports' => ['title', 'editor', 'revisions', 'custom-fields'],
        'capability_type' => 'post',
        'map_meta_cap' => true,
    ]);
    register_taxonomy('book_category', 'portfolio_book', [
        'labels' => ['name' => 'Book categories', 'singular_name' => 'Book category'],
        'public' => false,
        'show_ui' => true,
        'show_in_rest' => true,
        'hierarchical' => true,
        'show_admin_column' => true,
    ]);
    foreach (['book_author', 'book_url', 'book_status', 'book_recommended', 'book_series', 'book_series_order'] as $key) {
        register_post_meta('portfolio_book', $key, [
            'type' => match ($key) { 'book_recommended' => 'boolean', 'book_series_order' => 'integer', default => 'string' },
            'single' => true,
            'show_in_rest' => true,
            'sanitize_callback' => match ($key) {
                'book_url' => static fn ($value) => esc_url_raw($value, ['http', 'https']),
                'book_status' => static fn ($value) => $value === 'reading' ? 'reading' : 'read',
                'book_recommended' => 'rest_sanitize_boolean',
                'book_series_order' => 'absint',
                default => 'sanitize_text_field',
            },
            'auth_callback' => static fn ($allowed, $meta_key, $post_id) => current_user_can('edit_post', $post_id),
        ]);
    }
});

add_action('add_meta_boxes_portfolio_book', function () {
    add_meta_box('portfolio-book-details', 'Reading details', function ($post) {
        wp_nonce_field('portfolio_book_meta', 'portfolio_book_nonce');
        foreach (['book_author' => 'Author', 'book_url' => 'Book link (optional)', 'book_series' => 'Series (optional)'] as $key => $label) {
            echo '<p><label>' . esc_html($label) . '<br><input class="widefat" type="' . ($key === 'book_url' ? 'url' : 'text') . '" name="' . esc_attr($key) . '" value="' . esc_attr(get_post_meta($post->ID, $key, true)) . '"></label></p>';
        }
        echo '<p><label>Book number in series (optional)<br><input class="widefat" type="number" min="1" step="1" name="book_series_order" value="' . esc_attr(get_post_meta($post->ID, 'book_series_order', true) ?: '') . '"></label></p>';
        echo '<p>Use the same series name for related books. Volumes appear together in reading order, each with its own reading status. Books without a number appear last.</p>';
        echo '<p><label>Status<br><select name="book_status"><option value="read">Read</option><option value="reading" ' . selected(get_post_meta($post->ID, 'book_status', true), 'reading', false) . '>Currently reading</option></select></label></p>';
        echo '<p><label><input type="checkbox" name="book_recommended" value="1" ' . checked((bool) get_post_meta($post->ID, 'book_recommended', true), true, false) . '> One of my favourites</label></p>';
        echo '<p>Enter the book title and use the editor for a short note. Choose a category and publish: the book will appear immediately on the <a href="' . esc_url(rtrim(BLOG_FRONTEND_URL, '/') . '/libri/') . '">Books page</a>. Drafts remain private.</p>';
    }, 'portfolio_book', 'side');
});

add_action('save_post_portfolio_book', function ($post_id) {
    if (wp_is_post_revision($post_id) || wp_is_post_autosave($post_id) || !current_user_can('edit_post', $post_id) || !isset($_POST['portfolio_book_nonce']) || !wp_verify_nonce(sanitize_text_field(wp_unslash($_POST['portfolio_book_nonce'])), 'portfolio_book_meta')) {
        return;
    }
    foreach (['book_author', 'book_url', 'book_status', 'book_series', 'book_series_order'] as $key) {
        if (isset($_POST[$key]) && is_string($_POST[$key])) {
            update_post_meta($post_id, $key, wp_unslash($_POST[$key]));
        }
    }
    update_post_meta($post_id, 'book_recommended', isset($_POST['book_recommended']));
});

function portfolio_book_groups(array $books): array
{
    $groups = [];
    foreach ($books as $book) {
        $terms = get_the_terms($book->ID, 'book_category');
        if (!$terms || is_wp_error($terms)) {
            $groups['other']['label'] = 'Other books';
            $groups['other']['books'][] = $book;
        } else {
            foreach ($terms as $term) {
                $key = 'category-' . $term->term_id;
                $groups[$key]['label'] = $term->name;
                $groups[$key]['books'][] = $book;
            }
        }
    }
    uasort($groups, static fn ($a, $b) => strnatcasecmp($a['label'], $b['label']));
    foreach ($groups as &$group) {
        $group['entries'] = [];
        foreach ($group['books'] as $book) {
            $series = trim((string) get_post_meta($book->ID, 'book_series', true));
            $key = $series !== '' ? 'series-' . md5(mb_strtolower($series)) : 'book-' . $book->ID;
            $group['entries'][$key]['label'] = $series;
            $group['entries'][$key]['books'][] = $book;
        }
        foreach ($group['entries'] as &$entry) {
            if ($entry['label'] === '') {
                continue;
            }
            usort($entry['books'], static function ($a, $b) {
                $left = (int) get_post_meta($a->ID, 'book_series_order', true) ?: PHP_INT_MAX;
                $right = (int) get_post_meta($b->ID, 'book_series_order', true) ?: PHP_INT_MAX;
                return ($left <=> $right) ?: strnatcasecmp($a->post_title, $b->post_title) ?: ($a->ID <=> $b->ID);
            });
        }
        unset($entry);
    }
    unset($group);
    return $groups;
}
