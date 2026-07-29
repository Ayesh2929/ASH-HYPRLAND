#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Process Killer / Task Manager Script              ║
# ║                                                                              ║
# ║  Full process management via Rofi. Lists processes sorted by resource      ║
# ║  usage, sends signals, renices, shows strace and manages process groups.    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# §01  CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

readonly STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/ash-processkiller"
readonly SORT_FILE="${STATE_DIR}/sort"
readonly USER_FILTER_FILE="${STATE_DIR}/user-filter"
readonly MAX_PROCS=80
readonly CPU_HIGH_THRESHOLD=10    # % CPU for high-CPU highlight
readonly MEM_HIGH_THRESHOLD=500   # MB for high-mem highlight

# ══════════════════════════════════════════════════════════════════════════════
# §02  STATE MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

setup_state() {
    mkdir -p "$STATE_DIR"
    [[ ! -f "$SORT_FILE" ]] && echo "cpu" > "$SORT_FILE"
    [[ ! -f "$USER_FILTER_FILE" ]] && echo "mine" > "$USER_FILTER_FILE"
}

get_sort()        { cat "$SORT_FILE"        2>/dev/null || echo "cpu"; }
get_user_filter() { cat "$USER_FILTER_FILE" 2>/dev/null || echo "mine"; }

cycle_sort() {
    local current
    current=$(get_sort)
    case "$current" in
        cpu)    echo "mem"  > "$SORT_FILE" ;;
        mem)    echo "pid"  > "$SORT_FILE" ;;
        pid)    echo "name" > "$SORT_FILE" ;;
        name)   echo "cpu"  > "$SORT_FILE" ;;
        *)      echo "cpu"  > "$SORT_FILE" ;;
    esac
}

toggle_user_filter() {
    local current
    current=$(get_user_filter)
    if [[ "$current" == "mine" ]]; then
        echo "all" > "$USER_FILTER_FILE"
    else
        echo "mine" > "$USER_FILTER_FILE"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  PROCESS TYPE → ICON
# ══════════════════════════════════════════════════════════════════════════════

get_process_icon() {
    local name="${1,,}" cmd="${2,,}"
    local combined="${name} ${cmd}"

    if   [[ "$combined" =~ firefox|chromium|brave|chrome|vivaldi ]]; then echo "󰖟"
    elif [[ "$combined" =~ kitty|foot|alacritty|wezterm|xterm|urxvt|gnome-terminal ]]; then echo "󰆍"
    elif [[ "$combined" =~ nvim|vim|helix|emacs|code|zed|sublime ]]; then echo "󰅩"
    elif [[ "$combined" =~ steam|wine|lutris|gamescope|proton ]]; then echo "󰊗"
    elif [[ "$combined" =~ discord|vesktop|slack|teams|zoom|signal ]]; then echo "󰙯"
    elif [[ "$combined" =~ spotify|mpv|vlc|rhythmbox|cmus|ncmpcpp ]]; then echo "󰝚"
    elif [[ "$combined" =~ docker|containerd|podman|crio ]]; then echo "󰡨"
    elif [[ "$combined" =~ Xwayland|weston|sway|hyprland|kwin|mutter ]]; then echo "󰕙"
    elif [[ "$combined" =~ python|node|ruby|java|perl|php|lua ]]; then echo "󰅩"
    elif [[ "$combined" =~ postgres|mysql|redis|mongodb|sqlite ]]; then echo "󰆼"
    elif [[ "$combined" =~ nginx|apache|caddy|traefik ]]; then echo "󰖟"
    elif [[ "$combined" =~ systemd|dbus|pulseaudio|pipewire|udev ]]; then echo "󰻁"
    elif [[ "$combined" =~ thunar|nautilus|dolphin|nemo ]]; then echo "󱁉"
    elif [[ "$combined" =~ gimp|inkscape|krita|blender|darktable ]]; then echo "󰋩"
    elif [[ "$combined" =~ ssh|sshd|rsync|sftp ]]; then echo "󰢹"
    else echo "󰻁"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  SYSTEM RESOURCE STATS
# ══════════════════════════════════════════════════════════════════════════════

get_cpu_usage() {
    # Read /proc/stat for overall CPU
    local cpu_line
    cpu_line=$(head -1 /proc/stat)
    local user nice system idle iowait irq softirq
    read -r _ user nice system idle iowait irq softirq _ <<< "$cpu_line"

    local total=$(( user + nice + system + idle + iowait + irq + softirq ))
    local idle_total=$(( idle + iowait ))

    # Wait briefly and read again
    sleep 0.3

    local cpu_line2
    cpu_line2=$(head -1 /proc/stat)
    read -r _ user2 nice2 system2 idle2 iowait2 irq2 softirq2 _ <<< "$cpu_line2"

    local total2=$(( user2 + nice2 + system2 + idle2 + iowait2 + irq2 + softirq2 ))
    local idle2_total=$(( idle2 + iowait2 ))

    local delta_total=$(( total2 - total ))
    local delta_idle=$(( idle2_total - idle_total ))

    if [[ $delta_total -gt 0 ]]; then
        echo $(( (delta_total - delta_idle) * 100 / delta_total ))
    else
        echo 0
    fi
}

get_ram_info() {
    local total free buffers cached available
    while IFS=': ' read -r key value unit; do
        case "$key" in
            MemTotal)     total="$value" ;;
            MemAvailable) available="$value" ;;
        esac
    done < /proc/meminfo

    local used=$(( (total - available) / 1024 ))
    local total_mb=$(( total / 1024 ))
    echo "${used}MB/${total_mb}MB"
}

