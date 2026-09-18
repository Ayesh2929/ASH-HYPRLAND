#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  hw memory                                               ║
# ║  RAM usage • swap • DIMM slots • speed • type • pressure indicators             ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_HW_MEMORY_LOADED:-}" == "1" ]] && return 0
readonly _ASH_HW_MEMORY_LOADED=1

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  DATA COLLECTORS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_mem_parse_meminfo() {
    declare -gA _MEMINFO=()
    while IFS=':' read -r key val; do
        local k="${key// /}"
        local v
        v="$(printf '%s' "$val" | awk '{printf "%.0f", $1 * 1024}')"
        _MEMINFO["$k"]="$v"
    done < <(grep -E '^(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree|Active|Inactive|Dirty|Shmem|Mapped|HugePages_Total|HugePages_Free)' \
                  /proc/meminfo 2>/dev/null)
}

_mem_total()     { printf '%s' "${_MEMINFO[MemTotal]:-0}"; }
_mem_available() { printf '%s' "${_MEMINFO[MemAvailable]:-0}"; }
_mem_used()      { printf '%d' "$(( ${_MEMINFO[MemTotal]:-0} - ${_MEMINFO[MemAvailable]:-0} ))"; }
_mem_buffers()   { printf '%s' "${_MEMINFO[Buffers]:-0}"; }
_mem_cached()    { printf '%s' "${_MEMINFO[Cached]:-0}"; }
_mem_dirty()     { printf '%s' "${_MEMINFO[Dirty]:-0}"; }
_mem_swap_total(){ printf '%s' "${_MEMINFO[SwapTotal]:-0}"; }
_mem_swap_free() { printf '%s' "${_MEMINFO[SwapFree]:-0}"; }
_mem_swap_used() { printf '%d' "$(( ${_MEMINFO[SwapTotal]:-0} - ${_MEMINFO[SwapFree]:-0} ))"; }

_mem_used_pct() {
    local total="${_MEMINFO[MemTotal]:-1}"
    local used
    used="$(_mem_used)"
    (( total > 0 )) && printf '%d' "$(( used * 100 / total ))" || printf '0'
}

_mem_swap_pct() {
    local total="${_MEMINFO[SwapTotal]:-0}"
    local used
    used="$(_mem_swap_used)"
    (( total > 0 )) && printf '%d' "$(( used * 100 / total ))" || printf '0'
}

_mem_dimm_info() {
    # Try dmidecode (requires root) or decode from sysfs
    if command -v dmidecode &>/dev/null && sudo -n dmidecode &>/dev/null 2>&1; then
        sudo dmidecode -t memory 2>/dev/null | \
            awk '/Memory Device/,/^$/' | \
            grep -E 'Size:|Type:|Speed:|Manufacturer:|Locator:|Part Number:' | \
            grep -v 'No Module' | head -30
    else
        printf '  (root required: sudo ash hw memory --dimm)\n'
    fi
}

_mem_huge_pages() {
    local total="${_MEMINFO[HugePages_Total]:-0}"
    local free="${_MEMINFO[HugePages_Free]:-0}"
    local pagesize
    pagesize="$(cat /proc/meminfo 2>/dev/null | \
               awk '/Hugepagesize/{print $2*1024}')"

    if (( total > 0 )); then
        local used=$(( total - free ))
        printf '%d used / %d total  (%s each)' \
            "$used" "$total" "$(hw_human_bytes "${pagesize:-2097152}")"
    else
        printf 'not configured'
    fi
}

_mem_pressure() {
    # Linux PSI (Pressure Stall Information)
    local psi_file="/proc/pressure/memory"
    if [[ -r "$psi_file" ]]; then
        local some_avg10
        some_avg10="$(awk '/^some/{print $2}' "$psi_file" | \
                      cut -d= -f2)"
        local full_avg10
        full_avg10="$(awk '/^full/{print $2}' "$psi_file" | \
                      cut -d= -f2)"
        printf 'some=%.1f%%  full=%.1f%%' \
            "${some_avg10:-0}" "${full_avg10:-0}"
    else
        printf 'PSI not available'
    fi
}

