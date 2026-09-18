#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — MODE COMMAND ENGINE                              ║
# ║  /ash-cli/commands/mode/mode.sh                                              ║
# ║                                                                              ║
# ║  Ultra-premium desktop mode switching system with:                           ║
# ║  • Animated transitions with progress indicators                             ║
# ║  • Hardware-aware optimization per mode                                      ║
# ║  • Hook system (pre/post mode change)                                        ║
# ║  • IPC notifications to all desktop components                               ║
# ║  • State persistence and history tracking                                    ║
# ║  • Plugin integration support                                                ║
# ║  • Accessibility-first design                                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE:
#   ash mode <subcommand> [options]
#
# SUBCOMMANDS:
#   game          Activate gaming mode (max performance)
#   work          Activate work mode (productivity focused)
#   focus         Activate focus mode (distraction-free)
#   cinema        Activate cinema mode (media optimized)
#   present       Activate presentation mode
#   battery       Activate battery saver mode
#   stream        Activate streaming mode
#   privacy       Activate privacy mode
#   accessibility Activate accessibility mode
#   default       Reset to default mode
#   create        Create a custom mode
#   list          List all available modes
#   status        Show current mode status
#
# EXAMPLES:
#   ash mode game
#   ash mode focus --duration 90m
#   ash mode list --format json
#   ash mode status --verbose

set -euo pipefail
IFS=$'\n\t'

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 1 — BOOTSTRAP & DEPENDENCY RESOLUTION
# ─────────────────────────────────────────────────────────────────────────────

# Resolve the absolute path of the ash-cli root directory
readonly __ASH_CLI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly __ASH_MODE_DIR="${__ASH_CLI_DIR}/commands/mode"
readonly __ASH_LIB_DIR="${__ASH_CLI_DIR}/lib"
readonly __ASH_DATA_DIR="${__ASH_CLI_DIR}/data"

# Source core libraries with existence validation
# Load a core library once.
#
# This used to source unconditionally, which broke the whole command: when mode
# runs under the `ash` dispatcher the libraries are ALREADY loaded, and every
# one of them ends with a `readonly` declaration. Sourcing twice therefore dies
# with "ASH_VALIDATOR_VERSION: readonly variable" before mode does anything.
#
# The dispatcher's own loader dedupes through ASH_LOADED_LIBS; this mirrors that
# so mode works both standalone and as a subcommand.
__ash_require_lib() {
    local lib="${__ASH_LIB_DIR}/${1}"

    # Already loaded? Nothing to do.
    if [[ -n "${ASH_LOADED_LIBS[*]:-}" ]]; then
        local loaded
        for loaded in "${ASH_LOADED_LIBS[@]}"; do
            [[ "$loaded" == "$1" ]] && return 0
        done
    fi

    # Each library also guards itself, but a library sourced before this file
    # existed would not be recorded in ASH_LOADED_LIBS — so fall back to the
    # per-library flag rather than relying on the list alone.
    # Sanitise the name: a hyphen is legal in a filename but not in a bash
    # variable, so `${!flag}` on "progress-bar" produced
    # `_ASH_PROGRESS-BAR_LOADED: invalid variable name`.
    local flag="_ASH_${1%.sh}"
    flag="${flag^^}_LOADED"
    flag="${flag//-/_}"
    [[ -n "${!flag:-}" ]] && return 0

    if [[ ! -f "${lib}" ]]; then
        printf '\033[0;31m[FATAL]\033[0m Missing required library: %s\n' "${lib}" >&2
        exit 127
    fi

    # shellcheck source=/dev/null
    source "${lib}"
    ASH_LOADED_LIBS+=("$1")
}

# The double-load guard appends to this; make sure it exists before the first
# load. `declare -ga ASH_LOADED_LIBS=()` would RESET it and discard everything
# the dispatcher had already recorded — which is exactly the bug this guard
# exists to prevent, so test for existence first.
declare -p ASH_LOADED_LIBS >/dev/null 2>&1 || declare -ga ASH_LOADED_LIBS=()

__ash_require_lib "core.sh"
__ash_require_lib "colors.sh"
__ash_require_lib "logger.sh"
__ash_require_lib "utils.sh"
__ash_require_lib "validator.sh"
__ash_require_lib "animation.sh"
__ash_require_lib "progress-bar.sh"
__ash_require_lib "spinner.sh"
__ash_require_lib "notification.sh"
__ash_require_lib "ipc.sh"
__ash_require_lib "hook-runner.sh"
__ash_require_lib "state-machine.sh"
__ash_require_lib "json-parser.sh"
__ash_require_lib "table-renderer.sh"
__ash_require_lib "box-renderer.sh"
__ash_require_lib "event-bus.sh"
__ash_require_lib "telemetry.sh"

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 2 — CONSTANTS & CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────

# Version and metadata
readonly ASH_MODE_VERSION="5.0.0"
readonly ASH_MODE_BUILD_DATE="2025-01-01"

# XDG-compliant paths.
#
# utils.sh is sourced above and already defines the _DIR forms, so these only
# fill in a default when a variable is genuinely unset. Re-declaring them
# readonly here would override a caller's exported value and lock the name
# against every later library.
: "${ASH_STATE_DIR:=${XDG_STATE_HOME:-${HOME}/.local/state}/ash}"
: "${ASH_DATA_HOME:=${XDG_DATA_HOME:-${HOME}/.local/share}/ash}"
: "${ASH_RUNTIME_DIR:=${XDG_RUNTIME_DIR:-/tmp}/ash}"
: "${ASH_CONFIG_DIR:=${XDG_CONFIG_HOME:-${HOME}/.config}/ash}"

# Mode system paths
readonly ASH_MODE_STATE_FILE="${ASH_STATE_DIR}/current-mode.json"
readonly ASH_MODE_HISTORY_FILE="${ASH_STATE_DIR}/mode-history.jsonl"
readonly ASH_MODE_LOCK_FILE="${ASH_RUNTIME_DIR}/mode.lock"
readonly ASH_MODE_REGISTRY_FILE="${__ASH_DATA_DIR}/mode-registry.json"
readonly ASH_MODE_CUSTOM_DIR="${ASH_DATA_HOME}/modes/custom"
readonly ASH_MODE_CONFIG_FILE="${ASH_CONFIG_DIR}/mode-config.conf"

# IPC socket for real-time updates.
#
# ipc.sh — sourced above — already declares this readonly, as
# "${XDG_RUNTIME_DIR:-/tmp}/ash.sock". ASH_RUNTIME_DIR resolves to
# "${XDG_RUNTIME_DIR:-/tmp}/ash" just above, so the two spellings give the same
# path and re-declaring only produced "ASH_IPC_SOCKET: readonly variable".

# UI Configuration
readonly ASH_MODE_ANIMATION_DURATION=400  # milliseconds
readonly ASH_MODE_SPINNER_STYLE="dots"    # dots|line|circle|bounce
readonly ASH_MODE_TRANSITION_SOUND=true

# Color palette for mode display (256-color + truecolor)
readonly MODE_COLOR_RESET=$'\033[0m'
readonly MODE_COLOR_BOLD=$'\033[1m'
readonly MODE_COLOR_DIM=$'\033[2m'
readonly MODE_COLOR_ITALIC=$'\033[3m'
readonly MODE_COLOR_UNDERLINE=$'\033[4m'
readonly MODE_COLOR_BLINK=$'\033[5m'

# Truecolor definitions
readonly COLOR_ASH_PRIMARY=$'\033[38;2;137;180;250m'     # #89b4fa Catppuccin Blue
readonly COLOR_ASH_SECONDARY=$'\033[38;2;203;166;247m'   # #cba6f7 Catppuccin Mauve
readonly COLOR_ASH_SUCCESS=$'\033[38;2;166;227;161m'     # #a6e3a1 Catppuccin Green
readonly COLOR_ASH_WARNING=$'\033[38;2;249;226;175m'     # #f9e2af Catppuccin Yellow
readonly COLOR_ASH_ERROR=$'\033[38;2;243;139;168m'       # #f38ba8 Catppuccin Red
readonly COLOR_ASH_INFO=$'\033[38;2;148;226;213m'        # #94e2d5 Catppuccin Teal
readonly COLOR_ASH_MUTED=$'\033[38;2;88;91;112m'         # #58596f Catppuccin Overlay
readonly COLOR_ASH_SURFACE=$'\033[38;2;49;50;68m'        # #313244 Catppuccin Surface
readonly COLOR_ASH_TEXT=$'\033[38;2;205;214;244m'        # #cdd6f4 Catppuccin Text

