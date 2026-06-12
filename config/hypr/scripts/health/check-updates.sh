#!/bin/bash
set -euo pipefail

echo "Checking for updates..."

# Pacman
pacman_updates=$(checkupdates 2>/dev/null | wc -l)
echo "Pacman: $pacman_updates updates"

# AUR
if command -v paru &>/dev/null; then
    aur_updates=$(paru -Qua 2>/dev/null | wc -l)
    echo "AUR: $aur_updates updates"
fi

# Flatpak
if command -v flatpak &>/dev/null; then
    flatpak_updates=$(flatpak remote-ls --updates 2>/dev/null | wc -l)
    echo "Flatpak: $flatpak_updates updates"
fi

total=$((pacman_updates + ${aur_updates:-0} + ${flatpak_updates:-0}))
echo "Total: $total updates"

[[ $total -gt 0 ]] && exit 1 || exit 0