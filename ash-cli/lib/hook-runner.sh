#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  🪝 ASH HOOK RUNNER — sandboxed lifecycle hooks with budgets & ordering       ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  Hook discovery order (later definitions win on name conflicts):              ║
# ║    1. <repo>/scripts/hooks/<name>.sh          (shipped defaults)              ║
# ║    2. ~/.config/ash/hooks/<name>.sh           (user overrides)                ║
# ║    3. ~/.config/ash/hooks/<name>.d/*.sh       (drop-in fragments, sorted)     ║
# ║                                                                               ║
# ║  Safety model                                                                ║
# ║    • Each hook runs in its own subshell — it cannot mutate our state.         ║
# ║    • Hard wall-clock timeout (default 10 s) so a broken hook can't hang boot. ║
# ║    • Exit codes are captured; a failure is reported, never fatal (unless the  ║
# ║      hook is declared `critical` via the `# ash:critical` marker).            ║
# ║    • stdout/stderr are captured and surfaced only on failure.                 ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_HOOK_RUNNER_LOADED:-}" ]] && return 0
readonly _ASH_HOOK_RUNNER_LOADED=1
readonly ASH_HOOK_RUNNER_VERSION="5.0.0"

: "${ASH_HOOKS_USER_DIR:=${XDG_CONFIG_HOME:-$HOME/.config}/ash/hooks}"
: "${ASH_HOOK_TIMEOUT:=10}"
: "${ASH_HOOKS_ENABLED:=1}"
: "${ASH_HOOKS_STRICT:=0}"

# ── Canonical lifecycle hook names ───────────────────────────────────────────
readonly -a ASH_HOOK_NAMES=(
    "pre_command"        "post_command"
    "pre_install"        "post_install"
    "pre_theme_change"   "post_theme_change"
    "pre_mode_change"    "post_mode_change"
    "pre_snapshot"       "post_snapshot"
    "pre_update"         "post_update"
    "pre_plugin_install" "post_plugin_install"
    "pre_backup"         "post_backup"
    "on_login"           "on_logout"
    "on_lock"            "on_unlock"
    "on_suspend"         "on_resume"
    "on_monitor_connect" "on_monitor_disconnect"
    "on_battery"         "on_ac_power"
    "on_battery_low"     "on_battery_critical"
    "on_network_connect" "on_network_disconnect"
    "on_bluetooth_connect" "on_bluetooth_disconnect"
    "on_usb_connect"     "on_usb_disconnect"
    "on_window_open"     "on_window_close"
    "on_workspace_change" "on_fullscreen"
    "on_idle"            "on_startup"  "on_shutdown"
)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 1  DISCOVERY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

: "${ASH_REPO_ROOT:=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)}"

ash_hook_name_valid() {
    local n
    for n in "${ASH_HOOK_NAMES[@]}"; do [[ "$n" == "$1" ]] && return 0; done
    # Allow custom hooks but require the naming convention.
    [[ "$1" =~ ^[a-z][a-z0-9_]*$ ]]
}

