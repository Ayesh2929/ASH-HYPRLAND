#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ███████╗ ██████╗ ███╗   ██╗████████╗███████╗                                   ║
# ║  ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔════╝                                   ║
# ║  █████╗  ██║   ██║██╔██╗ ██║   ██║   ███████╗                                   ║
# ║  ██╔══╝  ██║   ██║██║╚██╗██║   ██║   ╚════██║                                   ║
# ║  ██║     ╚██████╔╝██║ ╚████║   ██║   ███████║                                   ║
# ║  ╚═╝      ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝                                   ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  DOCTOR CHECK: FONTS                                     ║
# ║  Nerd Fonts • Icon fonts • GTK • fontconfig • rendering • Unicode               ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CHECK_FONTS_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CHECK_FONTS_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Check if a font family is available via fc-list
_font_exists() {
    local family="$1"
    fc-list 2>/dev/null | grep -qi "$family"
}

# Check if font file contains a specific Unicode codepoint (via fc-query)
_font_has_glyph() {
    local font_file="$1"
    local codepoint="$2"   # decimal
    fc-query --format='%{charset}\n' "$font_file" 2>/dev/null | \
        grep -qi "$(printf '%x' "$codepoint")" 2>/dev/null
}

# Count installed variants (Regular/Bold/Italic) of a family
_font_variant_count() {
    local family="$1"
    fc-list 2>/dev/null | grep -ic "$family" || echo 0
}

