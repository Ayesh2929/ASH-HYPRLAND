#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ██████╗  ██████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗             ║
# ║  ██╔══██╗██╔═══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝             ║
# ║  ██████╔╝██║   ██║██║     ██║     ██████╔╝███████║██║     █████╔╝              ║
# ║  ██╔══██╗██║   ██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗              ║
# ║  ██║  ██║╚██████╔╝███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗             ║
# ║  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝             ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  update rollback                                          ║
# ║  Restore pre-update state: dotfiles git • package downgrade • config restore    ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_UPDATE_ROLLBACK_LOADED:-}" == "1" ]] && return 0
readonly _ASH_UPDATE_ROLLBACK_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SNAPSHOT DISCOVERY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_rb_find_snapshots() {
    local snap_base="${_UPD_SNAPSHOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/ash/snapshots/pre-update}"

    if [[ ! -d "$snap_base" ]]; then
        printf ''
        return 1
    fi

    find "$snap_base" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | \
        sort -rV | head -10
}

_rb_list_snapshots() {
    upd_section "📸" "Available Snapshots" "$(_uteal)"

    local -a snaps=()
    mapfile -t snaps < <(_rb_find_snapshots)

    if [[ ${#snaps[@]} -eq 0 ]]; then
        upd_info "No pre-update snapshots found"
        upd_info "Snapshots are created automatically by: ash update all"
        return 1
    fi

    printf '\n  %s%-5s  %-20s  %s%s\n' \
        "$(_udim)" "#" "Timestamp" "State" "$(_ur)"
    printf '  %s%s%s\n' "$(_udim)" "$(printf '─%.0s' $(seq 1 55))" "$(_ur)"

    local i=0
    for snap_dir in "${snaps[@]}"; do
        (( i++ )) || true
        local snap_name
        snap_name="$(basename "$snap_dir")"
        local snap_date
        snap_date="$(printf '%s' "$snap_name" | \
                     sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)-\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')"

        # Read state.json if present
        local commit="?"
        local state_file="${snap_dir}/state.json"
        if [[ -f "$state_file" ]] && command -v python3 &>/dev/null; then
            commit="$(python3 -c "
import json,sys
d=json.load(open('${state_file}'))
print(d.get('git_commit','?')[:8])
" 2>/dev/null || echo '?')"
        fi

        printf '  %s%3d%s  %s%-20s%s  %sgit:%s%s\n' \
            "$(_uyellow)" "$i" "$(_ur)" \
            "$(_usky)" "$snap_date" "$(_ur)" \
            "$(_udim)" "$commit" "$(_ur)"
    done

    printf '\n'
    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  DOTFILES ROLLBACK  (git)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_rb_dotfiles_git() {
    local target_commit="${1:-HEAD~1}"
    local ash_root="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}"

    upd_section "📁" "Dotfiles Git Rollback" "$(_upeach)"

    if [[ ! -d "${ash_root}/.git" ]]; then
        upd_fail "Not a git repository: ${ash_root}"
        return 1
    fi

    local current_commit
    current_commit="$(git -C "$ash_root" rev-parse --short HEAD 2>/dev/null)"
    local target_short
    target_short="$(git -C "$ash_root" rev-parse --short "$target_commit" \
                    2>/dev/null || echo '?')"

    upd_kv "Current commit" "$current_commit"
    upd_kv "Target commit"  "$target_short"

    # Show what will change
    printf '\n  %sCommits to revert:%s\n' "$(_udim)" "$(_ur)"
    git -C "$ash_root" log "${target_commit}..HEAD" --oneline 2>/dev/null | \
    while IFS= read -r line; do
        local chash="${line%% *}"
        local cmsg="${line#* }"
        printf '    %s%s%s  %s%s%s\n' \
            "$(_ured)" "$chash" "$(_ur)" \
            "$(_udim)" "$cmsg" "$(_ur)"
    done

    printf '\n'
    if [[ "${ASH_UPD_YES:-0}" -ne 1 ]]; then
        printf '  %s⚠  This will HARD RESET dotfiles to %s. Continue? [y/N] %s' \
            "$(_ured)" "$target_short" "$(_ur)"
        local ans
        read -r ans
        [[ "${ans,,}" != "y" ]] && { upd_info "Rollback cancelled"; return 0; }
    fi

    upd_step "Rolling back dotfiles to ${target_short}..."

    if [[ "${ASH_UPD_DRY:-0}" -eq 1 ]]; then
        upd_info "[dry-run] Would: git -C ${ash_root} reset --hard ${target_commit}"
    else
        if git -C "$ash_root" reset --hard "$target_commit" 2>/dev/null; then
            upd_ok "Dotfiles rolled back to: ${target_short}"
            upd_log_ok "Rollback: ${current_commit} → ${target_short}"
        else
            upd_fail "Git reset failed"
            return 1
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PACKAGE DOWNGRADE  (Arch / pacman cache)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_rb_pacman_packages() {
    local snap_state_file="${1:-}"

    upd_section "💻" "Package Rollback  (Pacman)" "$(_ugreen)"

    if [[ "$_UPD_PKG_MANAGER" != "pacman" ]]; then
        upd_skip "Package rollback only supported for pacman currently"
        return 0
    fi

    if ! command -v downgrade &>/dev/null; then
        upd_info "Install 'downgrade' for package-level rollback: paru -S downgrade"
        upd_info "Alternative: sudo pacman -U /var/cache/pacman/pkg/<pkg-version>.pkg.tar.zst"
        return 0
    fi

    # If we have a state file, compare current vs snapshot
    if [[ -n "$snap_state_file" ]] && [[ -f "$snap_state_file" ]]; then
        upd_step "Comparing current packages to snapshot..."

        local -a to_downgrade=()
        if command -v python3 &>/dev/null; then
            mapfile -t to_downgrade < <(python3 - "$snap_state_file" << 'PYEOF'
import json, subprocess, sys

snap_file = sys.argv[1]
with open(snap_file) as f:
    snap = json.load(f)

snap_pkgs = {}
for entry in snap.get('packages', []):
    if not entry or entry == 'null': continue
    if '=' in str(entry):
        name, ver = str(entry).strip('"').split('=', 1)
        snap_pkgs[name] = ver

# Current packages
result = subprocess.run(['pacman', '-Q'], capture_output=True, text=True)
for line in result.stdout.strip().splitlines():
    parts = line.split()
    if len(parts) >= 2:
        name, cur_ver = parts[0], parts[1]
        if name in snap_pkgs and snap_pkgs[name] != cur_ver:
            print(f"{name}={snap_pkgs[name]}")
PYEOF
)
        fi

        if [[ ${#to_downgrade[@]} -eq 0 ]]; then
            upd_ok "No packages need downgrading"
        else
            upd_warn "${#to_downgrade[@]} package(s) changed since snapshot"
            printf '\n  %sPkg  %s→%s  Target%s\n' \
                "$(_udim)" "$(_ur)" "$(_udim)" "$(_ur)"
            for pkg_ver in "${to_downgrade[@]}"; do
                local pkg="${pkg_ver%%=*}"
                local ver="${pkg_ver##*=}"
                printf '  %s%-30s%s → %s%s%s\n' \
                    "$(_usky)" "$pkg" "$(_ur)" "$(_uyellow)" "$ver" "$(_ur)"
            done
        fi
    else
        upd_info "No snapshot state file provided"
        upd_info "To downgrade specific packages: downgrade <package>"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_update_rollback() {
    local action="menu"
    local target_snapshot=""
    local rollback_target="HEAD~1"

    for arg in "${@:-}"; do
        case "$arg" in
            --list|-l)          action="list"        ;;
            --dotfiles|-d)      action="dotfiles"    ;;
            --packages|-p)      action="packages"    ;;
            --snapshot=*)       target_snapshot="${arg#*=}" ;;
            --to=*)             rollback_target="${arg#*=}" ;;
            [0-9]*)             target_snapshot="$arg"      ;;
        esac
    done

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;243;139;168m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  ⏪  ASH UPDATE ROLLBACK                                   ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  Restore system to pre-update state                      ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    case "$action" in
        list)
            _rb_list_snapshots
            ;;

        dotfiles)
            _rb_dotfiles_git "$rollback_target"
            ;;

        packages)
            local snap_state=""
            if [[ -n "$target_snapshot" ]]; then
                local snap_base="${_UPD_SNAPSHOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/ash/snapshots/pre-update}"
                snap_state="${snap_base}/${target_snapshot}/state.json"
            fi
            _rb_pacman_packages "$snap_state"
            ;;

        menu|*)
            # Show available snapshots and interactive menu
            local -a snaps=()
            mapfile -t snaps < <(_rb_find_snapshots)

            if _rb_list_snapshots; then
                printf '  %sOptions:%s\n' "$(_udim)" "$(_ur)"
                printf '    %s1%s  Rollback dotfiles only (git reset HEAD~1)\n' \
                    "$(_usky)" "$(_ur)"
                printf '    %s2%s  Rollback using last snapshot\n' \
                    "$(_usky)" "$(_ur)"
                printf '    %s3%s  Cancel\n' "$(_udim)" "$(_ur)"
                printf '\n  %sChoice [1/2/3]: %s' "$(_uyellow)" "$(_ur)"

                local choice
                read -r choice

                case "$choice" in
                    1)  _rb_dotfiles_git "HEAD~1" ;;
                    2)
                        if [[ ${#snaps[@]} -gt 0 ]]; then
                            local latest_snap="${snaps[0]}"
                            local snap_state="${latest_snap}/state.json"

                            # Find git commit from snapshot
                            local target_commit="HEAD~1"
                            if [[ -f "$snap_state" ]] && command -v python3 &>/dev/null; then
                                target_commit="$(python3 -c "
import json,sys
d=json.load(open('${snap_state}'))
print(d.get('git_commit','HEAD~1'))
" 2>/dev/null || echo 'HEAD~1')"
                            fi

                            _rb_dotfiles_git "$target_commit"
                            _rb_pacman_packages "$snap_state"
                        else
                            upd_fail "No snapshots available"
                        fi
                        ;;
                    *) upd_info "Rollback cancelled" ;;
                esac
            else
                # No snapshots — offer basic dotfiles rollback
                printf '\n  %sNo snapshots found. Rollback dotfiles with git reset? [y/N] %s' \
                    "$(_uyellow)" "$(_ur)"
                local ans
                read -r ans
                [[ "${ans,,}" == "y" ]] && _rb_dotfiles_git "HEAD~1"
            fi
            ;;
    esac

    printf '\n'
}
