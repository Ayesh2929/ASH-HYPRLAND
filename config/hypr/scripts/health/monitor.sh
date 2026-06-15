#!/bin/bash
set -euo pipefail

watch -n 1 '
echo "=== System Monitor ==="
echo "Time: $(date)"
echo ""
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk "{print \$2}" | tr -d "%")%"
echo "RAM: $(free | grep Mem | awk "{printf \"%.1f\", \$3/\$2 * 100}")%"
echo "Disk: $(df -h / | tail -1 | awk "{print \$5}")"
echo "Load: $(uptime | awk -F"load average:" "{print \$2}")"
echo ""
echo "Top Processes:"
ps aux --sort=-%cpu | head -6 | tail -5
'