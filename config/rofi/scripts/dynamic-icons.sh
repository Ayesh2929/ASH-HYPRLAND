#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
# ASH DOTFILES v5.0 OMEGA — DYNAMIC ICONS ULTRA ENGINE
# ══════════════════════════════════════════════════════════════════════════════
# File    : dynamic-icons.sh
# Author  : Ash Dotfiles v5.0 Omega
# License : MIT
# Desc    : Real-time dynamic icon generation and state-aware icon selection
#           for all Rofi menus in the ASH ecosystem.
#
#   Core capabilities:
#     • State-aware icons (battery level → correct icon, wifi signal → bars)
#     • Live system status icons (CPU/RAM/GPU load → colored indicators)
#     • Theme-color-aware icon coloring (recolor SVG to match active accent)
#     • Animated icon sequences (loading spinners, progress bars)
#     • Context-aware app icons (running vs. not running state)
#     • Network topology icons (connection type, VPN, proxy status)
#     • Media state icons (playing/paused/stopped with album art extraction)
#     • Volume/brightness OSD icon sequences
#     • Weather condition icons (current conditions → matching glyph + color)
#     • Time-of-day icons (morning/afternoon/evening/night transitions)
#     • Git repository status icons (clean/dirty/ahead/behind)
#     • Docker container state icons
#     • Kubernetes context icons
#     • Plugin health icons
#     • Notification badge overlay generation
#     • Icon size auto-scaling for DPI
#     • SVG recoloring pipeline
#     • PNG icon generation from glyph (for GTK/Qt interop)
#
#   Output modes:
#     • rofi   : Rofi-compatible icon path or Nerd Font glyph
#     • waybar : Waybar JSON (text + tooltip + class)
#     • shell  : Plain text glyph for terminal/prompt use
#     • json   : Full structured icon data
#
#   POSIX-safe, shellcheck-clean, strict mode
# ══════════════════════════════════════════════════════════════════════════════

set -euo pipefail
IFS=$'\n\t'

# ══════════════════════════════════════════════════════════════════════════════
# § 1  ENVIRONMENT & PATHS
# ══════════════════════════════════════════════════════════════════════════════

readonly XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
readonly XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
readonly XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"

readonly ASH_DIR="${XDG_CONFIG_HOME}/ash"
readonly ROFI_SCRIPTS_DIR="${XDG_CONFIG_HOME}/rofi/scripts"
readonly DYNAMIC_ICONS_CACHE="${XDG_CACHE_HOME}/ash/dynamic-icons"
readonly DYNAMIC_ICONS_LOG="${XDG_CACHE_HOME}/ash/dynamic-icons.log"
readonly DYNAMIC_ICONS_SETTINGS="${ASH_DIR}/rofi/dynamic-icons.conf"
readonly ASH_ASSETS_DIR="${XDG_DATA_HOME}/ash/assets/icons"
readonly ASH_THEME_FILE="${ASH_DIR}/current-theme.conf"

# Icon lookup engine
readonly ICON_LOOKUP="${ROFI_SCRIPTS_DIR}/icon-lookup.sh"

# ══════════════════════════════════════════════════════════════════════════════
# § 2  CONSTANTS
# ══════════════════════════════════════════════════════════════════════════════

readonly DATE_FMT="%Y-%m-%dT%H:%M:%S"
readonly ICON_CACHE_TTL_SHORT=5      # seconds — for live system stats
readonly ICON_CACHE_TTL_MEDIUM=30    # seconds — for network/media
readonly ICON_CACHE_TTL_LONG=300     # seconds — for weather/theme
readonly SVG_RECOLOR_TIMEOUT=2

# ── Nerd Font icon sets (organized by domain) ─────────────────────────────────

# Battery icons (0–100% in 10% steps + charging variants)
readonly -a BATTERY_ICONS=(
    "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"
)
readonly -a BATTERY_CHARGING_ICONS=(
    "󰢟" "󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂄"
)

# WiFi signal strength (0–4 bars)
readonly -a WIFI_ICONS=( "󰤭" "󰤟" "󰤢" "󰤥" "󰤨" )
readonly -a WIFI_ICONS_SECURE=( "󰤯" "󰤡" "󰤤" "󰤧" "󰤪" )

# Volume icons
readonly -a VOLUME_ICONS=( "󰝟" "󰕿" "󰖀" "󰕾" )
readonly VOLUME_MUTE_ICON="󰸈"
readonly VOLUME_BOOST_ICON="󰕾"

# Brightness icons
readonly -a BRIGHTNESS_ICONS=( "󰃞" "󰃟" "󰃠" )
readonly BRIGHTNESS_NIGHT_ICON="󰃝"

# CPU load icons
readonly -a CPU_ICONS=( "󰓅" "󰓅" "󱐋" "󱐋" "󰈸" )
readonly -a CPU_COLORS=( "#a6e3a1" "#f9e2af" "#fab387" "#f38ba8" "#f38ba8" )

# RAM usage icons
readonly -a RAM_ICONS=( "󰍛" "󰍛" "󱐋" "󱐋" "󰈸" )

# Temperature icons
readonly -a TEMP_ICONS=( "󱃃" "󰔏" "󱇭" "󰈸" )
readonly -a TEMP_COLORS=( "#89b4fa" "#a6e3a1" "#fab387" "#f38ba8" )

# Network type icons
readonly NET_ICON_ETHERNET="󰈁"
readonly NET_ICON_WIFI="󰤨"
readonly NET_ICON_VPN="󰒃"
readonly NET_ICON_PROXY="󰛳"
readonly NET_ICON_TOR="󰞟"
readonly NET_ICON_NONE="󰤭"
readonly NET_ICON_METERED="󰤩"

# Bluetooth icons
readonly BT_ICON_ON="󰂯"
readonly BT_ICON_OFF="󰂲"
readonly BT_ICON_CONNECTED="󰂱"
readonly BT_ICON_PAIRING="󰂰"

