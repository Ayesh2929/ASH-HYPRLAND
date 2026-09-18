#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗███████╗██████╗  █████╗  ██████╗███████╗   ║
# ║  ██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝   ║
# ║  ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ ███████╗██████╔╝███████║██║     █████╗     ║
# ║  ██║███╗██║██║   ██║██╔══██╗██╔═██╗ ╚════██║██╔═══╝ ██╔══██║██║     ██╔══╝     ║
# ║  ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗███████║██║     ██║  ██║╚██████╗███████╗   ║
# ║   ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝   ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  WORKSPACE COMMAND DISPATCHER                            ║
# ║  Hyprland-native workspace management hub with animated UI                      ║
# ║                                                                                  ║
# ║  Author   : ash-dotfiles                                                         ║
# ║  License  : MIT                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CMD_WORKSPACE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CMD_WORKSPACE_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _WS_CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -gr _WS_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash/workspace"
declare -gr _WS_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ash/workspace"
declare -gr _WS_LAYOUT_FILE="${_WS_STATE_DIR}/layouts.json"
declare -gr _WS_NAMES_FILE="${_WS_STATE_DIR}/names.json"
declare -gr _WS_HISTORY_FILE="${_WS_STATE_DIR}/history.log"

# Named workspace icon map  (index → icon)
declare -gA WS_ICONS=(
    [1]=""   [2]=""   [3]=""   [4]=""   [5]=""
    [6]=""   [7]=""   [8]=""   [9]=""   [10]=""
)

