#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  hw gpu                                                  ║
# ║  GPU info • VRAM • temperature • driver • Vulkan • VA-API • power state         ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_HW_GPU_LOADED:-}" == "1" ]] && return 0
readonly _ASH_HW_GPU_LOADED=1

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  GPU DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -ga _GPU_LIST=()
declare -gA _GPU_INFO=()

_gpu_detect_all() {
    _GPU_LIST=()
    local idx=0

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local pci_id="${line%% *}"
        local gpu_name
        gpu_name="$(printf '%s' "$line" | sed 's/^[^ ]* [^ ]* [^ ]* //')"

        _GPU_LIST+=("$pci_id")
        _GPU_INFO["${pci_id}_name"]="$gpu_name"
        _GPU_INFO["${pci_id}_idx"]="$idx"

        # Detect vendor
        local vendor
        if printf '%s' "$gpu_name" | grep -qi 'nvidia'; then
            vendor="nvidia"
        elif printf '%s' "$gpu_name" | grep -qi 'amd\|radeon'; then
            vendor="amd"
        elif printf '%s' "$gpu_name" | grep -qi 'intel\|iris'; then
            vendor="intel"
        else
            vendor="unknown"
        fi
        _GPU_INFO["${pci_id}_vendor"]="$vendor"

        (( idx++ )) || true
    done < <(lspci 2>/dev/null | grep -iE 'vga|3d|display|graphics')
}

_gpu_vram_bytes() {
    local vendor="$1"
    local pci_id="$2"

    case "$vendor" in
        nvidia)
            if command -v nvidia-smi &>/dev/null; then
                nvidia-smi --query-gpu=memory.total \
                           --format=csv,noheader,nounits 2>/dev/null | \
                awk '{printf "%d", $1 * 1048576}' | head -1
                return
            fi
            ;;
        amd)
            # sysfs VRAM
            for card_dir in /sys/class/drm/card*/; do
                local vendor_file="${card_dir}device/vendor"
                [[ -r "$vendor_file" ]] && \
                    [[ "$(cat "$vendor_file" 2>/dev/null)" == "0x1002" ]] || continue
                local vram_file="${card_dir}device/mem_info_vram_total"
                [[ -r "$vram_file" ]] && cat "$vram_file" && return
            done
            ;;
        intel)
            # iGPU: report system RAM aperture
            local aperture
            aperture="$(cat /sys/kernel/debug/dri/0/i915_gem_gtt 2>/dev/null | \
                       grep -oP '\d+ bytes' | head -1 | awk '{print $1}')"
            [[ -n "$aperture" ]] && printf '%s' "$aperture"
            ;;
    esac
    printf '0'
}

_gpu_temp_celsius() {
    local vendor="$1"

    case "$vendor" in
        nvidia)
            command -v nvidia-smi &>/dev/null && \
                nvidia-smi --query-gpu=temperature.gpu \
                           --format=csv,noheader,nounits 2>/dev/null | head -1
            ;;
        amd)
            for hwmon_dir in /sys/class/hwmon/hwmon*/; do
                local hname
                hname="$(cat "${hwmon_dir}name" 2>/dev/null || echo '')"
                [[ "$hname" =~ amdgpu|radeon ]] || continue
                local tf="${hwmon_dir}temp1_input"
                [[ -r "$tf" ]] && awk '{printf "%d", $1/1000}' "$tf" && return
            done
            ;;
        intel)
            for hwmon_dir in /sys/class/hwmon/hwmon*/; do
                local hname
                hname="$(cat "${hwmon_dir}name" 2>/dev/null || echo '')"
                [[ "$hname" =~ i915|xe ]] || continue
                local tf="${hwmon_dir}temp1_input"
                [[ -r "$tf" ]] && awk '{printf "%d", $1/1000}' "$tf" && return
            done
            ;;
    esac
}

