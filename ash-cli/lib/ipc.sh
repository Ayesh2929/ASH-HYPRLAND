#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  📡 ASH IPC ENGINE — Inter-process communication system for the ASH ecosystem    ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# A sourced library must not mutate the caller's shell options.
# `set -e` inside a sourced file silently aborts the *parent* script
# on the next non-zero test, which is a nightmare to debug.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
fi

readonly ASH_IPC_VERSION="5.0.0"

# IPC socket configuration
readonly ASH_IPC_SOCKET="${XDG_RUNTIME_DIR:-/tmp}/ash.sock"
readonly ASH_IPC_BUFFER_SIZE="8192"
readonly ASH_IPC_TIMEOUT="30"

# IPC message types
readonly ASH_IPC_MODE_CHANGED="mode_changed"
readonly ASH_IPC_CONFIG_CHANGED="config_changed"
readonly ASH_IPC_SYSTEM_EVENT="system_event"
readonly ASH_IPC_PLUGIN_MESSAGE="plugin_message"

# IPC client utilities
ash_ipc_connect() {
    if [[ ! -S "${ASH_IPC_SOCKET}" ]]; then
        echo "IPC socket not available: ${ASH_IPC_SOCKET}" >&2
        return 1
    fi

    echo "Connected to IPC socket: ${ASH_IPC_SOCKET}"
    return 0
}

ash_ipc_send() {
    local message_type="${1}"
    local message_data="${2}"
    local target="${3:-}"

    if [[ ! -S "${ASH_IPC_SOCKET}" ]]; then
        echo "IPC socket not available: ${ASH_IPC_SOCKET}" >&2
        return 1
    fi

    echo -n "${message_type} ${message_data}" | socat - UNIX-CONNECT:"${ASH_IPC_SOCKET}" 2>/dev/null
}

ash_ipc_broadcast() {
    local message_type="${1}"
    local message_data="${2}"
    ash_ipc_send "${message_type}" "${message_data}"
}

ash_ipc_request() {
    local message_type="${1}"
    local message_data="${2}"
    local timeout="${3:-${ASH_IPC_TIMEOUT}}"

    if [[ ! -S "${ASH_IPC_SOCKET}" ]]; then
        echo "IPC socket not available: ${ASH_IPC_SOCKET}" >&2
        return 1
    fi

    local temp_file="${ASH_RUNTIME_DIR}/ipc_request_$$.json"
    local response_file="${ASH_RUNTIME_DIR}/ipc_response_$$.json"

    # Send request
    echo -n "REQ ${message_type} ${message_data}" | socat - UNIX-CONNECT:"${ASH_IPC_SOCKET}" "UNIX-LISTEN:${temp_file}" 2>/dev/null

    # Wait for response
    local response_timeout=0
    while [[ ! -f "${response_file}" ]] && (( response_timeout < timeout )); do
        sleep 0.1
        response_timeout=$((response_timeout + 1))
    done

    if [[ -f "${response_file}" ]]; then
        cat "${response_file}"
        rm -f "${temp_file}" "${response_file}"
        return 0
    else
        echo "Request timeout"
        rm -f "${temp_file}"
        return 1
    fi
}

# IPC server utilities
ash_ipc_server_start() {
    local socket_path="${1:-${ASH_IPC_SOCKET}}"

    if [[ -S "${socket_path}" ]]; then
        echo "IPC socket already exists: ${socket_path}" >&2
        return 1
    fi

    mkdir -p "$(dirname "${socket_path}")" 2>/dev/null || true

    echo "Starting IPC server on: ${socket_path}"
    socat "UNIX-LISTEN:${socket_path}" "system:cat" 2>/dev/null &
    local server_pid=$!
    echo "${server_pid}" > "${ASH_RUNTIME_DIR}/ash.sock.pid"

    # Trap to clean up on exit
    trap 'ash_ipc_server_stop' EXIT INT TERM HUP
}

ash_ipc_server_stop() {
    if [[ -f "${ASH_RUNTIME_DIR}/ash.sock.pid" ]]; then
        local pid=$(cat "${ASH_RUNTIME_DIR}/ash.sock.pid")
        kill "${pid}" 2>/dev/null || true
        rm -f "${ASH_RUNTIME_DIR}/ash.sock.pid"
    fi

    if [[ -S "${ASH_IPC_SOCKET}" ]]; then
        rm -f "${ASH_IPC_SOCKET}" 2>/dev/null || true
    fi
}

ash_ipc_server_handle() {
    local message_type="${1}"
    local message_data="${2}"
    local response_file="${ASH_RUNTIME_DIR}/ipc_response_$$.json"

    case "${message_type}" in
        "mode_changed")
            echo "{" > "${response_file}"
            echo "  \"status\": \"handled\"," >> "${response_file}"
            echo "  \"message\": \"Mode change: ${message_data}\"" >> "${response_file}"
            echo "}" >> "${response_file}"
            ;;
        "config_changed")
            echo "{" > "${response_file}"
            echo "  \"status\": \"handled\"," >> "${response_file}"
            echo "  \"message\": \"Config changed: ${message_data}\"" >> "${response_file}"
            echo "}" >> "${response_file}"
            ;;
        *)
            echo "{" > "${response_file}"
            echo "  \"status\": \"error\"," >> "${response_file}"
            echo "  \"message\": \"Unknown message type: ${message_type}\"" >> "${response_file}"
            echo "}" >> "${response_file}"
            ;;
    esac

    echo "${response_file}"
}

# IPC message middleware
ash_ipc_middleware() {
    local message_type="${1}"
    local message_data="${2}"

    # Log the message
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) ${message_type} ${message_data}" >> "${ASH_RUNTIME_DIR}/ash.ipc.log" 2>/dev/null || true

    # Apply middleware logic here
    # For example, filter messages, modify them, etc.

    echo "${message_type} ${message_data}"
}

# Main entry point for IPC library
ash_ipc_main() {
    case "${1:-}" in
        init)
            echo "ASH IPC Engine v${ASH_IPC_VERSION} initialized"
            ;;
        status)
            echo "ASH IPC Engine v${ASH_IPC_VERSION}"
            echo "Socket: ${ASH_IPC_SOCKET}"
            echo "Buffer size: ${ASH_IPC_BUFFER_SIZE}"
            echo "Timeout: ${ASH_IPC_TIMEOUT}s"
            ;;
        start)
            ash_ipc_server_start "$2"
            ;;
        stop)
            ash_ipc_server_stop
            ;;
        *)
            echo "Usage: ash_ipc <command>"
            echo "Commands: init, status, start, stop"
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ash_ipc_main "$@"
fi
