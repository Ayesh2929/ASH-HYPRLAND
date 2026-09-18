#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██╗  ██╗██╗    ██╗    ██████╗██╗      ██████╗                                  ║
# ║  ██║  ██║██║    ██║   ██╔════╝██║     ██╔═══██╗                                 ║
# ║  ███████║██║ █╗ ██║   ██║     ██║     ██║   ██║                                 ║
# ║  ██╔══██║██║███╗██║   ██║     ██║     ██║   ██║                                 ║
# ║  ██║  ██║╚███╔███╔╝   ╚██████╗███████╗╚██████╔╝                                 ║
# ║  ╚═╝  ╚═╝ ╚══╝╚══╝     ╚═════╝╚══════╝ ╚═════╝                                  ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  HARDWARE COMMAND DISPATCHER                             ║
# ║  Unified hardware information & diagnostics hub                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CMD_HW_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CMD_HW_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _HW_CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -gr _HW_VERSION="5.0.0-omega"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  COLOUR PALETTE  (Catppuccin Mocha inline)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_hw_nc() { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }

_hw_r()       { _hw_nc $'\033[0m';                         }  # reset
_hw_bold()    { _hw_nc $'\033[1m';                         }
_hw_mauve()   { _hw_nc $'\033[38;2;203;166;247m';          }
_hw_blue()    { _hw_nc $'\033[38;2;137;180;250m';          }
_hw_green()   { _hw_nc $'\033[38;2;166;227;161m';          }
_hw_peach()   { _hw_nc $'\033[38;2;250;179;135m';          }
_hw_yellow()  { _hw_nc $'\033[38;2;249;226;175m';          }
_hw_red()     { _hw_nc $'\033[1;38;2;243;139;168m';        }
_hw_teal()    { _hw_nc $'\033[38;2;148;226;213m';          }
_hw_sky()     { _hw_nc $'\033[38;2;137;220;235m';          }
_hw_dim()     { _hw_nc $'\033[38;2;108;112;134m';          }
_hw_lavender(){ _hw_nc $'\033[38;2;180;190;254m';          }
_hw_pink()    { _hw_nc $'\033[38;2;245;194;231m';          }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SHARED DISPLAY HELPERS  (used by all hw sub-commands)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Section header with icon
hw_section() {
    local icon="$1"
    local title="$2"
    local color="${3:-$(_hw_mauve)}"

    printf '\n%s%s%s  %s%s%s\n' \
        "$color" "$(_hw_bold)" "$icon" "$title" "$(_hw_r)" ""
    printf '%s' "$(_hw_dim)"
    printf '  '; printf '─%.0s' $(seq 1 54)
    printf '%s\n' "$(_hw_r)"
}

# Key-value row
hw_kv() {
    local key="$1"
    local value="$2"
    local unit="${3:-}"
    local color="${4:-$(_hw_green)}"

    printf '  %s%-22s%s %s%s%s%s\n' \
        "$(_hw_dim)" "$key:" "$(_hw_r)" \
        "$color" "$value" \
        "$( [[ -n "$unit" ]] && printf ' %s%s' "$(_hw_dim)" "$unit" || true)" \
        "$(_hw_r)"
}

# Progress bar with label
hw_bar() {
    local label="$1"
    local pct="$2"    # 0-100
    local unit="${3:-}"
    local width="${4:-28}"

    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))

    local bar_color
    if   (( pct >= 90 )); then bar_color="$(_hw_red)"
    elif (( pct >= 75 )); then bar_color="$(_hw_yellow)"
    elif (( pct >= 50 )); then bar_color="$(_hw_peach)"
    else                       bar_color="$(_hw_green)"
    fi

    local bar=""
    local i
    for (( i=0; i<filled; i++ )); do bar+='█'; done
    for (( i=0; i<empty;  i++ )); do bar+='░'; done

    printf '  %s%-22s%s %s%s%s %s%3d%%%s %s%s%s\n' \
        "$(_hw_dim)" "${label}:" "$(_hw_r)" \
        "$bar_color" "$bar" "$(_hw_r)" \
        "$(_hw_bold)" "$pct" "$(_hw_r)" \
        "$(_hw_dim)" "$unit" "$(_hw_r)"
}

