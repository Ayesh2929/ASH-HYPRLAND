#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — PACMAN UPDATES HOOK                          ║
# ║           Track package updates via pacman hooks                           ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly UPDATE_COUNT_FILE="${CACHE_DIR}/pacman-update-count"
readonly LOG_FILE="${CACHE_DIR}/logs/updates.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 📦 PACMAN HOOK SETUP
# ═══════════════════════════════════════════════════════════════════════════════

setup_pacman_hook() {
    local hook_dir="/etc/pacman.d/hooks"
    local hook_file="${hook_dir}/ash-update-count.hook"

    if [[ -d "${hook_dir}" ]]; then
        sudo tee "${hook_file}" > /dev/null << 'EOF'
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = ASH: Updating package count cache
When = PostTransaction
Exec = /bin/bash -c "pacman -Q | wc -l > /home/$SUDO_USER/.cache/ash-dots/pacman-update-count 2>/dev/null || true"
EOF
        echo "Hook installed: ${hook_file}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 UPDATE CHECK
# ═══════════════════════════════════════════════════════════════════════════════

check_updates() {
    local official=0 aur=0

    # Check official updates (non-blocking)
    if command -v checkupdates &>/dev/null; then
        official=$(checkupdates 2>/dev/null | wc -l || echo 0)
    elif command -v pacman &>/dev/null; then
        official=$(pacman -Qu 2>/dev/null | wc -l || echo 0)
    fi

    # Check AUR updates
    local aur_helper=""
    command -v paru &>/dev/null && aur_helper="paru"
    command -v yay  &>/dev/null && aur_helper="${aur_helper:-yay}"

    if [[ -n "${aur_helper}" ]]; then
        aur=$(${aur_helper} -Qua 2>/dev/null | wc -l || echo 0)
    fi

    local total=$(( official + aur ))
    log "INFO" "Updates: official=${official} aur=${aur} total=${total}"
    echo "${total}"
}

main() {
    local action="${1:-check}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        check | "")
            local count
            count=$(check_updates)
            echo "${count}"
            ;;
        setup-hook)
            setup_pacman_hook
            ;;
        json)
            # Delegate to updates.sh for full JSON output
            exec "${HOME}/.config/waybar/scripts/system/updates.sh" status
            ;;
        *)
            echo "Usage: pacman-updates.sh [check|setup-hook|json]"
            exit 1
            ;;
    esac
}

main "$@"