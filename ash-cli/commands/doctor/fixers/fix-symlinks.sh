#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ███████╗██╗   ██╗███╗   ███╗██╗     ██╗███╗   ██╗██╗  ██╗███████╗              ║
# ║  ██╔════╝╚██╗ ██╔╝████╗ ████║██║     ██║████╗  ██║██║ ██╔╝██╔════╝              ║
# ║  ███████╗ ╚████╔╝ ██╔████╔██║██║     ██║██╔██╗ ██║█████╔╝ ███████╗              ║
# ║  ╚════██║  ╚██╔╝  ██║╚██╔╝██║██║     ██║██║╚██╗██║██╔═██╗ ╚════██║              ║
# ║  ███████║   ██║   ██║ ╚═╝ ██║███████╗██║██║ ╚████║██║  ██╗███████║              ║
# ║  ╚══════╝   ╚═╝   ╚═╝     ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝              ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  FIXER: SYMLINKS                                         ║
# ║  Detect broken symlinks • Remove dangling links • Recreate missing links        ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_FIX_SYMLINKS_LOADED:-}" == "1" ]] && return 0
readonly _ASH_FIX_SYMLINKS_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _FSL_ASH_ROOT="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}"
declare -gr _FSL_CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
declare -gr _FSL_DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
declare -gr _FSL_BIN="$HOME/.local/bin"

declare -g  _FSL_FIXED=0
declare -g  _FSL_REMOVED=0
declare -g  _FSL_SKIPPED=0
declare -g  _FSL_FAILED=0
declare -ga _FSL_BROKEN=()
declare -ga _FSL_ERRORS=()

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fsl_c()      { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_fsl_reset()  { _fsl_c '\033[0m';                      }
_fsl_green()  { _fsl_c '\033[38;2;166;227;161m';       }
_fsl_red()    { _fsl_c '\033[1;38;2;243;139;168m';     }
_fsl_yellow() { _fsl_c '\033[1;38;2;249;226;175m';     }
_fsl_blue()   { _fsl_c '\033[38;2;137;180;250m';       }
_fsl_dim()    { _fsl_c '\033[38;2;108;112;134m';       }
_fsl_peach()  { _fsl_c '\033[38;2;250;179;135m';       }
_fsl_teal()   { _fsl_c '\033[38;2;148;226;213m';       }

_fsl_section() {
    printf '\n'
    _fsl_peach
    printf '  ┌─────────────────────────────────────────────────────────\n'
    printf '  │  %s\n' "$1"
    printf '  └─────────────────────────────────────────────────────────\n'
    _fsl_reset
}

_fsl_action() {
    local icon="$1" label="$2" detail="$3" status="${4:-ok}"
    local color
    case "$status" in
        fixed)    color="$(_fsl_green)"  ;;
        removed)  color="$(_fsl_yellow)" ;;
        skipped)  color="$(_fsl_dim)"    ;;
        failed)   color="$(_fsl_red)"    ;;
        dry-run)  color="$(_fsl_blue)"   ;;
        broken)   color="$(_fsl_red)"    ;;
        *) color="" ;;
    esac

    printf '  %s  ' "$icon"
    _fsl_teal; printf '%-42s' "$label"; _fsl_reset
    printf '%s%s\033[0m\n' "$color" "$detail"
}

