#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — WiFi Manager Script                               ║
# ║                                                                              ║
# ║  Complete WiFi network management via NetworkManager (nmcli).              ║
# ║  Scan networks, connect with password prompts, manage saved connections,   ║
# ║  create hotspots and control VPN profiles.                                  ║
# ║                                                                              ║
# ║  Features:                                                                   ║
# ║  • Real-time signal strength bars (unicode block characters)               ║
# ║  • Security indicator icons (WPA/WPA2/WPA3/Open)                          ║
# ║  • Frequency band display (2.4GHz/5GHz/6GHz)                             ║
# ║  • Saved connection quick-connect                                          ║
# ║  • Password prompt via rofi-dmenu                                         ║
# ║  • Mobile hotspot creation                                                 ║
# ║  • Connection editor (nm-connection-editor)                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# §01  CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

readonly IFACE="${WIFI_IFACE:-}"          # Empty = auto-detect
readonly SCAN_TIMEOUT=10                  # Seconds for network scan
readonly CONNECT_TIMEOUT=30              # Seconds to wait for connection
readonly MAX_NETWORKS=30                  # Max networks to show

# ══════════════════════════════════════════════════════════════════════════════
# §02  SIGNAL STRENGTH → VISUAL BARS
# ══════════════════════════════════════════════════════════════════════════════

signal_to_bars() {
    local signal="$1"
    local bars=""
    local filled empty

    # Convert dBm to percentage if negative
    if [[ "$signal" -lt 0 ]] 2>/dev/null; then
        if   [[ "$signal" -ge -50 ]]; then signal=100
        elif [[ "$signal" -ge -60 ]]; then signal=$(( (signal + 60) * 4 + 60 ))
        elif [[ "$signal" -ge -70 ]]; then signal=$(( (signal + 70) * 4 + 20 ))
        elif [[ "$signal" -ge -80 ]]; then signal=$(( (signal + 80) * 2 ))
        else signal=0
        fi
    fi

    filled=$(( signal * 8 / 100 ))
    [[ $filled -gt 8 ]] && filled=8
    empty=$(( 8 - filled ))

    local i
    for (( i=0; i<filled; i++ )); do bars+="█"; done
    for (( i=0; i<empty;  i++ )); do bars+="░"; done

    echo "$bars"
}

signal_to_icon() {
    local signal="$1"
    # Convert dBm to percentage if needed
    if [[ "$signal" -lt 0 ]] 2>/dev/null; then
        if   [[ "$signal" -ge -55 ]]; then signal=90
        elif [[ "$signal" -ge -65 ]]; then signal=70
        elif [[ "$signal" -ge -75 ]]; then signal=50
        elif [[ "$signal" -ge -85 ]]; then signal=30
        else signal=10
        fi
    fi

    if   [[ "$signal" -ge 80 ]]; then echo "󰤨"   # Excellent
    elif [[ "$signal" -ge 60 ]]; then echo "󰤥"   # Good
    elif [[ "$signal" -ge 40 ]]; then echo "󰤢"   # Fair
    elif [[ "$signal" -ge 20 ]]; then echo "󰤟"   # Poor
    else                               echo "󰤯"   # Minimal
    fi
}

security_to_icon() {
    local security="${1:-}"
    local security_lower="${security,,}"

    if   [[ "$security_lower" =~ wpa3 ]];     then echo " WPA3"
    elif [[ "$security_lower" =~ wpa2 ]];     then echo " WPA2"
    elif [[ "$security_lower" =~ wpa  ]];     then echo " WPA "
    elif [[ "$security_lower" =~ wep  ]];     then echo "⚠ WEP "
    elif [[ -z "$security" || "$security_lower" =~ open|none ]]; then
                                                   echo "○ Open"
    else                                           echo " Sec "
    fi
}

