#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — SCREEN RECORDER                              ║
# ║           wf-recorder with area/window/audio modes + Waybar integration    ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE: recorder.sh [ACTION] [OPTIONS]
#
# ACTIONS:
#   toggle    — Toggle full-screen recording (no audio)
#   full      — Record full screen
#   area      — Record selected area (slurp)
#   window    — Record active window
#   audio     — Record with audio (full screen)
#   audio-area — Record area with audio
#   stop      — Stop current recording
#   status    — Show recording status JSON
#   gif       — Record area as GIF

set -euo pipefail

readonly SAVE_DIR="${HOME}/Pictures/Recordings"
readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/recorder.log"
readonly PID_FILE="/tmp/ash-recorder.pid"
readonly WAYBAR_SIGNAL=12
readonly TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"

# Recording quality presets
readonly VIDEO_CODEC="libx264"
readonly VIDEO_QUALITY=28       # CRF: lower=better (18-28 range)
readonly AUDIO_CODEC="libopus"
readonly FRAMERATE=60
readonly PIXEL_FORMAT="yuv420p"

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; }
err()  { echo -e "  \033[91m✗\033[0m $*" >&2; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 DEPENDENCY CHECK
# ═══════════════════════════════════════════════════════════════════════════════

check_deps() {
    local missing=()
    command -v wf-recorder &>/dev/null || missing+=("wf-recorder")
    command -v ffmpeg      &>/dev/null || missing+=("ffmpeg (optional)")

    if ! command -v wf-recorder &>/dev/null; then
        notify-send "🎬 Recorder" \
            "wf-recorder not installed\n\nparu -S wf-recorder" \
            --app-name="ASH Recorder" --urgency=critical 2>/dev/null || true
        err "wf-recorder not found — install: paru -S wf-recorder"
        exit 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 GEOMETRY SELECTION
# ═══════════════════════════════════════════════════════════════════════════════

get_area_geometry() {
    slurp \
        -d \
        -b "1e1e2eaa" \
        -c "f38ba8ff" \
        -s "f38ba81a" \
        -w 2 \
        2>/dev/null
}

get_window_geometry() {
    local win
    win=$(hyprctl activewindow -j 2>/dev/null)
    local x y w h
    x=$(echo "${win}" | jq '.at[0]')
    y=$(echo "${win}" | jq '.at[1]')
    w=$(echo "${win}" | jq '.size[0]')
    h=$(echo "${win}" | jq '.size[1]')
    echo "${x},${y} ${w}x${h}"
}

get_active_monitor() {
    hyprctl monitors -j 2>/dev/null \
        | jq -r '.[] | select(.focused == true) | .name' \
        2>/dev/null || echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔔 NOTIFICATIONS
# ═══════════════════════════════════════════════════════════════════════════════

notify_start() {
    local mode="${1:-recording}"
    notify-send "🔴 Recording Started" \
        "${mode^} — Press keybind or run 'recorder stop' to stop" \
        --app-name="ASH Recorder" \
        --expire-time=3000 \
        --icon=media-record \
        2>/dev/null || true
}

notify_stop() {
    local file="$1"
    local size
    size=$(du -sh "${file}" 2>/dev/null | cut -f1 || echo "?")

    notify-send "🎬 Recording Saved" \
        "$(basename "${file}") (${size})" \
        --app-name="ASH Recorder" \
        --expire-time=5000 \
        --icon=video-x-generic \
        2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# ▶️ START RECORDING
# ═══════════════════════════════════════════════════════════════════════════════

is_recording() {
    [[ -f "${PID_FILE}" ]] && kill -0 "$(cat "${PID_FILE}")" 2>/dev/null
}

stop_recording() {
    if ! is_recording; then
        info "No recording in progress"
        return 0
    fi

    local pid
    pid=$(cat "${PID_FILE}")

    # Graceful stop
    kill -SIGINT "${pid}" 2>/dev/null || true
    sleep 0.5

    # Force stop if still running
    kill -0 "${pid}" 2>/dev/null && kill -SIGTERM "${pid}" 2>/dev/null || true

    rm -f "${PID_FILE}"
    pkill -SIGRTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true

    local output_file="${CACHE_DIR}/recorder-last-file"
    if [[ -f "${output_file}" ]]; then
        local file
        file=$(cat "${output_file}")
        [[ -f "${file}" ]] && notify_stop "${file}" && ok "Saved: ${file}"
        rm -f "${output_file}"
    fi

    log "INFO" "Recording stopped (PID: ${pid})"
}

start_recording() {
    local output="$1"
    local geometry="${2:-}"
    local audio="${3:-false}"

    mkdir -p "${SAVE_DIR}"

    # Build wf-recorder command
    local cmd=(
        wf-recorder
        --codec="${VIDEO_CODEC}"
        --framerate="${FRAMERATE}"
        --pixel-format="${PIXEL_FORMAT}"
        --file="${output}"
    )

    # Add geometry if specified
    if [[ -n "${geometry}" ]]; then
        cmd+=(--geometry="${geometry}")
    else
        # Use active monitor
        local monitor
        monitor=$(get_active_monitor)
        [[ -n "${monitor}" ]] && cmd+=(--output="${monitor}")
    fi

    # Add audio
    if [[ "${audio}" == "true" ]]; then
        if command -v pactl &>/dev/null; then
            local audio_device
            audio_device=$(pactl get-default-sink 2>/dev/null).monitor
            cmd+=(--audio="${audio_device}" --audio-codec="${AUDIO_CODEC}")
        else
            cmd+=(--audio)
        fi
    fi

    # Start recording in background
    "${cmd[@]}" &>/dev/null &
    local pid=$!

    echo "${pid}" > "${PID_FILE}"
    echo "${output}" > "${CACHE_DIR}/recorder-last-file"

    # Verify it started
    sleep 0.3
    if ! kill -0 "${pid}" 2>/dev/null; then
        err "Recording failed to start"
        rm -f "${PID_FILE}"
        return 1
    fi

    pkill -SIGRTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true

    ok "Recording started: ${output}"
    log "INFO" "Started recording: ${output} (PID: ${pid}, audio: ${audio})"

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎥 RECORDING MODES
# ═══════════════════════════════════════════════════════════════════════════════

record_full() {
    local audio="${1:-false}"
    local suffix
    [[ "${audio}" == "true" ]] && suffix="_audio" || suffix=""
    local output="${SAVE_DIR}/recording_full${suffix}_${TIMESTAMP}.mp4"

    if start_recording "${output}" "" "${audio}"; then
        notify_start "Full screen"
    fi
}

record_area() {
    local audio="${1:-false}"
    local suffix
    [[ "${audio}" == "true" ]] && suffix="_audio" || suffix=""

    info "Select area to record..."
    local geometry
    geometry=$(get_area_geometry) || {
        info "Selection cancelled"
        return 0
    }

    local output="${SAVE_DIR}/recording_area${suffix}_${TIMESTAMP}.mp4"

    if start_recording "${output}" "${geometry}" "${audio}"; then
        notify_start "Area recording"
    fi
}

record_window() {
    local audio="${1:-false}"
    local geometry
    geometry=$(get_window_geometry)

    local output="${SAVE_DIR}/recording_window_${TIMESTAMP}.mp4"

    if start_recording "${output}" "${geometry}" "${audio}"; then
        notify_start "Window recording"
    fi
}

record_gif() {
    if ! command -v ffmpeg &>/dev/null; then
        err "ffmpeg required for GIF recording"
        notify-send "🎬 Recorder" "ffmpeg required for GIF\nparu -S ffmpeg" \
            --app-name="ASH Recorder" 2>/dev/null || true
        return 1
    fi

    info "Select area for GIF..."
    local geometry
    geometry=$(get_area_geometry) || {
        info "Selection cancelled"
        return 0
    }

    local tmp_output="/tmp/ash-recorder-gif-${TIMESTAMP}.mp4"
    local gif_output="${SAVE_DIR}/recording_${TIMESTAMP}.gif"

    # Record as MP4 first (lower framerate for GIF)
    local pid
    wf-recorder \
        --codec="${VIDEO_CODEC}" \
        --framerate=15 \
        --geometry="${geometry}" \
        --file="${tmp_output}" \
        &>/dev/null &
    pid=$!

    echo "${pid}" > "${PID_FILE}"
    notify_start "GIF recording (stop to convert)"
    pkill -SIGRTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true

    log "INFO" "GIF recording started (MP4: ${tmp_output})"

    # When stopped, convert to GIF
    wait "${pid}" 2>/dev/null || true
    rm -f "${PID_FILE}"
    pkill -SIGRTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true

    if [[ -f "${tmp_output}" ]]; then
        info "Converting to GIF..."
        ffmpeg \
            -i "${tmp_output}" \
            -vf "fps=12,scale=640:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=64[p];[s1][p]paletteuse=dither=bayer" \
            -loop 0 \
            "${gif_output}" \
            2>/dev/null

        rm -f "${tmp_output}"

        if [[ -f "${gif_output}" ]]; then
            # Copy to clipboard
            wl-copy < "${gif_output}" 2>/dev/null || true
            notify_stop "${gif_output}"
            ok "GIF saved: ${gif_output}"
            log "INFO" "GIF created: ${gif_output}"
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 WAYBAR STATUS
# ═══════════════════════════════════════════════════════════════════════════════

status_json() {
    if is_recording; then
        local pid
        pid=$(cat "${PID_FILE}" 2>/dev/null || echo "?")
        # Get recording duration
        local start_time
        start_time=$(stat -c %Y "${PID_FILE}" 2>/dev/null || echo "0")
        local now
        now=$(date +%s)
        local duration=$(( now - start_time ))
        local mins=$(( duration / 60 ))
        local secs=$(( duration % 60 ))

        printf '{"text": "🔴 %02d:%02d", "tooltip": "Recording in progress\nDuration: %02d:%02d\nPID: %s", "class": "recording"}\n' \
            "${mins}" "${secs}" "${mins}" "${secs}" "${pid}"
    else
        printf '{"text": "⏺️", "tooltip": "Click to start recording", "class": "idle"}\n'
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-toggle}"
    shift || true

    mkdir -p "${SAVE_DIR}" "${CACHE_DIR}/logs"

    case "${action}" in
        toggle)
            if is_recording; then
                stop_recording
            else
                record_full "false"
            fi
            ;;

        full)
            is_recording && stop_recording || record_full "false"
            ;;

        area)
            is_recording && stop_recording || record_area "false"
            ;;

        window)
            is_recording && stop_recording || record_window "false"
            ;;

        audio | audio-full)
            is_recording && stop_recording || record_full "true"
            ;;

        audio-area)
            is_recording && stop_recording || record_area "true"
            ;;

        audio-window)
            is_recording && stop_recording || record_window "true"
            ;;

        stop)
            stop_recording
            ;;

        gif)
            is_recording && stop_recording || record_gif
            ;;

        status)
            status_json
            ;;

        is-recording)
            is_recording && echo "true" || echo "false"
            ;;

        open)
            xdg-open "${SAVE_DIR}" 2>/dev/null || nemo "${SAVE_DIR}" 2>/dev/null || true
            ;;

        *)
            echo "Usage: recorder.sh [toggle|full|area|window|audio|audio-area|stop|gif|status]"
            exit 1
            ;;
    esac
}

main "$@"