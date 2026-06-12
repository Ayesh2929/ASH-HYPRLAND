#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — MUSIC REACTIVE THEME                          ║
# ║           Album art → extract colors → apply as accent theme               ║
# ║           UNIQUE FEATURE: No other dotfiles system has this               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE: album-art-theme.sh [enable|disable|once|daemon|status]
#
# HOW IT WORKS:
#   1. Monitors playerctl for song changes
#   2. Gets album art URL from MPRIS metadata
#   3. Downloads album art to temp file
#   4. Extracts dominant color using ImageMagick
#   5. Updates Hyprland border color + Waybar accent
#   6. Smooth transition animation
#
# RESULT: Desktop accent color changes with every song! 🎵

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly ALBUM_CACHE="${CACHE_DIR}/album-art"
readonly COLOR_CACHE="${CACHE_DIR}/colors"
readonly LOG_FILE="${CACHE_DIR}/logs/album-theme.log"
readonly PID_FILE="/tmp/ash-album-theme.pid"
readonly CURRENT_SONG_FILE="${CACHE_DIR}/current-song"
readonly WAYBAR_SIGNAL=7

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; log "INFO" "$*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; log "OK" "$*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; log "WARN" "$*"; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🎵 ALBUM ART FETCHING
# ═══════════════════════════════════════════════════════════════════════════════

