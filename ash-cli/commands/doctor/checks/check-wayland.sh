#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ DOCTOR CHECK — WAYLAND                                     ║
# ║  Wayland compositor, protocol support, XWayland, portals, env & display stack         ║
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

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
check_wayland::session() {
    local cat="wayland"

    # ── WAYLAND_DISPLAY ───────────────────────────────────────────────────────
    local wd="${WAYLAND_DISPLAY:-}"
    local wd_sev; [[ -n "${wd}" ]] && wd_sev="${SEV_PASS}" || wd_sev="${SEV_FAIL}"
    doc::result "${wd_sev}" "${cat}" "wy.sess.display" \
        "🌊 WAYLAND_DISPLAY" \
        "${wd:-<not set> — not in a Wayland session?}" ""

    # ── Socket file ───────────────────────────────────────────────────────────
    local runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    local socket="${runtime}/${wd:-wayland-0}"
    local sock_sev="${SEV_PASS}"
    [[ ! -S "${socket}" ]] && sock_sev="${SEV_FAIL}"
    doc::result "${sock_sev}" "${cat}" "wy.sess.socket" \
        "🌊 Wayland Socket" \
        "$( [[ -S "${socket}" ]] && printf '%s ✓' "${socket}" || printf 'Missing: %s' "${socket}")" ""

    # ── XDG_SESSION_TYPE ─────────────────────────────────────────────────────
    local st="${XDG_SESSION_TYPE:-}"
    local st_sev; [[ "${st}" == "wayland" ]] && st_sev="${SEV_PASS}" || st_sev="${SEV_WARN}"
    doc::result "${st_sev}" "${cat}" "wy.sess.type" \
        "🌊 XDG_SESSION_TYPE" \
        "${st:-<not set>}" ""

    # ── XDG_CURRENT_DESKTOP ───────────────────────────────────────────────────
    local cd="${XDG_CURRENT_DESKTOP:-}"
    local cd_sev; [[ -n "${cd}" ]] && cd_sev="${SEV_PASS}" || cd_sev="${SEV_WARN}"
    doc::result "${cd_sev}" "${cat}" "wy.sess.desktop" \
        "🌊 XDG_CURRENT_DESKTOP" "${cd:-<not set>}" ""

    # ── D-Bus session ─────────────────────────────────────────────────────────
    local dbus="${DBUS_SESSION_BUS_ADDRESS:-}"
    local dbus_sev; [[ -n "${dbus}" ]] && dbus_sev="${SEV_PASS}" || dbus_sev="${SEV_FAIL}"
    doc::result "${dbus_sev}" "${cat}" "wy.sess.dbus" \
        "🌊 D-Bus Session" \
        "${dbus:-<not set> — apps may not communicate correctly}" ""

    # ── XDG_RUNTIME_DIR ───────────────────────────────────────────────────────
    local rt="${XDG_RUNTIME_DIR:-}"
    local rt_sev="${SEV_PASS}"
    [[ -z "${rt}" ]] && rt_sev="${SEV_FAIL}"
    [[ -n "${rt}" ]] && [[ ! -d "${rt}" ]] && rt_sev="${SEV_FAIL}"
    local rt_perm=""
    [[ -d "${rt}" ]] && rt_perm=$(stat -c '%a' "${rt}" 2>/dev/null)
    doc::result "${rt_sev}" "${cat}" "wy.sess.runtime" \
        "🌊 XDG_RUNTIME_DIR" \
        "${rt:-<not set>}$([ -n "${rt_perm}" ] && printf ' (%s)' "${rt_perm}")" ""
}

