#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██╗███╗   ██╗████████╗███████╗██╗         ██████╗ ██████╗ ██╗   ██╗            ║
# ║  ██║████╗  ██║╚══██╔══╝██╔════╝██║        ██╔════╝ ██╔══██╗██║   ██║            ║
# ║  ██║██╔██╗ ██║   ██║   █████╗  ██║        ██║  ███╗██████╔╝██║   ██║            ║
# ║  ██║██║╚██╗██║   ██║   ██╔══╝  ██║        ██║   ██║██╔═══╝ ██║   ██║            ║
# ║  ██║██║ ╚████║   ██║   ███████╗███████╗   ╚██████╔╝██║     ╚██████╔╝            ║
# ║  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚══════╝    ╚═════╝ ╚═╝      ╚═════╝             ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  DOCTOR CHECK: INTEL GPU                                 ║
# ║  i915 • Xe • Arc • GuC/HuC firmware • VA-API • MSR • Wayland DMA-BUF           ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CHECK_GPU_INTEL_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CHECK_GPU_INTEL_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SHARED CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Intel vendor PCI ID
declare -gr _INTEL_PCI_VENDOR="0x8086"

# DRM sysfs base
declare -gr _DRM_SYSFS="/sys/class/drm"

# First Intel GPU sysfs path (populated by _intel_find_sysfs)
declare -g  _INTEL_GPU_SYSFS=""
declare -g  _INTEL_GPU_HWMON=""
declare -g  _INTEL_GPU_NAME=""
declare -g  _INTEL_GPU_GEN=""          # bdw | skl | kbl | cfl | icl | tgl | adl | mtl | lnl | arc
declare -g  _INTEL_DRM_CARD=""         # e.g. "card1"
declare -g  _INTEL_DRIVER=""           # i915 | xe | unknown

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  INTERNAL HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_intel_find_sysfs() {
    for card_dir in "${_DRM_SYSFS}"/card*/; do
        [[ -f "${card_dir}device/vendor" ]] || continue
        local vendor
        vendor="$(cat "${card_dir}device/vendor" 2>/dev/null || echo '')"
        [[ "$vendor" != "$_INTEL_PCI_VENDOR" ]] && continue

        _INTEL_GPU_SYSFS="${card_dir}device"
        _INTEL_DRM_CARD="$(basename "$card_dir")"

        # Detect driver via sysfs symlink
        local driver_link
        driver_link="$(readlink "${_INTEL_GPU_SYSFS}/driver" 2>/dev/null || echo '')"
        case "${driver_link##*/}" in
            i915) _INTEL_DRIVER="i915" ;;
            xe)   _INTEL_DRIVER="xe"   ;;
            *)    _INTEL_DRIVER="unknown" ;;
        esac

        # hwmon path
        for hwmon_dir in "${_INTEL_GPU_SYSFS}"/hwmon/hwmon*/; do
            [[ -d "$hwmon_dir" ]] && _INTEL_GPU_HWMON="$hwmon_dir" && break
        done

        # Detect generation from PCI device ID
        local dev_id
        dev_id="$(cat "${_INTEL_GPU_SYSFS}/device" 2>/dev/null | tr '[:lower:]' '[:upper:]' || echo '')"
        _intel_classify_gen "$dev_id"

        break
    done
}

