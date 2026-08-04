#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║   ██████╗  █████╗ ███╗   ███╗██╗███╗   ██╗ ██████╗                              ║
# ║  ██╔════╝ ██╔══██╗████╗ ████║██║████╗  ██║██╔════╝                              ║
# ║  ██║  ███╗███████║██╔████╔██║██║██╔██╗ ██║██║  ███╗                             ║
# ║  ██║   ██║██╔══██║██║╚██╔╝██║██║██║╚██╗██║██║   ██║                             ║
# ║  ╚██████╔╝██║  ██║██║ ╚═╝ ██║██║██║ ╚████║╚██████╔╝                             ║
# ║   ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝                              ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  GAMING COMMAND DISPATCHER                               ║
# ║  Complete gaming hub: performance tuning • Proton • MangoHUD • GameMode         ║
# ║                                                                                  ║
# ║  Author   : ash-dotfiles                                                         ║
# ║  License  : MIT                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CMD_GAMING_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CMD_GAMING_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _GM_CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -gr _GM_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash/gaming"
declare -gr _GM_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ash/gaming"
declare -gr _GM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ash/gaming"
declare -gr _GM_LOG_FILE="${_GM_STATE_DIR}/gaming.log"
declare -gr _GM_ACTIVE_FILE="${_GM_STATE_DIR}/active-mode"

# Proton paths
declare -gr _GM_STEAM_DIR="${HOME}/.steam/steam/steamapps/common"
declare -gr _GM_PROTON_DIR="${HOME}/.steam/root/compatibilitytools.d"
declare -gr _GM_STEAM_COMPAT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/Steam/compatibilitytools.d"