_mem_oom_score_top() {
    # Top 5 processes by OOM score
    local results=()
    for pid_dir in /proc/[0-9]*/; do
        local pid="${pid_dir%/}"
        pid="${pid##*/proc/}"
        local oom_score
        oom_score="$(cat "${pid_dir}oom_score" 2>/dev/null || echo 0)"
        local comm
        comm="$(cat "${pid_dir}comm" 2>/dev/null || echo '?')"
        local rss_kb
        rss_kb="$(awk '/^VmRSS:/{print $2}' "${pid_dir}status" 2>/dev/null || echo 0)"
        (( oom_score > 0 )) && results+=("${oom_score} ${comm} ${rss_kb}")
    done

    # Sort and take top 5
    printf '%s\n' "${results[@]:-}" | sort -rn | head -5
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MEMORY USAGE VISUALIZER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_mem_visualize() {
    local total="${_MEMINFO[MemTotal]:-1}"
    local used
    used="$(_mem_used)"
    local buffers
    buffers="$(_mem_buffers)"
    local cached
    cached="$(_mem_cached)"
    local free=$(( total - used - buffers - cached ))
    (( free < 0 )) && free=0

    local width=52

    local used_w=$(( used * width / total ))
    local buf_w=$(( buffers * width / total ))
    local cache_w=$(( cached * width / total ))
    local free_w=$(( width - used_w - buf_w - cache_w ))
    (( free_w < 0 )) && free_w=0

    printf '\n  %sRAM%s  [' "$(_hw_bold)" "$(_hw_r)"

    # Used (red/yellow/green based on %)
    local used_pct
    used_pct="$(_mem_used_pct)"
    local uc
    if (( used_pct >= 90 )); then uc="$(_hw_red)"
    elif (( used_pct >= 75 )); then uc="$(_hw_yellow)"
    else uc="$(_hw_green)"
    fi

    printf '%s%s%s' "$uc" "$(printf '█%.0s' $(seq 1 "$used_w"))" "$(_hw_r)"
    printf '%s%s%s' "$(_hw_blue)"   "$(printf '▒%.0s' $(seq 1 "$buf_w"))"   "$(_hw_r)"
    printf '%s%s%s' "$(_hw_teal)"   "$(printf '░%.0s' $(seq 1 "$cache_w"))" "$(_hw_r)"
    printf '%s%s%s' "$(_hw_dim)"    "$(printf ' %.0s' $(seq 1 "$free_w"))"  "$(_hw_r)"

    printf ']  %s%d%%%s\n\n' "$(_hw_bold)" "$used_pct" "$(_hw_r)"

    printf '  %s█%s Used: %-10s' "$uc" "$(_hw_r)" \
        "$(hw_human_bytes "$used")"
    printf '  %s▒%s Buffers: %-8s' "$(_hw_blue)" "$(_hw_r)" \
        "$(hw_human_bytes "$buffers")"
    printf '  %s░%s Cache: %-8s\n' "$(_hw_teal)" "$(_hw_r)" \
        "$(hw_human_bytes "$cached")"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_hw_memory() {
    local show_dimm=0
    local show_top=0
    local short=0

    for arg in "${@:-}"; do
        [[ "$arg" == "--dimm"  ]] && show_dimm=1
        [[ "$arg" == "--top"   ]] && show_top=1
        [[ "$arg" == "--short" ]] && short=1
    done

    _mem_parse_meminfo

    local total available used swap_total swap_used

    total="$(     hw_human_bytes "$(_mem_total)")"
    available="$( hw_human_bytes "$(_mem_available)")"
    used="$(      hw_human_bytes "$(_mem_used)")"
    swap_total="$(hw_human_bytes "$(_mem_swap_total)")"
    swap_used="$( hw_human_bytes "$(_mem_swap_used)")"

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        printf '{\n'
        printf '  "total_bytes": %s,\n'     "$(_mem_total)"
        printf '  "used_bytes": %s,\n'      "$(_mem_used)"
        printf '  "available_bytes": %s,\n' "$(_mem_available)"
        printf '  "swap_total_bytes": %s,\n' "$(_mem_swap_total)"
        printf '  "swap_used_bytes": %s\n'  "$(_mem_swap_used)"
        printf '}\n'
        return 0
    fi

    hw_section "🧠" "Memory" "$(_hw_mauve)"

    if [[ $short -eq 1 ]]; then
        hw_kv "RAM"   "${used} used / ${total} total  ($(_mem_used_pct)%)"
        hw_kv "Swap"  "${swap_used} used / ${swap_total} total"
        return 0
    fi

    # Visual bar
    _mem_visualize

    hw_section "📊" "RAM Details" "$(_hw_blue)"
    hw_kv "Total"      "$total"
    hw_kv "Used"       "$used  ($(_mem_used_pct)%)"
    hw_kv "Available"  "$available"
    hw_kv "Buffers"    "$(hw_human_bytes "$(_mem_buffers)")"
    hw_kv "Cache"      "$(hw_human_bytes "$(_mem_cached)")"
    hw_kv "Dirty"      "$(hw_human_bytes "$(_mem_dirty)")"
    hw_kv "Huge Pages" "$(_mem_huge_pages)"

    hw_section "💿" "Swap" "$(_hw_peach)"
    if [[ "$(_mem_swap_total)" -eq 0 ]]; then
        printf '  %s  No swap configured%s\n' "$(_hw_yellow)" "$(_hw_r)"
        printf '  %sConsider: sudo mkswap /swapfile && sudo swapon /swapfile%s\n' \
            "$(_hw_dim)" "$(_hw_r)"
    else
        hw_bar "Swap" "$(_mem_swap_pct)" \
            "${swap_used} / ${swap_total}"
        hw_kv "Swappiness" \
            "$(cat /proc/sys/vm/swappiness 2>/dev/null || echo '?')"
    fi

    hw_section "🔬" "Memory Pressure  (PSI)" "$(_hw_teal)"
    hw_kv "Pressure" "$(_mem_pressure)"

    hw_kv "vm.dirty_ratio" \
        "$(cat /proc/sys/vm/dirty_ratio 2>/dev/null || echo '?')%"
    hw_kv "vm.dirty_bg_ratio" \
        "$(cat /proc/sys/vm/dirty_background_ratio 2>/dev/null || echo '?')%"

    if [[ $show_dimm -eq 1 ]]; then
        hw_section "🔌" "DIMM Slots  (dmidecode)" "$(_hw_lavender)"
        _mem_dimm_info | while IFS= read -r dline; do
            [[ -z "$dline" ]] && continue
            printf '  %s%s%s\n' "$(_hw_dim)" "$dline" "$(_hw_r)"
        done
    fi

    if [[ $show_top -eq 1 ]]; then
        hw_section "🔝" "Top Processes by OOM Score" "$(_hw_red)"
        printf '  %s%-8s %-20s %s%s\n' \
            "$(_hw_dim)" "OOM" "Process" "RSS" "$(_hw_r)"

        while IFS=' ' read -r score comm rss_kb; do
            [[ -z "$score" ]] && continue
            printf '  %s%-8s%s %-20s %s%s\n' \
                "$(_hw_peach)" "$score" "$(_hw_r)" \
                "$comm" \
                "$(hw_human_bytes "$(( ${rss_kb:-0} * 1024 ))")" \
                "$(_hw_r)"
        done < <(_mem_oom_score_top)
    fi

    hw_divider
}
