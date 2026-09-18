#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ███████╗███████╗███╗   ██╗███████╗ ██████╗ ██████╗ ███████╗                    ║
# ║  ██╔════╝██╔════╝████╗  ██║██╔════╝██╔═══██╗██╔══██╗██╔════╝                    ║
# ║  ███████╗█████╗  ██╔██╗ ██║███████╗██║   ██║██████╔╝███████╗                    ║
# ║  ╚════██║██╔══╝  ██║╚██╗██║╚════██║██║   ██║██╔══██╗╚════██║                    ║
# ║  ███████║███████╗██║ ╚████║███████║╚██████╔╝██║  ██║███████║                    ║
# ║  ╚══════╝╚══════╝╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝                    ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  hw sensors                                               ║
# ║  All hwmon sensors • temps • voltages • fan RPM • power • live dashboard         ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_HW_SENSORS_LOADED:-}" == "1" ]] && return 0
readonly _ASH_HW_SENSORS_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HWMON SYSFS READER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g _SENS_WARN_TEMP=75
declare -g _SENS_CRIT_TEMP=90

_sens_read() {
    cat "${1}/${2}" 2>/dev/null | tr -d '\n' || printf ''
}

_sens_read_int() {
    local v
    v="$(_sens_read "$1" "$2")"
    printf '%d' "${v:-0}" 2>/dev/null || printf '0'
}

