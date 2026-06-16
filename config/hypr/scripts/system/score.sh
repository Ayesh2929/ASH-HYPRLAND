#!/bin/bash
set -euo pipefail

echo "System Benchmark"
echo "================"

echo "CPU: $(sysbench cpu --cpu-max-prime=20000 run 2>/dev/null | grep 'total time:' | awk '{print $3}')s"
echo "Memory: $(sysbench memory --memory-block-size=1K --memory-total-size=100M run 2>/dev/null | grep 'transferred' | awk '{print $2, $3}')"
echo "Disk: $(dd if=/dev/zero of=/tmp/testfile bs=1G count=1 oflag=direct 2>&1 | grep copied | awk '{print $8, $9}')"
rm -f /tmp/testfile