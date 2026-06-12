#!/bin/bash
set -euo pipefail

THEMES=("Bibata-Modern-Classic" "Bibita-Modern-Ice" "Capitaine-Cursors" "Nordzy-cursors")

apply_cursor_theme() {
    local theme="${1:-Bibata-Modern-Classic}"
    local size="${2:-24}"
    gsettings set org.gnome.desktop.interface cursor-theme "$theme"
    gsettings set org.gnome.desktop.interface cursor-size "$size"
    hyprctl setcursor "$theme" "$size"
    sed -i "s/gtk-cursor-theme-name=.*/gtk-cursor-theme-name=$theme/" ~/.config/gtk-3.0/settings.ini
    sed -i "s/gtk-cursor-theme-size=.*/gtk-cursor-theme-size=$size/" ~/.config/gtk-3.0/settings.ini
    echo "Applied cursor theme: $theme (size: $size)"
}

list_themes() {
    for t in "${THEMES[@]}"; do
        echo "$t"
    done
}

main() {
    case "${1:-}" in
        apply) apply_cursor_theme "${2:-}" "${3:-24}" ;;
        list) list_themes ;;
        *) echo "Usage: cursor-theme.sh [apply|list]"; exit 1 ;;
    esac
}

main "$@"