#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ███████╗██╗██╗  ██╗     ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗ ███████╗ ║
# ║  ██╔════╝██║╚██╗██╔╝    ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝ ██╔════╝ ║
# ║  █████╗  ██║ ╚███╔╝     ██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗███████╗ ║
# ║  ██╔══╝  ██║ ██╔██╗     ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║╚════██║ ║
# ║  ██║     ██║██╔╝ ██╗    ╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝███████║ ║
# ║  ╚═╝     ╚═╝╚═╝  ╚═╝     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝ ╚══════╝ ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  FIXER: CONFIGS                                          ║
# ║  Restore missing configs • Regenerate defaults • Repair broken JSON/TOML/Shell  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_FIX_CONFIGS_LOADED:-}" == "1" ]] && return 0
readonly _ASH_FIX_CONFIGS_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _FC_ASH_ROOT="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}"
declare -gr _FC_CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
declare -gr _FC_DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
declare -gr _FC_CFG_SRC="${_FC_ASH_ROOT}/config"   # Source configs in repo

declare -g  _FC_FIXED=0
declare -g  _FC_SKIPPED=0
declare -g  _FC_FAILED=0
declare -ga _FC_RESTORED=()
declare -ga _FC_ERRORS=()

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fc_c()     { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_fc_reset() { _fc_c $'\033[0m';                        }
_fc_green() { _fc_c $'\033[38;2;166;227;161m';         }
_fc_red()   { _fc_c $'\033[1;38;2;243;139;168m';       }
_fc_yellow(){ _fc_c $'\033[1;38;2;249;226;175m';       }
_fc_blue()  { _fc_c $'\033[38;2;137;180;250m';         }
_fc_dim()   { _fc_c $'\033[38;2;108;112;134m';         }
_fc_green2(){ _fc_c $'\033[1;38;2;166;227;161m';       }
_fc_teal()  { _fc_c $'\033[38;2;148;226;213m';         }

_fc_section() {
    printf '\n'
    _fc_green2
    printf '  ┌─────────────────────────────────────────────────────────\n'
    printf '  │  %s\n' "$1"
    printf '  └─────────────────────────────────────────────────────────\n'
    _fc_reset
}

_fc_action() {
    local icon="$1" label="$2" detail="$3" status="${4:-ok}"
    local color
    case "$status" in
        fixed)    color="$(_fc_green)"  ;;
        skipped)  color="$(_fc_dim)"    ;;
        failed)   color="$(_fc_red)"    ;;
        dry-run)  color="$(_fc_blue)"   ;;
        created)  color="$(_fc_teal)"   ;;
        *) color="" ;;
    esac
    printf '  %s  ' "$icon"
    _fc_teal; printf '%-40s' "$label"; _fc_reset
    printf '%s%s\033[0m\n' "$color" "$detail"
}

