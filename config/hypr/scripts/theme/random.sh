#!/bin/bash
set -euo pipefail

THEMES_DIR="${HOME}/.config/hypr/themes"

random_theme() {
    local themes=()
    mapfile -t themes < <(ls "$THEMES_DIR"/*.conf 2>/dev/null | xargs -n1 basename | sed 's/\.conf$//')
    
    [[ ${#themes[@]} -eq 0 ]] && { echo "No themes found"; return 1; }
    
    echo "${themes[RANDOM % ${#themes[@]}]}"
}

apply_random() {
    local theme=$(random_theme)
    ~/.config/hypr/scripts/theme/theme-switcher.sh apply "$theme"
}

main() {
    case "${1:-}" in
        get) random_theme ;;
        apply) apply_random ;;
        *) echo "Usage: random.sh [get|apply]"; exit 1 ;;
    esac
}

main "$@"