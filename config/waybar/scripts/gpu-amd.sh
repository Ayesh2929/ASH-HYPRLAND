#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Waybar Script: AMD GPU Monitor                   ║
# ║                                                                              ║
# ║  AMD GPU stats via sysfs (amdgpu driver). No external tools required.      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Find AMD GPU sysfs path ───────────────────────────────────────────────────
find_gpu_path() {
    for card in /sys/class/drm/card*/device; do
        if [[ -f "${card}/gpu_busy_percent" ]]; then
            echo "$card"
            return 0
        fi
    done
    return 1
}

GPU_PATH=$(find_gpu_path 2>/dev/null) || {
    echo '{"text":"","tooltip":"AMD GPU sysfs not found","class":"unavailable"}'
    exit 0
}

# ── Read sysfs metrics ────────────────────────────────────────────────────────
read_sysfs() { cat "${GPU_PATH}/${1}" 2>/dev/null || echo 0; }

UTIL=$(read_sysfs "gpu_busy_percent")

# VRAM
VRAM_USED=$(read_sysfs "mem_info_vram_used")
VRAM_TOTAL=$(read_sysfs "mem_info_vram_total")
VRAM_USED_MB=$(( VRAM_USED / 1024 / 1024 ))
VRAM_TOTAL_MB=$(( VRAM_TOTAL / 1024 / 1024 ))
VRAM_PCT=0
[[ "$VRAM_TOTAL" -gt 0 ]] && VRAM_PCT=$(( VRAM_USED * 100 / VRAM_TOTAL ))

# GTT (system RAM used by GPU)
GTT_USED=$(read_sysfs "mem_info_gtt_used")
GTT_TOTAL=$(read_sysfs "mem_info_gtt_total")
GTT_USED_MB=$(( GTT_USED / 1024 / 1024 ))

# Temperature (hwmon)
TEMP=0
for hwmon in "${GPU_PATH}/hwmon/hwmon"*/; do
    TEMP_RAW=$(cat "${hwmon}temp1_input" 2>/dev/null || echo 0)
    [[ "$TEMP_RAW" -gt 0 ]] && TEMP=$(( TEMP_RAW / 1000 )) && break
done

# Power (hwmon)
POWER=0
for hwmon in "${GPU_PATH}/hwmon/hwmon"*/; do
    POWER_RAW=$(cat "${hwmon}power1_average" 2>/dev/null || echo 0)
    if [[ "$POWER_RAW" -gt 0 ]]; then
        POWER=$(( POWER_RAW / 1000000 ))
        break
    fi
done

# Core clock
CLOCK="?"
CLOCK_FILE="${GPU_PATH}/pp_dpm_sclk"
if [[ -f "$CLOCK_FILE" ]]; then
    CLOCK=$(grep '\*' "$CLOCK_FILE" 2>/dev/null | awk '{print $2}' || echo "?")
fi

# GPU name
GPU_NAME="AMD GPU"
PCI_DEVICE=$(basename "$(readlink -f "${GPU_PATH}/../../")" 2>/dev/null || echo "")
if [[ -n "$PCI_DEVICE" ]]; then
    GPU_NAME=$(lspci -s "$PCI_DEVICE" 2>/dev/null | \
        grep -oP '(?<=\[).*(?=\])' | head -1 || echo "AMD GPU")
fi

# State class
CSS="good"
[[ "$UTIL" -ge 80 ]] && CSS="warning"
[[ "$UTIL" -ge 95 ]] && CSS="critical"
[[ "$TEMP" -ge 85 ]] && CSS="hot"
[[ "$TEMP" -ge 95 ]] && CSS="critical-hot"

TEXT="${UTIL}% ${TEMP}°C"

TOOLTIP="󰾲 ${GPU_NAME}\n\n"
TOOLTIP+="GPU:   ${UTIL}%\n"
TOOLTIP+="VRAM:  ${VRAM_USED_MB}/${VRAM_TOTAL_MB} MiB (${VRAM_PCT}%)\n"
TOOLTIP+="GTT:   ${GTT_USED_MB} MiB\n"
TOOLTIP+="Temp:  ${TEMP}°C\n"
TOOLTIP+="Power: ${POWER}W\n"
TOOLTIP+="Clock: ${CLOCK}\n"
TOOLTIP+="\nLeft: radeontop  Right: amdgpu_top"

TOOLTIP=$(echo "$TOOLTIP" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"text":"%s","tooltip":"%s","class":"%s","percentage":%d}\n' \
    "$TEXT" "$TOOLTIP" "$CSS" "$UTIL"