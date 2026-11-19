#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$repo_root"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "FAIL: this workspace is not a Git repository" >&2
  exit 1
fi

allowed_path='^(\.gitignore|README\.md|index\.html|\.github/|scripts/|viewer/|generated/)'
unexpected="$(git ls-files | grep -Ev "$allowed_path" || true)"
if [[ -n "$unexpected" ]]; then
  echo "FAIL: the public repository contains paths outside the allow-list:" >&2
  echo "$unexpected" >&2
  exit 1
fi

metadata_files="$(git ls-files | grep -E '(^|/)\.DS_Store$' || true)"
if [[ -n "$metadata_files" ]]; then
  echo "FAIL: operating-system metadata must not be public:" >&2
  echo "$metadata_files" >&2
  exit 1
fi

required_paths=(
  ".gitignore"
  "README.md"
  "index.html"
  "scripts/build-pages.sh"
  "scripts/publish-pages.sh"
  "scripts/verify-public-repo.sh"
  "viewer/index.html"
  "viewer/zoom.js"
)

for path in "${required_paths[@]}"; do
  if ! git ls-files --error-unmatch "$path" >/dev/null 2>&1; then
    echo "FAIL: required public path is not tracked: $path" >&2
    exit 1
  fi
done

workspace_files="$(mktemp)"
tracked_files="$(mktemp)"
trap 'rm -f "$workspace_files" "$tracked_files"' EXIT

find viewer generated -type f ! -name '.DS_Store' -print | LC_ALL=C sort >"$workspace_files"
git ls-files viewer generated | LC_ALL=C sort >"$tracked_files"

if ! diff -u "$workspace_files" "$tracked_files"; then
  echo "FAIL: every viewer/generated file must be tracked" >&2
  exit 1
fi

while IFS= read -r path; do
  size="$(wc -c <"$path" | tr -d ' ')"
  if (( size >= 100000000 )); then
    echo "FAIL: tracked file exceeds GitHub's 100 MB limit: $path" >&2
    exit 1
  fi
done < <(git ls-files)

pages_dir="$(mktemp -d)"
trap 'rm -f "$workspace_files" "$tracked_files"; rm -rf "$pages_dir"' EXIT

bash scripts/build-pages.sh "$pages_dir"

for path in index.html viewer/index.html viewer/zoom.js; do
  if [[ ! -f "$pages_dir/$path" ]]; then
    echo "FAIL: Pages artifact is missing: $path" >&2
    exit 1
  fi
done

if [[ ! -f "$pages_dir/.nojekyll" ]]; then
  echo "FAIL: branch-based Pages artifact is missing .nojekyll" >&2
  exit 1
fi

if git ls-files --error-unmatch ".github/workflows/pages.yml" >/dev/null 2>&1; then
  echo "FAIL: custom Pages workflow must not be tracked while Actions runners are billing-locked" >&2
  exit 1
fi

if [[ "$(find generated -type f ! -name '.DS_Store' | wc -l | tr -d ' ')" != "$(find "$pages_dir/generated" -type f | wc -l | tr -d ' ')" ]]; then
  echo "FAIL: Pages artifact does not contain every generated catalog image" >&2
  exit 1
fi

echo "PASS: public repository boundary is safe"
