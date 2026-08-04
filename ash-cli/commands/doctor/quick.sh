#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ DOCTOR QUICK                                               ║
# ║  Fast 30-second essential health check — 40 critical checks                           ║
# ║  Covers: system, wayland, hyprland, GPU, audio, network, fonts, tools                ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

doctor::quick::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash doctor quick [options]

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--issues-only${RST}   Show only warnings and failures
  ${ASH_MUTED}--compact,  -c${RST}  One-line-per-check compact output
  ${ASH_MUTED}--no-summary${RST}    Skip health score summary
  ${ASH_MUTED}--help,     -h${RST}   Show this help

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Runs ~40 essential checks in under 30 seconds.
  Covers critical system components without deep inspection.
  For comprehensive analysis use: ${ASH_ACCENT}ash doctor full${RST}
EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § QUICK CHECK GROUPS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_quick::system() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && [[ "${DOC_CATEGORY_FILTER}" != "system" ]] && return

    # OS detection
    if [[ -f /etc/os-release ]]; then
        local distro; distro=$(. /etc/os-release && printf '%s %s' "${NAME}" "${VERSION_ID:-}")
        doc::result "${SEV_INFO}" "system" "sys.distro" "Distribution" "${distro}" ""
    fi

    # Kernel
    local kernel; kernel=$(uname -r)
    doc::result "${SEV_INFO}" "system" "sys.kernel" "Kernel" "${kernel}" ""

    # Architecture
    local arch; arch=$(uname -m)
    local sev; [[ "${arch}" == "x86_64" ]] && sev="${SEV_PASS}" || sev="${SEV_INFO}"
    doc::result "${sev}" "system" "sys.arch" "Architecture" "${arch}" ""

    # Memory
    local mem_total mem_avail
    mem_total=$(awk '/MemTotal/ {printf "%.0f", $2/1024}' /proc/meminfo 2>/dev/null || echo 0)
    mem_avail=$(awk '/MemAvailable/ {printf "%.0f", $2/1024}' /proc/meminfo 2>/dev/null || echo 0)
    local mem_sev; (( mem_avail > 512 )) && mem_sev="${SEV_PASS}" || mem_sev="${SEV_WARN}"
    doc::result "${mem_sev}" "system" "sys.memory" "Available Memory" \
        "${mem_avail}MiB free / ${mem_total}MiB total" ""

    # Disk space — home
    doc::check_disk_space "system" "sys.disk_home" "${HOME}" 2048

    # Bash version
    local bash_ver="${BASH_VERSION}"
    local bash_sev; [[ "${BASH_VERSINFO[0]}" -ge 5 ]] && bash_sev="${SEV_PASS}" || bash_sev="${SEV_WARN}"
    doc::result "${bash_sev}" "system" "sys.bash" "Bash Version" "${bash_ver}" ""

    # XDG dirs
    doc::check_path "system" "sys.xdg_config" \
        "${XDG_CONFIG_HOME:-${HOME}/.config}" "XDG_CONFIG_HOME" "${SEV_WARN}"
    doc::check_path "system" "sys.xdg_data" \
        "${XDG_DATA_HOME:-${HOME}/.local/share}" "XDG_DATA_HOME" "${SEV_WARN}"
}

_quick::wayland() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && [[ "${DOC_CATEGORY_FILTER}" != "wayland" ]] && return

    # WAYLAND_DISPLAY
    doc::check_env "wayland" "wy.display" "WAYLAND_DISPLAY" "" "${SEV_FAIL}"

    # XDG_SESSION_TYPE
    local session_type="${XDG_SESSION_TYPE:-}"
    if [[ "${session_type}" == "wayland" ]]; then
        doc::result "${SEV_PASS}" "wayland" "wy.session" "Session Type" "wayland ✓" ""
    else
        doc::result "${SEV_WARN}" "wayland" "wy.session" "Session Type" \
            "${session_type:-unknown} (expected wayland)" ""
    fi

    # XDG_CURRENT_DESKTOP
    local desktop="${XDG_CURRENT_DESKTOP:-}"
    local desk_sev; [[ "${desktop}" == *"Hyprland"* ]] && desk_sev="${SEV_PASS}" || desk_sev="${SEV_INFO}"
    doc::result "${desk_sev}" "wayland" "wy.desktop" "Current Desktop" \
        "${desktop:-<unset>}" ""

    # DBUS session
    local dbus_sev; [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] && \
        dbus_sev="${SEV_PASS}" || dbus_sev="${SEV_WARN}"
    doc::result "${dbus_sev}" "wayland" "wy.dbus" "D-Bus Session" \
        "${DBUS_SESSION_BUS_ADDRESS:-not set}" ""
}

