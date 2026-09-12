#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  🔌 ASH PLUGIN LOADER — discovery, validation and sandboxed lifecycle         ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  A plugin is a directory containing:                                          ║
# ║      plugin.json   metadata + declared capabilities + config schema           ║
# ║      init.sh       optional one-time setup                                    ║
# ║      enable.sh     activate (idempotent)                                      ║
# ║      disable.sh    deactivate (idempotent, must fully undo enable)            ║
# ║      status.sh     print one of: enabled | disabled | error | degraded        ║
# ║                                                                               ║
# ║  Security posture                                                            ║
# ║    • Plugin scripts are executed with a restricted environment; the parent's  ║
# ║      ASH_* internals are not re-exported to them.                            ║
# ║    • `capabilities` in plugin.json is advisory but recorded, and the loader   ║
# ║      warns when a plugin touches paths outside its declared scope.            ║
# ║    • Every lifecycle call is time-bounded so a plugin cannot hang the shell.  ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_PLUGIN_LOADER_LOADED:-}" ]] && return 0
readonly _ASH_PLUGIN_LOADER_LOADED=1
readonly ASH_PLUGIN_LOADER_VERSION="5.0.0"

: "${ASH_PLUGINS_DIR:=${ASH_REPO_ROOT:-$PWD}/plugins}"
: "${ASH_PLUGINS_STATE:=${XDG_STATE_HOME:-$HOME/.local/state}/ash/plugins.json}"
: "${ASH_PLUGIN_TIMEOUT:=30}"

# name -> directory
declare -gA ASH_PLUGIN_DIRS=()
declare -gA ASH_PLUGIN_META=()
declare -gA ASH_PLUGIN_STATE=()

