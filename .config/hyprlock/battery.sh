#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — HYPRLOCK BATTERY SCRIPT                      ║
# ║           Battery status display for lock screen                           ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# 🔋 BATTERY DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

find_battery() {
    local paths=("/sys/class/power_supply/BAT0" "/sys/class/power_supply/BAT1"
                 "/sys/class/power_supply/BATT" "/sys/class/power_supply/battery")
    for p in "${paths[@]}"; do
        [[ -d "${p}" ]] && echo "${p}" && return 0
    done
    echo ""
}

find_ac() {
    local paths=("/sys/class/power_supply/AC" "/sys/class/power_supply/AC0"
                 "/sys/class/power_supply/ACAD" "/sys/class/power_supply/ADP1")
    for p in "${paths[@]}"; do
        [[ -f "${p}/online" ]] && echo "${p}" && return 0
    done
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 FORMAT OUTPUT
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local bat_path
    bat_path=$(find_battery)

    # No battery — desktop system
    if [[ -z "${bat_path}" ]]; then
        echo "🖥️  Desktop"
        return 0
    fi

    local capacity status
    capacity=$(cat "${bat_path}/capacity" 2>/dev/null || echo "?")
    status=$(cat "${bat_path}/status" 2>/dev/null || echo "Unknown")

    # AC adapter check
    local ac_path
    ac_path=$(find_ac)
    local on_ac=false
    if [[ -n "${ac_path}" ]]; then
        local online
        online=$(cat "${ac_path}/online" 2>/dev/null || echo "0")
        [[ "${online}" == "1" ]] && on_ac=true
    fi

    # Choose icon based on capacity and charging state
    local icon
    if [[ "${status}" == "Charging" ]]; then
        icon="󰂄"
    elif [[ "${status}" == "Full" ]]; then
        icon="󰁹"
    elif (( capacity <= 10 )); then
        icon="󰂎"
    elif (( capacity <= 20 )); then
        icon="󰁺"
    elif (( capacity <= 30 )); then
        icon="󰁻"
    elif (( capacity <= 40 )); then
        icon="󰁼"
    elif (( capacity <= 50 )); then
        icon="󰁽"
    elif (( capacity <= 60 )); then
        icon="󰁾"
    elif (( capacity <= 70 )); then
        icon="󰁿"
    elif (( capacity <= 80 )); then
        icon="󰂀"
    elif (( capacity <= 90 )); then
        icon="󰂁"
    else
        icon="󰂂"
    fi

    # Power estimate
    local power_str=""
    if [[ -f "${bat_path}/power_now" ]]; then
        local power_raw
        power_raw=$(cat "${bat_path}/power_now" 2>/dev/null || echo "0")
        if (( power_raw > 0 )); then
            local power_w
            power_w=$(awk "BEGIN{printf \"%.1f\", ${power_raw}/1000000}")
            power_str=" · ${power_w}W"
        fi
    fi

    # Format output
    local status_str=""
    case "${status}" in
        Charging)    status_str=" ⚡ charging" ;;
        Full)        status_str=" ✓ full" ;;
        Discharging) status_str="${power_str}" ;;
        *)           status_str="" ;;
    esac

    echo "${icon}  ${capacity}%${status_str}"
}

main "$@"