#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  shot timer                                               ║
# ║  Countdown timer with OSD overlay + animated progress arc before capture        ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_SHOT_TIMER_LOADED:-}" == "1" ]] && return 0
readonly _ASH_SHOT_TIMER_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_timer_osd_hyprctl() {
    local secs="$1"
    # Use hyprland dispatch to show message via hyprctl notify
    command -v hyprctl &>/dev/null || return 1
    [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && return 1
    hyprctl notify -1 "${secs}000" "rgb(cba6f7)" "📷 Screenshot in ${secs}s" \
        &>/dev/null 2>&1 || true
}

_timer_osd_notify() {
    local secs="$1"
    command -v notify-send &>/dev/null || return 1
    notify-send "📷 Screenshot Timer" \
        "Capturing in ${secs} seconds..." \
        --urgency=critical \
        --expire-time=$(( secs * 1000 )) \
        --icon=camera 2>/dev/null || true
}

_timer_terminal_countdown() {
    local total="$1"
    local mode="${2:-full}"

    # Arc characters for animation
    local arcs=( '◜' '◝' '◞' '◟' )
    local blocks=( '▁' '▂' '▃' '▄' '▅' '▆' '▇' '█' )

    printf '\n'

    for (( i=total; i>0; i-- )); do
        local arc_idx=$(( (total - i) % ${#arcs[@]} ))
        local bar_pct=$(( (total - i) * 100 / total ))
        local bar_filled=$(( bar_pct * 20 / 100 ))
        local bar_empty=$(( 20 - bar_filled ))

        # Progress bar
        local bar="${_smauve}$(printf '█%.0s' $(seq 1 $bar_filled))${_sdim}$(printf '░%.0s' $(seq 1 $bar_empty))${_sr}"

        printf '\r  %s%s%s  %s%s%d%s seconds  %s[%s]%s  %s%s%s  ' \
            "$(_smauve)" "${arcs[$arc_idx]}" "$(_sr)" \
            "$(_sbold)$(_syellow)" "" "$i" "$(_sr)" \
            "$(_sdim)" "$(printf '%s%s%s%s%s' "$(_smauve)" "$(printf '█%.0s' $(seq 1 $bar_filled))" "$(_sdim)" "$(printf '░%.0s' $(seq 1 $bar_empty))" "$(_sr)")" "$(_sdim)" \
            "$(_sdim)" "capturing: ${mode}" "$(_sr)"

        sleep 1
    done

    printf '\r  %s📸 Capturing!%-40s%s\n' "$(_sgreen)" " " "$(_sr)"
    sleep 0.1
}

ash_shot_timer() {
    local delay="${ASH_SHOT_DELAY:-5}"
    local mode="full"   # full | area | window

    for arg in "${@:-}"; do
        case "$arg" in
            --delay=*|-d=*) delay="${arg#*=}" ;;
            --area|-a)      mode="area"       ;;
            --window|-w)    mode="window"     ;;
            --full|-f)      mode="full"       ;;
            [0-9]*)         delay="$arg"      ;;
        esac
    done

    shot_section "⏱️ " "Timer Screenshot" "$(_steal)"

    shot_kv "Delay"   "${delay}s"
    shot_kv "Mode"    "$mode"

    # OSD notification
    _timer_osd_notify "$delay" &>/dev/null &
    _timer_osd_hyprctl "$delay" &>/dev/null &

    # Terminal countdown
    _timer_terminal_countdown "$delay" "$mode"

    # Trigger capture
    local out_file
    case "$mode" in
        area)
            export ASH_SHOT_DELAY=0
            _shot_load_sub area 2>/dev/null
            ash_shot_area
            ;;
        window)
            export ASH_SHOT_DELAY=0
            _shot_load_sub window 2>/dev/null
            ash_shot_window
            ;;
        full|*)
            out_file="$(shot_filename "timer" "${ASH_SHOT_FORMAT:-png}")"
            if command -v grim &>/dev/null; then
                grim "$out_file" 2>/dev/null
            fi

            if [[ -f "$out_file" ]]; then
                local size
                size="$(du -sh "$out_file" 2>/dev/null | cut -f1)"
                shot_ok "Timer screenshot saved"
                shot_kv "File" "$out_file"
                shot_kv "Size" "$size"

                [[ "${ASH_SHOT_CLIPBOARD:-0}" -eq 1 ]] && \
                    shot_copy_to_clipboard "$out_file"

                shot_log "$out_file" "timer" "${delay}s"
                shot_notify "⏱️  Timer Screenshot" "${delay}s delay  •  ${size}" "$out_file"
            fi
            ;;
    esac

    printf '\n'
}
