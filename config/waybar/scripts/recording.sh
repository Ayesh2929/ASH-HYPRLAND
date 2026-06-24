#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Waybar Script: Screen Recording Indicator        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# Check for active recorders
WF_PID=$(pgrep -x wf-recorder 2>/dev/null | head -1 || true)
OBS_RECORDING=false
if pgrep -x obs &>/dev/null; then
    # Check if OBS is actively recording (not just open)
    if command -v obs-cli &>/dev/null; then
        OBS_RECORDING=$(obs-cli recording status 2>/dev/null | grep -q "recording" && echo true || echo false)
    fi
fi

if [[ -n "$WF_PID" ]] || [[ "$OBS_RECORDING" == "true" ]]; then
    # Get recording duration
    ELAPSED=""
    if [[ -n "$WF_PID" ]]; then
        ELAPSED_SECS=$(( $(date +%s) - $(stat -c %Y /proc/"$WF_PID" 2>/dev/null || echo "$(date +%s)") ))
        ELAPSED=$(printf "%d:%02d" $((ELAPSED_SECS/60)) $((ELAPSED_SECS%60)))
    fi

    RECORDER="wf-recorder"
    [[ "$OBS_RECORDING" == "true" ]] && RECORDER="OBS Studio"

    TOOLTIP="🔴 Recording in progress\n\n"
    TOOLTIP+="Recorder: ${RECORDER}\n"
    [[ -n "$ELAPSED" ]] && TOOLTIP+="Duration: ${ELAPSED}\n"
    TOOLTIP+="\nLeft-click: stop recording"

    TOOLTIP=$(echo "$TOOLTIP" | sed 's/\\/\\\\/g; s/"/\\"/g')

    printf '{"text":"<span color=\"#f38ba8\">󰑊 REC %s</span>","tooltip":"%s","class":"recording"}\n' \
        "$ELAPSED" "$TOOLTIP"
else
    printf '{"text":"","tooltip":"No active recording","class":"idle"}\n'
fi