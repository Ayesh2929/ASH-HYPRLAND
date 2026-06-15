#!/bin/bash
set -euo pipefail

swayidle -w \
    timeout 300 'hyprctl dispatch dpms off' \
    timeout 600 'systemctl suspend' \
    before-sleep 'swaylock' \
    after-resume 'hyprctl dispatch dpms on'