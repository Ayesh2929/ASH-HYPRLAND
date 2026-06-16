#!/bin/bash
set -euo pipefail

REPO_DIR="${HOME}/.config/hypr"
VERSION="${1:-}"

[[ -z "$VERSION" ]] && { echo "Usage: release.sh <version>"; exit 1; }

cd "$REPO_DIR" || exit 1

# Update version
echo "$VERSION" > VERSION

# Generate changelog
./changelog.sh

# Commit and tag
git add VERSION CHANGELOG.md
git commit -m "Release $VERSION"
git tag "v$VERSION"

echo "Release $VERSION created. Push with: git push origin main --tags"