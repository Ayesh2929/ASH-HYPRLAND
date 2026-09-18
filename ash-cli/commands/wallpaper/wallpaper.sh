#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██╗    ██╗ █████╗ ██╗     ██╗     ██████╗  █████╗ ██████╗ ███████╗██████╗      ║
# ║  ██║    ██║██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗     ║
# ║  ██║ █╗ ██║███████║██║     ██║     ██████╔╝███████║██████╔╝█████╗  ██████╔╝     ║
# ║  ██║███╗██║██╔══██║██║     ██║     ██╔═══╝ ██╔══██║██╔═══╝ ██╔══╝  ██╔══██╗    ║
# ║  ╚███╔███╔╝██║  ██║███████╗███████╗██║     ██║  ██║██║     ███████╗██║  ██║    ║
# ║   ╚══╝╚══╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝    ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  WALLPAPER COMMAND DISPATCHER                            ║
# ║  Complete wallpaper management hub with 11 modes                                ║
# ║                                                                                  ║
# ║  Author   : ash-dotfiles                                                         ║
# ║  License  : MIT                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CMD_WALLPAPER_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CMD_WALLPAPER_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _WP_CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -gr _WP_ASH_ROOT="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}"
declare -gr _WP_LIB_DIR="${_WP_ASH_ROOT}/wallpapers"
declare -gr _WP_USER_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Wallpapers"
declare -gr _WP_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/ash/wallpapers"
declare -gr _WP_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/ash/wallpaper"
declare -gr _WP_HISTORY_FILE="${_WP_STATE}/history.log"
declare -gr _WP_CURRENT_FILE="${_WP_STATE}/current"
declare -gr _WP_LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/ash-wallpaper.lock"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CATPPUCCIN MOCHA PALETTE  (inline — zero external deps)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_w()       { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_wr()      { _w $'\033[0m';                          }
_wbold()   { _w $'\033[1m';                          }
_wdim()    { _w $'\033[38;2;108;112;134m';           }
_wmauve()  { _w $'\033[1;38;2;203;166;247m';         }
_wblue()   { _w $'\033[38;2;137;180;250m';           }
_wgreen()  { _w $'\033[38;2;166;227;161m';           }
_wpeach()  { _w $'\033[38;2;250;179;135m';           }
_wyellow() { _w $'\033[1;38;2;249;226;175m';         }
_wred()    { _w $'\033[1;38;2;243;139;168m';         }
_wteal()   { _w $'\033[38;2;148;226;213m';           }
_wsky()    { _w $'\033[38;2;137;220;235m';           }
_wlav()    { _w $'\033[38;2;180;190;254m';           }
_wpink()   { _w $'\033[38;2;245;194;231m';           }
_wsapph()  { _w $'\033[38;2;116;199;236m';           }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SHARED DISPLAY PRIMITIVES  (exported to sub-commands)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

wp_section() {
    local icon="$1"  title="$2"  color="${3:-$(_wmauve)}"
    printf '\n%s%s  %s%s\n' "$color" "$icon" "$title" "$(_wr)"
    printf '%s  %s%s\n' "$(_wdim)" "$(printf '─%.0s' $(seq 1 58))" "$(_wr)"
}

wp_kv() {
    local key="$1"  val="$2"  vc="${3:-$(_wgreen)}"
    printf '  %s%-26s%s %s%s%s\n' \
        "$(_wdim)" "${key}:" "$(_wr)" "$vc" "$val" "$(_wr)"
}

wp_ok()    { printf '  %s✓%s  %s\n' "$(_wgreen)"  "$(_wr)" "$1"; }
wp_fail()  { printf '  %s✗%s  %s\n' "$(_wred)"    "$(_wr)" "$1"; }
wp_info()  { printf '  %sℹ%s  %s\n' "$(_wdim)"    "$(_wr)" "$1"; }
wp_warn()  { printf '  %s⚠%s  %s\n' "$(_wyellow)" "$(_wr)" "$1"; }
wp_step()  { printf '  %s→%s  %s\n' "$(_wteal)"   "$(_wr)" "$1"; }

