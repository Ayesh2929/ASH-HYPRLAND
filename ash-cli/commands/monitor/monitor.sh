#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ███╗   ███╗ ██████╗ ███╗   ██╗██╗████████╗ ██████╗ ██████╗                    ║
# ║  ████╗ ████║██╔═══██╗████╗  ██║██║╚══██╔══╝██╔═══██╗██╔══██╗                   ║
# ║  ██╔████╔██║██║   ██║██╔██╗ ██║██║   ██║   ██║   ██║██████╔╝                   ║
# ║  ██║╚██╔╝██║██║   ██║██║╚██╗██║██║   ██║   ██║   ██║██╔══██╗                   ║
# ║  ██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██║   ██║   ╚██████╔╝██║  ██║                   ║
# ║  ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝                   ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  MONITOR COMMAND DISPATCHER                              ║
# ║  Complete display management hub for Hyprland / wlr-randr / xrandr              ║
# ║                                                                                  ║
# ║  Author   : ash-dotfiles                                                         ║
# ║  License  : MIT                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CMD_MONITOR_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CMD_MONITOR_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _MON_CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -gr _MON_ASH_ROOT="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}"
declare -gr _MON_CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
declare -gr _MON_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash/monitor"
declare -gr _MON_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ash/monitor"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CATPPUCCIN MOCHA PALETTE  (inline — zero external deps)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_m()       { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_mr()      { _m '\033[0m';                          }
_mbold()   { _m '\033[1m';                          }
_mdim()    { _m '\033[38;2;108;112;134m';           }
_mmauve()  { _m '\033[1;38;2;203;166;247m';         }
_mblue()   { _m '\033[38;2;137;180;250m';           }
_mgreen()  { _m '\033[38;2;166;227;161m';           }
_mpeach()  { _m '\033[38;2;250;179;135m';           }
_myellow() { _m '\033[1;38;2;249;226;175m';         }
_mred()    { _m '\033[1;38;2;243;139;168m';         }
_mteal()   { _m '\033[38;2;148;226;213m';           }
_msky()    { _m '\033[38;2;137;220;235m';           }
_mlav()    { _m '\033[38;2;180;190;254m';           }
_mpink()   { _m '\033[38;2;245;194;231m';           }
_msapph()  { _m '\033[38;2;116;199;236m';           }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SHARED DISPLAY PRIMITIVES  (exported to sub-commands)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

mon_section() {
    local icon="$1"  title="$2"  color="${3:-$(_mmauve)}"
    printf '\n%s%s  %s%s\n' "$color" "$icon" "$title" "$(_mr)"
    printf '%s  %s%s\n' "$(_mdim)" "$(printf '─%.0s' $(seq 1 58))" "$(_mr)"
}

mon_kv() {
    local key="$1"  val="$2"  vc="${3:-$(_mgreen)}"
    printf '  %s%-26s%s %s%s%s\n' \
        "$(_mdim)" "${key}:" "$(_mr)" "$vc" "$val" "$(_mr)"
}

mon_ok()    { printf '  %s✓%s  %s\n' "$(_mgreen)"  "$(_mr)" "$1"; }
mon_fail()  { printf '  %s✗%s  %s\n' "$(_mred)"    "$(_mr)" "$1"; }
mon_info()  { printf '  %sℹ%s  %s\n' "$(_mdim)"    "$(_mr)" "$1"; }
mon_warn()  { printf '  %s⚠%s  %s\n' "$(_myellow)" "$(_mr)" "$1"; }
mon_step()  { printf '  %s→%s  %s\n' "$(_mteal)"   "$(_mr)" "$1"; }

mon_divider() {
    printf '%s  %s%s\n' "$(_mdim)" "$(printf '─%.0s' $(seq 1 60))" "$(_mr)"
}

