#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — DESKTOP ANALYTICS                             ║
# ║           Track and visualize desktop usage patterns                       ║
# ║           UNIQUE FEATURE: No other dotfiles system has this               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly ANALYTICS_DIR="${CACHE_DIR}/analytics"
readonly DB_FILE="${ANALYTICS_DIR}/desktop.db"
readonly LOG_FILE="${CACHE_DIR}/logs/analytics.log"
readonly PID_FILE="/tmp/ash-analytics.pid"

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🗄️ DATABASE SETUP
# ═══════════════════════════════════════════════════════════════════════════════

init_db() {
    if ! command -v sqlite3 &>/dev/null; then
        echo "sqlite3 required: paru -S sqlite"
        exit 1
    fi

    mkdir -p "${ANALYTICS_DIR}"

    sqlite3 "${DB_FILE}" << 'SQL'
CREATE TABLE IF NOT EXISTS app_usage (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT    NOT NULL,
    app_class TEXT    NOT NULL,
    app_title TEXT,
    workspace INTEGER,
    duration  INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS workspace_switches (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp   TEXT NOT NULL,
    from_ws     INTEGER,
    to_ws       INTEGER
);

CREATE TABLE IF NOT EXISTS theme_changes (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp   TEXT NOT NULL,
    wallpaper   TEXT,
    primary_color TEXT
);

CREATE TABLE IF NOT EXISTS screenshot_events (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp   TEXT NOT NULL,
    mode        TEXT,
    saved_to    TEXT
);

CREATE TABLE IF NOT EXISTS system_metrics (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp   TEXT NOT NULL,
    cpu_percent REAL,
    mem_percent REAL,
    uptime_secs INTEGER
);

CREATE INDEX IF NOT EXISTS idx_app_timestamp ON app_usage(timestamp);
CREATE INDEX IF NOT EXISTS idx_app_class ON app_usage(app_class);
SQL

    log "INFO" "Database initialized"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📝 LOGGING FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

log_app() {
    local app_class="${1:-}"
    local app_title="${2:-}"
    local workspace="${3:-0}"
    local duration="${4:-0}"

    [[ -z "${app_class}" ]] && return 0

    sqlite3 "${DB_FILE}" \
        "INSERT INTO app_usage (timestamp, app_class, app_title, workspace, duration)
         VALUES (datetime('now'), '${app_class//\'/\'\'}', '${app_title//\'/\'\'}', ${workspace}, ${duration});" \
        2>/dev/null || true
}

log_workspace_switch() {
    local from_ws="${1:-0}"
    local to_ws="${2:-0}"

    sqlite3 "${DB_FILE}" \
        "INSERT INTO workspace_switches (timestamp, from_ws, to_ws)
         VALUES (datetime('now'), ${from_ws}, ${to_ws});" \
        2>/dev/null || true
}

log_theme_change() {
    local wallpaper="${1:-}"
    local color="${2:-}"

    sqlite3 "${DB_FILE}" \
        "INSERT INTO theme_changes (timestamp, wallpaper, primary_color)
         VALUES (datetime('now'), '${wallpaper//\'/\'\'}', '${color}');" \
        2>/dev/null || true
}

log_system_metrics() {
    local cpu mem uptime_secs

    cpu=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | tr -d '%' || echo "0")
    mem=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf "%.1f",(t-a)*100/t}' \
        /proc/meminfo 2>/dev/null || echo "0")
    uptime_secs=$(awk '{printf "%.0f", $1}' /proc/uptime 2>/dev/null || echo "0")

    sqlite3 "${DB_FILE}" \
        "INSERT INTO system_metrics (timestamp, cpu_percent, mem_percent, uptime_secs)
         VALUES (datetime('now'), ${cpu}, ${mem}, ${uptime_secs});" \
        2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# 👁️ ACTIVITY MONITOR DAEMON
# ═══════════════════════════════════════════════════════════════════════════════

run_monitor() {
    echo $$ > "${PID_FILE}"
    log "INFO" "Analytics daemon started"

    local last_app="" last_ws="" last_app_start=$(date +%s)

    # Listen to Hyprland socket for events
    local socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

    if [[ -S "${socket}" ]]; then
        socat -u "UNIX-CONNECT:${socket}" - 2>/dev/null | \
        while IFS= read -r line; do
            case "${line}" in
                activewindow*)
                    # Window focus changed
                    local win_info
                    win_info=$(hyprctl activewindow -j 2>/dev/null || echo "{}")
                    local new_app new_title new_ws
                    new_app=$(echo "${win_info}" | jq -r '.class // ""')
                    new_title=$(echo "${win_info}" | jq -r '.title // ""' | head -c 80)
                    new_ws=$(echo "${win_info}" | jq -r '.workspace.id // 0')

                    if [[ "${new_app}" != "${last_app}" ]] && [[ -n "${last_app}" ]]; then
                        local duration=$(( $(date +%s) - last_app_start ))
                        log_app "${last_app}" "" "${last_ws:-0}" "${duration}"
                        last_app_start=$(date +%s)
                    fi

                    last_app="${new_app}"
                    last_ws="${new_ws}"
                    ;;

                workspace*)
                    # Workspace switched
                    local new_ws="${line##workspace>>}"
                    log_workspace_switch "${last_ws:-0}" "${new_ws}"
                    last_ws="${new_ws}"
                    ;;
            esac
        done &
    fi

    # System metrics every 5 minutes
    while true; do
        log_system_metrics
        sleep 300
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 ANALYTICS DASHBOARD
# ═══════════════════════════════════════════════════════════════════════════════

