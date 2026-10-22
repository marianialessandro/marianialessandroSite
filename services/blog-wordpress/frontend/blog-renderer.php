<?php

defined('ABSPATH') || exit;

function portfolio_url(string $path = ''): string
{
    return rtrim(BLOG_FRONTEND_URL, '/') . '/' . ltrim($path, '/');
}

function portfolio_icon(string $name): void
{
    $paths = [
        'arrow' => '<path d="M5 12h14m-5-5 5 5-5 5"/>',
        'calendar' => '<rect x="4" y="5" width="16" height="16" rx="2"/><path d="M8 3v4m8-4v4M4 11h16"/>',
        'book' => '<path d="M12 5v15M3 4h5a4 4 0 0 1 4 2 4 4 0 0 1 4-2h5v15h-5a4 4 0 0 0-4 2 4 4 0 0 0-4-2H3Z"/>',
        'tag' => '<path d="m3 3 8 0 10 10-8 8L3 11Z"/><circle cx="7" cy="7" r="1"/>',
    ];
    echo '<svg aria-hidden="true" width="1em" height="1em" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">' . ($paths[$name] ?? '') . '</svg>';
}

function portfolio_description(WP_Post $post): string
{
    return (string) (get_post_meta($post->ID, 'blog_description', true) ?: wp_strip_all_tags(get_the_excerpt($post)));
}

function portfolio_meta(WP_Post $post, bool $compact = false): void
{
    echo '<div class="portfolio-meta"><div class="post-meta' . ($compact ? ' compact' : '') . '"><span class="meta-item">';
    portfolio_icon('calendar');
    echo '<time datetime="' . esc_attr(get_post_time('c', false, $post)) . '">' . esc_html(get_post_time('M j, Y', false, $post)) . '</time></span><span class="meta-item">';
    portfolio_icon('book');
    echo '<span>Post</span></span></div></div>';
}

function portfolio_tags(WP_Post $post, bool $compact = false): void
{
    $tags = get_the_tags($post->ID);
    if (!$tags) {
        return;
    }
    echo '<div class="portfolio-tags"><div class="tag-list' . ($compact ? ' compact' : '') . '" aria-label="Post tags">';
    foreach ($tags as $tag) {
        echo '<span class="tag">';
        portfolio_icon('tag');
        echo esc_html($tag->name) . '</span>';
    }
    echo '</div></div>';
}

function portfolio_card(WP_Post $post): void
{
    echo '<div class="portfolio-card"><a class="post-card" href="' . esc_url(get_permalink($post)) . '"><div class="content">';
    portfolio_meta($post, true);
    echo '<h2>' . esc_html(get_the_title($post)) . '</h2><p>' . esc_html(portfolio_description($post)) . '</p></div><div class="footer">';
    portfolio_tags($post, true);
    echo '<span class="read-more">Read ';
    portfolio_icon('arrow');
    echo '</span></div></a></div>';
}

