#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  🔔 ASH NOTIFICATION ENGINE — Notification system for the ASH ecosystem           ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

readonly ASH_NOTIFICATION_VERSION="5.0.0"

# Notification system utilities
ash_notify() {
    local title="${1:-ASH Notification}"
    local message="${2:-}"
    local urgency="${3:-normal}"  # normal, low, critical
    local timeout="${4:-5000}"     # milliseconds
    local app_name="${5:-ASH}"
    local icon="${6:-}"

    if command -v notify-send &>/dev/null; then
        local notify_cmd="notify-send"
        [[ -n "${title}" ]] && notify_cmd+=" --title \"${title}\""
        [[ -n "${message}" ]] && notify_cmd+=" --body \"${message}\""
        [[ -n "${urgency}" ]] && notify_cmd+=" --urgency ${urgency}"
        [[ -n "${timeout}" ]] && notify_cmd+=" --expire-time ${timeout}"
        [[ -n "${app_name}" ]] && notify_cmd+=" --app-name \"${app_name}\""
        [[ -n "${icon}" ]] && notify_cmd+=" --icon \"${icon}\""

        eval "${notify_cmd}"
    else
        echo "Notification failed: notify-send not available"
        echo "Title: ${title}"
        echo "Message: ${message}"
    fi
}

ash_notify_info() {
    ash_notify "${1:-Info}" "${2:-}" "normal" "${3:-5000}" "ASH" "${4:-}"
}

ash_notify_success() {
    ash_notify "${1:-Success}" "${2:-}" "normal" "${3:-5000}" "ASH" "${4:-}"
}

ash_notify_warning() {
    ash_notify "${1:-Warning}" "${2:-}" "low" "${3:-10000}" "ASH" "${4:-}"
}

ash_notify_error() {
    ash_notify "${1:-Error}" "${2:-}" "critical" "${3:-0}" "ASH" "${4:-}"
}

# Notification history
ash_notification_log() {
    local title="${1:-}"
    local message="${2:-}"
    local level="${3:-info}"
    local timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    local log_file="${XDG_STATE_HOME:-${HOME}/.local/state}/ash/notifications.log"

    mkdir -p "$(dirname "${log_file}")" 2>/dev/null || true
    echo "${timestamp} ${level} \"${title}\" \"${message}\"]" >> "${log_file}"
}

ash_notification_history() {
    local limit="${1:-10}"
    local log_file="${2:-${XDG_STATE_HOME:-${HOME}/.local/state}/ash/notifications.log}"

    if [[ -f "${log_file}" ]]; then
        tail -n "${limit}" "${log_file}"
    else
        echo "No notifications found"
    fi
}

ash_notification_clear() {
    local log_file="${1:-${XDG_STATE_HOME:-${HOME}/.local/state}/ash/notifications.log}"
    if [[ -f "${log_file}" ]]; then
        : > "${log_file}"
        ash_log_info "Notification log cleared"
    else
        ash_log_warn "Notification log not found"
    fi
}

# Notification templates
ash_notification_template() {
    local template="${1:-}"
    local title="${2:-}"
    local message="${3:-}"
    local data="${4:-}"

    case "${template}" in
        mode_switch)
            ash_notify_success "Mode Switched" "${title} mode has been activated"
            ash_notification_log "Mode Switched" "${title} mode has been activated" "info"
            ;;
        system_update)
            ash_notify_info "System Update" "System update completed: ${message}"
            ash_notification_log "System Update" "${message}" "info"
            ;;
        warning)
            ash_notify_warning "Warning" "${message}"
            ash_notification_log "Warning" "${message}" "warning"
            ;;
        error)
            ash_notify_error "Error" "${message}"
            ash_notification_log "Error" "${message}" "error"
            ;;
        *)
            ash_notify_info "${title:-Notification}" "${message:-}"
            ash_notification_log "${title:-Notification}" "${message:-}" "info"
            ;;
    esac
}

# Notification queue
ash_notification_queue() {
    local title="${1:-}"
    local message="${2:-}"
    local delay="${3:-0}"
    local queue_file="${XDG_RUNTIME_DIR:-/tmp}/ash/notifications.queue"

    mkdir -p "$(dirname "${queue_file}")" 2>/dev/null || true
    local timestamp="$(date -u +%s)"
    echo "${timestamp} ${delay} \"${title}\" \"${message}\"" >> "${queue_file}"

    if [[ "${delay}" -gt 0 ]]; then
        (sleep "${delay}" && ash_notification_process_queue) &
    else
        ash_notification_process_queue
    fi
}

ash_notification_process_queue() {
    local queue_file="${1:-${XDG_RUNTIME_DIR:-/tmp}/ash/notifications.queue}"
    local timestamp=$(date -u +%s)

    if [[ -f "${queue_file}" ]]; then
        while read -r line; do
            local queue_timestamp="${line%% *}"
            local delay="${line#* }"
            local title="${line#* }"
            local message="${line#* }"

            if [[ "${queue_timestamp}" -le "${timestamp}" ]]; then
                ash_notify "${title}" "${message}"
                # Remove processed entry
                sed -i "/^${queue_timestamp} /d" "${queue_file}" 2>/dev/null || true
            fi
        done < "${queue_file}"
    fi
}

# Main entry point for notification library
ash_notification_main() {
    case "${1:-}" in
        init)
            echo "ASH Notification Engine v${ASH_NOTIFICATION_VERSION} initialized"
            ;;
        status)
            echo "ASH Notification Engine v${ASH_NOTIFICATION_VERSION}"
            echo "Functions: notify, notify_info, notify_success, notify_warning, notify_error, notification_log, notification_history, notification_clear, notification_template, notification_queue"
            ;;
        *)
            echo "Usage: ash_notification <command>"
            echo "Commands: init, status"
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ash_notification_main "$@"
fi