# Temperature with color coding
hw_temp() {
    local label="$1"
    local temp_c="$2"
    local warn="${3:-75}"
    local crit="${4:-90}"

    local temp_color
    if   (( temp_c >= crit )); then temp_color="$(_hw_red)"
    elif (( temp_c >= warn )); then temp_color="$(_hw_yellow)"
    else                            temp_color="$(_hw_green)"
    fi

    local temp_icon
    if   (( temp_c >= crit )); then temp_icon="🔥"
    elif (( temp_c >= warn )); then temp_icon="🌡"
    else                            temp_icon="❄"
    fi

    printf '  %s%-22s%s %s%s%d°C%s %s\n' \
        "$(_hw_dim)" "${label}:" "$(_hw_r)" \
        "$temp_color" "$(_hw_bold)" "$temp_c" "$(_hw_r)" \
        "$temp_icon"
}

# Badge chip
hw_badge() {
    local text="$1"
    local bg="${2:-$(_hw_mauve)}"
    printf '%s%s \033[38;2;30;30;46m%s %s\033[0m' "$(_hw_bold)" "$bg" "$text" "$(_hw_r)"
}

# Divide two integers, printing <scale> decimal places — no bc required.
# hw_div <numerator> <denominator> [scale]
hw_div() {
    local num="${1:-0}" den="${2:-1}" scale="${3:-1}"
    local mult=1 i
    for (( i = 0; i < scale; i++ )); do mult=$(( mult * 10 )); done
    # awk handles "4.13e+09", "12 kB", leading +/-, etc.
    awk -v n="$num" -v d="$den" -v m="$mult" '
        BEGIN {
            n += 0; d += 0
            if (d == 0) { print "0"; exit }
            if (n < 0)  { n = -n }
            printf "%.*f", (m == 1000 ? 3 : (m == 100 ? 2 : (m == 10 ? 1 : 0))), n / d
        }' 2>/dev/null || printf '0'
}

# Human-readable bytes. Tolerates scientific notation, units and empty input.
hw_human_bytes() {
    local raw="${1:-0}"
    local bytes
    bytes="$(printf '%s' "$raw" | awk '{ v = $1 + 0; if (v < 0) v = 0; printf "%.0f", v }' 2>/dev/null)"
    [[ "$bytes" =~ ^[0-9]+$ ]] || bytes=0

    if   (( bytes >= 1099511627776 )); then printf '%s TB' "$(hw_div "$bytes" 1099511627776 1)"
    elif (( bytes >= 1073741824    )); then printf '%s GB' "$(hw_div "$bytes" 1073741824    1)"
    elif (( bytes >= 1048576       )); then printf '%s MB' "$(hw_div "$bytes" 1048576       1)"
    elif (( bytes >= 1024          )); then printf '%s KB' "$(hw_div "$bytes" 1024          1)"
    else printf '%d B' "$bytes"
    fi
}

