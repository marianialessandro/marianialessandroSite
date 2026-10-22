#!/usr/bin/env python3
"""Prepare a reproducible WordPress artifact without configuration or uploads."""

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import tempfile
import urllib.request
import zipfile


def build(output: Path, archive: Path | None = None) -> None:
    source = Path(__file__).resolve().parent.parent
    release = json.loads((source / 'deploy/wordpress-release.json').read_text())
    if output.exists():
        raise ValueError('The artifact directory must not already exist')
    if not (source / 'vendor/autoload.php').is_file():
        raise ValueError('Run composer install --working-dir services/blog-wordpress first')
    with tempfile.TemporaryDirectory(prefix='portfolio-wordpress-') as temporary:
        if archive is None:
            archive = Path(temporary) / 'wordpress.zip'
            urllib.request.urlretrieve(f'https://downloads.wordpress.org/release/wordpress-{release["version"]}.zip', archive)
        if hashlib.sha256(archive.read_bytes()).hexdigest() != release['sha256']:
            raise ValueError('WordPress archive SHA-256 does not match the pinned release')
        extracted = Path(temporary) / 'extracted'
        with zipfile.ZipFile(archive) as bundle:
            for member in bundle.infolist():
                if not (extracted / member.filename).resolve().is_relative_to(extracted.resolve()):
                    raise ValueError('Unsafe archive path')
            bundle.extractall(extracted)
        shutil.copytree(extracted / 'wordpress', output)
    (output / 'wp-config-sample.php').unlink(missing_ok=True)
    (output / 'readme.html').unlink(missing_ok=True)
    (output / 'license.txt').unlink(missing_ok=True)
    shutil.copytree(source / 'mu-plugins', output / 'wp-content/mu-plugins', dirs_exist_ok=True)
    shutil.copytree(source / 'vendor', output / 'wp-content/mu-plugins/blog-integration/vendor')
    shutil.copyfile(source / 'deploy/wp-config.php', output / 'wp-config.php')
    shutil.copyfile(source / 'deploy/cms.htaccess', output / '.htaccess')
    (output / 'wp-content/uploads').mkdir(exist_ok=True)
    shutil.copyfile(source / 'deploy/uploads.htaccess', output / 'wp-content/uploads/.htaccess')


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path, help='New artifact directory; refuses to overwrite an existing path')
    parser.add_argument('--archive', type=Path, help='Optional cached WordPress ZIP; SHA-256 is always verified')
    arguments = parser.parse_args()
    build(arguments.output, arguments.archive)


if __name__ == '__main__':
    main()
