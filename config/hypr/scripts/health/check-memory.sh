#!/bin/bash
set -euo pipefail

echo "Memory Check"
echo "============"

free -h

echo ""
echo "Top memory processes:"
ps aux --sort=-%mem | head -11 | tail -10 | awk '{printf "%-10s %5s%% %s\n", $1, $4, $11}'

echo ""
echo "Swap usage:"
free -h | grep Swap