function portfolio_home(array $posts): void
{
    $featured = array_values(array_filter($posts, static fn ($post) => is_sticky($post->ID)));
    usort($featured, static function ($left, $right) {
        $a = (int) get_post_meta($left->ID, 'blog_featured_rank', true) ?: PHP_INT_MAX;
        $b = (int) get_post_meta($right->ID, 'blog_featured_rank', true) ?: PHP_INT_MAX;
        return ($a <=> $b) ?: strcmp($right->post_date, $left->post_date);
    });
    $selected = $featured ?: $posts;
    $hero = $selected[0] ?? null;
    $supporting = array_slice($selected, 1, 2);
    $promoted = array_map(static fn ($post) => $post->ID, array_slice($selected, 0, 3));
    $latest = array_slice(array_values(array_filter($posts, static fn ($post) => !in_array($post->ID, $promoted, true))), 0, 6);
    ?>
    <div class="portfolio-home">
        <div class="portfolio-hero"><section class="hero" aria-labelledby="blog-title">
            <div class="copy"><p class="eyebrow">Notes and articles</p><h1 id="blog-title">Notes from<br>the workbench.</h1><p class="lede">Technical notes, experiments, and reflections on systems, networking, programming, and sustainability.</p></div>
            <div class="summary" aria-label="Blog information"><p class="count"><?php echo count($posts); ?></p><p class="label"><?php echo count($posts) === 1 ? 'published post' : 'published posts'; ?></p><a href="<?php echo esc_url(portfolio_url('archive/')); ?>">Archive <?php portfolio_icon('arrow'); ?></a></div>
        </section></div>
        <section class="page" aria-label="Articles">
        <?php if (!$hero) : ?>
            <div class="empty-state"><h2>No posts yet</h2><p>Check back soon for new notes.</p></div>
        <?php else : ?>
            <section class="section spotlight" aria-labelledby="featured-title"><header class="section-heading"><p>Featured</p><h2 id="featured-title">Start here</h2></header>
                <div class="spotlight-grid<?php echo $supporting ? '' : ' single'; ?>"><a class="lead-post" href="<?php echo esc_url(get_permalink($hero)); ?>">
                    <?php $cover = get_the_post_thumbnail_url($hero, 'large') ?: get_post_meta($hero->ID, 'blog_cover', true); ?>
                    <?php if ($cover) : ?><img class="lead-cover" src="<?php echo esc_url($cover); ?>" alt="" loading="eager">
                    <?php else : ?><div class="lead-visual" aria-hidden="true"><span>Notes</span><strong><?php echo esc_html((get_the_tags($hero->ID)[0]->name ?? 'Article')); ?></strong></div><?php endif; ?>
                    <div class="lead-copy"><?php portfolio_meta($hero); ?><h2><?php echo esc_html(get_the_title($hero)); ?></h2><p><?php echo esc_html(portfolio_description($hero)); ?></p><div class="lead-footer"><?php portfolio_tags($hero); ?><span class="read-more">Read article <?php portfolio_icon('arrow'); ?></span></div></div>
                </a>
                <?php if ($supporting) : ?><div class="supporting-posts" aria-label="More selected posts"><?php foreach ($supporting as $post) { portfolio_card($post); } ?></div><?php endif; ?>
                </div>
            </section>
            <?php if ($latest) : ?><section class="section latest" aria-labelledby="latest-title"><header class="section-heading row"><div><p>Recent</p><h2 id="latest-title">Latest notes</h2></div><a class="archive-link" href="<?php echo esc_url(portfolio_url('archive/')); ?>">All posts <?php portfolio_icon('arrow'); ?></a></header><div class="latest-grid">
                <?php foreach ($latest as $post) : ?><a class="latest-card" href="<?php echo esc_url(get_permalink($post)); ?>"><div class="latest-copy"><?php portfolio_meta($post, true); ?><h3><?php echo esc_html(get_the_title($post)); ?></h3><p><?php echo esc_html(portfolio_description($post)); ?></p></div><?php portfolio_tags($post, true); ?></a><?php endforeach; ?>
            </div></section><?php endif; ?>
        <?php endif; ?>
        </section>
    </div>
    <?php
}

function portfolio_filter_value(string $key): string
{
    return isset($_GET[$key]) && is_string($_GET[$key]) ? sanitize_text_field(wp_unslash($_GET[$key])) : '';
}