_quick::hyprland() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && [[ "${DOC_CATEGORY_FILTER}" != "hyprland" ]] && return

    doc::check_cmd "hyprland" "hl.hyprland" "Hyprland" "true" \
        "paru -S hyprland"
    doc::check_cmd "hyprland" "hl.hyprctl"  "hyprctl"  "true" \
        "paru -S hyprland"
    doc::check_cmd "hyprland" "hl.hyprpaper" "hyprpaper" "false" \
        "paru -S hyprpaper"

    # hyprland.conf
    local hl_conf="${XDG_CONFIG_HOME:-${HOME}/.config}/hypr/hyprland.conf"
    doc::check_path "hyprland" "hl.conf" "${hl_conf}" "hyprland.conf" "${SEV_FAIL}"

    # Running instance
    if command -v hyprctl &>/dev/null; then
        if hyprctl version &>/dev/null 2>&1; then
            local hl_ver; hl_ver=$(hyprctl version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
            doc::result "${SEV_PASS}" "hyprland" "hl.running" "Hyprland Running" \
                "v${hl_ver:-unknown}" ""
        else
            doc::result "${SEV_INFO}" "hyprland" "hl.running" "Hyprland Running" \
                "Not running (may be normal outside session)" ""
        fi
    fi

    # swww wallpaper daemon
    doc::check_cmd "hyprland" "hl.swww" "swww" "false" "paru -S swww"

    # Lock screen
    doc::check_cmd "hyprland" "hl.hyprlock"  "hyprlock"  "false" "paru -S hyprlock"
    doc::check_cmd "hyprland" "hl.hypridle"  "hypridle"  "false" "paru -S hypridle"
}

_quick::gpu() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && [[ "${DOC_CATEGORY_FILTER}" != "gpu" ]] && return

    # Detect GPU
    local gpu_info
    gpu_info=$(lspci 2>/dev/null | grep -iE '(vga|3d|display)' | head -3 || echo "unknown")

    if [[ "${gpu_info}" == "unknown" ]]; then
        doc::result "${SEV_WARN}" "gpu" "gpu.detect" "GPU Detection" \
            "lspci not available or no GPU found" "paru -S pciutils"
    else
        doc::result "${SEV_INFO}" "gpu" "gpu.detect" "GPU Detected" \
            "$(printf '%s' "${gpu_info}" | head -1)" ""
    fi

    # NVIDIA check
    if lspci 2>/dev/null | grep -qi nvidia; then
        local nvidia_sev="${SEV_PASS}"
        local nvidia_msg=""

        if ! command -v nvidia-smi &>/dev/null; then
            nvidia_sev="${SEV_FAIL}"
            nvidia_msg="nvidia-smi not found — drivers may not be installed"
        else
            local nvidia_driver
            nvidia_driver=$(nvidia-smi --query-gpu=driver_version \
                --format=csv,noheader 2>/dev/null | head -1 || echo "unknown")
            nvidia_msg="Driver v${nvidia_driver}"
        fi

        doc::result "${nvidia_sev}" "gpu" "gpu.nvidia" "NVIDIA Driver" \
            "${nvidia_msg}" "paru -S nvidia-dkms nvidia-utils"

        # NVIDIA Wayland env
        local nvidia_wayland="${__NV_PRIME_RENDER_OFFLOAD:-}"
        local nv_wl_sev="${SEV_INFO}"
        [[ -n "${nvidia_wayland}" ]] && nv_wl_sev="${SEV_PASS}"
        doc::result "${nv_wl_sev}" "gpu" "gpu.nvidia_wayland" "NVIDIA Wayland Env" \
            "${nvidia_wayland:-see ash config for env.conf}" ""
    fi

    # AMD check
    if lspci 2>/dev/null | grep -qi 'amd\|radeon\|ati'; then
        local amd_msg="AMD GPU detected"
        if [[ -d /sys/class/drm ]]; then
            local amdgpu_loaded; amdgpu_loaded=$(lsmod 2>/dev/null | grep -c amdgpu || echo 0)
            if (( amdgpu_loaded > 0 )); then
                amd_msg="amdgpu driver loaded ✓"
                doc::result "${SEV_PASS}" "gpu" "gpu.amd" "AMD Driver" "${amd_msg}" ""
            else
                doc::result "${SEV_WARN}" "gpu" "gpu.amd" "AMD Driver" \
                    "amdgpu module not loaded" "modprobe amdgpu"
            fi
        fi
    fi

    # Mesa / OpenGL
    if command -v glxinfo &>/dev/null; then
        local gl_renderer
        gl_renderer=$(glxinfo 2>/dev/null | grep 'OpenGL renderer' | cut -d: -f2- | sed 's/^ //' || echo "unknown")
        doc::result "${SEV_PASS}" "gpu" "gpu.opengl" "OpenGL Renderer" \
            "$(ash_truncate "${gl_renderer}" 50)" ""
    else
        doc::result "${SEV_INFO}" "gpu" "gpu.opengl" "OpenGL Info" \
            "glxinfo not installed" "paru -S mesa-utils"
    fi
}

