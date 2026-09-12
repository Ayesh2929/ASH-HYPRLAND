#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██╗  ██╗██████╗  ██████╗     ██████╗  ██████╗ ██████╗ ████████╗ █████╗ ██╗     ║
# ║  ╚██╗██╔╝██╔══██╗██╔════╝     ██╔══██╗██╔═══██╗██╔══██╗╚══██╔══╝██╔══██╗██║     ║
# ║   ╚███╔╝ ██║  ██║██║  ███╗    ██████╔╝██║   ██║██████╔╝   ██║   ███████║██║     ║
# ║   ██╔██╗ ██║  ██║██║   ██║    ██╔═══╝ ██║   ██║██╔══██╗   ██║   ██╔══██║██║     ║
# ║  ██╔╝ ██╗██████╔╝╚██████╔╝    ██║     ╚██████╔╝██║  ██║   ██║   ██║  ██║███████╗║
# ║  ╚═╝  ╚═╝╚═════╝  ╚═════╝     ╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  DOCTOR CHECK: XDG PORTALS                               ║
# ║                                                                                  ║
# ║  Deep diagnostic for XDG Desktop Portal ecosystem:                              ║
# ║  xdg-desktop-portal • Hyprland portal • GTK portal • file chooser               ║
# ║  screen capture • D-Bus • socket health • protocol conformance                  ║
# ║                                                                                  ║
# ║  Author   : ash-dotfiles                                                         ║
# ║  License  : MIT                                                                  ║
# ║  Category : doctor/checks                                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CHECK_XDG_PORTALS_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CHECK_XDG_PORTALS_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CONSTANTS & PATHS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _XDG_RUNTIME="${XDG_RUNTIME_DIR:-/run/user/${UID:-1000}}"
declare -gr _XDG_CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
declare -gr _XDG_DATA="${XDG_DATA_HOME:-$HOME/.local/share}"

# Well-known portal ICD/implementation search paths
declare -ga _PORTAL_SEARCH_PATHS=(
    "/usr/share/xdg-desktop-portal/portals"
    "/usr/local/share/xdg-desktop-portal/portals"
    "${_XDG_DATA}/xdg-desktop-portal/portals"
)

# Known portal implementations with metadata
# Format: "name|binary_path|portal_file_pattern|dbus_name|critical"
declare -gA _KNOWN_PORTALS=(
    [hyprland]="xdg-desktop-portal-hyprland|/usr/lib/xdg-desktop-portal-hyprland|*hyprland*.portal|org.freedesktop.impl.portal.desktop.hyprland|1"
    [gtk]="xdg-desktop-portal-gtk|/usr/lib/xdg-desktop-portal-gtk|*gtk*.portal|org.freedesktop.impl.portal.desktop.gtk|1"
    [wlr]="xdg-desktop-portal-wlr|/usr/lib/xdg-desktop-portal-wlr|*wlr*.portal|org.freedesktop.impl.portal.desktop.wlr|0"
    [kde]="xdg-desktop-portal-kde|/usr/lib/xdg-desktop-portal-kde|*kde*.portal|org.freedesktop.impl.portal.desktop.kde|0"
    [gnome]="xdg-desktop-portal-gnome|/usr/lib/xdg-desktop-portal-gnome|*gnome*.portal|org.freedesktop.impl.portal.desktop.gnome|0"
)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PORTAL-SPECIFIC HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Query a D-Bus property from xdg-desktop-portal
_portal_dbus_call() {
    local interface="$1"
    local method="${2:-Introspect}"

    if ! command -v dbus-send &>/dev/null; then
        echo "dbus-send not available"
        return 1
    fi

    if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
        echo "D-Bus session not available"
        return 1
    fi

    dbus-send \
        --session \
        --print-reply \
        --dest="org.freedesktop.portal.Desktop" \
        "/org/freedesktop/portal/desktop" \
        "${interface}.${method}" \
        2>/dev/null || true
}

