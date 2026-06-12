#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — HYPRLOCK NETWORK SCRIPT                      ║
# ║           Network status for lock screen                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

main() {
    # Check NetworkManager
    if ! command -v nmcli &>/dev/null; then
        echo "󰖪  No NetworkManager"
        return 0
    fi

    local state
    state=$(nmcli -t -f STATE general 2>/dev/null | head -1 || echo "unknown")

    case "${state}" in
        connected)
            # WiFi or Ethernet?
            local device_type
            device_type=$(nmcli -t -f TYPE,STATE device 2>/dev/null \
                | grep ":connected" | head -1 | cut -d: -f1)

            case "${device_type}" in
                wifi)
                    local ssid signal
                    ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null \
                        | grep "^yes" | cut -d: -f2 | head -1)
                    signal=$(nmcli -t -f active,signal dev wifi 2>/dev/null \
                        | grep "^yes" | cut -d: -f2 | head -1 || echo "0")

                    local wifi_icon
                    if (( signal >= 75 ));   then wifi_icon="󰤨"
                    elif (( signal >= 50 )); then wifi_icon="󰤥"
                    elif (( signal >= 25 )); then wifi_icon="󰤢"
                    else                          wifi_icon="󰤟"
                    fi

                    echo "${wifi_icon}  ${ssid} (${signal}%)"
                    ;;
                ethernet)
                    local ip
                    ip=$(ip -4 addr show 2>/dev/null \
                        | grep -oP "(?<=inet )[\d.]+(?=/)" \
                        | grep -v "^127" | head -1 || echo "N/A")
                    echo "󰈀  Ethernet · ${ip}"
                    ;;
                *)
                    echo "󰖟  Connected"
                    ;;
            esac
            ;;
        disconnected)
            echo "󰖪  Disconnected"
            ;;
        connecting)
            echo "󰤫  Connecting..."
            ;;
        *)
            echo "󰖪  ${state}"
            ;;
    esac
}

main "$@"