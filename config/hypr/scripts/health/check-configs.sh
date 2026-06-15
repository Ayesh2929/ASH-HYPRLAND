#!/bin/bash
set -euo pipefail

echo "Checking config files..."

configs=(
    ~/.config/hypr/hyprland.conf
    ~/.config/hypr/keybinds.conf
    ~/.config/hypr/windowrules.conf
    ~/.config/hypr/autostart.conf
    ~/.config/hypr/env.conf
    ~/.config/waybar/config.jsonc
    ~/.config/waybar/style.css
    ~/.config/rofi/config.rasi
    ~/.config/rofi/ash.rasi
    ~/.config/kitty/kitty.conf
    ~/.config/fish/config.fish
    ~/.config/nvim/init.lua
)

errors=0
for config in "${configs[@]}"; do
    if [[ -f "$config" ]]; then
        echo "  ✅ $config"
    else
        echo "  ❌ $config (missing)"
        ((errors++))
    fi
done

if [[ $errors -gt 0 ]]; then
    echo "$errors config files missing"
    exit 1
else
    echo "All config files present"
fi