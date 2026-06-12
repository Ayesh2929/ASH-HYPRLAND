#!/bin/bash
set -euo pipefail

SCRIPTS_DIR="${HOME}/.config/hypr/scripts"

echo "Available Scripts:"
echo "=================="

categories=("theme" "media" "system" "hypr" "health" "core")

for cat in "${categories[@]}"; do
    echo ""
    echo "$cat:"
    for script in "$SCRIPTS_DIR/$cat"/*.sh; do
        [[ -f "$script" ]] || continue
        name=$(basename "$script" .sh)
        desc=$(head -5 "$script" | grep -E '^#' | head -1 | sed 's/^# *//')
        printf "  %-30s %s\n" "$name" "${desc:-}"
    done
done