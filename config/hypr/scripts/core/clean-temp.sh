#!/bin/bash
set -euo pipefail

echo "Cleaning temporary files..."

# /tmp
find /tmp -type f -atime +7 -delete 2>/dev/null || true

# User temp
rm -rf ~/.cache/tmp/* 2>/dev/null || true

# Trash
rm -rf ~/.local/share/Trash/* 2>/dev/null || true

# Thumbnails
rm -rf ~/.cache/thumbnails/* 2>/dev/null || true

# Fontconfig
fc-cache -f 2>/dev/null || true

echo "Temporary files cleaned"