get_album_art_url() {
    # Get album art URI from MPRIS metadata
    local art_url
    art_url=$(playerctl metadata mpris:artUrl 2>/dev/null || echo "")

    # Handle different URL formats
    case "${art_url}" in
        file://*)
            # Local file
            echo "${art_url#file://}"
            ;;
        https://* | http://*)
            # Remote URL — download it
            local local_path="${ALBUM_CACHE}/current-art.jpg"
            curl -sL --max-time 5 "${art_url}" -o "${local_path}" 2>/dev/null \
                && echo "${local_path}" \
                || echo ""
            ;;
        /*)
            # Absolute local path
            echo "${art_url}"
            ;;
        *)
            echo ""
            ;;
    esac
}

get_current_song_id() {
    local title artist
    title=$(playerctl metadata title 2>/dev/null  || echo "")
    artist=$(playerctl metadata artist 2>/dev/null || echo "")
    echo "${artist}:${title}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 COLOR EXTRACTION FROM ALBUM ART
# ═══════════════════════════════════════════════════════════════════════════════

extract_vibrant_color() {
    local image_path="$1"

    if [[ ! -f "${image_path}" ]]; then
        echo ""
        return 1
    fi

    # Extract colors sorted by saturation (most vibrant first)
    local colors
    colors=$(convert "${image_path}" \
        -filter Lanczos \
        -resize 150x150^ \
        -gravity center \
        -extent 150x150 \
        -quantize transparent \
        -colors 16 \
        -unique-colors \
        -format "%[hex:u]\n" \
        info: 2>/dev/null || echo "")

    if [[ -z "${colors}" ]]; then
        echo ""
        return 1
    fi

    # Find most saturated + bright color (not too dark, not too light)
    local best_color=""
    local best_saturation=0

    while IFS= read -r hex; do
        [[ ${#hex} -ne 6 ]] && continue

        local r g b
        r=$(( 16#${hex:0:2} ))
        g=$(( 16#${hex:2:2} ))
        b=$(( 16#${hex:4:2} ))

        # Skip too dark (< 40 brightness)
        local brightness=$(( (r + g + b) / 3 ))
        (( brightness < 40 )) && continue

        # Skip too light (> 220 brightness)
        (( brightness > 220 )) && continue

        # Calculate saturation
        local max min
        max=$(( r > g ? (r > b ? r : b) : (g > b ? g : b) ))
        min=$(( r < g ? (r < b ? r : b) : (g < b ? g : b) ))

        local saturation=0
        if (( max > 0 )); then
            saturation=$(( (max - min) * 100 / max ))
        fi

        if (( saturation > best_saturation )); then
            best_saturation="${saturation}"
            best_color="${hex}"
        fi
    done <<< "${colors}"

    # Fallback: use first color if no vibrant found
    if [[ -z "${best_color}" ]]; then
        best_color=$(echo "${colors}" | head -1)
    fi

    echo "${best_color}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🖥️ APPLY MUSIC COLOR TO DESKTOP
# ═══════════════════════════════════════════════════════════════════════════════

apply_music_color() {
    local hex_color="$1"
    local song_name="$2"

    if [[ -z "${hex_color}" ]]; then
        return 0
    fi

    info "Applying music color: #${hex_color} (${song_name})"

    # ── Generate complementary colors ─────────────────────────────────────────
    local r g b
    r=$(( 16#${hex_color:0:2} ))
    g=$(( 16#${hex_color:2:2} ))
    b=$(( 16#${hex_color:4:2} ))

    # Lighter variant (for secondary accent)
    local r2 g2 b2
    r2=$(( r + 30 > 255 ? 255 : r + 30 ))
    g2=$(( g + 30 > 255 ? 255 : g + 30 ))
    b2=$(( b + 30 > 255 ? 255 : b + 30 ))
    local hex2
    hex2=$(printf "%02x%02x%02x" "${r2}" "${g2}" "${b2}")

    # Darker variant (for tertiary)
    local r3 g3 b3
    r3=$(( r - 30 < 0 ? 0 : r - 30 ))
    g3=$(( g - 30 < 0 ? 0 : g - 30 ))
    b3=$(( b - 30 < 0 ? 0 : b - 30 ))
    local hex3
    hex3=$(printf "%02x%02x%02x" "${r3}" "${g3}" "${b3}")

    # ── Update Hyprland border colors ─────────────────────────────────────────
    hyprctl keyword "general:col.active_border" \
        "rgba(${hex_color}ff) rgba(${hex2}ff) rgba(${hex3}ff) 60deg" \
        2>/dev/null || true

    hyprctl keyword "general:col.inactive_border" \
        "rgba(${hex_color}44)" \
        2>/dev/null || true

    # ── Update group bar colors ───────────────────────────────────────────────
    hyprctl keyword "group:col.border_active" \
        "rgba(${hex_color}ff)" \
        2>/dev/null || true

    hyprctl keyword "group:groupbar:col.active" \
        "rgba(${hex_color}ff)" \
        2>/dev/null || true

    # ── Save current music color ──────────────────────────────────────────────
    mkdir -p "${COLOR_CACHE}"
    cat > "${COLOR_CACHE}/music-color.sh" << EOF
# ASH Music Reactive Color — Generated $(date)
# Song: ${song_name}
ASH_MUSIC_PRIMARY="${hex_color}"
ASH_MUSIC_SECONDARY="${hex2}"
ASH_MUSIC_TERTIARY="${hex3}"
export ASH_MUSIC_PRIMARY ASH_MUSIC_SECONDARY ASH_MUSIC_TERTIARY
EOF

    # ── Update Waybar CSS variable ─────────────────────────────────────────────
    local waybar_colors="${HOME}/.config/waybar/styles/colors.css"
    if [[ -f "${waybar_colors}" ]]; then
        # Update music-specific color variable
        sed -i "s/@define-color music.*/@define-color music  #${hex_color};/" \
            "${waybar_colors}" 2>/dev/null || true

        # Signal Waybar to reload CSS
        pkill -SIGUSR2 waybar 2>/dev/null || true
    fi

    # ── Update Kitty terminal border ──────────────────────────────────────────
    if pgrep -x kitty &>/dev/null; then
        kitty @ --to unix:/tmp/kitty set-colors \
            "active_border_color=#${hex_color}" \
            2>/dev/null || true
    fi

    # ── Show notification with color preview ─────────────────────────────────
    notify-send "🎵 Theme Synced" \
        "Color: #${hex_color}\nSong: ${song_name}" \
        --app-name="ASH Music" \
        --expire-time=2000 \
        2>/dev/null || true

    # Signal Waybar player module
    pkill -SIGRTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true

    ok "Music color applied: #${hex_color}"
    log "INFO" "Music color: #${hex_color} — ${song_name}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔄 SONG CHANGE DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

process_current_song() {
    # Get current song info
    local status
    status=$(playerctl status 2>/dev/null || echo "Stopped")

    if [[ "${status}" == "Stopped" ]]; then
        return 0
    fi

    local song_id
    song_id=$(get_current_song_id)

    # Check if song changed
    local last_song=""
    [[ -f "${CURRENT_SONG_FILE}" ]] && last_song=$(cat "${CURRENT_SONG_FILE}")

    if [[ "${song_id}" == "${last_song}" ]]; then
        return 0  # Same song, no action needed
    fi

    # Song changed!
    echo "${song_id}" > "${CURRENT_SONG_FILE}"
    log "INFO" "Song changed: ${song_id}"

    # Get album art
    local art_path
    art_path=$(get_album_art_url)

    if [[ -z "${art_path}" ]] || [[ ! -f "${art_path}" ]]; then
        log "WARN" "No album art found for: ${song_id}"
        return 0
    fi

    # Extract color
    local color
    color=$(extract_vibrant_color "${art_path}")

    if [[ -n "${color}" ]]; then
        local title
        title=$(playerctl metadata title 2>/dev/null || echo "Unknown")
        apply_music_color "${color}" "${title}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 DAEMON MODE
# ═══════════════════════════════════════════════════════════════════════════════

run_daemon() {
    info "Starting music reactive theme daemon..."
    echo $$ > "${PID_FILE}"

    # Use playerctl follow for efficient event detection
    if command -v playerctl &>/dev/null; then
        # Process initial song
        process_current_song

        # Watch for changes
        playerctl --follow metadata title 2>/dev/null | \
        while IFS= read -r _; do
            process_current_song
        done &

        local watch_pid=$!
        log "INFO" "Watching playerctl (PID: ${watch_pid})"

        # Fallback polling loop (in case follow misses events)
        while kill -0 $$ 2>/dev/null; do
            process_current_song
            sleep 5
        done
    else
        warn "playerctl not found — polling mode"
        while true; do
            process_current_song
            sleep 5
        done
    fi
}

is_running() {
    [[ -f "${PID_FILE}" ]] && kill -0 "$(cat "${PID_FILE}")" 2>/dev/null
}

stop_daemon() {
    if is_running; then
        kill "$(cat "${PID_FILE}")" 2>/dev/null || true
        rm -f "${PID_FILE}" "${CURRENT_SONG_FILE}"
        ok "Music reactive theme stopped"
        log "INFO" "Daemon stopped"
    else
        info "Not running"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-once}"

    mkdir -p "${ALBUM_CACHE}" "${CACHE_DIR}/logs"

    # Check dependencies
    if ! command -v convert &>/dev/null; then
        warn "ImageMagick required: paru -S imagemagick"
        exit 1
    fi
    if ! command -v playerctl &>/dev/null; then
        warn "playerctl required: paru -S playerctl"
        exit 1
    fi

    case "${action}" in
        enable | daemon | start)
            if is_running; then
                info "Already running (PID: $(cat "${PID_FILE}"))"
            else
                run_daemon &>/dev/null &
                disown
                sleep 0.5
                is_running && ok "Music reactive theme ENABLED" \
                           || warn "Failed to start daemon"
            fi
            ;;

        disable | stop)
            stop_daemon
            ;;

        toggle)
            is_running && stop_daemon || {
                run_daemon &>/dev/null &
                disown
                ok "Music reactive theme ENABLED"
            }
            ;;

        once | update)
            process_current_song
            ;;

        status)
            if is_running; then
                echo -e "  \033[92m●\033[0m Music reactive theme: ACTIVE"
                local song
                [[ -f "${CURRENT_SONG_FILE}" ]] && song=$(cat "${CURRENT_SONG_FILE}") || song="?"
                echo "  Current song: ${song}"
            else
                echo -e "  \033[90m○\033[0m Music reactive theme: inactive"
            fi
            ;;

        color)
            # Just print the current music color
            local colors_file="${COLOR_CACHE}/music-color.sh"
            [[ -f "${colors_file}" ]] && cat "${colors_file}" || echo "No music color set"
            ;;

        reset)
            stop_daemon
            # Reset to default theme colors
            "${HOME}/.config/hypr/scripts/theme/theme-engine.sh" "" reapply
            ok "Reset to default theme"
            ;;

        *)
            echo "Usage: album-art-theme.sh [enable|disable|toggle|once|status|color|reset]"
            exit 1
            ;;
    esac
}

main "$@"