get_load_average() {
    read -r l1 l5 l15 _ < /proc/loadavg
    echo "$l1"
}

get_uptime_str() {
    local up
    up=$(cat /proc/uptime | awk '{print int($1)}')
    local hours=$(( up / 3600 ))
    local mins=$(( (up % 3600) / 60 ))
    printf "%dh%02dm" "$hours" "$mins"
}

get_task_count() {
    find /proc -maxdepth 1 -name '[0-9]*' -type d 2>/dev/null | wc -l
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  PROCESS LISTING VIA /proc
# ══════════════════════════════════════════════════════════════════════════════

format_mem_mb() {
    local kb="${1:-0}"
    local mb=$(( kb / 1024 ))
    if   (( mb >= 1024 )); then printf "%.1fG" "$(echo "scale=1; $mb/1024" | bc 2>/dev/null || echo 0)"
    else printf "%dMB" "$mb"
    fi
}

format_runtime() {
    local seconds="${1:-0}"
    local h=$(( seconds / 3600 ))
    local m=$(( (seconds % 3600) / 60 ))
    printf "%dh%02dm" "$h" "$m"
}

get_processes() {
    local sort_by
    sort_by=$(get_sort)
    local user_filter
    user_filter=$(get_user_filter)
    local my_uid
    my_uid=$(id -u)

    # Use ps for reliable process listing
    local ps_args=(-eo "pid,ppid,user,pcpu,pmem,rss,etime,comm,cmd")
    local sort_key

    case "$sort_by" in
        cpu)    sort_key="-k4 -rn" ;;
        mem)    sort_key="-k6 -rn" ;;
        pid)    sort_key="-k1 -n"  ;;
        name)   sort_key="-k8"     ;;
        *)      sort_key="-k4 -rn" ;;
    esac

    # Get all processes, then sort
    ps "${ps_args[@]}" --no-headers 2>/dev/null | \
        sort $sort_key | \
        head -"$MAX_PROCS" | \
        while read -r pid ppid user cpu mem rss etime comm cmd_rest; do
            # User filter
            if [[ "$user_filter" == "mine" ]]; then
                local proc_uid
                proc_uid=$(stat -c %u "/proc/${pid}" 2>/dev/null || echo 999)
                [[ "$proc_uid" != "$my_uid" ]] && continue
            fi

            # Skip kernel threads
            if [[ -z "$(cat /proc/${pid}/cmdline 2>/dev/null)" ]]; then
                local stat_flags
                stat_flags=$(awk '{print $9}' /proc/${pid}/stat 2>/dev/null || echo "")
                [[ "$stat_flags" =~ [KI] ]] && continue
            fi

            echo "${pid}|${user}|${cpu}|${mem}|${rss}|${etime}|${comm}|${cmd_rest}"
        done
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  SIGNAL ACTIONS
# ══════════════════════════════════════════════════════════════════════════════

