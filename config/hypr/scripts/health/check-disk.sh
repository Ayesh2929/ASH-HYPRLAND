#!/bin/bash
set -euo pipefail

echo "Disk Usage Check"
echo "================"

df -h / | tail -1 | awk '{print "Root: " $3 " / " $2 " (" $5 ")"}'

for disk in /home /var /tmp; do
    [[ -d "$disk" ]] && df -h "$disk" | tail -1 | awk -v d="$disk" '{print d ": " $3 " / " $2 " (" $5 ")"}'
done

echo ""
echo "Large directories in home:"
du -h ~/.* ~/* 2>/dev/null | sort -hr | head -10