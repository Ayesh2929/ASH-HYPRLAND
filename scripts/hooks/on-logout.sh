#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — scripts/hooks/on-logout.sh
# ║  On logout
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# ash:description=Run while the session is shutting down
# ash:timeout=10
#
# Hook contract (see ash-cli/lib/hook-runner.sh):
#   • Context arrives as KEY=VALUE arguments, exported as ASH_HOOK_<KEY>
#   • The legacy runner flags --env KEY=VAL, --timeout N and --on-error M are
#     accepted for backwards compatibility with older call sites
#   • Exit 0 = success, 66 = skip, any other status = failure
#
set -euo pipefail
IFS=$'\n\t'

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash/hooks"
LOG_FILE="${STATE_DIR}/${SCRIPT_NAME%.sh}.log"

usage() {
    cat <<EOF
${SCRIPT_NAME} — On logout

USAGE
  ${SCRIPT_NAME} [KEY=VALUE ...]

CONTEXT (exported by the runner)
  ASH_HOOK_NAME    hook name
  ASH_HOOK_ARGS    space separated key=value arguments
  ASH_HOOK_<KEY>   every argument upper-cased

Exit codes: 0 success · 66 skip · other failure
EOF
}

log_event() {
    mkdir -p "$STATE_DIR" 2>/dev/null || true
    printf '[%s] %s: %s\n' "$(date '+%F %T')" "${SCRIPT_NAME%.sh}" "$1" \
        >>"$LOG_FILE" 2>/dev/null || true
    # keep the log small — rotate past 128 KiB
    if [[ -f "$LOG_FILE" ]]; then
        local size
        size="$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)"
        if (( size > 131072 )); then
            mv -f "$LOG_FILE" "${LOG_FILE}.1" 2>/dev/null || true
        fi
    fi
}

notify() {
    local summary="$1" body="${2:-}" urgency="${3:-low}"
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send --app-name="ASH" --urgency="$urgency" --expire-time=4000 \
        "$summary" "$body" 2>/dev/null || true
}

# Waybar reloads without ever failing the hook when it is not running.
reload_waybar() {
    command -v pkill >/dev/null 2>&1 || return 0
    pkill -SIGUSR2 waybar 2>/dev/null || true
}

# Whisper to the user that a reload is a good idea after big changes.
ash_reload_hint() {
    notify "✓ ASH updated" "Reload the session to pick up every change" low
}

main() {
    local dry=0
    while (( $# )); do
        case "$1" in
            --help|-h)   usage; exit 0 ;;
            --dry-run|-n) dry=1; shift ;;
            --env)       shift || true
                         if [[ -n "${1:-}" ]]; then export "$1" 2>/dev/null || true; shift; fi ;;
            --timeout|--on-error) shift || true; (( $# )) && shift || true ;;
            --)          shift; break ;;
            --*)         shift ;;                      # unknown runner flag — ignore
            *=*)         export "$1" 2>/dev/null || true; shift ;;
            *)           shift ;;
        esac
    done

    if (( dry )); then
        log_event "dry-run"
        printf '[dry-run] %s would run\n' "$SCRIPT_NAME"
        exit 0
    fi

    log_event "start args=${ASH_HOOK_ARGS:-}"
    : # event recorded only
    log_event "done"
    exit 0
}

main "$@"
