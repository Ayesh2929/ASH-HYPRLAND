#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██████╗  █████╗ ██████╗                                                         ║
# ║  ██╔══██╗██╔══██╗██╔══██╗                                                        ║
# ║  ██████╔╝███████║██████╔╝                                                        ║
# ║  ██╔══██╗██╔══██║██╔══██╗                                                        ║
# ║  ██████╔╝██║  ██║██║  ██║                                                        ║
# ║  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝                                                        ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  BAR COMMAND DISPATCHER                                  ║
# ║  Waybar / AGS / EWW management hub with live monitoring                         ║
# ║                                                                                  ║
# ║  Author   : ash-dotfiles                                                         ║
# ║  License  : MIT                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CMD_BAR_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CMD_BAR_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _BAR_CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -gr _BAR_ASH_ROOT="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}"
declare -gr _BAR_CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
declare -gr _BAR_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash/bar"
declare -gr _BAR_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ash/bar"

# Known bar backends
declare -gA _BAR_BACKEND_PROCS=(
    [waybar]="waybar"
    [ags]="ags"
    [eww]="eww"
    [polybar]="polybar"
    [lemonbar]="lemonbar"
    [ironbar]="ironbar"
)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CATPPUCCIN MOCHA PALETTE  (inline — zero external deps)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_b()       { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_br()      { _b '\033[0m';                          }
_bbold()   { _b '\033[1m';                          }
_bdim()    { _b '\033[38;2;108;112;134m';           }
_bmauve()  { _b '\033[1;38;2;203;166;247m';         }
_bblue()   { _b '\033[38;2;137;180;250m';           }
_bgreen()  { _b '\033[38;2;166;227;161m';           }
_bpeach()  { _b '\033[38;2;250;179;135m';           }
_byellow() { _b '\033[1;38;2;249;226;175m';         }
_bred()    { _b '\033[1;38;2;243;139;168m';         }
_bteal()   { _b '\033[38;2;148;226;213m';           }
_bsky()    { _b '\033[38;2;137;220;235m';           }
_blav()    { _b '\033[38;2;180;190;254m';           }
_bpink()   { _b '\033[38;2;245;194;231m';           }
_bsapph()  { _b '\033[38;2;116;199;236m';           }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SHARED DISPLAY PRIMITIVES  (exported to sub-commands)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

bar_section() {
    local icon="$1"  title="$2"  color="${3:-$(_bmauve)}"
    printf '\n%s%s  %s%s\n' "$color" "$icon" "$title" "$(_br)"
    printf '%s  %s%s\n' "$(_bdim)" "$(printf '─%.0s' $(seq 1 58))" "$(_br)"
}

bar_kv() {
    local key="$1"  val="$2"  vc="${3:-$(_bgreen)}"
    printf '  %s%-26s%s %s%s%s\n' \
        "$(_bdim)" "${key}:" "$(_br)" "$vc" "$val" "$(_br)"
}

bar_ok()    { printf '  %s✓%s  %s\n' "$(_bgreen)"  "$(_br)" "$1"; }
bar_fail()  { printf '  %s✗%s  %s\n' "$(_bred)"    "$(_br)" "$1"; }
bar_info()  { printf '  %sℹ%s  %s\n' "$(_bdim)"    "$(_br)" "$1"; }
bar_warn()  { printf '  %s⚠%s  %s\n' "$(_byellow)" "$(_br)" "$1"; }
bar_step()  { printf '  %s→%s  %s\n' "$(_bteal)"   "$(_br)" "$1"; }

bar_divider() {
    printf '%s  %s%s\n' "$(_bdim)" "$(printf '─%.0s' $(seq 1 60))" "$(_br)"
}

# Status indicator badge
bar_badge() {
    local text="$1"  color="${2:-$(_bblue)}"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '%s%s\033[38;2;30;30;46m %s \033[0m' \
            "$(_bbold)" "$color" "$text"
    else
        printf '[%s]' "$text"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BACKEND DETECTION & STATUS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g BAR_BACKEND=""
declare -g BAR_PID=""

bar_detect_backend() {
    BAR_BACKEND=""
    BAR_PID=""

    for backend in waybar ags eww polybar ironbar lemonbar; do
        local proc="${_BAR_BACKEND_PROCS[$backend]:-$backend}"
        local pid
        pid="$(pgrep -x "$proc" 2>/dev/null | head -1 || echo '')"

        if [[ -n "$pid" ]]; then
            BAR_BACKEND="$backend"
            BAR_PID="$pid"
            break
        fi
    done

    # Check saved preference
    local pref_file="${_BAR_STATE_DIR}/preferred-backend"
    if [[ -z "$BAR_BACKEND" ]] && [[ -f "$pref_file" ]]; then
        BAR_BACKEND="$(cat "$pref_file" 2>/dev/null || echo 'waybar')"
    fi

    [[ -z "$BAR_BACKEND" ]] && BAR_BACKEND="waybar"
}

bar_is_running() {
    local backend="${1:-$BAR_BACKEND}"
    local proc="${_BAR_BACKEND_PROCS[$backend]:-$backend}"
    pgrep -x "$proc" &>/dev/null 2>&1
}

bar_get_config_dir() {
    local backend="${1:-$BAR_BACKEND}"
    case "$backend" in
        waybar)  printf '%s/waybar' "$_BAR_CFG_DIR" ;;
        ags)     printf '%s/ags'    "$_BAR_CFG_DIR" ;;
        eww)     printf '%s/eww'    "$_BAR_CFG_DIR" ;;
        polybar) printf '%s/polybar' "$_BAR_CFG_DIR" ;;
        *)       printf '%s/%s' "$_BAR_CFG_DIR" "$backend" ;;
    esac
}