_quick::audio() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && [[ "${DOC_CATEGORY_FILTER}" != "audio" ]] && return

    doc::check_cmd "audio" "aud.pipewire" "pipewire" "true" "paru -S pipewire"
    doc::check_cmd "audio" "aud.pw_cli"   "pw-cli"   "true" "paru -S pipewire"
    doc::check_cmd "audio" "aud.wireplumber" "wireplumber" "true" "paru -S wireplumber"
    doc::check_cmd "audio" "aud.pactl"    "pactl"    "false" "paru -S libpulse"

    # PipeWire running
    if pgrep -x pipewire &>/dev/null; then
        doc::result "${SEV_PASS}" "audio" "aud.pw_running" "PipeWire Running" "Active ✓" ""
    else
        doc::result "${SEV_WARN}" "audio" "aud.pw_running" "PipeWire Running" \
            "Not running" "systemctl --user start pipewire"
    fi

    # WirePlumber running
    if pgrep -x wireplumber &>/dev/null; then
        doc::result "${SEV_PASS}" "audio" "aud.wp_running" "WirePlumber Running" "Active ✓" ""
    else
        doc::result "${SEV_WARN}" "audio" "aud.wp_running" "WirePlumber Running" \
            "Not running" "systemctl --user start wireplumber"
    fi
}

_quick::network() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && [[ "${DOC_CATEGORY_FILTER}" != "network" ]] && return

    # NetworkManager
    doc::check_cmd "network" "net.nmcli" "nmcli" "false" "paru -S networkmanager"

    # Connectivity
    local conn_sev conn_msg
    if ping -c1 -W2 8.8.8.8 &>/dev/null 2>&1; then
        conn_sev="${SEV_PASS}"; conn_msg="Internet reachable ✓"
    else
        conn_sev="${SEV_WARN}"; conn_msg="No internet connectivity"
    fi
    doc::result "${conn_sev}" "network" "net.internet" "Internet Connectivity" "${conn_msg}" ""

    # DNS
    local dns_sev dns_msg
    if host -W2 archlinux.org &>/dev/null 2>&1 || \
       nslookup archlinux.org &>/dev/null 2>&1; then
        dns_sev="${SEV_PASS}"; dns_msg="DNS resolving ✓"
    else
        dns_sev="${SEV_WARN}"; dns_msg="DNS resolution may be broken"
    fi
    doc::result "${dns_sev}" "network" "net.dns" "DNS Resolution" "${dns_msg}" ""
}

_quick::fonts() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && [[ "${DOC_CATEGORY_FILTER}" != "fonts" ]] && return

    doc::check_cmd "fonts" "fnt.fc_list" "fc-list" "true" "paru -S fontconfig"

    # Nerd Font
    local nf_check; nf_check=$(fc-list 2>/dev/null | grep -ci "nerd\|nf-" || echo 0)
    if (( nf_check > 0 )); then
        doc::result "${SEV_PASS}" "fonts" "fnt.nerdfont" "Nerd Font" \
            "${nf_check} Nerd Font family/families found" ""
    else
        doc::result "${SEV_WARN}" "fonts" "fnt.nerdfont" "Nerd Font" \
            "No Nerd Fonts found — icons may be missing" \
            "paru -S ttf-jetbrains-mono-nerd"
    fi

    # Essential icon fonts
    for font_name in "Font Awesome" "Material Design" "Symbols Nerd"; do
        local found; found=$(fc-list 2>/dev/null | grep -ci "${font_name}" || echo 0)
        local fid; fid="fnt.$(printf '%s' "${font_name}" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')"
        local fsev; (( found > 0 )) && fsev="${SEV_PASS}" || fsev="${SEV_INFO}"
        local fmsg; (( found > 0 )) && fmsg="Found" || fmsg="Not installed (optional)"
        doc::result "${fsev}" "fonts" "${fid}" "Font: ${font_name}" "${fmsg}" ""
    done
}

