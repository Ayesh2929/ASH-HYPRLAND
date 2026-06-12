#!/bin/bash
set -euo pipefail

echo "Checking script syntax..."

scripts=(
    ~/.config/hypr/scripts/theme/smart-wallpaper.sh
    ~/.config/hypr/scripts/theme/desktop-analytics.sh
    ~/.config/hypr/scripts/theme/theme-switcher.sh
    ~/.config/hypr/scripts/media/screenshot.sh
    ~/.config/hypr/scripts/media/record.sh
    ~/.config/hypr/scripts/system/volume.sh
    ~/.config/hypr/scripts/system/brightness.sh
    ~/.config/hypr/scripts/system/lock.sh
    ~/.config/hypr/scripts/system/reload.sh
    ~/.config/hypr/scripts/health/doctor.sh
    ~/.config/hypr/scripts/core/update.sh
    ~/.config/hypr/scripts/core/backup.sh
    ~/.config/hypr/scripts/core/clean.sh
)

errors=0
for script in "${scripts[@]}"; do
    if bash -n "$script" 2>/dev/null; then
        echo "  ✅ $script"
    else
        echo "  ❌ $script (syntax error)"
        ((errors++))
    fi
done

if [[ $errors -gt 0 ]]; then
    echo "$errors syntax errors found"
    exit 1
else
    echo "All scripts have valid syntax"
fi