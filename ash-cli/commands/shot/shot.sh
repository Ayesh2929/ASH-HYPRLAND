#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ███████╗██╗  ██╗ ██████╗ ████████╗                                             ║
# ║  ██╔════╝██║  ██║██╔═══██╗╚══██╔══╝                                             ║
# ║  ███████╗███████║██║   ██║   ██║                                                ║
# ║  ╚════██║██╔══██║██║   ██║   ██║                                                ║
# ║  ███████║██║  ██║╚██████╔╝   ██║                                                ║
# ║  ╚══════╝╚═╝  ╚═╝ ╚═════╝    ╚═╝                                                ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  SCREENSHOT & RECORDING DISPATCHER                       ║
# ║  Wayland-native capture hub with 13 capture modes                               ║
# ║                                                                                  ║
# ║  Author   : ash-dotfiles                                                         ║
# ║  License  : MIT                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CMD_SHOT_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CMD_SHOT_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _SHOT_CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -gr _SHOT_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
declare -gr _SHOT_TMP="${XDG_RUNTIME_DIR:-/tmp}/ash-shot"
declare -gr _SHOT_HISTORY="${XDG_STATE_HOME:-$HOME/.local/state}/ash/shot-history.log"
declare -gr _SHOT_UPLOAD_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/ash/uploads"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CATPPUCCIN MOCHA PALETTE  (inline — zero deps)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_s()       { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_sr()      { _s $'\033[0m';                          }
_sbold()   { _s $'\033[1m';                          }
_sdim()    { _s $'\033[38;2;108;112;134m';           }
_smauve()  { _s $'\033[1;38;2;203;166;247m';         }
_sblue()   { _s $'\033[38;2;137;180;250m';           }
_sgreen()  { _s $'\033[38;2;166;227;161m';           }
_speach()  { _s $'\033[38;2;250;179;135m';           }
_syellow() { _s $'\033[1;38;2;249;226;175m';         }
_sred()    { _s $'\033[1;38;2;243;139;168m';         }
_steal()   { _s $'\033[38;2;148;226;213m';           }
_ssky()    { _s $'\033[38;2;137;220;235m';           }
_slav()    { _s $'\033[38;2;180;190;254m';           }
_spink()   { _s $'\033[38;2;245;194;231m';           }
_ssapph()  { _s $'\033[38;2;116;199;236m';           }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SHARED DISPLAY PRIMITIVES  (exported for sub-commands)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

shot_section() {
    local icon="$1"  title="$2"  color="${3:-$(_smauve)}"
    printf '\n%s%s  %s%s\n' "$color" "$icon" "$title" "$(_sr)"
    printf '%s  %s%s\n' "$(_sdim)" "$(printf '─%.0s' $(seq 1 58))" "$(_sr)"
}

shot_kv() {
    local key="$1"  val="$2"  vc="${3:-$(_sgreen)}"
    printf '  %s%-26s%s %s%s%s\n' \
        "$(_sdim)" "${key}:" "$(_sr)" "$vc" "$val" "$(_sr)"
}

shot_ok()    { printf '  %s✓%s  %s\n' "$(_sgreen)"  "$(_sr)" "$1"; }
shot_fail()  { printf '  %s✗%s  %s\n' "$(_sred)"    "$(_sr)" "$1"; }
shot_info()  { printf '  %sℹ%s  %s\n' "$(_sdim)"    "$(_sr)" "$1"; }
shot_warn()  { printf '  %s⚠%s  %s\n' "$(_syellow)" "$(_sr)" "$1"; }
shot_step()  { printf '  %s→%s  %s\n' "$(_steal)"   "$(_sr)" "$1"; }

