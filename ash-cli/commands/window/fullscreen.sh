#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ███████╗██╗   ██╗██╗     ██╗      ███████╗ ██████╗██████╗ ███████╗███████╗███╗  ║
# ║  ██╔════╝██║   ██║██║     ██║      ██╔════╝██╔════╝██╔══██╗██╔════╝██╔════╝████╗ ║
# ║  █████╗  ██║   ██║██║     ██║      ███████╗██║     ██████╔╝█████╗  █████╗  ██╔██╗║
# ║  ██╔══╝  ██║   ██║██║     ██║      ╚════██║██║     ██╔══██╗██╔══╝  ██╔══╝  ██║╚██║
# ║  ██║     ╚██████╔╝███████╗███████╗ ███████║╚██████╗██║  ██║███████╗███████╗██║ ╚═╝║
# ║  ╚═╝      ╚═════╝ ╚══════╝╚══════╝ ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝   ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  window fullscreen                                        ║
# ║  Fullscreen / maximise / monocle with animated transitions                      ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WIN_FULLSCREEN_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WIN_FULLSCREEN_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# Fullscreen modes in Hyprland:
#  0 = fullscreen (true fullscreen, no gaps/borders)
#  1 = maximize (fills monitor but keeps gaps/bar)
#  2 = maximize (same workspace, keeps tiling siblings)

_fs_animation() {
    local entering="$1"  mode="${2:-0}"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        if [[ $entering -eq 1 ]]; then
            # Expand animation
            local widths=( 10 20 30 40 50 60 70 80 )
            local chars=( '▏' '▎' '▍' '▌' '▋' '▊' '▉' '█' )
            local col="$(_wmauve)"
            [[ "$mode" == "1" ]] && col="$(_wblue)"
            for (( i=0; i<${#widths[@]}; i++ )); do
                local w="${widths[$i]}"
                local ch="${chars[$i]}"
                printf '\r  %s%s%s  %sExpanding %s%s...' \
                    "$col" "$ch" "$(_wr)" \
                    "$(_wdim)" "$([[ $mode == 0 ]] && echo 'fullscreen' || echo 'maximize')" \
                    "$(_wr)"
                sleep 0.05
            done
        else
            # Contract animation
            local chars=( '█' '▉' '▊' '▋' '▌' '▍' '▎' '▏' )
            for ch in "${chars[@]}"; do
                printf '\r  %s%s%s  %sRestoring...%s' \
                    "$(_wdim)" "$ch" "$(_wr)" "$(_wdim)" "$(_wr)"
                sleep 0.05
            done
        fi
        printf '\r  %-60s\n' ""
    fi
}

_fs_state_display() {
    local mode="$1"
    case "$mode" in
        full)
        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
            printf '\n  %s%s' "$(_wmauve)$(_wbold)" ""
            cat << 'BANNER'
  ╔════════════════════════════════════════════════════╗
  ║   ⛶   FULLSCREEN                                   ║
  ╚════════════════════════════════════════════════════╝
BANNER
            printf '%s\n' "$(_wr)"
        fi
        ;;
        max)
        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
            printf '\n  %s%s' "$(_wblue)$(_wbold)" ""
            cat << 'BANNER'
  ╔════════════════════════════════════════════════════╗
  ║   ⬜  MAXIMIZED                                    ║
  ╚════════════════════════════════════════════════════╝
BANNER
            printf '%s\n' "$(_wr)"
        fi
        ;;
        restore)
        win_ok "Window restored to normal"
        ;;
    esac
}

ash_win_fullscreen() {
    local mode="toggle"  # toggle | full | max | monocle | restore
    local hy_mode=0      # Hyprland fullscreen mode integer

    for arg in "${@:-}"; do
        case "$arg" in
            toggle|t)                       mode="toggle"   ;;
            full|fullscreen|0)              mode="full"     ;;
            max|maximize|maximise|1)        mode="max"      ;;
            monocle|2)                      mode="monocle"  ;;
            restore|r|off|normal|exit)      mode="restore"  ;;
        esac
    done

    win_section "⛶" "Fullscreen" "$(_wmauve)"

    local active_json
    active_json="$(win_get_active_json)"
    local title cls cur_fullscreen
    title="$(          python3 -c "import json; d=json.loads('''${active_json//\'/\'\\\'\'}'''); print(d.get('title','?')[:50])" 2>/dev/null)"
    cls="$(            python3 -c "import json; d=json.loads('''${active_json//\'/\'\\\'\'}'''); print(d.get('class','?'))" 2>/dev/null)"
    cur_fullscreen="$( python3 -c "import json; d=json.loads('''${active_json//\'/\'\\\'\'}'''); print(d.get('fullscreen',False))" 2>/dev/null)"
    cur_fs_mode="$(    python3 -c "import json; d=json.loads('''${active_json//\'/\'\\\'\'}'''); print(d.get('fullscreenMode',-1))" 2>/dev/null)"

    win_kv "Window"      "${cls}: ${title}"
    win_kv "Fullscreen"  "$([[ "$cur_fullscreen" == "True" ]] && echo "yes (mode ${cur_fs_mode})" || echo 'no')"

    # Resolve mode
    local entering=1
    case "$mode" in
        toggle)
            if [[ "$cur_fullscreen" == "True" ]]; then
                mode="restore"; entering=0
                hy_mode="${cur_fs_mode:-0}"
            else
                mode="full"; hy_mode=0
            fi
            ;;
        full)     hy_mode=0 ;;
        max)      hy_mode=1 ;;
        monocle)  hy_mode=2 ;;
        restore)
            entering=0
            hy_mode="${cur_fs_mode:-0}"
            ;;
    esac

    win_kv "Action"  "$mode"

    if [[ $entering -eq 0 ]] && [[ "$cur_fullscreen" != "True" ]]; then
        win_info "Window is not in fullscreen mode"
        printf '\n'; return 0
    fi

    if [[ $entering -eq 1 ]] && [[ "$cur_fullscreen" == "True" ]] && \
       [[ "${cur_fs_mode}" == "$hy_mode" ]]; then
        win_info "Already in this fullscreen mode"
        printf '\n'; return 0
    fi

    _fs_animation $entering "$hy_mode"

    win_dispatch fullscreen "$hy_mode"

    case "$mode" in
        full)
            _fs_state_display "full"
            win_kv "Mode" "$(win_badge " ⛶ FULLSCREEN " "$(_wmauve)")"
            win_notify "⛶ Fullscreen" "${cls}"
            ;;
        max)
            _fs_state_display "max"
            win_kv "Mode" "$(win_badge " ⬜ MAXIMIZED " "$(_wblue)")"
            win_notify "⬜ Maximized" "${cls}"
            ;;
        monocle)
            win_ok "Monocle mode active"
            win_kv "Mode" "$(win_badge " MONOCLE " "$(_wteal)")"
            ;;
        restore)
            _fs_state_display "restore"
            win_notify "⛶ Restored" "${cls}"
            ;;
    esac

    printf '\n'
}
