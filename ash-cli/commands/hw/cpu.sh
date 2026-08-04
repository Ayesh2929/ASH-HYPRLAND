#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  hw cpu                                                  ║
# ║  CPU architecture • cores • frequencies • temperatures • governor • flags       ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_HW_CPU_LOADED:-}" == "1" ]] && return 0
readonly _ASH_HW_CPU_LOADED=1

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  DATA COLLECTORS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_cpu_model() {
    grep -m1 'model name' /proc/cpuinfo 2>/dev/null | \
        sed 's/.*: //' | sed 's/  */ /g' || echo 'Unknown CPU'
}

_cpu_cores_physical() {
    sort -u /proc/cpuinfo 2>/dev/null | grep 'core id' | wc -l 2>/dev/null || \
    grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo 1
}

_cpu_cores_logical()  { nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo || echo 1; }
_cpu_cores_total()    { nproc --all 2>/dev/null || _cpu_cores_logical; }

_cpu_vendor() {
    grep -m1 'vendor_id' /proc/cpuinfo 2>/dev/null | \
        sed 's/.*: //' || echo 'unknown'
}

_cpu_freq_current() {
    # Average current frequency across all cores (MHz)
    local avg
    avg="$(grep 'cpu MHz' /proc/cpuinfo 2>/dev/null | \
           awk '{sum+=$4; n++} END{if(n>0) printf "%.0f", sum/n; else print "?"}' )"
    printf '%s' "${avg:-?}"
}

_cpu_freq_max() {
    cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null | \
        awk '{printf "%.0f", $1/1000}' || echo '?'
}

_cpu_freq_min() {
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null | \
        awk '{printf "%.0f", $1/1000}' || echo '?'
}

_cpu_governor() {
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || \
    cat /sys/devices/system/cpu/intel_pstate/status 2>/dev/null || \
    echo 'unknown'
}

_cpu_load_avg() {
    cut -d' ' -f1-3 /proc/loadavg 2>/dev/null || echo '? ? ?'
}

_cpu_usage_pct() {
    # Quick 100ms sample
    local s1 s2
    s1="$(awk '/^cpu /{print $2+$4, $2+$3+$4+$5+$6+$7+$8}' /proc/stat 2>/dev/null)"
    sleep 0.1
    s2="$(awk '/^cpu /{print $2+$4, $2+$3+$4+$5+$6+$7+$8}' /proc/stat 2>/dev/null)"

    local d_busy d_total
    d_busy=$(( $(printf '%s' "$s2" | awk '{print $1}') - $(printf '%s' "$s1" | awk '{print $1}') ))
    d_total=$(( $(printf '%s' "$s2" | awk '{print $2}') - $(printf '%s' "$s1" | awk '{print $2}') ))

    if (( d_total > 0 )); then
        printf '%d' "$(( d_busy * 100 / d_total ))"
    else
        printf '0'
    fi
}

_cpu_temp_all() {
    # Returns "label temp_mc" pairs from hwmon
    for hwmon_dir in /sys/class/hwmon/hwmon*/; do
        local name
        name="$(cat "${hwmon_dir}name" 2>/dev/null || echo '')"
        [[ "$name" =~ coretemp|k10temp|zenpower|cpu_thermal ]] || continue

        for temp_file in "${hwmon_dir}"temp*_input; do
            [[ -r "$temp_file" ]] || continue
            local temp_mc
            temp_mc="$(cat "$temp_file" 2>/dev/null || echo 0)"
            local label_file="${temp_file/_input/_label}"
            local label
            label="$(cat "$label_file" 2>/dev/null || basename "$temp_file" _input)"
            printf '%s %d\n' "$label" "$(( temp_mc / 1000 ))"
        done
        break
    done
}

_cpu_cache() {
    # L3 cache in KB
    grep -m1 'cache size' /proc/cpuinfo 2>/dev/null | \
        awk '{print $4, $5}' || echo '?'
}

_cpu_turbo_state() {
    local no_turbo
    no_turbo="$(cat /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || echo '?')"
    if [[ "$no_turbo" == "0" ]]; then echo "enabled"
    elif [[ "$no_turbo" == "1" ]]; then echo "disabled"
    else
        local boost
        boost="$(cat /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || echo '?')"
        [[ "$boost" == "1" ]] && echo "enabled" || echo "disabled/unknown"
    fi
}

