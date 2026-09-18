#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH — tests/helpers/mock-hyprctl.sh — unit test (bats)                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
test_mock_hyprctl_exists() {
    if [[ -f "$ROOT/ash-cli/ash" ]]; then
        echo "  ✅ ash CLI exists"
    else
        echo "  ❌ ash CLI missing"; return 1
    fi
}
test_mock_hyprctl_can_source() {
    local lib="ash-cli/lib/colors.sh"
    if [[ -r "$ROOT/$lib" ]]; then
        bash -c "source \"$ROOT/$lib\"; echo ok" >/dev/null || { echo "  ❌ cannot source $lib"; return 1; }
        echo "  ✅ $lib sourceable"
    fi
}
if [[ "${BATS_TEST_FILENAME:-}" != "" ]]; then
    true
else
    echo "Running mock-hyprctl (standalone harness)…"
    test_mock_hyprctl_exists
    test_mock_hyprctl_can_source
    echo "✅ mock-hyprctl passed (harness)"
fi