_quick::tools_critical() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && \
        [[ "${DOC_CATEGORY_FILTER}" != "tools" ]] && \
        [[ "${DOC_CATEGORY_FILTER}" != "optional" ]] && return

    local -a critical_tools=(
        "git:tools:git version control"
        "jq:tools:JSON processor"
        "tar:tools:archive tool"
        "curl:tools:HTTP client"
        "rsync:tools:file sync"
        "waybar:tools:status bar:paru -S waybar"
        "rofi:tools:launcher:paru -S rofi-wayland"
        "kitty:tools:terminal:paru -S kitty"
        "dunst:tools:notifications:paru -S dunst"
        "playerctl:tools:media control:paru -S playerctl"
        "brightnessctl:tools:brightness control:paru -S brightnessctl"
        "grim:tools:screenshot:paru -S grim"
        "slurp:tools:area select:paru -S slurp"
        "wl-copy:tools:clipboard:paru -S wl-clipboard"
    )

    for entry in "${critical_tools[@]}"; do
        IFS=':' read -r cmd cat _desc fix <<< "${entry}"
        local id; id="tool.${cmd//-/_}"
        doc::check_cmd "${cat}" "${id}" "${cmd}" "true" "${fix:-}"
    done

    local -a optional_tools=(
        "btop:optional:system monitor"
        "fastfetch:optional:system info"
        "lazygit:optional:git TUI"
        "fzf:optional:fuzzy finder"
        "zoxide:optional:smart cd"
        "eza:optional:modern ls"
        "bat:optional:syntax cat"
        "ripgrep:optional:fast grep"
        "fd:optional:fast find"
        "starship:optional:prompt"
        "atuin:optional:shell history"
        "yazi:optional:file manager"
        "swww:optional:wallpaper daemon"
        "nvim:optional:neovim editor"
    )

    for entry in "${optional_tools[@]}"; do
        IFS=':' read -r cmd cat _desc <<< "${entry}"
        local id; id="opt.${cmd//-/_}"
        doc::check_cmd "${cat}" "${id}" "${cmd}" "false" ""
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
doctor::quick() {
    local issues_only=false compact=false no_summary=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)      doctor::quick::help; return 0 ;;
            --issues-only)  issues_only=true; shift ;;
            --compact|-c)   compact=true; shift ;;
            --no-summary)   no_summary=true; shift ;;
            -*)             log::error "Unknown option: $1"; return 1 ;;
            *)              shift ;;
        esac
    done

    local start_ts; start_ts=$(date +%s%N)

    # ── Header ────────────────────────────────────────────────────────────────
    if [[ "${DOC_QUIET}" == "false" ]] && [[ "${DOC_JSON_OUTPUT}" == "false" ]]; then
        log::blank
        printf '  %s🩺  ASH Doctor — Quick Check%s\n' "${BOLD}${ASH_PRIMARY}" "${RST}"
        printf '  %s%s%s\n\n' \
            "${ASH_MUTED}" "Running ~40 essential checks…" "${RST}"
    fi

    # ── Run check groups ──────────────────────────────────────────────────────
    local groups=(_quick::system _quick::wayland _quick::hyprland
                  _quick::gpu _quick::audio _quick::network
                  _quick::fonts _quick::tools_critical)

    local gi=0 total_groups="${#groups[@]}"
    for group_fn in "${groups[@]}"; do
        (( gi++ ))
        [[ "${DOC_QUIET}" == "false" ]] && [[ "${DOC_JSON_OUTPUT}" == "false" ]] && \
            ash_progress "${gi}" "${total_groups}" \
                "$(printf '%s' "${group_fn#_quick::}")" 28

        "${group_fn}" 2>/dev/null || log::debug "Check group ${group_fn} returned error"
    done

    [[ "${DOC_QUIET}" == "false" ]] && [[ "${DOC_JSON_OUTPUT}" == "false" ]] && \
        printf '\n'

    # ── Elapsed ───────────────────────────────────────────────────────────────
    local end_ts; end_ts=$(date +%s%N)
    local elapsed; elapsed=$(awk "BEGIN {printf \"%.2f\", (${end_ts} - ${start_ts}) / 1000000000}")

    # ── Output ────────────────────────────────────────────────────────────────
    if [[ "${DOC_JSON_OUTPUT}" == "true" ]]; then
        doc::save_results
        doc::load_last_results
        return 0
    fi

    local render_mode="full"
    [[ "${compact}" == "true" ]]     && render_mode="compact"
    [[ "${issues_only}" == "true" ]] && render_mode="issues-only"

    doc::render_results "${render_mode}" "${DOC_CATEGORY_FILTER}"

    [[ "${no_summary}" == "false" ]] && doc::render_summary "${elapsed}"

    doc::save_results

    # Exit code: fail if critical issues
    (( DOC_CRIT_COUNT > 0 || DOC_FAIL_COUNT > 0 )) && return 1 || return 0
}
