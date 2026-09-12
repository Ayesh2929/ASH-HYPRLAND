#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ███████╗██╗██╗  ██╗    ███████╗ ██████╗ ███╗   ██╗████████╗███████╗            ║
# ║  ██╔════╝██║╚██╗██╔╝    ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔════╝            ║
# ║  █████╗  ██║ ╚███╔╝     █████╗  ██║   ██║██╔██╗ ██║   ██║   ███████╗            ║
# ║  ██╔══╝  ██║ ██╔██╗     ██╔══╝  ██║   ██║██║╚██╗██║   ██║   ╚════██║            ║
# ║  ██║     ██║██╔╝ ██╗    ██║     ╚██████╔╝██║ ╚████║   ██║   ███████║            ║
# ║  ╚═╝     ╚═╝╚═╝  ╚═╝    ╚═╝      ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝            ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  FIXER: FONTS                                            ║
# ║  Install Nerd Fonts • Emoji fonts • System fonts • Rebuild fontconfig cache     ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_FIX_FONTS_LOADED:-}" == "1" ]] && return 0
readonly _ASH_FIX_FONTS_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _FF_DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
declare -gr _FF_CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
declare -gr _FF_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"
declare -gr _FF_FONT_DIR="${_FF_DATA}/fonts"
declare -gr _FF_FC_CONF="${_FF_CFG}/fontconfig"
declare -gr _FF_ASH_FONTS="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}/assets/fonts"

# Nerd Fonts version to install from GitHub releases
declare -gr _FF_NF_VERSION="v3.2.1"
declare -gr _FF_NF_BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${_FF_NF_VERSION}"

declare -g  _FF_INSTALLED=0
declare -g  _FF_SKIPPED=0
declare -g  _FF_FAILED=0
declare -ga _FF_INSTALLED_LIST=()
declare -ga _FF_FAILED_LIST=()

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ff_c()      { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_ff_reset()  { _ff_c '\033[0m';                           }
_ff_green()  { _ff_c '\033[38;2;166;227;161m';            }
_ff_red()    { _ff_c '\033[1;38;2;243;139;168m';          }
_ff_blue()   { _ff_c '\033[38;2;137;180;250m';            }
_ff_dim()    { _ff_c '\033[38;2;108;112;134m';            }
_ff_mauve()  { _ff_c '\033[1;38;2;203;166;247m';          }
_ff_yellow() { _ff_c '\033[38;2;249;226;175m';            }
_ff_teal()   { _ff_c '\033[38;2;148;226;213m';            }
_ff_pink()   { _ff_c '\033[38;2;245;194;231m';            }

_ff_section() {
    printf '\n'
    _ff_mauve
    printf '  ┌─────────────────────────────────────────────────────────\n'
    printf '  │  %s\n' "$1"
    printf '  └─────────────────────────────────────────────────────────\n'
    _ff_reset
}

_ff_action() {
    local icon="$1" label="$2" detail="$3" status="${4:-ok}"
    local color
    case "$status" in
        installed) color="$(_ff_green)"  ;;
        skipped)   color="$(_ff_dim)"    ;;
        failed)    color="$(_ff_red)"    ;;
        dry-run)   color="$(_ff_blue)"   ;;
        info)      color="$(_ff_yellow)" ;;
        progress)  color="$(_ff_teal)"   ;;
        *) color="" ;;
    esac

    printf '  %s  ' "$icon"
    _ff_teal; printf '%-40s' "$label"; _ff_reset
    printf '%s%s\033[0m\n' "$color" "$detail"
}

# Check if a font family is installed
_ff_font_exists() {
    local family="$1"
    fc-list 2>/dev/null | grep -qi "$family"
}

