#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — EWW WORKSPACES LISTENER                      ║
# ║           Listen to Hyprland workspace events and output JSON              ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

get_workspaces() {
    hyprctl workspaces -j 2>/dev/null | jq -c '[
        .[] |
        {
            id: .id,
            name: .name,
            windows: .windows,
            focused: false
        }
    ] | sort_by(.id)' 2>/dev/null || echo "[]"
}

# Initial output
get_workspaces

# Listen for workspace changes via socat
if command -v socat &>/dev/null; then
    SOCKET="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

    if [[ -S "${SOCKET}" ]]; then
        socat -u "UNIX-CONNECT:${SOCKET}" - 2>/dev/null | while IFS= read -r line; do
            case "${line}" in
                workspace*|createworkspace*|destroyworkspace*|movewindow*|openwindow*|closewindow*)
                    get_workspaces
                    ;;
            esac
        done
    fi
fi