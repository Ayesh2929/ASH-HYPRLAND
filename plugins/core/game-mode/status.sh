#!/usr/bin/env bash
# ASH game-mode — status
set -euo pipefail
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/ash/game-mode.json"
if [[ -f "$STATE_FILE" ]]; then
    cat "$STATE_FILE"
    # human-readable
    if command -v jq &>/dev/null; then
        enabled=$(jq -r '.enabled' "$STATE_FILE" 2>/dev/null)
        echo "game-mode: ${enabled:-unknown}"
    fi
else
    echo '{"enabled":false,"note":"never enabled"}'
    echo "game-mode: disabled (no state)"
fi
exit 0
