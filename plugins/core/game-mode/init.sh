#!/usr/bin/env bash
# ASH game-mode — init: prepare gaming profile
set -euo pipefail
IFS=$'\n\t'
ROOT="${ASH_ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash"
mkdir -p "$STATE_DIR"
# Record that game-mode was initialized
printf '{"plugin":"game-mode","initialized":"%s","ts":%s}\n' "$(date -Iseconds)" "$(date +%s)" > "$STATE_DIR/game-mode-init.json"
echo "game-mode: initialized"
exit 0
