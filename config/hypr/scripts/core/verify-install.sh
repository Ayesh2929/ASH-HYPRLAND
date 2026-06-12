#!/bin/bash
set -euo pipefail

echo "Verifying ASH Dotfiles Installation"
echo "===================================="

total=0
passed=0

check() {
    ((total++))
    local name="$1"
    shift
    if eval "$@" &>/dev/null; then
        echo "  ✅ $name"
        ((passed++))
    else
        echo "  ❌ $name"
    fi
}

# Core
check "hyprland installed" command -v hyprland
check "waybar installed" command -v waybar
check "rofi installed" command -v rofi
check "kitty installed" command -v kitty
check "fish installed" command -v fish
check "nvim installed" command -v nvim

# Configs
check "hyprland.conf" "[[ -f ~/.config/hypr/hyprland.conf ]]"
check "waybar config" "[[ -f ~/.config/waybar/config.jsonc ]]"
check "rofi config" "[[ -f ~/.config/rofi/config.rasi ]]"
check "kitty config" "[[ -f ~/.config/kitty/kitty.conf ]]"
check "fish config" "[[ -f ~/.config/fish/config.fish ]]"
check "nvim config" "[[ -f ~/.config/nvim/init.lua ]]"

# Scripts
check "smart-wallpaper.sh executable" "[[ -x ~/.config/hypr/scripts/theme/smart-wallpaper.sh ]]"
check "desktop-analytics.sh executable" "[[ -x ~/.config/hypr/scripts/theme/desktop-analytics.sh ]]"
check "theme-switcher.sh executable" "[[ -x ~/.config/hypr/scripts/theme/theme-switcher.sh ]]"
check "screenshot.sh executable" "[[ -x ~/.config/hypr/scripts/media/screenshot.sh ]]"
check "volume.sh executable" "[[ -x ~/.config/hypr/scripts/system/volume.sh ]]"
check "brightness.sh executable" "[[ -x ~/.config/hypr/scripts/system/brightness.sh ]]"
check "lock.sh executable" "[[ -x ~/.config/hypr/scripts/system/lock.sh ]]"
check "reload.sh executable" "[[ -x ~/.config/hypr/scripts/system/reload.sh ]]"
check "doctor.sh executable" "[[ -x ~/.config/hypr/scripts/health/doctor.sh ]]"
check "update.sh executable" "[[ -x ~/.config/hypr/scripts/core/update.sh ]]"
check "backup.sh executable" "[[ -x ~/.config/hypr/scripts/core/backup.sh ]]"
check "clean.sh executable" "[[ -x ~/.config/hypr/scripts/core/clean.sh ]]"

# Themes
check "catppuccin theme" "[[ -f ~/.config/hypr/themes/catppuccin.conf ]]"
check "tokyo-night theme" "[[ -f ~/.config/hypr/themes/tokyo-night.conf ]]"
check "nord theme" "[[ -f ~/.config/hypr/themes/nord.conf ]]"
check "dracula theme" "[[ -f ~/.config/hypr/themes/dracula.conf ]]"

# CLI
check "ash CLI" "[[ -x ~/bin/ash ]]"

echo ""
echo "Results: $passed/$total checks passed"

if [[ $passed -eq $total ]]; then
    echo "Installation verified! 🎉"
else
    echo "Some checks failed."
    exit 1
fi