#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ DOCTOR CHECK — HYPRLAND                                    ║
# ║  Hyprland compositor: version, runtime, config, animations, keybinds, monitors        ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════╝
# Sourced as a library by _common.sh, so shell options are only
# tightened when this file is EXECUTED directly. A sourced file that
# sets -e/-u rewrites the options of whoever loaded it — the first
# module would make the whole doctor process abort on any non-zero
# status or unset variable.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
fi
IFS=$'\n\t'

# Guard against being sourced outside the doctor environment. This must NOT
# `exit`: a sourced file that exits takes its caller with it, so one missed
# dependency would kill doctor and the whole ash process instead of skipping one
# module. `return 0` leaves the module unloaded, which _ash_check_load_all
# reports as a skip.
if [[ -z "${DOC_VERSION:-}" ]]; then
    printf 'SKIP: %s needs the ash doctor environment — not sourced\n' "${BASH_SOURCE[0]##*/}" >&2
    return 0
fi

readonly HL_CONF_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/hypr"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
check_hyprland::binaries() {
    local cat="hyprland"

    # ── Core binaries ─────────────────────────────────────────────────────────
    doc::check_cmd "${cat}" "hl.bin.hyprland" "Hyprland"   "true" "paru -S hyprland"
    doc::check_cmd "${cat}" "hl.bin.hyprctl"  "hyprctl"    "true" "paru -S hyprland"
    doc::check_cmd "${cat}" "hl.bin.hyprpm"   "hyprpm"     "false" "paru -S hyprland"
    doc::check_cmd "${cat}" "hl.bin.hyprlock" "hyprlock"   "true" "paru -S hyprlock"
    doc::check_cmd "${cat}" "hl.bin.hypridle" "hypridle"   "true" "paru -S hypridle"
    doc::check_cmd "${cat}" "hl.bin.hyprpaper" "hyprpaper" "false" "paru -S hyprpaper"
    doc::check_cmd "${cat}" "hl.bin.swww"     "swww"       "true" "paru -S swww"
    doc::check_cmd "${cat}" "hl.bin.xdph"     "xdg-desktop-portal-hyprland" "true" \
        "paru -S xdg-desktop-portal-hyprland"

    # ── Hyprland version ──────────────────────────────────────────────────────
    if command -v Hyprland &>/dev/null; then
        local hl_ver
        hl_ver=$(Hyprland --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 \
                 || hyprctl version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 \
                 || echo "unknown")
        local hl_maj; hl_maj=$(printf '%s' "${hl_ver}" | cut -d. -f1)
        local hl_min; hl_min=$(printf '%s' "${hl_ver}" | cut -d. -f2)
        local ver_sev="${SEV_PASS}"
        # Require ≥ 0.40 for full feature support
        { (( hl_maj == 0 )) && (( hl_min < 40 )); } && ver_sev="${SEV_WARN}"
        doc::result "${ver_sev}" "${cat}" "hl.bin.version" \
            "🪟 Hyprland Version" "v${hl_ver}" \
            "$( [[ "${ver_sev}" == "${SEV_WARN}" ]] \
                && printf 'Update to ≥0.40 for all ASH features: paru -Su hyprland' \
                || printf '')"
    fi
}