# Custom workspace name overrides (load from names file)
declare -gA WS_NAMES=()

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CATPPUCCIN MOCHA PALETTE  (inline — zero external deps)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ws()      { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_wsr()     { _ws $'\033[0m';                          }
_wsbold()  { _ws $'\033[1m';                          }
_wsdim()   { _ws $'\033[38;2;108;112;134m';           }
_wsmauve() { _ws $'\033[1;38;2;203;166;247m';         }
_wsblue()  { _ws $'\033[38;2;137;180;250m';           }
_wsgreen() { _ws $'\033[38;2;166;227;161m';           }
_wspeach() { _ws $'\033[38;2;250;179;135m';           }
_wsyellow(){ _ws $'\033[1;38;2;249;226;175m';         }
_wsred()   { _ws $'\033[1;38;2;243;139;168m';         }
_wsteal()  { _ws $'\033[38;2;148;226;213m';           }
_wssky()   { _ws $'\033[38;2;137;220;235m';           }
_wslav()   { _ws $'\033[38;2;180;190;254m';           }
_wspink()  { _ws $'\033[38;2;245;194;231m';           }
_wssapph() { _ws $'\033[38;2;116;199;236m';           }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SHARED DISPLAY PRIMITIVES  (exported to sub-commands)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ws_section() {
    local icon="$1"  title="$2"  color="${3:-$(_wsmauve)}"
    printf '\n%s%s  %s%s\n' "$color" "$icon" "$title" "$(_wsr)"
    printf '%s  %s%s\n' "$(_wsdim)" "$(printf '─%.0s' $(seq 1 58))" "$(_wsr)"
}

ws_kv() {
    local key="$1"  val="$2"  vc="${3:-$(_wsgreen)}"
    printf '  %s%-26s%s %s%s%s\n' \
        "$(_wsdim)" "${key}:" "$(_wsr)" "$vc" "$val" "$(_wsr)"
}

ws_ok()    { printf '  %s✓%s  %s\n' "$(_wsgreen)"  "$(_wsr)" "$1"; }
ws_fail()  { printf '  %s✗%s  %s\n' "$(_wsred)"    "$(_wsr)" "$1"; }
ws_info()  { printf '  %sℹ%s  %s\n' "$(_wsdim)"    "$(_wsr)" "$1"; }
ws_warn()  { printf '  %s⚠%s  %s\n' "$(_wsyellow)" "$(_wsr)" "$1"; }
ws_step()  { printf '  %s→%s  %s\n' "$(_wsteal)"   "$(_wsr)" "$1"; }

ws_divider() {
    printf '%s  %s%s\n' "$(_wsdim)" "$(printf '─%.0s' $(seq 1 60))" "$(_wsr)"
}

ws_badge() {
    local text="$1"  color="${2:-$(_wsblue)}"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '%s%s\033[38;2;30;30;46m %s \033[0m' "$(_wsbold)" "$color" "$text"
    else
        printf '[%s]' "$text"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HYPRLAND IPC WRAPPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ws_require_hyprland() {
    if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        ws_fail "Hyprland is not running"
        ws_info "This command requires an active Hyprland session"
        return 1
    fi
    command -v hyprctl &>/dev/null || {
        ws_fail "hyprctl not found"
        ws_info "Install: paru -S hyprland"
        return 1
    }
}

ws_dispatch() {
    hyprctl dispatch "$@" &>/dev/null
}

ws_get_workspaces_json() {
    hyprctl workspaces -j 2>/dev/null || echo '[]'
}

ws_get_active_workspace_json() {
    hyprctl activeworkspace -j 2>/dev/null || echo '{}'
}

ws_get_clients_json() {
    hyprctl clients -j 2>/dev/null || echo '[]'
}

ws_get_monitors_json() {
    hyprctl monitors -j 2>/dev/null || echo '[]'
}

ws_get_active_id() {
    ws_get_active_workspace_json | \
        python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('id','1'))" \
        2>/dev/null || echo "1"
}

ws_get_active_name() {
    ws_get_active_workspace_json | \
        python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('name','1'))" \
        2>/dev/null || echo "1"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WORKSPACE NAME & ICON RESOLUTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ws_load_names() {
    [[ -f "$_WS_NAMES_FILE" ]] || return 0
    while IFS='=' read -r id name; do
        [[ -z "$id" ]] && continue
        WS_NAMES[$id]="$name"
    done < <(python3 -c "
import json
data = json.load(open('${_WS_NAMES_FILE}'))
for k,v in data.items():
    print(f'{k}={v}')
" 2>/dev/null || true)
}

ws_get_icon() {
    local id="$1"
    local icon="${WS_ICONS[$id]:-}"
    [[ -z "$icon" ]] && icon=""
    printf '%s' "$icon"
}

ws_get_display_name() {
    local id="$1"  name="$2"
    local custom="${WS_NAMES[$id]:-}"
    if [[ -n "$custom" ]]; then
        printf '%s' "$custom"
    elif [[ "$name" =~ ^[0-9]+$ ]]; then
        printf '%s' "$name"
    else
        printf '%s' "$name"
    fi
}

ws_save_name() {
    local id="$1"  name="$2"
    WS_NAMES[$id]="$name"

    # Persist to JSON
    local tmp_data="{}"
    [[ -f "$_WS_NAMES_FILE" ]] && tmp_data="$(cat "$_WS_NAMES_FILE" 2>/dev/null || echo '{}')"

    python3 - "$id" "$name" "$tmp_data" << 'PYEOF' > "${_WS_NAMES_FILE}.tmp" 2>/dev/null
import json, sys
ws_id, ws_name = sys.argv[1], sys.argv[2]
try:
    data = json.loads(sys.argv[3])
except:
    data = {}
data[ws_id] = ws_name
print(json.dumps(data, indent=2))
PYEOF
    mv "${_WS_NAMES_FILE}.tmp" "$_WS_NAMES_FILE" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WORKSPACE HISTORY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ws_log_history() {
    local ws_id="$1"
    local ts
    ts="$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')"
    printf '%s\t%s\n' "$ts" "$ws_id" >> "$_WS_HISTORY_FILE" 2>/dev/null || true
    # Keep last 200 entries
    if [[ -f "$_WS_HISTORY_FILE" ]]; then
        local lines
        lines="$(wc -l < "$_WS_HISTORY_FILE" 2>/dev/null || echo 0)"
        if (( lines > 200 )); then
            tail -200 "$_WS_HISTORY_FILE" > "${_WS_HISTORY_FILE}.tmp" && \
                mv "${_WS_HISTORY_FILE}.tmp" "$_WS_HISTORY_FILE" 2>/dev/null || true
        fi
    fi
}

ws_get_previous_id() {
    [[ -f "$_WS_HISTORY_FILE" ]] || return 1
    local current
    current="$(ws_get_active_id)"
    tac "$_WS_HISTORY_FILE" 2>/dev/null | \
        awk -F'\t' -v cur="$current" '$2 != cur {print $2; exit}' || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WORKSPACE STATUS FRAME  (used by status + watch)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ws_status_frame() {
    ws_section "🗂️ " "Workspace Status" "$(_wssky)"

    local active_json ws_json clients_json monitors_json
    active_json="$(ws_get_active_workspace_json)"
    ws_json="$(ws_get_workspaces_json)"
    clients_json="$(ws_get_clients_json)"
    monitors_json="$(ws_get_monitors_json)"

    python3 - << PYEOF
import json, os, sys

active   = json.loads("""${active_json//\"/\\\"}""") if '${active_json}' != '{}' else {}
wss      = json.loads("""${ws_json//\"/\\\"}""")     if '${ws_json}' != '[]'    else []
clients  = json.loads("""${clients_json//\"/\\\"}""")if '${clients_json}' != '[]' else []
monitors = json.loads("""${monitors_json//\"/\\\"}""")if '${monitors_json}' != '[]' else []

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
LAV    = '' if no_color else '\033[38;2;180;190;254m'

def kv(k,v,c=GRN):
    print(f'  {DIM}{k:<26}{R} {c}{v}{R}')

act_id   = active.get('id','?')
act_name = active.get('name','?')
act_wins = active.get('windows', 0)
last_win = active.get('lastwindowtitle','')[:40]

kv('Active workspace', f'{MAUVE}{act_name}{R}  ({act_id})')
kv('Windows in workspace', str(act_wins), TEAL)
if last_win:
    kv('Last window', last_win, DIM)

# Monitor workspace assignment
for mon in monitors:
    ws_mon = mon.get('activeWorkspace',{})
    print(f'  {DIM}{"Monitor "+mon.get("name","?")+"  :":<26}{R} '
          f'{SKY}workspace {ws_mon.get("id","?")}{R}  '
          f'{DIM}@ {mon.get("refreshRate",60):.0f}Hz{R}')

# Workspace bar visualisation
print(f'\n  {DIM}Workspaces:{R}')
ws_ids = {w.get("id"): w for w in wss}
all_ids = sorted(ws_ids.keys())
line = '  '
for ws_id in all_ids:
    ws = ws_ids[ws_id]
    name  = ws.get('name','?')
    wins  = ws.get('windows',0)
    is_act = ws_id == act_id

    if is_act:
        cell = f'{MAUVE}{BOLD}[{name}]{R}'
    elif wins > 0:
        cell = f'{SKY} {name} {R}'
    else:
        cell = f'{DIM} {name} {R}'

    line += cell + ' '

print(line)

# Window count per workspace
print(f'\n  {DIM}Per-workspace windows:{R}')
ws_win_count = {}
for c in clients:
    ws_c = c.get('workspace',{}).get('id')
    ws_win_count[ws_c] = ws_win_count.get(ws_c, 0) + 1

for ws_id in sorted(ws_ids.keys()):
    cnt = ws_win_count.get(ws_id, 0)
    ws  = ws_ids[ws_id]
    name = ws.get('name','?')
    bar = '█' * min(cnt, 15) if cnt else '·'
    col = PEACH if cnt > 5 else (TEAL if cnt > 0 else DIM)
    active_mark = f' {MAUVE}← active{R}' if ws_id == act_id else ''
    print(f'  {DIM}  {name:<6}{R} {col}{bar:<15}{R} {DIM}{cnt} window{"s" if cnt!=1 else ""}{R}{active_mark}')
PYEOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WATCH MODE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ws_watch() {
    local interval="${1:-1}"
    command -v tput &>/dev/null || { ws_fail "tput required"; return 1; }
    tput civis 2>/dev/null || true
    trap 'tput cnorm 2>/dev/null; exit 0' INT TERM EXIT
    while true; do
        printf '\033[2J\033[H'
        printf '%s  🗂️  WORKSPACE LIVE  •  %s  •  Ctrl+C to exit%s\n' \
            "$(_wsdim)" "$(date '+%H:%M:%S')" "$(_wsr)"
        ws_status_frame
        sleep "$interval"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  NOTIFICATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ws_notify() {
    local title="$1"  body="$2"
    [[ "${ASH_WS_NO_NOTIFY:-0}" -eq 1 ]] && return 0
    command -v notify-send &>/dev/null || return 0
    notify-send "$title" "$body" \
        --icon=view-list-symbolic \
        --expire-time=2000 \
        2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME INIT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ws_ensure_dirs() {
    mkdir -p "$_WS_STATE_DIR" "$_WS_CACHE_DIR" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SUB-COMMAND LOADER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ws_load_sub() {
    local sub="$1"
    local sub_file="${_WS_CMD_DIR}/${sub}.sh"
    if [[ ! -f "$sub_file" ]]; then
        printf '\n%s✗  workspace sub-command not found: %s%s\n\n' \
            "$(_wsred)" "$sub" "$(_wsr)" >&2
        return 1
    fi
    # shellcheck source=/dev/null
    source "$sub_file"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ws_help() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;148;226;213m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🗂️   ASH  ─  workspace  (Workspace Manager)              ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    local cc="$(_wssky)"  cd="$(_wsdim)"  cs="$(_wsmauve)"  cr="$(_wsr)"

    printf '\n%sUSAGE%s\n' "$(_wsbold)" "$cr"
    printf '   ash workspace [sub-command] [flags]\n'
    printf '   ash ws [sub-command] [flags]          (alias)\n\n'

    printf '%sSUB-COMMANDS%s\n\n' "$cs" "$cr"

    local -a cmds=(
        "status:🗂️ :Current workspace status and window map"
        "list:📋:List all workspaces with window counts"
        "switch:🔀:Switch to a workspace (by number, name, or direction)"
        "move-window:📦:Move active or selected window to workspace"
        "overview:👁️ :Visual workspace overview and minimap"
        "create:✨:Create a new named workspace"
        "rename:✏️ :Rename the current workspace"
        "delete:🗑️ :Delete an empty workspace"
        "back:⏪:Switch to previous workspace"
        "next:▶️ :Cycle to next workspace"
        "prev:◀️ :Cycle to previous workspace"
    )

    for entry in "${cmds[@]}"; do
        IFS=':' read -r cmd icon desc <<< "$entry"
        printf '   %s%s %-14s%s  %s%s%s\n' \
            "$cc" "$icon" "$cmd" "$cr" "$cd" "$desc" "$cr"
    done

    printf '\n%sFLAGS%s\n' "$cs" "$cr"
    printf '   %s--watch/-w%s       Live workspace monitor\n'         "$cc" "$cr"
    printf '   %s--json%s           Machine-readable JSON output\n'   "$cc" "$cr"
    printf '   %s--no-notify%s      Suppress desktop notifications\n' "$cc" "$cr"
    printf '   %s--silent/-s%s      No output, just execute\n'        "$cc" "$cr"

    printf '\n%sEXAMPLES%s\n' "$cs" "$cr"
    printf '   %sash ws status%s              Active workspace info\n'      "$cc" "$cr"
    printf '   %sash ws list%s                All workspaces\n'             "$cc" "$cr"
    printf '   %sash ws switch 3%s            Switch to workspace 3\n'     "$cc" "$cr"
    printf '   %sash ws switch code%s         Switch to named workspace\n' "$cc" "$cr"
    printf '   %sash ws move-window 2%s       Move window to ws 2\n'       "$cc" "$cr"
    printf '   %sash ws overview%s            Visual minimap\n'            "$cc" "$cr"
    printf '   %sash ws next%s                Cycle to next workspace\n'   "$cc" "$cr"
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN DISPATCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_cmd_workspace() {
    local sub="${1:-status}"
    shift || true

    local watch_mode=0
    local silent=0
    local -a fwd_args=()

    for arg in "${@:-}"; do
        case "$arg" in
            --watch|-w)        watch_mode=1                    ;;
            --no-notify)       export ASH_WS_NO_NOTIFY=1       ;;
            --json)            export ASH_FLAG_JSON_OUTPUT=1   ;;
            --silent|-s)       silent=1                        ;;
            *)                 fwd_args+=("$arg")              ;;
        esac
    done

    ws_ensure_dirs
    ws_load_names

    case "$sub" in
        help|-h|--help) _ws_help ;;

        status|info)
            ws_require_hyprland || return 1
            if [[ $watch_mode -eq 1 ]]; then
                _ws_watch 1
            else
                ws_status_frame
                printf '\n'
            fi
            ;;

        # Inline simple commands
        back|previous)
            ws_require_hyprland || return 1
            local prev_id
            prev_id="$(ws_get_previous_id)"
            if [[ -n "$prev_id" ]]; then
                ws_dispatch workspace "$prev_id"
                [[ $silent -eq 0 ]] && ws_ok "Switched to workspace ${prev_id}"
                ws_log_history "$prev_id"
            else
                [[ $silent -eq 0 ]] && ws_info "No previous workspace in history"
            fi
            ;;

        next)
            ws_require_hyprland || return 1
            ws_dispatch workspace "e+1"
            local new_id
            new_id="$(ws_get_active_id)"
            [[ $silent -eq 0 ]] && ws_ok "Switched to workspace ${new_id}"
            ws_log_history "$new_id"
            ;;

        prev)
            ws_require_hyprland || return 1
            ws_dispatch workspace "e-1"
            local new_id
            new_id="$(ws_get_active_id)"
            [[ $silent -eq 0 ]] && ws_ok "Switched to workspace ${new_id}"
            ws_log_history "$new_id"
            ;;

        create)
            ws_require_hyprland || return 1
            local ws_name="${fwd_args[0]:-}"
            if [[ -z "$ws_name" ]]; then
                printf '  %sWorkspace name: %s' "$(_wsyellow)" "$(_wsr)"
                read -r ws_name
            fi
            [[ -z "$ws_name" ]] && { ws_info "No name provided"; return 0; }
            ws_dispatch workspace "name:${ws_name}"
            ws_ok "Created and switched to: ${ws_name}"
            ws_notify "🗂️ Workspace" "Created: ${ws_name}"
            ;;

        rename)
            ws_require_hyprland || return 1
            local ws_name="${fwd_args[0]:-}"
            local current_id
            current_id="$(ws_get_active_id)"
            if [[ -z "$ws_name" ]]; then
                printf '  %sNew name for workspace %s: %s' \
                    "$(_wsyellow)" "$current_id" "$(_wsr)"
                read -r ws_name
            fi
            [[ -z "$ws_name" ]] && { ws_info "No name provided"; return 0; }
            ws_save_name "$current_id" "$ws_name"
            ws_ok "Workspace ${current_id} renamed to: ${ws_name}"
            ;;

        delete|remove)
            ws_require_hyprland || return 1
            local del_id="${fwd_args[0]:-$(ws_get_active_id)}"
            # Check if empty
            local win_count
            win_count="$(ws_get_workspaces_json | python3 -c "
