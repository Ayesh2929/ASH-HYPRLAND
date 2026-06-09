#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — ROFI APP LAUNCHER                            ║
# ║           Feature-rich application launcher with categories                ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CONFIG_DIR="${HOME}/.config"
readonly ROFI_THEME="${CONFIG_DIR}/rofi/themes/ash-dynamic.rasi"
readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/rofi.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 THEME OVERRIDE
# ═══════════════════════════════════════════════════════════════════════════════

THEME_OVERRIDE='
window {
    width: 680px;
    border-radius: 16px;
}
listview {
    columns: 1;
    lines: 10;
}
element {
    padding: 8px 12px;
}
'

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 LAUNCH
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    mkdir -p "${CACHE_DIR}/logs"

    # Ensure theme exists
    if [[ ! -f "${ROFI_THEME}" ]]; then
        # Generate minimal theme
        mkdir -p "$(dirname "${ROFI_THEME}")"
        cat > "${ROFI_THEME}" << 'EOF'
* { background-color: #1e1e2eee; text-color: #cdd6f4; font: "JetBrainsMono Nerd Font 12"; }
window { border: 2px solid #cba6f7; border-radius: 14px; padding: 16px; width: 640px; }
inputbar { background-color: #313244; border-radius: 10px; padding: 8px 12px; margin-bottom: 8px; }
entry { background-color: transparent; }
element selected { background-color: #313244; color: #cba6f7; border-radius: 8px; }
EOF
    fi

    log "INFO" "Launcher opened"

    rofi \
        -show drun \
        -theme "${ROFI_THEME}" \
        -theme-str "${THEME_OVERRIDE}" \
        -show-icons \
        -icon-theme "Papirus-Dark" \
        -display-drun "🚀 Launch" \
        -drun-display-format "{name}" \
        -no-drun-show-actions \
        -terminal "kitty" \
        -kb-cancel "Escape,Super_L" \
        -matching fuzzy \
        -sort \
        -sorting-method fzf \
        -drun-match-fields "name,generic,comment,categories,exec" \
        2>/dev/null

    log "INFO" "Launcher closed"
}

main "$@"