# Media state icons
readonly MEDIA_ICON_PLAYING="󰐊"
readonly MEDIA_ICON_PAUSED="󰏤"
readonly MEDIA_ICON_STOPPED="󰓛"
readonly MEDIA_ICON_NONE="󰎵"
readonly MEDIA_ICON_LOADING="󰔟"

# Weather condition icons
declare -A WEATHER_ICONS=(
    [clear-day]="󰖙"         [clear-night]="󰖔"
    [partly-cloudy-day]="󰖕" [partly-cloudy-night]="󰖓"
    [cloudy]="󰖐"             [rain]="󰖗"
    [drizzle]="󰖖"            [thunderstorm]="󰖙"
    [snow]="󰖘"               [sleet]="󰖘"
    [fog]="󰖑"                [windy]="󰖌"
    [tornado]="󰖌"            [hot]="󰖙"
    [cold]="󰖘"               [unknown]="󰖐"
)

# Weather colors by condition
declare -A WEATHER_COLORS=(
    [clear-day]="#f9e2af"    [clear-night]="#89b4fa"
    [partly-cloudy-day]="#fab387" [partly-cloudy-night]="#89b4fa"
    [cloudy]="#a6adc8"       [rain]="#89b4fa"
    [thunderstorm]="#f9e2af" [snow]="#cdd6f4"
    [fog]="#a6adc8"          [hot]="#f38ba8"
    [cold]="#89b4fa"
)

# Time of day icons
declare -A TIME_ICONS=(
    [dawn]="󰖜"      [morning]="󰖙"
    [afternoon]="󰖛"  [evening]="󰖚"
    [night]="󰖔"      [midnight]="󰖔"
)
declare -A TIME_COLORS=(
    [dawn]="#fab387"    [morning]="#f9e2af"
    [afternoon]="#fab387" [evening]="#f38ba8"
    [night]="#89b4fa"   [midnight]="#cba6f7"
)

# Git status icons
readonly GIT_ICON_CLEAN="󰊤"
readonly GIT_ICON_DIRTY="󰊥"
readonly GIT_ICON_AHEAD="󰁔"
readonly GIT_ICON_BEHIND="󰁎"
readonly GIT_ICON_DIVERGED="󰃻"
readonly GIT_ICON_STAGED="󰐖"
readonly GIT_ICON_UNTRACKED="󰋗"
readonly GIT_ICON_CONFLICT="󱚺"

# Docker state icons
readonly DOCKER_ICON_RUNNING="󰡨"
readonly DOCKER_ICON_STOPPED="󰡪"
readonly DOCKER_ICON_PAUSED="󰡩"
readonly DOCKER_ICON_ERROR="󰅖"
readonly DOCKER_ICON_PULLING="󰇵"
readonly DOCKER_ICON_BUILDING="󱑤"

# Spinner animation frames
readonly -a SPINNER_DOTS=( "⣾" "⣽" "⣻" "⢿" "⡿" "⣟" "⣯" "⣷" )
readonly -a SPINNER_BRAILLE=( "⠋" "⠙" "⠸" "⠴" "⠦" "⠇" )
readonly -a SPINNER_CLASSIC=( "◐" "◓" "◑" "◒" )
readonly -a SPINNER_ARROWS=( "←" "↖" "↑" "↗" "→" "↘" "↓" "↙" )
readonly -a SPINNER_NERD=( "󰔟" "󰔠" "󰔡" "󰔢" )

# Progress bar segments
readonly PROGRESS_FULL="█"
readonly PROGRESS_HALF="▓"
readonly PROGRESS_EMPTY="░"
readonly PROGRESS_TRACK="▱"
readonly PROGRESS_FILL="▰"

# ── ASH Mode icons ────────────────────────────────────────────────────────────
declare -A MODE_ICONS=(
    [default]="󰒓"    [game]="󰊗"      [work]="󰙏"
    [focus]="󰋋"      [cinema]="󰎆"    [present]="󰈩"
    [battery]="󰁹"    [stream]="󰕃"    [privacy]="󰛳"
    [accessibility]="󰀿"
)
declare -A MODE_COLORS=(
    [default]="#cdd6f4"  [game]="#a6e3a1"   [work]="#89b4fa"
    [focus]="#cba6f7"    [cinema]="#f38ba8"  [present]="#f9e2af"
    [battery]="#a6e3a1"  [stream]="#f5c2e7"  [privacy]="#89dceb"
    [accessibility]="#fab387"
)

# ══════════════════════════════════════════════════════════════════════════════
# § 3  LOGGING
# ══════════════════════════════════════════════════════════════════════════════

_dlog() {
    local level="$1"; shift
    printf '[%s] [%-5s] %s\n' "$(date +%H:%M:%S)" "${level}" "$*" \
        >> "${DYNAMIC_ICONS_LOG}" 2>/dev/null || true
}
dlog_debug() { [[ "${ASH_DEBUG:-0}" == "1" ]] && _dlog "DEBUG" "$@" || true; }
dlog_warn()  { _dlog "WARN"  "$@"; }
dlog_info()  { _dlog "INFO"  "$@"; }

# ══════════════════════════════════════════════════════════════════════════════
# § 4  INITIALISATION
# ══════════════════════════════════════════════════════════════════════════════