wp_divider() {
    printf '%s  %s%s\n' "$(_wdim)" "$(printf '─%.0s' $(seq 1 60))" "$(_wr)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RUNTIME INIT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

wp_ensure_dirs() {
    mkdir -p "$_WP_USER_DIR" "$_WP_CACHE" "$_WP_STATE" 2>/dev/null || true
    [[ -d "$_WP_LIB_DIR" ]] || mkdir -p "$_WP_LIB_DIR" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BACKEND DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g WP_BACKEND=""

wp_detect_backend() {
    if command -v swww &>/dev/null && pgrep -x swww-daemon &>/dev/null; then
        WP_BACKEND="swww"
    elif command -v swww &>/dev/null; then
        WP_BACKEND="swww"
    elif command -v hyprpaper &>/dev/null; then
        WP_BACKEND="hyprpaper"
    elif command -v swaybg &>/dev/null; then
        WP_BACKEND="swaybg"
    elif command -v feh &>/dev/null; then
        WP_BACKEND="feh"
    elif command -v nitrogen &>/dev/null; then
        WP_BACKEND="nitrogen"
    else
        WP_BACKEND="none"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CORE SET FUNCTION  (used by all sub-commands)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g WP_TRANSITION="${ASH_WP_TRANSITION:-wipe}"
declare -g WP_TRANSITION_FPS="${ASH_WP_TRANSITION_FPS:-60}"
declare -g WP_TRANSITION_DURATION="${ASH_WP_TRANSITION_DURATION:-0.8}"
declare -g WP_FILL_MODE="${ASH_WP_FILL:-fill}"

wp_set_backend() {
    local file="$1"
    [[ ! -f "$file" ]] && wp_fail "File not found: ${file}" && return 1

    case "$WP_BACKEND" in
        swww)
            # Ensure daemon is running
            if ! pgrep -x swww-daemon &>/dev/null; then
                wp_step "Starting swww-daemon..."
                swww-daemon &>/dev/null &
                sleep 0.5
            fi

            local transition_args=(
                "--transition-type"     "$WP_TRANSITION"
                "--transition-fps"      "$WP_TRANSITION_FPS"
                "--transition-duration" "$WP_TRANSITION_DURATION"
                "--transition-bezier"   ".43,1.19,1,.4"
            )

            swww img "$file" \
                "${transition_args[@]}" \
                --resize "$WP_FILL_MODE" \
                2>/dev/null
            ;;
        hyprpaper)
            hyprctl hyprpaper preload "$file" &>/dev/null
            hyprctl hyprpaper wallpaper ",$file" &>/dev/null
            ;;
        swaybg)
            pkill swaybg 2>/dev/null || true
            swaybg -m "$([[ "$WP_FILL_MODE" == "fill" ]] && echo "fill" || echo "fit")" \
                   -i "$file" &>/dev/null &
            ;;
        feh)
            feh --bg-fill "$file" &>/dev/null
            ;;
        nitrogen)
            nitrogen --set-zoom-fill --save "$file" &>/dev/null
            ;;
        none|*)
            wp_fail "No wallpaper backend found"
            wp_info "Install: paru -S swww  (recommended)"
            return 1
            ;;
    esac

    # Save current wallpaper state
    printf '%s\n' "$file" > "$_WP_CURRENT_FILE"

    # Log to history
    wp_log_history "$file"

    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HISTORY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

wp_log_history() {
    local file="$1"
    local ts
    ts="$(date -Iseconds)"
    printf '%s\t%s\n' "$ts" "$file" >> "$_WP_HISTORY_FILE" 2>/dev/null || true

    # Keep last 500 entries
    if [[ -f "$_WP_HISTORY_FILE" ]]; then
        local lines
        lines="$(wc -l < "$_WP_HISTORY_FILE" 2>/dev/null || echo 0)"
        if (( lines > 500 )); then
            tail -500 "$_WP_HISTORY_FILE" > "${_WP_HISTORY_FILE}.tmp" && \
                mv "${_WP_HISTORY_FILE}.tmp" "$_WP_HISTORY_FILE" 2>/dev/null || true
        fi
    fi
}

