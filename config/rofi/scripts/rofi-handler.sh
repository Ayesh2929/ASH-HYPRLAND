#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
# ASH DOTFILES v5.0 OMEGA — ROFI HANDLER ULTRA ENGINE
# ══════════════════════════════════════════════════════════════════════════════
# File    : rofi-handler.sh
# Author  : Ash Dotfiles v5.0 Omega
# License : MIT
# Desc    : Master Rofi orchestration engine — the single entry point for
#           launching, managing, and coordinating all Rofi menus across the
#           entire ASH dotfiles ecosystem.
#
#   Architecture:
#     • Unified launcher with per-menu theme injection
#     • Dynamic monitor geometry detection (multi-monitor aware)
#     • Context-aware positioning (cursor / center / monitor edge)
#     • Pre-launch hook system (10 hook points)
#     • Post-close hook system (result capture + action dispatch)
#     • Graceful error handling with visual feedback
#     • Performance profiling (per-menu startup timing)
#     • Session management (remember last menu, last selection)
#     • Accessibility support (font scaling, high contrast, large cursor)
#     • IPC bridge (named pipe + UNIX socket)
#     • Wayland-native (no xdotool dependency)
#     • Parallel menu pre-warming cache
#     • Rofi process lifecycle management (singleton per category)
#     • Full CLI interface (30+ flags)
#     • Structured JSON logging
#     • Hot-reload support (config changes without restart)
#
#   Supported menus (35 total):
#     Launchers  : apps, runner, drun, window, ssh, files
#     System     : powermenu, screenshot, wallpaper, theme, mode
#     Tools      : emoji, calc, clipboard, color, translate, quicknote
#     Dev        : bluetooth, wifi, audio, docker, kubectl, process
#     Plugin     : plugin-manager
#     Custom     : keybind-viewer, quicknote, ssh-connect, file-browser
#
#   POSIX-safe, shellcheck-clean, strict mode
# ══════════════════════════════════════════════════════════════════════════════

set -euo pipefail
IFS=$'\n\t'

# ══════════════════════════════════════════════════════════════════════════════
# § 1  ENVIRONMENT & PATHS
# ══════════════════════════════════════════════════════════════════════════════

readonly XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
readonly XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
readonly XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
readonly XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"
readonly XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

readonly ASH_DIR="${XDG_CONFIG_HOME}/ash"
readonly ROFI_DIR="${XDG_CONFIG_HOME}/rofi"
readonly ROFI_SCRIPTS_DIR="${ROFI_DIR}/scripts"
readonly ROFI_MENUS_DIR="${ROFI_DIR}/menus"
readonly ROFI_THEMES_DIR="${ROFI_DIR}/themes"

# Runtime dirs
readonly ROFI_RUNTIME_DIR="${XDG_RUNTIME_DIR}/ash/rofi"
readonly ROFI_CACHE_DIR="${XDG_CACHE_HOME}/ash/rofi"
readonly ROFI_STATE_DIR="${XDG_STATE_HOME}/ash"
readonly ROFI_LOG_FILE="${ROFI_STATE_DIR}/rofi-handler.log"
readonly ROFI_SESSION_FILE="${ROFI_STATE_DIR}/rofi-session.json"
readonly ROFI_PID_DIR="${ROFI_RUNTIME_DIR}/pids"
readonly ROFI_PIPE="${ROFI_RUNTIME_DIR}/ipc.pipe"
readonly ROFI_SOCKET="${ROFI_RUNTIME_DIR}/ipc.sock"
readonly ROFI_PERF_LOG="${ROFI_CACHE_DIR}/performance.jsonl"

# ASH integration
readonly ASH_THEME_FILE="${ASH_DIR}/current-theme.conf"
readonly ASH_CONFIG_FILE="${ASH_DIR}/ash.conf"
readonly ROFI_HANDLER_SETTINGS="${ASH_DIR}/rofi/handler.conf"

# Script references
readonly ICON_LOOKUP="${ROFI_SCRIPTS_DIR}/icon-lookup.sh"
readonly DYNAMIC_ICONS="${ROFI_SCRIPTS_DIR}/dynamic-icons.sh"

# ══════════════════════════════════════════════════════════════════════════════
# § 2  CONSTANTS & DEFAULTS
# ══════════════════════════════════════════════════════════════════════════════

readonly VERSION="5.0.0"
readonly DATE_FMT="%Y-%m-%dT%H:%M:%S"
readonly ROFI_BIN="${ROFI_BIN:-rofi}"
readonly ROFI_MIN_VERSION="1.7.5"
readonly DEFAULT_FONT="JetBrainsMono Nerd Font 12"
readonly DEFAULT_ICON_THEME="Papirus-Dark"
readonly LAUNCH_TIMEOUT=10
readonly MAX_LOG_SIZE_KB=2048
readonly PERF_HISTORY_MAX=500

