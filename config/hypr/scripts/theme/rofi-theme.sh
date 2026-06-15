#!/bin/bash
set -euo pipefail

apply_rofi_theme() {
    local theme="${1:-ash}"
    local theme_file="${HOME}/.config/rofi/${theme}.rasi"
    
    [[ -f "$theme_file" ]] || { echo "Theme not found: $theme"; return 1; }
    
    sed -i "s/@theme \".*\"/@theme \"$theme\"/" ~/.config/rofi/config.rasi
    echo "Applied Rofi theme: $theme"
}

list_themes() {
    ls ~/.config/rofi/*.rasi 2>/dev/null | xargs -n1 basename | sed 's/\.rasi$//'
}

main() {
    case "${1:-}" in
        apply) apply_rofi_theme "${2:-ash}" ;;
        list) list_themes ;;
        *) echo "Usage: rofi-theme.sh [apply|list]"; exit 1 ;;
    esac
}

main "$@"