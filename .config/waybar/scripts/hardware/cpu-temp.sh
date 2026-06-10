#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WAYBAR CPU TEMPERATURE MODULE                ║
# ║           Multi-source temperature detection with status classes           ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly SENSOR_CACHE="${CACHE_DIR}/cpu-sensor-path"

# ═══════════════════════════════════════════════════════════════════════════════
# 🌡️ TEMPERATURE DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

find_best_sensor() {
    # Check cached sensor path
    if [[ -f "${SENSOR_CACHE}" ]]; then
        local cached
        cached=$(cat "${SENSOR_CACHE}")
        if [[ -f "${cached}" ]]; then
            echo "${cached}"
            return 0
        fi
        rm -f "${SENSOR_CACHE}"
    fi

    local best_path=""

    # Priority order: k10temp, coretemp, acpitz, generic
    local sensor_types=("k10temp" "coretemp" "zenpower" "nct6775" "it8" "acpitz")

    for sensor_type in "${sensor_types[@]}"; do
        local hwmon_path
        hwmon_path=$(find /sys/class/hwmon -maxdepth 1 -mindepth 1 2>/dev/null \
            | while read -r hwmon; do
                local name
                name=$(cat "${hwmon}/name" 2>/dev/null || echo "")
                if [[ "${name}" == "${sensor_type}"* ]]; then
                    echo "${hwmon}"
                    break
                fi
            done | head -1)

        if [[ -n "${hwmon_path}" ]]; then
            # Find the best temperature file (prefer Tdie or Package)
            local temp_file=""

            # Try Tdie (AMD)
            for label_file in "${hwmon_path}"/temp*_label; do
                [[ -f "${label_file}" ]] || continue
                local label
                label=$(cat "${label_file}" 2>/dev/null || echo "")
                if [[ "${label}" == "Tdie" ]] || [[ "${label}" == "Package id 0" ]]; then
                    temp_file="${label_file/_label/_input}"
                    break
                fi
            done

            # Fallback to temp1_input
            if [[ -z "${temp_file}" ]] && [[ -f "${hwmon_path}/temp1_input" ]]; then
                temp_file="${hwmon_path}/temp1_input"
            fi

            if [[ -n "${temp_file}" ]] && [[ -f "${temp_file}" ]]; then
                best_path="${temp_file}"
                break
            fi
        fi
    done

    # Final fallback: thermal zones
    if [[ -z "${best_path}" ]]; then
        for zone in /sys/class/thermal/thermal_zone*/temp; do
            if [[ -f "${zone}" ]]; then
                local temp
                temp=$(cat "${zone}" 2>/dev/null || echo "0")
                if (( temp > 20000 && temp < 120000 )); then
                    best_path="${zone}"
                    break
                fi
            fi
        done
    fi

    if [[ -n "${best_path}" ]]; then
        echo "${best_path}" > "${SENSOR_CACHE}"
        echo "${best_path}"
    fi
}

get_temperature() {
    local sensor_path
    sensor_path=$(find_best_sensor)

    if [[ -z "${sensor_path}" ]]; then
        echo ""
        return 1
    fi

    local raw_temp
    raw_temp=$(cat "${sensor_path}" 2>/dev/null || echo "0")

    # Convert millidegrees to degrees
    local temp_c=$(( raw_temp / 1000 ))

    # Sanity check (valid CPU temp range)
    if (( temp_c < 1 || temp_c > 150 )); then
        echo ""
        return 1
    fi

    echo "${temp_c}"
}

get_all_core_temps() {
    local hwmon_paths=()
    while IFS= read -r hwmon; do
        local name
        name=$(cat "${hwmon}/name" 2>/dev/null || echo "")
        if [[ "${name}" == "k10temp" ]] || [[ "${name}" == "coretemp" ]] || \
           [[ "${name}" == "zenpower" ]]; then
            hwmon_paths+=("${hwmon}")
        fi
    done < <(find /sys/class/hwmon -maxdepth 1 -mindepth 1 2>/dev/null)

    local core_temps=""
    for hwmon in "${hwmon_paths[@]}"; do
        for temp_file in "${hwmon}"/temp*_input; do
            [[ -f "${temp_file}" ]] || continue
            local label_file="${temp_file/_input/_label}"
            local label="Core"
            [[ -f "${label_file}" ]] && label=$(cat "${label_file}" 2>/dev/null || echo "Core")

            local raw
            raw=$(cat "${temp_file}" 2>/dev/null || echo "0")
            local temp_c=$(( raw / 1000 ))

            if (( temp_c > 10 && temp_c < 150 )); then
                core_temps+="${label}: ${temp_c}°C\n"
            fi
        done
    done

    echo -e "${core_temps}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 FORMAT OUTPUT
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-status}"

    mkdir -p "${CACHE_DIR}"

    case "${action}" in
        status | "")
            local temp
            temp=$(get_temperature)

            if [[ -z "${temp}" ]]; then
                printf '{"text": "󰔏 ?°C", "class": "unknown", "tooltip": "Temperature sensor not found"}\n'
                return 0
            fi

            # Determine icon and class
            local icon class
            if (( temp >= 90 )); then
                icon="󰸁"
                class="critical"
            elif (( temp >= 80 )); then
                icon="󱃂"
                class="hot"
            elif (( temp >= 70 )); then
                icon="󰔏"
                class="warm"
            elif (( temp >= 60 )); then
                icon="󰔏"
                class="moderate"
            elif (( temp >= 40 )); then
                icon="󰔏"
                class="cool"
            else
                icon="󱃃"
                class="cold"
            fi

            # Get all core temps for tooltip
            local core_temps
            core_temps=$(get_all_core_temps)

            local tooltip="🌡️ CPU Temperature\n"
            tooltip+="────────────────────\n"
            tooltip+="Current: ${temp}°C\n"
            if [[ -n "${core_temps}" ]]; then
                tooltip+="────────────────────\n"
                tooltip+="${core_temps}"
            fi

            printf '{"text": "%s %s°C", "tooltip": "%s", "class": "%s", "percentage": %s}\n' \
                "${icon}" "${temp}" "${tooltip}" "${class}" "${temp}"
            ;;

        celsius)
            get_temperature
            ;;

        fahrenheit)
            local temp
            temp=$(get_temperature)
            [[ -n "${temp}" ]] && awk "BEGIN{printf \"%.0f\", ${temp}*9/5+32}" || echo "?"
            ;;

        reset-cache)
            rm -f "${SENSOR_CACHE}"
            echo "Sensor cache cleared"
            ;;

        *)
            echo "Usage: cpu-temp.sh [status|celsius|fahrenheit|reset-cache]"
            exit 1
            ;;
    esac
}

main "$@"