#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║   ███╗   ██╗██╗   ██╗██╗██████╗ ██╗ █████╗                                     ║
# ║   ████╗  ██║██║   ██║██║██╔══██╗██║██╔══██╗                                    ║
# ║   ██╔██╗ ██║██║   ██║██║██║  ██║██║███████║                                    ║
# ║   ██║╚██╗██║╚██╗ ██╔╝██║██║  ██║██║██╔══██║                                    ║
# ║   ██║ ╚████║ ╚████╔╝ ██║██████╔╝██║██║  ██║                                    ║
# ║   ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═╝                                    ║
# ║                                                                                  ║
# ║   ██╗    ██╗ █████╗ ██╗   ██╗██╗      █████╗ ███╗   ██╗██████╗                  ║
# ║   ██║    ██║██╔══██╗╚██╗ ██╔╝██║     ██╔══██╗████╗  ██║██╔══██╗                 ║
# ║   ██║ █╗ ██║███████║ ╚████╔╝ ██║     ███████║██╔██╗ ██║██║  ██║                 ║
# ║   ██║███╗██║██╔══██║  ╚██╔╝  ██║     ██╔══██║██║╚██╗██║██║  ██║                 ║
# ║   ╚███╔███╔╝██║  ██║   ██║   ███████╗██║  ██║██║ ╚████║██████╔╝                 ║
# ║    ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝                  ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  —  DOCTOR CHECK: NVIDIA GPU                                ║
# ║  Full NVIDIA driver · Wayland · PRIME · CUDA · performance diagnostic           ║
# ║                                                                                  ║
# ║  Author    : ash-dotfiles                                                        ║
# ║  License   : MIT                                                                 ║
# ║  Covers    : nvidia-dkms • NvAPI • Wayland EGL • PRIME • CUDA • power           ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CHECK_GPU_NVIDIA_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CHECK_GPU_NVIDIA_LOADED=1

# Sourced as a library by _common.sh, so shell options are only
# tightened when this file is EXECUTED directly. A sourced file that
# sets -e/-u rewrites the options of whoever loaded it — the first
# module would make the whole doctor process abort on any non-zero
# status or unset variable.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
fi
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELPERS — NVIDIA-SMI CACHED OUTPUT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g _NVIDIA_SMI_CACHE=""
declare -g _NVIDIA_SMI_AVAILABLE=0

_nvidia_smi_init() {
    if command -v nvidia-smi &>/dev/null; then
        _NVIDIA_SMI_CACHE="$(nvidia-smi 2>/dev/null || echo '')"
        [[ -n "$_NVIDIA_SMI_CACHE" ]] && _NVIDIA_SMI_AVAILABLE=1
    fi
}

