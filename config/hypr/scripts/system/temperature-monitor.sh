#!/bin/bash
set -euo pipefail

watch -n 2 '
echo "=== Temperature Monitor ==="
echo "Time: $(date)"
echo ""
sensors | grep -E "(Package|Core|edge|Composite)" | while read line; do
    echo "  $line"
done
echo ""
echo "Fan speeds:"
sensors | grep -i fan | while read line; do
    echo "  $line"
done
'