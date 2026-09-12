#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  window move                                              ║
# ║  Move active window: absolute coords / edges / workspaces / monitor             ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WIN_MOVE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WIN_MOVE_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_move_animation() {
    local from_x="$1" from_y="$2" to_x="$3" to_y="$4"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        local steps=6
        for (( i=0; i<=steps; i++ )); do
            local cur_x=$(( from_x + (to_x - from_x) * i / steps ))
            local cur_y=$(( from_y + (to_y - from_y) * i / steps ))
            printf '\r  %s📦%s  Moving: %s(%d, %d)%s  ' \
                "$(_wpeach)" "$(_wr)" "$(_wsky)" "$cur_x" "$cur_y" "$(_wr)"
            sleep 0.05
        done
        printf '\r  %-60s\n' ""
    fi
}

ash_win_move() {
    local x=""  y=""  edge=""  workspace=""  monitor=""  delta=0

    for arg in "${@:-}"; do
        case "$arg" in
            --edge=*)      edge="${arg#*=}"       ;;
            --workspace=*) workspace="${arg#*=}"  ;;
            --monitor=*)   monitor="${arg#*=}"    ;;
            --delta|-d)    delta=1                ;;
            center|c)      edge="center"          ;;
            left|right|up|down|tl|tr|bl|br) edge="$arg" ;;
            [+-]?[0-9]*)
                [[ -z "$x" ]] && x="$arg" || y="$arg" ;;
            [0-9]*)
                [[ -z "$x" ]] && x="$arg" || y="$arg" ;;
        esac
    done

    win_section "📦" "Move Window" "$(_wpeach)"

    local cur_x cur_y cur_w cur_h
    local active_json
    active_json="$(win_get_active_json)"
    read -r cur_x cur_y cur_w cur_h < <(python3 -c "
import json, sys
d = json.loads('''${active_json//\'/\'\\\'\'}''')
at = d.get('at',[0,0])
sz = d.get('size',[100,100])
print(at[0], at[1], sz[0], sz[1])
" 2>/dev/null || echo "0 0 100 100")

    win_kv "Current pos"  "(${cur_x}, ${cur_y})"

    # Handle edge positioning
    if [[ -n "$edge" ]]; then
        win_kv "Edge" "$edge"

        # Get monitor resolution
        local mon_w mon_h
        read -r mon_w mon_h < <(hyprctl monitors -j 2>/dev/null | python3 -c "
import json, sys
mons = json.load(sys.stdin)
m = next((m for m in mons if m.get('focused')), mons[0] if mons else {})
print(m.get('width',1920), m.get('height',1080))
" 2>/dev/null || echo "1920 1080")

        local gap=20
        case "$edge" in
            left)   x=$gap;                          y=$(( (mon_h - cur_h) / 2 )) ;;
            right)  x=$(( mon_w - cur_w - gap ));    y=$(( (mon_h - cur_h) / 2 )) ;;
            up)     x=$(( (mon_w - cur_w) / 2 ));    y=$gap ;;
            down)   x=$(( (mon_w - cur_w) / 2 ));    y=$(( mon_h - cur_h - gap )) ;;
            tl)     x=$gap;                          y=$gap ;;
            tr)     x=$(( mon_w - cur_w - gap ));    y=$gap ;;
            bl)     x=$gap;                          y=$(( mon_h - cur_h - gap )) ;;
            br)     x=$(( mon_w - cur_w - gap ));    y=$(( mon_h - cur_h - gap )) ;;
            center) x=$(( (mon_w - cur_w) / 2 ));   y=$(( (mon_h - cur_h) / 2 )) ;;
        esac
    fi

    # Move to workspace
    if [[ -n "$workspace" ]]; then
        win_kv "Workspace" "$workspace"
        win_dispatch movetoworkspace "$workspace"
        win_ok "Moved to workspace: ${workspace}"
        win_notify "📦 Moved" "Window → workspace ${workspace}"
        printf '\n'; return 0
    fi

    # Move to monitor
    if [[ -n "$monitor" ]]; then
        win_kv "Monitor" "$monitor"
        win_dispatch movecurrentworkspacetomonitor "$monitor"
        win_ok "Moved to monitor: ${monitor}"
        printf '\n'; return 0
    fi

    # Coordinate move
    [[ -z "$x" ]] && x="$cur_x"
    [[ -z "$y" ]] && y="$cur_y"

    win_kv "Target pos" "(${x}, ${y})"
    _move_animation "$cur_x" "$cur_y" "$x" "$y"

    if [[ $delta -eq 1 ]]; then
        win_dispatch movewindow "exact $x $y"
    else
        win_dispatch movewindowpixel "exact $x $y, address:$(win_get_active_field address)"
    fi

    win_ok "Window moved to (${x}, ${y})"
    win_notify "📦 Moved" "→ (${x}, ${y})"
    printf '\n'
}