_intel_classify_gen() {
    local dev_id="${1:-}"
    local pci_str
    pci_str="$(lspci -n 2>/dev/null | grep "${_INTEL_PCI_VENDOR#0x}" | \
               grep -i 'vga\|display\|3d' | head -1 || echo '')"

    local gpu_name_full
    gpu_name_full="$(lspci 2>/dev/null | grep -i 'intel' | \
                     grep -i 'vga\|display\|3d\|graphics' | head -1 | \
                     sed 's/^[^ ]* [^ ]* //' || echo 'Intel GPU')"
    _INTEL_GPU_NAME="$gpu_name_full"

    # Generation classification by product name
    if   printf '%s' "$gpu_name_full" | grep -qiE 'Arrow Lake|Lunar Lake|LNL|ARL'; then
        _INTEL_GPU_GEN="lnl_arl"
    elif printf '%s' "$gpu_name_full" | grep -qiE 'Meteor Lake|MTL|Core Ultra [0-9]'; then
        _INTEL_GPU_GEN="mtl"
    elif printf '%s' "$gpu_name_full" | grep -qiE 'Arc [AB][0-9]|Alchemist|DG2'; then
        _INTEL_GPU_GEN="arc"
    elif printf '%s' "$gpu_name_full" | grep -qiE 'Raptor Lake|Alder Lake|ADL|RPL|UHD 7[0-9]{2}'; then
        _INTEL_GPU_GEN="adl"
    elif printf '%s' "$gpu_name_full" | grep -qiE 'Tiger Lake|TGL|Xe Graphics|UHD Graphics.*G[0-9]'; then
        _INTEL_GPU_GEN="tgl"
    elif printf '%s' "$gpu_name_full" | grep -qiE 'Ice Lake|ICL|Iris Plus G[47]|UHD 6[0-9]{2}'; then
        _INTEL_GPU_GEN="icl"
    elif printf '%s' "$gpu_name_full" | grep -qiE 'Whiskey|Coffee|Comet|CFL|CML|UHD 6[0-2]'; then
        _INTEL_GPU_GEN="cfl"
    elif printf '%s' "$gpu_name_full" | grep -qiE 'Kaby Lake|KBL|HD Graphics 6[0-9]{2}'; then
        _INTEL_GPU_GEN="kbl"
    elif printf '%s' "$gpu_name_full" | grep -qiE 'Skylake|SKL|HD Graphics 5[0-9]{2}'; then
        _INTEL_GPU_GEN="skl"
    elif printf '%s' "$gpu_name_full" | grep -qiE 'Broadwell|BDW|HD Graphics 6000|Iris Pro'; then
        _INTEL_GPU_GEN="bdw"
    elif printf '%s' "$gpu_name_full" | grep -qiE 'Haswell|HSW|HD Graphics 4[0-9]{3}'; then
        _INTEL_GPU_GEN="hsw"
    else
        _INTEL_GPU_GEN="unknown"
    fi
}

