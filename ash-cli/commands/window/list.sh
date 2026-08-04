#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  window list                                              ║
# ║  Rich window listing with workspace groups, state badges, and mini layout map   ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WIN_LIST_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WIN_LIST_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MINI WORKSPACE MAP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_list_workspace_map() {
    local clients_json="$1"

    python3 - << PYEOF
import json, os

clients = json.loads("""${clients_json//\"/\\\"}""")
no_color = os.environ.get('ASH_FLAG_NO_COLOR','0') == '1'

R     = '' if no_color else '\033[0m'
DIM   = '' if no_color else '\033[38;2;108;112;134m'
MAUVE = '' if no_color else '\033[1;38;2;203;166;247m'
SKY   = '' if no_color else '\033[38;2;137;220;235m'
GRN   = '' if no_color else '\033[38;2;166;227;161m'
PEACH = '' if no_color else '\033[38;2;250;179;135m'

# Group by workspace
workspaces = {}
for c in clients:
    ws = c.get('workspace',{}).get('name','?')
    workspaces.setdefault(ws, []).append(c)

print(f'  {DIM}Workspace map:{R}')
for ws_name in sorted(workspaces.keys(), key=lambda x: (x.isdigit(), int(x) if x.isdigit() else x)):
    wins = workspaces[ws_name]
    count = len(wins)
    boxes = ''
    for win in wins[:6]:
        floating = win.get('floating', False)
        sym = '◻' if floating else '▪'
        col = PEACH if floating else SKY
        boxes += f'{col}{sym}{R}'
    if count > 6:
        boxes += f'{DIM}+{count-6}{R}'
    print(f'  {MAUVE}[{ws_name}]{R}  {boxes}  {DIM}({count} window{"s" if count != 1 else ""}){R}')

total = len(clients)
print(f'\n  {DIM}Total: {SKY}{total}{DIM} window{"s" if total != 1 else ""} across {len(workspaces)} workspace{"s" if len(workspaces) != 1 else ""}{R}')
PYEOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WINDOW TABLE RENDERER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_list_render_table() {
    local clients_json="$1"  filter="$2"  group_by_ws="$3"

    python3 - "$filter" "$group_by_ws" << PYEOF
import json, sys, os

clients = json.loads("""${clients_json//\"/\\\"}""")
filt    = sys.argv[1]
group   = sys.argv[2] == '1'

no_color = os.environ.get('ASH_FLAG_NO_COLOR','0') == '1'
R     = '' if no_color else '\033[0m'
BOLD  = '' if no_color else '\033[1m'
DIM   = '' if no_color else '\033[38;2;108;112;134m'
SKY   = '' if no_color else '\033[38;2;137;220;235m'
GRN   = '' if no_color else '\033[38;2;166;227;161m'
MAUVE = '' if no_color else '\033[1;38;2;203;166;247m'
BLUE  = '' if no_color else '\033[38;2;137;180;250m'
TEAL  = '' if no_color else '\033[38;2;148;226;213m'
PEACH = '' if no_color else '\033[38;2;250;179;135m'
YELL  = '' if no_color else '\033[38;2;249;226;175m'
RED   = '' if no_color else '\033[1;38;2;243;139;168m'

# Apply filter
if filt == 'floating':
    clients = [c for c in clients if c.get('floating')]
elif filt == 'tiled':
    clients = [c for c in clients if not c.get('floating')]
elif filt == 'fullscreen':
    clients = [c for c in clients if c.get('fullscreen')]
elif filt == 'pinned':
    clients = [c for c in clients if c.get('pinned')]
elif filt and filt not in ('all',''):
    clients = [c for c in clients
               if filt.lower() in c.get('class','').lower() or
                  filt.lower() in c.get('title','').lower()]

if not clients:
    print(f'  {DIM}No windows match filter: {filt}{R}')
    sys.exit(0)

def state_badge(c):
    badges = []
    if c.get('floating'):  badges.append(f'{PEACH}◈ float{R}')
    if c.get('pinned'):    badges.append(f'{YELL}📌 pin{R}')
    if c.get('fullscreen'):badges.append(f'{MAUVE}⛶ full{R}')
    return '  '.join(badges)

# Group by workspace
if group:
    workspaces = {}
    for c in clients:
        ws = c.get('workspace',{}).get('name','?')
        workspaces.setdefault(ws, []).append(c)

    for ws_name in sorted(workspaces.keys(),
                          key=lambda x: (x.isdigit(), int(x) if x.isdigit() else x)):
        print(f'\n  {MAUVE}Workspace {ws_name}:{R}')
        print(f'  {DIM}{"─"*56}{R}')
        for c in workspaces[ws_name]:
            cls   = c.get('class','?')[:18]
            title = c.get('title','?')[:35]
            addr  = c.get('address','?')[:14]
            sz    = c.get('size',[0,0])
            badges = state_badge(c)

            print(f'  {SKY}{BOLD}{cls:<20}{R} {DIM}{addr}{R}')
            print(f'     {title[:55]}')
            print(f'     {DIM}{sz[0]}×{sz[1]}{R}{"  " + badges if badges else ""}')
else:
    # Flat table
    print(f'\n  {DIM}{"Class":<20} {"Workspace":<10} {"Size":<12} {"Title":<35} {"State"}{R}')
    print(f'  {DIM}{"─"*85}{R}')
    for c in clients:
        cls   = c.get('class','?')[:18]
        title = c.get('title','?')[:33]
        ws    = c.get('workspace',{}).get('name','?')[:8]
        sz    = c.get('size',[0,0])
        sz_s  = f'{sz[0]}×{sz[1]}'
        badges = state_badge(c)

        print(f'  {SKY}{cls:<20}{R} {TEAL}{ws:<10}{R} {DIM}{sz_s:<12}{R} {title:<35} {badges}')
PYEOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_win_list() {
    local filter=""  group_by_ws=1  show_map=1  short=0

    for arg in "${@:-}"; do
        case "$arg" in
            --floating|-f)    filter="floating"    ;;
            --tiled|-t)       filter="tiled"       ;;
            --fullscreen)     filter="fullscreen"  ;;
            --pinned)         filter="pinned"      ;;
            --flat)           group_by_ws=0        ;;
            --no-map)         show_map=0           ;;
            --short|-s)       short=1              ;;
            --filter=*)       filter="${arg#*=}"   ;;
            *)                filter="$arg"        ;;
        esac
    done

    win_section "📋" "Window List" "$(_wlav)"

    local clients_json
    clients_json="$(win_get_clients_json)"

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        printf '%s\n' "$clients_json"
        return 0
    fi

    local win_count
    win_count="$(win_get_clients_count)"
    win_kv "Windows"   "$win_count"
    [[ -n "$filter" ]] && win_kv "Filter" "$filter"

    if [[ $show_map -eq 1 ]] && [[ $short -eq 0 ]]; then
        printf '\n'
        _list_workspace_map "$clients_json"
    fi

    printf '\n'
    _list_render_table "$clients_json" "$filter" "$group_by_ws"

    win_divider
    printf '\n'
}
