#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Waybar Script: Weather                           ║
# ║                                                                              ║
# ║  Fetches weather data from wttr.in and formats it for Waybar JSON output.  ║
# ║  Supports full, compact and raw modes. Caches results to reduce API calls.  ║
# ║                                                                              ║
# ║  Usage:                                                                      ║
# ║    weather.sh              — full format (default)                          ║
# ║    weather.sh --full       — full: icon + temp + condition                  ║
# ║    weather.sh --compact    — compact: icon + temp only                      ║
# ║    weather.sh --refresh    — force cache refresh                            ║
# ║    weather.sh --raw        — raw JSON from wttr.in                          ║
# ║                                                                              ║
# ║  Config:                                                                     ║
# ║    WEATHER_LOCATION        — set in env.conf (empty = auto-detect by IP)    ║
# ║    WEATHER_UNIT            — "C" or "F" (default: C)                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# §01  CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

readonly LOCATION="${WEATHER_LOCATION:-}"          # Empty = auto-detect by IP
readonly UNIT="${WEATHER_UNIT:-C}"                  # C or F
readonly CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/ash-dotfiles/weather.json"
readonly CACHE_AGE=1800                             # Cache validity in seconds (30 min)
readonly TIMEOUT=10                                 # HTTP timeout in seconds
readonly MAX_TOOLTIP_EVENTS=5                       # 3-day forecast entries in tooltip

# ══════════════════════════════════════════════════════════════════════════════
# §02  WEATHER CONDITION → ICON MAP
#      Maps wttr.in weather codes to Nerd Font / Unicode icons
# ══════════════════════════════════════════════════════════════════════════════

declare -A CONDITION_ICONS=(
    # ── Clear ─────────────────────────────────────────────────────────────────
    ["Sunny"]="󰖙"
    ["Clear"]="󰖙"
    ["clear"]="󰖔"              # Night clear
    # ── Clouds ────────────────────────────────────────────────────────────────
    ["Partly cloudy"]="󰖕"
    ["Partly Cloudy"]="󰖕"
    ["Cloudy"]="󰖐"
    ["Overcast"]="󰖐"
    # ── Rain ──────────────────────────────────────────────────────────────────
    ["Light rain"]="󰖗"
    ["Moderate rain"]="󰖗"
    ["Heavy rain"]="󰖖"
    ["Light drizzle"]="󰖗"
    ["Drizzle"]="󰖗"
    ["Freezing drizzle"]="󰖘"
    ["Patchy rain possible"]="󰖕"
    # ── Snow ──────────────────────────────────────────────────────────────────
    ["Light snow"]="󰖘"
    ["Moderate snow"]="󰖘"
    ["Heavy snow"]="󰖘"
    ["Blizzard"]="󰖘"
    ["Patchy snow possible"]="󰖘"
    # ── Storms ────────────────────────────────────────────────────────────────
    ["Thundery outbreaks possible"]="󰖓"
    ["Patchy light rain with thunder"]="󰖓"
    ["Moderate or heavy rain with thunder"]="󰖓"
    # ── Other ─────────────────────────────────────────────────────────────────
    ["Mist"]="󰖑"
    ["Fog"]="󰖑"
    ["Freezing fog"]="󰖑"
    ["Blowing snow"]="󰖘"
    ["Ice pellets"]="󰖘"
    ["Sleet"]="󰖘"
)

get_weather_icon() {
    local condition="${1:-}"
    local icon="${CONDITION_ICONS[$condition]:-}"
    if [[ -z "$icon" ]]; then
        # Fuzzy fallback matching
        local lc="${condition,,}"
        if   [[ "$lc" =~ sunny|clear ]];       then icon="󰖙"
        elif [[ "$lc" =~ cloud|overcast ]];     then icon="󰖐"
        elif [[ "$lc" =~ thunder|storm ]];      then icon="󰖓"
        elif [[ "$lc" =~ snow|blizzard|sleet ]];then icon="󰖘"
        elif [[ "$lc" =~ rain|drizzle|shower ]];then icon="󰖗"
        elif [[ "$lc" =~ fog|mist ]];           then icon="󰖑"
        else                                        icon="󰖙"
        fi
    fi
    echo "$icon"
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  WIND DIRECTION → ARROW
# ══════════════════════════════════════════════════════════════════════════════

wind_arrow() {
    local deg="${1:-0}"
    local dirs=("N" "NE" "E" "SE" "S" "SW" "W" "NW")
    local arrows=("↑" "↗" "→" "↘" "↓" "↙" "←" "↖")
    local idx=$(( (deg + 22) / 45 % 8 ))
    echo "${arrows[$idx]}"
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  CACHE MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

is_cache_valid() {
    [[ -f "$CACHE_FILE" ]] || return 1
    local age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) ))
    [[ $age -lt $CACHE_AGE ]]
}

