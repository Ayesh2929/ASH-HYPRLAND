#!/bin/bash
set -euo pipefail

echo "Cleaning logs..."

# Journal
journalctl --vacuum-time=7d
journalctl --vacuum-size=100M

# Hyprland logs
rm -f ~/.local/share/hyprland/hyprland.log.*
rm -f ~/.local/share/hyprland/hyprland.log

# Waybar logs
rm -f ~/.cache/waybar/*.log

# Custom logs
rm -f ~/.cache/ash-dots/logs/*.log

echo "Logs cleaned"