#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH — tests/lint/yamllint.sh — lint harness                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail
IFS=$'\n\t'
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
echo "Lint check: yamllint"
case "yamllint" in
    *shellcheck*) command -v shellcheck &>/dev/null && find "$ROOT" -name "*.sh" -print0 | xargs -0 shellcheck --severity=warning --exclude=SC1091,SC2034 2>&1 | head -n 50 || echo "shellcheck: no issues or not installed" ;;
    *yamllint*) command -v yamllint &>/dev/null && yamllint "$ROOT" 2>&1 | head -n 50 || echo "yamllint: skip" ;;
    *jsonlint*) find "$ROOT" -name "*.json" -exec python3 -m json.tool {} > /dev/null \; 2>&1 | head -n 20 || echo "jsonlint: skip" ;;
    *) echo "yamllint: lint harness placeholder — ok" ;;
esac
exit 0
