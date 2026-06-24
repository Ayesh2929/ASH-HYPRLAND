#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Waybar Script: Pacman/AUR Updates                ║
# ║                                                                              ║
# ║  Checks for pending system updates from pacman repos and AUR.              ║
# ║  Uses checkupdates (safe, no root) + paru/yay for AUR.                    ║
# ║  Caches results for 1 hour to avoid hammering mirrors.                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/ash-dotfiles/updates-pacman.cache"
readonly CACHE_AGE=3600     # 1 hour
readonly LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/ash-updates.lock"

# ── Argument handling ─────────────────────────────────────────────────────────
FORCE_REFRESH=false
[[ "${1:-}" == "--refresh" ]] && FORCE_REFRESH=true

# ── Lock (prevent concurrent update checks) ───────────────────────────────────
if [[ -f "$LOCK_FILE" ]]; then
    # Use cached data if locked
    [[ -f "$CACHE_FILE" ]] && cat "$CACHE_FILE" && exit 0
    echo '{"text":"󰀠 ...","tooltip":"Checking for updates...","class":"checking"}' && exit 0
fi
touch "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# ── Cache validity ────────────────────────────────────────────────────────────
if [[ "$FORCE_REFRESH" == false ]] && [[ -f "$CACHE_FILE" ]]; then
    local_age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) ))
    if [[ $local_age -lt $CACHE_AGE ]]; then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

mkdir -p "$(dirname "$CACHE_FILE")"

# ── Count updates ─────────────────────────────────────────────────────────────
PACMAN_COUNT=0
AUR_COUNT=0
PACMAN_LIST=""
AUR_LIST=""

# Official repos (checkupdates = no root, safe)
if command -v checkupdates &>/dev/null; then
    PACMAN_LIST=$(checkupdates 2>/dev/null || true)
    PACMAN_COUNT=$(echo "$PACMAN_LIST" | grep -c . 2>/dev/null || echo 0)
fi

# AUR (paru preferred, yay fallback)
if command -v paru &>/dev/null; then
    AUR_LIST=$(paru -Qua 2>/dev/null || true)
    AUR_COUNT=$(echo "$AUR_LIST" | grep -c . 2>/dev/null || echo 0)
elif command -v yay &>/dev/null; then
    AUR_LIST=$(yay -Qua 2>/dev/null || true)
    AUR_COUNT=$(echo "$AUR_LIST" | grep -c . 2>/dev/null || echo 0)
fi

TOTAL=$(( PACMAN_COUNT + AUR_COUNT ))

# ── Build output ──────────────────────────────────────────────────────────────
if [[ "$TOTAL" -eq 0 ]]; then
    OUTPUT='{"text":"","tooltip":"System is up to date 󰄬","class":"up-to-date"}'
else
    # Severity class
    CSS_CLASS="updates"
    [[ "$TOTAL" -ge 10 ]] && CSS_CLASS="many-updates"
    [[ "$TOTAL" -ge 25 ]] && CSS_CLASS="critical-updates"

    # Package preview (first 8 packages)
    local PREVIEW=""
    if [[ -n "$PACMAN_LIST" ]]; then
        PREVIEW+="Pacman (${PACMAN_COUNT}):\n"
        while IFS= read -r pkg; do
            [[ -z "$pkg" ]] && continue
            PREVIEW+="  • ${pkg}\n"
        done <<< "$(echo "$PACMAN_LIST" | head -5)"
        [[ $PACMAN_COUNT -gt 5 ]] && PREVIEW+="  … and $((PACMAN_COUNT - 5)) more\n"
    fi

    if [[ -n "$AUR_LIST" ]]; then
        [[ -n "$PREVIEW" ]] && PREVIEW+="\n"
        PREVIEW+="AUR (${AUR_COUNT}):\n"
        while IFS= read -r pkg; do
            [[ -z "$pkg" ]] && continue
            PREVIEW+="  • ${pkg}\n"
        done <<< "$(echo "$AUR_LIST" | head -5)"
        [[ $AUR_COUNT -gt 5 ]] && PREVIEW+="  … and $((AUR_COUNT - 5)) more\n"
    fi

    TOOLTIP="${TOTAL} update(s) available\n\n${PREVIEW}\nClick to upgrade • Right-click: refresh"
    TOOLTIP=$(echo "$TOOLTIP" | sed 's/\\/\\\\/g; s/"/\\"/g')

    OUTPUT=$(printf '{"text":"%s","tooltip":"%s","class":"%s"}' \
        "$TOTAL" "$TOOLTIP" "$CSS_CLASS")
fi

# ── Cache and output ──────────────────────────────────────────────────────────
echo "$OUTPUT" | tee "$CACHE_FILE"