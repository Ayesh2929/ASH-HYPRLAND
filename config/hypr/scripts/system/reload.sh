#!/bin/bash
set -euo pipefail

hyprctl reload
waybar &
swaync &
echo "Hyprland reloaded"