check_wayland::backends() {
    local cat="wayland"

    # ── GDK backend ───────────────────────────────────────────────────────────
    local gdk="${GDK_BACKEND:-}"
    local gdk_sev="${SEV_INFO}"
    [[ "${gdk}" == "wayland"* ]] && gdk_sev="${SEV_PASS}"
    [[ -z "${gdk}" ]] && gdk_sev="${SEV_WARN}"
    doc::result "${gdk_sev}" "${cat}" "wy.back.gdk" \
        "🔧 GDK_BACKEND" \
        "${gdk:-<not set> (GTK may use X11)}" \
        "export GDK_BACKEND=wayland,x11"

    # ── Qt platform ───────────────────────────────────────────────────────────
    local qt="${QT_QPA_PLATFORM:-}"
    local qt_sev="${SEV_INFO}"
    [[ "${qt}" == *"wayland"* ]] && qt_sev="${SEV_PASS}"
    [[ -z "${qt}" ]] && qt_sev="${SEV_WARN}"
    doc::result "${qt_sev}" "${cat}" "wy.back.qt" \
        "🔧 QT_QPA_PLATFORM" \
        "${qt:-<not set> (Qt apps may use X11)}" \
        "export QT_QPA_PLATFORM=wayland;xcb"

    # ── Qt Wayland decoration ──────────────────────────────────────────────────
    local qtwd="${QT_WAYLAND_DISABLE_WINDOWDECORATION:-}"
    doc::result "${SEV_INFO}" "${cat}" "wy.back.qtdeco" \
        "🔧 QT_WAYLAND_DISABLE_WINDOWDECORATION" \
        "${qtwd:-<not set> (client-side decorations may appear)}" \
        "export QT_WAYLAND_DISABLE_WINDOWDECORATION=1"

    # ── Mozilla ───────────────────────────────────────────────────────────────
    local moz="${MOZ_ENABLE_WAYLAND:-}"
    local moz_sev; [[ "${moz}" == "1" ]] && moz_sev="${SEV_PASS}" || moz_sev="${SEV_INFO}"
    doc::result "${moz_sev}" "${cat}" "wy.back.moz" \
        "🔧 MOZ_ENABLE_WAYLAND" \
        "${moz:-0 (Firefox uses X11 backend)}" \
        "export MOZ_ENABLE_WAYLAND=1"

    # ── SDL ───────────────────────────────────────────────────────────────────
    local sdl="${SDL_VIDEODRIVER:-}"
    local sdl_sev; [[ "${sdl}" == "wayland" ]] && sdl_sev="${SEV_PASS}" || sdl_sev="${SEV_INFO}"
    doc::result "${sdl_sev}" "${cat}" "wy.back.sdl" \
        "🔧 SDL_VIDEODRIVER" \
        "${sdl:-<not set>}" \
        "export SDL_VIDEODRIVER=wayland"

    # ── Clutter ───────────────────────────────────────────────────────────────
    local clutter="${CLUTTER_BACKEND:-}"
    doc::result "${SEV_INFO}" "${cat}" "wy.back.clutter" \
        "🔧 CLUTTER_BACKEND" \
        "${clutter:-<not set>}" \
        "export CLUTTER_BACKEND=wayland"

    # ── ELectron / Ozone ─────────────────────────────────────────────────────
    local ozone="${ELECTRON_OZONE_PLATFORM_HINT:-}"
    local ozone_sev; [[ "${ozone}" == "auto" || "${ozone}" == "wayland" ]] && \
        ozone_sev="${SEV_PASS}" || ozone_sev="${SEV_INFO}"
    doc::result "${ozone_sev}" "${cat}" "wy.back.ozone" \
        "🔧 ELECTRON_OZONE_PLATFORM_HINT" \
        "${ozone:-<not set> (Electron apps may use XWayland)}" \
        "export ELECTRON_OZONE_PLATFORM_HINT=auto"
}

check_wayland::xwayland() {
    local cat="wayland"

    doc::check_cmd "${cat}" "wy.xwl.bin" "Xwayland" "false" "paru -S xorg-xwayland"

    # ── XWayland running ──────────────────────────────────────────────────────
    if pgrep -x Xwayland &>/dev/null; then
        doc::result "${SEV_PASS}" "${cat}" "wy.xwl.running" \
            "🪟 XWayland Running" "Active (legacy X11 apps supported) ✓" ""
    else
        doc::result "${SEV_INFO}" "${cat}" "wy.xwl.running" \
            "🪟 XWayland Running" "Not running (starts on demand)" ""
    fi

    # ── DISPLAY for XWayland ─────────────────────────────────────────────────
    local display="${DISPLAY:-}"
    doc::result "${SEV_INFO}" "${cat}" "wy.xwl.display" \
        "🪟 \$DISPLAY" \
        "${display:-<not set> (set automatically when XWayland starts)}" ""
}

