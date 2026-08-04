#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  net speed                                                ║
# ║  Real-time RX/TX throughput • sparklines • per-interface breakdown              ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_NET_SPEED_LOADED:-}" == "1" ]] && return 0
readonly _ASH_NET_SPEED_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  THROUGHPUT MEASUREMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gA _SPEED_HISTORY_RX=()
declare -gA _SPEED_HISTORY_TX=()
declare -gi _SPEED_SAMPLE_MAX=30

_speed_read_bytes() {
    local iface="$1"  direction="$2"
    cat "/sys/class/net/${iface}/statistics/${direction}_bytes" 2>/dev/null || echo 0
}

_speed_measure() {
    local iface="$1"  interval="${2:-1}"

    local rx1 tx1 rx2 tx2
    rx1="$(_speed_read_bytes "$iface" rx)"
    tx1="$(_speed_read_bytes "$iface" tx)"

    sleep "$interval"

    rx2="$(_speed_read_bytes "$iface" rx)"
    tx2="$(_speed_read_bytes "$iface" tx)"

    local rx_bps tx_bps
    rx_bps=$(( (rx2 - rx1) / interval ))
    tx_bps=$(( (tx2 - tx1) / interval ))

    printf '%d %d' "$rx_bps" "$tx_bps"
}

_speed_format_bps() {
    local bps="${1:-0}"
    if   (( bps >= 1000000000 )); then printf '%.2f Gbps' "$(echo "scale=2;$bps/1000000000"|bc -l 2>/dev/null||echo 0)"
    elif (( bps >= 1000000    )); then printf '%.2f Mbps' "$(echo "scale=2;$bps/1000000"   |bc -l 2>/dev/null||echo 0)"
    elif (( bps >= 1000       )); then printf '%.1f Kbps' "$(echo "scale=1;$bps/1000"      |bc -l 2>/dev/null||echo 0)"
    else printf '%d bps' "$bps"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SPARKLINE GENERATOR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_speed_sparkline() {
    local key="$1"
    local new_val="$2"
    local max_ref="${3:-0}"

    # Append to history
    local history="${_SPEED_HISTORY_RX[$key]:-}"
    [[ "$key" =~ _tx_ ]] && history="${_SPEED_HISTORY_TX[$key]:-}"

    local -a vals=()
    mapfile -t vals <<< "$(printf '%s\n' $history)"
    vals+=("$new_val")

    # Keep last N samples
    if (( ${#vals[@]} > _SPEED_SAMPLE_MAX )); then
        vals=("${vals[@]: -${_SPEED_SAMPLE_MAX}}")
    fi

    # Update history
    if [[ "$key" =~ _tx_ ]]; then
        _SPEED_HISTORY_TX[$key]="${vals[*]}"
    else
        _SPEED_HISTORY_RX[$key]="${vals[*]}"
    fi

    # Find max for scaling
    local max_val=1
    for v in "${vals[@]}"; do
        (( v > max_val )) && max_val=$v
    done
    (( max_ref > max_val )) && max_val=$max_ref

    # Draw sparkline
    local blocks=( '▁' '▂' '▃' '▄' '▅' '▆' '▇' '█' )
    local spark=""
    for v in "${vals[@]}"; do
        local idx=$(( v * 7 / max_val ))
        (( idx > 7 )) && idx=7
        spark+="${blocks[$idx]}"
    done

    printf '%s' "$spark"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SPEEDTEST.NET BENCHMARK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_speed_internet_test() {
    if command -v speedtest-cli &>/dev/null; then
        printf '\n  %sRunning speedtest-cli...%s\n' "$(_ndim)" "$(_nr)"
        local result
        result="$(speedtest-cli --simple 2>/dev/null || echo '')"
        if [[ -n "$result" ]]; then
            while IFS= read -r line; do
                local key val
                key="$(printf '%s' "$line" | awk '{print $1}')"
                val="$(printf '%s' "$line" | cut -d' ' -f2-)"
                net_kv "$key" "$val"
            done <<< "$result"
        else
            printf '  %sspeedtest-cli failed%s\n' "$(_nred)" "$(_nr)"
        fi
    elif command -v fast-cli &>/dev/null; then
        printf '\n  %sRunning fast-cli...%s\n' "$(_ndim)" "$(_nr)"
        fast-cli 2>/dev/null || printf '  %sfast-cli failed%s\n' "$(_nred)" "$(_nr)"
    else
        printf '\n  %sInstall speedtest-cli for internet speed test%s\n' \
            "$(_nyellow)" "$(_nr)"
        printf '  %sparu -S speedtest-cli%s\n' "$(_ndim)" "$(_nr)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_net_speed() {
    local target_iface=""  run_speedtest=0
    local interval=1

    for arg in "${@:-}"; do
        case "$arg" in
            --internet|-i)  run_speedtest=1 ;;
            --interval=*)   interval="${arg#*=}" ;;
            --iface=*)      target_iface="${arg#*=}" ;;
            *)              [[ -e "/sys/class/net/$arg" ]] && target_iface="$arg" ;;
        esac
    done

    net_section "⚡" "Network Throughput" "$(_npeach)"

    if [[ $run_speedtest -eq 1 ]]; then
        _speed_internet_test
        net_divider
        return 0
    fi

    # Collect interfaces
    local -a ifaces=()
    if [[ -n "$target_iface" ]]; then
        ifaces=("$target_iface")
    else
        mapfile -t ifaces < <(
            ls /sys/class/net/ 2>/dev/null | grep -v '^lo$' | sort
        )
    fi

    printf '  %sMeasuring over %ds interval...%s\n' "$(_ndim)" "$interval" "$(_nr)"

    # Snapshot before
    declare -A rx1_map tx1_map
    for iface in "${ifaces[@]}"; do
        [[ -e "/sys/class/net/${iface}" ]] || continue
        rx1_map[$iface]="$(_speed_read_bytes "$iface" rx)"
        tx1_map[$iface]="$(_speed_read_bytes "$iface" tx)"
    done

    sleep "$interval"

    # Results table header
    printf '\n  %s%-14s  %-22s  %-22s  %-12s%s\n' \
        "$(_ndim)" "Interface" "↓ Download" "↑ Upload" "Total" "$(_nr)"
    printf '  %s%s%s\n' "$(_ndim)" "$(printf '─%.0s' $(seq 1 76))" "$(_nr)"

    local grand_rx=0 grand_tx=0

    for iface in "${ifaces[@]}"; do
        [[ -e "/sys/class/net/${iface}" ]] || continue

        local rx2 tx2 rx_bps tx_bps
        rx2="$(_speed_read_bytes "$iface" rx)"
        tx2="$(_speed_read_bytes "$iface" tx)"
        rx_bps=$(( (rx2 - rx1_map[$iface]) / interval ))
        tx_bps=$(( (tx2 - tx1_map[$iface]) / interval ))

        (( grand_rx += rx_bps )) || true
        (( grand_tx += tx_bps )) || true

        # Color by throughput
        local rx_c tx_c
        (( rx_bps > 10000000 )) && rx_c="$(_ngreen)"   || \
        (( rx_bps > 1000000  )) && rx_c="$(_nyellow)"  || \
        rx_c="$(_ndim)"
        (( tx_bps > 10000000 )) && tx_c="$(_npeach)"   || \
        (( tx_bps > 1000000  )) && tx_c="$(_nyellow)"  || \
        tx_c="$(_ndim)"

        local total_bps=$(( rx_bps + tx_bps ))
        local rx_fmt tx_fmt
        rx_fmt="$(_speed_format_bps "$rx_bps")"
        tx_fmt="$(_speed_format_bps "$tx_bps")"

        # Sparklines
        local rx_spark tx_spark
        rx_spark="$(_speed_sparkline "rx_${iface}" "$rx_bps")"
        tx_spark="$(_speed_sparkline "tx_${iface}" "$tx_bps")"

        printf '  %s%-14s%s  %s%-14s%s%s%s  %s%-14s%s%s%s  %s\n' \
            "$(_nsky)" "$iface" "$(_nr)" \
            "$rx_c" "$rx_fmt" "$(_ndim)" " $rx_spark" "$(_nr)" \
            "$tx_c" "$tx_fmt" "$(_ndim)" " $tx_spark" "$(_nr)" \
            "$(_speed_format_bps "$total_bps")"
    done

    printf '  %s%s%s\n' "$(_ndim)" "$(printf '─%.0s' $(seq 1 76))" "$(_nr)"
    printf '  %s%-14s%s  %s%-22s%s  %s%-22s%s\n' \
        "$(_nbold)" "TOTAL" "$(_nr)" \
        "$(_ngreen)" "$(_speed_format_bps "$grand_rx")" "$(_nr)" \
        "$(_npeach)"  "$(_speed_format_bps "$grand_tx")" "$(_nr)"

    net_divider
}
