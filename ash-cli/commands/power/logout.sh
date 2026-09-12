#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  power logout                                             ║
# ║  Session logout: Hyprland → SWAY → KDE → GNOME → generic loginctl              ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_POWER_LOGOUT_LOADED:-}" == "1" ]] && return 0
readonly _ASH_POWER_LOGOUT_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_logout_detect_session() {
    # Detect current desktop/compositor
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        printf 'hyprland'
    elif [[ "${XDG_CURRENT_DESKTOP,,}" == *"sway"* ]] || \
         [[ -n "${SWAYSOCK:-}" ]]; then
        printf 'sway'
    elif [[ "${XDG_CURRENT_DESKTOP,,}" == *"kde"* ]] || \
         [[ "${DESKTOP_SESSION,,}" == *"plasma"* ]]; then
        printf 'kde'
    elif [[ "${XDG_CURRENT_DESKTOP,,}" == *"gnome"* ]]; then
        printf 'gnome'
    elif [[ "${XDG_SESSION_TYPE:-}" == "x11" ]]; then
        printf 'x11'
    else
        printf 'generic'
    fi
}

_logout_hyprland() {
    pwr_step "Exiting Hyprland session..."

    # Save session state
    local session_file="${_PWR_STATE_DIR}/last-session.json"
    if command -v hyprctl &>/dev/null; then
        hyprctl -j clients 2>/dev/null > "$session_file" 2>/dev/null || true
    fi

    # Graceful exit via IPC
    if command -v hyprctl &>/dev/null; then
        hyprctl dispatch exit &>/dev/null && return 0
    fi

    # Signal the compositor
    pkill -SIGTERM Hyprland 2>/dev/null || \
    pkill -x Hyprland 2>/dev/null
}

_logout_sway() {
    pwr_step "Exiting Sway session..."
    if command -v swaymsg &>/dev/null; then
        swaymsg exit &>/dev/null && return 0
    fi
    pkill -SIGTERM sway 2>/dev/null
}

_logout_kde() {
    pwr_step "Logging out of KDE Plasma..."
    if command -v qdbus &>/dev/null; then
        qdbus org.kde.ksmserver /KSMServer logout 0 0 0 &>/dev/null && return 0
    fi
    if command -v dbus-send &>/dev/null; then
        dbus-send --session --print-reply \
            --dest=org.kde.ksmserver \
            /KSMServer org.kde.KSMServerInterface.logout \
            int32:0 int32:0 int32:0 &>/dev/null && return 0
    fi
    pkill -x plasmashell 2>/dev/null
}

_logout_gnome() {
    pwr_step "Logging out of GNOME..."
    if command -v gnome-session-quit &>/dev/null; then
        gnome-session-quit --no-prompt &>/dev/null && return 0
    fi
    if command -v dbus-send &>/dev/null; then
        dbus-send --session --print-reply \
            --dest=org.gnome.SessionManager \
            /org/gnome/SessionManager \
            org.gnome.SessionManager.RequestLogout \
            uint32:1 &>/dev/null && return 0
    fi
}

_logout_x11() {
    pwr_step "Exiting X11 session..."
    if command -v openbox &>/dev/null; then
        openbox --exit 2>/dev/null && return 0
    fi
    if [[ -n "${DESKTOP_SESSION:-}" ]]; then
        pkill -SIGTERM "$DESKTOP_SESSION" 2>/dev/null && return 0
    fi
    # Kill the X server as last resort
    pkill -SIGTERM Xorg 2>/dev/null || pkill -SIGTERM X 2>/dev/null
}

_logout_generic() {
    pwr_step "Terminating session via loginctl..."
    if command -v loginctl &>/dev/null; then
        local session_id
        session_id="$(loginctl list-sessions --no-legend 2>/dev/null | \
                      awk '{print $1}' | head -1)"
        if [[ -n "$session_id" ]]; then
            loginctl terminate-session "$session_id" 2>/dev/null && return 0
        fi
    fi

    if command -v systemctl &>/dev/null; then
        systemctl --user stop graphical-session.target 2>/dev/null && return 0
    fi

    # Nuclear option: kill all processes of current user except this shell
    pwr_warn "Using kill-all method — all user processes will be terminated"
    pkill -SIGTERM -u "${USER}" -x -v "bash\|sh\|zsh\|fish" 2>/dev/null || true
}

ash_power_logout() {
    local session
    session="$(_logout_detect_session)"

    pwr_section "🚪" "Logout" "$(_pwlav)"
    pwr_kv "Session"   "$session"
    pwr_kv "Desktop"   "${XDG_CURRENT_DESKTOP:-unknown}"
    pwr_kv "User"      "${USER:-?}"

    pwr_warn "Current session will be terminated"
    pwr_check_unsaved || true

    pwr_confirm "Log out of ${session} session" "🚪" "$(_pwlav)" || return 0

    pwr_run_hook "on-logout"
    pwr_notify "🚪 Logging Out" "${session} session ending..." "normal"
    pwr_log "logout" "initiated"

    pwr_countdown "logout" "$PWR_COUNTDOWN" "🚪" "$(_pwlav)"

    local exit_code=0
    case "$session" in
        hyprland) _logout_hyprland || exit_code=$? ;;
        sway)     _logout_sway     || exit_code=$? ;;
        kde)      _logout_kde      || exit_code=$? ;;
        gnome)    _logout_gnome    || exit_code=$? ;;
        x11)      _logout_x11      || exit_code=$? ;;
        generic|*) _logout_generic || exit_code=$? ;;
    esac

    if [[ $exit_code -ne 0 ]]; then
        pwr_warn "Primary logout method failed — trying generic..."
        _logout_generic || {
            pwr_fail "All logout methods failed"
            pwr_log "logout" "failed"
            return 1
        }
    fi

    pwr_log "logout" "executing"
    printf '\n'
}
