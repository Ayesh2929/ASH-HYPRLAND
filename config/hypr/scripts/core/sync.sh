#!/bin/bash
set -euo pipefail

REPO_DIR="${HOME}/.config/hypr"

cd "$REPO_DIR" || exit 1

git add -A
git commit -m "Sync: $(date '+%Y-%m-%d %H:%M:%S')" 2>/dev/null || true
git push

echo "Synced to remote"