send_signal() {
    local pid="$1" sig="${2:-TERM}" name="${3:-process}"

    if [[ ! -d "/proc/$pid" ]]; then
        notify_pk "Process gone" "$name (PID $pid) no longer exists" "normal"
        return 1
    fi

    if kill -"$sig" "$pid" 2>/dev/null; then
        local sig_desc
        case "$sig" in
            TERM|15) sig_desc="graceful termination" ;;
            KILL|9)  sig_desc="force killed" ;;
            STOP|19) sig_desc="frozen (SIGSTOP)" ;;
            CONT|18) sig_desc="resumed (SIGCONT)" ;;
            HUP|1)   sig_desc="hangup (config reload)" ;;
            USR1|10) sig_desc="user signal 1" ;;
            USR2|12) sig_desc="user signal 2" ;;
            *)        sig_desc="signal $sig" ;;
        esac
        notify_pk "SIG${sig}: $name" "$sig_desc (PID: $pid)" "low"
        return 0
    else
        # Try with sudo
        if sudo -n kill -"$sig" "$pid" 2>/dev/null; then
            notify_pk "SIG${sig}: $name" "(elevated) PID: $pid" "low"
            return 0
        fi
        notify_pk "Kill failed" "Permission denied: $name (PID $pid)" "critical"
        return 1
    fi
}

renice_process() {
    local pid="$1" name="${2:-process}"
    local current_nice
    current_nice=$(cat /proc/${pid}/stat 2>/dev/null | awk '{print $19}' || echo "0")

    local new_nice
    new_nice=$(rofi -dmenu \
        -p "Renice: $name (PID $pid)" \
        -filter "$current_nice" \
        -mesg "Current nice: <b>$current_nice</b>\nRange: -20 (highest priority) to 19 (lowest)\nNegative values require sudo" \
        -theme-str "window { width: 400px; } listview { lines: 0; }" \
        2>/dev/null || echo "")

    [[ -z "$new_nice" ]] && return

    if [[ "$new_nice" -lt 0 ]]; then
        sudo -n renice "$new_nice" -p "$pid" 2>/dev/null && \
            notify_pk "Renice: $name" "nice = $new_nice (elevated)" "low"
    else
        renice "$new_nice" -p "$pid" 2>/dev/null && \
            notify_pk "Renice: $name" "nice = $new_nice" "low"
    fi
}

show_process_info() {
    local pid="$1" name="${2:-}"

    [[ ! -d "/proc/$pid" ]] && {
        notify_pk "Process gone" "PID $pid no longer exists" "normal"
        return
    }

    local cmdline
    cmdline=$(cat /proc/${pid}/cmdline 2>/dev/null | tr '\0' ' ' | head -c 100 || echo "N/A")
    local status
    status=$(grep "^State:" /proc/${pid}/status 2>/dev/null | awk '{print $2, $3}' || echo "?")
    local threads
    threads=$(grep "^Threads:" /proc/${pid}/status 2>/dev/null | awk '{print $2}' || echo "?")
    local fd_count
    fd_count=$(ls /proc/${pid}/fd 2>/dev/null | wc -l || echo "?")
    local mem_rss
    mem_rss=$(grep "^VmRSS:" /proc/${pid}/status 2>/dev/null | awk '{print $2}' || echo "0")
    mem_rss=$(format_mem_mb "$mem_rss")
    local parent_pid
    parent_pid=$(grep "^PPid:" /proc/${pid}/status 2>/dev/null | awk '{print $2}' || echo "?")

    local info
    info="PID: $pid\nPPID: $parent_pid\nName: ${name:-?}\nStatus: $status\nThreads: $threads\nFDs: $fd_count\nMem: $mem_rss\nCmd: ${cmdline:0:80}"

    notify_pk "󰻁 Process Info" "$info" "low"
}

