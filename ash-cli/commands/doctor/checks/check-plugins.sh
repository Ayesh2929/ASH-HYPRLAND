#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██████╗ ██╗     ██╗   ██╗ ██████╗ ██╗███╗   ██╗███████╗                        ║
# ║  ██╔══██╗██║     ██║   ██║██╔════╝ ██║████╗  ██║██╔════╝                        ║
# ║  ██████╔╝██║     ██║   ██║██║  ███╗██║██╔██╗ ██║███████╗                        ║
# ║  ██╔═══╝ ██║     ██║   ██║██║   ██║██║██║╚██╗██║╚════██║                        ║
# ║  ██║     ███████╗╚██████╔╝╚██████╔╝██║██║ ╚████║███████║                        ║
# ║  ╚═╝     ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝  ╚═══╝╚══════╝                        ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  DOCTOR CHECK: ASH PLUGINS                               ║
# ║  Plugin registry • lifecycle • hooks • integrity • dependencies                 ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CHECK_PLUGINS_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CHECK_PLUGINS_LOADED=1

# Sourced as a library by _common.sh, so shell options are only
# tightened when this file is EXECUTED directly. A sourced file that
# sets -e/-u rewrites the options of whoever loaded it — the first
# module would make the whole doctor process abort on any non-zero
# status or unset variable.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
fi
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _PL_ROOT="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}/plugins"
declare -gr _PL_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/ash/plugins"
declare -gr _PL_CFG="${XDG_CONFIG_HOME:-$HOME/.config}/ash/plugins"
declare -gr _PL_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/ash/plugins"

