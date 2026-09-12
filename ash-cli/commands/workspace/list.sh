#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  workspace list                                           ║
# ║  Rich workspace listing with per-workspace window details and usage bars        ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WS_LIST_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WS_LIST_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WORKSPACE DETAIL RENDERER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_list_render() {
    local ws_json="$1"  clients_json="$2"  active_id="$3"
    local show_windows="${4:-1}"  compact="${5:-0}"

    python3 - "$active_id" "$show_windows" "$compact" << PYEOF
import json, sys, os

wss     = json.loads("""${ws_json//\"/\\\"}""")
clients = json.loads("""${clients_json//\"/\\\"}""")
act_id  = int(sys.argv[1]) if sys.argv[1].isdigit() else 0
show_w  = sys.argv[2] == '1'
compact = sys.argv[3] == '1'

no_color = os.environ.get('ASH_FLAG_NO_COLOR','0') == '1'
R      = '' if no_color else '\033[0m'
BOLD   = '' if no_color else '\033[1m'
DIM    = '' if no_color else '\033[38;2;108;112;134m'
SKY    = '' if no_color else '\033[38;2;137;220;235m'
GRN    = '' if no_color else '\033[38;2;166;227;161m'
MAUVE  = '' if no_color else '\033[1;38;2;203;166;247m'
BLUE   = '' if no_color else '\033[38;2;137;180;250m'
TEAL   = '' if no_color else '\033[38;2;148;226;213m'
PEACH  = '' if no_color else '\033[38;2;250;179;135m'
YELL   = '' if no_color else '\033[38;2;249;226;175m'
DIM2   = '' if no_color else '\033[38;2;88;91;112m'

# Build client index by workspace id
ws_clients = {}
for c in clients:
    ws_id = c.get('workspace',{}).get('id')
    ws_clients.setdefault(ws_id, []).append(c)

# Sort workspaces
wss_sorted = sorted(wss, key=lambda w: w.get('id', 0))

total_ws  = len(wss_sorted)
total_win = len(clients)

if not compact:
    print(f'\n  {DIM}{"ID":<4} {"Name":<12} {"Windows":<8} {"Monitor":<10} {"Usage":<20} Status{R}')
    print(f'  {DIM}{"─"*70}{R}')

for ws in wss_sorted:
    ws_id    = ws.get('id', '?')
    ws_name  = ws.get('name', str(ws_id))
    ws_wins  = ws.get('windows', 0)
    ws_mon   = ws.get('monitor', '?')
    is_act   = ws_id == act_id

    wins_here = ws_clients.get(ws_id, [])

    # Usage bar
    bar_w = 18
    filled = min(ws_wins, bar_w)
    empty  = bar_w - filled
    bar_col = PEACH if ws_wins > 8 else (TEAL if ws_wins > 3 else (BLUE if ws_wins > 0 else DIM2))
    bar = bar_col + '█' * filled + DIM2 + '░' * empty + R

    # Active indicator
    status = f'{MAUVE}{BOLD}◉ active{R}' if is_act else f'{DIM}○{R}'
    name_col = MAUVE if is_act else SKY

    if compact:
        mark = '▸' if is_act else ' '
        print(f'  {MAUVE if is_act else DIM}{mark}{R} '
              f'{name_col}{BOLD if is_act else ""}{ws_name:<12}{R} '
              f'{TEAL}{ws_wins:>3}{DIM} windows{R}  {bar}')
    else:
        print(f'  {name_col}{BOLD if is_act else ""}{ws_id:<4}{R}'
              f' {name_col}{ws_name:<12}{R}'
              f' {TEAL}{ws_wins:<8}{R}'
              f' {DIM}{str(ws_mon):<10}{R}'
              f' {bar}  '
              f' {status}')

    # Show window details
    if show_w and not compact and wins_here:
        for c in wins_here[:5]:
            cls   = c.get('class','?')[:15]
            title = c.get('title','?')[:35]
            float_mark = f'{PEACH}◈{R} ' if c.get('floating') else '  '
            pin_mark   = f'{YELL}📌{R} ' if c.get('pinned')   else '  '
            print(f'         {DIM}├─{R} {float_mark}{pin_mark}'
                  f'{BLUE}{cls:<16}{R} {DIM}{title}{R}')
        if len(wins_here) > 5:
            extra = len(wins_here) - 5
            print(f'         {DIM}└─ + {extra} more window{"s" if extra!=1 else ""}{R}')
        print()

if not compact:
    print(f'\n  {DIM}Total: {SKY}{total_ws}{DIM} workspaces  •  {SKY}{total_win}{DIM} windows{R}')
PYEOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_ws_list() {
    local show_windows=1  compact=0

    for arg in "${@:-}"; do
        case "$arg" in
            --compact|-c)     compact=1       ;;
            --no-windows|-n)  show_windows=0  ;;
        esac
    done

    ws_section "📋" "Workspace List" "$(_wslav)"

    local ws_json clients_json active_id
    ws_json="$(ws_get_workspaces_json)"
    clients_json="$(ws_get_clients_json)"
    active_id="$(ws_get_active_id)"

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        printf '%s\n' "$ws_json"
        return 0
    fi

    ws_kv "Active workspace" "$active_id"

    _list_render "$ws_json" "$clients_json" "$active_id" \
        "$show_windows" "$compact"

    ws_divider
    printf '\n'
}
