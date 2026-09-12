#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  window float                                             ║
# ║  Toggle/set float mode with optional center/corner positioning                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WIN_FLOAT_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WIN_FLOAT_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_float_animation() {
    local floating="$1"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        if [[ $floating -eq 1 ]]; then
            local frames=( '▭' '◱' '◰' '🎈' )
        else
            local frames=( '🎈' '◰' '◱' '▭' )
        fi
        for frame in "${frames[@]}"; do
            printf '\r  %s%s%s  %s...' \
                "$(_wpeach)" "$frame" "$(_wr)" \
                "$([ $floating -eq 1 ] && echo 'Floating' || echo 'Tiling')"
            sleep 0.1
        done
        printf '\r  %-40s\n' ""
    fi
}

ash_win_float() {
    local force_state=""  center_after=0  position=""
    local w=""  h=""

    for arg in "${@:-}"; do
        case "$arg" in
            on|float|1)       force_state="on"     ;;
            off|tile|tiled|0) force_state="off"    ;;
            toggle|t)         force_state="toggle"  ;;
            --center|-c)      center_after=1        ;;
            --pos=*)          position="${arg#*=}"  ;;
            [0-9]*x[0-9]*)
                w="${arg%%x*}"
                h="${arg##*x}"
                ;;
        esac
    done

    win_section "🎈" "Float Window" "$(_wpeach)"

    local active_json
    active_json="$(win_get_active_json)"
    local title cls is_floating cur_w cur_h cur_x cur_y
    title="$(      python3 -c "import json; d=json.loads('''${active_json//\'/\'\\\'\'}'''); print(d.get('title','?')[:50])" 2>/dev/null)"
    cls="$(        python3 -c "import json; d=json.loads('''${active_json//\'/\'\\\'\'}'''); print(d.get('class','?'))" 2>/dev/null)"
    is_floating="$(python3 -c "import json; d=json.loads('''${active_json//\'/\'\\\'\'}'''); print(d.get('floating',False))" 2>/dev/null)"
    read -r cur_w cur_h cur_x cur_y < <(python3 -c "
import json; d=json.loads('''${active_json//\'/\'\\\'\'}''')
s=d.get('size',[800,600]); a=d.get('at',[0,0])
print(s[0],s[1],a[0],a[1])
" 2>/dev/null || echo "800 600 0 0")

    win_kv "Window"   "${cls}: ${title}"
    win_kv "Floating" "$([[ "$is_floating" == "True" ]] && echo 'yes' || echo 'no')"

    # Determine action
    local action
    if [[ -n "$force_state" ]]; then
        [[ "$force_state" == "toggle" ]] && action="toggle" || action="$force_state"
    else
        action="toggle"
    fi

    local will_float
    if [[ "$action" == "toggle" ]]; then
        [[ "$is_floating" == "True" ]] && will_float=0 || will_float=1
    elif [[ "$action" == "on" ]]; then
        will_float=1
    else
        will_float=0
    fi

    _float_animation $will_float

    case "$action" in
        toggle) win_dispatch togglefloating ;;
        on)
            [[ "$is_floating" != "True" ]] && win_dispatch togglefloating
            ;;
        off)
            [[ "$is_floating" == "True" ]] && win_dispatch togglefloating
            ;;
    esac

    # Resize if dimensions given
    if [[ $will_float -eq 1 ]] && [[ -n "$w" ]] && [[ -n "$h" ]]; then
        sleep 0.1
        win_dispatch resizewindowpixel "exact $w $h, address:$(win_get_active_field address)"
        win_kv "Size" "${w}×${h}"
    fi

    # Center after floating
    if [[ $will_float -eq 1 ]] && [[ $center_after -eq 1 ]]; then
        sleep 0.1
        win_dispatch centerwindow
        win_kv "Position" "centered"
    elif [[ $will_float -eq 1 ]] && [[ -n "$position" ]]; then
        sleep 0.1
        local pos_x pos_y
        IFS=',' read -r pos_x pos_y <<< "$position"
        win_dispatch movewindowpixel "exact $pos_x $pos_y, address:$(win_get_active_field address)"
        win_kv "Position" "(${pos_x}, ${pos_y})"
    fi

    if [[ $will_float -eq 1 ]]; then
        win_ok "Window is now floating"
        win_kv "State" "$(win_badge " 🎈 FLOATING " "$(_wpeach)")"
        win_notify "🎈 Floating" "${cls}"
    else
        win_ok "Window is now tiled"
        win_kv "State" "$(win_badge " TILED " "$(_wdim)")"
        win_notify "🎈 Tiled" "${cls}"
    fi

    printf '\n'
}
