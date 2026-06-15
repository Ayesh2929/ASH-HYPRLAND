#!/bin/bash
set -euo pipefail

case "${1:-}" in
    count) pacman -Q | wc -l ;;
    explicit) pacman -Qe | wc -l ;;
    foreign) pacman -Qm | wc -l ;;
    list) pacman -Q ;;
    orphans) pacman -Qdt ;;
    *) echo "Usage: packages.sh [count|explicit|foreign|list|orphans]"; exit 1 ;;
esac