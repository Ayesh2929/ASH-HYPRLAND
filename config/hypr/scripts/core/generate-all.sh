#!/bin/bash
set -euo pipefail

echo "Generating all configurations..."

# Generate themes
~/.config/hypr/scripts/core/generate-themes.sh

# Create wallpaper directories
mkdir -p ~/Pictures/wallpapers/{dawn,morning,afternoon,sunset,evening,night}/{clear,cloudy,rainy,snowy,foggy}

echo "All configurations generated"