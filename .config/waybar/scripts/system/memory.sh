#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WAYBAR MEMORY MODULE                         ║
# ║           Detailed RAM/Swap usage with process info                        ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/waybar.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 MEMORY DATA
# ═══════════════════════════════════════════════════════════════════════════════

get_memory_info() {
    # Parse /proc/meminfo for accurate values
    local mem_total mem_free mem_available mem_buffers mem_cached
    local swap_total swap_free swap_used
    local mem_used mem_pct swap_pct

    while IFS=': ' read -r key value _unit; do
        case "${key}" in
            MemTotal)     mem_total="${value}" ;;
            MemFree)      mem_free="${value}" ;;
            MemAvailable) mem_available="${value}" ;;
            Buffers)      mem_buffers="${value}" ;;
            Cached)       mem_cached="${value}" ;;
            SwapTotal)    swap_total="${value}" ;;
            SwapFree)     swap_free="${value}" ;;
        esac
    done < /proc/meminfo

    # Calculate used memory (total - available)
    mem_used=$(( mem_total - mem_available ))
    swap_used=$(( swap_total - swap_free ))

    # Calculate percentages
    mem_pct=0
    (( mem_total > 0 )) && mem_pct=$(( mem_used * 100 / mem_total ))

    swap_pct=0
    (( swap_total > 0 )) && swap_pct=$(( swap_used * 100 / swap_total ))

    # Convert to human-readable (MiB/GiB)
    local mem_used_h mem_total_h swap_used_h swap_total_h

    if (( mem_used >= 1048576 )); then
        mem_used_h=$(awk "BEGIN{printf \"%.1f\", ${mem_used}/1048576}")G
    else
        mem_used_h=$(awk "BEGIN{printf \"%.0f\", ${mem_used}/1024}")M
    fi

    if (( mem_total >= 1048576 )); then
        mem_total_h=$(awk "BEGIN{printf \"%.1f\", ${mem_total}/1048576}")G
    else
        mem_total_h=$(awk "BEGIN{printf \"%.0f\", ${mem_total}/1024}")M
    fi

    if (( swap_total > 0 )); then
        swap_used_h=$(awk "BEGIN{printf \"%.1f\", ${swap_used}/1048576}")G
        swap_total_h=$(awk "BEGIN{printf \"%.1f\", ${swap_total}/1048576}")G
    fi

    # Get top memory-consuming processes
    local top_procs=""
    top_procs=$(ps -eo pid,rss,comm --sort=-rss 2>/dev/null \
        | awk 'NR>1 && NR<=6 {printf "%s(%.0fMB) ", $3, $2/1024}')

    echo "${mem_used}|${mem_total}|${mem_pct}|${mem_used_h}|${mem_total_h}|${swap_used}|${swap_total}|${swap_pct}|${swap_used_h:-0}|${swap_total_h:-0}|${top_procs}"
}

format_output() {
    local info="$1"
    local mem_used mem_total mem_pct mem_used_h mem_total_h
    local swap_used swap_total swap_pct swap_used_h swap_total_h top_procs

    IFS='|' read -r mem_used mem_total mem_pct mem_used_h mem_total_h \
                     swap_used swap_total swap_pct swap_used_h swap_total_h top_procs \
                     <<< "${info}"

    # Memory icon based on usage
    local icon class
    if (( mem_pct >= 90 )); then
        icon="󰀦"
        class="critical"
    elif (( mem_pct >= 75 )); then
        icon="󰍞"
        class="warning"
    elif (( mem_pct >= 50 )); then
        icon="󰍛"
        class="moderate"
    else
        icon="󰍛"
        class="normal"
    fi

    # Build progress bar
    local bar_width=10
    local filled=$(( mem_pct * bar_width / 100 ))
    local bar=""
    for (( i=0; i<filled; i++ )); do bar+="█"; done
    for (( i=filled; i<bar_width; i++ )); do bar+="░"; done

    # Display text
    local text="${icon} ${mem_used_h}/${mem_total_h}"

    # Tooltip
    local tooltip
    tooltip="󰍛 Memory Usage\n"
    tooltip+="────────────────────────\n"
    tooltip+="Used:      ${mem_used_h} / ${mem_total_h} (${mem_pct}%)\n"
    tooltip+="${bar}\n"
    tooltip+="Available: $(awk "BEGIN{printf \"%.1f\", (${mem_total} - ${mem_used})/1048576}")G\n"

    if (( swap_total > 0 )); then
        tooltip+="────────────────────────\n"
        tooltip+="Swap: ${swap_used_h}G / ${swap_total_h}G (${swap_pct}%)\n"
    fi

    if [[ -n "${top_procs}" ]]; then
        tooltip+="────────────────────────\n"
        tooltip+="Top processes:\n${top_procs}"
    fi

    printf '{"text": "%s", "tooltip": "%s", "class": "%s", "percentage": %s}\n' \
        "${text}" "${tooltip}" "${class}" "${mem_pct}"
}

main() {
    local action="${1:-status}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        status | "")
            local info
            info=$(get_memory_info)
            format_output "${info}"
            ;;
        used)
            awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "%.0f\n", (t-a)/1024}' /proc/meminfo
            ;;
        total)
            awk '/MemTotal/{printf "%.0f\n", $2/1024}' /proc/meminfo
            ;;
        percent)
            awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "%.0f\n", (t-a)*100/t}' /proc/meminfo
            ;;
        *)
            echo "Usage: memory.sh [status|used|total|percent]"
            exit 1
            ;;
    esac
}

main "$@"