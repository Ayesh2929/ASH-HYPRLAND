#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ DOCTOR FULL                                                ║
# ║  Comprehensive deep system audit — 200+ checks across 18 categories                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

doctor::full::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash doctor full [options]

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--category,   -c CAT${RST}   Check only one category
  ${ASH_MUTED}--issues-only${RST}          Show only warnings and failures
  ${ASH_MUTED}--compact,    -c${RST}       One-line-per-check compact output
  ${ASH_MUTED}--parallel,   -p${RST}       Run check groups in parallel (faster)
  ${ASH_MUTED}--no-summary${RST}           Skip health score summary
  ${ASH_MUTED}--save${RST}                 Save results to report file
  ${ASH_MUTED}--help,       -h${RST}        Show this help

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Full deep audit covering all 18 diagnostic categories.
  Typically takes 60-120 seconds depending on system.
  Results are automatically saved for comparison.
EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § DEEP CHECK GROUPS (extends quick checks with thorough inspection)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_full::system() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && [[ "${DOC_CATEGORY_FILTER}" != "system" ]] && return

    # Full system info
    local distro; distro=$(. /etc/os-release 2>/dev/null && printf '%s %s' "${NAME}" "${VERSION_ID:-}")
    doc::result "${SEV_INFO}" "system" "sys.distro" "Distribution" "${distro}" ""

    local kernel; kernel=$(uname -r)
    doc::result "${SEV_INFO}" "system" "sys.kernel" "Kernel" "${kernel}" ""

    # CPU info
    local cpu_model; cpu_model=$(grep 'model name' /proc/cpuinfo 2>/dev/null | head -1 | cut -d: -f2- | sed 's/^ //')
    local cpu_cores; cpu_cores=$(nproc 2>/dev/null || echo "?")
    doc::result "${SEV_INFO}" "system" "sys.cpu" "CPU" \
        "$(ash_truncate "${cpu_model:-unknown}" 40) (${cpu_cores} cores)" ""

    # Memory detailed
    local mem_total mem_avail mem_used
    mem_total=$(awk '/MemTotal/ {printf "%.0f", $2/1024}' /proc/meminfo 2>/dev/null || echo 0)
    mem_avail=$(awk '/MemAvailable/ {printf "%.0f", $2/1024}' /proc/meminfo 2>/dev/null || echo 0)
    mem_used=$(( mem_total - mem_avail ))
    local mem_pct=$(( mem_used * 100 / (mem_total + 1) ))
    local mem_sev; (( mem_pct > 90 )) && mem_sev="${SEV_CRIT}" || \
        { (( mem_pct > 75 )) && mem_sev="${SEV_WARN}" || mem_sev="${SEV_PASS}"; }
    doc::result "${mem_sev}" "system" "sys.memory" "Memory Usage" \
        "${mem_used}MiB / ${mem_total}MiB (${mem_pct}%)" ""

    # Load average
    local load_avg; load_avg=$(cat /proc/loadavg 2>/dev/null | awk '{print $1, $2, $3}')
    local load_1m; load_1m=$(cut -d' ' -f1 /proc/loadavg 2>/dev/null | cut -d. -f1 || echo 0)
    local load_sev; (( load_1m > cpu_cores * 2 )) && load_sev="${SEV_WARN}" || load_sev="${SEV_PASS}"
    doc::result "${load_sev}" "system" "sys.load" "Load Average (1/5/15m)" "${load_avg}" ""

    # Swap
    local swap_total; swap_total=$(awk '/SwapTotal/ {printf "%.0f", $2/1024}' /proc/meminfo 2>/dev/null || echo 0)
    local swap_free; swap_free=$(awk '/SwapFree/ {printf "%.0f", $2/1024}' /proc/meminfo 2>/dev/null || echo 0)
    local swap_sev; [[ "${swap_total}" == "0" ]] && swap_sev="${SEV_INFO}" || swap_sev="${SEV_PASS}"
    doc::result "${swap_sev}" "system" "sys.swap" "Swap" \
        "${swap_free}MiB free / ${swap_total}MiB total" ""

    # Disk space (multiple mounts)
    for mount in "/" "${HOME}" "/tmp"; do
        [[ -d "${mount}" ]] && doc::check_disk_space "system" \
            "sys.disk_$(printf '%s' "${mount}" | tr '/' '_')" "${mount}" 500
    done

    # Uptime
    local uptime_str; uptime_str=$(uptime -p 2>/dev/null || uptime | awk '{print $3,$4}')
    doc::result "${SEV_INFO}" "system" "sys.uptime" "System Uptime" "${uptime_str}" ""

    # Date/time sync
    if command -v timedatectl &>/dev/null; then
        local time_sync; time_sync=$(timedatectl 2>/dev/null | grep 'NTP' | awk '{print $NF}')
        local ts_sev; [[ "${time_sync}" == "yes" || "${time_sync}" == "active" ]] && \
            ts_sev="${SEV_PASS}" || ts_sev="${SEV_WARN}"
        doc::result "${ts_sev}" "system" "sys.ntp" "NTP Sync" \
            "${time_sync:-unknown}" "timedatectl set-ntp true"
    fi
}

