#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — DESKTOP HEALTH SCORE                          ║
# ║           Gamified system health with scoring and auto-fix                 ║
# ║           UNIQUE FEATURE: No other dotfiles system has this               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE: health-score.sh [show|fix|history|badge|export]

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly SCORE_DIR="${CACHE_DIR}/health-scores"
readonly LOG_FILE="${CACHE_DIR}/logs/health-score.log"
readonly SCORE_FILE="${SCORE_DIR}/latest.json"
readonly HISTORY_FILE="${SCORE_DIR}/history.json"

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# Colors
readonly R='\033[0m' B='\033[1m' G='\033[92m' Y='\033[93m'
readonly RED='\033[91m' C='\033[96m' M='\033[95m' DIM='\033[2m'

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 SCORING CATEGORIES
# ═══════════════════════════════════════════════════════════════════════════════

# Each check returns: score_value max_value "description" "fix_command"

check_performance() {
    local score=0 max=25 issues=()

    # CPU: check if CPU governor is set optimally
    local governor
    governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
    if [[ "${governor}" == "schedutil" ]] || [[ "${governor}" == "performance" ]]; then
        score=$(( score + 5 ))
    else
        issues+=("CPU governor suboptimal: ${governor}")
    fi

    # Memory: check swap usage
    local swap_pct
    swap_pct=$(awk '/SwapTotal/{t=$2}/SwapFree/{f=$2}END{if(t>0)printf "%.0f",(t-f)*100/t;else print "0"}' \
        /proc/meminfo 2>/dev/null || echo "0")
    if (( swap_pct < 20 )); then
        score=$(( score + 5 ))
    elif (( swap_pct < 50 )); then
        score=$(( score + 3 ))
        issues+=("Swap usage: ${swap_pct}%")
    else
        issues+=("High swap usage: ${swap_pct}% — close apps")
    fi

    # Disk: check root partition usage
    local disk_pct
    disk_pct=$(df / | awk 'NR==2{print $5}' | tr -d '%')
    if (( disk_pct < 50 )); then
        score=$(( score + 5 ))
    elif (( disk_pct < 75 )); then
        score=$(( score + 3 ))
        issues+=("Disk usage: ${disk_pct}%")
    elif (( disk_pct < 90 )); then
        score=$(( score + 1 ))
        issues+=("High disk usage: ${disk_pct}% — run ash clean deep")
    else
        issues+=("Critical disk usage: ${disk_pct}%!")
    fi

    # Uptime: system stability indicator
    local uptime_days
    uptime_days=$(awk '{printf "%.0f", $1/86400}' /proc/uptime 2>/dev/null || echo "0")
    if (( uptime_days >= 1 )); then
        score=$(( score + 5 ))
    fi

    # Process count: not too many zombies
    local zombie_count
    zombie_count=$(ps aux 2>/dev/null | awk '{print $8}' | grep -c "Z" || echo "0")
    if (( zombie_count == 0 )); then
        score=$(( score + 5 ))
    else
        issues+=("Zombie processes: ${zombie_count}")
    fi

    echo "${score}|${max}|${issues[*]:-none}"
}

check_security() {
    local score=0 max=20 issues=()

    # Firewall check
    if systemctl is-active ufw &>/dev/null || systemctl is-active firewalld &>/dev/null; then
        score=$(( score + 5 ))
    else
        issues+=("No firewall active — consider: paru -S ufw && sudo ufw enable")
    fi

    # Failed login attempts
    local failed_logins
    failed_logins=$(journalctl -u sshd 2>/dev/null | grep -c "Failed" || echo "0")
    if (( failed_logins == 0 )); then
        score=$(( score + 5 ))
    elif (( failed_logins < 10 )); then
        score=$(( score + 3 ))
    else
        issues+=("${failed_logins} failed SSH login attempts")
    fi

    # Check if screen locks automatically
    if pgrep -x hypridle &>/dev/null; then
        score=$(( score + 5 ))
    else
        issues+=("hypridle not running — screen won't auto-lock")
    fi

    # Check SSH key (no password auth preferred)
    if [[ -f "${HOME}/.ssh/id_ed25519" ]] || [[ -f "${HOME}/.ssh/id_rsa" ]]; then
        score=$(( score + 5 ))
    else
        issues+=("No SSH key found — consider: ssh-keygen -t ed25519")
    fi

    echo "${score}|${max}|${issues[*]:-none}"
}

