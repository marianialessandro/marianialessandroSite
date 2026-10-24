#!/usr/bin/env python3
"""Verify the actual PHP/Apache blog updates without a frontend rebuild."""

import argparse
import base64
import json
from pathlib import Path
import subprocess
import urllib.error
import urllib.parse
import urllib.request
import uuid


def wordpress(operation: str, parameters: dict) -> dict:
    bootstrap = "<?php define('WP_INSTALLING', true); define('DISABLE_WP_CRON', true); require '/var/www/html/cms/wp-load.php'; if (DB_NAME !== 'blog_wordpress_local') { throw new RuntimeException('Isolated test database required'); } $parameters = json_decode(base64_decode($argv[1]), true); "
    operations = {
        'create': "$admins = get_users(['role' => 'administrator', 'number' => 1]); wp_set_current_user($admins[0]->ID); $id = wp_insert_post(wp_slash($parameters), true); if (is_wp_error($id)) { throw new RuntimeException($id->get_error_message()); } wp_set_post_tags($id, ['Live testing']); echo json_encode(['id' => $id]);",
        'update': "$id = wp_update_post(wp_slash($parameters), true); if (is_wp_error($id)) { throw new RuntimeException($id->get_error_message()); } echo json_encode(['id' => $id]);",
        'delete': "wp_delete_post((int) $parameters['ID'], true); echo '{}';",
        'category': "$term = wp_insert_term($parameters['name'], 'book_category'); if (is_wp_error($term)) { throw new RuntimeException($term->get_error_message()); } echo json_encode(['id' => $term['term_id']]);",
        'delete_category': "wp_delete_term((int) $parameters['ID'], 'book_category'); echo '{}';",
    }
    arguments = ['docker', 'compose', '-f', 'services/blog-wordpress/compose.yml', 'exec', '-T', 'blog', 'php', '/dev/stdin', base64.b64encode(json.dumps(parameters).encode()).decode()]
    result = subprocess.run(arguments, input=bootstrap + operations[operation], text=True, capture_output=True, check=True)
    return json.loads(result.stdout)


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, file, code, message, headers, target):
        return None


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--url', default='http://localhost:8081', help='Local Apache frontend URL')
    arguments = parser.parse_args()
    opener = urllib.request.build_opener(NoRedirect)

    def request(path: str, expected: int = 200) -> str:
        try:
            response = opener.open(arguments.url + path, timeout=15)
        except urllib.error.HTTPError as error:
            response = error
        assert response.code == expected, f'{path}: expected {expected}, received {response.code}'
        body = response.read().decode()
        assert 'PHP Warning' not in body and 'Fatal error' not in body
        return body

    slug = 'dynamic-smoke-' + uuid.uuid4().hex[:12]
    health = json.loads(request('/cms/?rest_route=/portfolio/v1/health'))
    assert health == {'status': 'ok'}
    title = 'Live article ' + slug
    fixture = wordpress('create', {'post_title': title, 'post_name': slug, 'post_status': 'publish', 'post_type': 'post', 'post_content': '<h2>Live heading</h2><p>Body available without JavaScript.</p>'})
    stale = Path('services/blog-wordpress/public/build') / slug
    try:
        home = request('/')
        assert title in home
        archive = request('/archive/')
        assert title in archive
        article = request('/' + slug + '/')
        assert title in article and '<h2 id="live-heading">Live heading</h2>' in article
        assert '<link rel="canonical" href="' + arguments.url + '/' + slug + '/"' in article
        assert 'no-cache' in opener.open(arguments.url + '/' + slug + '/').headers.get('Cache-Control', '')
        print('PASS new post appears immediately in home, archive and server-rendered article HTML')
        filtered = request('/archive/?' + urllib.parse.urlencode({'tag': 'live testing'}))
        assert title in filtered
        assert title not in request('/archive/?year=1900')
        print('PASS archive tag/year filters operate on the server without JavaScript')
        wordpress('update', {'ID': fixture['id'], 'post_title': title + ' UPDATED'})
        assert title + ' UPDATED' in request('/' + slug + '/')
        print('PASS edits appear without rebuilding or redeploying')
        wordpress('update', {'ID': fixture['id'], 'post_status': 'draft'})
        stale.mkdir()
        (stale / 'index.html').write_text('STALE PUBLIC CONTENT')
        assert title not in request('/') and title not in request('/archive/')
        assert 'STALE PUBLIC CONTENT' not in request('/' + slug + '/', 404)
        print('PASS unpublishing hides the post and bypasses stale static HTML')
        wordpress('update', {'ID': fixture['id'], 'post_status': 'publish', 'post_password': 'fixture-password'})
        request('/' + slug + '/', 404)
        assert title not in request('/archive/')
        print('PASS password-protected articles remain private')
        request('/not-an-existing-article/', 404)
        request('/cms/wp-config.php', 403)
        request('/wp-config.php', 403)
        request('/admin/posts/123/', 302)
        print('PASS real 404, protected configuration and admin redirect')
    finally:
        wordpress('delete', {'ID': fixture['id']})
        if stale.exists():
            (stale / 'index.html').unlink()
            stale.rmdir()
    test_books(request)
    test_series(request)
    print('Dynamic blog suite passed. No build or GitHub call was needed between updates.')


