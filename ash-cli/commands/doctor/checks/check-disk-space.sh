#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██████╗ ██╗███████╗██╗  ██╗    ███████╗██████╗  █████╗  ██████╗███████╗        ║
# ║  ██╔══██╗██║██╔════╝██║ ██╔╝    ██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝        ║
# ║  ██║  ██║██║███████╗█████╔╝     ███████╗██████╔╝███████║██║     █████╗          ║
# ║  ██║  ██║██║╚════██║██╔═██╗     ╚════██║██╔═══╝ ██╔══██║██║     ██╔══╝          ║
# ║  ██████╔╝██║███████║██║  ██╗    ███████║██║     ██║  ██║╚██████╗███████╗        ║
# ║  ╚═════╝ ╚═╝╚══════╝╚═╝  ╚═╝    ╚══════╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝        ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  DOCTOR CHECK: DISK SPACE                                ║
# ║  Filesystems • Usage • ASH data sizes • Cleanup opportunities • inode audit     ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CHECK_DISK_SPACE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CHECK_DISK_SPACE_LOADED=1

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
# 🔷  HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Convert bytes to human-readable
_disk_human() {
    local bytes="${1:-0}"
    if   (( bytes >= 1099511627776 )); then printf '%.1fTB' "$(echo "$bytes/1099511627776" | bc -l 2>/dev/null || echo 0)"
    elif (( bytes >= 1073741824    )); then printf '%.1fGB' "$(echo "$bytes/1073741824"    | bc -l 2>/dev/null || echo 0)"
    elif (( bytes >= 1048576       )); then printf '%.1fMB' "$(echo "$bytes/1048576"       | bc -l 2>/dev/null || echo 0)"
    elif (( bytes >= 1024          )); then printf '%.1fKB' "$(echo "$bytes/1024"          | bc -l 2>/dev/null || echo 0)"
    else printf '%dB' "$bytes"
    fi
}

