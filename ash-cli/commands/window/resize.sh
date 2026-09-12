#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  window resize                                            ║
# ║  Resize active window: absolute / delta / preset sizes / interactive            ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WIN_RESIZE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WIN_RESIZE_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_resize_animation() {
    local from_w="$1"  from_h="$2"  to_w="$3"  to_h="$4"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        local steps=5
        for (( i=0; i<=steps; i++ )); do
            local cur_w=$(( from_w + (to_w - from_w) * i / steps ))
            local cur_h=$(( from_h + (to_h - from_h) * i / steps ))
            local bar_w=$(( cur_w / 40 ))
            local bar_h=$(( cur_h / 40 ))
            (( bar_w < 1 )) && bar_w=1
            (( bar_h < 1 )) && bar_h=1
            printf '\r  %s📐%s  %s%d×%d%s  [%s%s%s]  ' \
                "$(_wmauve)" "$(_wr)" \
                "$(_wsky)$(_wbold)" "$cur_w" "$cur_h" "$(_wr)" \
                "$(_wmauve)" "$(printf '█%.0s' $(seq 1 $bar_w))" "$(_wr)"
            sleep 0.06
        done
        printf '\r  %-60s\n' ""
    fi
}

declare -gA _RESIZE_PRESETS=(
    [small]="640 480"
    [medium]="1280 720"
    [large]="1600 900"
    [hd]="1920 1080"
    [2k]="2560 1440"
    [4k]="3840 2160"
    [ultrawide]="2560 1080"
    [terminal]="900 600"
    [editor]="1400 900"
    [browser]="1366 768"
    [half-h]="960 1080"
    [half-v]="1920 540"
    [third]="640 1080"
    [quarter]="960 540"
)

ash_win_resize() {
    local width=""  height=""  preset=""  delta=0
    local dw=""  dh=""

    for arg in "${@:-}"; do
        case "$arg" in
            --preset=*|-p=*) preset="${arg#*=}"   ;;
            --delta|-d)      delta=1               ;;
            [0-9]*)
                [[ -z "$width"  ]] && width="$arg" || height="$arg" ;;
            [+-][0-9]*)
                [[ -z "$dw" ]] && dw="$arg" || dh="$arg"
                delta=1
                ;;
            small|medium|large|hd|2k|4k|ultrawide|terminal|editor|browser|\
            half-h|half-v|third|quarter)
                preset="$arg" ;;
        esac
    done

    win_section "📐" "Resize Window" "$(_wmauve)"

    # Get current size
    local active_json cur_w cur_h
    active_json="$(win_get_active_json)"
    read -r cur_w cur_h < <(python3 -c "
import json; d=json.loads('''${active_json//\'/\'\\\'\'}''')
s=d.get('size',[1280,720]); print(s[0],s[1])
" 2>/dev/null || echo "1280 720")

    win_kv "Current size" "${cur_w}×${cur_h}"

    # Preset
    if [[ -n "$preset" ]]; then
        local preset_val="${_RESIZE_PRESETS[$preset]:-}"
        if [[ -z "$preset_val" ]]; then
            win_fail "Unknown preset: ${preset}"
            printf '\n  %sAvailable presets:%s\n' "$(_wdim)" "$(_wr)"
            for p in "${!_RESIZE_PRESETS[@]}"; do
                local dims="${_RESIZE_PRESETS[$p]}"
                printf '    %s%-12s%s  %s%s%s\n' \
                    "$(_wsky)" "$p" "$(_wr)" \
                    "$(_wdim)" "${dims/ /×}" "$(_wr)"
            done | sort
            printf '\n'; return 1
        fi
        read -r width height <<< "$preset_val"
        win_kv "Preset" "${preset}  (${width}×${height})"
    fi

    # Delta resize
    if [[ $delta -eq 1 ]] && [[ -n "$dw" || -n "$dh" ]]; then
        [[ -z "$dw" ]] && dw=0
        [[ -z "$dh" ]] && dh=0
        win_kv "Delta" "${dw}×${dh}"
        win_dispatch resizeactive "$dw $dh"
        win_ok "Window resized by (${dw}, ${dh})"
        printf '\n'; return 0
    fi

    # Interactive size input if nothing given
    if [[ -z "$width" ]]; then
        printf '\n  %sPresets: %s\n' "$(_wdim)" \
            "$(printf '%s ' "${!_RESIZE_PRESETS[@]}" | sort | head -c 80)"
        printf '  %sWidth [%d]: %s' "$(_wyellow)" "$cur_w" "$(_wr)"
        read -r width
        [[ -z "$width" ]] && width="$cur_w"
        printf '  %sHeight [%d]: %s' "$(_wyellow)" "$cur_h" "$(_wr)"
        read -r height
        [[ -z "$height" ]] && height="$cur_h"
    fi

    [[ -z "$height" ]] && height="$cur_h"

    win_kv "New size" "${width}×${height}"
    _resize_animation "$cur_w" "$cur_h" "$width" "$height"

    win_dispatch resizewindowpixel "exact $width $height, address:$(win_get_active_field address)"
    win_ok "Window resized to ${width}×${height}"
    win_notify "📐 Resized" "${width}×${height}"
    printf '\n'
}