# Find a portal file in known search paths
_find_portal_file() {
    local pattern="$1"
    for search_dir in "${_PORTAL_SEARCH_PATHS[@]}"; do
        if [[ -d "$search_dir" ]]; then
            local found
            found="$(find "$search_dir" -name "$pattern" 2>/dev/null | head -1)"
            [[ -n "$found" ]] && printf '%s' "$found" && return 0
        fi
    done
    return 1
}

# Check if a D-Bus name is owned
_dbus_name_owned() {
    local name="$1"
    [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]] && return 1
    dbus-send \
        --session \
        --print-reply \
        --dest=org.freedesktop.DBus \
        /org/freedesktop/DBus \
        org.freedesktop.DBus.NameHasOwner \
        "string:${name}" \
        2>/dev/null | grep -q 'boolean true'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 01 — CORE XDG PORTAL DAEMON
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_xdg_core() {
    _check_header "🌀 Core XDG Desktop Portal Daemon"

    # ── xdg-desktop-portal binary ────────────────────────────────────────────────
    if ! command -v xdg-desktop-portal &>/dev/null; then
        _check_report $CHECK_FAIL \
            "xdg-desktop-portal binary" \
            "Not found in PATH" \
            "Install: paru -S xdg-desktop-portal"
        return $CHECK_FAIL
    fi

    local xdg_ver
    xdg_ver="$(xdg-desktop-portal --version 2>/dev/null | \
               grep -oP '[\d]+\.[\d.]+' | head -1 || echo 'unknown')"

    local ver_major="${xdg_ver%%.*}"
    local ver_minor
    ver_minor="$(printf '%s' "$xdg_ver" | cut -d. -f2)"

    if [[ "$ver_major" =~ ^[0-9]+$ ]] && (( ver_major >= 1 )); then
        if (( ver_minor >= 18 )); then
            _check_report $CHECK_PASS \
                "xdg-desktop-portal" \
                "v${xdg_ver}  (current — dynamic portal resolution)"
        elif (( ver_minor >= 16 )); then
            _check_report $CHECK_PASS \
                "xdg-desktop-portal" \
                "v${xdg_ver}  (stable)"
        else
            _check_report $CHECK_WARN \
                "xdg-desktop-portal" \
                "v${xdg_ver}  (older — update recommended)" \
                "Update: paru -Su xdg-desktop-portal"
        fi
    else
        _check_report $CHECK_INFO \
            "xdg-desktop-portal" \
            "v${xdg_ver}"
    fi

    # ── Process running? ─────────────────────────────────────────────────────────
    if pgrep -x 'xdg-desktop-portal' &>/dev/null; then
        local xdg_pid
        xdg_pid="$(pgrep -x xdg-desktop-portal | head -1)"
        local xdg_uptime
        xdg_uptime="$(ps -p "$xdg_pid" -o etime= 2>/dev/null | tr -d ' ' || echo '?')"
        _check_report $CHECK_PASS \
            "xdg-desktop-portal process" \
            "Running  PID: ${xdg_pid}  •  uptime: ${xdg_uptime}"
    else
        _check_report $CHECK_FAIL \
            "xdg-desktop-portal process" \
            "NOT running" \
            "Start: systemctl --user start xdg-desktop-portal"
    fi

    # ── systemd service ──────────────────────────────────────────────────────────
    if command -v systemctl &>/dev/null; then
        local svc_active svc_enabled
        svc_active="$(  systemctl --user is-active  xdg-desktop-portal 2>/dev/null || echo 'inactive')"
        svc_enabled="$( systemctl --user is-enabled xdg-desktop-portal 2>/dev/null || echo 'disabled')"

        if [[ "$svc_active" == "active" ]]; then
            _check_report $CHECK_PASS \
                "xdg-desktop-portal.service" \
                "active  •  enabled: ${svc_enabled}"
        else
            _check_report $CHECK_FAIL \
                "xdg-desktop-portal.service" \
                "state: ${svc_active}  •  enabled: ${svc_enabled}" \
                "Enable: systemctl --user enable --now xdg-desktop-portal"
        fi
    fi

    # ── D-Bus name ownership ─────────────────────────────────────────────────────
    if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
        if _dbus_name_owned "org.freedesktop.portal.Desktop"; then
            _check_report $CHECK_PASS \
                "D-Bus name" \
                "org.freedesktop.portal.Desktop  (owned)"
        else
            _check_report $CHECK_FAIL \
                "D-Bus name" \
                "org.freedesktop.portal.Desktop  NOT owned" \
                "Portal not registering on D-Bus — restart: systemctl --user restart xdg-desktop-portal"
        fi
    else
        _check_report $CHECK_WARN \
            "D-Bus session" \
            "DBUS_SESSION_BUS_ADDRESS not set" \
            "D-Bus session not available in this context"
    fi

    # ── Portal socket file ───────────────────────────────────────────────────────
    local portal_socket="${_XDG_RUNTIME}/xdg-desktop-portal"
    if [[ -e "$portal_socket" ]]; then
        _check_report $CHECK_PASS \
            "Portal socket" \
            "${portal_socket}"
    else
        _check_report $CHECK_INFO \
            "Portal socket" \
            "Not found at ${portal_socket}  (may use D-Bus activation)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 02 — PORTAL IMPLEMENTATIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_xdg_implementations() {
    _check_header "🔌 Portal Backend Implementations"

    # ── Hyprland portal (critical for Wayland screen capture) ────────────────────
    _chk_xdg_impl_detail \
        "hyprland" \
        "xdg-desktop-portal-hyprland" \
        "hyprland" \
        "Screen capture, file picker, inhibit" \
        "paru -S xdg-desktop-portal-hyprland" \
        1

    # ── GTK portal (file chooser, notifications, settings) ───────────────────────
    _chk_xdg_impl_detail \
        "gtk" \
        "xdg-desktop-portal-gtk" \
        "gtk" \
        "File chooser, notifications, settings, print" \
        "paru -S xdg-desktop-portal-gtk" \
        1

    # ── WLR portal (older wlroots screen share) ───────────────────────────────────
    _chk_xdg_impl_detail \
        "wlr" \
        "xdg-desktop-portal-wlr" \
        "wlr" \
        "Screen sharing (legacy wlroots)" \
        "paru -S xdg-desktop-portal-wlr" \
        0

    # ── KDE portal ────────────────────────────────────────────────────────────────
    _chk_xdg_impl_detail \
        "kde" \
        "xdg-desktop-portal-kde" \
        "kde" \
        "KDE Plasma portal backend" \
        "paru -S xdg-desktop-portal-kde" \
        0

    # ── Detect conflicting portals ────────────────────────────────────────────────
    _chk_xdg_conflicts
}

