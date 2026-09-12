#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — WORK MODE                                        ║
# ║  /ash-cli/commands/mode/work.sh                                              ║
# ║                                                                              ║
# ║  Productivity-focused work environment:                                      ║
# ║  • Balanced CPU governor for responsiveness + efficiency                     ║
# ║  • Full notification stack enabled                                           ║
# ║  • Calendar and task integrations visible                                    ║
# ║  • Communication app indicators active                                       ║
# ║  • Clean tiling layout with good gaps                                        ║
# ║  • Blue light filter for extended sessions                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE:
#   ash mode work [options]
#
# OPTIONS:
#   --duration <time>     Auto-revert after time
#   --no-notify           Skip notification
#   --focus-bar           Use focus-mode-style minimal bar
#   --pomodoro            Start Pomodoro timer on activation
#   --night-light         Force night light regardless of time

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# ARGUMENT PARSING
# ─────────────────────────────────────────────────────────────────────────────

__work_duration=""
__work_no_notify=false
__work_pomodoro=false
__work_night_light=false

__work_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --duration)
                __work_duration="${2:?--duration requires a value}"
                shift 2
                ;;
            --no-notify)    __work_no_notify=true  ; shift ;;
            --pomodoro)     __work_pomodoro=true   ; shift ;;
            --night-light)  __work_night_light=true ; shift ;;
            --dry-run)      ASH_DRY_RUN=true       ; shift ;;
            --verbose)      ASH_VERBOSE=true       ; shift ;;
            --help|-h)      ash_work_help; return 0 ;;
            *)              shift ;;
        esac
    done
}

ash_work_help() {
    printf '\n'
    printf "${MODE_ACCENT_COLORS[work]}${MODE_COLOR_BOLD}  %s WORK MODE${MODE_COLOR_RESET}\n\n" \
        "${MODE_ICONS[work]}"
    printf "  ${COLOR_ASH_MUTED}%s${MODE_COLOR_RESET}\n\n" \
        "${MODE_DESCRIPTIONS[work]}"
}

# ─────────────────────────────────────────────────────────────────────────────
# MODE CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────

__work_build_settings() {
    declare -gA __WORK_SETTINGS=(
        # ── Hyprland Compositor ─────────────────────────────────────────────
        [hypr_animations]="true"        # Keep animations for polished feel
        [hypr_blur]="true"             # Glassmorphism for aesthetic
        [hypr_shadow]="true"           # Window depth
        [hypr_rounding]="12"           # Rounded corners
        [hypr_gaps_in]="5"            # Comfortable gaps for multitasking
        [hypr_gaps_out]="10"          # Screen breathing room
        [hypr_border_size]="2"        # Visible borders
        [hypr_vfr]="true"             # Variable frame rate (power efficient)
        [hypr_vrr]="0"                # VRR off (not needed for office work)
        [hypr_opacity]="0.98"         # Slight transparency

        # ── Power ───────────────────────────────────────────────────────────
        [cpu_governor]="schedutil"    # Kernel-managed: responsive but efficient
        [power_profile]="balanced"    # power-profiles-daemon balanced
        [gpu_power_profile]="balanced"

        # ── Display ─────────────────────────────────────────────────────────
        [night_light]="${__work_night_light}"
        [color_temperature]="5500"    # Slightly warm for eye comfort
        [idle_timeout]="300"          # 5 min DPMS
        [screen_brightness]="70"      # Comfortable for office

        # ── Notifications ───────────────────────────────────────────────────
        [do_not_disturb]="false"      # Receive all notifications
        [notification_timeout]="5000" # 5 second timeout

        # ── Audio ───────────────────────────────────────────────────────────
        [audio_volume]="40"           # Modest volume, not distracting
        [noise_cancel]="true"         # NC for open offices

        # ── Bar ─────────────────────────────────────────────────────────────
        [waybar_visible]="true"
        [waybar_layout]="top-bar"    # Full-featured work bar

        # ── Productivity Tools ───────────────────────────────────────────────
        [pomodoro]="${__work_pomodoro}"

        # ── Control Keys ────────────────────────────────────────────────────
        [no_notify]="${__work_no_notify}"
        [duration]="${__work_duration:-null}"
    )
}

ash_work_mode_main() {
    __work_parse_args "$@"
    __work_build_settings
    ash_mode_activate "work" "__WORK_SETTINGS"
}

ash_work_mode_main "$@"