function portfolio_archive(array $posts): void
{
    $year = portfolio_filter_value('year');
    $tag = mb_strtolower(trim(portfolio_filter_value('tag')));
    $years = [];
    $tags = [];
    $groups = [];
    $matched = 0;
    foreach ($posts as $post) {
        $post_year = substr($post->post_date, 0, 4);
        $years[$post_year] = $post_year;
        $post_tags = [];
        foreach (get_the_tags($post->ID) ?: [] as $term) {
            $key = mb_strtolower(trim($term->name));
            $tags[$key] = $term->name;
            $post_tags[] = $key;
        }
        if ((!$year || $year === $post_year) && (!$tag || in_array($tag, $post_tags, true))) {
            $groups[$post_year][] = $post;
            $matched++;
        }
    }
    krsort($years);
    ksort($tags);
    ?>
    <div class="portfolio-archive"><section class="page" aria-labelledby="archive-title"><header class="archive-header"><p>Archive</p><h1 id="archive-title">All posts</h1><span><?php echo ($year || $tag) ? $matched . ' of ' : ''; ?><?php echo count($posts); ?> <?php echo count($posts) === 1 ? 'article' : 'articles'; ?></span></header>
        <?php if ($posts) : ?><form class="filter-bar" aria-label="Archive filters" method="get" action="<?php echo esc_url(portfolio_url('archive/')); ?>">
            <label><span>Year</span><select name="year"><option value="">All years</option><?php foreach ($years as $value) : ?><option value="<?php echo esc_attr($value); ?>" <?php selected($year, $value); ?>><?php echo esc_html($value); ?></option><?php endforeach; ?></select></label>
            <label><span>Tag</span><select name="tag"><option value="">All tags</option><?php foreach ($tags as $value => $label) : ?><option value="<?php echo esc_attr($value); ?>" <?php selected($tag, $value); ?>><?php echo esc_html($label); ?></option><?php endforeach; ?></select></label>
            <button type="submit">Apply filters</button><?php if ($year || $tag) : ?><a href="<?php echo esc_url(portfolio_url('archive/')); ?>">Clear filters</a><?php endif; ?>
        </form><?php endif; ?>
        <?php if (!$groups) : ?><div class="empty-state"><h2><?php echo $posts ? 'No matching posts' : 'No posts yet'; ?></h2><p><?php echo $posts ? 'Try clearing filters or choosing a different tag or year.' : 'Check back soon for new notes.'; ?></p></div>
        <?php else : ?><div class="year-groups"><?php foreach ($groups as $group_year => $group) : ?><section class="year-group" aria-labelledby="year-<?php echo esc_attr($group_year); ?>"><h2 id="year-<?php echo esc_attr($group_year); ?>"><?php echo esc_html($group_year); ?></h2><div class="post-list">
            <?php foreach ($group as $post) : ?><a class="post-row" href="<?php echo esc_url(get_permalink($post)); ?>"><div class="post-main"><?php portfolio_meta($post, true); ?><h3><?php echo esc_html(get_the_title($post)); ?></h3><p><?php echo esc_html(portfolio_description($post)); ?></p></div><?php portfolio_tags($post, true); ?></a><?php endforeach; ?>
        </div></section><?php endforeach; ?></div><?php endif; ?>
    </section></div>
    <?php
}

function portfolio_article(WP_Post $post): void
{
    $GLOBALS['post'] = $post;
    setup_postdata($post);
    $html = wp_kses_post(apply_filters('the_content', $post->post_content));
    $document = new DOMDocument();
    $document->loadHTML('<?xml encoding="utf-8"?><div id="portfolio-content">' . $html . '</div>', LIBXML_NONET | LIBXML_NOERROR | LIBXML_NOWARNING);
    $content = $document->getElementById('portfolio-content');
    $headings = [];
    $used_ids = [];
    foreach ($document->getElementsByTagName('*') as $node) {
        if ($node->hasAttribute('id')) {
            $used_ids[$node->getAttribute('id')] = true;
        }
    }
    foreach ((new DOMXPath($document))->query('//*[@id="portfolio-content"]//*[self::h1 or self::h2 or self::h3 or self::h4]') as $heading) {
        $id = $heading->getAttribute('id');
        if (!$id) {
            $base = sanitize_title($heading->textContent) ?: 'section';
            $id = $base;
            $suffix = 2;
            while (isset($used_ids[$id])) {
                $id = $base . '-' . $suffix++;
            }
            $heading->setAttribute('id', $id);
            $used_ids[$id] = true;
        }
        $headings[] = ['id' => $id, 'text' => $heading->textContent, 'level' => substr($heading->tagName, 1)];
    }
    ?>
    <div class="portfolio-post-layout"><div class="post-layout<?php echo $headings ? '' : ' no-toc'; ?>">
        <?php if ($headings) : ?><aside class="toc-wrap" aria-label="Side table of contents"><div class="portfolio-toc"><nav class="toc" aria-label="Post table of contents"><h2 class="toc-title">On this page</h2><ul class="toc-list"><?php foreach ($headings as $heading) : ?><li class="item lvl-<?php echo esc_attr($heading['level']); ?>"><a class="link" href="#<?php echo esc_attr($heading['id']); ?>"><?php echo esc_html($heading['text']); ?></a></li><?php endforeach; ?></ul></nav></div></aside><?php endif; ?>
        <article class="post-shell" aria-label="Post"><div class="portfolio-article-header"><header class="article-header"><h1><?php echo esc_html(get_the_title($post)); ?></h1><p><?php echo esc_html(portfolio_description($post)); ?></p><div class="meta-row"><?php portfolio_meta($post); portfolio_tags($post); ?></div></header></div><div class="post"><?php foreach ($content->childNodes as $child) { echo $document->saveHTML($child); } ?></div></article>
    </div></div>
    <?php
    wp_reset_postdata();
}

