#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — HYPRLOCK SCRIPT: WEATHER-LOCK                   ║
# ║  Atmospheric intelligence engine — cache-native, zero-latency, rich output ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │  DESCRIPTION                                                                 │
# │  Full-featured weather data provider for all hyprlock weather widgets.      │
# │  Reads EXCLUSIVELY from ash weather cache — zero network calls on lock.    │
# │  Cache is written by ash-weather-fetch.timer (every 30 minutes via         │
# │  scripts/notification/weather.sh which calls wttr.in JSON API).            │
# │                                                                              │
# │  DESIGN PRINCIPLE: Lock screen scripts must NEVER block on network I/O.    │
# │  All data is pre-fetched, cached, and validated before lock activation.    │
# │                                                                              │
# │  USAGE                                                                       │
# │    weather-lock.sh                  Full primary conditions line            │
# │    weather-lock.sh --line1          Icon + temp + feels + condition         │
# │    weather-lock.sh --line2          Humidity + wind + UV + visibility       │
# │    weather-lock.sh --compact        Single compact line for ticker          │
# │    weather-lock.sh --minimal        Icon + temp only (8 chars)             │
# │    weather-lock.sh --location       "City, Country" only                   │
# │    weather-lock.sh --icon           Condition icon glyph only              │
# │    weather-lock.sh --temp           Temperature only with unit             │
# │    weather-lock.sh --full           All data, multi-line rich format       │
# │    weather-lock.sh --icon-temp      Large icon + temp (hero variant)       │
# │    weather-lock.sh --now            Current conditions brief               │
# │    weather-lock.sh --forecast       3-day forecast strip                   │
# │    weather-lock.sh --panel-header   Dashboard panel header line            │
# │    weather-lock.sh --panel-body     Dashboard panel body (multi-line)      │
# │    weather-lock.sh --sunrise        Sunrise time + countdown               │
# │    weather-lock.sh --sunset         Sunset time + countdown                │
# │    weather-lock.sh --solar          Sunrise + sunset + golden hour info    │
# │    weather-lock.sh --aqi            Air quality index (if available)       │
# │    weather-lock.sh --pressure       Barometric pressure + trend            │
# │    weather-lock.sh --wind           Wind speed + direction + gusts         │
# │    weather-lock.sh --moon           Lunar phase icon + phase name          │
# │    weather-lock.sh --feels          Feels-like temperature only            │
# │    weather-lock.sh --humidity       Humidity % with status label           │
# │    weather-lock.sh --uv             UV index with risk level               │
# │    weather-lock.sh --stale-check    Output warning if cache is stale       │
# │                                                                              │
# │  CACHE STRUCTURE                                                             │
# │  ~/.cache/ash/weather/current.json                                          │
# │  {                                                                           │
# │    "temp_c": 22,        "temp_f": 71,                                       │
# │    "feels_c": 19,       "feels_f": 66,                                      │
# │    "humidity": 65,      "wind_kph": 14,     "wind_mph": 8,                 │
# │    "wind_dir": "SW",    "wind_degree": 225, "gust_kph": 22,               │
# │    "condition": "Partly cloudy",            "code": 1003,                  │
# │    "is_day": 1,         "uv": 4,                                            │
# │    "vis_km": 10,        "vis_miles": 6,                                    │
# │    "pressure_mb": 1013, "precip_mm": 0.0,  "precip_in": 0.0,             │
# │    "cloud": 25,         "feelslike_c": 19,  "feelslike_f": 66,            │
# │    "city": "London",    "country": "UK",    "region": "England",           │
# │    "lat": 51.52,        "lon": -0.11,                                       │
# │    "localtime": "2025-01-15 22:30",                                         │
# │    "sunrise": "07:24 AM", "sunset": "04:48 PM",                            │
# │    "moonrise": "02:15 PM", "moonset": "03:28 AM",                          │
# │    "moon_phase": "Waxing Gibbous", "moon_illumination": 72,               │
# │    "aqi_us": 42,        "aqi_gb": 2,                                        │
# │    "fetched_at": "2025-01-15T22:30:00Z",                                   │
# │    "forecast": [                                                             │
# │      {"date":"2025-01-16","max_c":20,"min_c":12,"code":1063,"precip":1.2}, │
# │      {"date":"2025-01-17","max_c":18,"min_c":10,"code":1180,"precip":4.8}, │
# │      {"date":"2025-01-18","max_c":22,"min_c":14,"code":1000,"precip":0.0}  │
# │    ]                                                                         │
# │  }                                                                           │
# └─────────────────────────────────────────────────────────────────────────────┘

set -euo pipefail

readonly SCRIPT_NAME="weather-lock"
readonly SCRIPT_VERSION="5.0.0"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 01 — CONFIGURATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Cache paths ───────────────────────────────────────────────────────────────
readonly CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/ash/weather"
readonly CACHE_FILE="${CACHE_ROOT}/current.json"
readonly FORECAST_FILE="${CACHE_ROOT}/forecast.json"
readonly STALE_THRESHOLD_SECONDS=7200   # 2 hours → show staleness warning
readonly CRITICAL_STALE_SECONDS=21600   # 6 hours → data considered unreliable

# ── Unit system ───────────────────────────────────────────────────────────────
# Reads from ash config. Default: metric (°C, km/h, km)
# Override: ash config set weather.units imperial
readonly UNITS="${HL_WEATHER_UNITS:-metric}"

# ── Fallback output when cache unavailable ────────────────────────────────────
readonly FALLBACK_NO_CACHE="─"
readonly FALLBACK_NO_DATA="─"
readonly FALLBACK_LOCATION="Unknown location"

# ── UV index risk thresholds ──────────────────────────────────────────────────
readonly UV_LOW=2
readonly UV_MODERATE=5
readonly UV_HIGH=7
readonly UV_VERY_HIGH=10

