#!/bin/bash
set -euo pipefail

watch -n 1 '
echo "=== Network Monitor ==="
echo "Time: $(date)"
echo ""
echo "Interfaces:"
ip -brief addr | grep -v "DOWN" | while read line; do
    echo "  $line"
done
echo ""
echo "WiFi:"
nmcli -t -f active,ssid,signal dev wifi | grep "^yes" | while read line; do
    echo "  $line"
done
echo ""
echo "Connections:"
nmcli -t -f name,type,device con show --active | while read line; do
    echo "  $line"
done
'