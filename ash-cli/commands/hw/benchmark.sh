#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ██████╗ ███████╗███╗   ██╗ ██████╗██╗  ██╗███╗   ███╗ █████╗ ██████╗ ██╗  ██╗  ║
# ║  ██╔══██╗██╔════╝████╗  ██║██╔════╝██║  ██║████╗ ████║██╔══██╗██╔══██╗██║ ██╔╝  ║
# ║  ██████╔╝█████╗  ██╔██╗ ██║██║     ███████║██╔████╔██║███████║██████╔╝█████╔╝   ║
# ║  ██╔══██╗██╔══╝  ██║╚██╗██║██║     ██╔══██║██║╚██╔╝██║██╔══██║██╔══██╗██╔═██╗  ║
# ║  ██████╔╝███████╗██║ ╚████║╚██████╗██║  ██║██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██╗  ║
# ║  ╚═════╝ ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  hw benchmark                                             ║
# ║  CPU • memory bandwidth • disk I/O • GPU compute • network latency               ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_HW_BENCHMARK_LOADED:-}" == "1" ]] && return 0
readonly _ASH_HW_BENCHMARK_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BENCHMARK RESULT STORAGE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gA _BENCH_RESULTS=()
declare -g  _BENCH_START_TIME=0

_bench_start_timer() {
    _BENCH_START_TIME="$(date +%s%N)"
}