show_dashboard() {
    local days="${1:-30}"

    clear
    echo ""
    echo -e "  \033[1m\033[95m╔═══════════════════════════════════════════════════════╗\033[0m"
    echo -e "  \033[1m\033[95m║\033[0m      \033[1m📊 ASH DESKTOP ANALYTICS — Last ${days} Days\033[0m        \033[1m\033[95m║\033[0m"
    echo -e "  \033[1m\033[95m╚═══════════════════════════════════════════════════════╝\033[0m"
    echo ""

    # Most used apps
    echo -e "  \033[1m\033[96m🏆 Most Used Applications:\033[0m"
    sqlite3 "${DB_FILE}" << SQL 2>/dev/null || echo "  No data yet"
SELECT
    printf("  %-20s  %d sessions  %s",
        app_class,
        COUNT(*),
        CASE
            WHEN SUM(duration) > 3600 THEN printf("%.1fh", CAST(SUM(duration) AS REAL)/3600)
            WHEN SUM(duration) > 60 THEN printf("%.0fm", CAST(SUM(duration) AS REAL)/60)
            ELSE printf("%ds", SUM(duration))
        END
    ) as info
FROM app_usage
WHERE timestamp > datetime('now', '-${days} days')
GROUP BY app_class
ORDER BY COUNT(*) DESC
LIMIT 8;
SQL

    echo ""

    # Workspace usage
    echo -e "  \033[1m\033[96m🗂️  Workspace Usage:\033[0m"
    sqlite3 "${DB_FILE}" << SQL 2>/dev/null || echo "  No data yet"
SELECT
    printf("  Workspace %-3d  %d times  %.0f%%",
        workspace,
        COUNT(*),
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM app_usage WHERE timestamp > datetime('now', '-${days} days'))
    )
FROM app_usage
WHERE timestamp > datetime('now', '-${days} days')
  AND workspace > 0
GROUP BY workspace
ORDER BY COUNT(*) DESC
LIMIT 5;
SQL

    echo ""

    # System averages
    echo -e "  \033[1m\033[96m💻 System Averages (Last 7 Days):\033[0m"
    sqlite3 "${DB_FILE}" << SQL 2>/dev/null || echo "  No data yet"
SELECT
    printf("  CPU: %.1f%%  RAM: %.1f%%",
        AVG(cpu_percent),
        AVG(mem_percent)
    )