import json,sys
wss = json.load(sys.stdin)
for w in wss:
    if str(w.get('id','')) == '${del_id}' or w.get('name') == '${del_id}':
        print(w.get('windows',0))
        break
else:
    print(0)
" 2>/dev/null || echo 0)"

            if (( win_count > 0 )); then
                ws_warn "Workspace ${del_id} has ${win_count} window(s)"
                ws_info "Move or close windows first"
                return 1
            fi
            ws_dispatch closewindow "" # placeholder — workspace auto-cleans in Hyprland
            ws_ok "Workspace ${del_id} will be removed when empty"
            ;;

        list|switch|move-window|overview)
            ws_require_hyprland || return 1
            # Normalize sub-command name for file lookup
            local sub_file_name="${sub//-/_}"
            _ws_load_sub "${sub/-/_}" || \
                _ws_load_sub "$sub" || return 1

            local fn="ash_ws_${sub//-/_}"
            declare -f "$fn" &>/dev/null && \
                "$fn" "${fwd_args[@]:-}" || {
                ws_fail "Function not found: ${fn}"
                return 1
            }
            ;;
        *)
            printf '\n%s✗  Unknown sub-command: %s%s\n' \
                "$(_wsred)" "$sub" "$(_wsr)" >&2
            printf '%sRun: ash workspace help%s\n\n' "$(_wsdim)" "$(_wsr)" >&2
            return 1
            ;;
    esac
}

# Alias
ash_cmd_ws() { ash_cmd_workspace "$@"; }
