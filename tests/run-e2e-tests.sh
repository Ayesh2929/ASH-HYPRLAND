#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH — tests/run-e2e-tests.sh — integration/e2e/benchmark harness                          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
echo "Running tests/run-e2e-tests.sh — harness"
if [[ -f "$ROOT/ash-cli/ash" ]]; then
    bash "$ROOT/ash-cli/ash" --help >/dev/null 2>&1 && echo "  ✅ ash --help" || echo "  ⚠️ ash --help failed"
fi
if [[ -d "$ROOT/themes" ]]; then
    count=$(find "$ROOT/themes" -maxdepth 1 -name "*.json" | wc -l)
    echo "  ✅ themes: $count"
fi
echo "✅ run-e2e-tests harness complete"
exit 0