_full::wayland() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && [[ "${DOC_CATEGORY_FILTER}" != "wayland" ]] && return

    doc::check_env "wayland" "wy.display"      "WAYLAND_DISPLAY"     "" "${SEV_FAIL}"
    doc::check_env "wayland" "wy.session"      "XDG_SESSION_TYPE"    "wayland" "${SEV_WARN}"
    doc::check_env "wayland" "wy.desktop"      "XDG_CURRENT_DESKTOP" "" "${SEV_INFO}"
    doc::check_env "wayland" "wy.runtime_dir"  "XDG_RUNTIME_DIR"     "" "${SEV_WARN}"
    doc::check_env "wayland" "wy.dbus"         "DBUS_SESSION_BUS_ADDRESS" "" "${SEV_WARN}"

    # GDK backend
    local gdk_backend="${GDK_BACKEND:-}"
    local gdk_sev; [[ "${gdk_backend}" == *"wayland"* ]] && \
        gdk_sev="${SEV_PASS}" || gdk_sev="${SEV_INFO}"
    doc::result "${gdk_sev}" "wayland" "wy.gdk" "GDK_BACKEND" \
        "${gdk_backend:-not set (may use X11 fallback)}" ""

    # Qt platform
    local qt_platform="${QT_QPA_PLATFORM:-}"
    local qt_sev; [[ "${qt_platform}" == *"wayland"* ]] && \
        qt_sev="${SEV_PASS}" || qt_sev="${SEV_INFO}"
    doc::result "${qt_sev}" "wayland" "wy.qt" "QT_QPA_PLATFORM" \
        "${qt_platform:-not set}" ""

    # Mozilla Wayland
    doc::check_env "wayland" "wy.mozilla" "MOZ_ENABLE_WAYLAND" "1" "${SEV_INFO}"

    # Clutter
    doc::check_env "wayland" "wy.clutter" "CLUTTER_BACKEND" "wayland" "${SEV_INFO}"

    # XWayland availability
    doc::check_cmd "wayland" "wy.xwayland" "Xwayland" "false" "paru -S xorg-xwayland"
}

_full::hyprland() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && [[ "${DOC_CATEGORY_FILTER}" != "hyprland" ]] && return

    doc::check_cmd "hyprland" "hl.hyprland" "Hyprland"   "true" "paru -S hyprland"
    doc::check_cmd "hyprland" "hl.hyprctl"  "hyprctl"    "true" "paru -S hyprland"
    doc::check_cmd "hyprland" "hl.swww"     "swww"       "true" "paru -S swww"
    doc::check_cmd "hyprland" "hl.hyprlock" "hyprlock"   "true" "paru -S hyprlock"
    doc::check_cmd "hyprland" "hl.hypridle" "hypridle"   "true" "paru -S hypridle"

    # Config files
    local hl_conf_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/hypr"
    local hl_conf_files=(
        "hyprland.conf:FAIL"
        "env.conf:WARN"
        "keybinds/default.conf:WARN"
        "animations.conf:WARN"
        "decorations.conf:WARN"
        "monitors.conf:WARN"
        "windowrules.conf:WARN"
        "autostart.conf:WARN"
    )
    for cf in "${hl_conf_files[@]}"; do
        local fname="${cf%%:*}" fsev="${cf##*:}"
        local fpath="${hl_conf_dir}/${fname}"
        local fid="hl.conf_$(printf '%s' "${fname}" | tr '/.' '__')"
        doc::check_path "hyprland" "${fid}" "${fpath}" \
            "Config: ${fname}" "${fsev}"
    done

    # Hyprland plugins
    if command -v hyprctl &>/dev/null && hyprctl version &>/dev/null 2>&1; then
        local plugins
        plugins=$(hyprctl plugins list 2>/dev/null | grep -c 'Plugin' || echo 0)
        doc::result "${SEV_INFO}" "hyprland" "hl.plugins_active" \
            "Hyprland Plugins Active" "${plugins} plugin(s) loaded" ""
    fi

    # XDPH portal
    doc::check_cmd "hyprland" "hl.xdph" "xdg-desktop-portal-hyprland" "true" \
        "paru -S xdg-desktop-portal-hyprland"
}

