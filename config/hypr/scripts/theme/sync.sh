#!/bin/bash
set -euo pipefail

echo "Syncing themes across applications..."

THEME="${1:-catppuccin}"

case "$THEME" in
    catppuccin)
        ~/.config/hypr/scripts/theme/colorscheme.sh apply catppuccin
        ~/.config/hypr/scripts/theme/waybar-theme.sh apply catppuccin
        ~/.config/hypr/scripts/theme/kitty-theme.sh apply catppuccin
        ~/.config/hypr/scripts/theme/gtk-theme-v2.sh apply Adwaita:dark Papirus-Dark Bibata-Modern-Classic 24 "Noto Sans 11"
        ;;
    tokyo-night)
        ~/.config/hypr/scripts/theme/colorscheme.sh apply tokyo-night
        ~/.config/hypr/scripts/theme/waybar-theme.sh apply tokyo-night
        ~/.config/hypr/scripts/theme/kitty-theme.sh apply tokyo-night
        ~/.config/hypr/scripts/theme/gtk-theme-v2.sh apply Adwaita:dark Papirus-Dark Bibata-Modern-Classic 24 "Noto Sans 11"
        ;;
    nord)
        ~/.config/hypr/scripts/theme/colorscheme.sh apply nord
        ~/.config/hypr/scripts/theme/kitty-theme.sh apply nord
        ~/.config/hypr/scripts/theme/gtk-theme-v2.sh apply Adwaita:dark Papirus-Dark Bibata-Modern-Classic 24 "Noto Sans 11"
        ;;
    *) echo "Unknown theme: $THEME"; exit 1 ;;
esac

echo "Theme synced: $THEME"