mon_badge() {
    local text="$1"  color="${2:-$(_mblue)}"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '%s%s\033[38;2;30;30;46m %s \033[0m' "$(_mbold)" "$color" "$text"
    else
        printf '[%s]' "$text"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BACKEND DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g MON_BACKEND=""

mon_detect_backend() {
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && \
       command -v hyprctl &>/dev/null; then
        MON_BACKEND="hyprland"
    elif command -v wlr-randr &>/dev/null && \
         [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        MON_BACKEND="wlr-randr"
    elif command -v swaymsg &>/dev/null && \
         [[ -n "${SWAYSOCK:-}" ]]; then
        MON_BACKEND="sway"
    elif command -v xrandr &>/dev/null && \
         [[ -n "${DISPLAY:-}" ]]; then
        MON_BACKEND="xrandr"
    else
        MON_BACKEND="none"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CORE MONITOR DATA FETCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Returns JSON array of monitor objects (normalised across backends)
mon_get_monitors_json() {
    case "$MON_BACKEND" in
        hyprland)
            hyprctl monitors -j 2>/dev/null || echo '[]'
            ;;
        wlr-randr|sway)
            # Normalise wlr-randr output into a JSON-like structure via python3
            python3 - << 'PYEOF' 2>/dev/null
import subprocess, json, sys, re

try:
    raw = subprocess.check_output(['wlr-randr'], text=True, stderr=subprocess.DEVNULL)
except Exception:
    print('[]')
    sys.exit(0)

monitors = []
current = None
for line in raw.splitlines():
    # New monitor header
    m = re.match(r'^(\S+)\s+"([^"]*)"', line)
    if m:
        if current:
            monitors.append(current)
        current = {
            'name': m.group(1),
            'description': m.group(2),
            'width': 0, 'height': 0,
            'refreshRate': 0,
            'x': 0, 'y': 0,
            'scale': 1.0,
            'disabled': False,
            'focused': False,
        }
        continue

    if current is None:
        continue

    if 'current mode:' in line:
        parts = line.split()
        try:
            idx = parts.index('mode:') + 1 if 'mode:' in parts else 0
            res = parts[idx].split('x')
            current['width']  = int(res[0])
            current['height'] = int(res[1])
        except:
            pass

    if 'Hz' in line and 'current' in line.lower():
        m2 = re.search(r'([\d.]+)\s*Hz', line)
        if m2:
            current['refreshRate'] = float(m2.group(1))

    if 'position:' in line:
        m3 = re.search(r'(\d+),(\d+)', line)
        if m3:
            current['x'] = int(m3.group(1))
            current['y'] = int(m3.group(2))

    if 'scale:' in line:
        m4 = re.search(r'scale:\s*([\d.]+)', line)
        if m4:
            current['scale'] = float(m4.group(1))

    if 'Enabled: no' in line or 'disabled' in line.lower():
        current['disabled'] = True

if current:
    monitors.append(current)

print(json.dumps(monitors, indent=2))
PYEOF
            ;;
        xrandr)
            python3 - << 'PYEOF' 2>/dev/null
import subprocess, json, re, sys

try:
    raw = subprocess.check_output(['xrandr'], text=True, stderr=subprocess.DEVNULL)
except:
    print('[]')
    sys.exit(0)

monitors = []
current = None
for line in raw.splitlines():
    m = re.match(r'^(\S+) (connected|disconnected)', line)
    if m:
        if current and current.get('_connected'):
            monitors.append(current)
        current = {
            'name': m.group(1),
            'description': m.group(1),
            'width': 0, 'height': 0,
            'refreshRate': 0,
            'x': 0, 'y': 0,
            'scale': 1.0,
            'disabled': m.group(2) == 'disconnected',
            'focused': False,
            '_connected': m.group(2) == 'connected',
        }
        # Parse geometry from header
        geo = re.search(r'(\d+)x(\d+)\+(\d+)\+(\d+)', line)
        if geo:
            current['width']  = int(geo.group(1))
            current['height'] = int(geo.group(2))
            current['x']      = int(geo.group(3))
            current['y']      = int(geo.group(4))
        continue

    if current and current.get('_connected') and '*' in line:
        hz = re.search(r'([\d.]+)\*', line)
        if hz:
            current['refreshRate'] = float(hz.group(1))

if current and current.get('_connected'):
    monitors.append(current)

for m in monitors:
    m.pop('_connected', None)
print(json.dumps(monitors, indent=2))
PYEOF
            ;;
        *)
            echo '[]'
            ;;
    esac
}

# Parse monitor JSON and return specific field for given monitor name
mon_get_field() {
    local name="$1"  field="$2"
    mon_get_monitors_json | python3 -c "
import json, sys
mons = json.load(sys.stdin)
m = next((x for x in mons if x.get('name') == '$name'), None)
if m:
    print(m.get('$field', ''))
" 2>/dev/null
}

