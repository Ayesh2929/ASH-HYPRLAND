#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  hw disk                                                 ║
# ║  Block devices • filesystems • NVMe health • S.M.A.R.T. • I/O stats            ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_HW_DISK_LOADED:-}" == "1" ]] && return 0
readonly _ASH_HW_DISK_LOADED=1

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  DATA COLLECTORS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_disk_list_block_devs() {
    # NAME  SIZE  ROTA  MODEL  TRAN  FSTYPE  MOUNTPOINT
    lsblk -dno NAME,SIZE,ROTA,MODEL,TRAN \
          --sort NAME 2>/dev/null | \
    grep -v '^loop\|^sr'
}

_disk_partitions() {
    local dev="${1:-}"
    lsblk -no NAME,SIZE,FSTYPE,MOUNTPOINT,TYPE \
          "${dev:+/dev/$dev}" 2>/dev/null | \
    grep -v '^loop'
}

_disk_io_stats() {
    local dev="$1"
    # /proc/diskstats fields: reads completed, reads merged, sectors read,
    #   ms reading, writes completed, writes merged, sectors written, ms writing
    local stats
    stats="$(awk -v d="$dev" '$3==d{print $4,$6,$8,$10}' \
             /proc/diskstats 2>/dev/null | head -1)"
    printf '%s' "${stats:-0 0 0 0}"
}

_disk_smart_health() {
    local dev="$1"
    if ! command -v smartctl &>/dev/null; then
        printf 'smartmontools not installed'
        return
    fi

    local health
    health="$(sudo -n smartctl -H "/dev/${dev}" 2>/dev/null | \
              grep 'SMART overall-health' | awk '{print $NF}' || \
              echo 'requires root')"
    printf '%s' "${health:-unknown}"
}

_disk_nvme_health() {
    local dev="$1"
    if command -v nvme &>/dev/null; then
        local nvme_out
        nvme_out="$(sudo -n nvme smart-log "/dev/${dev}" 2>/dev/null || echo '')"

        if [[ -n "$nvme_out" ]]; then
            local wear_level temp data_read data_written
            wear_level="$(    printf '%s' "$nvme_out" | grep 'percentage_used' | awk '{print $NF}')"
            temp="$(          printf '%s' "$nvme_out" | grep 'temperature'     | awk 'NR==1{print $NF}')"
            data_read="$(     printf '%s' "$nvme_out" | grep 'data_units_read' | awk '{print $NF}')"
            data_written="$(  printf '%s' "$nvme_out" | grep 'data_units_writ' | awk '{print $NF}')"

            hw_kv "NVMe Wear"     "${wear_level:-?}%"
            [[ -n "$temp" ]] && hw_kv "NVMe Temp" "${temp}°C"
        fi
    fi
}

_disk_ssd_trim_last() {
    systemctl status fstrim 2>/dev/null | \
        grep 'TriggeredBy\|ExecStart\|Active:' | head -3 | \
        sed 's/^[[:space:]]*//' || echo 'unknown'
}

_disk_fs_usage() {
    df -hT --output=source,fstype,size,used,avail,pcent,target 2>/dev/null | \
    tail -n +2 | \
    grep -v 'tmpfs\|devtmpfs\|devpts\|proc\|sysfs\|cgroup\|efivarfs\|bpf\|pstore'
}

