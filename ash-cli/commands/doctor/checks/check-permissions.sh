#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██████╗ ███████╗██████╗ ███╗   ███╗██╗███████╗███████╗██╗ ██████╗ ███╗   ██╗  ║
# ║  ██╔══██╗██╔════╝██╔══██╗████╗ ████║██║██╔════╝██╔════╝██║██╔═══██╗████╗  ██║  ║
# ║  ██████╔╝█████╗  ██████╔╝██╔████╔██║██║███████╗███████╗██║██║   ██║██╔██╗ ██║  ║
# ║  ██╔═══╝ ██╔══╝  ██╔══██╗██║╚██╔╝██║██║╚════██║╚════██║██║██║   ██║██║╚██╗██║  ║
# ║  ██║     ███████╗██║  ██║██║ ╚═╝ ██║██║███████╗███████╗██║╚██████╔╝██║ ╚████║  ║
# ║  ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚══════╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝  ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  DOCTOR CHECK: PERMISSIONS                               ║
# ║  Files • Directories • SUID/SGID • Groups • XDG • Script executability          ║
# ║                                                                                  ║
# ║  Author   : ash-dotfiles                                                         ║
# ║  License  : MIT                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CHECK_PERMISSIONS_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CHECK_PERMISSIONS_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _PERM_CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
declare -gr _PERM_DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
declare -gr _PERM_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"
declare -gr _PERM_ASH_ROOT="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}"
declare -gr _PERM_ASH_CLI="${ASH_CLI_DIR:-$HOME/ash-dotfiles/ash-cli}"