# Background colors
readonly BG_ASH_SURFACE=$'\033[48;2;30;30;46m'           # #1e1e2e Catppuccin Base
readonly BG_ASH_OVERLAY=$'\033[48;2;49;50;68m'           # #313244 Catppuccin Surface

# Mode-specific accent colors (truecolor)
declare -A MODE_ACCENT_COLORS=(
    [game]=$'\033[38;2;243;139;168m'       # Red    — aggressive/performance
    [work]=$'\033[38;2;137;180;250m'       # Blue   — calm/productive
    [focus]=$'\033[38;2;148;226;213m'      # Teal   — clarity/zen
    [cinema]=$'\033[38;2;203;166;247m'     # Purple — creative/immersive
    [present]=$'\033[38;2;249;226;175m'    # Yellow — attention/professional
    [battery]=$'\033[38;2;166;227;161m'    # Green  — eco/efficient
    [stream]=$'\033[38;2;250;179;135m'     # Peach  — warm/engaging
    [privacy]=$'\033[38;2;88;91;112m'      # Gray   — subtle/secure
    [accessibility]=$'\033[38;2;116;199;236m' # Sky — clear/accessible
    [default]=$'\033[38;2;205;214;244m'    # White  — neutral/balanced
)

# Mode icons (Nerd Font glyphs with Unicode fallbacks)
declare -A MODE_ICONS=(
    [game]='󰊴'        # nf-md-gamepad_variant
    [work]='󰃟'        # nf-md-briefcase
    [focus]='󰓾'       # nf-md-bullseye
    [cinema]='󰿎'      # nf-md-film
    [present]='󰐨'     # nf-md-presentation
    [battery]='󰂎'     # nf-md-battery_alert
    [stream]='󰕍'      # nf-md-broadcast
    [privacy]='󰗹'     # nf-md-incognito
    [accessibility]='󰩗' # nf-md-human
    [default]='󰍹'     # nf-md-desktop_classic
)

# Mode descriptors
declare -A MODE_DESCRIPTIONS=(
    [game]="Maximum GPU/CPU performance, all effects disabled for minimum latency"
    [work]="Balanced productivity setup with notifications and collaboration tools"
    [focus]="Distraction-free environment with DND, minimal UI, pomodoro integration"
    [cinema]="Media-optimized with night light off, max volume, fullscreen-ready"
    [present]="Clean, professional presentation with mirroring and auto-hide bars"
    [battery]="Aggressive power saving: dim screen, suspend intervals, reduced animations"
    [stream]="OBS-ready streaming setup with scene management and audio routing"
    [privacy]="VPN enforcement, camera/mic indicators, history paused, secure clipboard"
    [accessibility]="High contrast, large fonts, screen reader support, enhanced navigation"
    [default]="Balanced daily driver with all features enabled"
)

# Mode status emoji (terminal fallback)
declare -A MODE_STATUS_EMOJI=(
    [game]="🎮"
    [work]="💼"
    [focus]="🎯"
    [cinema]="🎬"
    [present]="📊"
    [battery]="🔋"
    [stream]="📡"
    [privacy]="🔒"
    [accessibility]="♿"
    [default]="🖥️"
)

# Valid mode names (used for validation)
readonly -a ASH_BUILTIN_MODES=(
    game work focus cinema present battery stream privacy accessibility default
)

# Global state variables
ASH_CURRENT_MODE=""
ASH_PREVIOUS_MODE=""
ASH_MODE_START_TIME=""
ASH_DRY_RUN=false
ASH_VERBOSE=false
ASH_QUIET=false
ASH_NO_ANIMATION=false
ASH_FORCE=false
ASH_JSON_OUTPUT=false

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 3 — ARGUMENT PARSING & VALIDATION
# ─────────────────────────────────────────────────────────────────────────────

# Display the main help screen with full UI
ash_mode_help() {
    local term_width
    term_width=$(tput cols 2>/dev/null || echo 80)
    local box_width=$(( term_width < 90 ? term_width - 4 : 86 ))

    # ── Banner ──────────────────────────────────────────────────────────────
    printf '\n'
    printf "${COLOR_ASH_PRIMARY}${MODE_COLOR_BOLD}"
    printf '%s\n' "$(ash_box_top "${box_width}")"
    printf '%s\n' "$(ash_box_row "${box_width}" \
        "  ${MODE_ICONS[game]}${MODE_ICONS[focus]}${MODE_ICONS[cinema]} ASH DOTFILES v5.0 OMEGA — MODE ENGINE")"
    printf '%s\n' "$(ash_box_row "${box_width}" \
        "  Desktop Environment Mode Switching System")"
    printf '%s\n' "$(ash_box_bottom "${box_width}")"
    printf "${MODE_COLOR_RESET}\n"

    # ── Usage ───────────────────────────────────────────────────────────────
    printf "${COLOR_ASH_SECONDARY}${MODE_COLOR_BOLD}USAGE${MODE_COLOR_RESET}\n"
    printf "  ${COLOR_ASH_TEXT}ash mode${MODE_COLOR_RESET} "
    printf "${COLOR_ASH_INFO}<subcommand>${MODE_COLOR_RESET} "
    printf "${COLOR_ASH_MUTED}[options]${MODE_COLOR_RESET}\n\n"

    # ── Mode Subcommands ────────────────────────────────────────────────────
    printf "${COLOR_ASH_SECONDARY}${MODE_COLOR_BOLD}MODES${MODE_COLOR_RESET}\n"

    local -a mode_rows=(
        "  $(printf '%-14s' "${MODE_ICONS[game]}game")"
        "  $(printf '%-14s' "${MODE_ICONS[work]}work")"
        "  $(printf '%-14s' "${MODE_ICONS[focus]}focus")"
        "  $(printf '%-14s' "${MODE_ICONS[cinema]}cinema")"
        "  $(printf '%-14s' "${MODE_ICONS[present]}present")"
        "  $(printf '%-14s' "${MODE_ICONS[battery]}battery")"
        "  $(printf '%-14s' "${MODE_ICONS[stream]}stream")"
        "  $(printf '%-14s' "${MODE_ICONS[privacy]}privacy")"
        "  $(printf '%-14s' "${MODE_ICONS[accessibility]}accessibility")"
        "  $(printf '%-14s' "${MODE_ICONS[default]}default")"
    )
    local -a mode_desc_rows=(
        "Maximum performance for gaming, minimum latency"
        "Productivity-focused with collaboration tools"
        "Distraction-free with DND and pomodoro timer"
        "Media-optimized for movies and content"
        "Clean professional presentation layout"
        "Aggressive power saving for mobile use"
        "OBS-ready with scene management"
        "Privacy-hardened with VPN enforcement"
        "Enhanced accessibility and high contrast"
        "Balanced daily driver (resets all modes)"
    )

    for i in "${!mode_rows[@]}"; do
        local mode_name="${ASH_BUILTIN_MODES[$i]}"
        local accent="${MODE_ACCENT_COLORS[$mode_name]}"
        printf "${accent}${MODE_COLOR_BOLD}%s${MODE_COLOR_RESET}" "${mode_rows[$i]}"
        printf "${COLOR_ASH_MUTED}  %s${MODE_COLOR_RESET}\n" "${mode_desc_rows[$i]}"
    done

    printf "\n"

    # ── Management Subcommands ──────────────────────────────────────────────
    printf "${COLOR_ASH_SECONDARY}${MODE_COLOR_BOLD}MANAGEMENT${MODE_COLOR_RESET}\n"

    local -a mgmt_cmds=(
        "  create"
        "  list"
        "  status"
    )
    local -a mgmt_desc=(
        "Create a new custom mode from template"
        "List all available modes (built-in + custom)"
        "Display current active mode and its settings"
    )

    for i in "${!mgmt_cmds[@]}"; do
        printf "${COLOR_ASH_PRIMARY}${MODE_COLOR_BOLD}%-20s${MODE_COLOR_RESET}" "${mgmt_cmds[$i]}"
        printf "${COLOR_ASH_MUTED}%s${MODE_COLOR_RESET}\n" "${mgmt_desc[$i]}"
    done

    printf "\n"

    # ── Global Options ──────────────────────────────────────────────────────
    printf "${COLOR_ASH_SECONDARY}${MODE_COLOR_BOLD}OPTIONS${MODE_COLOR_RESET}\n"

    local -a opts=(
        "  --duration <time>"
        "  --no-notify"
        "  --no-animation"
        "  --dry-run"
        "  --force"
        "  --quiet"
        "  --verbose"
        "  --json"
        "  --help"
        "  --version"
    )
    local -a opts_desc=(
        "Auto-revert after duration (e.g. 90m, 2h, 30s)"
        "Skip desktop notifications"
        "Skip transition animations"
        "Preview changes without applying"
        "Override active mode lock"
        "Suppress all output"
        "Show detailed operation logs"
        "Output results as JSON"
        "Show this help message"
        "Show version information"
    )

    for i in "${!opts[@]}"; do
        printf "${COLOR_ASH_INFO}%-26s${MODE_COLOR_RESET}" "${opts[$i]}"
        printf "${COLOR_ASH_MUTED}%s${MODE_COLOR_RESET}\n" "${opts_desc[$i]}"
    done

    printf "\n"

    # ── Examples ────────────────────────────────────────────────────────────
    printf "${COLOR_ASH_SECONDARY}${MODE_COLOR_BOLD}EXAMPLES${MODE_COLOR_RESET}\n"

    local -a examples=(
        "ash mode game"
        "ash mode focus --duration 90m"
        "ash mode cinema --no-notify"
        "ash mode battery --verbose"
        "ash mode list --json"
        "ash mode status"
        "ash mode create --name deep-work"
        "ash mode default"
    )
    local -a example_comments=(
        "# Activate gaming mode immediately"
        "# Focus mode, auto-reverts in 90 minutes"
        "# Cinema mode without notifications"
        "# Battery mode with verbose output"
        "# List modes as JSON"
        "# Show current mode and uptime"
        "# Create a new custom mode"
        "# Reset to default settings"
    )

    for i in "${!examples[@]}"; do
        printf "  ${COLOR_ASH_PRIMARY}%-42s${MODE_COLOR_RESET}" "${examples[$i]}"
        printf "${COLOR_ASH_MUTED}%s${MODE_COLOR_RESET}\n" "${example_comments[$i]}"
    done

    printf "\n"

    # ── Footer ──────────────────────────────────────────────────────────────
    printf "${COLOR_ASH_MUTED}  ASH Mode Engine v%s • " "${ASH_MODE_VERSION}"
    printf "Built %s • " "${ASH_MODE_BUILD_DATE}"
    printf "github.com/ash-dotfiles${MODE_COLOR_RESET}\n\n"
}

