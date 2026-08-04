#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  shot gif                                                 ║
# ║  Record and convert to optimised animated GIF via ffmpeg + gifsicle             ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_SHOT_GIF_LOADED:-}" == "1" ]] && return 0
readonly _ASH_SHOT_GIF_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_gif_frames_to_gif() {
    local input_mp4="$1"  output_gif="$2"  fps="${3:-10}"  scale="${4:-720}"

    shot_step "Converting video to GIF  (fps=${fps}  scale=${scale}px)..."

    # Two-pass palette generation for quality
    local palette="${_SHOT_TMP}/palette-$$.png"

    ffmpeg -y -i "$input_mp4" \
        -vf "fps=${fps},scale=${scale}:-1:flags=lanczos,palettegen=stats_mode=diff" \
        -loglevel error \
        "$palette" 2>/dev/null && \

    ffmpeg -y -i "$input_mp4" -i "$palette" \
        -lavfi "fps=${fps},scale=${scale}:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5" \
        -loglevel error \
        "$output_gif" 2>/dev/null

    rm -f "$palette"

    # Optimize with gifsicle if available
    if command -v gifsicle &>/dev/null && [[ -f "$output_gif" ]]; then
        shot_step "Optimising GIF with gifsicle..."
        local before_size
        before_size="$(du -sb "$output_gif" 2>/dev/null | cut -f1)"
        gifsicle -b -O3 --colors 256 "$output_gif" 2>/dev/null || true
        local after_size
        after_size="$(du -sb "$output_gif" 2>/dev/null | cut -f1)"
        if (( before_size > after_size )); then
            local saved=$(( (before_size - after_size) * 100 / before_size ))
            shot_ok "Gifsicle saved ${saved}% size reduction"
        fi
    fi
}

ash_shot_gif() {
    local duration=5
    local fps=10
    local scale=720
    local mode="area"

    for arg in "${@:-}"; do
        case "$arg" in
            --duration=*|-d=*) duration="${arg#*=}" ;;
            --fps=*)           fps="${arg#*=}"      ;;
            --scale=*)         scale="${arg#*=}"    ;;
            --full|-f)         mode="full"          ;;
        esac
    done

    shot_section "🎞️ " "Animated GIF Recorder" "$(_smauve)"

    shot_require ffmpeg ffmpeg || return 1
    shot_check_wayland || return 1

    shot_kv "Duration"  "${duration}s"
    shot_kv "FPS"       "$fps"
    shot_kv "Scale"     "${scale}px wide"
    shot_kv "Mode"      "$mode"

    # Select area
    local geometry=""
    if [[ "$mode" == "area" ]]; then
        shot_info "Select area to record as GIF..."
        if command -v slurp &>/dev/null; then
            geometry="$(slurp \
                -b "1e1e2eCC" -c "cba6f7FF" -s "cba6f740" -w 2 \
                2>/dev/null)" || {
                shot_info "Selection cancelled"
                return 0
            }
        fi
    fi

    local tmp_video="${_SHOT_TMP}/gif-raw-$$.mp4"
    local output_file
    output_file="$(shot_filename "animation" "gif")"

    # Record video
    shot_step "Recording for ${duration}s..."

    local -a rec_cmd=()

    if command -v wf-recorder &>/dev/null; then
        rec_cmd=( "wf-recorder" )
        [[ -n "$geometry" ]] && rec_cmd+=( "-g" "$geometry" )
        rec_cmd+=( "-r" "$fps" "-f" "$tmp_video" )
    else
        shot_fail "wf-recorder required for GIF recording"
        shot_info "Install: paru -S wf-recorder"
        return 1
    fi

    # Countdown
    for (( i=3; i>0; i-- )); do
        printf '\r  %s🎞️   Starting in %s%d%s...%s  ' \
            "$(_syellow)" "$(_sbold)" "$i" "$(_sr)$(_syellow)" "$(_sr)"
        sleep 1
    done
    printf '\r  %-50s\n' ""

    # Record with timeout
    shot_step "Recording..."
    timeout "$duration" "${rec_cmd[@]}" &>/dev/null || true

    if [[ ! -f "$tmp_video" ]]; then
        shot_fail "Recording failed"
        return 1
    fi

    # Convert to GIF
    _gif_frames_to_gif "$tmp_video" "$output_file" "$fps" "$scale"
    rm -f "$tmp_video"

    if [[ ! -f "$output_file" ]]; then
        shot_fail "GIF conversion failed"
        return 1
    fi

    local size
    size="$(du -sh "$output_file" 2>/dev/null | cut -f1)"
    shot_ok "GIF created"
    shot_kv "File" "$output_file"
    shot_kv "Size" "$size"

    [[ "${ASH_SHOT_CLIPBOARD:-0}" -eq 1 ]] && shot_copy_to_clipboard "$output_file"
    [[ "${ASH_SHOT_UPLOAD:-0}" -eq 1 ]]    && ash_shot_upload "$output_file"

    shot_log "$output_file" "gif" "${duration}s/${fps}fps"
    shot_notify "🎞️  GIF Ready" "${output_file##*/}  •  ${size}" "$output_file"

    printf '\n'
}
