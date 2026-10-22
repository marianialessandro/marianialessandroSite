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
    print('Dynamic blog suite passed. No build or GitHub call was needed between updates.')


if __name__ == '__main__':
    main()
