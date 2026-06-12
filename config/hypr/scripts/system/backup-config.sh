#!/bin/bash
set -euo pipefail

BACKUP_DIR="${HOME}/.config/hypr/backups/config-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Backing up configurations..."

configs=(
    ~/.config/hypr
    ~/.config/waybar
    ~/.config/rofi
    ~/.config/kitty
    ~/.config/fish
    ~/.config/nvim
    ~/.config/gtk-3.0
    ~/.config/gtk-4.0
    ~/.config/eww
    ~/.config/swaync
    ~/.config/mako
)

for config in "${configs[@]}"; do
    [[ -d "$config" ]] && cp -r "$config" "$BACKUP_DIR/" && echo "  ✅ $(basename "$config")"
done

# Create tarball
tar -czf "${BACKUP_DIR}.tar.gz" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")"
rm -rf "$BACKUP_DIR"

echo "Backup saved to: ${BACKUP_DIR}.tar.gz"