# Restore a config by symlinking or copying from repo source
_fc_restore() {
    local src="$1"           # Source in ASH repo
    local dst="$2"           # Destination in ~/.config
    local label="${3:-$(basename "$dst")}"
    local use_symlink="${4:-1}"  # 1=symlink, 0=copy

    (( _FC_FIXED + _FC_SKIPPED + _FC_FAILED )) || true

    if [[ ! -f "$src" ]] && [[ ! -d "$src" ]]; then
        _fc_action "○" "$label" "source not found in repo — skip" "skipped"
        (( _FC_SKIPPED++ )) || true
        return 0
    fi

    if [[ -e "$dst" ]] && [[ ! -L "$dst" ]] && [[ "${ASH_FLAG_FORCE:-0}" -ne 1 ]]; then
        _fc_action "✓" "$label" "exists (use -f to overwrite)" "skipped"
        (( _FC_SKIPPED++ )) || true
        return 0
    fi

    if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
        _fc_action "~" "$label" "would restore from ${src##$HOME/}" "dry-run"
        return 0
    fi

    # Backup existing if present
    if [[ -e "$dst" ]]; then
        local backup="${dst}.ash-backup.$(date +%s)"
        cp -r "$dst" "$backup" 2>/dev/null || true
        _fc_action "💾" "Backup: ${label}" "${backup##$HOME/}" "skipped"
    fi

    # Ensure parent directory exists
    mkdir -p "$(dirname "$dst")" 2>/dev/null || true

    if [[ "$use_symlink" == "1" ]]; then
        if ln -sfn "$src" "$dst" 2>/dev/null; then
            _fc_action "🔗" "$label" "→  ${src##$HOME/}" "fixed"
            _FC_RESTORED+=("$label")
            (( _FC_FIXED++ )) || true
        else
            _fc_action "✗" "$label" "symlink FAILED" "failed"
            _FC_ERRORS+=("$label")
            (( _FC_FAILED++ )) || true
        fi
    else
        if cp -r "$src" "$dst" 2>/dev/null; then
            _fc_action "📋" "$label" "copied from repo" "fixed"
            _FC_RESTORED+=("$label")
            (( _FC_FIXED++ )) || true
        else
            _fc_action "✗" "$label" "copy FAILED" "failed"
            _FC_ERRORS+=("$label")
            (( _FC_FAILED++ )) || true
        fi
    fi
}

