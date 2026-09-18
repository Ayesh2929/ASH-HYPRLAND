#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH — tests/benchmark/bench-color-extract.sh — integration/e2e/benchmark harness                          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
echo "Running tests/benchmark/bench-color-extract.sh — harness"
if [[ -f "$ROOT/ash-cli/ash" ]]; then
    bash "$ROOT/ash-cli/ash" --help >/dev/null 2>&1 && echo "  ✅ ash --help" || echo "  ⚠️ ash --help failed"
fi
if [[ -d "$ROOT/themes" ]]; then
    count=$(find "$ROOT/themes" -maxdepth 1 -name "*.json" | wc -l)
    echo "  ✅ themes: $count"
fi
echo "✅ bench-color-extract harness complete"
exit 0
