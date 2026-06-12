#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WAYBAR WEATHER MODULE                        ║
# ║           wttr.in weather with icons, caching, and rich tooltips           ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE: weather.sh [ACTION]
#
# ACTIONS:
#   (none)   — Output JSON for Waybar
#   refresh  — Force refresh (ignore cache)
#   location — Set location
#   info     — Show detailed forecast

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly CACHE_FILE="${CACHE_DIR}/weather-cache.json"
readonly LOCATION_FILE="${CACHE_DIR}/weather-location"
readonly LOG_FILE="${CACHE_DIR}/logs/weather.log"
readonly CACHE_TTL=1800  # 30 minutes

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🗺️ LOCATION
# ═══════════════════════════════════════════════════════════════════════════════

get_location() {
    # Check saved location
    if [[ -f "${LOCATION_FILE}" ]]; then
        cat "${LOCATION_FILE}"
        return 0
    fi

    # Auto-detect via IP
    local ip_location
    ip_location=$(curl -s --max-time 5 "https://ipinfo.io/city" 2>/dev/null \
        || curl -s --max-time 5 "https://ipapi.co/city" 2>/dev/null \
        || echo "")

    if [[ -n "${ip_location}" ]]; then
        echo "${ip_location}" > "${LOCATION_FILE}"
        echo "${ip_location}"
    else
        echo "London"  # Ultimate fallback
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🌡️ WEATHER ICONS
# ═══════════════════════════════════════════════════════════════════════════════

get_weather_icon() {
    local condition="${1:-}"
    local is_night="${2:-false}"

    case "${condition}" in
        *"Sunny"* | *"Clear"*)
            [[ "${is_night}" == "true" ]] && echo "󰖔" || echo "󰖙"
            ;;
        *"Partly cloudy"* | *"Partly Cloudy"*)
            [[ "${is_night}" == "true" ]] && echo "󰖕" || echo "󰖕"
            ;;
        *"Cloudy"* | *"Overcast"*)
            echo "󰖐"
            ;;
        *"Mist"* | *"Fog"* | *"Haze"*)
            echo "󰖑"
            ;;
        *"Drizzle"* | *"Light rain"*)
            echo "󰖒"
            ;;
        *"Rain"* | *"Heavy rain"*)
            echo "󰖗"
            ;;
        *"Thunder"* | *"Thunderstorm"*)
            echo "󰖓"
            ;;
        *"Snow"* | *"Blizzard"*)
            echo "󰖘"
            ;;
        *"Sleet"* | *"Freezing"*)
            echo "󰼶"
            ;;
        *"Wind"* | *"Windy"*)
            echo "󰖝"
            ;;
        *"Hail"*)
            echo "󰖒"
            ;;
        *)
            echo "󰖙"
            ;;
    esac
}

