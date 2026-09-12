#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║   ██████╗ ██╗   ██╗███████╗██████╗ ██╗   ██╗██╗███████╗██╗    ██╗              ║
# ║  ██╔═══██╗██║   ██║██╔════╝██╔══██╗██║   ██║██║██╔════╝██║    ██║              ║
# ║  ██║   ██║██║   ██║█████╗  ██████╔╝██║   ██║██║█████╗  ██║ █╗ ██║              ║
# ║  ██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗╚██╗ ██╔╝██║██╔══╝  ██║███╗██║              ║
# ║  ╚██████╔╝ ╚████╔╝ ███████╗██║  ██║ ╚████╔╝ ██║███████╗╚███╔███╔╝              ║
# ║   ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚══════╝ ╚══╝╚══╝               ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  workspace overview                                       ║
# ║  Visual workspace minimap with window layout, stats, and interactive navigation  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WS_OVERVIEW_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WS_OVERVIEW_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WORKSPACE MINIMAP RENDERER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_overview_minimap() {
    local ws_json="$1"  clients_json="$2"  active_id="$3"
    local cell_w="${4:-20}"  cell_h="${5:-8}"

    python3 - "$active_id" "$cell_w" "$cell_h" << PYEOF
import json, sys, os, math

wss      = json.loads("""${ws_json//\"/\\\"}""")
clients  = json.loads("""${clients_json//\"/\\\"}""")
act_id   = int(sys.argv[1]) if sys.argv[1].isdigit() else 0
cell_w   = int(sys.argv[2])
cell_h   = int(sys.argv[3])

no_color = os.environ.get('ASH_FLAG_NO_COLOR','0') == '1'
R      = '' if no_color else '\033[0m'
BOLD   = '' if no_color else '\033[1m'
DIM    = '' if no_color else '\033[38;2;108;112;134m'
DIM2   = '' if no_color else '\033[38;2;88;91;112m'
SKY    = '' if no_color else '\033[38;2;137;220;235m'
GRN    = '' if no_color else '\033[38;2;166;227;161m'
MAUVE  = '' if no_color else '\033[1;38;2;203;166;247m'
BLUE   = '' if no_color else '\033[38;2;137;180;250m'
TEAL   = '' if no_color else '\033[38;2;148;226;213m'
PEACH  = '' if no_color else '\033[38;2;250;179;135m'
YELL   = '' if no_color else '\033[38;2;249;226;175m'
BG_ACT = '' if no_color else '\033[48;2;40;40;60m'
BG_NRM = '' if no_color else '\033[48;2;24;24;37m'
BG_EMP = '' if no_color else '\033[48;2;18;18;28m'

# Index clients by workspace
ws_clients = {}
for c in clients:
    ws_id_c = c.get('workspace',{}).get('id')
    ws_clients.setdefault(ws_id_c, []).append(c)

# Determine grid layout
wss_sorted = sorted(wss, key=lambda w: w.get('id', 0))
n_ws = len(wss_sorted)

# Fit into columns
cols = min(n_ws, 5)
rows = math.ceil(n_ws / cols)

print(f'\n  {MAUVE}Workspace Overview  {DIM}({n_ws} workspaces){R}\n')

