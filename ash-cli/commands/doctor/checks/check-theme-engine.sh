#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ████████╗██╗  ██╗███████╗███╗   ███╗███████╗                                   ║
# ║  ╚══██╔══╝██║  ██║██╔════╝████╗ ████║██╔════╝                                   ║
# ║     ██║   ███████║█████╗  ██╔████╔██║█████╗                                     ║
# ║     ██║   ██╔══██║██╔══╝  ██║╚██╔╝██║██╔══╝                                     ║
# ║     ██║   ██║  ██║███████╗██║ ╚═╝ ██║███████╗                                   ║
# ║     ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝                                   ║
# ║  ███████╗███╗   ██╗ ██████╗ ██╗███╗   ██╗███████╗                                ║
# ║  ██╔════╝████╗  ██║██╔════╝ ██║████╗  ██║██╔════╝                                ║
# ║  █████╗  ██╔██╗ ██║██║  ███╗██║██╔██╗ ██║█████╗                                  ║
# ║  ██╔══╝  ██║╚██╗██║██║   ██║██║██║╚██╗██║██╔══╝                                  ║
# ║  ███████╗██║ ╚████║╚██████╔╝██║██║ ╚████║███████╗                                ║
# ║  ╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝╚══════╝                                ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  DOCTOR CHECK: THEME ENGINE                              ║
# ║  Color pipeline • templates • wallpaper • hot-reload • presets                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CHECK_THEME_ENGINE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CHECK_THEME_ENGINE_LOADED=1

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