_full::gpu() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && [[ "${DOC_CATEGORY_FILTER}" != "gpu" ]] && return

    # GPU enumeration via DRM
    if [[ -d /sys/class/drm ]]; then
        local drm_cards; drm_cards=$(ls /sys/class/drm/card*/device/vendor 2>/dev/null | wc -l)
        doc::result "${SEV_INFO}" "gpu" "gpu.drm_cards" "DRM GPU Count" \
            "${drm_cards} card(s) in /sys/class/drm" ""
    fi

    # NVIDIA deep check
    if command -v nvidia-smi &>/dev/null; then
        local nv_driver; nv_driver=$(nvidia-smi --query-gpu=driver_version \
            --format=csv,noheader 2>/dev/null | head -1)
        local nv_temp; nv_temp=$(nvidia-smi --query-gpu=temperature.gpu \
            --format=csv,noheader 2>/dev/null | head -1 || echo "?")
        local nv_mem_used; nv_mem_used=$(nvidia-smi --query-gpu=memory.used \
            --format=csv,noheader 2>/dev/null | head -1 || echo "?")
        local nv_mem_total; nv_mem_total=$(nvidia-smi --query-gpu=memory.total \
            --format=csv,noheader 2>/dev/null | head -1 || echo "?")

        doc::result "${SEV_PASS}" "gpu" "gpu.nvidia_driver" "NVIDIA Driver" \
            "v${nv_driver}" ""
        doc::result "${SEV_INFO}" "gpu" "gpu.nvidia_temp" "NVIDIA Temperature" \
            "${nv_temp}°C" ""
        doc::result "${SEV_INFO}" "gpu" "gpu.nvidia_mem" "NVIDIA VRAM" \
            "${nv_mem_used} / ${nv_mem_total}" ""

        # NVIDIA Wayland env vars required
        local nv_envs=(
            "LIBVA_DRIVER_NAME:nvidia"
            "__GLX_VENDOR_LIBRARY_NAME:nvidia"
            "WLR_NO_HARDWARE_CURSORS:1"
        )
        for env_entry in "${nv_envs[@]}"; do
            local ekey="${env_entry%%:*}" eval="${env_entry##*:}"
            local eid="gpu.nv_env_$(printf '%s' "${ekey}" | tr '[:upper:]' '[:lower:]')"
            local eval_set="${!ekey:-}"
            local env_sev; [[ "${eval_set}" == "${eval}" ]] && \
                env_sev="${SEV_PASS}" || env_sev="${SEV_INFO}"
            doc::result "${env_sev}" "gpu" "${eid}" "Env: ${ekey}" \
                "${eval_set:-not set (expected ${eval})}" ""
        done
    fi

    # Vulkan
    if command -v vulkaninfo &>/dev/null; then
        local vk_device; vk_device=$(vulkaninfo 2>/dev/null | \
            grep 'deviceName' | head -1 | cut -d= -f2 | sed 's/^ //' || echo "unknown")
        doc::result "${SEV_PASS}" "gpu" "gpu.vulkan" "Vulkan Device" \
            "$(ash_truncate "${vk_device}" 50)" ""
    else
        doc::result "${SEV_INFO}" "gpu" "gpu.vulkan" "Vulkan Info" \
            "vulkan-tools not installed" "paru -S vulkan-tools"
    fi

    # VA-API
    if command -v vainfo &>/dev/null; then
        if vainfo &>/dev/null 2>&1; then
            doc::result "${SEV_PASS}" "gpu" "gpu.vaapi" "VA-API Hardware Decode" "Available ✓" ""
        else
            doc::result "${SEV_INFO}" "gpu" "gpu.vaapi" "VA-API Hardware Decode" \
                "Not available (may affect video playback)" ""
        fi
    fi
}

