#!/bin/bash
set -euo pipefail

BACKUPS=($(ls -dt ~/.config/hypr/backups/config-*.tar.gz 2>/dev/null))

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
    
    TEMP_DIR=$(mktemp -d)
    tar -xzf "$BACKUP" -C "$TEMP_DIR"
    
    for config in "$TEMP_DIR"/*/; do
        name=$(basename "$config")
        [[ -d "$config" ]] && cp -r "$config" ~/.config/ && echo "  ✅ $name"
    done
    
    rm -rf "$TEMP_DIR"
    echo "Restored. Reload Hyprland to apply changes."
else
    echo "Invalid selection"
    exit 1
fi