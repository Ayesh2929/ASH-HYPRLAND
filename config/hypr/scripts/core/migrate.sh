#!/bin/bash
set -euo pipefail

BACKUP_DIR="${HOME}/.config/hypr/backups/pre-migration-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Backing up current config to $BACKUP_DIR"
cp -r ~/.config/hypr "$BACKUP_DIR/"
cp -r ~/.config/waybar "$BACKUP_DIR/"
cp -r ~/.config/rofi "$BACKUP_DIR/"
cp -r ~/.config/kitty "$BACKUP_DIR/"
cp -r ~/.config/fish "$BACKUP_DIR/"

echo "Migration backup complete"
echo "Run restore.sh to revert"