# Required fields in a valid plugin.json
declare -ga _PL_REQUIRED_FIELDS=( "id" "name" "version" "author" "description" "ash_version" )

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PLUGIN MANIFEST VALIDATOR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_validate_plugin_manifest() {
    local plugin_dir="$1"
    local manifest="${plugin_dir}/plugin.json"
    local plugin_name
    plugin_name="$(basename "$plugin_dir")"

    local manifest_errors=0
    local manifest_warnings=0

    # ── JSON validity ────────────────────────────────────────────────────────────
    if ! command -v python3 &>/dev/null; then
        _check_report $CHECK_SKIP \
            "  Plugin: ${plugin_name}" \
            "python3 unavailable — skipping manifest validation"
        return $CHECK_SKIP
    fi

    if ! python3 -c "import json; json.load(open('${manifest}'))" &>/dev/null 2>&1; then
        _check_report $CHECK_FAIL \
            "  Plugin: ${plugin_name}" \
            "plugin.json: INVALID JSON" \
            "Fix: python3 -m json.tool '${manifest}'"
        return $CHECK_FAIL
    fi

    # ── Required fields ───────────────────────────────────────────────────────────
    for field in "${_PL_REQUIRED_FIELDS[@]}"; do
        local val
        val="$(python3 -c \
            "import json; d=json.load(open('${manifest}')); \
             print(d.get('${field}','__MISSING__'))" 2>/dev/null || echo '__MISSING__')"

        if [[ "$val" == "__MISSING__" ]] || [[ -z "$val" ]]; then
            _check_report $CHECK_WARN \
                "    └─ Missing field: ${field}" \
                "plugin.json must define '${field}'"
            (( manifest_warnings++ )) || true
        fi
    done

    # ── Required script files ─────────────────────────────────────────────────────
    local -a required_scripts=( "init.sh" )
    local -a optional_scripts=( "enable.sh" "disable.sh" "status.sh" "config.json" )

    for sc in "${required_scripts[@]}"; do
        if [[ ! -f "${plugin_dir}/${sc}" ]]; then
            _check_report $CHECK_FAIL \
                "    └─ Missing: ${sc}" \
                "Required plugin script not found"
            (( manifest_errors++ )) || true
        else
            if ! bash -n "${plugin_dir}/${sc}" 2>/dev/null; then
                _check_report $CHECK_FAIL \
                    "    └─ Syntax error: ${sc}" \
                    "Script has bash syntax errors" \
                    "Fix: bash -n '${plugin_dir}/${sc}'"
                (( manifest_errors++ )) || true
            fi
        fi
    done

    for sc in "${optional_scripts[@]}"; do
        if [[ -f "${plugin_dir}/${sc}" ]]; then
            if [[ "$sc" == *.sh ]] && ! bash -n "${plugin_dir}/${sc}" 2>/dev/null; then
                _check_report $CHECK_WARN \
                    "    └─ Syntax error: ${sc}" \
                    "Optional script has syntax errors"
                (( manifest_warnings++ )) || true
            fi
        fi
    done

    # ── Plugin ID matches directory name ─────────────────────────────────────────
    local declared_id
    declared_id="$(python3 -c \
        "import json; d=json.load(open('${manifest}')); print(d.get('id',''))" \
        2>/dev/null || echo '')"

    if [[ -n "$declared_id" ]] && [[ "$declared_id" != "$plugin_name" ]]; then
        _check_report $CHECK_WARN \
            "    └─ ID mismatch" \
            "plugin.json id='${declared_id}' but dir='${plugin_name}'"
        (( manifest_warnings++ )) || true
    fi

    # ── ASH version compatibility ─────────────────────────────────────────────────
    local req_ash_ver
    req_ash_ver="$(python3 -c \
        "import json; d=json.load(open('${manifest}')); print(d.get('ash_version','0.0.0'))" \
        2>/dev/null || echo '0.0.0')"

    local current_ash_ver="${ASH_VERSION:-5.0.0}"
    local req_major="${req_ash_ver%%.*}"
    local cur_major="${current_ash_ver%%.*}"

    if [[ "$req_major" =~ ^[0-9]+$ ]] && [[ "$cur_major" =~ ^[0-9]+$ ]]; then
        if (( req_major > cur_major )); then
            _check_report $CHECK_WARN \
                "    └─ Version compat" \
                "Plugin requires ASH v${req_ash_ver}, you have v${current_ash_ver}" \
                "Update ASH: ash update dotfiles"
            (( manifest_warnings++ )) || true
        fi
    fi

    # ── Summary for this plugin ───────────────────────────────────────────────────
    if (( manifest_errors > 0 )); then
        _check_report $CHECK_FAIL \
            "  Plugin: ${plugin_name}" \
            "${manifest_errors} error(s)  •  ${manifest_warnings} warning(s)"
        return $CHECK_FAIL
    elif (( manifest_warnings > 0 )); then
        local plugin_ver
        plugin_ver="$(python3 -c \
            "import json; d=json.load(open('${manifest}')); print(d.get('version','?'))" \
            2>/dev/null || echo '?')"
        _check_report $CHECK_WARN \
            "  Plugin: ${plugin_name}" \
            "v${plugin_ver}  •  ${manifest_warnings} warning(s)"
        return $CHECK_WARN
    else
        local plugin_ver plugin_desc
        plugin_ver="$(python3 -c \
            "import json; d=json.load(open('${manifest}')); print(d.get('version','?'))" \
            2>/dev/null || echo '?')"
        plugin_desc="$(python3 -c \
            "import json; d=json.load(open('${manifest}')); print(d.get('description','')[:50])" \
            2>/dev/null || echo '')"
        _check_report $CHECK_PASS \
            "  Plugin: ${plugin_name}" \
            "v${plugin_ver}  •  ${plugin_desc}"
        return $CHECK_PASS
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 01 — PLUGIN SYSTEM INFRASTRUCTURE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_plugins_infra() {
    _check_header "🏗️  Plugin System Infrastructure"

    # ── Directories ───────────────────────────────────────────────────────────────
    local -a pl_dirs=(
        "${_PL_ROOT}:ASH plugins root (source)"
        "${_PL_ROOT}/core:Core plugins"
        "${_PL_ROOT}/integrations:Integration plugins"
        "${_PL_ROOT}/community:Community plugins"
        "${_PL_ROOT}/template:Plugin template"
        "${_PL_ROOT}/schema:Plugin schema"
        "${_PL_DATA}:Plugin runtime data"
        "${_PL_CFG}:Plugin user configs"
        "${_PL_CACHE}:Plugin cache"
    )

    for dir_entry in "${pl_dirs[@]}"; do
        IFS=':' read -r dir_path dir_label <<< "$dir_entry"
        if [[ -d "$dir_path" ]]; then
            local item_count
            item_count="$(find "$dir_path" -maxdepth 1 -mindepth 1 2>/dev/null | wc -l)"
            _check_report $CHECK_PASS \
                "$dir_label" \
                "${item_count} item(s)"
        else
            _check_report $CHECK_INFO \
                "$dir_label" \
                "Not created yet: ${dir_path}"
        fi
    done

    # ── Plugin schema ─────────────────────────────────────────────────────────────
    local schema="${_PL_ROOT}/schema/plugin-schema.json"
    if [[ -f "$schema" ]]; then
        if command -v python3 &>/dev/null && \
           python3 -c "import json; json.load(open('${schema}'))" &>/dev/null 2>&1; then
            _check_report $CHECK_PASS \
                "Plugin JSON schema" \
                "Valid JSON  •  ${schema##*/}"
        else
            _check_report $CHECK_FAIL \
                "Plugin JSON schema" \
                "Invalid JSON!" \
                "Fix: python3 -m json.tool '${schema}'"
        fi
    else
        _check_report $CHECK_WARN \
            "Plugin JSON schema" \
            "Missing: ${schema}"
    fi

    # ── Plugin registry file ──────────────────────────────────────────────────────
    local registry="${ASH_CLI_DIR:-$HOME/ash-dotfiles/ash-cli}/data/plugin-registry.json"
    if [[ -f "$registry" ]]; then
        if command -v python3 &>/dev/null; then
            local reg_count
            reg_count="$(python3 -c \
                "import json; d=json.load(open('${registry}')); print(len(d))" \
                2>/dev/null || echo '?')"
            _check_report $CHECK_PASS \
                "Plugin registry" \
                "${reg_count} registered plugin(s)"
        else
            _check_report $CHECK_PASS \
                "Plugin registry" \
                "Present: ${registry}"
        fi
    else
        _check_report $CHECK_INFO \
            "Plugin registry" \
            "Not found: ${registry}  (will be created on first use)"
    fi

    # ── Plugin loader library ─────────────────────────────────────────────────────
    local loader="${ASH_CLI_DIR:-$HOME/ash-dotfiles/ash-cli}/lib/plugin-loader.sh"
    if [[ -f "$loader" ]]; then
        if bash -n "$loader" &>/dev/null; then
            _check_report $CHECK_PASS \
                "Plugin loader library" \
                "Syntax OK  •  ${loader##*/}"
        else
            _check_report $CHECK_FAIL \
                "Plugin loader library" \
                "Syntax error in plugin-loader.sh!" \
                "Fix: bash -n '${loader}'"
        fi
    else
        _check_report $CHECK_WARN \
            "Plugin loader library" \
            "Missing: ${loader}"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 02 — CORE PLUGINS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_plugins_core() {
    _check_header "🔌 Core Plugins  (${_PL_ROOT}/core)"

    local core_dir="${_PL_ROOT}/core"

    if [[ ! -d "$core_dir" ]]; then
        _check_report $CHECK_WARN \
            "Core plugins dir" \
            "Missing: ${core_dir}"
        return $CHECK_WARN
    fi

    # ── Enumerate core plugins ────────────────────────────────────────────────────
    local -a plugin_dirs=()
    mapfile -t plugin_dirs < <(
        find "$core_dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort
    )

    local pl_total=${#plugin_dirs[@]}
    local pl_valid=0 pl_warn=0 pl_fail=0

    _check_report $CHECK_INFO \
        "Core plugin count" \
        "${pl_total} plugin directories found"

    for plugin_dir in "${plugin_dirs[@]}"; do
        [[ -z "$plugin_dir" ]] && continue

        local manifest="${plugin_dir}/plugin.json"

        if [[ ! -f "$manifest" ]]; then
            _check_report $CHECK_WARN \
                "  Dir: $(basename "$plugin_dir")" \
                "No plugin.json  (incomplete plugin)"
            (( pl_warn++ )) || true
            continue
        fi

        local validate_result
        _validate_plugin_manifest "$plugin_dir"
        validate_result=$?

        case $validate_result in
            $CHECK_PASS) (( pl_valid++ )) || true ;;
            $CHECK_WARN) (( pl_warn++ ))  || true ;;
            $CHECK_FAIL) (( pl_fail++ ))  || true ;;
        esac
    done

    # ── Core plugin summary ───────────────────────────────────────────────────────
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n  \033[38;2;108;112;134m'
        printf '  Core plugin validation: '
        printf '\033[38;2;166;227;161m✓ %d valid\033[38;2;108;112;134m  •  ' "$pl_valid"
        printf '\033[38;2;249;226;175m▲ %d warn\033[38;2;108;112;134m  •  '  "$pl_warn"
        printf '\033[38;2;243;139;168m✗ %d fail\033[0m\n\n'                  "$pl_fail"
    else
        printf '\n  Core: %d valid  •  %d warn  •  %d fail\n\n' \
            "$pl_valid" "$pl_warn" "$pl_fail"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 03 — INTEGRATION PLUGINS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_plugins_integrations() {
    _check_header "🔗 Integration Plugins"

    local int_dir="${_PL_ROOT}/integrations"

    if [[ ! -d "$int_dir" ]]; then
        _check_report $CHECK_INFO \
            "Integrations dir" \
            "Not found: ${int_dir}"
        return $CHECK_PASS
    fi

    # Known integrations with their binary dependency
    # Format: "plugin_name:required_binary:description"
    local -a known_integrations=(
        "discord-rpc:discord:Discord Rich Presence"
        "spotify-control:spotify:Spotify integration"
        "github-status:gh:GitHub status"
        "home-assistant:ha:Home Assistant"
        "philips-hue:hue:Philips Hue lights"
        "stream-deck:streamdeck:Elgato Stream Deck"
        "obs-control:obs:OBS Studio control"
        "slack-status:slack:Slack status sync"
        "todoist-sync:todoist:Todoist task sync"
        "notion-sync:notion:Notion page sync"
        "cryptocurrency:curl:Crypto price ticker"
    )

    for int_entry in "${known_integrations[@]}"; do
        IFS=':' read -r plugin_id req_binary description <<< "$int_entry"
        local plugin_path="${int_dir}/${plugin_id}"

        if [[ -d "$plugin_path" ]]; then
            local bin_ok=0
            command -v "$req_binary" &>/dev/null && bin_ok=1

            if [[ $bin_ok -eq 1 ]]; then
                _check_report $CHECK_PASS \
                    "Integration: ${description}" \
                    "Plugin present  •  ${req_binary} ✓"
                _validate_plugin_manifest "$plugin_path" &>/dev/null || true
            else
                _check_report $CHECK_WARN \
                    "Integration: ${description}" \
                    "Plugin present but '${req_binary}' not installed" \
                    "Install dependency: paru -S ${req_binary}"
            fi
        else
            _check_report $CHECK_INFO \
                "Integration: ${description}" \
                "Not installed  •  requires: ${req_binary}" \
                "Install: ash plugin install ${plugin_id}"
        fi
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 04 — ENABLED/DISABLED PLUGIN STATES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_plugins_states() {
    _check_header "🔄 Plugin Runtime States"

    # ── Plugin state file ─────────────────────────────────────────────────────────
    local state_file="${XDG_DATA_HOME:-$HOME/.local/share}/ash/state/plugin-states.json"

    if [[ ! -f "$state_file" ]]; then
        _check_report $CHECK_INFO \
            "Plugin states file" \
            "Not found  (no plugins activated yet)"
        return $CHECK_PASS
    fi

    if ! command -v python3 &>/dev/null; then
        _check_report $CHECK_INFO \
            "Plugin states file" \
            "Found but python3 unavailable for parsing"
        return $CHECK_PASS
    fi

    local enabled_count disabled_count error_count

    enabled_count="$(  python3 -c \
        "import json; d=json.load(open('${state_file}')); \
         print(sum(1 for v in d.values() if v.get('enabled',False)))" \
        2>/dev/null || echo 0)"

    disabled_count="$( python3 -c \
        "import json; d=json.load(open('${state_file}')); \
         print(sum(1 for v in d.values() if not v.get('enabled',True)))" \
        2>/dev/null || echo 0)"

    error_count="$(    python3 -c \
        "import json; d=json.load(open('${state_file}')); \
         print(sum(1 for v in d.values() if v.get('error')))" \
        2>/dev/null || echo 0)"

    _check_report $CHECK_INFO \
        "Plugin states" \
        "✓ ${enabled_count} enabled  •  ○ ${disabled_count} disabled  •  ✗ ${error_count} error(s)"

    # ── List errored plugins ──────────────────────────────────────────────────────
    if (( error_count > 0 )); then
        local error_plugins
        error_plugins="$(python3 -c \
            "import json; d=json.load(open('${state_file}')); \
             [print(k,':', v.get('error','?')[:60]) \
              for k,v in d.items() if v.get('error')]" \
            2>/dev/null || echo '')"

        while IFS= read -r err_line; do
            [[ -z "$err_line" ]] && continue
            _check_report $CHECK_FAIL \
                "  Plugin error" \
                "$err_line" \
                "Fix: ash plugin reinstall ${err_line%%:*}"
        done <<< "$error_plugins"
    fi

    # ── Enabled plugin dependency check ──────────────────────────────────────────
    local enabled_plugins
    mapfile -t enabled_plugins < <(
        python3 -c \
            "import json; d=json.load(open('${state_file}')); \
             [print(k) for k,v in d.items() if v.get('enabled',False)]" \
            2>/dev/null || true
    )

    if [[ ${#enabled_plugins[@]} -gt 0 ]]; then
        _check_report $CHECK_INFO \
            "Enabled plugins" \
            "${#enabled_plugins[@]} active"

        for pl_id in "${enabled_plugins[@]}"; do
            [[ -z "$pl_id" ]] && continue
            local pl_dir

            # Find in core or integrations
            if [[ -d "${_PL_ROOT}/core/${pl_id}" ]]; then
                pl_dir="${_PL_ROOT}/core/${pl_id}"
            elif [[ -d "${_PL_ROOT}/integrations/${pl_id}" ]]; then
                pl_dir="${_PL_ROOT}/integrations/${pl_id}"
            elif [[ -d "${_PL_DATA}/${pl_id}" ]]; then
                pl_dir="${_PL_DATA}/${pl_id}"
            else
                _check_report $CHECK_WARN \
                    "  ✓ ${pl_id}" \
                    "Enabled but plugin directory not found" \
                    "Reinstall: ash plugin install ${pl_id}"
                continue
            fi

            # Quick manifest read
            local pl_ver
            pl_ver="$(python3 -c \
                "import json; d=json.load(open('${pl_dir}/plugin.json')); \
                 print(d.get('version','?'))" \
                2>/dev/null || echo '?')"

            _check_report $CHECK_PASS \
                "  ✓ ${pl_id}" \
                "v${pl_ver}  •  enabled"
        done
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 05 — HOOK RUNNER VALIDATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_plugins_hooks() {
    _check_header "🪝 Plugin Hook System"

    local hooks_dir="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}/scripts/hooks"

    if [[ ! -d "$hooks_dir" ]]; then
        _check_report $CHECK_WARN \
            "Hooks directory" \
            "Missing: ${hooks_dir}"
        return $CHECK_WARN
    fi

    # Count and validate hook scripts
    local hook_count valid_hooks broken_hooks
    hook_count="$(  find "$hooks_dir" -name '*.sh' | wc -l)"
    valid_hooks=0
    broken_hooks=0

    while IFS= read -r hook_script; do
        [[ -z "$hook_script" ]] && continue
        if bash -n "$hook_script" &>/dev/null; then
            (( valid_hooks++ )) || true
        else
            local hook_name
            hook_name="$(basename "$hook_script")"
            _check_report $CHECK_FAIL \
                "Hook syntax: ${hook_name}" \
                "Bash syntax error" \
                "Fix: bash -n '${hook_script}'"
            (( broken_hooks++ )) || true
        fi
    done < <(find "$hooks_dir" -name '*.sh' 2>/dev/null)

    if (( broken_hooks == 0 )); then
        _check_report $CHECK_PASS \
            "Hook scripts" \
            "${hook_count} hook(s)  •  all syntax OK"
    else
        _check_report $CHECK_WARN \
            "Hook scripts" \
            "${hook_count} total  •  ${broken_hooks} with syntax errors"
    fi

    # ── Hook runner library ────────────────────────────────────────────────────────
    local hook_runner="${ASH_CLI_DIR:-$HOME/ash-dotfiles/ash-cli}/lib/hook-runner.sh"
    if [[ -f "$hook_runner" ]]; then
        if bash -n "$hook_runner" &>/dev/null; then
            _check_report $CHECK_PASS \
                "hook-runner.sh" \
                "Syntax OK"
        else
            _check_report $CHECK_FAIL \
                "hook-runner.sh" \
                "Syntax error!" \
                "Fix: bash -n '${hook_runner}'"
        fi
    else
        _check_report $CHECK_WARN \
            "hook-runner.sh" \
            "Missing: ${hook_runner}"
    fi

    # ── systemd plugin daemon ─────────────────────────────────────────────────────
    if command -v systemctl &>/dev/null; then
        local daemon_state
        daemon_state="$(systemctl --user is-active ash-plugin-daemon 2>/dev/null || echo 'inactive')"
        if [[ "$daemon_state" == "active" ]]; then
            _check_report $CHECK_PASS \
                "ash-plugin-daemon" \
                "Running  (plugin hooks processed in background)"
        else
            _check_report $CHECK_INFO \
                "ash-plugin-daemon" \
                "Not running  (${daemon_state})" \
                "Enable: systemctl --user enable --now ash-plugin-daemon"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 06 — PLUGIN TEMPLATE VALIDITY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_plugins_template() {
    _check_header "📐 Plugin Development Template"

    local tpl_dir="${_PL_ROOT}/template"

    if [[ ! -d "$tpl_dir" ]]; then
        _check_report $CHECK_WARN \
            "Plugin template dir" \
            "Missing: ${tpl_dir}" \
            "Restore from git"
        return $CHECK_WARN
    fi

    local -a template_files=(
        "plugin.json.template:Plugin manifest template"
        "init.sh.template:Initialization script template"
        "enable.sh.template:Enable script template"
        "disable.sh.template:Disable script template"
        "config.json.template:Default config template"
        "README.md.template:Documentation template"
    )

    local tpl_ok=0 tpl_missing=0

    for tpl_entry in "${template_files[@]}"; do
        IFS=':' read -r tpl_file tpl_desc <<< "$tpl_entry"
        local tpl_path="${tpl_dir}/${tpl_file}"

        if [[ -f "$tpl_path" ]]; then
            local tpl_lines
            tpl_lines="$(wc -l < "$tpl_path" 2>/dev/null || echo 0)"
            _check_report $CHECK_PASS \
                "${tpl_file}" \
                "${tpl_lines} lines  — ${tpl_desc}"
            (( tpl_ok++ )) || true
        else
            _check_report $CHECK_WARN \
                "${tpl_file}" \
                "Missing  — ${tpl_desc}"
            (( tpl_missing++ )) || true
        fi
    done

    if (( tpl_missing == 0 )); then
        _check_report $CHECK_PASS \
            "Template completeness" \
            "All ${tpl_ok} template files present"
    else
        _check_report $CHECK_WARN \
            "Template completeness" \
            "${tpl_missing} template(s) missing"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_check_plugins() {
    local mode="${1:-full}"

    _CHECK_PASS_COUNT=0;  _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0;  _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=();   _CHECK_WARNINGS=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;250;179;135m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🔌  ASH DOCTOR — PLUGINS CHECK                          ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  infra • core • integrations • states • hooks • template ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n=== ASH DOCTOR — PLUGINS CHECK ===\n'
    fi

    case "$mode" in
        quick)
            _chk_plugins_infra
            _chk_plugins_states
            ;;
        core)         _chk_plugins_core          ;;
        integrations) _chk_plugins_integrations  ;;
        states)       _chk_plugins_states        ;;
        hooks)        _chk_plugins_hooks         ;;
        full|*)
            _chk_plugins_infra
            _chk_plugins_core
            _chk_plugins_integrations
            _chk_plugins_states
            _chk_plugins_hooks
            _chk_plugins_template
            ;;
    esac

    _ash_check_system_summary
}

ash_check_plugins_quick() {
    local issues=0
    [[ -d "${_PL_ROOT}/core" ]]              || (( issues++ )) || true
    [[ -f "${_PL_ROOT}/schema/plugin-schema.json" ]] || (( issues++ )) || true
    if (( issues == 0 )); then
        ash_log_success "Plugins: OK  (core dir and schema present)"
    else
        ash_log_warn "Plugins: ${issues} issue(s) — run 'ash doctor full --plugins'"
        return 1
    fi
}
