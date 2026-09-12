#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  ⏰ ASH SCHEDULER — cron-free recurring jobs via systemd user timers          ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  Why not crontab?                                                             ║
# ║    • Cron has no concept of "run once the session is up"                      ║
# ║    • Cron jobs inherit almost no environment, so themes break                 ║
# ║    • systemd timers support Persistent=true (catch up after suspend),         ║
# ║      RandomizedDelaySec (avoid the 09:00 thundering herd), and journal logs   ║
# ║                                                                               ║
# ║  This module generates + manages systemd user units. When systemd is absent   ║
# ║  (BSD, containers, WSL1) it falls back to a self-managing daemon loop.        ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_SCHEDULER_LOADED:-}" ]] && return 0
readonly _ASH_SCHEDULER_LOADED=1
readonly ASH_SCHEDULER_VERSION="5.0.0"

: "${ASH_SYSTEMD_USER_DIR:=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user}"
: "${ASH_SCHEDULE_DIR:=${XDG_CONFIG_HOME:-$HOME/.config}/ash/schedules}"

# ── Job registry: name -> "<OnCalendar>|<command>|<describe>" ────────────────
declare -gA ASH_SCHEDULE_REGISTRY=(
    [theme-watcher]="*:0/5|ash theme schedule --tick|Re-evaluate time/weather based theme"
    [wallpaper-slideshow]="*:0/15|ash wallpaper slideshow --next|Advance the wallpaper rotation"
    [snapshot-auto]="daily 03:30|ash snapshot create --auto --tag scheduled|Nightly config snapshot"
    [backup-daily]="daily 04:00|ash backup create --incremental --keep 7|Nightly incremental backup"
    [cleanup]="weekly Sun 05:00|ash clean --deep --yes|Weekly cache and log cleanup"
    [update-check]="daily 09:00|ash update --check|Check for dotfile updates"
    [weather-fetch]="*:0/30|ash wallpaper weather --refresh-cache|Refresh weather data"
    [night-light]="*-*-* 19:00|ash theme mode --night|Enable night light at dusk"
    [day-light]="*-*-* 07:00|ash theme mode --day|Disable night light at dawn"
    [health-monitor]="*:0/10|ash doctor --quick --quiet|Periodic health probe"
    [analytics]="hourly|ash analytics collect|Record usage metrics"
)

_ash_scheduler_has_systemd() {
    command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]
}

