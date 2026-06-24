#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Waybar Script: Docker Status                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# Check Docker is running
if ! systemctl is-active --quiet docker 2>/dev/null && \
   ! docker info &>/dev/null 2>&1; then
    echo '{"text":"","tooltip":"Docker: not running","class":"offline"}'
    exit 0
fi

# Count containers
RUNNING=$(   docker ps   -q           2>/dev/null | wc -l || echo 0)
TOTAL=$(     docker ps   -aq          2>/dev/null | wc -l || echo 0)
IMAGES=$(    docker image ls -q       2>/dev/null | wc -l || echo 0)
VOLUMES=$(   docker volume ls -q      2>/dev/null | wc -l || echo 0)

# Build container list
CONTAINERS=$(docker ps --format \
    "• {{.Names}} ({{.Image}}) — {{.Status}}" \
    2>/dev/null | head -8 || echo "")

# Docker system disk usage
DISK=$(docker system df --format \
    'Images: {{.ImagesSize}}  Containers: {{.ContainersSize}}' \
    2>/dev/null | head -1 || echo "N/A")

CSS="stopped"
[[ "$RUNNING" -gt 0 ]] && CSS="running"
[[ "$RUNNING" -ge 5 ]] && CSS="many-running"

TOOLTIP="󰡨 Docker\n\n"
TOOLTIP+="Running:  ${RUNNING} / ${TOTAL}\n"
TOOLTIP+="Images:   ${IMAGES}\n"
TOOLTIP+="Volumes:  ${VOLUMES}\n"
TOOLTIP+="Disk: ${DISK}\n"
if [[ -n "$CONTAINERS" ]]; then
    TOOLTIP+="\nContainers:\n${CONTAINERS}\n"
fi
TOOLTIP+="\nLeft: lazydocker  Right: docker ps"

TOOLTIP=$(echo "$TOOLTIP" | sed 's/\\/\\\\/g; s/"/\\"/g')

printf '{"text":"󰡨 %s","tooltip":"%s","class":"%s"}\n' \
    "$RUNNING" "$TOOLTIP" "$CSS"