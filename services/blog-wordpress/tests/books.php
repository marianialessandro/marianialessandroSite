<?php

// Included by integration.php after authenticating an administrator in the isolated database.
$book_id = wp_insert_post(['post_type' => 'portfolio_book', 'post_title' => 'Editor test book', 'post_status' => 'draft']);
$editor_id = get_current_user_id();
$original_post = $_POST;
try {
    $_POST = ['portfolio_book_nonce' => wp_create_nonce('portfolio_book_meta'), 'book_author' => 'Book author', 'book_url' => 'https://example.test/book', 'book_status' => 'reading', 'book_recommended' => '1', 'book_series' => 'A <b>series</b>', 'book_series_order' => '2'];
    wp_update_post(['ID' => $book_id, 'post_title' => 'Editor saves details']);
    verify(get_post_meta($book_id, 'book_author', true) === 'Book author' && get_post_meta($book_id, 'book_status', true) === 'reading' && (bool) get_post_meta($book_id, 'book_recommended', true), 'book editor saves details with a valid nonce');
    verify(get_post_meta($book_id, 'book_series', true) === 'A series' && (int) get_post_meta($book_id, 'book_series_order', true) === 2, 'book editor saves sanitized series and volume number');
    unset($_POST['book_recommended']);
    $_POST['book_status'] = 'read';
    wp_update_post(['ID' => $book_id, 'post_title' => 'Editor clears favourite']);
    verify(!(bool) get_post_meta($book_id, 'book_recommended', true) && get_post_meta($book_id, 'book_status', true) === 'read', 'book editor clears favourites and changes reading state');
    $_POST['book_series'] = '';
    $_POST['book_series_order'] = '';
    wp_update_post(['ID' => $book_id]);
    verify(get_post_meta($book_id, 'book_series', true) === '' && (int) get_post_meta($book_id, 'book_series_order', true) === 0, 'book editor can remove series membership and volume number');
    $_POST['portfolio_book_nonce'] = 'invalid';
    $_POST['book_author'] = 'Forged author';
    wp_update_post(['ID' => $book_id, 'post_title' => 'Invalid nonce test']);
    verify(get_post_meta($book_id, 'book_author', true) === 'Book author', 'invalid nonce cannot change book details');
    $_POST['portfolio_book_nonce'] = wp_create_nonce('portfolio_book_meta');
    wp_set_current_user(0);
    do_action('save_post_portfolio_book', $book_id);
    verify(get_post_meta($book_id, 'book_author', true) === 'Book author', 'anonymous users cannot save book details');
    $request = new WP_REST_Request('POST', '/wp/v2/portfolio_book');
    $request->set_param('title', 'Unauthorized book');
    verify(rest_do_request($request)->get_status() === 401, 'anonymous REST book creation is denied');
} finally {
    $_POST = $original_post;
    wp_set_current_user($editor_id);
    wp_delete_post($book_id, true);
}
