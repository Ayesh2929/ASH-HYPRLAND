#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Workspace Initialization Script                  ║
# ║                                                                              ║
# ║  Sets up workspace layout on session start: names workspaces,              ║
# ║  launches default applications per workspace, restores saved session        ║
# ║  state, and applies workspace-specific configurations.                      ║
# ║                                                                              ║
# ║  Usage:                                                                      ║
# ║    workspace-init.sh              — initialize all workspaces               ║
# ║    workspace-init.sh --restore    — restore saved session                   ║
# ║    workspace-init.sh --minimal    — minimal init (no app launch)            ║
# ║    workspace-init.sh --reset      — reset to blank state                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly LOG_FILE="${HOME}/.local/state/ash-dotfiles/logs/workspace-init.log"
readonly SESSION_FILE="${HOME}/.local/state/ash-dotfiles/session-history.json"

readonly C_RESET='\033[0m'
readonly C_GREEN='\033[38;2;166;227;161m'
readonly C_BLUE='\033[38;2;137;180;250m'
readonly C_MAUVE='\033[38;2;203;164;247m'

_log() {
    printf "[%s] [WS-INIT] %s\n" \
        "$(date '+%Y-%m-%dT%H:%M:%S')" "$*" \
        | tee -a "$LOG_FILE" >/dev/null
}

log_info() { _log "$*"; echo -e "${C_BLUE}[WS]${C_RESET} $*"; }
log_ok()   { _log "OK: $*"; echo -e "${C_GREEN}[WS]${C_RESET} $*"; }

# ══════════════════════════════════════════════════════════════════════════════
# §01  WORKSPACE NAMES
# ══════════════════════════════════════════════════════════════════════════════

# Icon map: workspace number → nerd font icon + label
declare -A WS_NAMES=(
    [1]="󰆍 term"
    [2]="󰖟 web"
    [3]="󰅩 code"
    [4]="󱁉 files"
    [5]="󰝚 music"
    [6]="󰊗 game"
    [7]="󰙯 social"
    [8]="󰍡 mail"
    [9]="󰙺 media"
    [10]="󰓅 system"
)

_name_workspaces() {
    log_info "Naming workspaces..."
    for ws in "${!WS_NAMES[@]}"; do
        hyprctl dispatch renameworkspace "$ws" "${WS_NAMES[$ws]}" \
            2>/dev/null || true
    done
    log_ok "All workspaces named"
}

# ══════════════════════════════════════════════════════════════════════════════
# §02  DEFAULT APPLICATION LAUNCH
# ══════════════════════════════════════════════════════════════════════════════

_launch_defaults() {
    log_info "Launching default workspace applications..."

    # Workspace 1: Terminal
    hyprctl dispatch workspace 1 2>/dev/null || true
    sleep 0.2
    kitty & disown
    log_ok "WS1: kitty launched"

    sleep 0.8

    # Return to workspace 1
    hyprctl dispatch workspace 1 2>/dev/null || true

    log_ok "Default apps launched"
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  SESSION RESTORE
# ══════════════════════════════════════════════════════════════════════════════

_restore_session() {
    if [[ ! -f "$SESSION_FILE" ]]; then
        log_info "No saved session found — starting fresh"
        _launch_defaults
        return
    fi

    log_info "Restoring saved session..."

    # Read session and reopen windows
    local count=0
    while IFS= read -r entry; do
        local ws cmd
        ws=$(jq -r '.workspace' <<< "$entry" 2>/dev/null || continue)
        cmd=$(jq -r '.command' <<< "$entry" 2>/dev/null || continue)

        if [[ -n "$ws" ]] && [[ -n "$cmd" ]]; then
            hyprctl dispatch workspace "$ws" 2>/dev/null || true
            sleep 0.1
            eval "$cmd" & disown
            ((count++))
        fi
    done < <(jq -c '.windows[]' "$SESSION_FILE" 2>/dev/null || true)

    log_ok "Session restored: $count windows"
    hyprctl dispatch workspace 1 2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  MINIMAL INIT (no app launch)
# ══════════════════════════════════════════════════════════════════════════════

_minimal_init() {
    log_info "Minimal workspace initialization..."
    _name_workspaces
    hyprctl dispatch workspace 1 2>/dev/null || true
    log_ok "Minimal init complete"
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  RESET
# ══════════════════════════════════════════════════════════════════════════════

_reset_workspaces() {
    log_info "Resetting workspaces..."

    # Close all windows
    local windows
    windows=$(hyprctl -j clients 2>/dev/null | jq -r '.[].address' 2>/dev/null || true)

    while IFS= read -r addr; do
        [[ -n "$addr" ]] && \
            hyprctl dispatch closewindow "address:$addr" 2>/dev/null || true
    done <<< "$windows"

    sleep 0.5
    _name_workspaces
    hyprctl dispatch workspace 1 2>/dev/null || true
    log_ok "Workspaces reset"
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  FULL INIT
# ══════════════════════════════════════════════════════════════════════════════

_full_init() {
    log_info "Full workspace initialization..."
    _name_workspaces
    sleep 0.3
    _launch_defaults
    log_ok "Workspace init complete"
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  MAIN
# ══════════════════════════════════════════════════════════════════════════════

main() {
    mkdir -p "$(dirname "$LOG_FILE")"
    _log "Workspace init started — args: $*"

    case "${1:---full}" in
        --full|-f)     _full_init       ;;
        --restore|-r)  _restore_session ;;
        --minimal|-m)  _minimal_init    ;;
        --reset)       _reset_workspaces ;;
        --help|-h)
            echo "Usage: $SCRIPT_NAME [--full|--restore|--minimal|--reset]"
            ;;
        *)
            log_info "Unknown arg: $1 — running full init"
            _full_init
            ;;
    esac
}

main "$@"