check_hyprland::runtime() {
    local cat="hyprland"

    # ── Instance running ──────────────────────────────────────────────────────
    if command -v hyprctl &>/dev/null && hyprctl version &>/dev/null 2>&1; then
        local hl_pid; hl_pid=$(pgrep -x Hyprland | head -1 || echo "?")
        doc::result "${SEV_PASS}" "${cat}" "hl.run.active" \
            "🪟 Hyprland Running" "PID ${hl_pid} ✓" ""

        # ── Monitors ──────────────────────────────────────────────────────────
        local monitor_count
        monitor_count=$(hyprctl monitors 2>/dev/null | grep -c '^Monitor' || echo 0)
        local mon_sev; (( monitor_count >= 1 )) && mon_sev="${SEV_PASS}" || mon_sev="${SEV_WARN}"
        doc::result "${mon_sev}" "${cat}" "hl.run.monitors" \
            "🖥 Active Monitors" "${monitor_count} connected" ""

        # ── Workspaces ────────────────────────────────────────────────────────
        local ws_count
        ws_count=$(hyprctl workspaces 2>/dev/null | grep -c '^workspace' || echo 0)
        doc::result "${SEV_INFO}" "${cat}" "hl.run.workspaces" \
            "🪟 Active Workspaces" "${ws_count} open" ""

        # ── Active window ─────────────────────────────────────────────────────
        local active_class
        active_class=$(hyprctl activewindow 2>/dev/null | awk '/class/{print $2}' | head -1 || echo "none")
        doc::result "${SEV_INFO}" "${cat}" "hl.run.activewin" \
            "🪟 Active Window Class" "${active_class:-none}" ""

        # ── IPC socket ────────────────────────────────────────────────────────
        local ipc_sock="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}"
        if [[ -d "${XDG_RUNTIME_DIR:-}/hypr" ]]; then
            doc::result "${SEV_PASS}" "${cat}" "hl.run.ipc" \
                "🔌 Hyprland IPC Socket" "Available ✓" ""
        else
            doc::result "${SEV_INFO}" "${cat}" "hl.run.ipc" \
                "🔌 Hyprland IPC Socket" "Not running (outside session)" ""
        fi

        # ── Cursor scale ──────────────────────────────────────────────────────
        local cursor_size
        cursor_size=$(hyprctl getoption cursor:default_monitor 2>/dev/null | \
            awk '/int:/{print $2}' | head -1 || echo "?")
        doc::result "${SEV_INFO}" "${cat}" "hl.run.cursor" \
            "🖱 Cursor Monitor" "${cursor_size:-default}" ""
    else
        doc::result "${SEV_INFO}" "${cat}" "hl.run.active" \
            "🪟 Hyprland Running" "Not active (may be normal outside session)" ""
    fi
}

check_hyprland::config_files() {
    local cat="hyprland"

    # ── Required config files ─────────────────────────────────────────────────
    local -a required_conf=(
        "hyprland.conf:FAIL:Main Hyprland config"
        "env.conf:WARN:Environment variables"
        "binds.conf:WARN:Keybindings"
        "animations.conf:WARN:Animation settings"
        "decorations.conf:WARN:Window decorations"
        "monitors.conf:WARN:Monitor layout"
        "windowrules.conf:WARN:Window rules"
        "autostart.conf:WARN:Autostart apps"
        "input.conf:WARN:Input settings"
        "keybinds/default.conf:WARN:Default keybinds"
    )

    for entry in "${required_conf[@]}"; do
        IFS=':' read -r fname sev desc <<< "${entry}"
        local fpath="${HL_CONF_DIR}/${fname}"
        local fid; fid="hl.conf.$(printf '%s' "${fname}" | tr '/.' '__' | tr '-' '_')"
        doc::check_path "${cat}" "${fid}" "${fpath}" "⚙ Config: ${fname}" "${sev}"
    done

    # ── Config syntax check ───────────────────────────────────────────────────
    local main_conf="${HL_CONF_DIR}/hyprland.conf"
    if [[ -f "${main_conf}" ]]; then
        # Check for common syntax errors: unclosed braces
        local open_brace close_brace
        open_brace=$(grep -c '{' "${main_conf}" 2>/dev/null || echo 0)
        close_brace=$(grep -c '}' "${main_conf}" 2>/dev/null || echo 0)
        if (( open_brace == close_brace )); then
            doc::result "${SEV_PASS}" "${cat}" "hl.conf.braces" \
                "⚙ Config Brace Balance" "Balanced ✓ ({${open_brace} / }${close_brace})" ""
        else
            doc::result "${SEV_WARN}" "${cat}" "hl.conf.braces" \
                "⚙ Config Brace Balance" \
                "Unbalanced: {${open_brace} opens vs }${close_brace} closes" ""
        fi

        # Check file size (very large = potential recursion)
        local conf_size; conf_size=$(wc -l < "${main_conf}" 2>/dev/null || echo 0)
        doc::result "${SEV_INFO}" "${cat}" "hl.conf.size" \
            "⚙ Config Lines (main)" "${conf_size} lines" ""
    fi

    # ── ASH theme integration ──────────────────────────────────────────────────
    local ash_theme_conf="${HL_CONF_DIR}/themes/active-theme.conf"
    doc::check_path "${cat}" "hl.conf.ash_theme" "${ash_theme_conf}" \
        "🎨 ASH Theme Colors" "${SEV_WARN}" \
        "ash theme apply catppuccin-mocha"
}

