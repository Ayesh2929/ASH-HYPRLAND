#!/bin/bash
set -euo pipefail

case "${1:-}" in
    cpu) sensors | grep "Package id 0" | awk '{print $4}' | tr -d '+°C' ;;
    gpu) sensors | grep "edge" | head -1 | awk '{print $2}' | tr -d '+°C' ;;
    nvme) sensors | grep "Composite" | awk '{print $2}' | tr -d '+°C' ;;
    all) sensors ;;
    *) echo "Usage: temperature.sh [cpu|gpu|nvme|all]"; exit 1 ;;
esac