shot_divider() {
    printf '%s  %s%s\n' "$(_sdim)" "$(printf '─%.0s' $(seq 1 60))" "$(_sr)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  ENVIRONMENT SETUP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

shot_ensure_dirs() {
    mkdir -p "$_SHOT_DIR" "$_SHOT_TMP" "$_SHOT_UPLOAD_CACHE" 2>/dev/null || true
    local log_dir
    log_dir="$(dirname "$_SHOT_HISTORY")"
    mkdir -p "$log_dir" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FILENAME GENERATOR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

shot_filename() {
    local prefix="${1:-screenshot}"
    local ext="${2:-png}"
    local ts
    ts="$(date '+%Y%m%d-%H%M%S')"
    printf '%s/%s-%s.%s' "$_SHOT_DIR" "$prefix" "$ts" "$ext"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HISTORY LOGGER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

shot_log() {
    local file="$1"  mode="${2:-unknown}"  extra="${3:-}"
    local ts size
    ts="$(date -Iseconds)"
    size="$(du -sh "$file" 2>/dev/null | cut -f1 || echo '?')"
    printf '%s\t%s\t%s\t%s\t%s\n' \
        "$ts" "$mode" "$file" "$size" "$extra" \
        >> "$_SHOT_HISTORY" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CLIPBOARD COPY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

shot_copy_to_clipboard() {
    local file="$1"

    if command -v wl-copy &>/dev/null; then
        wl-copy < "$file" 2>/dev/null && \
            shot_ok "Copied to clipboard  (wl-copy)" || true
    elif command -v xclip &>/dev/null; then
        xclip -selection clipboard -t image/png < "$file" 2>/dev/null && \
            shot_ok "Copied to clipboard  (xclip)" || true
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  NOTIFICATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

shot_notify() {
    local title="$1"  body="$2"  file="${3:-}"
    [[ "${ASH_SHOT_NO_NOTIFY:-0}" -eq 1 ]] && return 0
    command -v notify-send &>/dev/null || return 0

    local args=( "notify-send" "$title" "$body" "--icon=camera" )
    [[ -n "$file" ]] && args+=( "--hint=string:image-path:${file}" )
    "${args[@]}" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  TOOL AVAILABILITY CHECK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

shot_require() {
    local tool="$1"  pkg="${2:-$1}"
    if ! command -v "$tool" &>/dev/null; then
        shot_fail "${tool} not found"
        shot_info "Install: paru -S ${pkg}"
        return 1
    fi
}

shot_check_wayland() {
    if [[ -z "${WAYLAND_DISPLAY:-}" ]] && [[ -z "${DISPLAY:-}" ]]; then
        shot_fail "No display server detected"
        return 1
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SUB-COMMAND LOADER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_shot_load_sub() {
    local sub="$1"
    local sub_file="${_SHOT_CMD_DIR}/${sub}.sh"
    if [[ ! -f "$sub_file" ]]; then
        printf '\n%s✗  shot sub-command not found: %s%s\n\n' \
            "$(_sred)" "$sub" "$(_sr)" >&2
        return 1
    fi
    # shellcheck source=/dev/null
    source "$sub_file"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_shot_help() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;245;194;231m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  📷  ASH  ─  shot  (Screenshot & Recording Hub)          ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    local cc="$(_ssky)"  cd="$(_sdim)"  cs="$(_smauve)"  cr="$(_sr)"

    printf '\n%sUSAGE%s\n' "$(_sbold)" "$cr"
    printf '   ash shot [sub-command] [flags]\n\n'

    printf '%sSUB-COMMANDS%s\n\n' "$cs" "$cr"
    local -a cmds=(
        "full:📸:Capture entire screen(s)"
        "area:✂️ :Interactive area selection"
        "window:🪟:Capture active or selected window"
        "monitor:🖥️ :Capture specific monitor"
        "ocr:🔤:Screenshot + extract text via OCR"
        "color:🎨:Pick a color from screen (hex/rgb/hsl)"
        "record:🎬:Record screen to video (mp4/mkv)"
        "gif:🎞️ :Record screen to animated GIF"
        "annotate:✏️ :Annotate/edit an existing screenshot"
        "timer:⏱️ :Screenshot with countdown timer"
        "upload:☁️ :Upload screenshot to image host"
        "history:📋:Browse and manage screenshot history"
    )
    for entry in "${cmds[@]}"; do
        IFS=':' read -r cmd icon desc <<< "$entry"
        printf '   %s%s %-14s%s  %s%s%s\n' \
            "$cc" "$icon" "$cmd" "$cr" "$cd" "$desc" "$cr"
    done

    printf '\n%sGLOBAL FLAGS%s\n' "$cs" "$cr"
    printf '   %s--clipboard/-c%s   Copy to clipboard after capture\n'  "$cc" "$cr"
    printf '   %s--upload/-u%s      Upload after capture\n'             "$cc" "$cr"
    printf '   %s--annotate/-a%s    Open annotation tool after\n'       "$cc" "$cr"
    printf '   %s--delay=N%s        Delay N seconds before capture\n'   "$cc" "$cr"
    printf '   %s--format=EXT%s     Output format (png/jpg/webp)\n'     "$cc" "$cr"
    printf '   %s--quality=N%s      JPEG/WebP quality (1-100)\n'        "$cc" "$cr"
    printf '   %s--no-notify%s      Suppress desktop notification\n'    "$cc" "$cr"
    printf '   %s--dir=PATH%s       Override save directory\n'          "$cc" "$cr"

    printf '\n%sEXAMPLES%s\n' "$cs" "$cr"
    printf '   %sash shot full%s                   Fullscreen screenshot\n'        "$cc" "$cr"
    printf '   %sash shot area -c%s                Select area, copy to clipboard\n' "$cc" "$cr"
    printf '   %sash shot record --fps=30%s        Record at 30fps\n'             "$cc" "$cr"
    printf '   %sash shot ocr%s                    Capture + extract text\n'      "$cc" "$cr"
    printf '   %sash shot color --format=hex%s     Pick color as hex\n'           "$cc" "$cr"
    printf '   %sash shot timer --delay=5%s        5-second countdown\n'          "$cc" "$cr"
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN DISPATCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_cmd_shot() {
    local sub="${1:-full}"
    shift || true

    # Parse global shot flags into env vars consumed by sub-commands
    local -a fwd_args=()
    for arg in "${@:-}"; do
        case "$arg" in
            --clipboard|-c)    export ASH_SHOT_CLIPBOARD=1    ;;
            --upload|-u)       export ASH_SHOT_UPLOAD=1       ;;
            --annotate|-a)     export ASH_SHOT_ANNOTATE=1     ;;
            --no-notify)       export ASH_SHOT_NO_NOTIFY=1    ;;
            --delay=*)         export ASH_SHOT_DELAY="${arg#*=}" ;;
            --format=*)        export ASH_SHOT_FORMAT="${arg#*=}" ;;
            --quality=*)       export ASH_SHOT_QUALITY="${arg#*=}" ;;
            --dir=*)           export _SHOT_DIR="${arg#*=}"    ;;
            *)                 fwd_args+=("$arg")             ;;
        esac
    done

    shot_ensure_dirs

    case "$sub" in
        help|-h|--help) _shot_help ;;

        full|area|window|monitor|ocr|color|\
        record|gif|annotate|timer|upload|history)
            _shot_load_sub "$sub" || return 1
            local fn="ash_shot_${sub//-/_}"
            declare -f "$fn" &>/dev/null && \
                "$fn" "${fwd_args[@]:-}" || {
                shot_fail "Function not found: ${fn}"
                return 1
            }
            ;;
        *)
            printf '\n%s✗  Unknown sub-command: %s%s\n' \
                "$(_sred)" "$sub" "$(_sr)" >&2
            printf '%sRun: ash shot help%s\n\n' "$(_sdim)" "$(_sr)" >&2
            return 1
            ;;
    esac
}