# Get list of monitor names
mon_get_names() {
    mon_get_monitors_json | python3 -c "
import json, sys
mons = json.load(sys.stdin)
for m in mons:
    print(m.get('name',''))
" 2>/dev/null
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  APPLY MONITOR CONFIGURATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# mon_apply name width height refresh x y scale [extra_flags]
mon_apply() {
    local name="$1"  width="$2"  height="$3"  refresh="${4:-60}"
    local x="${5:-0}"  y="${6:-0}"  scale="${7:-1}"
    local extra="${8:-}"

    mon_step "Applying: ${name}  ${width}x${height}@${refresh}  pos:${x},${y}  scale:${scale}"

    case "$MON_BACKEND" in
        hyprland)
            hyprctl keyword monitor \
                "${name},${width}x${height}@${refresh},${x}x${y},${scale}" \
                2>/dev/null
            ;;
        wlr-randr)
            local args=( "wlr-randr" "--output" "$name"
                "--mode" "${width}x${height}@${refresh}.000000Hz"
                "--pos" "${x},${y}"
                "--scale" "$scale" )
            "${args[@]}" 2>/dev/null
            ;;
        sway)
            swaymsg "output ${name} resolution ${width}x${height} \
                     position ${x} ${y} scale ${scale}" 2>/dev/null
            ;;
        xrandr)
            xrandr --output "$name" \
                   --mode "${width}x${height}" \
                   --rate "$refresh" \
                   --pos "${x}x${y}" \
                   2>/dev/null
            ;;
    esac
}

# Save current config to Hyprland monitors.conf
mon_save_config() {
    local monitors_conf="${_MON_CFG_DIR}/monitors.conf"
    mkdir -p "$_MON_CFG_DIR" 2>/dev/null || true

    mon_step "Saving monitor config to ${monitors_conf}..."

    # Backup existing
    [[ -f "$monitors_conf" ]] && \
        cp "$monitors_conf" "${monitors_conf}.bak.$(date +%s)"

    # Generate new config from current Hyprland state
    if [[ "$MON_BACKEND" == "hyprland" ]]; then
        hyprctl monitors -j 2>/dev/null | python3 - "$monitors_conf" << 'PYEOF'
import json, sys

monitors = json.load(sys.stdin)
out_file = sys.argv[1]

lines = [
    "# ASH Monitor Configuration",
    "# Generated: " + __import__('datetime').datetime.now().isoformat(),
    ""
]

for m in monitors:
    name    = m.get('name', '?')
    width   = m.get('width', 1920)
    height  = m.get('height', 1080)
    hz      = m.get('refreshRate', 60)
    x       = m.get('x', 0)
    y       = m.get('y', 0)
    scale   = m.get('scale', 1)
    disabled = m.get('disabled', False)

    if disabled:
        lines.append(f"monitor={name},disable")
    else:
        lines.append(
            f"monitor={name},{width}x{height}@{hz:.3f},{x}x{y},{scale}"
        )

with open(out_file, 'w') as f:
    f.write('\n'.join(lines) + '\n')

print(f"Saved {len(monitors)} monitor(s) to {out_file}")
PYEOF
        mon_ok "Config saved"
    else
        mon_info "Config save only supported on Hyprland"
    fi
}

