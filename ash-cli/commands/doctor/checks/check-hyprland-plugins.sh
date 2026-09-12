#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║   ██╗  ██╗██╗   ██╗██████╗ ██████╗     ██████╗ ██╗     ██╗   ██╗ ██████╗       ║
# ║   ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗    ██╔══██╗██║     ██║   ██║██╔════╝       ║
# ║   ███████║ ╚████╔╝ ██████╔╝██████╔╝    ██████╔╝██║     ██║   ██║██║  ███╗      ║
# ║   ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗    ██╔═══╝ ██║     ██║   ██║██║   ██║      ║
# ║   ██║  ██║   ██║   ██║     ██║  ██║    ██║     ███████╗╚██████╔╝╚██████╔╝      ║
# ║   ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝    ╚═╝     ╚══════╝ ╚═════╝  ╚═════╝       ║
# ║                                                                                  ║
# ║   ██████╗ ██╗      ██████╗  ██████╗ ██╗███╗   ██╗███████╗                      ║
# ║   ██╔══██╗██║     ██╔═══██╗██╔════╝ ██║████╗  ██║██╔════╝                      ║
# ║   ██████╔╝██║     ██║   ██║██║  ███╗██║██╔██╗ ██║███████╗                      ║
# ║   ██╔═══╝ ██║     ██║   ██║██║   ██║██║██║╚██╗██║╚════██║                      ║
# ║   ██║     ███████╗╚██████╔╝╚██████╔╝██║██║ ╚████║███████║                      ║
# ║   ╚═╝     ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝  ╚═══╝╚══════╝                      ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  —  DOCTOR CHECK: HYPRLAND PLUGINS                         ║
# ║  Deep plugin ecosystem diagnostic, compatibility matrix, ABI verification       ║
# ║                                                                                  ║
# ║  Author    : ash-dotfiles                                                        ║
# ║  License   : MIT                                                                 ║
# ║  Category  : doctor/checks                                                      ║
# ║  Called by : commands/doctor/doctor.sh                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

