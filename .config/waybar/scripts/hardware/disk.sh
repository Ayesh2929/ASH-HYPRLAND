#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WAYBAR DISK MODULE                           ║
# ║           Multiple mount points with progress bars and IO stats            ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"

# Mount points to monitor
readonly -a MOUNT_POINTS=("/" "/home" "/boot" "/tmp" "/var")

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 DISK DATA
# ═══════════════════════════════════════════════════════════════════════════════

get_disk_info() {
    local mount="${1:-/}"

    if ! mountpoint -q "${mount}" 2>/dev/null && [[ "${mount}" != "/" ]]; then
        return 1
    fi

    local info
    info=$(df -BM "${mount}" 2>/dev/null | awk 'NR==2 {
        total = $2
        used  = $3
        avail = $4
        pct   = $5
        gsub(/M/, "", total)
        gsub(/M/, "", used)
        gsub(/M/, "", avail)
        gsub(/%/, "", pct)
        printf "%s|%s|%s|%s", total, used, avail, pct
    }') || return 1

    echo "${info}"
}

format_size() {
    local mb="$1"
    if (( mb >= 1024 )); then
        awk "BEGIN{printf \"%.1fG\", ${mb}/1024}"
    else
        echo "${mb}M"
    fi
}

build_bar() {
    local pct="$1"
    local width=8
    local filled=$(( pct * width / 100 ))
    local bar=""
    for (( i=0; i<filled; i++ )); do bar+="█"; done
    for (( i=filled; i<width; i++ )); do bar+="░"; done
    echo "${bar}"
}

get_disk_io() {
    # Get disk I/O stats if iostat is available
    if command -v iostat &>/dev/null; then
        iostat -d -k 1 1 2>/dev/null \
            | awk 'NR>3 && $1!="" {printf "%s: R:%.0fK/s W:%.0fK/s\n", $1, $3, $4}' \
            | head -3
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-status}"

    mkdir -p "${CACHE_DIR}"

    case "${action}" in
        status | "")
            # Get root filesystem stats
            local root_info
            root_info=$(get_disk_info "/") || {
                printf '{"text": "󰋊 N/A", "class": "error"}\n'
                return 0
            }

            local total used avail pct
            IFS='|' read -r total used avail pct <<< "${root_info}"

            local used_h avail_h total_h
            used_h=$(format_size "${used}")
            avail_h=$(format_size "${avail}")
            total_h=$(format_size "${total}")

            # Icon and class
            local icon class
            if (( pct >= 90 )); then
                icon="󰪥"
                class="critical"
            elif (( pct >= 75 )); then
                icon="󰪤"
                class="warning"
            elif (( pct >= 50 )); then
                icon="󰪣"
                class="moderate"
            else
                icon="󰋊"
                class="normal"
            fi

            # Build tooltip with all mount points
            local tooltip="󰋊 Disk Usage\n"
            tooltip+="─────────────────────────────────\n"

            for mount in "${MOUNT_POINTS[@]}"; do
                local info
                info=$(get_disk_info "${mount}" 2>/dev/null) || continue

                local m_total m_used m_avail m_pct
                IFS='|' read -r m_total m_used m_avail m_pct <<< "${info}"

                local bar
                bar=$(build_bar "${m_pct}")
                local m_used_h m_total_h
                m_used_h=$(format_size "${m_used}")
                m_total_h=$(format_size "${m_total}")

                local m_icon="󰋊"
                (( m_pct >= 90 )) && m_icon="󰪥"
                (( m_pct >= 75 )) && m_icon="󰪤"

                tooltip+="${m_icon} ${mount}\n"
                tooltip+="   ${bar} ${m_pct}%  (${m_used_h}/${m_total_h}, ${m_avail_h} free)\n"
            done

            # Add IO stats
            local io_stats
            io_stats=$(get_disk_io 2>/dev/null || echo "")
            if [[ -n "${io_stats}" ]]; then
                tooltip+="─────────────────────────────────\n"
                tooltip+="I/O Stats:\n${io_stats}\n"
            fi

            local text="${icon} ${used_h}/${total_h}"

            printf '{"text": "%s", "tooltip": "%s", "class": "%s", "percentage": %s}\n' \
                "${text}" "${tooltip}" "${class}" "${pct}"
            ;;

        percent)
            df "/" | awk 'NR==2{print $5}' | tr -d '%'
            ;;

        used)
            df -BG "/" | awk 'NR==2{print $3}' | tr -d 'G'
            ;;

        free)
            df -BG "/" | awk 'NR==2{print $4}' | tr -d 'G'
            ;;

        all)
            for mount in "${MOUNT_POINTS[@]}"; do
                local info
                info=$(get_disk_info "${mount}" 2>/dev/null) || continue
                local total used avail pct
                IFS='|' read -r total used avail pct <<< "${info}"
                printf "%-15s %8s/%8s (%3s%%) %8s free\n" \
                    "${mount}" \
                    "$(format_size "${used}")" \
                    "$(format_size "${total}")" \
                    "${pct}" \
                    "$(format_size "${avail}")"
            done
            ;;

        *)
            echo "Usage: disk.sh [status|percent|used|free|all]"
            exit 1
            ;;
    esac
}

main "$@"