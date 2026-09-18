#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Waybar: flatpak update counter                    ║
# ║  Result is cached for an hour: `flatpak remote-ls --updates` is slow.        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ash-dotfiles"
CACHE_FILE="${CACHE_DIR}/updates-flatpak.cache"
TTL=3600
mkdir -p "$CACHE_DIR" 2>/dev/null || true

now="$(date +%s)"
count=""
if [[ -f "$CACHE_FILE" ]]; then
    read -r stamp cached < <(printf '%s\n' "$(cat "$CACHE_FILE" 2>/dev/null)")
    if [[ "$stamp" =~ ^[0-9]+$ && "$cached" =~ ^[0-9]+$ ]] && (( now - stamp < TTL )); then
        count="$cached"
    fi
fi

if [[ -z "$count" ]]; then
    if command -v flatpak >/dev/null 2>&1; then
        count="$(timeout 25 flatpak remote-ls --updates --columns=application 2>/dev/null | grep -c . || true)"
    fi
    count="${count:-0}"
    [[ "$count" =~ ^[0-9]+$ ]] || count=0
    printf '%s %s\n' "$now" "$count" > "$CACHE_FILE" 2>/dev/null || true
fi

class="updates-flatpak"
if (( count > 0 )); then
    class="updates-flatpak has-updates"
    text="flatpak ${count}"
    tip="${count} flatpak update(s) available — click to update"
else
    text="flatpak 0"
    tip="All flatpaks are up to date"
fi

printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$text" "$class" "$tip"