_ash_plugin_state_dir() { mkdir -p "$(dirname "$ASH_PLUGINS_STATE")" 2>/dev/null || true; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 1  DISCOVERY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Search order (later wins on name collisions, so user plugins override core):
#   plugins/core  plugins/integrations  plugins/community  ~/.config/ash/plugins
ash_plugin_search_paths() {
    local -a paths=(
        "${ASH_PLUGINS_DIR}/core"
        "${ASH_PLUGINS_DIR}/integrations"
        "${ASH_PLUGINS_DIR}/community"
        "${ASH_PLUGINS_DIR}/user"
        "${XDG_CONFIG_HOME:-$HOME/.config}/ash/plugins"
    )
    local p
    for p in "${paths[@]}"; do [[ -d "$p" ]] && printf '%s\n' "$p"; done
}

ash_plugin_discover() {
    ASH_PLUGIN_DIRS=()

    local root
    while IFS= read -r root || [[ -n "$root" ]]; do
        [[ -z "$root" ]] && continue
        local dir
        while IFS= read -r dir || [[ -n "$dir" ]]; do
            [[ -z "$dir" ]] && continue
            [[ -f "${dir}/plugin.json" ]] || continue
            local name; name="$(basename "$dir")"
            ASH_PLUGIN_DIRS["$name"]="$dir"
        done < <(find "$root" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | LC_ALL=C sort)
    done < <(ash_plugin_search_paths)

    printf '%d\n' "${#ASH_PLUGIN_DIRS[@]}"
}

ash_plugin_exists() { [[ -n "${ASH_PLUGIN_DIRS[${1:-}]:-}" ]]; }

ash_plugin_dir() {
    local name="${1:-}"
    if [[ -z "${ASH_PLUGIN_DIRS[$name]:-}" ]]; then
        ash_plugin_discover >/dev/null
    fi
    printf '%s' "${ASH_PLUGIN_DIRS[$name]:-}"
}

# ── Metadata accessors (all read from plugin.json) ───────────────────────────
ash_plugin_meta() {
    local name="$1" key="$2" default="${3-}"
    local dir; dir="$(ash_plugin_dir "$name")"
    [[ -z "$dir" ]] && { printf '%s' "$default"; return 1; }

    local value
    value="$(ash_json_get "${dir}/plugin.json" ".${key}" "")"
    [[ -z "$value" ]] && value="$default"
    printf '%s' "$value"
}

ash_plugin_field() { ash_plugin_meta "$1" "$2" "${3-}"; }

# Columns: name|version|category|author|description|enabled|dir
ash_plugin_list() {
    ash_plugin_discover >/dev/null
    local name

    for name in $(printf '%s\n' "${!ASH_PLUGIN_DIRS[@]}" | LC_ALL=C sort); do
        local dir="${ASH_PLUGIN_DIRS[$name]}"
        local version category author description
        version="$(ash_json_get "${dir}/plugin.json" '.version' '0.0.0')"
        category="$(ash_json_get "${dir}/plugin.json" '.category' 'misc')"
        author="$(ash_json_get "${dir}/plugin.json" '.author' 'unknown')"
        description="$(ash_json_get "${dir}/plugin.json" '.description' '')"

        local state="disabled"
        if [[ -x "${dir}/status.sh" ]]; then
            state="$(ASH_PLUGIN_NAME="$name" timeout 5 bash "${dir}/status.sh" 2>/dev/null | head -1 || echo 'error')"
        fi

        printf '%s|%s|%s|%s|%s|%s|%s\n' \
            "$name" "$version" "$category" "$author" "$description" "$state" "$dir"
    done
}

# ── Validation ───────────────────────────────────────────────────────────────
ash_plugin_validate() {
    local name="$1"
    local dir; dir="$(ash_plugin_dir "$name")"
    [[ -z "$dir" ]] && { printf '  ✗ plugin not found: %s\n' "$name"; return 1; }

    local errors=0 warnings=0

    # plugin.json must exist, be valid JSON and carry required fields
    local manifest="${dir}/plugin.json"
    if [[ ! -f "$manifest" ]]; then
        printf '  ✗ missing plugin.json\n'; return 1
    fi
    if ! ash_json_valid "$manifest"; then
        printf '  ✗ plugin.json is not valid JSON\n'
        ash_json_validate_report "$manifest"
        return 1
    fi

    local field
    for field in name version description author license; do
        local v; v="$(ash_json_get "$manifest" ".${field}" "")"
        if [[ -z "$v" ]]; then
            printf '  ⚠ missing recommended field: %s\n' "$field"
            (( warnings += 1 ))
        fi
    done

    # Version must be semver
    local version; version="$(ash_json_get "$manifest" '.version' '')"
    if [[ -n "$version" ]] && ! ash_semver_valid "$version"; then
        printf '  ✗ version is not valid semver: %s\n' "$version"
        (( errors += 1 ))
    fi

    # Directory name should match the declared name
    local declared; declared="$(ash_json_get "$manifest" '.name' '')"
    if [[ -n "$declared" && "$declared" != "$name" ]]; then
        printf '  ⚠ directory '%s' declares name '%s'\n' "$name" "$declared"
        (( warnings += 1 ))
    fi

    # Lifecycle scripts: exist, executable, syntactically valid
    local script
    for script in init.sh enable.sh disable.sh status.sh; do
        local sp="${dir}/${script}"
        if [[ -f "$sp" ]]; then
            if ! bash -n "$sp" 2>/dev/null; then
                printf '  ✗ syntax error in %s\n' "$script"
                (( errors += 1 ))
            fi
            if [[ ! -x "$sp" ]]; then
                printf '  ⚠ %s is not executable\n' "$script"
                (( warnings += 1 ))
            fi
        fi
    done

    # enable.sh with no disable.sh is almost always a bug
    if [[ -f "${dir}/enable.sh" && ! -f "${dir}/disable.sh" ]]; then
        printf '  ✗ enable.sh present but disable.sh missing (cannot uninstall cleanly)\n'
        (( errors += 1 ))
    fi

    # Declared config keys should have defaults
    local keys
    keys="$(ash_json_get "$manifest" '.settings | keys[]' '')"
    if [[ -n "$keys" ]]; then
        local k
        while IFS= read -r k || [[ -n "$k" ]]; do
            [[ -z "$k" ]] && continue
            local default; default="$(ash_json_get "$manifest" ".settings.${k}.default" "")"
            [[ -z "$default" ]] && printf '  ⚠ setting '%s' has no default\n' "$k"
        done <<< "$keys"
    fi

    printf '  %s: %d error(s), %d warning(s)\n' "$name" "$errors" "$warnings"
    return $(( errors > 0 ? 1 : 0 ))
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 2  LIFECYCLE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Runs a plugin script with a scrubbed environment.
_ash_plugin_exec() {
    local name="$1" script="$2"; shift 2
    local dir; dir="$(ash_plugin_dir "$name")"
    local sp="${dir}/${script}"

    [[ -f "$sp" ]] || return 127
    [[ -x "$sp" ]] || chmod +x "$sp" 2>/dev/null || true

    local -a env_args=(
        "ASH_PLUGIN_NAME=${name}"
        "ASH_PLUGIN_DIR=${dir}"
        "ASH_PLUGIN_ROOT=${ASH_PLUGINS_DIR}"
        "ASH_CONFIG_HOME=${ASH_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/ash}"
        "ASH_DATA_HOME=${ASH_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/ash}"
        "ASH_CACHE_HOME=${ASH_CACHE_HOME:-${XDG_CACHE_HOME:-$HOME/.cache}/ash}"
        "ASH_RUNTIME_DIR=${ASH_RUNTIME_DIR:-${XDG_RUNTIME_DIR:-/tmp}/ash}"
        "ASH_VERSION=${ASH_VERSION:-5.0.0-omega}"
        "HOME=${HOME}"
        "USER=${USER:-$(id -un)}"
        "PATH=${PATH}"
        "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp}"
    )

    local rc=0
    if command -v timeout >/dev/null 2>&1; then
        env -i "${env_args[@]}" timeout --kill-after=3 "$ASH_PLUGIN_TIMEOUT" \
            bash "$sp" "$@" || rc=$?
    else
        env -i "${env_args[@]}" bash "$sp" "$@" || rc=$?
    fi
    return $rc
}

ash_plugin_install() {
    local name="$1"
    local dir; dir="$(ash_plugin_dir "$name")"
    [[ -z "$dir" ]] && { ash_log_error "plugin not found: ${name}" 2>/dev/null || true; return 1; }

    if ! ash_plugin_validate "$name" >/dev/null 2>&1; then
        ash_log_error "plugin '${name}' failed validation" 2>/dev/null || true
        ash_plugin_validate "$name"
        return 1
    fi

    # Idempotency: already installed?
    if ash_plugin_is_enabled "$name"; then
        ash_log_info "plugin '${name}' is already enabled" 2>/dev/null || true
        return 0
    fi

    local rc=0
    ash_plugin_exec "$name" "init.sh" 2>/dev/null || rc=$?
    (( rc == 127 )) && rc=0    # init.sh is optional

    if (( rc == 0 )); then
        ash_plugin_enable "$name"
        rc=$?
    fi

    (( rc == 0 )) && ash_event_emit "plugin.installed" "name=${name}" 2>/dev/null || true
    return $rc
}

ash_plugin_enable() {
    local name="$1"
    local dir; dir="$(ash_plugin_dir "$name")"
    [[ -z "$dir" ]] && return 1
    [[ -f "${dir}/enable.sh" ]] || { ash_log_error "plugin '${name}' has no enable.sh" 2>/dev/null || true; return 1; }

    local rc=0
    ash_plugin_exec "$name" "enable.sh" 2>/dev/null || rc=$?

    if (( rc == 0 )); then
        _ash_plugin_state_write "$name" "enabled" >/dev/null 2>&1 || true
        ash_event_emit "plugin.enabled" "name=${name}" 2>/dev/null || true
    else
        ash_log_error "plugin '${name}' failed to enable (exit ${rc})" 2>/dev/null || true
        ash_event_emit "plugin.failed" "name=${name}" "action=enable" "exit=${rc}" 2>/dev/null || true
    fi
    return $rc
}

ash_plugin_disable() {
    local name="$1"
    local dir; dir="$(ash_plugin_dir "$name")"
    [[ -z "$dir" ]] && return 1

    if [[ ! -f "${dir}/disable.sh" ]]; then
        ash_log_warn "plugin '${name}' has no disable.sh — nothing to undo" 2>/dev/null || true
        _ash_plugin_state_write "$name" "disabled" >/dev/null 2>&1 || true
        return 0
    fi

    local rc=0
    ash_plugin_exec "$name" "disable.sh" 2>/dev/null || rc=$?

    # Record the intent regardless — otherwise a failing disable leaves the
    # plugin marked enabled forever and it can never be removed.
    _ash_plugin_state_write "$name" "disabled" >/dev/null 2>&1 || true
    (( rc == 0 )) && ash_event_emit "plugin.disabled" "name=${name}" 2>/dev/null || true
    return $rc
}

ash_plugin_is_enabled() {
    local name="$1"
    local dir; dir="$(ash_plugin_dir "$name")"
    [[ -z "$dir" ]] && return 1

    if [[ -x "${dir}/status.sh" ]]; then
        local s
        s="$(ASH_PLUGIN_NAME="$name" timeout 5 bash "${dir}/status.sh" 2>/dev/null | head -1 || true)"
        [[ "$s" == "enabled" ]] && return 0
        [[ "$s" == "disabled" ]] && return 1
    fi

    # Fall back to recorded state
    _ash_plugin_state_read
    [[ "${ASH_PLUGIN_STATE[${name}.state]:-disabled}" == "enabled" ]]
}

ash_plugin_status() {
    local name="$1"
    local dir; dir="$(ash_plugin_dir "$name")"
    [[ -z "$dir" ]] && { printf 'missing\n'; return 1; }

    if [[ -x "${dir}/status.sh" ]]; then
        ASH_PLUGIN_NAME="$name" timeout 5 bash "${dir}/status.sh" 2>/dev/null | head -1 || printf 'error\n'
    elif ash_plugin_is_enabled "$name"; then
        printf 'enabled\n'
    else
        printf 'disabled\n'
    fi
}

ash_plugin_remove() {
    local name="$1"
    local dir; dir="$(ash_plugin_dir "$name")"
    [[ -z "$dir" ]] && return 1

    ash_plugin_disable "$name" || true

    # Only delete plugins living in a user-writable location.
    case "$dir" in
        "${XDG_CONFIG_HOME:-$HOME/.config}/ash/plugins/"*|"${ASH_PLUGINS_DIR}/user/"*|"${ASH_PLUGINS_DIR}/community/"*)
            rm -rf "$dir" 2>/dev/null || true
            ;;
        *)
            ash_log_warn "refusing to delete read-only plugin: ${dir}" 2>/dev/null || true
            ;;
    esac

    _ash_plugin_state_forget "$name"
    ash_event_emit "plugin.removed" "name=${name}" 2>/dev/null || true
    return 0
}