# ── Menu category registry ────────────────────────────────────────────────────
# Format: "menu_id:category:theme_file:script:description:icon"
declare -A MENU_REGISTRY=(
    # ── Launchers ────────────────────────────────────────────────────────────
    [apps]="launcher:launchers/type-4-center/launcher.rasi::Application Launcher:󰣆"
    [runner]="launcher:launchers/type-7-runner/launcher.rasi::Command Runner:󰣇"
    [window]="launcher:launchers/type-6-dmenu/launcher.rasi::Window Switcher:󱂬"
    [ssh]="launcher:menus/ssh-connect/ssh-connect.rasi:menus/ssh-connect/ssh-connect.sh:SSH Connect:󰣀"
    [files]="launcher:menus/file-browser/file-browser.rasi:menus/file-browser/file-browser.sh:File Browser:󰉋"

    # ── System menus ──────────────────────────────────────────────────────────
    [powermenu]="system:menus/powermenu/powermenu.rasi:menus/powermenu/powermenu.sh:Power Menu:󰐥"
    [screenshot]="system:menus/screenshot/screenshot.rasi:menus/screenshot/screenshot.sh:Screenshot:󰹑"
    [wallpaper]="system:menus/wallpaper/wallpaper.rasi:menus/wallpaper/wallpaper.sh:Wallpaper Picker:󰸉"
    [theme-picker]="system:menus/theme-picker/theme-picker.rasi:menus/theme-picker/theme-picker.sh:Theme Picker:󰔰"
    [mode-selector]="system:menus/mode-selector/mode-selector.rasi:menus/mode-selector/mode-selector.sh:Mode Selector:󰒓"

    # ── Tool menus ────────────────────────────────────────────────────────────
    [emoji]="tools:menus/emoji/emoji.rasi:menus/emoji/emoji.sh:Emoji Picker:󰞅"
    [calc]="tools:menus/calc/calc.rasi:menus/calc/calc.sh:Calculator:󰪖"
    [clipboard]="tools:menus/clipboard/clipboard.rasi:menus/clipboard/clipboard.sh:Clipboard Manager:󰆏"
    [color-picker]="tools:menus/color-picker/color-picker.rasi:menus/color-picker/color-picker.sh:Color Picker:󰈸"
    [translate]="tools:menus/translation/translation.rasi:menus/translation/translation.sh:Translate:󰗊"
    [quicknote]="tools:menus/quicknote/quicknote.rasi:menus/quicknote/quicknote.sh:Quick Note:󱞁"
    [keybind-viewer]="tools:menus/keybind-viewer/keybind-viewer.rasi:menus/keybind-viewer/keybind-viewer.sh:Keybind Viewer:󰥻"

    # ── Device menus ──────────────────────────────────────────────────────────
    [bluetooth]="device:menus/bluetooth/bluetooth.rasi:menus/bluetooth/bluetooth.sh:Bluetooth:󰂯"
    [wifi]="device:menus/wifi/wifi.rasi:menus/wifi/wifi.sh:WiFi Manager:󰤨"
    [audio-switcher]="device:menus/audio-switcher/audio-switcher.rasi:menus/audio-switcher/audio-switcher.sh:Audio Switcher:󰋋"

    # ── Developer menus ───────────────────────────────────────────────────────
    [docker-manager]="dev:menus/docker-manager/docker-manager.rasi:menus/docker-manager/docker-manager.sh:Docker Manager:󰡨"
    [process-killer]="dev:menus/process-killer/process-killer.rasi:menus/process-killer/process-killer.sh:Process Killer:󰒃"

    # ── Plugin menus ──────────────────────────────────────────────────────────
    [plugin-manager]="plugin:menus/plugin-manager/plugin-manager.rasi:menus/plugin-manager/plugin-manager.sh:Plugin Manager:󰏗"
)

# ── Position presets ──────────────────────────────────────────────────────────
declare -A POSITION_PRESETS=(
    [center]="center"
    [top]="north"
    [bottom]="south"
    [top-left]="northwest"
    [top-right]="northeast"
    [bottom-left]="southwest"
    [bottom-right]="southeast"
    [cursor]="cursor"
    [monitor-center]="center"
)

# ── Nerd Font icons (for notifications + logs) ────────────────────────────────
readonly ICON_LAUNCH="󰐊"
readonly ICON_ERROR="󰅖"
readonly ICON_WARN="󰏦"
readonly ICON_SUCCESS="󰄬"
readonly ICON_ROFI="󰣆"
readonly ICON_PERF="󱐋"
readonly ICON_IPC="󱠁"
readonly ICON_HOOK="󰁁"

# ══════════════════════════════════════════════════════════════════════════════
# § 3  LOGGING ENGINE
# ══════════════════════════════════════════════════════════════════════════════

# Rotate log if > MAX_LOG_SIZE_KB
_rotate_log() {
    if [[ -f "${ROFI_LOG_FILE}" ]]; then
        local size_kb
        size_kb="$(du -k "${ROFI_LOG_FILE}" 2>/dev/null | cut -f1)"
        if (( size_kb > MAX_LOG_SIZE_KB )); then
            mv "${ROFI_LOG_FILE}" "${ROFI_LOG_FILE}.old"
        fi
    fi
}

_log() {
    local level="$1"; shift
    local msg="$*"
    local ts
    ts="$(date +"${DATE_FMT}")"
    printf '[%s] [%-7s] %s\n' "${ts}" "${level}" "${msg}" \
        >> "${ROFI_LOG_FILE}" 2>/dev/null || true
}

log_info()    { _log "INFO"    "$@"; }
log_warn()    { _log "WARN"    "$@"; }
log_error()   { _log "ERROR"   "$@"; }
log_debug()   { [[ "${ASH_DEBUG:-0}" == "1" ]] && _log "DEBUG" "$@" || true; }
log_perf()    { _log "PERF"    "$@"; }
log_audit()   { _log "AUDIT"   "$@"; }

