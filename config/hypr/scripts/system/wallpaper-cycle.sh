#!/bin/bash
set -euo pipefail

WALLPAPER_DIR="${HOME}/Pictures/wallpapers"
INTERVAL="${1:-300}"

cycle() {
    while true; do
        wallpapers=()
        mapfile -t wallpapers < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null)
        [[ ${#wallpapers[@]} -eq 0 ]] && { echo "No wallpapers found"; sleep 60; continue; }
        
        for wp in "${wallpapers[@]}"; do
            hyprctl hyprpaper preload "$wp"
            hyprctl hyprpaper wallpaper ",$wp"
            sleep "$INTERVAL"
        done
    done
}

case "${1:-}" in
    start) cycle & disown; echo "Wallpaper cycling started (interval: ${INTERVAL}s)" ;;
    *) echo "Usage: wallpaper-cycle.sh [start] [interval]"; exit 1 ;;
esac