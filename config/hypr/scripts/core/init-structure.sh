#!/bin/bash
set -euo pipefail

echo "Initializing directory structure..."

dirs=(
    ~/.config/hypr/scripts/theme
    ~/.config/hypr/scripts/media
    ~/.config/hypr/scripts/system
    ~/.config/hypr/scripts/hypr
    ~/.config/hypr/scripts/health
    ~/.config/hypr/scripts/core
    ~/.config/hypr/themes
    ~/.config/waybar
    ~/.config/rofi
    ~/.config/kitty
    ~/.config/fish
    ~/.config/nvim
    ~/.config/gtk-3.0
    ~/.config/gtk-4.0
    ~/.config/eww
    ~/.config/swaync
    ~/.config/mako
    ~/Pictures/wallpapers
    ~/Videos/recordings
    ~/.cache/ash-dots/logs
    ~/.cache/ash-dots/analytics
    ~/.cache/ash-dots/wallpapers
)

for dir in "${dirs[@]}"; do
    mkdir -p "$dir"
done

echo "Directory structure initialized"