_chk_xdg_impl_detail() {
    local key="$1"
    local binary="$2"
    local short_name="$3"
    local provides="$4"
    local install_cmd="$5"
    local critical="$6"

    # Binary check (multiple possible locations)
    local binary_path=""
    local search_bins=(
        "/usr/lib/${binary}"
        "/usr/libexec/${binary}"
        "/usr/lib/xdg-desktop-portal-${short_name}"
    )

    for sb in "${search_bins[@]}"; do
        if [[ -x "$sb" ]]; then
            binary_path="$sb"
            break
        fi
    done

    # Also check if command is in PATH
    command -v "$binary" &>/dev/null && binary_path="$(command -v "$binary")"

    if [[ -n "$binary_path" ]]; then
        # Get version if possible
        local impl_ver
        impl_ver="$("$binary_path" --version 2>/dev/null | \
                    grep -oP '[\d]+\.[\d.]+' | head -1 || echo 'installed')"

        # Check if process is running
        local impl_pid
        impl_pid="$(pgrep -f "${binary}$" | head -1 || echo '')"

        if [[ -n "$impl_pid" ]]; then
            _check_report $CHECK_PASS \
                "Portal: ${short_name^^}  (${binary})" \
                "v${impl_ver}  •  PID: ${impl_pid}  •  ${provides}"
        else
            _check_report $CHECK_INFO \
                "Portal: ${short_name^^}  (${binary})" \
                "v${impl_ver}  •  installed but not running  (D-Bus activated)"
        fi

        # ── Find .portal ICD file ─────────────────────────────────────────────────
        local portal_file=""
        for pdir in "${_PORTAL_SEARCH_PATHS[@]}"; do
            local pf
            pf="$(find "$pdir" -name "*${short_name}*.portal" \
                  -o -name "*${key}*.portal" 2>/dev/null | head -1 || echo '')"
            [[ -n "$pf" ]] && portal_file="$pf" && break
        done

        if [[ -n "$portal_file" ]]; then
            # Parse portal interfaces from .portal file
            local ifaces
            ifaces="$(grep -oP '(?<=Interfaces=)[^\n]+' "$portal_file" 2>/dev/null | \
                      tr ';' '  ' || echo 'unknown')"
            _check_report $CHECK_PASS \
                "  └─ Portal file" \
                "$(basename "$portal_file")  •  interfaces: ${ifaces}"
        else
            _check_report $CHECK_WARN \
                "  └─ Portal file" \
                ".portal ICD not found in search paths" \
                "Reinstall: ${install_cmd}"
        fi

    else
        if [[ "$critical" == "1" ]]; then
            _check_report $CHECK_FAIL \
                "Portal: ${short_name^^}  (${binary})" \
                "NOT installed  —  provides: ${provides}" \
                "Install: ${install_cmd}"
        else
            _check_report $CHECK_INFO \
                "Portal: ${short_name^^}  (${binary})" \
                "Not installed  (optional)  —  provides: ${provides}" \
                "Install: ${install_cmd}"
        fi
    fi
}