# Parse global flags that affect all subcommands
ash_mode_parse_global_flags() {
    # These flags are consumed before subcommand dispatch
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --dry-run)         ASH_DRY_RUN=true   ;;
            --verbose|-v)      ASH_VERBOSE=true    ;;
            --quiet|-q)        ASH_QUIET=true      ;;
            --no-animation)    ASH_NO_ANIMATION=true ;;
            --force|-f)        ASH_FORCE=true      ;;
            --json)            ASH_JSON_OUTPUT=true ;;
            --help|-h)
                ash_mode_help
                exit 0
                ;;
            --version|-V)
                ash_mode_version
                exit 0
                ;;
            *)
                # Not a global flag, leave for subcommand
                return 0
                ;;
        esac
        shift
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 4 — STATE MANAGEMENT
# ─────────────────────────────────────────────────────────────────────────────

# Initialize required directories and files
ash_mode_init_state() {
    mkdir -p "${ASH_STATE_DIR}" \
             "${ASH_RUNTIME_DIR}" \
             "${ASH_MODE_CUSTOM_DIR}" \
             "${ASH_DATA_HOME}/modes"

    # Create default state file if it doesn't exist
    if [[ ! -f "${ASH_MODE_STATE_FILE}" ]]; then
        cat > "${ASH_MODE_STATE_FILE}" <<-EOF
		{
		  "current_mode": "default",
		  "previous_mode": null,
		  "activated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
		  "duration": null,
		  "revert_at": null,
		  "plugins_active": [],
		  "overrides": {}
		}
		EOF
    fi

    # Create history file if missing
    [[ -f "${ASH_MODE_HISTORY_FILE}" ]] || touch "${ASH_MODE_HISTORY_FILE}"
}

# Read the current mode from persistent state
ash_mode_get_current() {
    if [[ -f "${ASH_MODE_STATE_FILE}" ]]; then
        ash_json_get "${ASH_MODE_STATE_FILE}" ".current_mode" 2>/dev/null \
            || echo "default"
    else
        echo "default"
    fi
}

# Write the new mode to persistent state
ash_mode_set_state() {
    local mode="${1}"
    local duration="${2:-null}"
    local revert_at="${3:-null}"

    ASH_PREVIOUS_MODE="$(ash_mode_get_current)"
    ASH_CURRENT_MODE="${mode}"
    ASH_MODE_START_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    # Atomic write using temporary file
    local tmp_file="${ASH_MODE_STATE_FILE}.tmp.$$"
    cat > "${tmp_file}" <<-EOF
	{
	  "current_mode": "${mode}",
	  "previous_mode": "${ASH_PREVIOUS_MODE}",
	  "activated_at": "${ASH_MODE_START_TIME}",
	  "duration": ${duration},
	  "revert_at": ${revert_at},
	  "hostname": "$(hostname -s)",
	  "user": "${USER}",
	  "plugins_active": [],
	  "overrides": {}
	}
	EOF
    mv -f "${tmp_file}" "${ASH_MODE_STATE_FILE}"

    # Append to history log (JSONL format)
    echo "{\"mode\":\"${mode}\",\"previous\":\"${ASH_PREVIOUS_MODE}\",\"at\":\"${ASH_MODE_START_TIME}\"}" \
        >> "${ASH_MODE_HISTORY_FILE}"
}

# Acquire an exclusive lock to prevent concurrent mode switching
ash_mode_acquire_lock() {
    local timeout="${1:-10}"
    local elapsed=0

    while [[ -f "${ASH_MODE_LOCK_FILE}" ]] && [[ "${elapsed}" -lt "${timeout}" ]]; do
        if [[ "${ASH_FORCE}" == "true" ]]; then
            ash_log_warn "Force flag set — overriding existing mode lock"
            break
        fi
        ash_log_debug "Waiting for mode lock (${elapsed}s/${timeout}s)..."
        sleep 1
        (( elapsed++ ))
    done

    if [[ -f "${ASH_MODE_LOCK_FILE}" ]] && [[ "${ASH_FORCE}" != "true" ]]; then
        local locked_by
        locked_by=$(cat "${ASH_MODE_LOCK_FILE}" 2>/dev/null || echo "unknown")
        ash_die "Mode switch already in progress (PID: ${locked_by}). Use --force to override."
    fi

    echo "$$" > "${ASH_MODE_LOCK_FILE}"

    # Automatically release lock on exit/signal
    trap 'ash_mode_release_lock' EXIT INT TERM HUP
}

