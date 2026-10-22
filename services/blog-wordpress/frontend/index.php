<?php

define('WP_USE_THEMES', false);
if (!is_file(__DIR__ . '/cms/wp-load.php')) {
    http_response_code(503);
    header('Content-Type: text/plain; charset=utf-8');
    header('Cache-Control: no-store');
    exit('Il blog è in preparazione. Riprova tra poco.');
}
require __DIR__ . '/cms/wp-load.php';
require __DIR__ . '/blog-renderer.php';
portfolio_render_blog();
