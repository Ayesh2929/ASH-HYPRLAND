#!/bin/bash
set -euo pipefail

echo "Installing unique features..."

# Smart wallpaper cron
(crontab -l 2>/dev/null; echo "0 * * * * ~/.config/hypr/scripts/theme/smart-wallpaper.sh apply") | crontab -

# Analytics daemon
~/.config/hypr/scripts/theme/desktop-analytics.sh start

# Context awareness
~/.config/hypr/scripts/system/context.sh apply

echo "Unique features installed"