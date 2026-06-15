#!/bin/bash
set -euo pipefail

CACHE_FILE="${HOME}/.cache/ash-dots/wallpapers/weather.json"
LAT="${ASH_LAT:-}"
LON="${ASH_LON:-}"
API_KEY="${ASH_WEATHER_API_KEY:-}"

fetch_weather() {
    [[ -z "$LAT" || -z "$LON" || -z "$API_KEY" ]] && return 1
    curl -sf "https://api.openweathermap.org/data/2.5/weather?lat=$LAT&lon=$LON&appid=$API_KEY&units=metric" \
        -o "$CACHE_FILE.tmp" && mv "$CACHE_FILE.tmp" "$CACHE_FILE"
}

get_condition() {
    [[ -f "$CACHE_FILE" ]] || return 1
    jq -r '.weather[0].main // "clear"' "$CACHE_FILE" 2>/dev/null | tr '[:upper:]' '[:lower:]'
}

get_temp() {
    [[ -f "$CACHE_FILE" ]] || return 1
    jq -r '.main.temp // 0' "$CACHE_FILE" 2>/dev/null | awk '{printf "%.0f", $1}'
}

get_humidity() {
    [[ -f "$CACHE_FILE" ]] || return 1
    jq -r '.main.humidity // 0' "$CACHE_FILE" 2>/dev/null
}

get_wind() {
    [[ -f "$CACHE_FILE" ]] || return 1
    jq -r '.wind.speed // 0' "$CACHE_FILE" 2>/dev/null | awk '{printf "%.1f", $1}'
}

main() {
    case "${1:-}" in
        fetch) fetch_weather ;;
        condition) get_condition ;;
        temp) get_temp ;;
        humidity) get_humidity ;;
        wind) get_wind ;;
        all)
            fetch_weather
            echo "Condition: $(get_condition)"
            echo "Temperature: $(get_temp)°C"
            echo "Humidity: $(get_humidity)%"
            echo "Wind: $(get_wind) m/s"
            ;;
        *) echo "Usage: weather.sh [fetch|condition|temp|humidity|wind|all]"; exit 1 ;;
    esac
}

main "$@"