# MangoHUD config
declare -gr _GM_MANGOHUD_CFG="${XDG_CONFIG_HOME:-$HOME/.config}/MangoHud/MangoHud.conf"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CATPPUCCIN MOCHA PALETTE  (inline — zero external deps)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_g()       { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_gr()      { _g '\033[0m';                          }
_gbold()   { _g '\033[1m';                          }
_gdim()    { _g '\033[38;2;108;112;134m';           }
_gmauve()  { _g '\033[1;38;2;203;166;247m';         }
_gblue()   { _g '\033[38;2;137;180;250m';           }
_ggreen()  { _g '\033[38;2;166;227;161m';           }
_gpeach()  { _g '\033[38;2;250;179;135m';           }
_gyellow() { _g '\033[1;38;2;249;226;175m';         }
_gred()    { _g '\033[1;38;2;243;139;168m';         }
_gteal()   { _g '\033[38;2;148;226;213m';           }
_gsky()    { _g '\033[38;2;137;220;235m';           }
_glav()    { _g '\033[38;2;180;190;254m';           }
_gpink()   { _g '\033[38;2;245;194;231m';           }
_gsapph()  { _g '\033[38;2;116;199;236m';           }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SHARED DISPLAY PRIMITIVES  (exported to sub-commands)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

gm_section() {
    local icon="$1"  title="$2"  color="${3:-$(_gmauve)}"
    printf '\n%s%s  %s%s\n' "$color" "$icon" "$title" "$(_gr)"
    printf '%s  %s%s\n' "$(_gdim)" "$(printf '─%.0s' $(seq 1 58))" "$(_gr)"
}

gm_kv() {
    local key="$1"  val="$2"  vc="${3:-$(_ggreen)}"
    printf '  %s%-26s%s %s%s%s\n' \
        "$(_gdim)" "${key}:" "$(_gr)" "$vc" "$val" "$(_gr)"
}

gm_ok()    { printf '  %s✓%s  %s\n' "$(_ggreen)"  "$(_gr)" "$1"; }
gm_fail()  { printf '  %s✗%s  %s\n' "$(_gred)"    "$(_gr)" "$1"; }
gm_info()  { printf '  %sℹ%s  %s\n' "$(_gdim)"    "$(_gr)" "$1"; }
gm_warn()  { printf '  %s⚠%s  %s\n' "$(_gyellow)" "$(_gr)" "$1"; }
gm_step()  { printf '  %s→%s  %s\n' "$(_gteal)"   "$(_gr)" "$1"; }

gm_divider() {
    printf '%s  %s%s\n' "$(_gdim)" "$(printf '─%.0s' $(seq 1 60))" "$(_gr)"
}

gm_badge() {
    local text="$1"  color="${2:-$(_gblue)}"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '%s%s\033[38;2;30;30;46m %s \033[0m' "$(_gbold)" "$color" "$text"
    else
        printf '[%s]' "$text"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  GAMING STATUS SNAPSHOT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

gm_status_frame() {
    gm_section "🎮" "Gaming Status" "$(_gpink)"

    # Active gaming mode
    local active_mode=""
    [[ -f "$_GM_ACTIVE_FILE" ]] && active_mode="$(cat "$_GM_ACTIVE_FILE" 2>/dev/null || echo '')"

    if [[ -n "$active_mode" ]]; then
        gm_kv "Mode"      "$(gm_badge " 🎮 ${active_mode^^} " "$(_gpeach)")"
    else
        gm_kv "Mode"      "$(gm_badge " NORMAL " "$(_gdim)")"
    fi

    # GameMode daemon
    if pgrep -x gamemoded &>/dev/null; then
        gm_kv "GameMode"  "$(gm_badge " ● RUNNING " "$(_ggreen)")"
        local gm_games
        gm_games="$(gamemoded -s 2>/dev/null | grep -oP '\d+ client' || echo '?')"
        [[ -n "$gm_games" ]] && gm_kv "  Clients" "$gm_games"
    else
        gm_kv "GameMode"  "$(gm_badge " ○ STOPPED " "$(_gdim)")"
    fi

    # MangoHUD
    local mango_ver=""
    command -v mangohud &>/dev/null && \
        mango_ver="$(mangohud --version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo 'installed')"
    if [[ -n "$mango_ver" ]]; then
        gm_kv "MangoHUD"  "v${mango_ver}  $(gm_badge " READY " "$(_gteal)")"
    else
        gm_kv "MangoHUD"  "$(gm_badge " NOT INSTALLED " "$(_gdim)")"
    fi

    # Steam
    if pgrep -x steam &>/dev/null || pgrep -f 'steam.sh' &>/dev/null; then
        gm_kv "Steam"     "$(gm_badge " ● RUNNING " "$(_ggreen)")"
    else
        gm_kv "Steam"     "$(gm_badge " ○ STOPPED " "$(_gdim)")"
    fi

    # Proton GE
    local proton_count=0
    for proton_dir in \
        "${_GM_PROTON_DIR}" \
        "${_GM_STEAM_COMPAT_DIR}" \
        "${XDG_DATA_HOME:-$HOME/.local/share}/Steam/compatibilitytools.d"; do
        if [[ -d "$proton_dir" ]]; then
            local cnt
            cnt="$(find "$proton_dir" -maxdepth 1 -name 'GE-Proton*' \
                   -o -name 'Proton*' 2>/dev/null | wc -l)"
            (( proton_count += cnt )) || true
        fi
    done
    gm_kv "Proton GE"  "${proton_count} version(s) installed"

    # GPU info (quick)
    gm_section "🖥️ " "Hardware" "$(_gdim)"
    local gpu_info=""
    gpu_info="$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | \
                sed 's/.*: //' | head -2 | tr '\n' ' ')"
    [[ -n "$gpu_info" ]] && gm_kv "GPU"  "$gpu_info"

    # CPU governor
    local governor
    governor="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo '?')"
    local gov_color
    case "$governor" in
        performance) gov_color="$(_ggreen)" ;;
        schedutil)   gov_color="$(_gteal)"  ;;
        powersave)   gov_color="$(_gred)"   ;;
        *)           gov_color="$(_gdim)"   ;;
    esac
    gm_kv "CPU Governor" "${gov_color}${governor}$(_gr)"

    # Kernel
    gm_kv "Kernel"  "$(uname -r)"

    # Check for gaming-optimized kernel
    if uname -r | grep -qiE 'tkg|zen|liquorix|xanmod|bore|cachy'; then
        gm_ok "Gaming-optimized kernel detected"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  LOGGING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