wp_get_current() {
    [[ -f "$_WP_CURRENT_FILE" ]] && cat "$_WP_CURRENT_FILE" 2>/dev/null || echo ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WALLPAPER SEARCH
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

wp_find_all() {
    local -a search_dirs=()

    [[ -d "$_WP_LIB_DIR"  ]] && search_dirs+=("$_WP_LIB_DIR")
    [[ -d "$_WP_USER_DIR" ]] && search_dirs+=("$_WP_USER_DIR")

    find "${search_dirs[@]}" \
        \( -name '*.jpg'  -o -name '*.jpeg' \
        -o -name '*.png'  -o -name '*.webp' \
        -o -name '*.gif'  -o -name '*.mp4'  \) \
        2>/dev/null | sort
}

wp_count_all() {
    wp_find_all | wc -l
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  NOTIFICATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

wp_notify() {
    local title="$1"  body="$2"  file="${3:-}"
    [[ "${ASH_WP_NO_NOTIFY:-0}" -eq 1 ]] && return 0
    command -v notify-send &>/dev/null || return 0
    local args=( "notify-send" "$title" "$body" "--icon=image-x-generic" )
    [[ -n "$file" ]] && [[ -f "$file" ]] && \
        args+=( "--hint=string:image-path:${file}" )
    "${args[@]}" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SUB-COMMAND LOADER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_wp_load_sub() {
    local sub="$1"
    local sub_file="${_WP_CMD_DIR}/${sub}.sh"
    if [[ ! -f "$sub_file" ]]; then
        printf '\n%s✗  wallpaper sub-command not found: %s%s\n\n' \
            "$(_wred)" "$sub" "$(_wr)" >&2
        return 1
    fi
    # shellcheck source=/dev/null
    source "$sub_file"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_wp_help() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;203;166;247m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🖼️   ASH  ─  wallpaper  (Wallpaper Manager)              ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    local cc="$(_wsky)"  cd="$(_wdim)"  cs="$(_wmauve)"  cr="$(_wr)"

    printf '\n%sUSAGE%s\n' "$(_wbold)" "$cr"
    printf '   ash wallpaper [sub-command] [flags]\n'
    printf '   ash wp [sub-command] [flags]          (alias)\n\n'

    printf '%sSUB-COMMANDS%s\n\n' "$cs" "$cr"

    local -a cmds=(
        "set:🖼️ :Set a specific wallpaper file"
        "random:🎲:Set a random wallpaper from library"
        "pick:🔍:Interactive wallpaper picker (fzf + preview)"
        "download:⬇️ :Download wallpaper from URL or Wallhaven/Unsplash"
        "generate:✨:Generate wallpaper via gradients / patterns"
        "generate-ai:🤖:Generate wallpaper via Stable Diffusion / Ollama"
        "slideshow:▶️ :Auto-rotate wallpapers on a schedule"
        "blur:💧:Apply blur effect to current wallpaper"
        "info:📋:Show info about current wallpaper"
        "history:📜:Browse wallpaper history and re-apply"
    )

    for entry in "${cmds[@]}"; do
        IFS=':' read -r cmd icon desc <<< "$entry"
        printf '   %s%s %-16s%s  %s%s%s\n' \
            "$cc" "$icon" "$cmd" "$cr" "$cd" "$desc" "$cr"
    done

    printf '\n%sGLOBAL FLAGS%s\n' "$cs" "$cr"
    printf '   %s--transition=TYPE%s   swww transition (wipe/fade/wave/grow/outer)\n' "$cc" "$cr"
    printf '   %s--fps=N%s            Transition FPS (default: 60)\n'               "$cc" "$cr"
    printf '   %s--fill=MODE%s        Fill mode (fill/fit/stretch/center/tile)\n'   "$cc" "$cr"
    printf '   %s--no-notify%s        Suppress desktop notification\n'              "$cc" "$cr"
    printf '   %s--backend=NAME%s     Force backend (swww/hyprpaper/swaybg/feh)\n' "$cc" "$cr"

    printf '\n%sEXAMPLES%s\n' "$cs" "$cr"
    printf '   %sash wp set ~/Pictures/wall.jpg%s\n'                    "$cc" "$cr"
    printf '   %sash wp random --transition=fade%s\n'                   "$cc" "$cr"
    printf '   %sash wp pick%s\n'                                       "$cc" "$cr"
    printf '   %sash wp download --source=wallhaven --query=anime%s\n'  "$cc" "$cr"
    printf '   %sash wp slideshow --interval=300%s\n'                   "$cc" "$cr"
    printf '   %sash wp generate --type=gradient --colors=#cba6f7,#89b4fa%s\n' "$cc" "$cr"
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN DISPATCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_cmd_wallpaper() {
    local sub="${1:-info}"
    shift || true

    # Parse global wallpaper flags
    local -a fwd_args=()
    for arg in "${@:-}"; do
        case "$arg" in
            --transition=*)  export WP_TRANSITION="${arg#*=}"          ;;
            --fps=*)         export WP_TRANSITION_FPS="${arg#*=}"      ;;
            --fill=*)        export WP_FILL_MODE="${arg#*=}"           ;;
            --no-notify)     export ASH_WP_NO_NOTIFY=1                 ;;
            --backend=*)     export WP_BACKEND="${arg#*=}"             ;;
            *)               fwd_args+=("$arg")                        ;;
        esac
    done

    wp_ensure_dirs
    wp_detect_backend

    case "$sub" in
        help|-h|--help) _wp_help ;;

        set|random|pick|download|generate|generate-ai|\
        slideshow|blur|info|history)
            _wp_load_sub "${sub//-/_}" || return 1
            # Normalize function name (generate-ai → generate_ai)
            local fn="ash_wp_${sub//-/_}"
            declare -f "$fn" &>/dev/null && \
                "$fn" "${fwd_args[@]:-}" || {
                wp_fail "Function not found: ${fn}"
                return 1
            }
            ;;
        *)
            printf '\n%s✗  Unknown sub-command: %s%s\n' \
                "$(_wred)" "$sub" "$(_wr)" >&2
            printf '%sRun: ash wallpaper help%s\n\n' "$(_wdim)" "$(_wr)" >&2
            return 1
            ;;
    esac
}

# Alias
ash_cmd_wp() { ash_cmd_wallpaper "$@"; }
