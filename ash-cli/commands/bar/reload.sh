#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  bar reload                                               ║
# ║  Hot-reload bar config • validate before reload • watch-and-reload mode          ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_BAR_RELOAD_LOADED:-}" == "1" ]] && return 0
readonly _ASH_BAR_RELOAD_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CONFIG VALIDATORS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_reload_validate_waybar() {
    local cfg_dir="${_BAR_CFG_DIR}/waybar"
    local errors=0

    bar_step "Validating Waybar configuration..."

    # JSON validation
    local config_file="${cfg_dir}/config.jsonc"
    if [[ -f "$config_file" ]]; then
        if command -v python3 &>/dev/null; then
            if python3 -c "
import json, re, sys
content = open(sys.argv[1]).read()
clean = re.sub(r'//.*?\$|/\*.*?\*/', '', content, flags=re.M|re.S)
try:
    json.loads(clean)
    print('OK')
except json.JSONDecodeError as e:
    print(f'ERROR: {e}', file=sys.stderr)
    sys.exit(1)
" "$config_file" &>/dev/null; then
                bar_ok "config.jsonc: valid JSON"
            else
                bar_fail "config.jsonc: INVALID JSON"
                (( errors++ )) || true
            fi
        fi
    else
        bar_warn "config.jsonc not found at ${config_file}"
        (( errors++ )) || true
    fi

    # CSS syntax check (basic)
    local style_file="${cfg_dir}/style.css"
    if [[ -f "$style_file" ]]; then
        local brace_opens brace_closes
        brace_opens="$(grep -c '{' "$style_file" 2>/dev/null || echo 0)"
        brace_closes="$(grep -c '}' "$style_file" 2>/dev/null || echo 0)"

        if [[ "$brace_opens" -eq "$brace_closes" ]]; then
            bar_ok "style.css: braces balanced  ({:${brace_opens} }:${brace_closes})"
        else
            bar_warn "style.css: unbalanced braces  ({:${brace_opens} }:${brace_closes})"
        fi
    fi

    return $errors
}

_reload_validate_ags() {
    local cfg_dir="${_BAR_CFG_DIR}/ags"
    bar_step "Validating AGS configuration..."

    local app_js="${cfg_dir}/app.ts"
    [[ -f "$app_js" ]] || app_js="${cfg_dir}/config.js"

    if [[ -f "$app_js" ]]; then
        bar_ok "AGS config found: ${app_js##*/}"
    else
        bar_warn "AGS config not found"
    fi
}

_reload_validate_eww() {
    local cfg_dir="${_BAR_CFG_DIR}/eww"
    bar_step "Validating EWW configuration..."

    local yuck="${cfg_dir}/eww.yuck"
    local scss="${cfg_dir}/eww.scss"

    [[ -f "$yuck" ]] && bar_ok "eww.yuck found" || \
        bar_warn "eww.yuck not found"
    [[ -f "$scss" ]] && bar_ok "eww.scss found" || \
        bar_info "eww.scss not found (optional)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BACKEND-SPECIFIC RELOAD
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_reload_waybar() {
    local method="${1:-signal}"   # signal | restart | ipc

    case "$method" in
        signal)
            # SIGUSR2 = reload config
            if pkill -SIGUSR2 waybar 2>/dev/null; then
                bar_ok "Waybar reloaded  (SIGUSR2)"
                return 0
            fi
            ;;
        restart)
            pkill -x waybar 2>/dev/null || true
            sleep 0.3
            waybar &>/dev/null &
            sleep 0.5
            pgrep -x waybar &>/dev/null && \
                bar_ok "Waybar restarted" || \
                bar_fail "Waybar failed to restart"
            return 0
            ;;
        ipc)
            # Try waybar IPC socket
            local socket="${XDG_RUNTIME_DIR:-/tmp}/waybar.socket"
            if [[ -S "$socket" ]]; then
                printf '{"action":"reload"}' | nc -U "$socket" 2>/dev/null && \
                    bar_ok "Waybar reloaded via IPC"
                return 0
            fi
            ;;
    esac
}

_reload_ags() {
    if command -v ags &>/dev/null; then
        ags quit 2>/dev/null || true
        sleep 0.2
        ags &>/dev/null &
        sleep 0.3
        bar_ok "AGS restarted"
    else
        bar_fail "AGS not installed"
        return 1
    fi
}

