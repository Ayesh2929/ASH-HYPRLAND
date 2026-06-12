#!/bin/bash
set -euo pipefail

THEMES=("Adwaita:dark" "Adwaita" "Graphite-Dark" "Graphite" "Orchis-Dark" "Orchis")

apply_gtk_theme() {
    local theme="${1:-Adwaita:dark}"
    gsettings set org.gnome.desktop.interface gtk-theme "$theme"
    sed -i "s/gtk-theme-name=.*/gtk-theme-name=$theme/" ~/.config/gtk-3.0/settings.ini
    sed -i "s/gtk-theme-name=.*/gtk-theme-name=$theme/" ~/.config/gtk-4.0/settings.ini
    echo "Applied GTK theme: $theme"
}

list_themes() {
    for t in "${THEMES[@]}"; do
        echo "$t"
    done
}

main() {
    case "${1:-}" in
        apply) apply_gtk_theme "${2:-}" ;;
        list) list_themes ;;
        *) echo "Usage: gtk-theme.sh [apply|list]"; exit 1 ;;
    esac
}

main "$@"