bar_get_uptime() {
    local pid="${1:-$BAR_PID}"
    [[ -z "$pid" ]] && { printf '?'; return; }

    local start_time
    start_time="$(stat -c '%Y' "/proc/${pid}" 2>/dev/null || echo '0')"
    local now
    now="$(date +%s)"
    local seconds=$(( now - start_time ))

    if   (( seconds >= 3600 )); then printf '%dh %dm' "$(( seconds/3600 ))" "$(( (seconds%3600)/60 ))"
    elif (( seconds >= 60   )); then printf '%dm %ds' "$(( seconds/60 ))" "$(( seconds%60 ))"
    else                             printf '%ds' "$seconds"
    fi
}

bar_get_cpu_mem() {
    local pid="${1:-$BAR_PID}"
    [[ -z "$pid" ]] && { printf '? ?'; return; }

    local cpu mem
    cpu="$(ps -p "$pid" -o %cpu --no-headers 2>/dev/null | tr -d ' ' || echo '?')"
    mem="$(ps -p "$pid" -o rss  --no-headers 2>/dev/null | \
           awk '{printf "%.1f MB", $1/1024}' || echo '?')"
    printf '%s %s' "$cpu" "$mem"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME INIT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

bar_ensure_dirs() {
    mkdir -p "$_BAR_STATE_DIR" "$_BAR_CACHE_DIR" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SUB-COMMAND LOADER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bar_load_sub() {
    local sub="$1"
    local sub_file="${_BAR_CMD_DIR}/${sub}.sh"
    if [[ ! -f "$sub_file" ]]; then
        printf '\n%s✗  bar sub-command not found: %s%s\n\n' \
            "$(_bred)" "$sub" "$(_br)" >&2
        return 1
    fi
    # shellcheck source=/dev/null
    source "$sub_file"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  NOTIFICATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

bar_notify() {
    local title="$1"  body="$2"
    [[ "${ASH_BAR_NO_NOTIFY:-0}" -eq 1 ]] && return 0
    command -v notify-send &>/dev/null || return 0
    notify-send "$title" "$body" --icon=view-paned-symbolic 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bar_help() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;137;180;250m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  📊  ASH  ─  bar  (Status Bar Manager)                   ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    local cc="$(_bsky)"  cd="$(_bdim)"  cs="$(_bmauve)"  cr="$(_br)"

    printf '\n%sUSAGE%s\n' "$(_bbold)" "$cr"
    printf '   ash bar [sub-command] [flags]\n\n'

    printf '%sSUB-COMMANDS%s\n\n' "$cs" "$cr"

    local -a cmds=(
        "status:📊:Show current bar status, PID, memory, uptime"
        "layout:🗂️ :Switch bar layout (top/bottom/left/right/floating)"
        "toggle:👁️ :Toggle bar visibility on/off"
        "reload:🔄:Reload bar configuration (hot-reload)"
        "switch:🔀:Switch between bar backends (waybar/ags/eww)"
        "start:▶️ :Start the bar daemon"
        "stop:⏹️ :Stop the bar daemon"
        "restart:🔁:Restart bar (stop + start)"
        "config:⚙️ :Open bar config in editor"
        "logs:📋:Show bar logs (journalctl / stderr)"
    )

    for entry in "${cmds[@]}"; do
        IFS=':' read -r cmd icon desc <<< "$entry"
        printf '   %s%s %-12s%s  %s%s%s\n' \
            "$cc" "$icon" "$cmd" "$cr" "$cd" "$desc" "$cr"
    done

    printf '\n%sBACKENDS%s\n' "$cs" "$cr"
    for backend in waybar ags eww polybar ironbar; do
        local installed=0
        command -v "$backend" &>/dev/null && installed=1
        local status_badge
        if [[ $installed -eq 1 ]]; then
            status_badge="$(bar_badge " installed " "$(_bgreen)")"
        else
            status_badge="$(bar_badge " not found " "$(_bdim)")"
        fi
        printf '   %s%-10s%s  %s\n' "$cc" "$backend" "$cr" "$status_badge"
    done

    printf '\n%sFLAGS%s\n' "$cs" "$cr"
    printf '   %s--backend=NAME%s   Target specific backend\n'    "$cc" "$cr"
    printf '   %s--no-notify%s      Suppress desktop notification\n' "$cc" "$cr"
    printf '   %s--watch/-w%s       Live status (refresh every 2s)\n' "$cc" "$cr"

    printf '\n%sEXAMPLES%s\n' "$cs" "$cr"
    printf '   %sash bar status%s              Show bar status\n'           "$cc" "$cr"
    printf '   %sash bar toggle%s              Hide/show bar\n'             "$cc" "$cr"
    printf '   %sash bar reload%s              Reload config\n'             "$cc" "$cr"
    printf '   %sash bar layout top%s          Move bar to top\n'           "$cc" "$cr"
    printf '   %sash bar switch ags%s          Switch to AGS bar\n'         "$cc" "$cr"
    printf '   %sash bar --watch%s             Live monitoring\n'           "$cc" "$cr"
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  STATUS DISPLAY (used directly + by watch mode)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bar_status_frame() {
    bar_detect_backend

    bar_section "📊" "Bar Status" "$(_bblue)"

    # Backend
    local running_badge
    if bar_is_running "$BAR_BACKEND"; then
        running_badge="$(bar_badge " RUNNING " "$(_bgreen)")"
    else
        running_badge="$(bar_badge " STOPPED " "$(_bred)")"
    fi

    bar_kv "Backend"  "$BAR_BACKEND  ${running_badge}"
    bar_kv "Config"   "$(bar_get_config_dir)"

    if bar_is_running "$BAR_BACKEND"; then
        local pid
        pid="$(pgrep -x "${_BAR_BACKEND_PROCS[$BAR_BACKEND]:-$BAR_BACKEND}" | head -1)"

        bar_kv "PID"     "$pid"
        bar_kv "Uptime"  "$(bar_get_uptime "$pid")"

        local cpu_mem
        cpu_mem="$(bar_get_cpu_mem "$pid")"
        local cpu="${cpu_mem% *}"
        local mem="${cpu_mem#* }"
        bar_kv "CPU"     "${cpu}%"
        bar_kv "Memory"  "$mem"

        # Waybar-specific: IPC info
        if [[ "$BAR_BACKEND" == "waybar" ]]; then
            local wb_socket="${XDG_RUNTIME_DIR:-/tmp}/waybar.socket"
            [[ -S "$wb_socket" ]] && bar_kv "IPC socket" "$wb_socket"
        fi

        # Config validation
        case "$BAR_BACKEND" in
            waybar)
                local wb_cfg="${_BAR_CFG_DIR}/waybar/config.jsonc"
                if [[ -f "$wb_cfg" ]]; then
                    if python3 -c "import json; json.load(open('${wb_cfg}'))" \
                       &>/dev/null 2>&1; then
                        bar_kv "Config valid" "$(bar_badge " ✓ JSON OK " "$(_bgreen)")"
                    else
                        bar_kv "Config valid" "$(bar_badge " ✗ JSON ERR " "$(_bred)")"
                    fi
                fi
                ;;
        esac
    fi

    # All detected bars
    local -a active_bars=()
    for bk in "${!_BAR_BACKEND_PROCS[@]}"; do
        local proc="${_BAR_BACKEND_PROCS[$bk]}"
        pgrep -x "$proc" &>/dev/null 2>&1 && active_bars+=("$bk")
    done

    if [[ ${#active_bars[@]} -gt 1 ]]; then
        printf '\n  %sMultiple bars running:%s\n' "$(_byellow)" "$(_br)"
        for ab in "${active_bars[@]}"; do
            printf '    %s•%s  %s\n' "$(_byellow)" "$(_br)" "$ab"
        done
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WATCH MODE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bar_watch() {
    local interval="${1:-2}"
    command -v tput &>/dev/null || { bar_fail "tput required for watch mode"; return 1; }

    tput civis 2>/dev/null || true
    trap 'tput cnorm 2>/dev/null; printf "\033[?25h"; exit 0' INT TERM EXIT

    while true; do
        printf '\033[2J\033[H'
        printf '%s  📊 BAR LIVE MONITOR  •  %s  •  Ctrl+C to exit%s\n' \
            "$(_bdim)" "$(date '+%H:%M:%S')" "$(_br)"
        _bar_status_frame
        sleep "$interval"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN DISPATCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_cmd_bar() {
    local sub="${1:-status}"
    shift || true

    # Parse global bar flags
    local watch_mode=0
    local watch_interval=2
    local -a fwd_args=()

    for arg in "${@:-}"; do
        case "$arg" in
            --backend=*)        export BAR_BACKEND="${arg#*=}" ;;
            --no-notify)        export ASH_BAR_NO_NOTIFY=1    ;;
            --watch|-w)         watch_mode=1                   ;;
            --watch=*)          watch_mode=1; watch_interval="${arg#*=}" ;;
            *)                  fwd_args+=("$arg")             ;;
        esac
    done

    bar_ensure_dirs
    bar_detect_backend

    case "$sub" in
        help|-h|--help) _bar_help ;;

        status|info)
            if [[ $watch_mode -eq 1 ]]; then
                _bar_watch "$watch_interval"
            else
                _bar_status_frame
                printf '\n'
            fi
            ;;

        # Inline implementations for simple commands
        start|up)
            bar_section "▶️ " "Start Bar" "$(_bgreen)"
            bar_kv "Backend" "$BAR_BACKEND"

            if bar_is_running "$BAR_BACKEND"; then
                bar_warn "${BAR_BACKEND} already running  (PID: $BAR_PID)"
                printf '\n'; return 0
            fi

            bar_step "Starting ${BAR_BACKEND}..."
            case "$BAR_BACKEND" in
                waybar)
                    waybar &>/dev/null &
                    sleep 0.5
                    pgrep -x waybar &>/dev/null && \
                        bar_ok "Waybar started  (PID: $(pgrep -x waybar | head -1))" || \
                        bar_fail "Failed to start Waybar"
                    ;;
                ags)
                    ags &>/dev/null &
                    sleep 0.3
                    pgrep -x ags &>/dev/null && bar_ok "AGS started" || \
                        bar_fail "Failed to start AGS"
                    ;;
                eww)
                    eww daemon &>/dev/null
                    sleep 0.3
                    eww open bar 2>/dev/null && bar_ok "EWW started" || \
                        bar_fail "Failed to start EWW"
                    ;;
                *)
                    "$BAR_BACKEND" &>/dev/null &
                    sleep 0.3
                    bar_is_running "$BAR_BACKEND" && \
                        bar_ok "${BAR_BACKEND} started" || \
                        bar_fail "Failed to start ${BAR_BACKEND}"
                    ;;
            esac
            bar_notify "📊 Bar Started" "$BAR_BACKEND"
            ;;

        stop|down|kill)
            bar_section "⏹️ " "Stop Bar" "$(_bred)"
            bar_kv "Backend" "$BAR_BACKEND"

            if ! bar_is_running "$BAR_BACKEND"; then
                bar_info "${BAR_BACKEND} is not running"
                printf '\n'; return 0
            fi

            bar_step "Stopping ${BAR_BACKEND}..."
            pkill -x "${_BAR_BACKEND_PROCS[$BAR_BACKEND]:-$BAR_BACKEND}" 2>/dev/null
            sleep 0.3
            bar_is_running "$BAR_BACKEND" && \
                bar_warn "Still running after pkill" || \
                bar_ok "${BAR_BACKEND} stopped"
            bar_notify "📊 Bar Stopped" "$BAR_BACKEND"
            ;;

        restart)
            bar_section "🔁" "Restart Bar" "$(_byellow)"
            ash_cmd_bar stop   "${fwd_args[@]:-}"
            sleep 0.3
            ash_cmd_bar start  "${fwd_args[@]:-}"
            ;;

        config|edit)
            bar_section "⚙️ " "Bar Config" "$(_bpeach)"
            local cfg_dir
            cfg_dir="$(bar_get_config_dir)"
            bar_kv "Config dir" "$cfg_dir"

            local editor="${EDITOR:-${VISUAL:-nvim}}"
            local config_file="${cfg_dir}/config.jsonc"
            [[ -f "${cfg_dir}/config" ]] && config_file="${cfg_dir}/config"

            if [[ -f "$config_file" ]]; then
                bar_step "Opening: ${config_file}"
                "$editor" "$config_file"
            else
                bar_fail "Config file not found: ${config_file}"
            fi
            ;;

        logs|log)
            bar_section "📋" "Bar Logs" "$(_bteal)"
            bar_kv "Backend" "$BAR_BACKEND"

            if command -v journalctl &>/dev/null; then
                journalctl --user --no-pager -u "${BAR_BACKEND}" \
                    --since "1 hour ago" -n 50 2>/dev/null | \
                while IFS= read -r line; do
                    printf '  %s%s%s\n' "$(_bdim)" "$line" "$(_br)"
                done || bar_info "No systemd unit found for ${BAR_BACKEND}"
            else
                bar_info "journalctl not available"
            fi
            ;;

        layout|toggle|reload|switch)
            _bar_load_sub "$sub" || return 1
            local fn="ash_bar_${sub}"
            declare -f "$fn" &>/dev/null && \
                "$fn" "${fwd_args[@]:-}" || {
                bar_fail "Function not found: ${fn}"
                return 1
            }
            ;;

        *)
            printf '\n%s✗  Unknown sub-command: %s%s\n' \
                "$(_bred)" "$sub" "$(_br)" >&2
            printf '%sRun: ash bar help%s\n\n' "$(_bdim)" "$(_br)" >&2
            return 1
            ;;
    esac

    printf '\n'
}
