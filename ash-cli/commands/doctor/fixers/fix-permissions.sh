#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ███████╗██╗██╗  ██╗    ██████╗ ███████╗██████╗ ███╗   ███╗███████╗             ║
# ║  ██╔════╝██║╚██╗██╔╝    ██╔══██╗██╔════╝██╔══██╗████╗ ████║██╔════╝             ║
# ║  █████╗  ██║ ╚███╔╝     ██████╔╝█████╗  ██████╔╝██╔████╔██║███████╗             ║
# ║  ██╔══╝  ██║ ██╔██╗     ██╔═══╝ ██╔══╝  ██╔══██╗██║╚██╔╝██║╚════██║             ║
# ║  ██║     ██║██╔╝ ██╗    ██║     ███████╗██║  ██║██║ ╚═╝ ██║███████║             ║
# ║  ╚═╝     ╚═╝╚═╝  ╚═╝    ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝             ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  FIXER: PERMISSIONS                                      ║
# ║                                                                                  ║
# ║  Automatically repairs all permission issues detected by check-permissions.sh   ║
# ║  → Home/XDG dirs  → SSH keys  → ASH scripts  → User groups  → Config files     ║
# ║                                                                                  ║
# ║  Author   : ash-dotfiles                                                         ║
# ║  License  : MIT                                                                  ║
# ║  Safe     : All operations are previewed before execution (--dry-run)           ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_FIX_PERMISSIONS_LOADED:-}" == "1" ]] && return 0
readonly _ASH_FIX_PERMISSIONS_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _FP_ASH_ROOT="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}"
declare -gr _FP_ASH_CLI="${ASH_CLI_DIR:-$HOME/ash-dotfiles/ash-cli}"
declare -gr _FP_CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
declare -gr _FP_DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
declare -gr _FP_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"
declare -gr _FP_STATE="${XDG_STATE_HOME:-$HOME/.local/state}"

# Fix operation counters
declare -g  _FP_FIXED=0
declare -g  _FP_SKIPPED=0
declare -g  _FP_FAILED=0
declare -g  _FP_TOTAL=0
declare -ga _FP_ACTIONS=()
declare -ga _FP_ERRORS=()

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RENDER HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fp_c()     { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_fp_reset() { _fp_c '\033[0m'; }
_fp_bold()  { _fp_c '\033[1m'; }
_fp_green() { _fp_c '\033[38;2;166;227;161m'; }
_fp_red()   { _fp_c '\033[1;38;2;243;139;168m'; }
_fp_yellow(){ _fp_c '\033[1;38;2;249;226;175m'; }
_fp_blue()  { _fp_c '\033[38;2;137;180;250m'; }
_fp_dim()   { _fp_c '\033[38;2;108;112;134m'; }
_fp_pink()  { _fp_c '\033[38;2;245;194;231m'; }
_fp_sky()   { _fp_c '\033[38;2;137;220;235m'; }

_fp_section() {
    printf '\n'
    _fp_pink; _fp_bold
    printf '  ┌─────────────────────────────────────────────────────────\n'
    printf '  │  %s\n' "$1"
    printf '  └─────────────────────────────────────────────────────────\n'
    _fp_reset
}

_fp_action() {
    local icon="$1"
    local label="$2"
    local detail="$3"
    local status="${4:-fixing}"

    local status_color
    case "$status" in
        fixed)   status_color="$(_fp_green)"  ;;
        skipped) status_color="$(_fp_dim)"    ;;
        failed)  status_color="$(_fp_red)"    ;;
        dry-run) status_color="$(_fp_blue)"   ;;
        *)       status_color="$(_fp_yellow)" ;;
    esac

    printf '  %s  ' "$icon"
    _fp_sky; printf '%-35s' "$label"; _fp_reset
    printf '  '
    printf '%s' "$status_color"
    printf '%s' "$detail"
    _fp_reset
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CORE FIX PRIMITIVE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# _fp_chmod path  expected_perm  label
_fp_chmod() {
    local path="$1"
    local expected="$2"
    local label="${3:-${path##$HOME/}}"

    (( _FP_TOTAL++ )) || true

    if [[ ! -e "$path" ]]; then
        _fp_action "○" "$label" "not found — skip" "skipped"
        (( _FP_SKIPPED++ )) || true
        return 0
    fi

    local actual
    actual="$(stat -c '%a' "$path" 2>/dev/null || echo '???')"

    if [[ "$actual" == "$expected" ]]; then
        _fp_action "✓" "$label" "${actual}  already correct" "skipped"
        (( _FP_SKIPPED++ )) || true
        return 0
    fi

    if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
        _fp_action "~" "$label" "would: chmod ${expected}  (currently ${actual})" "dry-run"
        _FP_ACTIONS+=("chmod ${expected} '${path}'")
        return 0
    fi

    if chmod "$expected" "$path" 2>/dev/null; then
        _fp_action "🔧" "$label" "${actual} → ${expected}  fixed" "fixed"
        _FP_ACTIONS+=("chmod ${expected} '${path}'")
        (( _FP_FIXED++ )) || true
    else
        _fp_action "✗" "$label" "chmod ${expected} FAILED  (${actual})" "failed"
        _FP_ERRORS+=("chmod ${expected} '${path}'")
        (( _FP_FAILED++ )) || true
    fi
}