kill_all_by_name() {
    local name="$1"
    local count
    count=$(pgrep -x "$name" 2>/dev/null | wc -l || echo 0)

    if [[ "$count" -eq 0 ]]; then
        notify_pk "Not found" "No process named: $name" "normal"
        return
    fi

    local confirm
    confirm=$(printf "Yes, kill all %d\nNo, cancel" "$count" | \
        rofi -dmenu \
            -p "Kill all: $name?" \
            -mesg "<b>$count</b> instances of <b>$name</b> will be terminated" \
            -theme-str "window { width: 350px; } listview { lines: 2; }
                element selected.normal { background-color: #f38ba8; text-color: #1e1e2e; }" \
            2>/dev/null || echo "No, cancel")

    if [[ "$confirm" =~ ^Yes ]]; then
        pkill -TERM -x "$name" 2>/dev/null || true
        notify_pk "󰩹 Killed all" "$count × $name" "normal"
    fi
}

strace_process() {
    local pid="$1" name="${2:-process}"

    if ! command -v strace &>/dev/null; then
        notify_pk "strace not found" "paru -S strace" "normal"
        return
    fi

    kitty \
        --class strace-viewer \
        --title "strace: $name (PID $pid)" \
        -e bash -c "sudo strace -p $pid -s 200 2>&1; \
            echo; echo 'strace ended. Press Enter.'; read" \
        &>/dev/null & disown
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  CONTEXT MENU
# ══════════════════════════════════════════════════════════════════════════════

show_process_menu() {
    local pid="$1" name="$2" user="$3" cpu="$4" mem_mb="$5"

    local is_mine=false
    [[ "$user" == "$USER" ]] && is_mine=true

    local entries=(
        "💀  Kill (SIGTERM) — graceful"
        "⚡  Force Kill (SIGKILL) — immediate"
        "⏸  Freeze (SIGSTOP)"
        "▶  Resume (SIGCONT)"
        "🔄  Restart (SIGHUP)"
        "━━━━━━━━━━━━━━━━━━━━━━━━"
        "󰆹  Renice (priority change)"
        "󰋩  Process Info"
        "󰆿  Copy PID"
        "󰻁  Kill all: $name"
        "━━━━━━━━━━━━━━━━━━━━━━━━"
        "  strace attach"
        "  Open btop"
        "━━━━━━━━━━━━━━━━━━━━━━━━"
        "✖  Cancel"
    )

    local icon
    icon=$(get_process_icon "$name" "")

    local choice
    choice=$(printf '%s\n' "${entries[@]}" | \
        rofi -dmenu \
            -p "${icon} ${name} [${pid}]" \
            -mesg "User: <b>$user</b>  CPU: <b>${cpu}%</b>  RAM: <b>${mem_mb}</b>" \
            -theme-str "
                window { width: 360px; height: 0px; }
                listview { lines: 15; columns: 1; }
                element { padding: 7px 16px; border-radius: 8px; }
                element selected.normal {
                    background-color: #f38ba8;
                    text-color: #1e1e2e;
                }
            " \
            2>/dev/null || echo "✖  Cancel")

    case "$choice" in
        "💀  Kill"*)         send_signal   "$pid" "TERM" "$name" ;;
        "⚡  Force Kill"*)   send_signal   "$pid" "KILL" "$name" ;;
        "⏸  Freeze"*)       send_signal   "$pid" "STOP" "$name" ;;
        "▶  Resume"*)        send_signal   "$pid" "CONT" "$name" ;;
        "🔄  Restart"*)      send_signal   "$pid" "HUP"  "$name" ;;
        "󰆹  Renice"*)        renice_process "$pid" "$name" ;;
        "󰋩  Process Info")   show_process_info "$pid" "$name" ;;
        "󰆿  Copy PID")
            echo -n "$pid" | wl-copy 2>/dev/null && \
                notify_pk "Copied" "PID: $pid" "low"
            ;;
        "󰻁  Kill all:"*)    kill_all_by_name "$name" ;;
        "  strace attach")  strace_process  "$pid" "$name" ;;
        "  Open btop")
            kitty --class monitoring -e btop &>/dev/null & disown
            ;;
        *) ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §08  NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════════════════