# Release the exclusive lock
ash_mode_release_lock() {
    rm -f "${ASH_MODE_LOCK_FILE}"
    trap - EXIT INT TERM HUP
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 5 — CORE MODE ACTIVATION FRAMEWORK
# ─────────────────────────────────────────────────────────────────────────────

# The central mode activation function.
# All mode scripts (game.sh, work.sh, etc.) call this with their configuration.
#
# Arguments:
#   $1 - mode name
#   $2 - associative array name containing mode settings (nameref)
ash_mode_activate() {
    local mode="${1}"
    local -n _settings="${2}"   # nameref to associative array

    # ── Validation ──────────────────────────────────────────────────────────
    ash_mode_validate_name "${mode}"

    local current_mode
    current_mode="$(ash_mode_get_current)"

    if [[ "${current_mode}" == "${mode}" ]] && [[ "${ASH_FORCE}" != "true" ]]; then
        ash_print_info "Mode ${MODE_ICONS[$mode]:-} ${mode} is already active"
        ash_mode_status_brief
        return 0
    fi

    # ── Dry Run ─────────────────────────────────────────────────────────────
    if [[ "${ASH_DRY_RUN}" == "true" ]]; then
        ash_mode_dry_run_preview "${mode}"
        return 0
    fi

    # ── Acquire Lock ────────────────────────────────────────────────────────
    ash_mode_acquire_lock

    # ── Pre-activation Hooks ────────────────────────────────────────────────
    ash_log_debug "Running pre-mode-change hooks for: ${mode}"
    ash_hook_run "pre-mode-change" \
        "MODE_NAME=${mode}" \
        "PREVIOUS_MODE=${current_mode}"

    # ── Display Activation Header ───────────────────────────────────────────
    if [[ "${ASH_QUIET}" != "true" ]]; then
        ash_mode_print_activation_header "${mode}"
    fi

    # ── Apply Mode Steps ────────────────────────────────────────────────────
    local -i step=0
    local -i total_steps=${#_settings[@]}

    for action_key in "${!_settings[@]}"; do
        (( step++ ))
        local action_value="${_settings[$action_key]}"

        if [[ "${ASH_QUIET}" != "true" ]] && [[ "${ASH_NO_ANIMATION}" != "true" ]]; then
            ash_mode_print_step "${step}" "${total_steps}" "${action_key}" "${action_value}"
        fi

        ash_mode_execute_action "${action_key}" "${action_value}" "${mode}" || {
            ash_log_warn "Action '${action_key}' failed — continuing with remaining steps"
        }
    done

    # ── Persist State ───────────────────────────────────────────────────────
    ash_mode_set_state "${mode}" \
        "${_settings[duration]:-null}" \
        "${_settings[revert_at]:-null}"

    # ── Broadcast IPC Event ─────────────────────────────────────────────────
    ash_ipc_broadcast "mode_changed" \
        "{\"mode\":\"${mode}\",\"previous\":\"${current_mode}\"}" \
        || ash_log_debug "IPC broadcast failed (non-fatal)"

    # ── Reload Desktop Components ────────────────────────────────────────────
    ash_mode_reload_components "${mode}"

    # ── Send Desktop Notification ────────────────────────────────────────────
    if [[ "${_settings[no_notify]:-false}" != "true" ]] && \
       [[ "${ASH_QUIET}" != "true" ]]; then
        ash_mode_send_notification "${mode}"
    fi

    # ── Post-activation Hooks ────────────────────────────────────────────────
    ash_hook_run "post-mode-change" \
        "MODE_NAME=${mode}" \
        "PREVIOUS_MODE=${current_mode}"

    # ── Schedule Auto-revert ─────────────────────────────────────────────────
    if [[ -n "${_settings[duration]:-}" ]]; then
        ash_mode_schedule_revert "${mode}" "${_settings[duration]}"
    fi

    # ── Emit Telemetry ───────────────────────────────────────────────────────
    ash_telemetry_record "mode_change" \
        --data "{\"mode\":\"${mode}\",\"from\":\"${current_mode}\"}" \
        || true   # telemetry is never fatal

    # ── Success Output ────────────────────────────────────────────────────────
    if [[ "${ASH_QUIET}" != "true" ]]; then
        ash_mode_print_success "${mode}" "${current_mode}"
    fi

    if [[ "${ASH_JSON_OUTPUT}" == "true" ]]; then
        ash_mode_json_success "${mode}" "${current_mode}"
    fi

    # ── Release Lock ─────────────────────────────────────────────────────────
    ash_mode_release_lock
    return 0
}

# Execute a single mode action based on action key
ash_mode_execute_action() {
    local key="${1}"
    local value="${2}"
    local mode="${3}"

    case "${key}" in
        # ── Hyprland Settings ───────────────────────────────────────────────
        hypr_animations)
            ash_hyprctl_set "animations:enabled" "${value}"
            ;;
        hypr_blur)
            ash_hyprctl_set "decoration:blur:enabled" "${value}"
            ;;
        hypr_shadow)
            ash_hyprctl_set "decoration:shadow:enabled" "${value}"
            ;;
        hypr_rounding)
            ash_hyprctl_set "decoration:rounding" "${value}"
            ;;
        hypr_gaps_in)
            ash_hyprctl_set "general:gaps_in" "${value}"
            ;;
        hypr_gaps_out)
            ash_hyprctl_set "general:gaps_out" "${value}"
            ;;
        hypr_border_size)
            ash_hyprctl_set "general:border_size" "${value}"
            ;;
        hypr_opacity)
            ash_hyprctl_set "decoration:active_opacity" "${value}"
            ;;
        hypr_inactive_opacity)
            ash_hyprctl_set "decoration:inactive_opacity" "${value}"
            ;;
        hypr_vfr)
            ash_hyprctl_set "misc:vfr" "${value}"
            ;;
        hypr_vrr)
            ash_hyprctl_set "misc:vrr" "${value}"
            ;;
        hypr_max_fps)
            ash_hyprctl_set "misc:render_ahead_of_time" "${value}"
            ;;
        hypr_cursor_zoom)
            ash_hyprctl_set "cursor:zoom_factor" "${value}"
            ;;

        # ── Power Management ────────────────────────────────────────────────
        cpu_governor)
            ash_cpu_set_governor "${value}" || true
            ;;
        gpu_power_profile)
            ash_gpu_set_profile "${value}" || true
            ;;
        power_profile)
            ash_power_set_profile "${value}" || true
            ;;
        screen_brightness)
            ash_brightness_set "${value}" || true
            ;;
        dpms_timeout)
            ash_hyprctl_set "misc:dpms_timeout" "${value}"
            ;;

        # ── Audio ───────────────────────────────────────────────────────────
        audio_volume)
            ash_audio_set_volume "${value}" || true
            ;;
        audio_microphone)
            ash_audio_set_mic "${value}" || true
            ;;
        noise_cancel)
            ash_pipewire_noise_cancel "${value}" || true
            ;;

        # ── Notifications ───────────────────────────────────────────────────
        do_not_disturb)
            ash_dnd_set "${value}"
            ;;
        notification_timeout)
            ash_dunst_set_timeout "${value}" || true
            ;;

        # ── Display ─────────────────────────────────────────────────────────
        night_light)
            ash_night_light_set "${value}" || true
            ;;
        color_temperature)
            ash_hyprsunset_set "${value}" || true
            ;;
        gamma)
            ash_display_set_gamma "${value}" || true
            ;;

        # ── Bar/UI ──────────────────────────────────────────────────────────
        waybar_visible)
            if [[ "${value}" == "true" ]]; then
                ash_waybar_show
            else
                ash_waybar_hide
            fi
            ;;
        waybar_layout)
            ash_waybar_set_layout "${value}"
            ;;
        waybar_opacity)
            ash_waybar_set_opacity "${value}"
            ;;

        # ── Compositor Plugins ───────────────────────────────────────────────
        hypr_plugin_hyprspace)
            ash_hypr_plugin_toggle "hyprspace" "${value}"
            ;;

        # ── Shell Environment ───────────────────────────────────────────────
        fish_theme)
            ash_fish_set_theme "${value}" || true
            ;;

        # ── System Processes ─────────────────────────────────────────────────
        gamemode_daemon)
            if [[ "${value}" == "true" ]]; then
                systemctl --user start gamemoded.service 2>/dev/null || true
            else
                systemctl --user stop gamemoded.service 2>/dev/null || true
            fi
            ;;
        obs_studio)
            if [[ "${value}" == "true" ]]; then
                obs --startreplaybuffer &>/dev/null &
            fi
            ;;
        picom_compositor)
            if [[ "${value}" == "true" ]]; then
                picom --daemon 2>/dev/null || true
            else
                pkill picom 2>/dev/null || true
            fi
            ;;

        # ── Cursor ──────────────────────────────────────────────────────────
        cursor_size)
            ash_cursor_set_size "${value}" || true
            ;;
        cursor_theme)
            ash_cursor_set_theme "${value}" || true
            ;;

        # ── Font Scaling ─────────────────────────────────────────────────────
        font_scale)
            ash_font_set_scale "${value}" || true
            ;;

        # ── Keyboard ─────────────────────────────────────────────────────────
        keyboard_repeat_delay)
            ash_keyboard_set_repeat "${value}" "${_ASH_REPEAT_RATE:-25}" || true
            ;;
        keyboard_repeat_rate)
            _ASH_REPEAT_RATE="${value}"
            ;;

        # ── Network ──────────────────────────────────────────────────────────
        vpn)
            if [[ "${value}" == "true" ]]; then
                ash_vpn_connect || ash_log_warn "VPN connection failed"
            else
                ash_vpn_disconnect || true
            fi
            ;;
        firewall_level)
            ash_firewall_set "${value}" || true
            ;;

        # ── Clipboard ────────────────────────────────────────────────────────
        clipboard_history)
            ash_cliphist_set_enabled "${value}" || true
            ;;

        # ── Pomodoro ─────────────────────────────────────────────────────────
        pomodoro)
            if [[ "${value}" == "true" ]]; then
                systemctl --user start ash-pomodoro.service 2>/dev/null || true
            else
                systemctl --user stop ash-pomodoro.service 2>/dev/null || true
            fi
            ;;

        # ── Screen Recording ─────────────────────────────────────────────────
        screen_record_ready)
            if [[ "${value}" == "true" ]]; then
                ash_screenrecord_prepare || true
            fi
            ;;

        # ── Idle Behavior ────────────────────────────────────────────────────
        idle_timeout)
            ash_hypridle_set_timeout "${value}" || true
            ;;
        idle_lock_timeout)
            ash_hypridle_set_lock_timeout "${value}" || true
            ;;

        # ── Internal Control Keys (not executed as actions) ──────────────────
        duration|no_notify|revert_at|description|version)
            ash_log_debug "Skipping control key: ${key}"
            ;;

        # ── Custom Hooks ─────────────────────────────────────────────────────
        custom_*)
            ash_log_debug "Executing custom action: ${key}=${value}"
            eval "${value}" || ash_log_warn "Custom action failed: ${key}"
            ;;

        # ── Unknown ──────────────────────────────────────────────────────────
        *)
            ash_log_debug "Unknown action key '${key}' — skipping"
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 6 — COMPONENT RELOAD SYSTEM
# ─────────────────────────────────────────────────────────────────────────────

