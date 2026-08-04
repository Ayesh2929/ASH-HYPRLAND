#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  window pin                                               ║
# ║  Pin/unpin active window to appear on all workspaces                            ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WIN_PIN_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WIN_PIN_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_pin_animation() {
    local pinning="$1"  # 1=pinning 0=unpinning
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        if [[ $pinning -eq 1 ]]; then
            local frames=( '📌' '📌' '🔒' '🔒' '📌' )
        else
            local frames=( '📌' '🔓' '  ' '  ' '🔓' )
        fi
        for frame in "${frames[@]}"; do
            printf '\r  %s  %s...' "$frame" "$([ $pinning -eq 1 ] && echo 'Pinning' || echo 'Unpinning')"
            sleep 0.1
        done
        printf '\r  %-40s\n' ""
    fi
}

ash_win_pin() {
    local force_state=""  # on | off | ""=toggle

    for arg in "${@:-}"; do
        case "$arg" in
            on|pin|1)       force_state="on"  ;;
            off|unpin|0)    force_state="off" ;;
        esac
    done

    win_section "📌" "Pin Window" "$(_wyellow)"

    local active_json
    active_json="$(win_get_active_json)"
    local title cls is_pinned
    title="$(    python3 -c "import json; d=json.loads('''${active_json//\'/\'\\\'\'}'''); print(d.get('title','?')[:50])" 2>/dev/null)"
    cls="$(      python3 -c "import json; d=json.loads('''${active_json//\'/\'\\\'\'}'''); print(d.get('class','?'))" 2>/dev/null)"
    is_pinned="$(python3 -c "import json; d=json.loads('''${active_json//\'/\'\\\'\'}'''); print(d.get('pinned',False))" 2>/dev/null)"

    win_kv "Window"    "${cls}: ${title}"
    win_kv "Pinned"    "$([[ "$is_pinned" == "True" ]] && echo 'yes' || echo 'no')"

    # Determine action
    local action
    if [[ -n "$force_state" ]]; then
        action="$force_state"
    else
        # Toggle
        [[ "$is_pinned" == "True" ]] && action="off" || action="on"
    fi

    if [[ "$action" == "on" ]] && [[ "$is_pinned" == "True" ]]; then
        win_info "Window is already pinned"
        printf '\n'; return 0
    fi

    if [[ "$action" == "off" ]] && [[ "$is_pinned" == "False" ]]; then
        win_info "Window is not pinned"
        printf '\n'; return 0
    fi

    local pinning=1
    [[ "$action" == "off" ]] && pinning=0

    _pin_animation $pinning

    win_dispatch pin

    if [[ $pinning -eq 1 ]]; then
        win_ok "Window pinned to all workspaces"
        win_kv "Effect" "$(win_badge " 📌 PINNED " "$(_wyellow)")"
        win_notify "📌 Pinned" "${cls}: window visible on all workspaces"
    else
        win_ok "Window unpinned"
        win_kv "Effect" "$(win_badge " UNPINNED " "$(_wdim)")"
        win_notify "📌 Unpinned" "${cls}"
    fi

    printf '\n'
}
