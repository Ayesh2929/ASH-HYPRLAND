#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — SESSION SAVE/RESTORE                         ║
# ║           Save and restore window layouts and workspaces                    ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE: session-restore.sh [ACTION] [SESSION_NAME]
#
# ACTIONS:
#   save    [name]   — Save current session
#   restore [name]   — Restore named session
#   list             — List saved sessions
#   delete  [name]   — Delete session
#   auto-save        — Save every 5 minutes (daemon mode)
#   status           — Show session info

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly STATE_DIR="${HOME}/.local/state/ash-dots/sessions"
readonly LOG_FILE="${CACHE_DIR}/logs/session.log"
readonly AUTO_SAVE_INTERVAL=300  # 5 minutes

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; }
err()  { echo -e "  \033[91m✗\033[0m $*" >&2; }

# ═══════════════════════════════════════════════════════════════════════════════
# 💾 SAVE SESSION
# ═══════════════════════════════════════════════════════════════════════════════

save_session() {
    local name="${1:-auto-$(date '+%Y%m%d_%H%M%S')}"
    local session_file="${STATE_DIR}/${name}.json"

    mkdir -p "${STATE_DIR}"
    info "Saving session: ${name}"

    # Get all clients from Hyprland
    local clients
    clients=$(hyprctl clients -j 2>/dev/null) || {
        err "Failed to get Hyprland clients"
        return 1
    }

    # Get workspace info
    local workspaces
    workspaces=$(hyprctl workspaces -j 2>/dev/null) || workspaces="[]"

    # Get active workspace
    local active_ws
    active_ws=$(hyprctl activewindow -j 2>/dev/null | jq '.workspace.id' 2>/dev/null) || active_ws="1"

    # Build session data
    local session_data
    session_data=$(jq -n \
        --argjson clients "${clients}" \
        --argjson workspaces "${workspaces}" \
        --argjson active_ws "${active_ws}" \
        --arg name "${name}" \
        --arg timestamp "$(date -Iseconds)" \
        --arg hyprland_ver "$(hyprctl version -j 2>/dev/null | jq -r '.tag // "unknown"')" \
        '{
            meta: {
                name: $name,
                timestamp: $timestamp,
                hyprland_version: $hyprland_ver,
                active_workspace: $active_ws
            },
            workspaces: $workspaces,
            clients: [
                $clients[] | {
                    class: .class,
                    title: .title,
                    workspace: .workspace.id,
                    at: .at,
                    size: .size,
                    floating: .floating,
                    fullscreen: .fullscreen,
                    pinned: .pinned,
                    initialClass: .initialClass,
                    initialTitle: .initialTitle
                }
            ]
        }' 2>/dev/null)

    echo "${session_data}" > "${session_file}"
    ok "Session saved: ${session_file}"
    log "INFO" "Session saved: ${name} ($(echo "${clients}" | jq length) windows)"

    # Clean old auto-saves (keep last 10)
    local auto_saves
    auto_saves=$(find "${STATE_DIR}" -name "auto-*.json" | sort -r)
    local count=0
    while IFS= read -r old_save; do
        ((count++)) || true
        if (( count > 10 )); then
            rm -f "${old_save}"
            log "INFO" "Removed old auto-save: $(basename "${old_save}")"
        fi
    done <<< "${auto_saves}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔄 RESTORE SESSION
# ═══════════════════════════════════════════════════════════════════════════════

restore_session() {
    local name="${1:-}"

    # If no name given, show picker
    if [[ -z "${name}" ]]; then
        name=$(list_sessions_rofi) || return 0
    fi

    local session_file="${STATE_DIR}/${name}.json"

    if [[ ! -f "${session_file}" ]]; then
        # Try with .json extension
        session_file="${STATE_DIR}/${name}"
        if [[ ! -f "${session_file}" ]]; then
            err "Session not found: ${name}"
            return 1
        fi
    fi

    info "Restoring session: ${name}"
    log "INFO" "Restoring session: ${name}"

    local clients
    clients=$(jq '.clients' "${session_file}" 2>/dev/null)

    # Count clients
    local count
    count=$(echo "${clients}" | jq 'length')
    info "Restoring ${count} windows..."

    # Restore each client
    local restored=0
    while IFS= read -r client; do
        local class workspace floating
        class=$(echo "${client}"   | jq -r '.class // ""')
        workspace=$(echo "${client}" | jq -r '.workspace // 1')
        floating=$(echo "${client}"  | jq -r '.floating // false')

        if [[ -z "${class}" ]]; then
            continue
        fi

        # Build launch command
        local cmd=""
        case "${class}" in
            kitty)        cmd="kitty" ;;
            alacritty)    cmd="alacritty" ;;
            firefox)      cmd="firefox" ;;
            chromium)     cmd="chromium" ;;
            code-oss)     cmd="code" ;;
            nemo)         cmd="nemo" ;;
            thunar)       cmd="thunar" ;;
            discord)      cmd="discord" ;;
            spotify)      cmd="spotify" ;;
            steam)        cmd="steam" ;;
            *)            cmd="${class}" ;;
        esac

        # Launch in the correct workspace
        local rule=""
        if [[ "${floating}" == "true" ]]; then
            rule="[workspace ${workspace} float]"
        else
            rule="[workspace ${workspace} silent]"
        fi

        # Try to launch
        if command -v "${cmd}" &>/dev/null; then
            hyprctl dispatch exec "${rule} ${cmd}" 2>/dev/null || true
            ((restored++)) || true
            sleep 0.1  # Small delay between launches
        else
            warn "Cannot restore ${class}: command '${cmd}' not found"
        fi
    done < <(echo "${clients}" | jq -c '.[]')

    ok "Restored ${restored}/${count} windows"

    # Restore active workspace
    local active_ws
    active_ws=$(jq -r '.meta.active_workspace // 1' "${session_file}")
    hyprctl dispatch workspace "${active_ws}" 2>/dev/null || true

    notify-send "🔄 Session Restored" \
        "${restored}/${count} windows from '${name}'" \
        --app-name="ASH Session" \
        --expire-time=4000 \
        2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📋 LIST SESSIONS