_reload_eww() {
    if command -v eww &>/dev/null; then
        eww reload 2>/dev/null && \
            bar_ok "EWW reloaded" || \
            bar_fail "EWW reload failed"
    else
        bar_fail "EWW not installed"
        return 1
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WATCH MODE (auto-reload on config change)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_reload_watch_mode() {
    local cfg_dir
    cfg_dir="$(bar_get_config_dir)"

    if ! command -v inotifywait &>/dev/null; then
        bar_fail "inotifywait required for watch mode"
        bar_info "Install: paru -S inotify-tools"
        return 1
    fi

    bar_ok "Watching for config changes in: ${cfg_dir}"
    bar_info "Press Ctrl+C to stop"

    trap 'printf "\n"; bar_info "Watch mode stopped"; exit 0' INT TERM

    inotifywait -m -r -e modify,create,delete \
        --include '\.(jsonc|json|css|scss|ts|js|yuck)$' \
        "$cfg_dir" 2>/dev/null | \
    while IFS=' ' read -r dir event file; do
        printf '\n  %s%s  File changed: %s%s\n' \
            "$(_bpeach)" "$(date '+%H:%M:%S')" \
            "${file}" "$(_br)"

        sleep 0.2  # debounce

        bar_step "Auto-reloading ${BAR_BACKEND}..."
        ash_bar_reload --quiet 2>/dev/null || true
        bar_ok "Auto-reload complete"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PROGRESS ANIMATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_reload_spinner() {
    local msg="$1"
    local frames=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
    local i=0
    while true; do
        printf '\r  %s%s%s  %s' "$(_bteal)" "${frames[$i]}" "$(_br)" "$msg"
        i=$(( (i+1) % ${#frames[@]} ))
        sleep 0.08
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_bar_reload() {
    local skip_validation=0
    local method="signal"
    local watch=0
    local quiet=0
    local force=0

    for arg in "${@:-}"; do
        case "$arg" in
            --no-validate|-n)  skip_validation=1  ;;
            --method=*)        method="${arg#*=}"  ;;
            --restart|-r)      method="restart"   ;;
            --watch|-w)        watch=1             ;;
            --quiet|-q)        quiet=1             ;;
            --force|-f)        force=1             ;;
        esac
    done

    if [[ $watch -eq 1 ]]; then
        bar_section "👀" "Watch & Auto-Reload" "$(_byellow)"
        _reload_watch_mode
        return 0
    fi

    [[ $quiet -eq 0 ]] && bar_section "🔄" "Reload Bar" "$(_bteal)"
    [[ $quiet -eq 0 ]] && bar_kv "Backend" "$BAR_BACKEND"
    [[ $quiet -eq 0 ]] && bar_kv "Method"  "$method"

    if ! bar_is_running "$BAR_BACKEND"; then
        [[ $quiet -eq 0 ]] && bar_warn "${BAR_BACKEND} is not running"
        [[ $quiet -eq 0 ]] && bar_info "Nothing to reload"
        printf '\n'
        return 0
    fi

    # Validate config before reload
    local validation_ok=1
    if [[ $skip_validation -eq 0 ]]; then
        case "$BAR_BACKEND" in
            waybar)  _reload_validate_waybar || validation_ok=0 ;;
            ags)     _reload_validate_ags    || validation_ok=0 ;;
            eww)     _reload_validate_eww    || validation_ok=0 ;;
        esac

        if [[ $validation_ok -eq 0 ]] && [[ $force -eq 0 ]]; then
            bar_fail "Validation errors found — reload aborted"
            bar_info "Fix errors then retry, or use --force to skip validation"
            printf '\n'; return 1
        fi
    fi

    # Spinner during reload
    local spin_pid=""
    if [[ $quiet -eq 0 ]]; then
        _reload_spinner "Reloading ${BAR_BACKEND}..." &
        spin_pid=$!
        trap 'kill "$spin_pid" 2>/dev/null' EXIT INT TERM
    fi

    local start_ts exit_code=0
    start_ts="$(date +%s%N)"

    case "$BAR_BACKEND" in
        waybar)  _reload_waybar "$method"  || exit_code=$? ;;
        ags)     _reload_ags               || exit_code=$? ;;
        eww)     _reload_eww               || exit_code=$? ;;
        *)
            pkill -HUP "${BAR_BACKEND}" 2>/dev/null || {
                # Fallback: kill and restart
                pkill -x "$BAR_BACKEND" 2>/dev/null || true
                sleep 0.2
                "$BAR_BACKEND" &>/dev/null &
                exit_code=$?
            }
            ;;
    esac

    local elapsed_ms=$(( ($(date +%s%N) - start_ts) / 1000000 ))

    # Stop spinner
    if [[ -n "$spin_pid" ]]; then
        kill "$spin_pid" 2>/dev/null || true
        wait "$spin_pid" 2>/dev/null || true
        trap - EXIT INT TERM
        printf '\r  %-60s\n' ""
    fi

    if [[ $exit_code -eq 0 ]]; then
        [[ $quiet -eq 0 ]] && bar_ok "Reload complete  (${elapsed_ms}ms)"
        bar_notify "🔄 Bar Reloaded" "${BAR_BACKEND}  •  ${elapsed_ms}ms"
    else
        [[ $quiet -eq 0 ]] && bar_fail "Reload failed  (exit: ${exit_code})"
    fi

    printf '\n'
    return $exit_code
}
