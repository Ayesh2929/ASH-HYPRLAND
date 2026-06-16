#!/bin/bash
set -euo pipefail

THEMES_DIR="${HOME}/.config/kitty/themes"
mkdir -p "$THEMES_DIR"

apply_kitty_theme() {
    local theme="${1:-catppuccin}"
    local theme_file="${THEMES_DIR}/${theme}.conf"
    
    [[ -f "$theme_file" ]] || { echo "Theme not found: $theme"; return 1; }
    
    sed -i "s/include .*theme.conf/include ${theme}.conf/" ~/.config/kitty/kitty.conf
    
    # Reload kitty
    pkill -USR1 kitty 2>/dev/null || true
    echo "Applied Kitty theme: $theme"
}

create_theme() {
    local name="${1:-custom}"
    local theme_file="${THEMES_DIR}/${name}.conf"
    
    cat > "$theme_file" << 'EOF'
# Custom Kitty Theme
background #1e1e2e
foreground #cdd6f4
selection_background #45475a
selection_foreground #f5e0dc
cursor #f5e0dc
cursor_text_color #1e1e2e
url_color #89b4fa
color0 #45475a
color1 #f38ba8
color2 #a6e3a1
color3 #f9e2af
color4 #89b4fa
color5 #f5c2e7
color6 #94e2d5
color7 #bac2de
color8 #585b70
color9 #f38ba8
color10 #a6e3a1
color11 #f9e2af
color12 #89b4fa
color13 #f5c2e7
color14 #94e2d5
color15 #a6adc8
EOF
    echo "Created theme: $theme_file"
}

list_themes() {
    ls "$THEMES_DIR"/*.conf 2>/dev/null | xargs -n1 basename | sed 's/\.conf$//'
}

main() {
    case "${1:-}" in
        apply) apply_kitty_theme "${2:-catppuccin}" ;;
        create) create_theme "${2:-custom}" ;;
        list) list_themes ;;
        *) echo "Usage: kitty-theme.sh [apply|create|list]"; exit 1 ;;
    esac
}

main "$@"