#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WIFI TOGGLE                                  ║
# ║           NetworkManager WiFi control with notifications                    ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE: wifi-toggle.sh [ACTION]
#
# ACTIONS:
#   toggle   — Toggle WiFi on/off (default)
#   on       — Enable WiFi
#   off      — Disable WiFi
#   status   — Show connection status JSON
#   connect  — Rofi SSID picker + connect
#   scan     — Scan and show available networks
#   info     — Show current connection info

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/network.log"
readonly WAYBAR_SIGNAL=13

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; }
err()  { echo -e "  \033[91m✗\033[0m $*" >&2; }

# ═══════════════════════════════════════════════════════════════════════════════
# 📡 WIFI STATE
# ═══════════════════════════════════════════════════════════════════════════════

is_wifi_enabled() {
    local state
    state=$(nmcli radio wifi 2>/dev/null || echo "unavailable")
    [[ "${state}" == "enabled" ]]
}

is_connected() {
    nmcli -t -f STATE general 2>/dev/null | grep -q "connected"
}

get_ssid() {
    nmcli -t -f active,ssid dev wifi 2>/dev/null \
        | grep "^yes" \
        | cut -d: -f2 \
        | head -1 \
        || echo ""
}

get_signal_strength() {
    nmcli -t -f active,signal dev wifi 2>/dev/null \
        | grep "^yes" \
        | cut -d: -f2 \
        | head -1 \
        || echo "0"
}

