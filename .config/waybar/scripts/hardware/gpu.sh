#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WAYBAR GPU MODULE                            ║
# ║           AMD/NVIDIA/Intel GPU monitoring with auto-detection              ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly GPU_CACHE="${CACHE_DIR}/gpu-vendor"
readonly LOG_FILE="${CACHE_DIR}/logs/gpu.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 GPU VENDOR DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

detect_gpu_vendor() {
    if [[ -f "${GPU_CACHE}" ]]; then
        cat "${GPU_CACHE}"
        return 0
    fi

    local vendor=""

    if command -v nvidia-smi &>/dev/null; then
        vendor="nvidia"
    elif [[ -f /sys/class/drm/card0/device/vendor ]]; then
        local vendor_id
        vendor_id=$(cat /sys/class/drm/card0/device/vendor 2>/dev/null || echo "")
        case "${vendor_id}" in
            "0x1002") vendor="amd" ;;
            "0x10de") vendor="nvidia" ;;
            "0x8086") vendor="intel" ;;
            *)        vendor="unknown" ;;
        esac
    elif lspci 2>/dev/null | grep -qi "amd\|radeon"; then
        vendor="amd"
    elif lspci 2>/dev/null | grep -qi nvidia; then
        vendor="nvidia"
    elif lspci 2>/dev/null | grep -qi intel; then
        vendor="intel"
    else
        vendor="unknown"
    fi

    echo "${vendor}" > "${GPU_CACHE}"
    echo "${vendor}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 GPU METRICS
# ═══════════════════════════════════════════════════════════════════════════════

get_amd_stats() {
    local usage=0 temp=0 vram_used=0 vram_total=0 clock=0 name="AMD GPU"

    # GPU name
    name=$(lspci 2>/dev/null | grep -i "amd\|radeon" | head -1 \
        | grep -oP '(?<=: ).*' \
        | sed 's/\[.*\]//' \
        | xargs \
        || echo "AMD GPU")

    # Usage via sysfs
    local gpu_busy_path
    gpu_busy_path=$(find /sys/class/drm -name "gpu_busy_percent" 2>/dev/null | head -1)
    if [[ -n "${gpu_busy_path}" ]]; then
        usage=$(cat "${gpu_busy_path}" 2>/dev/null || echo 0)
    fi

    # Temperature via hwmon
    local temp_path
    temp_path=$(find /sys/class/hwmon -name "temp1_input" 2>/dev/null \
        | xargs -I{} sh -c 'cat "$(dirname {})/name" 2>/dev/null | grep -qi "amdgpu" && echo "{}"' \
        | head -1)
    if [[ -n "${temp_path}" ]]; then
        local raw_temp
        raw_temp=$(cat "${temp_path}" 2>/dev/null || echo 0)
        temp=$(( raw_temp / 1000 ))
    fi

    # VRAM via sysfs
    local vram_used_path vram_total_path
    vram_used_path=$(find /sys/class/drm -name "mem_info_vram_used" 2>/dev/null | head -1)
    vram_total_path=$(find /sys/class/drm -name "mem_info_vram_total" 2>/dev/null | head -1)
    if [[ -n "${vram_used_path}" ]] && [[ -n "${vram_total_path}" ]]; then
        local used_bytes total_bytes
        used_bytes=$(cat "${vram_used_path}" 2>/dev/null || echo 0)
        total_bytes=$(cat "${vram_total_path}" 2>/dev/null || echo 0)
        vram_used=$(( used_bytes / 1024 / 1024 ))
        vram_total=$(( total_bytes / 1024 / 1024 ))
    fi

    # Try radeontop for usage
    if command -v radeontop &>/dev/null && (( usage == 0 )); then
        usage=$(radeontop -d - -l 1 2>/dev/null \
            | grep -oP 'gpu \K[\d.]+' \
            | head -1 \
            | awk '{printf "%.0f", $1}' \
            || echo 0)
    fi

    echo "${usage}|${temp}|${vram_used}|${vram_total}|${clock}|${name}"
}

get_nvidia_stats() {
    local usage=0 temp=0 vram_used=0 vram_total=0 clock=0 name="NVIDIA GPU"

    if ! command -v nvidia-smi &>/dev/null; then
        echo "${usage}|${temp}|${vram_used}|${vram_total}|${clock}|${name}"
        return 0
    fi

    local smi_output
    smi_output=$(nvidia-smi \
        --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,clocks.gr,name \
        --format=csv,noheader,nounits 2>/dev/null \
        | head -1)

    if [[ -n "${smi_output}" ]]; then
        IFS=',' read -r usage temp vram_used vram_total clock name <<< "${smi_output}"
        usage=$(echo "${usage}" | xargs)
        temp=$(echo "${temp}"   | xargs)
        vram_used=$(echo "${vram_used}"   | xargs)
        vram_total=$(echo "${vram_total}" | xargs)
        clock=$(echo "${clock}" | xargs)
        name=$(echo "${name}"   | xargs)
    fi

    echo "${usage}|${temp}|${vram_used}|${vram_total}|${clock}|${name}"
}

