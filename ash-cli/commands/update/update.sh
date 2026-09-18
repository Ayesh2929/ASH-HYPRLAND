#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██╗   ██╗██████╗ ██████╗  █████╗ ████████╗███████╗                             ║
# ║  ██║   ██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝                             ║
# ║  ██║   ██║██████╔╝██║  ██║███████║   ██║   █████╗                               ║
# ║  ██║   ██║██╔═══╝ ██║  ██║██╔══██║   ██║   ██╔══╝                               ║
# ║  ╚██████╔╝██║     ██████╔╝██║  ██║   ██║   ███████╗                             ║
# ║   ╚═════╝ ╚═╝     ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝                             ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  UPDATE COMMAND DISPATCHER                               ║
# ║  Unified update management hub for all ASH components                           ║
# ║                                                                                  ║
# ║  Author   : ash-dotfiles                                                         ║
# ║  License  : MIT                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CMD_UPDATE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CMD_UPDATE_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _UPD_CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -gr _UPD_VERSION="5.0.0-omega"
declare -gr _UPD_LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/ash-update.lock"
declare -gr _UPD_LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash/logs"
declare -gr _UPD_LOG_FILE="${_UPD_LOG_DIR}/update.log"
declare -gr _UPD_SNAPSHOT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/ash/snapshots/pre-update"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CATPPUCCIN MOCHA PALETTE  (inline — zero external deps)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_u()       { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_ur()      { _u $'\033[0m';                          }   # reset
_ubold()   { _u $'\033[1m';                          }   # bold
_udim()    { _u $'\033[38;2;108;112;134m';           }   # overlay0
_umauve()  { _u $'\033[1;38;2;203;166;247m';         }   # mauve bold
_ublue()   { _u $'\033[38;2;137;180;250m';           }   # blue
_ugreen()  { _u $'\033[38;2;166;227;161m';           }   # green
_upeach()  { _u $'\033[38;2;250;179;135m';           }   # peach
_uyellow() { _u $'\033[1;38;2;249;226;175m';         }   # yellow bold
_ured()    { _u $'\033[1;38;2;243;139;168m';         }   # red bold
_uteal()   { _u $'\033[38;2;148;226;213m';           }   # teal
_usky()    { _u $'\033[38;2;137;220;235m';           }   # sky
_ulav()    { _u $'\033[38;2;180;190;254m';           }   # lavender
_upink()   { _u $'\033[38;2;245;194;231m';           }   # pink
_usapph()  { _u $'\033[38;2;116;199;236m';           }   # sapphire

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SHARED DISPLAY PRIMITIVES  (exported for sub-commands)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

upd_section() {
    local icon="$1"  title="$2"  color="${3:-$(_umauve)}"
    printf '\n%s%s  %s%s\n' "$color" "$icon" "$title" "$(_ur)"
    printf '%s  %s%s\n' "$(_udim)" "$(printf '─%.0s' $(seq 1 58))" "$(_ur)"
}

upd_kv() {
    local key="$1"  val="$2"  vc="${3:-$(_ugreen)}"
    printf '  %s%-26s%s %s%s%s\n' \
        "$(_udim)" "${key}:" "$(_ur)" "$vc" "$val" "$(_ur)"
}

upd_ok()    { printf '  %s✓%s  %s\n' "$(_ugreen)"  "$(_ur)" "$1"; }
upd_fail()  { printf '  %s✗%s  %s\n' "$(_ured)"    "$(_ur)" "$1"; }
upd_info()  { printf '  %sℹ%s  %s\n' "$(_udim)"    "$(_ur)" "$1"; }
upd_warn()  { printf '  %s⚠%s  %s\n' "$(_uyellow)" "$(_ur)" "$1"; }
upd_step()  { printf '  %s→%s  %s\n' "$(_uteal)"   "$(_ur)" "$1"; }
upd_skip()  { printf '  %s○%s  %s %s(skip)%s\n' \
    "$(_udim)" "$(_ur)" "$1" "$(_udim)" "$(_ur)"; }