# ── Pango color codes (no # — used with ##$VAR in markup) ────────────────────
readonly COLOR_PRIMARY="cdd6f4"    # Text (normal conditions)
readonly COLOR_WARM="fab387"       # Peach (hot/warm)
readonly COLOR_COLD="89dceb"       # Sky blue (cold)
readonly COLOR_RAIN="89b4fa"       # Blue (rain)
readonly COLOR_STORM="cba6f7"      # Mauve (storm)
readonly COLOR_SNOW="b4befe"       # Lavender (snow)
readonly COLOR_SUN="f9e2af"        # Yellow (sunny)
readonly COLOR_MUTED="6c7086"      # Overlay0 (subtle)
readonly COLOR_WARN="f9e2af"       # Yellow (warnings)
readonly COLOR_ERROR="f38ba8"      # Red (critical)
readonly COLOR_SUCCESS="a6e3a1"    # Green (good AQI, low UV)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 02 — WMO WEATHER CODE → ICON + DESCRIPTION MAPPING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Maps weatherapi.com condition codes to Nerd Font glyphs + display strings.
# is_day=1 → day icons  |  is_day=0 → night icons where variants exist.
# Full code list: https://www.weatherapi.com/docs/weather_conditions.json

# ── Day condition icon mapping ────────────────────────────────────────────────
declare -A ICON_DAY=(
    [1000]="󰖙"   # Sunny / Clear
    [1003]="󰖕"   # Partly cloudy
    [1006]="󰖐"   # Cloudy
    [1009]="󰖐"   # Overcast
    [1030]="󰖑"   # Mist
    [1063]="󰖗"   # Patchy rain possible
    [1066]="󰖘"   # Patchy snow possible
    [1069]="󰖘"   # Patchy sleet possible
    [1072]="󰖘"   # Patchy freezing drizzle possible
    [1087]="󰖓"   # Thundery outbreaks possible
    [1114]="󰖒"   # Blowing snow
    [1117]="󰖒"   # Blizzard
    [1135]="󰖑"   # Fog
    [1147]="󰖑"   # Freezing fog
    [1150]="󰖗"   # Patchy light drizzle
    [1153]="󰖗"   # Light drizzle
    [1168]="󰖗"   # Freezing drizzle
    [1171]="󰖗"   # Heavy freezing drizzle
    [1180]="󰖖"   # Patchy light rain
    [1183]="󰖖"   # Light rain
    [1186]="󰖖"   # Moderate rain at times
    [1189]="󰖖"   # Moderate rain
    [1192]="󰖖"   # Heavy rain at times
    [1195]="󰖖"   # Heavy rain
    [1198]="󰖖"   # Light freezing rain
    [1201]="󰖖"   # Moderate or heavy freezing rain
    [1204]="󰖘"   # Light sleet
    [1207]="󰖘"   # Moderate or heavy sleet
    [1210]="󰖘"   # Patchy light snow
    [1213]="󰖘"   # Light snow
    [1216]="󰖘"   # Patchy moderate snow
    [1219]="󰖘"   # Moderate snow
    [1222]="󰖒"   # Patchy heavy snow
    [1225]="󰖒"   # Heavy snow
    [1237]="󰖘"   # Ice pellets
    [1240]="󰖗"   # Light rain shower
    [1243]="󰖖"   # Moderate or heavy rain shower
    [1246]="󰖖"   # Torrential rain shower
    [1249]="󰖘"   # Light sleet showers
    [1252]="󰖘"   # Moderate or heavy sleet showers
    [1255]="󰖘"   # Light snow showers
    [1258]="󰖒"   # Moderate or heavy snow showers
    [1261]="󰖘"   # Light showers of ice pellets
    [1264]="󰖘"   # Moderate or heavy showers of ice pellets
    [1273]="󰖓"   # Patchy light rain with thunder
    [1276]="󰖓"   # Moderate or heavy rain with thunder
    [1279]="󰖓"   # Patchy light snow with thunder
    [1282]="󰖓"   # Moderate or heavy snow with thunder
)

# ── Night condition icon mapping (overrides for night variants) ───────────────
declare -A ICON_NIGHT=(
    [1000]="󰖔"   # Clear (night)
    [1003]="󰖔"   # Partly cloudy (night)
    [1006]="󰖐"   # Cloudy (same)
    [1009]="󰖐"   # Overcast (same)
)

# ── Condition description strings ─────────────────────────────────────────────
declare -A CONDITION_DESC=(
    [1000]="Clear"
    [1003]="Partly cloudy"
    [1006]="Cloudy"
    [1009]="Overcast"
    [1030]="Misty"
    [1063]="Light rain"
    [1066]="Light snow"
    [1069]="Sleet"
    [1087]="Thunderstorms"
    [1114]="Blowing snow"
    [1117]="Blizzard"
    [1135]="Foggy"
    [1147]="Freezing fog"
    [1150]="Light drizzle"
    [1153]="Drizzle"
    [1168]="Freezing drizzle"
    [1180]="Light rain"
    [1183]="Light rain"
    [1186]="Moderate rain"
    [1189]="Moderate rain"
    [1192]="Heavy rain"
    [1195]="Heavy rain"
    [1204]="Light sleet"
    [1207]="Heavy sleet"
    [1210]="Light snow"
    [1213]="Light snow"
    [1219]="Moderate snow"
    [1225]="Heavy snow"
    [1240]="Rain showers"
    [1243]="Heavy showers"
    [1255]="Snow showers"
    [1273]="Rain + thunder"
    [1276]="Storm"
    [1282]="Snow + thunder"
)

