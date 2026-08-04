#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║   ██████╗  █████╗ ███╗   ███╗███████╗███╗   ███╗ ██████╗ ██████╗ ███████╗       ║
# ║  ██╔════╝ ██╔══██╗████╗ ████║██╔════╝████╗ ████║██╔═══██╗██╔══██╗██╔════╝       ║
# ║  ██║  ███╗███████║██╔████╔██║█████╗  ██╔████╔██║██║   ██║██║  ██║█████╗         ║
# ║  ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  ██║╚██╔╝██║██║   ██║██║  ██║██╔══╝         ║
# ║  ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗██║ ╚═╝ ██║╚██████╔╝██████╔╝███████╗       ║
# ║   ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝       ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  gaming gamemode                                          ║
# ║  Feral GameMode daemon: start • stop • status • config • request for process    ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_GAMING_GAMEMODE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_GAMING_GAMEMODE_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  GAMEMODE STATUS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_gmd_status() {
    gm_section "🚀" "GameMode Status" "$(_ggreen)"

    # Check installation
    if ! command -v gamemoded &>/dev/null; then
        gm_fail "GameMode not installed"
        gm_info "Install: paru -S gamemode"
        printf '\n'; return 1
    fi

    local gmd_ver
    gmd_ver="$(gamemoded --version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo '?')"
    gm_kv "Version" "v${gmd_ver}"

    # Daemon status
    if pgrep -x gamemoded &>/dev/null; then
        local gmd_pid
        gmd_pid="$(pgrep -x gamemoded | head -1)"
        gm_kv "Daemon"   "$(gm_badge " ● RUNNING " "$(_ggreen)")  PID: ${gmd_pid}"

        # Client count via gamemoded -s
        local gmd_status
        gmd_status="$(gamemoded -s 2>/dev/null || echo '')"

        if [[ -n "$gmd_status" ]]; then
            local client_count
            client_count="$(printf '%s' "$gmd_status" | grep -oP '\d+(?= client)' || echo '0')"
            gm_kv "Clients"  "${client_count} game(s) using GameMode"

            # List active clients
            if (( ${client_count:-0} > 0 )); then
                gm_section "🎮" "Active GameMode Clients" "$(_gdim)"
                printf '%s' "$gmd_status" | \
                    grep -E 'PID|process' | head -10 | \
                    while IFS= read -r line; do
                        printf '  %s%s%s\n' "$(_gdim)" "$line" "$(_gr)"
                    done
            fi
        fi

        # Uptime
        local gmd_uptime
        gmd_uptime="$(ps -p "$gmd_pid" -o etime= 2>/dev/null | tr -d ' ')"
        [[ -n "$gmd_uptime" ]] && gm_kv "Uptime" "$gmd_uptime"

        # CPU/MEM usage
        local gmd_cpu gmd_mem
        gmd_cpu="$(ps -p "$gmd_pid" -o %cpu= 2>/dev/null | tr -d ' ')"
        gmd_mem="$(ps -p "$gmd_pid" -o rss=  2>/dev/null | awk '{printf "%.1f MB", $1/1024}')"
        [[ -n "$gmd_cpu" ]] && gm_kv "Resources" "CPU: ${gmd_cpu}%  •  MEM: ${gmd_mem}"

    else
        gm_kv "Daemon"   "$(gm_badge " ○ STOPPED " "$(_gdim)")"
        gm_info "Start: ash gaming gamemode start"
    fi

    # systemd service
    if command -v systemctl &>/dev/null; then
        local svc_state
        svc_state="$(systemctl --user is-enabled gamemoded 2>/dev/null || echo 'unknown')"
        gm_kv "Auto-start" "$svc_state"
    fi

    # Config file
    local gmd_config
    for cfg_path in \
        "${XDG_CONFIG_HOME:-$HOME/.config}/gamemode.ini" \
        "/etc/gamemode.ini" \
        "/usr/share/doc/gamemode/example/gamemode.ini"; do
        if [[ -f "$cfg_path" ]]; then
            gmd_config="$cfg_path"
            break
        fi
    done

    if [[ -n "${gmd_config:-}" ]]; then
        gm_kv "Config"  "${gmd_config/#$HOME/~}"
    else
        gm_kv "Config"  "not found  (using defaults)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  GAMEMODE CONFIG GENERATOR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_gmd_generate_config() {
    local cfg_file="${XDG_CONFIG_HOME:-$HOME/.config}/gamemode.ini"

    if [[ -f "$cfg_file" ]]; then
        gm_warn "Config already exists: ${cfg_file}"
        printf '  %sOverwrite? [y/N] %s' "$(_gyellow)" "$(_gr)"
        local ans; read -r ans
        [[ "${ans,,}" != "y" ]] && { gm_info "Cancelled"; return 0; }
    fi

    # Auto-detect GPU vendor
    local gpu_vendor="auto"
    if lspci 2>/dev/null | grep -qi 'nvidia'; then
        gpu_vendor="nvidia"
    elif lspci 2>/dev/null | grep -qi 'amd\|radeon'; then
        gpu_vendor="amd"
    fi

    local cpu_cores
    cpu_cores="$(nproc --all 2>/dev/null || echo 4)"

    cat > "$cfg_file" << CONF
