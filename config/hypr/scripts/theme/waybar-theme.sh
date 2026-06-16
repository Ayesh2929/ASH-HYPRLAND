#!/bin/bash
set -euo pipefail

apply_waybar_theme() {
    local theme="${1:-catppuccin}"
    local style_file="${HOME}/.config/waybar/style.css"
    
    case "$theme" in
        catppuccin)
            cat > "$style_file" << 'EOF'
* { border: none; border-radius: 0; font-family: "JetBrains Mono Nerd Font"; font-size: 13px; min-height: 0; }
window#waybar { background: rgba(30,30,46,0.9); color: #cdd6f4; border-bottom: 2px solid #89b4fa; }
#workspaces button { padding: 0 8px; color: #6c7086; }
#workspaces button.active { color: #89b4fa; font-weight: bold; }
#workspaces button:hover { color: #cdd6f4; background: rgba(137,180,250,0.1); }
#window { padding: 0 12px; color: #a6adc8; }
#clock { padding: 0 12px; font-weight: bold; color: #f9e2af; }
#cpu, #memory, #pulseaudio, #network, #battery { padding: 0 12px; color: #a6adc8; }
#tray { padding: 0 8px; }
#battery.critical:not(.charging) { color: #f38ba8; }
EOF
            ;;
        tokyo-night)
            cat > "$style_file" << 'EOF'
* { border: none; border-radius: 0; font-family: "JetBrains Mono Nerd Font"; font-size: 13px; min-height: 0; }
window#waybar { background: rgba(26,27,38,0.9); color: #c0caf5; border-bottom: 2px solid #7aa2f7; }
#workspaces button { padding: 0 8px; color: #565f89; }
#workspaces button.active { color: #7aa2f7; font-weight: bold; }
#workspaces button:hover { color: #c0caf5; background: rgba(122,162,247,0.1); }
#window { padding: 0 12px; color: #a9b1d6; }
#clock { padding: 0 12px; font-weight: bold; color: #e0af68; }
#cpu, #memory, #pulseaudio, #network, #battery { padding: 0 12px; color: #a9b1d6; }
#tray { padding: 0 8px; }
#battery.critical:not(.charging) { color: #f7768e; }
EOF
            ;;
        *) echo "Unknown theme: $theme"; return 1 ;;
    esac
    
    pkill -USR2 waybar 2>/dev/null || waybar &
    echo "Applied Waybar theme: $theme"
}

main() {
    case "${1:-}" in
        apply) apply_waybar_theme "${2:-catppuccin}" ;;
        list) echo -e "catppuccin\ntokyo-night" ;;
        *) echo "Usage: waybar-theme.sh [apply|list]"; exit 1 ;;
    esac
}

main "$@"