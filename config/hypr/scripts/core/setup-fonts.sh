#!/bin/bash
set -euo pipefail

echo "Setting up fonts..."

mkdir -p ~/.local/share/fonts

# Download JetBrains Mono Nerd Font
cd /tmp
wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -o JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono
fc-cache -fv

echo "Fonts installed"