_full::config() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && [[ "${DOC_CATEGORY_FILTER}" != "config" ]] && return

    local cfg_dir="${XDG_CONFIG_HOME:-${HOME}/.config}"

    # ASH main config
    local ash_conf="${cfg_dir}/ash/ash.conf"
    doc::check_path "config" "cfg.ash_conf" "${ash_conf}" "ASH main config" "${SEV_WARN}" \
        "ash config validate --fix"

    # Critical app configs
    local -a config_checks=(
        "waybar/config.jsonc:waybar config:WARN"
        "rofi/config.rasi:rofi config:WARN"
        "kitty/kitty.conf:kitty config:WARN"
        "fish/config.fish:fish config:WARN"
        "dunst/dunstrc:dunst config:WARN"
        "btop/btop.conf:btop config:INFO"
        "starship/starship.toml:starship config:INFO"
    )

    for entry in "${config_checks[@]}"; do
        IFS=':' read -r rel_path label sev <<< "${entry}"
        local full_path="${cfg_dir}/${rel_path}"
        local cid="cfg.$(printf '%s' "${rel_path}" | tr '/.' '__')"
        doc::check_path "config" "${cid}" "${full_path}" "${label}" "${sev}"
    done

    # Validate ASH config syntax
    if [[ -f "${ash_conf}" ]]; then
        local bad_lines; bad_lines=$(grep -cE '^\s*[^#=][^=]*$' "${ash_conf}" 2>/dev/null || echo 0)
        if (( bad_lines > 0 )); then
            doc::result "${SEV_WARN}" "config" "cfg.syntax" "ASH Config Syntax" \
                "${bad_lines} potentially malformed line(s)" "ash config validate"
        else
            doc::result "${SEV_PASS}" "config" "cfg.syntax" "ASH Config Syntax" "Valid ✓" ""
        fi
    fi
}

_full::theme() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && [[ "${DOC_CATEGORY_FILTER}" != "theme" ]] && return

    local ash_data="${ASH_DATA_DIR:-${HOME}/.local/share/ash}"

    # Current theme
    local current_theme_file="${ash_data}/state/current-theme.json"
    if [[ -f "${current_theme_file}" ]]; then
        local theme_name; theme_name=$(jq -r '.name // "unknown"' "${current_theme_file}" 2>/dev/null)
        doc::result "${SEV_INFO}" "theme" "thm.current" "Active Theme" "${theme_name}" ""
    else
        doc::result "${SEV_WARN}" "theme" "thm.current" "Active Theme" \
            "State file missing" "ash theme apply catppuccin-mocha"
    fi

    # Theme directory
    local theme_dir="${ash_data}/themes"
    if [[ -d "${theme_dir}" ]]; then
        local theme_count; theme_count=$(find "${theme_dir}" -name "theme.conf" 2>/dev/null | wc -l)
        doc::result "${SEV_INFO}" "theme" "thm.count" "Installed Themes" \
            "${theme_count} theme(s)" ""
    else
        doc::result "${SEV_WARN}" "theme" "thm.dir" "Theme Directory" \
            "Missing: ${theme_dir}" ""
    fi

    # Color extract dependencies
    doc::check_cmd "theme" "thm.magick" "magick" "false" "paru -S imagemagick"
    doc::check_cmd "theme" "thm.matugen" "matugen" "false" "paru -S matugen"

    # GTK theme
    local gtk_theme; gtk_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null \
        | tr -d "'")
    local gtk_sev; [[ -n "${gtk_theme}" ]] && gtk_sev="${SEV_INFO}" || gtk_sev="${SEV_WARN}"
    doc::result "${gtk_sev}" "theme" "thm.gtk" "GTK Theme" \
        "${gtk_theme:-not configured}" ""

    # Cursor
    local cursor_theme; cursor_theme=$(gsettings get org.gnome.desktop.interface cursor-theme \
        2>/dev/null | tr -d "'")
    doc::result "${SEV_INFO}" "theme" "thm.cursor" "Cursor Theme" \
        "${cursor_theme:-system default}" ""

    # Icon theme
    local icon_theme; icon_theme=$(gsettings get org.gnome.desktop.interface icon-theme \
        2>/dev/null | tr -d "'")
    doc::result "${SEV_INFO}" "theme" "thm.icons" "Icon Theme" \
        "${icon_theme:-system default}" ""
}

