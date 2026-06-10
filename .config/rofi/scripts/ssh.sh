#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — ROFI SSH LAUNCHER                            ║
# ║           SSH host picker from config + history with quick actions         ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly SSH_HISTORY="${CACHE_DIR}/ssh-history.txt"
readonly SSH_CONFIG="${HOME}/.ssh/config"
readonly LOG_FILE="${CACHE_DIR}/logs/rofi.log"
readonly MAX_HISTORY=30

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 HOST DISCOVERY
# ═══════════════════════════════════════════════════════════════════════════════

get_config_hosts() {
    if [[ ! -f "${SSH_CONFIG}" ]]; then
        return 0
    fi

    grep -i "^Host " "${SSH_CONFIG}" 2>/dev/null \
        | awk '{print $2}' \
        | grep -v "\*" \
        | grep -v "^#" \
        | sort -u
}

get_known_hosts() {
    local known_hosts="${HOME}/.ssh/known_hosts"
    if [[ ! -f "${known_hosts}" ]]; then
        return 0
    fi

    # Parse known_hosts (avoid hashed entries)
    awk '{print $1}' "${known_hosts}" 2>/dev/null \
        | grep -v "^\[" \
        | grep -v "^#" \
        | cut -d, -f1 \
        | sort -u \
        | head -20
}

get_history_hosts() {
    if [[ -f "${SSH_HISTORY}" ]]; then
        cat "${SSH_HISTORY}" 2>/dev/null
    fi
}

get_host_info() {
    local host="$1"
    if [[ -f "${SSH_CONFIG}" ]]; then
        local hostname user port
        hostname=$(awk "/^Host ${host}$/,/^Host /" "${SSH_CONFIG}" 2>/dev/null \
            | grep -i "Hostname" | head -1 | awk '{print $2}')
        user=$(awk "/^Host ${host}$/,/^Host /" "${SSH_CONFIG}" 2>/dev/null \
            | grep -i "^[[:space:]]*User " | head -1 | awk '{print $2}')
        port=$(awk "/^Host ${host}$/,/^Host /" "${SSH_CONFIG}" 2>/dev/null \
            | grep -i "^[[:space:]]*Port " | head -1 | awk '{print $2}')

        local info="${host}"
        [[ -n "${hostname}" ]] && info+=" → ${hostname}"
        [[ -n "${user}" ]]     && info+=" (${user})"
        [[ -n "${port}" ]] && [[ "${port}" != "22" ]] && info+=" :${port}"
        echo "${info}"
    else
        echo "${host}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 ROFI PICKER
# ═══════════════════════════════════════════════════════════════════════════════

build_menu() {
    local entries=""

    # History (most recent first, with star)
    if [[ -f "${SSH_HISTORY}" ]]; then
        while IFS= read -r host; do
            [[ -z "${host}" ]] && continue
            local info
            info=$(get_host_info "${host}")
            entries+="⭐ ${info}\0info\x1frecent\n"
        done < <(tac "${SSH_HISTORY}" | awk '!seen[$0]++' | head -10)
    fi

    # Config hosts
    local config_hosts
    config_hosts=$(get_config_hosts)
    if [[ -n "${config_hosts}" ]]; then
        while IFS= read -r host; do
            [[ -z "${host}" ]] && continue
            local info
            info=$(get_host_info "${host}")
            # Skip if already in history
            grep -q "^${host}$" "${SSH_HISTORY}" 2>/dev/null && continue
            entries+="🔑 ${info}\0info\x1fconfig\n"
        done <<< "${config_hosts}"
    fi

    # Known hosts
    local known_hosts
    known_hosts=$(get_known_hosts)
    if [[ -n "${known_hosts}" ]]; then
        while IFS= read -r host; do
            [[ -z "${host}" ]] && continue
            grep -q "^${host}$" "${SSH_HISTORY}" 2>/dev/null && continue
            entries+="🌐 ${host}\0info\x1fknown\n"
        done <<< "${known_hosts}"
    fi

    # Manual entry option
    entries+="✏️  Enter host manually...\0info\x1fmanual\n"

    echo -e "${entries}"
}

save_history() {
    local host="$1"
    mkdir -p "${CACHE_DIR}"

    # Remove existing entry
    if [[ -f "${SSH_HISTORY}" ]]; then
        grep -v "^${host}$" "${SSH_HISTORY}" > "${SSH_HISTORY}.tmp" 2>/dev/null || true
        mv "${SSH_HISTORY}.tmp" "${SSH_HISTORY}" 2>/dev/null || true
    fi

    # Add to top
    echo "${host}" | cat - "${SSH_HISTORY}" 2>/dev/null > "${SSH_HISTORY}.tmp" || echo "${host}" > "${SSH_HISTORY}.tmp"
    mv "${SSH_HISTORY}.tmp" "${SSH_HISTORY}"

    # Keep limited history
    if [[ -f "${SSH_HISTORY}" ]]; then
        head -"${MAX_HISTORY}" "${SSH_HISTORY}" > "${SSH_HISTORY}.tmp"
        mv "${SSH_HISTORY}.tmp" "${SSH_HISTORY}"
    fi
}

connect_ssh() {
    local host="$1"
    log "INFO" "SSH connecting: ${host}"
    save_history "${host}"

    # Try kitty SSH kitten first, then regular SSH
    if command -v kitty &>/dev/null && [[ "${TERM}" == "xterm-kitty" ]]; then
        kitty +kitten ssh "${host}"
    else
        kitty --title "SSH: ${host}" -e ssh "${host}" 2>/dev/null \
            || alacritty --title "SSH: ${host}" -e ssh "${host}" 2>/dev/null \
            || xterm -title "SSH: ${host}" -e ssh "${host}" 2>/dev/null
    fi
}

main() {
    mkdir -p "${CACHE_DIR}/logs"

    local selected
    selected=$(build_menu | rofi \
        -dmenu \
        -i \
        -p "  SSH Connect" \
        -theme-str '
            window { width: 620px; }
            listview { columns: 1; lines: 14; }
            element { padding: 8px 12px; }
        ' \
        -format "s" \
        2>/dev/null) || {
        log "INFO" "SSH picker cancelled"
        exit 0
    }

    # Parse selection
    local host=""
    case "${selected}" in
        "✏️  Enter host manually...")
            host=$(rofi \
                -dmenu \
                -p "  SSH Host" \
                -theme-str 'window { width: 400px; }' \
                < /dev/null 2>/dev/null) || exit 0
            ;;
        "⭐ "* | "🔑 "* | "🌐 "*)
            # Extract hostname (first word after emoji and space)
            host=$(echo "${selected}" | sed 's/^[⭐🔑🌐] //' | awk '{print $1}')
            ;;
        *)
            host="${selected}"
            ;;
    esac

    if [[ -n "${host}" ]]; then
        connect_ssh "${host}"
    fi
}

main "$@"