for row in range(rows):
    ws_row = wss_sorted[row * cols : (row + 1) * cols]

    # ── Top border ──────────────────────────────────────────────────────────────
    line_top = '  '
    for ws in ws_row:
        ws_id   = ws.get('id')
        is_act  = ws_id == act_id
        border_col = MAUVE if is_act else DIM2
        line_top += f'{border_col}╭{"─" * (cell_w - 2)}╮{R}  '
    print(line_top)

    # ── Workspace name row ───────────────────────────────────────────────────────
    line_name = '  '
    for ws in ws_row:
        ws_id   = ws.get('id')
        ws_name = ws.get('name', str(ws_id))
        ws_wins = ws.get('windows', 0)
        is_act  = ws_id == act_id
        bg      = BG_ACT if is_act else BG_NRM
        nc      = MAUVE  if is_act else SKY
        star    = '★ ' if is_act else '  '
        label   = f'{star}{ws_name}'[:cell_w - 6]
        wins_s  = f'{ws_wins}w'

        inner = f'{nc}{BOLD}{label}{R}{bg}{nc}'
        padding = cell_w - 2 - len(label) - len(wins_s)
        inner_full = f'{bg}{nc}{label}{R}{bg}{DIM}{" " * max(0,padding)}{wins_s}{R}'

        line_name += f'{MAUVE if is_act else DIM2}│{R}{inner_full}{MAUVE if is_act else DIM2}│{R}  '
    print(line_name)

    # ── Separator ────────────────────────────────────────────────────────────────
    line_sep = '  '
    for ws in ws_row:
        ws_id  = ws.get('id')
        is_act = ws_id == act_id
        bc = MAUVE if is_act else DIM2
        line_sep += f'{bc}├{"─" * (cell_w - 2)}┤{R}  '
    print(line_sep)

    # ── Window content rows ───────────────────────────────────────────────────────
    max_shown = cell_h - 4
    for wline in range(max_shown):
        line_cont = '  '
        for ws in ws_row:
            ws_id   = ws.get('id')
            is_act  = ws_id == act_id
            wins_ws = ws_clients.get(ws_id, [])
            bc      = MAUVE if is_act else DIM2
            bg      = BG_ACT if is_act else BG_NRM

            if wline < len(wins_ws):
                c = wins_ws[wline]
                cls   = c.get('class','?')[:cell_w // 2 - 1]
                title = c.get('title','?')[:cell_w // 2 - 2]
                float_m = '◈' if c.get('floating') else ' '
                pin_m   = '📌' if c.get('pinned')   else '  '
                inner   = f'{TEAL}{float_m}{BLUE}{cls[:6]}{DIM} {title[:cell_w - 12]}{R}'
                content_len = cell_w - 2
                # Pad to fill cell
                raw = f'{float_m}{cls[:6]} {title[:cell_w - 12]}'
                pad = ' ' * max(0, content_len - len(raw) - 1)
                line_cont += f'{bc}│{R}{bg}{TEAL}{float_m}{R}{bg}{BLUE}{cls[:6]}{R}{bg}{DIM} {title[:cell_w - 12]}{pad}{R}{bc}│{R}  '
            elif len(wins_ws) == 0 and wline == max_shown // 2:
                # Empty workspace indicator
                empty_msg = '  (empty)'
                pad = ' ' * max(0, cell_w - 2 - len(empty_msg))
                line_cont += f'{bc}│{R}{BG_EMP}{DIM2}{empty_msg}{pad}{R}{bc}│{R}  '
            else:
                pad = ' ' * (cell_w - 2)
                line_cont += f'{bc}│{R}{bg}{pad}{R}{bc}│{R}  '

        print(line_cont)

    # ── Bottom border ─────────────────────────────────────────────────────────────
    line_bot = '  '
    for ws in ws_row:
        ws_id  = ws.get('id')
        is_act = ws_id == act_id
        bc = MAUVE if is_act else DIM2
        line_bot += f'{bc}╰{"─" * (cell_w - 2)}╯{R}  '
    print(line_bot)
    print()

PYEOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  STATISTICS PANEL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_overview_stats() {
    local ws_json="$1"  clients_json="$2"  active_id="$3"

    python3 - "$active_id" << PYEOF
import json, sys, os

wss     = json.loads("""${ws_json//\"/\\\"}""")
clients = json.loads("""${clients_json//\"/\\\"}""")
act_id  = sys.argv[1]

no_color = os.environ.get('ASH_FLAG_NO_COLOR','0') == '1'
R     = '' if no_color else '\033[0m'
BOLD  = '' if no_color else '\033[1m'
DIM   = '' if no_color else '\033[38;2;108;112;134m'
SKY   = '' if no_color else '\033[38;2;137;220;235m'
GRN   = '' if no_color else '\033[38;2;166;227;161m'
MAUVE = '' if no_color else '\033[1;38;2;203;166;247m'
TEAL  = '' if no_color else '\033[38;2;148;226;213m'
PEACH = '' if no_color else '\033[38;2;250;179;135m'
YELL  = '' if no_color else '\033[38;2;249;226;175m'

total_ws  = len(wss)
total_win = len(clients)
floating  = sum(1 for c in clients if c.get('floating'))
pinned    = sum(1 for c in clients if c.get('pinned'))
empty_ws  = sum(1 for w in wss if w.get('windows',0) == 0)
max_ws    = max((w.get('windows',0) for w in wss), default=0)
most_pop  = next((w.get('name', str(w.get('id'))) for w in wss
                  if w.get('windows',0) == max_ws), '?') if max_ws > 0 else 'none'

classes   = {}
for c in clients:
    cls = c.get('class','unknown')
    classes[cls] = classes.get(cls, 0) + 1

top_apps = sorted(classes.items(), key=lambda x: -x[1])[:5]

def kv(k, v, c=GRN):
    print(f'  {DIM}{k:<26}{R} {c}{v}{R}')

kv('Total workspaces',   str(total_ws),   TEAL)
kv('Total windows',      str(total_win),  TEAL)
kv('Floating windows',   str(floating),   PEACH)
kv('Pinned windows',     str(pinned),     YELL)
kv('Empty workspaces',   str(empty_ws),   DIM)
kv('Busiest workspace',  f'{most_pop} ({max_ws} windows)', MAUVE)

if top_apps:
    print(f'\n  {DIM}Top applications:{R}')
    for cls, cnt in top_apps:
        bar_w = min(cnt * 2, 20)
        bar = '▇' * bar_w
        print(f'    {TEAL}{cls:<20}{R} {GRN}{bar:<20}{R} {DIM}{cnt}{R}')
PYEOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HYPREXPO INTEGRATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_overview_hyprexpo() {
    # Try to trigger hyprexpo plugin overview
    if hyprctl dispatch hyprexpo:expo toggle &>/dev/null 2>&1; then
        ws_ok "Hyprexpo overview triggered"
        return 0
    fi
    return 1
}

_overview_hyprspace() {
    # Try hyprspace plugin
    if hyprctl dispatch overview:toggle &>/dev/null 2>&1; then
        ws_ok "Hyprspace overview triggered"
        return 0
    fi
    return 1
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  INTERACTIVE OVERVIEW MODE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_overview_interactive() {
    local ws_json="$1"  clients_json="$2"  active_id="$3"

    command -v tput &>/dev/null || return 1

    tput civis 2>/dev/null || true
    trap 'tput cnorm 2>/dev/null; printf "\033[?25h\n"; exit 0' INT TERM EXIT

    local interval=2
    while true; do
        printf '\033[2J\033[H'

        printf '%s  👁️  WORKSPACE OVERVIEW  •  %s  •  q=quit  s=switch  n=next  p=prev%s\n\n' \
            "$(_wsdim)" "$(date '+%H:%M:%S')" "$(_wsr)"

        # Refresh data
        ws_json="$(ws_get_workspaces_json)"
        clients_json="$(ws_get_clients_json)"
        active_id="$(ws_get_active_id)"

        _overview_minimap "$ws_json" "$clients_json" "$active_id" 22 7

        printf '%s  ─────────────────────────────────────────────────────────%s\n' \
            "$(_wsdim)" "$(_wsr)"
        _overview_stats "$ws_json" "$clients_json" "$active_id"

        # Non-blocking key read
        if read -r -s -t "$interval" -n 1 key 2>/dev/null; then
            case "$key" in
                q|Q) break ;;
                n|N) ws_dispatch workspace "e+1" ;;
                p|P) ws_dispatch workspace "e-1" ;;
                s|S)
                    tput cnorm 2>/dev/null || true
                    printf '\n  %sSwitch to workspace: %s' "$(_wsyellow)" "$(_wsr)"
                    local ws_target; read -r ws_target
                    tput civis 2>/dev/null || true
                    [[ -n "$ws_target" ]] && {
                        ws_dispatch workspace "$ws_target" 2>/dev/null || \
                        ws_dispatch workspace "name:${ws_target}" 2>/dev/null || true
                    }
                    ;;
            esac
        fi
    done

    tput cnorm 2>/dev/null || true
    trap - INT TERM EXIT
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_ws_overview() {
    local mode="auto"  # auto | minimap | stats | interactive | plugin
    local cell_w=22  cell_h=7

    for arg in "${@:-}"; do
        case "$arg" in
            --minimap|-m)    mode="minimap"     ;;
            --stats|-s)      mode="stats"       ;;
            --interactive|-i) mode="interactive" ;;
            --plugin|-p)     mode="plugin"      ;;
            --cell-width=*)  cell_w="${arg#*=}" ;;
            --cell-height=*) cell_h="${arg#*=}" ;;
        esac
    done

    # Auto-detect: try native plugin first in auto mode
    if [[ "$mode" == "auto" ]]; then
        if _overview_hyprexpo 2>/dev/null || _overview_hyprspace 2>/dev/null; then
            return 0
        fi
        mode="minimap"
    fi

    ws_section "👁️ " "Workspace Overview" "$(_wsmauve)"

    local ws_json clients_json active_id
    ws_json="$(ws_get_workspaces_json)"
    clients_json="$(ws_get_clients_json)"
    active_id="$(ws_get_active_id)"

    ws_kv "Active"     "workspace ${active_id}"
    ws_kv "Total WS"   "$(ws_get_workspaces_json | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null)"
    ws_kv "Total WiNS" "$(ws_get_clients_json | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null)"

    case "$mode" in
        plugin)
            _overview_hyprexpo || _overview_hyprspace || {
                ws_warn "No Hyprland overview plugin found"
                ws_info "Install: hyprexpo or hyprspace Hyprland plugin"
                ws_info "Falling back to terminal minimap..."
                _overview_minimap "$ws_json" "$clients_json" "$active_id" "$cell_w" "$cell_h"
                _overview_stats "$ws_json" "$clients_json" "$active_id"
            }
            ;;
        minimap)
            _overview_minimap "$ws_json" "$clients_json" "$active_id" "$cell_w" "$cell_h"
            _overview_stats "$ws_json" "$clients_json" "$active_id"
            ;;
        stats)
            _overview_stats "$ws_json" "$clients_json" "$active_id"
            ;;
        interactive)
            _overview_interactive "$ws_json" "$clients_json" "$active_id"
            ;;
        *)
            _overview_minimap "$ws_json" "$clients_json" "$active_id" "$cell_w" "$cell_h"
            _overview_stats "$ws_json" "$clients_json" "$active_id"
            ;;
    esac

    ws_divider
    printf '\n'
}
