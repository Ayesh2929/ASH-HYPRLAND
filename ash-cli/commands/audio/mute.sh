#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  audio mute                                               ║
# ║  Mute/unmute/toggle sink and source with visual state indicator                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_AUD_MUTE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_AUD_MUTE_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_mute_animation() {
    local state="$1"  # muted | unmuted
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        if [[ "$state" == "muted" ]]; then
            local frames=( '🔊' '🔉' '🔈' '🔇' )
        else
            local frames=( '🔇' '🔈' '🔉' '🔊' )
        fi
        for frame in "${frames[@]}"; do
            printf '\r  %s  ' "$frame"
            sleep 0.08
        done
        printf '\r  %-10s\n' ""
    fi
}

ash_audio_mute() {
    local action="toggle"  # toggle | mute | unmute
    local target="sink"    # sink | source | both
    local quiet=0

    for arg in "${@:-}"; do
        case "$arg" in
            toggle|t)        action="toggle"  ;;
            mute|on|yes|1)   action="mute"    ;;
            unmute|off|no|0) action="unmute"  ;;
            source|-s)       target="source"  ;;
            both|-b)         target="both"    ;;
            --quiet|-q)      quiet=1          ;;
        esac
    done

    aud_section "🔇" "Mute Control" "$(_alav)"
    aud_kv "Backend" "$AUD_BACKEND"
    aud_kv "Target"  "$target"

    _mute_one() {
        local dev_sink="$1"  dev_label="$2"

        local was_muted=0
        aud_is_muted "$dev_sink" && was_muted=1

        case "$action" in
            toggle)
                aud_set_mute "toggle" "$dev_sink"
                aud_is_muted "$dev_sink" && new_state="muted" || new_state="unmuted"
                ;;
            mute)
                aud_set_mute "true" "$dev_sink"
                new_state="muted"
                ;;
            unmute)
                aud_set_mute "false" "$dev_sink"
                new_state="unmuted"
                ;;
        esac

        _mute_animation "$new_state"

        local state_badge
        if [[ "$new_state" == "muted" ]]; then
            state_badge="$(aud_badge " 🔇 MUTED " "$(_ared)")"
        else
            state_badge="$(aud_badge " 🔊 UNMUTED " "$(_agreen)")"
        fi

        aud_kv "$dev_label" "$state_badge"

        if [[ $quiet -eq 0 ]]; then
            local notif_icon
            [[ "$new_state" == "muted" ]] && notif_icon="🔇" || notif_icon="🔊"
            aud_notify "${notif_icon} Audio" "${dev_label}: ${new_state}"
        fi

        printf '%s' "$new_state"
    }

    local new_state=""

    case "$target" in
        sink)
            new_state="$(_mute_one "@DEFAULT_AUDIO_SINK@" "Sink")"
            ;;
        source)
            new_state="$(_mute_one "@DEFAULT_AUDIO_SOURCE@" "Source")"
            ;;
        both)
            _mute_one "@DEFAULT_AUDIO_SINK@"   "Sink"   &>/dev/null
            _mute_one "@DEFAULT_AUDIO_SOURCE@" "Source" &>/dev/null
            new_state="applied"
            aud_ok "Mute applied to both sink and source"
            ;;
    esac

    # Show current volume alongside mute state
    if [[ "$target" != "both" ]]; then
        local cur_vol
        cur_vol="$(aud_get_volume)"
        aud_kv "Volume" "${cur_vol}%"
    fi

    printf '\n'
}
