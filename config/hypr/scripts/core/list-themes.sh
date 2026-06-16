#!/bin/bash
set -euo pipefail

THEMES_DIR="${HOME}/.config/hypr/themes"

echo "Available Hyprland Themes:"
echo "========================="

for theme in "$THEMES_DIR"/*.conf; do
    [[ -f "$theme" ]] || continue
    name=$(basename "$theme" .conf)
    
    # Extract accent color
    accent=$(grep '^\$accent' "$theme" | head -1 | sed 's/.*= //')
    
    printf "  %-20s %s\n" "$name" "$accent"
done

echo ""
echo "Current: $(cat ~/.config/hypr/.current_theme 2>/dev/null || echo 'none')"