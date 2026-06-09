#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WAYBAR UPDATES MODULE                        ║
# ║           Official + AUR package updates with caching                      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly UPDATES_CACHE="${CACHE_DIR}/updates-cache.json"
readonly LOG_FILE="${CACHE_DIR}/logs/updates.log"
readonly CACHE_TTL=3600  # 1 hour

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 📦 UPDATE CHECKING
# ═══════════════════════════════════════════════════════════════════════════════

is_cache_valid() {
    [[ -f "${UPDATES_CACHE}" ]] || return 1
    local age=$(( $(date +%s) - $(stat -c %Y "${UPDATES_CACHE}" 2>/dev/null || echo 0) ))
    (( age < CACHE_TTL ))
}

check_official_updates() {
    # Check official repo updates
    local count=0

    if command -v checkupdates &>/dev/null; then
        count=$(checkupdates 2>/dev/null | wc -l || echo 0)
    elif command -v pacman &>/dev/null; then
        # Sync db first (read-only)
        count=$(pacman -Qu 2>/dev/null | wc -l || echo 0)
    fi

    echo "${count}"
}

check_aur_updates() {
    local count=0

    if command -v paru &>/dev/null; then
        count=$(paru -Qua 2>/dev/null | wc -l || echo 0)
    elif command -v yay &>/dev/null; then
        count=$(yay -Qua 2>/dev/null | wc -l || echo 0)
    fi

    echo "${count}"
}

get_update_list() {
    local updates=""

    if command -v checkupdates &>/dev/null; then
        updates=$(checkupdates 2>/dev/null || echo "")
    fi

    if command -v paru &>/dev/null; then
        local aur_updates
        aur_updates=$(paru -Qua 2>/dev/null || echo "")
        [[ -n "${aur_updates}" ]] && updates+=$'\n'"${aur_updates}"
    fi

    echo "${updates}"
}

fetch_updates() {
    local official aur total
    official=$(check_official_updates)
    aur=$(check_aur_updates)
    total=$(( official + aur ))

    # Get package list (first 10)
    local pkg_list
    pkg_list=$(get_update_list | head -10 | awk '{print $1}' | tr '\n' ',' | sed 's/,$//')

    local data
    data=$(jq -n \
        --argjson official "${official}" \
        --argjson aur "${aur}" \
        --argjson total "${total}" \
        --arg packages "${pkg_list}" \
        --arg timestamp "$(date -Iseconds)" \
        '{
            official: $official,
            aur: $aur,
            total: $total,
            packages: $packages,
            timestamp: $timestamp
        }')

    echo "${data}" > "${UPDATES_CACHE}"
    echo "${data}"
    log "INFO" "Updates: official=${official} aur=${aur} total=${total}"
}

get_updates_data() {
    if is_cache_valid; then
        cat "${UPDATES_CACHE}"
    else
        fetch_updates
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 FORMAT OUTPUT
# ═══════════════════════════════════════════════════════════════════════════════

format_output() {
    local data="$1"

    local total official aur packages timestamp
    total=$(echo "${data}"     | jq -r '.total // 0')
    official=$(echo "${data}"  | jq -r '.official // 0')
    aur=$(echo "${data}"       | jq -r '.aur // 0')
    packages=$(echo "${data}"  | jq -r '.packages // ""')
    timestamp=$(echo "${data}" | jq -r '.timestamp // ""' | cut -dT -f1)

    # Build tooltip
    local tooltip
    tooltip="📦 Package Updates\n"
    tooltip+="────────────────────\n"
    tooltip+="Official: ${official}\n"
    tooltip+="AUR:      ${aur}\n"
    tooltip+="Total:    ${total}\n"

    if [[ -n "${packages}" ]]; then
        tooltip+="────────────────────\n"
        tooltip+="Packages:\n"
        IFS=',' read -ra pkg_arr <<< "${packages}"
        for pkg in "${pkg_arr[@]}"; do
            tooltip+="  • ${pkg}\n"
        done
    fi

    tooltip+="────────────────────\n"
    tooltip+="Last checked: ${timestamp}\n"
    tooltip+="Click to update"

    # Determine icon and class
    local icon class text
    if (( total == 0 )); then
        icon="󰇯"
        class="up-to-date"
        text="${icon}"
    elif (( total < 10 )); then
        icon="󰇰"
        class="has-updates"
        text="${icon} ${total}"
    elif (( total < 50 )); then
        icon="󰇱"
        class="has-updates"
        text="${icon} ${total}"
    else
        icon="󰇲"
        class="many-updates"
        text="${icon} ${total}!"
    fi

    printf '{"text": "%s", "tooltip": "%s", "class": "%s", "percentage": %s}\n' \
        "${text}" "${tooltip}" "${class}" "${total}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        refresh)
            rm -f "${UPDATES_CACHE}"
            fetch_updates > /dev/null
            echo "Updates refreshed"
            ;;
        count)
            local data
            data=$(get_updates_data)
            echo "${data}" | jq -r '.total'
            ;;
        "")
            local data
            data=$(get_updates_data 2>/dev/null) || {
                printf '{"text": "󰇯", "class": "up-to-date", "tooltip": "Cannot check updates"}\n'
                exit 0
            }
            format_output "${data}"
            ;;
        *)
            echo "Usage: updates.sh [refresh|count]"
            exit 1
            ;;
    esac
}

main "$@"