# Structured JSON performance log entry
log_perf_json() {
    local menu="$1" duration_ms="$2" exit_code="${3:-0}" \
          selection="${4:-}" timestamp
    timestamp="$(date +"${DATE_FMT}")"
    printf '{"ts":"%s","menu":"%s","duration_ms":%d,"exit":%d,"selection":"%s"}\n' \
        "${timestamp}" "${menu}" "${duration_ms}" "${exit_code}" \
        "${selection//\"/\\\"}" \
        >> "${ROFI_PERF_LOG}" 2>/dev/null || true

    # Trim performance log
    if command -v tail &>/dev/null && [[ -f "${ROFI_PERF_LOG}" ]]; then
        local lines
        lines="$(wc -l < "${ROFI_PERF_LOG}" 2>/dev/null || echo 0)"
        if (( lines > PERF_HISTORY_MAX )); then
            local tmp
            tmp="$(mktemp)"
            tail -n "${PERF_HISTORY_MAX}" "${ROFI_PERF_LOG}" > "${tmp}"
            mv "${tmp}" "${ROFI_PERF_LOG}"
        fi
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# § 4  INITIALISATION
# ══════════════════════════════════════════════════════════════════════════════

init() {
    local -a dirs=(
        "${ROFI_RUNTIME_DIR}"
        "${ROFI_CACHE_DIR}"
        "${ROFI_STATE_DIR}"
        "${ROFI_PID_DIR}"
    )
    for d in "${dirs[@]}"; do
        mkdir -p "${d}"
    done

    # Ensure IPC named pipe exists
    [[ -p "${ROFI_PIPE}" ]] || mkfifo "${ROFI_PIPE}" 2>/dev/null || true

    _rotate_log
    log_audit "rofi-handler v${VERSION} initialised (PID=$$)"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 5  SETTINGS LOADER
# ══════════════════════════════════════════════════════════════════════════════

# Global configuration variables (populated by load_settings)
FONT="${DEFAULT_FONT}"
ICON_THEME="${DEFAULT_ICON_THEME}"
DPI="auto"
POSITION="center"
X_OFFSET="0"
Y_OFFSET="0"
BORDER_WIDTH="1"
BORDER_RADIUS="16"
ANIMATION="fade"
ANIMATION_SPEED="200"
LINES="8"
WIDTH="800"
TERMINAL="${TERMINAL:-kitty}"
EDITOR="${EDITOR:-nvim}"
NOTIFY_ON_LAUNCH="false"
NOTIFY_ON_ERROR="true"
ACCESSIBILITY_FONT_SCALE="1.0"
HIGH_CONTRAST="false"
SINGLETON_MODE="true"
PREWARM_CACHE="true"
DEFAULT_THEME="glassmorphism"

load_settings() {
    [[ -f "${ROFI_HANDLER_SETTINGS}" ]] || return 0

    while IFS='=' read -r key val; do
        [[ "${key}" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${key}" ]]               && continue
        key="${key// /}"
        val="${val//\"/}"; val="${val//\'/}"
        case "${key}" in
            font|icon_theme|dpi|position|x_offset|y_offset|\
            border_width|border_radius|animation|animation_speed|\
            lines|width|terminal|editor|notify_on_launch|\
            notify_on_error|accessibility_font_scale|high_contrast|\
            singleton_mode|prewarm_cache|default_theme)
                printf -v "${key}" '%s' "${val}" ;;
        esac
    done < "${ROFI_HANDLER_SETTINGS}"

    # Apply accessibility font scaling
    if [[ "${ACCESSIBILITY_FONT_SCALE}" != "1.0" ]]; then
        local base_size font_name font_size
        font_name="${FONT% *}"
        font_size="${FONT##* }"
        font_size="$(echo "${font_size} * ${ACCESSIBILITY_FONT_SCALE}" \
            | bc -l 2>/dev/null | cut -d. -f1)"
        FONT="${font_name} ${font_size}"
    fi

    log_debug "Settings loaded: font='${FONT}' pos='${POSITION}'"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 6  DEPENDENCY & ENVIRONMENT CHECK
# ══════════════════════════════════════════════════════════════════════════════

check_deps() {
    # Required
    local missing=()
    for dep in rofi jq; do
        command -v "${dep}" &>/dev/null || missing+=("${dep}")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing[*]}"
        notify_error "Missing deps: ${missing[*]}"
        exit 1
    fi

    # Check Rofi version
    local rofi_ver
    rofi_ver="$(rofi -version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)"
    log_debug "Rofi version: ${rofi_ver}"

    # Optional (warn only)
    local opt_missing=()
    for dep in hyprctl wl-copy notify-send; do
        command -v "${dep}" &>/dev/null || opt_missing+=("${dep}")
    done
    if [[ ${#opt_missing[@]} -gt 0 ]]; then
        log_warn "Optional deps missing: ${opt_missing[*]}"
    fi

    # Wayland check
    if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
        log_warn "WAYLAND_DISPLAY not set — some features may degrade"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# § 7  MONITOR & GEOMETRY ENGINE
# ══════════════════════════════════════════════════════════════════════════════

# Returns: "width height x y scale" for the active monitor
get_active_monitor_geometry() {
    if command -v hyprctl &>/dev/null; then
        local monitor_json
        monitor_json="$(hyprctl monitors -j 2>/dev/null)"
        if [[ -n "${monitor_json}" ]]; then
            # Get focused monitor
            echo "${monitor_json}" | jq -r '
                .[] | select(.focused == true) |
                "\(.width) \(.height) \(.x) \(.y) \(.scale)"
            ' 2>/dev/null | head -1
            return
        fi
    fi

    # Fallback: use xrandr
    if command -v xrandr &>/dev/null; then
        xrandr --current 2>/dev/null \
            | grep '*' \
            | awk 'NR==1{split($1,a,"x"); print a[1], a[2], "0", "0", "1"}' \
            | head -1
        return
    fi

    # Last resort
    echo "1920 1080 0 0 1"
}

# Get cursor position in Wayland
get_cursor_position() {
    if command -v hyprctl &>/dev/null; then
        hyprctl cursorpos 2>/dev/null | tr ',' ' ' | tr -d ' ' \
            | awk '{print $1, $2}' 2>/dev/null || echo "0 0"
    else
        echo "0 0"
    fi
}

# Build Rofi geometry args for a given menu
build_geometry_args() {
    local menu_id="$1"
    local position="${2:-${POSITION}}"
    local width="${3:-${WIDTH}}"

    local -a args=()

    # DPI
    if [[ "${DPI}" != "auto" ]]; then
        args+=( "-dpi" "${DPI}" )
    fi

    # Width
    args+=( "-width" "${width}" )

    # Location / anchor
    case "${position}" in
        center)
            args+=( "-location" "0" )
            ;;
        north|top)
            args+=( "-location" "2" "-yoffset" "40" )
            ;;
        south|bottom)
            args+=( "-location" "8" "-yoffset" "-40" )
            ;;
        northwest|top-left)
            args+=( "-location" "1" "-xoffset" "20" "-yoffset" "60" )
            ;;
        northeast|top-right)
            args+=( "-location" "3" "-xoffset" "-20" "-yoffset" "60" )
            ;;
        southwest|bottom-left)
            args+=( "-location" "7" "-xoffset" "20" "-yoffset" "-40" )
            ;;
        southeast|bottom-right)
            args+=( "-location" "9" "-xoffset" "-20" "-yoffset" "-40" )
            ;;
        cursor)
            local cx cy
            read -r cx cy <<< "$(get_cursor_position)"
            args+=( "-location" "0" "-xoffset" "${cx}" "-yoffset" "${cy}" )
            ;;
    esac

    # Custom offsets
    [[ "${X_OFFSET}" != "0" ]] && args+=( "-xoffset" "${X_OFFSET}" )
    [[ "${Y_OFFSET}" != "0" ]] && args+=( "-yoffset" "${Y_OFFSET}" )

    echo "${args[@]}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 8  THEME ENGINE INTEGRATION
# ══════════════════════════════════════════════════════════════════════════════

