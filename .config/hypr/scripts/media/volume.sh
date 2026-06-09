#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — VOLUME CONTROL                               ║
# ║           PipeWire/PulseAudio with OSD + Waybar signal                     ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE: volume.sh [ACTION] [AMOUNT]
#
# ACTIONS:
#   up    N  — Increase volume by N% (default 5)
#   down  N  — Decrease volume by N%
#   mute     — Toggle mute
#   set   N  — Set volume to exactly N%
#   get      — Get current volume (for Waybar)
#   status   — Get volume JSON for Waybar module

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/volume.log"
readonly MAX_VOLUME=150
readonly WAYBAR_SIGNAL=8

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔊 AUDIO BACKEND DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

detect_backend() {
    if command -v wpctl &>/dev/null && pactl info 2>/dev/null | grep -q PipeWire; then
        echo "pipewire"
    elif command -v pamixer &>/dev/null; then
        echo "pamixer"
    elif command -v pactl &>/dev/null; then
        echo "pulseaudio"
    elif command -v amixer &>/dev/null; then
        echo "alsa"
    else
        echo "none"
    fi
}

readonly BACKEND=$(detect_backend)

# ═══════════════════════════════════════════════════════════════════════════════
# 🔊 VOLUME OPERATIONS
# ═══════════════════════════════════════════════════════════════════════════════

get_volume() {
    case "${BACKEND}" in
        pipewire)
            wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null \
                | awk '{printf "%.0f", $2 * 100}'
            ;;
        pamixer)
            pamixer --get-volume 2>/dev/null || echo "0"
            ;;
        pulseaudio)
            pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null \
                | grep -oP '\d+(?=%)' | head -1
            ;;
        alsa)
            amixer sget Master 2>/dev/null \
                | grep -oP '\d+(?=%)' | head -1
            ;;
        *)
            echo "0"
            ;;
    esac
}

get_mute() {
    case "${BACKEND}" in
        pipewire)
            wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null \
                | grep -q MUTED && echo "true" || echo "false"
            ;;
        pamixer)
            pamixer --get-mute 2>/dev/null || echo "false"
            ;;
        pulseaudio)
            local mute
            mute=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}')
            [[ "${mute}" == "yes" ]] && echo "true" || echo "false"
            ;;
        alsa)
            amixer sget Master 2>/dev/null | grep -q "\[off\]" && echo "true" || echo "false"
            ;;
        *)
            echo "false"
            ;;
    esac
}

set_volume() {
    local vol="$1"
    # Clamp to 0-MAX_VOLUME
    (( vol < 0 )) && vol=0
    (( vol > MAX_VOLUME )) && vol=${MAX_VOLUME}

    case "${BACKEND}" in
        pipewire)
            wpctl set-volume @DEFAULT_AUDIO_SINK@ "${vol}%" 2>/dev/null
            ;;
        pamixer)
            pamixer --set-volume "${vol}" 2>/dev/null
            ;;
        pulseaudio)
            pactl set-sink-volume @DEFAULT_SINK@ "${vol}%" 2>/dev/null
            ;;
        alsa)
            amixer sset Master "${vol}%" 2>/dev/null
            ;;
    esac
}

toggle_mute() {
    case "${BACKEND}" in
        pipewire)
            wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle 2>/dev/null
            ;;
        pamixer)
            pamixer --toggle-mute 2>/dev/null
            ;;
        pulseaudio)
            pactl set-sink-mute @DEFAULT_SINK@ toggle 2>/dev/null
            ;;
        alsa)
            amixer sset Master toggle 2>/dev/null
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📣 OSD NOTIFICATION
# ═══════════════════════════════════════════════════════════════════════════════