_bench_elapsed_ms() {
    local end_ns
    end_ns="$(date +%s%N)"
    printf '%d' "$(( (end_ns - _BENCH_START_TIME) / 1000000 ))"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  ANIMATED PROGRESS DISPLAY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bench_running() {
    local msg="$1"
    local frames=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
    local i=0

    "$2" &>/tmp/ash_bench_out &
    local pid=$!

    tput civis 2>/dev/null || true
    while kill -0 "$pid" 2>/dev/null; do
        printf '\r  \033[38;2;203;166;247m%s\033[0m  \033[38;2;148;226;213m%s\033[0m  ' \
            "${frames[$i]}" "$msg"
        i=$(( (i + 1) % ${#frames[@]} ))
        sleep 0.08
    done
    tput cnorm 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    printf '\r  \033[38;2;166;227;161m✓\033[0m  %-50s\n' "$msg"
}

_bench_result_bar() {
    local label="$1"
    local value="$2"
    local unit="$3"
    local max_ref="$4"   # reference maximum for bar scaling

    local pct=0
    if [[ "$max_ref" =~ ^[0-9]+$ ]] && (( max_ref > 0 )); then
        pct=$(( value * 100 / max_ref ))
        (( pct > 100 )) && pct=100
    fi

    local bar_w=30
    local filled=$(( pct * bar_w / 100 ))
    local empty=$(( bar_w - filled ))

    local bar_color
    if   (( pct >= 80 )); then bar_color="\033[38;2;166;227;161m"
    elif (( pct >= 50 )); then bar_color="\033[38;2;249;226;175m"
    else                       bar_color="\033[38;2;243;139;168m"
    fi

    printf '  \033[38;2;108;112;134m%-22s\033[0m  %s%s\033[38;2;88;91;112m%s\033[0m  \033[1m%s %s\033[0m\n' \
        "$label" \
        "$bar_color" \
        "$(printf '█%.0s' $(seq 1 $filled))" \
        "$(printf '░%.0s' $(seq 1 $empty))" \
        "$value" \
        "$unit"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CPU BENCHMARK — Compression speed + Prime sieve
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bench_cpu_run() {
    # Python prime sieve up to 10M as CPU stress test
    python3 -c "
import time
n = 10_000_000
sieve = bytearray([1]) * (n+1)
sieve[0] = sieve[1] = 0
i = 2
while i*i <= n:
    if sieve[i]:
        sieve[i*i::i] = bytearray(len(sieve[i*i::i]))
    i += 1
count = sum(sieve)
" 2>/dev/null
}

_bench_cpu() {
    local cores
    cores="$(nproc 2>/dev/null || echo 1)"

    _bench_start_timer
    _bench_cpu_run
    local elapsed_ms
    elapsed_ms="$(_bench_elapsed_ms)"

    _BENCH_RESULTS["cpu_ms"]="$elapsed_ms"
    _BENCH_RESULTS["cpu_cores"]="$cores"

    # Score: higher is better (reference: 2000ms = baseline)
    local score=$(( 2000 * 100 / (elapsed_ms > 0 ? elapsed_ms : 1) ))
    _BENCH_RESULTS["cpu_score"]="$score"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MEMORY BANDWIDTH — Sequential read/write via dd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bench_memory_run() {
    # Write 512MB to /dev/null (tests memory read bandwidth)
    dd if=/dev/zero of=/dev/null bs=1M count=512 &>/tmp/ash_bench_mem
}

_bench_memory() {
    _bench_start_timer
    _bench_memory_run 2>/tmp/ash_bench_mem
    local elapsed_ms
    elapsed_ms="$(_bench_elapsed_ms)"

    # Parse dd output for speed
    local speed_str
    speed_str="$(cat /tmp/ash_bench_mem 2>/dev/null | \
                grep -oP '[\d.]+ [MG]B/s' | tail -1 || echo '')"

    if [[ -z "$speed_str" ]]; then
        # Calculate manually: 512MB / time
        local mb_per_s=$(( 512 * 1000 / (elapsed_ms > 0 ? elapsed_ms : 1) ))
        speed_str="${mb_per_s} MB/s"
    fi

    _BENCH_RESULTS["mem_speed"]="$speed_str"
    _BENCH_RESULTS["mem_ms"]="$elapsed_ms"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  DISK I/O BENCHMARK — Sequential write + read
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bench_disk_run() {
    local tmpfile="/tmp/.ash_bench_disk_$$"
    # Write 256MB sequential
    dd if=/dev/zero of="$tmpfile" bs=1M count=256 conv=fdatasync \
       2>/tmp/ash_bench_disk_write
    # Read 256MB sequential
    dd if="$tmpfile" of=/dev/null bs=1M \
       2>/tmp/ash_bench_disk_read
    rm -f "$tmpfile" 2>/dev/null || true
}

_bench_disk() {
    _bench_disk_run 2>/dev/null

    local write_speed read_speed
    write_speed="$(grep -oP '[\d.]+ [MG]B/s' /tmp/ash_bench_disk_write 2>/dev/null | tail -1 || echo '?')"
    read_speed="$( grep -oP '[\d.]+ [MG]B/s' /tmp/ash_bench_disk_read  2>/dev/null | tail -1 || echo '?')"

    _BENCH_RESULTS["disk_write"]="$write_speed"
    _BENCH_RESULTS["disk_read"]="$read_speed"

    rm -f /tmp/ash_bench_disk_write /tmp/ash_bench_disk_read 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  NETWORK LATENCY — Ping 3 targets
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bench_network() {
    local -A targets=(
        ["Cloudflare"]="1.1.1.1"
        ["Google"]="8.8.8.8"
        ["Quad9"]="9.9.9.9"
    )

    for label in "${!targets[@]}"; do
        local host="${targets[$label]}"
        local avg_ms
        avg_ms="$(ping -c 3 -W 1 -q "$host" 2>/dev/null | \
                  awk -F'/' '/rtt/{printf "%.1f", $5}' || echo '?')"
        _BENCH_RESULTS["net_${label}"]="$avg_ms"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BASH PERFORMANCE — Command execution speed
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bench_shell() {
    _bench_start_timer
    local count=0
    for (( i=0; i<10000; i++ )); do
        (( count++ )) || true
    done
    local elapsed_ms
    elapsed_ms="$(_bench_elapsed_ms)"
    local ops_per_ms=$(( 10000 / (elapsed_ms > 0 ? elapsed_ms : 1) ))
    _BENCH_RESULTS["shell_ops_ms"]="$ops_per_ms"
    _BENCH_RESULTS["shell_ms"]="$elapsed_ms"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RESULTS DASHBOARD
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bench_dashboard() {
    printf '\n'
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '\033[1;38;2;250;179;135m'
        printf '  ╔══════════════════════════════════════════════════════════╗\n'
        printf '  ║  ⚡  ASH BENCHMARK RESULTS                                ║\n'
        printf '  ╠══════════════════════════════════════════════════════════╣\n'
        printf '  ║  %-57s║\n' "$(date '+%Y-%m-%d %H:%M:%S')  •  $(uname -r)"
        printf '  ╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    hw_section "🔲" "CPU Performance" "\033[38;2;137;180;250m"
    local cpu_ms="${_BENCH_RESULTS[cpu_ms]:-?}"
    local cpu_score="${_BENCH_RESULTS[cpu_score]:-0}"
    local cpu_cores="${_BENCH_RESULTS[cpu_cores]:-?}"

    hw_kv "Prime sieve (10M)" "${cpu_ms}ms  (${cpu_cores} cores)"
    _bench_result_bar "CPU Score" "$cpu_score" "pts" 200

    hw_section "🧠" "Memory Bandwidth" "\033[38;2;203;166;247m"
    local mem_speed="${_BENCH_RESULTS[mem_speed]:-?}"
    hw_kv "Sequential R/W" "$mem_speed"

    hw_section "💿" "Disk I/O" "\033[38;2;148;226;213m"
    hw_kv "Sequential Write" "${_BENCH_RESULTS[disk_write]:-?}"
    hw_kv "Sequential Read"  "${_BENCH_RESULTS[disk_read]:-?}"

    hw_section "🌐" "Network Latency" "\033[38;2;137;220;235m"
    for key in "${!_BENCH_RESULTS[@]}"; do
        [[ "$key" =~ ^net_ ]] || continue
        local net_label="${key#net_}"
        local net_ms="${_BENCH_RESULTS[$key]}"
        hw_kv "$net_label" "${net_ms}ms"
    done

    hw_section "🐚" "Shell Performance" "\033[38;2;249;226;175m"
    hw_kv "Bash ops" "${_BENCH_RESULTS[shell_ops_ms]:-?} ops/ms  (${_BENCH_RESULTS[shell_ms]:-?}ms for 10k loops)"

    # ── Overall Grade ──────────────────────────────────────────────────────────────
    local total_score="${cpu_score:-0}"
    local grade grade_color
    if   (( total_score >= 150 )); then grade="S+"; grade_color="\033[1;38;2;203;166;247m"
    elif (( total_score >= 120 )); then grade="A";  grade_color="\033[1;38;2;166;227;161m"
    elif (( total_score >= 90  )); then grade="B";  grade_color="\033[1;38;2;249;226;175m"
    elif (( total_score >= 60  )); then grade="C";  grade_color="\033[1;38;2;250;179;135m"
    else                               grade="D";  grade_color="\033[1;38;2;243;139;168m"
    fi

    printf '\n'
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '  %s╔══════════════════════╗\033[0m\n' "$grade_color"
        printf '  %s║  Overall Grade: %s%-3s%s  ║\033[0m\n' \
            "$grade_color" "\033[1m" "$grade" "" 
        printf '  %s╚══════════════════════╝\033[0m\n' "$grade_color"
    else
        printf '  Overall Grade: %s\n' "$grade"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_hw_benchmark() {
    local run_cpu=1 run_mem=1 run_disk=1 run_net=1 run_shell=1
    local quick=0

    for arg in "${@:-}"; do
        case "$arg" in
            --cpu)     run_mem=0; run_disk=0; run_net=0; run_shell=0 ;;
            --memory)  run_cpu=0; run_disk=0; run_net=0; run_shell=0 ;;
            --disk)    run_cpu=0; run_mem=0;  run_net=0; run_shell=0 ;;
            --network) run_cpu=0; run_mem=0;  run_disk=0; run_shell=0 ;;
            --quick)   quick=1 ;;
        esac
    done

    hw_section "⚡" "Hardware Benchmark" "\033[38;2;250;179;135m"

    printf '  \033[38;2;249;226;175m⚠  Benchmark will take 15-60 seconds\033[0m\n'
    printf '  \033[38;2;108;112;134mClose heavy applications for accurate results\033[0m\n\n'

    # Run benchmarks with spinner
    [[ $run_cpu   -eq 1 ]] && _bench_running "CPU: Prime sieve 10M"       _bench_cpu
    [[ $run_mem   -eq 1 ]] && _bench_running "Memory: Sequential 512MB"   _bench_memory
    [[ $run_disk  -eq 1 ]] && _bench_running "Disk: Sequential 256MB R/W" _bench_disk
    [[ $run_net   -eq 1 ]] && _bench_running "Network: Ping 3 targets"    _bench_network
    [[ $run_shell -eq 1 ]] && _bench_running "Shell: 10k loop iterations" _bench_shell

    _bench_dashboard

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        printf '{\n'
        for key in "${!_BENCH_RESULTS[@]}"; do
            printf '  "%s": "%s",\n' "$key" "${_BENCH_RESULTS[$key]}"
        done | sed '$ s/,$//'
        printf '}\n'
    fi

    hw_divider
}