# Reload desktop components that respond to mode changes
ash_mode_reload_components() {
    local mode="${1}"

    ash_log_debug "Reloading desktop components for mode: ${mode}"

    # Reload Waybar configuration
    if pgrep -x waybar &>/dev/null; then
        ash_log_debug "  • Reloading Waybar"
        pkill -SIGUSR2 waybar 2>/dev/null || true
    fi

    # Send reload signal to AGS
    if pgrep -x ags &>/dev/null; then
        ash_log_debug "  • Reloading AGS widgets"
        ags -r "App.reload_css()" 2>/dev/null || true
        ags -r "Utils.exec('notify-send -h string:x-canonical-private-synchronous:mode ASH_MODE_CHANGED')" \
            2>/dev/null || true
    fi

    # Reload Dunst configuration
    if pgrep -x dunst &>/dev/null; then
        ash_log_debug "  • Reloading Dunst"
        pkill -SIGUSR1 dunst 2>/dev/null || true
    fi

    # Update GTK settings via gsettings
    ash_log_debug "  • Flushing GTK settings"
    gsettings set org.gnome.desktop.interface gtk-theme \
        "$(ash_config_get "gtk.theme" "Adwaita-dark")" 2>/dev/null || true

    # Signal Kitty terminals to reload config
    if pgrep -x kitty &>/dev/null; then
        ash_log_debug "  • Signaling Kitty terminals"
        kill -SIGUSR1 "$(pgrep -x kitty)" 2>/dev/null || true
    fi

    # Signal Neovim instances via RPC
    if command -v nvim &>/dev/null; then
        ash_log_debug "  • Signaling Neovim instances"
        for sock in /tmp/nvim.*.sock /run/user/"${UID}"/nvim.*.sock; do
            [[ -S "${sock}" ]] && \
                nvim --server "${sock}" --remote-send \
                    "<Cmd>lua require('ash').reload_theme()<CR>" \
                    2>/dev/null || true
        done
    fi

    # Write mode file for scripts to poll
    echo "${mode}" > "${ASH_RUNTIME_DIR}/current-mode"

    ash_log_debug "Component reload complete"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 7 — NOTIFICATION & DISPLAY
# ─────────────────────────────────────────────────────────────────────────────

# Send a rich desktop notification for mode change
ash_mode_send_notification() {
    local mode="${1}"
    local icon="${MODE_ICONS[$mode]:-🖥️}"
    local desc="${MODE_DESCRIPTIONS[$mode]:-}"
    local app_icon="${ASH_DATA_HOME}/icons/ash-system/${mode}-mode.svg"

    # Use system icon as fallback
    [[ -f "${app_icon}" ]] || app_icon="preferences-desktop"

    notify-send \
        --app-name="ASH Mode Engine" \
        --icon="${app_icon}" \
        --urgency=low \
        --expire-time=3000 \
        --hint="string:x-canonical-private-synchronous:ash-mode" \
        --hint="string:x-dunst-stack-tag:ash-mode" \
        "${icon} ${mode^} Mode Activated" \
        "${desc}" \
        2>/dev/null || true
}

# Print the animated activation header
ash_mode_print_activation_header() {
    local mode="${1}"
    local accent="${MODE_ACCENT_COLORS[$mode]:-${COLOR_ASH_PRIMARY}}"
    local icon="${MODE_ICONS[$mode]:-🖥️}"
    local emoji="${MODE_STATUS_EMOJI[$mode]:-🖥️}"

    printf '\n'

    if [[ "${ASH_NO_ANIMATION}" != "true" ]]; then
        # Animate the header entrance
        ash_animation_fade_in 3 0.05
    fi

    printf "${accent}${MODE_COLOR_BOLD}"
    printf '  ╭──────────────────────────────────────╮\n'
    printf '  │  %s %-36s│\n' \
        "${icon}" "Activating ${mode^^} MODE"
    printf '  │  %-38s│\n' \
        "$(printf '%.38s' "${MODE_DESCRIPTIONS[$mode]:-}")"
    printf '  ╰──────────────────────────────────────╯\n'
    printf "${MODE_COLOR_RESET}\n"
}

# Print a single progress step with alignment
ash_mode_print_step() {
    local step="${1}"
    local total="${2}"
    local key="${3}"
    local value="${4}"

    local percent=$(( step * 100 / total ))
    local bar_width=20
    local filled=$(( bar_width * step / total ))
    local empty=$(( bar_width - filled ))

    local bar=""
    local i
    for (( i=0; i<filled; i++ )); do bar+="█"; done
    for (( i=0; i<empty;  i++ )); do bar+="░"; done

    printf "  ${COLOR_ASH_MUTED}[%s]${MODE_COLOR_RESET} " "${bar}"
    printf "${COLOR_ASH_INFO}%3d%%${MODE_COLOR_RESET} " "${percent}"
    printf "${COLOR_ASH_TEXT}%-30s${MODE_COLOR_RESET}" "$(printf '%.30s' "${key}")"
    printf " ${COLOR_ASH_MUTED}→ ${MODE_COLOR_RESET}"
    printf "${COLOR_ASH_WARNING}%s${MODE_COLOR_RESET}\n" "$(printf '%.20s' "${value}")"
}

# Print success summary after mode activation
ash_mode_print_success() {
    local mode="${1}"
    local previous="${2}"
    local accent="${MODE_ACCENT_COLORS[$mode]:-${COLOR_ASH_PRIMARY}}"
    local icon="${MODE_ICONS[$mode]:-🖥️}"

    printf '\n'
    printf "  ${COLOR_ASH_SUCCESS}${MODE_COLOR_BOLD}✓${MODE_COLOR_RESET} "
    printf "${accent}${MODE_COLOR_BOLD}%s Mode${MODE_COLOR_RESET} " "${mode^}"
    printf "${COLOR_ASH_TEXT}activated successfully${MODE_COLOR_RESET}"

    if [[ -n "${previous}" ]] && [[ "${previous}" != "${mode}" ]]; then
        printf " ${COLOR_ASH_MUTED}(was: %s)${MODE_COLOR_RESET}" "${previous}"
    fi

    printf '\n'
    printf "  ${COLOR_ASH_MUTED}%s  Run 'ash mode status' for details${MODE_COLOR_RESET}\n\n" \
        "${icon}"
}

# Dry-run preview — show what would change without applying
ash_mode_dry_run_preview() {
    local mode="${1}"
    local accent="${MODE_ACCENT_COLORS[$mode]:-${COLOR_ASH_PRIMARY}}"

    printf '\n'
    printf "  ${COLOR_ASH_WARNING}${MODE_COLOR_BOLD}⚠ DRY RUN${MODE_COLOR_RESET} "
    printf "— No changes will be applied\n\n"

    printf "  ${accent}${MODE_COLOR_BOLD}%s Mode${MODE_COLOR_RESET} " "${mode^}"
    printf "${COLOR_ASH_TEXT}would apply the following:${MODE_COLOR_RESET}\n\n"

    # Source the mode file to show its settings
    local mode_file="${__ASH_MODE_DIR}/${mode}.sh"
    if [[ -f "${mode_file}" ]]; then
        # shellcheck source=/dev/null
        ASH_DRY_RUN_PREVIEW=true source "${mode_file}"
    fi

    printf "\n  ${COLOR_ASH_MUTED}Run without --dry-run to apply changes.${MODE_COLOR_RESET}\n\n"
}

# Emit JSON success response
ash_mode_json_success() {
    local mode="${1}"
    local previous="${2}"
    local ts
    ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    printf '{\n'
    printf '  "status": "success",\n'
    printf '  "mode": "%s",\n' "${mode}"
    printf '  "previous": "%s",\n' "${previous}"
    printf '  "icon": "%s",\n' "${MODE_ICONS[$mode]:-}"
    printf '  "description": "%s",\n' "${MODE_DESCRIPTIONS[$mode]:-}"
    printf '  "activated_at": "%s"\n' "${ts}"
    printf '}\n'
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 8 — AUTO-REVERT SCHEDULER
# ─────────────────────────────────────────────────────────────────────────────

# Schedule an automatic mode revert after a duration
ash_mode_schedule_revert() {
    local mode="${1}"
    local duration="${2}"

    # Parse duration: support 30s, 5m, 2h, 1d
    local seconds
    seconds="$(ash_parse_duration "${duration}")" || {
        ash_log_warn "Invalid duration format: ${duration}"
        return 1
    }

    ash_log_info "Scheduling auto-revert from '${mode}' after ${duration} (${seconds}s)"

    # Create a systemd transient timer for the revert
    if command -v systemd-run &>/dev/null; then
        systemd-run \
            --user \
            --on-active="${seconds}" \
            --unit="ash-mode-revert-$$.service" \
            --description="ASH Mode Auto-Revert: ${mode} → default" \
            -- \
            "${__ASH_CLI_DIR}/ash" mode default --quiet \
            2>/dev/null || {
            # Fallback: background sleep
            ash_mode_schedule_revert_fallback "${mode}" "${seconds}"
        }
    else
        ash_mode_schedule_revert_fallback "${mode}" "${seconds}"
    fi
}

# Fallback revert scheduler using background process
ash_mode_schedule_revert_fallback() {
    local mode="${1}"
    local seconds="${2}"

    local revert_pid_file="${ASH_RUNTIME_DIR}/mode-revert.pid"

    # Kill any existing revert timer
    if [[ -f "${revert_pid_file}" ]]; then
        local old_pid
        old_pid=$(cat "${revert_pid_file}")
        kill "${old_pid}" 2>/dev/null || true
    fi

    # Launch background revert process
    (
        sleep "${seconds}"
        "${__ASH_CLI_DIR}/ash" mode default --quiet
    ) &

    echo "$!" > "${revert_pid_file}"
    ash_log_debug "Revert scheduled (PID: $!) in ${seconds}s"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 9 — VALIDATION UTILITIES
# ─────────────────────────────────────────────────────────────────────────────

# Validate that a mode name is registered
ash_mode_validate_name() {
    local mode="${1}"

    # Check built-in modes
    local m
    for m in "${ASH_BUILTIN_MODES[@]}"; do
        [[ "${m}" == "${mode}" ]] && return 0
    done

    # Check custom modes
    if [[ -f "${ASH_MODE_CUSTOM_DIR}/${mode}/mode.conf" ]]; then
        return 0
    fi

    ash_die "Unknown mode: '${mode}'. Run 'ash mode list' to see available modes."
}

# Check if mode script exists and is executable
ash_mode_validate_script() {
    local mode="${1}"
    local script="${__ASH_MODE_DIR}/${mode}.sh"

    if [[ ! -f "${script}" ]]; then
        ash_die "Mode script not found: ${script}"
    fi

    if [[ ! -r "${script}" ]]; then
        ash_die "Mode script not readable: ${script}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 10 — HARDWARE DETECTION HELPERS
# ─────────────────────────────────────────────────────────────────────────────

# Detect primary GPU vendor
ash_mode_detect_gpu() {
    if lspci 2>/dev/null | grep -qi 'nvidia'; then
        echo "nvidia"
    elif lspci 2>/dev/null | grep -qi 'amd\|radeon'; then
        echo "amd"
    elif lspci 2>/dev/null | grep -qi 'intel'; then
        echo "intel"
    else
        echo "unknown"
    fi
}

# Detect if running on battery or AC power
ash_mode_detect_power_source() {
    local ac_path
    ac_path=$(find /sys/class/power_supply/ -name 'AC*' -o -name 'ADP*' \
        2>/dev/null | head -1)

    if [[ -n "${ac_path}" ]]; then
        local status
        status=$(cat "${ac_path}/online" 2>/dev/null || echo "1")
        [[ "${status}" == "1" ]] && echo "ac" || echo "battery"
    else
        echo "ac"  # Desktop systems assumed AC
    fi
}

# Detect if running in a VM
ash_mode_detect_virtualization() {
    if command -v systemd-detect-virt &>/dev/null; then
        systemd-detect-virt --quiet && echo "vm" || echo "bare-metal"
    else
        echo "unknown"
    fi
}

# Check if a display is connected at a specific output
ash_mode_get_monitor_count() {
    hyprctl monitors -j 2>/dev/null \
        | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" \
        2>/dev/null \
        || echo "1"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 11 — HYPRLAND IPC WRAPPERS
# ─────────────────────────────────────────────────────────────────────────────

# Set a Hyprland keyword value via hyprctl
ash_hyprctl_set() {
    local keyword="${1}"
    local value="${2}"

    if [[ "${ASH_DRY_RUN}" == "true" ]]; then
        ash_log_debug "  [DRY] hyprctl keyword ${keyword} ${value}"
        return 0
    fi

    if ! command -v hyprctl &>/dev/null; then
        ash_log_debug "hyprctl not available — skipping: ${keyword}"
        return 0
    fi

    hyprctl keyword "${keyword}" "${value}" 2>/dev/null || {
        ash_log_debug "hyprctl keyword failed: ${keyword} = ${value}"
        return 1
    }
}

# Dispatch a Hyprland dispatcher command
ash_hyprctl_dispatch() {
    local dispatcher="${1}"
    shift
    local args="$*"

    if [[ "${ASH_DRY_RUN}" == "true" ]]; then
        ash_log_debug "  [DRY] hyprctl dispatch ${dispatcher} ${args}"
        return 0
    fi

    hyprctl dispatch "${dispatcher}" "${args}" 2>/dev/null || {
        ash_log_debug "hyprctl dispatch failed: ${dispatcher} ${args}"
        return 1
    }
}

# Toggle a Hyprland plugin
ash_hypr_plugin_toggle() {
    local plugin="${1}"
    local state="${2}"   # true|false

    if [[ "${state}" == "true" ]]; then
        hyprctl plugin load "/usr/lib/hyprland/plugins/${plugin}.so" 2>/dev/null || true
    else
        hyprctl plugin unload "${plugin}" 2>/dev/null || true
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 12 — SYSTEM CONTROL HELPERS
# ─────────────────────────────────────────────────────────────────────────────

# Set CPU frequency governor
ash_cpu_set_governor() {
    local governor="${1}"

    [[ "${ASH_DRY_RUN}" == "true" ]] && {
        ash_log_debug "  [DRY] cpu governor → ${governor}"
        return 0
    }

    if command -v cpupower &>/dev/null; then
        cpupower frequency-set --governor "${governor}" 2>/dev/null || true
    elif [[ -d /sys/devices/system/cpu ]]; then
        local cpu
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            [[ -w "${cpu}" ]] && echo "${governor}" > "${cpu}" 2>/dev/null || true
        done
    fi
}

# Set GPU power profile
ash_gpu_set_profile() {
    local profile="${1}"
    local gpu_vendor
    gpu_vendor="$(ash_mode_detect_gpu)"

    [[ "${ASH_DRY_RUN}" == "true" ]] && {
        ash_log_debug "  [DRY] gpu (${gpu_vendor}) profile → ${profile}"
        return 0
    }

    case "${gpu_vendor}" in
        nvidia)
            if command -v nvidia-smi &>/dev/null; then
                case "${profile}" in
                    performance)
                        nvidia-smi --persistence-mode=1 2>/dev/null || true
                        nvidia-smi --power-limit=350 2>/dev/null || true
                        ;;
                    balanced|default)
                        nvidia-smi --persistence-mode=0 2>/dev/null || true
                        ;;
                    powersave)
                        nvidia-smi --persistence-mode=0 2>/dev/null || true
                        ;;
                esac
            fi
            ;;
        amd)
            local power_dpm_state
            case "${profile}" in
                performance) power_dpm_state="high"     ;;
                balanced)    power_dpm_state="balanced" ;;
                powersave)   power_dpm_state="low"      ;;
                *)           power_dpm_state="auto"     ;;
            esac
            local card
            for card in /sys/class/drm/card*/device/power_dpm_state; do
                [[ -w "${card}" ]] && \
                    echo "${power_dpm_state}" > "${card}" 2>/dev/null || true
            done
            ;;
    esac
}

