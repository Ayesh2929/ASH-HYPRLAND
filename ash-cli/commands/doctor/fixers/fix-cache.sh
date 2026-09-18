#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ███████╗██╗██╗  ██╗     ██████╗ █████╗  ██████╗██╗  ██╗███████╗               ║
# ║  ██╔════╝██║╚██╗██╔╝    ██╔════╝██╔══██╗██╔════╝██║  ██║██╔════╝               ║
# ║  █████╗  ██║ ╚███╔╝     ██║     ███████║██║     ███████║█████╗                 ║
# ║  ██╔══╝  ██║ ██╔██╗     ██║     ██╔══██║██║     ██╔══██║██╔══╝                 ║
# ║  ██║     ██║██╔╝ ██╗    ╚██████╗██║  ██║╚██████╗██║  ██║███████╗               ║
# ║  ╚═╝     ╚═╝╚═╝  ╚═╝     ╚═════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝               ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  FIXER: CACHE                                            ║
# ║  Clean & rebuild all ASH caches • Font cache • Pacman cache • Thumbnail cache   ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_FIX_CACHE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_FIX_CACHE_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _FCA_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"
declare -gr _FCA_CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
declare -gr _FCA_DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
declare -gr _FCA_ASH_ROOT="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}"

declare -g  _FCA_FREED_BYTES=0
declare -g  _FCA_OPERATIONS=0
declare -g  _FCA_REBUILT=0
declare -ga _FCA_LOG=()

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fca_c()     { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_fca_reset() { _fca_c $'\033[0m';                          }
_fca_green() { _fca_c $'\033[38;2;166;227;161m';           }
_fca_red()   { _fca_c $'\033[1;38;2;243;139;168m';         }
_fca_blue()  { _fca_c $'\033[38;2;137;180;250m';           }
_fca_dim()   { _fca_c $'\033[38;2;108;112;134m';           }
_fca_teal()  { _fca_c $'\033[38;2;148;226;213m';           }
_fca_sky()   { _fca_c $'\033[1;38;2;137;220;235m';         }
_fca_yellow(){ _fca_c $'\033[38;2;249;226;175m';           }

_fca_human() {
    local bytes="${1:-0}"
    if   (( bytes >= 1073741824 )); then printf '%.1fGB' "$(echo "$bytes/1073741824" | bc -l 2>/dev/null || echo 0)"
    elif (( bytes >= 1048576    )); then printf '%.1fMB' "$(echo "$bytes/1048576"    | bc -l 2>/dev/null || echo 0)"
    elif (( bytes >= 1024       )); then printf '%.1fKB' "$(echo "$bytes/1024"       | bc -l 2>/dev/null || echo 0)"
    else printf '%dB' "$bytes"
    fi
}

_fca_section() {
    printf '\n'
    _fca_sky
    printf '  ┌─────────────────────────────────────────────────────────\n'
    printf '  │  %s\n' "$1"
    printf '  └─────────────────────────────────────────────────────────\n'
    _fca_reset
}

_fca_action() {
    local icon="$1" label="$2" detail="$3" status="${4:-ok}"
    local color
    case "$status" in
        cleaned)  color="$(_fca_green)"  ;;
        rebuilt)  color="$(_fca_teal)"   ;;
        skipped)  color="$(_fca_dim)"    ;;
        failed)   color="$(_fca_red)"    ;;
        dry-run)  color="$(_fca_blue)"   ;;
        info)     color="$(_fca_yellow)" ;;
        *) color="" ;;
    esac
    printf '  %s  ' "$icon"
    _fca_teal; printf '%-38s' "$label"; _fca_reset
    printf '%s%s\033[0m\n' "$color" "$detail"
}

