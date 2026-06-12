#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — ROFI DRUN LAUNCHER                           ║
# ║           Desktop application launcher with categories                     ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly ROFI_THEME="${HOME}/.config/rofi/themes/ash-dynamic.rasi"

mkdir -p "${CACHE_DIR}/logs"

rofi \
    -show drun \
    -theme "${ROFI_THEME}" \
    -theme-str '
        window { width: 680px; border-radius: 16px; }
        listview { columns: 1; lines: 10; }
        element { padding: 8px 12px; }
        element-icon { size: 24px; }
    ' \
    -show-icons \
    -icon-theme "Papirus-Dark" \
    -display-drun "  Launch" \
    -drun-display-format "{name}" \
    -drun-match-fields "name,generic,comment,categories,exec" \
    -no-drun-show-actions \
    -terminal "kitty" \
    -matching fuzzy \
    -sort \
    -sorting-method fzf \
    2>/dev/null