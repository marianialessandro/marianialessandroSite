#!/usr/bin/env bash
set -euo pipefail
if [[ "$#" -ne 2 ]]; then
    echo 'Usage: build.sh <source-directory> <new-artifact-directory>'
    exit 64
fi
source_dir="${1%/}"
artifact_dir="${2%/}"
if [[ ! -f "$source_dir/vendor/autoload.php" || -e "$artifact_dir" ]]; then
    echo 'Installed dependencies and a new artifact directory are required.' >&2
    exit 65
fi
mkdir -p "$artifact_dir"
for directory in app bootstrap config database resources routes storage vendor; do
    cp -R "$source_dir/$directory" "$artifact_dir/$directory"
    cp "$source_dir/deploy/deny-all.htaccess" "$artifact_dir/$directory/.htaccess"
done
mkdir -p "$artifact_dir/storage/app/private" "$artifact_dir/storage/framework/cache/data" "$artifact_dir/storage/framework/sessions" "$artifact_dir/storage/framework/views" "$artifact_dir/storage/logs"
cp "$source_dir/deploy/index.php" "$artifact_dir/index.php"
cp "$source_dir/deploy/root.htaccess" "$artifact_dir/.htaccess"
# Signing keys and runtime configuration must never be distributed in the artifact.
rm -f "$artifact_dir/storage/oauth-private.key" "$artifact_dir/storage/oauth-public.key"
rm -f "$artifact_dir/bootstrap/cache/config.php" "$artifact_dir/bootstrap/cache/routes-v7.php"
