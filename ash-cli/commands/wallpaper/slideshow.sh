#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  wallpaper slideshow                                      ║
# ║  Auto-rotate wallpapers • systemd timer • order modes • category filter         ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WP_SLIDESHOW_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WP_SLIDESHOW_LOADED=1

set -euo pipefail

declare -gr _SS_PID_FILE="${_WP_STATE}/slideshow.pid"
declare -gr _SS_CONFIG_FILE="${_WP_STATE}/slideshow.conf"
declare -gr _SS_INDEX_FILE="${_WP_STATE}/slideshow.index"

_ss_is_running() {
    [[ -f "$_SS_PID_FILE" ]] || return 1
    local pid
    pid="$(cat "$_SS_PID_FILE" 2>/dev/null || echo '')"
    [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

_ss_stop() {
    if _ss_is_running; then
        local pid
        pid="$(cat "$_SS_PID_FILE")"
        kill "$pid" 2>/dev/null
        rm -f "$_SS_PID_FILE"
        wp_ok "Slideshow stopped  (PID: ${pid})"
    else
        wp_info "Slideshow not running"
    fi

    # Also stop systemd timer if active
    systemctl --user stop ash-wallpaper-slideshow.timer 2>/dev/null || true
}

_ss_next_index() {
    local order="$1"  total="$2"
    local current=0

    [[ -f "$_SS_INDEX_FILE" ]] && current="$(cat "$_SS_INDEX_FILE" 2>/dev/null || echo 0)"

    case "$order" in
        sequential)
            current=$(( (current + 1) % total ))
            ;;
        random|shuffle)
            current=$(( RANDOM % total ))
            ;;
        reverse)
            current=$(( (current - 1 + total) % total ))
            ;;
    esac

    printf '%d' "$current" > "$_SS_INDEX_FILE"
    printf '%d' "$current"
}

_ss_loop() {
    local interval="$1"  order="$2"  category="$3"

    wp_log_info() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$1" >> "${_WP_STATE}/slideshow.log" 2>/dev/null; }

    while true; do
        # Rebuild file list each iteration (handles new files)
        local -a files=()
        if [[ -n "$category" ]]; then
            mapfile -t files < <(
                find "$_WP_LIB_DIR" "$_WP_USER_DIR" \
                    -path "*/${category}/*" \
                    \( -name '*.jpg' -o -name '*.png' -o -name '*.webp' \) \
                    2>/dev/null | sort
            )
        else
            mapfile -t files < <(wp_find_all)
        fi

        [[ ${#files[@]} -eq 0 ]] && { sleep "$interval"; continue; }

        local idx
        idx="$(_ss_next_index "$order" "${#files[@]}")"
        local chosen="${files[$idx]}"

        [[ -f "$chosen" ]] && wp_set_backend "$chosen" &>/dev/null
        wp_log_info "Set: $(basename "$chosen")"

        sleep "$interval"
    done
}

ash_wp_slideshow() {
    local action="start"
    local interval=300      # seconds between changes
    local order="random"
    local category=""
    local use_systemd=0

    for arg in "${@:-}"; do
        case "$arg" in
            start)              action="start"              ;;
            stop|kill)          action="stop"               ;;
            status)             action="status"             ;;
            next)               action="next"               ;;
            --interval=*|-i=*)  interval="${arg#*=}"        ;;
            --order=*)          order="${arg#*=}"           ;;
            --category=*-c=*)   category="${arg#*=}"        ;;
            --systemd)          use_systemd=1               ;;
            [0-9]*)             interval="$arg"             ;;
        esac
    done

    wp_section "▶️ " "Wallpaper Slideshow" "$(_wgreen)"

    case "$action" in
        stop)
            _ss_stop
            printf '\n'
            return 0
            ;;

        status)
            if _ss_is_running; then
                local pid
                pid="$(cat "$_SS_PID_FILE")"
                wp_ok "Slideshow running  (PID: ${pid})"

                if [[ -f "$_SS_CONFIG_FILE" ]]; then
                    while IFS='=' read -r k v; do
                        wp_kv "$k" "$v"
                    done < "$_SS_CONFIG_FILE"
                fi
            else
                wp_info "Slideshow not running"
                wp_info "Start: ash wp slideshow start"
            fi
            printf '\n'
            return 0
            ;;

        next)
            if _ss_is_running; then
                # Signal the loop to advance
                local pid
                pid="$(cat "$_SS_PID_FILE")"
                kill -USR1 "$pid" 2>/dev/null && wp_ok "Advanced to next" || \
                    wp_fail "Could not signal slideshow"
            else
                # Just set a random one
                ash_wp_random
            fi
            printf '\n'
            return 0
            ;;

        start|*)
            if _ss_is_running; then
                wp_warn "Slideshow already running"
                wp_info "Stop first: ash wp slideshow stop"
                printf '\n'
                return 0
            fi

            local total
            total="$(wp_count_all)"

            wp_kv "Wallpapers"  "$total"
            wp_kv "Interval"    "${interval}s  ($(( interval / 60 ))m)"
            wp_kv "Order"       "$order"
            [[ -n "$category" ]] && wp_kv "Category" "$category"

            printf '\n'

            if (( total == 0 )); then
                wp_fail "No wallpapers found in library"
                return 1
            fi

            if [[ $use_systemd -eq 1 ]]; then
                # Create systemd user service + timer
                local service_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
                mkdir -p "$service_dir"

                cat > "${service_dir}/ash-wallpaper-slideshow.service" << EOF
[Unit]
Description=ASH Wallpaper Slideshow
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=${_WP_CMD_DIR}/../../ash wallpaper random \
    --transition=${WP_TRANSITION:-wipe} \
    ${category:+--category=$category}
EOF

                cat > "${service_dir}/ash-wallpaper-slideshow.timer" << EOF
[Unit]
Description=ASH Wallpaper Slideshow Timer

[Timer]
OnBootSec=30s
OnUnitActiveSec=${interval}s
Persistent=true

[Install]
WantedBy=timers.target
EOF

                systemctl --user daemon-reload
                systemctl --user enable --now ash-wallpaper-slideshow.timer
                wp_ok "Systemd timer created  (every ${interval}s)"
            else
                # Background loop process
                printf '{"interval":"%s","order":"%s","category":"%s","started":"%s"}\n' \
                    "$interval" "$order" "$category" "$(date -Iseconds)" \
                    > "$_SS_CONFIG_FILE"

                _ss_loop "$interval" "$order" "$category" &
                local loop_pid=$!
                printf '%d\n' "$loop_pid" > "$_SS_PID_FILE"

                wp_ok "Slideshow started  (PID: ${loop_pid})"
                wp_info "Stop: ash wp slideshow stop"
                wp_info "Next: ash wp slideshow next"
            fi
            ;;
    esac

    printf '\n'
}
