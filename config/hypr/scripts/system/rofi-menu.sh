#!/bin/bash
set -euo pipefail

menu_items="🔒 Lock\n🚪 Logout\n💤 Suspend\n🔄 Reboot⏻ Shutdown\n🎨 Theme\n🖼️ Wallpaper\n⚙️ Settings"

chosen=$(echo -e "$menu_items" | rofi -dmenu -p "System" -theme ash)

case "$chosen" in
    "🔒 Lock") swaylock ;;
    "🚪 Logout") hyprctl dispatch exit ;;
    "💤 Suspend") systemctl suspend ;;
    "🔄 Reboot") systemctl reboot ;;
    "⏻ Shutdown") systemctl poweroff ;;
    "🎨 Theme") ~/.config/hypr/scripts/theme/theme-switcher.sh apply ;;
    "🖼️ Wallpaper") ~/.config/hypr/scripts/theme/smart-wallpaper.sh apply ;;
    "⚙️ Settings") kitty -e nvim ~/.config/hypr/hyprland.conf ;;
esac