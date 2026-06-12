#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WAYBAR NETWORK TOGGLE SCRIPT                 ║
# ║           Quick WiFi toggle for Waybar module                              ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"

# Delegate to main wifi toggle script
exec "${HOME}/.config/hypr/scripts/network/wifi-toggle.sh" "${1:-toggle}"