freq_to_band() {
    local freq="${1:-0}"
    if   [[ "$freq" -ge 5945 ]]; then echo "6GHz"
    elif [[ "$freq" -ge 5000 ]]; then echo "5GHz"
    elif [[ "$freq" -ge 2400 ]]; then echo "2.4G"
    else                              echo "    "
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  NMCLI WRAPPERS
# ══════════════════════════════════════════════════════════════════════════════

get_wifi_interface() {
    if [[ -n "$IFACE" ]]; then
        echo "$IFACE"
        return
    fi
    nmcli -t -f DEVICE,TYPE device 2>/dev/null | \
        grep ":wifi$" | cut -d: -f1 | head -1 || echo "wlan0"
}

wifi_is_enabled() {
    nmcli radio wifi 2>/dev/null | grep -q "enabled"
}

wifi_enable() {
    nmcli radio wifi on 2>/dev/null
}

wifi_disable() {
    nmcli radio wifi off 2>/dev/null
}

wifi_toggle() {
    if wifi_is_enabled; then
        wifi_disable
        notify_wifi "󰤮 WiFi Disabled" "" "normal"
    else
        wifi_enable
        sleep 1
        wifi_scan_bg
        notify_wifi "󰤨 WiFi Enabled" "Scanning for networks…" "normal"
    fi
}

get_active_ssid() {
    nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | \
        grep "wifi$" | cut -d: -f1 | head -1 || echo ""
}

get_active_ip() {
    local iface
    iface=$(get_wifi_interface)
    nmcli -t -f IP4.ADDRESS device show "$iface" 2>/dev/null | \
        cut -d: -f2 | cut -d/ -f1 | head -1 || echo ""
}

get_active_speed() {
    local iface
    iface=$(get_wifi_interface)
    local rx tx
    rx=$(cat "/sys/class/net/${iface}/statistics/rx_bytes" 2>/dev/null || echo 0)
    tx=$(cat "/sys/class/net/${iface}/statistics/tx_bytes" 2>/dev/null || echo 0)
    echo "↓$(numfmt --to=iec $rx 2>/dev/null || echo '?') ↑$(numfmt --to=iec $tx 2>/dev/null || echo '?')"
}

wifi_scan_bg() {
    local iface
    iface=$(get_wifi_interface)
    nmcli device wifi rescan ifname "$iface" &>/dev/null & disown
}

get_networks() {
    nmcli -t -f SSID,SIGNAL,SECURITY,FREQ,BSSID device wifi list 2>/dev/null | \
        head -"$MAX_NETWORKS" || true
}

get_saved_connections() {
    nmcli -t -f NAME,TYPE connection show 2>/dev/null | \
        grep ":802-11-wireless$" | cut -d: -f1 | sort || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════════════════

notify_wifi() {
    local title="$1" msg="$2" urgency="${3:-low}"
    notify-send \
        "$title" "$msg" \
        --app-name="ASH WiFi" \
        --icon=network-wireless \
        --urgency="$urgency" \
        --expire-time=4000 \
        --hint=string:x-dunst-stack-tag:wifi \
        2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  PASSWORD PROMPT
# ══════════════════════════════════════════════════════════════════════════════

prompt_password() {
    local ssid="$1"
    rofi \
        -dmenu \
        -p "󰤨 Password for '${ssid}'" \
        -password \
        -mesg "Enter WiFi password — characters are hidden" \
        -theme-str "
            window { width: 380px; height: 0px; }
            listview { lines: 0; }
            inputbar { padding: 14px 18px; }
            entry { font: JetBrainsMono Nerd Font 13; }
        " \
        2>/dev/null || echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  CONNECTION ACTIONS
# ══════════════════════════════════════════════════════════════════════════════

action_connect() {
    local ssid="$1" security="${2:-}" bssid="${3:-}"

    # Check if saved connection exists
    local saved_connections
    saved_connections=$(get_saved_connections)

    if echo "$saved_connections" | grep -qx "$ssid"; then
        # Known network — connect directly
        notify_wifi "󰤨 Connecting…" "$ssid"
        if nmcli connection up "$ssid" &>/dev/null; then
            sleep 1
            local ip
            ip=$(get_active_ip)
            notify_wifi "󰤨 Connected!" "$ssid${ip:+\nIP: $ip}"
        else
            notify_wifi "Connection failed" "$ssid — check password" "critical"
        fi
        return
    fi

    # Unknown network — need password for secured
    local password=""
    if [[ -n "$security" ]] && ! echo "${security,,}" | grep -q "open\|none\|^$"; then
        password=$(prompt_password "$ssid")
        [[ -z "$password" ]] && { notify_wifi "Cancelled" "" "low"; return; }
    fi

    notify_wifi "󰤨 Connecting…" "$ssid"

    local nmcli_args=(device wifi connect "$ssid")
    [[ -n "$bssid"    ]] && nmcli_args+=(bssid "$bssid")
    [[ -n "$password" ]] && nmcli_args+=(password "$password")

    if timeout "$CONNECT_TIMEOUT" nmcli "${nmcli_args[@]}" &>/dev/null; then
        local ip
        ip=$(get_active_ip)
        notify_wifi "󰤨 Connected!" "$ssid${ip:+\nIP: $ip}"
    else
        notify_wifi "Connection failed" "$ssid — wrong password?" "critical"
    fi
}

action_disconnect() {
    local active_ssid
    active_ssid=$(get_active_ssid)

    if [[ -z "$active_ssid" ]]; then
        notify_wifi "Not connected" "No active WiFi connection" "low"
        return
    fi

    if nmcli connection down "$active_ssid" &>/dev/null; then
        notify_wifi "󰤮 Disconnected" "$active_ssid"
    else
        # Try device disconnect
        local iface
        iface=$(get_wifi_interface)
        nmcli device disconnect "$iface" &>/dev/null
        notify_wifi "󰤮 Disconnected" ""
    fi
}

action_forget() {
    local ssid="$1"

    # Confirm forget
    local confirm
    confirm=$(printf "Yes, forget\nCancel" | \
        rofi -dmenu \
            -p "Forget '${ssid}'?" \
            -mesg "This will remove saved password and settings" \
            -theme-str "window { width: 300px; } listview { lines: 2; }" \
            2>/dev/null || echo "Cancel")

    if [[ "$confirm" == "Yes, forget" ]]; then
        nmcli connection delete "$ssid" &>/dev/null && \
            notify_wifi "Forgotten" "$ssid removed" || \
            notify_wifi "Error" "Could not forget $ssid" "critical"
    fi
}

action_edit() {
    local ssid="$1"
    command -v nm-connection-editor &>/dev/null && \
        nm-connection-editor --edit "$ssid" &>/dev/null & disown || \
        notify_wifi "Error" "nm-connection-editor not installed" "critical"
}

action_hotspot() {
    # Check if hotspot already active
    if nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | \
        grep -q "Hotspot"; then
        nmcli connection down Hotspot &>/dev/null && \
            notify_wifi "󰀝 Hotspot stopped" "" "normal"
        return
    fi

    # Get hotspot config
    local hotspot_ssid hotspot_pwd
    hotspot_ssid=$(rofi -dmenu \
        -p "Hotspot SSID" \
        -filter "ASH-Hotspot" \
        -theme-str "window { width: 350px; } listview { lines: 0; }" \
        2>/dev/null || echo "")

    [[ -z "$hotspot_ssid" ]] && return

    hotspot_pwd=$(prompt_password "$hotspot_ssid")
    [[ -z "$hotspot_pwd" ]] && return

    notify_wifi "󰀝 Starting hotspot" "$hotspot_ssid" "normal"

    local iface
    iface=$(get_wifi_interface)

    nmcli device wifi hotspot \
        ifname "$iface" \
        ssid "$hotspot_ssid" \
        password "$hotspot_pwd" \
        &>/dev/null && \
        notify_wifi "󰀝 Hotspot active" \
            "SSID: $hotspot_ssid\nPassword: $hotspot_pwd" \
            "normal" || \
        notify_wifi "Hotspot failed" "" "critical"
}

action_rescan() {
    notify_wifi "󰓻 Scanning" "Looking for WiFi networks…" "low"
    wifi_scan_bg
    sleep 2     # Wait for scan results
}

action_toggle_wifi() {
    wifi_toggle
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  NETWORK CONTEXT MENU
# ══════════════════════════════════════════════════════════════════════════════

show_network_context_menu() {
    local ssid="$1" security="${2:-}" signal="${3:-}" bssid="${4:-}"

    local active_ssid
    active_ssid=$(get_active_ssid)
    local is_connected=false
    [[ "$ssid" == "$active_ssid" ]] && is_connected=true

    local is_saved=false
    get_saved_connections | grep -qx "$ssid" 2>/dev/null && is_saved=true

    local signal_icon
    signal_icon=$(signal_to_icon "$signal")
    local bars
    bars=$(signal_to_bars "$signal")
    local sec_icon
    sec_icon=$(security_to_icon "$security")

    local entries=()

    $is_connected && \
        entries+=("󰤮  Disconnect") || \
        entries+=("󰤨  Connect")

    $is_saved && entries+=("  Forget Network")
    $is_saved && entries+=("  Edit Connection")

    entries+=(
        "󰆏  Copy BSSID"
        "󰋼  Network Details"
        "───"
        "✖  Cancel"
    )

    local choice
    choice=$(printf '%s\n' "${entries[@]}" | \
        rofi \
            -dmenu \
            -p "${signal_icon} ${ssid}" \
            -mesg "Signal: <b>${bars}</b> ${signal}%  ${sec_icon}  BSSID: ${bssid}" \
            -theme-str "
                window { width: 340px; height: 0px; }
                listview { lines: $(( ${#entries[@]} + 1 )); columns: 1; }
                element { padding: 9px 16px; border-radius: 8px; }
                element selected.normal {
                    background-color: #a6e3a1;
                    text-color: #1e1e2e;
                }
            " \
            2>/dev/null || echo "✖  Cancel")

    case "$choice" in
        "󰤨  Connect")      action_connect  "$ssid" "$security" "$bssid" ;;
        "󰤮  Disconnect")   action_disconnect ;;
        "  Forget Network") action_forget  "$ssid" ;;
        "  Edit Connection") action_edit   "$ssid" ;;
        "󰆏  Copy BSSID")
            echo -n "$bssid" | wl-copy 2>/dev/null || true
            notify_wifi "Copied" "BSSID: $bssid"
            ;;
        "󰋼  Network Details")
            local details
            details=$(nmcli device wifi show-password 2>/dev/null | head -20 || \
                echo "SSID: $ssid\nBSSID: $bssid\nSignal: ${signal}%\nSecurity: $security")
            notify_wifi "${signal_icon} ${ssid}" "$details" "low"
            ;;
        *)  ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §08  MENU ENTRY BUILDERS
# ══════════════════════════════════════════════════════════════════════════════

build_network_entries() {
    if ! wifi_is_enabled; then
        printf '󰤮  WiFi is disabled\0nonselectable\x1ftrue\n'
        printf '⏻  Enable WiFi\0info\x1fenable\n'
        return
    fi

    local active_ssid
    active_ssid=$(get_active_ssid)

    local saved_connections
    saved_connections=$(get_saved_connections || true)

    # ── Connected network (first) ──────────────────────────────────────────────
    if [[ -n "$active_ssid" ]]; then
        printf '─── CONNECTED ────────────────────────\0nonselectable\x1ftrue\n'

        # Get signal for active network
        local active_signal active_security active_freq active_bssid
        active_signal=$(nmcli -t -f SSID,SIGNAL,SECURITY,FREQ,IN-USE,BSSID \
            device wifi list 2>/dev/null | \
            grep "^${active_ssid}:" | head -1 | cut -d: -f2 || echo 0)
        active_security=$(nmcli -t -f SSID,SECURITY device wifi list 2>/dev/null | \
            grep "^${active_ssid}:" | head -1 | cut -d: -f2 || echo "")
        active_freq=$(nmcli -t -f SSID,FREQ device wifi list 2>/dev/null | \
            grep "^${active_ssid}:" | head -1 | cut -d: -f2 | grep -oP '^\d+' || echo "0")
        active_bssid=$(nmcli -t -f SSID,BSSID device wifi list 2>/dev/null | \
            grep "^${active_ssid}:" | head -1 | cut -d: -f2 || echo "")

        local bars icon sec band
        bars=$(signal_to_bars "$active_signal")
        icon=$(signal_to_icon "$active_signal")
        sec=$(security_to_icon "$active_security")
        band=$(freq_to_band "$active_freq")

        local display
        display=$(printf '%s  %-22s  %s  %4s%%  %s  %s' \
            "$icon" \
            "${active_ssid:0:20}" \
            "$bars" \
            "$active_signal" \
            "$sec" \
            "$band")

        printf '%s\0info\x1fcontext\x1fmeta\x1f%s|%s|%s|%s\n' \
            "$display" "$active_ssid" "$active_security" "$active_signal" "$active_bssid"
    fi

    # ── Networks scan results ──────────────────────────────────────────────────
    local networks
    networks=$(nmcli -t -f SSID,SIGNAL,SECURITY,FREQ,BSSID \
        device wifi list 2>/dev/null || true)

    local saved_shown=false
    local nearby_shown=false

    # Sort by signal strength (highest first)
    local sorted_networks
    sorted_networks=$(echo "$networks" | sort -t: -k2 -rn 2>/dev/null || echo "$networks")

    while IFS=: read -r ssid signal security freq bssid; do
        [[ -z "$ssid" ]] && continue
        # Skip currently connected (already shown above)
        [[ "$ssid" == "$active_ssid" ]] && continue
        # Skip duplicates (prefer higher signal)
        signal="${signal:-0}"

        local is_saved=false
        echo "$saved_connections" | grep -qx "$ssid" 2>/dev/null && is_saved=true

        local bars icon sec band
        bars=$(signal_to_bars "$signal")
        icon=$(signal_to_icon "$signal")
        sec=$(security_to_icon "$security")
        band=$(freq_to_band "${freq//[^0-9]/}")

        local display
        display=$(printf '%s  %-22s  %s  %4s%%  %s  %s' \
            "$icon" \
            "${ssid:0:20}" \
            "$bars" \
            "$signal" \
            "$sec" \
            "$band")

        if $is_saved && ! $saved_shown; then
            printf '─── SAVED NETWORKS ───────────────────\0nonselectable\x1ftrue\n'
            saved_shown=true
        elif ! $is_saved && ! $nearby_shown; then
            printf '─── NEARBY NETWORKS ──────────────────\0nonselectable\x1ftrue\n'
            nearby_shown=true
        fi

        printf '%s\0info\x1fcontext\x1fmeta\x1f%s|%s|%s|%s\n' \
            "$display" "$ssid" "$security" "$signal" "$bssid"

    done <<< "$sorted_networks"

    # ── Actions ────────────────────────────────────────────────────────────────
    printf '─── WIFI CONTROLS ────────────────────\0nonselectable\x1ftrue\n'
    printf '󰓻  Rescan Networks  (Ctrl+R)\0info\x1frescan\n'

    if [[ -n "$active_ssid" ]]; then
        printf '󰤮  Disconnect from %s\0info\x1fdisconnect\n' "${active_ssid:0:20}"
    fi

    printf '󰀝  Create Mobile Hotspot\0info\x1fhotspot\n'
    printf '󰤮  Disable WiFi\0info\x1fdisable\n'
    printf '  Open Connection Editor\0info\x1feditor\n'
}

# ══════════════════════════════════════════════════════════════════════════════
# §09  ACTION DISPATCHER
# ══════════════════════════════════════════════════════════════════════════════

dispatch_action() {
    local action="$1"
    local meta="${2:-}"

    case "$action" in
        context)
            IFS='|' read -r ssid security signal bssid <<< "$meta"
            [[ -n "$ssid" ]] && show_network_context_menu \
                "$ssid" "$security" "$signal" "$bssid"
            ;;
        enable)         wifi_enable; wifi_scan_bg; notify_wifi "󰤨 WiFi Enabled" "" ;;
        disable)        wifi_disable; notify_wifi "󰤮 WiFi Disabled" "" ;;
        toggle)         action_toggle_wifi ;;
        rescan)         action_rescan ;;
        disconnect)     action_disconnect ;;
        hotspot)        action_hotspot ;;
        editor)
            command -v nm-connection-editor &>/dev/null && \
                nm-connection-editor &>/dev/null & disown || \
                notify_wifi "Error" "nm-connection-editor not found" "critical"
            ;;
        none|"")        return 0 ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §10  DIRECT CLI INVOCATION