# Create or repair a symlink
_fsl_link() {
    local src="$1"           # Target of symlink (must exist)
    local dst="$2"           # Symlink path to create
    local label="${3:-}"

    label="${label:-${dst##$HOME/}}"

    if [[ ! -e "$src" ]]; then
        _fsl_action "○" "$label" "source missing — skip: ${src##$HOME/}" "skipped"
        (( _FSL_SKIPPED++ )) || true
        return 0
    fi

    if [[ -L "$dst" ]]; then
        local current_target
        current_target="$(readlink -f "$dst" 2>/dev/null || echo '')"
        if [[ "$current_target" == "$(readlink -f "$src" 2>/dev/null)" ]]; then
            _fsl_action "✓" "$label" "symlink OK → ${src##$HOME/}" "skipped"
            (( _FSL_SKIPPED++ )) || true
            return 0
        fi
        # Wrong target — will recreate
    fi

    if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
        _fsl_action "~" "$label" "would link → ${src##$HOME/}" "dry-run"
        return 0
    fi

    mkdir -p "$(dirname "$dst")" 2>/dev/null || true

    if ln -sfn "$src" "$dst" 2>/dev/null; then
        _fsl_action "🔗" "$label" "→ ${src##$HOME/}" "fixed"
        (( _FSL_FIXED++ )) || true
    else
        _fsl_action "✗" "$label" "link FAILED" "failed"
        _FSL_ERRORS+=("$label")
        (( _FSL_FAILED++ )) || true
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 01 — SCAN & REPAIR BROKEN SYMLINKS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fsl_fix_broken() {
    _fsl_section "🔍 Broken Symlink Scan & Repair"

    # Scan important directories for broken symlinks
    local -a scan_dirs=(
        "$_FSL_CFG"
        "$HOME/.local/bin"
        "$HOME/.local/share/ash"
        "$_FSL_ASH_ROOT"
    )

    local broken_total=0
    local repaired=0

    for scan_dir in "${scan_dirs[@]}"; do
        [[ -d "$scan_dir" ]] || continue

        local broken_in_dir=()
        mapfile -t broken_in_dir < <(
            find "$scan_dir" -maxdepth 6 -type l ! -e 2>/dev/null | head -50
        )

        for broken_link in "${broken_in_dir[@]}"; do
            [[ -z "$broken_link" ]] && continue
            local rel="${broken_link##$HOME/}"
            local target
            target="$(readlink "$broken_link" 2>/dev/null || echo '?')"

            _FSL_BROKEN+=("$rel")
            (( broken_total++ )) || true

            _fsl_action "💔" "${rel}" "→ ${target}  (dangling)" "broken"

            # Attempt auto-repair: if target looks like it should be in ASH root
            if [[ "$target" =~ ash-dotfiles ]]; then
                local potential_src
                potential_src="${_FSL_ASH_ROOT}/${target##*/ash-dotfiles/}"

                if [[ -e "$potential_src" ]]; then
                    if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
                        _fsl_action "~" "  ↳ would relink" \
                            "→ ${potential_src##$HOME/}" "dry-run"
                    else
                        ln -sfn "$potential_src" "$broken_link" 2>/dev/null && {
                            _fsl_action "🔧" "  ↳ repaired" \
                                "→ ${potential_src##$HOME/}" "fixed"
                            (( repaired++, _FSL_FIXED++ )) || true
                        } || {
                            _fsl_action "✗" "  ↳ repair failed" \
                                "remove: rm '${broken_link}'" "failed"
                        }
                    fi
                else
                    # Cannot repair — offer to remove
                    if [[ "${ASH_FLAG_FORCE:-0}" -eq 1 ]]; then
                        if [[ "${ASH_FLAG_DRY_RUN:-0}" -ne 1 ]]; then
                            rm "$broken_link" 2>/dev/null && {
                                _fsl_action "🗑" "  ↳ removed dangling link" \
                                    "$rel" "removed"
                                (( _FSL_REMOVED++ )) || true
                            } || true
                        else
                            _fsl_action "~" "  ↳ would remove" "$rel" "dry-run"
                        fi
                    else
                        _fsl_action "⚠" "  ↳ manual removal:" \
                            "rm '${broken_link}'" "failed"
                    fi
                fi
            fi
        done
    done

    if (( broken_total == 0 )); then
        _fsl_action "✓" "Broken symlink scan" \
            "None found in ${#scan_dirs[@]} directories" "skipped"
    else
        _fsl_action "📊" "Broken symlinks summary" \
            "${broken_total} found  •  ${repaired} repaired" "fixed"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 02 — ASH CONFIG SYMLINKS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fsl_fix_ash_links() {
    _fsl_section "🔗 ASH Configuration Symlinks"

    # Core config directories — link from repo to ~/.config
    local -a config_links=(
        "hypr:${_FSL_CFG}/hypr"
        "waybar:${_FSL_CFG}/waybar"
        "kitty:${_FSL_CFG}/kitty"
        "fish:${_FSL_CFG}/fish"
        "rofi:${_FSL_CFG}/rofi"
        "nvim:${_FSL_CFG}/nvim"
        "dunst:${_FSL_CFG}/dunst"
        "swaync:${_FSL_CFG}/swaync"
        "btop:${_FSL_CFG}/btop"
        "cava:${_FSL_CFG}/cava"
        "fastfetch:${_FSL_CFG}/fastfetch"
        "yazi:${_FSL_CFG}/yazi"
        "mpv:${_FSL_CFG}/mpv"
        "zathura:${_FSL_CFG}/zathura"
        "lazygit:${_FSL_CFG}/lazygit"
        "helix:${_FSL_CFG}/helix"
        "atuin:${_FSL_CFG}/atuin"
    )

    for link_entry in "${config_links[@]}"; do
        IFS=':' read -r src_rel dst_path <<< "$link_entry"
        local src_path="${_FSL_ASH_ROOT}/config/${src_rel}"
        _fsl_link "$src_path" "$dst_path" "${src_rel}/"
    done

    # Individual file symlinks
    local -a file_links=(
        "config/starship/starship.toml:${_FSL_CFG}/starship.toml"
        "config/git/.gitconfig:${_FSL_CFG}/git/.gitconfig"
        "config/git/.gitignore_global:${_FSL_CFG}/git/.gitignore_global"
    )

    for link_entry in "${file_links[@]}"; do
        IFS=':' read -r src_rel dst_path <<< "$link_entry"
        local src_path="${_FSL_ASH_ROOT}/${src_rel}"
        _fsl_link "$src_path" "$dst_path" "$(basename "$dst_path")"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 03 — BINARY SYMLINKS (~/.local/bin)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fsl_fix_bin_links() {
    _fsl_section "⚡ Binary Symlinks  (~/.local/bin)"

    mkdir -p "$_FSL_BIN" 2>/dev/null || true

    # Main ash CLI
    local ash_bin="${_FSL_ASH_ROOT}/ash-cli/ash"
    local ash_link="${_FSL_BIN}/ash"

    _fsl_link "$ash_bin" "$ash_link" "ash  (main CLI)"

    # Verify ash is in PATH
    if echo "$PATH" | tr ':' '\n' | grep -qx "$_FSL_BIN"; then
        _fsl_action "✓" "~/.local/bin in PATH" "PATH contains ${_FSL_BIN}" "skipped"
    else
        _fsl_action "⚠" "~/.local/bin NOT in PATH" \
            "Add: export PATH=\"${_FSL_BIN}:\$PATH\" to shell config" "failed"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RESULTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fsl_report() {
    printf '\n'
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\033[1;38;2;250;179;135m'
        printf '  ╔══════════════════════════════════════════════════════════╗\n'
        printf '  ║  🔗  SYMLINKS FIX — RESULTS                               ║\n'
        printf '  ╠══════════════════════════════════════════════════════════╣\n'
        printf '  ║  \033[38;2;166;227;161m🔗 %-3d linked\033[38;2;250;179;135m  ' "$_FSL_FIXED"
        printf '  \033[38;2;249;226;175m🗑 %-3d removed\033[38;2;250;179;135m  ' "$_FSL_REMOVED"
        printf '  \033[38;2;108;112;134m○ %-3d skipped\033[38;2;250;179;135m  ' "$_FSL_SKIPPED"
        printf '  \033[38;2;243;139;168m✗ %-3d failed\033[38;2;250;179;135m   ║\n' "$_FSL_FAILED"
        printf '  ╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '  RESULTS: %d linked  •  %d removed  •  %d skipped  •  %d failed\n' \
            "$_FSL_FIXED" "$_FSL_REMOVED" "$_FSL_SKIPPED" "$_FSL_FAILED"
    fi

    if [[ ${#_FSL_BROKEN[@]} -gt 0 ]] && [[ "${ASH_FLAG_VERBOSE:-0}" -eq 1 ]]; then
        printf '\n'
        _fsl_yellow; printf '  Broken links found:\n'; _fsl_reset
        for bl in "${_FSL_BROKEN[@]}"; do
            printf '    • %s\n' "$bl"
        done
    fi
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_fix_symlinks() {
    local mode="${1:-all}"

    _FSL_FIXED=0; _FSL_REMOVED=0; _FSL_SKIPPED=0; _FSL_FAILED=0
    _FSL_BROKEN=(); _FSL_ERRORS=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;250;179;135m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🔗  ASH FIXER — SYMLINKS                                 ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]] && \
            printf '║  MODE: DRY RUN  (no changes will be made)                ║\n' || \
            printf '║  MODE: LIVE     (symlinks will be created/repaired)       ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    case "$mode" in
        broken) _fsl_fix_broken    ;;
        ash)    _fsl_fix_ash_links ;;
        bin)    _fsl_fix_bin_links ;;
        all|*)
            _fsl_fix_broken
            _fsl_fix_ash_links
            _fsl_fix_bin_links
            ;;
    esac

    _fsl_report
}