show_osd() {
    local volume="$1"
    local muted="$2"

    # Get icon based on volume/mute state
    local icon
    if [[ "${muted}" == "true" ]]; then
        icon="audio-volume-muted-symbolic"
    elif (( volume == 0 )); then
        icon="audio-volume-muted-symbolic"
    elif (( volume <= 33 )); then
        icon="audio-volume-low-symbolic"
    elif (( volume <= 66 )); then
        icon="audio-volume-medium-symbolic"
    else
        icon="audio-volume-high-symbolic"
    fi

    # Try swayosd first (best OSD)
    if command -v swayosd-client &>/dev/null; then
        if [[ "${muted}" == "true" ]]; then
            swayosd-client --output-volume mute-toggle 2>/dev/null || true
        else
            swayosd-client --output-volume "${volume}" 2>/dev/null || true
        fi
        return 0
    fi

    # Fallback: dunst notification with progress bar
    local bar=""
    local filled=$(( volume / 5 ))
    local empty=$(( 20 - filled ))
    for (( i=0; i<filled; i++ )); do bar+="█"; done
    for (( i=0; i<empty; i++ )); do bar+="░"; done

    local title
    if [[ "${muted}" == "true" ]]; then
        title="🔇 Muted"
    else
        title="🔊 Volume: ${volume}%"
    fi

    notify-send "${title}" \
        "${bar}" \
        --icon="${icon}" \
        --app-name="Volume" \
        --expire-time=1500 \
        --hint=int:value:"${volume}" \
        --hint=string:synchronous:volume \
        2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📡 WAYBAR SIGNAL
# ═══════════════════════════════════════════════════════════════════════════════

signal_waybar() {
    pkill -SIGRTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 WAYBAR JSON STATUS
# ═══════════════════════════════════════════════════════════════════════════════

status_json() {
    local vol
    vol=$(get_volume)
    local muted
    muted=$(get_mute)

    local icon
    local class
    if [[ "${muted}" == "true" ]]; then
        icon="󰝟"
        class="muted"
    elif (( vol == 0 )); then
        icon="󰝟"
        class="muted"
    elif (( vol <= 33 )); then
        icon="󰕿"
        class="low"
    elif (( vol <= 66 )); then
        icon="󰖀"
        class="medium"
    elif (( vol <= 100 )); then
        icon="󰕾"
        class="high"
    else
        icon="󰕾"
        class="boost"
    fi

    local text
    if [[ "${muted}" == "true" ]]; then
        text="${icon} Muted"
    else
        text="${icon} ${vol}%"
    fi

    printf '{"text": "%s", "tooltip": "Volume: %s%%\nMuted: %s\nBackend: %s", "class": "%s", "percentage": %s}\n' \
        "${text}" "${vol}" "${muted}" "${BACKEND}" "${class}" "${vol}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-status}"
    local amount="${2:-5}"

    mkdir -p "${CACHE_DIR}/logs"

    if [[ "${BACKEND}" == "none" ]]; then
        echo '{"text": "󰝟 No audio", "class": "error"}'
        exit 1
    fi

    case "${action}" in
        up)
            local current
            current=$(get_volume)
            local new=$(( current + amount ))
            set_volume "${new}"
            local final
            final=$(get_volume)
            local muted
            muted=$(get_mute)
            show_osd "${final}" "${muted}"
            signal_waybar
            log "INFO" "Volume up ${amount}% → ${final}%"
            ;;

        down)
            local current
            current=$(get_volume)
            local new=$(( current - amount ))
            set_volume "${new}"
            local final
            final=$(get_volume)
            local muted
            muted=$(get_mute)
            show_osd "${final}" "${muted}"
            signal_waybar
            log "INFO" "Volume down ${amount}% → ${final}%"
            ;;

        set)
            set_volume "${amount}"
            local final
            final=$(get_volume)
            local muted
            muted=$(get_mute)
            show_osd "${final}" "${muted}"
            signal_waybar
            log "INFO" "Volume set to ${amount}% → ${final}%"
            ;;

        mute | toggle)
            toggle_mute
            local vol
            vol=$(get_volume)
            local muted
            muted=$(get_mute)
            show_osd "${vol}" "${muted}"
            signal_waybar
            log "INFO" "Mute toggled → ${muted}"
            ;;

        get)
            get_volume
            ;;

        status)
            status_json
            ;;

        backend)
            echo "${BACKEND}"
            ;;

        *)
            echo "Usage: volume.sh [up|down|mute|set|get|status] [amount]" >&2
            exit 1
            ;;
    esac
}

main "$@"