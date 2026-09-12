#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██████╗ ██╗     ██╗   ██╗███████╗████████╗ ██████╗  ██████╗ ████████╗██╗  ██╗  ║
# ║  ██╔══██╗██║     ██║   ██║██╔════╝╚══██╔══╝██╔═══██╗██╔═══██╗╚══██╔══╝██║  ██║  ║
# ║  ██████╔╝██║     ██║   ██║█████╗     ██║   ██║   ██║██║   ██║   ██║   ███████║  ║
# ║  ██╔══██╗██║     ██║   ██║██╔══╝     ██║   ██║   ██║██║   ██║   ██║   ██╔══██║  ║
# ║  ██████╔╝███████╗╚██████╔╝███████╗   ██║   ╚██████╔╝╚██████╔╝   ██║   ██║  ██║  ║
# ║  ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝   ╚═╝    ╚═════╝  ╚═════╝    ╚═╝   ╚═╝  ╚═╝  ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  BLUETOOTH COMMAND DISPATCHER                            ║
# ║  Complete BlueZ management hub with animated UI and smart device handling       ║
# ║                                                                                  ║
# ║  Author   : ash-dotfiles                                                         ║
# ║  License  : MIT                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CMD_BLUETOOTH_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CMD_BLUETOOTH_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _BT_CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -gr _BT_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash/bluetooth"
declare -gr _BT_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ash/bluetooth"
declare -gr _BT_TRUST_FILE="${_BT_STATE_DIR}/trusted-devices.json"
declare -gr _BT_SCAN_CACHE="${_BT_CACHE_DIR}/last-scan.json"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CATPPUCCIN MOCHA PALETTE  (inline — zero external deps)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bt()      { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_btr()     { _bt '\033[0m';                          }
_btbold()  { _bt '\033[1m';                          }
_btdim()   { _bt '\033[38;2;108;112;134m';           }
_btmauve() { _bt '\033[1;38;2;203;166;247m';         }
_btblue()  { _bt '\033[38;2;137;180;250m';           }
_btgreen() { _bt '\033[38;2;166;227;161m';           }
_btpeach() { _bt '\033[38;2;250;179;135m';           }
_btyellow(){ _bt '\033[1;38;2;249;226;175m';         }
_btred()   { _bt '\033[1;38;2;243;139;168m';         }
_btteal()  { _bt '\033[38;2;148;226;213m';           }
_btsky()   { _bt '\033[38;2;137;220;235m';           }
_btlav()   { _bt '\033[38;2;180;190;254m';           }
_btpink()  { _bt '\033[38;2;245;194;231m';           }
_btsapph() { _bt '\033[38;2;116;199;236m';           }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SHARED DISPLAY PRIMITIVES  (exported to sub-commands)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

bt_section() {
    local icon="$1"  title="$2"  color="${3:-$(_btmauve)}"
    printf '\n%s%s  %s%s\n' "$color" "$icon" "$title" "$(_btr)"
    printf '%s  %s%s\n' "$(_btdim)" "$(printf '─%.0s' $(seq 1 58))" "$(_btr)"
}

bt_kv() {
    local key="$1"  val="$2"  vc="${3:-$(_btgreen)}"
    printf '  %s%-26s%s %s%s%s\n' \
        "$(_btdim)" "${key}:" "$(_btr)" "$vc" "$val" "$(_btr)"
}

bt_ok()    { printf '  %s✓%s  %s\n' "$(_btgreen)"  "$(_btr)" "$1"; }
bt_fail()  { printf '  %s✗%s  %s\n' "$(_btred)"    "$(_btr)" "$1"; }
bt_info()  { printf '  %sℹ%s  %s\n' "$(_btdim)"    "$(_btr)" "$1"; }
bt_warn()  { printf '  %s⚠%s  %s\n' "$(_btyellow)" "$(_btr)" "$1"; }
bt_step()  { printf '  %s→%s  %s\n' "$(_btteal)"   "$(_btr)" "$1"; }

bt_divider() {
    printf '%s  %s%s\n' "$(_btdim)" "$(printf '─%.0s' $(seq 1 60))" "$(_btr)"
}

bt_badge() {
    local text="$1"  color="${2:-$(_btblue)}"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '%s%s\033[38;2;30;30;46m %s \033[0m' "$(_btbold)" "$color" "$text"
    else
        printf '[%s]' "$text"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BLUETOOTH PREREQUISITE CHECKS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g BT_CTL=""   # bluetoothctl path
declare -g BT_ADAPTER=""

bt_check_prereqs() {
    if ! command -v bluetoothctl &>/dev/null; then
        bt_fail "bluetoothctl not found"
        bt_info "Install: paru -S bluez bluez-utils"
        return 1
    fi
    BT_CTL="$(command -v bluetoothctl)"

    if ! systemctl is-active bluetooth &>/dev/null 2>&1; then
        bt_warn "Bluetooth service not running"
        bt_info "Start: sudo systemctl enable --now bluetooth"
        if [[ "${ASH_FLAG_YES:-0}" -eq 1 ]]; then
            sudo systemctl start bluetooth 2>/dev/null || true
        fi
    fi

    # Get default adapter MAC
    BT_ADAPTER="$(bluetoothctl show 2>/dev/null | \
                  grep -oP '(?<=Controller )([0-9A-F:]{17})' | head -1 || echo '')"

    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  ANIMATED SPINNER  (used by scan and connect)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g _BT_SPIN_PID=""

bt_spin_start() {
    local msg="$1"
    local frames=( '◐' '◓' '◑' '◒' )
    local i=0
    tput civis 2>/dev/null || true
    while true; do
        printf '\r  %s%s%s  %s' "$(_btblue)" "${frames[$i]}" "$(_btr)" "$msg"
        i=$(( (i+1) % ${#frames[@]} ))
        sleep 0.12
    done &
    _BT_SPIN_PID=$!
}

bt_spin_stop() {
    local status="${1:-ok}"  msg="${2:-Done}"
    [[ -n "$_BT_SPIN_PID" ]] && kill "$_BT_SPIN_PID" 2>/dev/null || true
    _BT_SPIN_PID=""
    tput cnorm 2>/dev/null || true
    printf '\r  %-60s\n' ""
    if [[ "$status" == "ok" ]]; then
        bt_ok "$msg"
    else
        bt_fail "$msg"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BLUETOOTHCTL INTERACTION HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Send command to bluetoothctl and capture output with timeout
bt_ctl_cmd() {
    local cmd="$1"  timeout="${2:-5}"
    timeout "$timeout" bluetoothctl "$cmd" 2>/dev/null || true
}

# Execute a sequence of bluetoothctl commands via expect-free here-doc
bt_ctl_seq() {
    local timeout="${1:-10}"
    shift
    local cmds=("$@")
    local input=""
    for cmd in "${cmds[@]}"; do
        input+="${cmd}"$'\n'
    done
    printf '%s' "$input" | \
        timeout "$timeout" bluetoothctl 2>/dev/null || true
}

# Get controller power state
bt_is_powered() {
    bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'
}

bt_set_power() {
    local state="$1"  # on | off
    bluetoothctl power "$state" &>/dev/null
    sleep 0.3
}

# Check if device is connected
bt_is_connected() {
    local mac="$1"
    bluetoothctl info "$mac" 2>/dev/null | grep -q 'Connected: yes'
}

# Check if device is paired
bt_is_paired() {
    local mac="$1"
    bluetoothctl info "$mac" 2>/dev/null | grep -q 'Paired: yes'
}

# Check if device is trusted
bt_is_trusted() {
    local mac="$1"
    bluetoothctl info "$mac" 2>/dev/null | grep -q 'Trusted: yes'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  DEVICE TYPE CLASSIFIER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

bt_device_icon() {
    local icon_str="$1"  name="${2:-}"
    local combined="${icon_str,,} ${name,,}"
    case "$combined" in
        *headphone*|*headset*|*earphone*|*airpod*|*buds*)
            printf '🎧' ;;
        *speaker*|*soundbar*|*audio*)
            printf '🔊' ;;
        *keyboard*)
            printf '⌨️ ' ;;
        *mouse*|*trackpad*|*touchpad*)
            printf '🖱️ ' ;;
        *phone*|*mobile*|*android*|*iphone*)
            printf '📱' ;;
        *laptop*|*computer*|*macbook*)
            printf '💻' ;;
        *watch*|*band*|*fitness*)
            printf '⌚' ;;
        *gamepad*|*controller*|*joystick*)
            printf '🎮' ;;
        *camera*|*webcam*)
            printf '📷' ;;
        *printer*)
            printf '🖨️ ' ;;
        *tablet*|*ipad*)
            printf '📋' ;;
        *)
            printf '📡' ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RSSI SIGNAL STRENGTH DISPLAY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

