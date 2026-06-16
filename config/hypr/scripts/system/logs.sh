#!/bin/bash
set -euo pipefail

case "${1:-}" in
    errors) journalctl -p 3 -xb ;;
    boots) journalctl --list-boots ;;
    follow) journalctl -f ;;
    since) journalctl --since "${2:-1 hour ago}" ;;
    unit) journalctl -u "${2:-}" ;;
    *) echo "Usage: logs.sh [errors|boots|follow|since|unit]"; exit 1 ;;
esac