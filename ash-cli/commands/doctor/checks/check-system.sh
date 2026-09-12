#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════════════╗
# ║  ░██████╗██╗░░░██╗░██████╗████████╗███████╗███╗░░░███╗                                ║
# ║  ██╔════╝╚██╗░██╔╝██╔════╝╚══██╔══╝██╔════╝████╗░████║                                ║
# ║  ╚█████╗░░╚████╔╝░╚█████╗░░░░██║░░░█████╗░░██╔████╔██║                                ║
# ║  ░╚═══██╗░░╚██╔╝░░░╚═══██╗░░░██║░░░██╔══╝░░██║╚██╔╝██║                                ║
# ║  ██████╔╝░░░██║░░░██████╔╝░░░██║░░░███████╗██║░╚═╝░██║                                ║
# ║  ╚═════╝░░░░╚═╝░░░╚═════╝░░░░╚═╝░░░╚══════╝╚═╝░░░░░╚═╝                                ║
# ║                                                                                          ║
# ║  ASH DOTFILES v5.0 OMEGA ◆ DOCTOR CHECK — SYSTEM                                      ║
# ║  Deep system environment audit: OS, kernel, hardware, memory, storage,                ║
# ║  users, locale, timezone, processes, limits & environment variables                   ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════╝
# shellcheck disable=SC2154,SC1090,SC1091
# Sourced as a library by _common.sh, so shell options are only
# tightened when this file is EXECUTED directly. A sourced file that
# sets -e/-u rewrites the options of whoever loaded it — the first
# module would make the whole doctor process abort on any non-zero
# status or unset variable.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
fi
IFS=$'\n\t'