_cpu_architecture_details() {
    local flags
    flags="$(grep -m1 '^flags' /proc/cpuinfo 2>/dev/null | sed 's/flags\s*:\s*//')"

    # Extract key capability flags
    local has_avx2 has_avx512 has_aes has_rdrand has_vmx has_svm
    printf '%s' "$flags" | grep -q '\bavx2\b'   && has_avx2="AVX2"    || has_avx2=""
    printf '%s' "$flags" | grep -q 'avx512'      && has_avx512="AVX-512" || has_avx512=""
    printf '%s' "$flags" | grep -q '\baes\b'     && has_aes="AES-NI"  || has_aes=""
    printf '%s' "$flags" | grep -q '\brdrand\b'  && has_rdrand="RDRAND" || has_rdrand=""
    printf '%s' "$flags" | grep -q '\bvmx\b'     && has_vmx="Intel-VT" || has_vmx=""
    printf '%s' "$flags" | grep -q '\bsvm\b'     && has_svm="AMD-V"   || has_svm=""

    local caps=()
    for cap in "$has_avx2" "$has_avx512" "$has_aes" "$has_rdrand" "$has_vmx" "$has_svm"; do
        [[ -n "$cap" ]] && caps+=("$cap")
    done

    printf '%s' "${caps[*]:-none detected}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PER-CORE FREQUENCY GRID
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_cpu_core_freq_grid() {
    local max_freq
    max_freq="$(_cpu_freq_max)"

    printf '\n  %sPer-Core Frequencies:%s\n' "$(_hw_dim)" "$(_hw_r)"

    local core_num=0
    local row=""
    local cols=4

    for freq_file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
        [[ -r "$freq_file" ]] || continue
        local freq_mhz
        freq_mhz="$(awk '{printf "%4d", $1/1000}' "$freq_file" 2>/dev/null || echo '   ?')"

        local freq_int="${freq_mhz// /}"
        local pct=0
        if [[ "$max_freq" =~ ^[0-9]+$ ]] && (( max_freq > 0 )); then
            pct=$(( freq_int * 100 / max_freq ))
        fi

        local freq_color
        if   (( pct >= 85 )); then freq_color="$(_hw_red)"
        elif (( pct >= 60 )); then freq_color="$(_hw_yellow)"
        else                       freq_color="$(_hw_green)"
        fi

        row+="$(printf '  %sC%-2d%s %s%4dMHz%s' \
            "$(_hw_dim)" "$core_num" "$(_hw_r)" \
            "$freq_color" "$freq_int" "$(_hw_r)")"

        (( core_num++ )) || true
        (( core_num % cols == 0 )) && { printf '%s\n' "$row"; row=""; }
    done

    [[ -n "$row" ]] && printf '%s\n' "$row"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CPU USAGE SPARKLINE (last 5 samples)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_cpu_sparkline() {
    local -a samples=()
    local n=8

    # Quick sampling loop
    for (( i=0; i<n; i++ )); do
        local pct
        pct="$(_cpu_usage_pct)"
        samples+=("$pct")
        sleep 0.15
    done

    local spark=""
    local blocks=( '▁' '▂' '▃' '▄' '▅' '▆' '▇' '█' )

    for pct in "${samples[@]}"; do
        local idx=$(( pct * 7 / 100 ))
        (( idx > 7 )) && idx=7
        spark+="${blocks[$idx]}"
    done

    printf '%s' "$spark"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_hw_cpu() {
    local short=0
    for arg in "${@:-}"; do
        [[ "$arg" == "--short" ]] && short=1
    done

    local model
    model="$(_cpu_model)"
    local vendor
    vendor="$(_cpu_vendor)"
    local cores_p
    cores_p="$(_cpu_cores_physical)"
    local cores_l
    cores_l="$(_cpu_cores_logical)"
    local cores_t
    cores_t="$(_cpu_cores_total)"
    local freq_cur
    freq_cur="$(_cpu_freq_current)"
    local freq_max
    freq_max="$(_cpu_freq_max)"
    local freq_min
    freq_min="$(_cpu_freq_min)"
    local governor
    governor="$(_cpu_governor)"
    local load_avg
    load_avg="$(_cpu_load_avg)"
    local cache
    cache="$(_cpu_cache)"
    local turbo
    turbo="$(_cpu_turbo_state)"

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        printf '{\n'
        printf '  "model": "%s",\n'          "$model"
        printf '  "vendor": "%s",\n'         "$vendor"
        printf '  "cores_physical": %s,\n'   "$cores_p"
        printf '  "cores_logical": %s,\n'    "$cores_l"
        printf '  "freq_current_mhz": %s,\n' "$freq_cur"
        printf '  "freq_max_mhz": %s,\n'     "$freq_max"
        printf '  "governor": "%s",\n'        "$governor"
        printf '  "turbo": "%s",\n'           "$turbo"
        printf '  "load_avg": "%s"\n'         "$load_avg"
        printf '}\n'
        return 0
    fi

    if [[ $short -eq 1 ]]; then
        hw_section "🔲" "CPU" "$(_hw_blue)"
        hw_kv "Model"   "$model"
        hw_kv "Cores"   "${cores_p}P / ${cores_l}T"
        hw_kv "Freq"    "${freq_cur} MHz  (max: ${freq_max})"
        hw_kv "Load"    "$load_avg"
        return 0
    fi

    # ── Full display ──────────────────────────────────────────────────────────────
    hw_section "🔲" "CPU — Processor" "$(_hw_blue)"

    # Model badge
    printf '\n  '
    hw_badge " $model " "$(_hw_blue)"
    printf '\n\n'

    hw_kv "Vendor"          "$vendor"
    hw_kv "Cores"           "${cores_p} Physical  /  ${cores_l} Logical  /  ${cores_t} Total"
    hw_kv "Cache"           "$cache"
    hw_kv "Capabilities"    "$(_cpu_architecture_details)"

    hw_section "⚡" "Frequency & Governor" "$(_hw_peach)"
    hw_kv "Current (avg)"   "${freq_cur} MHz"
    hw_kv "Maximum"         "${freq_max} MHz"
    hw_kv "Minimum"         "${freq_min} MHz"
    hw_kv "Governor"        "$governor"
    hw_kv "Turbo / Boost"   "$turbo"

    # Governor recommendations
    case "$governor" in
        powersave)
            printf '  %s  ⚠  powersave governor — consider schedutil for desktop%s\n' \
                "$(_hw_yellow)" "$(_hw_r)" ;;
        performance)
            printf '  %s  ✓  performance governor — maximum speed%s\n' \
                "$(_hw_green)" "$(_hw_r)" ;;
        schedutil)
            printf '  %s  ✓  schedutil — optimal for desktop/laptop%s\n' \
                "$(_hw_green)" "$(_hw_r)" ;;
    esac

    hw_section "📊" "Current Usage" "$(_hw_teal)"

    # Live CPU usage bar
    local usage_pct
    usage_pct="$(_cpu_usage_pct)"
    hw_bar "CPU Usage" "$usage_pct" ""

    # Load averages
    local la1 la5 la15
    read -r la1 la5 la15 <<< "$load_avg"
    hw_kv "Load (1m/5m/15m)" "${la1}  ${la5}  ${la15}"

    # Sparkline
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '  %sLast ~1.2s:%s  %s%s%s\n' \
            "$(_hw_dim)" "$(_hw_r)" \
            "$(_hw_peach)" "$(_cpu_sparkline)" "$(_hw_r)"
    fi

    # ── Temperature ───────────────────────────────────────────────────────────────
    hw_section "🌡" "Temperatures" "$(_hw_red)"

    local temps_found=0
    while IFS=' ' read -r label temp_c; do
        [[ -z "$label" ]] && continue
        hw_temp "$label" "$temp_c" 75 90
        (( temps_found++ )) || true
    done < <(_cpu_temp_all)

    if (( temps_found == 0 )); then
        hw_kv "Temperature" "Not available via hwmon"
    fi

    # ── Per-core frequencies ──────────────────────────────────────────────────────
    if [[ -d /sys/devices/system/cpu/cpu0/cpufreq ]]; then
        _cpu_core_freq_grid
    fi

    hw_divider
}
