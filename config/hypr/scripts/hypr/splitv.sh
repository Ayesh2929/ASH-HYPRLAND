#!/bin/bash
set -euo pipefail

case "${1:-}" in
    toggle) hyprctl dispatch layoutmsg splitv ;;
    *) echo "Usage: splitv.sh [toggle]"; exit 1 ;;
esac