# ── Guard: must be sourced from doctor.sh ─────────────────────────────────────
# Guard against being sourced outside the doctor environment. This must NOT
# `exit`: a sourced file that exits takes its caller with it, so one missed
# dependency would kill doctor and the whole ash process instead of skipping one
# module. `return 0` leaves the module unloaded, which _ash_check_load_all
# reports as a skip.
if [[ -z "${DOC_VERSION:-}" ]]; then
    printf 'SKIP: %s needs the ash doctor environment — not sourced\n' "${BASH_SOURCE[0]##*/}" >&2
    return 0
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § HELPERS — system-specific
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_sys::cpu_count()     { nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo 1; }
_sys::total_mem_mb()  { awk '/MemTotal/  {printf "%.0f",$2/1024}' /proc/meminfo 2>/dev/null || echo 0; }
_sys::avail_mem_mb()  { awk '/MemAvailable/{printf "%.0f",$2/1024}' /proc/meminfo 2>/dev/null || echo 0; }
_sys::load_1m()       { awk '{print $1}' /proc/loadavg 2>/dev/null || echo 0; }
_sys::load_5m()       { awk '{print $2}' /proc/loadavg 2>/dev/null || echo 0; }
_sys::load_15m()      { awk '{print $3}' /proc/loadavg 2>/dev/null || echo 0; }
_sys::uptime_secs()   { awk '{printf "%.0f",$1}' /proc/uptime 2>/dev/null || echo 0; }
_sys::disk_avail_mb() { df -m "${1:-/}" 2>/dev/null | awk 'NR==2{print $4}' || echo 0; }
_sys::disk_pct()      { df -m "${1:-/}" 2>/dev/null | awk 'NR==2{print $5}' | tr -d '%' || echo 0; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § CHECK FUNCTIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

check_system::os() {
    local cat="system"

    # ── Distribution ──────────────────────────────────────────────────────────
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        local os_name os_id os_ver os_pretty
        os_name=$(  . /etc/os-release && printf '%s' "${NAME:-}")
        os_id=$(    . /etc/os-release && printf '%s' "${ID:-}")
        os_ver=$(   . /etc/os-release && printf '%s' "${VERSION_ID:-rolling}")
        os_pretty=$(. /etc/os-release && printf '%s' "${PRETTY_NAME:-}")

        doc::result "${SEV_INFO}" "${cat}" "sys.os.distro" \
            "🐧 Distribution" "${os_pretty}" ""

        # Arch-based: best supported
        local distro_sev="${SEV_INFO}"
        [[ "${os_id}" =~ ^(arch|manjaro|endeavouros|garuda|cachyos|artix)$ ]] && \
            distro_sev="${SEV_PASS}"
        [[ "${os_id}" =~ ^(fedora|nobara)$ ]] && distro_sev="${SEV_PASS}"
        [[ "${os_id}" == "nixos" ]] && distro_sev="${SEV_PASS}"
        doc::result "${distro_sev}" "${cat}" "sys.os.support" \
            "🐧 Distro Support" \
            "$( [[ "${distro_sev}" == "${SEV_PASS}" ]] \
                && printf 'Fully supported' \
                || printf 'Limited support — Arch/Fedora/NixOS recommended')" ""
    else
        doc::result "${SEV_WARN}" "${cat}" "sys.os.distro" \
            "🐧 Distribution" "/etc/os-release missing" ""
    fi

    # ── Kernel ────────────────────────────────────────────────────────────────
    local kernel; kernel=$(uname -r)
    local kernel_maj; kernel_maj=$(printf '%s' "${kernel}" | cut -d. -f1)
    local kernel_min; kernel_min=$(printf '%s' "${kernel}" | cut -d. -f2)
    local k_sev="${SEV_PASS}"
    # Require ≥ 6.1 for best Wayland/DMA-BUF support
    if (( kernel_maj < 6 )) || { (( kernel_maj == 6 )) && (( kernel_min < 1 )); }; then
        k_sev="${SEV_WARN}"
    fi
    doc::result "${k_sev}" "${cat}" "sys.os.kernel" \
        "⚙ Kernel Version" "${kernel}" \
        "$( [[ "${k_sev}" == "${SEV_WARN}" ]] \
            && printf 'Upgrade to ≥6.1 for best Wayland support' || printf '')"

    # ── Architecture ──────────────────────────────────────────────────────────
    local arch; arch=$(uname -m)
    local arch_sev; [[ "${arch}" == "x86_64" ]] && arch_sev="${SEV_PASS}" || arch_sev="${SEV_WARN}"
    doc::result "${arch_sev}" "${cat}" "sys.os.arch" \
        "🏗 Architecture" "${arch}" \
        "$( [[ "${arch_sev}" == "${SEV_WARN}" ]] && printf 'Only x86_64 fully supported' || printf '')"

    # ── Bash version ──────────────────────────────────────────────────────────
    local bash_ver="${BASH_VERSION}"
    local bash_maj="${BASH_VERSINFO[0]}" bash_min="${BASH_VERSINFO[1]}"
    local bash_sev="${SEV_PASS}"
    (( bash_maj < 5 )) && bash_sev="${SEV_FAIL}"
    { (( bash_maj == 5 )) && (( bash_min < 1 )); } && bash_sev="${SEV_WARN}"
    doc::result "${bash_sev}" "${cat}" "sys.os.bash" \
        "🐚 Bash Version" "${bash_ver}" \
        "$( [[ "${bash_sev}" != "${SEV_PASS}" ]] \
            && printf 'Bash ≥5.1 required' || printf '')"

    # ── Systemd ───────────────────────────────────────────────────────────────
    if command -v systemctl &>/dev/null; then
        local sd_ver; sd_ver=$(systemctl --version 2>/dev/null | head -1 | awk '{print $2}')
        local sd_sev; (( sd_ver >= 252 )) && sd_sev="${SEV_PASS}" || sd_sev="${SEV_WARN}"
        doc::result "${sd_sev}" "${cat}" "sys.os.systemd" \
            "⚙ Systemd Version" "v${sd_ver}" ""
    else
        doc::result "${SEV_WARN}" "${cat}" "sys.os.systemd" \
            "⚙ Systemd" "Not found — some ASH services unavailable" ""
    fi

    # ── Init system ───────────────────────────────────────────────────────────
    local init_sys="unknown"
    [[ -d /run/systemd ]]    && init_sys="systemd"
    [[ -f /run/openrc/softlevel ]] && init_sys="openrc"
    [[ -d /run/runit ]]      && init_sys="runit"
    local init_sev; [[ "${init_sys}" == "systemd" ]] && init_sev="${SEV_PASS}" || init_sev="${SEV_INFO}"
    doc::result "${init_sev}" "${cat}" "sys.os.init" \
        "🔧 Init System" "${init_sys}" ""
}

check_system::hardware() {
    local cat="system"

    # ── CPU ───────────────────────────────────────────────────────────────────
    local cpu_model; cpu_model=$(grep 'model name' /proc/cpuinfo 2>/dev/null \
        | head -1 | cut -d: -f2- | sed 's/^ //' | sed 's/  */ /g')
    local cpu_cores; cpu_cores=$(_sys::cpu_count)
    local cpu_threads; cpu_threads=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo "${cpu_cores}")
    local cpu_mhz; cpu_mhz=$(grep 'cpu MHz' /proc/cpuinfo 2>/dev/null \
        | head -1 | awk '{printf "%.0f",$NF}')

    doc::result "${SEV_INFO}" "${cat}" "sys.hw.cpu" \
        "🖥 CPU Model" \
        "$(ash_truncate "${cpu_model:-unknown}" 50) (${cpu_cores}c/${cpu_threads}t @ ${cpu_mhz:-?}MHz)" ""

    # ── CPU virtualization support ────────────────────────────────────────────
    local virt_flags; virt_flags=$(grep -oE '(vmx|svm)' /proc/cpuinfo 2>/dev/null | head -1)
    local virt_sev; [[ -n "${virt_flags}" ]] && virt_sev="${SEV_PASS}" || virt_sev="${SEV_INFO}"
    doc::result "${virt_sev}" "${cat}" "sys.hw.virt" \
        "🔧 CPU Virtualization" \
        "$( [[ -n "${virt_flags}" ]] \
            && printf '%s (hardware virt available)' "${virt_flags}" \
            || printf 'No hardware virtualization')" ""

    # ── Memory ────────────────────────────────────────────────────────────────
    local mem_total; mem_total=$(_sys::total_mem_mb)
    local mem_avail; mem_avail=$(_sys::avail_mem_mb)
    local mem_used=$(( mem_total - mem_avail ))
    local mem_pct=$(( mem_used * 100 / (mem_total + 1) ))
    local mem_sev="${SEV_PASS}"
    (( mem_total < 4096 ))  && mem_sev="${SEV_WARN}"
    (( mem_total < 2048 ))  && mem_sev="${SEV_FAIL}"
    (( mem_pct   > 90 ))    && mem_sev="${SEV_CRIT}"
    (( mem_pct   > 80 ))    && [[ "${mem_sev}" == "${SEV_PASS}" ]] && mem_sev="${SEV_WARN}"
    doc::result "${mem_sev}" "${cat}" "sys.hw.mem" \
        "💾 Memory" \
        "${mem_used}MiB used / ${mem_total}MiB total (${mem_pct}% used)" \
        "$( [[ "${mem_sev}" == "${SEV_FAIL}" ]] \
            && printf '4GiB+ recommended for smooth Hyprland session' || printf '')"

    # ── Swap ──────────────────────────────────────────────────────────────────
    local swap_total; swap_total=$(awk '/SwapTotal/{printf "%.0f",$2/1024}' /proc/meminfo 2>/dev/null || echo 0)
    local swap_free;  swap_free=$(awk '/SwapFree/{printf "%.0f",$2/1024}' /proc/meminfo 2>/dev/null || echo 0)
    local swap_sev="${SEV_INFO}"
    [[ "${swap_total}" == "0" ]] && swap_sev="${SEV_WARN}"
    doc::result "${swap_sev}" "${cat}" "sys.hw.swap" \
        "💾 Swap" \
        "${swap_free}MiB free / ${swap_total}MiB total" \
        "$( [[ "${swap_total}" == "0" ]] && printf 'Consider adding ZRAM or swap for stability' || printf '')"

    # ── ZRAM ──────────────────────────────────────────────────────────────────
    if [[ -d /sys/class/zram-control ]]; then
        local zram_devs; zram_devs=$(ls /sys/class/zram-control/ 2>/dev/null | wc -l)
        local zram_size=0
        for dev in /sys/block/zram*/disksize; do
            [[ -f "${dev}" ]] && \
                zram_size=$(( zram_size + $(cat "${dev}" 2>/dev/null || echo 0) ))
        done
        zram_size=$(( zram_size / 1048576 ))
        doc::result "${SEV_PASS}" "${cat}" "sys.hw.zram" \
            "💾 ZRAM" "${zram_devs} device(s) — ${zram_size}MiB total" ""
    else
        doc::result "${SEV_INFO}" "${cat}" "sys.hw.zram" \
            "💾 ZRAM" "Not configured (recommended for low-RAM systems)" \
            "paru -S zram-generator"
    fi

    # ── DMI/SMBIOS system info ────────────────────────────────────────────────
    local dmi_product=""
    local dmi_vendor=""
    local dmi_type=""
    for dmi_path in \
        /sys/class/dmi/id/product_name \
        /sys/class/dmi/id/sys_vendor \
        /sys/class/dmi/id/chassis_type; do
        [[ -r "${dmi_path}" ]] || continue
        case "$(basename "${dmi_path}")" in
            product_name) dmi_product=$(cat "${dmi_path}" 2>/dev/null | tr -d '\n') ;;
            sys_vendor)   dmi_vendor=$(cat "${dmi_path}" 2>/dev/null | tr -d '\n') ;;
            chassis_type) dmi_type=$(cat "${dmi_path}" 2>/dev/null | tr -d '\n') ;;
        esac
    done
    local hw_type="Desktop"
    case "${dmi_type:-0}" in
        8|9|10|14) hw_type="Laptop" ;;
        3)         hw_type="Desktop" ;;
        1)         hw_type="Other/VM" ;;
    esac
    doc::result "${SEV_INFO}" "${cat}" "sys.hw.product" \
        "🖥 Hardware" "${dmi_vendor} ${dmi_product} (${hw_type})" ""
}