# ── Condition color mapping ───────────────────────────────────────────────────
# Maps condition code to semantic color for Pango markup.
declare -A CONDITION_COLOR=(
    [1000]="$COLOR_SUN"
    [1003]="$COLOR_PRIMARY"
    [1006]="$COLOR_PRIMARY"
    [1009]="$COLOR_MUTED"
    [1030]="$COLOR_MUTED"
    [1063]="$COLOR_RAIN"
    [1066]="$COLOR_SNOW"
    [1069]="$COLOR_SNOW"
    [1087]="$COLOR_STORM"
    [1114]="$COLOR_SNOW"
    [1117]="$COLOR_SNOW"
    [1135]="$COLOR_MUTED"
    [1180]="$COLOR_RAIN"
    [1183]="$COLOR_RAIN"
    [1186]="$COLOR_RAIN"
    [1189]="$COLOR_RAIN"
    [1192]="$COLOR_RAIN"
    [1195]="$COLOR_RAIN"
    [1204]="$COLOR_SNOW"
    [1213]="$COLOR_SNOW"
    [1219]="$COLOR_SNOW"
    [1225]="$COLOR_SNOW"
    [1240]="$COLOR_RAIN"
    [1243]="$COLOR_RAIN"
    [1273]="$COLOR_STORM"
    [1276]="$COLOR_STORM"
)

# ── Wind direction degree → compass + icon ────────────────────────────────────
declare -A WIND_DIR_ICONS=(
    [N]="↑" [NNE]="↑" [NE]="↗" [ENE]="→"
    [E]="→" [ESE]="→" [SE]="↘" [SSE]="↓"
    [S]="↓" [SSW]="↓" [SW]="↙" [WSW]="←"
    [W]="←" [WNW]="←" [NW]="↖" [NNW]="↑"
)

# ── Moon phase icons ──────────────────────────────────────────────────────────
declare -A MOON_ICONS=(
    ["New Moon"]="🌑"
    ["Waxing Crescent"]="🌒"
    ["First Quarter"]="🌓"
    ["Waxing Gibbous"]="🌔"
    ["Full Moon"]="🌕"
    ["Waning Gibbous"]="🌖"
    ["Last Quarter"]="🌗"
    ["Waning Crescent"]="🌘"
)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 03 — CACHE MANAGEMENT & JSON PARSING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Validate cache file exists and is readable ────────────────────────────────
_cache_valid() {
    [[ -f "$CACHE_FILE" && -r "$CACHE_FILE" && -s "$CACHE_FILE" ]]
}

# ── Check cache staleness ─────────────────────────────────────────────────────
# Returns: seconds since last fetch, or 999999 if unknown
_cache_age_seconds() {
    if [[ ! -f "$CACHE_FILE" ]]; then
        echo "999999"
        return 0
    fi

    local fetched_at
    fetched_at=$(_json_get "fetched_at" "")

    if [[ -n "$fetched_at" ]]; then
        # Parse ISO 8601 timestamp
        local fetch_epoch
        fetch_epoch=$(date -d "$fetched_at" +%s 2>/dev/null \
            || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$fetched_at" +%s 2>/dev/null \
            || echo "0")
        local now_epoch
        now_epoch=$(date +%s)
        echo $(( now_epoch - fetch_epoch ))
    else
        # Fall back to file modification time
        local mtime
        mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null \
            || stat -f %m "$CACHE_FILE" 2>/dev/null \
            || echo "0")
        echo $(( $(date +%s) - mtime ))
    fi
}

# ── Extract JSON value by key (pure bash, no jq required) ─────────────────────
# Handles: strings, integers, floats, booleans.
# Usage: _json_get "key" "default"
# Limitation: top-level keys only (nested requires jq or python3)
_json_get() {
    local key="${1:-}"
    local default="${2:-}"

    if [[ ! -f "$CACHE_FILE" ]]; then
        echo "$default"
        return 0
    fi

    local val
    # Match: "key": value  (handles string, number, boolean)
    # String values (quoted)
    val=$(grep -oP "\"${key}\":\s*\"[^\"]*\"" "$CACHE_FILE" 2>/dev/null \
        | head -1 \
        | grep -oP ":\s*\"\K[^\"]+") \
        || val=""

    if [[ -z "$val" ]]; then
        # Numeric/boolean values (unquoted)
        val=$(grep -oP "\"${key}\":\s*\K[-0-9.truefals]+" "$CACHE_FILE" 2>/dev/null \
            | head -1) \
            || val=""
    fi

    echo "${val:-$default}"
}

# ── Extract JSON value using python3 (fallback for complex keys) ───────────────
# More reliable than regex for edge cases (unicode, nested, etc.)
_json_get_py() {
    local key="${1:-}"
    local default="${2:-}"

    if ! command -v python3 &>/dev/null || [[ ! -f "$CACHE_FILE" ]]; then
        _json_get "$key" "$default"
        return 0
    fi

    python3 -c "
import json, sys
try:
    with open('${CACHE_FILE}') as f:
        d = json.load(f)
    val = d.get('${key}', '${default}')
    print(val if val is not None else '${default}')
except:
    print('${default}')
" 2>/dev/null || echo "$default"
}

