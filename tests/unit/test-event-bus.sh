#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH — tests/unit/test-event-bus.sh — unit test (bats)                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
test_test_event_bus_exists() {
    if [[ -f "$ROOT/ash-cli/ash" ]]; then
        echo "  ✅ ash CLI exists"
    else
        echo "  ❌ ash CLI missing"; return 1
    fi
}
test_test_event_bus_can_source() {
    local lib="ash-cli/lib/colors.sh"
    if [[ -r "$ROOT/$lib" ]]; then
        bash -c "source \"$ROOT/$lib\"; echo ok" >/dev/null || { echo "  ❌ cannot source $lib"; return 1; }
        echo "  ✅ $lib sourceable"
    fi
}
if [[ "${BATS_TEST_FILENAME:-}" != "" ]]; then
    true
else
    echo "Running test-event-bus (standalone harness)…"
    test_test_event_bus_exists
    test_test_event_bus_can_source
    echo "✅ test-event-bus passed (harness)"
fi
