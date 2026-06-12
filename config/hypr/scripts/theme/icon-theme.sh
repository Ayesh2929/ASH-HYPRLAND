#!/bin/bash
set -euo pipefail

THEMES=("Papirus-Dark" "Papirus" "Tela-circle-dark" "Tela-circle" "Numix-Circle" "Numix")

apply_icon_theme() {
    local theme="${1:-Papirus-Dark}"
    gsettings set org.gnome.desktop.interface icon-theme "$theme"
    sed -i "s/gtk-icon-theme-name=.*/gtk-icon-theme-name=$theme/" ~/.config/gtk-3.0/settings.ini
    sed -i "s/gtk-icon-theme-name=.*/gtk-icon-theme-name=$theme/" ~/.config/gtk-4.0/settings.ini
    echo "Applied icon theme: $theme"
}

list_themes() {
    for t in "${THEMES[@]}"; do
        echo "$t"
    done
}

main() {
    case "${1:-}" in
        apply) apply_icon_theme "${2:-}" ;;
        list) list_themes ;;
        *) echo "Usage: icon-theme.sh [apply|list]"; exit 1 ;;
    esac
}

main "$@"