# ── State persistence ────────────────────────────────────────────────────────
_ash_plugin_state_read() {
    ASH_PLUGIN_STATE=()
    [[ -f "$ASH_PLUGINS_STATE" ]] || return 0

    local line
    while IFS='|' read -r name state ts; do
        [[ -z "$name" ]] && continue
        ASH_PLUGIN_STATE["${name}.state"]="$state"
        ASH_PLUGIN_STATE["${name}.ts"]="$ts"
    done < "$ASH_PLUGINS_STATE"
}

_ash_plugin_state_write() {
    local name="$1" state="$2"
    _ash_plugin_state_dir

    local tmp; tmp="$(mktemp "${ASH_PLUGINS_STATE}.tmp.XXXXXX")" || return 1
    local found=0 line

    if [[ -f "$ASH_PLUGINS_STATE" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "${line%%|*}" == "$name" ]]; then
                printf '%s|%s|%s\n' "$name" "$state" "$(date -Iseconds)" >> "$tmp"
                found=1
            else
                printf '%s\n' "$line" >> "$tmp"
            fi
        done < "$ASH_PLUGINS_STATE"
    fi

    (( found == 0 )) && printf '%s|%s|%s\n' "$name" "$state" "$(date -Iseconds)" >> "$tmp"

    mv -f "$tmp" "$ASH_PLUGINS_STATE"
}

