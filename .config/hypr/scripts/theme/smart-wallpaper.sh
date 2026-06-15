#!/bin/bash
set -euo pipefail

# Smart Wallpaper - Changes wallpaper based on time of day and weather

readonly WALLPAPER_DIR="${HOME}/Pictures/wallpapers"
readonly CACHE_DIR="${HOME}/.cache/ash-dots/wallpapers"

mkdir -p "${CACHE_DIR}"

get_time_category() {
    local hour
    hour=$(date +%H)
    hour=$((10#${hour}))

    if (( hour >= 5 && hour < 8 )); then
        echo "dawn"
    elif (( hour >= 8 && hour < 12 )); then
        echo "morning"
    elif (( hour >= 12 && hour < 17 )); then
        echo "afternoon"
    elif (( hour >= 17 && hour < 20 )); then
        echo "sunset"
    elif (( hour >= 20 && hour < 23 )); then
        echo "evening"
    else
        echo "night"
    fi
}

get_weather_category() {
    local weather_cache="${CACHE_DIR}/weather.json"
    local weather_condition="clear"

    if [[ -f "${weather_cache}" ]]; then
        local cache_age=$(( $(date +%s) - $(stat -c %Y "${weather_cache}" 2>/dev/null || echo 0) ))
        if (( cache_age < 1800 )); then
            weather_condition=$(jq -r '.weather[0].main // "clear"' "${weather_cache}" 2>/dev/null | tr '[:upper:]' '[:lower:]')
        fi
    fi

    case "${weather_condition}" in
        rain|drizzle|thunderstorm) echo "rainy" ;;
        snow) echo "snowy" ;;
        mist|fog|haze) echo "foggy" ;;
        clouds|overcast) echo "cloudy" ;;
        clear) echo "clear" ;;
        *) echo "clear" ;;
    esac
}

fetch_weather() {
    local lat="${ASH_LAT:-}"
    local lon="${ASH_LON:-}"
    local api_key="${ASH_WEATHER_API_KEY:-}"

    if [[ -z "${lat}" || -z "${lon}" || -z "${api_key}" ]]; then
        return 0
    fi

    local weather_cache="${CACHE_DIR}/weather.json"
    curl -sf "https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${api_key}&units=metric" \
        -o "${weather_cache}.tmp" && mv "${weather_cache}.tmp" "${weather_cache}" 2>/dev/null || true
}

select_wallpaper() {
    local time_cat="${1:-$(get_time_category)}"
    local weather_cat="${2:-$(get_weather_category)}"
    local search_dir="${WALLPAPER_DIR}/${time_cat}"

    [[ -d "${search_dir}" ]] || search_dir="${WALLPAPER_DIR}"

    local weather_subdir="${search_dir}/${weather_cat}"
    local wallpapers=()

    if [[ -d "${weather_subdir}" ]]; then
        mapfile -t wallpapers < <(find "${weather_subdir}" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null)
    fi

    if [[ ${#wallpapers[@]} -eq 0 ]]; then
        mapfile -t wallpapers < <(find "${search_dir}" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null)
    fi

    if [[ ${#wallpapers[@]} -eq 0 ]]; then
        mapfile -t wallpapers < <(find "${WALLPAPER_DIR}" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null)
    fi

    if [[ ${#wallpapers[@]} -gt 0 ]]; then
        echo "${wallpapers[RANDOM % ${#wallpapers[@]}]}"
    fi
}

apply_wallpaper() {
    local wallpaper="${1:-}"
    [[ -z "${wallpaper}" ]] && wallpaper=$(select_wallpaper)
    [[ -z "${wallpaper}" ]] && { echo "No wallpaper found"; return 1; }

    hyprctl hyprpaper preload "${wallpaper}" 2>/dev/null
    hyprctl hyprpaper wallpaper ",${wallpaper}" 2>/dev/null

    echo "${wallpaper}" > "${CACHE_DIR}/current"
}

main() {
    local action="${1:-apply}"

    case "${action}" in
        apply)
            fetch_weather
            apply_wallpaper
            ;;
        time)
            get_time_category
            ;;
        weather)
            get_weather_category
            ;;
        fetch)
            fetch_weather
            ;;
        select)
            select_wallpaper "$(get_time_category)" "$(get_weather_category)"
            ;;
        *)
            echo "Usage: smart-wallpaper.sh [apply|time|weather|fetch|select]"
            exit 1
            ;;
    esac
}

main "$@"