#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Waybar Script: Screen Share Indicator            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# Method 1: Check via XDG portal portal sessions
SHARING=false
SHARE_APP=""

# Check pipewire screenshare streams
if command -v pw-cli &>/dev/null; then
    if pw-cli list-objects Node 2>/dev/null | grep -q "xdg-desktop-portal"; then
        SHARING=true
        SHARE_APP="XDG Portal"
    fi
fi

# Method 2: Check for wlr-screencopy consumers
if command -v wlr-randr &>/dev/null && ! $SHARING; then
    # Check via dbus for screenshare sessions
    if command -v dbus-send &>/dev/null; then
        SESSIONS=$(dbus-send --session --print-reply \
            --dest=org.freedesktop.portal.Desktop \
            /org/freedesktop/portal/desktop \
            org.freedesktop.DBus.Properties.Get \
            string:org.freedesktop.portal.ScreenCast string:version \
            2>/dev/null || true)
        if [[ -n "$SESSIONS" ]]; then
            SHARING=true
            SHARE_APP="Screen Cast"
        fi
    fi
fi

# Method 3: Check for OBS screenshare or known sharing apps
for proc in obs zoom discord teams slack; do
    if pgrep -x "$proc" &>/dev/null; then
        SHARE_APP="$proc"
    fi
done

if $SHARING; then
    TOOLTIP="󰻃 Screen sharing active\n\n"
    TOOLTIP+="Via: ${SHARE_APP}\n"
    TOOLTIP+="\nLeft: stop sharing"
    TOOLTIP=$(echo "$TOOLTIP" | sed 's/\\/\\\\/g; s/"/\\"/g')

    printf '{"text":"<span color=\"#f38ba8\">󰻃 SHARE</span>","tooltip":"%s","class":"active"}\n' \
        "$TOOLTIP"
else
    printf '{"text":"","tooltip":"No active screen sharing","class":"idle"}\n'
fi