get_wind_icon() {
    local speed="${1:-0}"
    if (( speed <= 10 ));  then echo "🌬️"
    elif (( speed <= 30 )); then echo "💨"
    elif (( speed <= 60 )); then echo "🌪️"
    else echo "🌪️🌪️"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🌐 WEATHER FETCH
# ═══════════════════════════════════════════════════════════════════════════════

is_cache_valid() {
    if [[ ! -f "${CACHE_FILE}" ]]; then
        return 1
    fi

    local cache_age=$(( $(date +%s) - $(stat -c %Y "${CACHE_FILE}" 2>/dev/null || echo 0) ))
    (( cache_age < CACHE_TTL ))
}

fetch_weather() {
    local location
    location=$(get_location)

    # Fetch from wttr.in JSON API
    local raw
    raw=$(curl -s \
        --max-time 10 \
        --connect-timeout 5 \
        "https://wttr.in/${location}?format=j1" \
        2>/dev/null) || {
        log "WARN" "Weather fetch failed for ${location}"
        return 1
    }

    # Validate JSON
    echo "${raw}" | jq . > /dev/null 2>&1 || {
        log "WARN" "Invalid JSON from wttr.in"
        return 1
    }

    echo "${raw}" > "${CACHE_FILE}"
    log "INFO" "Weather updated for ${location}"
    echo "${raw}"
}

get_weather_data() {
    local refresh="${1:-false}"

    if [[ "${refresh}" == "true" ]] || ! is_cache_valid; then
        local data
        data=$(fetch_weather 2>/dev/null) || {
            # Try to use stale cache
            if [[ -f "${CACHE_FILE}" ]]; then
                cat "${CACHE_FILE}"
                return 0
            fi
            return 1
        }
        echo "${data}"
    else
        cat "${CACHE_FILE}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 FORMAT OUTPUT
# ═══════════════════════════════════════════════════════════════════════════════

format_waybar_output() {
    local data="$1"

    # Parse current conditions
    local temp_c temp_f feels_like condition humidity wind_kmph uv_index
    temp_c=$(echo "${data}"    | jq -r '.current_condition[0].temp_C // "?"')
    temp_f=$(echo "${data}"    | jq -r '.current_condition[0].temp_F // "?"')
    feels_like=$(echo "${data}" | jq -r '.current_condition[0].FeelsLikeC // "?"')
    condition=$(echo "${data}"  | jq -r '.current_condition[0].weatherDesc[0].value // "Unknown"')
    humidity=$(echo "${data}"   | jq -r '.current_condition[0].humidity // "?"')
    wind_kmph=$(echo "${data}"  | jq -r '.current_condition[0].windspeedKmph // "0"')
    uv_index=$(echo "${data}"   | jq -r '.current_condition[0].uvIndex // "?"')

    # Get icon
    local hour
    hour=$(date +%H)
    local is_night="false"
    (( hour >= 20 || hour < 6 )) && is_night="true"

    local icon
    icon=$(get_weather_icon "${condition}" "${is_night}")

    # Parse 3-day forecast
    local today_max today_min tomorrow_desc tomorrow_max tomorrow_min
    today_max=$(echo "${data}"    | jq -r '.weather[0].maxtempC // "?"')
    today_min=$(echo "${data}"    | jq -r '.weather[0].mintempC // "?"')
    tomorrow_desc=$(echo "${data}" | jq -r '.weather[1].hourly[4].weatherDesc[0].value // "?"')
    tomorrow_max=$(echo "${data}"  | jq -r '.weather[1].maxtempC // "?"')
    tomorrow_min=$(echo "${data}"  | jq -r '.weather[1].mintempC // "?"')

    local tomorrow_icon
    tomorrow_icon=$(get_weather_icon "${tomorrow_desc}" "false")

    local location
    location=$(get_location)

    # Wind icon
    local wind_icon
    wind_icon=$(get_wind_icon "${wind_kmph}")

    # Build tooltip (multi-line)
    local tooltip
    tooltip="📍 ${location}\n"
    tooltip+="─────────────────────────\n"
    tooltip+="${icon} ${condition}\n"
    tooltip+="🌡️ ${temp_c}°C / ${temp_f}°F  (Feels: ${feels_like}°C)\n"
    tooltip+="📊 Today: ${today_min}°C — ${today_max}°C\n"
    tooltip+="💧 Humidity: ${humidity}%\n"
    tooltip+="${wind_icon} Wind: ${wind_kmph} km/h\n"
    tooltip+="☀️ UV Index: ${uv_index}\n"
    tooltip+="─────────────────────────\n"
    tooltip+="Tomorrow: ${tomorrow_icon} ${tomorrow_desc}\n"
    tooltip+="📊 ${tomorrow_min}°C — ${tomorrow_max}°C"

    # Determine class based on temperature
    local class
    if (( temp_c >= 35 ));    then class="hot"
    elif (( temp_c >= 25 ));  then class="warm"
    elif (( temp_c >= 15 ));  then class="mild"
    elif (( temp_c >= 5 ));   then class="cool"
    elif (( temp_c >= 0 ));   then class="cold"
    else                           class="freezing"
    fi

    # Output JSON for Waybar
    printf '{"text": "%s %s°C", "tooltip": "%s", "class": "%s", "percentage": %s}\n' \
        "${icon}" \
        "${temp_c}" \
        "${tooltip}" \
        "${class}" \
        "${humidity}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        refresh)
            fetch_weather > /dev/null
            ok "Weather cache refreshed"
            ;;
        location)
            local loc="${2:-}"
            if [[ -n "${loc}" ]]; then
                echo "${loc}" > "${LOCATION_FILE}"
                rm -f "${CACHE_FILE}"
                echo "Location set to: ${loc}"
                log "INFO" "Location updated: ${loc}"
            else
                get_location
            fi
            ;;
        info)
            local data
            data=$(get_weather_data) || {
                echo "Failed to get weather data"
                exit 1
            }
            echo "${data}" | jq '.'
            ;;
        "")
            # Default: Waybar JSON output
            if ! command -v curl &>/dev/null; then
                printf '{"text": "󰖙 N/A", "tooltip": "curl not installed", "class": "error"}\n'
                exit 0
            fi

            local data
            data=$(get_weather_data) || {
                printf '{"text": "󰖙 ?", "tooltip": "Weather unavailable — check internet connection", "class": "error"}\n'
                exit 0
            }

            format_waybar_output "${data}"
            ;;
        *)
            echo "Usage: weather.sh [refresh|location CITY|info]"
            exit 1
            ;;
    esac
}

main "$@"