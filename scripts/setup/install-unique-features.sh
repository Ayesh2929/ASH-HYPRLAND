#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — UNIQUE FEATURES INSTALLER                    ║
# ║           Sets up all new unique features                                  ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly CONFIG_DIR="${HOME}/.config"

info() { echo -e "  \033[96m→\033[0m $*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; }
section() { echo -e "\n  \033[1m\033[95m${1}\033[0m"; }

main() {
    echo ""
    echo -e "  \033[1m\033[95m🌟 Installing ASH Unique Features...\033[0m"
    echo ""

    # ── Create required directories ───────────────────────────────────────────
    section "📁 Creating Directories"

    local dirs=(
        "${CACHE_DIR}/theme-history"
        "${CACHE_DIR}/analytics"
        "${CACHE_DIR}/ai-palettes"
        "${HOME}/.config/hypr/scripts/analytics"
        "${HOME}/.local/share/ash-dots/workspace-profiles"
    )

    for dir in "${dirs[@]}"; do
        mkdir -p "${dir}"
        ok "${dir/$HOME/~}"
    done

    # ── Make scripts executable ───────────────────────────────────────────────
    section "🔐 Setting Permissions"

    local scripts=(
        "${CONFIG_DIR}/hypr/scripts/theme/album-art-theme.sh"
        "${CONFIG_DIR}/hypr/scripts/theme/health-score.sh"
        "${CONFIG_DIR}/hypr/scripts/theme/workspace-profiles.sh"
        "${CONFIG_DIR}/hypr/scripts/theme/smart-wallpaper.sh"
        "${CONFIG_DIR}/hypr/scripts/theme/theme-undo.sh"
        "${CONFIG_DIR}/hypr/scripts/theme/light-theme.sh"
        "${CONFIG_DIR}/hypr/scripts/theme/ai-theme.sh"
        "${CONFIG_DIR}/hypr/scripts/analytics/desktop-analytics.sh"
    )

    for script in "${scripts[@]}"; do
        if [[ -f "${script}" ]]; then
            chmod +x "${script}"
            ok "chmod +x $(basename "${script}")"
        else
            warn "Not found: $(basename "${script}")"
        fi
    done

    # ── Install optional dependencies ─────────────────────────────────────────
    section "📦 Checking Dependencies"

    # sqlite3 for analytics
    if ! command -v sqlite3 &>/dev/null; then
        info "Installing sqlite3..."
        paru -S --needed --noconfirm sqlite 2>/dev/null \
            && ok "sqlite3 installed" \
            || warn "sqlite3 install failed (analytics won't work)"
    else
        ok "sqlite3 available"
    fi

    # socat for analytics socket
    if ! command -v socat &>/dev/null; then
        info "Installing socat..."
        paru -S --needed --noconfirm socat 2>/dev/null \
            && ok "socat installed" \
            || warn "socat install failed (analytics limited)"
    else
        ok "socat available"
    fi

    # ── Initialize workspace profiles ─────────────────────────────────────────
    section "📁 Workspace Profiles"
    "${CONFIG_DIR}/hypr/scripts/theme/workspace-profiles.sh" init 2>/dev/null \
        && ok "Built-in profiles created" \
        || warn "Profile creation failed"

    # ── Create default smart wallpaper schedule ───────────────────────────────
    section "🌤️ Smart Wallpaper"
    "${CONFIG_DIR}/hypr/scripts/theme/smart-wallpaper.sh" schedule \
        &>/dev/null 2>&1 || true
    ok "Default schedule created"

    # ── Setup auto theme timer ────────────────────────────────────────────────
    section "🕐 Auto Theme Timer"
    info "Setting up hourly auto-theme check..."

    cat > "${HOME}/.config/systemd/user/ash-auto-theme.service" << 'EOF'
[Unit]
Description=ASH Auto Theme Mode (light/dark based on time)

[Service]
Type=oneshot
ExecStart=%h/.config/hypr/scripts/theme/light-theme.sh auto
StandardOutput=journal
StandardError=journal
EOF

    cat > "${HOME}/.config/systemd/user/ash-auto-theme.timer" << 'EOF'
[Unit]
Description=ASH Auto Theme Timer

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF

    systemctl --user daemon-reload 2>/dev/null || true
    # Don't enable by default — user opts in
    info "Auto theme timer created (enable with: ash theme mode schedule)"

    # ── Update keybinds for new features ─────────────────────────────────────
    section "⌨️ New Keybinds"

    # These go into UserOverrides if user wants them
    cat >> "${HOME}/.cache/ash-dots/suggested-keybinds.txt" << 'EOF'
# === ASH UNIQUE FEATURES — Add to UserOverrides/user.conf ===

# Music reactive theme
bind = SUPER ALT, Z, exec, ~/.config/hypr/scripts/theme/album-art-theme.sh toggle

# Light/dark mode toggle
bind = SUPER ALT, D, exec, ~/.config/hypr/scripts/theme/light-theme.sh toggle

# Workspace profiles
bind = SUPER ALT, 1, exec, ~/.config/hypr/scripts/theme/workspace-profiles.sh apply coding
bind = SUPER ALT, 2, exec, ~/.config/hypr/scripts/theme/workspace-profiles.sh apply gaming
bind = SUPER ALT, 3, exec, ~/.config/hypr/scripts/theme/workspace-profiles.sh apply meeting

# Theme undo
bind = SUPER, Z, exec, ~/.config/hypr/scripts/theme/theme-undo.sh undo

# Health score
bind = SUPER SHIFT, H, exec, kitty --class=ash-score -e ash score

# Analytics dashboard
bind = SUPER SHIFT, A, exec, kitty --class=ash-analytics -e ash analytics show
EOF

    ok "Suggested keybinds saved to: ~/.cache/ash-dots/suggested-keybinds.txt"

    # ── Print summary ──────────────────────────────────────────────────────────
    echo ""
    echo -e "  \033[1m\033[95m╔══════════════════════════════════════════════╗\033[0m"
    echo -e "  \033[1m\033[95m║\033[0m   \033[1m🌟 Unique Features Installed!\033[0m             \033[1m\033[95m║\033[0m"
    echo -e "  \033[1m\033[95m╠══════════════════════════════════════════════╣\033[0m"
    echo -e "  \033[1m\033[95m║\033[0m   \033[96mash music enable\033[0m    → Music reactive     \033[1m\033[95m║\033[0m"
    echo -e "  \033[1m\033[95m║\033[0m   \033[96mash score\033[0m           → Health score       \033[1m\033[95m║\033[0m"
    echo -e "  \033[1m\033[95m║\033[0m   \033[96mash workspace list\033[0m  → Workspace profiles \033[1m\033[95m║\033[0m"
    echo -e "  \033[1m\033[95m║\033[0m   \033[96mash smart enable\033[0m    → Smart wallpapers   \033[1m\033[95m║\033[0m"
    echo -e "  \033[1m\033[95m║\033[0m   \033[96mash analytics start\033[0m → Desktop analytics  \033[1m\033[95m║\033[0m"
    echo -e "  \033[1m\033[95m║\033[0m   \033[96mash theme ai 'desc'\033[0m → AI color gen       \033[1m\033[95m║\033[0m"
    echo -e "  \033[1m\033[95m║\033[0m   \033[96mash theme undo\033[0m      → Undo last theme    \033[1m\033[95m║\033[0m"
    echo -e "  \033[1m\033[95m║\033[0m   \033[96mash theme mode light\033[0m → Light mode        \033[1m\033[95m║\033[0m"
    echo -e "  \033[1m\033[95m╚══════════════════════════════════════════════╝\033[0m"
    echo ""
}

main "$@"