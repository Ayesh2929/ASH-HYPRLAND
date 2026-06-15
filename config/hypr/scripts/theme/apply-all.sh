#!/bin/bash
set -euo pipefail

echo "Applying all theme settings..."

~/.config/hypr/scripts/theme/presets.sh apply default
~/.config/hypr/scripts/theme/waybar-theme.sh apply catppuccin
~/.config/hypr/scripts/theme/rofi-theme.sh apply ash
~/.config/hypr/scripts/theme/kitty-theme.sh apply catppuccin
~/.config/hypr/scripts/theme/gtk-theme-v2.sh apply Adwaita:dark Papirus-Dark Bibata-Modern-Classic 24 "Noto Sans 11"

echo "All themes applied!"