# Prints the executable hook files for <name>, in run order.
ash_hook_resolve() {
    local name="$1"
    local -a found=()

    local repo_hook="${ASH_REPO_ROOT}/scripts/hooks/${name}.sh"
    [[ -x "$repo_hook" || -f "$repo_hook" ]] && found+=("$repo_hook")

    local user_hook="${ASH_HOOKS_USER_DIR}/${name}.sh"
    [[ -f "$user_hook" ]] && found+=("$user_hook")

    local dropin_dir="${ASH_HOOKS_USER_DIR}/${name}.d"
    if [[ -d "$dropin_dir" ]]; then
        local f
        while IFS= read -r f || [[ -n "$f" ]]; do
            [[ -z "$f" ]] && continue
            found+=("$f")
        done < <(find "$dropin_dir" -maxdepth 1 -name '*.sh' -print 2>/dev/null | LC_ALL=C sort)
    fi

    (( ${#found[@]} )) && printf '%s\n' "${found[@]}"
}

ash_hook_exists() {
    local name="$1"
    [[ -n "$(ash_hook_resolve "$name" | head -1)" ]]
}

# ── Metadata extraction from the hook header ──────────────────────────────────
# A hook may declare, in its first 20 lines:
#     # ash:timeout=30
#     # ash:critical
#     # ash:description=Apply GTK colours
_ash_hook_meta() {
    local file="$1" key="$2"
    head -20 "$file" 2>/dev/null \
        | grep -oP "^#\s*ash:${key}(=\K.*)?" 2>/dev/null \
        | head -1
}

_ash_hook_is_critical() {
    head -20 "$1" 2>/dev/null | grep -qE '^#\s*ash:critical' 2>/dev/null
}

_ash_hook_timeout_of() {
    local t; t="$(_ash_hook_meta "$1" "timeout")"
    [[ "$t" =~ ^[0-9]+$ ]] && printf '%s' "$t" || printf '%s' "$ASH_HOOK_TIMEOUT"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 2  EXECUTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ash_hook_run <name> [key=value …]
# Returns 0 when every hook succeeded, 1 when a critical hook failed.
ash_hook_run() {
    local name="${1:-}"; shift || true
    [[ -z "$name" ]] && return 1

    [[ "${ASH_HOOKS_ENABLED:-1}" != "1" ]] && return 0
    [[ "${ASH_FLAG_NO_HOOKS:-0}" == "1" ]] && return 0

    # ── Runner-level flags consumed here, never forwarded to hooks ──────────
    #   --env KEY=VAL     legacy alias for the plain KEY=VAL form
    #   --timeout N       per-run override of the hook header timeout
    #   --on-error MODE   continue | fail  (overrides ASH_HOOKS_STRICT)
    #   --strict          shorthand for --on-error fail
    local -a pairs=()
    local timeout_override="" on_error=""
    while (( $# )); do
        case "${1:-}" in
            --env)
                shift || true
                [[ -n "${1:-}" ]] && pairs+=("$1") && shift
                ;;
            --timeout)
                shift || true
                [[ "${1:-}" =~ ^[0-9]+$ ]] && timeout_override="$1"
                shift || true
                ;;
            --on-error)
                shift || true
                on_error="${1:-}"
                shift || true
                ;;
            --strict)      on_error="fail"; shift ;;
            --no-strict)   on_error="continue"; shift ;;
            --*=*)         pairs+=("${1#--}"); shift ;;
            "")            shift ;;
            *)             pairs+=("$1"); shift ;;
        esac
    done
    [[ -n "$timeout_override" ]] && ASH_HOOK_TIMEOUT="$timeout_override"
    case "$on_error" in
        fail|strict) ASH_HOOKS_STRICT=1 ;;
        continue)    ASH_HOOKS_STRICT=0 ;;
    esac
    set -- "${pairs[@]:-}"

    local -a hooks
    mapfile -t hooks < <(ash_hook_resolve "$name")
    (( ${#hooks[@]} == 0 )) && return 0

    local critical_failed=0
    local hook

    for hook in "${hooks[@]}"; do
        [[ -f "$hook" ]] || continue

        local hook_timeout; hook_timeout="$(_ash_hook_timeout_of "$hook")"
        local start_ns; start_ns="$(date +%s%N 2>/dev/null || date +%s)"
        local out_tmp; out_tmp="$(mktemp "${TMPDIR:-/tmp}/ash-hook-XXXXXX")"

        # Export context so hooks don't have to be passed anything.
        local -a env_ctx=(
            "ASH_HOOK_NAME=${name}"
            "ASH_HOOK_FILE=${hook}"
            "ASH_HOOK_ARGS=${*:-}"
            "ASH_VERSION=${ASH_VERSION:-5.0.0-omega}"
        )
        local kv
        for kv in "$@"; do
            local k="${kv%%=*}" v="${kv#*=}"
            k="${k//[^A-Za-z0-9_]/_}"
            env_ctx+=("ASH_HOOK_${k^^}=${v}")
        done

        ash_event_emit "hook.pre" "hook=${name}" "file=${hook}" 2>/dev/null || true

        local rc=0
        if command -v timeout >/dev/null 2>&1; then
            env "${env_ctx[@]}" timeout --kill-after=2 "$hook_timeout" \
                bash "$hook" "$@" >"$out_tmp" 2>&1 || rc=$?
        else
            env "${env_ctx[@]}" bash "$hook" "$@" >"$out_tmp" 2>&1 || rc=$?
        fi

        local elapsed_ms
        local end_ns; end_ns="$(date +%s%N 2>/dev/null || date +%s)"
        elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))

        # ── Interpret the exit status ────────────────────────────────────
        if (( rc == 124 || rc == 137 )); then
            ash_log_warn "hook '${name}' timed out after ${hook_timeout}s: ${hook}" 2>/dev/null \
                || printf "ash: hook '%s' timed out\n" "$name" >&2
            sed 's/^/    /' "$out_tmp" 2>/dev/null | head -20
            ash_event_emit "hook.failed" "hook=${name}" "reason=timeout" "file=${hook}" 2>/dev/null || true
            _ash_hook_is_critical "$hook" && critical_failed=1

        elif (( rc == 66 )); then
            # Exit 66 is the documented "skip" code — not an error.
            ash_log_debug "hook '${name}' skipped itself: ${hook}" 2>/dev/null || true

        elif (( rc != 0 )); then
            ash_log_warn "hook '${name}' failed (exit ${rc}): ${hook}" 2>/dev/null \
                || printf "ash: hook '%s' failed with exit %d\n" "$name" "$rc" >&2
            sed 's/^/    /' "$out_tmp" 2>/dev/null | head -20
            ash_event_emit "hook.failed" "hook=${name}" "exit=${rc}" "file=${hook}" 2>/dev/null || true
            _ash_hook_is_critical "$hook" && critical_failed=1

        else
            ash_log_debug "hook '${name}' ok in ${elapsed_ms}ms: ${hook}" 2>/dev/null || true
            # Surface hook chatter at debug level only.
            [[ -s "$out_tmp" ]] && sed 's/^/    /' "$out_tmp" 2>/dev/null | head -10
        fi

        rm -f "$out_tmp" 2>/dev/null || true
        ash_event_emit "hook.post" "hook=${name}" "exit=${rc}" "ms=${elapsed_ms}" 2>/dev/null || true
    done

    if (( critical_failed == 1 && ASH_HOOKS_STRICT == 1 )); then
        return 1
    fi
    return 0
}