# Bulk chmod for all files matching pattern
_fp_chmod_bulk() {
    local dir="$1"
    local pattern="$2"
    local perm="$3"
    local label_prefix="${4:-}"

    [[ -d "$dir" ]] || return 0

    local count=0
    local fixed=0

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        local actual
        actual="$(stat -c '%a' "$file" 2>/dev/null || echo '???')"

        if [[ "$actual" != "$perm" ]]; then
            (( count++ )) || true
            if [[ "${ASH_FLAG_DRY_RUN:-0}" -ne 1 ]]; then
                chmod "$perm" "$file" 2>/dev/null && (( fixed++ )) || true
            fi
        fi
    done < <(find "$dir" -name "$pattern" 2>/dev/null)

    if (( count == 0 )); then
        _fp_action "✓" "${label_prefix}${pattern}" "all already ${perm}" "skipped"
    elif [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
        _fp_action "~" "${label_prefix}${pattern}" "would fix ${count} file(s) → ${perm}" "dry-run"
    else
        _fp_action "🔧" "${label_prefix}${pattern}" "${fixed}/${count} fixed → ${perm}" "fixed"
        (( _FP_FIXED += fixed )) || true
    fi
    (( _FP_TOTAL += count )) || true
}

# Add user to group if not already a member
_fp_add_group() {
    local group="$1"
    local current_user="${USER:-$(whoami)}"

    (( _FP_TOTAL++ )) || true

    if ! getent group "$group" &>/dev/null; then
        _fp_action "○" "Group: ${group}" "group does not exist on system" "skipped"
        (( _FP_SKIPPED++ )) || true
        return 0
    fi

    if groups 2>/dev/null | tr ' ' '\n' | grep -qx "$group"; then
        _fp_action "✓" "Group: ${group}" "already a member" "skipped"
        (( _FP_SKIPPED++ )) || true
        return 0
    fi

    if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
        _fp_action "~" "Group: ${group}" "would: sudo usermod -aG ${group} ${current_user}" "dry-run"
        _FP_ACTIONS+=("sudo usermod -aG ${group} ${current_user}")
        return 0
    fi

    if sudo usermod -aG "$group" "$current_user" 2>/dev/null; then
        _fp_action "🔧" "Group: ${group}" "added ${current_user} to ${group}" "fixed"
        _FP_ACTIONS+=("sudo usermod -aG ${group} ${current_user}")
        (( _FP_FIXED++ )) || true
    else
        _fp_action "✗" "Group: ${group}" "FAILED — run: sudo usermod -aG ${group} ${current_user}" "failed"
        (( _FP_FAILED++ )) || true
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 01 — HOME & XDG DIRECTORIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fp_fix_home_dirs() {
    _fp_section "🏠 Home & XDG Directory Permissions"

    _fp_chmod "$HOME"         "750"  "HOME (~)"
    _fp_chmod "$HOME/.ssh"    "700"  "~/.ssh"
    _fp_chmod "$HOME/.gnupg"  "700"  "~/.gnupg"
    _fp_chmod "$_FP_CFG"      "755"  "XDG_CONFIG_HOME"
    _fp_chmod "$_FP_DATA"     "755"  "XDG_DATA_HOME"
    _fp_chmod "$_FP_CACHE"    "755"  "XDG_CACHE_HOME"
    _fp_chmod "$_FP_STATE"    "755"  "XDG_STATE_HOME"

    # ~/.local/bin executables
    local local_bin="$HOME/.local/bin"
    if [[ -d "$local_bin" ]]; then
        _fp_action "🔧" "~/.local/bin scripts" "ensuring executable bit..." "fixing"
        _fp_chmod_bulk "$local_bin" "*" "755" "~/.local/bin/"
    fi

    # ASH runtime directories
    local ash_cfg="${_FP_CFG}/ash"
    local ash_data="${_FP_DATA}/ash"
    local ash_cache="${_FP_CACHE}/ash"
    local ash_state="${_FP_STATE}/ash"
    local ash_logs="${ash_state}/logs"

    for dir in "$ash_cfg" "$ash_data" "$ash_cache" "$ash_state" "$ash_logs"; do
        if [[ ! -d "$dir" ]]; then
            if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
                _fp_action "~" "Create: ${dir##$HOME/}" "would mkdir -p" "dry-run"
            else
                mkdir -p "$dir" && \
                    _fp_action "🔧" "Create: ${dir##$HOME/}" "created" "fixed" || \
                    _fp_action "✗"  "Create: ${dir##$HOME/}" "FAILED" "failed"
            fi
        fi
        _fp_chmod "$dir" "755" "${dir##$HOME/}"
    done

    # Secrets directory — must be 700
    local secrets_dir="${_FP_ASH_ROOT}/secrets"
    if [[ -d "$secrets_dir" ]]; then
        _fp_chmod "$secrets_dir" "700" "secrets/"
        # All files in secrets must be 600
        while IFS= read -r sf; do
            _fp_chmod "$sf" "600" "secrets/${sf##*/}"
        done < <(find "$secrets_dir" -maxdepth 1 -type f 2>/dev/null)
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 02 — SSH KEY PERMISSIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fp_fix_ssh() {
    _fp_section "🔑 SSH Key Permissions"

    local ssh_dir="$HOME/.ssh"
    [[ -d "$ssh_dir" ]] || {
        _fp_action "○" "~/.ssh" "not found — skip" "skipped"
        return 0
    }

    _fp_chmod "$ssh_dir" "700" "~/.ssh/"
    _fp_chmod "${ssh_dir}/config"           "600" "ssh/config"
    _fp_chmod "${ssh_dir}/known_hosts"      "644" "ssh/known_hosts"
    _fp_chmod "${ssh_dir}/authorized_keys"  "600" "ssh/authorized_keys"

    # Private keys → 600
    while IFS= read -r key; do
        [[ -z "$key" ]] && continue
        _fp_chmod "$key" "600" "ssh/${key##*/}  (private key)"
    done < <(find "$ssh_dir" \( -name 'id_*' ! -name '*.pub' \
             -o -name 'id_ed25519' -o -name 'id_rsa' \
             -o -name 'id_ecdsa' \) 2>/dev/null)

    # Public keys → 644
    while IFS= read -r pub; do
        [[ -z "$pub" ]] && continue
        _fp_chmod "$pub" "644" "ssh/${pub##*/}  (public key)"
    done < <(find "$ssh_dir" -name '*.pub' 2>/dev/null)

    # ssh/config.d sub-configs
    if [[ -d "${ssh_dir}/config.d" ]]; then
        _fp_chmod_bulk "${ssh_dir}/config.d" "*.conf" "600" "ssh/config.d/"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 03 — SCRIPT EXECUTABILITY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fp_fix_scripts() {
    _fp_section "📜 Script Executability"

    # Main ash CLI binary
    local ash_bin="${_FP_ASH_CLI}/ash"
    _fp_chmod "$ash_bin" "755" "ash CLI binary"

    # Scan and fix all .sh files in ASH tree
    local -a script_dirs=(
        "${_FP_ASH_CLI}/commands"
        "${_FP_ASH_CLI}/engines"
        "${_FP_ASH_CLI}/lib"
        "${_FP_ASH_ROOT}/scripts"
        "${_FP_ASH_ROOT}/fixers"
        "${_FP_CFG}/hypr/scripts"
        "${_FP_CFG}/waybar/scripts"
        "${_FP_CFG}/rofi/menus"
        "${_FP_CFG}/dunst/scripts"
        "${_FP_CFG}/swaync/scripts"
        "${_FP_CFG}/hyprlock/scripts"
        "${_FP_CFG}/hypridle/scripts"
    )

    for script_dir in "${script_dirs[@]}"; do
        [[ -d "$script_dir" ]] || continue

        local dir_label="${script_dir##$HOME/}"
        local sh_count=0 fixed_count=0

        while IFS= read -r sh_file; do
            [[ -z "$sh_file" ]] && continue
            (( sh_count++ )) || true

            if [[ ! -x "$sh_file" ]]; then
                if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
                    (( fixed_count++ )) || true
                else
                    chmod +x "$sh_file" 2>/dev/null && \
                        (( fixed_count++ )) || true
                fi
            fi
        done < <(find "$script_dir" -name '*.sh' -type f 2>/dev/null)

        if (( sh_count == 0 )); then
            _fp_action "○" "${dir_label}/" "no .sh files found" "skipped"
        elif (( fixed_count == 0 )); then
            _fp_action "✓" "${dir_label}/" "${sh_count} scripts — all executable" "skipped"
        elif [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
            _fp_action "~" "${dir_label}/" "would chmod +x ${fixed_count}/${sh_count} scripts" "dry-run"
        else
            _fp_action "🔧" "${dir_label}/" "${fixed_count}/${sh_count} scripts made executable" "fixed"
            (( _FP_FIXED += fixed_count, _FP_TOTAL += fixed_count )) || true
        fi
    done

    # Fish functions — must be readable
    local fish_fn_dir="${_FP_CFG}/fish/functions"
    if [[ -d "$fish_fn_dir" ]]; then
        _fp_chmod_bulk "$fish_fn_dir" "*.fish" "644" "fish/functions/"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 04 — USER GROUP MEMBERSHIP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fp_fix_groups() {
    _fp_section "👥 User Group Membership"

    # Critical groups for GPU + Wayland
    local -a critical_groups=( "video" "render" "input" "audio" "seat" )
    # Optional but useful groups
    local -a optional_groups=( "storage" "optical" "kvm" "docker" "bluetooth" "realtime" )

    local groups_changed=0

    printf '\n'
    _fp_action "ℹ" "Critical groups" "${critical_groups[*]}" "fixing"

    for grp in "${critical_groups[@]}"; do
        _fp_add_group "$grp" && \
            [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]] || \
            groups 2>/dev/null | grep -qw "$grp" && \
            (( groups_changed++ )) || true
    done

    printf '\n'
    _fp_action "ℹ" "Optional groups" "${optional_groups[*]}" "fixing"

    for grp in "${optional_groups[@]}"; do
        _fp_add_group "$grp"
    done

    if (( groups_changed > 0 )); then
        printf '\n'
        _fp_yellow
        printf '  ⚠️  Group membership changes require RE-LOGIN to take effect!\n'
        printf '     Run: newgrp <group>  or log out and back in.\n'
        _fp_reset
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FIX 05 — CONFIG FILE PERMISSIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fp_fix_config_perms() {
    _fp_section "⚙️  Config File Permissions"

    # Sensitive files
    local -a sensitive=(
        "$HOME/.gitconfig:644"
        "$HOME/.ssh/config:600"
        "$HOME/.gnupg/gpg.conf:600"
        "$HOME/.gnupg/gpg-agent.conf:600"
        "${_FP_CFG}/ash/ash.conf:644"
    )

    for entry in "${sensitive[@]}"; do
        IFS=':' read -r file_path perm <<< "$entry"
        _fp_chmod "$file_path" "$perm" "${file_path##$HOME/}"
    done

    # Fix any world-writable files in ~/.config/ash
    local ash_conf_dir="${_FP_CFG}/ash"
    if [[ -d "$ash_conf_dir" ]]; then
        local ww_fixed=0
        while IFS= read -r ww_file; do
            [[ -z "$ww_file" ]] && continue
            if [[ "${ASH_FLAG_DRY_RUN:-0}" -ne 1 ]]; then
                chmod o-w "$ww_file" 2>/dev/null && (( ww_fixed++ )) || true
            else
                (( ww_fixed++ )) || true
            fi
        done < <(find "$ash_conf_dir" -perm -o+w -type f 2>/dev/null)

        if (( ww_fixed > 0 )); then
            _fp_action "🔧" "World-writable in ash config" \
                "${ww_fixed} file(s) fixed (o-w)" "fixed"
            (( _FP_FIXED += ww_fixed )) || true
        else
            _fp_action "✓" "World-writable in ash config" "none found" "skipped"
        fi
    fi

    # Fix ASH data directory files
    local -a ash_data_dirs=(
        "${_FP_DATA}/ash/snapshots"
        "${_FP_STATE}/ash/logs"
    )

    for dir in "${ash_data_dirs[@]}"; do
        [[ -d "$dir" ]] || continue
        # Log files → 644, dirs → 755
        while IFS= read -r f; do
            [[ -f "$f" ]] && _fp_chmod "$f" "644" "${f##$HOME/}" || true
        done < <(find "$dir" -maxdepth 1 -type f 2>/dev/null)
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RESULTS REPORT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fp_report() {
    printf '\n'
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\033[1;38;2;245;194;231m'
        printf '  ╔══════════════════════════════════════════════════════════╗\n'
        printf '  ║  🔐  PERMISSIONS FIX — RESULTS                           ║\n'
        printf '  ╠══════════════════════════════════════════════════════════╣\n'
        printf '  ║  \033[38;2;166;227;161m🔧 %-4d fixed\033[38;2;245;194;231m  •  ' "$_FP_FIXED"
        printf '\033[38;2;108;112;134m○  %-4d skipped\033[38;2;245;194;231m  •  ' "$_FP_SKIPPED"
        printf '\033[38;2;243;139;168m✗  %-4d failed\033[38;2;245;194;231m         ║\n' "$_FP_FAILED"
        printf '  ╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '  RESULTS: %d fixed  •  %d skipped  •  %d failed\n' \
            "$_FP_FIXED" "$_FP_SKIPPED" "$_FP_FAILED"
    fi

    if [[ ${#_FP_ERRORS[@]} -gt 0 ]]; then
        printf '\n'
        _fp_red; printf '  Failures (run manually as root):\n'; _fp_reset
        for err in "${_FP_ERRORS[@]}"; do
            _fp_dim; printf '    $ %s\n' "$err"; _fp_reset
        done
    fi

    if [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]]; then
        printf '\n'
        _fp_blue; printf '  ℹ  DRY RUN — nothing was changed.\n'; _fp_reset
        printf '  Remove --dry-run to apply fixes.\n'
    elif (( _FP_FIXED > 0 )); then
        printf '\n'
        _fp_green; printf '  ✓ Permissions repaired. '; _fp_reset
        printf 'Re-login if group changes were made.\n'
    fi
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_fix_permissions() {
    local mode="${1:-all}"

    _FP_FIXED=0; _FP_SKIPPED=0; _FP_FAILED=0; _FP_TOTAL=0
    _FP_ACTIONS=(); _FP_ERRORS=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;245;194;231m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🔐  ASH FIXER — PERMISSIONS                              ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        [[ "${ASH_FLAG_DRY_RUN:-0}" -eq 1 ]] && \
            printf '║  MODE: DRY RUN  (no changes will be made)                ║\n' || \
            printf '║  MODE: LIVE     (changes will be applied)                ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    case "$mode" in
        home)    _fp_fix_home_dirs     ;;
        ssh)     _fp_fix_ssh           ;;
        scripts) _fp_fix_scripts       ;;
        groups)  _fp_fix_groups        ;;
        configs) _fp_fix_config_perms  ;;
        all|*)
            _fp_fix_home_dirs
            _fp_fix_ssh
            _fp_fix_scripts
            _fp_fix_groups
            _fp_fix_config_perms
            ;;
    esac

    _fp_report
}