# Clean a directory, return freed bytes
_fca_clean_dir() {
    local dir="$1"
    local label="${2:-${dir##$HOME/}}"
    local pattern="${3:-*}"
    local max_age_days="${4:-0}"   # 0 = all

    [[ -d "$dir" ]] || {
        _fca_action "○" "$label" "not found — skip" "skipped"
        return 0
    }

    # Measure before
    local size_before
    size_before="$(du -sb "$dir" 2>/dev/null | cut -f1 || echo 0)"

    if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
        local size_human
        size_human="$(_fca_human "$size_before")"
        _fca_action "~" "$label" "would free ~${size_human}" "dry-run"
        return 0
    fi

    # Remove files
    local find_args=("$dir" -name "$pattern")
    if (( max_age_days > 0 )); then
        find_args+=( -mtime "+${max_age_days}" )
    fi
    # The redirection belongs on the find call, not inside the array literal:
    # inside the parens the parser treats it as redirection of the assignment
    # and chokes on the stray `2`.
    find_args+=( -type f -delete )

    find "${find_args[@]}" 2>/dev/null || true

    # Remove empty subdirectories
    find "$dir" -type d -empty -delete 2>/dev/null || true

    # Measure after
    local size_after
    size_after="$(du -sb "$dir" 2>/dev/null | cut -f1 || echo 0)"
    local freed=$(( size_before - size_after ))
    (( freed < 0 )) && freed=0

    (( _FCA_FREED_BYTES += freed )) || true
    (( _FCA_OPERATIONS++ )) || true

    _fca_action "🗑" "$label" "freed $(_fca_human "$freed")" "cleaned"
    _FCA_LOG+=("Cleaned ${label}: $(_fca_human "$freed")")
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 01 — ASH CACHES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fca_clean_ash() {
    _fca_section "⚡ ASH Cache Cleanup"

    local ash_cache="${_FCA_CACHE}/ash"

    # Color cache — safe to clear (rebuilt on next theme apply)
    _fca_clean_dir "${ash_cache}/colors" "ash/colors cache"

    # Wallpaper thumbnail cache — rebuilds automatically
    _fca_clean_dir "${ash_cache}/wallpapers" "ash/wallpapers cache" \
        "*.thumb" 30

    # Theme render cache — older than 7 days
    _fca_clean_dir "${ash_cache}/themes" "ash/themes cache" \
        "*.json" 7

    # Download temp files
    _fca_clean_dir "${ash_cache}/tmp" "ash/tmp downloads"

    # Previews
    _fca_clean_dir "${ash_cache}/previews" "ash/previews"

    # Processing artifacts
    _fca_clean_dir "${ash_cache}/processing" "ash/processing temp"

    # AI model cache — only if explicitly requested
    if [[ "${ASH_FLAG_FORCE:-0}" -eq 1 ]]; then
        _fca_clean_dir "${ash_cache}/ai-models" "ash/ai-models cache"
    else
        _fca_action "○" "ash/ai-models cache" \
            "skipped  (use -f to clear AI model cache)" "skipped"
    fi

    # Rebuild ASH cache directory structure
    if [[ "${ASH_FLAG_DRY_RUN:-0}" -ne 1 ]]; then
        local -a ash_cache_dirs=(
            "${ash_cache}/colors"
            "${ash_cache}/wallpapers"
            "${ash_cache}/themes"
            "${ash_cache}/tmp"
            "${ash_cache}/previews"
        )
        for d in "${ash_cache_dirs[@]}"; do
            mkdir -p "$d" 2>/dev/null || true
        done
        _fca_action "✨" "ASH cache structure" "rebuilt" "rebuilt"
        (( _FCA_REBUILT++ )) || true
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 02 — FONT CACHE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fca_rebuild_font_cache() {
    _fca_section "🔤 Font Cache Rebuild"

    local font_cache="${_FCA_CACHE}/fontconfig"

    # Show current size
    local fc_size
    fc_size="$(du -sh "$font_cache" 2>/dev/null | cut -f1 || echo '?')"
    _fca_action "ℹ" "Current font cache" "${fc_size}" "info"

    # Clear old cache
    if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
        _fca_action "~" "Font cache" "would clear and rebuild" "dry-run"
        return 0
    fi

    # Remove old cache files
    if [[ -d "$font_cache" ]]; then
        local size_before
        size_before="$(du -sb "$font_cache" 2>/dev/null | cut -f1 || echo 0)"
        rm -rf "${font_cache:?}"/* 2>/dev/null || true
        local size_after
        size_after="$(du -sb "$font_cache" 2>/dev/null | cut -f1 || echo 0)"
        local freed=$(( size_before - size_after ))
        (( freed < 0 )) && freed=0
        (( _FCA_FREED_BYTES += freed )) || true
        _fca_action "🗑" "Font cache cleared" "$(_fca_human "$freed") freed" "cleaned"
    fi

    # Rebuild with fc-cache
    if command -v fc-cache &>/dev/null; then
        if fc-cache -fv &>/dev/null 2>&1; then
            local new_size
            new_size="$(du -sh "$font_cache" 2>/dev/null | cut -f1 || echo '?')"
            _fca_action "✨" "Font cache rebuilt" \
                "fc-cache -fv  •  new size: ${new_size}" "rebuilt"
            (( _FCA_REBUILT++ )) || true
        else
            _fca_action "✗" "Font cache rebuild" "fc-cache FAILED" "failed"
        fi
    else
        _fca_action "○" "Font cache rebuild" \
            "fc-cache not found  (install fontconfig)" "skipped"
    fi

    # Count fonts now available
    if command -v fc-list &>/dev/null; then
        local font_count
        font_count="$(fc-list 2>/dev/null | wc -l)"
        _fca_action "✓" "Fonts now available" "${font_count} font faces" "info"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 03 — SYSTEM CACHES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fca_clean_system() {
    _fca_section "🗑️  System Cache Cleanup"

    # ── Thumbnail cache ────────────────────────────────────────────────────────────
    _fca_clean_dir "${_FCA_CACHE}/thumbnails" \
        "Thumbnail cache" "*.png" 30

    # ── Trash ─────────────────────────────────────────────────────────────────────
    local trash_files="${_FCA_DATA}/Trash/files"
    local trash_info="${_FCA_DATA}/Trash/info"

    if [[ -d "$trash_files" ]]; then
        local trash_size
        trash_size="$(du -sb "$trash_files" 2>/dev/null | cut -f1 || echo 0)"
        local trash_count
        trash_count="$(find "$trash_files" -maxdepth 1 -mindepth 1 | wc -l)"

        if (( trash_count > 0 )); then
            if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
                _fca_action "~" "Trash" \
                    "would empty: ${trash_count} items  $(_fca_human "$trash_size")" \
                    "dry-run"
            elif [[ "${ASH_FLAG_FORCE:-0}" -eq 1 ]]; then
                rm -rf "${trash_files:?}"/* "${trash_info:?}"/* 2>/dev/null || true
                (( _FCA_FREED_BYTES += trash_size, _FCA_OPERATIONS++ )) || true
                _fca_action "🗑" "Trash" \
                    "emptied ${trash_count} items  $(_fca_human "$trash_size")" "cleaned"
            else
                _fca_action "○" "Trash" \
                    "${trash_count} items  $(_fca_human "$trash_size")  (use -f to empty)" \
                    "skipped"
            fi
        else
            _fca_action "✓" "Trash" "already empty" "skipped"
        fi
    fi

    # ── Neovim cache ──────────────────────────────────────────────────────────────
    local nvim_cache="${_FCA_CACHE}/nvim"
    if [[ -d "$nvim_cache" ]]; then
        # Only clear shada and old state — not plugins
        _fca_clean_dir "${nvim_cache}/lsp" "Neovim LSP cache"
        _fca_clean_dir "${nvim_cache}/telescope" "Neovim telescope cache"
    fi

    # ── Browser caches (if large) ─────────────────────────────────────────────────
    local -a browser_caches=(
        "${_FCA_CACHE}/mozilla:Firefox cache"
        "${_FCA_CACHE}/chromium:Chromium cache"
        "${_FCA_CACHE}/google-chrome:Chrome cache"
    )

    for bc_entry in "${browser_caches[@]}"; do
        IFS=':' read -r bc_dir bc_label <<< "$bc_entry"
        if [[ -d "$bc_dir" ]]; then
            local bc_size
            bc_size="$(du -sh "$bc_dir" 2>/dev/null | cut -f1 || echo '?')"
            _fca_action "ℹ" "$bc_label" \
                "${bc_size}  (skipped — clear manually if needed)" "info"
        fi
    done

    # ── pip cache ─────────────────────────────────────────────────────────────────
    local pip_cache="${_FCA_CACHE}/pip"
    if [[ -d "$pip_cache" ]]; then
        local pip_size
        pip_size="$(du -sh "$pip_cache" 2>/dev/null | cut -f1 || echo '?')"
        if [[ "${ASH_FLAG_FORCE:-0}" -eq 1 ]]; then
            _fca_clean_dir "$pip_cache" "pip cache"
        else
            _fca_action "ℹ" "pip cache" \
                "${pip_size}  (use -f to clear)" "info"
        fi
    fi

    # ── Cargo registry (Rust) ─────────────────────────────────────────────────────
    local cargo_cache="${CARGO_HOME:-$HOME/.cargo}/registry/cache"
    if [[ -d "$cargo_cache" ]]; then
        local cargo_size
        cargo_size="$(du -sh "$cargo_cache" 2>/dev/null | cut -f1 || echo '?')"
        _fca_action "ℹ" "Cargo registry cache" \
            "${cargo_size}  (run: cargo cache -a to clean)" "info"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 04 — PACMAN CACHE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fca_clean_pacman() {
    _fca_section "📦 Pacman Package Cache"

    if ! command -v pacman &>/dev/null; then
        _fca_action "○" "Pacman cache" "pacman not available — skip" "skipped"
        return 0
    fi

    local pacman_cache="/var/cache/pacman/pkg"
    if [[ -d "$pacman_cache" ]]; then
        local pc_size
        pc_size="$(du -sh "$pacman_cache" 2>/dev/null | cut -f1 || echo '?')"
        local pc_count
        pc_count="$(find "$pacman_cache" -name '*.pkg.tar.*' | wc -l)"
        _fca_action "ℹ" "Pacman cache" \
            "${pc_size}  •  ${pc_count} packages" "info"
    fi

    if command -v paccache &>/dev/null; then
        if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
            local to_remove
            to_remove="$(paccache -d 2>/dev/null | \
                        grep -oP 'no packages selected\|\d+ packages' | head -1 || echo '?')"
            _fca_action "~" "Pacman paccache" \
                "would remove: ${to_remove}" "dry-run"
        else
            # Keep 2 most recent versions
            local freed_out
            freed_out="$(sudo paccache -r -k 2 2>&1 | tail -1 || echo '')"
            _fca_action "🗑" "Pacman paccache" \
                "${freed_out:-cleaned (kept 2 versions)}" "cleaned"
            (( _FCA_OPERATIONS++ )) || true
        fi
    else
        _fca_action "ℹ" "paccache" \
            "not found  (install pacman-contrib for smart cache cleanup)" "info"
    fi

    # AUR build cache
    local paru_cache="${_FCA_CACHE}/paru/clone"
    if [[ -d "$paru_cache" ]]; then
        local paru_size
        paru_size="$(du -sh "$paru_cache" 2>/dev/null | cut -f1 || echo '?')"
        _fca_action "ℹ" "Paru AUR clone cache" \
            "${paru_size}  (run: paru -Sc to clean)" "info"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 05 — JOURNAL CLEANUP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fca_clean_journal() {
    _fca_section "📋 Journal Cleanup"

    if ! command -v journalctl &>/dev/null; then
        _fca_action "○" "Journal" "journalctl not available" "skipped"
        return 0
    fi

    local journal_size
    journal_size="$(journalctl --disk-usage 2>/dev/null | \
                   grep -oP '[\d.]+[MGK]B?' | head -1 || echo '?')"

    _fca_action "ℹ" "Journal disk usage" "$journal_size" "info"

    if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
        _fca_action "~" "Journal vacuum" \
            "would vacuum to 200MB (system) and 100MB (user)" "dry-run"
        return 0
    fi

    # System journal
    if sudo journalctl --vacuum-size=200M &>/dev/null 2>&1; then
        _fca_action "🗑" "System journal" \
            "vacuumed to 200MB" "cleaned"
        (( _FCA_OPERATIONS++ )) || true
    fi

    # User journal
    if journalctl --user --vacuum-size=100M &>/dev/null 2>&1; then
        _fca_action "🗑" "User journal" \
            "vacuumed to 100MB" "cleaned"
        (( _FCA_OPERATIONS++ )) || true
    fi

    # Rotate logs
    sudo journalctl --rotate &>/dev/null 2>&1 || true

    local journal_size_after
    journal_size_after="$(journalctl --disk-usage 2>/dev/null | \
                         grep -oP '[\d.]+[MGK]B?' | head -1 || echo '?')"
    _fca_action "✓" "Journal size after" "${journal_size} → ${journal_size_after}" "info"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RESULTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fca_report() {
    local freed_human
    freed_human="$(_fca_human "$_FCA_FREED_BYTES")"

    printf '\n'
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\033[1;38;2;137;220;235m'
        printf '  ╔══════════════════════════════════════════════════════════╗\n'
        printf '  ║  🗑  CACHE FIX — RESULTS                                  ║\n'
        printf '  ╠══════════════════════════════════════════════════════════╣\n'
        printf '  ║  \033[1;38;2;166;227;161m%s freed\033[38;2;137;220;235m  •  ' "$freed_human"
        printf '\033[38;2;148;226;213m%d operations\033[38;2;137;220;235m  •  ' "$_FCA_OPERATIONS"
        printf '\033[38;2;180;190;254m%d caches rebuilt\033[38;2;137;220;235m           ║\n' "$_FCA_REBUILT"
        printf '  ╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '  RESULTS: %s freed  •  %d operations  •  %d rebuilt\n' \
            "$freed_human" "$_FCA_OPERATIONS" "$_FCA_REBUILT"
    fi

    if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
        printf '\n'
        _fca_blue; printf '  ℹ  DRY RUN — nothing was changed.\n'; _fca_reset
    fi
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_fix_cache() {
    local mode="${1:-all}"

    _FCA_FREED_BYTES=0; _FCA_OPERATIONS=0; _FCA_REBUILT=0
    _FCA_LOG=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;137;220;235m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🗑  ASH FIXER — CACHE                                    ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]] && \
            printf '║  MODE: DRY RUN  (no files will be deleted)               ║\n' || \
            printf '║  MODE: LIVE     (caches will be cleared and rebuilt)      ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    case "$mode" in
        ash)      _fca_clean_ash          ;;
        fonts)    _fca_rebuild_font_cache ;;
        system)   _fca_clean_system       ;;
        pacman)   _fca_clean_pacman       ;;
        journal)  _fca_clean_journal      ;;
        all|*)
            _fca_clean_ash
            _fca_rebuild_font_cache
            _fca_clean_system
            _fca_clean_pacman
            _fca_clean_journal
            ;;
    esac

    _fca_report
}
