#!/bin/bash
set -euo pipefail

echo "Cleaning cache..."
rm -rf ~/.cache/ash-dots/*
rm -rf ~/.cache/hypr/*
rm -rf ~/.cache/waybar/*

echo "Cleaning logs..."
journalctl --vacuum-time=7d 2>/dev/null || true

echo "Done"