check_cleanliness() {
    local score=0 max=20 issues=()

    # Cache size
    local cache_size_mb
    cache_size_mb=$(du -sm "${HOME}/.cache" 2>/dev/null | cut -f1 || echo "0")
    if (( cache_size_mb < 500 )); then
        score=$(( score + 5 ))
    elif (( cache_size_mb < 2000 )); then
        score=$(( score + 3 ))
        issues+=("Cache: ${cache_size_mb}MB — run ash clean")
    else
        issues+=("Large cache: ${cache_size_mb}MB — run ash clean deep")
    fi

    # Old log files
    local old_logs
    old_logs=$(find "${CACHE_DIR}/logs" -name "*.log" -size +10M 2>/dev/null | wc -l)
    if (( old_logs == 0 )); then
        score=$(( score + 5 ))
    else
        issues+=("${old_logs} large log file(s) — run ash clean")
    fi

    # Orphaned packages
    if command -v pacman &>/dev/null; then
        local orphans
        orphans=$(pacman -Qtdq 2>/dev/null | wc -l || echo "0")
        if (( orphans == 0 )); then
            score=$(( score + 5 ))
        elif (( orphans < 5 )); then
            score=$(( score + 3 ))
            issues+=("${orphans} orphaned packages")
        else
            issues+=("${orphans} orphaned packages — run: pacman -Rns \$(pacman -Qtdq)")
        fi
    else
        score=$(( score + 5 ))
    fi

    # Tmp size
    local tmp_size_mb
    tmp_size_mb=$(du -sm /tmp 2>/dev/null | cut -f1 || echo "0")
    if (( tmp_size_mb < 500 )); then
        score=$(( score + 5 ))
    else
        issues+=("Large /tmp: ${tmp_size_mb}MB")
    fi

    echo "${score}|${max}|${issues[*]:-none}"
}

check_updates() {
    local score=0 max=15 issues=()

    # System package updates
    local sys_updates=0
    if command -v checkupdates &>/dev/null; then
        sys_updates=$(checkupdates 2>/dev/null | wc -l || echo "0")
    fi

    if (( sys_updates == 0 )); then
        score=$(( score + 8 ))
    elif (( sys_updates < 20 )); then
        score=$(( score + 5 ))
        issues+=("${sys_updates} system updates available — run ash update")
    else
        score=$(( score + 2 ))
        issues+=("${sys_updates} updates pending! — run ash update")
    fi

    # Dotfiles update check
    if [[ -d "${HOME}/.dotfiles/.git" ]]; then
        local behind
        behind=$(cd "${HOME}/.dotfiles" && \
            git fetch origin 2>/dev/null && \
            git rev-list HEAD...origin/main --count 2>/dev/null || echo "0")
        if (( behind == 0 )); then
            score=$(( score + 7 ))
        else
            score=$(( score + 3 ))
            issues+=("Dotfiles: ${behind} commits behind — run ash update")
        fi
    fi

    echo "${score}|${max}|${issues[*]:-none}"
}

