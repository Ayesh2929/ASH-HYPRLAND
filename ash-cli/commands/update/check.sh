#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  update check                                             ║
# ║  Preview available updates across all components without installing             ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_UPDATE_CHECK_LOADED:-}" == "1" ]] && return 0
readonly _ASH_UPDATE_CHECK_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  STATUS BADGE RENDERER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_check_badge() {
    local text="$1"  color="${2:-$(_udim)}"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '%s%s\033[38;2;30;30;46m %s \033[0m' \
            "$(_ubold)" "$color" "$text"
    else
        printf '[%s]' "$text"
    fi
}

_check_status_row() {
    local component="$1"  status="$2"  detail="${3:-}"  icon="${4:-}"

    local badge
    case "$status" in
        "up-to-date") badge="$(_check_badge " UP TO DATE " "$(_ugreen)")"  ;;
        "updates")    badge="$(_check_badge " UPDATES    " "$(_uyellow)")" ;;
        "error")      badge="$(_check_badge " ERROR      " "$(_ured)")"    ;;
        "skip")       badge="$(_check_badge " SKIP       " "$(_udim)")"    ;;
        *)            badge="$(_check_badge " UNKNOWN    " "$(_udim)")"    ;;
    esac

    printf '  %s  %s%-22s%s  %s  %s%s%s\n' \
        "$icon" \
        "$(_usky)" "$component" "$(_ur)" \
        "$badge" \
        "$(_udim)" "$detail" "$(_ur)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CHECK FUNCTIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_check_system_updates() {
    local count=0
    case "$_UPD_PKG_MANAGER" in
        pacman)
            count="$(checkupdates 2>/dev/null | wc -l || echo 0)"
            local aur_count=0
            [[ -n "$_UPD_AUR_HELPER" ]] && \
                aur_count="$("$_UPD_AUR_HELPER" -Qua 2>/dev/null | wc -l || echo 0)"

            if (( count + aur_count == 0 )); then
                _check_status_row "System (pacman)" "up-to-date" \
                    "All packages current" "💻"
            else
                _check_status_row "System (pacman)" "updates" \
                    "${count} official  •  ${aur_count} AUR" "💻"
            fi
            ;;
        dnf)
            count="$(dnf check-update -q 2>/dev/null | grep -c '^[^ ]' || echo 0)"
            if (( count == 0 )); then
                _check_status_row "System (dnf)" "up-to-date" "" "💻"
            else
                _check_status_row "System (dnf)" "updates" "${count} packages" "💻"
            fi
            ;;
        apt)
            count="$(apt-get -s upgrade 2>/dev/null | grep -c '^Inst' || echo 0)"
            if (( count == 0 )); then
                _check_status_row "System (apt)" "up-to-date" "" "💻"
            else
                _check_status_row "System (apt)" "updates" "${count} packages" "💻"
            fi
            ;;
        *)
            _check_status_row "System" "skip" "Unknown package manager" "💻"
            ;;
    esac
}

_check_dotfiles_updates() {
    local ash_root="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}"

    if [[ ! -d "${ash_root}/.git" ]]; then
        _check_status_row "ASH Dotfiles" "skip" "Not a git repo" "📁"
        return
    fi

    git -C "$ash_root" fetch origin --quiet 2>/dev/null || true

    local branch
    branch="$(git -C "$ash_root" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    local behind
    behind="$(git -C "$ash_root" rev-list "HEAD..origin/${branch}" \
              --count 2>/dev/null || echo 0)"

    if (( behind == 0 )); then
        local cur_commit
        cur_commit="$(git -C "$ash_root" rev-parse --short HEAD 2>/dev/null)"
        _check_status_row "ASH Dotfiles" "up-to-date" \
            "@ ${cur_commit}" "📁"
    else
        _check_status_row "ASH Dotfiles" "updates" \
            "${behind} commit(s) behind" "📁"
    fi
}

_check_nvim_updates() {
    command -v nvim &>/dev/null || {
        _check_status_row "Neovim" "skip" "Not installed" "📝"
        return
    }

    local ver
    ver="$(nvim --version 2>/dev/null | head -1 | grep -oP 'v[\d.]+')"

    local lazy_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy"
    local plugin_count=0
    [[ -d "$lazy_dir" ]] && \
        plugin_count="$(find "$lazy_dir" -maxdepth 1 -mindepth 1 -type d | wc -l)"

    _check_status_row "Neovim" "up-to-date" \
        "${ver}  •  ${plugin_count} plugins  (run to check: nvim +Lazy)" "📝"
}

_check_flatpak_updates() {
    command -v flatpak &>/dev/null || {
        _check_status_row "Flatpak" "skip" "Not installed" "📦"
        return
    }

    local count=0
    count="$(flatpak update --noninteractive --no-deploy \
             2>/dev/null | grep -c 'com\.\|org\.\|io\.' || echo 0)"

    if (( count == 0 )); then
        _check_status_row "Flatpak" "up-to-date" \
            "$(flatpak list --app 2>/dev/null | wc -l) apps" "📦"
    else
        _check_status_row "Flatpak" "updates" \
            "${count} app(s)" "📦"
    fi
}

_check_fish_updates() {
    command -v fish &>/dev/null || {
        _check_status_row "Fish" "skip" "Not installed" "🐟"
        return
    }

    local ver
    ver="$(fish --version 2>/dev/null | grep -oP '[\d.]+')"

    local plugins_file="${XDG_CONFIG_HOME:-$HOME/.config}/fish/fish_plugins"
    local pcount=0
    [[ -f "$plugins_file" ]] && pcount="$(wc -l < "$plugins_file")"

    _check_status_row "Fish" "up-to-date" \
        "v${ver}  •  ${pcount} Fisher plugins" "🐟"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_update_check() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;116;199;236m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🔍  ASH UPDATE CHECK  ─  No changes will be made         ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  Checking: %-49s║\n' "$(date '+%Y-%m-%d %H:%M:%S')"
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    printf '\n  %s%-22s  %-17s  %s%s\n' \
        "$(_udim)" "Component" "Status" "Details" "$(_ur)"
    printf '  %s%s%s\n' "$(_udim)" "$(printf '─%.0s' $(seq 1 70))" "$(_ur)"

    # Run all checks
    local funcs=(
        "_check_system_updates"
        "_check_dotfiles_updates"
        "_check_nvim_updates"
        "_check_fish_updates"
        "_check_flatpak_updates"
    )

    for fn in "${funcs[@]}"; do
        "$fn" 2>/dev/null || true
    done

    printf '\n  %sRun %sash update all%s to apply all updates%s\n\n' \
        "$(_udim)" "$(_usky)" "$(_udim)" "$(_ur)"
}
