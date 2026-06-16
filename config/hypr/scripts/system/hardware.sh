#!/bin/bash
set -euo pipefail

case "${1:-}" in
    cpu) lscpu ;;
    gpu) lspci | grep -i vga ;;
    memory) dmidecode -t memory 2>/dev/null | grep -E "Size|Speed|Type" | head -20 ;;
    disk) lsblk -o NAME,SIZE,TYPE,MOUNTPOINT ;;
    usb) lsusb ;;
    pci) lspci ;;
    all)
        echo "=== CPU ===" && lscpu
        echo "" && echo "=== GPU ===" && lspci | grep -i vga
        echo "" && echo "=== Memory ===" && dmidecode -t memory 2>/dev/null | grep -E "Size|Speed|Type" | head -20
        echo "" && echo "=== Disk ===" && lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
        ;;
    *) echo "Usage: hardware.sh [cpu|gpu|memory|disk|usb|pci|all]"; exit 1 ;;
esac