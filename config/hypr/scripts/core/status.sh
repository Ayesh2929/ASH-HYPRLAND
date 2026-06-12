#!/bin/bash
set -euo pipefail

REPO_DIR="${HOME}/.config/hypr"

cd "$REPO_DIR" || exit 1

echo "Git Status:"
git status --short

echo ""
echo "Branch: $(git branch --show-current)"
echo "Remote: $(git remote get-url origin 2>/dev/null || echo 'none')"
echo "Last commit: $(git log -1 --format='%h %s (%cr)')"