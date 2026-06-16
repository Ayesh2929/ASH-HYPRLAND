#!/bin/bash
set -euo pipefail

apply_gtk_theme_v2() {
    local theme="${1:-Adwaita:dark}"
    local icon="${2:-Papirus-Dark}"
    local cursor="${3:-Bibata-Modern-Classic}"
    local size="${4:-24}"
    local font="${5:-Noto Sans 11}"
    
    gsettings set org.gnome.desktop.interface gtk-theme "$theme"
    gsettings set org.gnome.desktop.interface icon-theme "$icon"
    gsettings set org.gnome.desktop.interface cursor-theme "$cursor"
    gsettings set org.gnome.desktop.interface cursor-size "$size"
    gsettings set org.gnome.desktop.interface font-name "$font"
    gsettings set org.gnome.desktop.interface monospace-font-name "JetBrains Mono Nerd Font 11"
    
    # Update config files
    sed -i "s/gtk-theme-name=.*/gtk-theme-name=$theme/" ~/.config/gtk-3.0/settings.ini
    sed -i "s/gtk-icon-theme-name=.*/gtk-icon-theme-name=$icon/" ~/.config/gtk-3.0/settings.ini
    sed -i "s/gtk-cursor-theme-name=.*/gtk-cursor-theme-name=$cursor/" ~/.config/gtk-3.0/settings.ini
    sed -i "s/gtk-cursor-theme-size=.*/gtk-cursor-theme-size=$size/" ~/.config/gtk-3.0/settings.ini
    sed -i "s/gtk-font-name=.*/gtk-font-name=$font/" ~/.config/gtk-3.0/settings.ini
    
    sed -i "s/gtk-theme-name=.*/gtk-theme-name=$theme/" ~/.config/gtk-4.0/settings.ini
    sed -i "s/gtk-icon-theme-name=.*/gtk-icon-theme-name=$icon/" ~/.config/gtk-4.0/settings.ini
    sed -i "s/gtk-cursor-theme-name=.*/gtk-cursor-theme-name=$cursor/" ~/.config/gtk-4.0/settings.ini
    sed -i "s/gtk-cursor-theme-size=.*/gtk-cursor-theme-size=$size/" ~/.config/gtk-4.0/settings.ini
    sed -i "s/gtk-font-name=.*/gtk-font-name=$font/" ~/.config/gtk-4.0/settings.ini
    
    hyprctl setcursor "$cursor" "$size"
    
    echo "Applied GTK theme: $theme"
    echo "Icon theme: $icon"
    echo "Cursor: $cursor ($size)"
    echo "Font: $font"
}

list_themes() {
    echo "GTK Themes:"
    ls /usr/share/themes/ 2>/dev/null | head -20
    echo ""
    echo "Icon Themes:"
    ls /usr/share/icons/ 2>/dev/null | head -20
    echo ""
    echo "Cursor Themes:"
    ls /usr/share/icons/ 2>/dev/null | grep -i cursor | head -10
}

main() {
    case "${1:-}" in
        apply) apply_gtk_theme_v2 "${2:-Adwaita:dark}" "${3:-Papirus-Dark}" "${4:-Bibata-Modern-Classic}" "${5:-24}" "${6:-Noto Sans 11}" ;;
        list) list_themes ;;
        *) echo "Usage: gtk-theme-v2.sh [apply|list]"; exit 1 ;;
    esac
}

main "$@"