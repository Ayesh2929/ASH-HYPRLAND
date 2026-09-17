#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██████╗  ██████╗ ██╗    ██╗███████╗██████╗                                     ║
# ║  ██╔══██╗██╔═══██╗██║    ██║██╔════╝██╔══██╗                                    ║
# ║  ██████╔╝██║   ██║██║ █╗ ██║█████╗  ██████╔╝                                    ║
# ║  ██╔═══╝ ██║   ██║██║███╗██║██╔══╝  ██╔══██╗                                    ║
# ║  ██║     ╚██████╔╝╚███╔███╔╝███████╗██║  ██║                                    ║
# ║  ╚═╝      ╚═════╝  ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝                                    ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  POWER COMMAND DISPATCHER                                ║
# ║  Complete power management hub with safety guards and animations                ║
# ║                                                                                  ║
# ║  Author   : ash-dotfiles                                                         ║
# ║  License  : MIT                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CMD_POWER_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CMD_POWER_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _PWR_CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -gr _PWR_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash/power"
declare -gr _PWR_LOG_FILE="${_PWR_STATE_DIR}/power.log"
declare -gr _PWR_HOOKS_DIR="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}/scripts/hooks"

# Default countdown (override via ASH_PWR_COUNTDOWN)
declare -g  PWR_COUNTDOWN="${ASH_PWR_COUNTDOWN:-5}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CATPPUCCIN MOCHA PALETTE  (inline — zero external deps)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_pw()      { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_pwr()     { _pw '\033[0m';                          }
_pwbold()  { _pw '\033[1m';                          }
_pwdim()   { _pw '\033[38;2;108;112;134m';           }
_pwmauve() { _pw '\033[1;38;2;203;166;247m';         }
_pwblue()  { _pw '\033[38;2;137;180;250m';           }
_pwgreen() { _pw '\033[38;2;166;227;161m';           }
_pwpeach() { _pw '\033[38;2;250;179;135m';           }
_pwyellow(){ _pw '\033[1;38;2;249;226;175m';         }
_pwred()   { _pw '\033[1;38;2;243;139;168m';         }
_pwteal()  { _pw '\033[38;2;148;226;213m';           }
_pwsky()   { _pw '\033[38;2;137;220;235m';           }
_pwlav()   { _pw '\033[38;2;180;190;254m';           }
_pwpink()  { _pw '\033[38;2;245;194;231m';           }
_pwsapph() { _pw '\033[38;2;116;199;236m';           }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SHARED DISPLAY PRIMITIVES  (exported for sub-commands)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pwr_section() {
    local icon="$1"  title="$2"  color="${3:-$(_pwmauve)}"
    printf '\n%s%s  %s%s\n' "$color" "$icon" "$title" "$(_pwr)"
    printf '%s  %s%s\n' "$(_pwdim)" "$(printf '─%.0s' $(seq 1 58))" "$(_pwr)"
}

pwr_kv() {
    local key="$1"  val="$2"  vc="${3:-$(_pwgreen)}"
    printf '  %s%-26s%s %s%s%s\n' \
        "$(_pwdim)" "${key}:" "$(_pwr)" "$vc" "$val" "$(_pwr)"
}

pwr_ok()    { printf '  %s✓%s  %s\n' "$(_pwgreen)"  "$(_pwr)" "$1"; }
pwr_fail()  { printf '  %s✗%s  %s\n' "$(_pwred)"    "$(_pwr)" "$1"; }
pwr_info()  { printf '  %sℹ%s  %s\n' "$(_pwdim)"    "$(_pwr)" "$1"; }
pwr_warn()  { printf '  %s⚠%s  %s\n' "$(_pwyellow)" "$(_pwr)" "$1"; }
pwr_step()  { printf '  %s→%s  %s\n' "$(_pwteal)"   "$(_pwr)" "$1"; }