# ── Load all weather data into globals ────────────────────────────────────────
# Populates: W_TEMP W_TEMP_F W_FEELS W_FEELS_F W_HUMIDITY W_WIND_KPH
#   W_WIND_MPH W_WIND_DIR W_GUST_KPH W_CONDITION W_CODE W_IS_DAY
#   W_UV W_VIS_KM W_VIS_MI W_PRESSURE W_PRECIP_MM W_PRECIP_IN
#   W_CLOUD W_CITY W_COUNTRY W_REGION W_SUNRISE W_SUNSET
#   W_MOONRISE W_MOONSET W_MOON_PHASE W_MOON_ILLUM W_AQI_US W_AQI_GB
_load_weather_data() {
    if ! _cache_valid; then
        return 1
    fi

    W_TEMP=$(_json_get "temp_c" "0")
    W_TEMP_F=$(_json_get "temp_f" "32")
    W_FEELS=$(_json_get "feelslike_c" "$(_json_get "feels_c" "0")")
    W_FEELS_F=$(_json_get "feelslike_f" "$(_json_get "feels_f" "32")")
    W_HUMIDITY=$(_json_get "humidity" "0")
    W_WIND_KPH=$(_json_get "wind_kph" "0")
    W_WIND_MPH=$(_json_get "wind_mph" "0")
    W_WIND_DIR=$(_json_get "wind_dir" "N")
    W_WIND_DEG=$(_json_get "wind_degree" "0")
    W_GUST_KPH=$(_json_get "gust_kph" "0")
    W_CONDITION=$(_json_get "condition" "Unknown")
    W_CODE=$(_json_get "code" "1000")
    W_IS_DAY=$(_json_get "is_day" "1")
    W_UV=$(_json_get "uv" "0")
    W_VIS_KM=$(_json_get "vis_km" "0")
    W_VIS_MI=$(_json_get "vis_miles" "0")
    W_PRESSURE=$(_json_get "pressure_mb" "1013")
    W_PRECIP_MM=$(_json_get "precip_mm" "0")
    W_PRECIP_IN=$(_json_get "precip_in" "0")
    W_CLOUD=$(_json_get "cloud" "0")
    W_CITY=$(_json_get "city" "")
    W_COUNTRY=$(_json_get "country" "")
    W_REGION=$(_json_get "region" "")
    W_SUNRISE=$(_json_get "sunrise" "")
    W_SUNSET=$(_json_get "sunset" "")
    W_MOONRISE=$(_json_get "moonrise" "")
    W_MOONSET=$(_json_get "moonset" "")
    W_MOON_PHASE=$(_json_get "moon_phase" "")
    W_MOON_ILLUM=$(_json_get "moon_illumination" "0")
    W_AQI_US=$(_json_get "aqi_us" "0")
    W_AQI_GB=$(_json_get "aqi_gb" "0")

    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 04 — ICON & UNIT RESOLUTION HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Get condition icon for current code + day/night ───────────────────────────
_get_icon() {
    local code="${1:-1000}"
    local is_day="${2:-1}"

    # Night override first
    if [[ "$is_day" == "0" ]] && [[ -n "${ICON_NIGHT[$code]:-}" ]]; then
        echo "${ICON_NIGHT[$code]}"
        return 0
    fi

    # Day icon (also fallback for night codes without override)
    echo "${ICON_DAY[$code]:-󰖐}"
}

# ── Get condition description ─────────────────────────────────────────────────
_get_desc() {
    local code="${1:-1000}"
    local fallback="${2:-Unknown}"
    echo "${CONDITION_DESC[$code]:-$fallback}"
}

# ── Get condition color ────────────────────────────────────────────────────────
_get_color() {
    local code="${1:-1000}"
    echo "${CONDITION_COLOR[$code]:-$COLOR_PRIMARY}"
}

# ── Get temperature in preferred units ───────────────────────────────────────
_get_temp() {
    if [[ "$UNITS" == "imperial" ]]; then
        printf "%.0f°F" "$W_TEMP_F"
    else
        printf "%.0f°C" "$W_TEMP"
    fi
}

# ── Get feels-like in preferred units ────────────────────────────────────────
_get_feels() {
    if [[ "$UNITS" == "imperial" ]]; then
        printf "%.0f°F" "$W_FEELS_F"
    else
        printf "%.0f°C" "$W_FEELS"
    fi
}

# ── Get wind speed in preferred units ────────────────────────────────────────
_get_wind_speed() {
    if [[ "$UNITS" == "imperial" ]]; then
        printf "%.0f mph" "$W_WIND_MPH"
    else
        printf "%.0f km/h" "$W_WIND_KPH"
    fi
}

# ── Get visibility in preferred units ────────────────────────────────────────
_get_visibility() {
    if [[ "$UNITS" == "imperial" ]]; then
        printf "%.0f mi" "$W_VIS_MI"
    else
        printf "%.0f km" "$W_VIS_KM"
    fi
}

# ── Get wind direction arrow icon ────────────────────────────────────────────
_get_wind_dir_icon() {
    echo "${WIND_DIR_ICONS[$W_WIND_DIR]:-→}"
}

# ── Get moon phase icon ───────────────────────────────────────────────────────
_get_moon_icon() {
    echo "${MOON_ICONS[$W_MOON_PHASE]:-🌙}"
}

# ── UV index risk label + color ───────────────────────────────────────────────
# Returns: "label|color" pipe-separated pair
_get_uv_info() {
    local uv="${1:-0}"
    local uv_int
    uv_int=$(printf "%.0f" "$uv" 2>/dev/null || echo "0")

    if [[ $uv_int -le $UV_LOW ]]; then
        echo "Low|$COLOR_SUCCESS"
    elif [[ $uv_int -le $UV_MODERATE ]]; then
        echo "Moderate|$COLOR_SUN"
    elif [[ $uv_int -le $UV_HIGH ]]; then
        echo "High|$COLOR_WARN"
    elif [[ $uv_int -le $UV_VERY_HIGH ]]; then
        echo "Very High|$COLOR_ERROR"
    else
        echo "Extreme|$COLOR_ERROR"
    fi
}

# ── AQI US level label + color ────────────────────────────────────────────────
_get_aqi_info() {
    local aqi="${1:-0}"
    local aqi_int
    aqi_int=$(printf "%.0f" "$aqi" 2>/dev/null || echo "0")

    if [[ $aqi_int -le 50 ]]; then
        echo "Good|$COLOR_SUCCESS"
    elif [[ $aqi_int -le 100 ]]; then
        echo "Moderate|$COLOR_SUN"
    elif [[ $aqi_int -le 150 ]]; then
        echo "Unhealthy (Sensitive)|$COLOR_WARN"
    elif [[ $aqi_int -le 200 ]]; then
        echo "Unhealthy|$COLOR_ERROR"
    elif [[ $aqi_int -le 300 ]]; then
        echo "Very Unhealthy|$COLOR_ERROR"
    else
        echo "Hazardous|$COLOR_ERROR"
    fi
}

# ── Parse time string "07:24 AM" → minutes since midnight ────────────────────
_time_to_minutes() {
    local time_str="${1:-}"
    [[ -z "$time_str" ]] && echo "0" && return 0

    local hour min ampm
    if [[ "$time_str" =~ ([0-9]{1,2}):([0-9]{2})[[:space:]]*(AM|PM)? ]]; then
        hour="${BASH_REMATCH[1]}"
        min="${BASH_REMATCH[2]}"
        ampm="${BASH_REMATCH[3]:-}"

        # Convert 12h → 24h
        if [[ "$ampm" == "PM" && $hour -lt 12 ]]; then
            hour=$(( hour + 12 ))
        elif [[ "$ampm" == "AM" && $hour -eq 12 ]]; then
            hour=0
        fi
    else
        echo "0"
        return 0
    fi

    echo $(( hour * 60 + min ))
}

# ── Minutes since midnight → countdown string ─────────────────────────────────
# Input: target minutes from midnight
# Output: "in 2h 34m" or "2h 34m ago"
_minutes_to_countdown() {
    local target_mins="${1:-0}"
    local now_mins=$(( $(date +%H) * 60 + $(date +%M) ))
    local diff=$(( target_mins - now_mins ))

    local prefix suffix abs_diff
    if [[ $diff -ge 0 ]]; then
        prefix="in "
        abs_diff=$diff
        suffix=""
    else
        prefix=""
        abs_diff=$(( -diff ))
        suffix=" ago"
    fi

    local h=$(( abs_diff / 60 ))
    local m=$(( abs_diff % 60 ))

    if [[ $h -gt 0 && $m -gt 0 ]]; then
        echo "${prefix}${h}h ${m}m${suffix}"
    elif [[ $h -gt 0 ]]; then
        echo "${prefix}${h}h${suffix}"
    elif [[ $abs_diff -gt 0 ]]; then
        echo "${prefix}${m}m${suffix}"
    else
        echo "now"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 05 — OUTPUT FORMAT FUNCTIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── DEFAULT / --line1: Primary conditions line ───────────────────────────────
# Format: "󰖕  22°C  Feels 19°C  Partly cloudy"
output_line1() {
    local icon temp feels desc color

    icon=$(_get_icon "$W_CODE" "$W_IS_DAY")
    temp=$(_get_temp)
    feels=$(_get_feels)
    desc=$(_get_desc "$W_CODE" "$W_CONDITION")
    color=$(_get_color "$W_CODE")

    # Temperature color: hot (>32°C), cold (<0°C), normal
    local temp_color="$COLOR_PRIMARY"
    local temp_int
    temp_int=$(printf "%.0f" "${W_TEMP:-0}" 2>/dev/null || echo "0")
    [[ $temp_int -ge 32 ]] && temp_color="$COLOR_WARM"
    [[ $temp_int -le 0 ]]  && temp_color="$COLOR_COLD"

    echo "<span foreground=\"##${color}\">${icon}</span>  <span foreground=\"##${temp_color}\">${temp}</span>  Feels <span foreground=\"##${COLOR_MUTED}\">${feels}</span>  <span foreground=\"##${color}\">${desc}</span>"
}

# ── --line2: Secondary atmospheric data ──────────────────────────────────────
# Format: "💧 65%  💨 14 km/h SW  ☀ UV4  👁 10km"
output_line2() {
    local wind_speed wind_dir_icon vis uv_info uv_label uv_color

    wind_speed=$(_get_wind_speed)
    wind_dir_icon=$(_get_wind_dir_icon)
    vis=$(_get_visibility)

    local uv_pair
    uv_pair=$(_get_uv_info "$W_UV")
    uv_label=$(echo "$uv_pair" | cut -d'|' -f1)
    uv_color=$(echo "$uv_pair" | cut -d'|' -f2)

    local hum_color="$COLOR_PRIMARY"
    [[ ${W_HUMIDITY:-0} -ge 80 ]] && hum_color="$COLOR_RAIN"
    [[ ${W_HUMIDITY:-0} -le 30 ]] && hum_color="$COLOR_WARN"

    echo "💧 <span foreground=\"##${hum_color}\">${W_HUMIDITY}%</span>  💨 ${wind_speed} ${wind_dir_icon}  <span foreground=\"##${uv_color}\">☀ UV${W_UV} ${uv_label}</span>  👁 ${vis}"
}

# ── --compact: Single ticker-friendly line ────────────────────────────────────
# Format: "󰖕  22°C  Partly cloudy  💧 65%"
output_compact() {
    local icon temp desc hum
    icon=$(_get_icon "$W_CODE" "$W_IS_DAY")
    temp=$(_get_temp)
    desc=$(_get_desc "$W_CODE" "$W_CONDITION")
    hum="${W_HUMIDITY}%"
    echo "${icon}  ${temp}  ${desc}  💧 ${hum}"
}

# ── --minimal: Icon + temp only ───────────────────────────────────────────────
# Format: "󰖕 22°C"
output_minimal() {
    local icon temp
    icon=$(_get_icon "$W_CODE" "$W_IS_DAY")
    temp=$(_get_temp)
    echo "${icon} ${temp}"
}

# ── --location: City, Country string ─────────────────────────────────────────
# Format: "󰍎  London, UK"
output_location() {
    local loc=""
    if [[ -n "$W_CITY" && -n "$W_COUNTRY" ]]; then
        loc="${W_CITY}, ${W_COUNTRY}"
    elif [[ -n "$W_CITY" ]]; then
        loc="$W_CITY"
    elif [[ -n "$W_REGION" ]]; then
        loc="$W_REGION"
    else
        loc="$FALLBACK_LOCATION"
    fi
    echo "󰍎  ${loc}"
}

# ── --icon: Condition icon glyph only ────────────────────────────────────────
output_icon_only() {
    local icon color
    icon=$(_get_icon "$W_CODE" "$W_IS_DAY")
    color=$(_get_color "$W_CODE")
    echo "<span foreground=\"##${color}\">${icon}</span>"
}

# ── --temp: Temperature only ──────────────────────────────────────────────────
output_temp() {
    local temp temp_color
    temp=$(_get_temp)
    local temp_int
    temp_int=$(printf "%.0f" "${W_TEMP:-0}" 2>/dev/null || echo "0")
    temp_color="$COLOR_PRIMARY"
    [[ $temp_int -ge 32 ]] && temp_color="$COLOR_WARM"
    [[ $temp_int -le 0 ]]  && temp_color="$COLOR_COLD"
    echo "<span foreground=\"##${temp_color}\">${temp}</span>"
}

# ── --feels: Feels-like temperature ──────────────────────────────────────────
output_feels() {
    local feels
    feels=$(_get_feels)
    echo "Feels ${feels}"
}

# ── --humidity: Humidity with label ──────────────────────────────────────────
# Format: "💧  65%  Comfortable"
output_humidity() {
    local hum="${W_HUMIDITY}%"
    local label color
    local hum_int="${W_HUMIDITY:-0}"

    if [[ $hum_int -ge 80 ]]; then
        label="Very Humid";   color="$COLOR_RAIN"
    elif [[ $hum_int -ge 60 ]]; then
        label="Humid";        color="$COLOR_RAIN"
    elif [[ $hum_int -ge 40 ]]; then
        label="Comfortable";  color="$COLOR_SUCCESS"
    elif [[ $hum_int -ge 20 ]]; then
        label="Dry";          color="$COLOR_WARN"
    else
        label="Very Dry";     color="$COLOR_ERROR"
    fi

    echo "💧  <span foreground=\"##${color}\">${hum}  ${label}</span>"
}

# ── --wind: Wind speed + direction + gusts ────────────────────────────────────
# Format: "💨  14 km/h SW ↙  Gusts 22 km/h"
output_wind() {
    local speed dir_icon gust_speed
    speed=$(_get_wind_speed)
    dir_icon=$(_get_wind_dir_icon)

    if [[ "$UNITS" == "imperial" ]]; then
        local gust_mph
        gust_mph=$(printf "%.0f" "${W_GUST_KPH:-0}" 2>/dev/null || echo "0")
        # Approximate: kph → mph
        gust_mph=$(( gust_mph * 621 / 1000 ))
        gust_speed="${gust_mph} mph"
    else
        gust_speed="$(printf "%.0f" "${W_GUST_KPH:-0}" 2>/dev/null || echo "0") km/h"
    fi

    echo "💨  ${speed} ${W_WIND_DIR} ${dir_icon}  Gusts ${gust_speed}"
}

# ── --uv: UV index + risk level ──────────────────────────────────────────────
# Format: "☀  UV 4  Moderate  (SPF 15+ recommended)"
output_uv() {
    local uv_pair uv_label uv_color advice
    uv_pair=$(_get_uv_info "$W_UV")
    uv_label=$(echo "$uv_pair" | cut -d'|' -f1)
    uv_color=$(echo "$uv_pair" | cut -d'|' -f2)

    local uv_int
    uv_int=$(printf "%.0f" "${W_UV:-0}" 2>/dev/null || echo "0")

    if [[ $uv_int -le 2 ]]; then
        advice="No protection needed"
    elif [[ $uv_int -le 5 ]]; then
        advice="SPF 15+ recommended"
    elif [[ $uv_int -le 7 ]]; then
        advice="SPF 30+, seek shade"
    elif [[ $uv_int -le 10 ]]; then
        advice="SPF 50+, minimize exposure"
    else
        advice="Stay indoors if possible"
    fi

    echo "<span foreground=\"##${uv_color}\">☀  UV ${W_UV}  ${uv_label}</span>  <span foreground=\"##${COLOR_MUTED}\">${advice}</span>"
}

# ── --pressure: Barometric pressure ──────────────────────────────────────────
# Format: "󰔅  1013 hPa  Normal"
output_pressure() {
    local pressure="${W_PRESSURE:-1013}"
    local label color

    local p_int
    p_int=$(printf "%.0f" "$pressure" 2>/dev/null || echo "1013")

    if [[ $p_int -ge 1020 ]]; then
        label="High (fair weather)"; color="$COLOR_SUN"
    elif [[ $p_int -ge 1013 ]]; then
        label="Normal";              color="$COLOR_PRIMARY"
    elif [[ $p_int -ge 1000 ]]; then
        label="Low (unsettled)";     color="$COLOR_WARN"
    else
        label="Very Low (storms)";   color="$COLOR_STORM"
    fi

    echo "<span foreground=\"##${color}\">󰔅  ${pressure} hPa  ${label}</span>"
}

# ── --aqi: Air Quality Index ──────────────────────────────────────────────────
# Format: "󰄙  AQI 42  Good"
output_aqi() {
    local aqi="${W_AQI_US:-0}"
    [[ "$aqi" == "0" ]] && echo "󰄙  AQI unavailable" && return 0

    local aqi_pair aqi_label aqi_color
    aqi_pair=$(_get_aqi_info "$aqi")
    aqi_label=$(echo "$aqi_pair" | cut -d'|' -f1)
    aqi_color=$(echo "$aqi_pair" | cut -d'|' -f2)

    echo "<span foreground=\"##${aqi_color}\">󰄙  AQI ${aqi}  ${aqi_label}</span>"
}

# ── --moon: Lunar phase + illumination ───────────────────────────────────────
# Format: "🌔  Waxing Gibbous  72% illuminated"
output_moon() {
    local phase="${W_MOON_PHASE:-}"
    local illum="${W_MOON_ILLUM:-0}"
    local icon

    icon=$(_get_moon_icon)

    if [[ -z "$phase" ]]; then
        echo "🌙  Lunar data unavailable"
        return 0
    fi

    echo "${icon}  ${phase}  ${illum}% illuminated"
}

# ── --sunrise: Sunrise time + countdown ──────────────────────────────────────
# Format: "󰖙  Sunrise  07:24  (in 8h 52m)"
output_sunrise() {
    local sr="${W_SUNRISE:-}"
    [[ -z "$sr" ]] && echo "󰖙  Sunrise data unavailable" && return 0

    # Format: strip AM/PM for clean display if 24h preference
    local sr_display="$sr"
    local sr_mins
    sr_mins=$(_time_to_minutes "$sr")
    local countdown
    countdown=$(_minutes_to_countdown "$sr_mins")

    echo "󰖙  Sunrise  ${sr_display}  (${countdown})"
}

# ── --sunset: Sunset time + countdown ────────────────────────────────────────
# Format: "󰖜  Sunset  04:48 PM  (in 2h 18m)"
output_sunset() {
    local ss="${W_SUNSET:-}"
    [[ -z "$ss" ]] && echo "󰖜  Sunset data unavailable" && return 0

    local ss_mins
    ss_mins=$(_time_to_minutes "$ss")
    local countdown
    countdown=$(_minutes_to_countdown "$ss_mins")

    echo "󰖜  Sunset  ${ss}  (${countdown})"
}

# ── --solar: Complete solar information block ─────────────────────────────────
# Three-line: sunrise / current solar position / sunset
output_solar() {
    local sr="${W_SUNRISE:-?}"
    local ss="${W_SUNSET:-?}"
    local now_mins=$(( $(date +%H) * 60 + $(date +%M) ))
    local sr_mins ss_mins
    sr_mins=$(_time_to_minutes "$sr")
    ss_mins=$(_time_to_minutes "$ss")

    # Solar position context
    local solar_context
    if [[ $now_mins -lt $sr_mins ]]; then
        solar_context="Before sunrise"
    elif [[ $now_mins -gt $ss_mins ]]; then
        solar_context="After sunset  🌙"
    else
        # Percentage through daylight hours
        local day_length=$(( ss_mins - sr_mins ))
        local elapsed=$(( now_mins - sr_mins ))
        local day_pct=$(( elapsed * 100 / day_length ))
        solar_context="Daylight: ${day_pct}% elapsed"
    fi

    printf "󰖙  %s\n%s\n󰖜  %s" "$sr" "$solar_context" "$ss"
}

# ── --full: Complete multi-line weather block ─────────────────────────────────
output_full() {
    local icon temp feels desc wind_speed dir_icon vis
    icon=$(_get_icon "$W_CODE" "$W_IS_DAY")
    temp=$(_get_temp)
    feels=$(_get_feels)
    desc=$(_get_desc "$W_CODE" "$W_CONDITION")
    wind_speed=$(_get_wind_speed)
    dir_icon=$(_get_wind_dir_icon)
    vis=$(_get_visibility)

    printf "%s  %s  Feels %s  %s\n💧 %s%%  💨 %s %s  ☀ UV%s  👁 %s\n%s\n%s" \
        "$icon" "$temp" "$feels" "$desc" \
        "$W_HUMIDITY" "$wind_speed" "$dir_icon" "$W_UV" "$vis" \
        "$(output_location)" \
        "$(output_sunrise)"
}

# ── --icon-temp: Large icon + temp (hero widget variant) ─────────────────────
output_icon_temp() {
    local icon temp color
    icon=$(_get_icon "$W_CODE" "$W_IS_DAY")
    temp=$(_get_temp)
    color=$(_get_color "$W_CODE")
    echo "<span foreground=\"##${color}\" font_size=\"36pt\">${icon}</span>  <span font_size=\"28pt\">${temp}</span>"
}

# ── --now: Current conditions brief (dashboard header) ───────────────────────
output_now() {
    local icon temp desc
    icon=$(_get_icon "$W_CODE" "$W_IS_DAY")
    temp=$(_get_temp)
    desc=$(_get_desc "$W_CODE" "$W_CONDITION")
    local color
    color=$(_get_color "$W_CODE")
    echo "<span foreground=\"##${color}\">${icon}  ${temp}  ${desc}</span>"
}

# ── --forecast: 3-day forecast strip ─────────────────────────────────────────
# Format: "Today 22/14°C  Tomorrow 󰖖 18/10°C  Thu 󰖙 22/11°C"
output_forecast() {
    if [[ ! -f "$CACHE_FILE" ]]; then
        echo "$FALLBACK_NO_CACHE"
        return 0
    fi

    # Extract forecast array using python3 for reliable JSON array parsing
    if ! command -v python3 &>/dev/null; then
        echo "─  Forecast requires python3"
        return 0
    fi

    python3 -c "
import json, sys
from datetime import datetime, timedelta

try:
    with open('${CACHE_FILE}') as f:
        d = json.load(f)

    forecast = d.get('forecast', [])
    if not forecast:
        print('─  No forecast data')
        sys.exit(0)

    units = '${UNITS}'
    icons = {
        1000:'󰖙', 1003:'󰖕', 1006:'󰖐', 1009:'󰖐',
        1063:'󰖗', 1066:'󰖘', 1087:'󰖓', 1135:'󰖑',
        1180:'󰖖', 1183:'󰖖', 1189:'󰖖', 1195:'󰖖',
        1210:'󰖘', 1213:'󰖘', 1219:'󰖘', 1225:'󰖒',
        1240:'󰖗', 1243:'󰖖', 1273:'󰖓', 1276:'󰖓',
    }
    today = datetime.now().date()
    parts = []
    day_names = ['Today', 'Tomorrow']

    for i, day in enumerate(forecast[:3]):
        code = int(day.get('code', 1000))
        icon = icons.get(code, '󰖐')
        if units == 'imperial':
            hi = round(day.get('max_f', day.get('max_c', 0) * 9/5 + 32))
            lo = round(day.get('min_f', day.get('min_c', 0) * 9/5 + 32))
            unit = '°F'
        else:
            hi = round(day.get('max_c', 0))
            lo = round(day.get('min_c', 0))
            unit = '°C'
        try:
            d_date = datetime.strptime(day['date'], '%Y-%m-%d').date()
            delta = (d_date - today).days
            if delta == 0: name = 'Today'
            elif delta == 1: name = 'Tomorrow'
            else: name = d_date.strftime('%a')
        except:
            name = day_names[i] if i < len(day_names) else f'Day {i+1}'

        parts.append(f'{name} {icon} {hi}/{lo}{unit}')

    print('  ·  '.join(parts))
except Exception as e:
    print('─  Forecast error')
" 2>/dev/null || echo "─  Forecast unavailable"
}

# ── --panel-header: Dashboard panel title line ────────────────────────────────
output_panel_header() {
    local icon desc temp city
    icon=$(_get_icon "$W_CODE" "$W_IS_DAY")
    desc=$(_get_desc "$W_CODE" "$W_CONDITION")
    temp=$(_get_temp)
    city="${W_CITY:-Unknown}"
    local color
    color=$(_get_color "$W_CODE")
    echo "<span foreground=\"##${color}\">${icon}  ${desc}  ${temp}  —  ${city}</span>"
}

# ── --panel-body: Dashboard panel body (multi-line detail) ───────────────────
output_panel_body() {
    local feels wind_speed dir_icon vis uv_pair uv_label uv_color
    feels=$(_get_feels)
    wind_speed=$(_get_wind_speed)
    dir_icon=$(_get_wind_dir_icon)
    vis=$(_get_visibility)
    uv_pair=$(_get_uv_info "$W_UV")
    uv_label=$(echo "$uv_pair" | cut -d'|' -f1)
    uv_color=$(echo "$uv_pair" | cut -d'|' -f2)

    printf "Feels %s  •  💧 %s%%  •  Cloud %s%%\n💨 %s %s %s  •  👁 %s\n<span foreground=\"##%s\">☀ UV%s %s</span>  •  %s hPa\n󰖙 %s  •  󰖜 %s" \
        "$feels" "$W_HUMIDITY" "${W_CLOUD}%" \
        "$wind_speed" "$W_WIND_DIR" "$dir_icon" "$vis" \
        "$uv_color" "$W_UV" "$uv_label" "$W_PRESSURE" \
        "${W_SUNRISE:-?}" "${W_SUNSET:-?}"
}

# ── --stale-check: Output warning if data is old ─────────────────────────────
output_stale_check() {
    local age
    age=$(_cache_age_seconds)

    if [[ $age -ge $CRITICAL_STALE_SECONDS ]]; then
        echo "<span foreground=\"##${COLOR_ERROR}\">󰖑  Weather data ${age}s old — may be unreliable</span>"
    elif [[ $age -ge $STALE_THRESHOLD_SECONDS ]]; then
        echo "<span foreground=\"##${COLOR_WARN}\">󰔚  Weather updated $(( age / 60 ))m ago</span>"
    else
        echo ""
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 06 — MAIN DISPATCH
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    local mode="${1:-}"

    # ── Declare all globals ───────────────────────────────────────────────────
    W_TEMP=0; W_TEMP_F=32; W_FEELS=0; W_FEELS_F=32
    W_HUMIDITY=0; W_WIND_KPH=0; W_WIND_MPH=0
    W_WIND_DIR="N"; W_WIND_DEG=0; W_GUST_KPH=0
    W_CONDITION="Unknown"; W_CODE=1000
    W_IS_DAY=1; W_UV=0; W_VIS_KM=0; W_VIS_MI=0
    W_PRESSURE=1013; W_PRECIP_MM=0; W_PRECIP_IN=0; W_CLOUD=0
    W_CITY=""; W_COUNTRY=""; W_REGION=""
    W_SUNRISE=""; W_SUNSET=""
    W_MOONRISE=""; W_MOONSET=""
    W_MOON_PHASE=""; W_MOON_ILLUM=0
    W_AQI_US=0; W_AQI_GB=0

    # ── Load cache ────────────────────────────────────────────────────────────
    if ! _load_weather_data; then
        echo "$FALLBACK_NO_CACHE"
        exit 0
    fi

    # ── Route to output function ──────────────────────────────────────────────
    case "$mode" in
        ""|--line1)       output_line1        ;;
        --line2)          output_line2        ;;
        --compact)        output_compact      ;;
        --minimal)        output_minimal      ;;
        --location)       output_location     ;;
        --icon)           output_icon_only    ;;
        --temp)           output_temp         ;;
        --feels)          output_feels        ;;
        --humidity)       output_humidity     ;;
        --wind)           output_wind         ;;
        --uv)             output_uv           ;;
        --pressure)       output_pressure     ;;
        --aqi)            output_aqi          ;;
        --moon)           output_moon         ;;
        --sunrise)        output_sunrise      ;;
        --sunset)         output_sunset       ;;
        --solar)          output_solar        ;;
        --full)           output_full         ;;
        --icon-temp)      output_icon_temp    ;;
        --now)            output_now          ;;
        --forecast)       output_forecast     ;;
        --panel-header)   output_panel_header ;;
        --panel-body)     output_panel_body   ;;
        --stale-check)    output_stale_check  ;;
        --version)        echo "${SCRIPT_NAME} v${SCRIPT_VERSION}" ;;
        --help|-h)
            echo "Usage: weather-lock.sh [--line1|--line2|--compact|--minimal|--location|--icon|--temp|--feels|--humidity|--wind|--uv|--pressure|--aqi|--moon|--sunrise|--sunset|--solar|--full|--icon-temp|--now|--forecast|--panel-header|--panel-body|--stale-check]"
            ;;
        *)
            echo "weather-lock: unknown flag: $mode" >&2
            output_line1
            ;;
    esac
}

main "$@"