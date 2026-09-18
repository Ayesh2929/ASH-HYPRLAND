#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║   █████╗ ██╗   ██╗██████╗ ██╗ ██████╗                                           ║
# ║  ██╔══██╗██║   ██║██╔══██╗██║██╔═══██╗                                          ║
# ║  ███████║██║   ██║██║  ██║██║██║   ██║                                          ║
# ║  ██╔══██║██║   ██║██║  ██║██║██║   ██║                                          ║
# ║  ██║  ██║╚██████╔╝██████╔╝██║╚██████╔╝                                          ║
# ║  ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝ ╚═════╝                                           ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  AUDIO COMMAND DISPATCHER                                ║
# ║  PipeWire-native audio management hub with 6 specialized modules                ║
# ║                                                                                  ║
# ║  Author   : ash-dotfiles                                                         ║
# ║  License  : MIT                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CMD_AUDIO_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CMD_AUDIO_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _AUD_CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -gr _AUD_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash/audio"
declare -gr _AUD_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ash/audio"
declare -gr _AUD_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ash/audio"
declare -gr _AUD_EQ_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/easyeffects/output"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CATPPUCCIN MOCHA PALETTE  (inline — zero external deps)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_a()       { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_ar()      { _a $'\033[0m';                          }
_abold()   { _a $'\033[1m';                          }
_adim()    { _a $'\033[38;2;108;112;134m';           }
_amauve()  { _a $'\033[1;38;2;203;166;247m';         }
_ablue()   { _a $'\033[38;2;137;180;250m';           }
_agreen()  { _a $'\033[38;2;166;227;161m';           }
_apeach()  { _a $'\033[38;2;250;179;135m';           }
_ayellow() { _a $'\033[1;38;2;249;226;175m';         }
_ared()    { _a $'\033[1;38;2;243;139;168m';         }
_ateal()   { _a $'\033[38;2;148;226;213m';           }
_asky()    { _a $'\033[38;2;137;220;235m';           }
_alav()    { _a $'\033[38;2;180;190;254m';           }
_apink()   { _a $'\033[38;2;245;194;231m';           }
_asapph()  { _a $'\033[38;2;116;199;236m';           }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SHARED DISPLAY PRIMITIVES  (exported for sub-commands)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

aud_section() {
    local icon="$1"  title="$2"  color="${3:-$(_amauve)}"
    printf '\n%s%s  %s%s\n' "$color" "$icon" "$title" "$(_ar)"
    printf '%s  %s%s\n' "$(_adim)" "$(printf '─%.0s' $(seq 1 58))" "$(_ar)"
}

aud_kv() {
    local key="$1"  val="$2"  vc="${3:-$(_agreen)}"
    printf '  %s%-26s%s %s%s%s\n' \
        "$(_adim)" "${key}:" "$(_ar)" "$vc" "$val" "$(_ar)"
}

aud_ok()    { printf '  %s✓%s  %s\n' "$(_agreen)"  "$(_ar)" "$1"; }
aud_fail()  { printf '  %s✗%s  %s\n' "$(_ared)"    "$(_ar)" "$1"; }
aud_info()  { printf '  %sℹ%s  %s\n' "$(_adim)"    "$(_ar)" "$1"; }
aud_warn()  { printf '  %s⚠%s  %s\n' "$(_ayellow)" "$(_ar)" "$1"; }
aud_step()  { printf '  %s→%s  %s\n' "$(_ateal)"   "$(_ar)" "$1"; }

aud_divider() {
    printf '%s  %s%s\n' "$(_adim)" "$(printf '─%.0s' $(seq 1 60))" "$(_ar)"
}

