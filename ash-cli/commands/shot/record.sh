#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  shot record                                              ║
# ║  Screen recording with wf-recorder/wl-screenrec/ffmpeg • audio • GPU encode    ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_SHOT_RECORD_LOADED:-}" == "1" ]] && return 0
readonly _ASH_SHOT_RECORD_LOADED=1

set -euo pipefail
IFS=$'\n\t'

declare -g _RECORD_PID_FILE="${_SHOT_TMP:-/tmp/ash-shot}/record.pid"
declare -g _RECORD_FILE_FILE="${_SHOT_TMP:-/tmp/ash-shot}/record.file"

_record_stop_existing() {
    if [[ -f "$_RECORD_PID_FILE" ]]; then
        local pid
        pid="$(cat "$_RECORD_PID_FILE" 2>/dev/null || echo '')"
        local rec_file
        rec_file="$(cat "$_RECORD_FILE_FILE" 2>/dev/null || echo '')"

        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            shot_step "Stopping existing recording  (PID: ${pid})..."
            kill -SIGINT "$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null
            sleep 1
            rm -f "$_RECORD_PID_FILE" "$_RECORD_FILE_FILE"

            if [[ -n "$rec_file" ]] && [[ -f "$rec_file" ]]; then
                local size
                size="$(du -sh "$rec_file" 2>/dev/null | cut -f1)"
                shot_ok "Recording saved: ${rec_file##*/}  (${size})"
                shot_notify "🎬 Recording Stopped" "${rec_file##*/}  •  ${size}" ""
            fi
            return 0
        fi
    fi
    return 1
}

_record_wf_recorder() {
    local output="$1"  audio="$2"  fps="$3"  codec="$4"
    local -a args=( "wf-recorder" )

    [[ -n "$codec" ]] && args+=( "-c" "$codec" )
    args+=( "-r" "$fps" )
    [[ "$audio" -eq 1 ]] && args+=( "-a" )
    args+=( "-f" "$output" )

    printf '%s' "${args[*]}"
}

_record_ffmpeg() {
    local output="$1"  audio="$2"  fps="$3"
    local -a args=(
        "ffmpeg" "-y"
        "-f" "pipewire"
        "-i" "default"
        "-r" "$fps"
        "-vcodec" "libx264"
        "-preset" "veryfast"
        "-crf" "23"
    )
    [[ "$audio" -eq 1 ]] && args+=( "-f" "pulse" "-i" "default" )
    args+=( "$output" )
    printf '%s' "${args[*]}"
}

ash_shot_record() {
    local mode="area"   # area | full | window
    local fps=30
    local audio=0
    local codec=""
    local fmt="mp4"
    local stop_mode=0

    for arg in "${@:-}"; do
        case "$arg" in
            --stop|-s)        stop_mode=1          ;;
            --full|-f)        mode="full"           ;;
            --area|-a)        mode="area"           ;;
            --audio)          audio=1               ;;
            --fps=*)          fps="${arg#*=}"       ;;
            --codec=*)        codec="${arg#*=}"     ;;
            --format=*)       fmt="${arg#*=}"       ;;
            mkv|mp4|webm)     fmt="$arg"            ;;
        esac
    done

    shot_section "🎬" "Screen Recording" "$(_sred)"

    # Stop existing recording
    if [[ $stop_mode -eq 1 ]] || _record_stop_existing; then
        [[ $stop_mode -eq 1 ]] && return 0
    fi

    shot_check_wayland || return 1

    local output_file
    output_file="$(shot_filename "recording" "$fmt")"

    shot_kv "Output"  "$output_file"
    shot_kv "FPS"     "$fps"
    shot_kv "Audio"   "$([[ $audio -eq 1 ]] && echo 'yes' || echo 'no')"
    shot_kv "Format"  "${fmt^^}"
    shot_kv "Mode"    "$mode"

    # Geometry for area mode
    local geometry=""
    if [[ "$mode" == "area" ]]; then
        shot_info "Select area to record..."
        if command -v slurp &>/dev/null; then
            geometry="$(slurp \
                -b "1e1e2eCC" -c "f38ba8FF" -s "f38ba840" -w 2 \
                2>/dev/null)" || {
                shot_info "Selection cancelled"
                return 0
            }
        fi
    fi

    # Choose backend
    local backend_cmd=()

    if command -v wl-screenrec &>/dev/null; then
        # Hardware-accelerated (vaapi)
        backend_cmd=( "wl-screenrec" )
        [[ -n "$geometry" ]] && backend_cmd+=( "-g" "$geometry" )
        [[ $audio -eq 1 ]] && backend_cmd+=( "--audio" )
        backend_cmd+=( "-f" "$output_file" )
        shot_kv "Backend" "wl-screenrec  (HW accel)"

    elif command -v wf-recorder &>/dev/null; then
        backend_cmd=( "wf-recorder" )
        [[ -n "$geometry" ]] && backend_cmd+=( "-g" "$geometry" )
        [[ -n "$codec"    ]] && backend_cmd+=( "-c" "$codec" )
        backend_cmd+=( "-r" "$fps" )
        [[ $audio -eq 1 ]] && backend_cmd+=( "-a" )
        backend_cmd+=( "-f" "$output_file" )
        shot_kv "Backend" "wf-recorder"

    else
        shot_fail "No screen recorder found"
        shot_info "Install: paru -S wl-screenrec  (recommended)"
        shot_info "Alternative: paru -S wf-recorder"
        return 1
    fi

    printf '\n'
    shot_ok "Recording started  →  press Ctrl+C or run: ash shot record --stop"
    shot_info "File: ${output_file}"
    printf '\n'

    # Notification
    shot_notify "🎬 Recording Started" \
        "${mode}  •  ${fps}fps  •  press --stop to finish" ""

    # Start recorder in background
    "${backend_cmd[@]}" &>/dev/null &
    local rec_pid=$!

    printf '%d\n' "$rec_pid" > "$_RECORD_PID_FILE"
    printf '%s\n' "$output_file" > "$_RECORD_FILE_FILE"

    shot_kv "PID" "$rec_pid"
    shot_info "Stop: ash shot record --stop"

    # Wait for Ctrl+C if running interactively
    if [[ -t 0 ]]; then
        trap '_record_stop_existing; exit 0' INT TERM
        wait "$rec_pid" 2>/dev/null || true
        rm -f "$_RECORD_PID_FILE" "$_RECORD_FILE_FILE"

        if [[ -f "$output_file" ]]; then
            local size dur
            size="$(du -sh "$output_file" 2>/dev/null | cut -f1)"
            shot_ok "Recording saved"
            shot_kv "File" "$output_file"
            shot_kv "Size" "$size"
            shot_log "$output_file" "record" "${mode}/${fps}fps"
            shot_notify "🎬 Recording Complete" "${output_file##*/}  •  ${size}" ""
        fi
    fi

    printf '\n'
}
