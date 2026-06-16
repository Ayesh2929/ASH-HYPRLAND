#!/bin/bash
set -euo pipefail

echo "Uninstalling ASH Dotfiles..."

read -rp "This will remove all ASH configurations. Continue? [y/N]: " confirm
[[ "${confirm,,}" != "y" ]] && { echo "Aborted"; exit 1; }

# Remove configs
rm -rf ~/.config/hypr
rm -rf ~/.config/waybar
rm -rf ~/.config/rofi
rm -rf ~/.config/kitty
rm -rf ~/.config/fish
rm -rf ~/.config/nvim
rm -rf ~/.config/gtk-3.0
rm -rf ~/.config/gtk-4.0
rm -rf ~/.config/eww
rm -rf ~/.config/swaync
rm -rf ~/.config/mako

# Remove cache
rm -rf ~/.cache/ash-dots

# Remove bin
rm -f ~/bin/ash

echo "Uninstalled. Restart your session."