#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — EWW CPU SCRIPT                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

case "${1:-usage}" in
    usage)
        # CPU usage percentage (average across all cores)
        cpu_line=$(grep 'cpu ' /proc/stat)
        read -r _ user nice system idle iowait irq softirq steal _ <<< "$cpu_line"
        total1=$(( user + nice + system + idle + iowait + irq + softirq + steal ))
        idle1=$idle

        sleep 0.5

        cpu_line=$(grep 'cpu ' /proc/stat)
        read -r _ user nice system idle iowait irq softirq steal _ <<< "$cpu_line"
        total2=$(( user + nice + system + idle + iowait + irq + softirq + steal ))
        idle2=$idle

        diff_total=$(( total2 - total1 ))
        diff_idle=$(( idle2 - idle1 ))

        if (( diff_total > 0 )); then
            usage=$(( (diff_total - diff_idle) * 100 / diff_total ))
        else
            usage=0
        fi

        echo "${usage}"
        ;;

    temp)
        # CPU temperature
        temp=""
        for zone in /sys/class/thermal/thermal_zone*/temp; do
            if [[ -f "${zone}" ]]; then
                raw=$(cat "${zone}" 2>/dev/null || echo "0")
                if (( raw > 0 && raw < 150000 )); then
                    temp=$(( raw / 1000 ))
                    break
                fi
            fi
        done
        echo "${temp:-?}"
        ;;

    cores)
        nproc 2>/dev/null || echo "?"
        ;;

    freq)
        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null \
            | awk '{printf "%.2f", $1/1000000}' \
            || echo "?"
        ;;

    model)
        grep "model name" /proc/cpuinfo 2>/dev/null \
            | head -1 \
            | cut -d: -f2 \
            | xargs \
            | sed 's/  */ /g'
        ;;

    *)
        echo "Usage: cpu.sh [usage|temp|cores|freq|model]"
        exit 1
        ;;
esac