_sens_hwmon_name() {
    _sens_read "$1" "name"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SENSOR RENDERERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_sens_render_temp() {
    local hwmon_dir="$1"
    local prefix="temp"
    local found=0

    for input_file in "${hwmon_dir}/${prefix}"*_input; do
        [[ -r "$input_file" ]] || continue
        local base="${input_file%_input}"
        local num="${base##*/temp}"

        local val_mc
        val_mc="$(_sens_read_int "$hwmon_dir" "temp${num}_input")"
        local val_c=$(( val_mc / 1000 ))

        local label
        label="$(_sens_read "$hwmon_dir" "temp${num}_label")"
        [[ -z "$label" ]] && label="temp${num}"

        local max_mc
        max_mc="$(_sens_read_int "$hwmon_dir" "temp${num}_max")"
        local crit_mc
        crit_mc="$(_sens_read_int "$hwmon_dir" "temp${num}_crit")"

        local crit_c=$(( crit_mc > 0 ? crit_mc / 1000 : _SENS_CRIT_TEMP ))
        local max_c="$(( max_mc > 0 ? max_mc / 1000 : _SENS_WARN_TEMP ))"

        # Color coding
        local temp_color temp_icon
        if   (( val_c >= crit_c )); then
            temp_color=$'\033[1;38;2;243;139;168m'; temp_icon="🔥"
        elif (( val_c >= max_c  )); then
            temp_color=$'\033[38;2;249;226;175m';   temp_icon="🌡"
        elif (( val_c >= 60     )); then
            temp_color=$'\033[38;2;250;179;135m';   temp_icon="🟠"
        else
            temp_color=$'\033[38;2;166;227;161m';   temp_icon="❄"
        fi

        # Mini thermometer bar
        local bar_pct=$(( val_c * 100 / (crit_c > 0 ? crit_c : 100) ))
        (( bar_pct > 100 )) && bar_pct=100
        local bar_width=20
        local filled=$(( bar_pct * bar_width / 100 ))
        local empty=$(( bar_width - filled ))
        local bar="${temp_color}$(printf '█%.0s' $(seq 1 $filled))\033[38;2;88;91;112m$(printf '░%.0s' $(seq 1 $empty))\033[0m"

        printf '  %s  \033[38;2;108;112;134m%-18s\033[0m  %s%s%3d°C\033[0m  %s' \
            "$temp_icon" \
            "${label:0:17}" \
            "$temp_color" $'\033[1m' \
            "$val_c" \
            "$bar"

        [[ "$max_mc"  -gt 0 ]] && printf '  \033[38;2;108;112;134mmax:%d°C\033[0m'  "$max_c"
        [[ "$crit_mc" -gt 0 ]] && printf '  \033[38;2;243;139;168mcrit:%d°C\033[0m' "$crit_c"
        printf '\n'

        (( found++ )) || true
    done

    return $(( found > 0 ? 0 : 1 ))
}

_sens_render_fans() {
    local hwmon_dir="$1"
    local found=0

    for input_file in "${hwmon_dir}/fan"*_input; do
        [[ -r "$input_file" ]] || continue
        local base="${input_file%_input}"
        local num="${base##*/fan}"

        local rpm
        rpm="$(_sens_read_int "$hwmon_dir" "fan${num}_input")"
        local min_rpm
        min_rpm="$(_sens_read_int "$hwmon_dir" "fan${num}_min")"
        local label
        label="$(_sens_read "$hwmon_dir" "fan${num}_label")"
        [[ -z "$label" ]] && label="fan${num}"

        local rpm_color
        if   (( rpm == 0 )); then
            rpm_color=$'\033[38;2;108;112;134m'
        elif (( rpm < 800 )); then
            rpm_color=$'\033[38;2;166;227;161m'
        elif (( rpm < 2000 )); then
            rpm_color=$'\033[38;2;249;226;175m'
        else
            rpm_color=$'\033[38;2;250;179;135m'
        fi

        printf '  🌀  \033[38;2;108;112;134m%-18s\033[0m  %s%4d RPM\033[0m' \
            "${label:0:17}" "$rpm_color" "$rpm"
        [[ $rpm -eq 0 ]] && printf '  \033[38;2;108;112;134m(stopped)\033[0m'
        printf '\n'
        (( found++ )) || true
    done

    return $(( found > 0 ? 0 : 1 ))
}

_sens_render_voltages() {
    local hwmon_dir="$1"
    local found=0

    for input_file in "${hwmon_dir}/in"*_input; do
        [[ -r "$input_file" ]] || continue
        local base="${input_file%_input}"
        local num="${base##*/in}"

        local mv
        mv="$(_sens_read_int "$hwmon_dir" "in${num}_input")"
        local label
        label="$(_sens_read "$hwmon_dir" "in${num}_label")"
        [[ -z "$label" ]] && label="in${num}"

        local volt
        volt="$(hw_div "$mv" 1000 3)"

        local min_mv max_mv
        min_mv="$(_sens_read_int "$hwmon_dir" "in${num}_min")"
        max_mv="$(_sens_read_int "$hwmon_dir" "in${num}_max")"

        local volt_color=$'\033[38;2;180;190;254m'
        if [[ "$max_mv" -gt 0 ]] && (( mv > max_mv )); then
            volt_color=$'\033[38;2;243;139;168m'
        elif [[ "$min_mv" -gt 0 ]] && (( mv < min_mv )); then
            volt_color=$'\033[38;2;249;226;175m'
        fi

        printf '  ⚡  \033[38;2;108;112;134m%-18s\033[0m  %s%5sV\033[0m\n' \
            "${label:0:17}" "$volt_color" "$volt"
        (( found++ )) || true
    done

    return $(( found > 0 ? 0 : 1 ))
}

_sens_render_power() {
    local hwmon_dir="$1"
    local found=0

    for input_file in "${hwmon_dir}/power"*_input \
                       "${hwmon_dir}/power"*_average; do
        [[ -r "$input_file" ]] || continue
        local basename_f
        basename_f="$(basename "$input_file")"
        local num
        num="${basename_f//[^0-9]/}"

        local uw
        uw="$(_sens_read_int "$hwmon_dir" "$basename_f")"
        local watts
        watts="$(hw_div "$uw" 1000000 2)"

        local label
        label="$(_sens_read "$hwmon_dir" "power${num}_label")"
        [[ -z "$label" ]] && label="power${num}"

        printf '  🔋  \033[38;2;108;112;134m%-18s\033[0m  \033[38;2;250;179;135m%6sW\033[0m\n' \
            "${label:0:17}" "$watts"
        (( found++ )) || true
    done

    return $(( found > 0 ? 0 : 1 ))
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SENSORS OVERVIEW DASHBOARD
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_sens_render_all() {
    local hwmon_count=0

    for hwmon_dir in /sys/class/hwmon/hwmon*/; do
        [[ -d "$hwmon_dir" ]] || continue

        local hw_name
        hw_name="$(_sens_hwmon_name "$hwmon_dir")"
        local hw_basename
        hw_basename="$(basename "$hwmon_dir")"

        # Map name to friendly label + color + icon
        local hw_label hw_color hw_icon
        case "${hw_name,,}" in
            coretemp|cpu_thermal)
                hw_label="CPU Temperature"
                hw_color=$'\033[38;2;243;139;168m'
                hw_icon="🔲" ;;
            k10temp|zenpower)
                hw_label="CPU Temperature  (AMD)"
                hw_color=$'\033[38;2;250;179;135m'
                hw_icon="🔲" ;;
            amdgpu|radeon)
                hw_label="GPU Temperature  (AMD)"
                hw_color=$'\033[38;2;250;179;135m'
                hw_icon="🎮" ;;
            nouveau|nvidia*)
                hw_label="GPU Temperature  (NVIDIA)"
                hw_color=$'\033[38;2;166;227;161m'
                hw_icon="🎮" ;;
            i915|xe)
                hw_label="GPU Temperature  (Intel)"
                hw_color=$'\033[38;2;137;180;250m'
                hw_icon="🔵" ;;
            it87|w83*|nct*|asus*)
                hw_label="Motherboard / Super-I/O"
                hw_color=$'\033[38;2;148;226;213m'
                hw_icon="🔧" ;;
            acpi*|bat*)
                hw_label="ACPI / Battery"
                hw_color=$'\033[38;2;166;227;161m'
                hw_icon="🔋" ;;
            nvme*)
                hw_label="NVMe Thermal"
                hw_color=$'\033[38;2;203;166;247m'
                hw_icon="💿" ;;
            *)
                hw_label="${hw_name:-$hw_basename}"
                hw_color=$'\033[38;2;108;112;134m'
                hw_icon="🔬" ;;
        esac

        printf '\n  %s  %s%s\033[0m  \033[38;2;108;112;134m(%s)\033[0m\n' \
            "$hw_icon" "$hw_color" "$hw_label" "$hw_basename"
        printf '  \033[38;2;88;91;112m  %s\033[0m\n' \
            "$(printf '─%.0s' $(seq 1 52))"

        local section_found=0
        _sens_render_temp     "$hwmon_dir" && (( section_found++ )) || true
        _sens_render_fans     "$hwmon_dir" && (( section_found++ )) || true
        _sens_render_voltages "$hwmon_dir" && (( section_found++ )) || true
        _sens_render_power    "$hwmon_dir" && (( section_found++ )) || true

        (( section_found > 0 )) && (( hwmon_count++ )) || true
    done

    (( hwmon_count == 0 )) && \
        printf '\n  \033[38;2;249;226;175m⚠  No hwmon sensors found%s\033[0m\n' \
            "$(command -v sensors &>/dev/null && echo '' || echo '  (install lm-sensors)')"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_hw_sensors() {
    local filter=""
    local short=0

    for arg in "${@:-}"; do
        case "$arg" in
            --temp|--temperature) filter="temp"    ;;
            --fan|--fans)         filter="fans"    ;;
            --volt|--voltage)     filter="volt"    ;;
            --power)              filter="power"   ;;
            --short)              short=1          ;;
        esac
    done

    hw_section "🌡" "Hardware Sensors" $'\033[38;2;243;139;168m'

    printf '  \033[38;2;108;112;134mSource: /sys/class/hwmon  •  All values read directly from kernel\033[0m\n'

    if [[ -n "$filter" ]]; then
        for hwmon_dir in /sys/class/hwmon/hwmon*/; do
            [[ -d "$hwmon_dir" ]] || continue
            local hw_name
            hw_name="$(_sens_hwmon_name "$hwmon_dir")"
            printf '\n  \033[38;2;203;166;247m%s\033[0m\n' "$hw_name"
            case "$filter" in
                temp)  _sens_render_temp     "$hwmon_dir" ;;
                fans)  _sens_render_fans     "$hwmon_dir" ;;
                volt)  _sens_render_voltages "$hwmon_dir" ;;
                power) _sens_render_power    "$hwmon_dir" ;;
            esac
        done
    else
        _sens_render_all
    fi

    # lm-sensors fallback/supplement
    if command -v sensors &>/dev/null && [[ $short -eq 0 ]]; then
        printf '\n  \033[38;2;108;112;134mlm-sensors (sensors):\033[0m\n'
        sensors 2>/dev/null | grep -v '^$' | while IFS= read -r sline; do
            if [[ "$sline" =~ ^[A-Za-z] ]]; then
                printf '  \033[38;2;203;166;247m%s\033[0m\n' "$sline"
            else
                printf '  \033[38;2;108;112;134m%s\033[0m\n' "$sline"
            fi
        done
    fi

    hw_divider
}