# Set system power profile (power-profiles-daemon)
ash_power_set_profile() {
    local profile="${1}"

    [[ "${ASH_DRY_RUN}" == "true" ]] && {
        ash_log_debug "  [DRY] power profile → ${profile}"
        return 0
    }

    if command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl set "${profile}" 2>/dev/null || true
    elif command -v tuned-adm &>/dev/null; then
        case "${profile}" in
            performance)    tuned-adm profile throughput-performance 2>/dev/null || true ;;
            balanced)       tuned-adm profile balanced 2>/dev/null || true ;;
            power-saver)    tuned-adm profile powersave 2>/dev/null || true ;;
        esac
    fi
}

# Set screen brightness percentage
ash_brightness_set() {
    local value="${1}"   # 0–100 or absolute nits

    [[ "${ASH_DRY_RUN}" == "true" ]] && {
        ash_log_debug "  [DRY] brightness → ${value}"
        return 0
    }

    if command -v brightnessctl &>/dev/null; then
        brightnessctl set "${value}%" 2>/dev/null || true
    elif command -v light &>/dev/null; then
        light -S "${value}" 2>/dev/null || true
    fi
}

# Set DND state
ash_dnd_set() {
    local state="${1}"   # true|false

    [[ "${ASH_DRY_RUN}" == "true" ]] && {
        ash_log_debug "  [DRY] DND → ${state}"
        return 0
    }

    if command -v dunstctl &>/dev/null; then
        if [[ "${state}" == "true" ]]; then
            dunstctl set-paused true 2>/dev/null || true
        else
            dunstctl set-paused false 2>/dev/null || true
        fi
    fi

    # Also signal SwayNC if available
    if command -v swaync-client &>/dev/null; then
        if [[ "${state}" == "true" ]]; then
            swaync-client --dnd-on 2>/dev/null || true
        else
            swaync-client --dnd-off 2>/dev/null || true
        fi
    fi
}

