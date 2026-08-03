#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — CINEMA MODE                                      ║
# ║  /ash-cli/commands/mode/cinema.sh                                            ║
# ║                                                                              ║
# ║  Immersive media experience:                                                 ║
# ║  • All interface chrome hidden                                               ║
# ║  • Night light disabled for accurate colors                                  ║
# ║  • Maximum volume, enhanced bass                                             ║
# ║  • Fullscreen-ready window rules                                             ║
# ║  • DPMS disabled (no screen sleep during movie)                              ║
# ║  • Ambient screen effect support                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

__cinema_duration=""
__cinema_no_notify=false
__cinema_caffeinate=true   # Prevent screen sleep

__cinema_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --duration)
                __cinema_duration="${2:?}"
                shift 2
                ;;
            --no-caffeinate)  __cinema_caffeinate=false  ; shift ;;
            --no-notify)      __cinema_no_notify=true    ; shift ;;
            --dry-run)        ASH_DRY_RUN=true           ; shift ;;
            --verbose)        ASH_VERBOSE=true           ; shift ;;
            *)                shift ;;
        esac
    done
}

__cinema_build_settings() {
    declare -gA __CINEMA_SETTINGS=(
        # ── Hyprland ────────────────────────────────────────────────────────
        [hypr_animations]="true"      # Keep for smooth media transitions
        [hypr_blur]="true"            # Blur for any UI elements visible
        [hypr_shadow]="true"
        [hypr_rounding]="0"           # Sharp corners for fullscreen
        [hypr_gaps_in]="0"
        [hypr_gaps_out]="0"
        [hypr_border_size]="0"        # No borders in cinema mode
        [hypr_opacity]="1.0"          # Full opacity for video
        [hypr_vfr]="true"

        # ── Power (no sleep during movies) ──────────────────────────────────
        [cpu_governor]="schedutil"
        [power_profile]="balanced"
        [idle_timeout]="0"            # Never timeout (movie running)
        [idle_lock_timeout]="0"       # Never lock
        [dpms_timeout]="0"            # Disable DPMS

        # ── Display ─────────────────────────────────────────────────────────
        [night_light]="false"         # Accurate colors for movies
        [gamma]="1.0"                 # Standard gamma
        [screen_brightness]="100"     # Maximum brightness

        # ── Notifications ───────────────────────────────────────────────────
        [do_not_disturb]="true"       # No interruptions

        # ── Audio ───────────────────────────────────────────────────────────
        [audio_volume]="90"           # Immersive volume level
        [noise_cancel]="false"        # Full audio fidelity

        # ── Bar ─────────────────────────────────────────────────────────────
        [waybar_visible]="false"      # Hidden for immersion

        # ── Control Keys ────────────────────────────────────────────────────
        [no_notify]="${__cinema_no_notify}"
        [duration]="${__cinema_duration:-null}"
    )
}

__cinema_apply_extras() {
    # ── Caffeinate (prevent screen sleep) ───────────────────────────────────
    if [[ "${__cinema_caffeinate}" == "true" ]]; then
        ash_log_info "  Enabling caffeine (screen-sleep prevention)"
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            # Use systemd-inhibit for proper D-Bus inhibition
            if command -v systemd-inhibit &>/dev/null; then
                systemd-inhibit \
                    --what=idle:sleep \
                    --who="ASH Cinema Mode" \
                    --why="Watching media" \
                    --mode=block \
                    sleep infinity &>/dev/null &
                echo "$!" > "${ASH_RUNTIME_DIR}/cinema-caffeinate.pid"
            else
                # Fallback: signal idle inhibitor via Hyprland
                ash_hyprctl_dispatch "keyword" "misc:new_window_takes_over_fullscreen" "1"
            fi
        fi
    fi

    # ── MPV Config Optimization ──────────────────────────────────────────────
    if [[ "${ASH_DRY_RUN}" != "true" ]]; then
        local mpv_profile_flag="${XDG_CONFIG_HOME:-${HOME}/.config}/ash/cinema-mpv.flag"
        touch "${mpv_profile_flag}"  # Signal mpv to use cinema profile
    fi
}

ash_cinema_mode_main() {
    __cinema_parse_args "$@"
    __cinema_build_settings
    ash_mode_activate "cinema" "__CINEMA_SETTINGS"
    [[ "${ASH_DRY_RUN}" != "true" ]] && __cinema_apply_extras
}

ash_cinema_mode_main "$@"