def test_books(request) -> None:
    suffix = uuid.uuid4().hex[:12]
    title = 'Book fixture ' + suffix
    category = wordpress('category', {'name': 'Test books ' + suffix})
    fixture = None
    try:
        fixture = wordpress('create', {'post_title': title, 'post_status': 'publish', 'post_type': 'portfolio_book', 'post_content': '<p>A personal reading note.</p><script>alert(1)</script>', 'tax_input': {'book_category': [category['id']]}, 'meta_input': {'book_author': 'Author <b>name</b>', 'book_url': 'https://example.test/book', 'book_status': 'read', 'book_recommended': True}})
        page = request('/libri/')
        assert title in page and 'A personal reading note.' in page
        assert 'Author name' in page and 'https://example.test/book' in page
        assert 'One of my favourites' in page and 'Test books ' + suffix in page
        assert '<script>alert(1)</script>' not in page
        assert title not in request('/') and title not in request('/archive/')
        request('/' + title.lower().replace(' ', '-') + '/', 404)
        assert 'aria-current="page" href="' in page and '/libri/' in page
        print('PASS books render author, category, safe notes and favourites, separately from articles')
        wordpress('update', {'ID': fixture['id'], 'post_title': title + ' UPDATED', 'meta_input': {'book_status': 'reading', 'book_url': 'javascript:alert(1)', 'book_recommended': False}})
        page = request('/libri/')
        assert title + ' UPDATED' in page
        assert 'id="reading"' not in page and 'javascript:alert' not in page
        assert '<span class="reading-status is-reading">Currently reading</span>' in page
        assert 'id="category-' + str(category['id']) + '"' in page
        print('PASS book edits and reading status appear immediately; unsafe links are rejected')
        for update in [{'post_status': 'draft'}, {'post_status': 'future', 'post_date': '2099-01-10 12:00:00', 'post_date_gmt': '2099-01-10 12:00:00'}, {'post_status': 'publish', 'post_date': '2020-01-10 12:00:00', 'post_date_gmt': '2020-01-10 12:00:00', 'post_password': 'private'}]:
            wordpress('update', {'ID': fixture['id'], **update})
            assert title not in request('/libri/')
        print('PASS draft, scheduled and password-protected books stay private')
        wordpress('update', {'ID': fixture['id'], 'post_password': '', 'meta_input': {'book_status': 'read'}, 'tax_input': {'book_category': []}})
        # Taxonomy mutations require an authenticated editor, unlike this low-level update helper.
        wordpress('delete_category', {'ID': category['id']})
        page = request('/libri/')
        assert title in page and 'Other books' in page
        wordpress('delete', {'ID': fixture['id']})
        assert title not in request('/libri/')
        print('PASS uncategorized books have a fallback section and deletion takes effect immediately')
    finally:
        if fixture:
            wordpress('delete', {'ID': fixture['id']})
        wordpress('delete_category', {'ID': category['id']})


def test_series(request) -> None:
    name = 'Series fixture ' + uuid.uuid4().hex[:12]
    fixtures = []
    category = wordpress('category', {'name': 'Category ' + name})
    try:
        for number, status, visibility in [(2, 'reading', 'publish'), (1, 'read', 'publish'), (0, 'read', 'publish'), (3, 'read', 'draft')]:
            title = name + ' volume ' + str(number)
            fixtures.append(wordpress('create', {'post_type': 'portfolio_book', 'post_status': visibility, 'post_title': title, 'tax_input': {'book_category': [category['id']]}, 'meta_input': {'book_series': '  ' + name.upper() + '  ' if number == 1 else name, 'book_series_order': number, 'book_status': status}})['id'])
        page = request('/libri/')
        first, second, unnumbered, private = [name + ' volume ' + str(number) for number in [1, 2, 0, 3]]
        assert page.index(first) < page.index(second) < page.index(unnumbered)
        assert page.count(first) == 1 and page.count(second) == 1
        assert private not in page
        assert 'id="reading"' not in page
        assert 'id="category-' + str(category['id']) + '"' in page
        group_start = page.rfind('<li class="book-series">', 0, page.index(first))
        group_end = page.index('</ul></li>', page.index(first))
        group = page[group_start:group_end]
        assert second in group and unnumbered in group
        assert 'Book 1' in group and 'Book 2' in group and 'Book 0' not in group
        assert 'Currently reading' in group and '>Read</span>' in group
        print('PASS series group read and in-progress volumes together, sort numerically, tolerate name casing and hide private books')
    finally:
        for fixture_id in fixtures:
            wordpress('delete', {'ID': fixture_id})
        wordpress('delete_category', {'ID': category['id']})


if __name__ == '__main__':
    main()
