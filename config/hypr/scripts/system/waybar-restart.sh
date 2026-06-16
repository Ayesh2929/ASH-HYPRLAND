#!/bin/bash
set -euo pipefail

pkill waybar 2>/dev/null || true
sleep 0.5
waybar &
echo "Waybar restarted"