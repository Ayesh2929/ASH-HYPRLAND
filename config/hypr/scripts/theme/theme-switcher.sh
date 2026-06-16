#!/bin/bash
set -euo pipefail

THEMES_DIR="${HOME}/.config/hypr/themes"
CURRENT_THEME_FILE="${HOME}/.config/hypr/.current_theme"

list_themes() {
    ls -1 "${THEMES_DIR}"/*.conf 2>/dev/null | xargs -n1 basename | sed 's/\.conf$//'
}

apply_theme() {
    local theme="$1"
    local theme_file="${THEMES_DIR}/${theme}.conf"
    
    [[ -f "${theme_file}" ]] || { echo "Theme not found: ${theme}"; return 1; }
    
    hyprctl source "${theme_file}"
    echo "${theme}" > "${CURRENT_THEME_FILE}"
    
    ~/.config/hypr/scripts/theme/smart-wallpaper.sh apply
    echo "Applied theme: ${theme}"
}

get_current() {
    [[ -f "${CURRENT_THEME_FILE}" ]] && cat "${CURRENT_THEME_FILE}" || echo "default"
}

main() {
    case "${1:-}" in
        list) list_themes ;;
        apply) apply_theme "${2:-}" ;;
        current) get_current ;;
        *) echo "Usage: theme-switcher.sh [list|apply|current]"; exit 1 ;;
    esac
}

main "$@"