; ╔══════════════════════════════════════════════════════════╗
; ║  ASH GameMode Configuration                              ║
; ║  Generated: $(date -Iseconds)                           ║
; ╚══════════════════════════════════════════════════════════╝

[general]
; Default governor when GameMode is active
desiredgov=performance

; Renice game processes
renice=0

; Soft realtime scheduling
softrealtime=off

; I/O priority for game processes  (0=highest, 7=lowest)
ioprio=0

; GameMode screensaver inhibitor
inhibit_screensaver=1

[filter]
; Whitelist mode (only listed games get GameMode)
; whitelist=game1:game2

; Blacklist (never apply GameMode to these)
; blacklist=wine:steam

[gpu]
; GPU optimizations (requires root/polkit)
apply_gpu_optimisations=accept-responsibility

; NVIDIA: enable persistence mode
nv_powermizer_mode=1

; AMD: DPM performance level
amd_performance_level=high

[cpu]
; CPU pin mode: none, pin, default
pin_cores=1

; Disable CPU pinning for hyperthreaded cores
park_cores=0

[custom]
; Custom scripts to run when GameMode activates
; start=${_GM_CONFIG_DIR}/gamemode-start.sh
; end=${_GM_CONFIG_DIR}/gamemode-end.sh
CONF

    gm_ok "Config generated: ${cfg_file}"

    # Also create custom hook scripts
    mkdir -p "$_GM_CONFIG_DIR" 2>/dev/null || true

    cat > "${_GM_CONFIG_DIR}/gamemode-start.sh" << 'HOOK'
#!/usr/bin/env bash
# Called when GameMode ACTIVATES
# Add custom pre-game optimizations here

# Example: disable compositor blur
# hyprctl keyword decoration:blur:enabled 0 2>/dev/null

# Example: notify
# notify-send "🎮 GameMode" "Game started" --urgency=low

exit 0
HOOK

    cat > "${_GM_CONFIG_DIR}/gamemode-end.sh" << 'HOOK'
#!/usr/bin/env bash
# Called when GameMode DEACTIVATES
# Restore any settings changed in start.sh

# hyprctl keyword decoration:blur:enabled 1 2>/dev/null

