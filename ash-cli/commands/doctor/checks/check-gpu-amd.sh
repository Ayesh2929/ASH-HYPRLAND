#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║   █████╗ ███╗   ███╗██████╗      ██████╗ ██████╗ ██╗   ██╗                      ║
# ║  ██╔══██╗████╗ ████║██╔══██╗    ██╔════╝ ██╔══██╗██║   ██║                      ║
# ║  ███████║██╔████╔██║██║  ██║    ██║  ███╗██████╔╝██║   ██║                      ║
# ║  ██╔══██║██║╚██╔╝██║██║  ██║    ██║   ██║██╔═══╝ ██║   ██║                      ║
# ║  ██║  ██║██║ ╚═╝ ██║██████╔╝    ╚██████╔╝██║     ╚██████╔╝                      ║
# ║  ╚═╝  ╚═╝╚═╝     ╚═╝╚═════╝      ╚═════╝ ╚═╝      ╚═════╝                       ║
# ║                                                                                  ║
# ║   ██████╗ ██╗ █████╗  ██████╗ ███╗   ██╗ ██████╗ ███████╗████████╗██╗ ██████╗   ║
# ║   ██╔══██╗██║██╔══██╗██╔════╝ ████╗  ██║██╔═══██╗██╔════╝╚══██╔══╝██║██╔════╝   ║
# ║   ██║  ██║██║███████║██║  ███╗██╔██╗ ██║██║   ██║███████╗   ██║   ██║██║        ║
# ║   ██║  ██║██║██╔══██║██║   ██║██║╚██╗██║██║   ██║╚════██║   ██║   ██║██║        ║
# ║   ██████╔╝██║██║  ██║╚██████╔╝██║ ╚████║╚██████╔╝███████║   ██║   ██║╚██████╗   ║
# ║   ╚═════╝ ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝ ╚═════╝   ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  —  DOCTOR CHECK: AMD GPU                                   ║
# ║  Full AMD GPU / ROCm / AMDGPU driver deep diagnostic                            ║
# ║                                                                                  ║
# ║  Author    : ash-dotfiles                                                        ║
# ║  License   : MIT                                                                 ║
# ║  Covers    : AMDGPU driver • Mesa • Vulkan • ROCm • Wayland DMA-BUF • perf      ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CHECK_GPU_AMD_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CHECK_GPU_AMD_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 01 — AMD GPU HARDWARE DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_amd_hardware() {
    _check_header "🔴 AMD GPU Hardware"

    # ── PCI scan ────────────────────────────────────────────────────────────────
    if ! command -v lspci &>/dev/null; then
        _check_report $CHECK_WARN \
            "lspci" \
            "Not found — hardware scan limited" \
            "Install: paru -S pciutils"
    fi

    local gpu_lines
    gpu_lines="$(lspci 2>/dev/null | grep -i 'amd\|radeon\|advanced micro' | \
                 grep -i 'vga\|display\|3d\|gpu' || echo '')"

    if [[ -z "$gpu_lines" ]]; then
        _check_report $CHECK_FAIL \
            "AMD GPU detected" \
            "No AMD GPU found via lspci" \
            "If you have an AMD GPU, install pciutils: paru -S pciutils"
        return $CHECK_FAIL
    fi

    local gpu_count
    gpu_count="$(printf '%s\n' "$gpu_lines" | wc -l)"
    _check_report $CHECK_PASS \
        "AMD GPU detected" \
        "${gpu_count} AMD GPU(s) found"

    # ── Per-GPU details ─────────────────────────────────────────────────────────
    while IFS= read -r gpu_line; do
        [[ -z "$gpu_line" ]] && continue

        local pci_id gpu_name
        pci_id="$(printf '%s' "$gpu_line"  | awk '{print $1}')"
        gpu_name="$(printf '%s' "$gpu_line" | sed 's/^[^ ]* [^ ]* [^ ]* //')"

        # Classify generation
        local generation gpu_arch
        if printf '%s' "$gpu_name" | grep -qiE 'navi3|rdna3|rx 7[0-9]{3}'; then
            generation="RDNA 3  (Navi 3x)"
            gpu_arch="rdna3"
        elif printf '%s' "$gpu_name" | grep -qiE 'navi2|rdna2|rx 6[0-9]{3}'; then
            generation="RDNA 2  (Navi 2x)"
            gpu_arch="rdna2"
        elif printf '%s' "$gpu_name" | grep -qiE 'navi|rdna1|rx 5[0-9]{3}'; then
            generation="RDNA 1  (Navi)"
            gpu_arch="rdna1"
        elif printf '%s' "$gpu_name" | grep -qiE 'vega|fiji|rx 560|rx 580|rx 590|rx 480|rx 470'; then
            generation="GCN 4/5  (Vega/Polaris)"
            gpu_arch="gcn5"
        elif printf '%s' "$gpu_name" | grep -qiE 'tonga|hawaii|bonaire|kaveri|carrizo'; then
            generation="GCN 2/3  (legacy)"
            gpu_arch="gcn3"
        elif printf '%s' "$gpu_name" | grep -qiE 'tahiti|pitcairn|verde|oland'; then
            generation="GCN 1  (Southern Islands — legacy)"
            gpu_arch="gcn1"
        elif printf '%s' "$gpu_name" | grep -qiE 'rx 9[0-9]{3}|navi4|rdna4'; then
            generation="RDNA 4  (Navi 4x — newest)"
            gpu_arch="rdna4"
        else
            generation="Unknown generation"
            gpu_arch="unknown"
        fi

        _check_report $CHECK_INFO \
            "GPU [${pci_id}]" \
            "${gpu_name}"
        _check_report $CHECK_INFO \
            "  └─ Architecture" \
            "${generation}"

        # Integrated GPU warning
        if printf '%s' "$gpu_name" | grep -qiE 'radeon graphics|vega.*mobile|780m|760m|740m|680m|660m'; then
            _check_report $CHECK_INFO \
                "  └─ Type" \
                "Integrated GPU  (iGPU — no discrete VRAM)"
        else
            # Estimate VRAM from sysfs
            local vram_bytes=0
            local sysfs_gpus=()
            mapfile -t sysfs_gpus < <(
                find /sys/class/drm -name 'card*' -maxdepth 1 -type l 2>/dev/null | sort
            )
            for sysfs_card in "${sysfs_gpus[@]}"; do
                local vram_file="${sysfs_card}/device/mem_info_vram_total"
                if [[ -r "$vram_file" ]]; then
                    vram_bytes="$(cat "$vram_file" 2>/dev/null || echo 0)"
                    break
                fi
            done

            if (( vram_bytes > 0 )); then
                local vram_gb=$(( vram_bytes / 1073741824 ))
                _check_report $CHECK_INFO \
                    "  └─ VRAM" \
                    "${vram_gb}GB"
            fi
        fi

    done <<< "$gpu_lines"

    # ── DRM render nodes ────────────────────────────────────────────────────────
    local render_nodes=()
    mapfile -t render_nodes < <(
        find /dev/dri -name 'renderD*' 2>/dev/null | sort
    )

    if [[ ${#render_nodes[@]} -gt 0 ]]; then
        _check_report $CHECK_PASS \
            "DRM render nodes" \
            "${render_nodes[*]}  (${#render_nodes[@]} found)"
    else
        _check_report $CHECK_FAIL \
            "DRM render nodes" \
            "No /dev/dri/renderD* found" \
            "Check: ls -la /dev/dri  and ensure amdgpu module loaded"
    fi

    # ── DRM card nodes ──────────────────────────────────────────────────────────
    local card_nodes=()
    mapfile -t card_nodes < <(find /dev/dri -name 'card*' 2>/dev/null | sort)

    if [[ ${#card_nodes[@]} -gt 0 ]]; then
        _check_report $CHECK_PASS \
            "DRM card nodes" \
            "${card_nodes[*]}"

        # Check permissions
        for card in "${card_nodes[@]}"; do
            if [[ -r "$card" ]] && [[ -w "$card" ]]; then
                _check_report $CHECK_PASS \
                    "  └─ Permissions ${card##*/}" \
                    "Read+write OK"
            else
                local current_groups
                current_groups="$(groups 2>/dev/null | tr ' ' '|')"
                if printf '%s' "$current_groups" | grep -qiE 'video|render'; then
                    _check_report $CHECK_WARN \
                        "  └─ Permissions ${card##*/}" \
                        "No write access" \
                        "Add user to video/render group: sudo usermod -aG video,render $USER"
                else
                    _check_report $CHECK_FAIL \
                        "  └─ Permissions ${card##*/}" \
                        "User not in video/render groups" \
                        "Fix: sudo usermod -aG video,render $USER  then re-login"
                fi
            fi
        done
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 02 — KERNEL MODULE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_amd_kernel_module() {
    _check_header "🔩 Kernel Module (amdgpu)"

    # ── amdgpu loaded? ──────────────────────────────────────────────────────────
    if lsmod 2>/dev/null | grep -q '^amdgpu'; then
        local mod_size
        mod_size="$(lsmod | awk '/^amdgpu/{print $2}')"
        _check_report $CHECK_PASS \
            "amdgpu module" \
            "Loaded  (size: ${mod_size} bytes)"
    else
        _check_report $CHECK_FAIL \
            "amdgpu module" \
            "Not loaded" \
            "Load: sudo modprobe amdgpu  or add to /etc/modules-load.d/"
        return $CHECK_FAIL
    fi

    # ── radeon (old driver) — should NOT be loaded ──────────────────────────────
    if lsmod 2>/dev/null | grep -q '^radeon\b'; then
        _check_report $CHECK_WARN \
            "radeon module" \
            "Loaded alongside amdgpu — potential conflict" \
            "Blacklist radeon: echo 'blacklist radeon' | sudo tee /etc/modprobe.d/blacklist-radeon.conf"
    else
        _check_report $CHECK_PASS \
            "radeon module" \
            "Not loaded  (correct — amdgpu takes precedence)"
    fi

    # ── amdgpu module parameters ────────────────────────────────────────────────
    local amdgpu_params_dir="/sys/module/amdgpu/parameters"

    if [[ -d "$amdgpu_params_dir" ]]; then

        # dc (display core) — must be 1 for Wayland
        local dc_value
        dc_value="$(cat "${amdgpu_params_dir}/dc" 2>/dev/null || echo '?')"
        if [[ "$dc_value" == "1" ]]; then
            _check_report $CHECK_PASS \
                "amdgpu.dc" \
                "1  (Display Core enabled — required for Wayland)"
        elif [[ "$dc_value" == "0" ]]; then
            _check_report $CHECK_FAIL \
                "amdgpu.dc" \
                "0  (Display Core DISABLED)" \
                "Enable: add 'amdgpu.dc=1' to kernel parameters"
        else
            _check_report $CHECK_INFO \
                "amdgpu.dc" \
                "${dc_value}  (auto-detect)"
        fi

        # ppfeaturemask — for overclocking, fan control
        local ppfeat
        ppfeat="$(cat "${amdgpu_params_dir}/ppfeaturemask" 2>/dev/null || echo '?')"
        _check_report $CHECK_INFO \
            "amdgpu.ppfeaturemask" \
            "${ppfeat}  (0xffffffff = all features unlocked)"

        # dpm (dynamic power management)
        local dpm
        dpm="$(cat "${amdgpu_params_dir}/dpm" 2>/dev/null || echo '?')"
        if [[ "$dpm" == "1" ]] || [[ "$dpm" == "-1" ]]; then
            _check_report $CHECK_PASS \
                "amdgpu.dpm" \
                "${dpm}  (Dynamic Power Management active)"
        else
            _check_report $CHECK_WARN \
                "amdgpu.dpm" \
                "${dpm}  (DPM state unknown)" \
                "Ensure DPM is not disabled in kernel params"
        fi

        # si_support / cik_support for legacy cards
        for legacy_param in si_support cik_support; do
            local lv
            lv="$(cat "${amdgpu_params_dir}/${legacy_param}" 2>/dev/null || echo '')"
            [[ -z "$lv" ]] && continue
            _check_report $CHECK_INFO \
                "amdgpu.${legacy_param}" \
                "${lv}  (legacy GPU support)"
        done

        # reset_method (important for GPU passthrough and stability)
        local reset_method
        reset_method="$(cat "${amdgpu_params_dir}/reset_method" 2>/dev/null || echo '?')"
        _check_report $CHECK_INFO \
            "amdgpu.reset_method" \
            "${reset_method}"

    else
        _check_report $CHECK_INFO \
            "Module parameters" \
            "/sys/module/amdgpu/parameters not accessible"
    fi

    # ── Firmware blobs ──────────────────────────────────────────────────────────
    _chk_amd_firmware
}

_chk_amd_firmware() {
    local fw_dir="/lib/firmware/amdgpu"

    if [[ -d "$fw_dir" ]]; then
        local fw_count
        fw_count="$(find "$fw_dir" -name '*.bin' 2>/dev/null | wc -l)"
        _check_report $CHECK_PASS \
            "AMDGPU firmware blobs" \
            "${fw_count} .bin files in ${fw_dir}"
    else
        _check_report $CHECK_FAIL \
            "AMDGPU firmware blobs" \
            "Missing: ${fw_dir}" \
            "Install: paru -S linux-firmware"
    fi

    # ── Firmware load errors in dmesg ──────────────────────────────────────────
    local fw_errors
    fw_errors="$(dmesg 2>/dev/null | grep -i 'amdgpu.*firmware.*fail\|failed to load.*amdgpu' \
                 | tail -3 || echo '')"
    if [[ -n "$fw_errors" ]]; then
        _check_report $CHECK_FAIL \
            "Firmware load errors" \
            "$(printf '%s' "$fw_errors" | head -1)" \
            "Update linux-firmware: paru -S linux-firmware"
    else
        _check_report $CHECK_PASS \
            "Firmware load errors" \
            "None detected in dmesg"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 03 — MESA / OPENGL / VULKAN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_amd_mesa() {
    _check_header "🟠 Mesa / OpenGL / Vulkan Stack"

    # ── Mesa version ────────────────────────────────────────────────────────────
    if command -v glxinfo &>/dev/null && [[ -n "${DISPLAY:-}" ]]; then
        local mesa_ver
        mesa_ver="$(glxinfo 2>/dev/null | grep 'OpenGL version' | head -1 | \
                    grep -oP 'Mesa [\d.]+' || echo '')"

        if [[ -n "$mesa_ver" ]]; then
            local mesa_num
            mesa_num="$(printf '%s' "$mesa_ver" | grep -oP '[\d.]+')"
            local mesa_major="${mesa_num%%.*}"

            if (( mesa_major >= 24 )); then
                _check_report $CHECK_PASS \
                    "Mesa version" \
                    "${mesa_ver}  (bleeding edge — excellent)"
            elif (( mesa_major >= 23 )); then
                _check_report $CHECK_PASS \
                    "Mesa version" \
                    "${mesa_ver}  (current stable)"
            elif (( mesa_major >= 22 )); then
                _check_report $CHECK_WARN \
                    "Mesa version" \
                    "${mesa_ver}  (older — update recommended)" \
                    "Update: paru -Su mesa"
            else
                _check_report $CHECK_FAIL \
                    "Mesa version" \
                    "${mesa_ver}  (too old — many features missing)" \
                    "Update: paru -Su mesa"
            fi
        else
            _check_report $CHECK_WARN \
                "Mesa version" \
                "Could not parse via glxinfo" \
                "Check: glxinfo | grep Mesa"
        fi
    else
        # Try package manager query
        local mesa_pkg_ver
        if command -v pacman &>/dev/null; then
            mesa_pkg_ver="$(pacman -Q mesa 2>/dev/null | awk '{print $2}' || echo '')"
        elif command -v rpm &>/dev/null; then
            mesa_pkg_ver="$(rpm -q mesa-libGL 2>/dev/null || echo '')"
        fi

        if [[ -n "${mesa_pkg_ver:-}" ]]; then
            _check_report $CHECK_INFO \
                "Mesa version" \
                "${mesa_pkg_ver}  (from package manager — glxinfo unavailable)"
        else
            _check_report $CHECK_INFO \
                "Mesa version" \
                "Cannot determine — install mesa-utils"
        fi
    fi

    # ── RADV (AMD Vulkan) ───────────────────────────────────────────────────────
    if command -v vulkaninfo &>/dev/null; then
        local vulkan_out
        vulkan_out="$(vulkaninfo --summary 2>/dev/null || true)"

        if printf '%s' "$vulkan_out" | grep -qi 'radv\|amd'; then
            local radv_ver
            radv_ver="$(printf '%s' "$vulkan_out" | \
                        grep -i 'driverVersion\|apiVersion' | head -2 | \
                        tr '\n' '  ' | sed 's/  */ /g')"
            _check_report $CHECK_PASS \
                "RADV Vulkan driver" \
                "Active  •  ${radv_ver}"
        else
            _check_report $CHECK_WARN \
                "RADV Vulkan driver" \
                "AMD GPU not detected as Vulkan device" \
                "Install: paru -S vulkan-radeon"
        fi
    else
        _check_report $CHECK_INFO \
            "Vulkan info" \
            "vulkaninfo not found" \
            "Install: paru -S vulkan-tools"
    fi

    # ── AMDVLK (alternative Vulkan) ────────────────────────────────────────────
    if [[ -f /usr/share/vulkan/icd.d/amd_icd64.json ]] || \
       [[ -f /usr/share/vulkan/icd.d/amd_pro_icd64.json ]]; then
        _check_report $CHECK_INFO \
            "AMDVLK Vulkan" \
            "Detected alongside RADV — both active" \
            "RADV is usually preferred for gaming: AMD_VULKAN_ICD=RADV"
    else
        _check_report $CHECK_PASS \
            "AMDVLK Vulkan" \
            "Not installed  (RADV-only — clean setup)"
    fi

    # ── vulkan-radeon ICD ───────────────────────────────────────────────────────
    local radv_icd="/usr/share/vulkan/icd.d/radeon_icd.x86_64.json"
    if [[ -f "$radv_icd" ]]; then
        _check_report $CHECK_PASS \
            "RADV ICD manifest" \
            "$radv_icd"
    else
        _check_report $CHECK_FAIL \
            "RADV ICD manifest" \
            "Missing: ${radv_icd}" \
            "Install: paru -S vulkan-radeon"
    fi

    # ── OpenGL renderer ─────────────────────────────────────────────────────────
    if command -v glxinfo &>/dev/null && [[ -n "${DISPLAY:-}" ]]; then
        local gl_renderer
        gl_renderer="$(glxinfo 2>/dev/null | grep 'OpenGL renderer' | \
                       sed 's/OpenGL renderer string: //')"
        if [[ -n "$gl_renderer" ]]; then
            if printf '%s' "$gl_renderer" | grep -qiE 'llvmpipe|softpipe'; then
                _check_report $CHECK_FAIL \
                    "OpenGL renderer" \
                    "${gl_renderer}" \
                    "Software rendering! GPU driver not working — check amdgpu module"
            else
                _check_report $CHECK_PASS \
                    "OpenGL renderer" \
                    "${gl_renderer}"
            fi
        fi
    fi

    # ── VA-API (video acceleration) ─────────────────────────────────────────────
    _chk_amd_vaapi
}

_chk_amd_vaapi() {
    if command -v vainfo &>/dev/null; then
        local vainfo_out
        vainfo_out="$(vainfo 2>/dev/null || true)"

        if printf '%s' "$vainfo_out" | grep -qi 'radeonsi\|amdgpu\|radv'; then
            local va_profiles
            va_profiles="$(printf '%s' "$vainfo_out" | \
                           grep -c 'VAProfile' 2>/dev/null || echo '0')"
            _check_report $CHECK_PASS \
                "VA-API acceleration" \
                "${va_profiles} profiles  (video decode/encode via GPU)"
        else
            _check_report $CHECK_WARN \
                "VA-API acceleration" \
                "AMD VA-API not working" \
                "Install: paru -S libva-mesa-driver mesa-vdpau"
        fi
    else
        _check_report $CHECK_INFO \
            "VA-API check" \
            "vainfo not found" \
            "Install for video accel check: paru -S libva-utils"
    fi

    # ── VDPAU ──────────────────────────────────────────────────────────────────
    if [[ -f /usr/lib/vdpau/libvdpau_radeonsi.so ]] || \
       [[ -f /usr/lib64/vdpau/libvdpau_radeonsi.so ]]; then
        _check_report $CHECK_PASS \
            "VDPAU (mesa-vdpau)" \
            "libvdpau_radeonsi.so present"
    else
        _check_report $CHECK_INFO \
            "VDPAU" \
            "mesa-vdpau not installed" \
            "Install: paru -S mesa-vdpau"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 04 — WAYLAND / DMA-BUF INTEGRATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_amd_wayland() {
    _check_header "🌊 Wayland / DMA-BUF Integration"

    # ── LIBVA_DRIVER_NAME ───────────────────────────────────────────────────────
    local libva_driver="${LIBVA_DRIVER_NAME:-}"
    if [[ "$libva_driver" == "radeonsi" ]]; then
        _check_report $CHECK_PASS \
            "LIBVA_DRIVER_NAME" \
            "radeonsi"
    else
        _check_report $CHECK_INFO \
            "LIBVA_DRIVER_NAME" \
            "${libva_driver:-not set}" \
            "Recommended: export LIBVA_DRIVER_NAME=radeonsi"
    fi

    # ── WLR_RENDERER ────────────────────────────────────────────────────────────
    local wlr_renderer="${WLR_RENDERER:-}"
    if [[ -z "$wlr_renderer" ]]; then
        _check_report $CHECK_PASS \
            "WLR_RENDERER" \
            "Auto-detect  (vulkan preferred by Hyprland)"
    elif [[ "$wlr_renderer" == "vulkan" ]]; then
        _check_report $CHECK_PASS \
            "WLR_RENDERER" \
            "vulkan  (explicitly forced — good)"
    else
        _check_report $CHECK_INFO \
            "WLR_RENDERER" \
            "$wlr_renderer"
    fi

    # ── WLR_NO_HARDWARE_CURSORS ─────────────────────────────────────────────────
    local hw_cursors="${WLR_NO_HARDWARE_CURSORS:-0}"
    if [[ "$hw_cursors" == "1" ]]; then
        _check_report $CHECK_INFO \
            "WLR_NO_HARDWARE_CURSORS" \
            "1  (hardware cursors disabled — fallback mode)" \
            "Remove if cursor glitch is fixed — hardware cursors are faster"
    else
        _check_report $CHECK_PASS \
            "WLR_NO_HARDWARE_CURSORS" \
            "0  (hardware cursors enabled — optimal)"
    fi

    # ── DMA-BUF ─────────────────────────────────────────────────────────────────
    local dmabuf_heaps=()
    mapfile -t dmabuf_heaps < <(find /dev/dma_heap -type c 2>/dev/null | sort)

    if [[ ${#dmabuf_heaps[@]} -gt 0 ]]; then
        _check_report $CHECK_PASS \
            "DMA-BUF heaps" \
            "${dmabuf_heaps[*]}"
    else
        _check_report $CHECK_INFO \
            "DMA-BUF heaps" \
            "No /dev/dma_heap entries  (normal on some kernels)"
    fi

    # ── Screen capture / PipeWire DMA-BUF ───────────────────────────────────────
    if pgrep -x pipewire &>/dev/null; then
        _check_report $CHECK_PASS \
            "PipeWire running" \
            "Required for screen capture in Wayland"

        if pgrep -x wireplumber &>/dev/null; then
            _check_report $CHECK_PASS \
                "WirePlumber running" \
                "Session manager active"
        else
            _check_report $CHECK_WARN \
                "WirePlumber" \
                "Not running" \
                "Start: systemctl --user start wireplumber"
        fi
    else
        _check_report $CHECK_FAIL \
            "PipeWire" \
            "Not running — screen capture will not work" \
            "Enable: systemctl --user enable --now pipewire"
    fi

    # ── Hyprland render backend ─────────────────────────────────────────────────
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && \
       command -v hyprctl &>/dev/null; then
        local render_backend
        render_backend="$(hyprctl getoption general:renderer 2>/dev/null | \
                         grep 'str:' | awk '{print $2}' || echo 'auto')"
        _check_report $CHECK_INFO \
            "Hyprland renderer" \
            "${render_backend}"

        # Check for tearing support (RDNA 2+)
        local allow_tearing
        allow_tearing="$(hyprctl getoption general:allow_tearing -j 2>/dev/null | \
                        python3 -c 'import sys,json; d=json.load(sys.stdin); \
                        print(d.get("int",0))' 2>/dev/null || echo '0')"
        if [[ "$allow_tearing" == "1" ]]; then
            _check_report $CHECK_INFO \
                "Allow tearing" \
                "Enabled  (lower latency for gaming — requires RDNA 2+)"
        else
            _check_report $CHECK_INFO \
                "Allow tearing" \
                "Disabled  (VSync mode)"
        fi
    fi

    # ── FreeSync / VRR ──────────────────────────────────────────────────────────
    local vrr_capable=0
    for card_dir in /sys/class/drm/card*/; do
        if [[ -f "${card_dir}device/vendor" ]]; then
            local vendor
            vendor="$(cat "${card_dir}device/vendor" 2>/dev/null || echo '')"
            if [[ "$vendor" == "0x1002" ]]; then   # AMD vendor ID
                if [[ -f "${card_dir}vrr_capable" ]]; then
                    local vrr_val
                    vrr_val="$(cat "${card_dir}vrr_capable" 2>/dev/null || echo '0')"
                    [[ "$vrr_val" == "1" ]] && vrr_capable=1
                fi
            fi
        fi
    done

    if [[ $vrr_capable -eq 1 ]]; then
        _check_report $CHECK_PASS \
            "FreeSync / VRR" \
            "Display is VRR-capable" \
            "Enable in hyprland.conf: monitor=...,vrr,1"
    else
        _check_report $CHECK_INFO \
            "FreeSync / VRR" \
            "Display does not report VRR capability (or none connected)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 05 — PERFORMANCE / POWER MANAGEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_amd_power() {
    _check_header "⚡ AMD GPU Power Management"

    # ── amdgpu sysfs for first AMD card ─────────────────────────────────────────
    local amd_hwmon=""
    local amd_sysfs=""

    for card_dir in /sys/class/drm/card*/; do
        [[ -f "${card_dir}device/vendor" ]] || continue
        local vendor
        vendor="$(cat "${card_dir}device/vendor" 2>/dev/null || echo '')"
        if [[ "$vendor" == "0x1002" ]]; then
            amd_sysfs="${card_dir}device"
            break
        fi
    done

    # Find hwmon for GPU temp
    if [[ -n "$amd_sysfs" ]]; then
        for hwmon_dir in "${amd_sysfs}"/hwmon/hwmon*/; do
            [[ -d "$hwmon_dir" ]] && amd_hwmon="$hwmon_dir" && break
        done
    fi

    # ── Power profile ───────────────────────────────────────────────────────────
    local power_profile_file="${amd_sysfs:-}/power_dpm_force_performance_level"
    if [[ -r "$power_profile_file" ]]; then
        local power_level
        power_level="$(cat "$power_profile_file" 2>/dev/null || echo '?')"
        case "$power_level" in
            auto)
                _check_report $CHECK_PASS \
                    "Power DPM level" \
                    "auto  (optimal for most use cases)"
                ;;
            high|manual)
                _check_report $CHECK_INFO \
                    "Power DPM level" \
                    "${power_level}  (maximum performance — high power draw)"
                ;;
            low)
                _check_report $CHECK_INFO \
                    "Power DPM level" \
                    "low  (battery saving)"
                ;;
            *)
                _check_report $CHECK_INFO \
                    "Power DPM level" \
                    "$power_level"
                ;;
        esac
    else
        _check_report $CHECK_INFO \
            "Power DPM level" \
            "Not accessible via sysfs"
    fi

    # ── Current power state ─────────────────────────────────────────────────────
    local power_state_file="${amd_sysfs:-}/power_state"
    if [[ -r "$power_state_file" ]]; then
        local power_state
        power_state="$(cat "$power_state_file" 2>/dev/null | head -1 || echo '?')"
        _check_report $CHECK_INFO \
            "Current power state" \
            "$power_state"
    fi

    # ── GPU temperature ─────────────────────────────────────────────────────────
    if [[ -n "$amd_hwmon" ]]; then
        local temp_input_file="${amd_hwmon}temp1_input"
        if [[ -r "$temp_input_file" ]]; then
            local temp_mc
            temp_mc="$(cat "$temp_input_file" 2>/dev/null || echo '0')"
            local temp_c=$(( temp_mc / 1000 ))
            local temp_crit_file="${amd_hwmon}temp1_crit"
            local temp_crit=95
            [[ -r "$temp_crit_file" ]] && \
                temp_crit=$(( $(cat "$temp_crit_file" 2>/dev/null || echo 95000) / 1000 ))

            local temp_warn=$(( temp_crit - 15 ))

            if (( temp_c >= temp_crit )); then
                _check_report $CHECK_FAIL \
                    "GPU temperature" \
                    "${temp_c}°C  (CRITICAL! Throttling imminent)" \
                    "Check cooling — clean dust, reapply thermal paste"
            elif (( temp_c >= temp_warn )); then
                _check_report $CHECK_WARN \
                    "GPU temperature" \
                    "${temp_c}°C  (hot — near critical ${temp_crit}°C)" \
                    "Monitor temps: watch -n1 cat ${temp_input_file}"
            elif (( temp_c >= 60 )); then
                _check_report $CHECK_INFO \
                    "GPU temperature" \
                    "${temp_c}°C  (warm — normal under load)"
            else
                _check_report $CHECK_PASS \
                    "GPU temperature" \
                    "${temp_c}°C  (cool)"
            fi
        fi

        # ── Fan speed ──────────────────────────────────────────────────────────
        local fan_input_file="${amd_hwmon}fan1_input"
        if [[ -r "$fan_input_file" ]]; then
            local fan_rpm
            fan_rpm="$(cat "$fan_input_file" 2>/dev/null || echo '0')"
            _check_report $CHECK_INFO \
                "GPU fan speed" \
                "${fan_rpm} RPM"
        fi

        # ── Power draw (watts) ─────────────────────────────────────────────────
        local power_avg_file="${amd_hwmon}power1_average"
        local power_cap_file="${amd_hwmon}power1_cap"
        if [[ -r "$power_avg_file" ]]; then
            local power_uw cap_uw
            power_uw="$(cat "$power_avg_file" 2>/dev/null || echo '0')"
            cap_uw="$(cat "$power_cap_file" 2>/dev/null || echo '0')"
            local power_w=$(( power_uw / 1000000 ))
            local cap_w=$(( cap_uw / 1000000 ))
            _check_report $CHECK_INFO \
                "GPU power draw" \
                "${power_w}W  /  ${cap_w}W TDP"
        fi
    else
        _check_report $CHECK_INFO \
            "GPU sensors" \
            "hwmon sysfs not found — cannot read temps/power"
    fi

    # ── Clock frequencies ───────────────────────────────────────────────────────
    local pp_od_file="${amd_sysfs:-}/pp_dpm_sclk"
    if [[ -r "$pp_od_file" ]]; then
        local active_clock
        active_clock="$(grep '^\*' "$pp_od_file" 2>/dev/null | tail -1 | \
                       awk '{print $2}' || echo '?')"
        _check_report $CHECK_INFO \
            "GPU clock (active)" \
            "${active_clock:-auto}"
    fi

    # ── Memory clock ────────────────────────────────────────────────────────────
    local pp_mclk_file="${amd_sysfs:-}/pp_dpm_mclk"
    if [[ -r "$pp_mclk_file" ]]; then
        local active_mclk
        active_mclk="$(grep '^\*' "$pp_mclk_file" 2>/dev/null | tail -1 | \
                      awk '{print $2}' || echo '?')"
        _check_report $CHECK_INFO \
            "VRAM clock (active)" \
            "${active_mclk:-auto}"
    fi

    # ── VRAM usage ─────────────────────────────────────────────────────────────
    if [[ -n "$amd_sysfs" ]]; then
        local vram_used_file="${amd_sysfs}/mem_info_vram_used"
        local vram_total_file="${amd_sysfs}/mem_info_vram_total"

        if [[ -r "$vram_used_file" ]] && [[ -r "$vram_total_file" ]]; then
            local vram_used_bytes vram_total_bytes
            vram_used_bytes="$(cat "$vram_used_file" 2>/dev/null || echo 0)"
            vram_total_bytes="$(cat "$vram_total_file" 2>/dev/null || echo 1)"
            local vram_used_mb=$(( vram_used_bytes / 1048576 ))
            local vram_total_mb=$(( vram_total_bytes / 1048576 ))
            local vram_pct=$(( vram_used_bytes * 100 / vram_total_bytes ))

            if (( vram_pct >= 90 )); then
                _check_report $CHECK_WARN \
                    "VRAM usage" \
                    "${vram_used_mb}MB / ${vram_total_mb}MB  (${vram_pct}% — VRAM pressure!)" \
                    "Reduce VRAM usage: lower texture quality or close GPU-heavy apps"
            else
                _check_report $CHECK_PASS \
                    "VRAM usage" \
                    "${vram_used_mb}MB / ${vram_total_mb}MB  (${vram_pct}%)"
            fi
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 06 — ROCm (Compute / AI)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_amd_rocm() {
    _check_header "🔵 ROCm  (GPU Compute / AI / ML)"

    # ── rocminfo ────────────────────────────────────────────────────────────────
    if command -v rocminfo &>/dev/null; then
        local rocm_out
        rocm_out="$(rocminfo 2>/dev/null | head -20 || echo '')"
        local rocm_agent_count
        rocm_agent_count="$(printf '%s' "$rocm_out" | \
                            grep -c 'Agent [0-9]' 2>/dev/null || echo '0')"
        _check_report $CHECK_PASS \
            "rocminfo" \
            "${rocm_agent_count} compute agent(s) detected"
    else
        _check_report $CHECK_INFO \
            "rocminfo" \
            "Not installed  (ROCm not set up)" \
            "Install: paru -S rocm-core rocminfo  (RDNA 2+ recommended)"
    fi

    # ── ROCm version ───────────────────────────────────────────────────────────
    local rocm_ver_file="/opt/rocm/.info/version"
    if [[ -f "$rocm_ver_file" ]]; then
        local rocm_ver
        rocm_ver="$(cat "$rocm_ver_file" 2>/dev/null || echo 'unknown')"
        _check_report $CHECK_PASS \
            "ROCm version" \
            "$rocm_ver"
    elif [[ -d /opt/rocm ]]; then
        _check_report $CHECK_INFO \
            "ROCm" \
            "/opt/rocm exists but version unknown"
    else
        _check_report $CHECK_INFO \
            "ROCm installation" \
            "Not found at /opt/rocm"
    fi

    # ── HSA (Heterogeneous System Architecture) ─────────────────────────────────
    if [[ -d /dev/kfd ]]; then
        _check_report $CHECK_PASS \
            "KFD device (/dev/kfd)" \
            "Present — GPU compute accessible"

        # Check user is in render group for KFD
        if groups 2>/dev/null | grep -qw render; then
            _check_report $CHECK_PASS \
                "render group" \
                "User is in render group — KFD accessible"
        else
            _check_report $CHECK_FAIL \
                "render group" \
                "User NOT in render group — ROCm will fail" \
                "Fix: sudo usermod -aG render $USER  then re-login"
        fi
    else
        _check_report $CHECK_INFO \
            "KFD device" \
            "/dev/kfd not present — ROCm compute unavailable"
    fi

    # ── HIP runtime ─────────────────────────────────────────────────────────────
    if command -v hipcc &>/dev/null; then
        local hip_ver
        hip_ver="$(hipcc --version 2>/dev/null | head -1 || echo 'installed')"
        _check_report $CHECK_PASS \
            "HIP compiler (hipcc)" \
            "$hip_ver"
    else
        _check_report $CHECK_INFO \
            "HIP compiler" \
            "Not installed" \
            "Install: paru -S hip-runtime-amd"
    fi

    # ── Ollama AMD support ──────────────────────────────────────────────────────
    if command -v ollama &>/dev/null; then
        local hsa_override="${HSA_OVERRIDE_GFX_VERSION:-}"
        if [[ -n "$hsa_override" ]]; then
            _check_report $CHECK_INFO \
                "Ollama / HSA override" \
                "HSA_OVERRIDE_GFX_VERSION=${hsa_override}  (compatibility mode)"
        else
            _check_report $CHECK_INFO \
                "Ollama" \
                "Installed — set HSA_OVERRIDE_GFX_VERSION if GPU not detected"
        fi
    else
        _check_report $CHECK_INFO \
            "Ollama" \
            "Not installed" \
            "Install for local AI: paru -S ollama"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 07 — GAMING & TOOLS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_amd_gaming() {
    _check_header "🎮 Gaming Tools & AMD Optimizations"

    # ── MangoHUD ────────────────────────────────────────────────────────────────
    if command -v mangohud &>/dev/null; then
        local mango_ver
        mango_ver="$(mangohud --version 2>/dev/null | head -1 || echo 'installed')"
        _check_report $CHECK_PASS \
            "MangoHUD" \
            "$mango_ver  (performance overlay)"
    else
        _check_report $CHECK_INFO \
            "MangoHUD" \
            "Not installed" \
            "Install: paru -S mangohud"
    fi

    # ── GameMode ────────────────────────────────────────────────────────────────
    if command -v gamemoded &>/dev/null; then
        _check_report $CHECK_PASS \
            "GameMode" \
            "Installed"
        if pgrep -x gamemoded &>/dev/null; then
            _check_report $CHECK_PASS \
                "  └─ gamemoded" \
                "Running"
        else
            _check_report $CHECK_INFO \
                "  └─ gamemoded" \
                "Not running  (starts on demand)"
        fi
    else
        _check_report $CHECK_INFO \
            "GameMode" \
            "Not installed" \
            "Install: paru -S gamemode"
    fi

    # ── Steam / Proton ──────────────────────────────────────────────────────────
    if command -v steam &>/dev/null; then
        _check_report $CHECK_PASS \
            "Steam" \
            "Installed"
    else
        _check_report $CHECK_INFO \
            "Steam" \
            "Not installed" \
            "Install: paru -S steam"
    fi

    # ── Lutris ──────────────────────────────────────────────────────────────────
    if command -v lutris &>/dev/null; then
        _check_report $CHECK_PASS \
            "Lutris" \
            "Installed  (multi-platform game manager)"
    else
        _check_report $CHECK_INFO \
            "Lutris" \
            "Not installed" \
            "Install: paru -S lutris"
    fi

    # ── Wine / Proton GE ────────────────────────────────────────────────────────
    if command -v wine &>/dev/null; then
        local wine_ver
        wine_ver="$(wine --version 2>/dev/null | head -1 || echo 'installed')"
        _check_report $CHECK_PASS \
            "Wine" \
            "$wine_ver"
    else
        _check_report $CHECK_INFO \
            "Wine" \
            "Not installed" \
            "Install: paru -S wine"
    fi

    # ── MESA environment variable performance tweaks ────────────────────────────
    local mesa_debug="${MESA_DEBUG:-}"
    if [[ -n "$mesa_debug" ]]; then
        _check_report $CHECK_INFO \
            "MESA_DEBUG" \
            "${mesa_debug}  (Mesa debug mode active — may hurt perf)" \
            "Unset MESA_DEBUG for production use"
    fi

    local radv_perftest="${RADV_PERFTEST:-}"
    if [[ -n "$radv_perftest" ]]; then
        _check_report $CHECK_INFO \
            "RADV_PERFTEST" \
            "${radv_perftest}  (experimental RADV features enabled)"
    fi

    local amd_vulkan_icd="${AMD_VULKAN_ICD:-}"
    if [[ "$amd_vulkan_icd" == "RADV" ]]; then
        _check_report $CHECK_PASS \
            "AMD_VULKAN_ICD" \
            "RADV  (Mesa Vulkan — preferred for gaming)"
    elif [[ "$amd_vulkan_icd" == "AMDVLK" ]]; then
        _check_report $CHECK_INFO \
            "AMD_VULKAN_ICD" \
            "AMDVLK  (AMD proprietary Vulkan)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_check_gpu_amd() {
    local mode="${1:-full}"   # quick | full | gaming | rocm

    _CHECK_PASS_COUNT=0;  _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0;  _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=();   _CHECK_WARNINGS=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n'
        printf '\033[1;38;2;250;179;135m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🔴  ASH DOCTOR — AMD GPU CHECK                          ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  Checks: hw • module • Mesa • Vulkan • Wayland • power   ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n=== ASH DOCTOR — AMD GPU CHECK ===\n'
    fi

    # ── Skip fast if no AMD GPU ─────────────────────────────────────────────────
    if ! lspci 2>/dev/null | grep -qi 'amd\|radeon'; then
        printf '\n'
        _check_report $CHECK_SKIP \
            "AMD GPU" \
            "No AMD GPU detected via lspci — skipping all AMD checks"
        _ash_check_system_summary
        return $CHECK_SKIP
    fi

    case "$mode" in
        quick)
            _chk_amd_hardware
            _chk_amd_kernel_module
            ;;
        gaming)
            _chk_amd_hardware
            _chk_amd_mesa
            _chk_amd_gaming
            ;;
        rocm)
            _chk_amd_hardware
            _chk_amd_rocm
            ;;
        full|*)
            _chk_amd_hardware
            _chk_amd_kernel_module
            _chk_amd_mesa
            _chk_amd_wayland
            _chk_amd_power
            _chk_amd_rocm
            _chk_amd_gaming
            ;;
    esac

    _ash_check_system_summary
}