# ═══════════════════════════════════════════════════════════════════════════════

list_sessions() {
    local sessions=()

    if [[ ! -d "${STATE_DIR}" ]]; then
        echo "No sessions saved yet"
        return 0
    fi

    while IFS= read -r file; do
        sessions+=("$(basename "${file}" .json)")
    done < <(find "${STATE_DIR}" -name "*.json" | sort -r)

    if (( ${#sessions[@]} == 0 )); then
        echo "No sessions found"
        return 0
    fi

    echo ""
    echo -e "  \033[1m📋 Saved Sessions:\033[0m"
    echo ""

    for session in "${sessions[@]}"; do
        local file="${STATE_DIR}/${session}.json"
        local timestamp count
        timestamp=$(jq -r '.meta.timestamp // "unknown"' "${file}" 2>/dev/null || echo "unknown")
        count=$(jq '.clients | length' "${file}" 2>/dev/null || echo "?")

        printf "  \033[96m%-30s\033[0m  %s windows  %s\n" \
            "${session}" "${count}" "${timestamp}"
    done
    echo ""
}

list_sessions_rofi() {
    if [[ ! -d "${STATE_DIR}" ]]; then
        echo ""
        return 1
    fi

    local sessions=()
    while IFS= read -r file; do
        local name count timestamp
        name=$(basename "${file}" .json)
        count=$(jq '.clients | length' "${file}" 2>/dev/null || echo "?")
        timestamp=$(jq -r '.meta.timestamp // ""' "${file}" 2>/dev/null \
            | cut -dT -f1 || echo "")
        sessions+=("${name}   (${count} windows, ${timestamp})")
    done < <(find "${STATE_DIR}" -name "*.json" | sort -r)

    if (( ${#sessions[@]} == 0 )); then
        notify-send "Session Restore" "No sessions found" \
            --app-name="ASH Session" 2>/dev/null || true
        return 1
    fi

    local selected
    selected=$(printf '%s\n' "${sessions[@]}" | rofi \
        -dmenu \
        -i \
        -p "🔄 Restore Session" \
        -theme-str 'window { width: 600px; }' \
        2>/dev/null) || return 1

    echo "${selected}" | awk '{print $1}'
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🗑️ DELETE SESSION
# ═══════════════════════════════════════════════════════════════════════════════

delete_session() {
    local name="${1:-}"

    if [[ -z "${name}" ]]; then
        err "Session name required"
        return 1
    fi

    local file="${STATE_DIR}/${name}.json"

    if [[ -f "${file}" ]]; then
        rm -f "${file}"
        ok "Session deleted: ${name}"
        log "INFO" "Deleted session: ${name}"
    else
        err "Session not found: ${name}"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🤖 AUTO-SAVE DAEMON
# ═══════════════════════════════════════════════════════════════════════════════

auto_save_daemon() {
    info "Auto-save daemon starting (interval: ${AUTO_SAVE_INTERVAL}s)"
    log "INFO" "Auto-save daemon started"

    while true; do
        save_session "auto-$(date '+%Y%m%d_%H%M%S')" 2>/dev/null || true
        sleep "${AUTO_SAVE_INTERVAL}"
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 STATUS
# ═══════════════════════════════════════════════════════════════════════════════

session_status() {
    local session_count=0
    [[ -d "${STATE_DIR}" ]] && \
        session_count=$(find "${STATE_DIR}" -name "*.json" | wc -l)

    local client_count
    client_count=$(hyprctl clients -j 2>/dev/null | jq 'length' || echo "0")

    local workspace
    workspace=$(hyprctl activewindow -j 2>/dev/null \
        | jq -r '.workspace.name // "1"' || echo "1")

    printf '{"text": "💾 %s", "tooltip": "Sessions: %s\nWindows: %s\nWorkspace: %s", "class": "session"}\n' \
        "${session_count}" "${session_count}" "${client_count}" "${workspace}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-list}"
    shift || true

    mkdir -p "${STATE_DIR}" "${CACHE_DIR}/logs"

    case "${action}" in
        save)
            save_session "${1:-}"
            ;;
        restore)
            restore_session "${1:-}"
            ;;
        list)
            list_sessions
            ;;
        delete)
            delete_session "${1:-}"
            ;;
        auto-save | daemon)
            auto_save_daemon
            ;;
        status)
            session_status
            ;;
        *)
            echo "Usage: session-restore.sh [save|restore|list|delete|auto-save|status] [name]"
            exit 1
            ;;
    esac
}

main "$@"