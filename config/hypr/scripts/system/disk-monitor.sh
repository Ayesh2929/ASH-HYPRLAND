#!/bin/bash
set -euo pipefail

watch -n 5 '
echo "=== Disk Monitor ==="
echo "Time: $(date)"
echo ""
df -h / | tail -1 | awk "{print \"Root: \" \$3 \" / \" \$2 \" (\" \$5 \")\"}"
df -h /home 2>/dev/null | tail -1 | awk "{print \"Home: \" \$3 \" / \" \$2 \" (\" \$5 \")\"}"
df -h /var 2>/dev/null | tail -1 | awk "{print \"Var: \" \$3 \" / \" \$2 \" (\" \$5 \")\"}"
df -h /tmp 2>/dev/null | tail -1 | awk "{print \"Tmp: \" \$3 \" / \" \$2 \" (\" \$5 \")\"}"
echo ""
echo "I/O stats:"
iostat -x 1 2 2>/dev/null | tail -10
'