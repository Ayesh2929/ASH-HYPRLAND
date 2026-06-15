#!/bin/bash
set -euo pipefail

case "${1:-}" in
    store) cliphist store ;;
    list) cliphist list ;;
    wipe) cliphist wipe ;;
    delete) cliphist delete "$2" ;;
    *) echo "Usage: cliphist.sh [store|list|wipe|delete]"; exit 1 ;;
esac