get_intel_stats() {
    local usage=0 temp=0 vram_used=0 vram_total=0 clock=0 name="Intel GPU"

    # Intel GPU stats via sysfs
    name=$(lspci 2>/dev/null | grep -i "intel.*graphics\|UHD\|Iris" | head -1 \
        | grep -oP '(?<=: ).*' | xargs || echo "Intel GPU")

    # Temperature
    local temp_path
    temp_path=$(find /sys/class/hwmon -name "temp*_input" 2>/dev/null \
        | xargs -I{} sh -c 'cat "$(dirname {})/name" 2>/dev/null | grep -qi "i915\|intel" && echo "{}"' \
        | head -1)
    if [[ -n "${temp_path}" ]]; then
        local raw
        raw=$(cat "${temp_path}" 2>/dev/null || echo 0)
        temp=$(( raw / 1000 ))
    fi

    # intel_gpu_top for usage
    if command -v intel_gpu_top &>/dev/null; then
        usage=$(intel_gpu_top -J -s 250 2>/dev/null \
            | jq -r '.engines["Render/3D/0"].busy // 0' \
            | awk '{printf "%.0f", $1}' \
            || echo 0)
    fi

    echo "${usage}|${temp}|${vram_used}|${vram_total}|${clock}|${name}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 FORMAT OUTPUT
# ═══════════════════════════════════════════════════════════════════════════════

format_output() {
    local vendor="$1"
    local stats="$2"

    local usage temp vram_used vram_total clock name
    IFS='|' read -r usage temp vram_used vram_total clock name <<< "${stats}"

    # Trim whitespace
    usage=$(echo "${usage}" | tr -d ' ')
    temp=$(echo "${temp}"   | tr -d ' ')
    vram_used=$(echo "${vram_used}" | tr -d ' ')
    vram_total=$(echo "${vram_total}" | tr -d ' ')

    # Default to 0 if empty
    usage="${usage:-0}"
    temp="${temp:-0}"
    vram_used="${vram_used:-0}"
    vram_total="${vram_total:-0}"

    # GPU icon by vendor
    local vendor_icon
    case "${vendor}" in
        amd)    vendor_icon="󰾲" ;;
        nvidia) vendor_icon="󰾲" ;;
        intel)  vendor_icon="󱤓" ;;
        *)      vendor_icon="󰾲" ;;
    esac

    # Temperature icon
    local temp_icon
    if (( temp >= 85 ));   then temp_icon="🔥"
    elif (( temp >= 70 )); then temp_icon="🌡️"
    else                        temp_icon="❄️"
    fi

    # Class based on usage
    local class
    if (( usage >= 90 ));   then class="critical"
    elif (( usage >= 70 )); then class="warning"
    elif (( usage >= 30 )); then class="active"
    else                         class="idle"
    fi

    # VRAM display
    local vram_text=""
    if (( vram_total > 0 )); then
        vram_text="${vram_used}/${vram_total}MiB"
    fi

    # Short name (remove vendor prefix for brevity)
    local short_name
    short_name=$(echo "${name}" | sed 's/Advanced Micro Devices.*\[//' | sed 's/\]//' | xargs)

    # Tooltip
    local tooltip
    tooltip="${vendor_icon} ${short_name}\n"
    tooltip+="────────────────────\n"
    tooltip+="Usage:  ${usage}%\n"
    tooltip+="${temp_icon} Temp:  ${temp}°C\n"
    [[ -n "${vram_text}" ]] && tooltip+="VRAM:  ${vram_text}\n"
    [[ -n "${clock}" ]] && [[ "${clock}" != "0" ]] && tooltip+="Clock: ${clock}MHz\n"
    tooltip+="────────────────────\n"
    tooltip+="Vendor: ${vendor^^}"

    # Display text
    local text="${vendor_icon} ${usage}% ${temp_icon}${temp}°C"

    printf '{"text": "%s", "tooltip": "%s", "class": "%s", "percentage": %s}\n' \
        "${text}" "${tooltip}" "${class}" "${usage}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-status}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        status | "")
            local vendor
            vendor=$(detect_gpu_vendor)

            local stats=""
            case "${vendor}" in
                amd)    stats=$(get_amd_stats) ;;
                nvidia) stats=$(get_nvidia_stats) ;;
                intel)  stats=$(get_intel_stats) ;;
                *)
                    printf '{"text": "󰾲 N/A", "class": "unknown", "tooltip": "GPU not detected"}\n'
                    exit 0
                    ;;
            esac

            format_output "${vendor}" "${stats}"
            ;;

        vendor)
            detect_gpu_vendor
            ;;

        reset-cache)
            rm -f "${GPU_CACHE}"
            echo "GPU vendor cache cleared"
            ;;

        *)
            echo "Usage: gpu.sh [status|vendor|reset-cache]"
            exit 1
            ;;
    esac
}

main "$@"