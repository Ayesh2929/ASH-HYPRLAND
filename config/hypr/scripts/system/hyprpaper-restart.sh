#!/bin/bash
set -euo pipefail

pkill hyprpaper 2>/dev/null || true
sleep 0.5
hyprpaper &
echo "Hyprpaper restarted"