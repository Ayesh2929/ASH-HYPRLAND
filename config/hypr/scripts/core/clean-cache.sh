#!/bin/bash
set -euo pipefail

echo "Cleaning caches..."

# Pacman cache
paccache -r -k 2 2>/dev/null || true
paccache -ruk0 2>/dev/null || true

# Yay/Paru cache
paru -Sc --noconfirm 2>/dev/null || yay -Sc --noconfirm 2>/dev/null || true

# Pip cache
pip cache purge 2>/dev/null || true

# NPM cache
npm cache clean --force 2>/dev/null || true

# Cargo cache
cargo clean 2>/dev/null || true

# Go cache
go clean -cache 2>/dev/null || true

# Docker
docker system prune -f 2>/dev/null || true

# Journal
journalctl --vacuum-time=7d 2>/dev/null || true

# Thumbnails
rm -rf ~/.cache/thumbnails/* 2>/dev/null || true

echo "Caches cleaned"