notify_pk() {
    local title="$1" msg="${2:-}" urgency="${3:-low}"
    notify-send \
        "$title" "$msg" \
        --app-name="ASH Process Killer" \
        --icon=utilities-system-monitor \
        --urgency="$urgency" \
        --expire-time=3000 \
        --hint=string:x-dunst-stack-tag:process-killer \
        2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §09  MENU ENTRY BUILDERS
# ══════════════════════════════════════════════════════════════════════════════

build_process_entries() {
    local sort_by
    sort_by=$(get_sort)
    local user_filter
    user_filter=$(get_user_filter)

    local sort_indicator
    case "$sort_by" in
        cpu)    sort_indicator="󰊚 CPU%" ;;
        mem)    sort_indicator="󰍛 RAM%" ;;
        pid)    sort_indicator="󰬷 PID" ;;
        name)   sort_indicator="󰂷 Name" ;;
    esac

    local filter_indicator
    [[ "$user_filter" == "mine" ]] && filter_indicator="My procs" || filter_indicator="All procs"

    printf '─── PROCESSES [%s · %s] ─────────────\0nonselectable\x1ftrue\n' \
        "$sort_indicator" "$filter_indicator"

    local count=0

    # Column header
    printf '  %-14s  %5s  %5s  %5s  %-8s  %s\0nonselectable\x1ftrue\n' \
        "NAME" "PID" "CPU%" "MEM" "USER" "RUNTIME"

    while IFS='|' read -r pid user cpu mem rss etime name cmd; do
        [[ -z "$pid" ]] && continue

        local icon
        icon=$(get_process_icon "$name" "$cmd")

        # Format values
        local mem_mb
        mem_mb=$(format_mem_mb "$rss")
        local cpu_fmt
        cpu_fmt=$(printf "%.1f" "$cpu" 2>/dev/null || echo "0.0")
        local runtime
        runtime=$(echo "$etime" | sed 's/-/:/' | head -c 8)

        # CPU/MEM bar
        local cpu_bar=""
        local cpu_int
        cpu_int=$(printf "%.0f" "$cpu" 2>/dev/null || echo 0)
        if (( cpu_int >= 20 )); then cpu_bar=" ████"
        elif (( cpu_int >= 10 )); then cpu_bar=" ██░░"
        elif (( cpu_int >= 5  )); then cpu_bar=" █░░░"
        fi

        local display
        display=$(printf '%s  %-14s  %5s  %5s%%  %6s  %-8s  %s%s' \
            "$icon" \
            "${name:0:12}" \
            "$pid" \
            "$cpu_fmt" \
            "$mem_mb" \
            "${user:0:7}" \
            "$runtime" \
            "$cpu_bar")

        printf '%s\0info\x1fprocess\x1fmeta\x1f%s|%s|%s|%s|%s\n' \
            "$display" \
            "$pid" "$name" "$user" "$cpu_fmt" "$mem_mb"

        (( count++ )) || true

    done < <(get_processes 2>/dev/null || true)

    if [[ $count -eq 0 ]]; then
        printf '  No processes found\0nonselectable\x1ftrue\n'
    fi

    # Footer actions
    printf '─────────────────────────────────────────\0nonselectable\x1ftrue\n'
    printf '󰻁  Open btop (system monitor)\0info\x1fopen-btop\n'
    printf '  Open htop\0info\x1fopen-htop\n'
    printf '🧹  Kill zombies (defunct processes)\0info\x1fkill-zombies\n'
    printf '  Memory analysis\0info\x1fmem-analysis\n'
}

