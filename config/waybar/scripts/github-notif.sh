#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Waybar Script: GitHub Notifications              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/ash-dotfiles/github-notif.cache"
readonly CACHE_AGE=300  # 5 minutes

# Check gh CLI auth
if ! gh auth status &>/dev/null 2>&1; then
    echo '{"text":"","tooltip":"GitHub CLI not authenticated","class":"no-auth"}'
    exit 0
fi

# Cache check
if [[ -f "$CACHE_FILE" ]]; then
    local_age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) ))
    [[ $local_age -lt $CACHE_AGE ]] && cat "$CACHE_FILE" && exit 0
fi

mkdir -p "$(dirname "$CACHE_FILE")"

# Fetch notifications
NOTIFS=$(gh api /notifications --jq '.' 2>/dev/null) || {
    echo '{"text":"󰊤 ?","tooltip":"Failed to fetch","class":"error"}'
    exit 0
}

COUNT=$(echo "$NOTIFS" | jq 'length' 2>/dev/null || echo 0)

if [[ "$COUNT" -eq 0 ]]; then
    OUTPUT='{"text":"","tooltip":"No GitHub notifications","class":"no-notif"}'
else
    # Build notification list (top 8)
    DETAILS=$(echo "$NOTIFS" | jq -r '
        .[0:8] |
        .[] |
        "• [\(.subject.type)] \(.subject.title | .[0:55])"
    ' 2>/dev/null | head -8)

    UNREAD_REPOS=$(echo "$NOTIFS" | jq -r '[.[].repository.full_name] | unique | .[:5] | .[]' 2>/dev/null | head -5)

    TOOLTIP="󰊤 GitHub: ${COUNT} unread notification(s)\n\n"
    TOOLTIP+="${DETAILS}\n\n"
    TOOLTIP+="Repos: $(echo "$UNREAD_REPOS" | tr '\n' ' ')\n"
    TOOLTIP+="\nLeft: open GitHub  Right: mark all read"

    TOOLTIP=$(echo "$TOOLTIP" | sed 's/\\/\\\\/g; s/"/\\"/g')

    CSS="has-notif"
    [[ "$COUNT" -ge 10 ]] && CSS="many-notif"

    OUTPUT=$(printf '{"text":"󰊤 %s","tooltip":"%s","class":"%s"}' \
        "$COUNT" "$TOOLTIP" "$CSS")
fi

echo "$OUTPUT" | tee "$CACHE_FILE"