gm_log() {
    local action="$1"  status="${2:-ok}"
    local ts
    ts="$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')"
    mkdir -p "$_GM_STATE_DIR" 2>/dev/null || true
    printf '[%s] [%-8s] %s\n' "$ts" "$status" "$action" \
        >> "$_GM_LOG_FILE" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  NOTIFICATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

gm_notify() {
    local title="$1"  body="$2"  urgency="${3:-normal}"
    [[ "${ASH_GM_NO_NOTIFY:-0}" -eq 1 ]] && return 0
    command -v notify-send &>/dev/null || return 0
    notify-send "$title" "$body" \
        --urgency="$urgency" \
        --icon=applications-games \
        --expire-time=4000 \
        2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME INIT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

gm_ensure_dirs() {
    mkdir -p "$_GM_STATE_DIR" "$_GM_CACHE_DIR" "$_GM_CONFIG_DIR" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SUB-COMMAND LOADER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_gm_load_sub() {
    local sub="$1"
    local sub_file="${_GM_CMD_DIR}/${sub}.sh"
    if [[ ! -f "$sub_file" ]]; then
        printf '\n%s✗  gaming sub-command not found: %s%s\n\n' \
            "$(_gred)" "$sub" "$(_gr)" >&2
        return 1
    fi
    # shellcheck source=/dev/null
    source "$sub_file"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WATCH MODE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_gm_watch() {
    local interval="${1:-2}"
    command -v tput &>/dev/null || { gm_fail "tput required"; return 1; }
    tput civis 2>/dev/null || true
    trap 'tput cnorm 2>/dev/null; exit 0' INT TERM EXIT
    while true; do
        printf '\033[2J\033[H'
        printf '%s  🎮 GAMING LIVE  •  %s  •  Ctrl+C to exit%s\n' \
            "$(_gdim)" "$(date '+%H:%M:%S')" "$(_gr)"
        gm_status_frame
        sleep "$interval"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_gm_help() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;250;179;135m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🎮  ASH  ─  gaming  (Gaming Performance Hub)            ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    local cc="$(_gsky)"  cd="$(_gdim)"  cs="$(_gmauve)"  cr="$(_gr)"

    printf '\n%sUSAGE%s\n' "$(_gbold)" "$cr"
    printf '   ash gaming [sub-command] [flags]\n\n'

    printf '%sSUB-COMMANDS%s\n\n' "$cs" "$cr"

    local -a cmds=(
        "status:🎮:Gaming mode status overview"
        "optimize:⚡:Apply system gaming optimizations"
        "mangohud:📊:MangoHUD overlay management"
        "proton:🍷:Proton/WINE management and launch"
        "gamemode:🚀:GameMode daemon control"
    )

    for entry in "${cmds[@]}"; do
        IFS=':' read -r cmd icon desc <<< "$entry"
        printf '   %s%s %-14s%s  %s%s%s\n' \
            "$cc" "$icon" "$cmd" "$cr" "$cd" "$desc" "$cr"
    done

    printf '\n%sFLAGS%s\n' "$cs" "$cr"
    printf '   %s--watch/-w%s       Live gaming status monitor\n' "$cc" "$cr"
    printf '   %s--no-notify%s      Suppress notifications\n'     "$cc" "$cr"
    printf '   %s--json%s           JSON output\n'                "$cc" "$cr"

    printf '\n%sEXAMPLES%s\n' "$cs" "$cr"
    printf '   %sash gaming status%s           Overview\n'              "$cc" "$cr"
    printf '   %sash gaming optimize on%s      Enable gaming mode\n'    "$cc" "$cr"
    printf '   %sash gaming optimize off%s     Restore normal mode\n'   "$cc" "$cr"
    printf '   %sash gaming mangohud toggle%s  Toggle HUD overlay\n'   "$cc" "$cr"
    printf '   %sash gaming proton list%s      List Proton versions\n'  "$cc" "$cr"
    printf '   %sash gaming gamemode start%s   Start GameMode\n'       "$cc" "$cr"
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN DISPATCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_cmd_gaming() {
    local sub="${1:-status}"
    shift || true

    local watch_mode=0
    local -a fwd_args=()

    for arg in "${@:-}"; do
        case "$arg" in
            --watch|-w)    watch_mode=1                    ;;
            --no-notify)   export ASH_GM_NO_NOTIFY=1       ;;
            --json)        export ASH_FLAG_JSON_OUTPUT=1   ;;
            *)             fwd_args+=("$arg")              ;;
        esac
    done

    gm_ensure_dirs

    case "$sub" in
        help|-h|--help) _gm_help ;;

        status|info)
            if [[ $watch_mode -eq 1 ]]; then
                _gm_watch 2
            else
                gm_status_frame
                printf '\n'
            fi
            ;;

        optimize|mangohud|proton|gamemode)
            _gm_load_sub "$sub" || return 1
            local fn="ash_gaming_${sub}"
            declare -f "$fn" &>/dev/null && \
                "$fn" "${fwd_args[@]:-}" || {
                gm_fail "Function not found: ${fn}"
                return 1
            }
            ;;
        *)
            printf '\n%s✗  Unknown sub-command: %s%s\n' \
                "$(_gred)" "$sub" "$(_gr)" >&2
            printf '%sRun: ash gaming help%s\n\n' "$(_gdim)" "$(_gr)" >&2
            return 1
            ;;
    esac
}
