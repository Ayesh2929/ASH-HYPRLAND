#!/bin/bash
set -euo pipefail

REPO_DIR="${HOME}/.config/hypr"

cd "$REPO_DIR" || exit 1

git log --oneline -20