#!/bin/bash
set -euo pipefail

echo "ASH Dotfiles Doctor"
echo "==================="

run_check() {
    local name="$1"
    local cmd="$2"
    
    if eval "$cmd" &>/dev/null; then
        echo "  ✅ $name"
        return 0
    else
        echo "  ❌ $name"
        return 1
    fi
}

failed=0

echo ""
echo "Core Dependencies:"
run_check "hyprland" "command -v hyprland" || ((failed++))
run_check "waybar" "command -v waybar" || ((failed++))
run_check "rofi" "command -v rofi" || ((failed++))
run_check "kitty" "command -v kitty" || ((failed++))
run_check "fish" "command -v fish" || ((failed++))
run_check "nvim" "command -v nvim" || ((failed++))

echo ""
echo "Utilities:"
run_check "swaylock" "command -v swaylock" || ((failed++))
run_check "swaync" "command -v swaync" || ((failed++))
run_check "hyprpaper" "command -v hyprpaper" || ((failed++))
run_check "grim" "command -v grim" || ((failed++))
run_check "slurp" "command -v slurp" || ((failed++))
run_check "wl-copy" "command -v wl-copy" || ((failed++))
run_check "brightnessctl" "command -v brightnessctl" || ((failed++))
run_check "pactl" "command -v pactl" || ((failed++))
run_check "jq" "command -v jq" || ((failed++))
run_check "sqlite3" "command -v sqlite3" || ((failed++))
run_check "socat" "command -v socat" || ((failed++))
run_check "curl" "command -v curl" || ((failed++))

echo ""
echo "Config Files:"
run_check "hyprland.conf" "[[ -f ~/.config/hypr/hyprland.conf ]]" || ((failed++))
run_check "keybinds.conf" "[[ -f ~/.config/hypr/keybinds.conf ]]" || ((failed++))
run_check "windowrules.conf" "[[ -f ~/.config/hypr/windowrules.conf ]]" || ((failed++))
run_check "autostart.conf" "[[ -f ~/.config/hypr/autostart.conf ]]" || ((failed++))
run_check "env.conf" "[[ -f ~/.config/hypr/env.conf ]]" || ((failed++))
run_check "waybar config" "[[ -f ~/.config/waybar/config.jsonc ]]" || ((failed++))
run_check "waybar style" "[[ -f ~/.config/waybar/style.css ]]" || ((failed++))
run_check "rofi config" "[[ -f ~/.config/rofi/config.rasi ]]" || ((failed++))
run_check "rofi theme" "[[ -f ~/.config/rofi/ash.rasi ]]" || ((failed++))
run_check "kitty config" "[[ -f ~/.config/kitty/kitty.conf ]]" || ((failed++))
run_check "fish config" "[[ -f ~/.config/fish/config.fish ]]" || ((failed++))
run_check "nvim config" "[[ -f ~/.config/nvim/init.lua ]]" || ((failed++))

echo ""
echo "Scripts:"
run_check "smart-wallpaper.sh" "[[ -x ~/.config/hypr/scripts/theme/smart-wallpaper.sh ]]" || ((failed++))
run_check "desktop-analytics.sh" "[[ -x ~/.config/hypr/scripts/theme/desktop-analytics.sh ]]" || ((failed++))
run_check "theme-switcher.sh" "[[ -x ~/.config/hypr/scripts/theme/theme-switcher.sh ]]" || ((failed++))

echo ""
if [[ $failed -eq 0 ]]; then
    echo "All checks passed! 🎉"
else
    echo "$failed checks failed. Run 'ash doctor' for details."
    exit 1
fi