# Generate a default config file from heredoc
_fc_generate() {
    local dst="$1"
    local label="${2:-$(basename "$dst")}"
    local content="$3"

    if [[ -f "$dst" ]] && [[ "${ASH_FLAG_FORCE:-0}" -ne 1 ]]; then
        _fc_action "✓" "$label" "already exists" "skipped"
        (( _FC_SKIPPED++ )) || true
        return 0
    fi

    if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
        _fc_action "~" "$label" "would generate default" "dry-run"
        return 0
    fi

    mkdir -p "$(dirname "$dst")" 2>/dev/null || true

    if printf '%s' "$content" > "$dst" 2>/dev/null; then
        _fc_action "✨" "$label" "generated default config" "created"
        (( _FC_FIXED++ )) || true
    else
        _fc_action "✗" "$label" "generate FAILED" "failed"
        (( _FC_FAILED++ )) || true
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 01 — HYPRLAND CONFIGS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fc_fix_hyprland() {
    _fc_section "💎 Hyprland Configuration"

    local hypr_src="${_FC_CFG_SRC}/hypr"
    local hypr_dst="${_FC_CFG}/hypr"

    mkdir -p "$hypr_dst" 2>/dev/null || true

    # Critical config files
    local -a hypr_configs=(
        "hyprland.conf"
        "env.conf"
        "monitors.conf"
        "autostart.conf"
        "windowrules.conf"
        "animations/default.conf"
        "keybinds/default.conf"
        "themes/colors.conf"
        "themes/active-theme.conf"
        "decorations.conf"
        "input.conf"
        "misc.conf"
    )

    for cfg in "${hypr_configs[@]}"; do
        _fc_restore \
            "${hypr_src}/${cfg}" \
            "${hypr_dst}/${cfg}" \
            "hypr/${cfg}"
    done

    # Create required subdirs if missing
    local -a hypr_dirs=(
        "keybinds" "animations" "themes" "modes"
        "per-device" "plugins" "scripts" "shaders"
    )
    for dir in "${hypr_dirs[@]}"; do
        local dpath="${hypr_dst}/${dir}"
        if [[ ! -d "$dpath" ]]; then
            mkdir -p "$dpath" 2>/dev/null && \
                _fc_action "📁" "hypr/${dir}/" "directory created" "created" || true
        fi
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 02 — WAYBAR CONFIGS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fc_fix_waybar() {
    _fc_section "📊 Waybar Configuration"

    local wb_src="${_FC_CFG_SRC}/waybar"
    local wb_dst="${_FC_CFG}/waybar"

    mkdir -p "$wb_dst" 2>/dev/null || true

    local -a wb_configs=(
        "config.jsonc"
        "style.css"
        "colors.css"
        "variables.css"
        "animations.css"
    )

    for cfg in "${wb_configs[@]}"; do
        _fc_restore \
            "${wb_src}/${cfg}" \
            "${wb_dst}/${cfg}" \
            "waybar/${cfg}"
    done

    # Scripts must be executable
    if [[ -d "${wb_src}/scripts" ]]; then
        _fc_restore \
            "${wb_src}/scripts" \
            "${wb_dst}/scripts" \
            "waybar/scripts/"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 03 — TERMINAL & SHELL CONFIGS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fc_fix_terminal() {
    _fc_section "🖥️  Terminal & Shell Configuration"

    # ── Kitty ────────────────────────────────────────────────────────────────────
    local kitty_src="${_FC_CFG_SRC}/kitty"
    local kitty_dst="${_FC_CFG}/kitty"

    mkdir -p "$kitty_dst" 2>/dev/null || true

    for cfg in kitty.conf colors.conf keybinds.conf fonts.conf; do
        _fc_restore \
            "${kitty_src}/${cfg}" \
            "${kitty_dst}/${cfg}" \
            "kitty/${cfg}"
    done

    # ── Fish ─────────────────────────────────────────────────────────────────────
    local fish_src="${_FC_CFG_SRC}/fish"
    local fish_dst="${_FC_CFG}/fish"

    mkdir -p "${fish_dst}/conf.d" "${fish_dst}/functions" "${fish_dst}/completions" 2>/dev/null || true

    _fc_restore "${fish_src}/config.fish" "${fish_dst}/config.fish" "fish/config.fish"

    # Restore conf.d files if present
    if [[ -d "${fish_src}/conf.d" ]]; then
        while IFS= read -r fish_file; do
            local fname
            fname="$(basename "$fish_file")"
            _fc_restore "$fish_file" "${fish_dst}/conf.d/${fname}" "fish/conf.d/${fname}"
        done < <(find "${fish_src}/conf.d" -name '*.fish' 2>/dev/null | sort)
    fi

    # ── Starship ─────────────────────────────────────────────────────────────────
    local starship_src="${_FC_CFG_SRC}/starship/starship.toml"
    local starship_dst="${_FC_CFG}/starship.toml"
    _fc_restore "$starship_src" "$starship_dst" "starship.toml"

    # ── Git ───────────────────────────────────────────────────────────────────────
    local git_src="${_FC_CFG_SRC}/git"
    local git_dst="${_FC_CFG}/git"

    mkdir -p "$git_dst" 2>/dev/null || true

    for cfg in .gitconfig .gitignore_global .gitattributes; do
        [[ -f "${git_src}/${cfg}" ]] && \
            _fc_restore "${git_src}/${cfg}" "${git_dst}/${cfg}" "git/${cfg}"
    done

    # Also ensure $HOME/.gitconfig exists (git looks there by default)
    if [[ ! -f "$HOME/.gitconfig" ]] && [[ -f "${git_dst}/.gitconfig" ]]; then
        _fc_generate "$HOME/.gitconfig" "~/.gitconfig" \
            "[include]\n    path = ${git_dst}/.gitconfig\n"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 04 — ASH DOTFILES CORE CONFIG
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fc_fix_ash_core() {
    _fc_section "⚡ ASH Core Configuration"

    local ash_cfg_dir="${_FC_CFG}/ash"
    mkdir -p "$ash_cfg_dir" 2>/dev/null || true

    # ── Generate default ash.conf if missing ─────────────────────────────────────
    local ash_conf="${ash_cfg_dir}/ash.conf"
    if [[ ! -f "$ash_conf" ]] || [[ "${ASH_FLAG_FORCE:-0}" -eq 1 ]]; then
        local ash_ver="${ASH_VERSION:-5.0.0}"
        _fc_generate "$ash_conf" "ash/ash.conf" \
"# ╔══════════════════════════════════════════════╗
# ║  ASH DOTFILES v${ash_ver} — User Configuration  ║
# ║  Generated: $(date -Iseconds)       ║
# ╚══════════════════════════════════════════════╝

[general]
version         = ${ash_ver}
profile         = default
log_level       = INFO
auto_update     = true

[theme]
default         = catppuccin-mocha
transition      = fade
transition_dur  = 300

[wallpaper]
backend         = swww
fit             = fill

[animation]
enabled         = true
preset          = smooth

[performance]
mode            = balanced
hot_reload      = true

[privacy]
analytics       = false
"
    else
        _fc_action "✓" "ash/ash.conf" "exists" "skipped"
    fi

    # ── XDG portal config ─────────────────────────────────────────────────────────
    local portal_dir="${_FC_CFG}/xdg-desktop-portal"
    local portal_conf="${portal_dir}/hyprland-portals.conf"

    mkdir -p "$portal_dir" 2>/dev/null || true

    if [[ ! -f "$portal_conf" ]] || [[ "${ASH_FLAG_FORCE:-0}" -eq 1 ]]; then
        _fc_generate "$portal_conf" "xdg-desktop-portal/hyprland-portals.conf" \
"[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.Secret=gnome-keyring
org.freedesktop.impl.portal.FileChooser=hyprland;gtk
"
    else
        _fc_action "✓" "xdg-desktop-portal/hyprland-portals.conf" "exists" "skipped"
    fi

    # ── environment.d ─────────────────────────────────────────────────────────────
    local env_dir="${_FC_CFG}/environment.d"
    mkdir -p "$env_dir" 2>/dev/null || true

    local env_wayland="${env_dir}/wayland.conf"
    if [[ ! -f "$env_wayland" ]] || [[ "${ASH_FLAG_FORCE:-0}" -eq 1 ]]; then
        _fc_generate "$env_wayland" "environment.d/wayland.conf" \
"# Wayland environment variables (loaded by systemd --user)
WAYLAND_DISPLAY=wayland-1
XDG_SESSION_TYPE=wayland
XDG_CURRENT_DESKTOP=Hyprland
GDK_BACKEND=wayland,x11
QT_QPA_PLATFORM=wayland;xcb
QT_AUTO_SCREEN_SCALE_FACTOR=1
QT_WAYLAND_DISABLE_WINDOWDECORATION=1
SDL_VIDEODRIVER=wayland,x11
CLUTTER_BACKEND=wayland
MOZ_ENABLE_WAYLAND=1
ELECTRON_OZONE_PLATFORM_HINT=auto
"
    else
        _fc_action "✓" "environment.d/wayland.conf" "exists" "skipped"
    fi

    # ── GTK settings ─────────────────────────────────────────────────────────────
    for gtk_ver in 3 4; do
        local gtk_dir="${_FC_CFG}/gtk-${gtk_ver}.0"
        local gtk_settings="${gtk_dir}/settings.ini"
        mkdir -p "$gtk_dir" 2>/dev/null || true

        if [[ ! -f "$gtk_settings" ]] || [[ "${ASH_FLAG_FORCE:-0}" -eq 1 ]]; then
            _fc_restore \
                "${_FC_CFG_SRC}/gtk-${gtk_ver}.0/settings.ini" \
                "$gtk_settings" \
                "gtk-${gtk_ver}.0/settings.ini" 0
        else
            _fc_action "✓" "gtk-${gtk_ver}.0/settings.ini" "exists" "skipped"
        fi
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 05 — VALIDATE CONFIG SYNTAX
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fc_validate_syntax() {
    _fc_section "🔬 Config Syntax Validation"

    # JSON validation
    local json_errors=0
    while IFS= read -r json_file; do
        [[ -z "$json_file" ]] && continue
        local rel="${json_file##$HOME/}"

        if command -v python3 &>/dev/null; then
            if ! python3 -c "import json; json.load(open('${json_file}'))" \
                 &>/dev/null 2>&1; then
                _fc_action "✗" "${rel}" "INVALID JSON" "failed"
                (( json_errors++ )) || true
                _FC_ERRORS+=("Invalid JSON: ${rel}")
            else
                _fc_action "✓" "${rel}" "valid JSON" "skipped"
            fi
        fi
    done < <(find "${_FC_CFG}/hypr" "${_FC_CFG}/waybar" \
                  "${_FC_CFG}/ash" "${_FC_CFG}/nvim" \
                  -name '*.json' -o -name '*.jsonc' 2>/dev/null | head -30)

    # Shell script syntax check
    local sh_errors=0
    while IFS= read -r sh_file; do
        [[ -z "$sh_file" ]] && continue
        if ! bash -n "$sh_file" 2>/dev/null; then
            local rel="${sh_file##$HOME/}"
            _fc_action "✗" "${rel}" "BASH SYNTAX ERROR" "failed"
            (( sh_errors++ )) || true
            _FC_ERRORS+=("Syntax error: ${rel}")
        fi
    done < <(find "${_FC_CFG}/waybar/scripts" \
                  "${_FC_CFG}/hypr/scripts" \
                  "${_FC_ASH_ROOT}/scripts" \
                  -name '*.sh' 2>/dev/null | head -30)

    if (( json_errors + sh_errors == 0 )); then
        _fc_action "✓" "All validated files" "syntax OK" "skipped"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RESULTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fc_report() {
    printf '\n'
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\033[1;38;2;166;227;161m'
        printf '  ╔══════════════════════════════════════════════════════════╗\n'
        printf '  ║  ⚙️   CONFIGS FIX — RESULTS                               ║\n'
        printf '  ╠══════════════════════════════════════════════════════════╣\n'
        printf '  ║  \033[38;2;166;227;161m✓ %-4d restored/fixed\033[38;2;166;227;161m  ' "$_FC_FIXED"
        printf '  \033[38;2;108;112;134m○ %-4d skipped\033[38;2;166;227;161m  ' "$_FC_SKIPPED"
        printf '  \033[38;2;243;139;168m✗ %-4d failed\033[38;2;166;227;161m  ║\n' "$_FC_FAILED"
        printf '  ╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '  RESULTS: %d fixed  •  %d skipped  •  %d failed\n' \
            "$_FC_FIXED" "$_FC_SKIPPED" "$_FC_FAILED"
    fi

    if [[ ${#_FC_ERRORS[@]} -gt 0 ]]; then
        printf '\n'
        _fc_red; printf '  Config errors to fix manually:\n'; _fc_reset
        for err in "${_FC_ERRORS[@]}"; do
            printf '    • %s\n' "$err"
        done
    fi

    if (( _FC_FIXED > 0 )); then
        printf '\n'
        _fc_green; printf '  ✓ Run: '; _fc_reset
        printf 'ash reload  to apply restored configs.\n'
    fi
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_fix_configs() {
    local mode="${1:-all}"

    _FC_FIXED=0; _FC_SKIPPED=0; _FC_FAILED=0
    _FC_RESTORED=(); _FC_ERRORS=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;166;227;161m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  ⚙️   ASH FIXER — CONFIGURATIONS                          ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]] && \
            printf '║  MODE: DRY RUN  (no changes will be made)                ║\n' || \
            printf '║  MODE: LIVE     (configs restored from repo source)       ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    case "$mode" in
        hyprland)  _fc_fix_hyprland    ;;
        waybar)    _fc_fix_waybar      ;;
        terminal)  _fc_fix_terminal    ;;
        ash)       _fc_fix_ash_core    ;;
        validate)  _fc_validate_syntax ;;
        all|*)
            _fc_fix_hyprland
            _fc_fix_waybar
            _fc_fix_terminal
            _fc_fix_ash_core
            _fc_validate_syntax
            ;;
    esac

    _fc_report
}
