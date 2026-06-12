#!/bin/bash
set -euo pipefail

case "${1:-}" in
    on) bluetoothctl power on ;;
    off) bluetoothctl power off ;;
    toggle)
        if bluetoothctl show | grep -q "Powered: yes"; then
            bluetoothctl power off
        else
            bluetoothctl power on
        fi
        ;;
    connect) bluetoothctl connect "$2" ;;
    disconnect) bluetoothctl disconnect "$2" ;;
    devices) bluetoothctl devices ;;
    scan) bluetoothctl scan on ;;
    *) echo "Usage: bluetooth.sh [on|off|toggle|connect|disconnect|devices|scan]"; exit 1 ;;
esac