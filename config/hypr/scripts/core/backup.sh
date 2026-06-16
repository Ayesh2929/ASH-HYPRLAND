#!/bin/bash
set -euo pipefail

BACKUP_DIR="${HOME}/.config/hypr/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "${BACKUP_DIR}"

cp -r ~/.config/hypr "${BACKUP_DIR}/"
cp -r ~/.config/waybar "${BACKUP_DIR}/"
cp -r ~/.config/rofi "${BACKUP_DIR}/"
cp -r ~/.config/kitty "${BACKUP_DIR}/"
cp -r ~/.config/fish "${BACKUP_DIR}/"

echo "Backup saved to: ${BACKUP_DIR}"