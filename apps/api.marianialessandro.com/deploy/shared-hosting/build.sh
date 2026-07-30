#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 2 ]]; then
    echo "Usage: build.sh <laravel-source-dir> <new-artifact-dir>" >&2
    exit 64
fi

source_dir="${1%/}"
artifact_dir="${2%/}"
template_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "$source_dir/bootstrap/app.php" || ! -d "$source_dir/vendor" ]]; then
    echo "Laravel source or production dependencies are missing: $source_dir" >&2
    exit 66
fi

if [[ -e "$artifact_dir" ]]; then
    echo "Artifact directory must not already exist: $artifact_dir" >&2
    exit 73
fi

mkdir -p "$artifact_dir"

private_directories=(
    app
    bootstrap
    config
    database
    resources
    routes
    storage
    vendor
)

for directory in "${private_directories[@]}"; do
    cp -R "$source_dir/$directory" "$artifact_dir/$directory"
    cp "$template_dir/deny-all.htaccess" "$artifact_dir/$directory/.htaccess"
done

# The hosting provider fixes the subdomain document root. Flatten Laravel's
# public directory into that root, then install the shared-hosting front
# controller and hardened Apache rules.
cp -R "$source_dir/public/." "$artifact_dir/"
cp "$template_dir/index.php" "$artifact_dir/index.php"
cp "$template_dir/root.htaccess" "$artifact_dir/.htaccess"

# FTP ignores runtime contents so that deployments never delete uploads,
# sessions, caches, compiled views, or logs. These markers ensure their
# writable parent directories exist on the first installation.
touch "$artifact_dir/storage/.deploy-keep"
touch "$artifact_dir/storage/app/.deploy-keep"
touch "$artifact_dir/storage/framework/.deploy-keep"

test -f "$artifact_dir/index.php"
test -f "$artifact_dir/.htaccess"
test -f "$artifact_dir/vendor/autoload.php"
test ! -d "$artifact_dir/public"