_intel_gen_label() {
    case "${_INTEL_GPU_GEN}" in
        lnl_arl) echo "Lunar Lake / Arrow Lake  (2024 — latest)" ;;
        mtl)     echo "Meteor Lake  (2023 — Intel Core Ultra)" ;;
        arc)     echo "Arc Alchemist  (A-series discrete GPU)" ;;
        adl)     echo "Alder Lake / Raptor Lake  (12th/13th Gen)" ;;
        tgl)     echo "Tiger Lake  (11th Gen — Xe integrated)" ;;
        icl)     echo "Ice Lake  (10th Gen — Gen11 Iris Plus)" ;;
        cfl)     echo "Coffee / Comet / Whiskey Lake  (8th/9th/10th Gen)" ;;
        kbl)     echo "Kaby Lake  (7th Gen)" ;;
        skl)     echo "Skylake  (6th Gen)" ;;
        bdw)     echo "Broadwell  (5th Gen — legacy)" ;;
        hsw)     echo "Haswell  (4th Gen — very old)" ;;
        *)       echo "Unknown Intel generation" ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 01 — HARDWARE DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_intel_hardware() {
    _check_header "🔵 Intel GPU Hardware"

    # ── PCI scan ────────────────────────────────────────────────────────────────
    local gpu_lines
    gpu_lines="$(lspci 2>/dev/null | grep -i 'intel' | \
                 grep -iE 'vga|3d|display|graphics' || echo '')"

    if [[ -z "$gpu_lines" ]]; then
        _check_report $CHECK_FAIL \
            "Intel GPU detected" \
            "No Intel GPU found via lspci" \
            "Install pciutils: paru -S pciutils"
        return $CHECK_FAIL
    fi

    local gpu_count
    gpu_count="$(printf '%s\n' "$gpu_lines" | wc -l)"
    _check_report $CHECK_PASS \
        "Intel GPU detected" \
        "${gpu_count} Intel GPU(s) found"

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local pci_id="${line%% *}"
        local gpu_label
        gpu_label="$(printf '%s' "$line" | sed 's/^[^ ]* [^ ]* [^ ]* //')"
        _check_report $CHECK_INFO "GPU [${pci_id}]"       "${gpu_label}"
    done <<< "$gpu_lines"

    # ── Generation ──────────────────────────────────────────────────────────────
    _check_report $CHECK_INFO \
        "Generation" \
        "$(_intel_gen_label)"

    # ── Driver ──────────────────────────────────────────────────────────────────
    case "$_INTEL_DRIVER" in
        i915)
            _check_report $CHECK_PASS \
                "Active driver" \
                "i915  (mature, stable Wayland support)" ;;
        xe)
            _check_report $CHECK_PASS \
                "Active driver" \
                "xe  (new kernel driver — Battlemage / future Arc)" ;;
        unknown)
            _check_report $CHECK_WARN \
                "Active driver" \
                "Could not detect — check: lspci -k" \
                "Ensure kernel headers and mesa are installed" ;;
    esac

    # ── DRM card node ───────────────────────────────────────────────────────────
    if [[ -n "$_INTEL_DRM_CARD" ]]; then
        _check_report $CHECK_PASS \
            "DRM card node" \
            "/dev/dri/${_INTEL_DRM_CARD}  (sysfs: ${_DRM_SYSFS}/${_INTEL_DRM_CARD})"
    else
        _check_report $CHECK_FAIL \
            "DRM card node" \
            "Not found — i915/xe not loaded?" \
            "Load: sudo modprobe i915"
    fi

    # ── Render node ─────────────────────────────────────────────────────────────
    local intel_render
    intel_render="$(find /dev/dri -name 'renderD*' 2>/dev/null | head -1 || echo '')"

    if [[ -n "$intel_render" ]]; then
        # Verify permissions
        if [[ -r "$intel_render" ]] && [[ -w "$intel_render" ]]; then
            _check_report $CHECK_PASS \
                "DRM render node" \
                "${intel_render}  (read+write OK)"
        else
            _check_report $CHECK_FAIL \
                "DRM render node" \
                "${intel_render}  (no write access)" \
                "Add user to render group: sudo usermod -aG render,video $USER"
        fi
    else
        _check_report $CHECK_FAIL \
            "DRM render node" \
            "No /dev/dri/renderD* found" \
            "Check: ls /dev/dri  and ensure i915 is loaded"
    fi

    # ── user groups ─────────────────────────────────────────────────────────────
    local user_groups
    user_groups="$(groups 2>/dev/null | tr ' ' '\n')"

    for grp in video render; do
        if printf '%s\n' "$user_groups" | grep -qx "$grp"; then
            _check_report $CHECK_PASS \
                "Group: ${grp}" \
                "User is a member"
        else
            _check_report $CHECK_WARN \
                "Group: ${grp}" \
                "User NOT in '${grp}' group" \
                "Fix: sudo usermod -aG ${grp} ${USER}  then re-login"
        fi
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 02 — KERNEL MODULE + PARAMETERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_intel_kmod() {
    _check_header "🔩 Kernel Module  (i915 / xe)"

    # ── Which driver module is loaded? ──────────────────────────────────────────
    local loaded_driver=""

    if lsmod 2>/dev/null | grep -q '^i915\b'; then
        local mod_size
        mod_size="$(lsmod | awk '/^i915 /{print $2}')"
        _check_report $CHECK_PASS \
            "i915 module" \
            "Loaded  (${mod_size} bytes)"
        loaded_driver="i915"
    else
        _check_report $CHECK_INFO \
            "i915 module" \
            "Not loaded"
    fi

    if lsmod 2>/dev/null | grep -q '^xe\b'; then
        local xe_size
        xe_size="$(lsmod | awk '/^xe /{print $2}')"
        _check_report $CHECK_PASS \
            "xe module" \
            "Loaded  (${xe_size} bytes)"
        loaded_driver="xe"
    else
        _check_report $CHECK_INFO \
            "xe module" \
            "Not loaded  (only needed for Battlemage / future Arc)"
    fi

    if [[ -z "$loaded_driver" ]]; then
        _check_report $CHECK_FAIL \
            "GPU kernel module" \
            "Neither i915 nor xe is loaded" \
            "Load: sudo modprobe i915"
        return $CHECK_FAIL
    fi

    # ── i915 module parameters ──────────────────────────────────────────────────
    local params_dir="/sys/module/i915/parameters"
    if [[ "$loaded_driver" == "i915" ]] && [[ -d "$params_dir" ]]; then

        # enable_guc — GuC/HuC submission
        local enable_guc
        enable_guc="$(cat "${params_dir}/enable_guc" 2>/dev/null || echo '?')"
        if [[ "$enable_guc" == "3" ]] || [[ "$enable_guc" == "2" ]]; then
            _check_report $CHECK_PASS \
                "i915.enable_guc" \
                "${enable_guc}  (GuC+HuC submission enabled — optimal)"
        elif [[ "$enable_guc" == "1" ]]; then
            _check_report $CHECK_WARN \
                "i915.enable_guc" \
                "1  (GuC only — add HuC: i915.enable_guc=3)" \
                "Set kernel param: i915.enable_guc=3"
        elif [[ "$enable_guc" == "0" ]]; then
            _check_report $CHECK_WARN \
                "i915.enable_guc" \
                "0  (disabled — sub-optimal performance)" \
                "Enable: add 'i915.enable_guc=3' to kernel parameters"
        else
            _check_report $CHECK_INFO \
                "i915.enable_guc" \
                "${enable_guc}"
        fi

        # enable_fbc — frame buffer compression (power saving)
        local enable_fbc
        enable_fbc="$(cat "${params_dir}/enable_fbc" 2>/dev/null || echo '?')"
        if [[ "$enable_fbc" == "1" ]]; then
            _check_report $CHECK_PASS \
                "i915.enable_fbc" \
                "1  (frame buffer compression — saves power)"
        else
            _check_report $CHECK_INFO \
                "i915.enable_fbc" \
                "${enable_fbc}  (0 = disabled)"
        fi

        # enable_psr — panel self refresh (OLED/laptop power saving)
        local enable_psr
        enable_psr="$(cat "${params_dir}/enable_psr" 2>/dev/null || echo '?')"
        if [[ "$enable_psr" == "1" ]]; then
            _check_report $CHECK_PASS \
                "i915.enable_psr" \
                "1  (Panel Self Refresh — saves battery on laptops)"
        else
            _check_report $CHECK_INFO \
                "i915.enable_psr" \
                "${enable_psr}  (disabled — may increase power draw)"
        fi

        # modeset
        local modeset
        modeset="$(cat "${params_dir}/modeset" 2>/dev/null || echo '?')"
        if [[ "$modeset" == "1" ]] || [[ "$modeset" == "-1" ]]; then
            _check_report $CHECK_PASS \
                "i915.modeset" \
                "${modeset}  (KMS enabled)"
        else
            _check_report $CHECK_FAIL \
                "i915.modeset" \
                "${modeset}  (KMS disabled — Wayland broken)" \
                "Add kernel param: i915.modeset=1"
        fi

        # force_probe (needed for very new iGPUs)
        local force_probe
        force_probe="$(cat "${params_dir}/force_probe" 2>/dev/null || echo '')"
        if [[ -n "$force_probe" ]]; then
            _check_report $CHECK_INFO \
                "i915.force_probe" \
                "${force_probe}"
        fi
    fi

    # ── GuC / HuC firmware ──────────────────────────────────────────────────────
    _chk_intel_firmware "$loaded_driver"
}