# Get font file path for a family
_font_path() {
    local family="$1"
    fc-list 2>/dev/null | grep -i "$family" | head -1 | cut -d: -f1
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 01 — FONT TOOLING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_fonts_tooling() {
    _check_header "🔧 Font Tooling"

    # ── fc-* tools (fontconfig) ──────────────────────────────────────────────────
    if command -v fc-list &>/dev/null; then
        local total_fonts
        total_fonts="$(fc-list 2>/dev/null | wc -l)"
        _check_report $CHECK_PASS \
            "fontconfig (fc-list)" \
            "${total_fonts} font faces installed"
    else
        _check_report $CHECK_FAIL \
            "fontconfig (fc-list)" \
            "Not found" \
            "Install: paru -S fontconfig"
        return $CHECK_FAIL
    fi

    if command -v fc-cache &>/dev/null; then
        _check_report $CHECK_PASS \
            "fc-cache" \
            "Available"
    fi

    if command -v fc-match &>/dev/null; then
        # Test: what does Sans/Mono resolve to?
        local sans_match mono_match serif_match
        sans_match="$( fc-match 'Sans'      --format='%{family} (%{file})' 2>/dev/null | head -1)"
        mono_match="$( fc-match 'Monospace' --format='%{family} (%{file})' 2>/dev/null | head -1)"
        serif_match="$(fc-match 'Serif'     --format='%{family} (%{file})' 2>/dev/null | head -1)"

        _check_report $CHECK_INFO "fc-match Sans"      "$sans_match"
        _check_report $CHECK_INFO "fc-match Monospace" "$mono_match"
        _check_report $CHECK_INFO "fc-match Serif"     "$serif_match"
    fi

    # ── Font cache freshness ──────────────────────────────────────────────────────
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/fontconfig"
    if [[ -d "$cache_dir" ]]; then
        local cache_age_days
        cache_age_days="$(( ( $(date +%s) - $(stat -c '%Y' "$cache_dir" 2>/dev/null || echo 0) ) / 86400 ))"
        if (( cache_age_days > 30 )); then
            _check_report $CHECK_WARN \
                "Font cache age" \
                "${cache_age_days} days old" \
                "Refresh: fc-cache -fv"
        else
            _check_report $CHECK_PASS \
                "Font cache age" \
                "${cache_age_days} day(s)  (fresh)"
        fi
    else
        _check_report $CHECK_INFO \
            "Font cache" \
            "No user cache at ${cache_dir} — run: fc-cache -fv"
    fi

    # ── Font directories ──────────────────────────────────────────────────────────
    local -a font_dirs=(
        "/usr/share/fonts"
        "/usr/local/share/fonts"
        "${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
        "$HOME/.fonts"
    )

    for dir in "${font_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local fcount
            fcount="$(find "$dir" \( -name '*.ttf' -o -name '*.otf' \
                       -o -name '*.woff' -o -name '*.woff2' \) \
                       2>/dev/null | wc -l)"
            _check_report $CHECK_INFO \
                "Font dir: ${dir##*/home*/}" \
                "${fcount} font files  (${dir})"
        fi
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 02 — NERD FONTS (CRITICAL FOR ASH RICE)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_fonts_nerd() {
    _check_header "⚡ Nerd Fonts  (required for icons in terminal)"

    # ── Detect Nerd Font version ──────────────────────────────────────────────────
    local nf_ver=""
    local nf_ver_file="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/.nerd-fonts-version"
    [[ -f "$nf_ver_file" ]] && nf_ver="$(cat "$nf_ver_file" 2>/dev/null)"

    if [[ -n "$nf_ver" ]]; then
        _check_report $CHECK_INFO \
            "Nerd Fonts version file" \
            "v${nf_ver}"
    fi

    # ── Check each popular Nerd Font family ──────────────────────────────────────
    # Format: "FC_name|display_name|package|critical"
    local -a nerd_fonts=(
        "JetBrainsMono Nerd Font|JetBrains Mono NF|ttf-jetbrains-mono-nerd|1"
        "FiraCode Nerd Font|Fira Code NF|ttf-firacode-nerd|1"
        "Hack Nerd Font|Hack NF|ttf-hack-nerd|1"
        "CaskaydiaCove Nerd Font|Cascadia Code NF|ttf-cascadia-code-nerd|0"
        "Iosevka Nerd Font|Iosevka NF|ttf-iosevka-nerd|0"
        "MesloLGS NF|MesloLGS NF|ttf-meslo-nerd-font-powerlevel10k|0"
        "SauceCodePro Nerd Font|Source Code Pro NF|ttf-sourcecodepro-nerd|0"
        "Mononoki Nerd Font|Mononoki NF|ttf-mononoki-nerd|0"
        "VictorMono Nerd Font|Victor Mono NF|ttf-victormono-nerd|0"
        "UbuntuMono Nerd Font|Ubuntu Mono NF|ttf-ubuntumono-nerd|0"
        "Terminus (TTF) for Windows|Terminus NF|terminus-font|0"
        "BigBlueTerm437 Nerd Font|BigBlue Terminal NF|ttf-bigblueterminal-nerd|0"
        "Symbols Nerd Font|Nerd Fonts Symbols Only|ttf-nerd-fonts-symbols|1"
        "Symbols Nerd Font Mono|Nerd Fonts Symbols Mono|ttf-nerd-fonts-symbols-mono|0"
    )

    local nf_found=0

    for nf_entry in "${nerd_fonts[@]}"; do
        IFS='|' read -r fc_name display pkg critical <<< "$nf_entry"

        if _font_exists "$fc_name"; then
            local var_count
            var_count="$(_font_variant_count "$fc_name")"
            _check_report $CHECK_PASS \
                "NF: ${display}" \
                "${var_count} variant(s)"
            (( nf_found++ )) || true
        else
            if [[ "$critical" == "1" ]]; then
                _check_report $CHECK_FAIL \
                    "NF: ${display}" \
                    "Not installed" \
                    "Install: paru -S ${pkg}"
            else
                _check_report $CHECK_INFO \
                    "NF: ${display}" \
                    "Not installed  (optional)" \
                    "Install: paru -S ${pkg}"
            fi
        fi
    done

    # ── Summary ──────────────────────────────────────────────────────────────────
    if (( nf_found == 0 )); then
        _check_report $CHECK_FAIL \
            "Nerd Fonts summary" \
            "NO Nerd Fonts found — icons will render as boxes □□□" \
            "Install: paru -S ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols"
    else
        _check_report $CHECK_PASS \
            "Nerd Fonts summary" \
            "${nf_found} Nerd Font family/families installed"
    fi

    # ── Nerd Font glyph smoke test ────────────────────────────────────────────────
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        # Test if terminal can render Nerd Font icons
        local test_glyphs="              "
        printf '\n  %s%s Icon render test:%s %s\n' \
            "$(printf '\033[38;2;203;166;247m')" \
            "Nerd Font" \
            "$(printf '\033[0m')" \
            "$test_glyphs"
        printf '  %s(Icons should appear — not boxes □ or question marks ?)\n%s\n' \
            "$(printf '\033[38;2;108;112;134m')" \
            "$(printf '\033[0m')"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 03 — ICON FONTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_fonts_icons() {
    _check_header "🎨 Icon Fonts & Symbol Fonts"

    # Format: "fc_name|display|package|critical"
    local -a icon_fonts=(
        "Font Awesome 6 Free|Font Awesome 6|ttf-font-awesome|1"
        "Font Awesome 5 Free|Font Awesome 5|ttf-font-awesome-5|0"
        "Material Design Icons|Material Icons|ttf-material-design-icons-extended|0"
        "Material Symbols|Material Symbols|ttf-material-symbols-variable-git|0"
        "Feather|Feather Icons|ttf-feather|0"
        "codicon|VS Code Icons (codicons)|ttf-codicons|0"
        "Typicons|Typicons|ttf-typicons|0"
        "weather icons|Weather Icons|ttf-weather-icons|0"
        "Segoe UI Emoji|Segoe UI Emoji|ttf-win10-emoji|0"
        "Twemoji|Twitter Emoji (Twemoji)|ttf-twemoji-color|0"
        "Noto Color Emoji|Noto Color Emoji|noto-fonts-emoji|1"
        "JoyPixels|JoyPixels Emoji|ttf-joypixels|0"
    )

    for icon_entry in "${icon_fonts[@]}"; do
        IFS='|' read -r fc_name display pkg critical <<< "$icon_entry"

        if _font_exists "$fc_name"; then
            _check_report $CHECK_PASS \
                "Icon: ${display}" \
                "Installed"
        else
            if [[ "$critical" == "1" ]]; then
                _check_report $CHECK_FAIL \
                    "Icon: ${display}" \
                    "Not installed" \
                    "Install: paru -S $pkg"
            else
                _check_report $CHECK_INFO \
                    "Icon: ${display}" \
                    "Not installed  (optional)" \
                    "Install: paru -S $pkg"
            fi
        fi
    done

    # ── Emoji rendering test ─────────────────────────────────────────────────────
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        local emoji_test="🎨 🎵 🔥 ⚡ 🌊 🎮 🖥️  💻 🐧 🦊"
        printf '\n  %sEmoji render test:%s %s\n' \
            "$(printf '\033[38;2;249;226;175m')" \
            "$(printf '\033[0m')" \
            "$emoji_test"
        printf '  %s(Emoji should be colorful — not boxes □)\n%s\n' \
            "$(printf '\033[38;2;108;112;134m')" \
            "$(printf '\033[0m')"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 04 — SYSTEM / UI FONTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_fonts_system() {
    _check_header "🖋️  System & UI Fonts"

    # Format: "fc_name|display|package|critical"
    local -a system_fonts=(
        "Inter|Inter (modern UI sans)|ttf-inter|1"
        "Noto Sans|Noto Sans (universal)|noto-fonts|1"
        "Roboto|Roboto (Material Design)|ttf-roboto|0"
        "Ubuntu|Ubuntu (Ubuntu DE)|ttf-ubuntu-font-family|0"
        "Cantarell|Cantarell (GNOME)|cantarell-fonts|0"
        "DejaVu Sans|DejaVu Sans|ttf-dejavu|1"
        "Liberation Sans|Liberation (MS compat)|ttf-liberation|1"
        "Noto Sans CJK|Noto CJK (Chinese/Japanese/Korean)|noto-fonts-cjk|0"
        "Noto Sans Arabic|Noto Arabic|noto-fonts-extra|0"
        "FreeSans|GNU FreeFont|gnu-free-fonts|0"
    )

    for sf_entry in "${system_fonts[@]}"; do
        IFS='|' read -r fc_name display pkg critical <<< "$sf_entry"

        if _font_exists "$fc_name"; then
            _check_report $CHECK_PASS \
                "System: ${display}" \
                "Installed"
        else
            if [[ "$critical" == "1" ]]; then
                _check_report $CHECK_FAIL \
                    "System: ${display}" \
                    "Not installed" \
                    "Install: paru -S $pkg"
            else
                _check_report $CHECK_INFO \
                    "System: ${display}" \
                    "Not installed  (optional)" \
                    "Install: paru -S $pkg"
            fi
        fi
    done

    # ── GTK font settings ────────────────────────────────────────────────────────
    local gtk_font_name=""
    if command -v gsettings &>/dev/null; then
        gtk_font_name="$(gsettings get org.gnome.desktop.interface font-name \
                        2>/dev/null | tr -d "'" || echo '')"
    fi

    local gtk3_settings="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini"
    if [[ -f "$gtk3_settings" ]]; then
        local gtk3_font
        gtk3_font="$(grep 'gtk-font-name' "$gtk3_settings" 2>/dev/null | \
                     cut -d= -f2 | sed 's/^ *//')"
        if [[ -n "$gtk3_font" ]]; then
            _check_report $CHECK_INFO \
                "GTK3 font" \
                "$gtk3_font"

            # Verify the font is actually installed
            local gtk3_family
            gtk3_family="$(printf '%s' "$gtk3_font" | sed 's/ [0-9]*$//')"
            if _font_exists "$gtk3_family"; then
                _check_report $CHECK_PASS \
                    "GTK3 font installed" \
                    "'${gtk3_family}' is available"
            else
                _check_report $CHECK_WARN \
                    "GTK3 font installed" \
                    "'${gtk3_family}' NOT found in font database" \
                    "Install font or update gtk-3.0/settings.ini"
            fi
        fi
    fi

    local gtk4_settings="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0/settings.ini"
    if [[ -f "$gtk4_settings" ]]; then
        local gtk4_font
        gtk4_font="$(grep 'gtk-font-name' "$gtk4_settings" 2>/dev/null | \
                     cut -d= -f2 | sed 's/^ *//')"
        [[ -n "$gtk4_font" ]] && \
            _check_report $CHECK_INFO \
                "GTK4 font" \
                "$gtk4_font"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 05 — MONOSPACE / TERMINAL FONTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_fonts_mono() {
    _check_header "💻 Monospace / Terminal Fonts"

    local -a mono_fonts=(
        "JetBrains Mono|JetBrains Mono|ttf-jetbrains-mono|1"
        "Fira Code|Fira Code  (ligatures)|ttf-fira-code|0"
        "Cascadia Code|Cascadia Code|ttf-cascadia-code|0"
        "Iosevka|Iosevka|ttf-iosevka|0"
        "Victor Mono|Victor Mono  (cursive italic)|ttf-victor-mono|0"
        "Inconsolata|Inconsolata|ttf-inconsolata|0"
        "Source Code Pro|Source Code Pro|adobe-source-code-pro-fonts|0"
        "Hack|Hack|ttf-hack|0"
        "Terminus|Terminus  (bitmap)|terminus-font|0"
        "Mononoki|Mononoki|ttf-mononoki|0"
        "Commit Mono|Commit Mono|ttf-commit-mono|0"
        "Geist Mono|Geist Mono|ttf-geist-mono|0"
    )

    local mono_found=0

    for mono_entry in "${mono_fonts[@]}"; do
        IFS='|' read -r fc_name display pkg critical <<< "$mono_entry"

        if _font_exists "$fc_name"; then
            local var_count
            var_count="$(_font_variant_count "$fc_name")"
            _check_report $CHECK_PASS \
                "Mono: ${display}" \
                "${var_count} variant(s)"
            (( mono_found++ )) || true
        else
            if [[ "$critical" == "1" ]]; then
                _check_report $CHECK_FAIL \
                    "Mono: ${display}" \
                    "Not installed" \
                    "Install: paru -S $pkg"
            else
                _check_report $CHECK_INFO \
                    "Mono: ${display}" \
                    "Not installed" \
                    "Install: paru -S $pkg"
            fi
        fi
    done

    if (( mono_found == 0 )); then
        _check_report $CHECK_FAIL \
            "Monospace fonts" \
            "No monospace fonts found — terminal will look broken" \
            "Install: paru -S ttf-jetbrains-mono"
    fi

    # ── Kitty font config ────────────────────────────────────────────────────────
    local kitty_conf="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/kitty.conf"
    if [[ -f "$kitty_conf" ]]; then
        local kitty_font
        kitty_font="$(grep '^font_family' "$kitty_conf" 2>/dev/null | \
                      sed 's/font_family\s*//' | head -1)"
        if [[ -n "$kitty_font" ]]; then
            _check_report $CHECK_INFO \
                "Kitty font_family" \
                "$kitty_font"

            if _font_exists "$kitty_font"; then
                _check_report $CHECK_PASS \
                    "  └─ Font installed" \
                    "'${kitty_font}' found"
            else
                _check_report $CHECK_WARN \
                    "  └─ Font installed" \
                    "'${kitty_font}' NOT in font database" \
                    "Install font or fix kitty.conf font_family"
            fi
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 06 — FONT RENDERING CONFIGURATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_fonts_rendering() {
    _check_header "🖊️  Font Rendering Configuration"

    # ── fontconfig local conf ────────────────────────────────────────────────────
    local fc_user_conf="${XDG_CONFIG_HOME:-$HOME/.config}/fontconfig/fonts.conf"
    local fc_user_dir="${XDG_CONFIG_HOME:-$HOME/.config}/fontconfig/conf.d"

    if [[ -f "$fc_user_conf" ]]; then
        local fc_lines
        fc_lines="$(wc -l < "$fc_user_conf" 2>/dev/null || echo 0)"
        _check_report $CHECK_PASS \
            "User fonts.conf" \
            "${fc_user_conf}  (${fc_lines} lines)"
    else
        _check_report $CHECK_INFO \
            "User fonts.conf" \
            "Not found  (using system defaults)"
    fi

    if [[ -d "$fc_user_dir" ]]; then
        local conf_count
        conf_count="$(find "$fc_user_dir" -name '*.conf' | wc -l)"
        _check_report $CHECK_INFO \
            "fontconfig conf.d" \
            "${conf_count} override file(s)"
    fi

    # ── Hinting ──────────────────────────────────────────────────────────────────
    local hint_setting
    hint_setting="$(fc-match 'Sans' --format='%{hintstyle}\n' 2>/dev/null | head -1 || echo '?')"
    case "$hint_setting" in
        hintfull)   _check_report $CHECK_INFO "Hinting style" "hintfull  (strong — good for LCD)" ;;
        hintslight) _check_report $CHECK_PASS "Hinting style" "hintslight  (recommended for HiDPI)" ;;
        hintmedium) _check_report $CHECK_INFO "Hinting style" "hintmedium" ;;
        hintnone)   _check_report $CHECK_INFO "Hinting style" "hintnone  (no hinting — best for HiDPI)" ;;
        *)          _check_report $CHECK_INFO "Hinting style" "${hint_setting:-unknown}" ;;
    esac

    # ── Antialiasing ─────────────────────────────────────────────────────────────
    local aa_setting
    aa_setting="$(fc-match 'Sans' --format='%{antialias}\n' 2>/dev/null | head -1 || echo '?')"
    if [[ "$aa_setting" == "True" ]]; then
        _check_report $CHECK_PASS \
            "Antialiasing" \
            "Enabled"
    else
        _check_report $CHECK_WARN \
            "Antialiasing" \
            "${aa_setting}  (disabled — fonts may look jagged)" \
            "Enable in ~/.config/fontconfig/fonts.conf"
    fi

    # ── Subpixel rendering ────────────────────────────────────────────────────────
    local rgba_setting
    rgba_setting="$(fc-match 'Sans' --format='%{rgba}\n' 2>/dev/null | head -1 || echo '?')"
    _check_report $CHECK_INFO \
        "Subpixel rendering (rgba)" \
        "${rgba_setting:-unknown}  (none=HiDPI, rgb=standard LCD)"

    # ── System fontconfig presets ─────────────────────────────────────────────────
    local -a expected_presets=(
        "10-hinting-slight.conf:Hinting slight preset"
        "10-sub-pixel-rgb.conf:RGB subpixel preset"
        "11-lcdfilter-default.conf:LCD filter default"
        "70-no-bitmaps.conf:No bitmap fonts"
    )

    local sys_conf_dir="/etc/fonts/conf.d"
    for preset_entry in "${expected_presets[@]}"; do
        IFS=':' read -r preset_file preset_name <<< "$preset_entry"
        if [[ -f "${sys_conf_dir}/${preset_file}" ]] || \
           [[ -L "${sys_conf_dir}/${preset_file}" ]]; then
            _check_report $CHECK_PASS \
                "Preset: ${preset_name}" \
                "Enabled  (${preset_file})"
        else
            _check_report $CHECK_INFO \
                "Preset: ${preset_name}" \
                "Not active"
        fi
    done

    # ── FreeType freetype2 ────────────────────────────────────────────────────────
    if ldconfig -p 2>/dev/null | grep -q 'libfreetype'; then
        local ft_ver
        ft_ver="$(pkg-config --modversion freetype2 2>/dev/null || echo 'installed')"
        _check_report $CHECK_PASS \
            "FreeType2" \
            "v${ft_ver}  (font rendering engine)"
    else
        _check_report $CHECK_WARN \
            "FreeType2" \
            "Not detected in ldconfig" \
            "Install: paru -S freetype2"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_check_fonts() {
    local mode="${1:-full}"   # quick | full | nerd | rendering

    _CHECK_PASS_COUNT=0;  _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0;  _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=();   _CHECK_WARNINGS=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;245;194;231m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🔤  ASH DOCTOR — FONTS CHECK                            ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  Checks: tooling • Nerd Fonts • icons • mono • rendering ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n=== ASH DOCTOR — FONTS CHECK ===\n'
    fi

    if ! command -v fc-list &>/dev/null; then
        _check_report $CHECK_FAIL \
            "fontconfig" \
            "fc-list not found — cannot run font checks" \
            "Install: paru -S fontconfig"
        _ash_check_system_summary
        return $CHECK_FAIL
    fi

    case "$mode" in
        quick)
            _chk_fonts_tooling
            _chk_fonts_nerd
            ;;
        nerd)
            _chk_fonts_tooling
            _chk_fonts_nerd
            _chk_fonts_icons
            ;;
        rendering)
            _chk_fonts_tooling
            _chk_fonts_rendering
            ;;
        full|*)
            _chk_fonts_tooling
            _chk_fonts_nerd
            _chk_fonts_icons
            _chk_fonts_system
            _chk_fonts_mono
            _chk_fonts_rendering
            ;;
    esac

    _ash_check_system_summary
}

ash_check_fonts_quick() {
    local issues=0
    command -v fc-list &>/dev/null         || (( issues++ )) || true
    _font_exists "Nerd Font"               || (( issues++ )) || true
    _font_exists "Noto"                    || (( issues++ )) || true
    if (( issues == 0 )); then
        ash_log_success "Fonts: OK  (fontconfig + Nerd Fonts present)"
    else
        ash_log_warn "Fonts: ${issues} issue(s) — run 'ash doctor full --fonts'"
        return 1
    fi
}