check_backups() {
    local score=0 max=10 issues=()

    local backup_dir="${HOME}/.local/share/ash-dots/backups"

    if [[ ! -d "${backup_dir}" ]]; then
        issues+=("No backup directory — run ash backup")
        echo "${score}|${max}|${issues[*]}"
        return
    fi

    # Count backups
    local backup_count
    backup_count=$(find "${backup_dir}" -name "*.tar.gz" 2>/dev/null | wc -l)

    if (( backup_count == 0 )); then
        issues+=("No backups found — run ash backup")
    else
        score=$(( score + 5 ))

        # Check backup age
        local latest_backup_age
        latest_backup_age=$(find "${backup_dir}" -name "*.tar.gz" \
            -printf "%T@\n" 2>/dev/null | sort -rn | head -1 || echo "0")
        local now
        now=$(date +%s)
        local age_days=$(( (now - ${latest_backup_age%.*}) / 86400 ))

        if (( age_days < 3 )); then
            score=$(( score + 5 ))
        elif (( age_days < 7 )); then
            score=$(( score + 3 ))
            issues+=("Last backup: ${age_days} days ago")
        else
            issues+=("Last backup: ${age_days} days ago — run ash backup")
        fi
    fi

    echo "${score}|${max}|${issues[*]:-none}"
}