pwr_divider() {
    printf '%s  %s%s\n' "$(_pwdim)" "$(printf '─%.0s' $(seq 1 60))" "$(_pwr)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  LOGGING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pwr_log() {
    local action="$1"  status="${2:-ok}"
    local ts
    ts="$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')"
    mkdir -p "$_PWR_STATE_DIR" 2>/dev/null || true
    printf '[%s] [%-8s] %s  (user=%s host=%s)\n' \
        "$ts" "$status" "$action" "${USER:-?}" "$(hostname 2>/dev/null || echo '?')" \
        >> "$_PWR_LOG_FILE" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SYSTEMD / LOGINCTL BACKEND
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pwr_systemctl() {
    local action="$1"
    if command -v systemctl &>/dev/null; then
        sudo systemctl "$action" 2>/dev/null && return 0
    fi
    if command -v loginctl &>/dev/null; then
        loginctl "$action" 2>/dev/null && return 0
    fi
    return 1
}

pwr_can_action() {
    local action="$1"
    local check_cmd=""
    case "$action" in
        suspend)    check_cmd="CanSuspend"   ;;
        hibernate)  check_cmd="CanHibernate" ;;
        reboot)     check_cmd="CanReboot"    ;;
        poweroff)   check_cmd="CanPowerOff"  ;;
    esac

    [[ -z "$check_cmd" ]] && return 0

    if command -v systemctl &>/dev/null; then
        local result
        result="$(systemctl "$check_cmd" 2>/dev/null || echo 'no')"
        [[ "$result" == "yes" ]]
    else
        return 0
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  ANIMATED COUNTDOWN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pwr_countdown() {
    local action="$1"
    local seconds="${2:-$PWR_COUNTDOWN}"
    local icon="${3:-⚡}"
    local color="${4:-$(_pwred)}"

    [[ $seconds -le 0 ]] && return 0

    printf '\n'

    local bar_width=30
    tput civis 2>/dev/null || true
    trap 'tput cnorm 2>/dev/null; printf "\n"; exit 130' INT TERM

    for (( i=seconds; i>0; i-- )); do
        local filled=$(( (seconds - i + 1) * bar_width / seconds ))
        local empty=$(( bar_width - filled ))

        # Arc progress animation frames
        local arc_frames=( '◷' '◶' '◵' '◴' )
        local arc_idx=$(( (seconds - i) % ${#arc_frames[@]} ))
        local arc="${arc_frames[$arc_idx]}"

        # Bar render
        local bar="${color}$(printf '█%.0s' $(seq 1 $filled))$(_pwdim)$(printf '░%.0s' $(seq 1 $empty))$(_pwr)"

        printf '\r  %s%s%s  %s%s%s in %s%s%d%s seconds  [%s]  ' \
            "$color" "$arc" "$(_pwr)" \
            "$color$(_pwbold)" "$icon $action" "$(_pwr)" \
            "$(_pwbold)$color" "" "$i" "$(_pwr)" \
            "$bar"

        sleep 1
    done

    tput cnorm 2>/dev/null || true
    trap - INT TERM
    printf '\r  %s%s  Executing: %s%s%-30s%s\n' \
        "$color" "$icon" "$(_pwbold)" "$color" "$action" "$(_pwr)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CONFIRMATION PROMPT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pwr_confirm() {
    local action="$1"  icon="${2:-⚡}"  color="${3:-$(_pwred)}"

    [[ "${ASH_FLAG_YES:-0}" -eq 1 ]] && return 0

    printf '\n  %s%s  %s%s%s?\n\n' \
        "$color$(_pwbold)" "$icon" "" "$action" "$(_pwr)"
    printf '  %s[Y/n] → %s' "$(_pwdim)" "$(_pwr)"

    local ans
    read -r ans

    case "${ans,,}" in
        y|yes|"") return 0 ;;
        n|no)
            pwr_info "Action cancelled by user"
            return 1
            ;;
        *)
            pwr_info "Action cancelled"
            return 1
            ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PRE/POST HOOKS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pwr_run_hook() {
    local hook_name="$1"
    local hook_file="${_PWR_HOOKS_DIR}/${hook_name}.sh"

    [[ "${ASH_FLAG_NO_HOOKS:-0}" -eq 1 ]] && return 0
    [[ -f "$hook_file" ]] && [[ -x "$hook_file" ]] || return 0

    pwr_step "Running hook: ${hook_name}..."
    bash "$hook_file" 2>/dev/null && \
        pwr_ok "Hook complete: ${hook_name}" || \
        pwr_warn "Hook failed: ${hook_name} (continuing)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  NOTIFICATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pwr_notify() {
    local title="$1"  body="$2"  urgency="${3:-normal}"
    [[ "${ASH_PWR_NO_NOTIFY:-0}" -eq 1 ]] && return 0
    command -v notify-send &>/dev/null || return 0
    notify-send "$title" "$body" \
        --urgency="$urgency" \
        --icon=system-shutdown-symbolic \
        --expire-time=3000 \
        2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  UNSAVED WORK DETECTOR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pwr_check_unsaved() {
    local found_unsaved=0

    # Check for unsaved files in editors
    if pgrep -x nvim &>/dev/null; then
        pwr_warn "Neovim is running — check for unsaved files"
        (( found_unsaved++ )) || true
    fi

    if pgrep -x vim &>/dev/null || pgrep -x vi &>/dev/null; then
        pwr_warn "Vim is running — check for unsaved files"
        (( found_unsaved++ )) || true
    fi

    # Check running background jobs
    local bg_jobs
    bg_jobs="$(jobs -r 2>/dev/null | wc -l)"
    if (( bg_jobs > 0 )); then
        pwr_warn "${bg_jobs} background job(s) running in this shell"
        (( found_unsaved++ )) || true
    fi

    # Check ongoing downloads (wget, curl)
    for downloader in wget curl aria2c; do
        pgrep -x "$downloader" &>/dev/null 2>&1 && {
            pwr_warn "Active download detected: ${downloader}"
            (( found_unsaved++ )) || true
        }
    done

    return $found_unsaved
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SYSTEM INFO SNAPSHOT  (shown before power actions)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pwr_system_snapshot() {
    local uptime_s
    uptime_s="$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo 0)"
    local uptime_str=""
    local days=$(( uptime_s / 86400 ))
    local hours=$(( (uptime_s % 86400) / 3600 ))
    local mins=$(( (uptime_s % 3600) / 60 ))
    (( days  > 0 )) && uptime_str+="${days}d "
    (( hours > 0 )) && uptime_str+="${hours}h "
    uptime_str+="${mins}m"

    local mem_used mem_total mem_pct
    if [[ -f /proc/meminfo ]]; then
        mem_total="$(awk '/^MemTotal:/{print $2}' /proc/meminfo)"
        local mem_avail
        mem_avail="$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)"
        mem_used=$(( mem_total - mem_avail ))
        mem_pct=$(( mem_used * 100 / mem_total ))
    fi

    local load_avg
    load_avg="$(cut -d' ' -f1 /proc/loadavg 2>/dev/null)"

    local battery_info=""
    for bat in /sys/class/power_supply/BAT*/; do
        [[ -d "$bat" ]] || continue
        local bat_pct bat_status
        bat_pct="$(cat "${bat}capacity" 2>/dev/null || echo '?')"
        bat_status="$(cat "${bat}status" 2>/dev/null || echo '?')"
        battery_info="${bat_pct}%  (${bat_status})"
        break
    done

    pwr_section "💻" "System Snapshot" "$(_pwdim)"
    pwr_kv "Uptime"   "$uptime_str"
    pwr_kv "Load avg" "${load_avg:-?}"
    [[ -n "${mem_pct:-}" ]] && \
        pwr_kv "Memory" "${mem_pct}%  ($(( mem_used / 1024 ))/$(( mem_total / 1024 ))MB)"
    [[ -n "$battery_info" ]] && pwr_kv "Battery" "$battery_info"
    pwr_kv "User"   "${USER:-?}  @  $(hostname 2>/dev/null || echo '?')"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SUB-COMMAND LOADER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_pwr_load_sub() {
    local sub="$1"
    local sub_file="${_PWR_CMD_DIR}/${sub}.sh"
    if [[ ! -f "$sub_file" ]]; then
        printf '\n%s✗  power sub-command not found: %s%s\n\n' \
            "$(_pwred)" "$sub" "$(_pwr)" >&2
        return 1
    fi
    # shellcheck source=/dev/null
    source "$sub_file"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_pwr_help() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;243;139;168m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  ⚡  ASH  ─  power  (Power Management)                   ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    local cc="$(_pwsky)"  cd="$(_pwdim)"  cs="$(_pwmauve)"  cr="$(_pwr)"

    printf '\n%sUSAGE%s\n' "$(_pwbold)" "$cr"
    printf '   ash power [sub-command] [flags]\n'
    printf '   ash pw [sub-command] [flags]          (alias)\n\n'

    printf '%sSUB-COMMANDS%s\n\n' "$cs" "$cr"

    local -a cmds=(
        "menu:🔋:Interactive power menu (rofi / TUI)"
        "lock:🔒:Lock screen (hyprlock / swaylock / i3lock)"
        "suspend:💤:Suspend to RAM (sleep)"
        "hibernate:❄️ :Hibernate to disk (suspend-to-disk)"
        "shutdown:🔴:Power off the system"
        "reboot:🔁:Restart the system"
        "logout:🚪:Log out of current session"
    )

    for entry in "${cmds[@]}"; do
        IFS=':' read -r cmd icon desc <<< "$entry"
        printf '   %s%s %-12s%s  %s%s%s\n' \
            "$cc" "$icon" "$cmd" "$cr" "$cd" "$desc" "$cr"
    done

    printf '\n%sFLAGS%s\n' "$cs" "$cr"
    printf '   %s--yes/-y%s         Skip confirmation prompt\n'     "$cc" "$cr"
    printf '   %s--now%s            Execute immediately (no countdown)\n' "$cc" "$cr"
    printf '   %s--countdown=N%s    Custom countdown (default: 5s)\n' "$cc" "$cr"
    printf '   %s--no-hooks%s       Skip pre/post hooks\n'          "$cc" "$cr"
    printf '   %s--no-notify%s      Suppress desktop notifications\n' "$cc" "$cr"
    printf '   %s--force/-f%s       Force action (skip safety checks)\n' "$cc" "$cr"

    printf '\n%sEXAMPLES%s\n' "$cs" "$cr"
    printf '   %sash power menu%s              Interactive power menu\n'    "$cc" "$cr"
    printf '   %sash power lock%s              Lock screen immediately\n'  "$cc" "$cr"
    printf '   %sash power shutdown --yes%s    Shutdown without prompt\n'  "$cc" "$cr"
    printf '   %sash power reboot --now%s      Reboot without countdown\n' "$cc" "$cr"
    printf '   %sash power suspend%s           Suspend to RAM\n'          "$cc" "$cr"
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN DISPATCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_cmd_power() {
    local sub="${1:-menu}"
    shift || true

    # Parse global power flags
    local -a fwd_args=()
    for arg in "${@:-}"; do
        case "$arg" in
            --yes|-y)          export ASH_FLAG_YES=1         ;;
            --now)             export PWR_COUNTDOWN=0        ;;
            --countdown=*)     export PWR_COUNTDOWN="${arg#*=}" ;;
            --no-hooks)        export ASH_FLAG_NO_HOOKS=1    ;;
            --no-notify)       export ASH_PWR_NO_NOTIFY=1    ;;
            --force|-f)        export ASH_PWR_FORCE=1        ;;
            *)                 fwd_args+=("$arg")            ;;
        esac
    done

    mkdir -p "$_PWR_STATE_DIR" 2>/dev/null || true

    case "$sub" in
        help|-h|--help) _pwr_help ;;

        menu|lock|suspend|hibernate|shutdown|reboot|logout)
            _pwr_load_sub "$sub" || return 1
            local fn="ash_power_${sub}"
            declare -f "$fn" &>/dev/null && \
                "$fn" "${fwd_args[@]:-}" || {
                pwr_fail "Function not found: ${fn}"
                return 1
            }
            ;;
        *)
            printf '\n%s✗  Unknown sub-command: %s%s\n' \
                "$(_pwred)" "$sub" "$(_pwr)" >&2
            printf '%sRun: ash power help%s\n\n' "$(_pwdim)" "$(_pwr)" >&2
            return 1
            ;;
    esac
}

# Alias
ash_cmd_pw() { ash_cmd_power "$@"; }
