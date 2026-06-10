#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — EWW ACTIVE WORKSPACE LISTENER                ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

get_active() {
    hyprctl activewindow -j 2>/dev/null \
        | jq -r '.workspace.id // 1' \
        || echo "1"
}

# Initial
get_active

# Listen
if command -v socat &>/dev/null; then
    SOCKET="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

    if [[ -S "${SOCKET}" ]]; then
        socat -u "UNIX-CONNECT:${SOCKET}" - 2>/dev/null | while IFS= read -r line; do
            case "${line}" in
                workspace*)
                    get_active
                    ;;
            esac
        done
    fi
fi