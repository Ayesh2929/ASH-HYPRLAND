#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██████╗ ███████╗██████╗ ███████╗ ██████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗║
# ║  ██╔══██╗██╔════╝██╔══██╗██╔════╝██╔═══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║║
# ║  ██████╔╝█████╗  ██████╔╝█████╗  ██║   ██║██████╔╝██╔████╔██║███████║██╔██╗ ██║║
# ║  ██╔═══╝ ██╔══╝  ██╔══██╗██╔══╝  ██║   ██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║║
# ║  ██║     ███████╗██║  ██║██║     ╚██████╔╝██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║║
# ║  ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  DOCTOR CHECK: PERFORMANCE                               ║
# ║  CPU governor • memory • I/O • compositor • GPU • power profiles                ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CHECK_PERFORMANCE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CHECK_PERFORMANCE_LOADED=1

# Sourced as a library by _common.sh, so shell options are only
# tightened when this file is EXECUTED directly. A sourced file that
# sets -e/-u rewrites the options of whoever loaded it — the first
# module would make the whole doctor process abort on any non-zero
# status or unset variable.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
fi
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PERFORMANCE SCORE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g  _PERF_SCORE=100
declare -ga _PERF_BOTTLENECKS=()
declare -ga _PERF_OPTIMIZATIONS=()

_perf_deduct() {
    local points="$1"
    local note="$2"
    (( _PERF_SCORE -= points )) || true
    _PERF_BOTTLENECKS+=("$note")
}