# Notification
mon_notify() {
    local title="$1"  body="$2"
    [[ "${ASH_MON_NO_NOTIFY:-0}" -eq 1 ]] && return 0
    command -v notify-send &>/dev/null || return 0
    notify-send "$title" "$body" --icon=video-display --expire-time=3000 \
        2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME INIT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

mon_ensure_dirs() {
    mkdir -p "$_MON_STATE_DIR" "$_MON_CACHE_DIR" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SUB-COMMAND LOADER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_mon_load_sub() {
    local sub="$1"
    local sub_file="${_MON_CMD_DIR}/${sub}.sh"
    if [[ ! -f "$sub_file" ]]; then
        printf '\n%s✗  monitor sub-command not found: %s%s\n\n' \
            "$(_mred)" "$sub" "$(_mr)" >&2
        return 1
    fi
    # shellcheck source=/dev/null
    source "$sub_file"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_mon_help() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;137;220;235m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🖥️   ASH  ─  monitor  (Display Manager)                  ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    local cc="$(_msky)"  cd="$(_mdim)"  cs="$(_mmauve)"  cr="$(_mr)"

    printf '\n%sUSAGE%s\n' "$(_mbold)" "$cr"
    printf '   ash monitor [sub-command] [flags]\n'
    printf '   ash mon [sub-command] [flags]          (alias)\n\n'

    printf '%sSUB-COMMANDS%s\n\n' "$cs" "$cr"
    local -a cmds=(
        "list:🖥️ :List all connected monitors with details"
        "layout:🗺️ :Arrange monitors (save/apply spatial layout)"
        "mirror:🪞:Mirror/clone display to another monitor"
        "extend:➕:Extend desktop across monitors"
        "resolution:📐:Change monitor resolution"
        "refresh-rate:⚡:Change monitor refresh rate"
    )
    for entry in "${cmds[@]}"; do
        IFS=':' read -r cmd icon desc <<< "$entry"
        printf '   %s%s %-14s%s  %s%s%s\n' \
            "$cc" "$icon" "$cmd" "$cr" "$cd" "$desc" "$cr"
    done

    printf '\n%sFLAGS%s\n' "$cs" "$cr"
    printf '   %s--monitor=NAME%s   Target specific monitor\n'    "$cc" "$cr"
    printf '   %s--save%s           Save config to monitors.conf\n' "$cc" "$cr"
    printf '   %s--no-notify%s      Suppress notifications\n'     "$cc" "$cr"
    printf '   %s--json%s           Output in JSON format\n'      "$cc" "$cr"
    printf '   %s--watch%s          Live monitor status\n'        "$cc" "$cr"

    printf '\n%sEXAMPLES%s\n' "$cs" "$cr"
    printf '   %sash mon list%s                    List all displays\n'         "$cc" "$cr"
    printf '   %sash mon resolution 2560x1440%s    Set resolution\n'            "$cc" "$cr"
    printf '   %sash mon refresh-rate 144%s         Set 144Hz\n'                "$cc" "$cr"
    printf '   %sash mon mirror DP-1 HDMI-A-1%s    Mirror DP-1 to HDMI-A-1\n'  "$cc" "$cr"
    printf '   %sash mon extend right%s             Extend to the right\n'      "$cc" "$cr"
    printf '   %sash mon layout --save%s            Save current layout\n'      "$cc" "$cr"
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WATCH MODE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_mon_watch() {
    local interval="${1:-2}"
    command -v tput &>/dev/null || { mon_fail "tput required"; return 1; }
    tput civis 2>/dev/null || true
    trap 'tput cnorm 2>/dev/null; exit 0' INT TERM EXIT
    while true; do
        printf '\033[2J\033[H'
        printf '%s  🖥️  MONITOR LIVE  •  %s  •  Ctrl+C to exit%s\n' \
            "$(_mdim)" "$(date '+%H:%M:%S')" "$(_mr)"
        _mon_load_sub list &>/dev/null
        ash_monitor_list 2>/dev/null || true
        sleep "$interval"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN DISPATCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_cmd_monitor() {
    local sub="${1:-list}"
    shift || true

    local watch_mode=0
    local watch_interval=2
    local -a fwd_args=()

    for arg in "${@:-}"; do
        case "$arg" in
            --no-notify)       export ASH_MON_NO_NOTIFY=1    ;;
            --json)            export ASH_FLAG_JSON_OUTPUT=1  ;;
            --watch|-w)        watch_mode=1                   ;;
            --watch=*)         watch_mode=1; watch_interval="${arg#*=}" ;;
            --save)            export ASH_MON_SAVE=1          ;;
            *)                 fwd_args+=("$arg")             ;;
        esac
    done

    mon_ensure_dirs
    mon_detect_backend

    case "$sub" in
        help|-h|--help) _mon_help ;;

        list|layout|mirror|extend|resolution|refresh-rate)
            if [[ $watch_mode -eq 1 ]] && [[ "$sub" == "list" ]]; then
                _mon_watch "$watch_interval"
                return 0
            fi

            _mon_load_sub "${sub//-/_}" || return 1
            local fn="ash_monitor_${sub//-/_}"
            declare -f "$fn" &>/dev/null && \
                "$fn" "${fwd_args[@]:-}" || {
                mon_fail "Function not found: ${fn}"
                return 1
            }
            ;;
        *)
            printf '\n%s✗  Unknown sub-command: %s%s\n' \
                "$(_mred)" "$sub" "$(_mr)" >&2
            printf '%sRun: ash monitor help%s\n\n' "$(_mdim)" "$(_mr)" >&2
            return 1
            ;;
    esac
}

# Alias
ash_cmd_mon() { ash_cmd_monitor "$@"; }