_chk_xdg_conflicts() {
    _check_header "⚡ Portal Conflict Detection"

    # Only xdg-desktop-portal-hyprland AND gtk should be active
    # Having wlr + hyprland simultaneously causes screen share conflicts
    local hypr_running wlr_running gnome_running kde_running
    hypr_running="$(pgrep -f 'xdg-desktop-portal-hyprland' | wc -l)"
    wlr_running="$(  pgrep -f 'xdg-desktop-portal-wlr'      | wc -l)"
    gnome_running="$(pgrep -f 'xdg-desktop-portal-gnome'    | wc -l)"
    kde_running="$(  pgrep -f 'xdg-desktop-portal-kde'       | wc -l)"

    local conflicts=0

    if (( hypr_running > 0 )) && (( wlr_running > 0 )); then
        _check_report $CHECK_WARN \
            "Conflict: hyprland + wlr" \
            "Both portals running — screen share may be ambiguous" \
            "Remove wlr: paru -R xdg-desktop-portal-wlr"
        (( conflicts++ )) || true
    fi

    if (( gnome_running > 0 )) && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        _check_report $CHECK_WARN \
            "Conflict: gnome portal on Hyprland" \
            "GNOME portal running on non-GNOME session" \
            "Remove: paru -R xdg-desktop-portal-gnome"
        (( conflicts++ )) || true
    fi

    if (( kde_running > 0 )) && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        _check_report $CHECK_WARN \
            "Conflict: kde portal on Hyprland" \
            "KDE portal running on non-KDE session"
        (( conflicts++ )) || true
    fi

    if (( conflicts == 0 )); then
        _check_report $CHECK_PASS \
            "Portal conflicts" \
            "None detected"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 03 — PORTAL CONFIGURATION FILES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_xdg_config() {
    _check_header "📄 Portal Configuration"

    # ── Hyprland portal config ───────────────────────────────────────────────────
    local hypr_portal_conf="${_XDG_CFG}/xdg-desktop-portal/hyprland-portals.conf"
    local alt_portal_conf="${_XDG_CFG}/xdg-desktop-portal/portals.conf"

    local portal_conf_found=0

    if [[ -f "$hypr_portal_conf" ]]; then
        local hpc_lines
        hpc_lines="$(wc -l < "$hypr_portal_conf" 2>/dev/null || echo 0)"
        _check_report $CHECK_PASS \
            "hyprland-portals.conf" \
            "${hpc_lines} lines  —  ${hypr_portal_conf}"

        # Validate content
        if grep -q '\[preferred\]' "$hypr_portal_conf" 2>/dev/null; then
            _check_report $CHECK_PASS \
                "  └─ [preferred] section" \
                "Present"

            local default_impl
            default_impl="$(grep -A5 '\[preferred\]' "$hypr_portal_conf" 2>/dev/null | \
                           grep '^default=' | cut -d= -f2)"
            if [[ -n "$default_impl" ]]; then
                _check_report $CHECK_INFO \
                    "  └─ Default portal" \
                    "$default_impl"
            fi
        else
            _check_report $CHECK_WARN \
                "  └─ [preferred] section" \
                "Missing from hyprland-portals.conf" \
                "Add: [preferred]\ndefault=hyprland;gtk"
        fi
        portal_conf_found=1
    fi

    if [[ -f "$alt_portal_conf" ]]; then
        _check_report $CHECK_INFO \
            "portals.conf (generic)" \
            "${alt_portal_conf}"
        portal_conf_found=1
    fi

    if [[ $portal_conf_found -eq 0 ]]; then
        _check_report $CHECK_WARN \
            "Portal config" \
            "No portal config found" \
            "Create: mkdir -p ${_XDG_CFG}/xdg-desktop-portal && cat > hyprland-portals.conf"
        _chk_xdg_config_generate_hint
    fi

    # ── System portal configs ─────────────────────────────────────────────────────
    local sys_portal_dir="/usr/share/xdg-desktop-portal"
    if [[ -d "$sys_portal_dir" ]]; then
        local sys_portal_count
        sys_portal_count="$(find "$sys_portal_dir/portals" \
                           -name '*.portal' 2>/dev/null | wc -l)"
        _check_report $CHECK_INFO \
            "System portal ICD dir" \
            "${sys_portal_dir}/portals  (${sys_portal_count} .portal files)"
    fi

    # ── EGL platform config ───────────────────────────────────────────────────────
    local egl_dir="/usr/share/egl/egl_external_platform.d"
    if [[ -d "$egl_dir" ]]; then
        local egl_count
        egl_count="$(find "$egl_dir" -name '*.json' 2>/dev/null | wc -l)"
        _check_report $CHECK_INFO \
            "EGL external platforms" \
            "${egl_count} platform file(s) in ${egl_dir}"

        # Check for Wayland EGL platform
        if find "$egl_dir" -name '*wayland*' 2>/dev/null -q; then
            _check_report $CHECK_PASS \
                "  └─ Wayland EGL" \
                "Platform file present"
        fi
    fi
}

_chk_xdg_config_generate_hint() {
    local conf_dir="${_XDG_CFG}/xdg-desktop-portal"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[38;2;108;112;134m  Suggested config to create:\033[0m\n'
        printf '\033[38;2;116;199;236m'
        printf '  mkdir -p %s\n' "$conf_dir"
        printf '  cat > %s/hyprland-portals.conf << EOF\n' "$conf_dir"
        printf '  [preferred]\n'
        printf '  default=hyprland;gtk\n'
        printf '  org.freedesktop.impl.portal.Secret=gnome-keyring\n'
        printf '  EOF\033[0m\n\n'
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 04 — PORTAL INTERFACES (FUNCTIONAL CHECK)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_xdg_interfaces() {
    _check_header "🔬 Portal Interface Availability"

    [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]] && {
        _check_report $CHECK_SKIP \
            "Interface check" \
            "D-Bus session unavailable — skipping"
        return $CHECK_SKIP
    }

    if ! _dbus_name_owned "org.freedesktop.portal.Desktop" 2>/dev/null; then
        _check_report $CHECK_SKIP \
            "Interface check" \
            "Portal D-Bus name not owned — portal not running"
        return $CHECK_SKIP
    fi

    # Required portal interfaces and their purpose
    local -A portal_interfaces=(
        ["org.freedesktop.portal.FileChooser"]="File open/save dialogs"
        ["org.freedesktop.portal.Screenshot"]="Screenshot API"
        ["org.freedesktop.portal.ScreenCast"]="Screen capture / recording"
        ["org.freedesktop.portal.RemoteDesktop"]="Remote desktop input"
        ["org.freedesktop.portal.Inhibit"]="Idle/suspend inhibit"
        ["org.freedesktop.portal.Notification"]="Desktop notifications"
        ["org.freedesktop.portal.Settings"]="Desktop settings (dark mode etc)"
        ["org.freedesktop.portal.OpenURI"]="Open URIs with default app"
        ["org.freedesktop.portal.Clipboard"]="Clipboard access"
        ["org.freedesktop.portal.Secret"]="Secret/keyring access"
        ["org.freedesktop.portal.Camera"]="Camera access"
        ["org.freedesktop.portal.Location"]="Location services"
        ["org.freedesktop.portal.Print"]="Print dialog"
        ["org.freedesktop.portal.Account"]="User account info"
        ["org.freedesktop.portal.Background"]="Background app running"
        ["org.freedesktop.portal.Email"]="Send email via portal"
    )

    # Attempt to introspect the portal to get supported interfaces
    local introspect_out
    introspect_out="$(dbus-send \
        --session \
        --print-reply \
        --dest=org.freedesktop.portal.Desktop \
        /org/freedesktop/portal/desktop \
        org.freedesktop.DBus.Introspectable.Introspect \
        2>/dev/null || echo '')"

    # Categorize
    local critical_missing=()
    local available=0

    for iface in "${!portal_interfaces[@]}"; do
        local desc="${portal_interfaces[$iface]}"
        local short="${iface##*.}"

        if [[ -n "$introspect_out" ]]; then
            if printf '%s' "$introspect_out" | grep -q "$iface\|$short"; then
                _check_report $CHECK_PASS \
                    "Interface: ${short}" \
                    "${desc}"
                (( available++ )) || true
            else
                case "$short" in
                    ScreenCast|FileChooser|Screenshot|Inhibit|Settings)
                        _check_report $CHECK_FAIL \
                            "Interface: ${short}" \
                            "NOT available  —  ${desc}" \
                            "Check portal backends are installed"
                        critical_missing+=("$short")
                        ;;
                    *)
                        _check_report $CHECK_INFO \
                            "Interface: ${short}" \
                            "Not found  (optional)  —  ${desc}"
                        ;;
                esac
            fi
        else
            _check_report $CHECK_INFO \
                "Interface: ${short}" \
                "${desc}"
        fi
    done

    if [[ -n "$introspect_out" ]]; then
        _check_report $CHECK_INFO \
            "Available interfaces" \
            "${available}/${#portal_interfaces[@]}"
    fi

    # ── ScreenCast special test ───────────────────────────────────────────────────
    if command -v pipewire &>/dev/null && pgrep -x pipewire &>/dev/null; then
        _check_report $CHECK_PASS \
            "PipeWire (ScreenCast backend)" \
            "Running  — screen capture via PipeWire enabled"
    else
        _check_report $CHECK_FAIL \
            "PipeWire (ScreenCast backend)" \
            "Not running  — ScreenCast portal will fail" \
            "Start: systemctl --user start pipewire"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 05 — SCREEN CAPTURE PIPELINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_xdg_screencapture() {
    _check_header "📸 Screen Capture Pipeline"

    # ── Full pipeline check ───────────────────────────────────────────────────────
    # Hyprland → xdg-desktop-portal-hyprland → PipeWire → WirePlumber → consumer

    local pipeline_ok=1

    # 1. Hyprland running
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        _check_report $CHECK_PASS \
            "① Hyprland compositor" \
            "Running  (provides zwlr_screencopy / ext_output_image)"
    else
        _check_report $CHECK_FAIL \
            "① Hyprland compositor" \
            "Not running" \
            "Start a Hyprland session"
        pipeline_ok=0
    fi

    # 2. xdg-desktop-portal-hyprland
    if pgrep -f 'xdg-desktop-portal-hyprland' &>/dev/null; then
        _check_report $CHECK_PASS \
            "② xdg-dp-hyprland" \
            "Running  (ScreenCast + Screenshot portal backend)"
    else
        _check_report $CHECK_FAIL \
            "② xdg-dp-hyprland" \
            "Not running" \
            "Enable: systemctl --user enable --now xdg-desktop-portal-hyprland"
        pipeline_ok=0
    fi

    # 3. PipeWire
    if pgrep -x pipewire &>/dev/null; then
        local pw_ver
        pw_ver="$(pipewire --version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo '?')"
        _check_report $CHECK_PASS \
            "③ PipeWire" \
            "Running  v${pw_ver}  (video stream transport)"
    else
        _check_report $CHECK_FAIL \
            "③ PipeWire" \
            "NOT running" \
            "Enable: systemctl --user enable --now pipewire"
        pipeline_ok=0
    fi

    # 4. WirePlumber
    if pgrep -x wireplumber &>/dev/null; then
        _check_report $CHECK_PASS \
            "④ WirePlumber" \
            "Running  (PipeWire session/policy manager)"
    else
        _check_report $CHECK_FAIL \
            "④ WirePlumber" \
            "NOT running" \
            "Enable: systemctl --user enable --now wireplumber"
        pipeline_ok=0
    fi

    # 5. pipewire-pulse (for applications using PulseAudio API)
    if pgrep -f 'pipewire-pulse\|pipewire.*pulse' &>/dev/null; then
        _check_report $CHECK_PASS \
            "⑤ pipewire-pulse" \
            "Running  (PulseAudio compat layer)"
    else
        _check_report $CHECK_INFO \
            "⑤ pipewire-pulse" \
            "Not running  (may be needed for some apps)" \
            "Enable: systemctl --user enable --now pipewire-pulse"
    fi

    # ── Overall pipeline status ───────────────────────────────────────────────────
    printf '\n'
    if [[ $pipeline_ok -eq 1 ]]; then
        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
            printf '  \033[1;38;2;166;227;161m'
            printf '  ┌─────────────────────────────────────────────┐\n'
            printf '  │  ✓ Screen capture pipeline: FULLY FUNCTIONAL │\n'
            printf '  │    OBS • obs-studio • wf-recorder • grim      │\n'
            printf '  └─────────────────────────────────────────────┘\033[0m\n\n'
        else
            printf '  ✓ Screen capture pipeline: FULLY FUNCTIONAL\n\n'
        fi
    else
        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
            printf '  \033[1;38;2;243;139;168m'
            printf '  ┌─────────────────────────────────────────────┐\n'
            printf '  │  ✗ Screen capture pipeline: BROKEN           │\n'
            printf '  │    Fix the failed steps above                 │\n'
            printf '  └─────────────────────────────────────────────┘\033[0m\n\n'
        else
            printf '  ✗ Screen capture pipeline: BROKEN\n\n'
        fi
    fi

    # ── Consumer tools check ──────────────────────────────────────────────────────
    local -a capture_tools=(
        "obs:OBS Studio:obs-studio"
        "wf-recorder:wf-recorder (Wayland screen record):wf-recorder"
        "grim:Grim (Wayland screenshot):grim"
        "grimblast:Grimblast (screenshot helper):grimblast"
        "hyprshot:Hyprshot:hyprshot"
        "swappy:Swappy (screenshot annotate):swappy"
    )

    for tool_entry in "${capture_tools[@]}"; do
        IFS=':' read -r bin label pkg <<< "$tool_entry"
        if command -v "$bin" &>/dev/null; then
            local tver
            tver="$("$bin" --version 2>/dev/null | grep -oP '[\d]+\.[\d.]+' | head -1 || echo 'installed')"
            _check_report $CHECK_PASS \
                "Capture tool: ${label}" \
                "v${tver}"
        else
            _check_report $CHECK_INFO \
                "Capture tool: ${label}" \
                "not installed" \
                "paru -S ${pkg}"
        fi
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 06 — FILE CHOOSER PORTAL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_xdg_filechooser() {
    _check_header "📁 File Chooser Portal"

    # ── GTK portal required for file chooser ─────────────────────────────────────
    local gtk_portal_running
    gtk_portal_running="$(pgrep -f 'xdg-desktop-portal-gtk' | wc -l)"

    if (( gtk_portal_running > 0 )); then
        _check_report $CHECK_PASS \
            "GTK file chooser portal" \
            "Running  (native GTK file picker for Flatpak + Electron apps)"
    else
        _check_report $CHECK_WARN \
            "GTK file chooser portal" \
            "Not running  (file dialogs may not work in Flatpak apps)" \
            "Enable: systemctl --user enable --now xdg-desktop-portal-gtk"
    fi

    # ── GTK_USE_PORTAL env var ────────────────────────────────────────────────────
    local gtk_portal="${GTK_USE_PORTAL:-}"
    if [[ "$gtk_portal" == "1" ]]; then
        _check_report $CHECK_PASS \
            "GTK_USE_PORTAL" \
            "1  (GTK apps use portal file chooser)"
    else
        _check_report $CHECK_INFO \
            "GTK_USE_PORTAL" \
            "${gtk_portal:-not set}  (apps may use native dialog)" \
            "Set: GTK_USE_PORTAL=1 in environment.d"
    fi

    # ── Electron apps portal file chooser ────────────────────────────────────────
    local electron_portal="${ELECTRON_USE_PORTAL:-}"
    if [[ "$electron_portal" == "1" ]]; then
        _check_report $CHECK_PASS \
            "ELECTRON_USE_PORTAL" \
            "1  (Electron/VSCode use portal dialogs)"
    else
        _check_report $CHECK_INFO \
            "ELECTRON_USE_PORTAL" \
            "${electron_portal:-not set}" \
            "Set: ELECTRON_USE_PORTAL=1 for VSCode/Electron apps"
    fi

    # ── Qt file portal ────────────────────────────────────────────────────────────
    local qt_dialog="${QT_QPA_PLATFORMTHEME:-}"
    if [[ "$qt_dialog" == "xdgdesktopportal" ]]; then
        _check_report $CHECK_PASS \
            "QT_QPA_PLATFORMTHEME" \
            "xdgdesktopportal  (Qt apps use portal)"
    else
        _check_report $CHECK_INFO \
            "QT_QPA_PLATFORMTHEME" \
            "${qt_dialog:-not set}  (Qt apps use native dialog)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_check_xdg_portals() {
    local mode="${1:-full}"

    _CHECK_PASS_COUNT=0;  _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0;  _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=();   _CHECK_WARNINGS=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;116;199;236m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🌀  ASH DOCTOR — XDG PORTALS CHECK                      ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  core daemon • backends • config • interfaces • capture  ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n=== ASH DOCTOR — XDG PORTALS CHECK ===\n'
    fi

    case "$mode" in
        quick)
            _chk_xdg_core
            _chk_xdg_implementations
            ;;
        capture)       _chk_xdg_screencapture  ;;
        filechooser)   _chk_xdg_filechooser    ;;
        interfaces)    _chk_xdg_interfaces     ;;
        full|*)
            _chk_xdg_core
            _chk_xdg_implementations
            _chk_xdg_config
            _chk_xdg_interfaces
            _chk_xdg_screencapture
            _chk_xdg_filechooser
            ;;
    esac

    _ash_check_system_summary
}

ash_check_xdg_portals_quick() {
    local issues=0
    pgrep -x 'xdg-desktop-portal' &>/dev/null || (( issues++ )) || true
    if pgrep -f 'xdg-desktop-portal-hyprland' &>/dev/null || \
       pgrep -f 'xdg-desktop-portal-gtk' &>/dev/null; then
        : # at least one backend running
    else
        (( issues++ )) || true
    fi
    if (( issues == 0 )); then
        ash_log_success "XDG Portals: OK  (daemon + at least one backend running)"
    else
        ash_log_warn "XDG Portals: ${issues} issue(s) — run 'ash doctor full --portals'"
        return 1
    fi
}