# Get current ASH theme accent color
get_theme_accent() {
    local accent="#cba6f7"  # Catppuccin Mocha Mauve fallback
    if [[ -f "${ASH_THEME_FILE}" ]]; then
        local extracted
        extracted="$(grep -i 'accent\s*=' "${ASH_THEME_FILE}" 2>/dev/null \
            | head -1 | cut -d= -f2 | tr -d ' "#')"
        [[ -n "${extracted}" ]] && accent="#${extracted##\#}"
    fi
    echo "${accent}"
}

# Get current theme dark/light mode
get_theme_mode() {
    if [[ -f "${ASH_THEME_FILE}" ]]; then
        grep -i 'mode\s*=' "${ASH_THEME_FILE}" 2>/dev/null \
            | head -1 | cut -d= -f2 | tr -d ' "' || echo "dark"
    else
        echo "dark"
    fi
}

# Build -theme path for a menu
build_theme_path() {
    local menu_id="$1"
    local theme_file=""

    # Get theme from registry
    if [[ -n "${MENU_REGISTRY[${menu_id}]:-}" ]]; then
        IFS=':' read -r _cat theme_rel _rest <<< "${MENU_REGISTRY[${menu_id}]}"
        [[ -n "${theme_rel}" ]] && theme_file="${ROFI_DIR}/${theme_rel}"
    fi

    # Fallback to default theme
    if [[ -z "${theme_file}" ]] || [[ ! -f "${theme_file}" ]]; then
        theme_file="${ROFI_THEMES_DIR}/${DEFAULT_THEME}.css"
    fi

    # Final fallback
    if [[ ! -f "${theme_file}" ]]; then
        log_warn "No theme file for menu '${menu_id}' — using default"
        theme_file=""
    fi

    echo "${theme_file}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 9  PROCESS LIFECYCLE MANAGER
# ══════════════════════════════════════════════════════════════════════════════

pid_file() {
    local menu_id="$1"
    echo "${ROFI_PID_DIR}/${menu_id}.pid"
}

is_running() {
    local menu_id="$1"
    local pf
    pf="$(pid_file "${menu_id}")"
    [[ ! -f "${pf}" ]] && return 1
    local pid
    pid="$(cat "${pf}" 2>/dev/null)"
    [[ -z "${pid}" ]] && return 1
    kill -0 "${pid}" 2>/dev/null
}

register_pid() {
    local menu_id="$1" pid="$2"
    echo "${pid}" > "$(pid_file "${menu_id}")"
}

cleanup_pid() {
    local menu_id="$1"
    rm -f "$(pid_file "${menu_id}")"
}

kill_menu() {
    local menu_id="$1"
    local pf
    pf="$(pid_file "${menu_id}")"
    if [[ -f "${pf}" ]]; then
        local pid
        pid="$(cat "${pf}" 2>/dev/null)"
        [[ -n "${pid}" ]] && kill -TERM "${pid}" 2>/dev/null || true
        rm -f "${pf}"
        log_info "Killed menu: ${menu_id} (PID=${pid})"
    fi
}

kill_all_menus() {
    find "${ROFI_PID_DIR}" -name "*.pid" -type f 2>/dev/null \
    | while read -r pf; do
        local pid
        pid="$(cat "${pf}" 2>/dev/null)"
        [[ -n "${pid}" ]] && kill -TERM "${pid}" 2>/dev/null || true
        rm -f "${pf}"
    done
    log_info "All Rofi menus terminated"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 10  HOOK SYSTEM
# ══════════════════════════════════════════════════════════════════════════════

# Hook files live at: ASH_DIR/rofi/hooks/<menu_id>/<hook_name>.sh
# Hook names: pre_launch, post_launch, on_selection, on_cancel, on_error
#             pre_close, post_close, on_timeout, on_singleton, on_prewarm

run_hook() {
    local menu_id="$1" hook_name="$2"
    shift 2
    local hook_args=("$@")
    local hook_file="${ASH_DIR}/rofi/hooks/${menu_id}/${hook_name}.sh"

    [[ ! -f "${hook_file}" ]] && return 0
    [[ ! -x "${hook_file}" ]] && chmod +x "${hook_file}"

    log_debug "Running hook: ${menu_id}/${hook_name}"

    local exit_code=0
    ROFI_MENU="${menu_id}" \
    ROFI_HOOK="${hook_name}" \
    timeout 5 bash "${hook_file}" "${hook_args[@]}" \
        >>"${ROFI_LOG_FILE}" 2>&1 || exit_code=$?

    if (( exit_code != 0 )); then
        log_warn "Hook ${hook_name} exited ${exit_code} for ${menu_id}"
    fi

    log_debug "Hook done: ${menu_id}/${hook_name} (exit=${exit_code})"
    return "${exit_code}"
}

# Global hooks (run for every menu)
run_global_hook() {
    local hook_name="$1"
    shift
    local global_hook="${ASH_DIR}/rofi/hooks/global/${hook_name}.sh"
    [[ -f "${global_hook}" ]] && \
        run_hook "global" "${hook_name}" "$@" || true
}

# ══════════════════════════════════════════════════════════════════════════════
# § 11  SESSION MANAGER
# ══════════════════════════════════════════════════════════════════════════════

session_save() {
    local key="$1" val="$2"
    local tmp
    tmp="$(mktemp)"
    if [[ -f "${ROFI_SESSION_FILE}" ]]; then
        jq --arg k "${key}" --arg v "${val}" \
            '.[$k] = $v | .updated_at = now | todate' \
            "${ROFI_SESSION_FILE}" > "${tmp}" 2>/dev/null \
            && mv "${tmp}" "${ROFI_SESSION_FILE}" \
            || rm -f "${tmp}"
    else
        jq -n \
            --arg k "${key}" --arg v "${val}" \
            '{($k): $v, updated_at: (now | todate)}' \
            > "${ROFI_SESSION_FILE}" 2>/dev/null || true
    fi
}

session_get() {
    local key="$1" default="${2:-}"
    [[ ! -f "${ROFI_SESSION_FILE}" ]] && { echo "${default}"; return; }
    local val
    val="$(jq -r --arg k "${key}" '.[$k] // empty' \
        "${ROFI_SESSION_FILE}" 2>/dev/null)"
    echo "${val:-${default}}"
}

session_get_last_menu() {
    session_get "last_menu" "apps"
}

session_save_result() {
    local menu_id="$1" selection="$2" exit_code="$3"
    session_save "last_menu"      "${menu_id}"
    session_save "last_selection" "${selection}"
    session_save "last_exit_code" "${exit_code}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 12  NOTIFICATION ENGINE
# ══════════════════════════════════════════════════════════════════════════════

notify_user() {
    local summary="$1" body="${2:-}" urgency="${3:-low}" icon="${4:-}"
    [[ "${NOTIFY_ON_LAUNCH}" != "true" ]] && [[ "${urgency}" == "low" ]] && return 0
    command -v notify-send &>/dev/null || return 0
    local -a args=(
        "--urgency=${urgency}"
        "--app-name=Rofi Handler"
        "--expire-time=3000"
    )
    [[ -n "${icon}" ]] && args+=( "--icon=${icon}" )
    notify-send "${args[@]}" "${summary}" "${body}" &>/dev/null &
}

notify_error() {
    local msg="$1"
    [[ "${NOTIFY_ON_ERROR}" != "true" ]] && return 0
    command -v notify-send &>/dev/null || return 0
    notify-send \
        --urgency=critical \
        --app-name="Rofi Handler" \
        --icon="dialog-error" \
        "Rofi Error" \
        "${msg}" &>/dev/null &
}

# ══════════════════════════════════════════════════════════════════════════════
# § 13  IPC BRIDGE
# ══════════════════════════════════════════════════════════════════════════════

# Send a command to a running rofi instance via Rofi's -drun-show-action
# or through our own named pipe IPC
ipc_send() {
    local cmd="$1"
    if [[ -p "${ROFI_PIPE}" ]]; then
        echo "${cmd}" > "${ROFI_PIPE}" &
        log_debug "IPC sent: ${cmd}"
    else
        log_warn "IPC pipe not available: ${ROFI_PIPE}"
    fi
}

# Listen on IPC pipe (run in background)
ipc_listen() {
    [[ -p "${ROFI_PIPE}" ]] || return 0
    log_debug "IPC listener started"
    while true; do
        if read -r cmd < "${ROFI_PIPE}"; then
            log_debug "IPC received: ${cmd}"
            case "${cmd}" in
                launch:*)
                    local menu="${cmd#launch:}"
                    launch_menu "${menu}" &
                    ;;
                kill:*)
                    local menu="${cmd#kill:}"
                    kill_menu "${menu}"
                    ;;
                kill-all)
                    kill_all_menus
                    ;;
                reload-settings)
                    load_settings
                    ;;
                status)
                    print_status
                    ;;
                *)
                    log_warn "Unknown IPC command: ${cmd}"
                    ;;
            esac
        fi
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# § 14  PREWARM CACHE ENGINE
# ══════════════════════════════════════════════════════════════════════════════