_chk_intel_firmware() {
    local driver="${1:-i915}"

    # GuC firmware
    local guc_fw
    guc_fw="$(find /lib/firmware/i915 -name '*guc*.bin' 2>/dev/null | \
              sort -V | tail -1 || echo '')"

    if [[ -n "$guc_fw" ]]; then
        _check_report $CHECK_PASS \
            "GuC firmware" \
            "$(basename "$guc_fw")"
    else
        _check_report $CHECK_WARN \
            "GuC firmware" \
            "Not found in /lib/firmware/i915" \
            "Install: paru -S linux-firmware"
    fi

    # HuC firmware
    local huc_fw
    huc_fw="$(find /lib/firmware/i915 -name '*huc*.bin' 2>/dev/null | \
              sort -V | tail -1 || echo '')"

    if [[ -n "$huc_fw" ]]; then
        _check_report $CHECK_PASS \
            "HuC firmware" \
            "$(basename "$huc_fw")"
    else
        _check_report $CHECK_INFO \
            "HuC firmware" \
            "Not found  (not required for all generations)"
    fi

    # DMC firmware (display microcontroller)
    local dmc_fw
    dmc_fw="$(find /lib/firmware/i915 -name '*dmc*.bin' 2>/dev/null | \
              sort -V | tail -1 || echo '')"

    if [[ -n "$dmc_fw" ]]; then
        _check_report $CHECK_PASS \
            "DMC firmware" \
            "$(basename "$dmc_fw")  (display power gating)"
    else
        _check_report $CHECK_INFO \
            "DMC firmware" \
            "Not found"
    fi

    # dmesg firmware errors
    local fw_errors
    fw_errors="$(dmesg 2>/dev/null | \
                 grep -iE 'i915.*firmware.*fail|failed to load.*guc|huc.*fail' | \
                 tail -3 || echo '')"

    if [[ -n "$fw_errors" ]]; then
        _check_report $CHECK_FAIL \
            "Firmware dmesg errors" \
            "$(printf '%s' "$fw_errors" | head -1 | sed 's/.*\] //')" \
            "Update: paru -S linux-firmware && sudo mkinitcpio -P"
    else
        _check_report $CHECK_PASS \
            "Firmware dmesg errors" \
            "None detected"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 03 — MESA / OPENGL / VULKAN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_intel_mesa() {
    _check_header "🟡 Mesa / OpenGL / Vulkan"

    # ── Mesa version via package manager ────────────────────────────────────────
    local mesa_ver=""
    if command -v pacman &>/dev/null; then
        mesa_ver="$(pacman -Q mesa 2>/dev/null | awk '{print $2}' || echo '')"
    elif command -v rpm &>/dev/null; then
        mesa_ver="$(rpm -q mesa-libGL 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo '')"
    fi

    # ── Prefer glxinfo when display is available ────────────────────────────────
    if command -v glxinfo &>/dev/null && [[ -n "${DISPLAY:-}" ]]; then
        local gl_renderer gl_vendor gl_version
        gl_renderer="$(glxinfo 2>/dev/null | awk -F': ' '/OpenGL renderer/{print $2}' | head -1)"
        gl_vendor="$(  glxinfo 2>/dev/null | awk -F': ' '/OpenGL vendor/{print $2}'   | head -1)"
        gl_version="$( glxinfo 2>/dev/null | awk -F': ' '/OpenGL version/{print $2}'  | head -1)"

        if printf '%s' "$gl_renderer" | grep -qiE 'llvmpipe|softpipe|virgl'; then
            _check_report $CHECK_FAIL \
                "OpenGL renderer" \
                "${gl_renderer}" \
                "SOFTWARE rendering — i915 not working. Check: dmesg | grep i915"
        else
            _check_report $CHECK_PASS \
                "OpenGL renderer" \
                "${gl_renderer}"
        fi

        [[ -n "$gl_version" ]] && \
            _check_report $CHECK_INFO "OpenGL version" "$gl_version"
    else
        if [[ -n "$mesa_ver" ]]; then
            local mesa_major="${mesa_ver%%.*}"
            if (( mesa_major >= 24 )); then
                _check_report $CHECK_PASS \
                    "Mesa version" \
                    "${mesa_ver}  (bleeding edge)"
            elif (( mesa_major >= 23 )); then
                _check_report $CHECK_PASS \
                    "Mesa version" \
                    "${mesa_ver}  (current stable)"
            else
                _check_report $CHECK_WARN \
                    "Mesa version" \
                    "${mesa_ver}  (old — update recommended)" \
                    "Update: paru -Su mesa"
            fi
        else
            _check_report $CHECK_INFO \
                "Mesa version" \
                "Cannot determine — install mesa-utils for glxinfo"
        fi
    fi

    # ── intel-media-driver (iHD) vs libva-intel-driver (i965) ──────────────────
    local ihd_path i965_path
    ihd_path="$(find /usr/lib -name 'iHD_drv_video.so' 2>/dev/null | head -1 || echo '')"
    i965_path="$(find /usr/lib -name 'i965_drv_video.so' 2>/dev/null | head -1 || echo '')"

    if [[ -n "$ihd_path" ]]; then
        _check_report $CHECK_PASS \
            "VA-API driver (iHD)" \
            "${ihd_path##*/}  (recommended for Gen8+)"
    else
        _check_report $CHECK_WARN \
            "VA-API driver (iHD)" \
            "Not found" \
            "Install: paru -S intel-media-driver  (Gen8+ / Broadwell+)"
    fi

    if [[ -n "$i965_path" ]]; then
        if [[ -n "$ihd_path" ]]; then
            _check_report $CHECK_INFO \
                "VA-API driver (i965)" \
                "Also present — older legacy driver"
        else
            _check_report $CHECK_INFO \
                "VA-API driver (i965)" \
                "${i965_path##*/}  (legacy — use iHD for Gen8+)"
        fi
    fi

    # ── LIBVA_DRIVER_NAME ───────────────────────────────────────────────────────
    local libva_driver="${LIBVA_DRIVER_NAME:-}"
    if [[ "$libva_driver" == "iHD" ]]; then
        _check_report $CHECK_PASS \
            "LIBVA_DRIVER_NAME" \
            "iHD  (correct for Gen8+ Intel)"
    elif [[ "$libva_driver" == "i965" ]]; then
        _check_report $CHECK_INFO \
            "LIBVA_DRIVER_NAME" \
            "i965  (legacy driver)" \
            "Use iHD for Gen8+: export LIBVA_DRIVER_NAME=iHD"
    else
        _check_report $CHECK_INFO \
            "LIBVA_DRIVER_NAME" \
            "${libva_driver:-not set}" \
            "Recommended: export LIBVA_DRIVER_NAME=iHD"
    fi

    # ── vainfo ──────────────────────────────────────────────────────────────────
    if command -v vainfo &>/dev/null; then
        local va_out
        va_out="$(LIBVA_DRIVER_NAME="${LIBVA_DRIVER_NAME:-iHD}" \
                  vainfo 2>/dev/null || true)"

        if printf '%s' "$va_out" | grep -qi 'VAProfile'; then
            local profile_count
            profile_count="$(printf '%s' "$va_out" | grep -c 'VAProfile' || echo 0)"
            _check_report $CHECK_PASS \
                "VA-API profiles" \
                "${profile_count} profiles  (hardware video decode active)"
        else
            _check_report $CHECK_WARN \
                "VA-API profiles" \
                "No profiles reported" \
                "Set LIBVA_DRIVER_NAME=iHD and reinstall intel-media-driver"
        fi
    else
        _check_report $CHECK_INFO \
            "VA-API check" \
            "vainfo not found" \
            "Install: paru -S libva-utils"
    fi

    # ── Vulkan (ANV — Intel's Mesa Vulkan) ──────────────────────────────────────
    local anv_icd
    anv_icd="$(find /usr/share/vulkan/icd.d -name 'intel_icd*.json' 2>/dev/null \
               | head -1 || echo '')"

    if [[ -n "$anv_icd" ]]; then
        _check_report $CHECK_PASS \
            "Intel Vulkan ICD (ANV)" \
            "$(basename "$anv_icd")"
    else
        _check_report $CHECK_FAIL \
            "Intel Vulkan ICD (ANV)" \
            "Not found in /usr/share/vulkan/icd.d/" \
            "Install: paru -S vulkan-intel"
    fi

    # ── vulkaninfo sanity ───────────────────────────────────────────────────────
    if command -v vulkaninfo &>/dev/null; then
        local vk_intel
        vk_intel="$(vulkaninfo --summary 2>/dev/null | grep -i 'intel\|anv' | head -2 || echo '')"
        if [[ -n "$vk_intel" ]]; then
            _check_report $CHECK_PASS \
                "Vulkan Intel device" \
                "$(printf '%s' "$vk_intel" | head -1 | sed 's/^\s*//')"
        else
            _check_report $CHECK_WARN \
                "Vulkan Intel device" \
                "Intel not listed in vulkaninfo --summary" \
                "Reinstall: paru -S vulkan-intel"
        fi
    fi

    # ── OpenCL (Intel compute runtime) ─────────────────────────────────────────
    local ocl_icd
    ocl_icd="$(find /etc/OpenCL/vendors -name 'intel*.icd' 2>/dev/null | head -1 || echo '')"

    if [[ -n "$ocl_icd" ]]; then
        _check_report $CHECK_PASS \
            "OpenCL ICD" \
            "$(basename "$ocl_icd")"
    else
        _check_report $CHECK_INFO \
            "OpenCL ICD" \
            "Not found" \
            "Install: paru -S intel-compute-runtime  (for OpenCL compute)"
    fi

    # ── Level Zero (oneAPI) ─────────────────────────────────────────────────────
    if [[ -f /usr/lib/libze_intel_gpu.so.1 ]] || \
       find /usr/lib -name 'libze_intel_gpu*.so*' -q 2>/dev/null; then
        _check_report $CHECK_PASS \
            "Intel Level Zero (oneAPI)" \
            "Present  (GPU compute via Level Zero)"
    else
        _check_report $CHECK_INFO \
            "Intel Level Zero (oneAPI)" \
            "Not installed" \
            "Install for AI/compute: paru -S level-zero-intel-gpu"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 04 — WAYLAND INTEGRATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_intel_wayland() {
    _check_header "🌊 Wayland / DMA-BUF / Display"

    # ── Environment variables ───────────────────────────────────────────────────
    local -a env_pairs=(
        "LIBVA_DRIVER_NAME:iHD:VA-API hardware decode"
        "WLR_RENDERER:vulkan:Hyprland Vulkan renderer  (or leave auto)"
    )

    for pair in "${env_pairs[@]}"; do
        IFS=':' read -r var rec hint <<< "$pair"
        local val="${!var:-}"
        if [[ -z "$val" ]]; then
            _check_report $CHECK_INFO \
                "$var" \
                "not set  (recommended: ${rec})" \
                "$hint — add to environment.d"
        elif [[ "$val" == "$rec" ]]; then
            _check_report $CHECK_PASS "$var" "$val"
        else
            _check_report $CHECK_INFO "$var" "$val  (expected: ${rec})"
        fi
    done

    # ── DRI_PRIME (for iGPU+dGPU hybrid) ───────────────────────────────────────
    local dri_prime="${DRI_PRIME:-}"
    if [[ -n "$dri_prime" ]]; then
        _check_report $CHECK_INFO \
            "DRI_PRIME" \
            "${dri_prime}  (GPU offloading active)"
    fi

    # ── Hyprland render backend ─────────────────────────────────────────────────
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl &>/dev/null; then
        local renderer_out
        renderer_out="$(hyprctl getoption general:renderer 2>/dev/null | \
                        grep 'str:' | awk '{print $2}' || echo 'auto')"
        _check_report $CHECK_INFO \
            "Hyprland renderer backend" \
            "${renderer_out}"

        # VFR
        local vfr
        vfr="$(hyprctl getoption misc:vfr -j 2>/dev/null | \
               python3 -c 'import sys,json; print(json.load(sys.stdin).get("int",0))' \
               2>/dev/null || echo '0')"
        if [[ "$vfr" == "1" ]]; then
            _check_report $CHECK_PASS \
                "VFR (variable frame rate)" \
                "Enabled  (reduces idle CPU+GPU usage)"
        else
            _check_report $CHECK_WARN \
                "VFR (variable frame rate)" \
                "Disabled" \
                "Enable: misc { vfr = true }  in hyprland.conf"
        fi
    fi

    # ── PSR (panel self refresh on laptop displays) ─────────────────────────────
    local psr_state
    psr_state="$(find /sys/kernel/debug/dri -name 'i915_edp_psr_status' \
                 2>/dev/null | head -1)"
    if [[ -r "${psr_state:-}" ]]; then
        local psr_val
        psr_val="$(cat "$psr_state" 2>/dev/null | grep 'enabled:' | \
                   awk '{print $2}' | head -1)"
        if [[ "$psr_val" == "yes" ]]; then
            _check_report $CHECK_PASS \
                "Panel Self Refresh (PSR)" \
                "Active  (saves battery on eDP laptops)"
        else
            _check_report $CHECK_INFO \
                "Panel Self Refresh (PSR)" \
                "Not active  (not on battery or OLED display)"
        fi
    fi

    # ── Screen capture / PipeWire ───────────────────────────────────────────────
    pgrep -x pipewire &>/dev/null && \
        _check_report $CHECK_PASS "PipeWire running" "Screen capture available" || \
        _check_report $CHECK_FAIL "PipeWire" \
            "Not running" \
            "Enable: systemctl --user enable --now pipewire"

    # ── HDR capability ──────────────────────────────────────────────────────────
    local hdr_capable=0
    for card_dir in "${_DRM_SYSFS}"/card*/; do
        if [[ -f "${card_dir}device/vendor" ]]; then
            local v
            v="$(cat "${card_dir}device/vendor" 2>/dev/null || echo '')"
            if [[ "$v" == "$_INTEL_PCI_VENDOR" ]]; then
                for conn_dir in "${card_dir}"*/; do
                    [[ -f "${conn_dir}hdr_output_metadata" ]] && hdr_capable=1 && break 2
                done
            fi
        fi
    done

    if [[ $hdr_capable -eq 1 ]]; then
        _check_report $CHECK_INFO \
            "HDR metadata" \
            "Display supports HDR metadata (Hyprland HDR experimental)"
    else
        _check_report $CHECK_INFO \
            "HDR metadata" \
            "HDR not reported by display"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 05 — POWER / TEMPERATURE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_intel_power() {
    _check_header "⚡ Intel GPU Power & Thermals"

    # ── GPU frequency via sysfs ─────────────────────────────────────────────────
    local gt_dir
    gt_dir="$(find /sys/class/drm -name 'gt_cur_freq_mhz' 2>/dev/null | head -1 || echo '')"
    gt_dir="${gt_dir%gt_cur_freq_mhz}"

    if [[ -n "$gt_dir" ]]; then
        local cur_freq min_freq max_freq boost_freq
        cur_freq="$(  cat "${gt_dir}gt_cur_freq_mhz"   2>/dev/null || echo '?')"
        min_freq="$(  cat "${gt_dir}gt_min_freq_mhz"   2>/dev/null || echo '?')"
        max_freq="$(  cat "${gt_dir}gt_max_freq_mhz"   2>/dev/null || echo '?')"
        boost_freq="$(cat "${gt_dir}gt_boost_freq_mhz" 2>/dev/null || echo '?')"

        _check_report $CHECK_INFO \
            "GPU frequency" \
            "${cur_freq} MHz  (min: ${min_freq}  max: ${max_freq}  boost: ${boost_freq})"
    fi

    # ── Temperature via hwmon ───────────────────────────────────────────────────
    local temp_file=""

    # Try direct hwmon path from detected sysfs
    if [[ -n "$_INTEL_GPU_HWMON" ]]; then
        temp_file="${_INTEL_GPU_HWMON}temp1_input"
    fi

    # Fallback: search all hwmon for Intel GPU
    if [[ -z "$temp_file" ]] || [[ ! -r "$temp_file" ]]; then
        temp_file="$(find /sys/class/hwmon -name 'temp*_input' 2>/dev/null | \
                     while read -r f; do
                         local nm
                         nm="$(cat "$(dirname "$f")/name" 2>/dev/null || echo '')"
                         [[ "$nm" =~ i915|xe|card ]] && printf '%s' "$f" && break
                     done)"
    fi

    if [[ -r "${temp_file:-}" ]]; then
        local temp_mc
        temp_mc="$(cat "$temp_file" 2>/dev/null || echo '0')"
        local temp_c=$(( temp_mc / 1000 ))

        if (( temp_c >= 90 )); then
            _check_report $CHECK_FAIL \
                "GPU temperature" \
                "${temp_c}°C  (CRITICAL — thermal throttle)" \
                "Check TDP limits and cooling"
        elif (( temp_c >= 75 )); then
            _check_report $CHECK_WARN \
                "GPU temperature" \
                "${temp_c}°C  (warm)"
        else
            _check_report $CHECK_PASS \
                "GPU temperature" \
                "${temp_c}°C"
        fi
    else
        _check_report $CHECK_INFO \
            "GPU temperature" \
            "Not accessible via hwmon sysfs"
    fi

    # ── CPU package power (includes iGPU TDP) ──────────────────────────────────
    local rapl_dir="/sys/class/powercap/intel-rapl"
    if [[ -d "$rapl_dir" ]]; then
        for rapl_pkg in "${rapl_dir}"/intel-rapl:*/; do
            local rapl_name
            rapl_name="$(cat "${rapl_pkg}name" 2>/dev/null || echo '')"
            if [[ "$rapl_name" == "package-0" ]]; then
                local energy_uj
                energy_uj="$(cat "${rapl_pkg}energy_uj" 2>/dev/null || echo '0')"
                # Read twice with 100ms gap for instant wattage estimate
                sleep 0.1 2>/dev/null || true
                local energy_uj2
                energy_uj2="$(cat "${rapl_pkg}energy_uj" 2>/dev/null || echo '0')"
                local power_mw=$(( (energy_uj2 - energy_uj) * 10 ))
                local power_w=$(( power_mw / 1000000 ))
                _check_report $CHECK_INFO \
                    "Package TDP (RAPL)" \
                    "~${power_w}W  (CPU + iGPU combined)"
                break
            fi
        done
    else
        _check_report $CHECK_INFO \
            "Package TDP (RAPL)" \
            "RAPL sysfs not accessible  (may need kernel param: msr)"
    fi

    # ── TurboBoost / P-state ────────────────────────────────────────────────────
    local no_turbo
    no_turbo="$(cat /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || echo '?')"
    if [[ "$no_turbo" == "0" ]]; then
        _check_report $CHECK_PASS \
            "Intel TurboBoost" \
            "Enabled  (max GPU boost available)"
    elif [[ "$no_turbo" == "1" ]]; then
        _check_report $CHECK_INFO \
            "Intel TurboBoost" \
            "Disabled  (power saving mode)"
    fi

    # ── Throttle reasons ────────────────────────────────────────────────────────
    local throttle
    throttle="$(dmesg 2>/dev/null | \
                grep -iE 'i915.*throttl|GPU.*freq.*throttl|thermal.*limit' | \
                tail -2 | sed 's/.*\] //' || echo '')"
    if [[ -n "$throttle" ]]; then
        _check_report $CHECK_WARN \
            "Thermal throttling" \
            "Events detected in dmesg" \
            "$(printf '%s' "$throttle" | head -1)"
    else
        _check_report $CHECK_PASS \
            "Thermal throttling" \
            "No events detected"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_check_gpu_intel() {
    local mode="${1:-full}"   # quick | full

    _CHECK_PASS_COUNT=0;  _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0;  _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=();   _CHECK_WARNINGS=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;137;180;250m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🔵  ASH DOCTOR — INTEL GPU CHECK                        ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  Checks: hw • i915/xe • Mesa • VA-API • Wayland • power  ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n=== ASH DOCTOR — INTEL GPU CHECK ===\n'
    fi

    # ── Gate: no Intel GPU? ──────────────────────────────────────────────────────
    if ! lspci 2>/dev/null | grep -qi 'intel.*graphics\|intel.*vga\|iris\|uhd'; then
        _check_report $CHECK_SKIP \
            "Intel GPU" \
            "No Intel GPU detected via lspci — skipping"
        _ash_check_system_summary
        return $CHECK_SKIP
    fi

    # ── Discover sysfs paths once ────────────────────────────────────────────────
    _intel_find_sysfs

    case "$mode" in
        quick)
            _chk_intel_hardware
            _chk_intel_kmod
            ;;
        full|*)
            _chk_intel_hardware
            _chk_intel_kmod
            _chk_intel_mesa
            _chk_intel_wayland
            _chk_intel_power
            ;;
    esac

    _ash_check_system_summary
}

ash_check_gpu_intel_quick() {
    lspci 2>/dev/null | grep -qi 'intel.*graphics\|iris\|uhd' || return 0
    local issues=0
    lsmod 2>/dev/null | grep -qE '^i915|^xe' || (( issues++ )) || true
    [[ -d "/sys/class/drm/card0" ]]           || (( issues++ )) || true
    if (( issues == 0 )); then
        ash_log_success "Intel GPU: OK"
    else
        ash_log_warn "Intel GPU: ${issues} issue(s) — run 'ash doctor full --gpu'"
        return 1
    fi
}