check_wayland::portals() {
    local cat="wayland"

    # ── xdg-desktop-portal ────────────────────────────────────────────────────
    doc::check_cmd "${cat}" "wy.prt.base" "xdg-desktop-portal" "true" \
        "paru -S xdg-desktop-portal"
    doc::check_cmd "${cat}" "wy.prt.hypr" "xdg-desktop-portal-hyprland" "true" \
        "paru -S xdg-desktop-portal-hyprland"
    doc::check_cmd "${cat}" "wy.prt.gtk"  "xdg-desktop-portal-gtk" "false" \
        "paru -S xdg-desktop-portal-gtk"

    # ── Portal services running ───────────────────────────────────────────────
    for svc in "xdg-desktop-portal" "xdg-desktop-portal-hyprland"; do
        local svc_id; svc_id="wy.prt.svc_$(printf '%s' "${svc}" | tr '-' '_')"
        if systemctl --user is-active --quiet "${svc}" 2>/dev/null; then
            doc::result "${SEV_PASS}" "${cat}" "${svc_id}" \
                "🚪 Service: ${svc}" "Active ✓" ""
        else
            doc::result "${SEV_WARN}" "${cat}" "${svc_id}" \
                "🚪 Service: ${svc}" "Not running — screen share & file pickers may fail" \
                "systemctl --user enable --now ${svc}"
        fi
    done

    # ── Portal interface via dbus ─────────────────────────────────────────────
    if command -v dbus-send &>/dev/null; then
        if dbus-send --session --dest=org.freedesktop.portal.Desktop \
            --print-reply /org/freedesktop/portal/desktop \
            org.freedesktop.DBus.Introspectable.Introspect \
            &>/dev/null 2>&1; then
            doc::result "${SEV_PASS}" "${cat}" "wy.prt.dbus" \
                "🚪 Portal D-Bus Interface" "Responding ✓" ""
        else
            doc::result "${SEV_WARN}" "${cat}" "wy.prt.dbus" \
                "🚪 Portal D-Bus Interface" "Not responding" \
                "systemctl --user restart xdg-desktop-portal"
        fi
    fi
}

check_wayland::tools() {
    local cat="wayland"

    local -a tools=(
        "wl-copy:🔧 wl-clipboard:true:paru -S wl-clipboard"
        "grim:📷 grim (screenshot):true:paru -S grim"
        "slurp:📷 slurp (area select):true:paru -S slurp"
        "waybar:📊 waybar:true:paru -S waybar"
        "swww:🖼 swww (wallpaper):true:paru -S swww"
        "hyprpicker:🎨 hyprpicker (color):false:paru -S hyprpicker"
        "wlsunset:🌅 wlsunset:false:paru -S wlsunset"
        "wlogout:🔌 wlogout:false:paru -S wlogout"
        "cliphist:📋 cliphist:false:paru -S cliphist"
        "wl-screenrec:📹 wl-screenrec:false:paru -S wl-screenrec"
    )

    for entry in "${tools[@]}"; do
        IFS=':' read -r cmd label req fix <<< "${entry}"
        local tid; tid="wy.tool.$(printf '%s' "${cmd}" | tr '-' '_')"
        doc::check_cmd "${cat}" "${tid}" "${cmd}" "${req}" "${fix}"
    done

    # ── wl-paste test ─────────────────────────────────────────────────────────
    if command -v wl-paste &>/dev/null; then
        if wl-paste --list-types &>/dev/null 2>&1; then
            doc::result "${SEV_PASS}" "${cat}" "wy.tool.clipboard" \
                "📋 Clipboard Functional" "wl-paste responding ✓" ""
        else
            doc::result "${SEV_INFO}" "${cat}" "wy.tool.clipboard" \
                "📋 Clipboard Functional" "No clipboard data (normal if freshly started)" ""
        fi
    fi
}

check_wayland::run() {
    log::debug "Running check-wayland.sh"
    check_wayland::session
    check_wayland::backends
    check_wayland::xwayland
    check_wayland::portals
    check_wayland::tools
}


# ── Entry points ──────────────────────────────────────────────────────────────
# Nineteen of the check modules expose ash_check_<area>() and a _quick variant.
# This one predates that convention and used a bare top-level call to check_wayland::run,
# which meant sourcing it ran the whole check. These wrappers give the loader a
# single, uniform interface to drive.
ash_check_wayland() {
    check_wayland::run
}

# The doc:: API records its own results and has no cheap subset, so the quick
# variant reports on the same areas. It exists so `ash doctor quick` can reach
# this module at all.
ash_check_wayland_quick() {
    check_wayland::run
}
