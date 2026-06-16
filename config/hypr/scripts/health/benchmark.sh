#!/bin/bash
set -euo pipefail

echo "System Benchmark"
echo "================"

echo ""
echo "CPU (single thread):"
sysbench cpu --cpu-max-prime=20000 --threads=1 run 2>/dev/null | grep "total time:" | awk '{print "  " $3 "s"}'

echo ""
echo "CPU (multi thread):"
sysbench cpu --cpu-max-prime=20000 --threads=$(nproc) run 2>/dev/null | grep "total time:" | awk '{print "  " $3 "s"}'

echo ""
echo "Memory:"
sysbench memory --memory-block-size=1K --memory-total-size=100M run 2>/dev/null | grep "transferred" | awk '{print "  " $2 " " $3}'

echo ""
echo "Disk (sequential write):"
dd if=/dev/zero of=/tmp/bench_test bs=1G count=1 oflag=direct 2>&1 | grep copied | awk '{print "  " $8 " " $9}'
rm -f /tmp/bench_test

echo ""
echo "Disk (random 4k):"
fio --name=randrw --ioengine=libaio --iodepth=16 --rw=randrw --bs=4k --direct=1 --size=256M --numjobs=4 --runtime=10 --group_reporting --filename=/tmp/fio_test 2>/dev/null | grep "IOPS" | head -1 | awk '{print "  " $1 " " $2}'
rm -f /tmp/fio_test