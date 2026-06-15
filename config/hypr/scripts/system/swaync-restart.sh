#!/bin/bash
set -euo pipefail

pkill swaync 2>/dev/null || true
sleep 0.5
swaync &
echo "SwayNC restarted"