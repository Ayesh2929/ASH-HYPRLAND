#!/bin/bash
set -euo pipefail

WALLPAPER_DIR="${HOME}/Pictures/wallpapers"

set_wallpaper() {
    local wallpaper="$1"
    [[ -f "$wallpaper" ]] || { echo "File not found: $wallpaper"; return 1; }
    hyprctl hyprpaper preload "$wallpaper"
    hyprctl hyprpaper wallpaper ",$wallpaper"
    echo "$wallpaper" > ~/.cache/ash-dots/current_wallpaper
}

random_wallpaper() {
    local wallpapers=()
    mapfile -t wallpapers < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null)
    [[ ${#wallpapers[@]} -gt 0 ]] && set_wallpaper "${wallpapers[RANDOM % ${#wallpapers[@]}]}"
}

list_wallpapers() {
    find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null
}

main() {
    case "${1:-}" in
        set) set_wallpaper "${2:-}" ;;
        random) random_wallpaper ;;
        list) list_wallpapers ;;
        current) cat ~/.cache/ash-dots/current_wallpaper 2>/dev/null || echo "None" ;;
        *) echo "Usage: wallpaper.sh [set|random|list|current]"; exit 1 ;;
    esac
}

main "$@"