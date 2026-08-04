#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  workspace switch                                         ║
# ║  Smart workspace switching: number / name / direction / last / fzf picker       ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WS_SWITCH_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WS_SWITCH_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SWITCH ANIMATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_switch_animation() {
    local from_id="$1"  to_id="$2"  direction="${3:-right}"

    [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] || return 0
    [[ -t 1 ]] || return 0

    local from_greater to_greater
    if [[ "$to_id" =~ ^[0-9]+$ ]] && [[ "$from_id" =~ ^[0-9]+$ ]]; then
        (( to_id > from_id )) && direction="right" || direction="left"
    fi

    local -a frames
    if [[ "$direction" == "right" ]]; then
        frames=( '⠶' '▷' '▶' '▷' '⠶' )
    else
        frames=( '⠶' '◁' '◀' '◁' '⠶' )
    fi

    for frame in "${frames[@]}"; do
        printf '\r  %s%s%s  %s→ workspace %s%s%s  ' \
            "$(_wsmauve)" "$frame" "$(_wsr)" \
            "$(_wsdim)" "$(_wssky)$(_wsbold)" "$to_id" "$(_wsr)"
        sleep 0.07
    done
    printf '\r  %-60s\n' ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WORKSPACE PICKER  (fzf or numbered)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_switch_pick_workspace() {
    local ws_json="$1"  active_id="$2"

    local fzf_input
    fzf_input="$(python3 - "$active_id" << PYEOF
import json, sys, os
wss = json.loads("""${ws_json//\"/\\\"}""")
act_id = sys.argv[1]
no_color = os.environ.get('ASH_FLAG_NO_COLOR','0') == '1'
MAUVE = '' if no_color else '\033[1;38;2;203;166;247m'
GRN   = '' if no_color else '\033[38;2;166;227;161m'
TEAL  = '' if no_color else '\033[38;2;148;226;213m'
DIM   = '' if no_color else '\033[38;2;108;112;134m'
R     = '' if no_color else '\033[0m'

for ws in sorted(wss, key=lambda w: w.get('id',0)):
    ws_id   = str(ws.get('id','?'))
    ws_name = ws.get('name', ws_id)
    ws_wins = ws.get('windows', 0)
    is_act  = ws_id == act_id
    mark    = f'{MAUVE}★{R} ' if is_act else '  '
    bar     = ('█' * min(ws_wins,8)).ljust(8, '░')
    print(f'{ws_id}\t{mark}{TEAL}{ws_name:<12}{R} {DIM}{bar}{R} {ws_wins} win{"s" if ws_wins!=1 else ""}')
PYEOF
)"

    if command -v fzf &>/dev/null; then
        printf '%s\n' "$fzf_input" | \
            fzf --prompt "  🗂️   Switch to: " \
                --height=15 \
                --border=rounded \
                --ansi \
                --delimiter='\t' \
                --with-nth=2 \
                --color="hl:$(printf '%s' "$(_wsmauve)" | sed 's/\033\[//;s/m//')" \
                --header="↵=switch  ESC=cancel" \
                2>/dev/null | awk -F'\t' '{print $1}'
    else
        printf '\n  %sAvailable workspaces:%s\n' "$(_wsdim)" "$(_wsr)"
        local i=0
        local -a ids=()

        while IFS=$'\t' read -r id display; do
            (( i++ )) || true
            ids+=("$id")
            printf '  %s%3d%s  %s\n' \
                "$(_wspeach)" "$i" "$(_wsr)" "$display"
        done <<< "$fzf_input"

        printf '\n  %sEnter number [1-%d]: %s' "$(_wsyellow)" "$i" "$(_wsr)"
        local choice; read -r choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && \
           (( choice >= 1 )) && (( choice <= ${#ids[@]} )); then
            printf '%s' "${ids[$((choice-1))]}"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_ws_switch() {
    local target=""  silent=0

    for arg in "${@:-}"; do
        case "$arg" in
            --silent|-s) silent=1    ;;
            *)           target="$arg" ;;
        esac
    done

    [[ $silent -eq 0 ]] && ws_section "🔀" "Switch Workspace" "$(_wsteal)"

    local from_id
    from_id="$(ws_get_active_id)"

    # Interactive picker if no target
    if [[ -z "$target" ]]; then
        local ws_json
        ws_json="$(ws_get_workspaces_json)"
        target="$(_switch_pick_workspace "$ws_json" "$from_id")"
    fi

    [[ -z "$target" ]] && {
        [[ $silent -eq 0 ]] && ws_info "No workspace selected"
        printf '\n'; return 0
    }

    # Resolve special targets
    case "$target" in
        next|+1)   ws_dispatch workspace "e+1"; ws_log_history "$(ws_get_active_id)"; return 0 ;;
        prev|-1|previous) ws_dispatch workspace "e-1"; ws_log_history "$(ws_get_active_id)"; return 0 ;;
        last|back) target="$(ws_get_previous_id)" ;;
    esac

    [[ $silent -eq 0 ]] && ws_kv "From" "workspace ${from_id}"
    [[ $silent -eq 0 ]] && ws_kv "To"   "workspace ${target}"

    _switch_animation "$from_id" "$target"

    # Switch (numeric or named)
    if [[ "$target" =~ ^[0-9]+$ ]]; then
        ws_dispatch workspace "$target"
    else
        ws_dispatch workspace "name:${target}"
    fi

    sleep 0.1
    local new_id
    new_id="$(ws_get_active_id)"
    ws_log_history "$new_id"

    if [[ $silent -eq 0 ]]; then
        ws_ok "Switched to workspace ${new_id}"
        ws_notify "🗂️ Workspace" "Switched to ${new_id}"
    fi

    printf '\n'
}