# ══════════════════════════════════════════════════════════════════════════════

handle_direct_args() {
    case "${1:-}" in
        --connect)      [[ -n "${2:-}" ]] && action_connect    "$2" "${3:-}" "" ;;
        --disconnect)   action_disconnect ;;
        --scan)         action_rescan ;;
        --enable)       wifi_enable;  notify_wifi "󰤨 WiFi ON"  "" ;;
        --disable)      wifi_disable; notify_wifi "󰤮 WiFi OFF" "" ;;
        --toggle)       wifi_toggle ;;
        --hotspot)      action_hotspot ;;
        --list)
            get_networks
            ;;
        --status)
            echo "WiFi: $(wifi_is_enabled && echo enabled || echo disabled)"
            echo "Connected: $(get_active_ssid || echo none)"
            echo "IP: $(get_active_ip || echo none)"
            ;;
        --help|-h)
            echo "ASH WiFi Manager v5.0"
            echo ""
            echo "Usage: wifi.sh [OPTION] [SSID]"
            echo ""
            echo "Options:"
            echo "  --connect SSID [SECURITY]  Connect to network"
            echo "  --disconnect               Disconnect current"
            echo "  --scan                     Scan for networks"
            echo "  --enable                   Enable WiFi"
            echo "  --disable                  Disable WiFi"
            echo "  --toggle                   Toggle WiFi"
            echo "  --hotspot                  Create mobile hotspot"
            echo "  --list                     List networks"
            echo "  --status                   Show WiFi status"
            echo ""
            echo "No args: Launch Rofi WiFi menu"
            exit 0
            ;;
        "")
            return 1
            ;;
    esac
    exit 0
}