check_hyprland::config_settings() {
    local cat="hyprland"
    local main_conf="${HL_CONF_DIR}/hyprland.conf"
    [[ ! -f "${main_conf}" ]] && return

    # ── Animation ─────────────────────────────────────────────────────────────
    local anim_enabled; anim_enabled=$(grep -E '^\s*enabled\s*=' "${HL_CONF_DIR}/animations.conf" \
        2>/dev/null | tail -1 | awk -F= '{print $2}' | tr -d ' ')
    local anim_sev; [[ "${anim_enabled}" == "true" || "${anim_enabled}" == "yes" ]] && \
        anim_sev="${SEV_PASS}" || anim_sev="${SEV_INFO}"
    doc::result "${anim_sev}" "${cat}" "hl.set.anim" \
        "✨ Animations" "${anim_enabled:-not checked}" ""

    # ── Blur ─────────────────────────────────────────────────────────────────
    local blur_enabled; blur_enabled=$(grep -rE '^\s*enabled\s*=.*true' \
        "${HL_CONF_DIR}/decorations.conf" 2>/dev/null | head -1)
    doc::result "${SEV_INFO}" "${cat}" "hl.set.blur" \
        "🌫 Blur Enabled" \
        "$( [[ -n "${blur_enabled}" ]] && printf 'Enabled' || printf 'Disabled / not set')" ""

    # ── Gaps ─────────────────────────────────────────────────────────────────
    for gap_key in "gaps_in" "gaps_out"; do
        local gap_val; gap_val=$(grep -rE "^\s*${gap_key}\s*=" \
            "${HL_CONF_DIR}/" 2>/dev/null | head -1 | awk -F= '{print $2}' | tr -d ' ')
        doc::result "${SEV_INFO}" "${cat}" "hl.set.${gap_key}" \
            "⚙ ${gap_key}" "${gap_val:-not set}" ""
    done

    # ── Rounding ──────────────────────────────────────────────────────────────
    local rounding; rounding=$(grep -rE "^\s*rounding\s*=" \
        "${HL_CONF_DIR}/" 2>/dev/null | head -1 | awk -F= '{print $2}' | tr -d ' ')
    doc::result "${SEV_INFO}" "${cat}" "hl.set.rounding" \
        "⚙ Window Rounding" "${rounding:-not set}" ""

    # ── Keybinds count ────────────────────────────────────────────────────────
    local bind_count; bind_count=$(grep -rhcE '^\s*bind\s*=' \
        "${HL_CONF_DIR}/" 2>/dev/null | awk '{s+=$1} END {print s+0}')
    local bind_sev; (( bind_count >= 20 )) && bind_sev="${SEV_PASS}" || bind_sev="${SEV_WARN}"
    doc::result "${bind_sev}" "${cat}" "hl.set.binds" \
        "⌨ Keybinds Defined" "${bind_count} bindings" ""

    # ── Monitor config ────────────────────────────────────────────────────────
    local mon_count; mon_count=$(grep -rE '^\s*monitor\s*=' \
        "${HL_CONF_DIR}/" 2>/dev/null | wc -l)
    doc::result "${SEV_INFO}" "${cat}" "hl.set.monitors" \
        "🖥 Monitor Rules" "${mon_count} rule(s)" ""
}

