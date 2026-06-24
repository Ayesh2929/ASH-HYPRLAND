#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Waybar Script: Pomodoro Timer                    ║
# ║                                                                              ║
# ║  Full Pomodoro timer with work/break cycles, session counting and           ║
# ║  desktop notifications.                                                      ║
# ║                                                                              ║
# ║  Usage:                                                                      ║
# ║    pomodoro.sh --status   — get Waybar JSON output                          ║
# ║    pomodoro.sh --toggle   — start or pause timer                            ║
# ║    pomodoro.sh --reset    — reset current session                           ║
# ║    pomodoro.sh --skip     — skip to next phase                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────────
readonly WORK_MINS=25
readonly SHORT_BREAK_MINS=5
readonly LONG_BREAK_MINS=15
readonly SESSIONS_BEFORE_LONG=4

# ── State directory ────────────────────────────────────────────────────────────
readonly STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/ash-pomodoro"
readonly STATE_FILE="${STATE_DIR}/state"
readonly PID_FILE="${STATE_DIR}/timer.pid"
readonly SESSION_FILE="${STATE_DIR}/session-count"

mkdir -p "$STATE_DIR"

# ── State helpers ──────────────────────────────────────────────────────────────
get_state()   { cat "${STATE_FILE}"    2>/dev/null || echo "idle"; }
get_sessions(){ cat "${SESSION_FILE}"  2>/dev/null || echo "0"; }
get_end_time(){ cat "${STATE_DIR}/end" 2>/dev/null || echo "0"; }

set_state() {
    echo "$1" > "$STATE_FILE"
    echo "$2" > "${STATE_DIR}/end"
}

# ── Timer background process ───────────────────────────────────────────────────
start_timer() {
    local phase="$1"
    local secs="$2"
    local next_phase="$3"

    # Kill existing timer
    if [[ -f "$PID_FILE" ]]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null || true
        rm -f "$PID_FILE"
    fi

    local end_time=$(( $(date +%s) + secs ))
    set_state "$phase" "$end_time"

    # Background timer
    (
        sleep "$secs"
        # Phase complete notification
        case "$phase" in
            work)
                SESSIONS=$(( $(get_sessions) + 1 ))
                echo "$SESSIONS" > "$SESSION_FILE"
                notify-send "🍅 Pomodoro Complete!" \
                    "Session ${SESSIONS} done! Time for a break." \
                    --urgency=normal --expire-time=10000
                # Next phase: short or long break
                if (( SESSIONS % SESSIONS_BEFORE_LONG == 0 )); then
                    start_timer "long-break" $(( LONG_BREAK_MINS * 60 )) "work"
                else
                    start_timer "short-break" $(( SHORT_BREAK_MINS * 60 )) "work"
                fi
                ;;
            short-break|long-break)
                notify-send "🍅 Break Over!" \
                    "Back to work! Start next session." \
                    --urgency=normal --expire-time=10000
                set_state "idle" "0"
                ;;
        esac
        pkill -SIGUSR1 waybar 2>/dev/null || true
    ) &
    echo $! > "$PID_FILE"
}

