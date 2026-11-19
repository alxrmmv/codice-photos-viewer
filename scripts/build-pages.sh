#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
destination="${1:-$repo_root/_site}"

if [[ -e "$destination" ]] && [[ -n "$(find "$destination" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
  echo "FAIL: Pages destination must be empty: $destination" >&2
  exit 1
fi

mkdir -p "$destination"
cp "$repo_root/index.html" "$destination/index.html"
cp -R "$repo_root/viewer" "$destination/viewer"
cp -R "$repo_root/generated" "$destination/generated"

find "$destination" -name '.DS_Store' -delete
touch "$destination/.nojekyll"

echo "Built Pages artifact at $destination"
