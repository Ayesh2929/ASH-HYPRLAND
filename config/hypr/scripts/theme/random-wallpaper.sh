#!/bin/bash
set -euo pipefail

WALLPAPER_DIR="${HOME}/Pictures/wallpapers"

get_random() {
    local category="${1:-}"
    local search_dir="$WALLPAPER_DIR"
    
    [[ -n "$category" && -d "$WALLPAPER_DIR/$category" ]] && search_dir="$WALLPAPER_DIR/$category"
    
    local wallpapers=()
    mapfile -t wallpapers < <(find "$search_dir" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null)
    
    if [[ ${#wallpapers[@]} -gt 0 ]]; then
        echo "${wallpapers[RANDOM % ${#wallpapers[@]}]}"
    fi
}

set_wallpaper() {
    local wallpaper="$1"
    [[ -f "$wallpaper" ]] || { echo "File not found: $wallpaper"; return 1; }
    hyprctl hyprpaper preload "$wallpaper"
    hyprctl hyprpaper wallpaper ",$wallpaper"
    echo "$wallpaper" > ~/.cache/ash-dots/current_wallpaper
}

main() {
    case "${1:-}" in
        get) get_random "${2:-}" ;;
        set) set_wallpaper "$(get_random "${2:-}")" ;;
        *) echo "Usage: random-wallpaper.sh [get|set] [category]"; exit 1 ;;
    esac
}

main "$@"