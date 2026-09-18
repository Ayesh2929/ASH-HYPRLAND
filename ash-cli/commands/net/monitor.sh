#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ███╗   ███╗ ██████╗ ███╗   ██╗██╗████████╗ ██████╗ ██████╗                    ║
# ║  ████╗ ████║██╔═══██╗████╗  ██║██║╚══██╔══╝██╔═══██╗██╔══██╗                   ║
# ║  ██╔████╔██║██║   ██║██╔██╗ ██║██║   ██║   ██║   ██║██████╔╝                   ║
# ║  ██║╚██╔╝██║██║   ██║██║╚██╗██║██║   ██║   ██║   ██║██╔══██╗                   ║
# ║  ██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██║   ██║   ╚██████╔╝██║  ██║                   ║
# ║  ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝                   ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  net monitor                                              ║
# ║  Live traffic dashboard • per-process bandwidth • connection table              ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_NET_MONITOR_LOADED:-}" == "1" ]] && return 0
readonly _ASH_NET_MONITOR_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  COLOUR HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_m()      { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_mr()     { _m $'\033[0m';                        }
_mbold()  { _m $'\033[1m';                        }
_mdim()   { _m $'\033[38;2;108;112;134m';         }
_mgreen() { _m $'\033[38;2;166;227;161m';         }
_mred()   { _m $'\033[1;38;2;243;139;168m';       }
_myellow(){ _m $'\033[1;38;2;249;226;175m';       }
_mteal()  { _m $'\033[38;2;148;226;213m';         }
_mblue()  { _m $'\033[38;2;137;180;250m';         }
_msky()   { _m $'\033[38;2;137;220;235m';         }
_mmauve() { _m $'\033[1;38;2;203;166;247m';       }
_mpeach() { _m $'\033[38;2;250;179;135m';         }

_mon_section() {
    printf '\n%s%s  %s%s\n' "$(_mmauve)" "$1" "$2" "$(_mr)"
    printf '%s  %s%s\n' "$(_mdim)" "$(printf '─%.0s' $(seq 1 60))" "$(_mr)"
}

_mon_human() {
    local b="${1:-0}"
    if   (( b >= 1073741824 )); then printf '%.2fGB' "$(echo "scale=2;$b/1073741824"|bc -l 2>/dev/null||echo 0)"
    elif (( b >= 1048576    )); then printf '%.2fMB' "$(echo "scale=2;$b/1048576"   |bc -l 2>/dev/null||echo 0)"
    elif (( b >= 1024       )); then printf '%.1fKB' "$(echo "scale=1;$b/1024"      |bc -l 2>/dev/null||echo 0)"
    else printf '%dB' "$b"
    fi
}

_mon_bps_color() {
    local bps="$1"
    if   (( bps >= 10000000 )); then printf '%s' "$(_mgreen)"
    elif (( bps >= 1000000  )); then printf '%s' "$(_myellow)"
    elif (( bps >= 100003   )); then printf '%s' "$(_mpeach)"
    else                             printf '%s' "$(_mdim)"
    fi
}

_mon_bps_fmt() {
    local bps="${1:-0}"
    if   (( bps >= 1000000000 )); then printf '%.2f Gbps' "$(echo "scale=2;$bps/1000000000"|bc -l 2>/dev/null||echo 0)"
    elif (( bps >= 1000000    )); then printf '%.2f Mbps' "$(echo "scale=2;$bps/1000000"   |bc -l 2>/dev/null||echo 0)"
    elif (( bps >= 1000       )); then printf '%.1f Kbps' "$(echo "scale=1;$bps/1000"      |bc -l 2>/dev/null||echo 0)"
    else printf '%d bps' "$bps"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  LIVE INTERFACE THROUGHPUT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gA _MON_RX_PREV=()
declare -gA _MON_TX_PREV=()
declare -gA _MON_RX_HIST=()
declare -gA _MON_TX_HIST=()
declare -g  _MON_SAMPLE_INTERVAL=1
declare -g  _MON_HIST_LEN=40

_mon_update_iface() {
    local iface="$1"
    local rx_bytes tx_bytes

    rx_bytes="$(cat "/sys/class/net/${iface}/statistics/rx_bytes" 2>/dev/null || echo 0)"
    tx_bytes="$(cat "/sys/class/net/${iface}/statistics/tx_bytes" 2>/dev/null || echo 0)"

    local rx_prev="${_MON_RX_PREV[$iface]:-$rx_bytes}"
    local tx_prev="${_MON_TX_PREV[$iface]:-$tx_bytes}"

    local rx_bps=$(( (rx_bytes - rx_prev) / _MON_SAMPLE_INTERVAL ))
    local tx_bps=$(( (tx_bytes - tx_prev) / _MON_SAMPLE_INTERVAL ))
    (( rx_bps < 0 )) && rx_bps=0
    (( tx_bps < 0 )) && tx_bps=0

    _MON_RX_PREV[$iface]="$rx_bytes"
    _MON_TX_PREV[$iface]="$tx_bytes"

    # Append to sparkline history
    local rx_hist="${_MON_RX_HIST[$iface]:-}"
    local tx_hist="${_MON_TX_HIST[$iface]:-}"
    _MON_RX_HIST[$iface]="${rx_hist:+$rx_hist }${rx_bps}"
    _MON_TX_HIST[$iface]="${tx_hist:+$tx_hist }${tx_bps}"

    # Trim history
    local -a rx_arr=()
    read -ra rx_arr <<< "${_MON_RX_HIST[$iface]}"
    if (( ${#rx_arr[@]} > _MON_HIST_LEN )); then
        _MON_RX_HIST[$iface]="${rx_arr[*]: -${_MON_HIST_LEN}}"
    fi

    printf '%d %d %d %d' "$rx_bps" "$tx_bps" "$rx_bytes" "$tx_bytes"
}

_mon_sparkline() {
    local history_str="$1"
    local -a vals=()
    read -ra vals <<< "$history_str"

    local max_v=1
    for v in "${vals[@]}"; do
        (( v > max_v )) && max_v=$v
    done

    local blocks=( '▁' '▂' '▃' '▄' '▅' '▆' '▇' '█' )
    local spark=""
    for v in "${vals[@]}"; do
        local idx=$(( v * 7 / max_v ))
        (( idx > 7 )) && idx=7
        spark+="${blocks[$idx]}"
    done
    printf '%s' "$spark"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CONNECTION TABLE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_mon_connections() {
    _mon_section "🔗" "Active Connections"

    printf '  %s%-7s %-45s %-20s %s%s\n' \
        "$(_mdim)" "Proto" "Remote Address" "State" "Process" "$(_mr)"
    printf '  %s%s%s\n' "$(_mdim)" "$(printf '─%.0s' $(seq 1 80))" "$(_mr)"

    local count=0
    ss -tnp state established 2>/dev/null | tail -n +2 | \
    while IFS= read -r line; do
        local proto local_addr remote_addr proc
        proto="TCP"
        remote_addr="$(printf '%s' "$line" | awk '{print $4}')"
        proc="$(       printf '%s' "$line" | awk '{print $6}' | \
                        grep -oP '(?<=\(\(")[^"]+' | head -1)"

        # Skip localhost
        [[ "$remote_addr" =~ ^127\. ]] && continue

        printf '  %sTCP%s    %-45s %-20s %s%s%s\n' \
            "$(_mblue)" "$(_mr)" \
            "${remote_addr:0:44}" \
            "ESTABLISHED" \
            "$(_mteal)" "${proc:-?}" "$(_mr)"

        (( count++ )) || true
    done

    printf '\n  %s%d established connections%s\n' "$(_mdim)" "$count" "$(_mr)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  LIVE DASHBOARD FRAME
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_mon_dashboard_frame() {
    local -a ifaces=()
    mapfile -t ifaces < <(
        ls /sys/class/net/ 2>/dev/null | grep -v '^lo$'
    )

    _mon_section "📊" "Network Monitor  ($(date '+%H:%M:%S'))"

    # Header
    printf '\n  %s%-14s  %-20s  %-20s  %-8s  %-8s%s\n' \
        "$(_mdim)" "Interface" "↓ Download" "↑ Upload" "Total RX" "Total TX" "$(_mr)"
    printf '  %s%s%s\n' "$(_mdim)" "$(printf '─%.0s' $(seq 1 80))" "$(_mr)"

    local grand_rx_bps=0 grand_tx_bps=0

    for iface in "${ifaces[@]}"; do
        [[ -e "/sys/class/net/${iface}" ]] || continue

        local state
        state="$(cat "/sys/class/net/${iface}/operstate" 2>/dev/null)"

        local data
        data="$(_mon_update_iface "$iface")"
        local rx_bps tx_bps rx_total tx_total
        read -r rx_bps tx_bps rx_total tx_total <<< "$data"

        (( grand_rx_bps += rx_bps )) || true
        (( grand_tx_bps += tx_bps )) || true

        local rx_c tx_c state_icon
        rx_c="$(_mon_bps_color "$rx_bps")"
        tx_c="$(_mon_bps_color "$tx_bps")"

        [[ "$state" == "up" ]] && \
            state_icon="${_mgreen}●${_mr}" || \
            state_icon="${_mdim}○${_mr}"

        # Sparklines
        local rx_spark tx_spark
        rx_spark="$(_mon_sparkline "${_MON_RX_HIST[$iface]:-}")"
        tx_spark="$(_mon_sparkline "${_MON_TX_HIST[$iface]:-}")"

        printf '  %s  %s%-12s%s  %s%-12s%s %s%s%s  %s%-12s%s %s%s%s  %-8s  %-8s\n' \
            "$state_icon" \
            "$(_msky)" "$iface" "$(_mr)" \
            "$rx_c" "$(_mon_bps_fmt "$rx_bps")" "$(_mr)" \
            "$(_mdim)" "${rx_spark: -10}" "$(_mr)" \
            "$tx_c" "$(_mon_bps_fmt "$tx_bps")" "$(_mr)" \
            "$(_mdim)" "${tx_spark: -10}" "$(_mr)" \
            "$(_mon_human "$rx_total")" \
            "$(_mon_human "$tx_total")"
    done

    printf '  %s%s%s\n' "$(_mdim)" "$(printf '─%.0s' $(seq 1 80))" "$(_mr)"
    printf '  %s%-14s%s  %s%-20s%s  %s%-20s%s\n' \
        "$(_mbold)" "TOTAL" "$(_mr)" \
        "$(_mgreen)" "$(_mon_bps_fmt "$grand_rx_bps")" "$(_mr)" \
        "$(_mpeach)" "$(_mon_bps_fmt "$grand_tx_bps")" "$(_mr)"

    # Connection count
    local conn_count
    conn_count="$(ss -tn state established 2>/dev/null | grep -c '^' || echo 0)"
    printf '\n  %sActive connections: %s%d%s\n' \
        "$(_mdim)" "$(_msky)" "$(( conn_count - 1 ))" "$(_mr)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_net_monitor() {
    local live=0  show_conns=0  interval=1

    for arg in "${@:-}"; do
        case "$arg" in
            --live|-l)         live=1  ;;
            --connections|-c)  show_conns=1 ;;
            --interval=*)      interval="${arg#*=}" _MON_SAMPLE_INTERVAL=$interval ;;
        esac
    done

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;148;226;213m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  📊  ASH  ─  Network Monitor                              ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    if [[ $live -eq 1 ]]; then
        command -v tput &>/dev/null || { printf 'tput required\n'; return 1; }
        tput civis 2>/dev/null || true
        trap 'tput cnorm 2>/dev/null; printf "\033[?25h"; exit 0' INT TERM EXIT

        # Prime samples
        for iface in $(ls /sys/class/net/ 2>/dev/null | grep -v '^lo$'); do
            _mon_update_iface "$iface" &>/dev/null || true
        done

        while true; do
            sleep "$_MON_SAMPLE_INTERVAL"
            printf '\033[2J\033[H'
            printf '%s  🔄 LIVE  interval:%ds  Ctrl+C to exit%s\n' \
                "$(_mdim)" "$_MON_SAMPLE_INTERVAL" "$(_mr)"
            _mon_dashboard_frame
            [[ $show_conns -eq 1 ]] && _mon_connections
        done
    else
        # Single snapshot
        sleep "$_MON_SAMPLE_INTERVAL"
        _mon_dashboard_frame
        [[ $show_conns -eq 1 ]] && _mon_connections
    fi

    printf '\n'
}