check_hyprland::ecosystem() {
    local cat="hyprland"

    # ── hypridle ──────────────────────────────────────────────────────────────
    local idle_conf="${XDG_CONFIG_HOME:-${HOME}/.config}/hypridle/hypridle.conf"
    doc::check_path "${cat}" "hl.eco.idle_conf" "${idle_conf}" \
        "😴 hypridle Config" "${SEV_WARN}" ""
    if pgrep -x hypridle &>/dev/null; then
        doc::result "${SEV_PASS}" "${cat}" "hl.eco.idle_running" \
            "😴 hypridle Running" "Active ✓" ""
    else
        doc::result "${SEV_INFO}" "${cat}" "hl.eco.idle_running" \
            "😴 hypridle Running" "Not running — auto-lock inactive" \
            "systemctl --user start hypridle"
    fi

    # ── hyprlock ──────────────────────────────────────────────────────────────
    local lock_conf="${XDG_CONFIG_HOME:-${HOME}/.config}/hyprlock/hyprlock.conf"
    doc::check_path "${cat}" "hl.eco.lock_conf" "${lock_conf}" \
        "🔒 hyprlock Config" "${SEV_WARN}" ""

    # ── swww daemon ───────────────────────────────────────────────────────────
    if pgrep -x swww-daemon &>/dev/null; then
        doc::result "${SEV_PASS}" "${cat}" "hl.eco.swww" \
            "🖼 swww Daemon" "Running ✓" ""
    else
        doc::result "${SEV_WARN}" "${cat}" "hl.eco.swww" \
            "🖼 swww Daemon" "Not running — wallpaper system inactive" \
            "swww-daemon &"
    fi

    # ── wallpaper file ────────────────────────────────────────────────────────
    local wall_state="${ASH_DATA_DIR:-${HOME}/.local/share/ash}/state/current-wallpaper"
    doc::check_path "${cat}" "hl.eco.wallpaper" "${wall_state}" \
        "🖼 Current Wallpaper State" "${SEV_INFO}"

    # ── Waybar ────────────────────────────────────────────────────────────────
    if pgrep -x waybar &>/dev/null; then
        doc::result "${SEV_PASS}" "${cat}" "hl.eco.waybar" \
            "📊 Waybar" "Running ✓" ""
    else
        doc::result "${SEV_INFO}" "${cat}" "hl.eco.waybar" \
            "📊 Waybar" "Not running" "waybar &"
    fi

    # ── Notification daemon ───────────────────────────────────────────────────
    local notif_daemon=""
    pgrep -x dunst    &>/dev/null && notif_daemon="dunst"
    pgrep -x swaync   &>/dev/null && notif_daemon="swaync"
    pgrep -x mako     &>/dev/null && notif_daemon="mako"
    local notif_sev; [[ -n "${notif_daemon}" ]] && notif_sev="${SEV_PASS}" || notif_sev="${SEV_WARN}"
    doc::result "${notif_sev}" "${cat}" "hl.eco.notif" \
        "🔔 Notification Daemon" \
        "${notif_daemon:-none running}" \
        "$( [[ -z "${notif_daemon}" ]] && printf 'systemctl --user start dunst' || printf '')"
}

check_hyprland::run() {
    log::debug "Running check-hyprland.sh"
    check_hyprland::binaries
    check_hyprland::runtime
    check_hyprland::config_files
    check_hyprland::config_settings
    check_hyprland::ecosystem
}


# ── Entry points ──────────────────────────────────────────────────────────────
# Nineteen of the check modules expose ash_check_<area>() and a _quick variant.
# This one predates that convention and used a bare top-level call to check_hyprland::run,
# which meant sourcing it ran the whole check. These wrappers give the loader a
# single, uniform interface to drive.
ash_check_hyprland() {
    check_hyprland::run
}

# The doc:: API records its own results and has no cheap subset, so the quick
# variant reports on the same areas. It exists so `ash doctor quick` can reach
# this module at all.
ash_check_hyprland_quick() {
    check_hyprland::run
}