_gpu_driver_version() {
    local vendor="$1"
    case "$vendor" in
        nvidia)
            nvidia-smi --query-gpu=driver_version \
                       --format=csv,noheader,nounits 2>/dev/null | head -1 || \
            modinfo nvidia 2>/dev/null | grep '^version:' | awk '{print $2}'
            ;;
        amd)
            printf 'amdgpu (Mesa %s)' \
                "$(pacman -Q mesa 2>/dev/null | awk '{print $2}' || \
                   dpkg -l mesa-libGL 2>/dev/null | awk '/^ii/{print $3}' || echo '?')"
            ;;
        intel)
            printf 'i915 (Mesa %s)' \
                "$(pacman -Q mesa 2>/dev/null | awk '{print $2}' || echo '?')"
            ;;
    esac
}

_gpu_power_watts() {
    local vendor="$1"
    case "$vendor" in
        nvidia)
            nvidia-smi --query-gpu=power.draw \
                       --format=csv,noheader,nounits 2>/dev/null | \
            awk '{printf "%.1f", $1}' | head -1
            ;;
        amd)
            for hwmon_dir in /sys/class/hwmon/hwmon*/; do
                local hname
                hname="$(cat "${hwmon_dir}name" 2>/dev/null || echo '')"
                [[ "$hname" =~ amdgpu ]] || continue
                local pf="${hwmon_dir}power1_average"
                [[ -r "$pf" ]] && \
                    awk '{printf "%.1f", $1/1000000}' "$pf" && return
            done
            ;;
    esac
}

_gpu_vram_used_bytes() {
    local vendor="$1"
    case "$vendor" in
        nvidia)
            nvidia-smi --query-gpu=memory.used \
                       --format=csv,noheader,nounits 2>/dev/null | \
            awk '{printf "%d", $1 * 1048576}' | head -1
            ;;
        amd)
            for card_dir in /sys/class/drm/card*/; do
                local vf="${card_dir}device/mem_info_vram_used"
                [[ -r "$vf" ]] && cat "$vf" && return
            done
            ;;
    esac
    printf '0'
}

_gpu_clock_mhz() {
    local vendor="$1"
    case "$vendor" in
        nvidia)
            nvidia-smi --query-gpu=clocks.sm \
                       --format=csv,noheader,nounits 2>/dev/null | head -1
            ;;
        amd)
            for card_dir in /sys/class/drm/card*/; do
                local cf="${card_dir}gt_cur_freq_mhz"
                [[ -r "$cf" ]] && cat "$cf" && return
                local ppclk="${card_dir}device/pp_dpm_sclk"
                [[ -r "$ppclk" ]] && \
                    grep '^\*' "$ppclk" | awk '{print $2}' | \
                    grep -oP '[0-9]+' | head -1 && return
            done
            ;;
        intel)
            local fq="${_DRM_SYSFS:-/sys/class/drm}/card*/gt_cur_freq_mhz"
            cat $fq 2>/dev/null | head -1
            ;;
    esac
}

_gpu_vulkan_info() {
    command -v vulkaninfo &>/dev/null || { echo 'vulkaninfo not installed'; return; }
    vulkaninfo --summary 2>/dev/null | \
        grep -E 'deviceName|driverVersion|apiVersion' | \
        head -6 | sed 's/^\s*//' || echo 'unavailable'
}

