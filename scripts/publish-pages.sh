#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
remote="${1:-$(git -C "$repo_root" remote get-url origin)}"
publish_root="$(mktemp -d)"
artifact_dir="$publish_root/artifact"
checkout_dir="$publish_root/checkout"
trap 'rm -rf "$publish_root"' EXIT

bash "$repo_root/scripts/build-pages.sh" "$artifact_dir"

if git ls-remote --exit-code --heads "$remote" gh-pages >/dev/null 2>&1; then
  git clone --quiet --depth 1 --branch gh-pages "$remote" "$checkout_dir"
  git -C "$checkout_dir" rm -r --quiet --ignore-unmatch .
else
  mkdir -p "$checkout_dir"
  git -C "$checkout_dir" init --quiet -b gh-pages
  git -C "$checkout_dir" remote add origin "$remote"
fi

cp -R "$artifact_dir/." "$checkout_dir/"

git -C "$checkout_dir" config user.name "$(git -C "$repo_root" config user.name || echo 'GitHub Pages Publisher')"
git -C "$checkout_dir" config user.email "$(git -C "$repo_root" config user.email || echo 'pages@users.noreply.github.com')"
git -C "$checkout_dir" add -A

if git -C "$checkout_dir" diff --cached --quiet; then
  echo "Pages branch already matches the current viewer"
  exit 0
fi

git -C "$checkout_dir" commit --quiet -m "Deploy viewer $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
git -C "$checkout_dir" push origin gh-pages

echo "Published viewer to gh-pages"
