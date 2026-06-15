#!/bin/bash
set -euo pipefail

case "${1:-}" in
    toggle) hyprctl dispatch layoutmsg splith ;;
    *) echo "Usage: splith.sh [toggle]"; exit 1 ;;
esac