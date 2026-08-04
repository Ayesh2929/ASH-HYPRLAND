#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║   ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗ ███████╗                        ║
# ║  ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝ ██╔════╝                        ║
# ║  ██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗███████╗                        ║
# ║  ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║╚════██║                        ║
# ║  ╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝███████║                        ║
# ║   ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝ ╚══════╝                        ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  DOCTOR CHECK: CONFIGURATIONS                            ║
# ║  Validates every config file ASH manages — syntax, permissions, completeness    ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CHECK_CONFIGS_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CHECK_CONFIGS_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
declare -gr _ASH_ROOT="${ASH_ROOT_DIR:-$HOME/.config/ash-dotfiles}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CONFIG PROBE HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Check a config file exists, has content, has correct permissions
_cfg_file() {
    local display="$1"
    local path="$2"
    local critical="${3:-1}"
    local min_lines="${4:-1}"
    local max_perm="${5:-644}"

    if [[ ! -e "$path" ]]; then
        if [[ "$critical" == "1" ]]; then
            _check_report $CHECK_FAIL \
                "$display" \
                "MISSING: ${path}" \
                "Run: ash doctor fix --configs"
        else
            _check_report $CHECK_INFO \
                "$display" \
                "not found (optional): ${path}"
        fi
        return $CHECK_FAIL
    fi

    if [[ -L "$path" ]]; then
        local real
        real="$(readlink -f "$path" 2>/dev/null || echo '?')"
        if [[ ! -e "$real" ]]; then
            _check_report $CHECK_FAIL \
                "$display" \
                "BROKEN SYMLINK → ${real}" \
                "Fix: ash doctor fix --symlinks"
            return $CHECK_FAIL
        fi
        _check_report $CHECK_INFO \
            "$display" \
            "symlink → ${real}"
        return $CHECK_PASS
    fi

    local line_count
    line_count="$(wc -l < "$path" 2>/dev/null || echo 0)"

    if (( line_count < min_lines )); then
        _check_report $CHECK_WARN \
            "$display" \
            "exists but suspiciously short (${line_count} lines)" \
            "Check file integrity: ${path}"
        return $CHECK_WARN
    fi

    # Permission check
    local actual_perm
    actual_perm="$(stat -c '%a' "$path" 2>/dev/null || echo '???')"
    if [[ "$actual_perm" =~ ^[0-7]+$ ]] && (( 8#$actual_perm > 8#$max_perm )); then
        _check_report $CHECK_WARN \
            "$display" \
            "${line_count}L  •  perm ${actual_perm} (too open — expected ≤ ${max_perm})" \
            "Fix: chmod ${max_perm} '${path}'"
        return $CHECK_WARN
    fi

    _check_report $CHECK_PASS \
        "$display" \
        "${line_count} lines  •  perm ${actual_perm}  •  ${path##*/}"
    return $CHECK_PASS
}

# Check a directory exists
_cfg_dir() {
    local display="$1"
    local path="$2"
    local critical="${3:-1}"

    if [[ -d "$path" ]]; then
        local item_count
        item_count="$(find "$path" -maxdepth 1 2>/dev/null | tail -n +2 | wc -l)"
        _check_report $CHECK_PASS \
            "$display" \
            "${item_count} item(s)  •  ${path}"
    elif [[ "$critical" == "1" ]]; then
        _check_report $CHECK_FAIL \
            "$display" \
            "MISSING: ${path}" \
            "Run: ash doctor fix --configs"
    else
        _check_report $CHECK_INFO \
            "$display" \
            "not found (optional): ${path}"
    fi
}

# Validate JSON syntax
_cfg_json() {
    local display="$1"
    local path="$2"
    local critical="${3:-1}"

    _cfg_file "$display" "$path" "$critical" || return

    if command -v python3 &>/dev/null; then
        if python3 -c "import json,sys; json.load(open('${path}'))" 2>/dev/null; then
            _check_report $CHECK_PASS \
                "${display}  [JSON ✓]" \
                "Valid JSON syntax"
        else
            _check_report $CHECK_FAIL \
                "${display}  [JSON ✗]" \
                "Invalid JSON syntax" \
                "Fix: python3 -m json.tool '${path}'"
        fi
    elif command -v jq &>/dev/null; then
        if jq empty "$path" &>/dev/null; then
            _check_report $CHECK_PASS "${display}  [JSON ✓]" "Valid JSON"
        else
            _check_report $CHECK_FAIL "${display}  [JSON ✗]" "Invalid JSON"
        fi
    fi
}

# Validate YAML syntax
_cfg_yaml() {
    local display="$1"
    local path="$2"
    local critical="${3:-1}"

    _cfg_file "$display" "$path" "$critical" || return

    if command -v python3 &>/dev/null; then
        if python3 -c "import yaml,sys; yaml.safe_load(open('${path}'))" 2>/dev/null; then
            _check_report $CHECK_PASS \
                "${display}  [YAML ✓]" \
                "Valid YAML syntax"
        else
            _check_report $CHECK_FAIL \
                "${display}  [YAML ✗]" \
                "Invalid YAML syntax" \
                "Fix: python3 -c \"import yaml; yaml.safe_load(open('${path}'))\""
        fi
    fi
}

# Validate shell script syntax
_cfg_shell() {
    local display="$1"
    local path="$2"
    local critical="${3:-1}"

    _cfg_file "$display" "$path" "$critical" || return

    if bash -n "$path" 2>/dev/null; then
        _check_report $CHECK_PASS \
            "${display}  [sh ✓]" \
            "Syntax OK"
    else
        local errors
        errors="$(bash -n "$path" 2>&1 | head -3)"
        _check_report $CHECK_FAIL \
            "${display}  [sh ✗]" \
            "Syntax error: $(printf '%s' "$errors" | head -1)" \
            "Fix: bash -n '${path}'"
    fi
}

# Validate TOML syntax
_cfg_toml() {
    local display="$1"
    local path="$2"
    local critical="${3:-1}"

    _cfg_file "$display" "$path" "$critical" || return

    if command -v python3 &>/dev/null && python3 -c "import tomllib" &>/dev/null 2>&1; then
        if python3 -c "import tomllib; tomllib.load(open('${path}','rb'))" 2>/dev/null; then
            _check_report $CHECK_PASS "${display}  [TOML ✓]" "Valid TOML"
        else
            _check_report $CHECK_FAIL "${display}  [TOML ✗]" "Invalid TOML"
        fi
    elif command -v taplo &>/dev/null; then
        if taplo lint "$path" &>/dev/null; then
            _check_report $CHECK_PASS "${display}  [TOML ✓]" "Valid TOML"
        else
            _check_report $CHECK_FAIL "${display}  [TOML ✗]" "Invalid TOML"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 01 — HYPRLAND
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_cfg_hyprland() {
    _check_header "💎 Hyprland Configuration"

    local hypr_dir="${_CFG}/hypr"
    _cfg_dir "Config dir" "$hypr_dir" 1

    # Critical Hyprland configs
    local -a critical_hypr=(
        "hyprland.conf:Main config"
        "env.conf:Environment variables"
        "monitors.conf:Monitor layout"
        "animations/default.conf:Animations"
        "keybinds/default.conf:Keybindings"
        "themes/colors.conf:Color theme"
        "themes/active-theme.conf:Active theme"
        "windowrules.conf:Window rules"
        "autostart.conf:Autostart programs"
    )

    for entry in "${critical_hypr[@]}"; do
        IFS=':' read -r file label <<< "$entry"
        _cfg_file "$label" "${hypr_dir}/${file}" 1 5
    done

    # Optional Hyprland configs
    local -a optional_hypr=(
        "decorations.conf:Decorations"
        "gestures.conf:Gestures"
        "input.conf:Input devices"
        "misc.conf:Miscellaneous"
        "layerrules.conf:Layer rules"
        "workspacerules.conf:Workspace rules"
        "plugins.conf:Hyprland plugins"
        "xwayland.conf:XWayland settings"
    )

    for entry in "${optional_hypr[@]}"; do
        IFS=':' read -r file label <<< "$entry"
        _cfg_file "$label" "${hypr_dir}/${file}" 0 1
    done

    # Shader files
    local shader_dir="${hypr_dir}/shaders"
    if [[ -d "$shader_dir" ]]; then
        local shader_count
        shader_count="$(find "$shader_dir" -name '*.frag' | wc -l)"
        _check_report $CHECK_INFO \
            "GLSL Shaders" \
            "${shader_count} .frag shader(s) in ${shader_dir}"
    fi

    # Hyprland parse error check (live)
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl &>/dev/null; then
        local log_dir="${XDG_RUNTIME_DIR:-/tmp}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}"
        local hypr_log="${log_dir}/hyprland.log"
        if [[ -f "$hypr_log" ]]; then
            local parse_errors
            parse_errors="$(grep -c '\[ERR\]\|Parse error\|Config error' \
                           "$hypr_log" 2>/dev/null || echo 0)"
            if (( parse_errors == 0 )); then
                _check_report $CHECK_PASS \
                    "Config parse errors" \
                    "None in runtime log"
            else
                _check_report $CHECK_FAIL \
                    "Config parse errors" \
                    "${parse_errors} error(s) in hyprland.log" \
                    "Check: tail -50 ${hypr_log} | grep ERR"
            fi
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 02 — WAYBAR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_cfg_waybar() {
    _check_header "📊 Waybar Configuration"

    local wb_dir="${_CFG}/waybar"
    _cfg_dir "Config dir" "$wb_dir" 1

    _cfg_json  "config.jsonc (main)"      "${wb_dir}/config.jsonc" 1
    _cfg_file  "style.css"                "${wb_dir}/style.css"    1 10
    _cfg_file  "colors.css"               "${wb_dir}/colors.css"   1 5
    _cfg_file  "variables.css"            "${wb_dir}/variables.css" 0 1
    _cfg_file  "animations.css"           "${wb_dir}/animations.css" 0 1

    local layouts_dir="${wb_dir}/layouts"
    if [[ -d "$layouts_dir" ]]; then
        local layout_count
        layout_count="$(find "$layouts_dir" -name '*.jsonc' | wc -l)"
        _check_report $CHECK_INFO \
            "Layout files" \
            "${layout_count} .jsonc layout(s)"
    fi

    local scripts_dir="${wb_dir}/scripts"
    if [[ -d "$scripts_dir" ]]; then
        local script_count broken=0
        script_count="$(find "$scripts_dir" -name '*.sh' | wc -l)"
        while IFS= read -r sh; do
            bash -n "$sh" 2>/dev/null || (( broken++ )) || true
        done < <(find "$scripts_dir" -name '*.sh' 2>/dev/null)

        if (( broken > 0 )); then
            _check_report $CHECK_WARN \
                "Waybar scripts" \
                "${script_count} scripts  •  ${broken} with syntax errors"
        else
            _check_report $CHECK_PASS \
                "Waybar scripts" \
                "${script_count} scripts  •  all syntax OK"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 03 — ROFI
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_cfg_rofi() {
    _check_header "🚀 Rofi Configuration"

    local rofi_dir="${_CFG}/rofi"
    _cfg_dir "Config dir" "$rofi_dir" 1

    _cfg_file "config.rasi"   "${rofi_dir}/config.rasi" 1 5
    _cfg_file "colors.rasi"   "${rofi_dir}/colors.rasi" 1 5
    _cfg_file "fonts.rasi"    "${rofi_dir}/fonts.rasi"  0 1

    # Launcher styles
    local -a launcher_types=( type-1-grid type-2-sidebar type-3-fullscreen type-4-center type-5-spotlight )
    local found_launchers=0
    for lt in "${launcher_types[@]}"; do
        [[ -f "${rofi_dir}/launchers/${lt}/launcher.rasi" ]] && (( found_launchers++ )) || true
    done
    _check_report $CHECK_INFO \
        "Launcher styles" \
        "${found_launchers}/${#launcher_types[@]} launcher types configured"

    # Menus
    local -a menus=( powermenu screenshot wallpaper bluetooth wifi clipboard emoji )
    local found_menus=0
    for menu in "${menus[@]}"; do
        [[ -f "${rofi_dir}/menus/${menu}/${menu}.rasi" ]] && (( found_menus++ )) || true
    done
    _check_report $CHECK_INFO \
        "Rofi menus" \
        "${found_menus}/${#menus[@]} menus configured"

    # Validate rofi config syntax
    if command -v rofi &>/dev/null; then
        if rofi -dump-config &>/dev/null 2>&1; then
            _check_report $CHECK_PASS \
                "Rofi config syntax" \
                "rofi -dump-config: OK"
        else
            _check_report $CHECK_WARN \
                "Rofi config syntax" \
                "rofi reports config issues" \
                "Run: rofi -dump-config 2>&1 | head -20"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 04 — TERMINAL & SHELL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_cfg_terminal() {
    _check_header "🖥️  Terminal & Shell Configuration"

    # Kitty
    local kitty_dir="${_CFG}/kitty"
    _cfg_dir "Kitty config dir" "$kitty_dir" 1
    _cfg_file "kitty.conf"       "${kitty_dir}/kitty.conf"   1 20
    _cfg_file "colors.conf"      "${kitty_dir}/colors.conf"  1 5
    _cfg_file "keybinds.conf"    "${kitty_dir}/keybinds.conf" 0 1

    # Kitty font check
    if [[ -f "${kitty_dir}/kitty.conf" ]]; then
        local kitty_font_family
        kitty_font_family="$(grep '^font_family' "${kitty_dir}/kitty.conf" \
                             2>/dev/null | awk '{$1="";print}' | sed 's/^ //')"
        local kitty_font_size
        kitty_font_size="$(grep '^font_size' "${kitty_dir}/kitty.conf" \
                          2>/dev/null | awk '{print $2}')"
        if [[ -n "$kitty_font_family" ]]; then
            _check_report $CHECK_INFO \
                "  Kitty font" \
                "${kitty_font_family}  •  size: ${kitty_font_size:-?}"
        fi
    fi

    # Fish
    local fish_dir="${_CFG}/fish"
    _cfg_dir "Fish config dir" "$fish_dir" 1
    _cfg_shell "config.fish"     "${fish_dir}/config.fish"   1 5

    local fish_confd="${fish_dir}/conf.d"
    if [[ -d "$fish_confd" ]]; then
        local fish_confd_count broken_fish=0
        fish_confd_count="$(find "$fish_confd" -name '*.fish' | wc -l)"
        while IFS= read -r ff; do
            fish --no-execute "$ff" 2>/dev/null || (( broken_fish++ )) || true
        done < <(find "$fish_confd" -name '*.fish' 2>/dev/null)
        if (( broken_fish > 0 )); then
            _check_report $CHECK_WARN \
                "fish/conf.d" \
                "${fish_confd_count} files  •  ${broken_fish} syntax error(s)"
        else
            _check_report $CHECK_PASS \
                "fish/conf.d" \
                "${fish_confd_count} files  •  all syntax OK"
        fi
    fi

    # Starship
    local starship_conf="${_CFG}/starship.toml"
    _cfg_toml "starship.toml" "$starship_conf" 1

    # Atuin
    local atuin_conf="${_CFG}/atuin/config.toml"
    _cfg_toml "atuin config" "$atuin_conf" 0

    # tmux
    local tmux_conf="${_CFG}/tmux/tmux.conf"
    _cfg_file "tmux.conf" "$tmux_conf" 0 5
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 05 — NEOVIM
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_cfg_neovim() {
    _check_header "📝 Neovim Configuration"

    local nvim_dir="${_CFG}/nvim"
    _cfg_dir "Neovim config dir" "$nvim_dir" 1

    _cfg_file  "init.lua"      "${nvim_dir}/init.lua"       1 5
    _cfg_json  "lazy-lock.json" "${nvim_dir}/lazy-lock.json" 0
    _cfg_file  "stylua.toml"   "${nvim_dir}/stylua.toml"    0 1

    local lua_core="${nvim_dir}/lua/core"
    if [[ -d "$lua_core" ]]; then
        local core_files
        core_files="$(find "$lua_core" -name '*.lua' | wc -l)"
        _check_report $CHECK_INFO \
            "lua/core files" \
            "${core_files} core module(s)"
    fi

    local lua_plugins="${nvim_dir}/lua/plugins"
    if [[ -d "$lua_plugins" ]]; then
        local plugin_spec_count
        plugin_spec_count="$(find "$lua_plugins" -name '*.lua' | wc -l)"
        _check_report $CHECK_INFO \
            "Plugin specs" \
            "${plugin_spec_count} .lua plugin spec file(s)"
    fi

    # Lazy plugin count from lock file
    local lazy_lock="${nvim_dir}/lazy-lock.json"
    if [[ -f "$lazy_lock" ]] && command -v python3 &>/dev/null; then
        local plugin_count
        plugin_count="$(python3 -c \
            "import json; d=json.load(open('${lazy_lock}')); print(len(d))" \
            2>/dev/null || echo '?')"
        _check_report $CHECK_INFO \
            "Lazy.nvim plugins" \
            "${plugin_count} plugins locked"
    fi

    # Mason data
    local mason_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/mason"
    if [[ -d "$mason_dir" ]]; then
        local mason_count
        mason_count="$(find "${mason_dir}/packages" -maxdepth 1 -mindepth 1 \
                       -type d 2>/dev/null | wc -l)"
        _check_report $CHECK_INFO \
            "Mason packages" \
            "${mason_count} LSP/formatter/linter(s) installed"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 06 — NOTIFICATION & LOCK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_cfg_notif_lock() {
    _check_header "🔔 Notifications & Lock Screen"

    # Dunst
    local dunst_dir="${_CFG}/dunst"
    _cfg_dir  "Dunst config dir" "$dunst_dir" 0
    _cfg_file "dunstrc"          "${dunst_dir}/dunstrc" 0 20

    # SwayNC
    local swaync_dir="${_CFG}/swaync"
    _cfg_dir  "SwayNC config dir" "$swaync_dir" 0
    _cfg_json "swaync config.json" "${swaync_dir}/config.json" 0
    _cfg_file "swaync style.css"   "${swaync_dir}/style.css"   0 5

    # Hyprlock
    local hyprlock_dir="${_CFG}/hypr"
    _cfg_file "hyprlock.conf" "${hyprlock_dir}/hyprlock.conf" 1 5

    # Hypridle
    _cfg_file "hypridle.conf" "${hyprlock_dir}/hypridle.conf" 1 5

    # Wlogout
    local wlogout_dir="${_CFG}/wlogout"
    _cfg_dir  "Wlogout config dir" "$wlogout_dir" 0
    _cfg_file "wlogout layout"     "${wlogout_dir}/layout" 0 5
    _cfg_file "wlogout style.css"  "${wlogout_dir}/style.css" 0 5
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 07 — GTK / QT / APPEARANCE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_cfg_appearance() {
    _check_header "🎨 GTK / QT / Appearance"

    _cfg_file "gtk-3.0/settings.ini"  "${_CFG}/gtk-3.0/settings.ini"  1 5
    _cfg_file "gtk-3.0/gtk.css"       "${_CFG}/gtk-3.0/gtk.css"       0 1
    _cfg_file "gtk-4.0/settings.ini"  "${_CFG}/gtk-4.0/settings.ini"  1 5
    _cfg_file "gtk-4.0/gtk.css"       "${_CFG}/gtk-4.0/gtk.css"       0 1

    # Validate GTK3 font/theme settings
    local gtk3="${_CFG}/gtk-3.0/settings.ini"
    if [[ -f "$gtk3" ]]; then
        local gtk_theme icon_theme cursor_theme font_name
        gtk_theme="$(  grep 'gtk-theme-name'   "$gtk3" 2>/dev/null | cut -d= -f2 | tr -d ' ')"
        icon_theme="$( grep 'gtk-icon-theme'   "$gtk3" 2>/dev/null | cut -d= -f2 | tr -d ' ')"
        cursor_theme="$(grep 'gtk-cursor-theme' "$gtk3" 2>/dev/null | cut -d= -f2 | tr -d ' ')"
        font_name="$(  grep 'gtk-font-name'    "$gtk3" 2>/dev/null | cut -d= -f2 | sed 's/^ //')"

        [[ -n "$gtk_theme"    ]] && _check_report $CHECK_INFO "  GTK3 theme"   "$gtk_theme"
        [[ -n "$icon_theme"   ]] && _check_report $CHECK_INFO "  Icon theme"   "$icon_theme"
        [[ -n "$cursor_theme" ]] && _check_report $CHECK_INFO "  Cursor theme" "$cursor_theme"
        [[ -n "$font_name"    ]] && _check_report $CHECK_INFO "  GTK3 font"    "$font_name"

        # Verify icon theme dir exists
        if [[ -n "$icon_theme" ]]; then
            local icon_dir_found=0
            for icons_base in /usr/share/icons "${XDG_DATA_HOME:-$HOME/.local/share}/icons"; do
                [[ -d "${icons_base}/${icon_theme}" ]] && icon_dir_found=1 && break
            done
            if [[ $icon_dir_found -eq 1 ]]; then
                _check_report $CHECK_PASS "  Icon theme installed" "$icon_theme"
            else
                _check_report $CHECK_WARN "  Icon theme installed" \
                    "'${icon_theme}' not found in icon dirs" \
                    "Install: paru -S $(printf '%s' "$icon_theme" | tr '[:upper:]' '[:lower:]')"
            fi
        fi
    fi

    # Kvantum
    local kv_dir="${_CFG}/Kvantum"
    if [[ -d "$kv_dir" ]]; then
        local kv_theme_count
        kv_theme_count="$(find "$kv_dir" -name '*.kvconfig' | wc -l)"
        _check_report $CHECK_INFO \
            "Kvantum themes" \
            "${kv_theme_count} theme(s) in ${kv_dir}"
    fi

    # cursor theme
    local cursor_dir="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
    local cursor_count
    cursor_count="$(find "$cursor_dir" -name 'cursors' -type d 2>/dev/null | wc -l)"
    _check_report $CHECK_INFO \
        "Cursor themes installed" \
        "${cursor_count} cursor set(s) in ${cursor_dir}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 08 — GIT, SSH & SECURITY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_cfg_git_security() {
    _check_header "🔒 Git / SSH / Security"

    # Git
    local gitconfig="${_CFG}/git/.gitconfig"
    [[ -f "$gitconfig" ]] || gitconfig="$HOME/.gitconfig"
    _cfg_file ".gitconfig" "$gitconfig" 1 5

    if [[ -f "$gitconfig" ]]; then
        local git_user git_email git_editor
        git_user="$(  git config --global user.name  2>/dev/null || echo '')"
        git_email="$( git config --global user.email 2>/dev/null || echo '')"
        git_editor="$(git config --global core.editor 2>/dev/null || echo '')"

        if [[ -n "$git_user" ]]; then
            _check_report $CHECK_PASS "  git user.name"  "$git_user"
        else
            _check_report $CHECK_WARN "  git user.name"  "Not set" \
                "Fix: git config --global user.name 'Your Name'"
        fi

        if [[ -n "$git_email" ]]; then
            _check_report $CHECK_PASS "  git user.email" "$git_email"
        else
            _check_report $CHECK_WARN "  git user.email" "Not set" \
                "Fix: git config --global user.email 'you@email.com'"
        fi

        [[ -n "$git_editor" ]] && \
            _check_report $CHECK_INFO "  git core.editor" "$git_editor"

        # Signing key
        local signing_key
        signing_key="$(git config --global user.signingkey 2>/dev/null || echo '')"
        if [[ -n "$signing_key" ]]; then
            _check_report $CHECK_PASS "  git signing key" "$signing_key"
        else
            _check_report $CHECK_INFO "  git signing key" "Not configured (optional)"
        fi
    fi

    _cfg_file ".gitignore_global" "${_CFG}/git/.gitignore_global" 0 3

    # SSH
    local ssh_dir="$HOME/.ssh"
    local ssh_config="${ssh_dir}/config"
    _cfg_dir  "~/.ssh dir"   "$ssh_dir"    1
    _cfg_file "ssh/config"   "$ssh_config" 0 1 600

    if [[ -d "$ssh_dir" ]]; then
        # Check .ssh dir permissions (must be 700)
        local ssh_perm
        ssh_perm="$(stat -c '%a' "$ssh_dir" 2>/dev/null || echo '???')"
        if [[ "$ssh_perm" == "700" ]]; then
            _check_report $CHECK_PASS "~/.ssh permissions" "700 ✓"
        else
            _check_report $CHECK_FAIL "~/.ssh permissions" \
                "${ssh_perm}  (must be 700)" \
                "Fix: chmod 700 ~/.ssh"
        fi

        # Private key permissions
        local bad_key_perms=0
        while IFS= read -r key_file; do
            local kp
            kp="$(stat -c '%a' "$key_file" 2>/dev/null || echo '000')"
            if (( 8#$kp > 8#600 )); then
                _check_report $CHECK_FAIL \
                    "SSH key perm: ${key_file##*/}" \
                    "${kp}  (must be ≤ 600)" \
                    "Fix: chmod 600 '${key_file}'"
                (( bad_key_perms++ )) || true
            fi
        done < <(find "$ssh_dir" \( -name 'id_*' ! -name '*.pub' \) 2>/dev/null)

        if (( bad_key_perms == 0 )); then
            local key_count
            key_count="$(find "$ssh_dir" \( -name 'id_*' ! -name '*.pub' \) | wc -l)"
            _check_report $CHECK_PASS \
                "SSH private keys" \
                "${key_count} key(s)  •  all have correct permissions"
        fi
    fi

    # GPG
    local gpg_dir="$HOME/.gnupg"
    if [[ -d "$gpg_dir" ]]; then
        local gpg_perm
        gpg_perm="$(stat -c '%a' "$gpg_dir" 2>/dev/null || echo '???')"
        if [[ "$gpg_perm" == "700" ]]; then
            _check_report $CHECK_PASS "~/.gnupg permissions" "700 ✓"
        else
            _check_report $CHECK_FAIL "~/.gnupg permissions" \
                "${gpg_perm}  (must be 700)" \
                "Fix: chmod 700 ~/.gnupg && chmod 600 ~/.gnupg/*"
        fi

        local gpg_key_count
        gpg_key_count="$(gpg --list-secret-keys 2>/dev/null | grep -c '^sec' || echo 0)"
        _check_report $CHECK_INFO \
            "GPG secret keys" \
            "${gpg_key_count} key(s)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 09 — ASH-SPECIFIC CONFIGS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_cfg_ash() {
    _check_header "⚡ ASH Dotfiles Configs"

    local ash_conf_dir="${_CFG}/ash"
    _cfg_dir "ASH config dir" "$ash_conf_dir" 1

    _cfg_file "ash.conf (main)"      "${ash_conf_dir}/ash.conf"        1 10
    _cfg_json "current-theme.json"   "${ash_conf_dir}/current-theme.json" 0
    _cfg_json "current-mode.json"    "${ash_conf_dir}/current-mode.json"  0

    # Data directory
    local ash_data="${XDG_DATA_HOME:-$HOME/.local/share}/ash"
    _cfg_dir "ASH data dir" "$ash_data" 1

    # Cache directory
    local ash_cache="${XDG_CACHE_HOME:-$HOME/.cache}/ash"
    _cfg_dir "ASH cache dir" "$ash_cache" 1

    # Snapshots directory
    local ash_snaps="${ash_data}/snapshots"
    if [[ -d "$ash_snaps" ]]; then
        local snap_count
        snap_count="$(find "$ash_snaps" -maxdepth 1 -mindepth 1 -type d | wc -l)"
        _check_report $CHECK_INFO \
            "Snapshots" \
            "${snap_count} snapshot(s) stored"
    fi

    # Logs
    local ash_log="${XDG_STATE_HOME:-$HOME/.local/state}/ash/logs/ash-cli.log"
    if [[ -f "$ash_log" ]]; then
        local log_size
        log_size="$(du -sh "$ash_log" 2>/dev/null | cut -f1)"
        local log_lines
        log_lines="$(wc -l < "$ash_log" 2>/dev/null || echo 0)"
        _check_report $CHECK_INFO \
            "ASH CLI log" \
            "${log_size}  •  ${log_lines} lines"
    else
        _check_report $CHECK_INFO \
            "ASH CLI log" \
            "Not yet created"
    fi

    # Version file
    local ver_file="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}/version.json"
    _cfg_json "version.json" "$ver_file" 0

    # Environment
    local env_dir="${_CFG}/environment.d"
    if [[ -d "$env_dir" ]]; then
        local env_count
        env_count="$(find "$env_dir" -name '*.conf' | wc -l)"
        _check_report $CHECK_INFO \
            "environment.d" \
            "${env_count} .conf file(s)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_check_configs() {
    local mode="${1:-full}"

    _CHECK_PASS_COUNT=0;  _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0;  _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=();   _CHECK_WARNINGS=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;166;227;161m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  ⚙️   ASH DOCTOR — CONFIGS CHECK                          ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  Hyprland • Waybar • Rofi • Fish • Nvim • GTK • ASH     ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n=== ASH DOCTOR — CONFIGS CHECK ===\n'
    fi

    case "$mode" in
        quick)
            _chk_cfg_hyprland
            _chk_cfg_terminal
            _chk_cfg_ash
            ;;
        hypr)       _chk_cfg_hyprland      ;;
        waybar)     _chk_cfg_waybar        ;;
        nvim)       _chk_cfg_neovim        ;;
        security)   _chk_cfg_git_security  ;;
        full|*)
            _chk_cfg_hyprland
            _chk_cfg_waybar
            _chk_cfg_rofi
            _chk_cfg_terminal
            _chk_cfg_neovim
            _chk_cfg_notif_lock
            _chk_cfg_appearance
            _chk_cfg_git_security
            _chk_cfg_ash
            ;;
    esac

    _ash_check_system_summary
}

ash_check_configs_quick() {
    local issues=0
    local -a must_exist=(
        "${_CFG}/hypr/hyprland.conf"
        "${_CFG}/waybar/config.jsonc"
        "${_CFG}/kitty/kitty.conf"
        "${_CFG}/fish/config.fish"
    )
    for f in "${must_exist[@]}"; do
        [[ -f "$f" ]] || (( issues++ )) || true
    done
    if (( issues == 0 )); then
        ash_log_success "Configs: OK  (${#must_exist[@]} critical files present)"
    else
        ash_log_warn "Configs: ${issues} missing — run 'ash doctor full --configs'"
        return 1
    fi
}
