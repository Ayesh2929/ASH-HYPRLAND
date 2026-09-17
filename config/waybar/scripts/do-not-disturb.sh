#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Waybar Script: Do Not Disturb                    ║
# ║                                                                              ║
# ║  Reports the swaync DND state as a Waybar custom-module JSON payload.        ║
# ║  Referenced by config/waybar/config.jsonc → custom/do-not-disturb            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
#  The module uses format "{icon}" with two format-icons:
#     [0] 󰂞  notifications enabled
#     [1] 󰂛  do not disturb
#
#  Waybar selects the icon from the returned "alt" index, so the whole script
#  only has to answer "is DND on?".

set -euo pipefail

DND=false

if command -v swaync-client >/dev/null 2>&1; then
    # swaync-client -D prints true/false and exits 0 either way.
    raw="$(swaync-client -D 2>/dev/null || true)"
    [[ "${raw,,}" == "true" ]] && DND=true
elif command -v dunstctl >/dev/null 2>&1; then
    # Fall back to dunst so the module still works on non-swaync setups.
    if [[ "$(dunstctl is-paused 2>/dev/null || echo false)" == "true" ]]; then
        DND=true
    fi
fi

# Real newlines here — the escaping step below turns them into \n for JSON.
if [[ "$DND" == "true" ]]; then
    alt=1
    class="dnd"
    tooltip=$'Do Not Disturb is ON\n\nLeft-click: turn notifications back on'
else
    alt=0
    class="notifications"
    tooltip=$'Notifications are ON\n\nLeft-click: enable Do Not Disturb'
fi

# JSON-escape: backslashes first, then quotes, then newlines.
tooltip="${tooltip//\\/\\\\}"
tooltip="${tooltip//\"/\\\"}"
tooltip="${tooltip//$'\n'/\\n}"

printf '{"text":"","alt":%d,"class":"%s","tooltip":"%s"}\n' \
    "$alt" "$class" "$tooltip"
