#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — schedule.sh                                                      ║
# ║  Change the theme with the time of day                                        ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::schedule::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme schedule${RST} [options]

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Maps the four parts of the day to themes. The mapping is stored in
  ${ASH_MUTED}\$XDG_CONFIG_HOME/ash/theme-schedule.json${RST} and consulted by
  ${ASH_MUTED}--now${RST}; nothing runs in the background unless you install the timer.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--list${RST}                 Show the schedule and the current slot
  ${ASH_MUTED}--set SLOT=THEME${RST}       Assign a theme (slot: morning|day|evening|night)
  ${ASH_MUTED}--unset SLOT${RST}           Clear a slot
  ${ASH_MUTED}--now${RST}                  Apply the theme for the current slot
  ${ASH_MUTED}--install${RST}              Install a systemd timer to run --now hourly
  ${ASH_MUTED}--uninstall${RST}            Remove the timer
  ${ASH_MUTED}--status${RST}               Show whether the timer is active
  ${ASH_MUTED}--json${RST}                 Machine-readable output

${BOLD}${ASH_PRIMARY}SLOT BOUNDARIES${RST}
  ${ASH_MUTED}morning${RST} 05:00-09:59   ${ASH_MUTED}day${RST} 10:00-17:59
  ${ASH_MUTED}evening${RST} 18:00-21:59   ${ASH_MUTED}night${RST} 22:00-04:59

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme schedule --set day=gruvbox-light${RST}
  ${ASH_MUTED}ash theme schedule --set night=catppuccin-mocha${RST}
  ${ASH_MUTED}ash theme schedule --install${RST}
EOF
}

theme::schedule::file() { printf '%s' "${ASH_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/ash}/theme-schedule.json"; }

# Slot for an hour of the day.
theme::schedule::slot_for() {
    local h="${1:-$(date +%H 2>/dev/null || printf '12')}"
    h="${h#0}"; [[ -z "$h" ]] && h=0
    if   (( h >= 5  && h < 10 )); then printf 'morning'
    elif (( h >= 10 && h < 18 )); then printf 'day'
    elif (( h >= 18 && h < 22 )); then printf 'evening'
    else                                printf 'night'
    fi
}

theme::schedule::boundary() {
    case "$1" in
        morning) printf '05:00–09:59' ;;
        day)     printf '10:00–17:59' ;;
        evening) printf '18:00–21:59' ;;
        night)   printf '22:00–04:59' ;;
        *)       printf '?' ;;
    esac
}