_disk_inode_usage() {
    local dev="$1"
    df -i "${dev:+/dev/$dev}" 2>/dev/null | tail -n +2 | head -5
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RENDER ONE DISK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_disk_render_one() {
    local name="$1" size="$2" rota="$3" model="$4" tran="$5"

    local disk_type disk_icon disk_color
    if [[ "$rota" == "0" ]]; then
        if printf '%s' "$tran" | grep -qi 'nvme'; then
            disk_type="NVMe SSD"
            disk_icon="⚡"
            disk_color="$(_hw_mauve)"
        else
            disk_type="SATA SSD"
            disk_icon="💿"
            disk_color="$(_hw_blue)"
        fi
    else
        disk_type="HDD"
        disk_icon="🖴"
        disk_color="$(_hw_peach)"
    fi

    printf '\n  %s%s%s  %s/dev/%s%s  %s%s%s  %s%s%s\n' \
        "$disk_color" "$(_hw_bold)" "$disk_icon" \
        "$(_hw_sky)" "$(_hw_bold)" "$name" "$(_hw_r)" \
        "$(_hw_dim)" "($disk_type  •  $size)" "$(_hw_r)" \
        "$(_hw_dim)" "$model" "$(_hw_r)"

    # Partitions
    local -a parts=()
    mapfile -t parts < <(_disk_partitions "$name" | grep -v "^${name} " || true)

    if [[ ${#parts[@]} -gt 0 ]]; then
        printf '  %s  Partitions:%s\n' "$(_hw_dim)" "$(_hw_r)"
        for part_line in "${parts[@]}"; do
            [[ -z "$part_line" ]] && continue
            local pname psize pfs pmnt ptype
            read -r pname psize pfs pmnt ptype <<< "$part_line"
            printf '    %s├─ /dev/%-12s%s %s%-8s%s %-10s %s%s%s\n' \
                "$(_hw_dim)" "$pname" "$(_hw_r)" \
                "$(_hw_teal)" "$psize" "$(_hw_r)" \
                "${pfs:-raw}" \
                "$(_hw_sky)" "${pmnt:---}" "$(_hw_r)"
        done
    fi

    # NVMe specific health
    if printf '%s' "$name" | grep -q '^nvme'; then
        _disk_nvme_health "$name"
    fi

    # SMART health
    local smart
    smart="$(_disk_smart_health "$name")"
    hw_kv "S.M.A.R.T." "$smart"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FILESYSTEM USAGE TABLE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_disk_fs_table() {
    printf '\n  %s%-20s %-8s %-6s %-6s %-6s %-5s %s%s\n' \
        "$(_hw_dim)" \
        "Filesystem" "Type" "Size" "Used" "Avail" "Use%" "Mountpoint" \
        "$(_hw_r)"

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local src fstype size used avail pcent mnt
        read -r src fstype size used avail pcent mnt <<< "$line"

        local pct="${pcent//%/}"
        local bar_color
        if   [[ "$pct" =~ ^[0-9]+$ ]] && (( pct >= 90 )); then
            bar_color="$(_hw_red)"
        elif [[ "$pct" =~ ^[0-9]+$ ]] && (( pct >= 75 )); then
            bar_color="$(_hw_yellow)"
        else
            bar_color="$(_hw_green)"
        fi

        printf '  %-20s %-8s %-6s %-6s %-6s %s%-5s%s %s\n' \
            "${src:-?}" "${fstype:-?}" \
            "${size:-?}" "${used:-?}" "${avail:-?}" \
            "$bar_color" "${pcent:-?}" "$(_hw_r)" \
            "${mnt:-?}"

    done < <(_disk_fs_usage)
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_hw_disk() {
    local target_dev=""
    local short=0

    for arg in "${@:-}"; do
        case "$arg" in
            --short) short=1 ;;
            /dev/*)  target_dev="${arg#/dev/}" ;;
            *)       [[ "$arg" =~ ^[a-z] ]] && target_dev="$arg" ;;
        esac
    done

    hw_section "💿" "Disk & Storage" "$(_hw_sky)"

    if [[ $short -eq 1 ]]; then
        _disk_fs_table
        return 0
    fi

    hw_section "🗜" "Block Devices" "$(_hw_teal)"

    local dev_found=0
    while IFS= read -r dev_line; do
        [[ -z "$dev_line" ]] && continue
        local name size rota model tran
        read -r name size rota model tran <<< "$dev_line"

        if [[ -n "$target_dev" ]] && [[ "$name" != "$target_dev" ]]; then
            continue
        fi

        _disk_render_one "$name" "$size" "$rota" "$model" "$tran"
        (( dev_found++ )) || true

    done < <(_disk_list_block_devs)

    if (( dev_found == 0 )); then
        printf '\n  %sNo block devices found%s\n' "$(_hw_yellow)" "$(_hw_r)"
    fi

    hw_section "📁" "Filesystem Usage" "$(_hw_blue)"
    _disk_fs_table

    hw_section "✂" "SSD TRIM" "$(_hw_green)"
    hw_kv "fstrim.timer" \
        "$(systemctl is-active fstrim.timer 2>/dev/null || echo 'inactive')"

    hw_divider
}