_full::plugins() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && [[ "${DOC_CATEGORY_FILTER}" != "plugins" ]] && return

    local plugins_dir="${ASH_DATA_DIR:-${HOME}/.local/share/ash}/plugins"

    if [[ ! -d "${plugins_dir}" ]]; then
        doc::result "${SEV_INFO}" "plugins" "plg.dir" "Plugin Directory" \
            "Not created yet (no plugins installed)" ""
        return
    fi

    local total_plugins; total_plugins=$(find "${plugins_dir}" -name "plugin.json" 2>/dev/null | wc -l)
    doc::result "${SEV_INFO}" "plugins" "plg.count" "Installed Plugins" \
        "${total_plugins} plugin(s)" ""

    # Check each plugin
    local p_ok=0 p_err=0
    while IFS= read -r plugin_json; do
        local pname; pname=$(jq -r '.name // "unknown"' "${plugin_json}" 2>/dev/null)
        local pver; pver=$(jq -r '.version // "?"' "${plugin_json}" 2>/dev/null)
        local penabled; penabled=$(jq -r '.enabled // false' "${plugin_json}" 2>/dev/null)
        local pid; pid="plg.$(printf '%s' "${pname}" | tr -s ' ' '_' | tr '[:upper:]' '[:lower:]')"

        if [[ "${penabled}" == "true" ]]; then
            doc::result "${SEV_PASS}" "plugins" "${pid}" \
                "Plugin: ${pname}" "v${pver} — enabled" ""
            (( p_ok++ ))
        else
            doc::result "${SEV_INFO}" "plugins" "${pid}" \
                "Plugin: ${pname}" "v${pver} — disabled" ""
        fi
    done < <(find "${plugins_dir}" -name "plugin.json" 2>/dev/null)
}

_full::performance() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && [[ "${DOC_CATEGORY_FILTER}" != "performance" ]] && return

    # CPU governor
    local governor_path="/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
    if [[ -f "${governor_path}" ]]; then
        local governor; governor=$(cat "${governor_path}" 2>/dev/null)
        local gov_sev; [[ "${governor}" == "performance" || "${governor}" == "schedutil" ]] && \
            gov_sev="${SEV_PASS}" || gov_sev="${SEV_INFO}"
        doc::result "${gov_sev}" "performance" "perf.governor" "CPU Governor" \
            "${governor}" ""
    fi

    # THP (Transparent Huge Pages)
    local thp_path="/sys/kernel/mm/transparent_hugepage/enabled"
    if [[ -f "${thp_path}" ]]; then
        local thp; thp=$(cat "${thp_path}" 2>/dev/null | grep -oE '\[.+\]' | tr -d '[]')
        doc::result "${SEV_INFO}" "performance" "perf.thp" "Transparent Huge Pages" \
            "${thp:-unknown}" ""
    fi

    # Gamemode
    doc::check_cmd "performance" "perf.gamemode" "gamemoded" "false" "paru -S gamemode"
    if pgrep gamemoded &>/dev/null; then
        doc::result "${SEV_INFO}" "performance" "perf.gamemode_running" \
            "Gamemode Daemon" "Running" ""
    fi

    # ZRAM
    if [[ -d /sys/class/zram-control ]]; then
        local zram_devs; zram_devs=$(ls /sys/class/zram-control/ 2>/dev/null | wc -l)
        doc::result "${SEV_INFO}" "performance" "perf.zram" "ZRAM Devices" \
            "${zram_devs} device(s)" ""
    fi

    # Irqbalance
    if pgrep irqbalance &>/dev/null; then
        doc::result "${SEV_PASS}" "performance" "perf.irqbalance" "IRQ Balance" "Running ✓" ""
    else
        doc::result "${SEV_INFO}" "performance" "perf.irqbalance" "IRQ Balance" \
            "Not running (optional)" ""
    fi
}

