#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  power suspend                                            ║
# ║  Suspend to RAM with pre-suspend lock, brightness save, hook execution          ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_POWER_SUSPEND_LOADED:-}" == "1" ]] && return 0
readonly _ASH_POWER_SUSPEND_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_suspend_save_state() {
    # Save brightness for restore on resume
    local brightness_file="${_PWR_STATE_DIR}/pre-suspend-brightness"
    for bl_dev in /sys/class/backlight/*/brightness; do
        [[ -r "$bl_dev" ]] && cat "$bl_dev" > "$brightness_file" 2>/dev/null || true
        break
    done

    # Save audio volume
    local vol_file="${_PWR_STATE_DIR}/pre-suspend-volume"
    if command -v wpctl &>/dev/null; then
        wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | \
            grep -oP '[\d.]+' > "$vol_file" 2>/dev/null || true
    fi
}

ash_power_suspend() {
    local lock_before=1  # Lock screen before suspend by default

    for arg in "${@:-}"; do
        case "$arg" in
            --no-lock) lock_before=0 ;;
        esac
    done

    pwr_section "💤" "Suspend to RAM" "$(_pwblue)"

    if ! pwr_can_action suspend; then
        pwr_fail "System cannot suspend  (systemd CanSuspend=no)"
        pwr_info "Check: systemctl suspend"
        return 1
    fi

    pwr_system_snapshot

    pwr_warn "All unsaved work should be saved before suspending"
    pwr_check_unsaved || true

    pwr_confirm "Suspend to RAM" "💤" "$(_pwblue)" || return 0

    pwr_run_hook "on-suspend"
    _suspend_save_state

    # Lock screen before suspend if configured
    if [[ $lock_before -eq 1 ]] && ! [[ "${ASH_PWR_NO_LOCK:-0}" -eq 1 ]]; then
        pwr_step "Locking screen before suspend..."
        _pwr_load_sub lock &>/dev/null || true
        ash_power_lock --now &>/dev/null &
        sleep 0.5
    fi

    pwr_notify "💤 Suspending" "System suspending to RAM..." "critical"
    pwr_log "suspend" "initiated"

    pwr_countdown "suspend" "$PWR_COUNTDOWN" "💤" "$(_pwblue)"

    pwr_step "Suspending system..."
    pwr_systemctl suspend || {
        pwr_fail "Suspend failed"
        pwr_log "suspend" "failed"
        return 1
    }

    pwr_log "suspend" "resumed"
    pwr_run_hook "on-resume"

    printf '\n'
}
