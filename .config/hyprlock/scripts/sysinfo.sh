#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — HYPRLOCK SYSINFO SCRIPT                      ║
# ║           System information for lock screen (bottom right)                ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

main() {
    # CPU usage
    local cpu_usage
    cpu_usage=$(top -bn1 2>/dev/null \
        | grep "Cpu(s)" \
        | awk '{print $2}' \
        | cut -d. -f1 \
        || echo "?")

    # RAM usage
    local mem_used mem_total mem_pct
    mem_used=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf "%.0f", (t-a)/1024}' \
        /proc/meminfo 2>/dev/null || echo "?")
    mem_total=$(awk '/MemTotal/{printf "%.0f", $2/1024}' \
        /proc/meminfo 2>/dev/null || echo "?")
    mem_pct=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf "%.0f", (t-a)*100/t}' \
        /proc/meminfo 2>/dev/null || echo "?")

    # CPU temp
    local cpu_temp=""
    local temp_path
    temp_path=$(find /sys/class/thermal/thermal_zone*/temp 2>/dev/null \
        | head -1)
    if [[ -n "${temp_path}" ]]; then
        local raw_temp
        raw_temp=$(cat "${temp_path}" 2>/dev/null || echo "0")
        if (( raw_temp > 0 )); then
            cpu_temp=$(( raw_temp / 1000 ))
            cpu_temp=" · 🌡 ${cpu_temp}°C"
        fi
    fi

    # Uptime
    local uptime_str
    uptime_str=$(uptime -p 2>/dev/null | sed 's/up //' || echo "?")

    # Output (multi-line for lock screen)
    echo "  ${cpu_usage}%${cpu_temp}"
    echo "  ${mem_used}MB / ${mem_total}MB (${mem_pct}%)"
    echo "⏱  ${uptime_str}"
}

main "$@"