# Counters
declare -g _PERM_PASS=0
declare -g _PERM_WARN=0
declare -g _PERM_FAIL=0
declare -ga _PERM_ISSUES=()

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PERMISSION PROBE HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# _perm_check  path  expected_perm  label  fix_hint
_perm_check() {
    local path="$1"
    local expected="$2"
    local label="${3:-$path}"
    local fix_hint="${4:-}"
    local path_type="${5:-auto}"   # auto | file | dir

    # ── Existence ────────────────────────────────────────────────────────────────
    if [[ ! -e "$path" ]]; then
        _check_report $CHECK_INFO \
            "$label" \
            "does not exist  (skip)"
        return $CHECK_PASS
    fi

    # ── Actual permissions ───────────────────────────────────────────────────────
    local actual
    actual="$(stat -c '%a' "$path" 2>/dev/null || echo '???')"

    if [[ "$actual" == "???" ]]; then
        _check_report $CHECK_WARN \
            "$label" \
            "Cannot stat: ${path}"
        return $CHECK_WARN
    fi

    # ── Owner check ──────────────────────────────────────────────────────────────
    local owner
    owner="$(stat -c '%U' "$path" 2>/dev/null || echo '?')"
    local current_user="${USER:-$(whoami)}"

    local owner_note=""
    if [[ "$owner" != "$current_user" ]] && [[ "$owner" != "root" ]]; then
        owner_note="  ⚠️ owned by ${owner}"
    fi

    # ── Comparison ───────────────────────────────────────────────────────────────
    if [[ "$actual" == "$expected" ]]; then
        _check_report $CHECK_PASS \
            "$label" \
            "${actual}${owner_note}"
        (( _PERM_PASS++ )) || true
        return $CHECK_PASS
    fi

    # Too permissive?
    if (( 8#$actual > 8#$expected )); then
        local fix_cmd
        if [[ -n "$fix_hint" ]]; then
            fix_cmd="$fix_hint"
        else
            fix_cmd="chmod ${expected} '${path}'"
        fi
        _check_report $CHECK_FAIL \
            "$label" \
            "got ${actual}  expected ${expected}${owner_note}" \
            "Fix: ${fix_cmd}"
        _PERM_ISSUES+=("chmod ${expected} '${path}'")
        (( _PERM_FAIL++ )) || true
        return $CHECK_FAIL
    else
        # Too restrictive
        _check_report $CHECK_WARN \
            "$label" \
            "got ${actual}  expected ${expected} (too restrictive)"
        (( _PERM_WARN++ )) || true
        return $CHECK_WARN
    fi
}

# Check executable bit set on a script
_perm_exec() {
    local path="$1"
    local label="${2:-$path}"

    if [[ ! -f "$path" ]]; then
        _check_report $CHECK_INFO "$label" "not found  (skip)"
        return $CHECK_PASS
    fi

    if [[ -x "$path" ]]; then
        _check_report $CHECK_PASS "$label" "executable ✓"
        (( _PERM_PASS++ )) || true
    else
        _check_report $CHECK_FAIL \
            "$label" \
            "NOT executable" \
            "chmod +x '${path}'"
        _PERM_ISSUES+=("chmod +x '${path}'")
        (( _PERM_FAIL++ )) || true
    fi
}

# Bulk scan for world-writable files in a directory (security)
_perm_scan_world_writable() {
    local dir="$1"
    local label="${2:-$dir}"
    local max_depth="${3:-3}"

    if [[ ! -d "$dir" ]]; then
        _check_report $CHECK_INFO "$label" "directory not found  (skip)"
        return $CHECK_PASS
    fi

    local ww_count
    ww_count="$(find "$dir" -maxdepth "$max_depth" -perm -o+w \
                ! -type l ! -path '*/\.*' 2>/dev/null | wc -l)"

    if (( ww_count == 0 )); then
        _check_report $CHECK_PASS \
            "$label" \
            "No world-writable files found"
    else
        _check_report $CHECK_WARN \
            "$label" \
            "${ww_count} world-writable file(s)" \
            "Review: find '${dir}' -maxdepth ${max_depth} -perm -o+w"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 01 — HOME & XDG DIRECTORIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_perm_home() {
    _check_header "🏠 Home & XDG Directory Permissions"

    # ── Critical home directories ─────────────────────────────────────────────────
    _perm_check "$HOME"                   "750" "HOME (~)"              "chmod 750 $HOME"
    _perm_check "$HOME/.ssh"              "700" "~/.ssh"                "chmod 700 ~/.ssh"
    _perm_check "$HOME/.gnupg"            "700" "~/.gnupg"              "chmod 700 ~/.gnupg"
    _perm_check "$HOME/.password-store"   "700" "~/.password-store"     "chmod 700 ~/.password-store"

    # ── XDG directories ───────────────────────────────────────────────────────────
    local -a xdg_dirs=(
        "${_PERM_CFG}:755:XDG_CONFIG_HOME"
        "${_PERM_DATA}:755:XDG_DATA_HOME"
        "${_PERM_CACHE}:755:XDG_CACHE_HOME"
        "${XDG_STATE_HOME:-$HOME/.local/state}:755:XDG_STATE_HOME"
        "${XDG_RUNTIME_DIR:-/run/user/${UID:-1000}}:700:XDG_RUNTIME_DIR"
    )

    for xdg_entry in "${xdg_dirs[@]}"; do
        IFS=':' read -r dir expected label <<< "$xdg_entry"
        _perm_check "$dir" "$expected" "$label" "chmod ${expected} '${dir}'"
    done

    # ── XDG_RUNTIME_DIR ownership ─────────────────────────────────────────────────
    local runtime_dir="${XDG_RUNTIME_DIR:-/run/user/${UID:-1000}}"
    if [[ -d "$runtime_dir" ]]; then
        local rt_owner
        rt_owner="$(stat -c '%U' "$runtime_dir" 2>/dev/null || echo '?')"
        local cur_user="${USER:-$(whoami)}"
        if [[ "$rt_owner" == "$cur_user" ]]; then
            _check_report $CHECK_PASS \
                "XDG_RUNTIME_DIR owner" \
                "Owned by ${cur_user} ✓"
        else
            _check_report $CHECK_FAIL \
                "XDG_RUNTIME_DIR owner" \
                "Owned by ${rt_owner}, expected ${cur_user}" \
                "This is set by pam_systemd — ensure systemd-logind is running"
        fi
    fi

    # ── ~/.local/bin ─────────────────────────────────────────────────────────────
    local local_bin="$HOME/.local/bin"
    if [[ -d "$local_bin" ]]; then
        _perm_check "$local_bin" "755" "~/.local/bin"

        # All scripts in ~/.local/bin must be executable
        local non_exec
        non_exec="$(find "$local_bin" -maxdepth 1 -type f ! -perm -u+x 2>/dev/null | wc -l)"
        if (( non_exec > 0 )); then
            _check_report $CHECK_WARN \
                "~/.local/bin executables" \
                "${non_exec} file(s) not executable" \
                "Fix: chmod +x ~/.local/bin/*"
        else
            local bin_count
            bin_count="$(find "$local_bin" -maxdepth 1 -type f | wc -l)"
            _check_report $CHECK_PASS \
                "~/.local/bin executables" \
                "${bin_count} file(s) — all executable"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 02 — SSH KEY PERMISSIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_perm_ssh() {
    _check_header "🔑 SSH Key Permissions"

    local ssh_dir="$HOME/.ssh"
    [[ -d "$ssh_dir" ]] || {
        _check_report $CHECK_INFO "SSH directory" "~/.ssh not found  (skip)"
        return $CHECK_PASS
    }

    # ── Private keys — must be 600 or 400 ────────────────────────────────────────
    local priv_keys=()
    mapfile -t priv_keys < <(
        find "$ssh_dir" \( -name 'id_*' ! -name '*.pub' \
        -o -name 'id_ed25519' -o -name 'id_rsa' \
        -o -name 'id_ecdsa' \) 2>/dev/null
    )

    if [[ ${#priv_keys[@]} -eq 0 ]]; then
        _check_report $CHECK_INFO "SSH private keys" "None found"
    fi

    for key in "${priv_keys[@]}"; do
        local kperm
        kperm="$(stat -c '%a' "$key" 2>/dev/null || echo '???')"
        local kname
        kname="${key##*/}"

        if [[ "$kperm" == "600" ]] || [[ "$kperm" == "400" ]]; then
            _check_report $CHECK_PASS \
                "Private key: ${kname}" \
                "${kperm} ✓"
            (( _PERM_PASS++ )) || true
        else
            _check_report $CHECK_FAIL \
                "Private key: ${kname}" \
                "perm ${kperm}  (must be 600 or 400)" \
                "chmod 600 '${key}'"
            _PERM_ISSUES+=("chmod 600 '${key}'")
            (( _PERM_FAIL++ )) || true
        fi
    done

    # ── Public keys — 644 ────────────────────────────────────────────────────────
    local pub_keys=()
    mapfile -t pub_keys < <(find "$ssh_dir" -name '*.pub' 2>/dev/null)

    for pub in "${pub_keys[@]}"; do
        local pperm
        pperm="$(stat -c '%a' "$pub" 2>/dev/null || echo '???')"
        local pname="${pub##*/}"
        if [[ "$pperm" == "644" ]] || [[ "$pperm" == "640" ]]; then
            _check_report $CHECK_PASS "Public key: ${pname}" "${pperm} ✓"
            (( _PERM_PASS++ )) || true
        else
            _check_report $CHECK_WARN \
                "Public key: ${pname}" \
                "perm ${pperm}  (expected 644)" \
                "chmod 644 '${pub}'"
        fi
    done

    # ── authorized_keys ──────────────────────────────────────────────────────────
    local auth_keys="${ssh_dir}/authorized_keys"
    [[ -f "$auth_keys" ]] && _perm_check "$auth_keys" "600" "authorized_keys"

    # ── known_hosts ──────────────────────────────────────────────────────────────
    local known_hosts="${ssh_dir}/known_hosts"
    [[ -f "$known_hosts" ]] && _perm_check "$known_hosts" "644" "known_hosts"

    # ── SSH config ───────────────────────────────────────────────────────────────
    local ssh_config="${ssh_dir}/config"
    [[ -f "$ssh_config" ]] && _perm_check "$ssh_config" "600" "ssh/config"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 03 — ASH SCRIPTS EXECUTABILITY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_perm_scripts() {
    _check_header "📜 ASH Script Executability"

    # ── Main ash CLI binary ───────────────────────────────────────────────────────
    local ash_bin="${_PERM_ASH_CLI}/ash"
    _perm_exec "$ash_bin" "ash CLI binary"

    # ── Check/ scripts (doctor checks) ───────────────────────────────────────────
    local checks_dir="${_PERM_ASH_CLI}/commands"
    if [[ -d "$checks_dir" ]]; then
        local total_scripts non_exec_scripts=0
        total_scripts="$(find "$checks_dir" -name '*.sh' 2>/dev/null | wc -l)"

        while IFS= read -r sh_file; do
            [[ -f "$sh_file" ]] && [[ ! -x "$sh_file" ]] && \
                (( non_exec_scripts++ )) || true
        done < <(find "$checks_dir" -name '*.sh' 2>/dev/null)

        if (( non_exec_scripts == 0 )); then
            _check_report $CHECK_PASS \
                "Command scripts" \
                "${total_scripts} scripts  •  all executable"
            (( _PERM_PASS++ )) || true
        else
            _check_report $CHECK_FAIL \
                "Command scripts" \
                "${non_exec_scripts}/${total_scripts} NOT executable" \
                "Fix: find '${checks_dir}' -name '*.sh' -exec chmod +x {} +"
            _PERM_ISSUES+=("find '${checks_dir}' -name '*.sh' -exec chmod +x {} +")
            (( _PERM_FAIL++ )) || true
        fi
    fi

    # ── Engine scripts ────────────────────────────────────────────────────────────
    local engines_dir="${_PERM_ASH_CLI}/engines"
    if [[ -d "$engines_dir" ]]; then
        local eng_total eng_bad=0
        eng_total="$(find "$engines_dir" -name '*.sh' 2>/dev/null | wc -l)"
        while IFS= read -r sh; do
            [[ -x "$sh" ]] || (( eng_bad++ )) || true
        done < <(find "$engines_dir" -name '*.sh' 2>/dev/null)

        if (( eng_bad == 0 )); then
            _check_report $CHECK_PASS \
                "Engine scripts" \
                "${eng_total} scripts  •  all executable"
            (( _PERM_PASS++ )) || true
        else
            _check_report $CHECK_FAIL \
                "Engine scripts" \
                "${eng_bad}/${eng_total} NOT executable" \
                "Fix: find '${engines_dir}' -name '*.sh' -exec chmod +x {} +"
            (( _PERM_FAIL++ )) || true
        fi
    fi

    # ── Hyprland scripts ──────────────────────────────────────────────────────────
    local hypr_scripts="${_PERM_CFG}/hypr/scripts"
    if [[ -d "$hypr_scripts" ]]; then
        local hs_total hs_bad=0
        hs_total="$(find "$hypr_scripts" -name '*.sh' | wc -l)"
        while IFS= read -r sh; do
            [[ -x "$sh" ]] || (( hs_bad++ )) || true
        done < <(find "$hypr_scripts" -name '*.sh' 2>/dev/null)

        if (( hs_bad == 0 )); then
            _check_report $CHECK_PASS \
                "Hyprland scripts" \
                "${hs_total} scripts  •  all executable"
            (( _PERM_PASS++ )) || true
        else
            _check_report $CHECK_FAIL \
                "Hyprland scripts" \
                "${hs_bad}/${hs_total} NOT executable" \
                "Fix: find '${hypr_scripts}' -name '*.sh' -exec chmod +x {} +"
            (( _PERM_FAIL++ )) || true
        fi
    fi

    # ── Waybar scripts ───────────────────────────────────────────────────────────
    local wb_scripts="${_PERM_CFG}/waybar/scripts"
    if [[ -d "$wb_scripts" ]]; then
        local wb_bad=0
        local wb_total
        wb_total="$(find "$wb_scripts" -name '*.sh' | wc -l)"
        while IFS= read -r sh; do
            [[ -x "$sh" ]] || (( wb_bad++ )) || true
        done < <(find "$wb_scripts" -name '*.sh' 2>/dev/null)
        if (( wb_bad == 0 )); then
            _check_report $CHECK_PASS \
                "Waybar scripts" \
                "${wb_total} scripts  •  all executable"
            (( _PERM_PASS++ )) || true
        else
            _check_report $CHECK_FAIL \
                "Waybar scripts" \
                "${wb_bad}/${wb_total} NOT executable" \
                "Fix: find '${wb_scripts}' -name '*.sh' -exec chmod +x {} +"
            (( _PERM_FAIL++ )) || true
        fi
    fi

    # ── Hook scripts ─────────────────────────────────────────────────────────────
    local hooks_dir="${_PERM_ASH_ROOT}/scripts/hooks"
    if [[ -d "$hooks_dir" ]]; then
        local hooks_bad=0
        local hooks_total
        hooks_total="$(find "$hooks_dir" -name '*.sh' | wc -l)"
        while IFS= read -r sh; do
            [[ -x "$sh" ]] || (( hooks_bad++ )) || true
        done < <(find "$hooks_dir" -name '*.sh' 2>/dev/null)
        if (( hooks_bad == 0 )); then
            _check_report $CHECK_PASS \
                "Hook scripts" \
                "${hooks_total} scripts  •  all executable"
        else
            _check_report $CHECK_WARN \
                "Hook scripts" \
                "${hooks_bad}/${hooks_total} NOT executable"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 04 — USER GROUPS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_perm_groups() {
    _check_header "👥 User Group Membership"

    local current_user="${USER:-$(whoami)}"
    local current_groups
    current_groups="$(groups 2>/dev/null | tr ' ' '\n')"

    # Format: "group:critical:reason"
    local -a required_groups=(
        "video:1:GPU access — required for DRM and hardware acceleration"
        "render:1:DRM render nodes — required for Vulkan/OpenGL"
        "audio:0:Direct audio device access (usually via PipeWire)"
        "input:0:Raw input device access — needed by some Hyprland plugins"
        "seat:0:logind seat — required for rootless Wayland without systemd"
        "storage:0:USB auto-mount without sudo"
        "optical:0:Optical drives"
        "lp:0:Printers"
        "scanner:0:Scanners"
        "bluetooth:0:Bluetooth daemon access"
        "kvm:0:KVM virtualization — required for VMs"
        "docker:0:Docker without sudo"
        "libvirt:0:libvirt virtualization"
        "wireshark:0:Packet capture without root"
        "realtime:0:Low-latency audio (JACK/PipeWire pro audio)"
    )

    local crit_missing=0 opt_missing=0

    for grp_entry in "${required_groups[@]}"; do
        IFS=':' read -r grp critical reason <<< "$grp_entry"

        # Check if group exists on system
        if ! getent group "$grp" &>/dev/null; then
            _check_report $CHECK_INFO \
                "Group: ${grp}" \
                "Group does not exist on this system"
            continue
        fi

        if printf '%s\n' "$current_groups" | grep -qx "$grp"; then
            _check_report $CHECK_PASS \
                "Group: ${grp}" \
                "Member ✓  — ${reason}"
            (( _PERM_PASS++ )) || true
        else
            if [[ "$critical" == "1" ]]; then
                _check_report $CHECK_FAIL \
                    "Group: ${grp}" \
                    "NOT a member  — ${reason}" \
                    "Fix: sudo usermod -aG ${grp} ${current_user}  then re-login"
                _PERM_ISSUES+=("sudo usermod -aG ${grp} ${current_user}")
                (( crit_missing++ )) || true
                (( _PERM_FAIL++ )) || true
            else
                _check_report $CHECK_INFO \
                    "Group: ${grp}  (optional)" \
                    "Not a member  — ${reason}" \
                    "Add: sudo usermod -aG ${grp} ${current_user}"
                (( opt_missing++ )) || true
            fi
        fi
    done

    # ── Summary ───────────────────────────────────────────────────────────────────
    _check_report $CHECK_INFO \
        "Group summary" \
        "${crit_missing} critical missing  •  ${opt_missing} optional missing"

    # ── All current groups ────────────────────────────────────────────────────────
    _check_report $CHECK_INFO \
        "Current groups" \
        "$(groups 2>/dev/null | tr ' ' '  ')"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 05 — SUID / SGID BINARIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_perm_suid() {
    _check_header "🚨 SUID / SGID Binaries"

    # Known legitimate SUID binaries (whitelist)
    local -a whitelist=(
        "/usr/bin/sudo"
        "/usr/bin/su"
        "/usr/bin/passwd"
        "/usr/bin/newgrp"
        "/usr/bin/chsh"
        "/usr/bin/chfn"
        "/usr/bin/gpasswd"
        "/usr/bin/pkexec"
        "/usr/lib/dbus-1.0/dbus-daemon-launch-helper"
        "/usr/lib/polkit-1/polkit-agent-helper-1"
        "/usr/bin/ping"
        "/usr/bin/umount"
        "/usr/bin/mount"
        "/usr/bin/fusermount"
        "/usr/bin/fusermount3"
        "/usr/bin/ksu"
        "/usr/lib/openssh/ssh-keysign"
        "/usr/sbin/pam_timestamp_check"
    )

    # ── Find all SUID binaries ────────────────────────────────────────────────────
    _check_report $CHECK_INFO \
        "SUID scan" \
        "Scanning /usr for SUID binaries..."

    local -a suid_bins=()
    mapfile -t suid_bins < <(
        find /usr /bin /sbin -maxdepth 5 -perm -4000 -type f \
             2>/dev/null | sort
    )

    local known=0 unknown=0
    local -a unknown_suid=()

    for suid_bin in "${suid_bins[@]}"; do
        local is_known=0
        for wl in "${whitelist[@]}"; do
            [[ "$suid_bin" == "$wl" ]] && is_known=1 && break
        done

        if [[ $is_known -eq 1 ]]; then
            (( known++ )) || true
        else
            unknown_suid+=("$suid_bin")
            (( unknown++ )) || true
        fi
    done

    _check_report $CHECK_INFO \
        "SUID binaries total" \
        "${#suid_bins[@]}  (${known} known-legitimate  •  ${unknown} unknown)"

    # ── Report unknown SUID binaries ─────────────────────────────────────────────
    if (( unknown == 0 )); then
        _check_report $CHECK_PASS \
            "Unknown SUID binaries" \
            "None  (all SUID binaries are expected)"
    else
        _check_report $CHECK_WARN \
            "Unknown SUID binaries" \
            "${unknown} unexpected SUID binaries found" \
            "Review and remove SUID if not needed"
        for unknown_bin in "${unknown_suid[@]}"; do
            _check_report $CHECK_WARN \
                "  SUID" \
                "$unknown_bin" \
                "Remove SUID: sudo chmod u-s '${unknown_bin}'"
        done
    fi

    # ── SGID binaries ────────────────────────────────────────────────────────────
    local sgid_count
    sgid_count="$(find /usr /bin /sbin -maxdepth 5 -perm -2000 -type f \
                  2>/dev/null | wc -l)"
    _check_report $CHECK_INFO \
        "SGID binaries" \
        "${sgid_count} SGID binaries in /usr/bin/sbin"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 06 — CONFIG FILE PERMISSIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_perm_configs() {
    _check_header "⚙️  Config File Permission Audit"

    # Sensitive files that should not be world-readable
    local -a sensitive_files=(
        "${_PERM_CFG}/git/.gitconfig:644"
        "${HOME}/.gitconfig:644"
        "${_PERM_CFG}/ssh/config:600"
        "${HOME}/.ssh/config:600"
        "${HOME}/.gnupg/gpg.conf:600"
        "${HOME}/.gnupg/gpg-agent.conf:600"
        "${_PERM_CFG}/ash/ash.conf:644"
        "${_PERM_CFG}/environment.d/ash.conf:644"
    )

    for entry in "${sensitive_files[@]}"; do
        IFS=':' read -r file_path expected_perm <<< "$entry"
        _perm_check "$file_path" "$expected_perm" \
            "${file_path##$HOME/}" \
            "chmod ${expected_perm} '${file_path}'"
    done

    # ── World-writable scan ───────────────────────────────────────────────────────
    _perm_scan_world_writable "${_PERM_CFG}" "~/.config world-writable" 4
    _perm_scan_world_writable "${_PERM_ASH_ROOT}/ash-cli" "ash-cli world-writable" 5

    # ── ASH secrets directory ─────────────────────────────────────────────────────
    local secrets_dir="${_PERM_ASH_ROOT}/secrets"
    if [[ -d "$secrets_dir" ]]; then
        _perm_check "$secrets_dir" "700" "secrets/ directory" \
            "chmod 700 '${secrets_dir}'"

        # Every file in secrets must be 600 or less
        local secret_bad=0
        while IFS= read -r sfile; do
            local sp
            sp="$(stat -c '%a' "$sfile" 2>/dev/null || echo '777')"
            (( 8#$sp > 8#600 )) && (( secret_bad++ )) || true
        done < <(find "$secrets_dir" -maxdepth 1 -type f 2>/dev/null)

        if (( secret_bad > 0 )); then
            _check_report $CHECK_FAIL \
                "Secrets file permissions" \
                "${secret_bad} file(s) have perm > 600" \
                "Fix: chmod 600 '${secrets_dir}'/*"
        else
            _check_report $CHECK_PASS \
                "Secrets file permissions" \
                "All ≤ 600 ✓"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 07 — FIX REPORT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_perm_fix_report() {
    [[ ${#_PERM_ISSUES[@]} -eq 0 ]] && return 0

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;243;139;168m'
        printf '  ╔══════════════════════════════════════════════════════════╗\n'
        printf '  ║  🔧  AUTO-FIX COMMANDS                                    ║\n'
        printf '  ╠══════════════════════════════════════════════════════════╣\033[0m\n'
    else
        printf '\n  AUTO-FIX COMMANDS:\n'
    fi

    for fix_cmd in "${_PERM_ISSUES[@]}"; do
        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
            printf '  \033[38;2;116;199;236m$\033[0m  \033[38;2;205;214;244m%s\033[0m\n' "$fix_cmd"
        else
            printf '  $ %s\n' "$fix_cmd"
        fi
    done

    printf '\n'
    printf '  Or run all: \033[38;2;166;227;161mash doctor fix --permissions\033[0m\n\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_check_permissions() {
    local mode="${1:-full}"

    _CHECK_PASS_COUNT=0;  _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0;  _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=();   _CHECK_WARNINGS=()
    _PERM_PASS=0; _PERM_WARN=0; _PERM_FAIL=0; _PERM_ISSUES=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;245;194;231m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🔐  ASH DOCTOR — PERMISSIONS CHECK                      ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  home • ssh keys • scripts • groups • SUID • configs     ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n=== ASH DOCTOR — PERMISSIONS CHECK ===\n'
    fi

    case "$mode" in
        quick)
            _chk_perm_home
            _chk_perm_ssh
            _chk_perm_groups
            ;;
        scripts) _chk_perm_scripts ;;
        groups)  _chk_perm_groups  ;;
        suid)    _chk_perm_suid    ;;
        full|*)
            _chk_perm_home
            _chk_perm_ssh
            _chk_perm_scripts
            _chk_perm_groups
            _chk_perm_suid
            _chk_perm_configs
            ;;
    esac

    _chk_perm_fix_report
    _ash_check_system_summary
}

ash_check_permissions_quick() {
    local issues=0
    local ssh_dir="$HOME/.ssh"
    if [[ -d "$ssh_dir" ]]; then
        local perm
        perm="$(stat -c '%a' "$ssh_dir" 2>/dev/null || echo '777')"
        (( 8#$perm > 8#700 )) && (( issues++ )) || true
    fi
    groups | grep -qw "video" || (( issues++ )) || true
    groups | grep -qw "render" || (( issues++ )) || true
    if (( issues == 0 )); then
        ash_log_success "Permissions: OK"
    else
        ash_log_warn "Permissions: ${issues} issue(s) — run 'ash doctor full --permissions'"
        return 1
    fi
}