# Install a font package via package manager
_ff_install_pkg() {
    local pkg="$1"
    local label="${2:-$pkg}"
    local check_family="${3:-}"

    # Check if already installed
    if [[ -n "$check_family" ]] && _ff_font_exists "$check_family"; then
        _ff_action "✓" "$label" "already installed" "skipped"
        (( _FF_SKIPPED++ )) || true
        return 0
    fi

    if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
        _ff_action "~" "$label" "would install: paru -S $pkg" "dry-run"
        return 0
    fi

    # Determine package manager
    local install_cmd=""
    if command -v paru &>/dev/null; then
        install_cmd="paru -S --noconfirm --needed $pkg"
    elif command -v yay &>/dev/null; then
        install_cmd="yay -S --noconfirm --needed $pkg"
    elif command -v pacman &>/dev/null; then
        install_cmd="sudo pacman -S --noconfirm --needed $pkg"
    elif command -v apt &>/dev/null; then
        install_cmd="sudo apt-get install -y $pkg"
    elif command -v dnf &>/dev/null; then
        install_cmd="sudo dnf install -y $pkg"
    else
        _ff_action "✗" "$label" "No package manager found" "failed"
        (( _FF_FAILED++ )) || true
        return 1
    fi

    # Show progress
    _ff_action "⬇" "$label" "installing via ${install_cmd%% *}..." "progress"

    if eval "$install_cmd" &>/dev/null 2>&1; then
        _ff_action "✓" "$label" "installed  ✓" "installed"
        _FF_INSTALLED_LIST+=("$label")
        (( _FF_INSTALLED++ )) || true
    else
        _ff_action "✗" "$label" "install FAILED  (try: $install_cmd)" "failed"
        _FF_FAILED_LIST+=("$label")
        (( _FF_FAILED++ )) || true
    fi
}

