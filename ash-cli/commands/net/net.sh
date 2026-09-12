#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗                 ║
# ║  ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝                 ║
# ║  ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝                  ║
# ║  ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗                  ║
# ║  ██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗                 ║
# ║  ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝                 ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  NETWORK COMMAND DISPATCHER                              ║
# ║  Unified network management hub with live monitoring & WiFi control             ║
# ║                                                                                  ║
# ║  Author   : ash-dotfiles                                                         ║
# ║  License  : MIT                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CMD_NET_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CMD_NET_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _NET_CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -gr _NET_VERSION="5.0.0-omega"
declare -gr _NET_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ash/net"
declare -gr _NET_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash/net"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CATPPUCCIN MOCHA PALETTE  (inline — no external deps)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_n()       { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_nr()      { _n '\033[0m';                          }  # reset
_nbold()   { _n '\033[1m';                          }  # bold
_ndim()    { _n '\033[38;2;108;112;134m';           }  # overlay0
_nmauve()  { _n '\033[1;38;2;203;166;247m';         }  # mauve bold
_nblue()   { _n '\033[38;2;137;180;250m';           }  # blue
_ngreen()  { _n '\033[38;2;166;227;161m';           }  # green
_npeach()  { _n '\033[38;2;250;179;135m';           }  # peach
_nyellow() { _n '\033[1;38;2;249;226;175m';         }  # yellow bold
_nred()    { _n '\033[1;38;2;243;139;168m';         }  # red bold
_nteal()   { _n '\033[38;2;148;226;213m';           }  # teal
_nsky()    { _n '\033[38;2;137;220;235m';           }  # sky
_nlav()    { _n '\033[38;2;180;190;254m';           }  # lavender
_npink()   { _n '\033[38;2;245;194;231m';           }  # pink
_nsapph()  { _n '\033[38;2;116;199;236m';           }  # sapphire

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SHARED DISPLAY PRIMITIVES  (exported for sub-commands)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Decorative section header
net_section() {
    local icon="$1"  title="$2"  color="${3:-$(_nmauve)}"
    printf '\n%s%s  %s%s\n' "$color" "$icon" "$title" "$(_nr)"
    printf '%s  %s%s\n' "$(_ndim)" "$(printf '─%.0s' $(seq 1 54))" "$(_nr)"
}

# Key-value pair with aligned columns
net_kv() {
    local key="$1"  val="$2"  unit="${3:-}"  vc="${4:-$(_ngreen)}"
    printf '  %s%-24s%s %s%s%s%s\n' \
        "$(_ndim)" "${key}:" "$(_nr)" \
        "$vc" "$val" \
        "$([[ -n "$unit" ]] && printf ' %s%s' "$(_ndim)" "$unit" || true)" \
        "$(_nr)"
}

# Coloured progress/usage bar
net_bar() {
    local label="$1"  pct="$2"  suffix="${3:-}"  width="${4:-28}"
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    local bc
    if   (( pct >= 90 )); then bc="$(_nred)"
    elif (( pct >= 70 )); then bc="$(_nyellow)"
    elif (( pct >= 40 )); then bc="$(_npeach)"
    else                       bc="$(_ngreen)"
    fi
    printf '  %s%-24s%s %s%s%s%s%s  %s%d%%%s %s%s%s\n' \
        "$(_ndim)" "${label}:" "$(_nr)" \
        "$bc" "$(printf '█%.0s' $(seq 1 $filled))" \
        "$(_ndim)" "$(printf '░%.0s' $(seq 1 $empty))" \
        "$(_nr)" \
        "$(_nbold)" "$pct" "$(_nr)" \
        "$(_ndim)" "$suffix" "$(_nr)"
}

# Signal-strength wifi bar (0-100)
net_signal_bar() {
    local dbm="$1"  label="${2:-Signal}"
    local dbm_abs="${dbm#-}"
    local pct sc bars desc
    if   (( dbm_abs <= 50 )); then pct=100; sc="$(_ngreen)";   bars="▂▄▆█"; desc="Excellent" ;;
    elif (( dbm_abs <= 60 )); then pct=75;  sc="$(_ngreen)";   bars="▂▄▆░"; desc="Good"      ;;
    elif (( dbm_abs <= 70 )); then pct=50;  sc="$(_nyellow)";  bars="▂▄░░"; desc="Fair"      ;;
    elif (( dbm_abs <= 80 )); then pct=25;  sc="$(_npeach)";   bars="▂░░░"; desc="Weak"      ;;
    else                           pct=10;  sc="$(_nred)";     bars="░░░░"; desc="Poor"      ;;
    fi
    printf '  %s%-24s%s %s%s%s  %s%d dBm%s  %s%s%s\n' \
        "$(_ndim)" "${label}:" "$(_nr)" \
        "$sc" "$bars" "$(_nr)" \
        "$(_ndim)" "$dbm" "$(_nr)" \
        "$sc" "$desc" "$(_nr)"
}

