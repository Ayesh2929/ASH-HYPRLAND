#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  workspace move-window                                    ║
# ║  Move windows between workspaces with follow option and silent mode              ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WS_MOVE_WINDOW_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WS_MOVE_WINDOW_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MOVE ANIMATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_mw_animation() {
    local window_name="$1"  target_ws="$2"

    [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] || return 0
    [[ -t 1 ]] || return 0

    local frames=( '📦' '📦' '🚀' '🚀' '📥' )
    for frame in "${frames[@]}"; do
        printf '\r  %s  %sMoving%s %s%s%s %s→%s ws%s%s%s  ' \
            "$frame" \
            "$(_wsdim)" "$(_wsr)" \
            "$(_wssky)$(_wsbold)" "${window_name:0:20}" "$(_wsr)" \
            "$(_wsdim)" "$(_wsr)" \
            "$(_wspeach)$(_wsbold)" "$target_ws" "$(_wsr)"
        sleep 0.1
    done
    printf '\r  %-60s\n' ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BATCH MOVE (all windows from workspace)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_mw_move_all_from() {
    local from_ws="$1"  to_ws="$2"

    local -a window_addresses=()
    mapfile -t window_addresses < <(
        ws_get_clients_json | python3 -c "
import json, sys
clients = json.load(sys.stdin)
for c in clients:
    ws = c.get('workspace',{})
    ws_id   = str(ws.get('id',''))
    ws_name = ws.get('name','')
    if ws_id == '${from_ws}' or ws_name == '${from_ws}':
        print(c.get('address',''))
" 2>/dev/null
    )

    if [[ ${#window_addresses[@]} -eq 0 ]]; then
        ws_info "No windows in workspace ${from_ws}"
        return 0
    fi

    ws_kv "Moving" "${#window_addresses[@]} windows  ${from_ws} → ${to_ws}"

    for addr in "${window_addresses[@]}"; do
        [[ -z "$addr" ]] && continue
        ws_dispatch movetoworkspacesilent "$to_ws,address:${addr}"
    done

    ws_ok "Moved ${#window_addresses[@]} windows to workspace ${to_ws}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_ws_move_window() {
    local target_ws=""  follow=0  all_from=""  silent=0

    for arg in "${@:-}"; do
        case "$arg" in
            --follow|-f)      follow=1          ;;
            --all-from=*)     all_from="${arg#*=}" ;;
            --silent|-s)      silent=1          ;;
            *)                target_ws="$arg"  ;;
        esac
    done

    [[ $silent -eq 0 ]] && ws_section "📦" "Move Window to Workspace" "$(_wspeach)"

    # Move all from a workspace
    if [[ -n "$all_from" ]]; then
        [[ -z "$target_ws" ]] && {
            printf '  %sTarget workspace: %s' "$(_wsyellow)" "$(_wsr)"
            read -r target_ws
        }
        _mw_move_all_from "$all_from" "$target_ws"
        printf '\n'; return 0
    fi

    # Interactive workspace picker if no target given
    if [[ -z "$target_ws" ]]; then
        local ws_json active_id
        ws_json="$(ws_get_workspaces_json)"
        active_id="$(ws_get_active_id)"

        local fzf_input
        fzf_input="$(python3 - << PYEOF
import json, os
wss = json.loads("""${ws_json//\"/\\\"}""")
no_color = os.environ.get('ASH_FLAG_NO_COLOR','0') == '1'
TEAL = '' if no_color else '\033[38;2;148;226;213m'
DIM  = '' if no_color else '\033[38;2;108;112;134m'
R    = '' if no_color else '\033[0m'
for ws in sorted(wss, key=lambda w: w.get('id',0)):
    ws_id   = str(ws.get('id','?'))
    ws_name = ws.get('name', ws_id)
    ws_wins = ws.get('windows', 0)
    print(f'{ws_id}\t{TEAL}{ws_name:<12}{R} {DIM}{ws_wins} windows{R}')
PYEOF
)"

        if command -v fzf &>/dev/null; then
            target_ws="$(printf '%s\n' "$fzf_input" | \
                fzf --prompt "  📦  Move to workspace: " \
                    --height=12 \
                    --border=rounded \
                    --ansi \
                    --delimiter='\t' \
                    --with-nth=2 \
                    --color="hl:$(printf '%s' "$(_wspeach)" | sed 's/\033\[//;s/m//')" \
                    --header="ESC=cancel" \
                    2>/dev/null | awk -F'\t' '{print $1}')"
        else
            printf '\n  %sTarget workspace number or name: %s' \
                "$(_wsyellow)" "$(_wsr)"
            read -r target_ws
        fi
    fi

    [[ -z "$target_ws" ]] && {
        [[ $silent -eq 0 ]] && ws_info "No target workspace selected"
        printf '\n'; return 0
    }

    # Get active window info
    local active_json
    active_json="$(ws_get_active_workspace_json)"
    local win_title win_class from_ws

    win_title="$(hyprctl activewindow -j 2>/dev/null | \
                 python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('title','?')[:35])" \
                 2>/dev/null || echo '?')"
    win_class="$(hyprctl activewindow -j 2>/dev/null | \
                 python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('class','?'))" \
                 2>/dev/null || echo '?')"
    from_ws="$(ws_get_active_id)"

    [[ $silent -eq 0 ]] && ws_kv "Window"      "${win_class}: ${win_title}"
    [[ $silent -eq 0 ]] && ws_kv "From"        "workspace ${from_ws}"
    [[ $silent -eq 0 ]] && ws_kv "To"          "workspace ${target_ws}"
    [[ $silent -eq 0 ]] && ws_kv "Follow"      "$([[ $follow -eq 1 ]] && echo 'yes' || echo 'no')"

    _mw_animation "${win_class}" "$target_ws"

    if [[ $follow -eq 1 ]]; then
        # Move and follow (switch to target workspace too)
        if [[ "$target_ws" =~ ^[0-9]+$ ]]; then
            ws_dispatch movetoworkspace "$target_ws"
        else
            ws_dispatch movetoworkspace "name:${target_ws}"
        fi
        ws_log_history "$target_ws"
    else
        # Move silently (stay on current workspace)
        if [[ "$target_ws" =~ ^[0-9]+$ ]]; then
            ws_dispatch movetoworkspacesilent "$target_ws"
        else
            ws_dispatch movetoworkspacesilent "name:${target_ws}"
        fi
    fi

    if [[ $silent -eq 0 ]]; then
        ws_ok "Window moved to workspace ${target_ws}"
        ws_notify "📦 Window Moved" "${win_class} → workspace ${target_ws}"
    fi

    printf '\n'
}
