#!/bin/bash
set -euo pipefail

THEMES_DIR="${HOME}/.config/hypr/themes"
PREVIEW_DIR="${HOME}/.cache/ash-dots/theme-previews"

mkdir -p "$PREVIEW_DIR"

generate_preview() {
    local theme="$1"
    local theme_file="${THEMES_DIR}/${theme}.conf"
    
    [[ -f "$theme_file" ]] || { echo "Theme not found: $theme"; return 1; }
    
    # Extract colors
    local bg=$(grep '^\$bg' "$theme_file" | head -1 | sed 's/.*= //')
    local fg=$(grep '^\$fg' "$theme_file" | head -1 | sed 's/.*= //')
    local accent=$(grep '^\$accent' "$theme_file" | head -1 | sed 's/.*= //')
    local surface=$(grep '^\$surface' "$theme_file" | head -1 | sed 's/.*= //')
    
    # Create preview image using imagemagick if available
    if command -v convert &>/dev/null; then
        convert -size 400x200 xc:"$bg" \
            -fill "$accent" -draw "rectangle 0,0 400,4" \
            -fill "$surface" -draw "rectangle 10,50 390,150" \
            -fill "$fg" -pointsize 24 -annotate +20,100 "$theme" \
            "$PREVIEW_DIR/${theme}.png"
        echo "Generated preview: $PREVIEW_DIR/${theme}.png"
    else
        echo "ImageMagick not installed, skipping image generation"
        echo "Theme: $theme"
        echo "  BG: $bg"
        echo "  FG: $fg"
        echo "  Accent: $accent"
        echo "  Surface: $surface"
    fi
}

main() {
    case "${1:-}" in
        generate) generate_preview "${2:-}" ;;
        all)
            for theme in "$THEMES_DIR"/*.conf; do
                [[ -f "$theme" ]] || continue
                name=$(basename "$theme" .conf)
                generate_preview "$name"
            done
            ;;
        list) ls "$PREVIEW_DIR"/*.png 2>/dev/null || echo "No previews generated" ;;
        *) echo "Usage: preview.sh [generate|all|list]"; exit 1 ;;
    esac
}

main "$@"