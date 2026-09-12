#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██╗    ██╗██╗███╗   ██╗██████╗  ██████╗ ██╗    ██╗                             ║
# ║  ██║    ██║██║████╗  ██║██╔══██╗██╔═══██╗██║    ██║                             ║
# ║  ██║ █╗ ██║██║██╔██╗ ██║██║  ██║██║   ██║██║ █╗ ██║                             ║
# ║  ██║███╗██║██║██║╚██╗██║██║  ██║██║   ██║██║███╗██║                             ║
# ║  ╚███╔███╔╝██║██║ ╚████║██████╔╝╚██████╔╝╚███╔███╔╝                             ║
# ║   ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝╚═════╝  ╚═════╝  ╚══╝╚══╝                              ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  WINDOW COMMAND DISPATCHER                               ║
# ║  Hyprland-native window management hub with 9 specialized modules               ║
# ║                                                                                  ║
# ║  Author   : ash-dotfiles                                                         ║
# ║  License  : MIT                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CMD_WINDOW_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CMD_WINDOW_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _WIN_CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -gr _WIN_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash/window"
declare -gr _WIN_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ash/window"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CATPPUCCIN MOCHA PALETTE  (inline — zero external deps)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_w()       { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_wr()      { _w '\033[0m';                          }
_wbold()   { _w '\033[1m';                          }
_wdim()    { _w '\033[38;2;108;112;134m';           }
_wmauve()  { _w '\033[1;38;2;203;166;247m';         }
_wblue()   { _w '\033[38;2;137;180;250m';           }
_wgreen()  { _w '\033[38;2;166;227;161m';           }
_wpeach()  { _w '\033[38;2;250;179;135m';           }
_wyellow() { _w '\033[1;38;2;249;226;175m';         }
_wred()    { _w '\033[1;38;2;243;139;168m';         }
_wteal()   { _w '\033[38;2;148;226;213m';           }
_wsky()    { _w '\033[38;2;137;220;235m';           }
_wlav()    { _w '\033[38;2;180;190;254m';           }
_wpink()   { _w '\033[38;2;245;194;231m';           }
_wsapph()  { _w '\033[38;2;116;199;236m';           }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SHARED DISPLAY PRIMITIVES  (exported to sub-commands)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

win_section() {
    local icon="$1"  title="$2"  color="${3:-$(_wmauve)}"
    printf '\n%s%s  %s%s\n' "$color" "$icon" "$title" "$(_wr)"
    printf '%s  %s%s\n' "$(_wdim)" "$(printf '─%.0s' $(seq 1 58))" "$(_wr)"
}

win_kv() {
    local key="$1"  val="$2"  vc="${3:-$(_wgreen)}"
    printf '  %s%-26s%s %s%s%s\n' \
        "$(_wdim)" "${key}:" "$(_wr)" "$vc" "$val" "$(_wr)"
}

win_ok()    { printf '  %s✓%s  %s\n' "$(_wgreen)"  "$(_wr)" "$1"; }
win_fail()  { printf '  %s✗%s  %s\n' "$(_wred)"    "$(_wr)" "$1"; }
win_info()  { printf '  %sℹ%s  %s\n' "$(_wdim)"    "$(_wr)" "$1"; }
win_warn()  { printf '  %s⚠%s  %s\n' "$(_wyellow)" "$(_wr)" "$1"; }
win_step()  { printf '  %s→%s  %s\n' "$(_wteal)"   "$(_wr)" "$1"; }

win_divider() {
    printf '%s  %s%s\n' "$(_wdim)" "$(printf '─%.0s' $(seq 1 60))" "$(_wr)"
}