declare -gr _TE_THEMES_DIR="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}/themes"
declare -gr _TE_ENGINE_DIR="${ASH_CLI_DIR:-$HOME/ash-dotfiles/ash-cli}/engines"
declare -gr _TE_CFG="${XDG_CONFIG_HOME:-$HOME/.config}/ash"
declare -gr _TE_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/ash"
declare -gr _TE_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/ash"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 01 — THEME ENGINE BINARIES & DEPS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_te_binaries() {
    _check_header "🔧 Theme Engine Dependencies"

    # ── Color extraction ─────────────────────────────────────────────────────────
    # Format: "binary:package:role:critical"
    local -a color_deps=(
        "python3:python:Python 3 runtime:1"
        "magick:imagemagick:ImageMagick 7 (color extract):1"
        "convert:imagemagick:ImageMagick convert:1"
        "jq:jq:JSON processing:1"
        "sed:sed:Stream editor:1"
        "awk:gawk:Pattern scanning:1"
        "grep:grep:Pattern matching:1"
        "envsubst:gettext:Template variable substitution:1"
        "xargs:findutils:Build argument lists:1"
        "parallel:parallel:GNU parallel (async apply):0"
    )

    # ── Wallpaper backends ───────────────────────────────────────────────────────
    local -a wallpaper_backends=(
        "swww:swww:swww wallpaper daemon (animated):1"
        "swww-daemon:swww:swww daemon process:1"
        "hyprpaper:hyprpaper:Hyprpaper (static wallpaper):0"
        "swaybg:swaybg:swaybg (simple wallpaper):0"
        "feh:feh:feh (X11 wallpaper):0"
    )

    # ── Color processing ─────────────────────────────────────────────────────────
    local -a color_tools=(
        "colorz:python-colorz:Colorz color extractor:0"
        "colorthief:python-colorthief:ColorThief (dominant color):0"
        "pywal:python-pywal:PyWal (auto-palette from wallpaper):0"
        "wpgtk:wpgtk:Wpgtk (PyWal GUI):0"
        "matugen:matugen:Material You palette generator:0"
    )

    # ── Hot reload ───────────────────────────────────────────────────────────────
    local -a reload_deps=(
        "inotifywait:inotify-tools:inotifywait (file watcher):1"
        "hyprctl:hyprland:Hyprland IPC:1"
        "pkill:procps-ng:Process signaling:1"
        "dbus-send:dbus:D-Bus messaging:0"
        "gsettings:glib2:GSettings (GTK theme apply):0"
        "xsettingsd:xsettingsd:XSettings daemon (Xwayland GTK):0"
    )

    local all_groups=(
        "color_deps[@]"
        "wallpaper_backends[@]"
        "color_tools[@]"
        "reload_deps[@]"
    )
    local group_labels=(
        "Color Extraction"
        "Wallpaper Backends"
        "Color Processors"
        "Hot Reload"
    )

    local gi=0
    for group_var in "${all_groups[@]}"; do
        local label="${group_labels[$gi]}"
        printf '\n'
        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
            printf '  \033[38;2;108;112;134m── %s ──\033[0m\n' "$label"
        else
            printf '  -- %s --\n' "$label"
        fi

        local -n dep_list="$group_var"
        for dep_entry in "${dep_list[@]}"; do
            IFS=':' read -r binary pkg role critical <<< "$dep_entry"

            if command -v "$binary" &>/dev/null; then
                local ver
                ver="$("$binary" --version 2>&1 | head -1 | \
                       grep -oP '[\d]+\.[\d.]+' | head -1 || echo 'ok')"
                _check_report $CHECK_PASS \
                    "${binary}" \
                    "v${ver}  — ${role}"
            else
                if [[ "$critical" == "1" ]]; then
                    _check_report $CHECK_FAIL \
                        "${binary}" \
                        "MISSING  — ${role}" \
                        "Install: paru -S ${pkg}"
                else
                    _check_report $CHECK_INFO \
                        "${binary}" \
                        "not installed  — ${role}" \
                        "Optional: paru -S ${pkg}"
                fi
            fi
        done
        (( gi++ )) || true
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 02 — ACTIVE THEME STATE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_te_active_theme() {
    _check_header "🎨 Active Theme State"

    # ── Current theme JSON ───────────────────────────────────────────────────────
    local theme_json="${_TE_CFG}/current-theme.json"

    if [[ ! -f "$theme_json" ]]; then
        _check_report $CHECK_WARN \
            "current-theme.json" \
            "Not found — no theme applied yet" \
            "Apply a theme: ash theme apply catppuccin-mocha"
        return $CHECK_WARN
    fi

    # Parse theme fields
    if command -v python3 &>/dev/null; then
        local theme_name theme_variant theme_category theme_applied wallpaper

        theme_name="$(    python3 -c "import json; d=json.load(open('${theme_json}')); \
                          print(d.get('name','?'))"     2>/dev/null || echo '?')"
        theme_variant="$( python3 -c "import json; d=json.load(open('${theme_json}')); \
                          print(d.get('variant','?'))"  2>/dev/null || echo '?')"
        theme_category="$(python3 -c "import json; d=json.load(open('${theme_json}')); \
                          print(d.get('category','?'))" 2>/dev/null || echo '?')"
        theme_applied="$( python3 -c "import json; d=json.load(open('${theme_json}')); \
                          print(d.get('applied_at','?'))" 2>/dev/null || echo '?')"
        wallpaper="$(     python3 -c "import json; d=json.load(open('${theme_json}')); \
                          print(d.get('wallpaper','none'))" 2>/dev/null || echo '?')"

        _check_report $CHECK_PASS \
            "Active theme" \
            "${theme_name}  •  variant: ${theme_variant}  •  category: ${theme_category}"

        _check_report $CHECK_INFO \
            "Applied at" \
            "${theme_applied}"

        if [[ "$wallpaper" != "none" ]] && [[ -f "$wallpaper" ]]; then
            local wp_size
            wp_size="$(du -sh "$wallpaper" 2>/dev/null | cut -f1)"
            _check_report $CHECK_PASS \
                "Active wallpaper" \
                "${wallpaper##*/}  •  ${wp_size}"
        elif [[ "$wallpaper" != "none" ]]; then
            _check_report $CHECK_WARN \
                "Active wallpaper" \
                "File missing: ${wallpaper}" \
                "Re-apply theme: ash theme apply ${theme_name}"
        fi

        # ── Color palette validation ──────────────────────────────────────────────
        local color_count
        color_count="$(python3 -c \
            "import json; d=json.load(open('${theme_json}')); \
             colors=d.get('colors',{}); print(len(colors))" \
            2>/dev/null || echo 0)"

        if (( color_count >= 16 )); then
            _check_report $CHECK_PASS \
                "Color palette" \
                "${color_count} color entries  (full palette)"
        elif (( color_count > 0 )); then
            _check_report $CHECK_WARN \
                "Color palette" \
                "${color_count} colors  (expected ≥ 16)" \
                "Regenerate: ash theme apply ${theme_name} --force"
        else
            _check_report $CHECK_FAIL \
                "Color palette" \
                "Empty or missing colors in theme JSON" \
                "Regenerate: ash theme apply ${theme_name} --force"
        fi

        # ── WCAG contrast check ───────────────────────────────────────────────────
        local bg_hex fg_hex
        bg_hex="$(python3 -c \
            "import json; d=json.load(open('${theme_json}')); \
             print(d.get('colors',{}).get('base','#000000'))" \
            2>/dev/null || echo '#1e1e2e')"
        fg_hex="$(python3 -c \
            "import json; d=json.load(open('${theme_json}')); \
             print(d.get('colors',{}).get('text','#cdd6f4'))" \
            2>/dev/null || echo '#cdd6f4')"

        # Simple luminance contrast (approximate)
        if command -v python3 &>/dev/null; then
            local contrast_ratio
            contrast_ratio="$(python3 << PYEOF 2>/dev/null || echo '?'
import re
def hex_to_lum(h):
    h = h.lstrip('#')
    r,g,b = (int(h[i:i+2],16)/255 for i in (0,2,4))
    def lin(c): return c/12.92 if c<=0.04045 else ((c+0.055)/1.055)**2.4
    return 0.2126*lin(r)+0.7152*lin(g)+0.0722*lin(b)
bg = hex_to_lum('${bg_hex}')
fg = hex_to_lum('${fg_hex}')
l1,l2 = (max(bg,fg),min(bg,fg))
cr = (l1+0.05)/(l2+0.05)
print(f'{cr:.2f}:1')
PYEOF
)"

            if [[ "$contrast_ratio" != "?" ]]; then
                local ratio_num
                ratio_num="${contrast_ratio%%:*}"
                local ratio_int="${ratio_num%.*}"
                local ratio_dec="${ratio_num#*.}"

                if (( ratio_int >= 7 )) || (( ratio_int == 7 )); then
                    _check_report $CHECK_PASS \
                        "WCAG contrast ratio" \
                        "${contrast_ratio}  (AAA — excellent)"
                elif (( ratio_int >= 4 )); then
                    _check_report $CHECK_PASS \
                        "WCAG contrast ratio" \
                        "${contrast_ratio}  (AA — good)"
                elif (( ratio_int >= 3 )); then
                    _check_report $CHECK_WARN \
                        "WCAG contrast ratio" \
                        "${contrast_ratio}  (AA Large only — borderline)"
                else
                    _check_report $CHECK_FAIL \
                        "WCAG contrast ratio" \
                        "${contrast_ratio}  (FAIL — text may be unreadable)" \
                        "Choose a theme with better contrast: ash theme pick"
                fi
            fi
        fi
    else
        _check_report $CHECK_INFO \
            "current-theme.json" \
            "Found but python3 unavailable for parsing"
    fi

    # ── Active hyprland colors ────────────────────────────────────────────────────
    local hypr_colors="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/themes/colors.conf"
    if [[ -f "$hypr_colors" ]]; then
        local color_line_count
        color_line_count="$(wc -l < "$hypr_colors" 2>/dev/null || echo 0)"
        _check_report $CHECK_PASS \
            "Hyprland colors.conf" \
            "${color_line_count} lines  ($(date -r "$hypr_colors" '+%Y-%m-%d %H:%M' 2>/dev/null))"
    else
        _check_report $CHECK_WARN \
            "Hyprland colors.conf" \
            "Missing — colors not applied to Hyprland" \
            "Run: ash theme apply --force"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 03 — THEME LIBRARY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_te_library() {
    _check_header "📚 Theme Library"

    if [[ ! -d "$_TE_THEMES_DIR" ]]; then
        _check_report $CHECK_FAIL \
            "Themes directory" \
            "Missing: ${_TE_THEMES_DIR}" \
            "Clone ASH dotfiles: git clone https://github.com/ash-dotfiles"
        return $CHECK_FAIL
    fi

    # ── Count presets ─────────────────────────────────────────────────────────────
    local total_themes
    total_themes="$(find "${_TE_THEMES_DIR}/presets" \
                    -name 'theme.conf' -type f 2>/dev/null | wc -l)"
    _check_report $CHECK_INFO \
        "Theme presets" \
        "${total_themes} theme(s) in library"

    # ── Category breakdown ───────────────────────────────────────────────────────
    if [[ -d "${_TE_THEMES_DIR}/presets" ]]; then
        local -a categories=( dark light neon nature space pastel anime retro gradient seasonal mood gaming minimal special )
        for cat in "${categories[@]}"; do
            local cat_dir="${_TE_THEMES_DIR}/presets/${cat}"
            if [[ -d "$cat_dir" ]]; then
                local cat_count
                cat_count="$(find "$cat_dir" -name 'theme.conf' | wc -l)"
                _check_report $CHECK_INFO \
                    "  Category: ${cat}" \
                    "${cat_count} theme(s)"
            fi
        done
    fi

    # ── Theme schema validation ──────────────────────────────────────────────────
    local schema_file="${_TE_THEMES_DIR}/schema/theme-schema.json"
    if [[ -f "$schema_file" ]]; then
        _check_report $CHECK_PASS \
            "Theme JSON schema" \
            "$schema_file"
    else
        _check_report $CHECK_WARN \
            "Theme JSON schema" \
            "Missing: ${schema_file}" \
            "Restore from git: git checkout themes/schema/"
    fi

    # ── Spot-check 3 random themes for integrity ─────────────────────────────────
    local -a spot_themes=()
    mapfile -t spot_themes < <(
        find "${_TE_THEMES_DIR}/presets" -name 'colors.json' \
             2>/dev/null | shuf -n 5 2>/dev/null || true
    )

    local valid_spot=0 invalid_spot=0
    for theme_colors in "${spot_themes[@]}"; do
        if command -v python3 &>/dev/null; then
            if python3 -c "import json; json.load(open('${theme_colors}'))" \
               &>/dev/null 2>&1; then
                (( valid_spot++ )) || true
            else
                (( invalid_spot++ )) || true
                local theme_name="${theme_colors%/colors.json}"
                theme_name="${theme_name##*/}"
                _check_report $CHECK_WARN \
                    "  Invalid colors.json" \
                    "${theme_name}" \
                    "Fix: validate JSON in ${theme_colors}"
            fi
        fi
    done

    if [[ ${#spot_themes[@]} -gt 0 ]]; then
        if (( invalid_spot == 0 )); then
            _check_report $CHECK_PASS \
                "Theme integrity spot-check" \
                "${valid_spot}/${#spot_themes[@]} sampled themes: valid JSON"
        else
            _check_report $CHECK_WARN \
                "Theme integrity spot-check" \
                "${invalid_spot} of ${#spot_themes[@]} have invalid JSON"
        fi
    fi

    # ── User themes directory ────────────────────────────────────────────────────
    local user_themes="${_TE_THEMES_DIR}/user"
    if [[ -d "$user_themes" ]]; then
        local user_count
        user_count="$(find "$user_themes" -name 'theme.conf' | wc -l)"
        _check_report $CHECK_INFO \
            "User themes" \
            "${user_count} custom theme(s)"
    fi

    # ── Dynamic themes cache ─────────────────────────────────────────────────────
    local dynamic_cache="${_TE_CACHE}/themes"
    if [[ -d "$dynamic_cache" ]]; then
        local cache_size
        cache_size="$(du -sh "$dynamic_cache" 2>/dev/null | cut -f1)"
        local cache_count
        cache_count="$(find "$dynamic_cache" -name '*.json' | wc -l)"
        _check_report $CHECK_INFO \
            "Dynamic theme cache" \
            "${cache_count} cached palette(s)  •  ${cache_size}"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 04 — COLOR PIPELINE & TEMPLATES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_te_pipeline() {
    _check_header "🔄 Color Pipeline & Templates"

    local color_engine="${_TE_ENGINE_DIR}/color-engine"

    # ── Engine scripts ────────────────────────────────────────────────────────────
    local -a engine_scripts=(
        "extract.sh:Color extraction from wallpaper"
        "generate.sh:Palette generation"
        "harmonize.sh:Color harmonization"
        "contrast-check.sh:WCAG contrast validation"
        "wcag-validate.sh:Full WCAG validation"
        "palette.sh:Palette builder"
        "gradient.sh:Gradient generator"
        "material-you.sh:Material You adapter"
        "oklch.sh:OKLCH color space"
    )

    local scripts_ok=0 scripts_missing=0

    for script_entry in "${engine_scripts[@]}"; do
        IFS=':' read -r script_name desc <<< "$script_entry"
        local script_path="${color_engine}/${script_name}"

        if [[ -f "$script_path" ]]; then
            if bash -n "$script_path" &>/dev/null; then
                _check_report $CHECK_PASS \
                    "${script_name}" \
                    "Syntax OK  — ${desc}"
                (( scripts_ok++ )) || true
            else
                _check_report $CHECK_FAIL \
                    "${script_name}" \
                    "Syntax ERROR" \
                    "Fix: bash -n '${script_path}'"
                (( scripts_missing++ )) || true
            fi
        else
            _check_report $CHECK_WARN \
                "${script_name}" \
                "Missing  — ${desc}"
            (( scripts_missing++ )) || true
        fi
    done

    # ── Templates directory ───────────────────────────────────────────────────────
    local templates_dir="${color_engine}/templates"
    if [[ -d "$templates_dir" ]]; then
        local template_count
        template_count="$(find "$templates_dir" -name '*.template' | wc -l)"
        _check_report $CHECK_PASS \
            "Color templates" \
            "${template_count} .template files"

        # Check each expected template exists
        local -a expected_templates=(
            "hyprland" "waybar" "rofi" "kitty" "dunst"
            "swaync" "hyprlock" "gtk3" "gtk4" "fish"
            "nvim" "btop" "wlogout" "bat" "tmux" "starship"
        )
        local missing_templates=()
        for tpl in "${expected_templates[@]}"; do
            [[ -f "${templates_dir}/${tpl}.template" ]] || missing_templates+=("$tpl")
        done

        if [[ ${#missing_templates[@]} -eq 0 ]]; then
            _check_report $CHECK_PASS \
                "Template completeness" \
                "All ${#expected_templates[@]} expected templates present"
        else
            _check_report $CHECK_WARN \
                "Template completeness" \
                "${#missing_templates[@]} templates missing: ${missing_templates[*]}"
        fi
    else
        _check_report $CHECK_FAIL \
            "Templates directory" \
            "Missing: ${templates_dir}" \
            "Restore from git: git checkout engines/color-engine/templates/"
    fi

    # ── Live color extraction test ────────────────────────────────────────────────
    if command -v magick &>/dev/null || command -v convert &>/dev/null; then
        local test_wallpaper
        test_wallpaper="$(find "${ASH_ROOT_DIR:-$HOME/ash-dotfiles}/assets/wallpapers" \
                          -name '*.jpg' -o -name '*.png' 2>/dev/null | head -1 || echo '')"

        if [[ -n "$test_wallpaper" ]]; then
            local extract_cmd
            command -v magick &>/dev/null && extract_cmd="magick" || extract_cmd="convert"

            local extracted_colors
            extracted_colors="$(timeout 5 $extract_cmd "$test_wallpaper" \
                -colors 5 -format '%c' histogram:info: 2>/dev/null | \
                grep -oP '#[0-9a-fA-F]{6}' | head -5 || echo '')"

            if [[ -n "$extracted_colors" ]]; then
                local color_count
                color_count="$(printf '%s\n' "$extracted_colors" | wc -l)"
                _check_report $CHECK_PASS \
                    "Color extraction test" \
                    "Extracted ${color_count} dominant color(s) from wallpaper"
            else
                _check_report $CHECK_WARN \
                    "Color extraction test" \
                    "No colors extracted — check ImageMagick"
            fi
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 05 — HOT RELOAD ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_te_hot_reload() {
    _check_header "⚡ Hot Reload Engine"

    local reload_dir="${_TE_ENGINE_DIR}/hot-reload-engine"

    if [[ ! -d "$reload_dir" ]]; then
        _check_report $CHECK_FAIL \
            "Hot reload engine dir" \
            "Missing: ${reload_dir}"
        return $CHECK_FAIL
    fi

    # ── Reload scripts ────────────────────────────────────────────────────────────
    local -a reload_scripts=(
        "watcher.sh:File system watcher"
        "dispatcher.sh:Change event dispatcher"
        "debounce.sh:Debounce rapid changes"
        "reload-hyprland.sh:Reload Hyprland"
        "reload-waybar.sh:Reload Waybar"
        "reload-rofi.sh:Reload Rofi"
        "reload-kitty.sh:Reload Kitty"
        "reload-dunst.sh:Reload Dunst"
        "reload-swaync.sh:Reload SwayNC"
        "reload-gtk.sh:Reload GTK theme"
        "reload-nvim.sh:Reload Neovim"
        "reload-all.sh:Reload everything"
    )

    local reload_ok=0 reload_fail=0

    for rs_entry in "${reload_scripts[@]}"; do
        IFS=':' read -r rs_name rs_desc <<< "$rs_entry"
        local rs_path="${reload_dir}/${rs_name}"

        if [[ -f "$rs_path" ]]; then
            if bash -n "$rs_path" &>/dev/null; then
                _check_report $CHECK_PASS \
                    "${rs_name}" \
                    "${rs_desc}  •  syntax OK"
                (( reload_ok++ )) || true
            else
                _check_report $CHECK_FAIL \
                    "${rs_name}" \
                    "Syntax error!" \
                    "Fix: bash -n '${rs_path}'"
                (( reload_fail++ )) || true
            fi
        else
            _check_report $CHECK_WARN \
                "${rs_name}" \
                "Missing  — ${rs_desc}"
            (( reload_fail++ )) || true
        fi
    done

    _check_report $CHECK_INFO \
        "Reload scripts" \
        "${reload_ok} OK  •  ${reload_fail} missing/broken"

    # ── inotifywait availability ─────────────────────────────────────────────────
    if command -v inotifywait &>/dev/null; then
        _check_report $CHECK_PASS \
            "inotifywait" \
            "Available  (file system watcher)"
    else
        _check_report $CHECK_FAIL \
            "inotifywait" \
            "Missing — hot reload DISABLED" \
            "Install: paru -S inotify-tools"
    fi

    # ── ASH hot reload service ────────────────────────────────────────────────────
    if command -v systemctl &>/dev/null; then
        local svc_state
        svc_state="$(systemctl --user is-active ash-hot-reload 2>/dev/null || echo 'inactive')"
        if [[ "$svc_state" == "active" ]]; then
            _check_report $CHECK_PASS \
                "ash-hot-reload.service" \
                "Active  (auto-applying theme on config change)"
        else
            _check_report $CHECK_INFO \
                "ash-hot-reload.service" \
                "Not running  (state: ${svc_state})" \
                "Enable: systemctl --user enable --now ash-hot-reload"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 06 — WALLPAPER ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_te_wallpaper() {
    _check_header "🖼️  Wallpaper Engine"

    local wp_dir="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}/wallpapers"

    if [[ -d "$wp_dir" ]]; then
        local wp_total
        wp_total="$(find "$wp_dir" \
                    \( -name '*.jpg' -o -name '*.png' -o -name '*.webp' \
                    -o -name '*.gif' -o -name '*.mp4' \) \
                    2>/dev/null | wc -l)"
        _check_report $CHECK_INFO \
            "Wallpaper library" \
            "${wp_total} wallpaper file(s) in library"

        # Category counts
        local -a wp_cats=( dark light minimal abstract nature space anime cyberpunk retro 4k ultrawide animated )
        for cat in "${wp_cats[@]}"; do
            local cat_path="${wp_dir}/${cat}"
            if [[ -d "$cat_path" ]]; then
                local cat_count
                cat_count="$(find "$cat_path" \
                             \( -name '*.jpg' -o -name '*.png' -o -name '*.webp' \) \
                             2>/dev/null | wc -l)"
                (( cat_count > 0 )) && \
                    _check_report $CHECK_INFO \
                        "  ${cat}/" \
                        "${cat_count} wallpaper(s)"
            fi
        done
    else
        _check_report $CHECK_INFO \
            "Wallpaper library" \
            "Directory not found: ${wp_dir}"
    fi

    # ── swww daemon state ────────────────────────────────────────────────────────
    if command -v swww &>/dev/null; then
        if pgrep -x swww-daemon &>/dev/null; then
            _check_report $CHECK_PASS \
                "swww-daemon" \
                "Running  (wallpaper transitions active)"

            # Query current wallpaper
            local swww_query
            swww_query="$(swww query 2>/dev/null | head -1 || echo '')"
            if [[ -n "$swww_query" ]]; then
                _check_report $CHECK_INFO \
                    "  Current wallpaper" \
                    "$(printf '%s' "$swww_query" | sed 's/.*: //' | head -1)"
            fi
        else
            _check_report $CHECK_WARN \
                "swww-daemon" \
                "Not running — wallpaper will not change on theme switch" \
                "Start: swww-daemon &"
        fi
    fi

    # ── Wallpaper cache ──────────────────────────────────────────────────────────
    local wp_cache="${_TE_CACHE}/wallpapers"
    if [[ -d "$wp_cache" ]]; then
        local cache_size
        cache_size="$(du -sh "$wp_cache" 2>/dev/null | cut -f1)"
        local cache_count
        cache_count="$(find "$wp_cache" -type f | wc -l)"
        _check_report $CHECK_INFO \
            "Wallpaper cache" \
            "${cache_count} files  •  ${cache_size}"

        # Warn if cache too large
        local cache_bytes
        cache_bytes="$(du -sb "$wp_cache" 2>/dev/null | cut -f1 || echo 0)"
        if (( cache_bytes > 5368709120 )); then  # 5GB
            _check_report $CHECK_WARN \
                "Wallpaper cache size" \
                "${cache_size}  (>5GB — consider cleaning)" \
                "Clean: ash wallpaper cache --clean"
        fi
    fi

    # ── Wallpaper engine scripts ──────────────────────────────────────────────────
    local wp_engine="${_TE_ENGINE_DIR}/wallpaper-engine"
    if [[ -d "$wp_engine" ]]; then
        local wp_script_count
        wp_script_count="$(find "$wp_engine" -name '*.sh' | wc -l)"
        _check_report $CHECK_INFO \
            "Wallpaper engine" \
            "${wp_script_count} script(s) in engine"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 07 — PERFORMANCE BENCHMARK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_te_performance() {
    _check_header "⚡ Theme Engine Performance"

    # ── Benchmark: read theme JSON ────────────────────────────────────────────────
    local theme_json="${_TE_CFG}/current-theme.json"
    if [[ -f "$theme_json" ]] && command -v python3 &>/dev/null; then
        local start_ns end_ns elapsed_ms
        start_ns="$(date +%s%N)"
        python3 -c "import json; json.load(open('${theme_json}'))" &>/dev/null
        end_ns="$(date +%s%N)"
        elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))

        if (( elapsed_ms < 50 )); then
            _check_report $CHECK_PASS \
                "Theme JSON parse time" \
                "${elapsed_ms}ms  (excellent)"
        elif (( elapsed_ms < 200 )); then
            _check_report $CHECK_INFO \
                "Theme JSON parse time" \
                "${elapsed_ms}ms  (good)"
        else
            _check_report $CHECK_WARN \
                "Theme JSON parse time" \
                "${elapsed_ms}ms  (slow — check disk speed)"
        fi
    fi

    # ── Stored benchmark results ──────────────────────────────────────────────────
    local bench_db="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}/benchmarks/theme-apply-time.json"
    if [[ -f "$bench_db" ]] && command -v python3 &>/dev/null; then
        local avg_ms
        avg_ms="$(python3 -c \
            "import json; d=json.load(open('${bench_db}')); \
             vals=d.get('results',[]); \
             print(f'{sum(vals)/len(vals):.0f}' if vals else '?')" \
            2>/dev/null || echo '?')"

        if [[ "$avg_ms" != "?" ]]; then
            local avg_int="${avg_ms%.*}"
            if (( avg_int < 500 )); then
                _check_report $CHECK_PASS \
                    "Avg theme apply time" \
                    "${avg_ms}ms  (fast)"
            elif (( avg_int < 1500 )); then
                _check_report $CHECK_INFO \
                    "Avg theme apply time" \
                    "${avg_ms}ms  (acceptable)"
            else
                _check_report $CHECK_WARN \
                    "Avg theme apply time" \
                    "${avg_ms}ms  (slow)" \
                    "Profile with: ash benchmark theme-apply"
            fi
        fi
    fi

    # ── Color cache hit rate ──────────────────────────────────────────────────────
    local color_cache="${_TE_CACHE}/colors"
    if [[ -d "$color_cache" ]]; then
        local cached_palettes
        cached_palettes="$(find "$color_cache" -name '*.json' | wc -l)"
        _check_report $CHECK_INFO \
            "Color cache entries" \
            "${cached_palettes} palette(s) cached"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_check_theme_engine() {
    local mode="${1:-full}"

    _CHECK_PASS_COUNT=0;  _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0;  _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=();   _CHECK_WARNINGS=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;203;166;247m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🎨  ASH DOCTOR — THEME ENGINE CHECK                     ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  binaries • active theme • library • pipeline • reload   ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n=== ASH DOCTOR — THEME ENGINE CHECK ===\n'
    fi

    case "$mode" in
        quick)
            _chk_te_active_theme
            _chk_te_binaries
            ;;
        library)     _chk_te_library      ;;
        pipeline)    _chk_te_pipeline     ;;
        wallpaper)   _chk_te_wallpaper    ;;
        full|*)
            _chk_te_binaries
            _chk_te_active_theme
            _chk_te_library
            _chk_te_pipeline
            _chk_te_hot_reload
            _chk_te_wallpaper
            _chk_te_performance
            ;;
    esac

    _ash_check_system_summary
}

ash_check_theme_engine_quick() {
    local issues=0
    [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/ash/current-theme.json" ]] || (( issues++ )) || true
    command -v magick &>/dev/null || command -v convert &>/dev/null     || (( issues++ )) || true
    command -v inotifywait &>/dev/null                                   || (( issues++ )) || true
    if (( issues == 0 )); then
        ash_log_success "Theme engine: OK"
    else
        ash_log_warn "Theme engine: ${issues} issue(s) — run 'ash doctor full --theme'"
        return 1
    fi
}
