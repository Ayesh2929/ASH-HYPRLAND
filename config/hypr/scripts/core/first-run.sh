#!/bin/bash
set -euo pipefail

echo "ASH Dotfiles - First Run Setup"
echo "=============================="

# Create directories
mkdir -p ~/.config/hypr/scripts
mkdir -p ~/.config/waybar
mkdir -p ~/.config/rofi
mkdir -p ~/.config/kitty
mkdir -p ~/.config/fish
mkdir -p ~/.config/nvim
mkdir -p ~/.config/gtk-3.0
mkdir -p ~/.config/gtk-4.0
mkdir -p ~/.config/eww
mkdir -p ~/.config/swaync
mkdir -p ~/.config/mako
mkdir -p ~/Pictures/wallpapers
mkdir -p ~/Videos/recordings
mkdir -p ~/.cache/ash-dots

# Initialize analytics DB
~/.config/hypr/scripts/theme/desktop-analytics.sh init 2>/dev/null || true

# Set default theme
echo "catppuccin" > ~/.config/hypr/.current_theme

echo "First run setup complete!"
echo "Run 'ash install' to install dependencies"
echo "Run 'ash reload' to apply configuration"