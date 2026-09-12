#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  shot window                                              ║
# ║  Capture active window or interactive window picker via Hyprland IPC            ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_SHOT_WINDOW_LOADED:-}" == "1" ]] && return 0
readonly _ASH_SHOT_WINDOW_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_win_get_active_geometry_hyprctl() {
    # Returns "X,Y WxH" via Hyprland IPC
    command -v hyprctl &>/dev/null || return 1
    [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && return 1

    python3 - << 'PYEOF' 2>/dev/null
import json, subprocess
result = subprocess.run(['hyprctl', 'activewindow', '-j'],
                       capture_output=True, text=True)
w = json.loads(result.stdout)
x  = w.get('at', [0,0])[0]
y  = w.get('at', [0,0])[1]
ww = w.get('size', [100,100])[0]
wh = w.get('size', [100,100])[1]
print(f"{x},{y} {ww}x{wh}")
PYEOF
}

_win_get_active_xprop() {
    # X11 fallback via xdotool
    command -v xdotool &>/dev/null || return 1
    local win_id
    win_id="$(xdotool getactivewindow 2>/dev/null)"
    local geom
    geom="$(xdotool getwindowgeometry --shell "$win_id" 2>/dev/null)"
    local x y w h
    eval "$geom" 2>/dev/null
    printf '%d,%d %dx%d' "${X:-0}" "${Y:-0}" "${WIDTH:-100}" "${HEIGHT:-100}"
}

_win_picker_hyprctl() {
    # Let user pick from open windows via fzf
    command -v hyprctl &>/dev/null || return 1

    python3 - << 'PYEOF' 2>/dev/null
import json, subprocess, sys
result = subprocess.run(['hyprctl', 'clients', '-j'],
                       capture_output=True, text=True)
clients = json.loads(result.stdout)
for c in clients:
    x  = c.get('at', [0,0])[0]
    y  = c.get('at', [0,0])[1]
    ww = c.get('size', [100,100])[0]
    wh = c.get('size', [100,100])[1]
    title = c.get('title', 'Untitled')[:40]
    cls   = c.get('class', '?')
    print(f"{x},{y} {ww}x{wh}\t{cls}: {title}")
PYEOF
}

ash_shot_window() {
    local fmt="${ASH_SHOT_FORMAT:-png}"
    local pick_mode=0
    local freeze=0

    for arg in "${@:-}"; do
        case "$arg" in
            --pick|-p)   pick_mode=1 ;;
            --freeze|-f) freeze=1    ;;
        esac
    done

    shot_section "🪟" "Window Capture" "$(_slav)"

    shot_check_wayland || return 1

    local geometry=""

    if [[ $pick_mode -eq 1 ]]; then
        # Interactive window picker
        shot_info "Click on a window to capture..."
        if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
            local win_list
            win_list="$(_win_picker_hyprctl 2>/dev/null || echo '')"

            if command -v fzf &>/dev/null && [[ -n "$win_list" ]]; then
                local selected
                selected="$(printf '%s\n' "$win_list" | \
                            fzf --prompt "  🪟  Select window: " \
                                --height=20 \
                                --border=rounded \
                                --with-nth=2 \
                                --delimiter='\t' \
                                --color="hl:$(printf '%s' "$(_smauve)" | sed 's/\x1b\[//;s/m//')" \
                                --header="ESC to cancel" 2>/dev/null || echo '')"

                [[ -n "$selected" ]] && \
                    geometry="$(printf '%s' "$selected" | cut -f1)"
            else
                # slurp window pick
                geometry="$(_win_get_active_geometry_hyprctl)"
            fi
        fi
    else
        # Active window
        shot_step "Getting active window geometry..."
        geometry="$(_win_get_active_geometry_hyprctl 2>/dev/null || \
                    _win_get_active_xprop 2>/dev/null || echo '')"
    fi

    if [[ -z "$geometry" ]]; then
        # Fallback: let user draw
        shot_info "Could not determine window geometry — use slurp to select"
        if command -v slurp &>/dev/null; then
            geometry="$(slurp 2>/dev/null)" || {
                shot_info "Selection cancelled"
                return 0
            }
        else
            shot_fail "Cannot determine window geometry"
            return 1
        fi
    fi

    shot_kv "Geometry" "$geometry"

    local output_file
    output_file="$(shot_filename "window" "$fmt")"

    if command -v grim &>/dev/null; then
        grim -g "$geometry" "$output_file" 2>/dev/null || {
            shot_fail "grim capture failed"
            return 1
        }
    else
        shot_fail "grim not found — required for Wayland window capture"
        shot_info "Install: paru -S grim"
        return 1
    fi

    local size
    size="$(du -sh "$output_file" 2>/dev/null | cut -f1)"
    shot_ok "Window screenshot saved"
    shot_kv "File" "$output_file"
    shot_kv "Size" "$size"

    [[ "${ASH_SHOT_CLIPBOARD:-0}" -eq 1 ]] && shot_copy_to_clipboard "$output_file"
    [[ "${ASH_SHOT_ANNOTATE:-0}" -eq 1 ]]  && ash_shot_annotate "$output_file"
    [[ "${ASH_SHOT_UPLOAD:-0}" -eq 1 ]]    && ash_shot_upload "$output_file"

    shot_log "$output_file" "window" "$geometry"
    shot_notify "🪟 Window Captured" "${size}" "$output_file"

    printf '\n'
}