_full::security() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && [[ "${DOC_CATEGORY_FILTER}" != "security" ]] && return

    # SSH dir permissions
    if [[ -d "${HOME}/.ssh" ]]; then
        doc::check_perm "security" "sec.ssh_dir"  "${HOME}/.ssh"              "700" ""
        doc::check_perm "security" "sec.ssh_key"  "${HOME}/.ssh/id_ed25519"   "600" "" 2>/dev/null || true
        doc::check_perm "security" "sec.auth_key" "${HOME}/.ssh/authorized_keys" "600" "" 2>/dev/null || true
    fi

    # GPG agent
    if pgrep gpg-agent &>/dev/null; then
        doc::result "${SEV_PASS}" "security" "sec.gpg" "GPG Agent" "Running ✓" ""
    else
        doc::result "${SEV_INFO}" "security" "sec.gpg" "GPG Agent" \
            "Not running (optional)" ""
    fi

    # Firewall
    local fw_active=false fw_name=""
    if command -v ufw &>/dev/null && ufw status 2>/dev/null | grep -q "active"; then
        fw_active=true; fw_name="ufw"
    elif command -v firewall-cmd &>/dev/null && \
         firewall-cmd --state 2>/dev/null | grep -q "running"; then
        fw_active=true; fw_name="firewalld"
    elif command -v nft &>/dev/null && nft list ruleset 2>/dev/null | grep -q chain; then
        fw_active=true; fw_name="nftables"
    fi
    local fw_sev; "${fw_active}" && fw_sev="${SEV_PASS}" || fw_sev="${SEV_INFO}"
    doc::result "${fw_sev}" "security" "sec.firewall" "Firewall" \
        "$( "${fw_active}" && printf '%s active' "${fw_name}" || printf 'None detected')" ""

    # DNS-over-HTTPS / encrypted DNS
    local systemd_resolved=false
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        systemd_resolved=true
        local dnsovertls; dnsovertls=$(resolvectl status 2>/dev/null | grep -i 'DNS over TLS' | awk '{print $NF}')
        local dns_sev; [[ "${dnsovertls}" == "yes" || "${dnsovertls}" == "opportunistic" ]] && \
            dns_sev="${SEV_PASS}" || dns_sev="${SEV_INFO}"
        doc::result "${dns_sev}" "security" "sec.dot" "DNS over TLS" \
            "${dnsovertls:-unknown}" ""
    fi

    # Secrets tool
    doc::check_cmd "security" "sec.gnome_keyring" "gnome-keyring-daemon" "false" \
        "paru -S gnome-keyring"
    doc::check_cmd "security" "sec.keepassxc" "keepassxc" "false" \
        "paru -S keepassxc"
}

_full::permissions() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && [[ "${DOC_CATEGORY_FILTER}" != "permissions" ]] && return

    # Critical ASH dirs
    local ash_dirs=(
        "${ASH_DATA_DIR:-${HOME}/.local/share/ash}:700"
        "${ASH_STATE_DIR:-${HOME}/.local/state/ash}:700"
        "${ASH_CACHE_DIR:-${HOME}/.cache/ash}:700"
        "${XDG_CONFIG_HOME:-${HOME}/.config}/ash:700"
    )
    for entry in "${ash_dirs[@]}"; do
        local dpath="${entry%%:*}" expected_perm="${entry##*:}"
        local did; did="perm.$(basename "${dpath}")"
        [[ -d "${dpath}" ]] && \
            doc::check_perm "permissions" "${did}" "${dpath}" "${expected_perm}" ""
    done

    # Scripts are executable
    local ash_bin="${_DOC_DIR}/../../ash"
    if [[ -f "${ash_bin}" ]]; then
        if [[ -x "${ash_bin}" ]]; then
            doc::result "${SEV_PASS}" "permissions" "perm.ash_bin" "ASH Binary Executable" "✓" ""
        else
            doc::result "${SEV_FAIL}" "permissions" "perm.ash_bin" "ASH Binary Executable" \
                "Not executable" "chmod +x ${ash_bin}"
        fi
    fi

    # polkit agent
    local polkit_agents=("polkit-gnome-authentication-agent-1" "lxqt-policykit-agent" \
                         "/usr/lib/polkit-kde-agent-1")
    local polkit_found=false
    for agent in "${polkit_agents[@]}"; do
        pgrep -f "$(basename "${agent}")" &>/dev/null && { polkit_found=true; break; }
    done
    local pol_sev; "${polkit_found}" && pol_sev="${SEV_PASS}" || pol_sev="${SEV_WARN}"
    doc::result "${pol_sev}" "permissions" "perm.polkit" "Polkit Agent" \
        "$( "${polkit_found}" && printf 'Running ✓' || printf 'Not running')" \
        "paru -S polkit-gnome"
}

