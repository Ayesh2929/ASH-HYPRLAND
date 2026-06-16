#!/bin/bash
set -euo pipefail

case "${1:-}" in
    cpu) stress-ng --cpu $(nproc) --timeout "${2:-60}s" ;;
    memory) stress-ng --vm 2 --vm-bytes 80% --timeout "${2:-60}s" ;;
    disk) stress-ng --hdd 2 --hdd-bytes 1G --timeout "${2:-60}s" ;;
    all) stress-ng --cpu $(nproc) --vm 2 --vm-bytes 80% --hdd 2 --hdd-bytes 1G --timeout "${2:-60}s" ;;
    *) echo "Usage: stress.sh [cpu|memory|disk|all] [timeout]"; exit 1 ;;
esac