exit 0
HOOK

    chmod +x "${_GM_CONFIG_DIR}/gamemode-start.sh" \
             "${_GM_CONFIG_DIR}/gamemode-end.sh" 2>/dev/null || true

    gm_ok "Hook scripts created: ${_GM_CONFIG_DIR}/"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  LAUNCH WITH GAMEMODE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_gmd_run() {
    local -a cmd=("$@")

    if [[ ${#cmd[@]} -eq 0 ]]; then
        gm_fail "No command specified"
        gm_info "Usage: ash gaming gamemode run <command>"
        return 1
    fi

    if ! command -v gamemoderun &>/dev/null; then
        gm_fail "gamemoderun not found"
        gm_info "Install: paru -S gamemode"
        return 1
    fi

    gm_step "Launching with GameMode: ${cmd[*]}..."

    # Ensure daemon is running
    if ! pgrep -x gamemoded &>/dev/null; then
        gamemoded -d 2>/dev/null &
        sleep 0.3
    fi

    gamemoderun "${cmd[@]}" &
    local pid=$!

    gm_ok "Launched  (PID: ${pid})"
    gm_notify "🚀 GameMode" "Running: ${cmd[*]:0:1}"

    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  ANIMATED STARTUP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_gmd_boot_animation() {
    local starting="$1"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        if [[ $starting -eq 1 ]]; then
            local frames=( '🚀' '🚀' '⚡' '⚡' '🎮' )
            local msg="Starting GameMode daemon"
        else
            local frames=( '🎮' '⚡' '💤' '💤' )
            local msg="Stopping GameMode daemon"
        fi
        for frame in "${frames[@]}"; do
            printf '\r  %s  %s%s%s...' \
                "$frame" "$(_ggreen)$(_gbold)" "$msg" "$(_gr)"
            sleep 0.12
        done
        printf '\r  %-60s\n' ""
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_gaming_gamemode() {
    local action="status"
    local -a run_cmd=()

    for arg in "${@:-}"; do
        case "$arg" in
            status|info)                          action="status"   ;;
            start|enable|on)                      action="start"    ;;
            stop|disable|off|kill)                action="stop"     ;;
            restart)                              action="restart"  ;;
            config|configure|init)                action="config"   ;;
            run|-r|exec)                          action="run"      ;;
            enable-autostart|autostart)           action="autostart" ;;
            disable-autostart|no-autostart)       action="no-autostart" ;;
            request|-q)                           action="request"  ;;
            *)
                [[ "$action" == "run" ]] && run_cmd+=("$arg")
                ;;
        esac
    done

    gm_section "🚀" "GameMode" "$(_ggreen)"

    # Check installation
    if ! command -v gamemoded &>/dev/null; then
        gm_fail "GameMode not installed"
        gm_info "Install: paru -S gamemode"
        printf '\n'; return 1
    fi

    case "$action" in
        status)
            _gmd_status
            ;;

        start)
            if pgrep -x gamemoded &>/dev/null; then
                gm_info "GameMode is already running"
                printf '\n'; return 0
            fi

            _gmd_boot_animation 1

            if systemctl --user start gamemoded 2>/dev/null; then
                sleep 0.3
                gm_ok "GameMode started via systemd"
            elif gamemoded -d 2>/dev/null; then
                sleep 0.3
                gm_ok "GameMode started as daemon"
            else
                gm_fail "Failed to start GameMode"
                return 1
            fi

            gm_notify "🚀 GameMode" "Daemon started"
            ;;

        stop)
            if ! pgrep -x gamemoded &>/dev/null; then
                gm_info "GameMode is not running"
                printf '\n'; return 0
            fi

            _gmd_boot_animation 0

            if systemctl --user stop gamemoded 2>/dev/null; then
                gm_ok "GameMode stopped via systemd"
            else
                pkill -x gamemoded 2>/dev/null && gm_ok "GameMode stopped"
            fi

            gm_notify "💤 GameMode" "Daemon stopped"
            ;;

        restart)
            ash_gaming_gamemode stop
            sleep 0.5
            ash_gaming_gamemode start
            ;;

        config)
            _gmd_generate_config
            ;;

        autostart)
            systemctl --user enable gamemoded 2>/dev/null && \
                gm_ok "GameMode: will auto-start with user session" || \
                gm_fail "Could not enable auto-start"
            ;;

        no-autostart)
            systemctl --user disable gamemoded 2>/dev/null && \
                gm_ok "GameMode: auto-start disabled" || \
                gm_fail "Could not disable auto-start"
            ;;

        run)
            _gmd_run "${run_cmd[@]:-}"
            ;;

        request)
            # Request GameMode for current shell PID
            local target_pid="${run_cmd[0]:-$$}"
            if command -v gamemoded &>/dev/null; then
                gamemoded -r "$target_pid" 2>/dev/null && \
                    gm_ok "GameMode requested for PID: ${target_pid}" || \
                    gm_warn "GameMode request failed (is daemon running?)"
            fi
            ;;
    esac

    printf '\n'
}
