#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  window close                                             ║
# ║  Close windows: active / by class / by address / all in workspace / kill        ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WIN_CLOSE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WIN_CLOSE_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_close_animation() {
    local name="$1"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        local frames=( '✕' '✗' '×' ' ' )
        for frame in "${frames[@]}"; do
            printf '\r  %s%s%s  %sClosing: %s%s' \
                "$(_wred)" "$frame" "$(_wr)" \
                "$(_wdim)" "$name" "$(_wr)"
            sleep 0.1
        done
        printf '\r  %-60s\n' ""
    fi
}

ash_win_close() {
    local target=""  kill_mode=0  all_class=0  workspace_all=0

    for arg in "${@:-}"; do
        case "$arg" in
            --kill|-k)       kill_mode=1    ;;
            --all-class|-a)  all_class=1    ;;
            --workspace|-ws) workspace_all=1 ;;
            --address=*)     target="${arg#*=}" ;;
            *)               [[ -z "$target" ]] && target="$arg" ;;
        esac
    done

    win_section "✕" "Close Window" "$(_wred)"

    # Close all in current workspace
    if [[ $workspace_all -eq 1 ]]; then
        local ws_name
        ws_name="$(win_get_active_field "workspace.name")"
        win_kv "Workspace" "$ws_name"

        local -a addrs=()
        mapfile -t addrs < <(win_get_clients_json | python3 -c "
import json, sys
clients = json.load(sys.stdin)
ws = '${ws_name}'
for c in clients:
    if c.get('workspace',{}).get('name') == ws:
        print(c.get('address',''))
" 2>/dev/null)

        win_kv "Count" "${#addrs[@]} windows"

        if [[ "${ASH_FLAG_YES:-0}" -ne 1 ]]; then
            printf '  %sClose %d windows in workspace %s? [y/N] %s' \
                "$(_wyellow)" "${#addrs[@]}" "$ws_name" "$(_wr)"
            local ans; read -r ans
            [[ "${ans,,}" != "y" ]] && { win_info "Cancelled"; printf '\n'; return 0; }
        fi

        for addr in "${addrs[@]}"; do
            [[ -z "$addr" ]] && continue
            if [[ $kill_mode -eq 1 ]]; then
                win_dispatch closewindow "address:${addr}"
            else
                win_dispatch closewindow "address:${addr}"
            fi
        done

        win_ok "Closed ${#addrs[@]} windows in workspace ${ws_name}"
        printf '\n'; return 0
    fi

    # Close all windows of same class
    if [[ $all_class -eq 1 ]] && [[ -n "$target" ]]; then
        local -a class_addrs=()
        mapfile -t class_addrs < <(win_get_clients_json | python3 -c "
import json, sys
clients = json.load(sys.stdin)
query = '${target}'.lower()
for c in clients:
    if query in c.get('class','').lower():
        print(c.get('address',''))
" 2>/dev/null)

        win_kv "Class"  "$target"
        win_kv "Count"  "${#class_addrs[@]}"

        for addr in "${class_addrs[@]}"; do
            [[ -z "$addr" ]] && continue
            win_dispatch closewindow "address:${addr}"
        done

        win_ok "Closed ${#class_addrs[@]} windows of class '${target}'"
        printf '\n'; return 0
    fi

    # Active window (no target)
    if [[ -z "$target" ]]; then
        local active_title active_class
        active_title="$(win_get_active_field title)"
        active_class="$(win_get_active_field class)"

        win_kv "Window" "${active_class}: ${active_title:0:40}"
        _close_animation "${active_class}"

        if [[ $kill_mode -eq 1 ]]; then
            win_dispatch killactive
        else
            win_dispatch killactive
        fi
        win_ok "Window closed"
        win_notify "✕ Closed" "${active_class}"
        printf '\n'; return 0
    fi

    # Close by address or search
    win_kv "Target" "$target"
    _close_animation "$target"
    win_dispatch closewindow "address:${target}" || \
        win_dispatch closewindow "class:${target}"
    win_ok "Closed: ${target}"
    printf '\n'
}