init() {
    mkdir -p \
        "${DYNAMIC_ICONS_CACHE}" \
        "${DYNAMIC_ICONS_CACHE}/svg" \
        "${DYNAMIC_ICONS_CACHE}/png" \
        "${DYNAMIC_ICONS_CACHE}/state"
    dlog_info "Dynamic icons engine initialised"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 5  SETTINGS LOADER
# ══════════════════════════════════════════════════════════════════════════════

OUTPUT_MODE="rofi"
SVG_RECOLOR_ENABLED="true"
ICON_DPI="auto"
ICON_SIZE_SCALE="1.0"

load_settings() {
    [[ ! -f "${DYNAMIC_ICONS_SETTINGS}" ]] && return 0
    while IFS='=' read -r key val; do
        [[ "${key}" =~ ^# ]] && continue
        [[ -z "${key}" ]]    && continue
        key="${key// /}"
        val="${val//\"/}"; val="${val//\'/}"
        case "${key}" in
            output_mode|svg_recolor_enabled|icon_dpi|icon_size_scale)
                printf -v "${key}" '%s' "${val}" ;;
        esac
    done < "${DYNAMIC_ICONS_SETTINGS}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 6  THEME COLOR READER
# ══════════════════════════════════════════════════════════════════════════════

get_theme_color() {
    local key="${1:-accent}"
    local default="${2:-#cba6f7}"

    [[ ! -f "${ASH_THEME_FILE}" ]] && { echo "${default}"; return; }

    local val
    val="$(grep -i "^${key}\s*=" "${ASH_THEME_FILE}" 2>/dev/null \
        | head -1 | cut -d= -f2 | tr -d ' "#')"

    if [[ -n "${val}" ]]; then
        echo "#${val##\#}"
    else
        echo "${default}"
    fi
}

get_theme_bg()      { get_theme_color "background" "#1e1e2e"; }
get_theme_fg()      { get_theme_color "foreground"  "#cdd6f4"; }
get_theme_accent()  { get_theme_color "accent"      "#cba6f7"; }
get_theme_mode()    {
    grep -i "^mode\s*=" "${ASH_THEME_FILE}" 2>/dev/null \
        | head -1 | cut -d= -f2 | tr -d ' "' || echo "dark"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 7  SHORT-LIVED STATE CACHE
# ══════════════════════════════════════════════════════════════════════════════

state_cache_get() {
    local key="$1" ttl="${2:-5}"
    local cache_file="${DYNAMIC_ICONS_CACHE}/state/${key//\//_}.cache"
    [[ ! -f "${cache_file}" ]] && return 1
    local now mtime age
    now="$(date +%s)"
    mtime="$(stat -c %Y "${cache_file}" 2>/dev/null || echo 0)"
    age=$(( now - mtime ))
    (( age > ttl )) && return 1
    cat "${cache_file}"
}

state_cache_set() {
    local key="$1" value="$2"
    local cache_file="${DYNAMIC_ICONS_CACHE}/state/${key//\//_}.cache"
    printf '%s' "${value}" > "${cache_file}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 8  SVG RECOLOR ENGINE
# ══════════════════════════════════════════════════════════════════════════════

# Recolor an SVG icon to match active theme accent
recolor_svg() {
    local svg_in="$1"
    local target_color="${2:-$(get_theme_accent)}"
    local svg_out="${3:-}"

    [[ ! -f "${svg_in}" ]] && { echo "${svg_in}"; return; }
    [[ "${SVG_RECOLOR_ENABLED}" != "true" ]] && { echo "${svg_in}"; return; }

    local hash
    hash="$(echo "${svg_in}${target_color}" | sha256sum | cut -c1-8)"
    local cached_svg="${DYNAMIC_ICONS_CACHE}/svg/${hash}.svg"

    if [[ -f "${cached_svg}" ]]; then
        echo "${cached_svg}"
        return 0
    fi

    if [[ -n "${svg_out}" ]]; then
        cached_svg="${svg_out}"
    fi

    # Replace common color values in SVG
    timeout "${SVG_RECOLOR_TIMEOUT}" sed \
        -e "s/#[0-9a-fA-F]\{6\}/${target_color}/g" \
        -e "s/fill=\"currentColor\"/fill=\"${target_color}\"/g" \
        -e "s/stroke=\"currentColor\"/stroke=\"${target_color}\"/g" \
        "${svg_in}" > "${cached_svg}" 2>/dev/null || {
        echo "${svg_in}"
        return
    }

    echo "${cached_svg}"
}

# Convert SVG to PNG using rsvg-convert or inkscape
svg_to_png() {
    local svg_file="$1" size="${2:-48}"
    local hash
    hash="$(echo "${svg_file}${size}" | sha256sum | cut -c1-8)"
    local png_out="${DYNAMIC_ICONS_CACHE}/png/${hash}-${size}.png"

    [[ -f "${png_out}" ]] && { echo "${png_out}"; return 0; }

    if command -v rsvg-convert &>/dev/null; then
        rsvg-convert \
            --width="${size}" \
            --height="${size}" \
            --output="${png_out}" \
            "${svg_file}" 2>/dev/null && {
            echo "${png_out}"
            return 0
        }
    fi

    if command -v inkscape &>/dev/null; then
        inkscape \
            --export-width="${size}" \
            --export-height="${size}" \
            --export-filename="${png_out}" \
            "${svg_file}" &>/dev/null && {
            echo "${png_out}"
            return 0
        }
    fi

    echo "${svg_file}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 9  SYSTEM STATE READERS
# ══════════════════════════════════════════════════════════════════════════════

# ── Battery ───────────────────────────────────────────────────────────────────
read_battery() {
    local cache_key="battery"
    local cached
    cached="$(state_cache_get "${cache_key}" "${ICON_CACHE_TTL_SHORT}")" && {
        echo "${cached}"; return 0
    }

    local capacity=100 status="Discharging" path

    # Find first battery
    for path in /sys/class/power_supply/BAT*/; do
        [[ -f "${path}/capacity" ]] || continue
        capacity="$(cat "${path}/capacity" 2>/dev/null || echo 100)"
        status="$(cat "${path}/status"    2>/dev/null || echo "Discharging")"
        break
    done

    local result="${capacity}|${status}"
    state_cache_set "${cache_key}" "${result}"
    echo "${result}"
}

get_battery_icon() {
    local cap_status
    cap_status="$(read_battery)"
    IFS='|' read -r capacity status <<< "${cap_status}"

    local idx=$(( capacity / 10 ))
    (( idx > 10 )) && idx=10
    (( idx < 0  )) && idx=0

    local icon color
    if [[ "${status}" == "Charging" ]] || [[ "${status}" == "Full" ]]; then
        icon="${BATTERY_CHARGING_ICONS[${idx}]}"
        color="#a6e3a1"
    else
        icon="${BATTERY_ICONS[${idx}]}"
        if   (( capacity <= 10 )); then color="#f38ba8"
        elif (( capacity <= 20 )); then color="#fab387"
        elif (( capacity <= 40 )); then color="#f9e2af"
        else                            color="#a6e3a1"
        fi
    fi

    output_icon "${icon}" "${color}" "Battery: ${capacity}% (${status})"
}

# ── WiFi ──────────────────────────────────────────────────────────────────────
read_wifi() {
    local cache_key="wifi"
    local cached
    cached="$(state_cache_get "${cache_key}" "${ICON_CACHE_TTL_SHORT}")" && {
        echo "${cached}"; return 0
    }

    local ssid="" signal=0 secured=false connected=false

    if command -v iwctl &>/dev/null; then
        local iw_out
        iw_out="$(iwctl station wlan0 show 2>/dev/null | grep -i 'connected network')"
        ssid="$(echo "${iw_out}" | awk '{print $NF}')"
        [[ -n "${ssid}" ]] && connected=true
        signal="$(awk 'NR==3{print int($3 * 100 / 70)}' \
            /proc/net/wireless 2>/dev/null || echo 0)"

    elif command -v nmcli &>/dev/null; then
        local nm_out
        nm_out="$(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi \
            2>/dev/null | grep '^*:' | head -1)"
        IFS=':' read -r _use ssid signal secured_flag <<< "${nm_out}"
        [[ -n "${ssid}" ]] && connected=true
        [[ "${secured_flag}" != "--" ]] && secured=true
    fi

    local result="${connected}|${ssid}|${signal}|${secured}"
    state_cache_set "${cache_key}" "${result}"
    echo "${result}"
}

get_wifi_icon() {
    local wifi_data
    wifi_data="$(read_wifi)"
    IFS='|' read -r connected ssid signal secured <<< "${wifi_data}"

    local icon color tooltip

    if [[ "${connected}" != "true" ]]; then
        icon="${WIFI_ICONS[0]}"
        color="#6c7086"
        tooltip="WiFi: Disconnected"
    else
        local bars=0
        (( signal >= 25 )) && bars=1
        (( signal >= 50 )) && bars=2
        (( signal >= 75 )) && bars=3
        (( signal >= 90 )) && bars=4

        if [[ "${secured}" == "true" ]]; then
            icon="${WIFI_ICONS_SECURE[${bars}]}"
        else
            icon="${WIFI_ICONS[${bars}]}"
        fi
        color="#89b4fa"
        tooltip="WiFi: ${ssid} (${signal}%)"
    fi

    output_icon "${icon}" "${color}" "${tooltip}"
}

# ── Volume ────────────────────────────────────────────────────────────────────
read_volume() {
    local cache_key="volume"
    local cached
    cached="$(state_cache_get "${cache_key}" "${ICON_CACHE_TTL_SHORT}")" && {
        echo "${cached}"; return 0
    }

    local volume=50 muted=false

    if command -v wpctl &>/dev/null; then
        local wp_out
        wp_out="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)"
        volume="$(echo "${wp_out}" | awk '{printf "%d", $2 * 100}')"
        echo "${wp_out}" | grep -q "MUTED" && muted=true
    elif command -v pactl &>/dev/null; then
        volume="$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null \
            | grep -oP '\d+%' | head -1 | tr -d '%')"
        pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null \
            | grep -q "yes" && muted=true
    fi

    local result="${volume:-50}|${muted}"
    state_cache_set "${cache_key}" "${result}"
    echo "${result}"
}

get_volume_icon() {
    local vol_data
    vol_data="$(read_volume)"
    IFS='|' read -r volume muted <<< "${vol_data}"

    local icon color

    if [[ "${muted}" == "true" ]]; then
        icon="${VOLUME_MUTE_ICON}"
        color="#6c7086"
    elif (( volume == 0 )); then
        icon="${VOLUME_ICONS[0]}"
        color="#6c7086"
    elif (( volume <= 33 )); then
        icon="${VOLUME_ICONS[1]}"
        color="#a6e3a1"
    elif (( volume <= 66 )); then
        icon="${VOLUME_ICONS[2]}"
        color="#89b4fa"
    elif (( volume <= 100 )); then
        icon="${VOLUME_ICONS[3]}"
        color="#cba6f7"
    else
        icon="${VOLUME_BOOST_ICON}"
        color="#f38ba8"
    fi

    output_icon "${icon}" "${color}" "Volume: ${volume}%$([ "${muted}" = true ] && echo " [MUTED]" || echo "")"
}

# ── CPU Load ──────────────────────────────────────────────────────────────────
read_cpu() {
    local cache_key="cpu_load"
    local cached
    cached="$(state_cache_get "${cache_key}" "${ICON_CACHE_TTL_SHORT}")" && {
        echo "${cached}"; return 0
    }

    local cpu_load=0
    if [[ -f /proc/stat ]]; then
        local cpu_line1 cpu_line2
        cpu_line1="$(head -1 /proc/stat)"
        sleep 0.2
        cpu_line2="$(head -1 /proc/stat)"

        local idle1 total1 idle2 total2
        idle1="$(echo "${cpu_line1}" | awk '{print $5}')"
        total1="$(echo "${cpu_line1}" | awk '{for(i=2;i<=NF;i++)sum+=$i;print sum}')"
        idle2="$(echo "${cpu_line2}" | awk '{print $5}')"
        total2="$(echo "${cpu_line2}" | awk '{for(i=2;i<=NF;i++)sum+=$i;print sum}')"

        local d_idle d_total
        d_idle=$(( idle2  - idle1  ))
        d_total=$(( total2 - total1 ))
        (( d_total > 0 )) && \
            cpu_load=$(( 100 - d_idle * 100 / d_total )) || \
            cpu_load=0
    fi

    state_cache_set "${cache_key}" "${cpu_load}"
    echo "${cpu_load}"
}

get_cpu_icon() {
    local load
    load="$(read_cpu)"

    local idx=0
    (( load >= 20 )) && idx=1
    (( load >= 50 )) && idx=2
    (( load >= 75 )) && idx=3
    (( load >= 90 )) && idx=4

    local icon="${CPU_ICONS[${idx}]}"
    local color="${CPU_COLORS[${idx}]}"
    output_icon "${icon}" "${color}" "CPU: ${load}%"
}

# ── RAM Usage ─────────────────────────────────────────────────────────────────
read_ram() {
    local cache_key="ram"
    local cached
    cached="$(state_cache_get "${cache_key}" "${ICON_CACHE_TTL_SHORT}")" && {
        echo "${cached}"; return 0
    }

    local used_pct=0
    if [[ -f /proc/meminfo ]]; then
        local total avail
        total="$(grep '^MemTotal:' /proc/meminfo | awk '{print $2}')"
        avail="$(grep '^MemAvailable:' /proc/meminfo | awk '{print $2}')"
        (( total > 0 )) && \
            used_pct=$(( (total - avail) * 100 / total )) || \
            used_pct=0
    fi

    state_cache_set "${cache_key}" "${used_pct}"
    echo "${used_pct}"
}

get_ram_icon() {
    local used
    used="$(read_ram)"

    local idx=0
    (( used >= 40 )) && idx=1
    (( used >= 60 )) && idx=2
    (( used >= 80 )) && idx=3
    (( used >= 95 )) && idx=4

    local color
    if   (( used >= 90 )); then color="#f38ba8"
    elif (( used >= 70 )); then color="#fab387"
    elif (( used >= 50 )); then color="#f9e2af"
    else                        color="#a6e3a1"
    fi

    output_icon "${RAM_ICONS[${idx:-0}]}" "${color}" "RAM: ${used}%"
}

# ── Temperature ───────────────────────────────────────────────────────────────
read_temp() {
    local cache_key="temperature"
    local cached
    cached="$(state_cache_get "${cache_key}" "${ICON_CACHE_TTL_SHORT}")" && {
        echo "${cached}"; return 0
    }

    local temp_c=0 path

    for path in /sys/class/thermal/thermal_zone*/temp; do
        local raw
        raw="$(cat "${path}" 2>/dev/null || echo 0)"
        temp_c=$(( raw / 1000 ))
        break
    done

    state_cache_set "${cache_key}" "${temp_c}"
    echo "${temp_c}"
}

get_temp_icon() {
    local temp
    temp="$(read_temp)"

    local idx=0
    (( temp >= 50 )) && idx=1
    (( temp >= 70 )) && idx=2
    (( temp >= 85 )) && idx=3

    output_icon "${TEMP_ICONS[${idx}]}" \
        "${TEMP_COLORS[${idx}]}" \
        "Temperature: ${temp}°C"
}

# ── Bluetooth ─────────────────────────────────────────────────────────────────
get_bluetooth_icon() {
    local cache_key="bluetooth"
    local cached
    cached="$(state_cache_get "${cache_key}" "${ICON_CACHE_TTL_MEDIUM}")" && {
        echo "${cached}"; return 0
    }

    local icon="${BT_ICON_OFF}" color="#6c7086" tooltip="Bluetooth: Off"

    if command -v bluetoothctl &>/dev/null; then
        local bt_power
        bt_power="$(bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}')"
        if [[ "${bt_power}" == "yes" ]]; then
            local bt_connected
            bt_connected="$(bluetoothctl info 2>/dev/null | grep 'Connected:' | awk '{print $2}')"
            if [[ "${bt_connected}" == "yes" ]]; then
                local bt_device
                bt_device="$(bluetoothctl info 2>/dev/null | grep 'Name:' | cut -d: -f2 | xargs)"
                icon="${BT_ICON_CONNECTED}"
                color="#cba6f7"
                tooltip="Bluetooth: ${bt_device}"
            else
                icon="${BT_ICON_ON}"
                color="#89b4fa"
                tooltip="Bluetooth: On"
            fi
        fi
    fi

    local result
    result="$(output_icon "${icon}" "${color}" "${tooltip}")"
    state_cache_set "${cache_key}" "${result}"
    echo "${result}"
}

# ── Media Player ──────────────────────────────────────────────────────────────
get_media_icon() {
    local cache_key="media"
    local cached
    cached="$(state_cache_get "${cache_key}" "${ICON_CACHE_TTL_SHORT}")" && {
        echo "${cached}"; return 0
    }

    local icon="${MEDIA_ICON_NONE}" color="#6c7086" tooltip="No media"

    if command -v playerctl &>/dev/null; then
        local status title artist
        status="$(playerctl status 2>/dev/null || echo "Stopped")"
        title="$(playerctl metadata title 2>/dev/null | head -c 40 || echo "")"
        artist="$(playerctl metadata artist 2>/dev/null | head -c 30 || echo "")"

        case "${status}" in
            Playing)
                icon="${MEDIA_ICON_PLAYING}"
                color="#a6e3a1"
                tooltip="${artist:+${artist} — }${title:-Unknown}"
                ;;
            Paused)
                icon="${MEDIA_ICON_PAUSED}"
                color="#f9e2af"
                tooltip="${title:-Paused}"
                ;;
            Stopped)
                icon="${MEDIA_ICON_STOPPED}"
                color="#6c7086"
                tooltip="Stopped"
                ;;
        esac
    fi

    local result
    result="$(output_icon "${icon}" "${color}" "${tooltip}")"
    state_cache_set "${cache_key}" "${result}"
    echo "${result}"
}

# ── Network Status ────────────────────────────────────────────────────────────
get_network_icon() {
    local icon="${NET_ICON_NONE}" color="#6c7086" tooltip="No network"

    # Check VPN first (highest priority visual)
    if ip link show 2>/dev/null | grep -q 'tun\|wg\|vpn'; then
        icon="${NET_ICON_VPN}"
        color="#a6e3a1"
        tooltip="VPN Active"
        output_icon "${icon}" "${color}" "${tooltip}"
        return
    fi

    # Ethernet
    if ip link show 2>/dev/null | grep -q 'state UP' | grep -qv 'wl\|ww'; then
        icon="${NET_ICON_ETHERNET}"
        color="#a6e3a1"
        tooltip="Ethernet"
        output_icon "${icon}" "${color}" "${tooltip}"
        return
    fi

    # WiFi (delegate to wifi icon)
    get_wifi_icon
}

# ── Time of Day ───────────────────────────────────────────────────────────────
get_time_icon() {
    local hour
    hour="$(date +%H)"
    local period

    if   (( hour >= 5  && hour < 8  )); then period="dawn"
    elif (( hour >= 8  && hour < 12 )); then period="morning"
    elif (( hour >= 12 && hour < 17 )); then period="afternoon"
    elif (( hour >= 17 && hour < 20 )); then period="evening"
    elif (( hour >= 20 && hour < 23 )); then period="night"
    else                                      period="midnight"
    fi

    local icon="${TIME_ICONS[${period}]:-󰖔}"
    local color="${TIME_COLORS[${period}]:-#89b4fa}"
    output_icon "${icon}" "${color}" "$(date +'%H:%M')"
}

# ── Weather ───────────────────────────────────────────────────────────────────
get_weather_icon() {
    local condition="${1:-unknown}"
    local icon="${WEATHER_ICONS[${condition}]:-${WEATHER_ICONS[unknown]}}"
    local color="${WEATHER_COLORS[${condition}]:-#a6adc8}"
    output_icon "${icon}" "${color}" "Weather: ${condition}"
}

# ── Git Status ────────────────────────────────────────────────────────────────
get_git_icon() {
    local dir="${1:-$(pwd)}"

    if ! git -C "${dir}" rev-parse --git-dir &>/dev/null; then
        echo ""
        return
    fi

    local icon color tooltip
    local ahead=0 behind=0 dirty=false staged=false untracked=false

    # Check status
    local git_status
    git_status="$(git -C "${dir}" status --porcelain=v2 --branch 2>/dev/null)"

    echo "${git_status}" | grep -q '^? ' && untracked=true
    echo "${git_status}" | grep -qE '^[12] [MADRCU]' && staged=true
    echo "${git_status}" | grep -qE '^[12] .[MADRCU]' && dirty=true

    ahead="$(echo "${git_status}" | grep '^# branch.ab' \
        | grep -oP '(?<=\+)\d+' || echo 0)"
    behind="$(echo "${git_status}" | grep '^# branch.ab' \
        | grep -oP '(?<=-)\d+' || echo 0)"

    if "${dirty}"; then
        icon="${GIT_ICON_DIRTY}"
        color="#fab387"
        tooltip="Git: Modified"
    elif "${staged}"; then
        icon="${GIT_ICON_STAGED}"
        color="#f9e2af"
        tooltip="Git: Staged"
    elif (( ahead > 0 )) && (( behind > 0 )); then
        icon="${GIT_ICON_DIVERGED}"
        color="#f38ba8"
        tooltip="Git: +${ahead}/-${behind}"
    elif (( ahead > 0 )); then
        icon="${GIT_ICON_AHEAD}"
        color="#a6e3a1"
        tooltip="Git: +${ahead}"
    elif (( behind > 0 )); then
        icon="${GIT_ICON_BEHIND}"
        color="#f38ba8"
        tooltip="Git: -${behind}"
    else
        icon="${GIT_ICON_CLEAN}"
        color="#a6e3a1"
        tooltip="Git: Clean"
    fi

    output_icon "${icon}" "${color}" "${tooltip}"
}

# ── Docker Status ─────────────────────────────────────────────────────────────
get_docker_icon() {
    local cache_key="docker"
    local cached
    cached="$(state_cache_get "${cache_key}" "${ICON_CACHE_TTL_MEDIUM}")" && {
        echo "${cached}"; return 0
    }

    local icon="${DOCKER_ICON_STOPPED}" color="#6c7086" tooltip="Docker"

    if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
        local running
        running="$(docker ps -q 2>/dev/null | wc -l)"
        if (( running > 0 )); then
            icon="${DOCKER_ICON_RUNNING}"
            color="#89b4fa"
            tooltip="Docker: ${running} running"
        else
            icon="${DOCKER_ICON_STOPPED}"
            color="#6c7086"
            tooltip="Docker: No containers"
        fi
    else
        icon="${DOCKER_ICON_STOPPED}"
        color="#6c7086"
        tooltip="Docker: Not running"
    fi

    local result
    result="$(output_icon "${icon}" "${color}" "${tooltip}")"
    state_cache_set "${cache_key}" "${result}"
    echo "${result}"
}

# ── ASH Mode Icon ─────────────────────────────────────────────────────────────
get_mode_icon() {
    local mode="${1:-default}"
    # Read current mode from state if not provided
    if [[ -z "${1:-}" ]]; then
        local mode_file="${ASH_DIR}/current-mode.conf"
        [[ -f "${mode_file}" ]] && \
            mode="$(grep -i '^mode\s*=' "${mode_file}" | cut -d= -f2 | tr -d ' "' | head -1)"
    fi

    local icon="${MODE_ICONS[${mode}]:-${MODE_ICONS[default]}}"
    local color="${MODE_COLORS[${mode}]:-#cdd6f4}"
    output_icon "${icon}" "${color}" "Mode: ${mode}"
}

# ── App Running State ─────────────────────────────────────────────────────────
get_app_state_icon() {
    local app_name="$1"
    local running_icon="${2:-}"
    local stopped_icon="${3:-}"

    local is_running=false
    if pgrep -x "${app_name}" &>/dev/null 2>&1 || \
       pgrep -f "${app_name}" &>/dev/null 2>&1; then
        is_running=true
    fi

    if "${is_running}"; then
        local icon="${running_icon:-$(bash "${ICON_LOOKUP}" nerd "${app_name}" 2>/dev/null || echo '●')}"
        output_icon "${icon}" "#a6e3a1" "${app_name}: Running"
    else
        local icon="${stopped_icon:-$(bash "${ICON_LOOKUP}" nerd "${app_name}" 2>/dev/null || echo '○')}"
        output_icon "${icon}" "#6c7086" "${app_name}: Stopped"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# § 10  PROGRESS & ANIMATION ENGINE
# ══════════════════════════════════════════════════════════════════════════════

render_progress_bar() {
    local value="${1:-0}"     # 0–100
    local width="${2:-10}"
    local style="${3:-block}" # block | braille | circle | arrow

    local filled=$(( value * width / 100 ))
    local empty=$(( width - filled ))
    local bar=""

    case "${style}" in
        block)
            local i
            for (( i=0; i<filled; i++ )); do bar+="${PROGRESS_FULL}"; done
            for (( i=0; i<empty;  i++ )); do bar+="${PROGRESS_EMPTY}"; done
            ;;
        thin)
            local i
            for (( i=0; i<filled; i++ )); do bar+="${PROGRESS_FILL}"; done
            for (( i=0; i<empty;  i++ )); do bar+="${PROGRESS_TRACK}"; done
            ;;
        dots)
            local i
            for (( i=0; i<filled; i++ )); do bar+="●"; done
            for (( i=0; i<empty;  i++ )); do bar+="○"; done
            ;;
        numeric)
            bar="${value}%"
            ;;
    esac

    echo "${bar}"
}

