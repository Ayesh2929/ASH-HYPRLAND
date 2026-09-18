#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ███████╗███████╗ ██████╗██╗   ██╗██████╗ ██╗████████╗██╗   ██╗                 ║
# ║  ██╔════╝██╔════╝██╔════╝██║   ██║██╔══██╗██║╚══██╔══╝╚██╗ ██╔╝                 ║
# ║  ███████╗█████╗  ██║     ██║   ██║██████╔╝██║   ██║    ╚████╔╝                  ║
# ║  ╚════██║██╔══╝  ██║     ██║   ██║██╔══██╗██║   ██║     ╚██╔╝                   ║
# ║  ███████║███████╗╚██████╗╚██████╔╝██║  ██║██║   ██║      ██║                    ║
# ║  ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝      ╚═╝                    ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  DOCTOR CHECK: SECURITY                                  ║
# ║  Kernel hardening • CVE exposure • secrets scan • network attack surface        ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CHECK_SECURITY_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CHECK_SECURITY_LOADED=1

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
# 🔷  SECURITY SCORE STATE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g  _SEC_SCORE=100      # Start at 100, deduct for issues
declare -g  _SEC_FINDINGS=0
declare -ga _SEC_HIGH=()
declare -ga _SEC_MEDIUM=()
declare -ga _SEC_LOW=()
declare -ga _SEC_INFO_LIST=()