check_desktop() {
    local score=0 max=10 issues=()

    # Hyprland running
    pgrep -x Hyprland &>/dev/null && score=$(( score + 2 )) \
        || issues+=("Hyprland not running")

    # Waybar running
    pgrep -x waybar &>/dev/null && score=$(( score + 2 )) \
        || issues+=("Waybar not running")

    # Dunst running
    pgrep -x dunst &>/dev/null && score=$(( score + 2 )) \
        || issues+=("Dunst not running — notifications broken")

    # PipeWire audio
    pgrep -x pipewire &>/dev/null && score=$(( score + 2 )) \
        || issues+=("PipeWire not running — no audio")

    # Theme applied
    [[ -f "${HOME}/.cache/ash-dots/colors/current.json" ]] && score=$(( score + 2 )) \
        || issues+=("No theme applied — run ash theme pick")

    echo "${score}|${max}|${issues[*]:-none}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 CALCULATE TOTAL SCORE
# ═══════════════════════════════════════════════════════════════════════════════

calculate_score() {
    local perf_result sec_result clean_result update_result backup_result desk_result

    info "Running health checks..."

    perf_result=$(check_performance)
    sec_result=$(check_security)
    clean_result=$(check_cleanliness)
    update_result=$(check_updates)
    backup_result=$(check_backups)
    desk_result=$(check_desktop)

    # Parse results
    local perf_score  perf_max  perf_issues
    local sec_score   sec_max   sec_issues
    local clean_score clean_max clean_issues
    local update_score update_max update_issues
    local backup_score backup_max backup_issues
    local desk_score  desk_max  desk_issues

    IFS='|' read -r perf_score  perf_max  perf_issues  <<< "${perf_result}"
    IFS='|' read -r sec_score   sec_max   sec_issues   <<< "${sec_result}"
    IFS='|' read -r clean_score clean_max clean_issues <<< "${clean_result}"
    IFS='|' read -r update_score update_max update_issues <<< "${update_result}"
    IFS='|' read -r backup_score backup_max backup_issues <<< "${backup_result}"
    IFS='|' read -r desk_score  desk_max  desk_issues  <<< "${desk_result}"

    local total=$(( perf_score + sec_score + clean_score + update_score + backup_score + desk_score ))
    local max_total=$(( perf_max + sec_max + clean_max + update_max + backup_max + desk_max ))
    local percentage=$(( total * 100 / max_total ))

    # Save score
    mkdir -p "${SCORE_DIR}"
    python3 - << EOF 2>/dev/null || true
import json
from datetime import datetime

data = {
    "timestamp": datetime.now().isoformat(),
    "total": $total,
    "max": $max_total,
    "percentage": $percentage,
    "categories": {
        "performance": {"score": $perf_score, "max": $perf_max, "issues": "${perf_issues}"},
        "security":    {"score": $sec_score,  "max": $sec_max,  "issues": "${sec_issues}"},
        "cleanliness": {"score": $clean_score,"max": $clean_max,"issues": "${clean_issues}"},
        "updates":     {"score": $update_score,"max": $update_max,"issues": "${update_issues}"},
        "backups":     {"score": $backup_score,"max": $backup_max,"issues": "${backup_issues}"},
        "desktop":     {"score": $desk_score, "max": $desk_max, "issues": "${desk_issues}"}
    }
}

with open("${SCORE_FILE}", "w") as f:
    json.dump(data, f, indent=2)

# Append to history
try:
    with open("${HISTORY_FILE}", "r") as f:
        history = json.load(f)
except:
    history = []

history.append({"timestamp": data["timestamp"], "percentage": data["percentage"]})
history = history[-30:]  # Keep last 30

with open("${HISTORY_FILE}", "w") as f:
    json.dump(history, f, indent=2)
EOF

    # Return all data
    echo "${total}|${max_total}|${percentage}"
    echo "${perf_score}|${perf_max}|${perf_issues}"
    echo "${sec_score}|${sec_max}|${sec_issues}"
    echo "${clean_score}|${clean_max}|${clean_issues}"
    echo "${update_score}|${update_max}|${update_issues}"
    echo "${backup_score}|${backup_max}|${backup_issues}"
    echo "${desk_score}|${desk_max}|${desk_issues}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 DISPLAY SCORE
# ═══════════════════════════════════════════════════════════════════════════════

make_bar() {
    local score="$1" max="$2" width="${3:-20}"
    local filled=$(( score * width / max ))
    local empty=$(( width - filled ))
    local bar=""
    for (( i=0; i<filled; i++ )); do bar+="█"; done
    for (( i=0; i<empty; i++ ));  do bar+="░"; done
    echo "${bar}"
}

score_color() {
    local pct="$1"
    if (( pct >= 90 )); then echo "${G}"
    elif (( pct >= 70 )); then echo "${C}"
    elif (( pct >= 50 )); then echo "${Y}"
    else echo "${RED}"
    fi
}

score_emoji() {
    local pct="$1"
    if (( pct >= 95 )); then echo "🏆"
    elif (( pct >= 85 )); then echo "⭐"
    elif (( pct >= 70 )); then echo "✅"
    elif (( pct >= 50 )); then echo "⚠️"
    else echo "🚨"
    fi
}

display_score() {
    local results
    mapfile -t results < <(calculate_score)

    local total_line="${results[0]}"
    local perf_line="${results[1]}"
    local sec_line="${results[2]}"
    local clean_line="${results[3]}"
    local update_line="${results[4]}"
    local backup_line="${results[5]}"
    local desk_line="${results[6]}"

    local total max pct
    IFS='|' read -r total max pct <<< "${total_line}"

    local color
    color=$(score_color "${pct}")
    local emoji
    emoji=$(score_emoji "${pct}")

    local bar
    bar=$(make_bar "${total}" "${max}" 30)

    clear
    echo ""
    echo -e "  ${B}${M}╔══════════════════════════════════════════════════╗${R}"
    echo -e "  ${B}${M}║${R}       ${B}🏥 ASH DESKTOP HEALTH SCORE${R}               ${B}${M}║${R}"
    echo -e "  ${B}${M}╠══════════════════════════════════════════════════╣${R}"
    echo -e "  ${B}${M}║${R}                                                  ${B}${M}║${R}"
    printf "  ${B}${M}║${R}   Overall: ${color}${B}%s${R} ${color}%3d/100${R}  %s                 ${B}${M}║${R}\n" \
        "${bar}" "${pct}" "${emoji}"
    echo -e "  ${B}${M}║${R}                                                  ${B}${M}║${R}"
    echo -e "  ${B}${M}╠══════════════════════════════════════════════════╣${R}"

    # Category breakdown
    local categories=(
        "${perf_line}|⚡ Performance"
        "${sec_line}|🔒 Security"
        "${clean_line}|🧹 Cleanliness"
        "${update_line}|📦 Updates"
        "${backup_line}|💾 Backups"
        "${desk_line}|🖥️  Desktop"
    )

    local all_issues=()

    for cat_data in "${categories[@]}"; do
        local cat_score cat_max cat_issues cat_name
        local data="${cat_data%%|*}"
        cat_name="${cat_data##*|}"

        IFS='|' read -r cat_score cat_max cat_issues <<< "${data}"

        local cat_pct=$(( cat_score * 100 / cat_max ))
        local cat_color
        cat_color=$(score_color "${cat_pct}")
        local cat_bar
        cat_bar=$(make_bar "${cat_score}" "${cat_max}" 12)

        printf "  ${B}${M}║${R}  %s  ${cat_color}%s${R} %3d%%                        ${B}${M}║${R}\n" \
            "${cat_name}" "${cat_bar}" "${cat_pct}"

        # Collect issues
        if [[ "${cat_issues}" != "none" ]] && [[ -n "${cat_issues}" ]]; then
            all_issues+=("${cat_issues}")
        fi
    done

    echo -e "  ${B}${M}╠══════════════════════════════════════════════════╣${R}"

    # Grade
    local grade
    if (( pct >= 97 )); then grade="S+"
    elif (( pct >= 93 )); then grade="S"
    elif (( pct >= 85 )); then grade="A"
    elif (( pct >= 75 )); then grade="B"
    elif (( pct >= 65 )); then grade="C"
    elif (( pct >= 50 )); then grade="D"
    else grade="F"
    fi

    echo -e "  ${B}${M}║${R}   Grade: ${color}${B}${grade}${R}  —  ${total}/${max} points                   ${B}${M}║${R}"
    echo -e "  ${B}${M}╠══════════════════════════════════════════════════╣${R}"

    if (( ${#all_issues[@]} > 0 )); then
        echo -e "  ${B}${M}║${R}   ${Y}${B}Issues Found:${R}                                 ${B}${M}║${R}"
        for issue in "${all_issues[@]}"; do
            printf "  ${B}${M}║${R}   ${Y}•${R} %-46s ${B}${M}║${R}\n" "${issue:0:46}"
        done
        echo -e "  ${B}${M}║${R}                                                  ${B}${M}║${R}"
        echo -e "  ${B}${M}║${R}   Run: ${C}ash score fix${R} to auto-fix issues         ${B}${M}║${R}"
    else
        echo -e "  ${B}${M}║${R}   ${G}${B}🎉 No issues found — perfect health!${R}          ${B}${M}║${R}"
    fi

    echo -e "  ${B}${M}╚══════════════════════════════════════════════════╝${R}"
    echo ""

    log "INFO" "Health score: ${pct}/100 (${grade})"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 AUTO-FIX
# ═══════════════════════════════════════════════════════════════════════════════

auto_fix() {
    echo ""
    echo -e "  ${B}${M}🔧 AUTO-FIX MODE${R}"
    echo ""

    local fixed=0

    # Fix 1: Update system packages
    info "Checking for package updates..."
    local updates
    updates=$(checkupdates 2>/dev/null | wc -l || echo "0")
    if (( updates > 0 )); then
        info "Updating ${updates} packages..."
        if command -v paru &>/dev/null; then
            paru -Syu --noconfirm 2>/dev/null && ok "Packages updated" && ((fixed++)) || warn "Update failed"
        else
            sudo pacman -Syu --noconfirm 2>/dev/null && ok "Packages updated" && ((fixed++)) || warn "Update failed"
        fi
    else
        ok "Packages up to date"
    fi

    # Fix 2: Create backup
    info "Creating backup..."
    ash backup 2>/dev/null && ok "Backup created" && ((fixed++)) || warn "Backup failed"

    # Fix 3: Clean caches
    info "Cleaning caches..."
    ash clean 2>/dev/null && ok "Caches cleaned" && ((fixed++)) || warn "Clean failed"

    # Fix 4: Remove orphaned packages
    if command -v pacman &>/dev/null; then
        local orphans
        orphans=$(pacman -Qtdq 2>/dev/null | wc -l || echo "0")
        if (( orphans > 0 )); then
            info "Removing ${orphans} orphaned packages..."
            pacman -Qtdq 2>/dev/null | sudo pacman -Rns - 2>/dev/null \
                && ok "Orphans removed" && ((fixed++)) \
                || warn "Could not remove orphans"
        fi
    fi

    # Fix 5: Fix script permissions
    info "Fixing script permissions..."
    find "${HOME}/.config" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    find "${HOME}/.local/bin" -name "ash*" -exec chmod +x {} \; 2>/dev/null || true
    ok "Permissions fixed" && ((fixed++))

    # Fix 6: Restart unhealthy services
    for svc in dunst hypridle waybar; do
        if ! pgrep -x "${svc}" &>/dev/null; then
            info "Restarting ${svc}..."
            "${svc}" &>/dev/null & disown
            ok "${svc} restarted" && ((fixed++))
        fi
    done

    # Fix 7: Update dotfiles
    if [[ -d "${HOME}/.dotfiles/.git" ]]; then
        info "Checking dotfiles..."
        cd "${HOME}/.dotfiles"
        local behind
        behind=$(git fetch origin 2>/dev/null && \
            git rev-list HEAD...origin/main --count 2>/dev/null || echo "0")
        if (( behind > 0 )); then
            git pull origin main 2>/dev/null \
                && ok "Dotfiles updated (${behind} commits)" && ((fixed++)) \
                || warn "Dotfiles update failed"
        else
            ok "Dotfiles up to date"
        fi
    fi

    echo ""
    ok "${fixed} issues fixed!"
    echo ""
    info "Re-run 'ash score' to see new score"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📈 HISTORY
# ═══════════════════════════════════════════════════════════════════════════════

show_history() {
    if [[ ! -f "${HISTORY_FILE}" ]]; then
        echo "No history yet — run ash score first"
        return 0
    fi

    echo ""
    echo -e "  ${B}${M}📈 Health Score History (Last 30)${R}"
    echo ""

    python3 - << 'EOF'
import json, sys
from datetime import datetime

try:
    with open(sys.argv[1]) as f:
        history = json.load(f)
except:
    print("  No history data")
    sys.exit(0)

print("  Date                Score  Bar")
print("  " + "─" * 50)

for entry in history[-15:]:
    ts = entry.get("timestamp", "?")[:10]
    pct = entry.get("percentage", 0)
    bar_len = pct // 5
    bar = "█" * bar_len + "░" * (20 - bar_len)

    if pct >= 85:   color = "\033[92m"
    elif pct >= 65: color = "\033[93m"
    else:           color = "\033[91m"

    print(f"  {ts}    {color}{bar}{pct:3d}%\033[0m")
EOF
    "${HISTORY_FILE}"

    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-show}"
    mkdir -p "${SCORE_DIR}" "${CACHE_DIR}/logs"

    case "${action}" in
        show | score | "")  display_score ;;
        fix | autofix)      auto_fix ;;
        history | h)        show_history ;;
        export)
            [[ -f "${SCORE_FILE}" ]] && cat "${SCORE_FILE}" || echo "No score data"
            ;;
        quick)
            # Quick one-line score
            local results
            mapfile -t results < <(calculate_score 2>/dev/null)
            local pct
            IFS='|' read -r _ _ pct <<< "${results[0]}"
            local emoji
            emoji=$(score_emoji "${pct}")
            echo "${emoji} Health: ${pct}/100"
            ;;
        *)
            echo "Usage: health-score.sh [show|fix|history|export|quick]"
            exit 1
            ;;
    esac
}

main "$@"