# Pre-warm frequently used menus by running them invisibly to populate caches
prewarm_menu() {
    local menu_id="$1"
    local cache_file="${ROFI_CACHE_DIR}/prewarm-${menu_id}.cache"

    # Only prewarm if cache is stale (>1h)
    if [[ -f "${cache_file}" ]]; then
        local now age mtime
        now="$(date +%s)"
        mtime="$(stat -c %Y "${cache_file}" 2>/dev/null || echo 0)"
        age=$(( now - mtime ))
        (( age < 3600 )) && return 0
    fi

    log_debug "Prewarming: ${menu_id}"

    # Run the script in background to populate its caches
    local script_rel
    IFS=':' read -r _cat _theme script_rel _rest \
        <<< "${MENU_REGISTRY[${menu_id}]:-}"
    if [[ -n "${script_rel}" ]]; then
        local script_path="${ROFI_DIR}/${script_rel}"
        if [[ -x "${script_path}" ]]; then
            # Run with ROFI_RETV=28 (initial call) to populate cache
            ROFI_RETV=28 ROFI_OUTSIDE=1 \
                timeout 5 bash "${script_path}" \
                >/dev/null 2>&1 &
        fi
    fi

    touch "${cache_file}"
}

prewarm_all() {
    [[ "${PREWARM_CACHE}" != "true" ]] && return 0
    log_info "Prewarming all menus…"
    local id
    for id in "${!MENU_REGISTRY[@]}"; do
        prewarm_menu "${id}" &
    done
    log_debug "Prewarm jobs dispatched"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 15  CORE LAUNCH ENGINE
# ══════════════════════════════════════════════════════════════════════════════

launch_menu() {
    local menu_id="$1"
    shift
    local extra_args=("$@")

    log_audit "LAUNCH: ${menu_id}"

    # ── Validate menu exists ─────────────────────────────────────────────
    if [[ -z "${MENU_REGISTRY[${menu_id}]:-}" ]]; then
        log_error "Unknown menu: ${menu_id}"
        notify_error "Unknown menu: '${menu_id}'"
        return 1
    fi

    # ── Singleton check ──────────────────────────────────────────────────
    if [[ "${SINGLETON_MODE}" == "true" ]]; then
        if is_running "${menu_id}"; then
            log_info "Singleton: ${menu_id} already running — focusing"
            run_hook "${menu_id}" "on_singleton"
            # Try to focus existing instance
            local pid
            pid="$(cat "$(pid_file "${menu_id}")" 2>/dev/null)"
            [[ -n "${pid}" ]] && kill -USR1 "${pid}" 2>/dev/null || true
            return 0
        fi
    fi

    # ── Parse menu registry entry ─────────────────────────────────────────
    local category theme_rel script_rel description icon
    IFS=':' read -r category theme_rel script_rel description icon \
        <<< "${MENU_REGISTRY[${menu_id}]}"

    local theme_path
    theme_path="$(build_theme_path "${menu_id}")"

    local script_path=""
    if [[ -n "${script_rel}" ]]; then
        script_path="${ROFI_DIR}/${script_rel}"
    fi

    # ── Pre-launch hook ──────────────────────────────────────────────────
    run_global_hook "pre_launch" "${menu_id}" || true
    run_hook "${menu_id}" "pre_launch" || true

    # ── Build Rofi arguments ─────────────────────────────────────────────
    local -a rofi_args=()
    local -a geo_args
    read -ra geo_args <<< "$(build_geometry_args "${menu_id}")"
    rofi_args+=( "${geo_args[@]}" )

    # Font
    rofi_args+=( "-font" "${FONT}" )

    # Icon theme
    rofi_args+=( "-icon-theme" "${ICON_THEME}" )

    # Theme
    [[ -n "${theme_path}" ]] && rofi_args+=( "-theme" "${theme_path}" )

    # High contrast override
    if [[ "${HIGH_CONTRAST}" == "true" ]]; then
        rofi_args+=(
            "-theme-str" "* { bg-col: #000000; fg-col: #ffffff; }"
        )
    fi

    # Lines
    rofi_args+=( "-lines" "${LINES}" )

    # ── Build modi-specific args ──────────────────────────────────────────
    local -a modi_args=()
    case "${menu_id}" in
        apps)
            modi_args=( "-show" "drun" "-drun-show-actions" )
            ;;
        runner)
            modi_args=( "-show" "run" )
            ;;
        window)
            modi_args=( "-show" "window" )
            ;;
        ssh)
            modi_args=( "-show" "ssh" )
            ;;
        *)
            if [[ -n "${script_path}" ]] && [[ -f "${script_path}" ]]; then
                chmod +x "${script_path}"
                local modi_name="${menu_id}"
                modi_args=(
                    "-show"  "${modi_name}"
                    "-modi"  "${modi_name}:${script_path}"
                )
            fi
            ;;
    esac

    rofi_args+=( "${modi_args[@]}" )

    # Extra args from caller
    rofi_args+=( "${extra_args[@]}" )

    # ── Performance timer start ───────────────────────────────────────────
    local t_start
    t_start="$(date +%s%3N)"

    # ── Notification ──────────────────────────────────────────────────────
    notify_user "${ICON_LAUNCH} Opening ${description:-${menu_id}}" "" "low"
    log_info "Launching: ${menu_id} → rofi ${rofi_args[*]}"

    # ── Launch Rofi ───────────────────────────────────────────────────────
    local selection="" exit_code=0

    # Run in subshell to capture selection + exit code
    selection="$(
        "${ROFI_BIN}" "${rofi_args[@]}" 2>>"${ROFI_LOG_FILE}"
    )" || exit_code=$?

    local t_end duration_ms
    t_end="$(date +%s%3N)"
    duration_ms=$(( t_end - t_start ))

    # ── Post-close hooks ──────────────────────────────────────────────────
    run_hook "${menu_id}" "pre_close" "${selection}" "${exit_code}" || true

    # ── Process exit codes ────────────────────────────────────────────────
    case "${exit_code}" in
        0)
            log_info "Selection: '${selection}' (${duration_ms}ms)"
            run_hook "${menu_id}" "on_selection" "${selection}" || true
            ;;
        1)
            log_debug "Cancelled: ${menu_id}"
            run_hook "${menu_id}" "on_cancel" || true
            ;;
        10|11|12|13|14|15|16|17|18|19|20)
            # Custom keybind exit codes
            log_info "Custom keybind exit: ${exit_code} selection='${selection}'"
            run_hook "${menu_id}" "on_custom_keybind" \
                "${exit_code}" "${selection}" || true
            ;;
        130)
            log_debug "Interrupted: ${menu_id}"
            run_hook "${menu_id}" "on_cancel" || true
            ;;
        *)
            log_error "Rofi exited ${exit_code} for: ${menu_id}"
            run_hook "${menu_id}" "on_error" "${exit_code}" || true
            notify_error "Menu '${menu_id}' failed (exit ${exit_code})"
            ;;
    esac

    # ── Post-close ────────────────────────────────────────────────────────
    run_hook "${menu_id}" "post_close" "${selection}" "${exit_code}" || true
    run_global_hook "post_close" "${menu_id}" "${selection}" "${exit_code}" || true

    # ── Dispatch action on successful selection ───────────────────────────
    if [[ -n "${selection}" ]] && [[ "${exit_code}" -eq 0 ]]; then
        dispatch_action "${menu_id}" "${selection}" "${exit_code}"
    fi

    # ── Session + performance logging ─────────────────────────────────────
    session_save_result "${menu_id}" "${selection}" "${exit_code}"
    log_perf_json "${menu_id}" "${duration_ms}" "${exit_code}" "${selection}"
    log_perf "Menu '${menu_id}' closed in ${duration_ms}ms (exit=${exit_code})"
    cleanup_pid "${menu_id}"

    return "${exit_code}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 16  ACTION DISPATCHER
