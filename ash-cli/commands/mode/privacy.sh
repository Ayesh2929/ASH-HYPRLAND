#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — PRIVACY MODE                                     ║
# ║  /ash-cli/commands/mode/privacy.sh                                           ║
# ║                                                                              ║
# ║  Privacy-hardened secure computing environment:                              ║
# ║  • Shell history paused (no commands logged)                                 ║
# ║  • Clipboard history cleared and paused                                      ║
# ║  • Camera and microphone indicators always visible                           ║
# ║  • VPN connection enforced                                                   ║
# ║  • Crash reporting and telemetry disabled                                    ║
# ║  • Screen lock on idle (30 seconds)                                          ║
# ║  • Private browsing window rules                                             ║
# ║  • Tor routing option                                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

__privacy_duration=""
__privacy_no_notify=false
__privacy_vpn=true
__privacy_tor=false
__privacy_clear_clipboard=true
__privacy_pause_history=true

__privacy_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --duration)
                __privacy_duration="${2:?}"
                shift 2
                ;;
            --no-vpn)           __privacy_vpn=false            ; shift ;;
            --tor)              __privacy_tor=true             ; shift ;;
            --no-clipboard)     __privacy_clear_clipboard=false ; shift ;;
            --no-history)       __privacy_pause_history=true   ; shift ;;
            --no-notify)        __privacy_no_notify=true       ; shift ;;
            --dry-run)          ASH_DRY_RUN=true               ; shift ;;
            --verbose)          ASH_VERBOSE=true               ; shift ;;
            *)                  shift ;;
        esac
    done
}

__privacy_build_settings() {
    declare -gA __PRIVACY_SETTINGS=(
        # ── Hyprland ────────────────────────────────────────────────────────
        [hypr_animations]="false"    # Minimal visual footprint
        [hypr_blur]="false"
        [hypr_shadow]="false"
        [hypr_rounding]="4"
        [hypr_gaps_in]="4"
        [hypr_gaps_out]="8"
        [hypr_vfr]="true"

        # ── Power ───────────────────────────────────────────────────────────
        [cpu_governor]="schedutil"
        [power_profile]="balanced"

        # ── Display ─────────────────────────────────────────────────────────
        [screen_brightness]="60"
        [idle_timeout]="30"          # Quick dim: 30 seconds
        [idle_lock_timeout]="60"     # Lock quickly: 1 minute

        # ── Notifications ───────────────────────────────────────────────────
        [do_not_disturb]="true"      # Don't reveal content

        # ── Audio ───────────────────────────────────────────────────────────
        [audio_microphone]="mute"   # Mic off by default
        [noise_cancel]="false"

        # ── Bar ─────────────────────────────────────────────────────────────
        [waybar_visible]="true"
        [waybar_layout]="minimal-bar"

        # ── Clipboard ────────────────────────────────────────────────────────
        [clipboard_history]="false"  # Don't record clipboard

        # ── Network ─────────────────────────────────────────────────────────
        [vpn]="${__privacy_vpn}"

        # ── Control Keys ────────────────────────────────────────────────────
        [no_notify]="${__privacy_no_notify}"
        [duration]="${__privacy_duration:-null}"
    )
}

__privacy_apply_extras() {
    # ── Clear Clipboard ───────────────────────────────────────────────────────
    if [[ "${__privacy_clear_clipboard}" == "true" ]]; then
        ash_log_info "  Clearing clipboard history"
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            # Clear cliphist
            if command -v cliphist &>/dev/null; then
                cliphist wipe 2>/dev/null || true
            fi
            # Clear wl-clipboard
            if command -v wl-copy &>/dev/null; then
                wl-copy --clear 2>/dev/null || true
            fi
        fi
    fi

    # ── Pause Shell History ───────────────────────────────────────────────────
    if [[ "${__privacy_pause_history}" == "true" ]]; then
        ash_log_info "  Pausing shell history"
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            # Signal Fish to pause history
            touch "${ASH_RUNTIME_DIR}/privacy-no-history.flag"
            # Atuin pause
            if command -v atuin &>/dev/null; then
                atuin disable 2>/dev/null || true
            fi
        fi
    fi

    # ── Tor Routing ───────────────────────────────────────────────────────────
    if [[ "${__privacy_tor}" == "true" ]]; then
        ash_log_info "  Enabling Tor routing"
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            if systemctl is-active tor &>/dev/null || \
               systemctl --user is-active tor &>/dev/null; then
                ash_log_debug "Tor already running"
            else
                sudo systemctl start tor 2>/dev/null || \
                    ash_log_warn "Failed to start Tor (install: paru -S tor)"
            fi
        fi
    fi

    # ── Disable Crash Reporting ───────────────────────────────────────────────
    ash_log_info "  Disabling crash reporting and telemetry"
    if [[ "${ASH_DRY_RUN}" != "true" ]]; then
        systemctl --user stop apport.service 2>/dev/null || true
        systemctl --user stop whoopsie.service 2>/dev/null || true
    fi

    # ── Camera Indicator ─────────────────────────────────────────────────────
    ash_log_info "  Enabling camera/mic usage indicators"
    if [[ "${ASH_DRY_RUN}" != "true" ]]; then
        # Signal Waybar to show privacy indicator module
        pkill -SIGUSR2 waybar 2>/dev/null || true
    fi
}

ash_privacy_mode_main() {
    __privacy_parse_args "$@"
    __privacy_build_settings
    ash_mode_activate "privacy" "__PRIVACY_SETTINGS"
    [[ "${ASH_DRY_RUN}" != "true" ]] && __privacy_apply_extras
}

ash_privacy_mode_main "$@"