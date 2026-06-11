#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WAYBAR PLAYER PICKER SCRIPT                  ║
# ║           Select active media player for Waybar module                     ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# Delegate to the Hyprland player picker
exec "${HOME}/.config/hypr/scripts/media/player-picker.sh" "${@:-pick}"