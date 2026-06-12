#!/bin/bash
set -euo pipefail

case "${1:-}" in
    list) systemctl list-units --type=service --state=running ;;
    failed) systemctl --failed ;;
    user) systemctl --user list-units --type=service --state=running ;;
    enable) systemctl enable "${2:-}" ;;
    disable) systemctl disable "${2:-}" ;;
    start) systemctl start "${2:-}" ;;
    stop) systemctl stop "${2:-}" ;;
    restart) systemctl restart "${2:-}" ;;
    status) systemctl status "${2:-}" ;;
    *) echo "Usage: services.sh [list|failed|user|enable|disable|start|stop|restart|status]"; exit 1 ;;
esac