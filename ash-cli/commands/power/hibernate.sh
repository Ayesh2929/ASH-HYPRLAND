#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  power hibernate                                          ║
# ║  Hibernate to disk with swap validation, state save, and hook execution         ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_POWER_HIBERNATE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_POWER_HIBERNATE_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_hibernate_check_swap() {
    # Check if swap is available and large enough for RAM
    local swap_total ram_total
    swap_total="$(awk '/^SwapTotal:/{print $2}' /proc/meminfo 2>/dev/null || echo 0)"
    ram_total="$( awk '/^MemTotal:/{print $2}'  /proc/meminfo 2>/dev/null || echo 1)"

    if (( swap_total == 0 )); then
        pwr_fail "No swap space configured — hibernate not possible"
        pwr_info "Create swap: sudo mkswap /swapfile && sudo swapon /swapfile"
        return 1
    fi

    local swap_gb=$(( swap_total / 1048576 ))
    local ram_gb=$(( ram_total / 1048576 ))

    if (( swap_total < ram_total )); then
        pwr_warn "Swap (${swap_gb}GB) < RAM (${ram_gb}GB) — hibernate may fail"
        pwr_info "Recommended: swap ≥ RAM size"
    else
        pwr_ok "Swap: ${swap_gb}GB  •  RAM: ${ram_gb}GB  ✓"
    fi

    return 0
}

_hibernate_check_image() {
    # Check hibernation image support
    local resume_file="/sys/power/resume"
    if [[ -r "$resume_file" ]]; then
        local resume_dev
        resume_dev="$(cat "$resume_file")"
        if [[ "$resume_dev" == "0:0" ]]; then
            pwr_warn "No hibernate resume device configured"
            pwr_info "Set in /etc/default/grub: GRUB_CMDLINE_LINUX_DEFAULT=\"resume=UUID=...\""
        else
            pwr_ok "Resume device: ${resume_dev}"
        fi
    fi
}

ash_power_hibernate() {
    local skip_checks=0

    for arg in "${@:-}"; do
        case "$arg" in
            --skip-checks) skip_checks=1 ;;
        esac
    done

    pwr_section "❄️ " "Hibernate to Disk" "$(_pwsapph)"

    if ! pwr_can_action hibernate; then
        pwr_fail "System cannot hibernate  (systemd CanHibernate=no)"
        pwr_info "Ensure swap is configured and kernel resume= parameter is set"
        return 1
    fi

    if [[ $skip_checks -eq 0 ]]; then
        _hibernate_check_swap || {
            [[ "${ASH_PWR_FORCE:-0}" -ne 1 ]] && return 1
        }
        _hibernate_check_image
    fi

    pwr_system_snapshot
    pwr_warn "All unsaved work will be saved to disk — safe to power off after"
    pwr_check_unsaved || true

    pwr_confirm "Hibernate to disk" "❄️ " "$(_pwsapph)" || return 0

    pwr_run_hook "on-suspend"

    pwr_notify "❄️  Hibernating" "Writing system state to disk..." "critical"
    pwr_log "hibernate" "initiated"

    pwr_countdown "hibernate" "$PWR_COUNTDOWN" "❄️ " "$(_pwsapph)"

    pwr_step "Hibernating system..."
    pwr_systemctl hibernate || {
        pwr_fail "Hibernate failed"
        pwr_log "hibernate" "failed"
        return 1
    }

    pwr_log "hibernate" "resumed"
    pwr_run_hook "on-resume"

    printf '\n'
}
