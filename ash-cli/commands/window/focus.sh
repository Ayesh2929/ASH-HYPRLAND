#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  window focus                                             ║
# ║  Smart window focusing: class / title / address / direction / recent            ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WIN_FOCUS_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WIN_FOCUS_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_focus_animation() {
    local name="$1"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        local frames=( '◎' '◉' '●' '◉' '◎' )
        for frame in "${frames[@]}"; do
            printf '\r  %s%s%s  %sFocusing: %s%s%s' \
                "$(_wblue)" "$frame" "$(_wr)" \
                "$(_wdim)" "$(_wsky)$(_wbold)" "$name" "$(_wr)"
            sleep 0.08
        done
        printf '\r  %-60s\n' ""
    fi
}

ash_win_focus() {
    local target=""  direction=""  by_address=0

    for arg in "${@:-}"; do
        case "$arg" in
            left|right|up|down|l|r|u|d) direction="$arg" ;;
            --address=*) target="${arg#*=}"; by_address=1 ;;
            --next|-n)   direction="next"  ;;
            --prev|-p)   direction="prev"  ;;
            *)           [[ -z "$target" ]] && target="$arg" ;;
        esac
    done

    win_section "🎯" "Focus Window" "$(_wpeach)"

    # Direction-based focus
    if [[ -n "$direction" ]]; then
        win_kv "Direction" "$direction"

        local dispatch_dir
        case "$direction" in
            left|l)  dispatch_dir="l" ;;
            right|r) dispatch_dir="r" ;;
            up|u)    dispatch_dir="u" ;;
            down|d)  dispatch_dir="d" ;;
            next)    win_dispatch cyclenext; win_ok "Focused next window"; printf '\n'; return 0 ;;
            prev)    win_dispatch cyclenext prev; win_ok "Focused prev window"; printf '\n'; return 0 ;;
        esac

        win_dispatch movefocus "$dispatch_dir"
        win_ok "Moved focus: ${direction}"
        printf '\n'; return 0
    fi

    # Interactive picker if no target
    if [[ -z "$target" ]]; then
        target="$(win_pick_window "Focus window")"
        by_address=1
    fi

    [[ -z "$target" ]] && { win_info "No target specified"; printf '\n'; return 0; }

    if [[ $by_address -eq 1 ]]; then
        # Focus by hex address
        win_kv "Address" "$target"
        _focus_animation "$target"
        win_dispatch focuswindow "address:${target}" && \
            win_ok "Window focused" || win_fail "Focus failed"
    else
        # Focus by class or title (fuzzy)
        win_kv "Query"   "$target"

        # Find matching window address
        local match_addr
        match_addr="$(win_get_clients_json | python3 -c "
import json, sys
clients = json.load(sys.stdin)
query = '${target}'.lower()
for c in clients:
    if (query in c.get('class','').lower() or
        query in c.get('title','').lower()):
        print(c.get('address',''))
        break
" 2>/dev/null)"

        if [[ -z "$match_addr" ]]; then
            win_fail "No window matching: ${target}"
            printf '\n'; return 1
        fi

        local match_name
        match_name="$(win_get_clients_json | python3 -c "
import json, sys
clients = json.load(sys.stdin)
query = '${target}'.lower()
for c in clients:
    if (query in c.get('class','').lower() or
        query in c.get('title','').lower()):
        print(c.get('class','?'), '-', c.get('title','?')[:30])
        break
" 2>/dev/null)"

        win_kv "Match" "$match_name"
        _focus_animation "$match_name"
        win_dispatch focuswindow "address:${match_addr}" && \
            win_ok "Window focused: ${match_name}" || \
            win_fail "Focus failed"
    fi

    win_notify "🎯 Focused" "$target"
    printf '\n'
}