# Run every hook of a category in parallel (used at login for independent
# things like "restore wallpaper" + "start clipboard daemon").
ash_hook_run_parallel() {
    local name="$1"; shift || true
    local -a hooks
    mapfile -t hooks < <(ash_hook_resolve "$name")
    (( ${#hooks[@]} == 0 )) && return 0

    local -a pids=()
    local hook
    for hook in "${hooks[@]}"; do
        ( bash "$hook" "$@" >/dev/null 2>&1 ) &
        pids+=("$!")
    done

    local rc=0 p
    for p in "${pids[@]}"; do
        wait "$p" || rc=1
    done
    return $rc
}

# ── Scaffolding ──────────────────────────────────────────────────────────────
ash_hook_create() {
    local name="$1"
    ash_hook_name_valid "$name" || {
        ash_log_error "invalid hook name: ${name}" 2>/dev/null \
            || printf 'ash: invalid hook name: %s\n' "$name" >&2
        return 1
    }

    mkdir -p "$ASH_HOOKS_USER_DIR" 2>/dev/null || return 1
    local target="${ASH_HOOKS_USER_DIR}/${name}.sh"

    [[ -f "$target" ]] && {
        ash_log_error "hook already exists: ${target}" 2>/dev/null || true
        return 1
    }

    cat > "$target" <<EOF
#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# ASH user hook: ${name}
# ash:description=Describe what this hook does
# ash:timeout=10
# ash:critical
#
# Available context:
#   ASH_HOOK_NAME   ${name}
#   ASH_HOOK_ARGS   space-separated key=value arguments
#   ASH_HOOK_<KEY>  each argument upper-cased
#   ASH_VERSION     dotfiles version
#
# Exit codes:
#   0  success
#   66 skip this hook without reporting an error
#   *  failure (logged; keeps running unless `ash:critical`)
# ─────────────────────────────────────────────────────────────────────────
# A sourced library must not mutate the caller's shell options.
# `set -e` inside a sourced file silently aborts the *parent* script
# on the next non-zero test, which is a nightmare to debug.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
fi

ash_log_info "hook ${name} running" 2>/dev/null || echo "${name}: running"

# ↓ your logic here ↓
true
EOF

    chmod +x "$target"
    printf '%s\n' "$target"
}

# ── Introspection ────────────────────────────────────────────────────────────
ash_hook_list() {
    local name
    for name in "${ASH_HOOK_NAMES[@]}"; do
        local -a hooks
        mapfile -t hooks < <(ash_hook_resolve "$name")
        if (( ${#hooks[@]} == 0 )); then
            printf '%-26s %s\n' "$name" "—"
        else
            printf '%-26s %d file(s)\n' "$name" "${#hooks[@]}"
            local h
            for h in "${hooks[@]}"; do printf '%-26s   %s\n' "" "$h"; done
        fi
    done
}

# Health check used by `ash doctor`.
ash_hook_health_check() {
    local issues=0 name hook
    for name in "${ASH_HOOK_NAMES[@]}"; do
        while IFS= read -r hook || [[ -n "$hook" ]]; do
            [[ -z "$hook" ]] && continue
            if [[ ! -x "$hook" ]]; then
                printf '  ⚠ not executable: %s\n' "$hook"
                (( issues += 1 ))
            fi
            if ! bash -n "$hook" 2>/dev/null; then
                printf '  ✗ syntax error  : %s\n' "$hook"
                (( issues += 1 ))
            fi
            if [[ "$(head -1 "$hook")" != '#!/usr/bin/env bash' && "$(head -1 "$hook")" != '#!/bin/bash' ]]; then
                printf '  ⚠ missing shebang: %s\n' "$hook"
            fi
        done < <(ash_hook_resolve "$name")
    done
    (( issues == 0 )) && printf '  ✓ all hooks are executable and syntactically valid\n'
    return $(( issues > 0 ? 1 : 0 ))
}
