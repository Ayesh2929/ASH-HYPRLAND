#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  backup schedule                                          ║
# ║  Systemd timer and cron-based automated backup scheduling                       ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_BK_SCHEDULE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_BK_SCHEDULE_LOADED=1

set -euo pipefail
IFS=$'\n\t'

declare -gr _SCHED_SERVICE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
declare -gr _SCHED_SERVICE_NAME="ash-backup"

_sched_create_systemd() {
    local frequency="$1"  time_spec="$2"  bk_type="${3:-full}"

    mkdir -p "$_SCHED_SERVICE_DIR" 2>/dev/null || true

    # Generate OnCalendar spec
    local on_calendar
    case "$frequency" in
        hourly)   on_calendar="hourly"                      ;;
        daily)    on_calendar="daily"                       ;;
        weekly)   on_calendar="weekly"                      ;;
        monthly)  on_calendar="monthly"                     ;;
        *)
            # Custom time
            on_calendar="*-*-* ${time_spec:-02:00}:00"
            [[ "$frequency" =~ ^[0-9] ]] && \
                on_calendar="${frequency} ${time_spec:-02:00}:00"
            ;;
    esac

    # Service file
    cat > "${_SCHED_SERVICE_DIR}/${_SCHED_SERVICE_NAME}.service" << SVCEOF
[Unit]
Description=ASH Backup Service
Documentation=https://github.com/ash-dotfiles
After=network.target

[Service]
Type=oneshot
ExecStart=${HOME}/.local/bin/ash backup create ${bk_type} --no-notify
StandardOutput=journal
StandardError=journal
Environment=HOME=${HOME}
Environment=XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
Environment=XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
SVCEOF

    # Timer file
    cat > "${_SCHED_SERVICE_DIR}/${_SCHED_SERVICE_NAME}.timer" << TIMEREOF
[Unit]
Description=ASH Backup Timer (${frequency})
Documentation=https://github.com/ash-dotfiles

[Timer]
OnCalendar=${on_calendar}
Persistent=true
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
TIMEREOF

    # Enable and start timer
    systemctl --user daemon-reload 2>/dev/null
    systemctl --user enable "${_SCHED_SERVICE_NAME}.timer" 2>/dev/null && \
        systemctl --user start "${_SCHED_SERVICE_NAME}.timer" 2>/dev/null

    bk_ok "Systemd timer created: ${frequency}"
    bk_kv "Schedule"   "$on_calendar"
    bk_kv "Backup type" "$bk_type"
    bk_kv "Service"    "${_SCHED_SERVICE_NAME}.timer"
}

_sched_status() {
    bk_section "📊" "Schedule Status" "$(_bkdim)"

    # Systemd timer
    local timer_active
    timer_active="$(systemctl --user is-active \
                    "${_SCHED_SERVICE_NAME}.timer" 2>/dev/null || echo 'inactive')"

    if [[ "$timer_active" == "active" ]]; then
        bk_kv "Systemd timer" "$(bk_badge " ● ACTIVE " "$(_bkgreen)")"

        # Next run
        local next_run
        next_run="$(systemctl --user list-timers \
                    "${_SCHED_SERVICE_NAME}.timer" \
                    --no-legend 2>/dev/null | \
                    awk 'NR==1{print $1,$2,$3}' || echo '?')"
        bk_kv "Next run" "${next_run:-?}"

        # Last run
        local last_run
        last_run="$(systemctl --user status \
                    "${_SCHED_SERVICE_NAME}.service" 2>/dev/null | \
                    grep 'Active:' | head -1 | sed 's/.*; //' || echo '?')"
        bk_kv "Last run" "${last_run:-?}"
    else
        bk_kv "Systemd timer" "$(bk_badge " ○ INACTIVE " "$(_bkdim)")"
    fi

    # Config file
    if [[ -f "$_BK_SCHEDULE_FILE" ]]; then
        bk_kv "Config file" "${_BK_SCHEDULE_FILE/#$HOME/~}"
        while IFS='=' read -r k v; do
            [[ "$k" =~ ^# ]] && continue
            [[ -z "$k" ]] && continue
            bk_kv "  ${k}" "${v}"
        done < "$_BK_SCHEDULE_FILE"
    fi

    # Cron fallback check
    if command -v crontab &>/dev/null; then
        local cron_entry
        cron_entry="$(crontab -l 2>/dev/null | grep "ash.*backup" || echo '')"
        [[ -n "$cron_entry" ]] && \
            bk_kv "Cron entry" "$cron_entry"
    fi
}

ash_backup_schedule() {
    local action="status"
    local frequency=""
    local time_spec="02:00"
    local bk_type="full"

    for arg in "${@:-}"; do
        case "$arg" in
            status|info)      action="status"  ;;
            enable|add|set)   action="enable"  ;;
            disable|remove)   action="disable" ;;
            list)             action="list"    ;;
            hourly|daily|weekly|monthly) frequency="$arg" ;;
            --time=*)         time_spec="${arg#*=}" ;;
            --type=*)         bk_type="${arg#*=}"   ;;
            [0-9][0-9]:[0-9][0-9]) time_spec="$arg" ;;
        esac
    done

    bk_section "⏰" "Backup Schedule" "$(_bkyellow)"

    case "$action" in
        status)
            _sched_status
            ;;

        enable)
            if [[ -z "$frequency" ]]; then
                printf '\n  %sFrequency [hourly/daily/weekly/monthly]: %s' \
                    "$(_bkyellow)" "$(_bkr)"
                read -r frequency
            fi
            [[ -z "$frequency" ]] && { bk_info "No frequency specified"; return 0; }

            bk_kv "Frequency"  "$frequency"
            bk_kv "Time"       "$time_spec"
            bk_kv "Type"       "$bk_type"

            bk_step "Creating systemd timer..."
            _sched_create_systemd "$frequency" "$time_spec" "$bk_type"

            # Save config
            mkdir -p "$(dirname "$_BK_SCHEDULE_FILE")" 2>/dev/null || true
            {
                printf '# ASH Backup Schedule — %s\n' "$(date -Iseconds)"
                printf 'frequency=%s\n' "$frequency"
                printf 'time=%s\n' "$time_spec"
                printf 'type=%s\n' "$bk_type"
            } > "$_BK_SCHEDULE_FILE"

            bk_notify "⏰ Schedule Set" "Backup ${frequency} at ${time_spec}"
            ;;

        disable)
            bk_step "Disabling backup schedule..."
            systemctl --user stop "${_SCHED_SERVICE_NAME}.timer" 2>/dev/null || true
            systemctl --user disable "${_SCHED_SERVICE_NAME}.timer" 2>/dev/null || true
            rm -f \
                "${_SCHED_SERVICE_DIR}/${_SCHED_SERVICE_NAME}.timer" \
                "${_SCHED_SERVICE_DIR}/${_SCHED_SERVICE_NAME}.service" \
                "$_BK_SCHEDULE_FILE" \
                2>/dev/null || true
            systemctl --user daemon-reload 2>/dev/null || true
            bk_ok "Schedule disabled"
            ;;

        list)
            systemctl --user list-timers "*backup*" 2>/dev/null | \
            while IFS= read -r line; do
                printf '  %s%s%s\n' "$(_bkdim)" "$line" "$(_bkr)"
            done
            ;;
    esac

    printf '\n'
}