aud_badge() {
    local text="$1"  color="${2:-$(_ablue)}"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '%s%s\033[38;2;30;30;46m %s \033[0m' "$(_abold)" "$color" "$text"
    else
        printf '[%s]' "$text"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PIPEWIRE / PULSEAUDIO BACKEND DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g AUD_BACKEND=""
declare -g AUD_HAS_WPCTL=0
declare -g AUD_HAS_PAMIXER=0
declare -g AUD_HAS_PACTL=0
declare -g AUD_HAS_PW_CLI=0

aud_detect_backend() {
    command -v wpctl   &>/dev/null && AUD_HAS_WPCTL=1
    command -v pamixer &>/dev/null && AUD_HAS_PAMIXER=1
    command -v pactl   &>/dev/null && AUD_HAS_PACTL=1
    command -v pw-cli  &>/dev/null && AUD_HAS_PW_CLI=1

    if pgrep -x pipewire &>/dev/null; then
        AUD_BACKEND="pipewire"
    elif pgrep -x pulseaudio &>/dev/null; then
        AUD_BACKEND="pulseaudio"
    elif command -v aplay &>/dev/null; then
        AUD_BACKEND="alsa"
    else
        AUD_BACKEND="none"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  UNIFIED VOLUME GETTER / SETTER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

aud_get_volume() {
    local sink="${1:-@DEFAULT_AUDIO_SINK@}"
    if [[ $AUD_HAS_WPCTL -eq 1 ]]; then
        wpctl get-volume "$sink" 2>/dev/null | \
            awk '{printf "%.0f", $2 * 100}'
    elif [[ $AUD_HAS_PAMIXER -eq 1 ]]; then
        pamixer --get-volume 2>/dev/null
    elif [[ $AUD_HAS_PACTL -eq 1 ]]; then
        pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | \
            grep -oP '\d+(?=%)' | head -1
    else
        echo "?"
    fi
}

aud_set_volume() {
    local pct="$1"  sink="${2:-@DEFAULT_AUDIO_SINK@}"
    local vol
    vol="$(printf '%.2f' "$(echo "$pct / 100" | bc -l 2>/dev/null || echo 1)")"

    if [[ $AUD_HAS_WPCTL -eq 1 ]]; then
        wpctl set-volume "$sink" "${vol}" 2>/dev/null
    elif [[ $AUD_HAS_PAMIXER -eq 1 ]]; then
        pamixer --set-volume "$pct" 2>/dev/null
    elif [[ $AUD_HAS_PACTL -eq 1 ]]; then
        pactl set-sink-volume @DEFAULT_SINK@ "${pct}%" 2>/dev/null
    fi
}

aud_is_muted() {
    local sink="${1:-@DEFAULT_AUDIO_SINK@}"
    if [[ $AUD_HAS_WPCTL -eq 1 ]]; then
        wpctl get-volume "$sink" 2>/dev/null | grep -q 'MUTED'
    elif [[ $AUD_HAS_PAMIXER -eq 1 ]]; then
        pamixer --get-mute 2>/dev/null | grep -q 'true'
    elif [[ $AUD_HAS_PACTL -eq 1 ]]; then
        pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q 'yes'
    fi
}

aud_set_mute() {
    local state="$1"  sink="${2:-@DEFAULT_AUDIO_SINK@}"  # toggle | true | false
    if [[ $AUD_HAS_WPCTL -eq 1 ]]; then
        case "$state" in
            toggle) wpctl set-mute "$sink" toggle 2>/dev/null ;;
            true)   wpctl set-mute "$sink" 1      2>/dev/null ;;
            false)  wpctl set-mute "$sink" 0      2>/dev/null ;;
        esac
    elif [[ $AUD_HAS_PAMIXER -eq 1 ]]; then
        case "$state" in
            toggle) pamixer --toggle-mute 2>/dev/null ;;
            true)   pamixer --mute        2>/dev/null ;;
            false)  pamixer --unmute      2>/dev/null ;;
        esac
    elif [[ $AUD_HAS_PACTL -eq 1 ]]; then
        case "$state" in
            toggle) pactl set-sink-mute @DEFAULT_SINK@ toggle 2>/dev/null ;;
            true)   pactl set-sink-mute @DEFAULT_SINK@ 1      2>/dev/null ;;
            false)  pactl set-sink-mute @DEFAULT_SINK@ 0      2>/dev/null ;;
        esac
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  AUDIO STATUS SNAPSHOT  (used by status sub-command and watch mode)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