function portfolio_render_blog(): void
{
    $path = trim(rawurldecode(parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/'), '/');
    $posts = [];
    $post = null;
    if ($path === '' || $path === 'archive') {
        $posts = get_posts(['post_type' => 'post', 'post_status' => 'publish', 'has_password' => false, 'numberposts' => -1, 'orderby' => 'date', 'order' => 'DESC']);
    } elseif (!str_contains($path, '/')) {
        $candidate = get_page_by_path($path, OBJECT, 'post');
        if ($candidate && $candidate->post_status === 'publish' && !$candidate->post_password && $candidate->post_date_gmt <= gmdate('Y-m-d H:i:s')) {
            $post = $candidate;
        }
    }
    $found = $path === '' || $path === 'archive' || $post;
    status_header($found ? 200 : 404);
    nocache_headers();
    header('Content-Type: text/html; charset=utf-8');
    $title = $post ? get_the_title($post) : ($path === 'archive' ? 'Archive - marianialessandro.com' : ($found ? 'marianialessandro.com - Alessandro Mariani' : 'Post not found'));
    $description = $post ? portfolio_description($post) : 'Articles and notes from Alessandro Mariani';
    $version = require __DIR__ . '/blog-assets/version.php';
    ?>
    <!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title><?php echo esc_html($title); ?></title><meta name="description" content="<?php echo esc_attr($description); ?>"><meta name="color-scheme" content="light"><meta name="theme-color" content="#fafafa">
    <?php if ($found) : ?><link rel="canonical" href="<?php echo esc_url($post ? get_permalink($post) : portfolio_url($path ? $path . '/' : '')); ?>"><?php else : ?><meta name="robots" content="noindex"><?php endif; ?>
    <meta property="og:title" content="<?php echo esc_attr($title); ?>"><meta property="og:description" content="<?php echo esc_attr($description); ?>"><meta property="og:type" content="<?php echo $post ? 'article' : 'website'; ?>">
    <link rel="icon" href="/blog-assets/favicon.png"><link rel="stylesheet" href="<?php echo esc_url(includes_url('css/dist/block-library/style.min.css')); ?>"><link rel="stylesheet" href="/blog-assets/blog.css?v=<?php echo esc_attr($version); ?>"></head><body class="portfolio-site" data-blog-renderer="wordpress-php"><a class="skip" href="#main">Skip to content</a><div class="app">
    <div class="portfolio-header"><header class="blog-header"><div class="inner"><a class="brand" href="<?php echo esc_url(portfolio_url()); ?>" aria-label="Alessandro Mariani — blog home"><span class="brand-mark" aria-hidden="true">am.</span><span class="brand-name">Alessandro Mariani</span></a><nav aria-label="Blog navigation"><a <?php echo $path === '' ? 'class="active" aria-current="page"' : ''; ?> href="<?php echo esc_url(portfolio_url()); ?>">Blog</a><a <?php echo $path === 'archive' ? 'class="active" aria-current="page"' : ''; ?> href="<?php echo esc_url(portfolio_url('archive/')); ?>">Archive</a><a href="https://marianialessandro.com">Portfolio <span aria-hidden="true">↗</span></a></nav></div></header></div>
    <main id="main" tabindex="-1"><?php if ($post) { portfolio_article($post); } elseif ($path === '') { portfolio_home($posts); } elseif ($path === 'archive') { portfolio_archive($posts); } else { echo '<div class="portfolio-archive"><section class="page"><h1>Post not found</h1><p>The article is unavailable.</p><a href="' . esc_url(portfolio_url('archive/')) . '">Browse the archive</a></section></div>'; } ?></main>
    <footer class="blog-footer">© <?php echo gmdate('Y'); ?> Alessandro Mariani</footer></div><script src="/blog-assets/site.js" defer></script></body></html>
    <?php
}
