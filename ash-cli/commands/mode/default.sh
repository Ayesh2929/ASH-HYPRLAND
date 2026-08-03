#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — DEFAULT MODE                                     ║
# ║  /ash-cli/commands/mode/default.sh                                           ║
# ║                                                                              ║
# ║  Resets all settings to balanced daily-driver defaults:                      ║
# ║  • Restores compositor effects                                               ║
# ║  • Resumes notifications                                                     ║
# ║  • Balanced power settings                                                   ║
# ║  • Cleans up mode-specific state files                                       ║
# ║  • Cancels auto-revert timers                                                ║
# ║  • Runs post-mode cleanup hooks                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

__default_no_notify=false

__default_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --no-notify)    __default_no_notify=true   ; shift ;;
            --dry-run)      ASH_DRY_RUN=true           ; shift ;;
            --verbose)      ASH_VERBOSE=true           ; shift ;;
            --quiet)        ASH_QUIET=true             ; shift ;;
            *)              shift ;;
        esac
    done
}

__default_build_settings() {
    declare -gA __DEFAULT_SETTINGS=(
        # ── Hyprland ────────────────────────────────────────────────────────
        [hypr_animations]="true"
        [hypr_blur]="true"
        [hypr_shadow]="true"
        [hypr_rounding]="12"
        [hypr_gaps_in]="5"
        [hypr_gaps_out]="10"
        [hypr_border_size]="2"
        [hypr_vfr]="true"
        [hypr_vrr]="0"
        [hypr_opacity]="1.0"

        # ── CPU & Power ─────────────────────────────────────────────────────
        [cpu_governor]="schedutil"
        [power_profile]="balanced"
        [gpu_power_profile]="balanced"

        # ── Display ─────────────────────────────────────────────────────────
        [screen_brightness]="80"
        [idle_timeout]="300"
        [idle_lock_timeout]="600"

        # ── Notifications ───────────────────────────────────────────────────
        [do_not_disturb]="false"
        [notification_timeout]="6000"

        # ── Audio ───────────────────────────────────────────────────────────
        [audio_volume]="50"
        [audio_microphone]="unmute"
        [noise_cancel]="false"

        # ── Bar ─────────────────────────────────────────────────────────────
        [waybar_visible]="true"
        [waybar_layout]="top-bar"

        # ── Cursor & Font ────────────────────────────────────────────────────
        [cursor_size]="24"
        [font_scale]="1.0"

        # ── Keyboard ─────────────────────────────────────────────────────────
        [keyboard_repeat_delay]="300"
        [keyboard_repeat_rate]="25"

        # ── Clipboard ────────────────────────────────────────────────────────
        [clipboard_history]="true"

        # ── System Processes ─────────────────────────────────────────────────
        [gamemode_daemon]="false"

        # ── Control Keys ────────────────────────────────────────────────────
        [no_notify]="${__default_no_notify}"
        [duration]="null"
    )
}

__default_apply_cleanup() {
    ash_log_info "  Cleaning up previous mode state"

    # ── Cancel Auto-Revert Timers ────────────────────────────────────────────
    if [[ "${ASH_DRY_RUN}" != "true" ]]; then
        local revert_pid_file="${ASH_RUNTIME_DIR}/mode-revert.pid"
        if [[ -f "${revert_pid_file}" ]]; then
            local pid
            pid=$(cat "${revert_pid_file}")
            kill "${pid}" 2>/dev/null || true
            rm -f "${revert_pid_file}"
            ash_log_debug "  Cancelled auto-revert timer (PID: ${pid})"
        fi

        # Cancel systemd revert timers
        systemctl --user list-timers --no-legend 2>/dev/null \
            | awk '/ash-mode-revert/{print $NF}' \
            | while read -r unit; do
                systemctl --user stop "${unit}" 2>/dev/null || true
            done
    fi

    # ── Run Previous Mode Cleanup ────────────────────────────────────────────
    local cleanup_script="${ASH_RUNTIME_DIR}/focus-cleanup.sh"
    if [[ -f "${cleanup_script}" ]] && [[ "${ASH_DRY_RUN}" != "true" ]]; then
        ash_log_debug "  Running focus mode cleanup"
        bash "${cleanup_script}" 2>/dev/null || true
        rm -f "${cleanup_script}"
    fi

    # ── Restore Bluetooth ─────────────────────────────────────────────────────
    if [[ -f "${ASH_RUNTIME_DIR}/battery-bt.state" ]]; then
        ash_log_info "  Restoring Bluetooth"
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            rfkill unblock bluetooth 2>/dev/null || \
                bluetoothctl power on 2>/dev/null || true
            rm -f "${ASH_RUNTIME_DIR}/battery-bt.state"
        fi
    fi

    # ── Stop Cinema Caffeinate ────────────────────────────────────────────────
    if [[ -f "${ASH_RUNTIME_DIR}/cinema-caffeinate.pid" ]]; then
        ash_log_info "  Stopping caffeinate"
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            kill "$(cat "${ASH_RUNTIME_DIR}/cinema-caffeinate.pid")" \
                2>/dev/null || true
            rm -f "${ASH_RUNTIME_DIR}/cinema-caffeinate.pid"
        fi
    fi

    # ── Restore Shell History ─────────────────────────────────────────────────
    if [[ -f "${ASH_RUNTIME_DIR}/privacy-no-history.flag" ]]; then
        ash_log_info "  Restoring shell history"
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            rm -f "${ASH_RUNTIME_DIR}/privacy-no-history.flag"
            command -v atuin &>/dev/null && atuin enable 2>/dev/null || true
        fi
    fi

    # ── Restore GTK Accessibility Settings ──────────────────────────────────
    if [[ "${ASH_DRY_RUN}" != "true" ]]; then
        gsettings set org.gnome.desktop.interface \
            text-scaling-factor 1.0 2>/dev/null || true
        gsettings set org.gnome.desktop.a11y.keyboard \
            stickykeys-enable false 2>/dev/null || true
    fi

    # ── Disable Screen Shaders ───────────────────────────────────────────────
    if [[ "${ASH_DRY_RUN}" != "true" ]]; then
        ash_hyprctl_set "decoration:screen_shader" "" 2>/dev/null || true
    fi
}

ash_default_mode_main() {
    __default_parse_args "$@"
    __default_build_settings
    ash_mode_activate "default" "__DEFAULT_SETTINGS"
    [[ "${ASH_DRY_RUN}" != "true" ]] && __default_apply_cleanup
}

ash_default_mode_main "$@"