# ══════════════════════════════════════════════════════════════════════════════
# §11  ROFI CUSTOM MODE PROTOCOL
# ══════════════════════════════════════════════════════════════════════════════

if [[ -z "${ROFI_RETV:-}" ]]; then
    handle_direct_args "${1:-}" "${2:-}" "${3:-}" 2>/dev/null || true

    rofi \
        -show wifi \
        -modi "wifi:${BASH_SOURCE[0]}" \
        -config "${HOME}/.config/rofi/menus/wifi/wifi.rasi" \
        2>/dev/null
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 0 ]]; then
    build_network_entries
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 1 ]]; then
    action="${ROFI_INFO:-}"
    [[ "$action" == "true" ]] && exit 0
    [[ -z "$action" ]] && exit 0

    IFS=$'\x1f' read -ra parts <<< "$action"
    local_action="${parts[0]:-}"
    meta_value="${parts[2]:-}"

    dispatch_action "$local_action" "$meta_value"
    exit 0
fi

# Ctrl+R: Rescan
if [[ "${ROFI_RETV}" -eq 10 ]]; then
    action_rescan
    build_network_entries
    exit 0
fi

# Ctrl+D: Disconnect
if [[ "${ROFI_RETV}" -eq 11 ]]; then
    action_disconnect
    build_network_entries
    exit 0
fi

# Ctrl+T: Toggle WiFi
if [[ "${ROFI_RETV}" -eq 12 ]]; then
    action_toggle_wifi
    build_network_entries
    exit 0
fi

# Ctrl+H: Hotspot
if [[ "${ROFI_RETV}" -eq 13 ]]; then
    action_hotspot
    build_network_entries
    exit 0
fi

# Re-filter
if [[ "${ROFI_RETV}" -eq 2 ]]; then
    build_network_entries
    exit 0
fi