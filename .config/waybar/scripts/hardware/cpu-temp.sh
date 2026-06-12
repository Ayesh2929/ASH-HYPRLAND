#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WAYBAR CPU TEMPERATURE MODULE                ║
# ║           Multi-sensor detection with thresholds and alerts               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/cpu-temp.log"
readonly TEMP_CRITICAL=85
readonly TEMP_WARNING=70
readonly NOTIF_LOCKFILE="/tmp/ash-temp-notified"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🌡️ TEMPERATURE DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

detect_cpu_temp() {
    local temp=0

    # Method 1: sensors (lm-sensors)
    if command -v sensors &>/dev/null; then
        local sensors_out
        sensors_out=$(sensors 2>/dev/null)

        # Try multiple sensor chips
        local candidates=(
            "$(echo "${sensors_out}" | grep -i "core 0\|Package id 0\|Tdie\|Tctl" | head -1 | grep -oP '[\+]?[\d.]+(?=°C)')"
            "$(echo "${sensors_out}" | grep -i "cpu_thermal\|cpu temp\|k10temp" | head -1 | grep -oP '[\+]?[\d.]+(?=°C)' | head -1)"
        )

        for candidate in "${candidates[@]}"; do
            if [[ -n "${candidate}" ]] && [[ "${candidate}" != "0" ]]; then
                temp=$(echo "${candidate}" | tr -d '+' | awk '{printf "%.0f", $1}')
                [[ "${temp}" -gt 0 ]] && echo "${temp}" && return 0
            fi
        done
    fi

    # Method 2: Thermal zones (sysfs)
    local thermal_zones=(/sys/class/thermal/thermal_zone*/temp)
    local best_temp=0
    local best_type=""

    for zone_temp in "${thermal_zones[@]}"; do
        local zone_dir
        zone_dir=$(dirname "${zone_temp}")
        local zone_type
        zone_type=$(cat "${zone_dir}/type" 2>/dev/null || echo "unknown")

        # Prefer CPU-related zones
        if echo "${zone_type,,}" | grep -qE "cpu|x86|acpi"; then
            local raw
            raw=$(cat "${zone_temp}" 2>/dev/null || echo "0")
            local current=$(( raw / 1000 ))

            # Sanity check (0-120°C)
            if (( current > 5 && current < 120 )); then
                if (( current > best_temp )) || [[ -z "${best_type}" ]]; then
                    best_temp="${current}"
                    best_type="${zone_type}"
                fi
            fi
        fi
    done

    if (( best_temp > 0 )); then
        echo "${best_temp}"
        return 0
    fi

    # Method 3: hwmon
    local hwmon_dirs=(/sys/class/hwmon/hwmon*/temp1_input)
    for hwmon_temp in "${hwmon_dirs[@]}"; do
        if [[ -f "${hwmon_temp}" ]]; then
            local hwmon_dir
            hwmon_dir=$(dirname "${hwmon_temp}")
            local name
            name=$(cat "${hwmon_dir}/name" 2>/dev/null || echo "")

            if echo "${name,,}" | grep -qE "coretemp|k10temp|nct|w83|it87|acpitz"; then
                local raw
                raw=$(cat "${hwmon_temp}" 2>/dev/null || echo "0")
                local current=$(( raw / 1000 ))
                if (( current > 5 && current < 120 )); then
                    echo "${current}"
                    return 0
                fi
            fi
        fi
    done

    # Could not detect
    echo "?"
}

get_all_temps() {
    if ! command -v sensors &>/dev/null; then
        echo "lm-sensors not installed"
        return 0
    fi
    sensors 2>/dev/null | grep -E "°C" | head -20
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 FORMAT OUTPUT
# ═══════════════════════════════════════════════════════════════════════════════

format_output() {
    local temp
    temp=$(detect_cpu_temp)

    if [[ "${temp}" == "?" ]]; then
        printf '{"text": "? °C", "tooltip": "Temperature unavailable", "class": "unknown"}\n'
        return 0
    fi

    # Determine class and icon
    local class icon
    if (( temp >= TEMP_CRITICAL )); then
        class="critical"; icon="🔥"
        # Critical notification
        if [[ ! -f "${NOTIF_LOCKFILE}" ]]; then
            notify-send "🔥 CPU Temperature Critical!" \
                "CPU at ${temp}°C — check cooling!" \
                --urgency=critical \
                --app-name="ASH Temperature" \
                2>/dev/null || true
            touch "${NOTIF_LOCKFILE}"
            log "CRIT" "CPU temp critical: ${temp}°C"
        fi
    elif (( temp >= TEMP_WARNING )); then
        class="warning";  icon="🌡️"
        rm -f "${NOTIF_LOCKFILE}" 2>/dev/null || true
    elif (( temp >= 50 )); then
        class="warm";     icon="󰔏"
        rm -f "${NOTIF_LOCKFILE}" 2>/dev/null || true
    else
        class="cool";     icon="󱃃"
        rm -f "${NOTIF_LOCKFILE}" 2>/dev/null || true
    fi

    # Build tooltip
    local all_temps
    all_temps=$(get_all_temps)

    local tooltip
    tooltip="🌡️ CPU Temperature\n"
    tooltip+="────────────────────\n"
    tooltip+="Current: ${temp}°C\n"
    tooltip+="Warning: ${TEMP_WARNING}°C\n"
    tooltip+="Critical: ${TEMP_CRITICAL}°C\n"

    if [[ -n "${all_temps}" ]]; then
        tooltip+="────────────────────\n"
        tooltip+="All sensors:\n${all_temps}"
    fi

    printf '{"text": "%s %s°C", "tooltip": "%s", "class": "%s", "percentage": %s}\n' \
        "${icon}" "${temp}" "${tooltip}" "${class}" "$(( temp ))"
}

main() {
    local action="${1:-status}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        status | "") format_output ;;
        temp)        detect_cpu_temp ;;
        all)         get_all_temps ;;
        critical)    echo "${TEMP_CRITICAL}" ;;
        warning)     echo "${TEMP_WARNING}" ;;
        *)
            echo "Usage: cpu-temp.sh [status|temp|all]"
            exit 1
            ;;
    esac
}

main "$@"