fetch_weather() {
    mkdir -p "$(dirname "$CACHE_FILE")"
    local url="https://wttr.in/${LOCATION}?format=j1"
    if curl -sf --max-time "$TIMEOUT" --compressed "$url" > "$CACHE_FILE" 2>/dev/null; then
        return 0
    else
        rm -f "$CACHE_FILE"
        return 1
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  PARSE WEATHER DATA
# ══════════════════════════════════════════════════════════════════════════════

parse_weather() {
    local data="$1"

    # ── Current conditions ────────────────────────────────────────────────────
    local CONDITION TEMP_C TEMP_F FEELS_C HUMIDITY WIND_KMH WIND_DIR_DEG
    local WIND_DIR_STR PRESSURE UV_INDEX VISIBILITY AREA COUNTRY

    CONDITION=$(    jq -r '.current_condition[0].weatherDesc[0].value'    <<< "$data")
    TEMP_C=$(       jq -r '.current_condition[0].temp_C'                  <<< "$data")
    TEMP_F=$(       jq -r '.current_condition[0].temp_F'                  <<< "$data")
    FEELS_C=$(      jq -r '.current_condition[0].FeelsLikeC'              <<< "$data")
    FEELS_F=$(      jq -r '.current_condition[0].FeelsLikeF'              <<< "$data")
    HUMIDITY=$(     jq -r '.current_condition[0].humidity'                <<< "$data")
    WIND_KMH=$(     jq -r '.current_condition[0].windspeedKmph'           <<< "$data")
    WIND_MILES=$(   jq -r '.current_condition[0].windspeedMiles'          <<< "$data")
    WIND_DIR_DEG=$( jq -r '.current_condition[0].winddirDegree'           <<< "$data")
    WIND_DIR_STR=$( jq -r '.current_condition[0].winddir16Point'          <<< "$data")
    UV_INDEX=$(     jq -r '.current_condition[0].uvIndex'                 <<< "$data")
    PRESSURE=$(     jq -r '.current_condition[0].pressure'                <<< "$data")
    VISIBILITY=$(   jq -r '.current_condition[0].visibility'              <<< "$data")
    AREA=$(         jq -r '.nearest_area[0].areaName[0].value'            <<< "$data")
    COUNTRY=$(      jq -r '.nearest_area[0].country[0].value'             <<< "$data")

    # ── Select unit ───────────────────────────────────────────────────────────
    local TEMP FEELS WIND_SPEED WIND_UNIT
    if [[ "$UNIT" == "F" ]]; then
        TEMP="$TEMP_F°F"
        FEELS="${FEELS_F}°F"
        WIND_SPEED="${WIND_MILES} mph"
    else
        TEMP="${TEMP_C}°C"
        FEELS="${FEELS_C}°C"
        WIND_SPEED="${WIND_KMH} km/h"
    fi

    local WIND_ARROW
    WIND_ARROW=$(wind_arrow "$WIND_DIR_DEG")
    local ICON
    ICON=$(get_weather_icon "$CONDITION")

    # ── 3-day forecast ────────────────────────────────────────────────────────
    local FORECAST=""
    local i
    for i in 0 1 2; do
        local DAY_DATE DAY_MAX DAY_MIN DAY_COND DAY_ICON
        DAY_DATE=$(  jq -r ".weather[$i].date"                               <<< "$data")
        if [[ "$UNIT" == "F" ]]; then
            DAY_MAX=$(jq -r ".weather[$i].maxtempF"                          <<< "$data")
            DAY_MIN=$(jq -r ".weather[$i].mintempF"                          <<< "$data")
            DAY_MAX="${DAY_MAX}°F"; DAY_MIN="${DAY_MIN}°F"
        else
            DAY_MAX=$(jq -r ".weather[$i].maxtempC"                          <<< "$data")
            DAY_MIN=$(jq -r ".weather[$i].mintempC"                          <<< "$data")
            DAY_MAX="${DAY_MAX}°C"; DAY_MIN="${DAY_MIN}°C"
        fi
        DAY_COND=$(  jq -r ".weather[$i].hourly[4].weatherDesc[0].value"    <<< "$data")
        DAY_ICON=$(get_weather_icon "$DAY_COND")
        local DOW
        DOW=$(date -d "$DAY_DATE" +"%a" 2>/dev/null || echo "Day$i")
        FORECAST+="\n${DOW}  ${DAY_ICON}  ${DAY_MAX} / ${DAY_MIN}"
    done

    # ── Output JSON ───────────────────────────────────────────────────────────
    local TEXT TOOLTIP CSS_CLASS
    TEXT="${ICON} ${TEMP}"
    CSS_CLASS="weather"

    TOOLTIP="${AREA}, ${COUNTRY}\n"
    TOOLTIP+="${ICON} ${CONDITION}\n\n"
    TOOLTIP+="  Temp:       ${TEMP} (feels ${FEELS})\n"
    TOOLTIP+="  Humidity:   ${HUMIDITY}%\n"
    TOOLTIP+="  Wind:       ${WIND_ARROW} ${WIND_DIR_STR} ${WIND_SPEED}\n"
    TOOLTIP+="  UV Index:   ${UV_INDEX}\n"
    TOOLTIP+="  Pressure:   ${PRESSURE} hPa\n"
    TOOLTIP+="  Visibility: ${VISIBILITY} km\n"
    TOOLTIP+="\n── 3-Day Forecast ──${FORECAST}\n"
    TOOLTIP+="\nLast updated: $(date '+%H:%M')"

    # Escape for JSON
    TEXT=$(echo "$TEXT" | sed 's/\\/\\\\/g; s/"/\\"/g')
    TOOLTIP=$(echo "$TOOLTIP" | sed 's/\\/\\\\/g; s/"/\\"/g')

    printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
        "$TEXT" "$TOOLTIP" "$CSS_CLASS"
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  OUTPUT MODES
# ══════════════════════════════════════════════════════════════════════════════

compact_output() {
    local data="$1"
    local CONDITION TEMP ICON
    CONDITION=$(jq -r '.current_condition[0].weatherDesc[0].value' <<< "$data")
    if [[ "$UNIT" == "F" ]]; then
        TEMP=$(jq -r '.current_condition[0].temp_F' <<< "$data")°F
    else
        TEMP=$(jq -r '.current_condition[0].temp_C' <<< "$data")°C
    fi
    ICON=$(get_weather_icon "$CONDITION")

    local AREA
    AREA=$(jq -r '.nearest_area[0].areaName[0].value' <<< "$data")

    printf '{"text":"%s %s","tooltip":"%s — %s","class":"weather-compact"}\n' \
        "$ICON" "$TEMP" "$AREA" "$CONDITION"
}

error_output() {
    printf '{"text":"󰖑 N/A","tooltip":"Weather: %s","class":"weather-error"}\n' \
        "${1:-Unable to fetch}"
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  MAIN
# ══════════════════════════════════════════════════════════════════════════════

main() {
    local mode="full"
    local force_refresh=false

    # Parse args
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --full)     mode="full"     ;;
            --compact)  mode="compact"  ;;
            --raw)      mode="raw"      ;;
            --refresh)  force_refresh=true ;;
            --waybar)   mode="full"     ;;
            *)          ;;
        esac
        shift
    done

    # Check connectivity
    if ! ping -c1 -W2 wttr.in &>/dev/null; then
        error_output "No internet connection"
        exit 0
    fi

    # Refresh cache if needed
    if [[ "$force_refresh" == true ]] || ! is_cache_valid; then
        if ! fetch_weather; then
            if [[ -f "$CACHE_FILE" ]]; then
                : # Use stale cache as fallback
            else
                error_output "Failed to fetch weather data"
                exit 0
            fi
        fi
    fi

    # Validate cache
    if [[ ! -f "$CACHE_FILE" ]] || ! jq -e '.current_condition' "$CACHE_FILE" &>/dev/null; then
        rm -f "$CACHE_FILE"
        error_output "Invalid weather data"
        exit 0
    fi

    local data
    data=$(cat "$CACHE_FILE")

    case "$mode" in
        full)    parse_weather "$data" ;;
        compact) compact_output "$data" ;;
        raw)     echo "$data" ;;
    esac
}

main "$@"