# Download a Nerd Font from GitHub releases
_ff_download_nf() {
    local font_name="$1"     # e.g. "JetBrainsMono"
    local display="${2:-$font_name}"
    local check_family="${3:-}"

    if [[ -n "$check_family" ]] && _ff_font_exists "$check_family"; then
        _ff_action "✓" "NF: ${display}" "already installed" "skipped"
        (( _FF_SKIPPED++ )) || true
        return 0
    fi

    if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
        _ff_action "~" "NF: ${display}" \
            "would download ${_FF_NF_BASE_URL}/${font_name}.tar.xz" "dry-run"
        return 0
    fi

    if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
        _ff_action "✗" "NF: ${display}" \
            "curl/wget not found" "failed"
        (( _FF_FAILED++ )) || true
        return 1
    fi

    local url="${_FF_NF_BASE_URL}/${font_name}.tar.xz"
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    local tmp_file="${tmp_dir}/${font_name}.tar.xz"
    local font_install_dir="${_FF_FONT_DIR}/NerdFonts/${font_name}"

    mkdir -p "$font_install_dir" 2>/dev/null || true

    _ff_action "⬇" "NF: ${display}" "downloading ${_FF_NF_VERSION}..." "progress"

    # Download
    local download_ok=0
    if command -v curl &>/dev/null; then
        curl -fsSL --progress-bar "$url" -o "$tmp_file" 2>/dev/null && download_ok=1
    elif command -v wget &>/dev/null; then
        wget -q --show-progress "$url" -O "$tmp_file" 2>/dev/null && download_ok=1
    fi

    if [[ $download_ok -eq 0 ]]; then
        rm -rf "$tmp_dir" 2>/dev/null || true
        _ff_action "✗" "NF: ${display}" "download FAILED  (${url})" "failed"
        _FF_FAILED_LIST+=("$display")
        (( _FF_FAILED++ )) || true
        return 1
    fi

    # Extract
    if tar xf "$tmp_file" -C "$font_install_dir" &>/dev/null 2>&1; then
        rm -rf "$tmp_dir" 2>/dev/null || true
        local font_count
        font_count="$(find "$font_install_dir" \
                     \( -name '*.ttf' -o -name '*.otf' \) | wc -l)"
        _ff_action "✓" "NF: ${display}" \
            "installed ${font_count} font files → ${font_install_dir}" "installed"
        _FF_INSTALLED_LIST+=("NF: $display")
        (( _FF_INSTALLED++ )) || true
    else
        rm -rf "$tmp_dir" 2>/dev/null || true
        _ff_action "✗" "NF: ${display}" "extraction FAILED" "failed"
        _FF_FAILED_LIST+=("$display")
        (( _FF_FAILED++ )) || true
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 01 — NERD FONTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ff_fix_nerd_fonts() {
    _ff_section "⚡ Nerd Fonts Installation"

    mkdir -p "$_FF_FONT_DIR" 2>/dev/null || true

    # Show installation method preference
    if command -v paru &>/dev/null || command -v pacman &>/dev/null; then
        _ff_action "ℹ" "Install method" \
            "Package manager (paru/pacman)" "info"

        # Install via package manager (Arch/AUR)
        # Format: "package:display:fc-family-check"
        local -a nf_pkgs=(
            "ttf-jetbrains-mono-nerd:JetBrains Mono NF:JetBrainsMono Nerd Font"
            "ttf-firacode-nerd:Fira Code NF:FiraCode Nerd Font"
            "ttf-hack-nerd:Hack NF:Hack Nerd Font"
            "ttf-nerd-fonts-symbols:Nerd Fonts Symbols:Symbols Nerd Font"
            "ttf-nerd-fonts-symbols-mono:Nerd Fonts Symbols Mono:Symbols Nerd Font Mono"
            "noto-fonts-emoji:Noto Color Emoji:Noto Color Emoji"
            "noto-fonts:Noto Sans (system):Noto Sans"
            "ttf-ubuntu-font-family:Ubuntu Font Family:Ubuntu"
            "ttf-liberation:Liberation Fonts:Liberation Sans"
            "ttf-dejavu:DejaVu Fonts:DejaVu Sans"
            "ttf-inter:Inter:Inter"
        )

        for pkg_entry in "${nf_pkgs[@]}"; do
            IFS=':' read -r pkg display check_family <<< "$pkg_entry"
            _ff_install_pkg "$pkg" "$display" "$check_family"
        done

    else
        _ff_action "ℹ" "Install method" \
            "Direct GitHub download (${_FF_NF_VERSION})" "info"

        # Direct download method
        local -a nf_downloads=(
            "JetBrainsMono:JetBrains Mono NF:JetBrainsMono Nerd Font"
            "FiraCode:Fira Code NF:FiraCode Nerd Font"
            "Hack:Hack NF:Hack Nerd Font"
            "NerdFontsSymbolsOnly:Symbols Only:Symbols Nerd Font"
        )

        for dl_entry in "${nf_downloads[@]}"; do
            IFS=':' read -r name display check_family <<< "$dl_entry"
            _ff_download_nf "$name" "$display" "$check_family"
        done
    fi

    # Copy ASH bundled fonts if available
    if [[ -d "$_FF_ASH_FONTS" ]]; then
        local ash_font_count
        ash_font_count="$(find "$_FF_ASH_FONTS" \
                         \( -name '*.ttf' -o -name '*.otf' \) | wc -l)"

        if (( ash_font_count > 0 )); then
            if [[ "${ASH_FLAG_DRY_RUN:-0}" -ne 1 ]]; then
                cp -r "${_FF_ASH_FONTS}"/. "$_FF_FONT_DIR/" 2>/dev/null || true
                _ff_action "📋" "ASH bundled fonts" \
                    "${ash_font_count} font file(s) copied" "installed"
                (( _FF_INSTALLED++ )) || true
            else
                _ff_action "~" "ASH bundled fonts" \
                    "would copy ${ash_font_count} font(s)" "dry-run"
            fi
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 02 — FONTCONFIG CONFIGURATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ff_fix_fontconfig() {
    _ff_section "⚙️  Fontconfig Configuration"

    mkdir -p "${_FF_FC_CONF}/conf.d" 2>/dev/null || true

    # ── Enable system presets ────────────────────────────────────────────────────
    local sys_conf_avail="/usr/share/fontconfig/conf.avail"
    local sys_conf_d="/etc/fonts/conf.d"

    local -a recommended_presets=(
        "10-hinting-slight.conf:Slight hinting  (recommended for LCD)"
        "10-sub-pixel-rgb.conf:RGB subpixel rendering"
        "11-lcdfilter-default.conf:LCD filter default"
        "70-no-bitmaps.conf:Disable bitmap fonts"
    )

    for preset_entry in "${recommended_presets[@]}"; do
        IFS=':' read -r preset_file preset_label <<< "$preset_entry"
        local preset_src="/usr/share/fontconfig/conf.avail/${preset_file}"
        local preset_dst="${sys_conf_d}/${preset_file}"

        if [[ -L "$preset_dst" ]] && [[ -e "$preset_dst" ]]; then
            _ff_action "✓" "${preset_label}" \
                "already active  (${preset_file})" "skipped"
        elif [[ -f "$preset_src" ]]; then
            if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
                _ff_action "~" "${preset_label}" \
                    "would enable: sudo ln -s ${preset_src} ${preset_dst}" "dry-run"
            else
                if sudo ln -s "$preset_src" "$preset_dst" 2>/dev/null; then
                    _ff_action "✓" "${preset_label}" \
                        "enabled  (${preset_file})" "installed"
                    (( _FF_INSTALLED++ )) || true
                else
                    _ff_action "ℹ" "${preset_label}" \
                        "already enabled or needs root" "info"
                fi
            fi
        fi
    done

    # ── User fonts.conf ───────────────────────────────────────────────────────────
    local user_fonts_conf="${_FF_FC_CONF}/fonts.conf"

    if [[ ! -f "$user_fonts_conf" ]] || [[ "${ASH_FLAG_FORCE:-0}" -eq 1 ]]; then
        if [[ "${ASH_FLAG_DRY_RUN:-0}" -ne 1 ]]; then
            cat > "$user_fonts_conf" << 'FONTSCONF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<!--
  ╔════════════════════════════════════════════════════╗
  ║  ASH Dotfiles — fontconfig user configuration      ║
  ╚════════════════════════════════════════════════════╝
-->
<fontconfig>

  <!-- ── Hinting ──────────────────────────────────────── -->
  <match target="font">
    <edit name="hinting" mode="assign"><bool>true</bool></edit>
    <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
    <edit name="antialias" mode="assign"><bool>true</bool></edit>
    <edit name="rgba" mode="assign"><const>rgb</const></edit>
    <edit name="lcdfilter" mode="assign"><const>lcddefault</const></edit>
  </match>

  <!-- ── Emoji rendering priority ─────────────────────── -->
  <alias>
    <family>emoji</family>
    <prefer>
      <family>Noto Color Emoji</family>
      <family>JoyPixels</family>
      <family>Twemoji</family>
    </prefer>
  </alias>

  <!-- ── Nerd Fonts fallback chain ────────────────────── -->
  <alias>
    <family>monospace</family>
    <prefer>
      <family>JetBrainsMono Nerd Font</family>
      <family>FiraCode Nerd Font</family>
      <family>Hack Nerd Font</family>
      <family>Symbols Nerd Font</family>
      <family>Noto Color Emoji</family>
    </prefer>
  </alias>

  <!-- ── Sans-serif fallback ──────────────────────────── -->
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Inter</family>
      <family>Noto Sans</family>
      <family>DejaVu Sans</family>
    </prefer>
  </alias>

  <!-- ── Serif fallback ───────────────────────────────── -->
  <alias>
    <family>serif</family>
    <prefer>
      <family>Noto Serif</family>
      <family>DejaVu Serif</family>
      <family>Liberation Serif</family>
    </prefer>
  </alias>

  <!-- ── Disable bitmap fonts (cleaner rendering) ─────── -->
  <selectfont>
    <rejectfont>
      <pattern><patelt name="scalable"><bool>false</bool></patelt></pattern>
    </rejectfont>
  </selectfont>

</fontconfig>
FONTSCONF
            _ff_action "✨" "~/.config/fontconfig/fonts.conf" \
                "generated optimal config" "installed"
            (( _FF_INSTALLED++ )) || true
        else
            _ff_action "~" "~/.config/fontconfig/fonts.conf" \
                "would generate optimal config" "dry-run"
        fi
    else
        _ff_action "✓" "~/.config/fontconfig/fonts.conf" \
            "already exists" "skipped"
        (( _FF_SKIPPED++ )) || true
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 03 — REBUILD FONT CACHE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ff_rebuild_cache() {
    _ff_section "🔄 Font Cache Rebuild"

    if ! command -v fc-cache &>/dev/null; then
        _ff_action "✗" "fc-cache" \
            "not found — install fontconfig" "failed"
        (( _FF_FAILED++ )) || true
        return 1
    fi

    if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
        _ff_action "~" "Font cache" "would run: fc-cache -fv" "dry-run"
        return 0
    fi

    _ff_action "⏳" "Font cache" "rebuilding..." "progress"

    if fc-cache -fv &>/dev/null 2>&1; then
        local font_total
        font_total="$(fc-list 2>/dev/null | wc -l)"
        _ff_action "✓" "Font cache" \
            "rebuilt  •  ${font_total} font faces available" "installed"
        (( _FF_INSTALLED++ )) || true
    else
        _ff_action "✗" "Font cache" "fc-cache -fv FAILED" "failed"
        (( _FF_FAILED++ )) || true
    fi

    # Verify Nerd Font icons render
    if command -v fc-list &>/dev/null; then
        local nf_count
        nf_count="$(fc-list | grep -ci 'nerd\|nf ' || echo 0)"
        _ff_action "ℹ" "Nerd Font faces" \
            "${nf_count} faces registered" "info"

        # Check specific critical families
        local -a crit_families=(
            "JetBrainsMono Nerd Font:JetBrains Mono NF"
            "Symbols Nerd Font:Symbols Only NF"
            "Noto Color Emoji:Emoji"
        )

        for fam_entry in "${crit_families[@]}"; do
            IFS=':' read -r family label <<< "$fam_entry"
            if _ff_font_exists "$family"; then
                _ff_action "✓" "  ${label}" "registered in fontconfig" "info"
            else
                _ff_action "✗" "  ${label}" "NOT found after install!" "failed"
            fi
        done
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RESULTS & GLYPH TEST
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ff_report() {
    printf '\n'
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\033[1;38;2;203;166;247m'
        printf '  ╔══════════════════════════════════════════════════════════╗\n'
        printf '  ║  🔤  FONTS FIX — RESULTS                                  ║\n'
        printf '  ╠══════════════════════════════════════════════════════════╣\n'
        printf '  ║  \033[38;2;166;227;161m✓ %-3d installed\033[38;2;203;166;247m  ' "$_FF_INSTALLED"
        printf '  \033[38;2;108;112;134m○ %-3d skipped\033[38;2;203;166;247m  ' "$_FF_SKIPPED"
        printf '  \033[38;2;243;139;168m✗ %-3d failed\033[38;2;203;166;247m                ║\n' "$_FF_FAILED"
        printf '  ╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '  RESULTS: %d installed  •  %d skipped  •  %d failed\n' \
            "$_FF_INSTALLED" "$_FF_SKIPPED" "$_FF_FAILED"
    fi

    # ── Glyph render test ─────────────────────────────────────────────────────────
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]] && \
       [[ "${ASH_FLAG_QUIET:-0}" -eq 0 ]]; then
        printf '\n'
        _ff_mauve; printf '  🔤 Nerd Font glyph render test:\n'; _ff_reset
        _ff_pink
        printf '  '
        printf '            '
        printf '\n'
        _ff_dim
        printf '  (icons above should be symbols — not □ boxes or ? marks)\n'
        _ff_reset

        printf '\n'
        _ff_mauve; printf '  😀 Emoji render test:\n'; _ff_reset
        printf '  🎨 🔥 ⚡ 🌊 🎮 🖥️  💻 🐧 🦊 🚀 🎵 🏆\n'
        _ff_dim; printf '  (emoji above should be colorful)\n'; _ff_reset
    fi

    if (( _FF_INSTALLED > 0 )); then
        printf '\n'
        _ff_green; printf '  ✓ '; _ff_reset
        printf 'Restart applications to use newly installed fonts.\n'
    fi

    if [[ ${#_FF_FAILED_LIST[@]} -gt 0 ]]; then
        printf '\n'
        _ff_red; printf '  Failed fonts:\n'; _ff_reset
        for fail in "${_FF_FAILED_LIST[@]}"; do
            printf '    • %s\n' "$fail"
        done
    fi
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_fix_fonts() {
    local mode="${1:-all}"

    _FF_INSTALLED=0; _FF_SKIPPED=0; _FF_FAILED=0
    _FF_INSTALLED_LIST=(); _FF_FAILED_LIST=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;203;166;247m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🔤  ASH FIXER — FONTS                                    ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  Nerd Fonts v%-12s  •  fontconfig  •  cache rebuild  ║\n' \
            "$_FF_NF_VERSION"
        [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]] && \
            printf '║  MODE: DRY RUN  (no fonts will be installed)             ║\n' || \
            printf '║  MODE: LIVE     (fonts will be installed)                 ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    # Ensure user font directory exists
    mkdir -p "$_FF_FONT_DIR" 2>/dev/null || true

    case "$mode" in
        nerd)        _ff_fix_nerd_fonts  ;;
        fontconfig)  _ff_fix_fontconfig  ;;
        cache)       _ff_rebuild_cache   ;;
        all|*)
            _ff_fix_nerd_fonts
            _ff_fix_fontconfig
            _ff_rebuild_cache
            ;;
    esac

    _ff_report
}