# Divider
hw_divider() {
    printf '\n%s  %s%s\n' "$(_hw_dim)" "$(printf '─%.0s' $(seq 1 56))" "$(_hw_r)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SUB-COMMAND LOADER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_hw_load_sub() {
    local sub="$1"
    local sub_file="${_HW_CMD_DIR}/${sub}.sh"

    if [[ ! -f "$sub_file" ]]; then
        printf '\n%s✗  Hardware sub-command not found: %s%s\n\n' \
            "$(_hw_red)" "$sub" "$(_hw_r)" >&2
        return 1
    fi

    # shellcheck source=/dev/null
    source "$sub_file"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_hw_help() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;250;179;135m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🖥️   ASH  ─  hw  (Hardware Information)                  ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\nASH hw — Hardware Information\n'
    fi

    local c_cmd="$(_hw_blue)"
    local c_desc="$(_hw_dim)"
    local c_sec="$(_hw_mauve)$(_hw_bold)"
    local c_r="$(_hw_r)"

    printf '\n%sUSAGE%s\n' "$(_hw_bold)" "$c_r"
    printf '   ash hw [sub-command] [flags]\n\n'

    printf '%sSUB-COMMANDS%s\n\n' "$c_sec" "$c_r"

    local -a commands=(
        "cpu:🔲:CPU architecture, cores, frequencies, temperatures, governor"
        "gpu:🎮:GPU info, VRAM, driver, Vulkan, VA-API, power state"
        "memory:🧠:RAM usage, swap, DIMM slots, speed, type"
        "disk:💿:Block devices, filesystems, NVMe health, I/O stats"
        "monitor:🖥️ :Connected displays, resolutions, refresh rates, HDR"
        "battery:🔋:Battery health, charge cycles, capacity, power draw"
        "full-report:📋:Complete HTML/text hardware report for all subsystems"
        "usb:🔌:USB devices and hubs  (via lsusb)"
        "pci:🚌:PCI devices  (via lspci)"
        "sensors:🌡️ :All hardware sensors via lm-sensors / hwmon sysfs"
        "audio:🔊:Audio devices and PipeWire node listing"
        "network:🌐:Network interfaces, speeds, driver info"
        "bluetooth:📡:Bluetooth adapter info"
        "benchmark:⚡:Quick CPU/memory/disk performance benchmarks"
    )

    for cmd_entry in "${commands[@]}"; do
        IFS=':' read -r cmd icon desc <<< "$cmd_entry"
        printf '   %s%s %-14s%s  %s%s%s\n' \
            "$c_cmd" "$icon" "$cmd" "$c_r" \
            "$c_desc" "$desc" "$c_r"
    done

    printf '\n%sFLAGS%s\n' "$c_sec" "$c_r"
    printf '   %s--json%s           Output in JSON format\n' "$c_cmd" "$c_r"
    printf '   %s--watch%s          Refresh every 2 seconds (live view)\n' "$c_cmd" "$c_r"
    printf '   %s--watch=N%s        Refresh every N seconds\n' "$c_cmd" "$c_r"
    printf '   %s--short%s          Compact single-line output\n' "$c_cmd" "$c_r"
    printf '   %s--no-color%s       Disable ANSI colors\n' "$c_cmd" "$c_r"

    printf '\n%sEXAMPLES%s\n' "$c_sec" "$c_r"
    printf '   %sash hw cpu%s                 CPU overview\n' "$c_cmd" "$c_r"
    printf '   %sash hw gpu --json%s          GPU info as JSON\n' "$c_cmd" "$c_r"
    printf '   %sash hw memory --watch%s      Live RAM monitor\n' "$c_cmd" "$c_r"
    printf '   %sash hw disk /dev/nvme0n1%s   Specific disk info\n' "$c_cmd" "$c_r"
    printf '   %sash hw full-report%s         Generate full report\n' "$c_cmd" "$c_r"
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WATCH MODE WRAPPER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_hw_watch_run() {
    local interval="${1:-2}"
    local func="$2"
    shift 2
    local args=("$@")

    if ! command -v tput &>/dev/null; then
        ash_log_error "watch mode requires tput (install ncurses)"
        return 1
    fi

    # Hide cursor
    tput civis 2>/dev/null || true
    trap 'tput cnorm 2>/dev/null; printf "\033[?25h"; exit 0' INT TERM EXIT

    while true; do
        printf '\033[2J\033[H'   # Clear screen + move to top

        # Timestamp header
        printf '%s  🔄 LIVE  •  refresh: %ds  •  %s  •  Ctrl+C to exit%s\n' \
            "$(_hw_dim)" "$interval" "$(date '+%H:%M:%S')" "$(_hw_r)"

        "$func" "${args[@]:-}" 2>/dev/null || true

        sleep "$interval"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN DISPATCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_cmd_hw() {
    local sub="${1:-}"
    shift || true
    local -a remaining=("$@")

    # Parse watch flag
    local watch_interval=0
    local -a filtered_args=()
    for arg in "${remaining[@]:-}"; do
        case "$arg" in
            --watch)        watch_interval=2   ;;
            --watch=*)      watch_interval="${arg#*=}" ;;
            *)              filtered_args+=("$arg") ;;
        esac
    done

    case "${sub:-help}" in
        help|-h|--help)
            _hw_help
            ;;
        cpu|gpu|memory|mem|disk|monitor|display|battery|full-report|report|\
        usb|pci|sensors|audio|network|net|bluetooth|bt|benchmark|bench)
            # Normalize aliases
            case "$sub" in
                mem)       sub="memory"       ;;
                display)   sub="monitor"      ;;
                report)    sub="full-report"  ;;
                net)       sub="network"      ;;
                bt)        sub="bluetooth"    ;;
                bench)     sub="benchmark"    ;;
            esac

            _hw_load_sub "$sub" || return 1

            local fn="ash_hw_${sub//-/_}"

            if declare -f "$fn" &>/dev/null; then
                if (( watch_interval > 0 )); then
                    _hw_watch_run "$watch_interval" "$fn" "${filtered_args[@]:-}"
                else
                    "$fn" "${filtered_args[@]:-}"
                fi
            else
                ash_log_error "Function not found: ${fn}"
                return 1
            fi
            ;;
        *)
            printf '\n%s✗  Unknown hw sub-command: %s%s\n' \
                "$(_hw_red)" "$sub" "$(_hw_r)" >&2
            printf '%sRun: ash hw help%s\n\n' "$(_hw_dim)" "$(_hw_r)" >&2
            return 1
            ;;
    esac
}