# Progress bar for disk usage
_disk_bar() {
    local pct="$1"
    local width="${2:-30}"
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))

    local color
    if   (( pct >= 90 )); then color=$'\033[1;38;2;243;139;168m'  # Red
    elif (( pct >= 75 )); then color=$'\033[1;38;2;249;226;175m'  # Yellow
    elif (( pct >= 50 )); then color=$'\033[38;2;250;179;135m'    # Peach
    else                       color=$'\033[38;2;166;227;161m'    # Green
    fi

    local reset=$'\033[0m'
    local dim=$'\033[38;2;88;91;112m'

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '%s' "$color"
        local i
        for (( i=0; i<filled; i++ )); do printf '█'; done
        printf '%s' "$dim"
        for (( i=0; i<empty;  i++ )); do printf '░'; done
        printf '%s' "$reset"
    else
        local bar=""
        local i
        for (( i=0; i<filled; i++ )); do bar+='#'; done
        for (( i=0; i<empty;  i++ )); do bar+='-'; done
        printf '%s' "$bar"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 01 — FILESYSTEM OVERVIEW
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_disk_filesystems() {
    _check_header "💾 Filesystem Usage"

    # ── df output parsing ─────────────────────────────────────────────────────────
    local df_out
    df_out="$(df -h --output=source,fstype,size,used,avail,pcent,target \
              2>/dev/null | tail -n +2)"

    # Filter to only real filesystems
    local -a fs_lines=()
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local fstype
        fstype="$(printf '%s' "$line" | awk '{print $2}')"
        # Skip virtual/pseudo filesystems
        case "$fstype" in
            tmpfs|devtmpfs|devpts|proc|sysfs|cgroup*|efivarfs|bpf|pstore|debugfs|securityfs|hugetlbfs|fusectl|mqueue)
                continue ;;
        esac
        fs_lines+=("$line")
    done <<< "$df_out"

    if [[ ${#fs_lines[@]} -eq 0 ]]; then
        _check_report $CHECK_WARN "Filesystems" "No real filesystems detected via df"
        return $CHECK_WARN
    fi

    # ── Render each filesystem ────────────────────────────────────────────────────
    for fs_line in "${fs_lines[@]}"; do
        local source fstype size used avail pcent_str mountpoint
        read -r source fstype size used avail pcent_str mountpoint <<< "$fs_line"

        local pcent="${pcent_str//%/}"
        [[ ! "$pcent" =~ ^[0-9]+$ ]] && pcent=0

        # Build display label
        local mount_label="${mountpoint}"
        case "$mountpoint" in
            /)      mount_label="/ (root)" ;;
            /home)  mount_label="/home" ;;
            /boot)  mount_label="/boot" ;;
            /boot/efi) mount_label="/boot/efi (EFI)" ;;
            /tmp)   mount_label="/tmp (tmpfs)" ;;
            /var)   mount_label="/var" ;;
            /opt)   mount_label="/opt" ;;
        esac

        # Status based on usage
        local status=$CHECK_PASS
        local status_note=""
        if   (( pcent >= 95 )); then
            status=$CHECK_FAIL
            status_note="  🚨 CRITICAL — free immediately!"
        elif (( pcent >= 85 )); then
            status=$CHECK_WARN
            status_note="  ⚠️  running low"
        elif (( pcent >= 70 )); then
            status=$CHECK_INFO
            status_note="  📊 moderate usage"
        fi

        # Build bar
        local bar
        bar="$(_disk_bar "$pcent" 25)"

        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
            printf '  \033[38;2;205;214;244m%-28s\033[0m  %s  %s/%s  \033[38;2;108;112;134m(%s%%)\033[0m%s\n' \
                "$mount_label" "$bar" "$used" "$size" "$pcent" "$status_note"
        else
            printf '  %-28s  [%3d%%]  %s/%s  %s\n' \
                "$mount_label" "$pcent" "$used" "$size" "${status_note}"
        fi

        _check_report $status \
            "FS: ${mount_label}" \
            "${used}/${size}  (${pcent}%)  avail: ${avail}"

    done

    # ── Boot partition special check ──────────────────────────────────────────────
    local boot_avail
    boot_avail="$(df -h /boot 2>/dev/null | awk 'NR==2{print $4}')"
    if [[ -n "$boot_avail" ]]; then
        local boot_pct
        boot_pct="$(df /boot 2>/dev/null | awk 'NR==2{print $5}' | tr -d '%')"
        if [[ "$boot_pct" =~ ^[0-9]+$ ]] && (( boot_pct >= 80 )); then
            _check_report $CHECK_WARN \
                "/boot space" \
                "${boot_pct}%  (${boot_avail} free) — clean old kernels" \
                "Clean: paru -Sc  or  sudo pacman -R linux-old"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 02 — ASH DATA SIZES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_disk_ash_data() {
    _check_header "⚡ ASH Data Directory Sizes"

    local ash_root="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}"
    local ash_data="${XDG_DATA_HOME:-$HOME/.local/share}/ash"
    local ash_cache="${XDG_CACHE_HOME:-$HOME/.cache}/ash"
    local ash_cfg="${XDG_CONFIG_HOME:-$HOME/.config}/ash"

    # Format: "path:label:warn_mb:crit_mb"
    local -a ash_dirs=(
        "${ash_root}:ASH dotfiles repo:500:2000"
        "${ash_root}/themes:Themes library:200:1000"
        "${ash_root}/wallpapers:Wallpapers:2000:10000"
        "${ash_root}/assets:Assets:200:1000"
        "${ash_data}:ASH runtime data:100:500"
        "${ash_data}/snapshots:Snapshots:200:2000"
        "${ash_cache}:ASH cache:500:3000"
        "${ash_cache}/themes:Theme cache:100:500"
        "${ash_cache}/wallpapers:Wallpaper cache:500:5000"
        "${ash_cache}/colors:Color cache:10:100"
        "${ash_cfg}:ASH config:5:50"
        "${XDG_STATE_HOME:-$HOME/.local/state}/ash:ASH state/logs:10:100"
    )

    for dir_entry in "${ash_dirs[@]}"; do
        IFS=':' read -r dir_path label warn_mb crit_mb <<< "$dir_entry"

        [[ -d "$dir_path" ]] || {
            _check_report $CHECK_INFO "$label" "directory not found  (skip)"
            continue
        }

        local size_bytes
        size_bytes="$(du -sb "$dir_path" 2>/dev/null | cut -f1 || echo 0)"
        local size_mb=$(( size_bytes / 1048576 ))
        local size_human
        size_human="$(_disk_human "$size_bytes")"

        if (( size_mb >= crit_mb )); then
            _check_report $CHECK_WARN \
                "$label" \
                "${size_human}  (≥${crit_mb}MB — consider cleaning)" \
                "Clean: ash doctor fix --clean"
        elif (( size_mb >= warn_mb )); then
            _check_report $CHECK_INFO \
                "$label" \
                "${size_human}  (≥${warn_mb}MB — monitoring)"
        else
            _check_report $CHECK_PASS \
                "$label" \
                "${size_human}"
        fi
    done

    # ── Top 10 largest files in ASH ───────────────────────────────────────────────
    local ash_total_bytes
    ash_total_bytes="$(du -sb "${ash_root}" 2>/dev/null | cut -f1 || echo 0)"
    _check_report $CHECK_INFO \
        "ASH total size" \
        "$(_disk_human "$ash_total_bytes")"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 03 — SYSTEM CACHE & TMP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_disk_caches() {
    _check_header "🗑️  System Caches & Cleanup Opportunities"

    # ── Pacman cache ──────────────────────────────────────────────────────────────
    local pacman_cache="/var/cache/pacman/pkg"
    if [[ -d "$pacman_cache" ]]; then
        local pc_size
        pc_size="$(du -sh "$pacman_cache" 2>/dev/null | cut -f1)"
        local pc_count
        pc_count="$(find "$pacman_cache" -name '*.pkg.tar.*' | wc -l)"
        local pc_bytes
        pc_bytes="$(du -sb "$pacman_cache" 2>/dev/null | cut -f1 || echo 0)"

        if (( pc_bytes > 5368709120 )); then  # 5GB
            _check_report $CHECK_WARN \
                "Pacman cache" \
                "${pc_size}  •  ${pc_count} packages  (>5GB)" \
                "Clean: sudo paccache -r  or  sudo paccache -rk1"
        else
            _check_report $CHECK_PASS \
                "Pacman cache" \
                "${pc_size}  •  ${pc_count} packages"
        fi
    fi

    # ── Paru/Yay build cache ──────────────────────────────────────────────────────
    local aur_cache="${XDG_CACHE_HOME:-$HOME/.cache}/paru/clone"
    if [[ -d "$aur_cache" ]]; then
        local aur_size
        aur_size="$(du -sh "$aur_cache" 2>/dev/null | cut -f1)"
        local aur_count
        aur_count="$(find "$aur_cache" -maxdepth 1 -mindepth 1 -type d | wc -l)"
        _check_report $CHECK_INFO \
            "Paru AUR clone cache" \
            "${aur_size}  •  ${aur_count} cloned packages" \
            "Clean: paru -Sc"
    fi

    # ── ~/.cache overview ─────────────────────────────────────────────────────────
    local home_cache="${XDG_CACHE_HOME:-$HOME/.cache}"
    if [[ -d "$home_cache" ]]; then
        local hc_size
        hc_size="$(du -sh "$home_cache" 2>/dev/null | cut -f1)"
        local hc_bytes
        hc_bytes="$(du -sb "$home_cache" 2>/dev/null | cut -f1 || echo 0)"

        if (( hc_bytes > 10737418240 )); then  # 10GB
            _check_report $CHECK_WARN \
                "~/.cache total" \
                "${hc_size}  (>10GB)" \
                "Top users: du -sh ~/.cache/* | sort -hr | head -10"
        else
            _check_report $CHECK_PASS \
                "~/.cache total" \
                "${hc_size}"
        fi

        # Top 5 largest cache dirs
        local top5
        top5="$(du -sh "${home_cache}"/* 2>/dev/null | \
                sort -rh | head -5 | \
                awk '{printf "%-8s %s\n", $1, $2}' || echo '')"

        if [[ -n "$top5" ]]; then
            printf '\n'
            if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
                printf '  \033[38;2;108;112;134mTop 5 largest cache dirs:\033[0m\n'
            else
                printf '  Top 5 largest cache dirs:\n'
            fi
            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
                    printf '  \033[38;2;116;199;236m→\033[0m  %s\n' "$line"
                else
                    printf '  →  %s\n' "$line"
                fi
            done <<< "$top5"
            printf '\n'
        fi
    fi

    # ── /tmp usage ────────────────────────────────────────────────────────────────
    local tmp_size
    tmp_size="$(du -sh /tmp 2>/dev/null | cut -f1 || echo '?')"
    local tmp_pct
    tmp_pct="$(df /tmp 2>/dev/null | awk 'NR==2{print $5}' | tr -d '%' || echo '0')"

    if [[ "$tmp_pct" =~ ^[0-9]+$ ]] && (( tmp_pct >= 80 )); then
        _check_report $CHECK_WARN \
            "/tmp usage" \
            "${tmp_size}  (${tmp_pct}% — high)" \
            "Clean: sudo rm -rf /tmp/*  (logout required)"
    else
        _check_report $CHECK_PASS \
            "/tmp usage" \
            "${tmp_size}  (${tmp_pct}%)"
    fi

    # ── Journal size ──────────────────────────────────────────────────────────────
    if command -v journalctl &>/dev/null; then
        local journal_size
        journal_size="$(journalctl --disk-usage 2>/dev/null | \
                        grep -oP '[\d.]+[MGK]' | head -1 || echo '?')"
        _check_report $CHECK_INFO \
            "systemd journal size" \
            "${journal_size}" \
            "Trim: sudo journalctl --vacuum-size=500M"
    fi

    # ── Flatpak cache ─────────────────────────────────────────────────────────────
    if command -v flatpak &>/dev/null; then
        local fp_size
        fp_size="$(du -sh "${XDG_DATA_HOME:-$HOME/.local/share}/flatpak" \
                  2>/dev/null | cut -f1 || echo '?')"
        _check_report $CHECK_INFO \
            "Flatpak data" \
            "${fp_size}" \
            "Clean unused: flatpak uninstall --unused"
    fi

    # ── Trash ─────────────────────────────────────────────────────────────────────
    local trash_dir="${XDG_DATA_HOME:-$HOME/.local/share}/Trash"
    if [[ -d "${trash_dir}/files" ]]; then
        local trash_size
        trash_size="$(du -sh "${trash_dir}/files" 2>/dev/null | cut -f1 || echo '0B')"
        local trash_count
        trash_count="$(find "${trash_dir}/files" -maxdepth 1 -mindepth 1 | wc -l)"
        if (( trash_count > 0 )); then
            _check_report $CHECK_INFO \
                "Trash" \
                "${trash_count} item(s)  •  ${trash_size}" \
                "Empty: rm -rf '${trash_dir}/files'/*  '${trash_dir}/info'/*"
        else
            _check_report $CHECK_PASS "Trash" "Empty"
        fi
    fi

    # ── Docker images ─────────────────────────────────────────────────────────────
    if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
        local docker_size
        docker_size="$(docker system df --format '{{.Size}}' 2>/dev/null | \
                       head -1 || echo '?')"
        local dangling_images
        dangling_images="$(docker images -f dangling=true -q 2>/dev/null | wc -l)"
        if (( dangling_images > 0 )); then
            _check_report $CHECK_INFO \
                "Docker dangling images" \
                "${dangling_images} dangling image(s)" \
                "Clean: docker system prune -f"
        else
            _check_report $CHECK_PASS "Docker images" "No dangling images"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 04 — INODE AUDIT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_disk_inodes() {
    _check_header "📊 Inode Usage"

    # df inode output
    local -a inode_lines=()
    mapfile -t inode_lines < <(
        df -i --output=source,iused,iavail,ipcent,target 2>/dev/null | \
        tail -n +2 | grep -v 'tmpfs\|devtmpfs\|udev'
    )

    for iline in "${inode_lines[@]}"; do
        [[ -z "$iline" ]] && continue
        local src iused iavail ipct mountpt
        read -r src iused iavail ipct mountpt <<< "$iline"

        local ipct_num="${ipct//%/}"
        [[ ! "$ipct_num" =~ ^[0-9]+$ ]] && continue

        if (( ipct_num >= 90 )); then
            _check_report $CHECK_FAIL \
                "Inodes: ${mountpt}" \
                "${ipct}  (${iused} used  •  ${iavail} free)  — CRITICAL" \
                "Find culprit: find ${mountpt} -xdev -printf '%h\n' | sort | uniq -c | sort -rn | head"
        elif (( ipct_num >= 75 )); then
            _check_report $CHECK_WARN \
                "Inodes: ${mountpt}" \
                "${ipct}  (${iused} used  •  ${iavail} free)"
        else
            _check_report $CHECK_PASS \
                "Inodes: ${mountpt}" \
                "${ipct}  (${iused} used  •  ${iavail} free)"
        fi
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 05 — LARGE FILES SCAN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_disk_large_files() {
    _check_header "🔍 Large File Scan  (HOME)"

    # Files > 500MB in HOME that are not in expected locations
    local -a exclude_paths=(
        "-path ${HOME}/.steam"
        "-path ${HOME}/.local/share/Steam"
        "-path ${HOME}/Games"
        "-path ${HOME}/.wine"
    )

    local exclude_args=""
    for ep in "${exclude_paths[@]}"; do
        exclude_args+=" ${ep} -prune -o"
    done

    local large_files
    large_files="$(eval find "$HOME" $exclude_args \
                   -size +500M -type f -printf '%s\t%p\n' 2>/dev/null | \
                   sort -rn | head -10 || echo '')"

    if [[ -z "$large_files" ]]; then
        _check_report $CHECK_PASS \
            "Large files (>500MB)" \
            "None found in HOME  (excluding Games/Steam)"
    else
        local large_count
        large_count="$(printf '%s\n' "$large_files" | wc -l)"
        _check_report $CHECK_INFO \
            "Large files (>500MB)" \
            "${large_count} file(s) found"

        while IFS=$'\t' read -r size_bytes file_path; do
            [[ -z "$file_path" ]] && continue
            local human_size
            human_size="$(_disk_human "$size_bytes")"
            _check_report $CHECK_INFO \
                "  ${human_size}" \
                "${file_path/#$HOME/~}"
        done <<< "$large_files"
    fi

    # ── Core dumps ────────────────────────────────────────────────────────────────
    local core_dumps
    core_dumps="$(find /tmp /var/lib/systemd/coredump "$HOME" \
                  -maxdepth 3 \( -name 'core' -o -name 'core.*' \) \
                  -type f 2>/dev/null | wc -l)"
    if (( core_dumps > 0 )); then
        _check_report $CHECK_WARN \
            "Core dumps" \
            "${core_dumps} core dump file(s)" \
            "Remove: coredumpctl clean  or  find . -name 'core.*' -delete"
    else
        _check_report $CHECK_PASS "Core dumps" "None found"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_check_disk_space() {
    local mode="${1:-full}"

    _CHECK_PASS_COUNT=0;  _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0;  _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=();   _CHECK_WARNINGS=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;137;220;235m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  💾  ASH DOCTOR — DISK SPACE CHECK                       ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  filesystems • ASH data • caches • inodes • large files  ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n=== ASH DOCTOR — DISK SPACE CHECK ===\n'
    fi

    case "$mode" in
        quick)
            _chk_disk_filesystems
            _chk_disk_ash_data
            ;;
        caches)     _chk_disk_caches      ;;
        inodes)     _chk_disk_inodes      ;;
        large)      _chk_disk_large_files ;;
        full|*)
            _chk_disk_filesystems
            _chk_disk_ash_data
            _chk_disk_caches
            _chk_disk_inodes
            _chk_disk_large_files
            ;;
    esac

    _ash_check_system_summary
}

ash_check_disk_space_quick() {
    local issues=0
    local home_pct
    home_pct="$(df "$HOME" 2>/dev/null | awk 'NR==2{print $5}' | tr -d '%')"
    local root_pct
    root_pct="$(df / 2>/dev/null | awk 'NR==2{print $5}' | tr -d '%')"

    [[ "$home_pct" =~ ^[0-9]+$ ]] && (( home_pct >= 90 )) && (( issues++ )) || true
    [[ "$root_pct" =~ ^[0-9]+$ ]] && (( root_pct >= 90 )) && (( issues++ )) || true

    if (( issues == 0 )); then
        ash_log_success "Disk space: OK  (root: ${root_pct}%  home: ${home_pct}%)"
    else
        ash_log_warn "Disk space: CRITICAL — ${issues} filesystem(s) >90%"
        return 1
    fi
}
