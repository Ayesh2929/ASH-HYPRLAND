#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Waybar Script: NVIDIA GPU Monitor                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

if ! command -v nvidia-smi &>/dev/null; then
    echo '{"text":"","tooltip":"nvidia-smi not found","class":"unavailable"}'
    exit 0
fi

# Query all metrics in one call
DATA=$(nvidia-smi \
    --query-gpu=\
name,\
utilization.gpu,\
utilization.memory,\
memory.used,\
memory.total,\
temperature.gpu,\
power.draw,\
power.limit,\
clocks.current.graphics,\
clocks.current.memory,\
fan.speed \
    --format=csv,noheader,nounits 2>/dev/null | head -1) || {
    echo '{"text":"󰾲 err","tooltip":"GPU query failed","class":"error"}'
    exit 0
}

IFS=',' read -r \
    GPU_NAME UTIL MEM_UTIL MEM_USED MEM_TOTAL \
    TEMP POWER POWER_LIMIT CLOCK_CORE CLOCK_MEM FAN \
    <<< "$DATA"

# Trim whitespace
trim() { echo "${1// /}"; }
GPU_NAME=$(trim "$GPU_NAME")
UTIL=$(trim "$UTIL")
MEM_USED=$(trim "$MEM_USED")
MEM_TOTAL=$(trim "$MEM_TOTAL")
TEMP=$(trim "$TEMP")
POWER=$(trim "$POWER")
POWER_LIMIT=$(trim "$POWER_LIMIT")
CLOCK_CORE=$(trim "$CLOCK_CORE")
CLOCK_MEM=$(trim "$CLOCK_MEM")
FAN=$(trim "$FAN")

# Short GPU name (strip vendor prefix)
GPU_SHORT=$(echo "$GPU_NAME" | sed 's/NVIDIA //; s/GeForce //; s/RTX /RTX /; s/GTX /GTX /' | head -c 20)

# State class
CSS="good"
UTIL_INT="${UTIL%.*}"
TEMP_INT="${TEMP%.*}"
[[ "${UTIL_INT:-0}" -ge 80 ]] && CSS="warning"
[[ "${UTIL_INT:-0}" -ge 95 ]] && CSS="critical"
[[ "${TEMP_INT:-0}" -ge 80 ]] && CSS="hot"
[[ "${TEMP_INT:-0}" -ge 90 ]] && CSS="critical-hot"

# Memory usage bar
MEM_PCT=0
if [[ "$MEM_TOTAL" -gt 0 ]] 2>/dev/null; then
    MEM_PCT=$(( MEM_USED * 100 / MEM_TOTAL ))
fi

TEXT="${UTIL}% ${TEMP}°C"

TOOLTIP="󰾲 ${GPU_NAME}\n\n"
TOOLTIP+="GPU:    ${UTIL}%\n"
TOOLTIP+="Mem:    ${MEM_USED}/${MEM_TOTAL} MiB (${MEM_PCT}%)\n"
TOOLTIP+="Mem BW: ${MEM_UTIL}%\n"
TOOLTIP+="Temp:   ${TEMP}°C\n"
TOOLTIP+="Power:  ${POWER}W / ${POWER_LIMIT}W\n"
TOOLTIP+="Core:   ${CLOCK_CORE} MHz\n"
TOOLTIP+="VRAM:   ${CLOCK_MEM} MHz\n"
TOOLTIP+="Fan:    ${FAN}%\n"
TOOLTIP+="\nLeft: nvtop  Right: nvidia-settings"

TOOLTIP=$(echo "$TOOLTIP" | sed 's/\\/\\\\/g; s/"/\\"/g')
TEXT=$(echo "$TEXT" | sed 's/\\/\\\\/g; s/"/\\"/g')

printf '{"text":"%s","tooltip":"%s","class":"%s","percentage":%d}\n' \
    "$TEXT" "$TOOLTIP" "$CSS" "$UTIL_INT"