_gpu_vaapi_profiles() {
    command -v vainfo &>/dev/null || { echo 'vainfo not installed'; return; }
    local profile_count
    profile_count="$(vainfo 2>/dev/null | grep -c 'VAProfile' || echo 0)"
    printf '%d profiles' "$profile_count"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RENDER ONE GPU
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_gpu_render_one() {
    local pci_id="$1"
    local vendor="${_GPU_INFO[${pci_id}_vendor]}"
    local name="${_GPU_INFO[${pci_id}_name]}"

    # Vendor icon + color
    local icon color
    case "$vendor" in
        nvidia) icon="🟢"; color="$(_hw_green)"  ;;
        amd)    icon="🔴"; color="$(_hw_peach)"  ;;
        intel)  icon="🔵"; color="$(_hw_blue)"   ;;
        *)      icon="🔧"; color="$(_hw_dim)"    ;;
    esac

    hw_section "${icon}" "GPU  [${pci_id}]" "$color"
    printf '\n  '
    hw_badge " ${vendor^^} " "$color"
    printf '  '
    printf '%s%s%s\n\n' "$(_hw_bold)" "$name" "$(_hw_r)"

    # Driver
    local drv
    drv="$(_gpu_driver_version "$vendor")"
    hw_kv "Driver" "$drv"

    # VRAM
    local vram_total vram_used vram_pct
    vram_total="$(_gpu_vram_bytes "$vendor" "$pci_id")"
    vram_used="$( _gpu_vram_used_bytes "$vendor")"

    if [[ "$vram_total" =~ ^[0-9]+$ ]] && (( vram_total > 0 )); then
        vram_pct=$(( vram_used * 100 / vram_total ))
        hw_bar "VRAM" "$vram_pct" \
            "$(hw_human_bytes "$vram_used") / $(hw_human_bytes "$vram_total")"
    else
        hw_kv "VRAM" "Shared / Dynamic (iGPU)"
    fi

    # Temperature
    local temp
    temp="$(_gpu_temp_celsius "$vendor")"
    if [[ -n "$temp" ]]; then
        hw_temp "Temperature" "$temp" 75 90
    fi

    # Clock
    local clk
    clk="$(_gpu_clock_mhz "$vendor")"
    [[ -n "$clk" ]] && hw_kv "GPU Clock" "${clk} MHz"

    # Power
    local pwr
    pwr="$(_gpu_power_watts "$vendor")"
    [[ -n "$pwr" ]] && hw_kv "Power Draw" "${pwr}W"

    # VA-API
    hw_kv "VA-API" "$(_gpu_vaapi_profiles)"

    # Vulkan (brief)
    if command -v vulkaninfo &>/dev/null; then
        local vk_dev
        vk_dev="$(vulkaninfo --summary 2>/dev/null | \
                  grep 'deviceName' | head -1 | sed 's/.*= //')"
        hw_kv "Vulkan device" "${vk_dev:-see: ash hw gpu --vulkan}"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_hw_gpu() {
    local show_vulkan=0
    local short=0
    for arg in "${@:-}"; do
        [[ "$arg" == "--vulkan"  ]] && show_vulkan=1
        [[ "$arg" == "--short"  ]] && short=1
    done

    _gpu_detect_all

    if [[ ${#_GPU_LIST[@]} -eq 0 ]]; then
        printf '\n%s  No GPU detected via lspci%s\n' "$(_hw_yellow)" "$(_hw_r)"
        return 0
    fi

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        printf '{"gpus":[\n'
        local first=1
        for pci_id in "${_GPU_LIST[@]}"; do
            [[ $first -eq 0 ]] && printf ','
            printf '{"pci":"%s","name":"%s","vendor":"%s"}\n' \
                "$pci_id" \
                "${_GPU_INFO[${pci_id}_name]}" \
                "${_GPU_INFO[${pci_id}_vendor]}"
            first=0
        done
        printf ']}\n'
        return 0
    fi

    for pci_id in "${_GPU_LIST[@]}"; do
        if [[ $short -eq 1 ]]; then
            hw_section "🎮" "GPU" "$(_hw_green)"
            hw_kv "Name"   "${_GPU_INFO[${pci_id}_name]}"
            hw_kv "Vendor" "${_GPU_INFO[${pci_id}_vendor]}"
        else
            _gpu_render_one "$pci_id"
        fi
    done

    if [[ $show_vulkan -eq 1 ]]; then
        hw_section "🌋" "Vulkan Info" "$(_hw_teal)"
        _gpu_vulkan_info | while IFS= read -r vkline; do
            printf '  %s%s%s\n' "$(_hw_dim)" "$vkline" "$(_hw_r)"
        done
    fi

    hw_divider
}
