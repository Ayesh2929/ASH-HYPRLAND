#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  audio volume                                             ║
# ║  Get/set/increment/decrement volume with animated OSD bar and safe-clamping     ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_AUD_VOLUME_LOADED:-}" == "1" ]] && return 0
readonly _ASH_AUD_VOLUME_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  VOLUME BAR RENDERER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_vol_bar() {
    local pct="$1"  width="${2:-40}"  animate="${3:-0}"
    local filled=$(( pct * width / 100 ))
    (( filled > width )) && filled=$width
    local empty=$(( width - filled ))

    # Colour tiers
    local bc
    if   (( pct >= 100 )); then bc="$(_ared)"
    elif (( pct >= 80  )); then bc="$(_ayellow)"
    elif (( pct >= 40  )); then bc="$(_agreen)"
    else                        bc="$(_ablue)"
    fi

    # Volume icon
    local icon
    if   aud_is_muted 2>/dev/null; then icon="🔇"
    elif (( pct == 0  )); then icon="🔇"
    elif (( pct < 33  )); then icon="🔈"
    elif (( pct < 66  )); then icon="🔉"
    else                       icon="🔊"
    fi

    if [[ $animate -eq 1 ]] && [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        # Animated fill
        printf '\n  %s  [' "$icon"
        for (( i=1; i<=filled; i++ )); do
            printf '%s█%s' "$bc" "$(_ar)"
            sleep 0.015
        done
        printf '%s%s%s' "$(_adim)" "$(printf '░%.0s' $(seq 1 $empty))" "$(_ar)"
        printf ']  %s%s%d%%%s\n\n' "$(_abold)" "$bc" "$pct" "$(_ar)"
    else
        printf '\n  %s  %s[%s%s%s%s%s]%s  %s%s%d%%%s\n\n' \
            "$icon" \
            "$(_adim)" "$(_ar)" \
            "$bc" "$(printf '█%.0s' $(seq 1 $filled))" \
            "$(_adim)" "$(printf '░%.0s' $(seq 1 $empty))" "$(_ar)" \
            "$(_abold)" "$bc" "$pct" "$(_ar)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  VOLUME SPARKLINE HISTORY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _VOL_HISTORY_FILE="${_AUD_STATE_DIR}/volume-history.dat"
declare -gi _VOL_HISTORY_MAX=40

_vol_log_history() {
    local pct="$1"
    printf '%s\n' "$pct" >> "$_VOL_HISTORY_FILE" 2>/dev/null || true
    # Trim to last N
    if [[ -f "$_VOL_HISTORY_FILE" ]]; then
        local lines
        lines="$(wc -l < "$_VOL_HISTORY_FILE" 2>/dev/null || echo 0)"
        if (( lines > _VOL_HISTORY_MAX )); then
            tail -"$_VOL_HISTORY_MAX" "$_VOL_HISTORY_FILE" > \
                "${_VOL_HISTORY_FILE}.tmp" && \
                mv "${_VOL_HISTORY_FILE}.tmp" "$_VOL_HISTORY_FILE" 2>/dev/null || true
        fi
    fi
}

_vol_sparkline() {
    [[ -f "$_VOL_HISTORY_FILE" ]] || return 0
    local -a vals=()
    mapfile -t vals < "$_VOL_HISTORY_FILE"
    [[ ${#vals[@]} -eq 0 ]] && return 0

    local blocks=( '▁' '▂' '▃' '▄' '▅' '▆' '▇' '█' )
    local spark=""
    for v in "${vals[@]}"; do
        local idx=$(( v * 7 / 100 ))
        (( idx > 7 )) && idx=7
        spark+="${blocks[$idx]}"
    done

    printf '  %sHistory:%s  %s%s%s\n' \
        "$(_adim)" "$(_ar)" "$(_ablue)" "$spark" "$(_ar)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_audio_volume() {
    local target=""  sink="@DEFAULT_AUDIO_SINK@"
    local source_mode=0  max_vol=150  animate=1  quiet=0

    for arg in "${@:-}"; do
        case "$arg" in
            --source|-s)    source_mode=1; sink="@DEFAULT_AUDIO_SOURCE@" ;;
            --sink=*)       sink="${arg#*=}"   ;;
            --max=*)        max_vol="${arg#*=}" ;;
            --no-animate)   animate=0          ;;
            --quiet|-q)     quiet=1            ;;
            *)              target="$arg"      ;;
        esac
    done

    aud_section "🔉" "Volume Control" "$(_apeach)"

    local current_vol
    current_vol="$(aud_get_volume "$sink")"
    current_vol="${current_vol:-0}"

    # GET mode
    if [[ -z "$target" ]]; then
        aud_kv "Backend" "$AUD_BACKEND"
        aud_kv "Sink"    "$sink"
        aud_kv "Volume"  "${current_vol}%"
        aud_is_muted "$sink" && \
            aud_kv "Muted" "$(aud_badge " MUTED " "$(_ared)")" || \
            aud_kv "Muted" "no"
        _vol_bar "$current_vol" 36
        _vol_sparkline
        printf '\n'
        return 0
    fi

    # SET / ADJUST mode
    local new_vol

    if [[ "$target" =~ ^\+[0-9]+$ ]]; then
        # Increase
        new_vol=$(( current_vol + ${target#+} ))
    elif [[ "$target" =~ ^-[0-9]+$ ]]; then
        # Decrease
        new_vol=$(( current_vol - ${target#-} ))
    elif [[ "$target" =~ ^[0-9]+%?$ ]]; then
        # Absolute
        new_vol="${target%\%}"
    else
        aud_fail "Invalid volume: ${target}  (use: 65, +10, -5)"
        return 1
    fi

    # Clamp
    (( new_vol < 0   )) && new_vol=0
    (( new_vol > max_vol )) && new_vol=$max_vol

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        printf '{"volume":%d,"previous":%d,"muted":false}\n' "$new_vol" "$current_vol"
        aud_set_volume "$new_vol" "$sink"
        return 0
    fi

    aud_kv "Previous" "${current_vol}%"
    aud_kv "New"      "${new_vol}%"

    # Delta indicator
    local delta=$(( new_vol - current_vol ))
    if (( delta > 0 )); then
        aud_kv "Change" "${_agreen}+${delta}%${_ar}"
    elif (( delta < 0 )); then
        aud_kv "Change" "${_ared}${delta}%${_ar}"
    else
        aud_kv "Change" "no change"
    fi

    aud_set_volume "$new_vol" "$sink"
    _vol_log_history "$new_vol"

    _vol_bar "$new_vol" 36 "$animate"
    _vol_sparkline

    [[ $quiet -eq 0 ]] && \
        aud_notify "🔉 Volume" "${new_vol}%" "$new_vol"

    printf '\n'
}
