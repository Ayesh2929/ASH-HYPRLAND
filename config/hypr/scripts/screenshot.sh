#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — screenshot helper                                  ║
# ║  Referenced by config/hypr/env.conf ($screenshotter) and the binds.           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# Usage: screenshot.sh [area|window|monitor|full|gif|ocr]
set -euo pipefail

MODE="${1:-area}"
DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$DIR" 2>/dev/null || true
STAMP="$(date '+%Y%m%d-%H%M%S')"

notify() {
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send --app-name="ash-shot" --urgency="${2:-low}" "$1" "${3:-}" 2>/dev/null || true
}

copy_file() {
    [[ -f "$1" ]] || return 0
    command -v wl-copy >/dev/null 2>&1 && wl-copy < "$1" 2>/dev/null || true
}

case "$MODE" in
    area)
        command -v grim >/dev/null 2>&1 || { notify "⚠ grim missing" critical; exit 1; }
        command -v slurp >/dev/null 2>&1 || { notify "⚠ slurp missing" critical; exit 1; }
        geo="$(slurp 2>/dev/null)" || exit 0
        out="${DIR}/area-${STAMP}.png"
        grim -g "$geo" "$out" && { copy_file "$out"; notify "📸 Area captured" low "$out"; }
        ;;
    window)
        out="${DIR}/window-${STAMP}.png"
        if command -v hyprctl >/dev/null 2>&1 && command -v grim >/dev/null 2>&1; then
            geo="$(hyprctl activewindow -j 2>/dev/null | jq -r 'if .at and .size then "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])" else empty end' 2>/dev/null || true)"
            [[ -n "$geo" ]] && grim -g "$geo" "$out"
        elif command -v grimblast >/dev/null 2>&1; then
            grimblast save active "$out"
        fi
        [[ -f "$out" ]] && { copy_file "$out"; notify "📸 Window captured" low "$out"; }
        ;;
    monitor|output)
        out="${DIR}/monitor-${STAMP}.png"
        grim "$out" 2>/dev/null || { notify "⚠ grim missing" critical; exit 1; }
        copy_file "$out"; notify "📸 Monitor captured" low "$out"
        ;;
    full|screen)
        out="${DIR}/screen-${STAMP}.png"
        grim "$out" 2>/dev/null || { notify "⚠ grim missing" critical; exit 1; }
        copy_file "$out"; notify "📸 Screen captured" low "$out"
        ;;
    gif)
        command -v wf-recorder >/dev/null 2>&1 || { notify "⚠ wf-recorder missing" critical; exit 1; }
        geo="$(slurp 2>/dev/null)" || exit 0
        out="${DIR}/rec-${STAMP}.gif"
        notify "⏺ Recording GIF — click the notification to stop" low "$out"
        wf-recorder -g "$geo" -f "$out" >/dev/null 2>&1 &
        pid=$!
        wait "$pid" 2>/dev/null || true
        notify "⏹ GIF saved" low "$out"
        ;;
    ocr)
        command -v tesseract >/dev/null 2>&1 || { notify "⚠ tesseract missing" critical; exit 1; }
        geo="$(slurp 2>/dev/null)" || exit 0
        tmp="$(mktemp --suffix=.png)"
        grim -g "$geo" "$tmp" 2>/dev/null || exit 1
        text="$(tesseract "$tmp" - 2>/dev/null || true)"
        rm -f "$tmp"
        if [[ -n "$text" ]]; then
            printf '%s\n' "$text" | wl-copy 2>/dev/null || printf '%s\n' "$text"
            notify "🔤 Text copied" low "Recognised $(printf '%s' "$text" | wc -l) line(s)"
        else
            notify "🔤 No text found" normal
        fi
        ;;
    *)
        printf 'Usage: %s [area|window|monitor|full|gif|ocr]\n' "${0##*/}" >&2
        exit 2
        ;;
esac
exit 0
