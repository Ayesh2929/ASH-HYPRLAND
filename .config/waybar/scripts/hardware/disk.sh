#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WAYBAR DISK MODULE                           ║
# ║           Multi-mountpoint disk usage with IO stats                        ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/disk.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# Mountpoints to monitor
readonly -a WATCH_MOUNTS=("/" "/home" "/boot" "/tmp" "/var")

# ═══════════════════════════════════════════════════════════════════════════════
# 💾 DISK STATS
# ═══════════════════════════════════════════════════════════════════════════════

get_disk_stats() {
    local mount="${1:-/}"

    local df_output
    df_output=$(df -h "${mount}" 2>/dev/null | tail -1)

    if [[ -z "${df_output}" ]]; then
        echo "0|0|0|0|?"
        return 0
    fi

    local total used avail pct fstype
    read -r _ total used avail pct _ <<< "${df_output}"
    pct="${pct//%/}"

    # Filesystem type
    fstype=$(findmnt -n -o FSTYPE "${mount}" 2>/dev/null || echo "?")

    echo "${used}|${avail}|${total}|${pct}|${fstype}"
}

get_all_disks() {
    local output=""

    for mount in "${WATCH_MOUNTS[@]}"; do
        if mountpoint -q "${mount}" 2>/dev/null || [[ "${mount}" == "/" ]]; then
            local stats
            stats=$(get_disk_stats "${mount}")
            local used avail total pct fstype
            IFS='|' read -r used avail total pct fstype <<< "${stats}"
            output+="${mount}: ${used}/${total} (${pct}%)\n"
        fi
    done

    echo -e "${output}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 FORMAT OUTPUT
# ═══════════════════════════════════════════════════════════════════════════════

format_output() {
    local mount="${1:-/}"

    local stats
    stats=$(get_disk_stats "${mount}")

    local used avail total pct fstype
    IFS='|' read -r used avail total pct fstype <<< "${stats}"

    # Determine class
    local class icon
    if (( pct >= 90 )); then
        class="critical"; icon="󰋊"
    elif (( pct >= 75 )); then
        class="warning";  icon="󰋊"
    elif (( pct >= 50 )); then
        class="moderate"; icon="󰋊"
    else
        class="normal";   icon="󰋊"
    fi

    # All disks for tooltip
    local all_disks
    all_disks=$(get_all_disks)

    local tooltip
    tooltip="󰋊 Disk Usage\n"
    tooltip+="────────────────────\n"
    tooltip+="${all_disks}"
    tooltip+="────────────────────\n"
    tooltip+="Root: ${used} used / ${avail} free\n"
    tooltip+="Total: ${total}\n"
    tooltip+="FS: ${fstype}"

    printf '{"text": "%s %s%%", "tooltip": "%s", "class": "%s", "percentage": %s}\n' \
        "${icon}" "${pct}" "${tooltip}" "${class}" "${pct}"
}

main() {
    local action="${1:-status}"
    local mount="${2:-/}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        status | "")  format_output "${mount}" ;;
        used)
            local stats
            stats=$(get_disk_stats "${mount}")
            echo "${stats}" | cut -d'|' -f1
            ;;
        avail)
            local stats
            stats=$(get_disk_stats "${mount}")
            echo "${stats}" | cut -d'|' -f2
            ;;
        percent)
            local stats
            stats=$(get_disk_stats "${mount}")
            echo "${stats}" | cut -d'|' -f4
            ;;
        all)  get_all_disks ;;
        *)
            echo "Usage: disk.sh [status|used|avail|percent|all] [mountpoint]"
            exit 1
            ;;
    esac
}

main "$@"