get_ip_address() {
    nmcli -t -f IP4.ADDRESS device show 2>/dev/null \
        | grep "IP4.ADDRESS" \
        | head -1 \
        | awk -F: '{print $2}' \
        | cut -d/ -f1 \
        || hostname -I 2>/dev/null | awk '{print $1}' \
        || echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 WIFI CONTROL
# ═══════════════════════════════════════════════════════════════════════════════

enable_wifi() {
    info "Enabling WiFi..."
    nmcli radio wifi on 2>/dev/null

    # Wait for connection
    local attempts=0
    while (( attempts < 10 )); do
        sleep 1
        if is_connected; then
            local ssid
            ssid=$(get_ssid)
            ok "Connected to: ${ssid}"
            notify-send "📶 WiFi Enabled" \
                "Connected to: ${ssid}" \
                --icon=network-wireless-symbolic \
                --app-name="ASH Network" \
                --expire-time=3000 \
                2>/dev/null || true
            break
        fi
        ((attempts++)) || true
    done

    if ! is_connected; then
        notify-send "📶 WiFi Enabled" \
            "Searching for networks..." \
            --icon=network-wireless-symbolic \
            --app-name="ASH Network" \
            --expire-time=2000 \
            2>/dev/null || true
    fi

    signal_waybar
    log "INFO" "WiFi enabled"
}

disable_wifi() {
    info "Disabling WiFi..."
    nmcli radio wifi off 2>/dev/null

    notify-send "📵 WiFi Disabled" \
        "Wireless turned off" \
        --icon=network-wireless-disabled-symbolic \
        --app-name="ASH Network" \
        --expire-time=2000 \
        2>/dev/null || true

    signal_waybar
    log "INFO" "WiFi disabled"
}

toggle_wifi() {
    if is_wifi_enabled; then
        disable_wifi
    else
        enable_wifi
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 NETWORK SCAN & CONNECT
# ═══════════════════════════════════════════════════════════════════════════════

scan_networks() {
    info "Scanning for networks..."
    nmcli dev wifi rescan 2>/dev/null || true
    sleep 1

    local networks
    networks=$(nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null \
        | sort -t: -k2 -rn \
        | head -20)

    echo "${networks}"
}

rofi_connect() {
    # Scan for networks
    info "Scanning for networks..."
    nmcli dev wifi rescan 2>/dev/null || true
    sleep 1.5

    # Build network list
    local network_list=""
    while IFS=: read -r ssid signal security; do
        [[ -z "${ssid}" ]] && continue

        # Signal icon
        local sig_icon
        if (( signal >= 75 )); then sig_icon="📶"
        elif (( signal >= 50 )); then sig_icon="📶"
        elif (( signal >= 25 )); then sig_icon="📶"
        else sig_icon="📵"
        fi

        # Security icon
        local sec_icon=""
        [[ "${security}" != "--" ]] && [[ -n "${security}" ]] && sec_icon="🔒"

        network_list+="${sig_icon} ${ssid} ${sec_icon}  [${signal}%]\n"
    done < <(nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null \
        | sort -t: -k2 -rn | head -15)

    local selected
    selected=$(echo -e "${network_list}" | rofi \
        -dmenu \
        -i \
        -p "📶 Connect to WiFi" \
        -theme-str 'window { width: 500px; }' \
        2>/dev/null) || {
        info "Connect cancelled"
        return 0
    }

    # Extract SSID
    local ssid
    ssid=$(echo "${selected}" | sed 's/^[📶📵] //' | awk '{print $1}')

    if [[ -z "${ssid}" ]]; then
        err "No network selected"
        return 1
    fi

    # Check if password needed
    local security
    security=$(nmcli -t -f SSID,SECURITY dev wifi list \
        | grep "^${ssid}:" | head -1 | cut -d: -f2)

    if [[ "${security}" != "--" ]] && [[ -n "${security}" ]]; then
        # Ask for password
        local password
        password=$(rofi \
            -dmenu \
            -password \
            -p "🔒 Password for ${ssid}" \
            -theme-str 'window { width: 400px; }' \
            < /dev/null 2>/dev/null) || {
            info "Password entry cancelled"
            return 0
        }
        nmcli dev wifi connect "${ssid}" password "${password}" 2>/dev/null
    else
        nmcli dev wifi connect "${ssid}" 2>/dev/null
    fi

    sleep 1
    if is_connected && [[ "$(get_ssid)" == "${ssid}" ]]; then
        ok "Connected to: ${ssid}"
        notify-send "📶 Connected" \
            "Connected to: ${ssid}" \
            --icon=network-wireless-symbolic \
            --app-name="ASH Network" \
            --expire-time=3000 \
            2>/dev/null || true
    else
        err "Failed to connect to ${ssid}"
        notify-send "📵 Connection Failed" \
            "Could not connect to: ${ssid}" \
            --icon=network-wireless-disconnected-symbolic \
            --app-name="ASH Network" \
            --urgency=normal \
            --expire-time=4000 \
            2>/dev/null || true
    fi

    signal_waybar
    log "INFO" "Connect attempt: ${ssid}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📡 SIGNAL WAYBAR
# ═══════════════════════════════════════════════════════════════════════════════

signal_waybar() {
    pkill -SIGRTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 STATUS JSON
# ═══════════════════════════════════════════════════════════════════════════════

status_json() {
    if ! command -v nmcli &>/dev/null; then
        echo '{"text": "❌ NM", "class": "error", "tooltip": "NetworkManager not found"}'
        return 0
    fi

    if ! is_wifi_enabled; then
        echo '{"text": "󰖪", "class": "disabled", "tooltip": "WiFi disabled"}'
        return 0
    fi

    if is_connected; then
        local ssid signal ip
        ssid=$(get_ssid)
        signal=$(get_signal_strength)
        ip=$(get_ip_address)

        local icon
        if (( signal >= 75 ));   then icon="󰤨"
        elif (( signal >= 50 )); then icon="󰤥"
        elif (( signal >= 25 )); then icon="󰤢"
        else                          icon="󰤟"
        fi

        local class
        if (( signal >= 75 ));   then class="excellent"
        elif (( signal >= 50 )); then class="good"
        elif (( signal >= 25 )); then class="fair"
        else                          class="poor"
        fi

        printf '{"text": "%s %s", "tooltip": "SSID: %s\nSignal: %s%%\nIP: %s", "class": "%s", "percentage": %s}\n' \
            "${icon}" "${ssid}" "${ssid}" "${signal}" "${ip:-N/A}" "${class}" "${signal}"
    else
        echo '{"text": "󰤭", "class": "disconnected", "tooltip": "WiFi enabled but not connected"}'
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# ℹ️ CONNECTION INFO
# ═══════════════════════════════════════════════════════════════════════════════

show_info() {
    if ! is_connected; then
        echo "Not connected to any network"
        return 0
    fi

    local ssid signal ip
    ssid=$(get_ssid)
    signal=$(get_signal_strength)
    ip=$(get_ip_address)

    echo ""
    echo "  📶 WiFi Connection Info"
    echo "  ─────────────────────────────"
    echo "  SSID:   ${ssid}"
    echo "  Signal: ${signal}%"
    echo "  IP:     ${ip}"
    echo ""

    # Full nmcli output
    nmcli connection show --active 2>/dev/null | head -20 || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-toggle}"

    mkdir -p "${CACHE_DIR}/logs"

    if ! command -v nmcli &>/dev/null; then
        echo '{"text": "❌ NM", "class": "error"}'
        exit 0
    fi

    case "${action}" in
        toggle)     toggle_wifi ;;
        on | enable)  enable_wifi ;;
        off | disable) disable_wifi ;;
        connect)    rofi_connect ;;
        scan)       scan_networks ;;
        status)     status_json ;;
        info)       show_info ;;
        ssid)       get_ssid ;;
        signal)     get_signal_strength ;;
        ip)         get_ip_address ;;
        *)
            echo "Usage: wifi-toggle.sh [toggle|on|off|connect|scan|status|info]"
            exit 1
            ;;
    esac
}

main "$@"