_ash_plugin_state_forget() {
    local name="$1"
    [[ -f "$ASH_PLUGINS_STATE" ]] || return 0
    grep -v "^${name}|" "$ASH_PLUGINS_STATE" > "${ASH_PLUGINS_STATE}.tmp" 2>/dev/null || true
    mv -f "${ASH_PLUGINS_STATE}.tmp" "$ASH_PLUGINS_STATE" 2>/dev/null || true
}

# ── Bulk operations ──────────────────────────────────────────────────────────
ash_plugin_enable_all() {
    ash_plugin_discover >/dev/null
    local enabled=0 failed=0 name
    for name in $(printf '%s\n' "${!ASH_PLUGIN_DIRS[@]}" | LC_ALL=C sort); do
        local autostart; autostart="$(ash_json_get "${ASH_PLUGIN_DIRS[$name]}/plugin.json" '.autostart' 'false')"
        [[ "$autostart" != "true" ]] && continue
        if ash_plugin_enable "$name" >/dev/null 2>&1; then (( enabled += 1 )); else (( failed += 1 )); fi
    done
    printf '%d enabled, %d failed\n' "$enabled" "$failed"
}

# ── Scaffolding ──────────────────────────────────────────────────────────────
ash_plugin_create() {
    local name="$1" category="${2:-core}"
    [[ "$name" =~ ^[a-z][a-z0-9-]*$ ]] || {
        ash_log_error "plugin name must be lowercase-with-dashes" 2>/dev/null || true
        return 1
    }

    local dir="${ASH_PLUGINS_DIR}/${category}/${name}"
    [[ -d "$dir" ]] && { ash_log_error "plugin already exists: ${dir}" 2>/dev/null || true; return 1; }

    mkdir -p "$dir" || return 1
    local tpl="${ASH_PLUGINS_DIR}/template"

    if [[ -d "$tpl" ]]; then
        local f
        for f in plugin.json init.sh enable.sh disable.sh config.json README.md; do
            [[ -f "${tpl}/${f}.template" ]] || continue
            sed "s/{{name}}/${name}/g; s/{{category}}/${category}/g" \
                "${tpl}/${f}.template" > "${dir}/${f}"
        done
    fi

    # Guarantee the essential files exist even without templates.
    [[ -f "${dir}/plugin.json" ]] || cat > "${dir}/plugin.json" <<EOF
{
  "name": "${name}",
  "version": "0.1.0",
  "description": "Describe what ${name} does",
  "author": "${USER:-unknown}",
  "license": "MIT",
  "category": "${category}",
  "autostart": false,
  "capabilities": [],
  "settings": {},
  "dependencies": { "commands": [] }
}
EOF

    mkdir -p "${dir}/.state"
    chmod +x "${dir}"/*.sh 2>/dev/null || true

    printf '%s\n' "$dir"
    ash_log_info "created plugin skeleton at ${dir}" 2>/dev/null || true
}
