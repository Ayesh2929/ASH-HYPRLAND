#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  net wifi-scan                                            ║
# ║  Scan nearby APs • signal heat-map • channel utilisation • security matrix      ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_NET_WIFI_SCAN_LOADED:-}" == "1" ]] && return 0
readonly _ASH_NET_WIFI_SCAN_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SCAN BACKENDS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_scan_find_iface() {
    for i in /sys/class/net/*/wireless; do
        [[ -d "$i" ]] && basename "${i%/wireless}" && return
    done
}

_scan_via_nmcli() {
    local iface="${1:-}"
    command -v nmcli &>/dev/null || return 1

    # Trigger rescan
    nmcli dev wifi rescan ${iface:+ifname "$iface"} 2>/dev/null || true
    sleep 1

    nmcli -t -f SSID,BSSID,MODE,CHAN,FREQ,RATE,SIGNAL,BARS,SECURITY \
          dev wifi list ${iface:+ifname "$iface"} 2>/dev/null || return 1
}

_scan_via_iw() {
    local iface="${1:-}"
    command -v iw &>/dev/null || return 1

    sudo -n iw dev "$iface" scan 2>/dev/null || \
    iw dev "$iface" scan 2>/dev/null || return 1
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RESULT TABLE RENDERER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_scan_signal_bars() {
    local pct="$1"
    if   (( pct >= 80 )); then printf '%s▂▄▆█%s'  "$(_ngreen)"  "$(_nr)"
    elif (( pct >= 60 )); then printf '%s▂▄▆░%s'  "$(_ngreen)"  "$(_nr)"
    elif (( pct >= 40 )); then printf '%s▂▄░░%s'  "$(_nyellow)" "$(_nr)"
    elif (( pct >= 20 )); then printf '%s▂░░░%s'  "$(_npeach)"  "$(_nr)"
    else                       printf '%s░░░░%s'  "$(_nred)"    "$(_nr)"
    fi
}

_scan_security_short() {
    local sec="$1"
    case "${sec^^}" in
        *WPA3*) printf '%s WPA3%s' "$(_ngreen)"  "$(_nr)" ;;
        *WPA2*) printf '%s WPA2%s' "$(_ngreen)"  "$(_nr)" ;;
        *WPA*)  printf '%s WPA%s'  "$(_nyellow)" "$(_nr)" ;;
        *WEP*)  printf '%s WEP!%s' "$(_nred)"    "$(_nr)" ;;
        "")     printf '%sOPEN%s'  "$(_nred)"    "$(_nr)" ;;
        *)      printf '%s%s%s'    "$(_ndim)" "${sec:0:6}" "$(_nr)" ;;
    esac
}

_scan_render_nmcli_table() {
    local data="$1"  filter="${2:-}"

    # Column header
    printf '\n  %s%-32s %-19s %4s %5s %4s  %-5s %s%s\n' \
        "$(_ndim)" "SSID" "BSSID" "CH" "FREQ" "SIG" "BARS" "SECURITY" "$(_nr)"
    printf '  %s%s%s\n' "$(_ndim)" "$(printf '─%.0s' $(seq 1 85))" "$(_nr)"

    local count=0

    while IFS=':' read -r ssid bssid mode chan freq rate signal bars security; do
        # Skip empty SSID or filter mismatch
        [[ -z "$ssid" ]] && ssid="(hidden)"
        [[ -n "$filter" ]] && \
            ! printf '%s' "${ssid,,}" | grep -qi "$filter" && continue

        local signal_int="${signal//[^0-9]/}"
        local sig_bars
        sig_bars="$(_scan_signal_bars "${signal_int:-0}")"

        local sec_fmt
        sec_fmt="$(_scan_security_short "$security")"

        # Current network indicator
        local cur_marker=" "
        nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | \
            grep -q "yes:${ssid}" && cur_marker="${_ngreen}★${_nr}"

        # Band color by frequency
        local freq_c
        printf '%s' "$freq" | grep -q '^5\|^6' && \
            freq_c="$(_nmauve)" || freq_c="$(_ndim)"

        printf '  %s%s%-32s%s %-19s %s%4s%s %s%5s%s %s%4s%s  %s  %s\n' \
            "$cur_marker" \
            "$(_nsky)" "${ssid:0:31}" "$(_nr)" \
            "${bssid:0:17}" \
            "$(_ndim)" "${chan:0:3}" "$(_nr)" \
            "$freq_c" "${freq:0:5}" "$(_nr)" \
            "$(_nbold)" "${signal_int}%" "$(_nr)" \
            "$sig_bars" \
            "$sec_fmt"

        (( count++ )) || true
    done <<< "$data"

    printf '\n  %s%d networks found%s\n' "$(_ndim)" "$count" "$(_nr)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CHANNEL UTILISATION MAP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_scan_channel_map() {
    local data="$1"
    declare -A ch_count=()

    while IFS=':' read -r ssid bssid mode chan freq rate signal bars security; do
        [[ -z "$chan" ]] && continue
        ch_count[$chan]=$(( ${ch_count[$chan]:-0} + 1 ))
    done <<< "$data"

    net_section "📻" "Channel Utilisation" "$(_nteal)"

    printf '  %sCH  Count  Congestion%s\n' "$(_ndim)" "$(_nr)"
    printf '  %s%s%s\n' "$(_ndim)" "$(printf '─%.0s' $(seq 1 40))" "$(_nr)"

    # Sort channels numerically
    for ch in $(printf '%s\n' "${!ch_count[@]}" | sort -n); do
        local cnt="${ch_count[$ch]}"
        local bar_pct=$(( cnt * 100 / 10 ))
        (( bar_pct > 100 )) && bar_pct=100
        local filled=$(( bar_pct * 20 / 100 ))
        local bc
        (( cnt >= 5 )) && bc="$(_nred)" || \
        (( cnt >= 3 )) && bc="$(_nyellow)" || bc="$(_ngreen)"

        printf '  %s%3s%s  %s%5d%s  %s%s%s%s%s\n' \
            "$(_nsky)" "$ch" "$(_nr)" \
            "$(_nbold)" "$cnt" "$(_nr)" \
            "$bc" "$(printf '█%.0s' $(seq 1 $filled))" \
            "$(_ndim)" "$(printf '░%.0s' $(seq 1 $(( 20 - filled )) ))" \
            "$(_nr)"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_net_wifi_scan() {
    local iface=""  filter=""  show_channels=1

    for arg in "${@:-}"; do
        case "$arg" in
            --iface=*)      iface="${arg#*=}"  ;;
            --filter=*)     filter="${arg#*=}" ;;
            --no-channels)  show_channels=0   ;;
            *)              filter="$arg"     ;;
        esac
    done

    [[ -z "$iface" ]] && iface="$(_scan_find_iface)"

    net_section "🔍" "WiFi Scan" "$(_nblue)"
    net_kv "Interface" "${iface:-none}"
    [[ -n "$filter" ]] && net_kv "Filter" "$filter"

    if [[ -z "$iface" ]]; then
        printf '\n  %s⚠  No WiFi interface found%s\n' "$(_nyellow)" "$(_nr)"
        net_divider; return 0
    fi

    # Scan
    printf '\n  %s⠋  Scanning...%s' "$(_nteal)" "$(_nr)"

    local scan_data=""
    if scan_data="$(_scan_via_nmcli "$iface" 2>/dev/null)"; then
        printf '\r  %s✓%s  Scan complete  %s(nmcli)%s\n' \
            "$(_ngreen)" "$(_nr)" "$(_ndim)" "$(_nr)"
    else
        printf '\r  %s⚠%s  nmcli unavailable — trying iw...\n' \
            "$(_nyellow)" "$(_nr)"
        if scan_data="$(_scan_via_iw "$iface" 2>/dev/null)"; then
            printf '  %s✓%s  Scan complete  %s(iw)%s\n' \
                "$(_ngreen)" "$(_nr)" "$(_ndim)" "$(_nr)"
        else
            printf '  %s✗%s  Scan failed. Try: sudo ash net wifi-scan\n' \
                "$(_nred)" "$(_nr)"
            net_divider; return 1
        fi
    fi

    net_section "📋" "Access Points" "$(_nsky)"
    _scan_render_nmcli_table "$scan_data" "$filter"

    [[ $show_channels -eq 1 ]] && _scan_channel_map "$scan_data"

    net_divider
}
