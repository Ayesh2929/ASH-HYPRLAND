#!/bin/bash
set -euo pipefail

deps=(
    hyprland waybar rofi kitty fish nvim
    swaylock swaync hyprpaper grim slurp
    brightnessctl pipewire wireplumber
    jq sqlite3 socat curl eza bat fd rg
    starship zoxide fzf cliphist hyprpicker
)

missing=0
for dep in "${deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
        echo "  ❌ $dep"
        ((missing++))
    else
        echo "  ✅ $dep"
    fi
done

echo ""
if [[ $missing -eq 0 ]]; then
    echo "All dependencies installed"
else
    echo "$missing dependencies missing"
    exit 1
fi