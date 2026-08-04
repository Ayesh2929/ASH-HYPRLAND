#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  power reboot                                             ║
# ║  System restart with BIOS/UEFI entry selection, kernel chooser, and scheduling  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_POWER_REBOOT_LOADED:-}" == "1" ]] && return 0
readonly _ASH_POWER_REBOOT_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_reboot_to_firmware() {
    pwr_step "Rebooting into BIOS/UEFI firmware setup..."
    if command -v systemctl &>/dev/null; then
        sudo systemctl reboot --firmware-setup 2>/dev/null && return 0
    fi
    pwr_fail "Firmware reboot not supported on this system"
    return 1
}

_reboot_bootctl_entries() {
    # List systemd-boot entries for selection
    command -v bootctl &>/dev/null || return 1
    bootctl list 2>/dev/null | grep -E '^\s+title:' | \
        awk '{$1=""; print NR". "$0}' | sed 's/^ //'
}

_reboot_grub_entries() {
    local grub_cfg="/boot/grub/grub.cfg"
    [[ -f "$grub_cfg" ]] || grub_cfg="/boot/grub2/grub.cfg"
    [[ -f "$grub_cfg" ]] || return 1
    grep "^menuentry\|^submenu" "$grub_cfg" 2>/dev/null | \
        awk -F"'" 'NR<=10{print NR". "$2}'
}

_reboot_select_boot_entry() {
    local -a entries=()

    # Try bootctl entries first
    mapfile -t entries < <(_reboot_bootctl_entries 2>/dev/null || true)

    if [[ ${#entries[@]} -eq 0 ]]; then
        mapfile -t entries < <(_reboot_grub_entries 2>/dev/null || true)
    fi

    if [[ ${#entries[@]} -eq 0 ]]; then
        pwr_info "No boot entries found"
        return 1
    fi

    printf '\n  %sAvailable boot entries:%s\n' "$(_pwdim)" "$(_pwr)"
    for entry in "${entries[@]}"; do
        printf '    %s%s%s\n' "$(_pwsky)" "$entry" "$(_pwr)"
    done

    printf '\n  %sEnter entry number (or press Enter to skip): %s' \
        "$(_pwyellow)" "$(_pwr)"
    local choice
    read -r choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 )) && \
       (( choice <= ${#entries[@]} )); then
        local selected
        selected="$(printf '%s' "${entries[$((choice-1))]}" | \
                    sed 's/^[0-9]*\. //')"
        pwr_kv "Boot entry" "$selected"
        # Set next boot entry via bootctl
        if command -v bootctl &>/dev/null; then
            sudo bootctl set-oneshot "$selected" 2>/dev/null && \
                pwr_ok "Boot entry set: ${selected}"
        fi
    fi
}

ash_power_reboot() {
    local firmware=0
    local boot_entry=0

    for arg in "${@:-}"; do
        case "$arg" in
            --firmware|--bios|--uefi) firmware=1    ;;
            --boot-entry|-b)          boot_entry=1  ;;
        esac
    done

    if [[ $firmware -eq 1 ]]; then
        pwr_section "⚙️ " "Reboot to Firmware" "$(_pwpeach)"
        pwr_confirm "Reboot to BIOS/UEFI" "⚙️ " "$(_pwpeach)" || return 0
        _reboot_to_firmware
        return $?
    fi

    pwr_section "🔁" "System Reboot" "$(_pwyellow)"
    pwr_system_snapshot

    pwr_warn "All running processes will be restarted"
    pwr_check_unsaved || true

    # Boot entry selection
    [[ $boot_entry -eq 1 ]] && _reboot_select_boot_entry || true

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '\n  \033[1;38;2;249;226;175m'
        printf '  ╔══════════════════════════════════════╗\n'
        printf '  ║  🔁  SYSTEM WILL RESTART               ║\n'
        printf '  ╚══════════════════════════════════════╝\033[0m\n'
    fi

    pwr_confirm "REBOOT  (Restart)" "🔁" "$(_pwyellow)" || return 0

    pwr_run_hook "pre-reboot"
    pwr_notify "🔁 Rebooting" "System restarting in ${PWR_COUNTDOWN}s" "critical"
    pwr_log "reboot" "initiated"

    pwr_countdown "reboot" "$PWR_COUNTDOWN" "🔁" "$(_pwyellow)"

    pwr_step "Restarting system..."
    pwr_systemctl reboot || {
        pwr_fail "Reboot via systemctl failed — trying alternatives..."
        sudo reboot 2>/dev/null || \
            sudo shutdown -r now 2>/dev/null || {
            pwr_fail "All reboot methods failed"
            return 1
        }
    }

    pwr_log "reboot" "executing"
}