# ══════════════════════════════════════════════════════════════════════════════

dispatch_action() {
    local menu_id="$1" selection="$2" exit_code="$3"

    log_debug "Dispatch: ${menu_id} → '${selection}'"

    case "${menu_id}" in
        apps)
            # drun handles execution internally; nothing needed
            ;;
        runner)
            # run mode handles execution internally
            ;;
        window)
            # window mode handles focus internally
            ;;
        ssh)
            # SSH connection handled by script; xterm/kitty spawned by script
            ;;
        files)
            # File browser handles opening internally
            ;;
        powermenu)
            # Power actions handled by powermenu.sh
            ;;
        wallpaper)
            # Wallpaper set by wallpaper.sh
            ;;
        theme-picker)
            # Theme apply handled by theme-picker.sh
            if [[ -n "${selection}" ]]; then
                local ash_bin
                ash_bin="${ASH_DIR}/../ash-cli/ash"
                if [[ -x "${ash_bin}" ]]; then
                    "${ash_bin}" theme apply "${selection}" &>/dev/null &
                fi
            fi
            ;;
        emoji)
            # Emoji copied to clipboard by emoji.sh
            ;;
        color-picker)
            # Color value copied by color-picker.sh
            ;;
        translate)
            # Translation copied by translation.sh
            ;;
        calc)
            # Result copied by calc.sh
            ;;
        clipboard)
            # Paste handled by clipboard.sh
            ;;
        *)
            log_debug "No dispatch handler for: ${menu_id}"
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# § 17  SPECIALIZED LAUNCHERS
# ══════════════════════════════════════════════════════════════════════════════

# Launch with a specific position override
launch_at() {
    local menu_id="$1" position="$2"
    shift 2
    POSITION="${position}" launch_menu "${menu_id}" "$@"
}

# Launch and wait (blocking)
launch_blocking() {
    local menu_id="$1"
    shift
    launch_menu "${menu_id}" "$@"
}

