#!/usr/bin/env bash
# Exports the web build and publishes it to the gh-pages branch (served by GitHub Pages).
# The branch is replaced on every deploy, so old ~40 MB builds don't pile up in history.
# Usage: GODOT=/path/to/godot let-me-cook/tools/deploy_pages.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
GODOT="${GODOT:-godot}"
REMOTE="$(git remote get-url origin)"

rm -rf build/web && mkdir -p build/web
"$GODOT" --headless --path let-me-cook --export-release "Web" ../build/web/index.html
touch build/web/.nojekyll

publish="$(mktemp -d)"
cp -r build/web/. "$publish"
cd "$publish"
git init -q -b gh-pages
git add -A
git commit -q -m "Deploy web build from $(git -C "$OLDPWD" rev-parse --short HEAD)"
# Use the GitHub CLI's login for this push only, if it's installed (no global config changes).
auth=()
if command -v gh > /dev/null; then
	auth=(-c credential.helper= -c "credential.helper=!gh auth git-credential")
fi
git "${auth[@]}" push -q --force "$REMOTE" gh-pages
cd - > /dev/null
rm -rf "$publish"
echo "Published to gh-pages."
