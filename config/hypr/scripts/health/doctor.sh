#!/bin/bash
set -euo pipefail

echo "ASH Dotfiles Health Check"
echo "========================="

check_cmd() {
    command -v "$1" &>/dev/null && echo "  ✅ $1" || echo "  ❌ $1 (missing)"
}

check_cmd hyprland
check_cmd waybar
check_cmd rofi
check_cmd kitty
check_cmd swaylock
check_cmd hyprpaper
check_cmd grim
check_cmd slurp
check_cmd wl-clipboard
check_cmd brightnessctl
check_cmd wpctl
check_cmd jq
check_cmd sqlite3
check_cmd socat
check_cmd curl

echo ""
echo "Config files:"
[[ -f ~/.config/hypr/hyprland.conf ]] && echo "  ✅ hyprland.conf" || echo "  ❌ hyprland.conf"
[[ -f ~/.config/waybar/config.jsonc ]] && echo "  ✅ waybar config" || echo "  ❌ waybar config"
[[ -f ~/.config/rofi/config.rasi ]] && echo "  ✅ rofi config" || echo "  ❌ rofi config"

echo ""
echo "Scripts:"
[[ -x ~/.config/hypr/scripts/theme/smart-wallpaper.sh ]] && echo "  ✅ smart-wallpaper.sh" || echo "  ❌ smart-wallpaper.sh"
[[ -x ~/.config/hypr/scripts/theme/desktop-analytics.sh ]] && echo "  ✅ desktop-analytics.sh" || echo "  ❌ desktop-analytics.sh"

echo ""
echo "Done"