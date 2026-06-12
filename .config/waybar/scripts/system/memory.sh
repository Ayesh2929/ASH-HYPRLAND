#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WAYBAR MEMORY MODULE                         ║
# ║           Detailed RAM/swap monitoring with alerts                         ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/memory.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 MEMORY STATS
# ═══════════════════════════════════════════════════════════════════════════════

get_mem_stats() {
    local mem_info
    mem_info=$(cat /proc/meminfo 2>/dev/null)

    local mem_total mem_free mem_available mem_buffers mem_cached
    local mem_slab_reclaim swap_total swap_free

    mem_total=$(echo "${mem_info}"       | awk '/^MemTotal:/{print $2}')
    mem_free=$(echo "${mem_info}"        | awk '/^MemFree:/{print $2}')
    mem_available=$(echo "${mem_info}"   | awk '/^MemAvailable:/{print $2}')
    mem_buffers=$(echo "${mem_info}"     | awk '/^Buffers:/{print $2}')
    mem_cached=$(echo "${mem_info}"      | awk '/^Cached:/{print $2}')
    mem_slab_reclaim=$(echo "${mem_info}" | awk '/^SReclaimable:/{print $2}')
    swap_total=$(echo "${mem_info}"      | awk '/^SwapTotal:/{print $2}')
    swap_free=$(echo "${mem_info}"       | awk '/^SwapFree:/{print $2}')

    # Calculate used memory
    local mem_used=$(( mem_total - mem_available ))
    local mem_pct=$(( mem_used * 100 / mem_total ))

    # Swap
    local swap_used=0
    local swap_pct=0
    if (( swap_total > 0 )); then
        swap_used=$(( swap_total - swap_free ))
        swap_pct=$(( swap_used * 100 / swap_total ))
    fi

    # Human-readable
    local mem_used_gb mem_total_gb swap_used_gb swap_total_gb
    mem_used_gb=$(awk "BEGIN{printf \"%.1f\", ${mem_used}/1024/1024}")
    mem_total_gb=$(awk "BEGIN{printf \"%.1f\", ${mem_total}/1024/1024}")
    swap_used_gb=$(awk "BEGIN{printf \"%.1f\", ${swap_used}/1024/1024}")
    swap_total_gb=$(awk "BEGIN{printf \"%.1f\", ${swap_total}/1024/1024}")

    echo "${mem_used}|${mem_total}|${mem_pct}|${mem_used_gb}|${mem_total_gb}|${swap_used_gb}|${swap_total_gb}|${swap_pct}"
}

get_top_processes() {
    ps aux --sort=-%mem 2>/dev/null \
        | awk 'NR>1 && NR<=6 {printf "  %-20s %s%%\n", $11, $4}' \
        | sed 's|.*/||'
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 FORMAT OUTPUT
# ═══════════════════════════════════════════════════════════════════════════════

format_output() {
    local stats
    stats=$(get_mem_stats)

    local mem_used mem_total mem_pct mem_used_gb mem_total_gb
    local swap_used_gb swap_total_gb swap_pct
    IFS='|' read -r mem_used mem_total mem_pct mem_used_gb mem_total_gb \
        swap_used_gb swap_total_gb swap_pct <<< "${stats}"

    # Determine class
    local class icon
    if (( mem_pct >= 90 )); then
        class="critical"; icon="󰍛"
    elif (( mem_pct >= 75 )); then
        class="warning";  icon="󰍛"
    elif (( mem_pct >= 50 )); then
        class="moderate"; icon="󰍛"
    else
        class="normal";   icon="󰍛"
    fi

    # Build tooltip
    local top_procs
    top_procs=$(get_top_processes)

    local tooltip
    tooltip="󰍛 Memory Usage\n"
    tooltip+="────────────────────\n"
    tooltip+="Used:      ${mem_used_gb}G / ${mem_total_gb}G\n"
    tooltip+="Usage:     ${mem_pct}%\n"

    if (( swap_pct > 0 )); then
        tooltip+="────────────────────\n"
        tooltip+="Swap Used: ${swap_used_gb}G / ${swap_total_gb}G (${swap_pct}%)\n"
    fi

    tooltip+="────────────────────\n"
    tooltip+="Top by memory:\n${top_procs}"

    # Send warning notification if critical
    if (( mem_pct >= 90 )); then
        local notif_file="/tmp/ash-mem-notified"
        if [[ ! -f "${notif_file}" ]]; then
            notify-send "🚨 Memory Critical" \
                "RAM usage at ${mem_pct}%\nUsed: ${mem_used_gb}G / ${mem_total_gb}G" \
                --urgency=critical \
                --app-name="ASH Memory" \
                2>/dev/null || true
            touch "${notif_file}"
            log "WARN" "Critical memory: ${mem_pct}%"
        fi
    else
        rm -f /tmp/ash-mem-notified 2>/dev/null || true
    fi

    printf '{"text": "%s %s%%", "tooltip": "%s", "class": "%s", "percentage": %s}\n' \
        "${icon}" "${mem_pct}" "${tooltip}" "${class}" "${mem_pct}"
}

main() {
    local action="${1:-status}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        status | "") format_output ;;
        used)
            local stats
            stats=$(get_mem_stats)
            echo "${stats}" | cut -d'|' -f4
            ;;
        percent)
            local stats
            stats=$(get_mem_stats)
            echo "${stats}" | cut -d'|' -f3
            ;;
        total)
            local stats
            stats=$(get_mem_stats)
            echo "${stats}" | cut -d'|' -f5
            ;;
        *)
            echo "Usage: memory.sh [status|used|percent|total]"
            exit 1
            ;;
    esac
}

main "$@"