check_system::storage() {
    local cat="system"

    # ── Critical mountpoints ───────────────────────────────────────────────────
    local -a mounts=("/:1024:Root" "${HOME}:2048:Home" "/tmp:512:Tmp")
    for entry in "${mounts[@]}"; do
        IFS=':' read -r mount min_mb label <<< "${entry}"
        [[ ! -d "${mount}" ]] && continue
        local avail; avail=$(_sys::disk_avail_mb "${mount}")
        local pct;   pct=$(_sys::disk_pct "${mount}")
        local fs;    fs=$(df -T "${mount}" 2>/dev/null | awk 'NR==2{print $2}')
        local total; total=$(df -m "${mount}" 2>/dev/null | awk 'NR==2{print $2}')
        local disk_sev="${SEV_PASS}"
        (( avail < min_mb ))        && disk_sev="${SEV_WARN}"
        (( avail < min_mb / 2 ))    && disk_sev="${SEV_FAIL}"
        (( pct > 95 ))              && disk_sev="${SEV_CRIT}"
        local mid; mid="sys.disk.$(printf '%s' "${mount}" | tr '/' '_')"
        doc::result "${disk_sev}" "${cat}" "${mid}" \
            "💾 Disk: ${label} (${fs})" \
            "${avail}MiB free / ${total}MiB (${pct}% used)" \
            "$( [[ "${disk_sev}" != "${SEV_PASS}" ]] \
                && printf 'Free up space on %s' "${mount}" || printf '')"
    done

    # ── Inode usage ────────────────────────────────────────────────────────────
    local inode_pct; inode_pct=$(df -i / 2>/dev/null | awk 'NR==2{gsub(/%/,"",$5); print $5}' || echo 0)
    local inode_sev="${SEV_PASS}"
    (( inode_pct > 85 )) && inode_sev="${SEV_WARN}"
    (( inode_pct > 95 )) && inode_sev="${SEV_FAIL}"
    doc::result "${inode_sev}" "${cat}" "sys.disk.inodes" \
        "💾 Inode Usage (root)" "${inode_pct}% used" ""

    # ── IO scheduler ──────────────────────────────────────────────────────────
    for sched_file in /sys/block/*/queue/scheduler; do
        local dev; dev=$(printf '%s' "${sched_file}" | awk -F/ '{print $4}')
        [[ "${dev}" =~ ^(loop|ram|zram|dm) ]] && continue
        local sched; sched=$(cat "${sched_file}" 2>/dev/null | grep -oE '\[[^]]+\]' | tr -d '[]' || echo "?")
        local sched_sev="${SEV_INFO}"
        [[ "${sched}" =~ ^(mq-deadline|bfq|none|kyber)$ ]] && sched_sev="${SEV_PASS}"
        doc::result "${sched_sev}" "${cat}" "sys.disk.sched_${dev}" \
            "💾 IO Scheduler (${dev})" "${sched}" ""
        break  # show only first physical disk
    done
}

check_system::performance() {
    local cat="system"

    # ── Load average ──────────────────────────────────────────────────────────
    local cpu_count; cpu_count=$(_sys::cpu_count)
    local load_1m;   load_1m=$(_sys::load_1m)
    local load_5m;   load_5m=$(_sys::load_5m)
    local load_15m;  load_15m=$(_sys::load_15m)
    local load_int;  load_int=$(printf '%.0f' "${load_1m}")
    local load_sev="${SEV_PASS}"
    (( load_int > cpu_count ))     && load_sev="${SEV_WARN}"
    (( load_int > cpu_count * 2 )) && load_sev="${SEV_FAIL}"
    doc::result "${load_sev}" "${cat}" "sys.perf.load" \
        "⚡ Load Average" \
        "${load_1m} / ${load_5m} / ${load_15m} (${cpu_count} CPUs)" ""

    # ── Uptime ────────────────────────────────────────────────────────────────
    local uptime_s; uptime_s=$(_sys::uptime_secs)
    local uptime_h=$(( uptime_s / 3600 ))
    local uptime_m=$(( (uptime_s % 3600) / 60 ))
    doc::result "${SEV_INFO}" "${cat}" "sys.perf.uptime" \
        "⏱ System Uptime" "${uptime_h}h ${uptime_m}m" ""

    # ── Process count ─────────────────────────────────────────────────────────
    local proc_count; proc_count=$(ls /proc | grep -cE '^[0-9]+$' 2>/dev/null || echo 0)
    local proc_sev="${SEV_PASS}"
    (( proc_count > 500 )) && proc_sev="${SEV_INFO}"
    (( proc_count > 800 )) && proc_sev="${SEV_WARN}"
    doc::result "${proc_sev}" "${cat}" "sys.perf.procs" \
        "⚡ Running Processes" "${proc_count}" ""

    # ── File descriptor limits ────────────────────────────────────────────────
    local fd_hard; fd_hard=$(ulimit -Hn 2>/dev/null || echo 0)
    local fd_soft; fd_soft=$(ulimit -Sn 2>/dev/null || echo 0)
    local fd_sev="${SEV_PASS}"
    (( fd_soft < 8192 ))  && fd_sev="${SEV_WARN}"
    (( fd_soft < 1024 ))  && fd_sev="${SEV_FAIL}"
    doc::result "${fd_sev}" "${cat}" "sys.perf.fd_limit" \
        "⚡ File Descriptor Limit" \
        "soft=${fd_soft} hard=${fd_hard}" \
        "$( [[ "${fd_sev}" != "${SEV_PASS}" ]] \
            && printf 'Add "* soft nofile 65536" to /etc/security/limits.conf' || printf '')"

    # ── CPU frequency scaling ─────────────────────────────────────────────────
    local gov_path="/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
    if [[ -f "${gov_path}" ]]; then
        local governor; governor=$(cat "${gov_path}" 2>/dev/null)
        local gov_sev="${SEV_PASS}"
        [[ "${governor}" == "powersave" ]] && gov_sev="${SEV_WARN}"
        doc::result "${gov_sev}" "${cat}" "sys.perf.governor" \
            "⚡ CPU Governor" "${governor}" \
            "$( [[ "${gov_sev}" == "${SEV_WARN}" ]] \
                && printf 'Use schedutil or performance for better responsiveness' || printf '')"
    fi

    # ── Transparent Huge Pages ────────────────────────────────────────────────
    local thp_path="/sys/kernel/mm/transparent_hugepage/enabled"
    if [[ -f "${thp_path}" ]]; then
        local thp; thp=$(grep -oE '\[[^]]+\]' "${thp_path}" 2>/dev/null | tr -d '[]' || echo "?")
        local thp_sev="${SEV_INFO}"
        [[ "${thp}" == "madvise" ]] && thp_sev="${SEV_PASS}"
        doc::result "${thp_sev}" "${cat}" "sys.perf.thp" \
            "⚡ Transparent Huge Pages" "${thp}" ""
    fi

    # ── Dirty page writeback ──────────────────────────────────────────────────
    local dirty_ratio; dirty_ratio=$(cat /proc/sys/vm/dirty_ratio 2>/dev/null || echo "?")
    doc::result "${SEV_INFO}" "${cat}" "sys.perf.dirty_ratio" \
        "⚡ VM Dirty Ratio" "${dirty_ratio}%" ""
}

check_system::user_env() {
    local cat="system"

    # ── Current user ──────────────────────────────────────────────────────────
    local uid; uid=$(id -u)
    local username; username=$(id -un)
    local groups_out; groups_out=$(id -Gn | tr ' ' ',')

    doc::result "${SEV_INFO}" "${cat}" "sys.usr.name" \
        "👤 Current User" "${username} (uid=${uid})" ""

    # Must not run as root
    local root_sev="${SEV_PASS}"
    [[ "${uid}" == "0" ]] && root_sev="${SEV_CRIT}"
    doc::result "${root_sev}" "${cat}" "sys.usr.root" \
        "🔒 Running as Root" \
        "$( [[ "${uid}" == "0" ]] \
            && printf 'CRITICAL: Never run ASH as root' \
            || printf 'Not root ✓')" ""

    # ── Group membership ──────────────────────────────────────────────────────
    local -a required_groups=("video" "input" "audio" "seat" "render")
    for grp in "${required_groups[@]}"; do
        local grp_sev
        if id -nG "${username}" 2>/dev/null | grep -qw "${grp}"; then
            grp_sev="${SEV_PASS}"
        else
            grp_sev="${SEV_WARN}"
        fi
        doc::result "${grp_sev}" "${cat}" "sys.usr.group_${grp}" \
            "👤 Group: ${grp}" \
            "$( [[ "${grp_sev}" == "${SEV_PASS}" ]] \
                && printf 'Member ✓' || printf 'Not member — some features may fail')" \
            "usermod -aG ${grp} ${username}"
    done

    # ── Home directory ────────────────────────────────────────────────────────
    local home_perm; home_perm=$(stat -c '%a' "${HOME}" 2>/dev/null || echo "?")
    local home_sev="${SEV_PASS}"
    [[ "${home_perm}" == "777" ]] && home_sev="${SEV_WARN}"
    doc::result "${home_sev}" "${cat}" "sys.usr.home_perm" \
        "🔒 Home Dir Permissions" "${home_perm}" \
        "$( [[ "${home_sev}" != "${SEV_PASS}" ]] \
            && printf 'chmod 750 %s' "${HOME}" || printf '')"

    # ── Locale ────────────────────────────────────────────────────────────────
    local locale_lang="${LANG:-}"
    local locale_sev="${SEV_PASS}"
    [[ -z "${locale_lang}" ]] && locale_sev="${SEV_WARN}"
    [[ "${locale_lang}" != *".UTF-8"* ]] && locale_sev="${SEV_WARN}"
    doc::result "${locale_sev}" "${cat}" "sys.usr.locale" \
        "🌐 Locale (LANG)" "${locale_lang:-<not set>}" \
        "$( [[ "${locale_sev}" != "${SEV_PASS}" ]] \
            && printf 'Set LANG=en_US.UTF-8 for best Unicode support' || printf '')"

    # ── Timezone ──────────────────────────────────────────────────────────────
    local timezone
    timezone=$(timedatectl 2>/dev/null | awk '/Time zone/{print $3}' \
               || cat /etc/timezone 2>/dev/null \
               || readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||' \
               || printf "unknown")
    doc::result "${SEV_INFO}" "${cat}" "sys.usr.timezone" \
        "🕐 Timezone" "${timezone}" ""

    # ── NTP sync ──────────────────────────────────────────────────────────────
    if command -v timedatectl &>/dev/null; then
        local ntp_sync; ntp_sync=$(timedatectl 2>/dev/null \
            | grep -i 'NTP\|synchronized' | head -1 | awk '{print $NF}')
        local ntp_sev="${SEV_PASS}"
        [[ "${ntp_sync}" == "no" ]] && ntp_sev="${SEV_WARN}"
        doc::result "${ntp_sev}" "${cat}" "sys.usr.ntp" \
            "🕐 NTP Synchronized" "${ntp_sync:-unknown}" \
            "timedatectl set-ntp true"
    fi

    # ── Shell ─────────────────────────────────────────────────────────────────
    local user_shell; user_shell=$(getent passwd "${username}" 2>/dev/null | cut -d: -f7 \
        || echo "${SHELL:-unknown}")
    local shell_sev="${SEV_INFO}"
    [[ "${user_shell}" == *"fish"* ]] && shell_sev="${SEV_PASS}"
    doc::result "${shell_sev}" "${cat}" "sys.usr.shell" \
        "🐚 Login Shell" "${user_shell}" ""
}

check_system::env_vars() {
    local cat="system"

    # ── Critical XDG vars ─────────────────────────────────────────────────────
    local -A xdg_vars=(
        ["XDG_CONFIG_HOME"]="${HOME}/.config"
        ["XDG_DATA_HOME"]="${HOME}/.local/share"
        ["XDG_STATE_HOME"]="${HOME}/.local/state"
        ["XDG_CACHE_HOME"]="${HOME}/.cache"
        ["XDG_RUNTIME_DIR"]="/run/user/$(id -u)"
    )
    for var in "${!xdg_vars[@]}"; do
        local expected="${xdg_vars[${var}]}"
        local actual="${!var:-}"
        local xdg_sev="${SEV_PASS}"
        [[ -z "${actual}" ]] && { xdg_sev="${SEV_WARN}"; actual="<not set> (will use ${expected})"; }
        local vid; vid="sys.env.$(printf '%s' "${var}" | tr '[:upper:]' '[:lower:]')"
        doc::result "${xdg_sev}" "${cat}" "${vid}" \
            "🌐 \$${var}" "${actual}" ""
    done

    # ── PATH completeness ──────────────────────────────────────────────────────
    local -a required_paths=(
        "${HOME}/.local/bin"
        "/usr/local/bin"
        "/usr/bin"
        "/bin"
    )
    for rp in "${required_paths[@]}"; do
        local pid; pid="sys.env.path_$(printf '%s' "${rp}" | tr '/.' '__')"
        local rp_sev="${SEV_PASS}"
        printf '%s' "${PATH}" | tr ':' '\n' | grep -qF "${rp}" || rp_sev="${SEV_WARN}"
        doc::result "${rp_sev}" "${cat}" "${pid}" \
            "🛤 PATH includes ${rp}" \
            "$( [[ "${rp_sev}" == "${SEV_PASS}" ]] && printf 'Present ✓' || printf 'Missing')" \
            "export PATH=\"${rp}:\$PATH\""
    done

    # ── ASH-specific vars ─────────────────────────────────────────────────────
    doc::check_env "${cat}" "sys.env.ash_data"  "ASH_DATA_DIR"  "" "${SEV_INFO}"
    doc::check_env "${cat}" "sys.env.ash_state" "ASH_STATE_DIR" "" "${SEV_INFO}"
    doc::check_env "${cat}" "sys.env.ash_cache" "ASH_CACHE_DIR" "" "${SEV_INFO}"
    doc::check_env "${cat}" "sys.env.ash_cfg"   "ASH_CONFIG_DIR" "" "${SEV_INFO}"

    # ── Editor ────────────────────────────────────────────────────────────────
    local editor="${EDITOR:-${VISUAL:-}}"
    local ed_sev; [[ -n "${editor}" ]] && ed_sev="${SEV_PASS}" || ed_sev="${SEV_INFO}"
    doc::result "${ed_sev}" "${cat}" "sys.env.editor" \
        "✏ \$EDITOR" "${editor:-<not set>}" \
        "export EDITOR=nvim"
}

check_system::security() {
    local cat="system"

    # ── SELinux / AppArmor ────────────────────────────────────────────────────
    local mac_status="none"
    if command -v getenforce &>/dev/null; then
        local se; se=$(getenforce 2>/dev/null)
        mac_status="SELinux: ${se}"
    elif [[ -f /sys/kernel/security/apparmor/profiles ]]; then
        local aa; aa=$(cat /sys/kernel/security/apparmor/profiles 2>/dev/null | wc -l)
        mac_status="AppArmor: ${aa} profiles"
    fi
    doc::result "${SEV_INFO}" "${cat}" "sys.sec.mac" \
        "🔒 MAC Security" "${mac_status}" ""

    # ── Secure Boot ───────────────────────────────────────────────────────────
    if command -v mokutil &>/dev/null; then
        local sb_state; sb_state=$(mokutil --sb-state 2>/dev/null || echo "unknown")
        doc::result "${SEV_INFO}" "${cat}" "sys.sec.secboot" \
            "🔒 Secure Boot" "${sb_state}" ""
    fi

    # ── Kernel pointer leak ────────────────────────────────────────────────────
    local kptr; kptr=$(sysctl -n kernel.kptr_restrict 2>/dev/null || echo "?")
    local kptr_sev; [[ "${kptr}" -ge 1 ]] 2>/dev/null && \
        kptr_sev="${SEV_PASS}" || kptr_sev="${SEV_INFO}"
    doc::result "${kptr_sev}" "${cat}" "sys.sec.kptr" \
        "🔒 Kernel Pointer Restrict" "${kptr}" ""

    # ── Dmesg access ──────────────────────────────────────────────────────────
    local dmesg_r; dmesg_r=$(sysctl -n kernel.dmesg_restrict 2>/dev/null || echo "0")
    local dm_sev; [[ "${dmesg_r}" == "1" ]] && dm_sev="${SEV_PASS}" || dm_sev="${SEV_INFO}"
    doc::result "${dm_sev}" "${cat}" "sys.sec.dmesg" \
        "🔒 Dmesg Restricted" "${dmesg_r}" ""

    # ── Coredump ──────────────────────────────────────────────────────────────
    local core_pattern; core_pattern=$(cat /proc/sys/kernel/core_pattern 2>/dev/null || echo "?")
    doc::result "${SEV_INFO}" "${cat}" "sys.sec.core" \
        "🔒 Core Dump Pattern" "${core_pattern}" ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
check_system::run() {
    log::debug "Running check-system.sh"
    check_system::os
    check_system::hardware
    check_system::storage
    check_system::performance
    check_system::user_env
    check_system::env_vars
    check_system::security
}


# ── Entry points ──────────────────────────────────────────────────────────────
# Nineteen of the check modules expose ash_check_<area>() and a _quick variant.
# This one predates that convention and used a bare top-level call to check_system::run,
# which meant sourcing it ran the whole check. These wrappers give the loader a
# single, uniform interface to drive.
ash_check_system() {
    check_system::run
}

# The doc:: API records its own results and has no cheap subset, so the quick
# variant reports on the same areas. It exists so `ash doctor quick` can reach
# this module at all.
ash_check_system_quick() {
    check_system::run
}
