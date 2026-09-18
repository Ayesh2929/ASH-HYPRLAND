#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH — ash-cli/api/color-api.sh — API shim                                                    ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail
IFS=$'\n\t'
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
API_BASE="${ASH_API_BASE:-http://localhost:8787/api/v1}"
usage() {
    cat <<'EOF'
ash-cli/api/color-api.sh — ASH color-api API shim

Usage:
  ash-cli/api/color-api.sh [--help] [--json] [args...]
Proxies to $API_BASE/color-api. Requires api/server.py running.
Falls back to local fixtures when daemon unreachable.
EOF
}
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then usage; exit 0; fi
if curl -sf "$API_BASE/health" >/dev/null 2>&1; then
    echo "Proxying to $API_BASE/color-api (daemon reachable)"
    curl -sf "$API_BASE/color-api" 2>&1 | head -n 100 || true
else
    echo "ASH daemon unreachable at $API_BASE — using fixture data for color-api"
    if [[ -f "$ROOT/ash-cli/data/color-api.json" ]]; then
        cat "$ROOT/ash-cli/data/color-api.json"
    else
        echo '{"api":"color-api","status":"fixture","note":"daemon not running"}'
    fi
fi
exit 0
