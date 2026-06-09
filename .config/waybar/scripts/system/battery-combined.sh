#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — COMBINED BATTERY MODULE                      ║
# ║           Multi-battery support with AC state and time estimates            ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/battery.log"
readonly NOTIFIED_FILE="${CACHE_DIR}/battery-notified"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔋 BATTERY DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

find_batteries() {
    find /sys/class/power_supply -maxdepth 1 -name "BAT*" -o -name "BATT*" 2>/dev/null
}

find_ac_adapter() {
    local adapters=("AC" "AC0" "ACAD" "ADP0" "ADP1" "usb_type_c_source_sink")

    for adapter in "${adapters[@]}"; do
        local path="/sys/class/power_supply/${adapter}"
        if [[ -f "${path}/online" ]]; then
            echo "${path}"
            return 0
        fi
    done

    # Search all power supplies
    find /sys/class/power_supply -maxdepth 1 2>/dev/null \
        | while read -r psu; do
            local type
            type=$(cat "${psu}/type" 2>/dev/null || echo "")
            if [[ "${type}" == "Mains" ]]; then
                echo "${psu}"
                return 0
            fi
          done
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 BATTERY DATA
# ═══════════════════════════════════════════════════════════════════════════════

get_battery_stats() {
    local batteries=()
    while IFS= read -r bat; do
        [[ -n "${bat}" ]] && batteries+=("${bat}")
    done < <(find_batteries)

    if (( ${#batteries[@]} == 0 )); then
        echo "no_battery|100|100|Charging|0|0"
        return 0
    fi

    local total_capacity=0
    local total_energy_now=0
    local total_energy_full=0
    local total_power=0
    local status="Unknown"
    local bat_count=0
    local bat_names=""

    for bat in "${batteries[@]}"; do
        local cap energy_now energy_full power bat_status bat_name

        bat_name=$(basename "${bat}")
        bat_status=$(cat "${bat}/status" 2>/dev/null || echo "Unknown")

        # Capacity percentage
        cap=$(cat "${bat}/capacity" 2>/dev/null || echo "0")
        total_capacity=$(( total_capacity + cap ))

        # Energy
        if [[ -f "${bat}/energy_now" ]]; then
            energy_now=$(cat "${bat}/energy_now" 2>/dev/null || echo "0")
            energy_full=$(cat "${bat}/energy_full" 2>/dev/null || echo "0")
        elif [[ -f "${bat}/charge_now" ]]; then
            energy_now=$(cat "${bat}/charge_now" 2>/dev/null || echo "0")
            energy_full=$(cat "${bat}/charge_full" 2>/dev/null || echo "0")
        else
            energy_now=0
            energy_full=0
        fi

        total_energy_now=$(( total_energy_now + energy_now ))
        total_energy_full=$(( total_energy_full + energy_full ))

        # Power draw
        if [[ -f "${bat}/power_now" ]]; then
            power=$(cat "${bat}/power_now" 2>/dev/null || echo "0")
        elif [[ -f "${bat}/current_now" ]] && [[ -f "${bat}/voltage_now" ]]; then
            local current voltage
            current=$(cat "${bat}/current_now" 2>/dev/null || echo "0")
            voltage=$(cat "${bat}/voltage_now" 2>/dev/null || echo "0")
            power=$(( current * voltage / 1000000 / 1000 ))
        else
            power=0
        fi

        total_power=$(( total_power + power ))

        # Overall status priority: Charging > Discharging > Full
        case "${bat_status}" in
            Charging)    status="Charging" ;;
            Full)        [[ "${status}" != "Charging" ]] && status="Full" ;;
            Discharging) [[ "${status}" != "Charging" ]] && status="Discharging" ;;
        esac

        bat_names+="${bat_name},"
        ((bat_count++)) || true
    done

    # Average capacity if multiple batteries
    local avg_capacity
    avg_capacity=$(( total_capacity / bat_count ))

    # Calculate combined capacity from energy
    local combined_capacity="${avg_capacity}"
    if (( total_energy_full > 0 )); then
        combined_capacity=$(( total_energy_now * 100 / total_energy_full ))
    fi

    # Power in watts
    local power_watts
    power_watts=$(echo "${total_power}" | awk '{printf "%.1f", $1/1000000}')

    # Time estimate
    local time_estimate="∞"
    if [[ "${status}" == "Discharging" ]] && (( total_power > 0 )); then
        local seconds_left
        seconds_left=$(echo "${total_energy_now} ${total_power}" \
            | awk '{printf "%.0f", ($1 / $2) * 3600}')
        local hours=$(( seconds_left / 3600 ))
        local mins=$(( (seconds_left % 3600) / 60 ))
        time_estimate="${hours}h ${mins}m"
    elif [[ "${status}" == "Charging" ]] && (( total_power > 0 )); then
        local energy_needed=$(( total_energy_full - total_energy_now ))
        local seconds_to_full
        seconds_to_full=$(echo "${energy_needed} ${total_power}" \
            | awk '{printf "%.0f", ($1 / $2) * 3600}')
        local hours=$(( seconds_to_full / 3600 ))
        local mins=$(( (seconds_to_full % 3600) / 60 ))
        time_estimate="${hours}h ${mins}m"
    fi

    bat_names="${bat_names%,}"
    echo "${bat_names}|${combined_capacity}|${avg_capacity}|${status}|${power_watts}|${time_estimate}"
}

is_on_ac() {
    local ac_path
    ac_path=$(find_ac_adapter)

    if [[ -n "${ac_path}" ]]; then
        local online
        online=$(cat "${ac_path}/online" 2>/dev/null || echo "0")
        [[ "${online}" == "1" ]]
    else
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔔 LOW BATTERY NOTIFICATIONS
# ═══════════════════════════════════════════════════════════════════════════════

check_low_battery() {
    local capacity="$1"
    local status="$2"

    [[ "${status}" == "Charging" ]] && return 0

    if (( capacity <= 5 )) && ! grep -q "critical" "${NOTIFIED_FILE}" 2>/dev/null; then
        notify-send "🔋 CRITICAL Battery!" \
            "${capacity}% — Plug in immediately!" \
            --urgency=critical \
            --app-name="ASH Battery" \
            --expire-time=0 \
            --icon=battery-caution-symbolic \
            2>/dev/null || true
        echo "critical" >> "${NOTIFIED_FILE}"
        log "WARN" "Critical battery: ${capacity}%"

        # Auto power saver
        ~/.config/hypr/scripts/system/power-profile.sh power-saver 2>/dev/null || true

    elif (( capacity <= 15 )) && ! grep -q "low" "${NOTIFIED_FILE}" 2>/dev/null; then
        notify-send "🔋 Low Battery" \
            "${capacity}% remaining" \
            --urgency=normal \
            --app-name="ASH Battery" \
            --expire-time=8000 \
            --icon=battery-low-symbolic \
            2>/dev/null || true
        echo "low" >> "${NOTIFIED_FILE}"
        log "WARN" "Low battery: ${capacity}%"

    elif (( capacity > 20 )) && [[ -f "${NOTIFIED_FILE}" ]]; then
        rm -f "${NOTIFIED_FILE}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 FORMAT OUTPUT
# ═══════════════════════════════════════════════════════════════════════════════

format_output() {
    local stats="$1"

    local bat_names capacity avg_capacity status power_watts time_estimate
    IFS='|' read -r bat_names capacity avg_capacity status power_watts time_estimate <<< "${stats}"

    # Handle no battery
    if [[ "${bat_names}" == "no_battery" ]]; then
        printf '{"text": "󰚥", "class": "plugged", "tooltip": "AC powered (no battery)"}\n'
        return 0
    fi

    # Check low battery
    check_low_battery "${capacity}" "${status}"

    # AC state
    local on_ac=false
    is_on_ac && on_ac=true

    # Battery icon
    local icon
    local icon_idx=$(( capacity / 10 ))
    (( icon_idx > 10 )) && icon_idx=10

    local icons=("󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")

    case "${status}" in
        Charging) icon="󰂄" ;;
        Full)     icon="󰁹" ;;
        *)        icon="${icons[${icon_idx}]}" ;;
    esac

    # Class
    local class
    case "${status}" in
        Charging) class="charging" ;;
        Full)     class="full" ;;
        *)
            if (( capacity <= 10 ));   then class="critical"
            elif (( capacity <= 25 )); then class="warning"
            elif (( capacity <= 50 )); then class="low"
            else                            class="good"
            fi
            ;;
    esac

    # Display text
    local text="${icon} ${capacity}%"

    # Tooltip
    local bat_count
    bat_count=$(echo "${bat_names}" | tr ',' '\n' | wc -l)

    local tooltip
    tooltip="🔋 Battery Status\n"
    tooltip+="────────────────────\n"
    tooltip+="Capacity:  ${capacity}%\n"
    tooltip+="Status:    ${status}\n"
    tooltip+="AC Power:  $(${on_ac} && echo 'Connected' || echo 'Disconnected')\n"

    if [[ "${status}" != "Full" ]]; then
        tooltip+="Power:     ${power_watts}W\n"
        tooltip+="Time:      ${time_estimate}\n"
    fi

    if (( bat_count > 1 )); then
        tooltip+="────────────────────\n"
        tooltip+="Batteries: ${bat_names}\n"
    fi

    printf '{"text": "%s", "tooltip": "%s", "class": "%s", "percentage": %s}\n' \
        "${text}" "${tooltip}" "${class}" "${capacity}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        "" | status)
            local stats
            stats=$(get_battery_stats)
            format_output "${stats}"
            ;;
        percent)
            get_battery_stats | cut -d'|' -f2
            ;;
        ac)
            is_on_ac && echo "plugged" || echo "unplugged"
            ;;
        *)
            echo "Usage: battery-combined.sh [status|percent|ac]"
            exit 1
            ;;
    esac
}

main "$@"