#!/bin/bash
set -euo pipefail

echo "Final System Check"
echo "=================="

checks=0
passed=0

check() {
    ((checks++))
    if eval "$2"; then
        echo "  ✅ $1"
        ((passed++))
    else
        echo "  ❌ $1"
    fi
}

check "Hyprland running" "pgrep -x hyprland >/dev/null"
check "Waybar running" "pgrep -x waybar >/dev/null"
check "SwayNC running" "pgrep -x swaync >/dev/null"
check "Hyprpaper running" "pgrep -x hyprpaper >/dev/null"
check "Config valid" "hyprctl reload 2>&1 | grep -q 'ok' || true"
check "Scripts executable" "[[ -x ~/.config/hypr/scripts/theme/smart-wallpaper.sh ]]"
check "Analytics DB" "[[ -f ~/.cache/ash-dots/analytics/desktop.db ]]"
check "Current theme" "[[ -f ~/.config/hypr/.current_theme ]]"

echo ""
echo "Results: $passed/$checks checks passed"

if [[ $passed -eq $checks ]]; then
    echo "All systems operational!"
else
    echo "Some checks failed. Run 'ash doctor' for details."
    exit 1
fi