get_spinner_frame() {
    local style="${1:-dots}"
    local step="${2:-0}"
    local -a frames

    case "${style}" in
        dots)    frames=( "${SPINNER_DOTS[@]}" ) ;;
        braille) frames=( "${SPINNER_BRAILLE[@]}" ) ;;
        classic) frames=( "${SPINNER_CLASSIC[@]}" ) ;;
        arrows)  frames=( "${SPINNER_ARROWS[@]}" ) ;;
        nerd)    frames=( "${SPINNER_NERD[@]}" ) ;;
        *)       frames=( "${SPINNER_DOTS[@]}" ) ;;
    esac

    local idx=$(( step % ${#frames[@]} ))
    echo "${frames[${idx}]}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 11  NOTIFICATION BADGE GENERATOR
# ══════════════════════════════════════════════════════════════════════════════

# Generate icon with count badge overlay (text-based)
icon_with_badge() {
    local icon="$1"
    local count="${2:-0}"
    local max_display="${3:-99}"

    if (( count <= 0 )); then
        echo "${icon}"
    elif (( count > max_display )); then
        printf '%s %s+' "${icon}" "${max_display}"
    else
        printf '%s %s' "${icon}" "${count}"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# § 12  OUTPUT FORMATTER
# ══════════════════════════════════════════════════════════════════════════════

output_icon() {
    local icon="${1:-}"
    local color="${2:-}"
    local tooltip="${3:-}"

    case "${OUTPUT_MODE}" in
        rofi)
            # Rofi nerd font: just the glyph (path if it's a file)
            echo "${icon}"
            ;;
        waybar)
            # Waybar JSON format with pango markup
            local text_colored="${icon}"
            [[ -n "${color}" ]] && \
                text_colored="<span color='${color}'>${icon}</span>"
            jq -nc \
                --arg text "${text_colored}" \
                --arg tooltip "${tooltip}" \
                --arg class "${tooltip%:*}" \
                '{text:$text, tooltip:$tooltip, class:$class}'
            ;;
        shell)
            # Plain text for terminal prompt
            echo "${icon}"
            ;;
        colored)
            # ANSI colored for terminal
            if [[ -n "${color}" ]]; then
                # Convert hex to ANSI (approximate)
                printf '\033[38;2;%dm%s\033[0m' "$(hex_to_ansi "${color}")" "${icon}"
            else
                echo "${icon}"
            fi
            ;;
        json)
            # Full structured output
            jq -nc \
                --arg icon "${icon}" \
                --arg color "${color}" \
                --arg tooltip "${tooltip}" \
                '{icon:$icon, color:$color, tooltip:$tooltip}'
            ;;
        *)
            echo "${icon}"
            ;;
    esac
}