_full::services() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && [[ "${DOC_CATEGORY_FILTER}" != "services" ]] && return

    local ash_services=(
        "ash-hot-reload.service:false"
        "ash-ipc-server.service:false"
        "ash-weather-fetch.timer:false"
        "ash-update-check.timer:false"
        "ash-snapshot-auto.timer:false"
        "ash-backup-daily.timer:false"
    )

    for entry in "${ash_services[@]}"; do
        local svc="${entry%%:*}" required="${entry##*:}"
        local sid; sid="svc.$(printf '%s' "${svc}" | tr '.-' '__')"
        doc::check_service "services" "${sid}" "${svc}" "${required}"
    done

    # System services
    local sys_services=("systemd-logind.service" "dbus.service" "NetworkManager.service")
    for svc in "${sys_services[@]}"; do
        local sid; sid="svc.sys_$(printf '%s' "${svc%%.*}" | tr '-' '_')"
        if systemctl is-active --quiet "${svc}" 2>/dev/null; then
            doc::result "${SEV_PASS}" "services" "${sid}" "Service: ${svc}" "Active ✓" ""
        else
            doc::result "${SEV_WARN}" "services" "${sid}" "Service: ${svc}" \
                "Not active" "systemctl start ${svc}"
        fi
    done
}

_full::portals() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && [[ "${DOC_CATEGORY_FILTER}" != "portals" ]] && return

    doc::check_cmd "portals" "prt.xdph" "xdg-desktop-portal-hyprland" "true" \
        "paru -S xdg-desktop-portal-hyprland"
    doc::check_cmd "portals" "prt.xdpw" "xdg-desktop-portal-wlr" "false" \
        "paru -S xdg-desktop-portal-wlr"
    doc::check_cmd "portals" "prt.xdpg" "xdg-desktop-portal-gtk" "false" \
        "paru -S xdg-desktop-portal-gtk"

    # Portal service running
    if systemctl --user is-active --quiet xdg-desktop-portal 2>/dev/null; then
        doc::result "${SEV_PASS}" "portals" "prt.svc" "XDG Portal Service" "Active ✓" ""
    else
        doc::result "${SEV_WARN}" "portals" "prt.svc" "XDG Portal Service" \
            "Not running — screen share / file pickers may fail" \
            "systemctl --user start xdg-desktop-portal"
    fi

    # HYPRLAND portal specifically
    if systemctl --user is-active --quiet xdg-desktop-portal-hyprland 2>/dev/null; then
        doc::result "${SEV_PASS}" "portals" "prt.hyprland" \
            "Hyprland Portal Service" "Active ✓" ""
    else
        doc::result "${SEV_WARN}" "portals" "prt.hyprland" \
            "Hyprland Portal Service" "Not running" \
            "systemctl --user start xdg-desktop-portal-hyprland"
    fi
}