# ══════════════════════════════════════════════════════════════════════════════
# §10  ACTION DISPATCHER
# ══════════════════════════════════════════════════════════════════════════════

dispatch_action() {
    local action="$1"
    local meta="${2:-}"

    case "$action" in
        process)
            IFS='|' read -r pid name user cpu mem <<< "$meta"
            [[ -n "$pid" ]] && show_process_menu "$pid" "$name" "$user" "$cpu" "$mem"
            ;;
        open-btop)
            kitty --class monitoring -e btop &>/dev/null & disown
            ;;
        open-htop)
            kitty --class monitoring -e htop &>/dev/null & disown
            ;;
        kill-zombies)
            local zombies
            zombies=$(ps aux 2>/dev/null | awk '$8 == "Z" {print $2}' | head -10)
            if [[ -n "$zombies" ]]; then
                echo "$zombies" | xargs -I{} sh -c 'kill -SIGCHLD "$(ps -o ppid= -p "$1" 2>/dev/null)" 2>/dev/null || true' -- {}
                notify_pk "🧹 Zombie cleanup" "Attempted to reap $(echo "$zombies" | wc -l) zombies" "low"
            else
                notify_pk "✓ No zombies" "No defunct processes found" "low"
            fi
            ;;
        mem-analysis)
            local analysis
            analysis=$(ps aux --sort=-%mem 2>/dev/null | \
                awk 'NR>1 {sum += $6} NR>1 && NR<=6 {printf "%s: %.1fMB\n", $11, $6/1024}
                     END {printf "\nTotal RSS: %.1fMB", sum/1024}' | \
                head -10 || echo "Analysis failed")
            notify_pk "󰍛 Top memory consumers" "$analysis" "low"
            ;;
        sort-cpu)   echo "cpu"  > "$SORT_FILE" ;;
        sort-mem)   echo "mem"  > "$SORT_FILE" ;;
        sort-pid)   echo "pid"  > "$SORT_FILE" ;;
        sort-name)  echo "name" > "$SORT_FILE" ;;
        toggle-user) toggle_user_filter ;;
        none|"")    return 0 ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §11  DIRECT CLI INVOCATION
# ══════════════════════════════════════════════════════════════════════════════

handle_direct_args() {
    case "${1:-}" in
        --kill)     [[ -n "${2:-}" ]] && send_signal "$2" "TERM" "process" ;;
        --force)    [[ -n "${2:-}" ]] && send_signal "$2" "KILL" "process" ;;
        --stop)     [[ -n "${2:-}" ]] && send_signal "$2" "STOP" "process" ;;
        --cont)     [[ -n "${2:-}" ]] && send_signal "$2" "CONT" "process" ;;
        --list)     get_processes | awk -F'|' '{print $1"\t"$7"\t"$3"% CPU"}' ;;
        --top)
            get_processes | head -5 | \
                awk -F'|' '{printf "PID:%s  %-15s  CPU:%.1f%%  MEM:%s\n", $1,$7,$3,$5}'
            ;;
        --help|-h)
            echo "ASH Process Killer v5.0"
            echo ""
            echo "Usage: process-killer.sh [OPTION] [PID]"
            echo "  --kill PID    Send SIGTERM"
            echo "  --force PID   Send SIGKILL"
            echo "  --stop PID    Send SIGSTOP (freeze)"
            echo "  --cont PID    Send SIGCONT (resume)"
            echo "  --list        List processes"
            echo "  --top         Top 5 by CPU"
            exit 0
            ;;
        "")
            return 1
            ;;
    esac
    exit 0
}

# ══════════════════════════════════════════════════════════════════════════════
# §12  ROFI CUSTOM MODE PROTOCOL
# ══════════════════════════════════════════════════════════════════════════════

