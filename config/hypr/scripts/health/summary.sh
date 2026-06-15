#!/bin/bash
set -euo pipefail

echo "ASH Dotfiles Summary"
echo "===================="

echo ""
echo "Scripts:"
find ~/.config/hypr/scripts -name "*.sh" -type f | wc -l | xargs -I{} echo "  Shell scripts: {}"

echo ""
echo "Configs:"
find ~/.config/hypr -name "*.conf" -type f | wc -l | xargs -I{} echo "  Hyprland configs: {}"
find ~/.config/waybar -name "*.jsonc" -o -name "*.css" -type f | wc -l | xargs -I{} echo "  Waybar configs: {}"
find ~/.config/rofi -name "*.rasi" -type f | wc -l | xargs -I{} echo "  Rofi configs: {}"

echo ""
echo "Themes:"
ls ~/.config/hypr/themes/*.conf 2>/dev/null | wc -l | xargs -I{} echo "  Available themes: {}"

echo ""
echo "Cache size:"
du -sh ~/.cache/ash-dots 2>/dev/null | cut -f1 | xargs -I{} echo "  {}"

echo ""
echo "Git status:"
cd ~/.config/hypr && git status --short 2>/dev/null | wc -l | xargs -I{} echo "  Modified files: {}"