aud_status_frame() {
    aud_section "🔊" "Audio Status" "$(_asky)"

    aud_kv "Backend"    "$AUD_BACKEND"
    aud_kv "PipeWire"   "$(pgrep -x pipewire   &>/dev/null && echo 'running' || echo 'not running')"
    aud_kv "WirePlumber" "$(pgrep -x wireplumber &>/dev/null && echo 'running' || echo 'not running')"

    local vol muted_str
    vol="$(aud_get_volume)"
    aud_is_muted && muted_str="${_ared}MUTED${_ar}" || muted_str="${_agreen}unmuted${_ar}"

    # Volume bar
    local bar_w=30
    local vol_int="${vol:-0}"
    [[ "$vol_int" =~ ^[0-9]+$ ]] || vol_int=0
    local filled=$(( vol_int * bar_w / 100 ))
    (( filled > bar_w )) && filled=$bar_w
    local empty=$(( bar_w - filled ))

    local vol_color
    if   (( vol_int >= 100 )); then vol_color="$(_ared)"
    elif (( vol_int >= 80  )); then vol_color="$(_ayellow)"
    elif (( vol_int >= 40  )); then vol_color="$(_agreen)"
    else                            vol_color="$(_ablue)"
    fi

    printf '\n  %s🔊%s  %s%s%s%s%s  %s%d%%%s  %s\n\n' \
        "$(_agreen)" "$(_ar)" \
        "$vol_color" "$(printf '█%.0s' $(seq 1 $filled))" \
        "$(_adim)"   "$(printf '░%.0s' $(seq 1 $empty))" \
        "$(_ar)" \
        "$(_abold)$vol_color" "$vol_int" "$(_ar)" \
        "$muted_str"

    # Default sink/source
    if [[ $AUD_HAS_WPCTL -eq 1 ]]; then
        local default_sink default_source
        default_sink="$(wpctl status 2>/dev/null | \
            awk '/Sinks:/{p=1} p && /\*/{print; exit}' | \
            sed 's/.*\. //' | cut -c1-50)"
        default_source="$(wpctl status 2>/dev/null | \
            awk '/Sources:/{p=1} p && /\*/{print; exit}' | \
            sed 's/.*\. //' | cut -c1-50)"

        [[ -n "$default_sink"   ]] && aud_kv "Sink"   "$default_sink"
        [[ -n "$default_source" ]] && aud_kv "Source" "$default_source"
    fi

    # PipeWire version + quantum
    if [[ $AUD_HAS_PW_CLI -eq 1 ]]; then
        local pw_info
        pw_info="$(pw-cli info 0 2>/dev/null | \
                   grep -E 'version|clock.quantum|clock.rate' | head -4)"
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            local key="${line%%=*}"  val="${line##*=}"
            key="$(printf '%s' "$key" | tr -d ' ')"
            val="$(printf '%s' "$val" | tr -d ' "')"
            aud_kv "  ${key}" "$val" "$(_adim)"
        done <<< "$pw_info"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  NOTIFICATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

aud_notify() {
    local title="$1"  body="$2"  hint="${3:-}"
    [[ "${ASH_AUD_NO_NOTIFY:-0}" -eq 1 ]] && return 0
    command -v notify-send &>/dev/null || return 0
    local args=( "notify-send" "$title" "$body"
                 "--icon=audio-volume-high"
                 "--expire-time=2000" )
    [[ -n "$hint" ]] && args+=( "--hint=int:value:${hint}" )
    "${args[@]}" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME INIT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

aud_ensure_dirs() {
    mkdir -p "$_AUD_STATE_DIR" "$_AUD_CACHE_DIR" "$_AUD_CONFIG_DIR" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SUB-COMMAND LOADER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_aud_load_sub() {
    local sub="$1"
    local sub_file="${_AUD_CMD_DIR}/${sub}.sh"
    if [[ ! -f "$sub_file" ]]; then
        printf '\n%s✗  audio sub-command not found: %s%s\n\n' \
            "$(_ared)" "$sub" "$(_ar)" >&2
        return 1
    fi
    # shellcheck source=/dev/null
    source "$sub_file"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WATCH MODE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_aud_watch() {
    local interval="${1:-1}"
    command -v tput &>/dev/null || { aud_fail "tput required"; return 1; }
    tput civis 2>/dev/null || true
    trap 'tput cnorm 2>/dev/null; exit 0' INT TERM EXIT
    while true; do
        printf '\033[2J\033[H'
        printf '%s  🔊 AUDIO LIVE  •  %s  •  Ctrl+C to exit%s\n' \
            "$(_adim)" "$(date '+%H:%M:%S')" "$(_ar)"
        aud_status_frame
        sleep "$interval"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_aud_help() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;250;179;135m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🔊  ASH  ─  audio  (Audio Manager)                      ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    local cc="$(_asky)"  cd="$(_adim)"  cs="$(_amauve)"  cr="$(_ar)"

    printf '\n%sUSAGE%s\n' "$(_abold)" "$cr"
    printf '   ash audio [sub-command] [flags]\n\n'

    printf '%sSUB-COMMANDS%s\n\n' "$cs" "$cr"

    local -a cmds=(
        "status:🔊:Show audio status, default sink/source, volume"
        "volume:🔉:Get/set/adjust volume with animated bar"
        "mute:🔇:Mute/unmute/toggle sink or source"
        "device:🎧:List and switch audio devices"
        "eq:🎛️ :EQ presets via EasyEffects / PipeWire"
        "visualizer:📊:Terminal audio visualizer (cava)"
    )

    for entry in "${cmds[@]}"; do
        IFS=':' read -r cmd icon desc <<< "$entry"
        printf '   %s%s %-14s%s  %s%s%s\n' \
            "$cc" "$icon" "$cmd" "$cr" "$cd" "$desc" "$cr"
    done

    printf '\n%sFLAGS%s\n' "$cs" "$cr"
    printf '   %s--watch/-w%s       Live audio status (refresh every 1s)\n' "$cc" "$cr"
    printf '   %s--json%s           Machine-readable JSON output\n'          "$cc" "$cr"
    printf '   %s--no-notify%s      Suppress OSD notifications\n'            "$cc" "$cr"

    printf '\n%sEXAMPLES%s\n' "$cs" "$cr"
    printf '   %sash audio status%s              Show audio overview\n'     "$cc" "$cr"
    printf '   %sash audio volume 65%s           Set volume to 65%%\n'      "$cc" "$cr"
    printf '   %sash audio volume +10%s          Increase by 10%%\n'        "$cc" "$cr"
    printf '   %sash audio mute toggle%s         Toggle mute\n'             "$cc" "$cr"
    printf '   %sash audio device list%s         List audio devices\n'      "$cc" "$cr"
    printf '   %sash audio eq bass-boost%s       Apply bass-boost EQ\n'    "$cc" "$cr"
    printf '   %sash audio visualizer%s          Launch cava visualizer\n'  "$cc" "$cr"
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN DISPATCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_cmd_audio() {
    local sub="${1:-status}"
    shift || true

    local watch_mode=0
    local watch_interval=1
    local -a fwd_args=()

    for arg in "${@:-}"; do
        case "$arg" in
            --watch|-w)        watch_mode=1                    ;;
            --watch=*)         watch_mode=1; watch_interval="${arg#*=}" ;;
            --no-notify)       export ASH_AUD_NO_NOTIFY=1      ;;
            --json)            export ASH_FLAG_JSON_OUTPUT=1   ;;
            *)                 fwd_args+=("$arg")              ;;
        esac
    done

    aud_ensure_dirs
    aud_detect_backend

    case "$sub" in
        help|-h|--help) _aud_help ;;

        status|info)
            if [[ $watch_mode -eq 1 ]]; then
                _aud_watch "$watch_interval"
            else
                aud_status_frame
                printf '\n'
            fi
            ;;

        volume|mute|device|eq|visualizer)
            _aud_load_sub "$sub" || return 1
            local fn="ash_audio_${sub}"
            declare -f "$fn" &>/dev/null && \
                "$fn" "${fwd_args[@]:-}" || {
                aud_fail "Function not found: ${fn}"
                return 1
            }
            ;;
        *)
            printf '\n%s✗  Unknown sub-command: %s%s\n' \
                "$(_ared)" "$sub" "$(_ar)" >&2
            printf '%sRun: ash audio help%s\n\n' "$(_adim)" "$(_ar)" >&2
            return 1
            ;;
    esac
}
