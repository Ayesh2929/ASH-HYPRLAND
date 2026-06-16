#!/bin/bash
set -euo pipefail

echo "Validating configuration..."

errors=0

check_file() {
    [[ -f "$1" ]] && echo "  ✅ $1" || { echo "  ❌ $1 (missing)"; ((errors++)); }
}

check_dir() {
    [[ -d "$1" ]] && echo "  ✅ $1" || { echo "  ❌ $1 (missing)"; ((errors++)); }
}

check_file ~/.config/hypr/hyprland.conf
check_file ~/.config/hypr/keybinds.conf
check_file ~/.config/hypr/windowrules.conf
check_file ~/.config/hypr/autostart.conf
check_file ~/.config/hypr/env.conf
check_file ~/.config/waybar/config.jsonc
check_file ~/.config/waybar/style.css
check_file ~/.config/rofi/config.rasi
check_file ~/.config/rofi/ash.rasi
check_file ~/.config/kitty/kitty.conf
check_file ~/.config/fish/config.fish
check_file ~/.config/nvim/init.lua

check_dir ~/.config/hypr/scripts
check_dir ~/.config/hypr/scripts/theme
check_dir ~/.config/hypr/scripts/media
check_dir ~/.config/hypr/scripts/system
check_dir ~/.config/hypr/scripts/hypr
check_dir ~/.config/hypr/scripts/health
check_dir ~/.config/hypr/scripts/core

echo ""
if [[ $errors -eq 0 ]]; then
    echo "All validations passed!"
else
    echo "Found $errors error(s)"
    exit 1
fi