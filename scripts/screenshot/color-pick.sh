#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — scripts/screenshot/color-pick.sh                                        ║
# ║  Utility script.                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail
IFS=$'\n\t'

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

usage() {
    cat <<'EOF'
${SCRIPT_NAME} — ASH helper

Usage:
  ${SCRIPT_NAME} [--help] [--dry-run] [args...]

Part of ASH modular toolbox. Pass --help for details.
Use --dry-run to preview without side effects.
EOF
}

main() {
    local dry=0
    while (( $# )); do
        case "$1" in
            --help|-h) usage; exit 0 ;;
            --dry-run|-n) dry=1; shift ;;
            --) shift; break ;;
            -*) echo "$SCRIPT_NAME: unknown option $1" >&2; usage >&2; exit 2 ;;
            *) break ;;
        esac
    done
    if (( dry )); then
        echo "[dry-run] $SCRIPT_NAME would execute with: $*"
        exit 0
    fi
    if command -v ash &>/dev/null && [[ -x "$ROOT/ash-cli/ash" ]]; then
        echo "$SCRIPT_NAME: delegating to ash CLI where applicable (shim)"
    else
        echo "$SCRIPT_NAME: executed (shim) with args: $*"
    fi
    exit 0
}

main "$@"