FROM system_metrics
WHERE timestamp > datetime('now', '-7 days');
SQL

    echo ""

    # Theme changes
    echo -e "  \033[1m\033[96m🎨 Theme Activity:\033[0m"
    local theme_count
    theme_count=$(sqlite3 "${DB_FILE}" \
        "SELECT COUNT(*) FROM theme_changes WHERE timestamp > datetime('now', '-${days} days');" \
        2>/dev/null || echo "0")
    echo "  Themes applied: ${theme_count} times"

    # Total sessions
    local total_sessions
    total_sessions=$(sqlite3 "${DB_FILE}" \
        "SELECT COUNT(*) FROM app_usage WHERE timestamp > datetime('now', '-${days} days');" \
        2>/dev/null || echo "0")
    echo "  App sessions: ${total_sessions}"

    # Workspace switches
    local ws_switches
    ws_switches=$(sqlite3 "${DB_FILE}" \
        "SELECT COUNT(*) FROM workspace_switches WHERE timestamp > datetime('now', '-${days} days');" \
        2>/dev/null || echo "0")
    echo "  Workspace switches: ${ws_switches}"

    echo ""

    # Recommendations
    echo -e "  \033[1m\033[96m💡 Recommendations:\033[0m"

    # Check if any workspace is barely used
    local unused_ws
    unused_ws=$(sqlite3 "${DB_FILE}" \
        "SELECT workspace FROM app_usage WHERE timestamp > datetime('now', '-${days} days') GROUP BY workspace HAVING COUNT(*) < 5 ORDER BY COUNT(*);" \
        2>/dev/null || echo "")

    if [[ -n "${unused_ws}" ]]; then
        echo "  • Workspace ${unused_ws} rarely used — consider removing it"
    fi

    echo ""
    echo -e "  \033[2mExport data: ash analytics export\033[0m"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📤 EXPORT
# ═══════════════════════════════════════════════════════════════════════════════

export_data() {
    local format="${1:-json}"
    local output="${2:-${HOME}/ash-analytics-$(date +%Y%m%d).${format}}"

    case "${format}" in
        json)
            sqlite3 -json "${DB_FILE}" \
                "SELECT * FROM app_usage ORDER BY timestamp DESC LIMIT 1000;" \
                > "${output}" 2>/dev/null
            ok "Exported to: ${output}"
            ;;
        csv)
            sqlite3 -csv -header "${DB_FILE}" \
                "SELECT * FROM app_usage ORDER BY timestamp DESC LIMIT 1000;" \
                > "${output}" 2>/dev/null
            ok "Exported to: ${output}"
            ;;
        *)
            echo "Formats: json, csv"
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-show}"
    shift || true

    mkdir -p "${ANALYTICS_DIR}" "${CACHE_DIR}/logs"
    init_db

    case "${action}" in
        show | dashboard | "")  show_dashboard "${1:-30}" ;;
        start | enable)
            [[ -f "${PID_FILE}" ]] && kill -0 "$(cat "${PID_FILE}")" 2>/dev/null \
                && { info "Already running"; return 0; }
            run_monitor &>/dev/null & disown
            sleep 0.3
            ok "Analytics daemon started"
            ;;
        stop | disable)
            [[ -f "${PID_FILE}" ]] && {
                kill "$(cat "${PID_FILE}")" 2>/dev/null || true
                rm -f "${PID_FILE}"
                ok "Analytics daemon stopped"
            } || info "Not running"
            ;;
        log-app)        log_app "$@" ;;
        log-ws)         log_workspace_switch "$@" ;;
        log-theme)      log_theme_change "$@" ;;
        export)         export_data "${1:-json}" "${2:-}" ;;
        reset)
            read -rp "  Delete all analytics data? [y/N]: " confirm
            [[ "${confirm,,}" == "y" ]] && {
                rm -f "${DB_FILE}"
                init_db
                ok "Analytics reset"
            }
            ;;
        status)
            [[ -f "${PID_FILE}" ]] && kill -0 "$(cat "${PID_FILE}")" 2>/dev/null \
                && echo "  ● Analytics: ACTIVE" \
                || echo "  ○ Analytics: inactive"
            ;;
        *)
            echo "Usage: desktop-analytics.sh [show|start|stop|export|reset|status]"
            exit 1
            ;;
    esac
}

main "$@"