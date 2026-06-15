#!/bin/bash
set -euo pipefail

REPO_DIR="${HOME}/.config/hypr"

cd "$REPO_DIR" || exit 1

echo "Generating changelog..."

git log --pretty=format:"## %s (%h)%n%n%b%n" --since="30 days ago" > CHANGELOG.md

echo "Changelog generated: CHANGELOG.md"
cat CHANGELOG.md