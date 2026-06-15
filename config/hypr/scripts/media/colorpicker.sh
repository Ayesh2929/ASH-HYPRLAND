#!/bin/bash
set -euo pipefail

color=$(hyprpicker -a 2>/dev/null) || exit 1
echo "$color" | wl-copy
notify-send "Color picked" "$color" -i color-select