# ── Time spec translation ────────────────────────────────────────────────────
# Accepts either a friendly shorthand or a raw systemd calendar expression.
#   "hourly"            → *-*-* *:00:00
#   "daily 03:30"       → *-*-* 03:30:00
#   "weekly Sun 05:00"  → Sun *-*-* 05:00:00
#   "*:0/15"            → *-*-* *:0/15:00
_ash_schedule_parse() {
    local spec="$1"

    case "$spec" in
        hourly)  printf '*-*-* *:00:00'; return ;;
        daily)   printf '*-*-* 00:00:00'; return ;;
        weekly)  printf 'Mon *-*-* 00:00:00'; return ;;
        monthly) printf '*-*-01 00:00:00'; return ;;
        daily\ *)  printf '*-*-* %s:00' "${spec#daily }"; return ;;
        weekly\ *)
            local rest="${spec#weekly }"
            printf '%s *-*-* %s:00' "${rest%% *}" "${rest#* }"
            return
            ;;
        *:0/*)   printf '*-*-* %s:00' "$spec"; return ;;
        *.+*)    printf '%s' "$spec"; return ;;
    esac

    # Already looks like a systemd calendar expression?
    if [[ "$spec" == *-*-* || "$spec" == Mon* || "$spec" == Sun* || "$spec" == '*:'* ]]; then
        printf '%s' "$spec"
    else
        printf '*-*-* %s:00' "$spec"
    fi
}

# ── Unit generation ──────────────────────────────────────────────────────────
ash_schedule_service_content() {
    local name="$1" command="$2" description="$3"

    cat <<EOF
[Unit]
Description=${description}
Documentation=man:ash(1)
After=graphical-session.target
PartOf=graphical-session.target
ConditionEnvironment=WAYLAND_DISPLAY

[Service]
Type=oneshot
ExecStart=/usr/bin/env bash -lc '${command}'
# systemd's default PATH is minimal; inherit the session's.
Environment=PATH=${PATH}
Environment=XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
Environment=WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-1}
Environment=ASH_VERSION=${ASH_VERSION:-5.0.0-omega}
WorkingDirectory=${HOME}

# Never let a stuck job pile up.
TimeoutStartSec=300
TimeoutStopSec=15

# Resource guard rails — these jobs must never compete with the user's work.
CPUWeight=20
IOWeight=20
MemoryMax=512M
MemoryHigh=384M

# Restart only on genuine failure, with backoff.
Restart=on-failure
RestartSec=30

# Modest hardening; these jobs read configs, so we can't sandbox aggressively.
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=read-only
ReadWritePaths=${HOME}/.config/ash ${HOME}/.local/share/ash ${HOME}/.cache/ash ${HOME}/.local/state/ash

StandardOutput=journal
StandardError=journal
SyslogIdentifier=ash-${name}
EOF
}

ash_schedule_timer_content() {
    local name="$1" on_calendar="$2" description="$3"

    cat <<EOF
[Unit]
Description=${description} (timer)
Documentation=man:ash(1)

[Timer]
OnCalendar=${on_calendar}
# Catch up if the machine was asleep when the timer should have fired.
Persistent=true
# Spread load so every ASH user doesn't wake up at the same second.
RandomizedDelaySec=300
AccuracySec=1min
Unit=ash-${name}.service

[Install]
WantedBy=timers.target
EOF
}

# ── Enable / disable ─────────────────────────────────────────────────────────
ash_schedule_enable() {
    local name="$1"
    local spec="${ASH_SCHEDULE_REGISTRY[$name]:-}"

    if [[ -z "$spec" ]]; then
        # Allow ad-hoc schedules: ash schedule enable <name> "<OnCalendar>" "<command>"
        if [[ -n "${2:-}" && -n "${3:-}" ]]; then
            spec="$2|$3|Custom ASH schedule: $name"
            ASH_SCHEDULE_REGISTRY["$name"]="$spec"
        else
            ash_log_error "unknown schedule: ${name}" 2>/dev/null || true
            return 1
        fi
    fi

    local on_cal command description
    IFS='|' read -r on_cal command description <<< "$spec"
    on_cal="$(_ash_schedule_parse "$on_cal")"

    if _ash_scheduler_has_systemd; then
        mkdir -p "$ASH_SYSTEMD_USER_DIR" 2>/dev/null || return 1

        ash_schedule_service_content "$name" "$command" "$description" \
            > "${ASH_SYSTEMD_USER_DIR}/ash-${name}.service" || return 1
        ash_schedule_timer_content "$name" "$on_cal" "$description" \
            > "${ASH_SYSTEMD_USER_DIR}/ash-${name}.timer" || return 1

        systemctl --user daemon-reload 2>/dev/null || true
        if ! systemctl --user enable --now "ash-${name}.timer" 2>/dev/null; then
            ash_log_warn "could not enable ash-${name}.timer (is the user manager running?)" 2>/dev/null || true
            return 1
        fi
        ash_log_info "scheduled '${name}' → ${on_cal}" 2>/dev/null || true
    else
        # ── Fallback daemon ──────────────────────────────────────────────
        mkdir -p "$ASH_SCHEDULE_DIR" 2>/dev/null || true
        printf '%s|%s|%s\n' "$on_cal" "$command" "$description" \
            > "${ASH_SCHEDULE_DIR}/${name}.job"
        ash_log_warn "systemd unavailable — registered '${name}' for the fallback daemon" 2>/dev/null || true
    fi

    ash_event_emit "schedule.enabled" "name=${name}" "on_calendar=${on_cal}" 2>/dev/null || true
    return 0
}

ash_schedule_disable() {
    local name="$1"

    if _ash_scheduler_has_systemd; then
        systemctl --user disable --now "ash-${name}.timer" 2>/dev/null || true
        rm -f "${ASH_SYSTEMD_USER_DIR}/ash-${name}.service" \
              "${ASH_SYSTEMD_USER_DIR}/ash-${name}.timer" 2>/dev/null || true
        systemctl --user daemon-reload 2>/dev/null || true
    fi

    rm -f "${ASH_SCHEDULE_DIR}/${name}.job" 2>/dev/null || true
    ash_event_emit "schedule.disabled" "name=${name}" 2>/dev/null || true
    return 0
}

ash_schedule_list() {
    local name
    for name in $(printf '%s\n' "${!ASH_SCHEDULE_REGISTRY[@]}" | LC_ALL=C sort); do
        local spec="${ASH_SCHEDULE_REGISTRY[$name]}"
        local on_cal="${spec%%|*}"
        local rest="${spec#*|}"
        local command="${rest%%|*}"
        local description="${rest#*|}"

        local state="disabled"
        local next="—"

        if _ash_scheduler_has_systemd; then
            if systemctl --user is-enabled "ash-${name}.timer" >/dev/null 2>&1; then
                state="enabled"
                next="$(systemctl --user list-timers "ash-${name}.timer" --no-legend 2>/dev/null | awk '{print $1, $2, $3}' | head -1)"
                [[ -z "$next" ]] && next="pending"
            fi
        elif [[ -f "${ASH_SCHEDULE_DIR}/${name}.job" ]]; then
            state="enabled (daemon)"
        fi

        printf '%s|%s|%s|%s|%s\n' "$name" "$on_cal" "$state" "${next:-—}" "$description"
    done
}

ash_schedule_status() {
    if ! _ash_scheduler_has_systemd; then
        printf '  systemd : unavailable — fallback daemon mode\n'
        printf '  job dir : %s\n' "$ASH_SCHEDULE_DIR"
        local count; count="$(find "$ASH_SCHEDULE_DIR" -name '*.job' 2>/dev/null | wc -l)"
        printf '  jobs    : %d registered\n' "$count"
        return 0
    fi

    printf '  systemd : available\n'
    printf '  units   : %s\n' "$ASH_SYSTEMD_USER_DIR"

    local enabled=0 total=0
    local t
    while IFS= read -r t || [[ -n "$t" ]]; do
        [[ -z "$t" ]] && continue
        (( total += 1 ))
        systemctl --user is-enabled "$t" >/dev/null 2>&1 && (( enabled += 1 ))
    done < <(find "$ASH_SYSTEMD_USER_DIR" -maxdepth 1 -name 'ash-*.timer' -printf '%f\n' 2>/dev/null)

    printf '  timers  : %d/%d enabled\n' "$enabled" "$total"

    if (( total > 0 )); then
        printf '\n'
        systemctl --user list-timers 'ash-*' --no-legend --no-pager 2>/dev/null \
            | awk '{printf "  %-8s %-8s %-22s %s %s\n", $1, $2, $3, $4, $5}' | head -20
    fi

    # Report any unit that failed since last check
    local failed
    failed="$(systemctl --user list-units 'ash-*' --state=failed --no-legend --no-pager 2>/dev/null | wc -l)"
    (( failed > 0 )) && printf '\n  ⚠ %d ASH unit(s) in failed state — run: ash schedule logs <name>\n' "$failed"
    return 0
}

ash_schedule_logs() {
    local name="$1" lines="${2:-50}"
    if _ash_scheduler_has_systemd; then
        journalctl --user -u "ash-${name}.service" -n "$lines" --no-pager 2>/dev/null
    else
        printf 'fallback daemon log: %s\n' "${ASH_SCHEDULE_DIR}/daemon.log"
        [[ -f "${ASH_SCHEDULE_DIR}/daemon.log" ]] && tail -n "$lines" "${ASH_SCHEDULE_DIR}/daemon.log"
    fi
}

ash_schedule_run_now() {
    local name="$1"
    if _ash_scheduler_has_systemd; then
        systemctl --user start "ash-${name}.service" 2>/dev/null \
            && ash_log_info "started ash-${name}.service" 2>/dev/null || true
    else
        local job="${ASH_SCHEDULE_DIR}/${name}.job"
        [[ -f "$job" ]] || return 1
        local command; IFS='|' read -r _ command _ < "$job"
        bash -lc "$command"
    fi
}

# Enables every schedule the user config marks as active.
ash_schedule_enable_configured() {
    local -a active=()
    if declare -f ash_config_get_array >/dev/null 2>&1; then
        mapfile -t active < <(ash_config_get_array "schedule.enabled" 2>/dev/null || true)
    fi

    # Nothing configured → enable the safe defaults.
    if (( ${#active[@]} == 0 )); then
        active=(theme-watcher wallpaper-slideshow snapshot-auto cleanup update-check)
    fi

    local name ok=0 fail=0
    for name in "${active[@]}"; do
        if ash_schedule_enable "$name" >/dev/null 2>&1; then (( ok += 1 )); else (( fail += 1 )); fi
    done
    printf '%d enabled, %d failed\n' "$ok" "$fail"
}

# ── Fallback daemon ──────────────────────────────────────────────────────────
# Runs in the foreground; intended to be started by the session autostart.
ash_schedule_daemon() {
    mkdir -p "$ASH_SCHEDULE_DIR" 2>/dev/null || true
    local log="${ASH_SCHEDULE_DIR}/daemon.log"

    ash_log_info "ASH scheduler daemon started (pid $$)" 2>/dev/null || true

    declare -A last_run=()

    while :; do
        local now; now="$(date +%s)"
        local minute; minute="$(date +%M)"
        local hour; hour="$(date +%H)"
        local dom; dom="$(date +%d)"
        local dow; dow="$(date +%u)"    # 1=Mon … 7=Sun

        local job
        for job in "$ASH_SCHEDULE_DIR"/*.job; do
            [[ -f "$job" ]] || continue
            local name; name="$(basename "$job" .job)"
            local spec; spec="$(cat "$job")"
            local on_cal="${spec%%|*}"
            local rest="${spec#*|}"
            local command="${rest%%|*}"

            local should_run=0

            # A deliberately small subset of systemd's calendar syntax —
            # enough for the schedules we ship.
            case "$on_cal" in
                *'*:0/'*)
                    local step="${on_cal##*:0/}"
                    step="${step%%:*}"
                    (( minute % step == 0 )) && should_run=1
                    ;;
                'hourly')     (( minute == 0 )) && should_run=1 ;;
                'daily '*)
                    local t="${on_cal#daily }"; t="${t%:00}"
                    [[ "$hour:$minute" == "$t" ]] && should_run=1
                    ;;
                '*-*-01 '*)   [[ "$dom" == "01" && "$minute" == "00" ]] && should_run=1 ;;
                *'Sun '*)     [[ "$dow" == "7" && "$minute" == "00" ]] && should_run=1 ;;
                *-*-*\ *)
                    local t="${on_cal##* }"; t="${t%:00}"
                    [[ "$hour:$minute" == "$t" ]] && should_run=1
                    ;;
            esac

            (( should_run == 0 )) && continue

            # Guard against double-firing inside the same minute.
            local key="${name}:${hour}:${minute}"
            [[ "${last_run[$key]:-0}" == "$now" ]] && continue
            last_run["$key"]="$now"

            printf '%s running %s\n' "$(date -Iseconds)" "$name" >> "$log"
            ( bash -lc "$command" >> "$log" 2>&1 & ) 2>/dev/null || true
        done

        # Prune the dedupe map so it can't grow without bound.
        if (( ${#last_run[@]} > 200 )); then
            last_run=()
        fi

        sleep 30
    done
}

# ── Diagnostics used by `ash doctor` ─────────────────────────────────────────
ash_schedule_health() {
    if ! _ash_scheduler_has_systemd; then
        printf '  ⚠ systemd user session unavailable — schedules use the fallback daemon\n'
        return 0
    fi

    local ok=0 broken=0
    local f
    while IFS= read -r f || [[ -n "$f" ]]; do
        [[ -z "$f" ]] && continue
        local name; name="$(basename "$f" .timer)"
        if systemctl --user cat "$name" >/dev/null 2>&1; then
            (( ok += 1 ))
        else
            printf '  ✗ unit not loadable: %s\n' "$name"
            (( broken += 1 ))
        fi
    done < <(find "$ASH_SYSTEMD_USER_DIR" -maxdepth 1 -name 'ash-*.timer' 2>/dev/null)

    printf '  ✓ %d schedule unit(s) loadable' "$ok"
    (( broken > 0 )) && printf ', %d broken' "$broken"
    printf '\n'
    return $(( broken > 0 ? 1 : 0 ))
}