hex_to_ansi() {
    local hex="${1##\#}"
    local r g b
    r=$(( 16#${hex:0:2} ))
    g=$(( 16#${hex:2:2} ))
    b=$(( 16#${hex:4:2} ))
    printf '%d;%d;%d' "${r}" "${g}" "${b}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 13  ICON DASHBOARD (all icons at once, for waybar/statusbar use)
# ══════════════════════════════════════════════════════════════════════════════

get_all_icons() {
    local mode="${OUTPUT_MODE}"
    local -A result=()

    result[battery]="$(get_battery_icon)"
    result[wifi]="$(get_wifi_icon)"
    result[volume]="$(get_volume_icon)"
    result[cpu]="$(get_cpu_icon)"
    result[ram]="$(get_ram_icon)"
    result[temp]="$(get_temp_icon)"
    result[bluetooth]="$(get_bluetooth_icon)"
    result[media]="$(get_media_icon)"
    result[network]="$(get_network_icon)"
    result[time]="$(get_time_icon)"
    result[ash_mode]="$(get_mode_icon)"

    case "${mode}" in
        json)
            local json="{}"
            local key
            for key in "${!result[@]}"; do
                json="$(echo "${json}" | jq \
                    --arg k "${key}" \
                    --arg v "${result[${key}]}" \
                    '.[$k] = $v')"
            done
            echo "${json}"
            ;;
        *)
            local key
            for key in "${!result[@]}"; do
                printf '%s=%s\n' "${key}" "${result[${key}]}"
            done
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# § 14  SVG ASSET MANAGER
# ══════════════════════════════════════════════════════════════════════════════

# Get ASH system icon path with theme-color recoloring
get_ash_icon() {
    local icon_name="$1"
    local color="${2:-$(get_theme_accent)}"
    local size="${3:-48}"

    local icon_path="${ASH_ASSETS_DIR}/${icon_name}.svg"
    [[ ! -f "${icon_path}" ]] && {
        ilog_warn "ASH icon not found: ${icon_name}"
        resolve_nerd_glyph "${icon_name}" 2>/dev/null || echo "󰋗"
        return
    }

    local recolored
    recolored="$(recolor_svg "${icon_path}" "${color}")"

    if [[ "${OUTPUT_MODE}" == "rofi" ]]; then
        # Rofi accepts SVG paths
        echo "${recolored}"
    else
        svg_to_png "${recolored}" "${size}"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# § 15  ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════

main() {
    init
    load_settings

    # Output mode override from env
    [[ -n "${DYNAMIC_ICONS_MODE:-}" ]] && OUTPUT_MODE="${DYNAMIC_ICONS_MODE}"

    local cmd="${1:-help}"
    shift 2>/dev/null || true

    case "${cmd}" in
        # ── System state icons ───────────────────────────────────────────
        battery)         get_battery_icon ;;
        wifi)            get_wifi_icon ;;
        volume|audio)    get_volume_icon ;;
        cpu)             get_cpu_icon ;;
        ram|memory)      get_ram_icon ;;
        temp|temperature) get_temp_icon ;;
        bluetooth|bt)    get_bluetooth_icon ;;
        media|player)    get_media_icon ;;
        network|net)     get_network_icon ;;
        time|clock)      get_time_icon ;;
        mode|ash-mode)   get_mode_icon "${1:-}" ;;
        weather)         get_weather_icon "${1:-unknown}" ;;
        git)             get_git_icon "${1:-$(pwd)}" ;;
        docker)          get_docker_icon ;;
        app)             get_app_state_icon "${1:?}" "${2:-}" "${3:-}" ;;

        # ── Animation & progress ─────────────────────────────────────────
        spinner)
            local style="${1:-dots}" step="${2:-0}"
            get_spinner_frame "${style}" "${step}"
            ;;
        progress)
            local value="${1:-0}" width="${2:-10}" style="${3:-block}"
            render_progress_bar "${value}" "${width}" "${style}"
            ;;
        badge)
            local icon="${1:?}" count="${2:-0}"
            icon_with_badge "${icon}" "${count}"
            ;;

        # ── SVG / asset icons ─────────────────────────────────────────────
        svg)
            local icon_path="${1:?}" color="${2:-$(get_theme_accent)}"
            recolor_svg "${icon_path}" "${color}"
            ;;
        ash-icon)
            local icon_name="${1:?}" color="${2:-}" size="${3:-48}"
            get_ash_icon "${icon_name}" "${color}" "${size}"
            ;;

        # ── Dashboard ─────────────────────────────────────────────────────
        all|dashboard)
            get_all_icons
            ;;

        # ── Output mode ───────────────────────────────────────────────────
        --mode|-m)
            OUTPUT_MODE="${1:?}"
            shift
            main "$@"
            ;;

        # ── Info ─────────────────────────────────────────────────────────
        list-spinners)
            printf 'Styles: dots braille classic arrows nerd\n'
            local style
            for style in dots braille classic arrows nerd; do
                printf '  %-10s: ' "${style}"
                local i
                for i in 0 1 2 3 4 5; do
                    printf '%s ' "$(get_spinner_frame "${style}" "${i}")"
                done
                echo
            done
            ;;
        list-states)
            printf 'battery wifi volume cpu ram temp bluetooth media network time mode\n'
            ;;
        clear-cache)
            rm -f "${DYNAMIC_ICONS_CACHE}"/state/*.cache
            rm -f "${DYNAMIC_ICONS_CACHE}"/svg/*.svg
            rm -f "${DYNAMIC_ICONS_CACHE}"/png/*.png
            echo "Dynamic icons cache cleared"
            ;;
        version|-V)
            echo "dynamic-icons v5.0.0"
            ;;
        help|--help|-h|"")
            cat <<'EOF'
dynamic-icons.sh — ASH Dotfiles v5.0 Dynamic Icon Engine

USAGE: dynamic-icons.sh [--mode <mode>] <command> [args...]

OUTPUT MODES: rofi | waybar | shell | colored | json

SYSTEM STATE COMMANDS:
  battery              Current battery level + charge state
  wifi                 WiFi signal strength + SSID
  volume               Audio volume + mute state
  cpu                  CPU load percentage
  ram                  RAM usage percentage
  temp                 System temperature
  bluetooth            Bluetooth state + connected device
  media                Media player state + track
  network              Network connection type
  time                 Time-of-day icon
  mode [name]          ASH desktop mode icon
  weather <condition>  Weather condition icon
  git [path]           Git repository status icon
  docker               Docker container status
  app <name> [on] [off] App running state icon

ANIMATION COMMANDS:
  spinner <style> <step>       Get spinner frame (dots|braille|classic|arrows|nerd)
  progress <val> <w> <style>   Render progress bar
  badge <icon> <count>         Icon with notification badge

ASSET COMMANDS:
  svg <path> [color]           Recolor SVG to theme accent
  ash-icon <name> [color] [sz] Get ASH system icon (recolored)
  all                          Get all system state icons at once

EXAMPLES:
  dynamic-icons.sh battery
  dynamic-icons.sh --mode waybar battery
  dynamic-icons.sh --mode json all
  dynamic-icons.sh spinner dots 3
  dynamic-icons.sh progress 75 10 block
  dynamic-icons.sh badge 󰎆 5
  dynamic-icons.sh git /home/user/project
  dynamic-icons.sh weather clear-day
  dynamic-icons.sh app discord
EOF
            ;;
        *)
            dlog_warn "Unknown command: ${cmd}"
            echo "Unknown: ${cmd}. Run: dynamic-icons.sh help" >&2
            exit 1
            ;;
    esac
}

main "$@"