if [[ -z "${ROFI_RETV:-}" ]]; then
    handle_direct_args "${1:-}" "${2:-}" 2>/dev/null || true
    setup_state

    rofi \
        -show pk \
        -modi "pk:${BASH_SOURCE[0]}" \
        -config "${HOME}/.config/rofi/menus/process-killer/process-killer.rasi" \
        2>/dev/null
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 0 ]]; then
    setup_state
    build_process_entries
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 1 ]]; then
    action="${ROFI_INFO:-}"
    [[ "$action" == "true" ]] && exit 0
    [[ -z "$action" ]] && exit 0

    IFS=$'\x1f' read -ra parts <<< "$action"
    local_action="${parts[0]:-}"
    meta_value="${parts[2]:-}"

    dispatch_action "$local_action" "$meta_value"
    build_process_entries
    exit 0
fi

# Ctrl+S: SIGSTOP
if [[ "${ROFI_RETV}" -eq 10 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    IFS='|' read -r pid name rest <<< "$meta_value"
    [[ -n "$pid" ]] && send_signal "$pid" "STOP" "${name:-process}"
    build_process_entries
    exit 0
fi

# Ctrl+C: SIGCONT
if [[ "${ROFI_RETV}" -eq 11 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    IFS='|' read -r pid name rest <<< "$meta_value"
    [[ -n "$pid" ]] && send_signal "$pid" "CONT" "${name:-process}"
    build_process_entries
    exit 0
fi

# Ctrl+N: Renice
if [[ "${ROFI_RETV}" -eq 12 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    IFS='|' read -r pid name rest <<< "$meta_value"
    [[ -n "$pid" ]] && renice_process "$pid" "${name:-process}"
    build_process_entries
    exit 0
fi

# Ctrl+I: Process info
if [[ "${ROFI_RETV}" -eq 13 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    IFS='|' read -r pid name rest <<< "$meta_value"
    [[ -n "$pid" ]] && show_process_info "$pid" "${name:-}"
    build_process_entries
    exit 0
fi

# Ctrl+R: Refresh
if [[ "${ROFI_RETV}" -eq 14 ]]; then
    build_process_entries
    exit 0
fi

# Ctrl+H: Toggle user filter
if [[ "${ROFI_RETV}" -eq 22 ]]; then
    toggle_user_filter
    build_process_entries
    exit 0
fi

# Ctrl+T: Sort by CPU
if [[ "${ROFI_RETV}" -eq 16 ]]; then
    echo "cpu" > "$SORT_FILE"
    build_process_entries
    exit 0
fi

# Ctrl+M: Sort by MEM
if [[ "${ROFI_RETV}" -eq 17 ]]; then
    echo "mem" > "$SORT_FILE"
    build_process_entries
    exit 0
fi

# Ctrl+K: Kill all by name
if [[ "${ROFI_RETV}" -eq 19 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    IFS='|' read -r pid name rest <<< "$meta_value"
    [[ -n "$name" ]] && kill_all_by_name "$name"
    build_process_entries
    exit 0
fi

# Ctrl+E: Open btop
if [[ "${ROFI_RETV}" -eq 20 ]]; then
    dispatch_action "open-btop"
    exit 0
fi

# Alt+Enter: Force kill
if [[ "${ROFI_RETV}" -eq 21 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    IFS='|' read -r pid name rest <<< "$meta_value"
    if [[ -n "$pid" ]]; then
        confirm=$(printf "Yes, force kill\nCancel" | \
            rofi -dmenu \
                -p "Force kill: ${name} (${pid})?" \
                -theme-str "window { width: 300px; } listview { lines: 2; }
                    element selected.normal { background-color: #f38ba8; text-color: #1e1e2e; }" \
                2>/dev/null || echo "Cancel")
        [[ "$confirm" == "Yes, force kill" ]] && send_signal "$pid" "KILL" "${name:-process}"
    fi
    build_process_entries
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 2 ]]; then
    build_process_entries
    exit 0
fi