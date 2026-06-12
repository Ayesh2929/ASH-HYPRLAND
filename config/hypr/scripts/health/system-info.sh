#!/bin/bash
set -euo pipefail

echo "System Information"
echo "=================="

echo ""
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Kernel: $(uname -r)"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo ""

echo "CPU: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
echo "Cores: $(nproc)"
echo "RAM: $(free -h | grep Mem | awk '{print $2}')"
echo ""

echo "GPU: $(lspci | grep -i vga | cut -d':' -f3 | xargs)"
echo ""

echo "Disk: $(df -h / | tail -1 | awk '{print $2}')"
echo "Used: $(df -h / | tail -1 | awk '{print $3}')"
echo "Free: $(df -h / | tail -1 | awk '{print $4}')"
echo ""

echo "Hyprland: $(hyprctl version | head -1)"
echo "Waybar: $(waybar --version 2>/dev/null | head -1)"
echo "Rofi: $(rofi -v 2>&1 | head -1)"
echo "Kitty: $(kitty --version 2>/dev/null | head -1)"