_perf_suggest() {
    _PERF_OPTIMIZATIONS+=("$1")
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 01 — CPU PERFORMANCE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_perf_cpu() {
    _check_header "⚡ CPU Performance"

    # ── CPU info ──────────────────────────────────────────────────────────────────
    local cpu_model
    cpu_model="$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | \
                 sed 's/.*: //' | sed 's/  */ /g')"
    local cpu_cores
    cpu_cores="$(nproc --all 2>/dev/null || grep -c '^processor' /proc/cpuinfo || echo '?')"
    local cpu_threads
    cpu_threads="$(nproc 2>/dev/null || echo '?')"
    local cpu_freq_mhz
    cpu_freq_mhz="$(grep 'cpu MHz' /proc/cpuinfo 2>/dev/null | \
                   awk '{sum+=$4; count++} END{if(count>0) printf "%.0f", sum/count}' || echo '?')"

    _check_report $CHECK_INFO \
        "CPU model" \
        "${cpu_model:-unknown}  (${cpu_cores}c/${cpu_threads}t @ ~${cpu_freq_mhz}MHz)"

    # ── CPU governor ──────────────────────────────────────────────────────────────
    local governor_file="/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
    if [[ -r "$governor_file" ]]; then
        local governor
        governor="$(cat "$governor_file" 2>/dev/null || echo 'unknown')"

        case "$governor" in
            performance)
                _check_report $CHECK_PASS \
                    "CPU governor" \
                    "performance  (maximum speed — good for desktop)"
                ;;
            schedutil)
                _check_report $CHECK_PASS \
                    "CPU governor" \
                    "schedutil  (kernel scheduler-guided — optimal)"
                ;;
            ondemand)
                _check_report $CHECK_INFO \
                    "CPU governor" \
                    "ondemand  (adequate — schedutil preferred)"
                _perf_suggest "Switch CPU governor: echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
                ;;
            powersave)
                _check_report $CHECK_WARN \
                    "CPU governor" \
                    "powersave  (reduced performance — use schedutil for desktop)" \
                    "Switch: echo schedutil | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
                _perf_deduct 15 "CPU in powersave mode"
                ;;
            conservative)
                _check_report $CHECK_WARN \
                    "CPU governor" \
                    "conservative  (slow to scale up)" \
                    "Switch: echo schedutil | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
                _perf_deduct 10 "CPU conservative governor"
                ;;
            *)
                _check_report $CHECK_INFO \
                    "CPU governor" \
                    "$governor"
                ;;
        esac

        # ── Available governors ───────────────────────────────────────────────────
        local avail_gov_file="/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors"
        if [[ -r "$avail_gov_file" ]]; then
            local avail_governors
            avail_governors="$(cat "$avail_gov_file" 2>/dev/null | tr ' ' '  ')"
            _check_report $CHECK_INFO \
                "Available governors" \
                "$avail_governors"
        fi
    else
        _check_report $CHECK_INFO \
            "CPU governor" \
            "cpufreq not available  (may be using intel_pstate)"

        # Check intel_pstate
        local pstate_status="/sys/devices/system/cpu/intel_pstate/status"
        if [[ -r "$pstate_status" ]]; then
            local pstate
            pstate="$(cat "$pstate_status")"
            _check_report $CHECK_INFO \
                "intel_pstate" \
                "$pstate"
        fi
    fi

    # ── CPU load average ─────────────────────────────────────────────────────────
    local load_1 load_5 load_15
    read -r load_1 load_5 load_15 _ < /proc/loadavg 2>/dev/null || load_1="?"

    local load_int="${load_1%.*}"
    local status=$CHECK_PASS
    local load_note=""

    if [[ "$load_int" =~ ^[0-9]+$ ]]; then
        if   (( load_int >= cpu_cores * 2 )); then
            status=$CHECK_FAIL
            load_note="  🔴 OVERLOADED"
            _perf_deduct 20 "CPU severely overloaded (load: ${load_1})"
        elif (( load_int >= cpu_cores )); then
            status=$CHECK_WARN
            load_note="  🟡 High load"
            _perf_deduct 10 "CPU load high (${load_1})"
        elif (( load_int >= cpu_cores / 2 )); then
            load_note="  🟠 Moderate"
        else
            load_note="  🟢 Idle"
        fi
    fi

    _check_report $status \
        "Load average" \
        "${load_1}  ${load_5}  ${load_15}  (1m  5m  15m)${load_note}"

    # ── CPU temperature ───────────────────────────────────────────────────────────
    local cpu_temp=""
    # Try hwmon
    for sensor_dir in /sys/class/hwmon/hwmon*/; do
        local sensor_name
        sensor_name="$(cat "${sensor_dir}name" 2>/dev/null || echo '')"
        if [[ "$sensor_name" =~ coretemp|k10temp|zenpower ]]; then
            local temp_mc
            temp_mc="$(cat "${sensor_dir}temp1_input" 2>/dev/null || echo '')"
            if [[ -n "$temp_mc" ]]; then
                cpu_temp=$(( temp_mc / 1000 ))
                break
            fi
        fi
    done

    if [[ -n "$cpu_temp" ]]; then
        local temp_status=$CHECK_PASS
        local temp_note=""
        if   (( cpu_temp >= 95 )); then
            temp_status=$CHECK_FAIL
            temp_note="  🔴 CRITICAL — thermal throttle imminent!"
            _perf_deduct 20 "CPU at critical temperature (${cpu_temp}°C)"
        elif (( cpu_temp >= 85 )); then
            temp_status=$CHECK_WARN
            temp_note="  🟡 Hot"
            _perf_deduct 10 "CPU running hot (${cpu_temp}°C)"
        elif (( cpu_temp >= 70 )); then
            temp_note="  🟠 Warm"
        else
            temp_note="  🟢 Cool"
        fi

        _check_report $temp_status \
            "CPU temperature" \
            "${cpu_temp}°C${temp_note}"
    fi

    # ── CPU frequency boosting ────────────────────────────────────────────────────
    local no_turbo="/sys/devices/system/cpu/intel_pstate/no_turbo"
    local boost="/sys/devices/system/cpu/cpufreq/boost"

    if [[ -r "$no_turbo" ]]; then
        local nt
        nt="$(cat "$no_turbo")"
        if [[ "$nt" == "0" ]]; then
            _check_report $CHECK_PASS "Intel Turbo Boost" "Enabled"
        else
            _check_report $CHECK_WARN \
                "Intel Turbo Boost" \
                "DISABLED  — reduced peak performance" \
                "Enable: echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo"
            _perf_deduct 8 "Turbo Boost disabled"
        fi
    elif [[ -r "$boost" ]]; then
        local bv
        bv="$(cat "$boost")"
        if [[ "$bv" == "1" ]]; then
            _check_report $CHECK_PASS "CPU Boost" "Enabled"
        else
            _check_report $CHECK_WARN \
                "CPU Boost" \
                "DISABLED" \
                "Enable: echo 1 | sudo tee /sys/devices/system/cpu/cpufreq/boost"
            _perf_deduct 8 "CPU Boost disabled"
        fi
    fi

    # ── power-profiles-daemon ─────────────────────────────────────────────────────
    if command -v powerprofilesctl &>/dev/null; then
        local active_profile
        active_profile="$(powerprofilesctl get 2>/dev/null || echo 'unknown')"
        case "$active_profile" in
            performance)
                _check_report $CHECK_PASS "power-profiles-daemon" "performance" ;;
            balanced)
                _check_report $CHECK_INFO "power-profiles-daemon" "balanced" ;;
            power-saver)
                _check_report $CHECK_WARN \
                    "power-profiles-daemon" \
                    "power-saver  (reduced performance)" \
                    "Switch: powerprofilesctl set balanced"
                _perf_deduct 8 "Power-saver profile active"
                ;;
        esac
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 02 — MEMORY PERFORMANCE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_perf_memory() {
    _check_header "🧠 Memory Performance"

    if [[ ! -f /proc/meminfo ]]; then
        _check_report $CHECK_SKIP "Memory" "/proc/meminfo not readable"
        return $CHECK_SKIP
    fi

    local total_kb avail_kb cached_kb buffers_kb swap_total_kb swap_free_kb
    total_kb="$(   awk '/^MemTotal:/{print $2}'     /proc/meminfo)"
    avail_kb="$(   awk '/^MemAvailable:/{print $2}' /proc/meminfo)"
    cached_kb="$(  awk '/^Cached:/{print $2}'       /proc/meminfo)"
    buffers_kb="$( awk '/^Buffers:/{print $2}'      /proc/meminfo)"
    swap_total_kb="$(awk '/^SwapTotal:/{print $2}'  /proc/meminfo)"
    swap_free_kb="$( awk '/^SwapFree:/{print $2}'   /proc/meminfo)"

    local total_gb=$(( total_kb / 1048576 ))
    local avail_gb=$(( avail_kb / 1048576 ))
    local used_kb=$(( total_kb - avail_kb ))
    local used_pct=$(( used_kb * 100 / total_kb ))

    # ── Total RAM ─────────────────────────────────────────────────────────────────
    if   (( total_gb >= 32 )); then
        _check_report $CHECK_PASS "Total RAM" "${total_gb}GB  (excellent)"
    elif (( total_gb >= 16 )); then
        _check_report $CHECK_PASS "Total RAM" "${total_gb}GB  (great)"
    elif (( total_gb >= 8 )); then
        _check_report $CHECK_PASS "Total RAM" "${total_gb}GB  (good)"
    elif (( total_gb >= 4 )); then
        _check_report $CHECK_WARN \
            "Total RAM" \
            "${total_gb}GB  (minimum — consider upgrading)" \
            "Hyprland with compositor effects needs 8GB+"
        _perf_deduct 10 "Low RAM: ${total_gb}GB"
    else
        _check_report $CHECK_FAIL \
            "Total RAM" \
            "${total_gb}GB  (insufficient)"
        _perf_deduct 20 "Critically low RAM: ${total_gb}GB"
    fi

    # ── Available RAM ─────────────────────────────────────────────────────────────
    local mem_status=$CHECK_PASS
    if   (( used_pct >= 90 )); then
        mem_status=$CHECK_FAIL
        _perf_deduct 15 "Memory critically low (${used_pct}% used)"
    elif (( used_pct >= 80 )); then
        mem_status=$CHECK_WARN
        _perf_deduct 8 "Memory pressure high (${used_pct}% used)"
    fi

    # Memory pressure bar
    local mem_bar
    mem_bar=""
    local bar_w=25
    local filled=$(( used_pct * bar_w / 100 ))
    local empty=$(( bar_w - filled ))
    local i
    for (( i=0; i<filled; i++ )); do mem_bar+='█'; done
    for (( i=0; i<empty;  i++ )); do mem_bar+='░'; done

    _check_report $mem_status \
        "RAM usage" \
        "${mem_bar}  ${used_pct}%  (${avail_gb}GB free / ${total_gb}GB)"

    # ── Cache / Buffers ──────────────────────────────────────────────────────────
    local cache_mb=$(( (cached_kb + buffers_kb) / 1024 ))
    _check_report $CHECK_INFO \
        "Page cache" \
        "${cache_mb}MB  (kernel disk cache — more = faster I/O)"

    # ── Swap usage ────────────────────────────────────────────────────────────────
    if (( swap_total_kb > 0 )); then
        local swap_total_gb=$(( swap_total_kb / 1048576 ))
        local swap_used_kb=$(( swap_total_kb - swap_free_kb ))
        local swap_pct=$(( swap_used_kb * 100 / swap_total_kb ))

        if (( swap_pct >= 50 )); then
            _check_report $CHECK_WARN \
                "Swap usage" \
                "${swap_pct}%  (${swap_total_gb}GB)  — memory pressure!" \
                "Add more RAM or reduce memory usage"
            _perf_deduct 10 "Heavy swap usage (${swap_pct}%)"
        elif (( swap_pct >= 20 )); then
            _check_report $CHECK_INFO \
                "Swap usage" \
                "${swap_pct}%  (${swap_total_gb}GB)"
        else
            _check_report $CHECK_PASS \
                "Swap usage" \
                "${swap_pct}%  (${swap_total_gb}GB)  — minimal"
        fi
    else
        _check_report $CHECK_WARN \
            "Swap" \
            "Not configured" \
            "Create swap: ash doctor fix --swap  (prevents OOM crashes)"
    fi

    # ── vm.swappiness ────────────────────────────────────────────────────────────
    local swappiness
    swappiness="$(cat /proc/sys/vm/swappiness 2>/dev/null || echo '?')"
    if [[ "$swappiness" =~ ^[0-9]+$ ]]; then
        if (( swappiness <= 20 )); then
            _check_report $CHECK_PASS \
                "vm.swappiness" \
                "${swappiness}  (low — RAM preferred)"
        elif (( swappiness <= 60 )); then
            _check_report $CHECK_INFO \
                "vm.swappiness" \
                "${swappiness}  (default — acceptable)"
            _perf_suggest "Lower swappiness for desktop: echo 10 | sudo tee /proc/sys/vm/swappiness"
        else
            _check_report $CHECK_WARN \
                "vm.swappiness" \
                "${swappiness}  (high — system swaps aggressively)" \
                "Lower: sudo sysctl -w vm.swappiness=10"
            _perf_deduct 5 "Swappiness too high (${swappiness})"
        fi
    fi

    # ── Huge pages ───────────────────────────────────────────────────────────────
    local hugepages_total
    hugepages_total="$(cat /proc/sys/vm/nr_hugepages 2>/dev/null || echo '?')"
    if [[ "$hugepages_total" =~ ^[0-9]+$ ]] && (( hugepages_total > 0 )); then
        _check_report $CHECK_INFO \
            "Huge pages" \
            "${hugepages_total} huge page(s) configured"
    fi

    # ── OOM score adj for Hyprland ────────────────────────────────────────────────
    if pgrep -x Hyprland &>/dev/null; then
        local hypr_pid
        hypr_pid="$(pgrep -x Hyprland | head -1)"
        local oom_adj
        oom_adj="$(cat "/proc/${hypr_pid}/oom_score_adj" 2>/dev/null || echo '?')"
        if [[ "$oom_adj" =~ ^-?[0-9]+$ ]] && (( oom_adj < -100 )); then
            _check_report $CHECK_PASS \
                "Hyprland OOM score" \
                "${oom_adj}  (protected from OOM killer)"
        else
            _check_report $CHECK_INFO \
                "Hyprland OOM score" \
                "${oom_adj}  (may be killed under memory pressure)" \
                "Protect: echo -500 | sudo tee /proc/${hypr_pid}/oom_score_adj"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 03 — I/O PERFORMANCE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_perf_io() {
    _check_header "💿 I/O & Storage Performance"

    # ── Block devices ─────────────────────────────────────────────────────────────
    local -a block_devs=()
    mapfile -t block_devs < <(
        lsblk -dno NAME,ROTA,SIZE,MODEL 2>/dev/null | grep -v '^loop\|^sr'
    )

    for blk_line in "${block_devs[@]}"; do
        [[ -z "$blk_line" ]] && continue
        local dev_name rotational size model
        read -r dev_name rotational size model <<< "$blk_line"
        local dev_type
        [[ "$rotational" == "0" ]] && dev_type="SSD/NVMe" || dev_type="HDD"

        _check_report $CHECK_INFO \
            "Block device: /dev/${dev_name}" \
            "${dev_type}  •  ${size}  •  ${model:-unknown}"

        if [[ "$rotational" == "1" ]]; then
            _check_report $CHECK_WARN \
                "  └─ Storage type" \
                "HDD detected  — SSD/NVMe strongly recommended for Wayland" \
                "SSDs eliminate I/O bottlenecks in compositor animations"
            _perf_deduct 15 "HDD storage: ${dev_name}"
        fi
    done

    # ── I/O scheduler ────────────────────────────────────────────────────────────
    for dev_sched in /sys/block/*/queue/scheduler; do
        [[ -r "$dev_sched" ]] || continue
        local dev_name="${dev_sched%/queue/scheduler}"
        dev_name="${dev_name##*/}"

        # Skip loop/optical
        [[ "$dev_name" =~ ^loop|^sr ]] && continue

        local scheduler
        scheduler="$(cat "$dev_sched" 2>/dev/null | grep -oP '\[.*?\]' | tr -d '[]')"

        local is_rotational
        is_rotational="$(cat "/sys/block/${dev_name}/queue/rotational" \
                        2>/dev/null || echo '?')"

        if [[ "$is_rotational" == "0" ]]; then
            # SSD — prefer none or mq-deadline
            case "$scheduler" in
                none|mq-deadline|kyber)
                    _check_report $CHECK_PASS \
                        "I/O scheduler (${dev_name})" \
                        "${scheduler}  (optimal for SSD)"
                    ;;
                bfq)
                    _check_report $CHECK_INFO \
                        "I/O scheduler (${dev_name})" \
                        "${scheduler}  (SSD: prefer none/mq-deadline)"
                    _perf_suggest "Switch scheduler: echo none > /sys/block/${dev_name}/queue/scheduler"
                    ;;
                *)
                    _check_report $CHECK_INFO \
                        "I/O scheduler (${dev_name})" \
                        "${scheduler:-unknown}"
                    ;;
            esac
        else
            # HDD — prefer bfq
            case "$scheduler" in
                bfq|mq-deadline)
                    _check_report $CHECK_PASS \
                        "I/O scheduler (${dev_name})" \
                        "${scheduler}  (good for HDD)"
                    ;;
                *)
                    _check_report $CHECK_INFO \
                        "I/O scheduler (${dev_name})" \
                        "${scheduler}  (HDD: bfq recommended)"
                    ;;
            esac
        fi
    done

    # ── vm.dirty_ratio tuning ────────────────────────────────────────────────────
    local dirty_ratio
    dirty_ratio="$(cat /proc/sys/vm/dirty_ratio 2>/dev/null || echo '?')"
    local dirty_bg
    dirty_bg="$(cat /proc/sys/vm/dirty_background_ratio 2>/dev/null || echo '?')"

    if [[ "$dirty_ratio" =~ ^[0-9]+$ ]]; then
        _check_report $CHECK_INFO \
            "vm.dirty_ratio" \
            "${dirty_ratio}%  (background: ${dirty_bg}%)  — write-back cache"
    fi

    # ── Simple sequential read bench ─────────────────────────────────────────────
    local bench_file="/tmp/.ash_io_bench_$$"
    if command -v dd &>/dev/null; then
        local read_speed
        read_speed="$(dd if=/dev/zero of="$bench_file" bs=1M count=64 \
                     conv=fdatasync 2>&1 | grep -oP '[\d.]+ [GM]B/s' | tail -1 || echo '?')"
        rm -f "$bench_file" 2>/dev/null || true

        if [[ -n "$read_speed" ]] && [[ "$read_speed" != "?" ]]; then
            _check_report $CHECK_INFO \
                "Write speed (64MB seq)" \
                "$read_speed"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 04 — COMPOSITOR PERFORMANCE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_perf_compositor() {
    _check_header "💎 Compositor Performance"

    [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && {
        _check_report $CHECK_SKIP "Compositor" "Hyprland not running — skipping"
        return $CHECK_SKIP
    }

    # ── Hyprland FPS / VFR ───────────────────────────────────────────────────────
    if command -v hyprctl &>/dev/null; then
        # VFR (Variable Frame Rate) — reduces idle CPU/GPU usage
        local vfr
        vfr="$(hyprctl getoption misc:vfr -j 2>/dev/null | \
               python3 -c 'import sys,json; print(json.load(sys.stdin).get("int",0))' \
               2>/dev/null || echo '?')"

        if [[ "$vfr" == "1" ]]; then
            _check_report $CHECK_PASS \
                "VFR (variable frame rate)" \
                "Enabled  — reduces idle GPU usage significantly"
        else
            _check_report $CHECK_WARN \
                "VFR (variable frame rate)" \
                "Disabled  — GPU renders at max rate when idle" \
                "Enable: misc { vfr = true } in hyprland.conf"
            _perf_deduct 10 "VFR disabled — GPU spinning at idle"
            _perf_suggest "Enable VFR: misc { vfr = true }"
        fi

        # ── Blur settings ─────────────────────────────────────────────────────────
        local blur_enabled
        blur_enabled="$(hyprctl getoption decoration:blur:enabled -j 2>/dev/null | \
                       python3 -c 'import sys,json; print(json.load(sys.stdin).get("int",1))' \
                       2>/dev/null || echo '1')"

        if [[ "$blur_enabled" == "0" ]]; then
            _check_report $CHECK_INFO \
                "Blur" \
                "Disabled  — best performance"
        else
            # Check blur passes (expensive)
            local blur_passes
            blur_passes="$(hyprctl getoption decoration:blur:passes -j 2>/dev/null | \
                          python3 -c 'import sys,json; print(json.load(sys.stdin).get("int",3))' \
                          2>/dev/null || echo '3')"

            if (( blur_passes > 4 )); then
                _check_report $CHECK_WARN \
                    "Blur passes" \
                    "${blur_passes}  (high — GPU intensive)" \
                    "Reduce: decoration { blur { passes = 2 } }"
                _perf_deduct 5 "High blur passes: ${blur_passes}"
            else
                _check_report $CHECK_INFO \
                    "Blur" \
                    "Enabled  •  ${blur_passes} passes"
            fi
        fi

        # ── Shadow ─────────────────────────────────────────────────────────────
        local shadow_enabled
        shadow_enabled="$(hyprctl getoption decoration:drop_shadow -j 2>/dev/null | \
                         python3 -c 'import sys,json; print(json.load(sys.stdin).get("int",1))' \
                         2>/dev/null || echo '1')"
        _check_report $CHECK_INFO \
            "Drop shadow" \
            "$([ "$shadow_enabled" == "1" ] && echo "Enabled" || echo "Disabled")"

        # ── Animation performance ─────────────────────────────────────────────────
        local anim_enabled
        anim_enabled="$(hyprctl getoption animations:enabled -j 2>/dev/null | \
                       python3 -c 'import sys,json; print(json.load(sys.stdin).get("int",1))' \
                       2>/dev/null || echo '1')"
        if [[ "$anim_enabled" == "1" ]]; then
            _check_report $CHECK_INFO \
                "Animations" \
                "Enabled  (disable with 'ash mode battery' for max perf)"
        else
            _check_report $CHECK_INFO "Animations" "Disabled  (performance mode)"
        fi

        # ── Hyprland CPU/RAM ──────────────────────────────────────────────────────
        local hypr_pid
        hypr_pid="$(pgrep -x Hyprland | head -1)"
        if [[ -n "$hypr_pid" ]]; then
            local hypr_cpu hypr_mem_mb
            hypr_cpu="$(ps -p "$hypr_pid" -o %cpu --no-headers 2>/dev/null | tr -d ' ')"
            local hypr_rss_kb
            hypr_rss_kb="$(cat "/proc/${hypr_pid}/status" 2>/dev/null | \
                          awk '/VmRSS:/{print $2}')"
            hypr_mem_mb=$(( ${hypr_rss_kb:-0} / 1024 ))

            local cpu_int="${hypr_cpu%.*}"
            local cpu_status=$CHECK_PASS
            if [[ "$cpu_int" =~ ^[0-9]+$ ]]; then
                (( cpu_int >= 30 )) && { cpu_status=$CHECK_WARN; _perf_deduct 5 "Hyprland high CPU: ${hypr_cpu}%"; }
            fi

            _check_report $cpu_status \
                "Hyprland CPU" \
                "${hypr_cpu:-?}%"
            _check_report $CHECK_INFO \
                "Hyprland RAM" \
                "${hypr_mem_mb}MB"
        fi

        # ── Active monitor refresh rate ───────────────────────────────────────────
        local monitors_json
        monitors_json="$(hyprctl monitors -j 2>/dev/null || echo '[]')"
        if command -v python3 &>/dev/null; then
            while IFS= read -r monitor_line; do
                [[ -z "$monitor_line" ]] && continue
                local mon_name mon_hz
                mon_name="$(printf '%s' "$monitor_line" | awk -F'|' '{print $1}')"
                mon_hz="$(  printf '%s' "$monitor_line" | awk -F'|' '{print $2}')"

                local hz_int="${mon_hz%.*}"
                if [[ "$hz_int" =~ ^[0-9]+$ ]]; then
                    if (( hz_int >= 120 )); then
                        _check_report $CHECK_PASS \
                            "Monitor: ${mon_name}" \
                            "${mon_hz}Hz  (high refresh — smooth)"
                    elif (( hz_int >= 60 )); then
                        _check_report $CHECK_INFO \
                            "Monitor: ${mon_name}" \
                            "${mon_hz}Hz"
                    else
                        _check_report $CHECK_WARN \
                            "Monitor: ${mon_name}" \
                            "${mon_hz}Hz  (low refresh)" \
                            "Check monitor supports higher refresh rate"
                    fi
                fi
            done < <(
                python3 -c \
                    "import json,sys; \
                     d=json.load(sys.stdin); \
                     [print(f'{m[\"name\"]}|{m[\"refreshRate\"]:.1f}') for m in d]" \
                    <<< "$monitors_json" 2>/dev/null || true
            )
        fi
    fi

    # ── GameMode integration ──────────────────────────────────────────────────────
    if command -v gamemoded &>/dev/null; then
        if pgrep -x gamemoded &>/dev/null; then
            _check_report $CHECK_PASS \
                "GameMode daemon" \
                "Running  (boosts performance when games are active)"
        else
            _check_report $CHECK_INFO \
                "GameMode daemon" \
                "Installed but not running  (auto-starts on game launch)"
        fi
    else
        _check_report $CHECK_INFO \
            "GameMode" \
            "Not installed" \
            "Install for gaming perf: paru -S gamemode"
        _perf_suggest "Install GameMode: paru -S gamemode"
    fi

    # ── MangoHUD ─────────────────────────────────────────────────────────────────
    command -v mangohud &>/dev/null && \
        _check_report $CHECK_PASS "MangoHUD" "Installed  (FPS overlay for gaming)" || \
        _check_report $CHECK_INFO "MangoHUD" "Not installed" \
            "Install: paru -S mangohud"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 05 — NETWORK PERFORMANCE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_perf_network() {
    _check_header "🌐 Network Performance"

    # ── TCP congestion control ────────────────────────────────────────────────────
    local tcp_cc
    tcp_cc="$(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || echo '?')"
    case "$tcp_cc" in
        bbr)
            _check_report $CHECK_PASS \
                "TCP congestion control" \
                "BBR  (Google's high-performance algorithm)"
            ;;
        cubic)
            _check_report $CHECK_INFO \
                "TCP congestion control" \
                "CUBIC  (default — consider BBR)" \
                "Enable: sudo modprobe tcp_bbr && sudo sysctl -w net.ipv4.tcp_congestion_control=bbr"
            _perf_suggest "Enable TCP BBR: modprobe tcp_bbr + sysctl net.ipv4.tcp_congestion_control=bbr"
            ;;
        *)
            _check_report $CHECK_INFO "TCP congestion control" "$tcp_cc"
            ;;
    esac

    # ── TCP fast open ────────────────────────────────────────────────────────────
    local tfo
    tfo="$(cat /proc/sys/net/ipv4/tcp_fastopen 2>/dev/null || echo '?')"
    if [[ "$tfo" == "3" ]]; then
        _check_report $CHECK_PASS \
            "TCP Fast Open" \
            "3  (client+server — reduces connection latency)"
    else
        _check_report $CHECK_INFO \
            "TCP Fast Open" \
            "${tfo}  (3=optimal)" \
            "Enable: sudo sysctl -w net.ipv4.tcp_fastopen=3"
        _perf_suggest "Enable TCP Fast Open: sysctl net.ipv4.tcp_fastopen=3"
    fi

    # ── Network socket buffers ────────────────────────────────────────────────────
    local rmem_max
    rmem_max="$(cat /proc/sys/net/core/rmem_max 2>/dev/null || echo '0')"
    if (( rmem_max >= 134217728 )); then
        _check_report $CHECK_PASS \
            "net.core.rmem_max" \
            "$(( rmem_max / 1048576 ))MB  (large socket buffers)"
    else
        _check_report $CHECK_INFO \
            "net.core.rmem_max" \
            "$(( rmem_max / 1024 ))KB  (default)" \
            "Increase for high-throughput: sysctl -w net.core.rmem_max=134217728"
    fi

    # ── DNS performance ───────────────────────────────────────────────────────────
    if command -v resolvectl &>/dev/null && \
       systemctl is-active systemd-resolved &>/dev/null 2>&1; then
        _check_report $CHECK_PASS \
            "DNS caching" \
            "systemd-resolved active  (local DNS cache)"
    elif command -v unbound &>/dev/null && pgrep -x unbound &>/dev/null; then
        _check_report $CHECK_PASS \
            "DNS caching" \
            "Unbound running  (full local resolver)"
    else
        _check_report $CHECK_INFO \
            "DNS caching" \
            "No local DNS cache  (each DNS lookup goes to upstream)" \
            "Enable: systemctl enable --now systemd-resolved"
        _perf_suggest "Enable DNS caching: systemctl enable --now systemd-resolved"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 06 — PERFORMANCE SCORE & RECOMMENDATIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_perf_score_report() {
    local score="${_PERF_SCORE}"
    (( score < 0 )) && score=0

    local grade grade_icon color
    if   (( score >= 90 )); then grade="A+"; grade_icon="🚀"; color=$'\033[1;38;2;166;227;161m'
    elif (( score >= 80 )); then grade="A";  grade_icon="⚡"; color=$'\033[38;2;166;227;161m'
    elif (( score >= 70 )); then grade="B";  grade_icon="📊"; color=$'\033[38;2;249;226;175m'
    elif (( score >= 60 )); then grade="C";  grade_icon="⚠️ "; color=$'\033[38;2;250;179;135m'
    else                         grade="D";  grade_icon="🐌"; color=$'\033[1;38;2;243;139;168m'
    fi

    local bar_w=40
    local filled=$(( score * bar_w / 100 ))
    local empty=$(( bar_w - filled ))
    local bar=""
    local i
    for (( i=0; i<filled; i++ )); do bar+='█'; done
    for (( i=0; i<empty;  i++ )); do bar+='░'; done

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;250;179;135m'
        printf '  ╔══════════════════════════════════════════════════════════╗\n'
        printf '  ║  %s  PERFORMANCE SCORE                                    ║\n' "$grade_icon"
        printf '  ╠══════════════════════════════════════════════════════════╣\n'
        printf '  ║  %s%s\033[0m\033[1;38;2;250;179;135m  %s%3d/100  %s%-2s\033[38;2;250;179;135m                              ║\n' \
            "$color" "$bar" "$color" "$score" "$color" "${grade}"
        printf '  ╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n  PERFORMANCE SCORE: %d/100  (Grade: %s %s)\n\n' "$score" "$grade" "$grade_icon"
    fi

    # Bottlenecks
    if [[ ${#_PERF_BOTTLENECKS[@]} -gt 0 ]]; then
        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
            printf '\033[1;38;2;243;139;168m  🔴 PERFORMANCE BOTTLENECKS:\033[0m\n'
        else
            printf '  BOTTLENECKS:\n'
        fi
        for b in "${_PERF_BOTTLENECKS[@]}"; do
            printf '    • %s\n' "$b"
        done
        printf '\n'
    fi

    # Optimizations
    if [[ ${#_PERF_OPTIMIZATIONS[@]} -gt 0 ]]; then
        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
            printf '\033[1;38;2;166;227;161m  💡 SUGGESTED OPTIMIZATIONS:\033[0m\n'
        else
            printf '  OPTIMIZATIONS:\n'
        fi
        for opt in "${_PERF_OPTIMIZATIONS[@]}"; do
            if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
                printf '  \033[38;2;116;199;236m→\033[0m  %s\n' "$opt"
            else
                printf '  → %s\n' "$opt"
            fi
        done
        printf '\n'
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_check_performance() {
    local mode="${1:-full}"

    _CHECK_PASS_COUNT=0;  _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0;  _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=();   _CHECK_WARNINGS=()
    _PERF_SCORE=100; _PERF_BOTTLENECKS=(); _PERF_OPTIMIZATIONS=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;250;179;135m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🚀  ASH DOCTOR — PERFORMANCE CHECK                      ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  CPU governor • memory • I/O • compositor • network      ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n=== ASH DOCTOR — PERFORMANCE CHECK ===\n'
    fi

    case "$mode" in
        quick)
            _chk_perf_cpu
            _chk_perf_memory
            ;;
        cpu)        _chk_perf_cpu        ;;
        memory)     _chk_perf_memory     ;;
        io)         _chk_perf_io         ;;
        compositor) _chk_perf_compositor ;;
        network)    _chk_perf_network    ;;
        full|*)
            _chk_perf_cpu
            _chk_perf_memory
            _chk_perf_io
            _chk_perf_compositor
            _chk_perf_network
            ;;
    esac

    _chk_perf_score_report
    _ash_check_system_summary
}

ash_check_performance_quick() {
    local issues=0
    local load_1
    read -r load_1 _ < /proc/loadavg 2>/dev/null || load_1="0"
    local cpu_cores
    cpu_cores="$(nproc 2>/dev/null || echo 4)"
    local load_int="${load_1%.*}"
    [[ "$load_int" =~ ^[0-9]+$ ]] && (( load_int >= cpu_cores )) && (( issues++ )) || true

    local avail_kb total_kb used_pct=0
    total_kb="$(awk '/^MemTotal:/{print $2}' /proc/meminfo 2>/dev/null || echo 1)"
    avail_kb="$(awk '/^MemAvailable:/{print $2}' /proc/meminfo 2>/dev/null || echo 1)"
    used_pct=$(( (total_kb - avail_kb) * 100 / total_kb ))
    (( used_pct >= 90 )) && (( issues++ )) || true

    if (( issues == 0 )); then
        ash_log_success "Performance: OK  (load: ${load_1}  mem: ${used_pct}%)"
    else
        ash_log_warn "Performance: ${issues} concern(s) — run 'ash doctor full --performance'"
        return 1
    fi
}
