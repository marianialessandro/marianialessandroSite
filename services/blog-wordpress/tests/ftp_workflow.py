#!/usr/bin/env python3
"""Exercise the actual FTP deploy action against an isolated local FTP server."""

import ast
import hashlib
import logging
import os
from pathlib import Path
import subprocess
import tempfile
import threading
import urllib.request

import yaml
from pyftpdlib.authorizers import DummyAuthorizer
from pyftpdlib.handlers import FTPHandler
from pyftpdlib.servers import FTPServer


def main() -> None:
    logging.disable(logging.CRITICAL)
    document = yaml.safe_load(Path('.github/workflows/deploy-blog.yml').read_text())
    condition = ast.parse(document['jobs']['deploy']['if'].replace('&&', ' and ').replace('||', ' or '), mode='eval')

    def enabled(node, context):
        if isinstance(node, ast.Expression):
            return enabled(node.body, context)
        if isinstance(node, ast.Name) and node.id in ('true', 'false'):
            return node.id == 'true'
        if isinstance(node, ast.Constant):
            return node.value
        if isinstance(node, ast.Attribute) and isinstance(node.value, ast.Name):
            return context[node.value.id + '.' + node.attr]
        if isinstance(node, ast.BoolOp):
            values = [enabled(value, context) for value in node.values]
            return all(values) if isinstance(node.op, ast.And) else any(values)
        if isinstance(node, ast.Compare) and len(node.ops) == 1:
            left, right = enabled(node.left, context), enabled(node.comparators[0], context)
            if isinstance(node.ops[0], ast.Eq):
                return left == right
            if isinstance(node.ops[0], ast.NotEq):
                return left != right
        raise ValueError('Unsupported workflow condition')

    for event, provider, after_api, expected in [('push', '', False, True), ('push', 'wordpress', False, True), ('push', 'laravel', False, False), ('push', 'laravel', True, True), ('schedule', 'wordpress', False, False), ('schedule', 'laravel', False, True), ('workflow_dispatch', 'wordpress', False, True), ('workflow_dispatch', 'laravel', False, True)]:
        assert enabled(condition, {'github.event_name': event, 'vars.BLOG_CMS_PROVIDER': provider, 'inputs.after_api': after_api, 'inputs.diagnose_ftp': False}) == expected
    api = yaml.safe_load(Path('.github/workflows/deploy-api.yml').read_text())
    assert api['jobs']['deploy-blog']['with']['after_api'] is True
    print('PASS push, reusable API call, schedule and manual trigger conditions', flush=True)
    steps = document['jobs']['deploy']['steps']
    root_settings = next(step['with'] for step in steps if step.get('name') == '📂 Sync files via FTP')
    cms_settings = next(step['with'] for step in steps if step.get('name') == 'Sync WordPress runtime via FTP')
    standalone = yaml.safe_load(Path('.github/workflows/deploy-wordpress.yml').read_text())
    standalone_settings = next(step['with'] for step in standalone['jobs']['deploy']['steps'] if 'FTP-Deploy-Action' in step.get('uses', ''))
    assert cms_settings['exclude'] == standalone_settings['exclude']
    assert cms_settings['state-name'] == standalone_settings['state-name']
    with tempfile.TemporaryDirectory(prefix='wordpress-ftp-test-') as temporary:
        temporary = Path(temporary)
        action = temporary / 'ftp-action.js'
        urllib.request.urlretrieve('https://raw.githubusercontent.com/SamKirkland/FTP-Deploy-Action/v4.3.6/dist/index.js', action)
        assert hashlib.sha256(action.read_bytes()).hexdigest() == 'dcacab0087a5b1f4c82bc0fbf3440f4639eed945c1b4deb5c219cb202bc1742a'
        remote = temporary / 'remote'
        remote.mkdir()
        authorizer = DummyAuthorizer()
        authorizer.add_user('fixture', 'fixture-password', str(remote), perm='elradfmwMT')
        handler = type('FixtureFTPHandler', (FTPHandler,), {'authorizer': authorizer})
        server = FTPServer(('127.0.0.1', 0), handler)
        stopped = threading.Event()

        def serve():
            while not stopped.is_set():
                server.ioloop.loop(timeout=0.1, blocking=False)

        worker = threading.Thread(target=serve, daemon=True)
        worker.start()

        def write(directory: Path, files: dict) -> None:
            for name, contents in files.items():
                target = directory / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(contents)

        def deploy(source: Path, destination: str, settings: dict) -> None:
            values = dict(settings) | {'server': '127.0.0.1', 'port': server.socket.getsockname()[1], 'username': 'fixture', 'password': 'fixture-password', 'local-dir': str(source) + '/', 'server-dir': destination, 'log-level': 'minimal'}
            environment = os.environ | {'GITHUB_WORKSPACE': str(Path.cwd())}
            environment.update({'INPUT_' + key.upper(): str(value).lower() if isinstance(value, bool) else str(value) for key, value in values.items()})
            result = subprocess.run(['node', str(action)], env=environment, text=True, capture_output=True, timeout=45)
            if result.returncode:
                raise RuntimeError('FTP deploy action failed: ' + result.stdout[-1500:] + result.stderr[-500:])

        try:
            write(remote, {'blog/cms/blog-config.php': 'PRIVATE CONFIGURATION'})
            old = temporary / 'legacy'
            write(old, {'index.html': 'OLD HOME', 'old-post/index.html': 'OLD POST'})
            deploy(old, 'blog/', root_settings)
            cms = temporary / 'cms'
            write(cms, {'wp-config.php': 'CONFIGURATION LOADER', 'wp-content/mu-plugins/integration.php': 'PLUGIN v1', 'wp-content/uploads/.htaccess': 'UPLOAD EXECUTION GUARD'})
            deploy(cms, 'blog/cms/', cms_settings)
            assert (remote / 'blog/cms/wp-content/uploads/.htaccess').read_text() == 'UPLOAD EXECUTION GUARD'
            print('PASS first CMS deploy creates uploads and installs its execution guard', flush=True)
            write(remote, {'blog/cms/wp-content/uploads/2026/image.jpg': 'USER UPLOAD'})
            frontend = temporary / 'frontend'
            write(frontend, {'index.php': 'DYNAMIC HOME', '.htaccess': 'DYNAMIC ROUTING', 'blog-assets/blog.css': 'DESIGN'})
            deploy(frontend, 'blog/', root_settings)
            assert not (remote / 'blog/index.html').exists() and not (remote / 'blog/old-post/index.html').exists()
            assert (remote / 'blog/index.php').read_text() == 'DYNAMIC HOME'
            assert (remote / 'blog/cms/wp-config.php').read_text() == 'CONFIGURATION LOADER'
            print('PASS frontend cutover removes obsolete managed HTML and preserves the CMS', flush=True)
            write(cms, {'wp-content/mu-plugins/integration.php': 'PLUGIN v2'})
            deploy(cms, 'blog/cms/', standalone_settings)
            assert (remote / 'blog/cms/wp-content/mu-plugins/integration.php').read_text() == 'PLUGIN v2'
            assert (remote / 'blog/cms/blog-config.php').read_text() == 'PRIVATE CONFIGURATION'
            assert (remote / 'blog/cms/wp-content/uploads/2026/image.jpg').read_text() == 'USER UPLOAD'
            assert (remote / 'blog/.ftp-deploy-sync-state.json').is_file()
            assert (remote / 'blog/cms/.ftp-deploy-sync-state-wordpress.json').is_file()
            print('PASS repeated CMS deploy preserves configuration, media and independent FTP states', flush=True)
        finally:
            stopped.set()
            worker.join(timeout=5)
            server.close_all()
    print('Real FTP workflow suite passed. No production server was contacted.')


if __name__ == '__main__':
    main()
