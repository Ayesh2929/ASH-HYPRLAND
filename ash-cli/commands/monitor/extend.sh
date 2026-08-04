#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  monitor extend                                           ║
# ║  Extend desktop: left/right/above/below/auto with position calculation           ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_MON_EXTEND_LOADED:-}" == "1" ]] && return 0
readonly _ASH_MON_EXTEND_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_extend_calculate_positions() {
    local direction="$1"
    # Returns space-separated: "name w h hz x y scale" lines
    mon_get_monitors_json | python3 - "$direction" << 'PYEOF'
import json, sys

mons_raw = json.load(sys.stdin)
direction = sys.argv[1]

# Only active monitors
mons = [m for m in mons_raw if not m.get('disabled')]
if not mons:
    sys.exit(1)

# Sort by x then y
mons.sort(key=lambda m: (m.get('x',0), m.get('y',0)))

if direction == 'right':
    # Stack horizontally: each monitor goes to the right of the previous
    x_cursor = 0
    for m in mons:
        w = m.get('width', 1920)
        h = m.get('height', 1080)
        hz = m.get('refreshRate', 60)
        s = m.get('scale', 1)
        print(f"{m['name']}|{w}|{h}|{hz}|{x_cursor}|0|{s}")
        x_cursor += int(w / s)

elif direction == 'left':
    # Primary at right, secondary to the left
    x_cursor = 0
    total_w = sum(int(m.get('width',1920) / m.get('scale',1)) for m in mons)
    x_cursor = total_w
    for m in reversed(mons):
        w = m.get('width', 1920)
        h = m.get('height', 1080)
        hz = m.get('refreshRate', 60)
        s = m.get('scale', 1)
        x_cursor -= int(w / s)
        print(f"{m['name']}|{w}|{h}|{hz}|{x_cursor}|0|{s}")

elif direction == 'above':
    y_cursor = 0
    total_h = sum(int(m.get('height',1080) / m.get('scale',1)) for m in mons)
    y_cursor = total_h
    for m in reversed(mons):
        w = m.get('width', 1920)
        h = m.get('height', 1080)
        hz = m.get('refreshRate', 60)
        s = m.get('scale', 1)
        y_cursor -= int(h / s)
        print(f"{m['name']}|{w}|{h}|{hz}|0|{y_cursor}|{s}")

elif direction == 'below':
    y_cursor = 0
    for m in mons:
        w = m.get('width', 1920)
        h = m.get('height', 1080)
        hz = m.get('refreshRate', 60)
        s = m.get('scale', 1)
        print(f"{m['name']}|{w}|{h}|{hz}|0|{y_cursor}|{s}")
        y_cursor += int(h / s)

else:
    # auto: place all at x=0,y=0 offset by their width
    x_cursor = 0
    for m in mons:
        w = m.get('width', 1920)
        h = m.get('height', 1080)
        hz = m.get('refreshRate', 60)
        s = m.get('scale', 1)
        print(f"{m['name']}|{w}|{h}|{hz}|{x_cursor}|0|{s}")
        x_cursor += int(w / s)
PYEOF
}

ash_monitor_extend() {
    local direction="right"
    local primary=""  secondary=""

    for arg in "${@:-}"; do
        case "$arg" in
            left|right|above|below|auto) direction="$arg" ;;
            --primary=*)    primary="${arg#*=}"   ;;
            --secondary=*)  secondary="${arg#*=}" ;;
        esac
    done

    mon_section "➕" "Extend Display" "$(_mteal)"
    mon_kv "Backend"   "$MON_BACKEND"
    mon_kv "Direction" "$direction"

    local positions
    positions="$(_extend_calculate_positions "$direction")"

    if [[ -z "$positions" ]]; then
        mon_fail "Could not calculate monitor positions"
        return 1
    fi

    printf '\n  %sCalculated layout:%s\n' "$(_mdim)" "$(_mr)"

    while IFS='|' read -r mon_name w h hz x y scale; do
        [[ -z "$mon_name" ]] && continue
        mon_kv "  ${mon_name}" "${w}x${h}@${hz}  pos:(${x},${y})  scale:${scale}"
    done <<< "$positions"

    printf '\n'
    if [[ "${ASH_FLAG_YES:-0}" -ne 1 ]]; then
        printf '  %sApply this layout? [Y/n] %s' "$(_myellow)" "$(_mr)"
        local ans
        read -r ans
        [[ "${ans,,}" == "n" ]] && { mon_info "Cancelled"; printf '\n'; return 0; }
    fi

    mon_step "Applying extended layout..."

    while IFS='|' read -r mon_name w h hz x y scale; do
        [[ -z "$mon_name" ]] && continue
        mon_apply "$mon_name" "$w" "$h" "$hz" "$x" "$y" "$scale" && \
            mon_ok "  ${mon_name}: positioned at (${x},${y})" || \
            mon_warn "  ${mon_name}: apply may have failed"
    done <<< "$positions"

    [[ "${ASH_MON_SAVE:-0}" -eq 1 ]] && mon_save_config
    mon_notify "➕ Extended" "${direction}  •  $(echo "$positions" | wc -l) monitors"

    printf '\n'
}
