#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — UPDATE SCRIPT                                ║
# ║           Update dotfiles and packages with safety checks                  ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly DOTFILES_DIR="${HOME}/.dotfiles"
readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/update.log"
readonly BACKUP_BEFORE_UPDATE=true

# Colors
readonly R='\033[0m'
readonly B='\033[1m'
readonly G='\033[92m'
readonly Y='\033[93m'
readonly C='\033[96m'
readonly M='\033[95m'
readonly DIM='\033[2m'

log()     { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info()    { echo -e "  ${C}→${R} $*"; log "INFO" "$*"; }
ok()      { echo -e "  ${G}✓${R} $*"; log "OK" "$*"; }
warn()    { echo -e "  ${Y}⚠${R} $*" >&2; log "WARN" "$*"; }
section() { echo -e "\n  ${B}${M}${1}${R}"; }

main() {
    mkdir -p "${CACHE_DIR}/logs"

    echo ""
    echo -e "  ${B}${M}📦 ASH Dotfiles Update${R}"
    echo -e "  ${DIM}$(date '+%Y-%m-%d %H:%M:%S')${R}"
    echo ""

    # ── Backup first ─────────────────────────────────────────────────────────
    if [[ "${BACKUP_BEFORE_UPDATE}" == "true" ]]; then
        section "💾 Creating Backup"
        ash backup silent 2>/dev/null \
            && ok "Backup created" \
            || warn "Backup failed — continuing anyway"
    fi

    # ── Update dotfiles repo ──────────────────────────────────────────────────
    section "🐙 Updating Dotfiles Repository"

    if [[ ! -d "${DOTFILES_DIR}/.git" ]]; then
        warn "Not a git repo: ${DOTFILES_DIR}"
    else
        cd "${DOTFILES_DIR}"
        local branch
        branch=$(git branch --show-current 2>/dev/null || echo "main")

        info "Current branch: ${branch}"

        # Check for local changes
        if ! git diff --quiet 2>/dev/null; then
            warn "Local changes detected — stashing..."
            git stash push -m "ash-update-$(date +%s)" 2>/dev/null
            ok "Changes stashed"
        fi

        # Fetch
        info "Fetching from remote..."
        if git fetch origin "${branch}" 2>/dev/null; then
            local behind
            behind=$(git rev-list "HEAD...origin/${branch}" --count 2>/dev/null || echo "0")

            if (( behind > 0 )); then
                info "Pulling ${behind} new commit(s)..."
                git pull origin "${branch}" 2>/dev/null \
                    && ok "Updated ${behind} commits" \
                    || warn "Pull failed"
            else
                ok "Already up to date"
            fi
        else
            warn "Could not fetch from remote"
        fi
    fi

    # ── Fix permissions ───────────────────────────────────────────────────────
    section "🔐 Fixing Permissions"
    find "${HOME}/.config" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    find "${HOME}/.local/bin" -name "ash*" -exec chmod +x {} \; 2>/dev/null || true
    ok "Script permissions updated"

    # ── Update system packages ────────────────────────────────────────────────
    section "📦 System Package Updates"

    local aur_helper=""
    command -v paru &>/dev/null && aur_helper="paru"
    command -v yay  &>/dev/null && aur_helper="${aur_helper:-yay}"

    if [[ -n "${aur_helper}" ]]; then
        info "Updating with ${aur_helper}..."
        if "${aur_helper}" -Syu --noconfirm 2>/dev/null; then
            ok "System packages updated"
        else
            warn "Package update had issues — check manually"
        fi
    else
        info "Updating with pacman..."
        if sudo pacman -Syu --noconfirm 2>/dev/null; then
            ok "System packages updated"
        else
            warn "Pacman update had issues"
        fi
    fi

    # ── Reload theme ──────────────────────────────────────────────────────────
    section "🎨 Reapplying Theme"
    if command -v ash &>/dev/null; then
        ash reload theme 2>/dev/null && ok "Theme reapplied"
    fi

    # ── Update Neovim plugins ─────────────────────────────────────────────────
    section "📝 Updating Neovim Plugins"
    if command -v nvim &>/dev/null; then
        info "Running :Lazy sync..."
        nvim --headless "+Lazy! sync" +qa 2>/dev/null \
            && ok "Neovim plugins updated" \
            || warn "Neovim plugin update failed"
    fi

    # ── Update Fisher plugins ─────────────────────────────────────────────────
    section "🐟 Updating Fish Plugins"
    if command -v fish &>/dev/null; then
        fish -c "fisher update 2>/dev/null" \
            && ok "Fish plugins updated" \
            || warn "Fisher update failed (fisher may not be installed)"
    fi

# Quick verification stub — if called directly, sources the real file
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_FILE="${SELF_DIR}/update.sh"

if [[ -f "${REAL_FILE}" ]] && [[ "${BASH_SOURCE[0]}" != "${REAL_FILE}" ]]; then
    exec bash "${REAL_FILE}" "$@"
fi

echo "ASH Update Script — v3.0.0"
echo "Run: ash update"

    # ── Done ──────────────────────────────────────────────────────────────────
    echo ""
    echo -e "  ${G}${B}✓ Update complete!${R}"
    echo ""
    log "INFO" "update complete"
}

main "$@"