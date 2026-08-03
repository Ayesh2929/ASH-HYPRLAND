#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — WORK MODE                                        ║
# ║  /ash-cli/commands/mode/work.sh                                              ║
# ║                                                                              ║
# ║  Balanced productivity environment:                                          ║
# ║  • Balanced CPU/GPU profile (responsive, not wasteful)                        ║
# ║  • Notifications enabled (mail, calendar, chat alerts)                        ║
# ║  • Work-optimized Waybar layout                                               ║
# ║  • Comfortable compositor effects                                             ║
# ║  • Clipboard history kept for paste workflows                                 ║
# ║  • Noise cancellation for voice calls                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE:
#   ash mode work [options]
#
# OPTIONS:
#   --duration <time>     Auto-revert after time (e.g. 8h)
#   --no-notify           Skip desktop notification
#   --no-animation        Skip transition animation
#   --dry-run             Preview without applying
#   --verbose             Show detailed output
#
# EXAMPLES:
#   ash mode work
#   ash mode work --duration 8h

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 1 — ARGUMENT PARSING
# ─────────────────────────────────────────────────────────────────────────────

__work_duration=""
__work_no_notify=false

__work_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --duration)
                [[ -n "${2:-}" ]] || ash_die "--duration requires a value (e.g. 8h)"
                __work_duration="${2}"
                shift 2
                ;;
            --no-notify)        __work_no_notify=true   ; shift ;;
            --dry-run)          ASH_DRY_RUN=true        ; shift ;;
            --verbose)          ASH_VERBOSE=true        ; shift ;;
            --no-animation)     ASH_NO_ANIMATION=true   ; shift ;;
            --help|-h)
                printf '\n'
                printf "${MODE_ACCENT_COLORS[work]}${MODE_COLOR_BOLD}"
                printf "  %s WORK MODE — Balanced Productivity\n" "${MODE_ICONS[work]}"
                printf "${MODE_COLOR_RESET}\n"
                printf "  ${COLOR_ASH_TEXT}%s${MODE_COLOR_RESET}\n\n" \
                    "${MODE_DESCRIPTIONS[work]}"
                return 0
                ;;
            *)
                ash_log_warn "Unknown option for work mode: '${1}'"
                shift
                ;;
        esac
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 2 — MODE CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────

# Build the settings array for this mode.
# Keys map directly to ash_mode_execute_action() cases in mode.sh
__work_build_settings() {
    declare -gA __WORK_SETTINGS=(
        # ── Hyprland Compositor ─────────────────────────────────────────────
        [hypr_animations]="true"      # Smooth but not distracting
        [hypr_blur]="true"            # Subtle depth for UI
        [hypr_shadow]="true"
        [hypr_rounding]="12"          # Comfortable rounding
        [hypr_gaps_in]="5"
        [hypr_gaps_out]="10"
        [hypr_border_size]="2"
        [hypr_vfr]="true"
        [hypr_opacity]="1.0"

        # ── CPU & Power ─────────────────────────────────────────────────────
        [cpu_governor]="schedutil"
        [power_profile]="balanced"

        # ── Display ─────────────────────────────────────────────────────────
        [screen_brightness]="80"
        [night_light]="false"         # Accurate colors for documents
        [idle_timeout]="300"          # 5 minutes before dimming
        [idle_lock_timeout]="600"     # Lock after 10 minutes

        # ── Notifications ───────────────────────────────────────────────────
        [do_not_disturb]="false"      # Keep notifications on for work
        [notification_timeout]="6000" # Long enough to read alerts

        # ── Audio ───────────────────────────────────────────────────────────
        [audio_volume]="50"
        [noise_cancel]="true"         # Clean voice calls

        # ── Bar ─────────────────────────────────────────────────────────────
        [waybar_visible]="true"
        [waybar_layout]="work-bar"    # Work-specific layout

        # ── Productivity ─────────────────────────────────────────────────────
        [clipboard_history]="true"
        [pomodoro]="false"            # Available on demand via focus mode

        # ── Control Keys ────────────────────────────────────────────────────
        [no_notify]="${__work_no_notify}"
        [duration]="${__work_duration:-null}"
    )
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 3 — WORK-SPECIFIC EXTRAS
# ─────────────────────────────────────────────────────────────────────────────

__work_apply_extras() {
    # ── Work Session Notification ───────────────────────────────────────────
    if [[ "${__work_no_notify}" != "true" ]] && \
       [[ "${ASH_QUIET}" != "true" ]] && \
       [[ "${ASH_DRY_RUN}" != "true" ]]; then
        notify-send \
            --app-name="ASH Work Mode" \
            --urgency=low \
            --expire-time=3000 \
            "💼 Work Mode Active" \
            "Balanced profile • Notifications on • Collaboration ready" \
            2>/dev/null || true
    fi

    # ── Collaboration Services ──────────────────────────────────────────────
    # Ensure chat/collaboration daemons are running (discord, slack, etc.)
    if [[ "${ASH_DRY_RUN}" != "true" ]]; then
        for svc in ash-discord-rpc ash-slack-status; do
            systemctl --user is-active "${svc}.service" &>/dev/null || \
                systemctl --user start "${svc}.service" 2>/dev/null || true
        done
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 4 — ENTRY POINT
# ─────────────────────────────────────────────────────────────────────────────

ash_work_mode_main() {
    __work_parse_args "$@"
    __work_build_settings
    ash_mode_activate "work" "__WORK_SETTINGS"

    if [[ "${ASH_DRY_RUN}" != "true" ]]; then
        __work_apply_extras
    fi
}

ash_work_mode_main "$@"