bt_rssi_bars() {
    local rssi="${1:-0}"
    local rssi_abs="${rssi#-}"
    local bars desc color

    if   (( rssi_abs <= 55 )); then bars="▂▄▆█"; desc="Excellent"; color="$(_btgreen)"
    elif (( rssi_abs <= 65 )); then bars="▂▄▆░"; desc="Good";      color="$(_btgreen)"
    elif (( rssi_abs <= 75 )); then bars="▂▄░░"; desc="Fair";      color="$(_btyellow)"
    elif (( rssi_abs <= 85 )); then bars="▂░░░"; desc="Weak";      color="$(_btpeach)"
    else                            bars="░░░░"; desc="Poor";      color="$(_btred)"
    fi

    printf '%s%s%s  %s dBm  %s' \
        "$color" "$bars" "$(_btr)" \
        "$rssi" "$desc"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BLUETOOTH STATUS SNAPSHOT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

bt_status_frame() {
    bt_section "📡" "Bluetooth Status" "$(_btblue)"

    local controller_info
    controller_info="$(bluetoothctl show 2>/dev/null || echo '')"

    if [[ -z "$controller_info" ]]; then
        bt_fail "No Bluetooth controller found"
        bt_info "Check: lsusb | grep -i bluetooth"
        return 1
    fi

    # Parse controller fields
    local name addr powered discoverable pairable

    name="$(          printf '%s' "$controller_info" | grep 'Name:' | head -1 | awk '{$1=""; print}' | sed 's/^ //')"
    addr="$(          printf '%s' "$controller_info" | grep -oP '(?<=Controller )([0-9A-F:]{17})')"
    powered="$(       printf '%s' "$controller_info" | grep 'Powered:' | awk '{print $2}')"
    discoverable="$(  printf '%s' "$controller_info" | grep 'Discoverable:' | awk '{print $2}')"
    pairable="$(      printf '%s' "$controller_info" | grep 'Pairable:' | awk '{print $2}')"

    # Power status badge
    local power_badge
    if [[ "$powered" == "yes" ]]; then
        power_badge="$(bt_badge " ● ON " "$(_btgreen)")"
    else
        power_badge="$(bt_badge " ○ OFF " "$(_btred)")"
    fi

    bt_kv "Controller" "$name"
    bt_kv "Address"    "$addr"
    bt_kv "Power"      "$power_badge"
    bt_kv "Discoverable" "$([[ "$discoverable" == "yes" ]] && echo 'yes' || echo 'no')"
    bt_kv "Pairable"   "$([[ "$pairable" == "yes" ]] && echo 'yes' || echo 'no')"

    # Connected devices count
    local connected_count
    connected_count="$(bluetoothctl devices Connected 2>/dev/null | \
                       grep -c '^Device' || echo 0)"
    bt_kv "Connected" "${connected_count} device(s)"

    # rfkill status
    if command -v rfkill &>/dev/null; then
        local bt_blocked
        bt_blocked="$(rfkill list bluetooth 2>/dev/null | grep 'Soft blocked: yes')"
        if [[ -n "$bt_blocked" ]]; then
            bt_warn "Bluetooth is SOFT BLOCKED by rfkill"
            bt_info "Unblock: rfkill unblock bluetooth"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WATCH MODE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bt_watch() {
    local interval="${1:-2}"
    command -v tput &>/dev/null || { bt_fail "tput required"; return 1; }
    tput civis 2>/dev/null || true
    trap 'tput cnorm 2>/dev/null; exit 0' INT TERM EXIT
    while true; do
        printf '\033[2J\033[H'
        printf '%s  📡 BT LIVE  •  %s  •  Ctrl+C to exit%s\n' \
            "$(_btdim)" "$(date '+%H:%M:%S')" "$(_btr)"
        bt_status_frame
        sleep "$interval"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  NOTIFICATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

bt_notify() {
    local title="$1"  body="$2"  urgency="${3:-normal}"
    [[ "${ASH_BT_NO_NOTIFY:-0}" -eq 1 ]] && return 0
    command -v notify-send &>/dev/null || return 0
    notify-send "$title" "$body" \
        --urgency="$urgency" \
        --icon=bluetooth \
        --expire-time=4000 \
        2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME INIT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

bt_ensure_dirs() {
    mkdir -p "$_BT_STATE_DIR" "$_BT_CACHE_DIR" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SUB-COMMAND LOADER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bt_load_sub() {
    local sub="$1"
    local sub_file="${_BT_CMD_DIR}/${sub}.sh"
    if [[ ! -f "$sub_file" ]]; then
        printf '\n%s✗  bluetooth sub-command not found: %s%s\n\n' \
            "$(_btred)" "$sub" "$(_btr)" >&2
        return 1
    fi
    # shellcheck source=/dev/null
    source "$sub_file"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bt_help() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;180;190;254m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  📡  ASH  ─  bluetooth  (Bluetooth Manager)              ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    local cc="$(_btsky)"  cd="$(_btdim)"  cs="$(_btmauve)"  cr="$(_btr)"

    printf '\n%sUSAGE%s\n' "$(_btbold)" "$cr"
    printf '   ash bluetooth [sub-command] [flags]\n'
    printf '   ash bt [sub-command] [flags]          (alias)\n\n'

    printf '%sSUB-COMMANDS%s\n\n' "$cs" "$cr"

    local -a cmds=(
        "status:📡:Show adapter status and connected devices"
        "list:📋:List paired and connected devices"
        "scan:🔍:Scan for nearby Bluetooth devices"
        "pair:🔗:Pair with a new device"
        "connect:🔌:Connect to a paired device"
        "disconnect:⛔:Disconnect a connected device"
        "on:🟢:Power on Bluetooth adapter"
        "off:🔴:Power off Bluetooth adapter"
        "toggle:🔄:Toggle Bluetooth power"
        "trust:✅:Trust a paired device (auto-connect)"
        "remove:🗑️ :Remove/forget a paired device"
    )

    for entry in "${cmds[@]}"; do
        IFS=':' read -r cmd icon desc <<< "$entry"
        printf '   %s%s %-14s%s  %s%s%s\n' \
            "$cc" "$icon" "$cmd" "$cr" "$cd" "$desc" "$cr"
    done

    printf '\n%sFLAGS%s\n' "$cs" "$cr"
    printf '   %s--yes/-y%s        Skip confirmation prompts\n'     "$cc" "$cr"
    printf '   %s--no-notify%s     Suppress desktop notifications\n' "$cc" "$cr"
    printf '   %s--watch/-w%s      Live status monitor\n'           "$cc" "$cr"
    printf '   %s--json%s          Machine-readable JSON output\n'  "$cc" "$cr"
    printf '   %s--timeout=N%s     Operation timeout in seconds\n'  "$cc" "$cr"

    printf '\n%sEXAMPLES%s\n' "$cs" "$cr"
    printf '   %sash bt status%s              Adapter + device status\n'    "$cc" "$cr"
    printf '   %sash bt scan%s                Scan for devices\n'           "$cc" "$cr"
    printf '   %sash bt pair%s                Interactive pair wizard\n'    "$cc" "$cr"
    printf '   %sash bt connect AA:BB:CC%s    Connect by MAC\n'             "$cc" "$cr"
    printf '   %sash bt list --connected%s    Show only connected\n'        "$cc" "$cr"
    printf '   %sash bt on%s                  Power on adapter\n'           "$cc" "$cr"
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN DISPATCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_cmd_bluetooth() {
    local sub="${1:-status}"
    shift || true

    local watch_mode=0
    local -a fwd_args=()

    for arg in "${@:-}"; do
        case "$arg" in
            --yes|-y)        export ASH_FLAG_YES=1           ;;
            --no-notify)     export ASH_BT_NO_NOTIFY=1       ;;
            --json)          export ASH_FLAG_JSON_OUTPUT=1   ;;
            --watch|-w)      watch_mode=1                    ;;
            --timeout=*)     export BT_TIMEOUT="${arg#*=}"   ;;
            *)               fwd_args+=("$arg")              ;;
        esac
    done

    bt_ensure_dirs
    bt_check_prereqs || return 1

    case "$sub" in
        help|-h|--help) _bt_help ;;

        status|info)
            if [[ $watch_mode -eq 1 ]]; then
                _bt_watch 2
            else
                bt_status_frame
                printf '\n'
            fi
            ;;

        # Inline power commands (no sub-file needed)
        on|power-on)
            bt_section "🟢" "Bluetooth ON" "$(_btgreen)"
            bt_is_powered && {
                bt_info "Already powered on"
                printf '\n'; return 0
            }
            bt_step "Powering on Bluetooth..."
            bt_set_power on
            bt_is_powered && bt_ok "Bluetooth is ON" || bt_fail "Failed to power on"
            bt_notify "📡 Bluetooth" "Adapter powered ON"
            ;;

        off|power-off)
            bt_section "🔴" "Bluetooth OFF" "$(_btred)"
            ! bt_is_powered && {
                bt_info "Already powered off"
                printf '\n'; return 0
            }
            bt_step "Powering off Bluetooth..."
            bt_set_power off
            ! bt_is_powered && bt_ok "Bluetooth is OFF" || bt_fail "Failed to power off"
            bt_notify "📡 Bluetooth" "Adapter powered OFF"
            ;;

        toggle)
            bt_section "🔄" "Toggle Bluetooth" "$(_btlav)"
            if bt_is_powered; then
                ash_cmd_bluetooth off
            else
                ash_cmd_bluetooth on
            fi
            ;;

        trust)
            bt_section "✅" "Trust Device" "$(_btgreen)"
            local mac="${fwd_args[0]:-}"
            [[ -z "$mac" ]] && {
                bt_fail "MAC address required: ash bt trust AA:BB:CC:DD:EE:FF"
                return 1
            }
            bt_step "Trusting device: ${mac}..."
            bluetoothctl trust "$mac" &>/dev/null && \
                bt_ok "Device trusted: ${mac}" || \
                bt_fail "Failed to trust device"
            ;;

        remove|forget|delete)
            bt_section "🗑️ " "Remove Device" "$(_btred)"
            local mac="${fwd_args[0]:-}"
            [[ -z "$mac" ]] && {
                bt_fail "MAC address required: ash bt remove AA:BB:CC:DD:EE:FF"
                return 1
            }
            if [[ "${ASH_FLAG_YES:-0}" -ne 1 ]]; then
                printf '  %sRemove device %s? [y/N] %s' \
                    "$(_btyellow)" "$mac" "$(_btr)"
                local ans; read -r ans
                [[ "${ans,,}" != "y" ]] && { bt_info "Cancelled"; return 0; }
            fi
            bt_step "Removing device: ${mac}..."
            bluetoothctl remove "$mac" &>/dev/null && \
                bt_ok "Device removed: ${mac}" || \
                bt_fail "Failed to remove device"
            ;;

        scan|list|pair|connect|disconnect)
            _bt_load_sub "$sub" || return 1
            local fn="ash_bt_${sub}"
            declare -f "$fn" &>/dev/null && \
                "$fn" "${fwd_args[@]:-}" || {
                bt_fail "Function not found: ${fn}"
                return 1
            }
            ;;
        *)
            printf '\n%s✗  Unknown sub-command: %s%s\n' \
                "$(_btred)" "$sub" "$(_btr)" >&2
            printf '%sRun: ash bluetooth help%s\n\n' "$(_btdim)" "$(_btr)" >&2
            return 1
            ;;
    esac

    printf '\n'
}

# Alias
ash_cmd_bt() { ash_cmd_bluetooth "$@"; }
