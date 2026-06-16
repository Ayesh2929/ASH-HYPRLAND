#!/bin/bash
set -euo pipefail

echo "Updating fonts..."

cd /tmp
wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -o JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono
fc-cache -fv

echo "Fonts updated"