# Query nvidia-smi with csv format (cached)
_nvidia_query() {
    local query="$1"
    local unit="${2:+--unit=${2}}"

    if [[ $_NVIDIA_SMI_AVAILABLE -eq 0 ]]; then
        echo "N/A"
        return 0
    fi

    nvidia-smi \
        --query-gpu="$query" \
        --format=csv,noheader,nounits \
        $unit \
        2>/dev/null | head -1 | sed 's/^ *//; s/ *$//'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 01 — HARDWARE DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_nvidia_hardware() {
    _check_header "🟢 NVIDIA GPU Hardware"

    # ── PCI scan ────────────────────────────────────────────────────────────────
    local gpu_lines
    gpu_lines="$(lspci 2>/dev/null | grep -iE 'nvidia' | \
                 grep -iE 'vga|3d|display|video' || echo '')"

    if [[ -z "$gpu_lines" ]]; then
        _check_report $CHECK_FAIL \
            "NVIDIA GPU detected" \
            "No NVIDIA GPU found via lspci" \
            "If you have an NVIDIA GPU, install pciutils: paru -S pciutils"
        return $CHECK_FAIL
    fi

    local gpu_count
    gpu_count="$(printf '%s\n' "$gpu_lines" | wc -l)"
    _check_report $CHECK_PASS \
        "NVIDIA GPU detected" \
        "${gpu_count} NVIDIA GPU(s) found"

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local pci_id gpu_model
        pci_id="$(printf '%s' "$line"  | awk '{print $1}')"
        gpu_model="$(printf '%s' "$line" | sed 's/^[^ ]* [^ ]* [^ ]* //')"

        # Architecture classification
        local arch_label
        if   printf '%s' "$gpu_model" | grep -qiE 'RTX 50|GB[0-9]{3}'; then
            arch_label="Blackwell (RTX 50 series)"
        elif printf '%s' "$gpu_model" | grep -qiE 'RTX 40|AD[0-9]{3}'; then
            arch_label="Ada Lovelace (RTX 40 series)"
        elif printf '%s' "$gpu_model" | grep -qiE 'RTX 30|GA[0-9]{3}'; then
            arch_label="Ampere (RTX 30 series)"
        elif printf '%s' "$gpu_model" | grep -qiE 'RTX 20|TU[0-9]{3}'; then
            arch_label="Turing (RTX 20 series)"
        elif printf '%s' "$gpu_model" | grep -qiE 'GTX 16|TU1[0-9]{2}'; then
            arch_label="Turing (GTX 16 series)"
        elif printf '%s' "$gpu_model" | grep -qiE 'GTX 10|GP[0-9]{3}'; then
            arch_label="Pascal (GTX 10 series)"
        elif printf '%s' "$gpu_model" | grep -qiE 'GTX 9|GM[0-9]{3}'; then
            arch_label="Maxwell (GTX 9 series)"
        elif printf '%s' "$gpu_model" | grep -qiE 'GTX [78]|GK[0-9]'; then
            arch_label="Kepler / Maxwell (legacy)"
        else
            arch_label="Unknown architecture"
        fi

        _check_report $CHECK_INFO "GPU [${pci_id}]" "${gpu_model}"
        _check_report $CHECK_INFO "  └─ Architecture" "${arch_label}"

    done <<< "$gpu_lines"

    # ── DRM nodes ───────────────────────────────────────────────────────────────
    local nvidia_renders=()
    mapfile -t nvidia_renders < <(
        find /dev/dri -name 'renderD*' 2>/dev/null | sort
    )

    if [[ ${#nvidia_renders[@]} -gt 0 ]]; then
        _check_report $CHECK_PASS \
            "DRM render nodes" \
            "${nvidia_renders[*]}"
    else
        _check_report $CHECK_WARN \
            "DRM render nodes" \
            "None found — may indicate missing nvidia-drm.modeset=1" \
            "Add kernel param: nvidia-drm.modeset=1"
    fi

    # ── /dev/nvidia* ────────────────────────────────────────────────────────────
    local nvidia_devs=()
    mapfile -t nvidia_devs < <(find /dev -name 'nvidia*' -maxdepth 1 2>/dev/null | sort)

    if [[ ${#nvidia_devs[@]} -gt 0 ]]; then
        _check_report $CHECK_PASS \
            "/dev/nvidia* devices" \
            "${#nvidia_devs[@]} entries  (${nvidia_devs[*]})"
    else
        _check_report $CHECK_FAIL \
            "/dev/nvidia* devices" \
            "Not found — driver not loaded or modprobe failed" \
            "Try: sudo modprobe nvidia"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 02 — DRIVER & KERNEL MODULES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_nvidia_driver() {
    _check_header "🔩 NVIDIA Driver & Kernel Modules"

    # ── nvidia-smi ──────────────────────────────────────────────────────────────
    if command -v nvidia-smi &>/dev/null; then
        local smi_ver
        smi_ver="$(_nvidia_query driver.version)"
        _check_report $CHECK_PASS \
            "nvidia-smi" \
            "Driver version: ${smi_ver}"
    else
        _check_report $CHECK_FAIL \
            "nvidia-smi" \
            "Not found" \
            "Install: paru -S nvidia-utils"
        return $CHECK_FAIL
    fi

    # ── Driver version classification ────────────────────────────────────────────
    local drv_ver
    drv_ver="$(_nvidia_query driver.version)"
    local drv_major="${drv_ver%%.*}"

    if [[ "$drv_major" =~ ^[0-9]+$ ]]; then
        if (( drv_major >= 560 )); then
            _check_report $CHECK_PASS \
                "Driver generation" \
                "v${drv_ver}  (Open Kernel Module generation — recommended)"
        elif (( drv_major >= 535 )); then
            _check_report $CHECK_PASS \
                "Driver generation" \
                "v${drv_ver}  (stable — good Wayland support)"
        elif (( drv_major >= 520 )); then
            _check_report $CHECK_WARN \
                "Driver generation" \
                "v${drv_ver}  (older — update recommended)" \
                "Update: paru -Su nvidia"
        else
            _check_report $CHECK_FAIL \
                "Driver generation" \
                "v${drv_ver}  (too old — Wayland support limited)" \
                "Update: paru -Su nvidia  (requires ≥ 525 for EGL streams)"
        fi
    fi

    # ── Required kernel modules ──────────────────────────────────────────────────
    local -a required_modules=(
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
    )

    for mod in "${required_modules[@]}"; do
        if lsmod 2>/dev/null | grep -q "^${mod}\b"; then
            local mod_size
            mod_size="$(lsmod | awk -v m="$mod" '$1==m{print $2}')"
            _check_report $CHECK_PASS \
                "Module: ${mod}" \
                "Loaded  (${mod_size} bytes)"
        else
            _check_report $CHECK_FAIL \
                "Module: ${mod}" \
                "NOT loaded" \
                "Load: sudo modprobe ${mod}"
        fi
    done

    # ── nvidia_drm.modeset critical check ───────────────────────────────────────
    local modeset_val
    modeset_val="$(cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null || echo '?')"
    if [[ "$modeset_val" == "Y" ]] || [[ "$modeset_val" == "1" ]]; then
        _check_report $CHECK_PASS \
            "nvidia-drm.modeset" \
            "Y  (KMS enabled — required for Wayland)"
    elif [[ "$modeset_val" == "N" ]] || [[ "$modeset_val" == "0" ]]; then
        _check_report $CHECK_FAIL \
            "nvidia-drm.modeset" \
            "N  (KMS DISABLED — Wayland will not work properly)" \
            "Fix: add 'nvidia-drm.modeset=1' to kernel parameters in bootloader"
    else
        _check_report $CHECK_WARN \
            "nvidia-drm.modeset" \
            "Value: ${modeset_val}  (could not confirm enabled)" \
            "Check: cat /sys/module/nvidia_drm/parameters/modeset"
    fi

    # ── nouveau (open source — must NOT be loaded) ──────────────────────────────
    if lsmod 2>/dev/null | grep -q '^nouveau\b'; then
        _check_report $CHECK_FAIL \
            "nouveau module" \
            "LOADED — conflicts with proprietary NVIDIA driver" \
            "Blacklist: echo 'blacklist nouveau' | sudo tee /etc/modprobe.d/blacklist-nouveau.conf && sudo mkinitcpio -P"
    else
        _check_report $CHECK_PASS \
            "nouveau module" \
            "Not loaded  (correct)"
    fi

    # ── Open kernel module variant? ─────────────────────────────────────────────
    local nvidia_open_path
    nvidia_open_path="$(modinfo nvidia 2>/dev/null | grep -i 'filename' | \
                        grep -i 'open\|oss' | head -1 || echo '')"
    if [[ -n "$nvidia_open_path" ]]; then
        _check_report $CHECK_INFO \
            "Kernel module variant" \
            "Open source kernel module (nvidia-open)"
    else
        _check_report $CHECK_INFO \
            "Kernel module variant" \
            "Proprietary kernel module (nvidia-dkms)"
    fi

    # ── DKMS status ─────────────────────────────────────────────────────────────
    if command -v dkms &>/dev/null; then
        local dkms_status
        dkms_status="$(dkms status 2>/dev/null | grep -i nvidia | head -3 || echo '')"
        if [[ -n "$dkms_status" ]]; then
            local dkms_line
            dkms_line="$(printf '%s' "$dkms_status" | head -1)"
            if printf '%s' "$dkms_line" | grep -qi 'installed'; then
                _check_report $CHECK_PASS \
                    "DKMS status" \
                    "$(printf '%s' "$dkms_line" | sed 's/,/  /g')"
            else
                _check_report $CHECK_WARN \
                    "DKMS status" \
                    "$dkms_line" \
                    "Rebuild: sudo dkms autoinstall"
            fi
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 03 — WAYLAND / EGL / GBM
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_nvidia_wayland() {
    _check_header "🌊 NVIDIA Wayland / EGL / GBM Support"

    # ── GBM backend ─────────────────────────────────────────────────────────────
    local gbm_nvidia="/usr/lib/libnvidia-egl-gbm.so.1"
    local gbm_nvidia_alt="/usr/lib/x86_64-linux-gnu/libnvidia-egl-gbm.so.1"

    if [[ -f "$gbm_nvidia" ]] || [[ -f "$gbm_nvidia_alt" ]]; then
        _check_report $CHECK_PASS \
            "libnvidia-egl-gbm" \
            "Present — GBM backend for Wayland"
    else
        _check_report $CHECK_FAIL \
            "libnvidia-egl-gbm" \
            "Missing" \
            "Install: paru -S nvidia-utils  (driver ≥ 495 required)"
    fi

    # ── EGL Wayland extension ───────────────────────────────────────────────────
    local egl_wayland="/usr/lib/libnvidia-egl-wayland.so.1"
    if [[ -f "$egl_wayland" ]]; then
        _check_report $CHECK_PASS \
            "libnvidia-egl-wayland" \
            "Present — EGL Wayland streams"
    else
        _check_report $CHECK_FAIL \
            "libnvidia-egl-wayland" \
            "Missing" \
            "Install: paru -S egl-wayland"
    fi

    # ── 10_nvidia_wayland.json ICD ───────────────────────────────────────────────
    local nvidia_egl_icd
    for icd_path in \
        /usr/share/egl/egl_external_platform.d/10_nvidia_wayland.json \
        /usr/share/egl/egl_external_platform.d/15_nvidia_gbm.json; do
        if [[ -f "$icd_path" ]]; then
            _check_report $CHECK_PASS \
                "EGL platform ICD" \
                "$icd_path"
        fi
    done

    # ── Critical env vars for NVIDIA Wayland ────────────────────────────────────
    local -a nvidia_env_checks=(
        "GBM_BACKEND:nvidia-drm:Required for GBM Wayland backend"
        "__GLX_VENDOR_LIBRARY_NAME:nvidia:Required for GLX Wayland"
        "LIBVA_DRIVER_NAME:nvidia:Required for hardware video decode"
        "WLR_NO_HARDWARE_CURSORS:1:May be needed if cursor is invisible"
    )

    for env_check in "${nvidia_env_checks[@]}"; do
        IFS=':' read -r var_name expected_val hint <<< "$env_check"
        local actual_val="${!var_name:-}"

        if [[ "$actual_val" == "$expected_val" ]]; then
            _check_report $CHECK_PASS \
                "${var_name}" \
                "${actual_val}"
        elif [[ -z "$actual_val" ]]; then
            _check_report $CHECK_WARN \
                "${var_name}" \
                "not set  (expected: ${expected_val})" \
                "${hint}  — add to /etc/environment.d/nvidia.conf"
        else
            _check_report $CHECK_INFO \
                "${var_name}" \
                "${actual_val}  (expected: ${expected_val})"
        fi
    done

    # ── NVIDIA_DRIVER_CAPABILITIES ──────────────────────────────────────────────
    local nvidia_caps="${NVIDIA_DRIVER_CAPABILITIES:-}"
    if [[ -z "$nvidia_caps" ]]; then
        _check_report $CHECK_INFO \
            "NVIDIA_DRIVER_CAPABILITIES" \
            "Not set  (default: graphics,compat32,utility)"
    else
        _check_report $CHECK_INFO \
            "NVIDIA_DRIVER_CAPABILITIES" \
            "$nvidia_caps"
    fi

    # ── Hyprland NVIDIA env flags ────────────────────────────────────────────────
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        local hypr_env_conf="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/env.conf"
        if [[ -f "$hypr_env_conf" ]]; then
            local nvidia_env_count
            nvidia_env_count="$(grep -ci 'nvidia\|gbm\|__glx\|__vk' \
                               "$hypr_env_conf" 2>/dev/null || echo 0)"
            _check_report $CHECK_INFO \
                "NVIDIA entries in env.conf" \
                "${nvidia_env_count} environment variable(s) configured"
        else
            _check_report $CHECK_INFO \
                "hypr/env.conf" \
                "Not found — NVIDIA env vars may not be set"
        fi
    fi

    # ── Vulkan ICD ──────────────────────────────────────────────────────────────
    local nvidia_vk_icd
    for icd in \
        /usr/share/vulkan/icd.d/nvidia_icd.json \
        /usr/share/vulkan/icd.d/nvidia_icd.x86_64.json; do
        if [[ -f "$icd" ]]; then
            _check_report $CHECK_PASS \
                "NVIDIA Vulkan ICD" \
                "$icd"
            nvidia_vk_icd=1
            break
        fi
    done
    [[ -z "${nvidia_vk_icd:-}" ]] && \
        _check_report $CHECK_FAIL \
            "NVIDIA Vulkan ICD" \
            "Not found" \
            "Install: paru -S nvidia-utils"

    # ── GSP firmware ────────────────────────────────────────────────────────────
    local gsp_fw
    gsp_fw="$(find /lib/firmware/nvidia -name 'gsp*.bin' 2>/dev/null | head -1 || echo '')"
    if [[ -n "$gsp_fw" ]]; then
        _check_report $CHECK_PASS \
            "NVIDIA GSP firmware" \
            "$gsp_fw"
    else
        _check_report $CHECK_INFO \
            "NVIDIA GSP firmware" \
            "Not found in /lib/firmware/nvidia  (may be bundled in driver)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 04 — PRIME / OPTIMUS (Laptops)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_nvidia_prime() {
    _check_header "💡 NVIDIA PRIME / Optimus  (Hybrid GPU — Laptops)"

    # Only relevant if both Intel/AMD iGPU and NVIDIA exist
    local has_igpu=0
    lspci 2>/dev/null | grep -iE 'intel.*graphics|amd.*graphics|iris|radeon' | \
    grep -iqv 'nvidia' && has_igpu=1

    if [[ $has_igpu -eq 0 ]]; then
        _check_report $CHECK_INFO \
            "PRIME / Optimus" \
            "Single GPU system — PRIME not applicable"
        return $CHECK_PASS
    fi

    _check_report $CHECK_INFO \
        "System type" \
        "Hybrid GPU (iGPU + NVIDIA dGPU detected)"

    # ── prime-run ───────────────────────────────────────────────────────────────
    if command -v prime-run &>/dev/null; then
        _check_report $CHECK_PASS \
            "prime-run" \
            "Available  (run: prime-run <app>)"
    else
        _check_report $CHECK_INFO \
            "prime-run" \
            "Not found" \
            "Install: paru -S nvidia-prime"
    fi

    # ── offload mode vs full performance ────────────────────────────────────────
    local dgpu_power_state=""
    local dri_prime="${DRI_PRIME:-}"
    local nv_prime="${__NV_PRIME_RENDER_OFFLOAD:-}"

    if [[ "$nv_prime" == "1" ]]; then
        _check_report $CHECK_INFO \
            "PRIME render offload" \
            "Active  (__NV_PRIME_RENDER_OFFLOAD=1)"
    else
        _check_report $CHECK_INFO \
            "PRIME render offload" \
            "Not forced  (default iGPU rendering)"
    fi

    # ── Runtime D3 power management ─────────────────────────────────────────────
    local nvidia_pci_dir
    nvidia_pci_dir="$(find /sys/bus/pci/devices -name '*/power/control' \
                      2>/dev/null | xargs grep -l '' 2>/dev/null | \
                      while read -r f; do
                          local vendor
                          vendor="$(cat "${f%/power/control}/vendor" 2>/dev/null || echo '')"
                          [[ "$vendor" == "0x10de" ]] && printf '%s' "${f%/power/control}"
                      done | head -1)"

    if [[ -n "$nvidia_pci_dir" ]]; then
        local power_control
        power_control="$(cat "${nvidia_pci_dir}/power/control" 2>/dev/null || echo '?')"
        local runtime_status
        runtime_status="$(cat "${nvidia_pci_dir}/power/runtime_status" 2>/dev/null || echo '?')"

        if [[ "$power_control" == "auto" ]]; then
            _check_report $CHECK_PASS \
                "PRIME power management" \
                "auto  •  runtime: ${runtime_status}  (RTD3 — saves battery)"
        else
            _check_report $CHECK_INFO \
                "PRIME power management" \
                "power/control=${power_control}  (RTD3 not enabled)" \
                "Enable RTD3 in /etc/udev/rules.d/80-nvidia-pm.rules"
        fi
    fi

    # ── supergfxctl (ASUS laptops) ──────────────────────────────────────────────
    if command -v supergfxctl &>/dev/null; then
        local sgfx_mode
        sgfx_mode="$(supergfxctl --get 2>/dev/null || echo 'unknown')"
        _check_report $CHECK_INFO \
            "supergfxctl mode" \
            "$sgfx_mode  (ASUS GPU switcher)"
    fi

    # ── optimus-manager ─────────────────────────────────────────────────────────
    if command -v optimus-manager &>/dev/null; then
        local om_mode
        om_mode="$(optimus-manager --print-mode 2>/dev/null | \
                   grep -oP 'Current GPU mode.*' || echo 'unknown')"
        _check_report $CHECK_INFO \
            "optimus-manager" \
            "$om_mode"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 05 — PERFORMANCE & TEMPERATURES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_nvidia_performance() {
    _check_header "⚡ NVIDIA Performance & Thermals"

    if [[ $_NVIDIA_SMI_AVAILABLE -eq 0 ]]; then
        _check_report $CHECK_SKIP \
            "Performance data" \
            "nvidia-smi not available — skipping"
        return $CHECK_SKIP
    fi

    # ── Temperature ──────────────────────────────────────────────────────────────
    local temp
    temp="$(_nvidia_query temperature.gpu)"

    if [[ "$temp" =~ ^[0-9]+$ ]]; then
        if (( temp >= 90 )); then
            _check_report $CHECK_FAIL \
                "GPU temperature" \
                "${temp}°C  (CRITICAL — throttling likely)" \
                "Clean fans, reapply thermal paste, improve airflow"
        elif (( temp >= 80 )); then
            _check_report $CHECK_WARN \
                "GPU temperature" \
                "${temp}°C  (hot — near throttle threshold)"
        elif (( temp >= 65 )); then
            _check_report $CHECK_INFO \
                "GPU temperature" \
                "${temp}°C  (warm — normal under load)"
        else
            _check_report $CHECK_PASS \
                "GPU temperature" \
                "${temp}°C  (cool)"
        fi
    fi

    # ── Fan speed ────────────────────────────────────────────────────────────────
    local fan_speed
    fan_speed="$(_nvidia_query fan.speed)"
    [[ "$fan_speed" =~ ^[0-9]+$ ]] && \
        _check_report $CHECK_INFO "Fan speed" "${fan_speed}%"

    # ── Power draw ───────────────────────────────────────────────────────────────
    local power_draw power_limit
    power_draw="$(_nvidia_query power.draw)"
    power_limit="$(_nvidia_query power.limit)"

    if [[ "$power_draw" =~ ^[0-9.]+ ]] && [[ "$power_limit" =~ ^[0-9.]+ ]]; then
        local pw_int="${power_draw%.*}"
        local lim_int="${power_limit%.*}"
        local pw_pct=0
        (( lim_int > 0 )) && pw_pct=$(( pw_int * 100 / lim_int ))

        if (( pw_pct >= 95 )); then
            _check_report $CHECK_WARN \
                "Power draw" \
                "${power_draw}W / ${power_limit}W TDP  (${pw_pct}% — power limit reached)"
        else
            _check_report $CHECK_PASS \
                "Power draw" \
                "${power_draw}W / ${power_limit}W TDP  (${pw_pct}%)"
        fi
    fi

    # ── GPU & Memory utilization ─────────────────────────────────────────────────
    local gpu_util mem_util
    gpu_util="$(_nvidia_query utilization.gpu)"
    mem_util="$(_nvidia_query utilization.memory)"

    [[ "$gpu_util" =~ ^[0-9]+$ ]] && \
        _check_report $CHECK_INFO "GPU utilization" "${gpu_util}%"
    [[ "$mem_util" =~ ^[0-9]+$ ]] && \
        _check_report $CHECK_INFO "Memory utilization" "${mem_util}%"

    # ── VRAM ─────────────────────────────────────────────────────────────────────
    local vram_used vram_total
    vram_used="$(_nvidia_query memory.used)"
    vram_total="$(_nvidia_query memory.total)"

    if [[ "$vram_used" =~ ^[0-9]+$ ]] && [[ "$vram_total" =~ ^[0-9]+$ ]]; then
        local vram_pct=0
        (( vram_total > 0 )) && vram_pct=$(( vram_used * 100 / vram_total ))
        local vram_used_gb
        vram_used_gb="$(printf '%.1f' "$(echo "$vram_used / 1024" | bc -l 2>/dev/null || echo 0)")"
        local vram_total_gb
        vram_total_gb="$(printf '%.1f' "$(echo "$vram_total / 1024" | bc -l 2>/dev/null || echo 0)")"

        if (( vram_pct >= 90 )); then
            _check_report $CHECK_WARN \
                "VRAM usage" \
                "${vram_used_gb}GB / ${vram_total_gb}GB  (${vram_pct}% — VRAM pressure!)" \
                "Reduce VRAM usage or upgrade GPU"
        else
            _check_report $CHECK_PASS \
                "VRAM usage" \
                "${vram_used_gb}GB / ${vram_total_gb}GB  (${vram_pct}%)"
        fi
    fi

    # ── Clock speeds ─────────────────────────────────────────────────────────────
    local clk_sm clk_mem
    clk_sm="$(_nvidia_query clocks.sm)"
    clk_mem="$(_nvidia_query clocks.mem)"

    [[ "$clk_sm" =~ ^[0-9]+$ ]] && \
        _check_report $CHECK_INFO "GPU clock" "${clk_sm} MHz"
    [[ "$clk_mem" =~ ^[0-9]+$ ]] && \
        _check_report $CHECK_INFO "Memory clock" "${clk_mem} MHz"

    # ── Performance state (Pstate) ───────────────────────────────────────────────
    local pstate
    pstate="$(_nvidia_query pstate)"
    if [[ -n "$pstate" ]]; then
        local pstate_desc
        case "$pstate" in
            P0) pstate_desc="P0 — Maximum performance" ;;
            P8) pstate_desc="P8 — Low power (idle)" ;;
            P12) pstate_desc="P12 — Deep sleep / display only" ;;
            *) pstate_desc="$pstate" ;;
        esac
        _check_report $CHECK_INFO "Performance state" "$pstate_desc"
    fi

    # ── Persistence mode ─────────────────────────────────────────────────────────
    local persist
    persist="$(_nvidia_query persistence_mode)"
    if [[ "$persist" == "Enabled" ]]; then
        _check_report $CHECK_INFO \
            "Persistence mode" \
            "Enabled  (driver stays loaded — faster wake from idle)"
    else
        _check_report $CHECK_INFO \
            "Persistence mode" \
            "Disabled  (GPU powers down when idle)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 06 — CUDA / COMPUTE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_nvidia_cuda() {
    _check_header "🔵 CUDA / GPU Compute"

    # ── CUDA version ────────────────────────────────────────────────────────────
    local cuda_ver
    cuda_ver="$(_nvidia_query cuda_version)"

    if [[ "$cuda_ver" =~ ^[0-9.]+ ]]; then
        local cuda_major="${cuda_ver%%.*}"
        if (( cuda_major >= 12 )); then
            _check_report $CHECK_PASS \
                "CUDA version" \
                "${cuda_ver}  (current — good AI/ML support)"
        elif (( cuda_major >= 11 )); then
            _check_report $CHECK_PASS \
                "CUDA version" \
                "${cuda_ver}  (supported)"
        else
            _check_report $CHECK_WARN \
                "CUDA version" \
                "${cuda_ver}  (old — many frameworks require CUDA 11+)" \
                "Update driver: paru -Su nvidia"
        fi
    else
        _check_report $CHECK_INFO \
            "CUDA version" \
            "Cannot determine via nvidia-smi"
    fi

    # ── nvcc (CUDA compiler) ─────────────────────────────────────────────────────
    if command -v nvcc &>/dev/null; then
        local nvcc_ver
        nvcc_ver="$(nvcc --version 2>/dev/null | grep -oP 'release [\d.]+' | head -1 || echo 'installed')"
        _check_report $CHECK_PASS \
            "CUDA compiler (nvcc)" \
            "$nvcc_ver"
    else
        _check_report $CHECK_INFO \
            "CUDA compiler (nvcc)" \
            "Not installed" \
            "Install: paru -S cuda"
    fi

    # ── cuDNN ───────────────────────────────────────────────────────────────────
    local cudnn_h
    cudnn_h="$(find /usr/include /usr/local/cuda -name 'cudnn_version.h' \
               2>/dev/null | head -1 || echo '')"
    if [[ -n "$cudnn_h" ]]; then
        local cudnn_ver
        cudnn_ver="$(grep 'CUDNN_MAJOR\|CUDNN_MINOR\|CUDNN_PATCHLEVEL' "$cudnn_h" 2>/dev/null | \
                     awk '{print $3}' | tr '\n' '.' | sed 's/\.$//')"
        _check_report $CHECK_PASS \
            "cuDNN" \
            "v${cudnn_ver}  (deep learning acceleration)"
    else
        _check_report $CHECK_INFO \
            "cuDNN" \
            "Not found" \
            "Install: paru -S cudnn  (required for PyTorch/TensorFlow GPU)"
    fi

    # ── PyTorch CUDA check ────────────────────────────────────────────────────
    if command -v python3 &>/dev/null; then
        local torch_cuda
        torch_cuda="$(python3 -c \
            'import torch; print(f"PyTorch {torch.__version__} — CUDA: {torch.cuda.is_available()} — Device: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else None}")' \
            2>/dev/null || echo '')"

        if [[ -n "$torch_cuda" ]]; then
            if printf '%s' "$torch_cuda" | grep -q 'CUDA: True'; then
                _check_report $CHECK_PASS \
                    "PyTorch CUDA" \
                    "$torch_cuda"
            else
                _check_report $CHECK_WARN \
                    "PyTorch CUDA" \
                    "$torch_cuda  (no GPU access)" \
                    "Reinstall: pip install torch --index-url https://download.pytorch.org/whl/cu121"
            fi
        fi
    fi

    # ── Ollama NVIDIA ────────────────────────────────────────────────────────────
    if command -v ollama &>/dev/null; then
        local ollama_running=0
        pgrep -x ollama &>/dev/null && ollama_running=1

        if [[ $ollama_running -eq 1 ]]; then
            _check_report $CHECK_PASS \
                "Ollama" \
                "Running  (CUDA will be auto-detected)"
        else
            _check_report $CHECK_INFO \
                "Ollama" \
                "Installed but not running" \
                "Start: systemctl --user start ollama"
        fi
    fi

    # ── nvidia-container-toolkit (Docker GPU) ───────────────────────────────────
    if command -v nvidia-container-runtime &>/dev/null; then
        _check_report $CHECK_PASS \
            "nvidia-container-toolkit" \
            "Installed  (Docker/Podman GPU containers enabled)"
    else
        _check_report $CHECK_INFO \
            "nvidia-container-toolkit" \
            "Not installed" \
            "Install for GPU in Docker: paru -S nvidia-container-toolkit"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 07 — GAMING OPTIMIZATIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_nvidia_gaming() {
    _check_header "🎮 NVIDIA Gaming Optimizations"

    # ── VRR / G-Sync ────────────────────────────────────────────────────────────
    if [[ $_NVIDIA_SMI_AVAILABLE -eq 1 ]]; then
        local gsync_capable
        gsync_capable="$(nvidia-smi --query-gpu=gsp.mode.current \
                         --format=csv,noheader,nounits 2>/dev/null | head -1 || echo '')"
        _check_report $CHECK_INFO \
            "G-Sync / VRR" \
            "Check display: nvidia-settings → display config"
    fi

    # ── MangoHUD with NVIDIA backend ────────────────────────────────────────────
    if command -v mangohud &>/dev/null; then
        _check_report $CHECK_PASS \
            "MangoHUD" \
            "Installed  (will auto-detect NVIDIA via nvml)"
    else
        _check_report $CHECK_INFO \
            "MangoHUD" \
            "Not installed" \
            "Install: paru -S mangohud"
    fi

    # ── DXVK (Direct3D → Vulkan) ────────────────────────────────────────────────
    if [[ -f /usr/lib/wine/x86_64-windows/dxgi.dll.so ]] || \
       find ~/.local/share -name 'dxvk.conf' 2>/dev/null -q; then
        _check_report $CHECK_PASS \
            "DXVK" \
            "Detected"
    else
        _check_report $CHECK_INFO \
            "DXVK" \
            "Not found in system paths" \
            "Usually bundled with Proton/Wine — install: paru -S dxvk"
    fi

    # ── vkd3d-proton (DX12) ──────────────────────────────────────────────────────
    if command -v vkd3d-proton &>/dev/null || \
       find ~/.local/share -name 'd3d12.dll.so' 2>/dev/null -q; then
        _check_report $CHECK_PASS \
            "vkd3d-proton" \
            "Detected  (DirectX 12 support)"
    else
        _check_report $CHECK_INFO \
            "vkd3d-proton" \
            "Not found  (usually bundled in Proton GE)"
    fi

    # ── Shader cache location ────────────────────────────────────────────────────
    local shader_cache="${__GL_SHADER_DISK_CACHE_PATH:-$HOME/.cache/nvidia}"
    local shader_size=""
    if [[ -d "$shader_cache" ]]; then
        shader_size="$(du -sh "$shader_cache" 2>/dev/null | cut -f1)"
        _check_report $CHECK_INFO \
            "NVIDIA shader cache" \
            "${shader_cache}  (${shader_size})"
    fi

    # ── Async compute ────────────────────────────────────────────────────────────
    local async_compute="${__GL_ALLOW_ASYNC_UPLOADS:-}"
    if [[ -n "$async_compute" ]]; then
        _check_report $CHECK_INFO \
            "__GL_ALLOW_ASYNC_UPLOADS" \
            "$async_compute"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_check_gpu_nvidia() {
    local mode="${1:-full}"   # quick | full | gaming | cuda

    _CHECK_PASS_COUNT=0;  _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0;  _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=();   _CHECK_WARNINGS=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n'
        printf '\033[1;38;2;166;227;161m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🟢  ASH DOCTOR — NVIDIA GPU CHECK                       ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  Checks: hw • driver • Wayland • PRIME • perf • CUDA    ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n=== ASH DOCTOR — NVIDIA GPU CHECK ===\n'
    fi

    # ── Skip if no NVIDIA GPU present ───────────────────────────────────────────
    if ! lspci 2>/dev/null | grep -qi 'nvidia'; then
        _check_report $CHECK_SKIP \
            "NVIDIA GPU" \
            "No NVIDIA GPU detected via lspci — skipping all NVIDIA checks"
        _ash_check_system_summary
        return $CHECK_SKIP
    fi

    # ── Initialize nvidia-smi cache once ────────────────────────────────────────
    _nvidia_smi_init

    case "$mode" in
        quick)
            _chk_nvidia_hardware
            _chk_nvidia_driver
            ;;
        gaming)
            _chk_nvidia_hardware
            _chk_nvidia_wayland
            _chk_nvidia_performance
            _chk_nvidia_gaming
            ;;
        cuda)
            _chk_nvidia_hardware
            _chk_nvidia_cuda
            ;;
        full|*)
            _chk_nvidia_hardware
            _chk_nvidia_driver
            _chk_nvidia_wayland
            _chk_nvidia_prime
            _chk_nvidia_performance
            _chk_nvidia_cuda
            _chk_nvidia_gaming
            ;;
    esac

    _ash_check_system_summary
}

# ── Quick status API ────────────────────────────────────────────────────────────
ash_check_gpu_nvidia_quick() {
    local issues=0

    # Fast critical checks only
    lspci 2>/dev/null | grep -qi 'nvidia' || return 0  # no nvidia = not applicable

    lsmod 2>/dev/null | grep -q '^nvidia\b'           || (( issues++ )) || true
    lsmod 2>/dev/null | grep -q '^nvidia_drm\b'       || (( issues++ )) || true

    local modeset
    modeset="$(cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null || echo N)"
    [[ "$modeset" == "Y" ]] || [[ "$modeset" == "1" ]] || (( issues++ )) || true

    lsmod 2>/dev/null | grep -q '^nouveau\b' && (( issues++ )) || true

    if (( issues == 0 )); then
        ash_log_success "NVIDIA GPU: OK"
        return 0
    else
        ash_log_warn "NVIDIA GPU: ${issues} issue(s) — run 'ash doctor full --gpu'"
        return 1
    fi
}
