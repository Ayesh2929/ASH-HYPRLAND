#!/bin/bash
set -euo pipefail

echo "CPU Check"
echo "========="

echo "Load average: $(uptime | awk -F'load average:' '{print $2}')"
echo "CPU cores: $(nproc)"
echo ""

echo "CPU frequencies:"
cat /proc/cpuinfo | grep "cpu MHz" | awk '{print "  Core " NR ": " $4 " MHz"}'

echo ""
echo "Top CPU processes:"
ps aux --sort=-%cpu | head -11 | tail -10 | awk '{printf "%-10s %5s%% %s\n", $1, $3, $11}'

echo ""
echo "Temperature:"
sensors | grep -E "Package|Core" | head -10