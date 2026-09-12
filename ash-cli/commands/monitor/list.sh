#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  monitor list                                             ║
# ║  Rich monitor listing with visual map, EDID info, capabilities                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_MON_LIST_LOADED:-}" == "1" ]] && return 0
readonly _ASH_MON_LIST_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  VISUAL MONITOR MAP  (ASCII art spatial layout)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_list_ascii_map() {
    local monitors_json="$1"

    command -v python3 &>/dev/null || return 0

    python3 - "$monitors_json" << 'PYEOF'
import json, sys, math

data = json.loads(sys.argv[1])
if not data:
    sys.exit(0)

no_color = True
try:
    import os
    no_color = os.environ.get('ASH_FLAG_NO_COLOR', '0') == '1'
except:
    pass

# Colour escape codes
RESET  = '' if no_color else '\033[0m'
BORDER = '' if no_color else '\033[38;2;108;112;134m'
ACTIVE = '' if no_color else '\033[1;38;2;137;220;235m'
NORM   = '' if no_color else '\033[38;2;205;214;244m'
DIM    = '' if no_color else '\033[38;2;88;91;112m'
MAUVE  = '' if no_color else '\033[38;2;203;166;247m'

# Find bounding box
max_x = max((m.get('x',0) + m.get('width',1920)) for m in data if not m.get('disabled'))
max_y = max((m.get('y',0) + m.get('height',1080)) for m in data if not m.get('disabled'))

scale = 0.04    # scale factor: 1920px → ~77 chars
h_scale = 0.018  # vertical scale

print(f'\n  {MAUVE}Monitor Layout Map:{RESET}')
print()

MAP_W = min(int(max_x * scale) + 4, 72)
MAP_H = min(int(max_y * h_scale) + 4, 20)

# Create canvas
canvas = [[' '] * MAP_W for _ in range(MAP_H)]

colors = ['\033[38;2;137;180;250m', '\033[38;2;166;227;161m',
          '\033[38;2;250;179;135m', '\033[38;2;203;166;247m',
          '\033[38;2;148;226;213m', '\033[38;2;249;226;175m']
color_idx = 0

for m in data:
    if m.get('disabled'):
        continue
    mx = m.get('x', 0)
    my = m.get('y', 0)
    mw = m.get('width', 1920)
    mh = m.get('height', 1080)
    name = m.get('name', '?')[:8]
    hz   = m.get('refreshRate', 60)
    focused = m.get('focused', False)

    # Map to canvas coords
    cx1 = int(mx * scale)
    cy1 = int(my * h_scale)
    cx2 = min(int((mx + mw) * scale), MAP_W - 1)
    cy2 = min(int((my + mh) * h_scale), MAP_H - 1)

    col = colors[color_idx % len(colors)] if not no_color else ''
    color_idx += 1

    # Draw box
    for row in range(cy1, cy2 + 1):
        if row < 0 or row >= MAP_H: continue
        for col_p in range(cx1, cx2 + 1):
            if col_p < 0 or col_p >= MAP_W: continue
            if row == cy1 or row == cy2:
                canvas[row][col_p] = '─'
            elif col_p == cx1 or col_p == cx2:
                canvas[row][col_p] = '│'
            else:
                canvas[row][col_p] = ' '

    # Corner characters
    for r, c, ch in [
        (cy1,cx1,'╭'),(cy1,cx2,'╮'),
        (cy2,cx1,'╰'),(cy2,cx2,'╯')
    ]:
        if 0 <= r < MAP_H and 0 <= c < MAP_W:
            canvas[r][c] = ch

    # Label
    label = f' {name} {int(hz)}Hz '
    lx = cx1 + 1 + (cx2 - cx1 - len(label)) // 2
    ly = cy1 + (cy2 - cy1) // 2
    if 0 <= ly < MAP_H:
        for i, ch in enumerate(label):
            if 0 <= lx + i < MAP_W:
                canvas[ly][lx + i] = ch

    star_row = cy1 + 1
    if focused and 0 <= star_row < MAP_H and cx1 + 1 < MAP_W:
        canvas[star_row][cx1 + 1] = '★'

# Print canvas
for row in canvas:
    print('  ' + ''.join(row))
print()

PYEOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  DETAILED MONITOR BLOCK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_list_render_monitor() {
    local mon_json="$1"

    python3 - << PYEOF
import json, sys, os

m = json.loads("""${mon_json}""")
no_color = os.environ.get('ASH_FLAG_NO_COLOR','0') == '1'

R     = '' if no_color else '\033[0m'
BOLD  = '' if no_color else '\033[1m'
DIM   = '' if no_color else '\033[38;2;108;112;134m'
SKY   = '' if no_color else '\033[38;2;137;220;235m'
GREEN = '' if no_color else '\033[38;2;166;227;161m'
MAUVE = '' if no_color else '\033[38;2;203;166;247m'
BLUE  = '' if no_color else '\033[38;2;137;180;250m'
TEAL  = '' if no_color else '\033[38;2;148;226;213m'
RED   = '' if no_color else '\033[1;38;2;243;139;168m'
YELL  = '' if no_color else '\033[38;2;249;226;175m'
PEACH = '' if no_color else '\033[38;2;250;179;135m'

name     = m.get('name','?')
desc     = m.get('description','')
w        = m.get('width',0)
h        = m.get('height',0)
hz       = m.get('refreshRate',0)
x        = m.get('x',0)
y        = m.get('y',0)
scale    = m.get('scale',1)
focused  = m.get('focused',False)
disabled = m.get('disabled',False)
vrr      = m.get('vrr',False)
hdr      = m.get('hdrEnabled',False)

# Status badge
if disabled:
    status = f'{RED}●  DISABLED{R}'
elif focused:
    status = f'{GREEN}●  ACTIVE (focused){R}'
else:
    status = f'{TEAL}●  active{R}'

# Resolution quality indicator
quality = ''
if w >= 3840:
    quality = f'{MAUVE}4K{R}'
elif w >= 2560:
    quality = f'{BLUE}QHD{R}'
elif w >= 1920:
    quality = f'{TEAL}FHD{R}'
elif w >= 1280:
    quality = f'{DIM}HD{R}'

# Refresh rate colour
if hz >= 240:
    hz_col = MAUVE
elif hz >= 144:
    hz_col = GREEN
elif hz >= 100:
    hz_col = TEAL
elif hz >= 60:
    hz_col = BLUE
else:
    hz_col = DIM

# DPI estimation (assuming 24" diagonal as fallback)
dpi_str = ''
if w and h:
    # assume ~24" if no physical size available
    dpi = round(((w**2 + h**2)**0.5) / 24, 0)
    dpi_str = f'{int(dpi)} PPI (estimated)'

def kv(key, val, col=GREEN):
    print(f'  {DIM}{key:<24}{R} {col}{val}{R}')

print()
print(f'  {SKY}{BOLD}🖥️   {name}{R}  {status}')
if desc:
    print(f'  {DIM}    {desc}{R}')
print(f'  {DIM}  {"─"*54}{R}')

kv('Resolution',  f'{w}x{h}  {quality}', '')
kv('Refresh rate', f'{hz_col}{hz:.3f} Hz{R}', '')
kv('Position',    f'{x},{y}  (X,Y)')
kv('Scale',       f'{scale}x')
if dpi_str:
    kv('DPI',     dpi_str, DIM)
kv('VRR',        f'{GREEN}enabled{R}' if vrr else f'{DIM}disabled{R}', '')
kv('HDR',        f'{GREEN}enabled{R}' if hdr else f'{DIM}disabled{R}', '')
PYEOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_monitor_list() {
    local target_name=""  show_modes=0  short=0

    for arg in "${@:-}"; do
        case "$arg" in
            --modes|-m)      show_modes=1  ;;
            --short|-s)      short=1       ;;
            --monitor=*)     target_name="${arg#*=}" ;;
            *)               [[ -z "$target_name" ]] && target_name="$arg" ;;
        esac
    done

    mon_section "🖥️ " "Monitor List" "$(_msky)"

    mon_kv "Backend" "$MON_BACKEND"

    local monitors_json
    monitors_json="$(mon_get_monitors_json)"

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        printf '%s\n' "$monitors_json"
        return 0
    fi

    local mon_count
    mon_count="$(printf '%s' "$monitors_json" | \
                 python3 -c "import json,sys; print(len(json.load(sys.stdin)))" \
                 2>/dev/null || echo 0)"

    mon_kv "Detected" "${mon_count} monitor(s)"

    if [[ $mon_count -eq 0 ]]; then
        mon_warn "No monitors detected"
        printf '\n'; return 0
    fi

    # ASCII spatial map
    if [[ $short -eq 0 ]]; then
        _list_ascii_map "$monitors_json"
    fi

    # Per-monitor details
    if [[ -n "$target_name" ]]; then
        local mon_data
        mon_data="$(printf '%s' "$monitors_json" | \
                    python3 -c "
import json,sys
mons=json.load(sys.stdin)
m=next((x for x in mons if x.get('name')=='${target_name}'),None)
print(json.dumps(m) if m else 'null')
" 2>/dev/null)"

        if [[ "$mon_data" == "null" ]] || [[ -z "$mon_data" ]]; then
            mon_fail "Monitor not found: ${target_name}"
            return 1
        fi

        _list_render_monitor "$mon_data"
    else
        # All monitors
        printf '%s' "$monitors_json" | python3 -c "
import json, sys
mons = json.load(sys.stdin)
for m in mons:
    print(json.dumps(m))
" 2>/dev/null | while IFS= read -r mon_json; do
            _list_render_monitor "$mon_json"
        done
    fi

    # Available modes
    if [[ $show_modes -eq 1 ]] && [[ "$MON_BACKEND" == "hyprland" ]]; then
        mon_section "📋" "Available Modes" "$(_mdim)"
        hyprctl monitors -j 2>/dev/null | python3 -c "
import json, sys
mons = json.load(sys.stdin)
for m in mons:
    name = m.get('name','?')
    print(f'  {name}:')
    for mode in m.get('availableModes',[]):
        print(f'    {mode}')
" 2>/dev/null
    fi

    mon_divider
    printf '\n'
}