# Set audio volume
ash_audio_set_volume() {
    local volume="${1}"

    [[ "${ASH_DRY_RUN}" == "true" ]] && {
        ash_log_debug "  [DRY] volume → ${volume}"
        return 0
    }

    if command -v pactl &>/dev/null; then
        pactl set-sink-volume @DEFAULT_SINK@ "${volume}%" 2>/dev/null || true
    elif command -v wpctl &>/dev/null; then
        # wpctl uses 0.0–1.0 scale
        local wpvol
        wpvol=$(awk "BEGIN {printf \"%.2f\", ${volume}/100}")
        wpctl set-volume @DEFAULT_AUDIO_SINK@ "${wpvol}" 2>/dev/null || true
    fi
}

# Control microphone state
ash_audio_set_mic() {
    local state="${1}"   # mute|unmute

    [[ "${ASH_DRY_RUN}" == "true" ]] && {
        ash_log_debug "  [DRY] mic → ${state}"
        return 0
    }

    if command -v pactl &>/dev/null; then
        if [[ "${state}" == "mute" ]]; then
            pactl set-source-mute @DEFAULT_SOURCE@ 1 2>/dev/null || true
        else
            pactl set-source-mute @DEFAULT_SOURCE@ 0 2>/dev/null || true
        fi
    fi
}

# Control night light / color temperature
ash_night_light_set() {
    local state="${1}"   # true|false

    [[ "${ASH_DRY_RUN}" == "true" ]] && {
        ash_log_debug "  [DRY] night light → ${state}"
        return 0
    }

    if [[ "${state}" == "false" ]]; then
        pkill hyprsunset 2>/dev/null || true
    else
        hyprsunset --temperature 4000 &>/dev/null &
    fi
}

# Set color temperature (Kelvin)
ash_hyprsunset_set() {
    local temp="${1}"

    [[ "${ASH_DRY_RUN}" == "true" ]] && {
        ash_log_debug "  [DRY] color temp → ${temp}K"
        return 0
    }

    pkill hyprsunset 2>/dev/null || true
    hyprsunset --temperature "${temp}" &>/dev/null &
}

# Set cursor size
ash_cursor_set_size() {
    local size="${1}"

    [[ "${ASH_DRY_RUN}" == "true" ]] && {
        ash_log_debug "  [DRY] cursor size → ${size}"
        return 0
    }

    ash_hyprctl_set "cursor:default_monitor" ""
    hyprctl setcursor "$(gsettings get org.gnome.desktop.interface cursor-theme \
        2>/dev/null | tr -d "'")" "${size}" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size "${size}" 2>/dev/null || true
}

# Set Waybar visibility
ash_waybar_show() {
    [[ "${ASH_DRY_RUN}" == "true" ]] && {
        ash_log_debug "  [DRY] waybar → show"
        return 0
    }
    pkill waybar 2>/dev/null || true
    sleep 0.1
    waybar &>/dev/null &
}

ash_waybar_hide() {
    [[ "${ASH_DRY_RUN}" == "true" ]] && {
        ash_log_debug "  [DRY] waybar → hide"
        return 0
    }
    pkill waybar 2>/dev/null || true
}