_full::dependencies() {
    [[ -n "${DOC_CATEGORY_FILTER}" ]] && [[ "${DOC_CATEGORY_FILTER}" != "dependencies" ]] && return

    # Python
    if command -v python3 &>/dev/null; then
        local py_ver; py_ver=$(python3 --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        local py_sev; python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3,8) else 1)' 2>/dev/null && \
            py_sev="${SEV_PASS}" || py_sev="${SEV_WARN}"
        doc::result "${py_sev}" "dependencies" "dep.python" "Python 3" \
            "v${py_ver} (min 3.8 required)" ""
    else
        doc::result "${SEV_FAIL}" "dependencies" "dep.python" "Python 3" \
            "Not found" "paru -S python"
    fi

    # Node.js (for AGS/web dashboard)
    if command -v node &>/dev/null; then
        local node_ver; node_ver=$(node --version 2>/dev/null | tr -d 'v')
        doc::result "${SEV_PASS}" "dependencies" "dep.node" "Node.js" \
            "v${node_ver}" ""
    else
        doc::result "${SEV_INFO}" "dependencies" "dep.node" "Node.js" \
            "Not installed (required for AGS/web dashboard)" "paru -S nodejs"
    fi

    # Rust
    if command -v rustc &>/dev/null; then
        local rust_ver; rust_ver=$(rustc --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        doc::result "${SEV_PASS}" "dependencies" "dep.rust" "Rust" "v${rust_ver}" ""
    else
        doc::result "${SEV_INFO}" "dependencies" "dep.rust" "Rust" \
            "Not installed (some tools require it)" \
            "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    fi

    # Go
    if command -v go &>/dev/null; then
        local go_ver; go_ver=$(go version 2>/dev/null | grep -oE 'go[0-9]+\.[0-9]+\.[0-9]+')
        doc::result "${SEV_PASS}" "dependencies" "dep.go" "Go" "${go_ver}" ""
    else
        doc::result "${SEV_INFO}" "dependencies" "dep.go" "Go" \
            "Not installed" "paru -S go"
    fi

    # jq (critical for ASH)
    doc::check_cmd "dependencies" "dep.jq" "jq" "true" "paru -S jq"

    # Package manager
    local pkg_mgr=""
    for pm in paru yay pacman dnf apt zypper xbps-install emerge; do
        command -v "${pm}" &>/dev/null && { pkg_mgr="${pm}"; break; }
    done
    local pm_sev; [[ -n "${pkg_mgr}" ]] && pm_sev="${SEV_PASS}" || pm_sev="${SEV_WARN}"
    doc::result "${pm_sev}" "dependencies" "dep.pkg_mgr" "Package Manager" \
        "${pkg_mgr:-none detected}" ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
doctor::full() {
    local issues_only=false compact=false no_summary=false
    local parallel=false save_report=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)      doctor::full::help; return 0 ;;
            --issues-only)  issues_only=true; shift ;;
            --compact|-c)   compact=true; shift ;;
            --parallel|-p)  parallel=true; shift ;;
            --no-summary)   no_summary=true; shift ;;
            --save)         save_report=true; shift ;;
            -*)             log::error "Unknown option: $1"; return 1 ;;
            *)              shift ;;
        esac
    done

    local start_ts; start_ts=$(date +%s%N)

    # ── Header ────────────────────────────────────────────────────────────────
    if [[ "${DOC_QUIET}" == "false" ]] && [[ "${DOC_JSON_OUTPUT}" == "false" ]]; then
        log::blank
        printf '  %s🩺  ASH Doctor — Full Audit%s\n' "${BOLD}${ASH_PRIMARY}" "${RST}"
        printf '  %sRunning comprehensive system check (200+ checks)…%s\n\n' \
            "${ASH_MUTED}" "${RST}"
    fi

    # ── Check groups ──────────────────────────────────────────────────────────
    # Source quick checks first (inherit all _quick:: functions)
    source "${_DOC_DIR}/quick.sh" 2>/dev/null || true

    local groups=(
        _quick::system      _full::system
        _quick::wayland     _full::wayland
        _quick::hyprland    _full::hyprland
        _quick::gpu         _full::gpu
        _quick::audio
        _quick::network
        _quick::fonts
        _quick::tools_critical
        _full::config
        _full::theme
        _full::plugins
        _full::performance
        _full::security
        _full::permissions
        _full::services
        _full::portals
        _full::dependencies
    )

    # Deduplicate (run _full:: which already covers _quick:: for overlapping cats)
    local unique_groups=()
    for g in "${groups[@]}"; do
        local base="${g#_quick::}"
        local has_full=false
        for og in "${groups[@]}"; do
            [[ "${og}" == "_full::${base}" ]] && { has_full=true; break; }
        done
        # Only include _quick:: if no _full:: equivalent
        if [[ "${g}" == _quick::* ]] && [[ "${has_full}" == "true" ]]; then
            continue
        fi
        unique_groups+=("${g}")
    done

    local gi=0 total_groups="${#unique_groups[@]}"

    for group_fn in "${unique_groups[@]}"; do
        (( gi++ ))
        [[ "${DOC_QUIET}" == "false" ]] && [[ "${DOC_JSON_OUTPUT}" == "false" ]] && \
            ash_progress "${gi}" "${total_groups}" \
                "$(printf '%s' "${group_fn}" | sed 's/_quick:://;s/_full:://')" 30
        "${group_fn}" 2>/dev/null || log::debug "Group ${group_fn} returned error"
    done

    [[ "${DOC_QUIET}" == "false" ]] && [[ "${DOC_JSON_OUTPUT}" == "false" ]] && printf '\n'

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

    # Save named report
    if [[ "${save_report}" == "true" ]]; then
        source "${_DOC_DIR}/report.sh"
        local report_path
        report_path="${DOC_REPORT_DIR}/full-$(date '+%Y%m%d-%H%M%S').json"
        doctor::report --format json --output "${report_path}" --quiet
        log::info "Report saved: ${report_path}"
    fi

    (( DOC_CRIT_COUNT > 0 || DOC_FAIL_COUNT > 0 )) && return 1 || return 0
}
