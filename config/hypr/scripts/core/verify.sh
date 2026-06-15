#!/bin/bash
set -euo pipefail

echo "Verifying ASH Dotfiles Installation"
echo "===================================="

checks=0
passed=0

check() {
    ((checks++))
    if eval "$2"; then
        echo "  ✅ $1"
        ((passed++))
    else
        echo "  ❌ $1"
    fi
}

# Core configs
check "hyprland.conf" "[[ -f ~/.config/hypr/hyprland.conf ]]"
check "keybinds.conf" "[[ -f ~/.config/hypr/keybinds.conf ]]"
check "windowrules.conf" "[[ -f ~/.config/hypr/windowrules.conf ]]"
check "autostart.conf" "[[ -f ~/.config/hypr/autostart.conf ]]"
check "env.conf" "[[ -f ~/.config/hypr/env.conf ]]"

# Waybar
check "waybar config" "[[ -f ~/.config/waybar/config.jsonc ]]"
check "waybar style" "[[ -f ~/.config/waybar/style.css ]]"

# Rofi
check "rofi config" "[[ -f ~/.config/rofi/config.rasi ]]"
check "rofi theme" "[[ -f ~/.config/rofi/ash.rasi ]]"

# Kitty
check "kitty config" "[[ -f ~/.config/kitty/kitty.conf ]]"

# Fish
check "fish config" "[[ -f ~/.config/fish/config.fish ]]"

# Neovim
check "nvim config" "[[ -f ~/.config/nvim/init.lua ]]"

# Scripts
check "smart-wallpaper.sh" "[[ -x ~/.config/hypr/scripts/theme/smart-wallpaper.sh ]]"
check "desktop-analytics.sh" "[[ -x ~/.config/hypr/scripts/theme/desktop-analytics.sh ]]"
check "theme-switcher.sh" "[[ -x ~/.config/hypr/scripts/theme/theme-switcher.sh ]]"
check "screenshot.sh" "[[ -x ~/.config/hypr/scripts/media/screenshot.sh ]]"
check "volume.sh" "[[ -x ~/.config/hypr/scripts/system/volume.sh ]]"
check "brightness.sh" "[[ -x ~/.config/hypr/scripts/system/brightness.sh ]]"
check "lock.sh" "[[ -x ~/.config/hypr/scripts/system/lock.sh ]]"
check "reload.sh" "[[ -x ~/.config/hypr/scripts/system/reload.sh ]]"
check "doctor.sh" "[[ -x ~/.config/hypr/scripts/health/doctor.sh ]]"
check "update.sh" "[[ -x ~/.config/hypr/scripts/core/update.sh ]]"
check "backup.sh" "[[ -x ~/.config/hypr/scripts/core/backup.sh ]]"
check "clean.sh" "[[ -x ~/.config/hypr/scripts/core/clean.sh ]]"

# Themes
check "catppuccin theme" "[[ -f ~/.config/hypr/themes/catppuccin.conf ]]"
check "tokyo-night theme" "[[ -f ~/.config/hypr/themes/tokyo-night.conf ]]"
check "nord theme" "[[ -f ~/.config/hypr/themes/nord.conf ]]"
check "dracula theme" "[[ -f ~/.config/hypr/themes/dracula.conf ]]"

# CLI
check "ash CLI" "[[ -x ~/bin/ash ]]"

echo ""
echo "Results: $passed/$checks checks passed"

if [[ $passed -eq $checks ]]; then
    echo "Installation verified successfully!"
else
    echo "Some checks failed. Run 'ash doctor' for details."
    exit 1
fi