_sec_deduct() {
    local points="$1"
    local finding="$2"
    local severity="${3:-medium}"  # high | medium | low

    (( _SEC_SCORE -= points )) || true
    (( _SEC_FINDINGS++ )) || true

    case "$severity" in
        high)   _SEC_HIGH+=("$finding")   ;;
        medium) _SEC_MEDIUM+=("$finding") ;;
        low)    _SEC_LOW+=("$finding")    ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 01 — KERNEL SECURITY FEATURES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_sec_kernel() {
    _check_header "🔩 Kernel Security Features"

    # ── ASLR ─────────────────────────────────────────────────────────────────────
    local aslr
    aslr="$(cat /proc/sys/kernel/randomize_va_space 2>/dev/null || echo '?')"
    if [[ "$aslr" == "2" ]]; then
        _check_report $CHECK_PASS \
            "ASLR" \
            "Full randomization (2)  — address space layout randomization"
    elif [[ "$aslr" == "1" ]]; then
        _check_report $CHECK_WARN \
            "ASLR" \
            "Partial (1)  — should be 2" \
            "Enable: sudo sysctl -w kernel.randomize_va_space=2"
        _sec_deduct 5 "ASLR partial" "medium"
    else
        _check_report $CHECK_FAIL \
            "ASLR" \
            "DISABLED (${aslr})" \
            "Enable: echo 'kernel.randomize_va_space=2' | sudo tee -a /etc/sysctl.d/99-security.conf"
        _sec_deduct 15 "ASLR disabled" "high"
    fi

    # ── PTrace scope ─────────────────────────────────────────────────────────────
    local ptrace
    ptrace="$(cat /proc/sys/kernel/yama/ptrace_scope 2>/dev/null || echo '?')"
    case "$ptrace" in
        0) _check_report $CHECK_WARN \
               "ptrace scope" "0  (unrestricted — any process can trace any)" \
               "Restrict: echo 1 > /proc/sys/kernel/yama/ptrace_scope"
           _sec_deduct 5 "ptrace unrestricted" "medium" ;;
        1) _check_report $CHECK_PASS "ptrace scope" "1  (restricted to parent processes)" ;;
        2) _check_report $CHECK_PASS "ptrace scope" "2  (admin-only)" ;;
        3) _check_report $CHECK_PASS "ptrace scope" "3  (disabled completely)" ;;
        *) _check_report $CHECK_INFO "ptrace scope" "${ptrace:-not available}" ;;
    esac

    # ── kernel.dmesg_restrict ─────────────────────────────────────────────────────
    local dmesg_r
    dmesg_r="$(cat /proc/sys/kernel/dmesg_restrict 2>/dev/null || echo '?')"
    if [[ "$dmesg_r" == "1" ]]; then
        _check_report $CHECK_PASS \
            "dmesg_restrict" \
            "1  (restricted to root)"
    else
        _check_report $CHECK_INFO \
            "dmesg_restrict" \
            "${dmesg_r:-not available}  (any user can read kernel ring buffer)" \
            "Restrict: sudo sysctl -w kernel.dmesg_restrict=1"
    fi

    # ── kernel.kptr_restrict ─────────────────────────────────────────────────────
    local kptr
    kptr="$(cat /proc/sys/kernel/kptr_restrict 2>/dev/null || echo '?')"
    if [[ "$kptr" == "2" ]] || [[ "$kptr" == "1" ]]; then
        _check_report $CHECK_PASS \
            "kptr_restrict" \
            "${kptr}  (kernel pointers hidden)"
    else
        _check_report $CHECK_INFO \
            "kptr_restrict" \
            "${kptr:-not set}  (kernel pointers exposed)" \
            "Hide: sudo sysctl -w kernel.kptr_restrict=2"
    fi

    # ── Secure boot ──────────────────────────────────────────────────────────────
    local sb_status="unknown"
    if command -v mokutil &>/dev/null; then
        sb_status="$(mokutil --sb-state 2>/dev/null | grep -oP '(enabled|disabled)' || echo 'unknown')"
    elif [[ -d /sys/firmware/efi ]]; then
        sb_status="UEFI system — check mokutil for Secure Boot status"
    fi
    _check_report $CHECK_INFO \
        "Secure Boot" \
        "$sb_status"

    # ── CPU vulnerabilities ───────────────────────────────────────────────────────
    local vuln_dir="/sys/devices/system/cpu/vulnerabilities"
    if [[ -d "$vuln_dir" ]]; then
        local vuln_files=()
        mapfile -t vuln_files < <(find "$vuln_dir" -type f | sort)
        local not_affected=0 mitigated=0 vulnerable=0

        for vf in "${vuln_files[@]}"; do
            local vname vval
            vname="$(basename "$vf")"
            vval="$(cat "$vf" 2>/dev/null || echo 'unknown')"

            case "$vval" in
                "Not affected")
                    (( not_affected++ )) || true ;;
                Mitigation*)
                    (( mitigated++ )) || true ;;
                Vulnerable*)
                    (( vulnerable++ )) || true
                    _check_report $CHECK_FAIL \
                        "CPU vuln: ${vname}" \
                        "$vval" \
                        "Update kernel: paru -Su linux"
                    _sec_deduct 10 "CPU vulnerable: ${vname}" "high"
                    ;;
                *)
                    _check_report $CHECK_INFO \
                        "CPU vuln: ${vname}" \
                        "$vval" ;;
            esac
        done

        _check_report $CHECK_INFO \
            "CPU vulnerabilities" \
            "${not_affected} not-affected  •  ${mitigated} mitigated  •  ${vulnerable} VULNERABLE"
    fi

    # ── /proc/kallsyms restriction ────────────────────────────────────────────────
    local kallsyms_r
    kallsyms_r="$(cat /proc/sys/kernel/perf_event_paranoid 2>/dev/null || echo '?')"
    if [[ "$kallsyms_r" =~ ^[0-9]+$ ]] && (( kallsyms_r >= 2 )); then
        _check_report $CHECK_PASS \
            "perf_event_paranoid" \
            "${kallsyms_r}  (restricted performance events)"
    else
        _check_report $CHECK_INFO \
            "perf_event_paranoid" \
            "${kallsyms_r:-?}  (performance events accessible)" \
            "Restrict: sudo sysctl -w kernel.perf_event_paranoid=3"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 02 — NETWORK SECURITY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_sec_network() {
    _check_header "🌐 Network Security"

    # ── IP forwarding ─────────────────────────────────────────────────────────────
    local ip_forward
    ip_forward="$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo '?')"
    if [[ "$ip_forward" == "0" ]]; then
        _check_report $CHECK_PASS \
            "IP forwarding (IPv4)" \
            "Disabled  (correct for desktop)"
    else
        _check_report $CHECK_INFO \
            "IP forwarding (IPv4)" \
            "Enabled  (required for VPN/VM routing)"
    fi

    # ── ICMP redirects ───────────────────────────────────────────────────────────
    local icmp_accept
    icmp_accept="$(cat /proc/sys/net/ipv4/conf/all/accept_redirects \
                  2>/dev/null || echo '?')"
    if [[ "$icmp_accept" == "0" ]]; then
        _check_report $CHECK_PASS \
            "ICMP redirects" \
            "Not accepted  (protects against MITM)"
    else
        _check_report $CHECK_WARN \
            "ICMP redirects" \
            "Accepted  (MITM risk)" \
            "Disable: sudo sysctl -w net.ipv4.conf.all.accept_redirects=0"
        _sec_deduct 5 "ICMP redirects accepted" "medium"
    fi

    # ── SYN cookies ──────────────────────────────────────────────────────────────
    local syn_cookies
    syn_cookies="$(cat /proc/sys/net/ipv4/tcp_syncookies 2>/dev/null || echo '?')"
    if [[ "$syn_cookies" == "1" ]]; then
        _check_report $CHECK_PASS \
            "TCP SYN cookies" \
            "Enabled  (SYN flood protection)"
    else
        _check_report $CHECK_WARN \
            "TCP SYN cookies" \
            "Disabled  (SYN flood vulnerability)" \
            "Enable: sudo sysctl -w net.ipv4.tcp_syncookies=1"
        _sec_deduct 5 "TCP SYN cookies disabled" "medium"
    fi

    # ── Source route ─────────────────────────────────────────────────────────────
    local src_route
    src_route="$(cat /proc/sys/net/ipv4/conf/all/accept_source_route \
                2>/dev/null || echo '?')"
    if [[ "$src_route" == "0" ]]; then
        _check_report $CHECK_PASS \
            "Source routing" \
            "Disabled  (correct)"
    else
        _check_report $CHECK_WARN \
            "Source routing" \
            "Enabled  (spoofing risk)" \
            "Disable: sudo sysctl -w net.ipv4.conf.all.accept_source_route=0"
        _sec_deduct 5 "Source routing enabled" "medium"
    fi

    # ── Martian packets logging ───────────────────────────────────────────────────
    local martians
    martians="$(cat /proc/sys/net/ipv4/conf/all/log_martians 2>/dev/null || echo '?')"
    if [[ "$martians" == "1" ]]; then
        _check_report $CHECK_PASS \
            "Martian packet logging" \
            "Enabled  (logs suspicious packets)"
    else
        _check_report $CHECK_INFO \
            "Martian packet logging" \
            "Disabled" \
            "Enable: sudo sysctl -w net.ipv4.conf.all.log_martians=1"
    fi

    # ── Listening services ───────────────────────────────────────────────────────
    if command -v ss &>/dev/null; then
        local world_listen
        world_listen="$(ss -tlnp 2>/dev/null | awk 'NR>1 && $4!~/127\.|::1/{print}' | \
                       grep -v '^$' | wc -l)"
        if (( world_listen == 0 )); then
            _check_report $CHECK_PASS \
                "World-accessible TCP services" \
                "None  (no services listening on 0.0.0.0/*)"
        else
            _check_report $CHECK_WARN \
                "World-accessible TCP services" \
                "${world_listen} service(s) listening on all interfaces" \
                "Review: ss -tlnp | grep -v '127\.\|::1'"
            _sec_deduct 5 "Services exposed on all interfaces" "medium"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 03 — SECRETS & CREDENTIAL SCAN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_sec_secrets() {
    _check_header "🔒 Secrets & Credential Scan"

    local ash_root="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}"

    # ── Common secret patterns in ASH config files ────────────────────────────────
    local -a secret_patterns=(
        'password\s*=\s*["\047][^\047"]{6,}'
        'secret\s*=\s*["\047][^\047"]{6,}'
        'api_key\s*=\s*["\047][^\047"]{10,}'
        'apikey\s*=\s*["\047][^\047"]{10,}'
        'token\s*=\s*["\047][^\047"]{10,}'
        'private_key\s*=\s*["\047]'
        'aws_secret_access_key\s*='
        'sk-[a-zA-Z0-9]{32,}'
        'ghp_[a-zA-Z0-9]{36}'
        'glpat-[a-zA-Z0-9\-_]{20}'
        'AKIA[A-Z0-9]{16}'
        'eyJ[a-zA-Z0-9_-]{10,}\.'
    )

    local secret_hits=0
    local -a secret_files=()

    if command -v grep &>/dev/null; then
        local pattern_regex
        pattern_regex="$(printf '%s\n' "${secret_patterns[@]}" | paste -sd '|')"

        while IFS= read -r hit_file; do
            [[ -z "$hit_file" ]] && continue
            secret_files+=("$hit_file")
            (( secret_hits++ )) || true
        done < <(
            grep -rEl "$pattern_regex" \
                --include='*.conf' \
                --include='*.json' \
                --include='*.yaml' \
                --include='*.yml' \
                --include='*.toml' \
                --include='*.env' \
                --include='*.sh' \
                "$ash_root" \
                2>/dev/null | head -20 || true
        )
    fi

    if (( secret_hits == 0 )); then
        _check_report $CHECK_PASS \
            "Secret pattern scan" \
            "No credentials detected in config files"
    else
        _check_report $CHECK_FAIL \
            "Secret pattern scan" \
            "${secret_hits} file(s) may contain hardcoded credentials" \
            "Review and move to encrypted secrets manager"
        _sec_deduct 20 "Potential hardcoded secrets found" "high"

        for sf in "${secret_files[@]:0:5}"; do
            _check_report $CHECK_FAIL \
                "  Potential secret" \
                "${sf/#$HOME/~}"
        done
    fi

    # ── .env files ────────────────────────────────────────────────────────────────
    local env_files
    env_files="$(find "$HOME" -maxdepth 4 -name '.env' \
                -o -name '.env.local' -o -name '.env.production' \
                2>/dev/null | head -10 || echo '')"

    if [[ -n "$env_files" ]]; then
        local ef_count
        ef_count="$(printf '%s\n' "$env_files" | grep -c '.' || echo 0)"
        _check_report $CHECK_INFO \
            ".env files found" \
            "${ef_count} .env file(s)  — ensure not committed to git"
    fi

    # ── git credential helper ─────────────────────────────────────────────────────
    local git_cred_helper
    git_cred_helper="$(git config --global credential.helper 2>/dev/null || echo '')"
    if [[ -z "$git_cred_helper" ]]; then
        _check_report $CHECK_WARN \
            "Git credential helper" \
            "Not configured  — passwords may be stored in plaintext" \
            "Set: git config --global credential.helper store  (or libsecret)"
        _sec_deduct 5 "Git credentials not secured" "low"
    else
        _check_report $CHECK_PASS \
            "Git credential helper" \
            "$git_cred_helper"
    fi

    # ── SSH agent ────────────────────────────────────────────────────────────────
    if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
        _check_report $CHECK_PASS \
            "SSH agent" \
            "Running  (keys loaded in memory)"
    else
        _check_report $CHECK_INFO \
            "SSH agent" \
            "Not running — SSH passphrases will be asked every time"
    fi

    # ── GPG key expiry ────────────────────────────────────────────────────────────
    if command -v gpg &>/dev/null; then
        local expired_keys
        expired_keys="$(gpg --list-keys 2>/dev/null | grep -c '\[expired\]' || echo 0)"
        if (( expired_keys > 0 )); then
            _check_report $CHECK_WARN \
                "GPG expired keys" \
                "${expired_keys} expired key(s)" \
                "Extend or remove expired keys"
            _sec_deduct 3 "GPG keys expired" "low"
        else
            _check_report $CHECK_PASS \
                "GPG key expiry" \
                "No expired keys"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 04 — AUTHENTICATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_sec_auth() {
    _check_header "🔑 Authentication Security"

    # ── SSH root login ────────────────────────────────────────────────────────────
    local sshd_conf="/etc/ssh/sshd_config"
    if [[ -f "$sshd_conf" ]]; then
        local root_login
        root_login="$(grep -iE '^\s*PermitRootLogin' "$sshd_conf" 2>/dev/null | \
                     awk '{print $2}' | tail -1)"

        if [[ -z "$root_login" ]] || [[ "${root_login,,}" == "prohibit-password" ]]; then
            _check_report $CHECK_PASS \
                "SSH PermitRootLogin" \
                "${root_login:-default (prohibit-password)}"
        elif [[ "${root_login,,}" == "no" ]]; then
            _check_report $CHECK_PASS \
                "SSH PermitRootLogin" \
                "no  (root login disabled)"
        else
            _check_report $CHECK_FAIL \
                "SSH PermitRootLogin" \
                "${root_login}  (root login ALLOWED)" \
                "Set PermitRootLogin no in /etc/ssh/sshd_config"
            _sec_deduct 15 "SSH root login enabled" "high"
        fi

        # ── SSH password auth ─────────────────────────────────────────────────────
        local pass_auth
        pass_auth="$(grep -iE '^\s*PasswordAuthentication' "$sshd_conf" 2>/dev/null | \
                    awk '{print $2}' | tail -1)"

        if [[ "${pass_auth,,}" == "no" ]]; then
            _check_report $CHECK_PASS \
                "SSH PasswordAuthentication" \
                "no  (key-only login)"
        else
            _check_report $CHECK_WARN \
                "SSH PasswordAuthentication" \
                "${pass_auth:-yes (default)}  — brute-force risk" \
                "Disable: PasswordAuthentication no in /etc/ssh/sshd_config"
            _sec_deduct 8 "SSH password auth enabled" "medium"
        fi

        # ── SSH protocol ──────────────────────────────────────────────────────────
        local ssh_port
        ssh_port="$(grep -iE '^\s*Port' "$sshd_conf" 2>/dev/null | \
                   awk '{print $2}' | tail -1)"
        if [[ -z "$ssh_port" ]]; then ssh_port="22"; fi

        if [[ "$ssh_port" == "22" ]]; then
            _check_report $CHECK_INFO \
                "SSH port" \
                "22  (default — consider changing to reduce brute-force)"
        else
            _check_report $CHECK_PASS \
                "SSH port" \
                "${ssh_port}  (non-standard — good)"
        fi
    else
        _check_report $CHECK_INFO \
            "sshd_config" \
            "Not found  (SSH daemon not installed)"
    fi

    # ── Sudo config ───────────────────────────────────────────────────────────────
    if command -v sudo &>/dev/null; then
        # Check for NOPASSWD sudo
        local nopasswd_count
        nopasswd_count="$(sudo -l 2>/dev/null | grep -c 'NOPASSWD' || echo 0)"
        if (( nopasswd_count > 0 )); then
            _check_report $CHECK_WARN \
                "sudo NOPASSWD" \
                "${nopasswd_count} NOPASSWD rule(s)  — passwordless sudo" \
                "Review: sudo -l"
            _sec_deduct 5 "sudo NOPASSWD configured" "medium"
        else
            _check_report $CHECK_PASS \
                "sudo NOPASSWD" \
                "Not configured  (password required)"
        fi

        # Sudo timestamp timeout
        local sudo_ts
        sudo_ts="$(sudo -l 2>/dev/null | \
                  grep -oP '(?<=env_reset)[^,]*' | head -1 || echo '')"
        _check_report $CHECK_INFO \
            "sudo session" \
            "Password cached for 15 minutes (default)"
    fi

    # ── PAM password policy ───────────────────────────────────────────────────────
    local pam_pwquality="/etc/pam.d/passwd"
    if [[ -f "$pam_pwquality" ]]; then
        if grep -q 'pwquality\|pam_cracklib' "$pam_pwquality" 2>/dev/null; then
            _check_report $CHECK_PASS \
                "PAM password quality" \
                "Password quality enforcement active"
        else
            _check_report $CHECK_INFO \
                "PAM password quality" \
                "pwquality not in /etc/pam.d/passwd"
        fi
    fi

    # ── Root account ─────────────────────────────────────────────────────────────
    local root_shell
    root_shell="$(getent passwd root 2>/dev/null | cut -d: -f7)"
    if [[ "$root_shell" == "/usr/bin/nologin" ]] || \
       [[ "$root_shell" == "/sbin/nologin" ]]    || \
       [[ "$root_shell" == "/bin/false" ]]; then
        _check_report $CHECK_PASS \
            "Root direct login" \
            "Disabled (${root_shell})"
    else
        _check_report $CHECK_INFO \
            "Root direct login" \
            "Enabled (${root_shell:-/bin/bash})  — use sudo instead"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 05 — FILE SYSTEM SECURITY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_sec_filesystem() {
    _check_header "📂 Filesystem Security"

    # ── /tmp noexec mount ─────────────────────────────────────────────────────────
    local tmp_opts
    tmp_opts="$(findmnt -n -o OPTIONS /tmp 2>/dev/null || echo '')"
    if printf '%s' "$tmp_opts" | grep -q 'noexec'; then
        _check_report $CHECK_PASS \
            "/tmp noexec" \
            "Mounted with noexec  (script execution in /tmp blocked)"
    else
        _check_report $CHECK_INFO \
            "/tmp noexec" \
            "noexec not set  (scripts can be executed from /tmp)"
    fi

    # ── /proc hidepid ────────────────────────────────────────────────────────────
    local proc_opts
    proc_opts="$(findmnt -n -o OPTIONS /proc 2>/dev/null || echo '')"
    if printf '%s' "$proc_opts" | grep -q 'hidepid'; then
        _check_report $CHECK_PASS \
            "/proc hidepid" \
            "hidepid set  (users can't see other users' processes)"
    else
        _check_report $CHECK_INFO \
            "/proc hidepid" \
            "Not set  (all processes visible to all users)"
    fi

    # ── Sticky bit on /tmp ────────────────────────────────────────────────────────
    local tmp_perm
    tmp_perm="$(stat -c '%a' /tmp 2>/dev/null || echo '???')"
    if [[ "$tmp_perm" =~ ^1 ]]; then
        _check_report $CHECK_PASS \
            "/tmp sticky bit" \
            "Set (${tmp_perm})  — users can't delete others' files"
    else
        _check_report $CHECK_FAIL \
            "/tmp sticky bit" \
            "NOT set (${tmp_perm})  — privilege escalation risk" \
            "Fix: sudo chmod +t /tmp"
        _sec_deduct 10 "/tmp sticky bit missing" "high"
    fi

    # ── /etc/cron.d permissions ───────────────────────────────────────────────────
    for cron_dir in /etc/cron.d /etc/cron.daily /etc/cron.weekly; do
        if [[ -d "$cron_dir" ]]; then
            local cron_perm
            cron_perm="$(stat -c '%a' "$cron_dir" 2>/dev/null || echo '???')"
            if (( 8#$cron_perm <= 8#755 )); then
                _check_report $CHECK_PASS \
                    "${cron_dir##/etc/}" \
                    "perm ${cron_perm}  (secure)"
            else
                _check_report $CHECK_WARN \
                    "${cron_dir##/etc/}" \
                    "perm ${cron_perm}  (too permissive)" \
                    "Fix: sudo chmod 755 ${cron_dir}"
                _sec_deduct 5 "Cron dir too permissive" "medium"
            fi
        fi
    done

    # ── Umask ─────────────────────────────────────────────────────────────────────
    local current_umask
    current_umask="$(umask 2>/dev/null || echo '?')"
    if [[ "$current_umask" == "0022" ]] || [[ "$current_umask" == "022" ]]; then
        _check_report $CHECK_PASS \
            "umask" \
            "${current_umask}  (new files: 644, dirs: 755)"
    elif [[ "$current_umask" == "0027" ]] || [[ "$current_umask" == "027" ]]; then
        _check_report $CHECK_PASS \
            "umask" \
            "${current_umask}  (strict — new files: 640, dirs: 750)"
    else
        _check_report $CHECK_INFO \
            "umask" \
            "${current_umask}"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 06 — SECURITY SCORE REPORT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_sec_score() {
    local score="${_SEC_SCORE}"
    (( score < 0 )) && score=0

    local grade color grade_icon
    if   (( score >= 90 )); then
        grade="A+"  color=$'\033[1;38;2;166;227;161m'  grade_icon="🛡️ "
    elif (( score >= 80 )); then
        grade="A"   color=$'\033[38;2;166;227;161m'    grade_icon="🔒"
    elif (( score >= 70 )); then
        grade="B"   color=$'\033[38;2;249;226;175m'    grade_icon="⚠️ "
    elif (( score >= 60 )); then
        grade="C"   color=$'\033[38;2;250;179;135m'    grade_icon="⚠️ "
    else
        grade="D"   color=$'\033[1;38;2;243;139;168m'  grade_icon="🚨"
    fi

    local bar_width=40
    local filled=$(( score * bar_width / 100 ))
    local empty=$(( bar_width - filled ))
    local bar=""
    local i
    for (( i=0; i<filled; i++ )); do bar+='█'; done
    for (( i=0; i<empty;  i++ )); do bar+='░'; done

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;243;139;168m'
        printf '  ╔══════════════════════════════════════════════════════════╗\n'
        printf '  ║  🔐  SECURITY SCORE                                       ║\n'
        printf '  ╠══════════════════════════════════════════════════════════╣\n'
        printf '  ║  %s%s%s  %s%3d/100  %s%-3s%s                                 ║\n' \
            "$color" "$bar" $'\033[0m\033[1;38;2;243;139;168m' \
            "$color" "$score" "$color" "${grade}" $'\033[38;2;243;139;168m'
        printf '  ║  %s findings  •  %d HIGH  •  %d MEDIUM  •  %d LOW        ║\n' \
            "$_SEC_FINDINGS" "${#_SEC_HIGH[@]}" "${#_SEC_MEDIUM[@]}" "${#_SEC_LOW[@]}"
        printf '  ╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n  SECURITY SCORE: %d/100  (Grade: %s)\n' "$score" "$grade"
        printf '  Findings: %d  •  HIGH: %d  MEDIUM: %d  LOW: %d\n\n' \
            "$_SEC_FINDINGS" "${#_SEC_HIGH[@]}" "${#_SEC_MEDIUM[@]}" "${#_SEC_LOW[@]}"
    fi

    # ── High findings ─────────────────────────────────────────────────────────────
    if [[ ${#_SEC_HIGH[@]} -gt 0 ]]; then
        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
            printf '\033[1;38;2;243;139;168m  🚨 HIGH SEVERITY:\033[0m\n'
        else
            printf '  HIGH SEVERITY:\n'
        fi
        for h in "${_SEC_HIGH[@]}"; do
            printf '    • %s\n' "$h"
        done
        printf '\n'
    fi

    # ── Medium findings ───────────────────────────────────────────────────────────
    if [[ ${#_SEC_MEDIUM[@]} -gt 0 ]] && [[ "${ASH_FLAG_VERBOSE:-0}" -eq 1 ]]; then
        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
            printf '\033[1;38;2;249;226;175m  ⚠️  MEDIUM SEVERITY:\033[0m\n'
        else
            printf '  MEDIUM SEVERITY:\n'
        fi
        for m in "${_SEC_MEDIUM[@]}"; do
            printf '    • %s\n' "$m"
        done
        printf '\n'
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_check_security() {
    local mode="${1:-full}"

    _CHECK_PASS_COUNT=0;  _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0;  _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=();   _CHECK_WARNINGS=()
    _SEC_SCORE=100; _SEC_FINDINGS=0
    _SEC_HIGH=(); _SEC_MEDIUM=(); _SEC_LOW=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;243;139;168m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🔐  ASH DOCTOR — SECURITY CHECK                         ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  kernel • network • secrets • auth • filesystem • score  ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n=== ASH DOCTOR — SECURITY CHECK ===\n'
    fi

    case "$mode" in
        quick)
            _chk_sec_kernel
            _chk_sec_network
            ;;
        secrets)    _chk_sec_secrets    ;;
        auth)       _chk_sec_auth       ;;
        kernel)     _chk_sec_kernel     ;;
        full|*)
            _chk_sec_kernel
            _chk_sec_network
            _chk_sec_secrets
            _chk_sec_auth
            _chk_sec_filesystem
            ;;
    esac

    _chk_sec_score
    _ash_check_system_summary
}

ash_check_security_quick() {
    local issues=0
    local aslr
    aslr="$(cat /proc/sys/kernel/randomize_va_space 2>/dev/null || echo 0)"
    [[ "$aslr" == "2" ]] || (( issues++ )) || true

    local tmp_perm
    tmp_perm="$(stat -c '%a' /tmp 2>/dev/null || echo '777')"
    [[ "$tmp_perm" =~ ^1 ]] || (( issues++ )) || true

    if (( issues == 0 )); then
        ash_log_success "Security: OK  (ASLR enabled  •  /tmp sticky)"
    else
        ash_log_warn "Security: ${issues} issue(s) — run 'ash doctor full --security'"
        return 1
    fi
}