upd_divider() {
    printf '%s  %s%s\n' "$(_udim)" "$(printf '─%.0s' $(seq 1 60))" "$(_ur)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  LOGGING ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g _UPD_LOG_ENABLED=1

upd_log() {
    [[ $_UPD_LOG_ENABLED -eq 0 ]] && return 0
    local level="$1"; shift
    local msg="$*"
    local ts
    ts="$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')"
    mkdir -p "$_UPD_LOG_DIR" 2>/dev/null || true
    printf '[%s] [%-5s] %s\n' "$ts" "$level" "$msg" >> "$_UPD_LOG_FILE" 2>/dev/null || true
}

upd_log_info()  { upd_log "INFO"  "$@"; }
upd_log_warn()  { upd_log "WARN"  "$@"; }
upd_log_error() { upd_log "ERROR" "$@"; }
upd_log_ok()    { upd_log "OK"    "$@"; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  LOCK FILE MANAGEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

upd_lock_acquire() {
    if [[ -f "$_UPD_LOCK_FILE" ]]; then
        local lock_pid
        lock_pid="$(cat "$_UPD_LOCK_FILE" 2>/dev/null || echo '?')"

        if kill -0 "$lock_pid" 2>/dev/null; then
            upd_fail "Another update is running  (PID: ${lock_pid})"
            return 1
        else
            # Stale lock
            rm -f "$_UPD_LOCK_FILE"
        fi
    fi
    printf '%d' "$$" > "$_UPD_LOCK_FILE"
    trap 'rm -f "$_UPD_LOCK_FILE"' EXIT INT TERM
}

upd_lock_release() {
    rm -f "$_UPD_LOCK_FILE" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PROGRESS TRACKER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g  _UPD_TOTAL_STEPS=0
declare -g  _UPD_CURRENT_STEP=0
declare -g  _UPD_START_EPOCH=0
declare -ga _UPD_RESULTS=()

upd_progress_start() {
    _UPD_TOTAL_STEPS="$1"
    _UPD_CURRENT_STEP=0
    _UPD_START_EPOCH="$(date +%s)"
    _UPD_RESULTS=()
}

upd_progress_step() {
    local label="$1"
    (( _UPD_CURRENT_STEP++ )) || true
    local pct=$(( _UPD_CURRENT_STEP * 100 / _UPD_TOTAL_STEPS ))
    local bar_w=30
    local filled=$(( pct * bar_w / 100 ))
    local empty=$(( bar_w - filled ))

    printf '\r  %s[%s%s%s%s]%s  %s%3d%%%s  %s%-30s%s  ' \
        "$(_udim)" \
        "$(_ugreen)" "$(printf '█%.0s' $(seq 1 $filled))" \
        "$(_udim)"  "$(printf '░%.0s' $(seq 1 $empty))" \
        "$(_ur)" \
        "$(_ubold)" "$pct" "$(_ur)" \
        "$(_usky)" "${label:0:29}" "$(_ur)"
}

upd_progress_finish() {
    local elapsed=$(( $(date +%s) - _UPD_START_EPOCH ))
    printf '\r  %s%-70s%s\n' "$(_udim)" "" "$(_ur)"
    printf '\n  %s✓ Completed in %ds%s\n' "$(_ugreen)$(_ubold)" "$elapsed" "$(_ur)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RESULT TRACKING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g  _UPD_PASS_COUNT=0
declare -g  _UPD_FAIL_COUNT=0
declare -g  _UPD_SKIP_COUNT=0
declare -ga _UPD_FAILED_LIST=()

upd_result_pass() {
    (( _UPD_PASS_COUNT++ )) || true
    _UPD_RESULTS+=("PASS:$1")
    upd_log_ok "$1"
}

upd_result_fail() {
    (( _UPD_FAIL_COUNT++ )) || true
    _UPD_RESULTS+=("FAIL:$1")
    _UPD_FAILED_LIST+=("$1")
    upd_log_error "$1"
}

upd_result_skip() {
    (( _UPD_SKIP_COUNT++ )) || true
    _UPD_RESULTS+=("SKIP:$1")
    upd_log_info "SKIP: $1"
}

upd_summary_report() {
    local elapsed="${1:-0}"

    printf '\n'
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\033[1;38;2;203;166;247m'
        printf '  ╔══════════════════════════════════════════════════════════╗\n'
        printf '  ║  📊  UPDATE SUMMARY                                       ║\n'
        printf '  ╠══════════════════════════════════════════════════════════╣\n'
        printf '  ║  %s✓ %-4d updated%s  %s○ %-4d skipped%s  %s✗ %-4d failed%s        ║\n' \
            "$(_ugreen)" "$_UPD_PASS_COUNT" "$(_umauve)" \
            "$(_udim)"   "$_UPD_SKIP_COUNT" "$(_umauve)" \
            "$(_ured)"   "$_UPD_FAIL_COUNT" "$(_umauve)"
        printf '  ║  %s⏱  Elapsed: %-4ds%s                                     ║\n' \
            "$(_udim)" "$elapsed" "$(_umauve)"
        printf '  ╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '  SUMMARY: %d updated  •  %d skipped  •  %d failed  •  %ds\n' \
            "$_UPD_PASS_COUNT" "$_UPD_SKIP_COUNT" \
            "$_UPD_FAIL_COUNT" "$elapsed"
    fi

    if [[ ${#_UPD_FAILED_LIST[@]} -gt 0 ]]; then
        printf '\n  %sFailed components:%s\n' "$(_ured)" "$(_ur)"
        for f in "${_UPD_FAILED_LIST[@]}"; do
            printf '    %s•%s  %s\n' "$(_ured)" "$(_ur)" "$f"
        done
    fi

    upd_log_info "Summary: pass=$_UPD_PASS_COUNT skip=$_UPD_SKIP_COUNT fail=$_UPD_FAIL_COUNT elapsed=${elapsed}s"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PACKAGE MANAGER DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g _UPD_PKG_MANAGER=""
declare -g _UPD_AUR_HELPER=""

upd_detect_pkg_manager() {
    if command -v paru  &>/dev/null; then _UPD_AUR_HELPER="paru"
    elif command -v yay &>/dev/null; then _UPD_AUR_HELPER="yay"
    fi

    if command -v pacman &>/dev/null; then
        _UPD_PKG_MANAGER="pacman"
    elif command -v dnf   &>/dev/null; then _UPD_PKG_MANAGER="dnf"
    elif command -v zypper &>/dev/null; then _UPD_PKG_MANAGER="zypper"
    elif command -v xbps-install &>/dev/null; then _UPD_PKG_MANAGER="xbps"
    elif command -v nix-env &>/dev/null; then _UPD_PKG_MANAGER="nix"
    elif command -v apt   &>/dev/null; then _UPD_PKG_MANAGER="apt"
    fi

    upd_log_info "pkg_manager=${_UPD_PKG_MANAGER} aur_helper=${_UPD_AUR_HELPER}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SUB-COMMAND LOADER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_upd_load_sub() {
    local sub="$1"
    local sub_file="${_UPD_CMD_DIR}/${sub}.sh"

    if [[ ! -f "$sub_file" ]]; then
        printf '\n%s✗  update sub-command not found: %s%s\n\n' \
            "$(_ured)" "$sub" "$(_ur)" >&2
        return 1
    fi

    # shellcheck source=/dev/null
    source "$sub_file"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_upd_help() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;166;227;161m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🔄  ASH  ─  update  (Component Update Manager)          ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    local cc="$(_usky)"  cd="$(_udim)"  cs="$(_umauve)"  cr="$(_ur)"

    printf '\n%sUSAGE%s\n' "$(_ubold)" "$cr"
    printf '   ash update [sub-command] [flags]\n\n'

    printf '%sSUB-COMMANDS%s\n\n' "$cs" "$cr"

    local -a cmds=(
        "all:🚀:Update ALL components (system + dotfiles + plugins + themes)"
        "system:💻:System packages via pacman/paru/dnf/apt"
        "dotfiles:📁:ASH dotfiles repository (git pull + rebuild)"
        "plugins:🔌:All ASH plugins"
        "themes:🎨:Theme library and presets"
        "nvim:📝:Neovim + Lazy.nvim plugins + Mason packages"
        "fish:🐟:Fish shell + Fisher plugins + functions"
        "flatpak:📦:Flatpak applications"
        "check:🔍:Check for available updates (no install)"
        "rollback:⏪:Rollback to last pre-update snapshot"
    )

    for entry in "${cmds[@]}"; do
        IFS=':' read -r cmd icon desc <<< "$entry"
        printf '   %s%s %-14s%s  %s%s%s\n' \
            "$cc" "$icon" "$cmd" "$cr" "$cd" "$desc" "$cr"
    done

    printf '\n%sFLAGS%s\n' "$cs" "$cr"
    printf '   %s--yes/-y%s       Skip all confirmation prompts\n'    "$cc" "$cr"
    printf '   %s--dry-run/-n%s   Preview updates without applying\n' "$cc" "$cr"
    printf '   %s--no-snapshot%s  Skip pre-update snapshot\n'         "$cc" "$cr"
    printf '   %s--verbose/-v%s   Show detailed package output\n'     "$cc" "$cr"
    printf '   %s--no-notify%s    Disable desktop notifications\n'    "$cc" "$cr"

    printf '\n%sEXAMPLES%s\n' "$cs" "$cr"
    printf '   %sash update all%s              Update everything\n'           "$cc" "$cr"
    printf '   %sash update system -y%s        System update no-confirm\n'   "$cc" "$cr"
    printf '   %sash update check%s            What needs updating?\n'        "$cc" "$cr"
    printf '   %sash update rollback%s         Undo last update\n'            "$cc" "$cr"
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN DISPATCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_cmd_update() {
    local sub="${1:-all}"
    shift || true

    # Parse global update flags
    local -a fwd_args=()
    for arg in "${@:-}"; do
        case "$arg" in
            --yes|-y)          export ASH_UPD_YES=1       ;;
            --dry-run|-n)      export ASH_UPD_DRY=1       ;;
            --no-snapshot)     export ASH_UPD_NO_SNAP=1   ;;
            --verbose|-v)      export ASH_UPD_VERBOSE=1   ;;
            --no-notify)       export ASH_UPD_NO_NOTIFY=1 ;;
            *)                 fwd_args+=("$arg")         ;;
        esac
    done

    # Init
    upd_detect_pkg_manager
    mkdir -p "$_UPD_LOG_DIR" 2>/dev/null || true

    case "$sub" in
        help|-h|--help) _upd_help ;;

        all|system|dotfiles|plugins|themes|nvim|fish|flatpak|check|rollback)
            _upd_load_sub "$sub" || return 1
            local fn="ash_update_${sub//-/_}"
            declare -f "$fn" &>/dev/null && \
                "$fn" "${fwd_args[@]:-}" || {
                ash_log_error "Function not found: ${fn}"
                return 1
            }
            ;;
        *)
            printf '\n%s✗  Unknown sub-command: %s%s\n' \
                "$(_ured)" "$sub" "$(_ur)" >&2
            printf '%sRun: ash update help%s\n\n' "$(_udim)" "$(_ur)" >&2
            return 1
            ;;
    esac
}
