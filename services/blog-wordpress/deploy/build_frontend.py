#!/usr/bin/env python3
"""Build the dynamic PHP blog using the current Svelte design, without fetching content."""

import argparse
import hashlib
from pathlib import Path
import shutil
import subprocess


def build(output: Path) -> None:
    service = Path(__file__).resolve().parent.parent
    repository = service.parent.parent
    if output.exists():
        raise ValueError('The output directory must not already exist')
    shutil.copytree(service / 'frontend', output)
    shutil.copyfile(service / 'deploy/blog.htaccess', output / '.htaccess')
    assets = output / 'blog-assets'
    assets.mkdir(exist_ok=True)
    subprocess.run(['node', str(service / 'deploy/build_styles.mjs'), '--output=' + str((assets / 'blog.css').resolve())], cwd=repository, check=True)
    shutil.copyfile(repository / 'apps/blog.marianialessandro.com/static/favicon.png', assets / 'favicon.png')
    shutil.copyfile(repository / 'node_modules/@fontsource/fira-mono/files/fira-mono-latin-400-normal.woff2', assets / 'fira-mono-latin-400-normal.woff2')
    version = hashlib.sha256((assets / 'blog.css').read_bytes()).hexdigest()[:16]
    (assets / 'version.php').write_text("<?php return '" + version + "';\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True, help='New public frontend artifact directory')
    arguments = parser.parse_args()
    build(arguments.output)


if __name__ == '__main__':
    main()