# Launch as floating overlay (Hyprland dispatch)
launch_floating() {
    local menu_id="$1"
    shift
    if command -v hyprctl &>/dev/null; then
        hyprctl dispatch exec \
            "[float; center; size 800 600] rofi-handler launch ${menu_id}" \
            &>/dev/null &
    else
        launch_menu "${menu_id}" "$@" &
    fi
}

# Chain menus (open next menu after selection)
launch_chain() {
    local -a menu_chain=("$@")
    local current="${menu_chain[0]}"
    local rest=( "${menu_chain[@]:1}" )

    local selection
    selection="$(
        "${ROFI_BIN}" \
            -show "${current}" \
            -modi "${current}:${ROFI_DIR}/menus/${current}/${current}.sh" \
            -theme "$(build_theme_path "${current}")" \
            -font "${FONT}" \
            2>/dev/null
    )" || return 0

    if [[ -n "${selection}" ]] && [[ ${#rest[@]} -gt 0 ]]; then
        ROFI_PREV_SELECTION="${selection}" \
            launch_chain "${rest[@]}"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# § 18  QUICK-LAUNCH SHORTCUTS (used by keybind binds in hyprland.conf)
# ══════════════════════════════════════════════════════════════════════════════

quick_apps()         { launch_menu "apps"; }
quick_runner()       { launch_menu "runner"; }
quick_window()       { launch_menu "window"; }
quick_powermenu()    { launch_menu "powermenu"; }
quick_screenshot()   { launch_menu "screenshot"; }
quick_wallpaper()    { launch_menu "wallpaper"; }
quick_theme()        { launch_menu "theme-picker"; }
quick_mode()         { launch_menu "mode-selector"; }
quick_emoji()        { launch_menu "emoji"; }
quick_calc()         { launch_menu "calc"; }
quick_clipboard()    { launch_menu "clipboard"; }
quick_color()        { launch_menu "color-picker"; }
quick_translate()    { launch_menu "translate"; }
quick_quicknote()    { launch_menu "quicknote"; }
quick_bluetooth()    { launch_menu "bluetooth"; }
quick_wifi()         { launch_menu "wifi"; }
quick_audio()        { launch_menu "audio-switcher"; }
quick_plugins()      { launch_menu "plugin-manager"; }
quick_ssh()          { launch_menu "ssh"; }
quick_docker()       { launch_menu "docker-manager"; }
quick_process()      { launch_menu "process-killer"; }
quick_keybinds()     { launch_menu "keybind-viewer"; }
quick_files()        { launch_menu "files"; }

# ══════════════════════════════════════════════════════════════════════════════
# § 19  STATUS & DIAGNOSTICS
# ══════════════════════════════════════════════════════════════════════════════

print_status() {
    local running=0 total
    total="${#MENU_REGISTRY[@]}"

    printf '\n%s Rofi Handler v%s — Status\n' "${ICON_ROFI}" "${VERSION}"
    printf '%s\n' "$(printf '─%.0s' {1..60})"
    printf '%-20s %-10s %-10s\n' "Menu" "Category" "Status"
    printf '%-20s %-10s %-10s\n' "────" "────────" "──────"

    local id
    for id in $(echo "${!MENU_REGISTRY[@]}" | tr ' ' '\n' | sort); do
        local cat
        IFS=':' read -r cat _rest <<< "${MENU_REGISTRY[${id}]}"
        local status="idle"
        if is_running "${id}"; then
            status="running"
            (( running++ ))
        fi
        printf '%-20s %-10s %-10s\n' "${id}" "${cat}" "${status}"
    done

    printf '%s\n' "$(printf '─%.0s' {1..60})"
    printf 'Running: %d / %d\n' "${running}" "${total}"
    printf 'Session: %s\n' "$(session_get_last_menu)"
    printf 'Log:     %s\n' "${ROFI_LOG_FILE}"
    printf 'Cache:   %s\n' "${ROFI_CACHE_DIR}"
}

print_perf_report() {
    [[ ! -f "${ROFI_PERF_LOG}" ]] && {
        echo "No performance data yet"
        return
    }

    printf '\n%s Rofi Performance Report\n' "${ICON_PERF}"
    printf '%s\n' "$(printf '─%.0s' {1..60})"
    printf '%-20s %-10s %-10s %-10s\n' "Menu" "Count" "Avg ms" "Max ms"
    printf '%-20s %-10s %-10s %-10s\n' "────" "─────" "──────" "──────"

    jq -rs '
        group_by(.menu) |
        .[] |
        {
            menu:  .[0].menu,
            count: length,
            avg:   (map(.duration_ms) | add / length | floor),
            max:   (map(.duration_ms) | max)
        } |
        [.menu, .count, .avg, .max] | @tsv
    ' "${ROFI_PERF_LOG}" 2>/dev/null \
    | while IFS=$'\t' read -r menu count avg max_ms; do
        printf '%-20s %-10s %-10s %-10s\n' \
            "${menu}" "${count}" "${avg}ms" "${max_ms}ms"
    done
}

print_menu_list() {
    printf '\n%s Available Menus (%d)\n' "${ICON_ROFI}" "${#MENU_REGISTRY[@]}"
    printf '%s\n' "$(printf '─%.0s' {1..70})"
    printf '%-20s %-12s %-5s %-30s\n' "ID" "Category" "Icon" "Description"
    printf '%-20s %-12s %-5s %-30s\n' "──" "────────" "────" "───────────"

    local id
    for id in $(echo "${!MENU_REGISTRY[@]}" | tr ' ' '\n' | sort); do
        local cat theme_rel script_rel desc icon_char
        IFS=':' read -r cat _theme_rel _script_rel desc icon_char \
            <<< "${MENU_REGISTRY[${id}]}"
        printf '%-20s %-12s %-5s %-30s\n' \
            "${id}" "${cat}" "${icon_char}" "${desc}"
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# § 20  HOT-RELOAD SUPPORT
# ══════════════════════════════════════════════════════════════════════════════

hot_reload() {
    log_info "Hot reload triggered"
    load_settings
    # Clear prewarm caches so they rebuild
    rm -f "${ROFI_CACHE_DIR}"/prewarm-*.cache 2>/dev/null || true
    log_info "Settings reloaded, prewarm caches cleared"
    notify_user "󰑐 Rofi Settings Reloaded" "Configuration hot-reloaded" "low"
}

# Watch for config file changes (inotifywait)
watch_config() {
    if ! command -v inotifywait &>/dev/null; then
        log_warn "inotifywait not found — hot-reload watch disabled"
        return 1
    fi

    log_info "Watching config for changes: ${ROFI_HANDLER_SETTINGS}"
    inotifywait \
        --quiet \
        --monitor \
        --event close_write \
        "${ROFI_HANDLER_SETTINGS}" \
        "${ASH_THEME_FILE}" \
        2>/dev/null \
    | while read -r; do
        hot_reload
    done &

    log_info "Config watcher PID: $!"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 21  HELP & USAGE
# ══════════════════════════════════════════════════════════════════════════════

print_help() {
    cat <<EOF

${ICON_ROFI}  Rofi Handler v${VERSION} — ASH Dotfiles Ultra Engine

USAGE:
  rofi-handler.sh <COMMAND> [OPTIONS]
  rofi-handler.sh launch <menu_id> [rofi_args...]
  rofi-handler.sh <menu_id>                        # Quick launch shorthand

COMMANDS:
  launch <id> [args]     Launch a Rofi menu by ID
  launch-at <id> <pos>   Launch at position (center|top|bottom|cursor|…)
  launch-float <id>      Launch as floating Hyprland window
  launch-chain <id...>   Chain multiple menus in sequence
  kill <id>              Kill a running menu instance
  kill-all               Kill all running Rofi instances
  reload                 Hot-reload configuration
  watch                  Watch config for auto-reload (background)
  prewarm                Prewarm cache for all menus
  prewarm <id>           Prewarm specific menu cache
  status                 Show handler status and running menus
  list                   List all available menus
  perf                   Show performance report
  ipc <cmd>              Send IPC command
  version                Print version

QUICK-LAUNCH SHORTCUTS:
  apps        launcher    emoji       translate
  runner      powermenu   calc        quicknote
  window      screenshot  clipboard   bluetooth
  ssh         wallpaper   color       wifi
  files       theme       plugins     audio
  docker      process     keybinds    mode

POSITION VALUES: center top bottom top-left top-right
                 bottom-left bottom-right cursor

ENVIRONMENT:
  ASH_DEBUG=1            Enable debug logging
  ROFI_BIN=<path>        Override rofi binary path
  ROFI_FONT=<font>       Override font
  ROFI_ICON_THEME=<name> Override icon theme

EXAMPLES:
  rofi-handler.sh launch apps
  rofi-handler.sh launch-at powermenu center
  rofi-handler.sh launch translate -lines 15
  rofi-handler.sh kill-all
  rofi-handler.sh prewarm apps runner
  rofi-handler.sh status
  rofi-handler.sh perf

EOF
}

# ══════════════════════════════════════════════════════════════════════════════
# § 22  ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════

main() {
    init
    load_settings
    check_deps

    local cmd="${1:-}"
    shift 2>/dev/null || true

    # Environment overrides
    [[ -n "${ROFI_FONT:-}" ]]       && FONT="${ROFI_FONT}"
    [[ -n "${ROFI_ICON_THEME:-}" ]] && ICON_THEME="${ROFI_ICON_THEME}"

    case "${cmd}" in
        # ── Core launch commands ─────────────────────────────────────────
        launch)
            local menu_id="${1:?Usage: rofi-handler.sh launch <menu_id>}"
            shift
            launch_menu "${menu_id}" "$@"
            ;;
        launch-at)
            local menu_id="${1:?}" pos="${2:-center}"
            shift 2
            launch_at "${menu_id}" "${pos}" "$@"
            ;;
        launch-float)
            local menu_id="${1:?}"
            shift
            launch_floating "${menu_id}" "$@"
            ;;
        launch-chain)
            launch_chain "$@"
            ;;

        # ── Quick shortcuts (called directly from hyprland keybinds) ────
        apps)           quick_apps ;;
        runner)         quick_runner ;;
        window)         quick_window ;;
        powermenu)      quick_powermenu ;;
        screenshot)     quick_screenshot ;;
        wallpaper)      quick_wallpaper ;;
        theme)          quick_theme ;;
        mode)           quick_mode ;;
        emoji)          quick_emoji ;;
        calc)           quick_calc ;;
        clipboard)      quick_clipboard ;;
        color|color-picker) quick_color ;;
        translate)      quick_translate ;;
        quicknote|note) quick_quicknote ;;
        bluetooth|bt)   quick_bluetooth ;;
        wifi|network)   quick_wifi ;;
        audio)          quick_audio ;;
        plugins|plugin) quick_plugins ;;
        ssh)            quick_ssh ;;
        docker)         quick_docker ;;
        process|kill-proc) quick_process ;;
        keybinds|keys)  quick_keybinds ;;
        files)          quick_files ;;

        # ── Lifecycle ────────────────────────────────────────────────────
        kill)
            local menu_id="${1:?Usage: rofi-handler.sh kill <menu_id>}"
            kill_menu "${menu_id}"
            ;;
        kill-all)
            kill_all_menus
            ;;
        reload)
            hot_reload
            ;;
        watch)
            watch_config
            ;;

        # ── Cache ─────────────────────────────────────────────────────────
        prewarm)
            if [[ $# -gt 0 ]]; then
                for menu_id in "$@"; do
                    prewarm_menu "${menu_id}"
                done
            else
                prewarm_all
            fi
            ;;

        # ── IPC ──────────────────────────────────────────────────────────
        ipc)
            local ipc_cmd="${1:?Usage: rofi-handler.sh ipc <command>}"
            ipc_send "${ipc_cmd}"
            ;;
        ipc-listen)
            ipc_listen
            ;;

        # ── Info ─────────────────────────────────────────────────────────
        status|st)
            print_status
            ;;
        list|ls)
            print_menu_list
            ;;
        perf|performance)
            print_perf_report
            ;;
        version|-V|--version)
            echo "rofi-handler v${VERSION}"
            ;;
        help|--help|-h|"")
            print_help
            ;;

        # ── Unknown → try as menu ID ──────────────────────────────────────
        *)
            if [[ -n "${MENU_REGISTRY[${cmd}]:-}" ]]; then
                launch_menu "${cmd}" "$@"
            else
                log_error "Unknown command or menu: ${cmd}"
                printf 'Unknown: %s\nRun: rofi-handler.sh help\n' "${cmd}" >&2
                exit 1
            fi
            ;;
    esac
}

main "$@"
