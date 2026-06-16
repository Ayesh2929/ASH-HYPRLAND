#!/bin/bash
set -euo pipefail

case "${1:-}" in
    wifi)
        nmcli -t -f active,ssid,signal dev wifi | grep '^yes' | cut -d: -f2-
        ;;
    ethernet)
        nmcli -t -f type,state dev | grep '^ethernet:connected' && echo "Connected" || echo "Disconnected"
        ;;
    vpn)
        nmcli -t -f type,state dev | grep '^vpn:connected' && echo "Connected" || echo "Disconnected"
        ;;
    scan)
        nmcli dev wifi rescan && nmcli -t -f ssid,signal dev wifi list | sort -t: -k2 -nr | head -10
        ;;
    *) echo "Usage: network.sh [wifi|ethernet|vpn|scan]"; exit 1 ;;
esac