#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  power shutdown                                           ║
# ║  System poweroff with scheduled shutdown, cancellation, and broadcast           ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_POWER_SHUTDOWN_LOADED:-}" == "1" ]] && return 0
readonly _ASH_POWER_SHUTDOWN_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_shutdown_broadcast() {
    local countdown="$1"
    # Broadcast to all logged-in users
    if command -v wall &>/dev/null && (( countdown > 60 )); then
        wall "System shutdown in ${countdown} seconds" 2>/dev/null || true
    fi
}

_shutdown_cancel() {
    pwr_step "Cancelling scheduled shutdown..."
    if command -v systemctl &>/dev/null; then
        sudo systemctl cancel 2>/dev/null && \
            pwr_ok "Shutdown cancelled" || \
            pwr_fail "No scheduled shutdown to cancel"
    else
        sudo shutdown -c 2>/dev/null && \
            pwr_ok "Shutdown cancelled" || \
            pwr_fail "Cannot cancel shutdown"
    fi
}

_shutdown_scheduled() {
    local schedule="$1"   # e.g. "+30" (30 minutes) or "22:00"
    pwr_step "Scheduling shutdown at: ${schedule}..."
    sudo shutdown "$schedule" 2>/dev/null && \
        pwr_ok "Shutdown scheduled: ${schedule}"
}

ash_power_shutdown() {
    local schedule=""
    local cancel=0

    for arg in "${@:-}"; do
        case "$arg" in
            --cancel|-c)      cancel=1          ;;
            --schedule=*|+*)  schedule="${arg#*=}"; [[ "$arg" == +* ]] && schedule="$arg" ;;
        esac
    done

    if [[ $cancel -eq 1 ]]; then
        _shutdown_cancel
        printf '\n'; return 0
    fi

    if [[ -n "$schedule" ]]; then
        _shutdown_scheduled "$schedule"
        printf '\n'; return 0
    fi

    pwr_section "🔴" "System Shutdown" "$(_pwred)"
    pwr_system_snapshot

    pwr_warn "ALL running processes will be terminated"
    pwr_warn "Unsaved work will be LOST"

    # Critical warning with red banner
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '\n  \033[1;38;2;243;139;168m'
        printf '  ╔══════════════════════════════════════╗\n'
        printf '  ║  ⚠️   THIS WILL POWER OFF THE SYSTEM   ║\n'
        printf '  ╚══════════════════════════════════════╝\033[0m\n'
    fi

    pwr_check_unsaved || true
    pwr_confirm "SHUTDOWN  (Power Off)" "🔴" "$(_pwred)" || return 0

    _shutdown_broadcast "$PWR_COUNTDOWN"
    pwr_run_hook "pre-shutdown"

    pwr_notify "🔴 Shutting Down" "System powering off in ${PWR_COUNTDOWN}s" "critical"
    pwr_log "shutdown" "initiated"

    pwr_countdown "shutdown" "$PWR_COUNTDOWN" "🔴" "$(_pwred)"

    pwr_step "Powering off system..."
    pwr_systemctl poweroff || {
        pwr_fail "Shutdown failed — trying alternative methods..."
        if ! sudo shutdown -h now 2>/dev/null; then
            sudo halt -p 2>/dev/null || \
                sudo systemctl poweroff --force 2>/dev/null || {
                pwr_fail "All shutdown methods failed"
                return 1
            }
        fi
    }

    pwr_log "shutdown" "executing"
}