# ── Guard: prevent double-sourcing ─────────────────────────────────────────────────
[[ "${_ASH_CHECK_HYPRLAND_PLUGINS_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CHECK_HYPRLAND_PLUGINS_LOADED=1

# ── Strict mode ────────────────────────────────────────────────────────────────────
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
# 🔷  KNOWN PLUGIN REGISTRY
#     Every supported Hyprland plugin with metadata for deep validation
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Schema: "PLUGIN_ID|display_name|repo|so_name_pattern|critical|description|conflicts"
declare -gA _PLUGIN_REGISTRY

_plugin_registry_init() {
    # ── Layout / Tiling ─────────────────────────────────────────────────────────
    _PLUGIN_REGISTRY[hy3]="hy3|hy3 (i3-style tiling)|hyprwm/hy3|hy3.so|0|i3-inspired manual tiling layout|hyprscroller"
    _PLUGIN_REGISTRY[hyprscroller]="hyprscroller|Hyprscroller|dawsers/hyprscroller|hyprscroller.so|0|Scrollable tiling layout|hy3"
    _PLUGIN_REGISTRY[hyprtasking]="hyprtasking|Hyprtasking|raybbian/hyprtasking|hyprtasking.so|0|Task overview and switching|"

    # ── Visuals / Effects ───────────────────────────────────────────────────────
    _PLUGIN_REGISTRY[hyprexpo]="hyprexpo|Hyprexpo|hyprwm/hyprland-plugins|hyprexpo.so|0|Expose-style workspace overview|"
    _PLUGIN_REGISTRY[hyprspace]="hyprspace|Hyprspace|KZDKM/Hyprspace|hyprspace.so|0|macOS Spaces-like overview|"
    _PLUGIN_REGISTRY[hyprfocus]="hyprfocus|Hyprfocus|pyt0xic3/hyprfocus|hyprfocus.so|0|Focus animation effects|"
    _PLUGIN_REGISTRY[hyprbars]="hyprbars|Hyprbars|hyprwm/hyprland-plugins|hyprbars.so|0|Window title bars|"
    _PLUGIN_REGISTRY[hyprwinwrap]="hyprwinwrap|HyprWinWrap|hyprwm/hyprland-plugins|hyprwinwrap.so|0|Animated wallpaper via window|"
    _PLUGIN_REGISTRY[hyprtrails]="hyprtrails|Hyprtrails|hyprwm/hyprland-plugins|hyprtrails.so|0|Window movement trails|"
    _PLUGIN_REGISTRY[hyprNStack]="hyprnstack|HyprNStack|hyprwm/hyprland-plugins|hyprNStack.so|0|N-stack tiling layout|hy3 hyprscroller"
    _PLUGIN_REGISTRY[hyprfloat]="hyprfloat|Hyprfloat|ClaytonTDM/hyprfloat|hyprfloat.so|0|Enhanced float rules|"
    _PLUGIN_REGISTRY[hyprgd]="hyprGD|HyprGD (grid)|hyprwm/hyprland-plugins|hyprGD.so|0|Grid layout plugin|hy3 hyprscroller"

    # ── Cursor / Input ──────────────────────────────────────────────────────────
    _PLUGIN_REGISTRY[hyprland-easymotion]="hyprland-easymotion|Easy Motion|zakk4223/hyprland-easymotion|easymotion.so|0|Vim-easymotion-style window focus|"
    _PLUGIN_REGISTRY[hyprland-touch-gestures]="hyprland-touch-gestures|Touch Gestures|horriblename/hyprland-touch-gestures|touch_gestures.so|0|Touch/trackpad gestures|"
    _PLUGIN_REGISTRY[hy3-smart-gaps]="hy3-smart-gaps|Smart Gaps||smart_gaps.so|0|Smart gap adjustment|"

    # ── Utility ─────────────────────────────────────────────────────────────────
    _PLUGIN_REGISTRY[hyprland-plugins]="hyprland-plugins|Official Plugin Bundle|hyprwm/hyprland-plugins|*.so|0|Official Hyprland plugin collection|"
    _PLUGIN_REGISTRY[hyprsplit]="hyprsplit|Hyprsplit|shezdy/hyprsplit|hyprsplit.so|0|Split containers|hy3"
    _PLUGIN_REGISTRY[hyprpm]="hyprpm|hyprpm (built-in)|hyprwm/hyprland|hyprpm|1|Official Hyprland plugin manager|"
    _PLUGIN_REGISTRY[hyprland-virtual-desktops]="hyprland-virtual-desktops|Virtual Desktops|levnikolaev/hyprland-virtual-desktops|virtual-desktops.so|0|Named virtual desktops|"
    _PLUGIN_REGISTRY[hypr-darkwindow]="hypr-darkwindow|Dark Window|micha4w/hypr-darkwindow|darkwindow.so|0|Per-window dark mode inversion|"
    _PLUGIN_REGISTRY[hypr-dynamic-cursors]="hypr-dynamic-cursors|Dynamic Cursors|VirtCode/hypr-dynamic-cursors|hypr-dynamic-cursors.so|0|Physics-based animated cursor|"
    _PLUGIN_REGISTRY[Hyprload]="hyprload|Hyprload (legacy)|duckonaut/hyprload|hyprload.so|0|Legacy plugin loader (use hyprpm instead)|hyprpm"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 01 — HYPRPM HEALTH
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_plugins_hyprpm() {
    _check_header "🔧 Plugin Manager (hyprpm)"

    # ── Binary presence ─────────────────────────────────────────────────────────
    if ! command -v hyprpm &>/dev/null; then
        _check_report $CHECK_FAIL \
            "hyprpm binary" \
            "Not found in PATH" \
            "Should ship with Hyprland ≥ 0.36.0 — reinstall: paru -S hyprland"
        return $CHECK_FAIL
    fi

    local hyprpm_path
    hyprpm_path="$(command -v hyprpm)"
    local hyprpm_ver
    hyprpm_ver="$(hyprpm --version 2>/dev/null | grep -oP 'v?[\d.]+' | head -1 \
                  || echo 'unknown')"
    _check_report $CHECK_PASS \
        "hyprpm binary" \
        "${hyprpm_ver}  (${hyprpm_path})"

    # ── Global plugin directory ─────────────────────────────────────────────────
    local plugin_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/hyprpm"
    if [[ -d "$plugin_data_dir" ]]; then
        local plugin_so_count
        plugin_so_count="$(find "$plugin_data_dir" -name '*.so' 2>/dev/null | wc -l)"
        _check_report $CHECK_PASS \
            "Plugin data dir" \
            "${plugin_data_dir}  (${plugin_so_count} .so files)"
    else
        _check_report $CHECK_INFO \
            "Plugin data dir" \
            "Not yet created — run: hyprpm update" \
            "Will be created on first plugin install"
    fi

    # ── Hyprland headers cached? ────────────────────────────────────────────────
    local headers_dir="${XDG_CACHE_HOME:-$HOME/.cache}/hyprpm/hyprland-source"
    if [[ -d "$headers_dir" ]]; then
        local headers_age_days
        headers_age_days="$(( ( $(date +%s) - $(stat -c '%Y' "$headers_dir" 2>/dev/null || echo 0) ) / 86400 ))"
        if (( headers_age_days <= 7 )); then
            _check_report $CHECK_PASS \
                "Hyprland headers cache" \
                "${headers_dir}  (${headers_age_days}d old)"
        else
            _check_report $CHECK_WARN \
                "Hyprland headers cache" \
                "Stale (${headers_age_days} days old)" \
                "Refresh with: hyprpm update"
        fi
    else
        _check_report $CHECK_INFO \
            "Hyprland headers cache" \
            "Not cached — will be fetched on first install"
    fi

    # ── hyprpm update available? ────────────────────────────────────────────────
    if hyprpm update --dry-run &>/dev/null 2>&1; then
        _check_report $CHECK_INFO \
            "hyprpm update status" \
            "Updates may be available — run: hyprpm update"
    else
        _check_report $CHECK_PASS \
            "hyprpm update status" \
            "Plugins appear up to date"
    fi

    # ── Build deps for plugin compilation ──────────────────────────────────────
    local -a build_deps=( "cmake" "make" "gcc" "g++" "git" "meson" "ninja" )
    local missing_deps=()

    for dep in "${build_deps[@]}"; do
        command -v "$dep" &>/dev/null || missing_deps+=("$dep")
    done

    if [[ ${#missing_deps[@]} -eq 0 ]]; then
        _check_report $CHECK_PASS \
            "Build dependencies" \
            "All present (cmake make gcc git meson ninja)"
    else
        _check_report $CHECK_WARN \
            "Build dependencies" \
            "Missing: ${missing_deps[*]}" \
            "Install: paru -S ${missing_deps[*]}"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 02 — ACTIVE PLUGIN RUNTIME STATE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_plugins_runtime() {
    _check_header "🟢 Active Plugin Runtime"

    # ── Hyprland must be running for runtime checks ─────────────────────────────
    if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        _check_report $CHECK_SKIP \
            "Runtime check" \
            "Skipped — Hyprland not running in this session"
        return $CHECK_SKIP
    fi

    if ! command -v hyprctl &>/dev/null; then
        _check_report $CHECK_FAIL \
            "hyprctl" \
            "Not found — cannot query runtime plugin state"
        return $CHECK_FAIL
    fi

    # ── Fetch active plugins via IPC ────────────────────────────────────────────
    local plugins_json
    plugins_json="$(hyprctl plugins list -j 2>/dev/null || echo '[]')"

    # Validate JSON
    if ! printf '%s' "$plugins_json" | python3 -c 'import sys,json; json.load(sys.stdin)' \
         &>/dev/null 2>&1; then
        _check_report $CHECK_FAIL \
            "Plugin IPC response" \
            "Invalid JSON from hyprctl — possible IPC corruption" \
            "Restart Hyprland: hyprctl reload"
        return $CHECK_FAIL
    fi

    # ── Count loaded plugins ────────────────────────────────────────────────────
    local plugin_count
    plugin_count="$(printf '%s' "$plugins_json" | \
                    python3 -c 'import sys,json; d=json.load(sys.stdin); print(len(d))' \
                    2>/dev/null || echo 0)"

    if (( plugin_count == 0 )); then
        _check_report $CHECK_INFO \
            "Loaded plugins" \
            "None active — install with: ash plugin install <name>"
        return $CHECK_PASS
    fi

    _check_report $CHECK_PASS \
        "Loaded plugins" \
        "${plugin_count} plugin(s) active"

    # ── Per-plugin validation ───────────────────────────────────────────────────
    local plugin_names plugin_paths plugin_versions
    plugin_names="$(  printf '%s' "$plugins_json" | \
                      python3 -c 'import sys,json; [print(p.get("name","?"))       for p in json.load(sys.stdin)]' 2>/dev/null)"
    plugin_paths="$(  printf '%s' "$plugins_json" | \
                      python3 -c 'import sys,json; [print(p.get("path","?"))       for p in json.load(sys.stdin)]' 2>/dev/null)"
    plugin_versions="$(printf '%s' "$plugins_json" | \
                       python3 -c 'import sys,json; [print(p.get("version","?"))   for p in json.load(sys.stdin)]' 2>/dev/null)"

    # Pair into arrays
    mapfile -t _pnames   <<< "$plugin_names"
    mapfile -t _ppaths   <<< "$plugin_paths"
    mapfile -t _pversions <<< "$plugin_versions"

    local idx=0
    for pname in "${_pnames[@]}"; do
        local ppath="${_ppaths[$idx]:-?}"
        local pver="${_pversions[$idx]:-?}"

        # ── .so file accessible? ─────────────────────────────────────────────
        if [[ -f "$ppath" ]]; then
            local so_size
            so_size="$(du -sh "$ppath" 2>/dev/null | cut -f1)"

            # ── ABI tag check — strip and look for Hyprland ABI marker ──────
            local abi_ok=0
            if command -v strings &>/dev/null; then
                strings "$ppath" 2>/dev/null | grep -q 'HYPR_PLUGIN_API_VERSION' \
                    && abi_ok=1
            else
                abi_ok=1  # assume ok if strings not available
            fi

            if [[ $abi_ok -eq 1 ]]; then
                _check_report $CHECK_PASS \
                    "Plugin: ${pname}" \
                    "v${pver}  •  ${so_size}  •  ABI ✓  (${ppath##*/})"
            else
                _check_report $CHECK_WARN \
                    "Plugin: ${pname}" \
                    "ABI marker not found — may crash on API change" \
                    "Rebuild: hyprpm update"
            fi
        else
            _check_report $CHECK_FAIL \
                "Plugin: ${pname}" \
                "SO file missing: ${ppath}" \
                "Reinstall: hyprpm remove ${pname} && hyprpm install ${pname}"
        fi

        (( idx++ )) || true
    done

    # ── Conflict detection among active plugins ─────────────────────────────────
    _chk_plugins_conflicts "${_pnames[@]}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 03 — CONFLICT MATRIX
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_plugins_conflicts() {
    local -a active_plugins=("$@")
    [[ ${#active_plugins[@]} -lt 2 ]] && return 0

    _check_header "⚡ Plugin Conflict Matrix"

    # Known incompatible pairs: "A|B|reason"
    local -a conflict_pairs=(
        "hy3|hyprscroller|Both override the layout — only one layout plugin at a time"
        "hy3|hyprNStack|Multiple layout plugins conflict"
        "hy3|hyprsplit|hyprsplit conflicts with hy3 splits"
        "hyprscroller|hyprNStack|Multiple layout plugins conflict"
        "Hyprload|hyprpm|Use hyprpm exclusively — Hyprload is legacy"
        "hyprspace|hyprexpo|Both provide workspace overview — pick one"
    )

    local conflicts_found=0

    for pair in "${conflict_pairs[@]}"; do
        IFS='|' read -r pa pb reason <<< "$pair"

        local has_a=0 has_b=0
        for active in "${active_plugins[@]}"; do
            [[ "${active,,}" == "${pa,,}" ]] && has_a=1
            [[ "${active,,}" == "${pb,,}" ]] && has_b=1
        done

        if [[ $has_a -eq 1 ]] && [[ $has_b -eq 1 ]]; then
            _check_report $CHECK_FAIL \
                "Conflict: ${pa} ↔ ${pb}" \
                "$reason" \
                "Disable one: hyprpm disable ${pb}"
            (( conflicts_found++ )) || true
        fi
    done

    if (( conflicts_found == 0 )); then
        _check_report $CHECK_PASS \
            "Conflict matrix" \
            "No conflicts among ${#active_plugins[@]} active plugin(s)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 04 — PLUGIN CONFIG FILES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_plugins_config_files() {
    _check_header "📄 Plugin Configuration Files"

    local plugins_conf_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/plugins"
    local ash_plugins_conf="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/plugins.conf"

    # ── plugins/ directory ──────────────────────────────────────────────────────
    if [[ -d "$plugins_conf_dir" ]]; then
        local conf_count
        conf_count="$(find "$plugins_conf_dir" -name '*.conf' 2>/dev/null | wc -l)"
        _check_report $CHECK_PASS \
            "Config dir" \
            "${plugins_conf_dir}  (${conf_count} .conf files)"

        # Individual plugin config validation
        while IFS= read -r conf_file; do
            local bname
            bname="$(basename "$conf_file" .conf)"
            local line_count
            line_count="$(wc -l < "$conf_file" 2>/dev/null || echo 0)"

            # Check for empty configs (likely placeholder)
            if (( line_count == 0 )); then
                _check_report $CHECK_WARN \
                    "Config: ${bname}.conf" \
                    "Empty file" \
                    "Add plugin configuration or remove the file"
            else
                _check_report $CHECK_PASS \
                    "Config: ${bname}.conf" \
                    "${line_count} lines"
            fi
        done < <(find "$plugins_conf_dir" -name '*.conf' -type f 2>/dev/null | sort)
    else
        _check_report $CHECK_INFO \
            "Config dir" \
            "Not found: ${plugins_conf_dir}" \
            "Create with: mkdir -p ${plugins_conf_dir}"
    fi

    # ── hypr/plugins.conf source file ──────────────────────────────────────────
    if [[ -f "$ash_plugins_conf" ]]; then
        local load_count
        load_count="$(grep -c '^plugin\s*=' "$ash_plugins_conf" 2>/dev/null || echo 0)"
        _check_report $CHECK_PASS \
            "plugins.conf" \
            "${ash_plugins_conf}  (${load_count} plugin= entries)"
    else
        _check_report $CHECK_INFO \
            "plugins.conf" \
            "Not found — plugin loading may be inline in hyprland.conf"
    fi

    # ── ASH plugin config dir ───────────────────────────────────────────────────
    local ash_plugin_store="${ASH_PLUGINS_DIR:-}"
    if [[ -n "$ash_plugin_store" ]] && [[ -d "$ash_plugin_store" ]]; then
        local ash_plugin_count
        ash_plugin_count="$(find "$ash_plugin_store" -maxdepth 2 -name 'plugin.json' \
                            2>/dev/null | wc -l)"
        _check_report $CHECK_PASS \
            "ASH plugin store" \
            "${ash_plugin_store}  (${ash_plugin_count} plugins)"
    else
        _check_report $CHECK_INFO \
            "ASH plugin store" \
            "Not initialized — run: ash plugin browse"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 05 — ABI COMPATIBILITY DEEP SCAN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_plugins_abi() {
    _check_header "🔬 ABI / Shared Library Compatibility"

    # ── Current Hyprland ABI hash ───────────────────────────────────────────────
    local hypr_abi_hash=""
    if command -v hyprctl &>/dev/null && \
       [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        hypr_abi_hash="$(hyprctl version 2>/dev/null | \
                         grep -oP 'Tag:\s*\K\S+' | head -1 || echo '')"
    fi

    if [[ -n "$hypr_abi_hash" ]]; then
        _check_report $CHECK_INFO \
            "Hyprland ABI tag" \
            "$hypr_abi_hash"
    else
        _check_report $CHECK_INFO \
            "Hyprland ABI tag" \
            "Could not determine (offline or not running)"
    fi

    # ── Scan all installed .so files ────────────────────────────────────────────
    local plugin_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/hyprpm"
    if [[ ! -d "$plugin_data_dir" ]]; then
        _check_report $CHECK_SKIP \
            "ABI scan" \
            "Plugin data dir absent — nothing to scan"
        return $CHECK_SKIP
    fi

    local so_files=()
    mapfile -t so_files < <(find "$plugin_data_dir" -name '*.so' -type f 2>/dev/null | sort)

    if [[ ${#so_files[@]} -eq 0 ]]; then
        _check_report $CHECK_INFO \
            "ABI scan" \
            "No .so files found in ${plugin_data_dir}"
        return $CHECK_PASS
    fi

    _check_report $CHECK_INFO \
        "SO files found" \
        "${#so_files[@]} shared libraries to scan"

    # ── Per-file checks ─────────────────────────────────────────────────────────
    local abi_fail_count=0

    for so_file in "${so_files[@]}"; do
        local so_name
        so_name="$(basename "$so_file")"

        # 1. File is valid ELF
        local file_type
        file_type="$(file -b "$so_file" 2>/dev/null | head -1)"
        if ! [[ "$file_type" =~ "ELF" ]] || ! [[ "$file_type" =~ "shared object" ]]; then
            _check_report $CHECK_FAIL \
                "ABI: ${so_name}" \
                "Not a valid ELF shared object" \
                "Reinstall plugin: hyprpm update"
            (( abi_fail_count++ )) || true
            continue
        fi

        # 2. Linked against correct libhyprland ABI
        local linked_libs
        linked_libs="$(ldd "$so_file" 2>/dev/null | awk '{print $1}' || echo '')"

        # 3. Look for unresolved symbols
        local unresolved
        unresolved="$(ldd "$so_file" 2>/dev/null | grep 'not found' || echo '')"

        if [[ -n "$unresolved" ]]; then
            local missing_count
            missing_count="$(printf '%s\n' "$unresolved" | wc -l)"
            _check_report $CHECK_FAIL \
                "ABI: ${so_name}" \
                "${missing_count} unresolved symbol(s)" \
                "Rebuild plugin against current Hyprland: hyprpm update"
            (( abi_fail_count++ )) || true
        else
            # 4. Check architecture matches host
            local so_arch
            so_arch="$(file -b "$so_file" 2>/dev/null | grep -oP 'x86-64|aarch64|ARM' | head -1)"
            local host_arch
            host_arch="$(uname -m | sed 's/x86_64/x86-64/; s/arm64/aarch64/')"

            if [[ "$so_arch" == "$host_arch" ]] || [[ -z "$so_arch" ]]; then
                local so_size
                so_size="$(du -sh "$so_file" 2>/dev/null | cut -f1)"
                _check_report $CHECK_PASS \
                    "ABI: ${so_name}" \
                    "${so_size}  •  ELF valid  •  symbols resolved"
            else
                _check_report $CHECK_FAIL \
                    "ABI: ${so_name}" \
                    "Arch mismatch: plugin is ${so_arch}, host is ${host_arch}" \
                    "Rebuild for correct architecture: hyprpm update"
                (( abi_fail_count++ )) || true
            fi
        fi
    done

    if (( abi_fail_count == 0 )); then
        _check_report $CHECK_PASS \
            "ABI summary" \
            "All ${#so_files[@]} plugin(s) pass ABI validation"
    else
        _check_report $CHECK_FAIL \
            "ABI summary" \
            "${abi_fail_count} of ${#so_files[@]} plugin(s) have ABI issues" \
            "Fix all with: hyprpm update --force"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 06 — KNOWN PLUGIN CATALOG SCAN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_plugins_catalog() {
    _check_header "📚 Plugin Catalog  (popular + recommended)"

    # Pull currently active plugin names for comparison
    local active_json
    active_json="$(hyprctl plugins list -j 2>/dev/null || echo '[]')"
    local active_names
    active_names="$(printf '%s' "$active_json" | \
                    python3 -c 'import sys,json; [print(p.get("name","").lower()) \
                    for p in json.load(sys.stdin)]' 2>/dev/null || echo '')"

    # Format: "id|display|category|priority_recommendation"
    local -a catalog=(
        "hy3|hy3  (i3-style tiling)|Layout|recommended for power users"
        "hyprscroller|Hyprscroller  (scrollable)|Layout|great for ultrawide monitors"
        "hyprexpo|Hyprexpo  (workspace expose)|Overview|official plugin — stable"
        "hyprspace|Hyprspace  (spaces overview)|Overview|macOS-like mission control"
        "hyprbars|Hyprbars  (title bars)|Visual|adds CSD-style titlebars"
        "hyprfocus|Hyprfocus  (dim unfocused)|Visual|productivity enhancer"
        "hyprwinwrap|HyprWinWrap  (live wallpaper)|Visual|run apps as wallpaper"
        "hyprtrails|Hyprtrails  (movement trails)|Visual|eye-candy"
        "hypr-dynamic-cursors|Dynamic Cursors  (physics)|Cursor|premium feel"
        "hypr-darkwindow|Dark Window  (per-window dark)|Utility|inverter for light apps"
        "hyprland-virtual-desktops|Virtual Desktops  (named)|Utility|named persistent desktops"
        "hyprland-touch-gestures|Touch Gestures  (trackpad)|Input|essential for laptops"
        "hyprland-easymotion|Easy Motion  (vim-style)|Input|keyboard window focus"
        "hyprsplit|Hyprsplit  (containers)|Layout|tmux-like splits"
    )

    for entry in "${catalog[@]}"; do
        IFS='|' read -r cid cname cat hint <<< "$entry"

        local is_active=0
        if printf '%s\n' "$active_names" | grep -qi "^${cid}$"; then
            is_active=1
        fi

        if [[ $is_active -eq 1 ]]; then
            _check_report $CHECK_PASS \
                "${cname}" \
                "ACTIVE  [${cat}]  •  ${hint}"
        else
            _check_report $CHECK_INFO \
                "${cname}" \
                "not installed  [${cat}]  •  ${hint}" \
                "Install: ash plugin install ${cid}"
        fi
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 07 — PERFORMANCE OVERHEAD ESTIMATE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_plugins_performance() {
    _check_header "⚡ Plugin Performance Impact Estimate"

    [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && {
        _check_report $CHECK_SKIP "Performance" "Skipped — Hyprland not running"
        return $CHECK_SKIP
    }

    local plugins_json
    plugins_json="$(hyprctl plugins list -j 2>/dev/null || echo '[]')"
    local plugin_count
    plugin_count="$(printf '%s' "$plugins_json" | \
                    python3 -c 'import sys,json; print(len(json.load(sys.stdin)))' \
                    2>/dev/null || echo 0)"

    # Overhead lookup table (subjective scores per known plugin)
    declare -A overhead_table=(
        [hy3]=1          [hyprscroller]=1    [hyprsplit]=1
        [hyprexpo]=2     [hyprspace]=3       [hyprtasking]=2
        [hyprbars]=2     [hyprfocus]=1       [hyprwinwrap]=4
        [hyprtrails]=3   [hyprNStack]=1      [hyprnstack]=1
        [hypr-dynamic-cursors]=2
        [hypr-darkwindow]=3
        [hyprland-virtual-desktops]=1
        [hyprland-touch-gestures]=1
        [hyprland-easymotion]=1
    )

    local total_overhead=0
    local -a pnames=()
    mapfile -t pnames < <(
        printf '%s' "$plugins_json" | \
        python3 -c 'import sys,json; [print(p.get("name","").lower()) \
        for p in json.load(sys.stdin)]' 2>/dev/null || true
    )

    for pn in "${pnames[@]}"; do
        local score="${overhead_table[${pn,,}]:-1}"
        (( total_overhead += score )) || true

        local impact_label
        case "$score" in
            1) impact_label="$(printf '\033[38;2;166;227;161m●\033[0m minimal')"     ;;
            2) impact_label="$(printf '\033[38;2;249;226;175m●\033[0m low')"         ;;
            3) impact_label="$(printf '\033[38;2;250;179;135m●\033[0m moderate')"    ;;
            4) impact_label="$(printf '\033[38;2;243;139;168m●\033[0m high')"        ;;
            *) impact_label="$(printf '\033[38;2;108;112;134m●\033[0m unknown')"     ;;
        esac

        _check_report $CHECK_INFO \
            "Impact: ${pn}" \
            "$impact_label"
    done

    # ── Aggregate score ─────────────────────────────────────────────────────────
    if (( plugin_count == 0 )); then
        _check_report $CHECK_INFO \
            "Total overhead" \
            "None — no plugins loaded"
    else
        local avg_overhead=0
        (( avg_overhead = total_overhead / plugin_count )) || true

        local overall_label overall_status
        if (( total_overhead <= 4 )); then
            overall_label="Excellent — very light plugin set"
            overall_status=$CHECK_PASS
        elif (( total_overhead <= 8 )); then
            overall_label="Good — balanced plugin set"
            overall_status=$CHECK_PASS
        elif (( total_overhead <= 14 )); then
            overall_label="Moderate — consider disabling visual plugins on battery"
            overall_status=$CHECK_WARN
        else
            overall_label="Heavy — may impact battery life and input latency"
            overall_status=$CHECK_WARN
        fi

        _check_report $overall_status \
            "Total overhead score" \
            "${total_overhead}/~${plugin_count}  •  ${overall_label}"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_check_hyprland_plugins() {
    local mode="${1:-full}"   # quick | full | catalog | abi

    # ── Reset counters (may be shared with sibling checks) ──────────────────────
    _CHECK_PASS_COUNT=0;  _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0;  _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=();   _CHECK_WARNINGS=()

    # ── Banner ──────────────────────────────────────────────────────────────────
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n'
        printf '\033[1;38;2;203;166;247m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🔌  ASH DOCTOR — HYPRLAND PLUGINS CHECK                 ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  Checks: hyprpm • runtime • ABI • conflicts • perf       ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n=== ASH DOCTOR — HYPRLAND PLUGINS CHECK ===\n'
    fi

    # ── Initialize plugin registry ──────────────────────────────────────────────
    _plugin_registry_init

    # ── Run checks based on mode ────────────────────────────────────────────────
    case "$mode" in
        quick)
            _chk_plugins_hyprpm
            _chk_plugins_runtime
            ;;
        abi)
            _chk_plugins_abi
            ;;
        catalog)
            _chk_plugins_catalog
            ;;
        full|*)
            _chk_plugins_hyprpm
            _chk_plugins_runtime
            _chk_plugins_config_files
            _chk_plugins_abi
            _chk_plugins_performance
            _chk_plugins_catalog
            ;;
    esac

    # ── Summary ─────────────────────────────────────────────────────────────────
    _ash_check_system_summary
}

# ── Quick status API (used by doctor --quick) ───────────────────────────────────
ash_check_hyprland_plugins_quick() {
    local issues=0

    command -v hyprpm &>/dev/null                          || (( issues++ )) || true
    [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]            || (( issues++ )) || true

    if (( issues == 0 )); then
        ash_log_success "Hyprland plugins: OK"
        return 0
    else
        ash_log_warn "Hyprland plugins: ${issues} issue(s) — run 'ash doctor full --plugins'"
        return 1
    fi
}