theme::schedule() {
    local list=0 now=0 install=0 uninstall=0 status=0 json=0
    local -a sets=() unsets=()

    while (( $# )); do
        case "$1" in
            --list|-l)   list=1; shift ;;
            --now)       now=1; shift ;;
            --install)   install=1; shift ;;
            --uninstall) uninstall=1; shift ;;
            --status)    status=1; shift ;;
            --set)       sets+=("${2:-}"); shift 2 ;;
            --unset)     unsets+=("${2:-}"); shift 2 ;;
            --json)      json=1; export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help)   theme::schedule::help; return 0 ;;
            -*)          ash_log_error "Unknown option: $1"; theme::schedule::help; return 2 ;;
            *)           ash_log_error "Unexpected argument: $1"; theme::schedule::help; return 2 ;;
        esac
    done

    local file
    file="$(theme::schedule::file)"

    # ── Assignments ───────────────────────────────────────────────────────────
    if (( ${#sets[@]} || ${#unsets[@]} )); then
        local json_doc='{}'
        [[ -f "$file" ]] && json_doc="$(jq -c '.' "$file" 2>/dev/null || printf '{}')"

        local pair slot theme_name
        for pair in "${sets[@]}"; do
            [[ "$pair" == *=* ]] || { ash_log_error "--set wants SLOT=THEME (got: $pair)"; return 2; }
            slot="${pair%%=*}"; theme_name="${pair#*=}"
            case "$slot" in morning|day|evening|night) : ;;
                *) ash_log_error "Unknown slot: $slot (morning, day, evening, night)"; return 2 ;;
            esac
            if ! theme::resolve "$theme_name" >/dev/null 2>&1; then
                ash_log_error "No such theme: $theme_name"
                continue
            fi
            json_doc="$(jq -c --arg k "$slot" --arg v "$theme_name" '. + {($k): $v}' <<<"$json_doc")"
        done

        for slot in "${unsets[@]}"; do
            json_doc="$(jq -c --arg k "$slot" 'del(.[$k])' <<<"$json_doc")"
        done

        mkdir -p "$(dirname "$file")"
        jq -S . <<<"$json_doc" > "${file}.tmp" && mv "${file}.tmp" "$file" || {
            ash_log_error "Could not write $file"; return 1; }

        if (( json )); then printf '%s\n' "$json_doc"; return 0; fi

        printf '\n  %s✅ Schedule updated.%s\n\n' "${ASH_SUCCESS}" "${RST}"
        # `${array[*]}` joins with the first character of IFS, which is a
        # newline here, so the assignments ran together on one line.
        local _p
        for _p in "${sets[@]:-}"; do
            [[ -n "$_p" ]] && printf '    %s+ %s%s\n' "${ASH_ACCENT}" "$_p" "${RST}"
        done
        for _p in "${unsets[@]:-}"; do
            [[ -n "$_p" ]] && printf '    %s- %s%s\n' "${ASH_MUTED}" "$_p" "${RST}"
        done
        printf '\n'
        return 0
    fi

    # ── Timer management ──────────────────────────────────────────────────────
    if (( install || uninstall || status )); then
        local unit="ash-theme-schedule"
        local unitdir="${HOME}/.config/systemd/user"

        if (( uninstall )); then
            if declare -f ash_schedule_disable >/dev/null 2>&1; then
                ash_schedule_disable "$unit" >/dev/null 2>&1 || true
            fi
            rm -f "${unitdir}/${unit}.timer" "${unitdir}/${unit}.service"
            printf '\n  %s✅ Timer removed.%s\n\n' "${ASH_SUCCESS}" "${RST}"
            return 0
        fi

        local active=0
        if declare -f ash_schedule_has_systemd >/dev/null 2>&1 && ash_schedule_has_systemd 2>/dev/null; then
            systemctl --user is-active "${unit}.timer" >/dev/null 2>&1 && active=1
        fi

        if (( status )); then
            if (( json )); then
                jq -n --arg unit "$unit" --argjson active "$active" \
                      --arg file "$file" '{unit: $unit, active: ($active == 1), schedule_file: $file}'
            else
                printf '\n  %sTimer: %s%s\n' \
                    "${ASH_MUTED}" "$( ((active)) && printf 'active' || printf 'not installed' )" "${RST}"
                printf '  %sConfig: %s%s\n\n' "${ASH_MUTED}" "$file" "${RST}"
            fi
            return 0
        fi

        if ! declare -f ash_schedule_has_systemd >/dev/null 2>&1 || ! ash_schedule_has_systemd 2>/dev/null; then
            ash_log_error "systemd is not available; cannot install a timer."
            printf '  %sRun %sash theme schedule --now%s from your own cron instead.%s\n\n' \
                "${ASH_MUTED}" "${ASH_ACCENT}" "${ASH_MUTED}" "${RST}" >&2
            return 1
        fi

        mkdir -p "$unitdir"
        cat > "${unitdir}/${unit}.service" <<EOF
[Unit]
Description=ASH theme — apply the theme for the current time of day

[Service]
Type=oneshot
ExecStart=%h/.local/bin/ash theme schedule --now
EOF

        cat > "${unitdir}/${unit}.timer" <<EOF
[Unit]
Description=ASH theme — hourly time-of-day check

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF

        if declare -f ash_schedule_enable >/dev/null 2>&1; then
            ash_schedule_enable "$unit" >/dev/null 2>&1 || true
        fi
        systemctl --user daemon-reload >/dev/null 2>&1 || true
        systemctl --user enable --now "${unit}.timer" >/dev/null 2>&1 || true

        printf '\n  %s✅ Timer installed%s — the theme follows the time of day from now on.\n' \
            "${ASH_SUCCESS}" "${RST}"
        printf '  %s   Check it with: systemctl --user list-timers %s.timer%s\n\n' \
            "${ASH_MUTED}" "$unit" "${RST}"
        return 0
    fi

    # ── Read the schedule ─────────────────────────────────────────────────────
    local -A sched=()
    if [[ -f "$file" ]]; then
        local k v
        while IFS=$'\t' read -r k v; do
            [[ -n "$k" ]] && sched["$k"]="$v"
        done < <(jq -r 'to_entries[] | "\(.key)\t\(.value)"' "$file" 2>/dev/null)
    fi

    local slot
    slot="$(theme::schedule::slot_for)"

    if (( now )); then
        local chosen="${sched[$slot]:-}"
        if [[ -z "$chosen" ]]; then
            if (( json )); then
                jq -n --arg slot "$slot" '{slot: $slot, theme: null, applied: false}'
            else
                printf '\n  %sNo theme is scheduled for the %s.%s\n' \
                    "${ASH_MUTED}" "$slot" "${RST}"
                printf '  %sSet one:  ash theme schedule --set %s=<theme>%s\n\n' \
                    "${ASH_MUTED}" "$slot" "${RST}"
            fi
            return 0
        fi

        theme::source_sub apply || return 1
        theme::apply "$chosen" || return $?

        if (( json )); then
            jq -n --arg slot "$slot" --arg theme "$chosen" \
                  '{slot: $slot, theme: $theme, applied: true}'
        else
            printf '  %s🕐 %s — %s%s\n\n' "${ASH_MUTED}" "$slot" "$chosen" "${RST}"
        fi
        return 0
    fi

    if (( json )); then
        local obj='{}'
        local k
        for k in morning day evening night; do
            obj="$(jq -c --arg k "$k" --arg v "${sched[$k]:-}" '. + {($k): $v}' <<<"$obj")"
        done
        jq -n --argjson s "$obj" --arg slot "$slot" --arg file "$file" \
              '{schedule: $s, current_slot: $slot, file: $file}'
        return 0
    fi

    ash_banner "⏰ THEME SCHEDULE" "current slot: ${slot}" 80

    local have=0
    for slot in morning day evening night; do
        local theme_name="${sched[$slot]:-}"
        local marker=" "
        [[ "$slot" == "$(theme::schedule::slot_for)" ]] && marker="▸"
        if [[ -n "$theme_name" ]]; then
            printf '    %s%s %-8s%s %s%-14s%s %s%s%s\n' \
                "${ASH_ACCENT}" "$marker" "$slot" "${RST}" \
                "${ASH_MUTED}" "$(theme::schedule::boundary "$slot")" "${RST}" \
                "${BOLD}" "$theme_name" "${RST}"
            (( have++ )) || true
        else
            printf '    %s  %-8s %-14s —%s\n' \
                "${ASH_MUTED}" "$slot" "$(theme::schedule::boundary "$slot")" "${RST}"
        fi
    done

    if (( have == 0 )); then
        printf '\n  %sNothing scheduled yet.%s\n' "${ASH_MUTED}" "${RST}"
        printf '  %sTry:  ash theme schedule --set day=gruvbox-light --set night=nord%s\n' \
            "${ASH_MUTED}" "${RST}"
    fi
    printf '\n  %sApply the current slot: ash theme schedule --now%s\n\n' "${ASH_MUTED}" "${RST}"
}
