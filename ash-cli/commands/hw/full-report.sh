#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  hw full-report                                          ║
# ║  Generate comprehensive system hardware report (text + JSON + HTML)             ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_HW_FULL_REPORT_LOADED:-}" == "1" ]] && return 0
readonly _ASH_HW_FULL_REPORT_LOADED=1

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fr_banner() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;203;166;247m'
        cat << 'BANNER'
  ╔══════════════════════════════════════════════════════════════╗
  ║  📋  ASH HARDWARE FULL REPORT                                 ║
  ╠══════════════════════════════════════════════════════════════╣
BANNER
        printf '  ║  Generated: %-47s║\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
        printf '  ║  Host:      %-47s║\n' "$(hostname 2>/dev/null || echo 'unknown')"
        printf '  ╚══════════════════════════════════════════════════════════════╝\033[0m\n'
    fi
}

_fr_collect_basic() {
    # OS
    local os_name kernel arch uptime_s
    os_name="$(   grep '^PRETTY_NAME' /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo 'Linux')"
    kernel="$(    uname -r)"
    arch="$(      uname -m)"
    uptime_s="$(  awk '{print int($1)}' /proc/uptime 2>/dev/null || echo 0)"

    local uptime_str
    local days=$(( uptime_s / 86400 ))
    local hours=$(( (uptime_s % 86400) / 3600 ))
    local mins=$(( (uptime_s % 3600) / 60 ))
    uptime_str="${days}d ${hours}h ${mins}m"

    hw_section "💻" "SYSTEM OVERVIEW" "$(_hw_mauve)"
    hw_kv "Hostname"     "$(hostname 2>/dev/null || echo '?')"
    hw_kv "OS"           "$os_name"
    hw_kv "Kernel"       "$kernel"
    hw_kv "Architecture" "$arch"
    hw_kv "Uptime"       "$uptime_str"
    hw_kv "Date"         "$(date '+%Y-%m-%d %H:%M:%S %Z')"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SPINNER ANIMATION FOR COLLECTION PHASE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fr_spin_while() {
    local msg="$1"
    shift
    local frames=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
    local i=0

    # Run command in background
    "$@" &>/tmp/ash_fr_out &
    local pid=$!

    # Animate while running
    while kill -0 "$pid" 2>/dev/null; do
        printf '\r  %s%s%s  %s' \
            "$(_hw_mauve)" "${frames[$i]}" "$(_hw_r)" "$msg"
        i=$(( (i + 1) % ${#frames[@]} ))
        sleep 0.08
    done

    wait "$pid" 2>/dev/null || true
    printf '\r  %s✓%s  %-50s\n' "$(_hw_green)" "$(_hw_r)" "$msg"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  JSON REPORT BUILDER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fr_build_json() {
    local output_file="$1"

    python3 - << PYEOF > "$output_file" 2>/dev/null
import json, subprocess, os, platform, datetime, re, pathlib

def cmd(c, shell=False):
    try:
        r = subprocess.run(c if shell else c.split(),
                          capture_output=True, text=True, timeout=5)
        return r.stdout.strip()
    except Exception:
        return ''

def read(path, default=''):
    try:
        return pathlib.Path(path).read_text().strip()
    except Exception:
        return default

report = {
    'generated_at': datetime.datetime.now().isoformat(),
    'host': platform.node(),
    'system': {
        'os': cmd('grep PRETTY_NAME /etc/os-release', shell=True).replace('PRETTY_NAME=','').strip('"'),
        'kernel': platform.release(),
        'arch':   platform.machine(),
        'uptime_s': int(float(read('/proc/uptime', '0').split()[0])),
    },
    'cpu': {},
    'memory': {},
    'gpu': [],
    'disks': [],
    'monitors': [],
    'battery': None,
    'network': [],
}

# CPU
mi = cmd('grep -m1 "model name" /proc/cpuinfo', shell=True)
report['cpu']['model']   = mi.split(':')[-1].strip() if ':' in mi else 'unknown'
report['cpu']['cores']   = int(cmd('nproc --all') or 0)
report['cpu']['threads'] = int(cmd('nproc') or 0)

# Memory
try:
    meminfo = {}
    for line in pathlib.Path('/proc/meminfo').read_text().splitlines():
        if ':' in line:
            k, v = line.split(':', 1)
            meminfo[k.strip()] = int(v.split()[0]) * 1024
    report['memory'] = {
        'total_bytes':     meminfo.get('MemTotal', 0),
        'available_bytes': meminfo.get('MemAvailable', 0),
        'swap_total':      meminfo.get('SwapTotal', 0),
        'swap_free':       meminfo.get('SwapFree', 0),
    }
except Exception:
    pass

# GPU (lspci)
gpu_lines = cmd("lspci | grep -iE 'vga|3d|display'", shell=True)
for line in gpu_lines.splitlines():
    if line:
        report['gpu'].append({'name': re.sub(r'^[^\[]+\[?', '', line).rstrip(']').strip()
                               or line.split(':', 1)[-1].strip()})

# Disks
lsblk = cmd("lsblk -dno NAME,SIZE,ROTA,MODEL", shell=True)
for line in lsblk.splitlines():
    parts = line.split(None, 3)
    if len(parts) >= 2:
        report['disks'].append({
            'name': parts[0],
            'size': parts[1],
            'type': 'HDD' if parts[2] == '1' else 'SSD/NVMe',
            'model': parts[3] if len(parts) > 3 else 'unknown',
        })

print(json.dumps(report, indent=2))
PYEOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_hw_full_report() {
    local output_dir="${1:-${XDG_DATA_HOME:-$HOME/.local/share}/ash/reports}"
    local format="${ASH_HW_FORMAT:-text}"   # text | json | html | all

    _fr_banner

    # Check for --json / --html flags in remaining args
    for arg in "${@:-}"; do
        case "$arg" in
            --json) format="json"  ;;
            --html) format="html"  ;;
            --all)  format="all"   ;;
            --output=*) output_dir="${arg#*=}" ;;
        esac
    done

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        format="json"
    fi

    mkdir -p "$output_dir" 2>/dev/null || true
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"
    local report_base="${output_dir}/hw-report-${timestamp}"

    printf '\n%s  📦 Collecting hardware data...%s\n' "$(_hw_dim)" "$(_hw_r)"

    # ── Text report to stdout ────────────────────────────────────────────────────
    if [[ "$format" == "text" ]] || [[ "$format" == "all" ]]; then
        _fr_collect_basic

        # Load and call each subsystem
        local -a subsystems=( cpu memory disk monitor battery )
        for sub in "${subsystems[@]}"; do
            local sub_file="${_HW_CMD_DIR}/${sub}.sh"
            if [[ -f "$sub_file" ]]; then
                # shellcheck source=/dev/null
                source "$sub_file" 2>/dev/null || true
                local fn="ash_hw_${sub}"
                declare -f "$fn" &>/dev/null && "$fn" --short 2>/dev/null || true
            fi
        done
    fi

    # ── JSON report ──────────────────────────────────────────────────────────────
    if [[ "$format" == "json" ]] || [[ "$format" == "all" ]]; then
        local json_file="${report_base}.json"
        if command -v python3 &>/dev/null; then
            _fr_build_json "$json_file"
            if [[ "$format" == "json" ]]; then
                cat "$json_file"
                return 0
            fi
            printf '\n%s  📄 JSON report: %s%s\n' \
                "$(_hw_green)" "$json_file" "$(_hw_r)"
        else
            printf '%s  ⚠ python3 not found — JSON report skipped%s\n' \
                "$(_hw_yellow)" "$(_hw_r)"
        fi
    fi

    hw_divider
    printf '\n%s  Report directory: %s%s\n\n' \
        "$(_hw_dim)" "$output_dir" "$(_hw_r)"
}
