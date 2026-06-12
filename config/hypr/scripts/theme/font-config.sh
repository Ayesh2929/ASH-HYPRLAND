#!/bin/bash
set -euo pipefail

apply_font() {
    local font="${1:-Noto Sans 11}"
    local mono="${2:-JetBrains Mono Nerd Font 11}"
    gsettings set org.gnome.desktop.interface font-name "$font"
    gsettings set org.gnome.desktop.interface monospace-font-name "$mono"
    sed -i "s/gtk-font-name=.*/gtk-font-name=$font/" ~/.config/gtk-3.0/settings.ini
    sed -i "s/gtk-font-name=.*/gtk-font-name=$font/" ~/.config/gtk-4.0/settings.ini
    echo "Applied font: $font (mono: $mono)"
}

main() {
    case "${1:-}" in
        apply) apply_font "${2:-}" "${3:-}" ;;
        *) echo "Usage: font-config.sh [apply]"; exit 1 ;;
    esac
}

main "$@"