# ── Status output ──────────────────────────────────────────────────────────────
status_output() {
    local STATE END_TIME NOW REMAINING SESSIONS
    STATE=$(get_state)
    END_TIME=$(get_end_time)
    NOW=$(date +%s)
    SESSIONS=$(get_sessions)

    case "$STATE" in
        work)
            REMAINING=$(( END_TIME - NOW ))
            [[ $REMAINING -lt 0 ]] && REMAINING=0
            ICON="🍅"
            COLOR="#f38ba8"
            LABEL="Focus"
            ;;
        short-break)
            REMAINING=$(( END_TIME - NOW ))
            [[ $REMAINING -lt 0 ]] && REMAINING=0
            ICON="☕"
            COLOR="#a6e3a1"
            LABEL="Break"
            ;;
        long-break)
            REMAINING=$(( END_TIME - NOW ))
            [[ $REMAINING -lt 0 ]] && REMAINING=0
            ICON="🌴"
            COLOR="#89dceb"
            LABEL="Long Break"
            ;;
        idle)
            REMAINING=0
            ICON="⏸"
            COLOR="#6c7086"
            LABEL="Idle"
            ;;
        *)
            echo '{}'
            return 0
            ;;
    esac

    local MINS=$(( REMAINING / 60 ))
    local SECS=$(( REMAINING % 60 ))
    local TIME_FMT
    TIME_FMT=$(printf "%02d:%02d" $MINS $SECS)

    local TEXT
    if [[ "$STATE" == "idle" ]]; then
        TEXT="<span color='${COLOR}'>${ICON}</span>"
    else
        TEXT="<span color='${COLOR}'>${ICON} ${TIME_FMT}</span>"
    fi

    local TOOLTIP="${ICON} Pomodoro Timer\n\n"
    TOOLTIP+="State:    ${LABEL}\n"
    [[ "$STATE" != "idle" ]] && TOOLTIP+="Remaining: ${TIME_FMT}\n"
    TOOLTIP+="Sessions: ${SESSIONS}/${SESSIONS_BEFORE_LONG}\n\n"
    TOOLTIP+="Left:   start/pause\n"
    TOOLTIP+="Right:  reset\n"
    TOOLTIP+="Middle: skip phase"

    TEXT=$(echo "$TEXT" | sed 's/"/\\"/g')
    TOOLTIP=$(echo "$TOOLTIP" | sed 's/\\/\\\\/g; s/"/\\"/g')

    printf '{"text":"%s","tooltip":"%s","class":"%s","percentage":%d}\n' \
        "$TEXT" "$TOOLTIP" "$STATE" \
        "$(( REMAINING > 0 && STATE == work ? REMAINING * 100 / (WORK_MINS * 60) : 0 ))"
}

# ── Controls ───────────────────────────────────────────────────────────────────
toggle() {
    local STATE
    STATE=$(get_state)
    case "$STATE" in
        idle)
            start_timer "work" $(( WORK_MINS * 60 )) "short-break"
            notify-send "🍅 Pomodoro Started!" \
                "${WORK_MINS} minute focus session" \
                --urgency=low --expire-time=3000
            ;;
        work|short-break|long-break)
            # Pause: kill timer, save remaining
            if [[ -f "$PID_FILE" ]]; then
                kill "$(cat "$PID_FILE")" 2>/dev/null || true
                rm -f "$PID_FILE"
            fi
            set_state "idle" "0"
            notify-send "🍅 Pomodoro Paused" "" --urgency=low --expire-time=2000
            ;;
    esac
    pkill -SIGUSR1 waybar 2>/dev/null || true
}

reset_timer() {
    [[ -f "$PID_FILE" ]] && kill "$(cat "$PID_FILE")" 2>/dev/null || true
    rm -f "$PID_FILE" "$STATE_FILE" "${STATE_DIR}/end"
    echo "0" > "$SESSION_FILE"
    pkill -SIGUSR1 waybar 2>/dev/null || true
}

skip_phase() {
    local STATE
    STATE=$(get_state)
    [[ -f "$PID_FILE" ]] && kill "$(cat "$PID_FILE")" 2>/dev/null || true
    rm -f "$PID_FILE"

    case "$STATE" in
        work)        start_timer "short-break" $(( SHORT_BREAK_MINS * 60 )) "work" ;;
        short-break) start_timer "work"        $(( WORK_MINS       * 60 )) "short-break" ;;
        long-break)  start_timer "work"        $(( WORK_MINS       * 60 )) "short-break" ;;
        *)           start_timer "work"        $(( WORK_MINS       * 60 )) "short-break" ;;
    esac
    pkill -SIGUSR1 waybar 2>/dev/null || true
}

# ── Main ───────────────────────────────────────────────────────────────────────
case "${1:---status}" in
    --status)   status_output ;;
    --toggle)   toggle        ;;
    --reset)    reset_timer   ;;
    --skip)     skip_phase    ;;
    *)          status_output ;;
esac