# Status indicator badge
net_badge() {
    local text="$1"  bg="${2:-$(_nblue)}"
    printf '%s%s \033[38;2;30;30;46m%s \033[0m' "$(_nbold)" "$bg" "$text"
}

# Horizontal divider
net_divider() {
    printf '\n%s  %s%s\n' "$(_ndim)" "$(printf '─%.0s' $(seq 1 56))" "$(_nr)"
}

# Formatted bytes → human
net_human() {
    local b="${1:-0}"
    if   (( b >= 1099511627776 )); then printf '%.2f TB' "$(echo "scale=2;$b/1099511627776"|bc -l 2>/dev/null||echo 0)"
    elif (( b >= 1073741824    )); then printf '%.2f GB' "$(echo "scale=2;$b/1073741824"    |bc -l 2>/dev/null||echo 0)"
    elif (( b >= 1048576       )); then printf '%.2f MB' "$(echo "scale=2;$b/1048576"       |bc -l 2>/dev/null||echo 0)"
    elif (( b >= 1024          )); then printf '%.1f KB' "$(echo "scale=1;$b/1024"          |bc -l 2>/dev/null||echo 0)"
    else printf '%d B' "$b"
    fi
}

# Spinner while command runs in background
net_spin() {
    local msg="$1"; shift
    local frames=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
    local i=0

    "$@" &>/tmp/ash_net_spin_out &
    local pid=$!
    tput civis 2>/dev/null || true

    while kill -0 "$pid" 2>/dev/null; do
        printf '\r  %s%s%s  %s' "$(_nteal)" "${frames[$i]}" "$(_nr)" "$msg"
        i=$(( (i+1) % ${#frames[@]} ))
        sleep 0.08
    done

    tput cnorm 2>/dev/null || true
    wait "$pid" 2>/dev/null; local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        printf '\r  %s✓%s  %-55s\n' "$(_ngreen)" "$(_nr)" "$msg"
    else
        printf '\r  %s✗%s  %-55s\n' "$(_nred)" "$(_nr)" "$msg"
    fi
    return $exit_code
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  COMMON NETWORK PROBES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

net_default_iface() {
    ip route show default 2>/dev/null | awk 'NR==1{print $5}' | head -1
}

net_default_gw() {
    ip route show default 2>/dev/null | awk 'NR==1{print $3}' | head -1
}

net_iface_ipv4() {
    ip -4 addr show "$1" 2>/dev/null | awk '/inet /{print $2}' | head -1
}

net_iface_ipv6() {
    ip -6 addr show "$1" 2>/dev/null | awk '/inet6 / && !/fe80/{print $2}' | head -1
}

net_iface_mac() {
    cat "/sys/class/net/${1}/address" 2>/dev/null | tr -d '\n' || echo '?'
}

net_iface_state() {
    cat "/sys/class/net/${1}/operstate" 2>/dev/null | tr -d '\n' || echo 'unknown'
}

net_iface_speed() {
    cat "/sys/class/net/${1}/speed" 2>/dev/null | tr -d '\n' || echo '?'
}

net_iface_rx_bytes() {
    cat "/sys/class/net/${1}/statistics/rx_bytes" 2>/dev/null || echo 0
}

net_iface_tx_bytes() {
    cat "/sys/class/net/${1}/statistics/tx_bytes" 2>/dev/null || echo 0
}

net_is_wifi() {
    [[ -d "/sys/class/net/${1}/wireless" ]]
}

net_is_up() {
    local state
    state="$(net_iface_state "$1")"
    [[ "$state" == "up" ]]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SUB-COMMAND LOADER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_net_load_sub() {
    local sub="$1"
    local sub_file="${_NET_CMD_DIR}/${sub}.sh"

    if [[ ! -f "$sub_file" ]]; then
        printf '\n%s✗  net sub-command not found: %s%s\n' "$(_nred)" "$sub" "$(_nr)" >&2
        printf '%sRun: ash net help%s\n\n' "$(_ndim)" "$(_nr)" >&2
        return 1
    fi

    # shellcheck source=/dev/null
    source "$sub_file"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WATCH MODE WRAPPER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_net_watch() {
    local interval="${1:-2}"; shift
    local fn="$1";            shift
    local args=("$@")

    command -v tput &>/dev/null || { echo "watch requires ncurses" >&2; return 1; }

    tput civis 2>/dev/null || true
    trap 'tput cnorm 2>/dev/null; printf "\033[?25h"; exit 0' INT TERM EXIT

    while true; do
        printf '\033[2J\033[H'
        printf '%s  🔄 LIVE  interval:%ss  %s  Ctrl+C to exit%s\n' \
            "$(_ndim)" "$interval" "$(date '+%H:%M:%S')" "$(_nr)"
        "$fn" "${args[@]:-}" 2>/dev/null || true
        sleep "$interval"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_net_help() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;137;220;235m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🌐  ASH  ─  net  (Network Management)                   ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\nASH net — Network Management\n'
    fi

    local cc="$(_nsky)"  cd="$(_ndim)"  cs="$(_nmauve)"  cr="$(_nr)"

    printf '\n%sUSAGE%s\n' "$(_nbold)" "$cr"
    printf '   ash net [sub-command] [flags]\n\n'

    printf '%sSUB-COMMANDS%s\n\n' "$cs" "$cr"

    local -a cmds=(
        "status:🟢:Live network interface status, IPs, gateway, DNS"
        "speed:⚡:Measure real-time RX/TX throughput per interface"
        "wifi:📶:Show active WiFi connection details"
        "wifi-scan:🔍:Scan and list nearby WiFi access points"
        "wifi-connect:🔌:Connect to a WiFi network"
        "wifi-hotspot:📡:Create a WiFi hotspot (access point)"
        "vpn:🔒:VPN management (WireGuard / OpenVPN)"
        "dns:🔍:Query DNS and test resolution"
        "firewall:🛡:Firewall status and rule management"
        "ports:🚪:List listening TCP/UDP ports"
        "proxy:🌉:Configure HTTP/SOCKS proxy settings"
        "tor:🧅:Route traffic through Tor"
        "monitor:📊:Live network traffic dashboard"
    )

    for entry in "${cmds[@]}"; do
        IFS=':' read -r cmd icon desc <<< "$entry"
        printf '   %s%s %-16s%s  %s%s%s\n' \
            "$cc" "$icon" "$cmd" "$cr" "$cd" "$desc" "$cr"
    done

    printf '\n%sFLAGS%s\n' "$cs" "$cr"
    printf '   %s--watch[=N]%s     Refresh every N seconds (default 2)\n' "$cc" "$cr"
    printf '   %s--json%s          Machine-readable JSON output\n'         "$cc" "$cr"
    printf '   %s--iface=NAME%s    Target a specific interface\n'          "$cc" "$cr"
    printf '   %s--no-color%s      Disable ANSI colour output\n'           "$cc" "$cr"
    printf '   %s--verbose%s       Extended detail\n'                      "$cc" "$cr"

    printf '\n%sEXAMPLES%s\n' "$cs" "$cr"
    printf '   %sash net status%s              All interface status\n'             "$cc" "$cr"
    printf '   %sash net speed --watch%s       Live throughput monitor\n'          "$cc" "$cr"
    printf '   %sash net wifi-scan%s           Nearby access points\n'            "$cc" "$cr"
    printf '   %sash net wifi-connect Home%s   Connect to SSID\n'                 "$cc" "$cr"
    printf '   %sash net wifi-hotspot%s        Create hotspot\n'                  "$cc" "$cr"
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN DISPATCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_cmd_net() {
    local sub="${1:-status}"
    shift || true

    # Parse --watch flag before dispatching
    local watch_interval=0
    local -a fwd_args=()
    for arg in "${@:-}"; do
        case "$arg" in
            --watch)    watch_interval=2  ;;
            --watch=*)  watch_interval="${arg#*=}" ;;
            *)          fwd_args+=("$arg") ;;
        esac
    done

    # Runtime dir init
    mkdir -p "$_NET_CACHE_DIR" "$_NET_STATE_DIR" 2>/dev/null || true

    case "$sub" in
        help|-h|--help) _net_help ;;

        status|speed|wifi|wifi-scan|wifi-connect|wifi-hotspot|\
        vpn|dns|firewall|ports|proxy|tor|monitor)

            _net_load_sub "$sub" || return 1
            local fn="ash_net_${sub//-/_}"

            if declare -f "$fn" &>/dev/null; then
                if (( watch_interval > 0 )); then
                    _net_watch "$watch_interval" "$fn" "${fwd_args[@]:-}"
                else
                    "$fn" "${fwd_args[@]:-}"
                fi
            else
                echo "Function not found: ${fn}" >&2
                return 1
            fi
            ;;
        *)
            printf '\n%s✗  Unknown sub-command: %s%s\n' "$(_nred)" "$sub" "$(_nr)" >&2
            printf '%sRun: ash net help%s\n\n' "$(_ndim)" "$(_nr)" >&2
            return 1
            ;;
    esac
}
