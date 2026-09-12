#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ███████╗███████╗██████╗ ██╗   ██╗██╗ ██████╗███████╗███████╗                   ║
# ║  ██╔════╝██╔════╝██╔══██╗██║   ██║██║██╔════╝██╔════╝██╔════╝                   ║
# ║  ███████╗█████╗  ██████╔╝██║   ██║██║██║     █████╗  ███████╗                   ║
# ║  ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██║██║     ██╔══╝  ╚════██║                   ║
# ║  ███████║███████╗██║  ██║ ╚████╔╝ ██║╚██████╗███████╗███████║                   ║
# ║  ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚═╝ ╚═════╝╚══════╝╚══════╝                   ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  DOCTOR CHECK: SERVICES                                  ║
# ║  systemd user/system services • ASH daemons • failed units • timers             ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CHECK_SERVICES_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CHECK_SERVICES_LOADED=1

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
# 🔷  SERVICE PROBE HELPER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# _svc_check  scope  unit  expected_state  label  fix_hint  critical
_svc_check() {
    local scope="$1"       # user | system
    local unit="$2"
    local expected="$3"    # active | inactive | any
    local label="${4:-$unit}"
    local fix_hint="${5:-}"
    local critical="${6:-0}"

    local systemctl_args=("--${scope}")

    # Get active state
    local active enabled sub
    active="$(  systemctl "${systemctl_args[@]}" is-active  "$unit" 2>/dev/null || echo 'inactive')"
    enabled="$( systemctl "${systemctl_args[@]}" is-enabled "$unit" 2>/dev/null || echo 'disabled')"
    sub="$(     systemctl "${systemctl_args[@]}" show -p SubState --value \
                "$unit" 2>/dev/null || echo 'unknown')"

    # Get uptime / since
    local since
    since="$(systemctl "${systemctl_args[@]}" show -p ActiveEnterTimestamp \
             --value "$unit" 2>/dev/null | \
             sed 's/ [A-Z]*$//' | awk '{print $1,$2}' || echo '')"

    local status_detail="${active} (${sub})  enabled: ${enabled}"
    [[ -n "$since" ]] && status_detail+="  since: ${since}"

    case "$expected" in
        active)
            if [[ "$active" == "active" ]]; then
                _check_report $CHECK_PASS "$label" "$status_detail"
            elif [[ "$active" == "inactive" ]] || [[ "$active" == "dead" ]]; then
                if [[ "$critical" == "1" ]]; then
                    _check_report $CHECK_FAIL "$label" \
                        "${active}  —  expected: active" \
                        "${fix_hint:-systemctl --${scope} start ${unit}}"
                else
                    _check_report $CHECK_WARN "$label" \
                        "${active}  —  expected: active" \
                        "${fix_hint:-systemctl --${scope} enable --now ${unit}}"
                fi
            elif [[ "$active" == "failed" ]]; then
                _check_report $CHECK_FAIL "$label" \
                    "FAILED" \
                    "Check: systemctl --${scope} status ${unit}  •  journalctl --${scope} -u ${unit}"
            else
                _check_report $CHECK_INFO "$label" "$status_detail"
            fi
            ;;
        inactive)
            if [[ "$active" == "inactive" ]] || [[ "$active" == "dead" ]]; then
                _check_report $CHECK_PASS "$label" "Not running  (correct)"
            else
                _check_report $CHECK_WARN "$label" \
                    "${active}  —  should be inactive" \
                    "Stop: systemctl --${scope} stop ${unit}"
            fi
            ;;
        any|*)
            if [[ "$active" == "failed" ]]; then
                _check_report $CHECK_FAIL "$label" "FAILED" \
                    "Check: systemctl --${scope} status ${unit}"
            else
                _check_report $CHECK_INFO "$label" "$status_detail"
            fi
            ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 01 — FAILED UNITS (SYSTEM HEALTH)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_svc_failed_units() {
    _check_header "🚨 Failed systemd Units"

    if ! command -v systemctl &>/dev/null; then
        _check_report $CHECK_SKIP "systemd" "systemctl not available"
        return $CHECK_SKIP
    fi

    # ── System failed units ───────────────────────────────────────────────────────
    local sys_failed=()
    mapfile -t sys_failed < <(
        systemctl --system list-units --state=failed --no-legend \
                  --no-pager 2>/dev/null | awk '{print $1}' | head -20
    )

    if [[ ${#sys_failed[@]} -eq 0 ]] || [[ -z "${sys_failed[0]:-}" ]]; then
        _check_report $CHECK_PASS \
            "System failed units" \
            "None  🎉"
    else
        _check_report $CHECK_FAIL \
            "System failed units" \
            "${#sys_failed[@]} failed unit(s)" \
            "View: systemctl list-units --state=failed"

        for unit in "${sys_failed[@]}"; do
            [[ -z "$unit" ]] && continue
            local unit_desc
            unit_desc="$(systemctl show -p Description --value "$unit" \
                        2>/dev/null || echo '?')"
            _check_report $CHECK_FAIL \
                "  ✗ ${unit}" \
                "${unit_desc}" \
                "Fix: systemctl restart ${unit}"
        done
    fi

    # ── User failed units ─────────────────────────────────────────────────────────
    local usr_failed=()
    mapfile -t usr_failed < <(
        systemctl --user list-units --state=failed --no-legend \
                  --no-pager 2>/dev/null | awk '{print $1}' | head -20
    )

    if [[ ${#usr_failed[@]} -eq 0 ]] || [[ -z "${usr_failed[0]:-}" ]]; then
        _check_report $CHECK_PASS \
            "User failed units" \
            "None  🎉"
    else
        _check_report $CHECK_FAIL \
            "User failed units" \
            "${#usr_failed[@]} failed unit(s)" \
            "View: systemctl --user list-units --state=failed"

        for unit in "${usr_failed[@]}"; do
            [[ -z "$unit" ]] && continue
            local unit_desc
            unit_desc="$(systemctl --user show -p Description --value "$unit" \
                        2>/dev/null || echo '?')"
            _check_report $CHECK_FAIL \
                "  ✗ ${unit}" \
                "${unit_desc}" \
                "Fix: systemctl --user restart ${unit}"
        done
    fi

    # ── System overall state ──────────────────────────────────────────────────────
    local sys_state
    sys_state="$(systemctl is-system-running 2>/dev/null || echo 'unknown')"
    case "$sys_state" in
        running)
            _check_report $CHECK_PASS "System running state" "running  ✓" ;;
        degraded)
            _check_report $CHECK_WARN "System running state" \
                "degraded  (some units failed)" \
                "systemctl list-units --state=failed" ;;
        maintenance|emergency)
            _check_report $CHECK_FAIL "System running state" \
                "${sys_state}  — system in recovery mode!" \
                "journalctl -b -p err --no-pager | tail -20" ;;
        *)
            _check_report $CHECK_INFO "System running state" "$sys_state" ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 02 — ASH DAEMON SERVICES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_svc_ash_daemons() {
    _check_header "⚡ ASH Daemon Services"

    # Format: "unit|expected|label|fix_hint|critical"
    local -a ash_services=(
        "ash-hot-reload.service|active|Hot reload engine|systemctl --user enable --now ash-hot-reload|0"
        "ash-plugin-daemon.service|any|Plugin daemon|systemctl --user enable --now ash-plugin-daemon|0"
        "ash-ipc-server.service|any|IPC server|systemctl --user enable --now ash-ipc-server|0"
        "ash-theme-watcher.service|any|Theme watcher|systemctl --user enable --now ash-theme-watcher|0"
        "ash-battery-monitor.service|any|Battery monitor|systemctl --user enable --now ash-battery-monitor|0"
        "ash-network-monitor.service|any|Network monitor|systemctl --user enable --now ash-network-monitor|0"
        "ash-weather-fetch.service|any|Weather fetch||0"
        "ash-ai-assistant.service|any|AI assistant||0"
        "ash-discord-rpc.service|any|Discord RPC||0"
        "ash-spotify-sync.service|any|Spotify sync||0"
    )

    local ash_svc_total=0 ash_svc_active=0

    for svc_entry in "${ash_services[@]}"; do
        IFS='|' read -r unit expected label fix_hint critical <<< "$svc_entry"
        (( ash_svc_total++ )) || true

        local active_state
        active_state="$(systemctl --user is-active "$unit" 2>/dev/null || echo 'inactive')"

        [[ "$active_state" == "active" ]] && (( ash_svc_active++ )) || true

        _svc_check "user" "$unit" "$expected" "$label" "$fix_hint" "$critical"
    done

    _check_report $CHECK_INFO \
        "ASH services summary" \
        "${ash_svc_active}/${ash_svc_total} active"

    # ── ASH timer summary ─────────────────────────────────────────────────────────
    local ash_timers=()
    mapfile -t ash_timers < <(
        systemctl --user list-timers --no-legend --no-pager 2>/dev/null | \
        grep '^ash-' | awk '{print $1}' | head -20
    )

    if [[ ${#ash_timers[@]} -gt 0 ]]; then
        _check_report $CHECK_INFO \
            "ASH timers active" \
            "${#ash_timers[@]} timer(s) scheduled"
        for timer in "${ash_timers[@]}"; do
            local next_run
            next_run="$(systemctl --user list-timers "$timer" --no-legend \
                        --no-pager 2>/dev/null | awk 'NR==1{print $1,$2,$3}' || echo '?')"
            _check_report $CHECK_INFO "  Timer: ${timer}" "${next_run}"
        done
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 03 — CRITICAL SYSTEM SERVICES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_svc_system() {
    _check_header "🔧 Critical System Services"

    # ── Must-be-active system services ───────────────────────────────────────────
    _svc_check "system" "dbus.service" \
        "active" "D-Bus system bus" \
        "sudo systemctl restart dbus" 1

    _svc_check "system" "systemd-logind.service" \
        "active" "systemd-logind" \
        "sudo systemctl restart systemd-logind" 1

    _svc_check "system" "systemd-udevd.service" \
        "active" "udev device manager" \
        "sudo systemctl restart systemd-udevd" 1

    _svc_check "system" "systemd-resolved.service" \
        "any" "systemd-resolved (DNS)" \
        "sudo systemctl enable --now systemd-resolved" 0

    _svc_check "system" "NetworkManager.service" \
        "any" "NetworkManager" \
        "sudo systemctl enable --now NetworkManager" 0

    _svc_check "system" "bluetooth.service" \
        "any" "Bluetooth daemon" \
        "sudo systemctl enable --now bluetooth" 0

    _svc_check "system" "cups.service" \
        "any" "CUPS printing" "" 0

    _svc_check "system" "avahi-daemon.service" \
        "any" "Avahi mDNS" "" 0

    _svc_check "system" "sshd.service" \
        "any" "SSH daemon" "" 0

    _svc_check "system" "docker.service" \
        "any" "Docker" "" 0

    _svc_check "system" "libvirtd.service" \
        "any" "libvirt virtualization" "" 0

    _svc_check "system" "fstrim.timer" \
        "any" "SSD TRIM timer" "" 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 04 — USER SESSION SERVICES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_svc_user_session() {
    _check_header "👤 User Session Services"

    # ── Core Wayland session ──────────────────────────────────────────────────────
    _svc_check "user" "dbus.service" \
        "active" "D-Bus user session" "" 1

    _svc_check "user" "pipewire.service" \
        "active" "PipeWire audio/video" \
        "systemctl --user enable --now pipewire" 1

    _svc_check "user" "pipewire-pulse.service" \
        "active" "PipeWire PulseAudio" \
        "systemctl --user enable --now pipewire-pulse" 1

    _svc_check "user" "wireplumber.service" \
        "active" "WirePlumber session mgr" \
        "systemctl --user enable --now wireplumber" 1

    _svc_check "user" "xdg-desktop-portal.service" \
        "active" "XDG Desktop Portal" \
        "systemctl --user enable --now xdg-desktop-portal" 1

    _svc_check "user" "xdg-desktop-portal-hyprland.service" \
        "active" "XDG Portal Hyprland" \
        "systemctl --user enable --now xdg-desktop-portal-hyprland" 1

    _svc_check "user" "xdg-desktop-portal-gtk.service" \
        "active" "XDG Portal GTK" \
        "systemctl --user enable --now xdg-desktop-portal-gtk" 1

    # ── Optional but recommended ──────────────────────────────────────────────────
    _svc_check "user" "gcr-ssh-agent.service" \
        "any" "GCR SSH agent" "" 0

    _svc_check "user" "gnome-keyring-daemon.service" \
        "any" "GNOME Keyring" "" 0

    _svc_check "user" "ssh-agent.service" \
        "any" "SSH agent" "" 0

    _svc_check "user" "gpg-agent.service" \
        "any" "GPG agent" "" 0

    _svc_check "user" "mpd.service" \
        "any" "MPD music daemon" "" 0

    _svc_check "user" "syncthing.service" \
        "any" "Syncthing file sync" "" 0

    _svc_check "user" "ollama.service" \
        "any" "Ollama AI server" "" 0

    # ── systemd-user target units ──────────────────────────────────────────────────
    local user_target_state
    user_target_state="$(systemctl --user is-active \
                         graphical-session.target 2>/dev/null || echo 'inactive')"

    if [[ "$user_target_state" == "active" ]]; then
        _check_report $CHECK_PASS \
            "graphical-session.target" \
            "Active  (Wayland session properly anchored)"
    else
        _check_report $CHECK_WARN \
            "graphical-session.target" \
            "${user_target_state}  — Wayland session target not active" \
            "This affects service ordering — check Hyprland session startup"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 05 — TIMERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_svc_timers() {
    _check_header "⏰ systemd Timers"

    # ── System timers ─────────────────────────────────────────────────────────────
    local sys_timers_out
    sys_timers_out="$(systemctl list-timers --all --no-legend --no-pager \
                     2>/dev/null | head -30 || echo '')"
    local sys_timer_count
    sys_timer_count="$(printf '%s\n' "$sys_timers_out" | grep -c '.' || echo 0)"

    _check_report $CHECK_INFO \
        "System timers" \
        "${sys_timer_count} timer(s) configured"

    # Important system timers
    local -a important_timers=(
        "fstrim.timer:SSD TRIM:system"
        "logrotate.timer:Log rotation:system"
        "man-db.timer:Man page DB update:system"
        "shadow.timer:Shadow files update:system"
        "paccache.timer:Pacman cache cleanup:system"
        "systemd-tmpfiles-clean.timer:Tmpfiles cleanup:system"
        "arch-audit.timer:Security audit:system"
    )

    for timer_entry in "${important_timers[@]}"; do
        IFS=':' read -r unit label scope <<< "$timer_entry"
        local timer_state
        timer_state="$(systemctl "--${scope}" is-active "$unit" 2>/dev/null || echo 'inactive')"

        if [[ "$timer_state" == "active" ]]; then
            # Get next trigger
            local next
            next="$(systemctl "--${scope}" list-timers "$unit" --no-legend \
                   --no-pager 2>/dev/null | awk 'NR==1{print $1,$2}' || echo '?')"
            _check_report $CHECK_PASS \
                "Timer: ${label}" \
                "Active  •  next: ${next}"
        else
            _check_report $CHECK_INFO \
                "Timer: ${label}" \
                "Not active  (${unit})"
        fi
    done

    # ── User timers ───────────────────────────────────────────────────────────────
    local usr_timer_count
    usr_timer_count="$(systemctl --user list-timers --all --no-legend \
                      --no-pager 2>/dev/null | grep -c '.' || echo 0)"
    _check_report $CHECK_INFO \
        "User timers" \
        "${usr_timer_count} timer(s) configured"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 06 — RESOURCE USAGE BY TOP SERVICES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_svc_resources() {
    _check_header "📊 Service Resource Usage  (Top 10)"

    # systemd-cgtop output (top slices by CPU)
    if command -v systemd-cgtop &>/dev/null; then
        local cgtop_out
        cgtop_out="$(systemd-cgtop --batch -n 1 --depth=3 2>/dev/null | \
                    tail -n +4 | head -10 || echo '')"

        if [[ -n "$cgtop_out" ]]; then
            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                local slice cpu mem
                slice="$(printf '%s' "$line" | awk '{print $1}')"
                cpu="$(  printf '%s' "$line" | awk '{print $2}')"
                mem="$(  printf '%s' "$line" | awk '{print $4}')"

                # Highlight high CPU
                local cpu_num="${cpu%.*}"
                if [[ "$cpu_num" =~ ^[0-9]+$ ]] && (( cpu_num > 20 )); then
                    _check_report $CHECK_WARN \
                        "High CPU: ${slice##*/}" \
                        "CPU: ${cpu}%  •  MEM: ${mem}"
                else
                    _check_report $CHECK_INFO \
                        "Service: ${slice##*/}" \
                        "CPU: ${cpu}%  •  MEM: ${mem}"
                fi
            done <<< "$cgtop_out"
        fi
    fi

    # ── D-Bus service count ───────────────────────────────────────────────────────
    if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] && command -v dbus-send &>/dev/null; then
        local dbus_services
        dbus_services="$(dbus-send \
            --session \
            --print-reply \
            --dest=org.freedesktop.DBus \
            /org/freedesktop/DBus \
            org.freedesktop.DBus.ListNames \
            2>/dev/null | grep -c 'string "' || echo '?')"
        _check_report $CHECK_INFO \
            "D-Bus session services" \
            "${dbus_services} service name(s) registered"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_check_services() {
    local mode="${1:-full}"

    _CHECK_PASS_COUNT=0;  _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0;  _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=();   _CHECK_WARNINGS=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;180;190;254m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  ⚙️   ASH DOCTOR — SERVICES CHECK                         ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  failed units • ASH daemons • system • user • timers     ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n=== ASH DOCTOR — SERVICES CHECK ===\n'
    fi

    if ! command -v systemctl &>/dev/null; then
        _check_report $CHECK_FAIL \
            "systemd" \
            "systemctl not available — services check requires systemd"
        _ash_check_system_summary
        return $CHECK_FAIL
    fi

    case "$mode" in
        quick)
            _chk_svc_failed_units
            _chk_svc_user_session
            ;;
        ash)        _chk_svc_ash_daemons   ;;
        system)     _chk_svc_system        ;;
        timers)     _chk_svc_timers        ;;
        full|*)
            _chk_svc_failed_units
            _chk_svc_ash_daemons
            _chk_svc_system
            _chk_svc_user_session
            _chk_svc_timers
            _chk_svc_resources
            ;;
    esac

    _ash_check_system_summary
}

ash_check_services_quick() {
    local issues=0

    # Failed units check
    local sys_failed usr_failed
    sys_failed="$(systemctl --system list-units --state=failed --no-legend \
                  --no-pager 2>/dev/null | wc -l)"
    usr_failed="$( systemctl --user   list-units --state=failed --no-legend \
                  --no-pager 2>/dev/null | wc -l)"

    (( sys_failed > 0 )) && (( issues++ )) || true
    (( usr_failed > 0 )) && (( issues++ )) || true

    # Core services
    systemctl --user is-active pipewire   &>/dev/null || (( issues++ )) || true
    systemctl --user is-active wireplumber &>/dev/null || (( issues++ )) || true

    if (( issues == 0 )); then
        ash_log_success "Services: OK  (no failed units  •  PipeWire running)"
    else
        ash_log_warn "Services: ${issues} concern(s) — run 'ash doctor full --services'"
        return 1
    fi
}