win_badge() {
    local text="$1"  color="${2:-$(_wblue)}"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '%s%s\033[38;2;30;30;46m %s \033[0m' "$(_wbold)" "$color" "$text"
    else
        printf '[%s]' "$text"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HYPRLAND PREREQUISITE CHECK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

win_require_hyprland() {
    if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        win_fail "Hyprland is not running"
        win_info "This command requires an active Hyprland session"
        return 1
    fi
    if ! command -v hyprctl &>/dev/null; then
        win_fail "hyprctl not found"
        win_info "Install: paru -S hyprland"
        return 1
    fi
    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HYPRLAND IPC WRAPPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

win_dispatch() {
    hyprctl dispatch "$@" &>/dev/null
}

win_get_active_json() {
    hyprctl activewindow -j 2>/dev/null || echo '{}'
}

win_get_clients_json() {
    hyprctl clients -j 2>/dev/null || echo '[]'
}

win_get_active_field() {
    local field="$1"
    win_get_active_json | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('${field}',''))
" 2>/dev/null
}

win_get_clients_count() {
    win_get_clients_json | python3 -c "
import json,sys; print(len(json.load(sys.stdin)))
" 2>/dev/null || echo 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  ACTIVE WINDOW SNAPSHOT  (used by status and sub-commands)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

win_active_frame() {
    win_section "🪟" "Active Window" "$(_wsky)"

    local win_json
    win_json="$(win_get_active_json)"

    python3 - << PYEOF
import json, sys, os

d = json.loads("""${win_json//\"/\\\"}""") if '${win_json}' != '{}' else {}
no_color = os.environ.get('ASH_FLAG_NO_COLOR','0') == '1'

R    = '' if no_color else '\033[0m'
BOLD = '' if no_color else '\033[1m'
DIM  = '' if no_color else '\033[38;2;108;112;134m'
SKY  = '' if no_color else '\033[38;2;137;220;235m'
GRN  = '' if no_color else '\033[38;2;166;227;161m'
MAUVE= '' if no_color else '\033[38;2;203;166;247m'
PEACH= '' if no_color else '\033[38;2;250;179;135m'
TEAL = '' if no_color else '\033[38;2;148;226;213m'
YELL = '' if no_color else '\033[38;2;249;226;175m'

def kv(k,v,c=GRN):
    print(f'  {DIM}{k:<26}{R} {c}{v}{R}')

if not d:
    print(f'  {DIM}No active window{R}')
    sys.exit(0)

title    = d.get('title','?')[:60]
cls      = d.get('class','?')
addr     = d.get('address','?')
ws       = d.get('workspace',{}).get('name','?')
floating = d.get('floating',False)
pinned   = d.get('pinned',False)
fullscr  = d.get('fullscreen',False)
monitor  = d.get('monitor',0)
at       = d.get('at',[0,0])
sz       = d.get('size',[0,0])
pid      = d.get('pid',0)

print(f'\n  {BOLD}{SKY}🪟  {title}{R}')
print(f'  {DIM}   {cls}{R}')
print(f'  {DIM}  {"─"*52}{R}')

kv('Class',     cls)
kv('Title',     title[:50])
kv('Workspace', ws,    TEAL)
kv('Monitor',   str(monitor), TEAL)
kv('Position',  f'{at[0]},{at[1]}   (X,Y)')
kv('Size',      f'{sz[0]}×{sz[1]}   px')
kv('PID',       str(pid), DIM)
kv('Address',   addr[:14] + '…', DIM)

flags = []
if floating: flags.append(f'{PEACH}floating{R}')
if pinned:   flags.append(f'{YELL}pinned{R}')
if fullscr:  flags.append(f'{MAUVE}fullscreen{R}')
if flags:
    print(f'  {DIM}{"Flags:":<26}{R} ' + '  '.join(flags))
PYEOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WINDOW PICKER  (fzf or numbered list)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

win_pick_window() {
    local prompt="${1:-Select window}"

    local clients_json
    clients_json="$(win_get_clients_json)"

    if command -v fzf &>/dev/null; then
        python3 - << PYEOF | \
            fzf --prompt "  🪟  ${prompt}: " \
                --height=20 \
                --border=rounded \
                --ansi \
                --color="hl:$(printf '%s' "$(_wmauve)" | sed 's/\033\[//;s/m//')" \
                --header="↵=select  ESC=cancel" \
                2>/dev/null | awk '{print $1}'
import json, sys

clients = json.loads("""${clients_json}""")
for c in clients:
    addr = c.get('address','?')
    cls  = c.get('class','?')[:20]
    title = c.get('title','?')[:35]
    ws   = c.get('workspace',{}).get('name','?')
    print(f'{addr}  [{ws}]  {cls:<20}  {title}')
PYEOF
    else
        # Fallback: numbered list
        local -a addresses=()
        local i=0

        printf '\n  %sOpen windows:%s\n\n' "$(_wdim)" "$(_wr)"
        printf '  %s%-6s %-20s %-12s %s%s\n' \
            "$(_wdim)" "Num" "Class" "Workspace" "Title" "$(_wr)"
        printf '  %s%s%s\n' "$(_wdim)" "$(printf '─%.0s' $(seq 1 60))" "$(_wr)"

        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            local addr cls ws title
            addr="$(  printf '%s' "$line" | awk -F'\t' '{print $1}')"
            cls="$(   printf '%s' "$line" | awk -F'\t' '{print $2}')"
            ws="$(    printf '%s' "$line" | awk -F'\t' '{print $3}')"
            title="$( printf '%s' "$line" | awk -F'\t' '{print $4}')"

            (( i++ )) || true
            addresses+=("$addr")

            printf '  %s%3d%s  %s%-20s%s %-12s %s%s%s\n' \
                "$(_wpeach)" "$i" "$(_wr)" \
                "$(_wsky)"   "${cls:0:19}" "$(_wr)" \
                "${ws:0:11}" \
                "$(_wdim)"   "${title:0:30}" "$(_wr)"
        done < <(python3 - << PYEOF
import json, sys
clients = json.loads("""${clients_json}""")
for c in clients:
    print('\t'.join([
        c.get('address','?'),
        c.get('class','?'),
        c.get('workspace',{}).get('name','?'),
        c.get('title','?'),
    ]))
PYEOF
)

        printf '\n  %sEnter number [1-%d]: %s' "$(_wyellow)" "$i" "$(_wr)"
        local choice; read -r choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && \
           (( choice >= 1 )) && (( choice <= ${#addresses[@]} )); then
            printf '%s' "${addresses[$((choice-1))]}"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  NOTIFICATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

win_notify() {
    local title="$1"  body="$2"
    [[ "${ASH_WIN_NO_NOTIFY:-0}" -eq 1 ]] && return 0
    command -v notify-send &>/dev/null || return 0
    notify-send "$title" "$body" \
        --icon=window-restore \
        --expire-time=2000 \
        2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME INIT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

win_ensure_dirs() {
    mkdir -p "$_WIN_STATE_DIR" "$_WIN_CACHE_DIR" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SUB-COMMAND LOADER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_win_load_sub() {
    local sub="$1"
    local sub_file="${_WIN_CMD_DIR}/${sub}.sh"
    if [[ ! -f "$sub_file" ]]; then
        printf '\n%s✗  window sub-command not found: %s%s\n\n' \
            "$(_wred)" "$sub" "$(_wr)" >&2
        return 1
    fi
    # shellcheck source=/dev/null
    source "$sub_file"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WATCH MODE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_win_watch() {
    local interval="${1:-1}"
    command -v tput &>/dev/null || { win_fail "tput required"; return 1; }
    tput civis 2>/dev/null || true
    trap 'tput cnorm 2>/dev/null; exit 0' INT TERM EXIT
    while true; do
        printf '\033[2J\033[H'
        printf '%s  🪟 WINDOW LIVE  •  %s  •  Ctrl+C to exit%s\n' \
            "$(_wdim)" "$(date '+%H:%M:%S')" "$(_wr)"
        win_active_frame
        sleep "$interval"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_win_help() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;137;220;235m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🪟  ASH  ─  window  (Window Manager)                    ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    local cc="$(_wsky)"  cd="$(_wdim)"  cs="$(_wmauve)"  cr="$(_wr)"

    printf '\n%sUSAGE%s\n' "$(_wbold)" "$cr"
    printf '   ash window [sub-command] [flags]\n'
    printf '   ash win [sub-command] [flags]          (alias)\n\n'

    printf '%sSUB-COMMANDS%s\n\n' "$cs" "$cr"

    local -a cmds=(
        "status:🪟:Show active window details"
        "list:📋:List all open windows"
        "focus:🎯:Focus a window by title/class/address"
        "move:📦:Move window to position or edge"
        "resize:📐:Resize window (absolute or delta)"
        "close:✕:Close window(s)"
        "pin:📌:Pin window on all workspaces"
        "float:🎈:Toggle or set float mode"
        "fullscreen:⛶:Toggle or set fullscreen mode"
    )

    for entry in "${cmds[@]}"; do
        IFS=':' read -r cmd icon desc <<< "$entry"
        printf '   %s%s %-14s%s  %s%s%s\n' \
            "$cc" "$icon" "$cmd" "$cr" "$cd" "$desc" "$cr"
    done

    printf '\n%sFLAGS%s\n' "$cs" "$cr"
    printf '   %s--watch/-w%s       Live window monitor\n'          "$cc" "$cr"
    printf '   %s--json%s           Machine-readable JSON output\n'  "$cc" "$cr"
    printf '   %s--no-notify%s      Suppress desktop notifications\n' "$cc" "$cr"
    printf '   %s--address=ADDR%s   Target window by hex address\n'  "$cc" "$cr"

    printf '\n%sEXAMPLES%s\n' "$cs" "$cr"
    printf '   %sash win status%s             Active window info\n'        "$cc" "$cr"
    printf '   %sash win list%s               All open windows\n'          "$cc" "$cr"
    printf '   %sash win focus firefox%s      Focus by class/title\n'      "$cc" "$cr"
    printf '   %sash win move 200 150%s       Move to X,Y\n'               "$cc" "$cr"
    printf '   %sash win resize 1280 720%s    Resize to WxH\n'             "$cc" "$cr"
    printf '   %sash win float toggle%s       Toggle floating\n'           "$cc" "$cr"
    printf '   %sash win fullscreen%s         Toggle fullscreen\n'         "$cc" "$cr"
    printf '   %sash win pin%s                Pin to all workspaces\n'     "$cc" "$cr"
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN DISPATCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_cmd_window() {
    local sub="${1:-status}"
    shift || true

    local watch_mode=0
    local -a fwd_args=()

    for arg in "${@:-}"; do
        case "$arg" in
            --watch|-w)    watch_mode=1                   ;;
            --no-notify)   export ASH_WIN_NO_NOTIFY=1     ;;
            --json)        export ASH_FLAG_JSON_OUTPUT=1  ;;
            *)             fwd_args+=("$arg")             ;;
        esac
    done

    win_ensure_dirs

    case "$sub" in
        help|-h|--help) _win_help ;;

        status|info|active)
            win_require_hyprland || return 1
            if [[ $watch_mode -eq 1 ]]; then
                _win_watch 1
            else
                win_active_frame
                printf '\n'
            fi
            ;;

        list|focus|move|resize|close|pin|float|fullscreen)
            win_require_hyprland || return 1
            _win_load_sub "$sub" || return 1
            local fn="ash_win_${sub}"
            declare -f "$fn" &>/dev/null && \
                "$fn" "${fwd_args[@]:-}" || {
                win_fail "Function not found: ${fn}"
                return 1
            }
            ;;
        *)
            printf '\n%s✗  Unknown sub-command: %s%s\n' \
                "$(_wred)" "$sub" "$(_wr)" >&2
            printf '%sRun: ash window help%s\n\n' "$(_wdim)" "$(_wr)" >&2
            return 1
            ;;
    esac
}

# Alias
ash_cmd_win() { ash_cmd_window "$@"; }
