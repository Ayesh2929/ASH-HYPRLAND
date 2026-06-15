#!/bin/bash
set -euo pipefail

BACKUPS=($(ls -dt ~/.config/hypr/backups/*/ 2>/dev/null))

if [[ ${#BACKUPS[@]} -eq 0 ]]; then
    echo "No backups found"
    exit 1
fi

echo "Available backups:"
for i in "${!BACKUPS[@]}"; do
    echo "  $((i+1)). ${BACKUPS[$i]}"
done

read -p "Select backup to restore (1-${#BACKUPS[@]}): " choice
choice=$((choice-1))

if [[ $choice -ge 0 && $choice -lt ${#BACKUPS[@]} ]]; then
    BACKUP="${BACKUPS[$choice]}"
    echo "Restoring from $BACKUP"
    cp -r "$BACKUP"hypr/* ~/.config/hypr/
    cp -r "$BACKUP"waybar/* ~/.config/waybar/
    cp -r "$BACKUP"rofi/* ~/.config/rofi/
    cp -r "$BACKUP"kitty/* ~/.config/kitty/
    cp -r "$BACKUP"fish/* ~/.config/fish/
    echo "Restored. Reload Hyprland to apply changes."
else
    echo "Invalid selection"
    exit 1
fi