# Set Waybar opacity
ash_waybar_set_opacity() {
    local opacity="${1}"

    [[ "${ASH_DRY_RUN}" == "true" ]] && {
        ash_log_debug "  [DRY] waybar opacity → ${opacity}"
        return 0
    }
    # Send CSS override via SIGUSR2
    pkill -SIGUSR2 waybar 2>/dev/null || true
}

# Parse duration strings: 30s → 30, 5m → 300, 2h → 7200
ash_parse_duration() {
    local dur="${1}"
    local num="${dur%[smhd]}"
    local unit="${dur: -1}"

    # Validate numeric part
    [[ "${num}" =~ ^[0-9]+$ ]] || {
        ash_log_error "Invalid duration: ${dur}"
        return 1
    }

    case "${unit}" in
        s) echo "${num}" ;;
        m) echo $(( num * 60 )) ;;
        h) echo $(( num * 3600 )) ;;
        d) echo $(( num * 86400 )) ;;
        *) echo "${num}" ;;   # Treat raw number as seconds
    esac
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 13 — VERSION DISPLAY
# ─────────────────────────────────────────────────────────────────────────────

ash_mode_version() {
    if [[ "${ASH_JSON_OUTPUT}" == "true" ]]; then
        printf '{"component":"ash-mode","version":"%s","build_date":"%s"}\n' \
            "${ASH_MODE_VERSION}" "${ASH_MODE_BUILD_DATE}"
    else
        printf "${COLOR_ASH_PRIMARY}${MODE_COLOR_BOLD}ASH Mode Engine${MODE_COLOR_RESET} "
        printf "${COLOR_ASH_TEXT}v%s${MODE_COLOR_RESET}" "${ASH_MODE_VERSION}"
        printf " ${COLOR_ASH_MUTED}(built %s)${MODE_COLOR_RESET}\n" "${ASH_MODE_BUILD_DATE}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 14 — MAIN DISPATCHER
# ─────────────────────────────────────────────────────────────────────────────

# Usage block for a single built-in mode (used by `ash mode <mode> --help`).
ash_mode_print_subcommand_help() {
    local mode="${1:-}"
    local desc="${MODE_DESCRIPTIONS[$mode]:-Switch the desktop into the ${mode} profile}"

    printf '\n%s%sash mode %s%s\n' \
        "${MODE_COLOR_BOLD:-}" "${COLOR_ASH_PRIMARY:-}" "${mode}" "${MODE_COLOR_RESET:-}"
    printf '%s%s%s\n\n' "${MODE_COLOR_DIM:-}" "${desc}" "${MODE_COLOR_RESET:-}"
    printf '%sUSAGE%s\n' "${MODE_COLOR_BOLD:-}" "${MODE_COLOR_RESET:-}"
    printf '  ash mode %s [options]\n\n' "${mode}"
    printf '%sOPTIONS%s\n' "${MODE_COLOR_BOLD:-}" "${MODE_COLOR_RESET:-}"
    printf '  %-24s %s\n' '--dry-run'        'Preview the changes without applying them'
    printf '  %-24s %s\n' '--duration <time>' 'Auto-revert after e.g. 30m, 2h'
    printf '  %-24s %s\n' '--no-notify'      'Do not send a desktop notification'
    printf '  %-24s %s\n' '--no-animation'   'Skip the transition animation'
    printf '  %-24s %s\n' '--force, -f'      'Re-apply even if already active'
    printf '  %-24s %s\n' '--verbose, -v'    'Show detailed progress'
    printf '  %-24s %s\n' '--quiet, -q'      'Suppress non-error output'
    printf '  %-24s %s\n' '--json'           'Machine-readable result'
    printf '  %-24s %s\n' '--help, -h'       'Show this help'
    printf '\n%sGlobal: ash mode list | status | create | help%s\n\n' \
        "${MODE_COLOR_DIM:-}" "${MODE_COLOR_RESET:-}"
    return 0
}

ash_mode_main() {
    # Initialize state directories
    ash_mode_init_state

    # Load current mode into global
    ASH_CURRENT_MODE="$(ash_mode_get_current)"

    # Require at least one argument
    if [[ $# -eq 0 ]]; then
        ash_mode_help
        exit 0
    fi

    # Consume global flags that appear before the subcommand
    # Flags mixed with subcommands are handled per-subcommand
    local subcommand=""
    local -a subcommand_args=()

    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --dry-run)       ASH_DRY_RUN=true        ; shift ;;
            --verbose|-v)    ASH_VERBOSE=true         ; shift ;;
            --quiet|-q)      ASH_QUIET=true           ; shift ;;
            --no-animation)  ASH_NO_ANIMATION=true    ; shift ;;
            --force|-f)      ASH_FORCE=true           ; shift ;;
            --json)          ASH_JSON_OUTPUT=true     ; shift ;;
            --help|-h)       ash_mode_help; exit 0    ;;
            --version|-V)    ash_mode_version; exit 0 ;;
            --*)
                # Unknown global flag — pass to subcommand
                subcommand_args+=("${1}")
                shift
                ;;
            *)
                # First non-flag argument is the subcommand
                subcommand="${1}"
                shift
                subcommand_args+=("$@")
                break
                ;;
        esac
    done

    # Export globals so sourced mode scripts can read them
    export ASH_DRY_RUN ASH_VERBOSE ASH_QUIET ASH_NO_ANIMATION ASH_FORCE
    export ASH_JSON_OUTPUT ASH_CURRENT_MODE

    ash_log_debug "Dispatching mode subcommand: '${subcommand}' args: '${subcommand_args[*]:-}'"

    # ── Subcommand Dispatch ─────────────────────────────────────────────────
    case "${subcommand}" in
        # Built-in modes
        game | work | focus | cinema | present | \
        battery | stream | privacy | accessibility | default)
            local mode_script="${__ASH_MODE_DIR}/${subcommand}.sh"
            ash_mode_validate_script "${subcommand}"
            # `--help` must show usage, not apply the mode. The mode scripts run
            # their entry point as soon as they are sourced, so help is handled
            # here, before any file is loaded.
            local _arg
            for _arg in "${subcommand_args[@]:-}"; do
                case "${_arg}" in
                    --help|-h)
                        ash_mode_print_subcommand_help "${subcommand}"
                        return 0
                        ;;
                esac
            done
            # shellcheck source=/dev/null
            source "${mode_script}" "${subcommand_args[@]:-}"
            ;;

        # Help — must never fall through to activation
        help | -h | --help)
            ash_mode_help
            return 0
            ;;

        # Management commands
        create)
            source "${__ASH_MODE_DIR}/create.sh" "${subcommand_args[@]:-}"
            ;;
        list)
            source "${__ASH_MODE_DIR}/list.sh" "${subcommand_args[@]:-}"
            ;;
        status)
            source "${__ASH_MODE_DIR}/status.sh" "${subcommand_args[@]:-}"
            ;;

        # Custom mode detection: check custom dir
        *)
            if [[ -f "${ASH_MODE_CUSTOM_DIR}/${subcommand}/init.sh" ]]; then
                # shellcheck source=/dev/null
                source "${ASH_MODE_CUSTOM_DIR}/${subcommand}/init.sh" \
                    "${subcommand_args[@]:-}"
            else
                ash_print_error "Unknown subcommand: '${subcommand}'"
                printf "  Run ${COLOR_ASH_INFO}ash mode --help${MODE_COLOR_RESET} "
                printf "for available commands.\n\n"
                exit 1
            fi
            ;;
    esac
}

# Entry point — only execute if called directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ash_mode_main "$@"
fi

# ── Dispatcher entry point ────────────────────────────────────────────────────
# The ash dispatcher calls ash_cmd_<category> after sourcing. This file is
# already a well-behaved library — main is guarded, nothing runs on source — it
# simply never exposed the name the dispatcher looks for, so `ash mode` always
# ended in "Command function not found".
ash_cmd_mode() {
    ash_mode_main "$@"
}
