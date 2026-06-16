#!/bin/bash
set -euo pipefail

case "${1:-}" in
    bios) dmidecode -t bios 2>/dev/null | grep -E "Vendor|Version|Release Date" ;;
    system) dmidecode -t system 2>/dev/null | grep -E "Manufacturer|Product Name|Version" ;;
    baseboard) dmidecode -t baseboard 2>/dev/null | grep -E "Manufacturer|Product Name|Version" ;;
    all)
        echo "=== BIOS ===" && dmidecode -t bios 2>/dev/null | grep -E "Vendor|Version|Release Date"
        echo "" && echo "=== System ===" && dmidecode -t system 2>/dev/null | grep -E "Manufacturer|Product Name|Version"
        echo "" && echo "=== Baseboard ===" && dmidecode -t baseboard 2>/dev/null | grep -E "Manufacturer|Product Name|Version"
        ;;
    *) echo "Usage: firmware.sh [bios|system|baseboard|all]"; exit 1 ;;
esac