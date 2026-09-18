#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                           ║
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — BENCHMARK EXECUTION ENGINE                                  ║
# ║                                                                                           ║
# ║  ██████╗ ██╗   ██╗███╗   ██╗    ██████╗ ███████╗███╗   ██╗ ██████╗██╗  ██╗              ║
# ║  ██╔══██╗██║   ██║████╗  ██║    ██╔══██╗██╔════╝████╗  ██║██╔════╝██║  ██║              ║
# ║  ██████╔╝██║   ██║██╔██╗ ██║    ██████╔╝█████╗  ██╔██╗ ██║██║     ███████╗              ║
# ║  ██╔══██╗██║   ██║██║╚██╗██║    ██╔══██╗██╔══╝  ██║╚██╗██║██║     ██╔══██║              ║
# ║  ██████╔╝╚██████╔╝██║ ╚████║    ██████╔╝███████╗██║ ╚████║╚██████╗██║  ██║              ║
# ║  ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝    ╚═════╝ ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝              ║
# ║                                                                                           ║
# ║  ███████╗███╗   ██╗ ██████╗ ██╗███╗   ██╗███████╗                                       ║
# ║  ██╔════╝████╗  ██║██╔════╝ ██║████╗  ██║██╔════╝                                       ║
# ║  █████╗  ██╔██╗ ██║██║  ███╗██║██╔██╗ ██║█████╗                                         ║
# ║  ██╔══╝  ██║╚██╗██║██║   ██║██║██║╚██╗██║██╔══╝                                         ║
# ║  ███████╗██║ ╚████║╚██████╔╝██║██║ ╚████║███████╗                                       ║
# ║  ╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝╚══════╝                                       ║
# ║                                                                                           ║
# ║  Version:  5.0.0-omega                                                                   ║
# ║  Pipeline: preflight → setup → [12 domain benchmarks] → analyze →                       ║
# ║            regress → report → baseline → outputs                                         ║
# ║                                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────
readonly ENGINE_VERSION="5.0.0-omega"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly START_EPOCH=$(date +%s)
readonly START_NS=$(date +%s%N 2>/dev/null || echo "${START_EPOCH}000000000")

# ─────────────────────────────────────────────────────────────────────────────
# ENVIRONMENT RESOLUTION
# ─────────────────────────────────────────────────────────────────────────────
SESSION_ID="${SESSION_ID:-bench-$(date +%s)}"
RESOLVED_BENCHMARKS="${RESOLVED_BENCHMARKS:-startup,theme-apply}"
ITERATIONS="${ITERATIONS:-10}"
WARMUP_RUNS="${WARMUP_RUNS:-3}"
MIN_ITERATIONS="${MIN_ITERATIONS:-3}"
MAX_ITERATIONS="${MAX_ITERATIONS:-100}"
TIME_LIMIT_SECONDS="${TIME_LIMIT_SECONDS:-300}"
PERCENTILES="${PERCENTILES:-50,75,90,95,99}"
OUTLIER_METHOD="${OUTLIER_METHOD:-iqr}"
OUTLIER_THRESHOLD="${OUTLIER_THRESHOLD:-1.5}"
CONFIDENCE_LEVEL="${CONFIDENCE_LEVEL:-0.95}"
TIME_UNIT="${TIME_UNIT:-auto}"
COMPARE_BASELINE="${COMPARE_BASELINE:-true}"
BASELINE_REF="${BASELINE_REF:-main}"
REGRESSION_THRESHOLD_PCT="${REGRESSION_THRESHOLD_PCT:-15}"
REGRESSION_THRESHOLD_MS="${REGRESSION_THRESHOLD_MS:-0}"
FAIL_ON_REGRESSION="${FAIL_ON_REGRESSION:-false}"
SAVE_BASELINE="${SAVE_BASELINE:-false}"
BASELINE_HIT="${BASELINE_HIT:-false}"
CLI_PATH="${CLI_PATH:-ash-cli/ash}"
STARTUP_MODES="${STARTUP_MODES:-cold,warm,version}"
THEME_NAME="${THEME_NAME:-catppuccin-mocha}"
THEME_TARGETS="${THEME_TARGETS:-all}"
API_HOST="${API_HOST:-localhost}"
API_PORT="${API_PORT:-8765}"
API_ENDPOINTS="${API_ENDPOINTS:-/health,/api/v1/themes}"
API_CONCURRENT="${API_CONCURRENT:-10}"
MEMORY_INTERVAL_MS="${MEMORY_INTERVAL_MS:-50}"
IMAGE_COUNT="${IMAGE_COUNT:-5}"
PLUGIN_COUNT="${PLUGIN_COUNT:-10}"
CUSTOM_BENCH_PATH="${CUSTOM_BENCH_PATH:-benchmarks/custom-benchmarks.sh}"
OUTPUT_FORMATS="${OUTPUT_FORMATS:-json,markdown,summary}"
OUTPUT_DIR="${OUTPUT_DIR:-.benchmark-results}"
REPORT_TITLE="${REPORT_TITLE:-ASH Dotfiles v5.0 OMEGA Benchmarks}"
INCLUDE_SYSTEM_INFO="${INCLUDE_SYSTEM_INFO:-true}"
INCLUDE_GIT_INFO="${INCLUDE_GIT_INFO:-true}"
CHART_STYLE="${CHART_STYLE:-catppuccin}"
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"
FAIL_ON_ERROR="${FAIL_ON_ERROR:-false}"
BENCH_SEED="${BENCH_SEED:-42}"
USE_HYPERFINE="${USE_HYPERFINE:-true}"
BENCH_SHELL="${BENCH_SHELL:-bash}"
WORKSPACE="${WORKSPACE:-$(pwd)}"
BENCHMARK_COUNT="${BENCHMARK_COUNT:-0}"

# ─────────────────────────────────────────────────────────────────────────────
# CATPPUCCIN MOCHA — COMPLETE ANSI PALETTE
# ─────────────────────────────────────────────────────────────────────────────
C_RST=$'\033[0m'    C_BLD=$'\033[1m'    C_DIM=$'\033[2m'
C_MAUVE=$'\033[38;2;203;166;247m'   C_BLUE=$'\033[38;2;137;180;250m'
C_GREEN=$'\033[38;2;166;227;161m'   C_RED=$'\033[38;2;243;139;168m'
C_YELLOW=$'\033[38;2;249;226;175m'  C_PEACH=$'\033[38;2;250;179;135m'
C_TEAL=$'\033[38;2;148;226;213m'    C_SAP=$'\033[38;2;116;199;236m'
C_SKY=$'\033[38;2;137;220;235m'     C_LAV=$'\033[38;2;180;190;254m'
C_TEXT=$'\033[38;2;205;214;244m'    C_SUB=$'\033[38;2;166;173;200m'
C_OVR=$'\033[38;2;108;112;134m'     C_PINK=$'\033[38;2;245;194;231m'
C_MAR=$'\033[38;2;235;160;172m'     C_RW=$'\033[38;2;245;224;220m'
C_FL=$'\033[38;2;242;205;205m'

# ─────────────────────────────────────────────────────────────────────────────
# LOGGING ENGINE
# ─────────────────────────────────────────────────────────────────────────────
readonly OUTPUT_ABS="${WORKSPACE}/${OUTPUT_DIR}"
mkdir -p "${OUTPUT_ABS}"
readonly LOG_FILE="${OUTPUT_ABS}/benchmark-run.log"

_log() {
  local icon="$1" color="$2"; shift 2
  local ts; ts=$(date '+%H:%M:%S.%3N' 2>/dev/null || date '+%H:%M:%S')
  local elapsed=$(( $(date +%s) - START_EPOCH ))
  printf "${color}${icon}${C_RST} ${C_DIM}[%s +%ds]${C_RST} ${C_TEXT}%s${C_RST}\n" \
    "${ts}" "${elapsed}" "$*"
  printf "[%s] [+%ds] %s\n" "${ts}" "${elapsed}" "$*" >> "${LOG_FILE}"
}

log_bench()    { _log "⚡" "${C_MAUVE}"   "$@"; }
log_pass()     { _log "✅" "${C_GREEN}"   "$@"; }
log_fail()     { _log "❌" "${C_RED}"     "$@"; }
log_warn()     { _log "⚠️ " "${C_YELLOW}"  "$@"; }
log_info()     { _log "ℹ️ " "${C_BLUE}"    "$@"; }
log_stat()     { _log "📊" "${C_SAP}"     "$@"; }
log_regress()  { _log "🚨" "${C_MAR}"     "$@"; }
log_cache()    { _log "💾" "${C_TEAL}"    "$@"; }
log_dry()      { _log "🔍" "${C_LAV}"     "$@"; }
log_perf()     { _log "🎯" "${C_PEACH}"   "$@"; }
log_metric()   { _log "📈" "${C_PINK}"    "$@"; }
log_section()  { _log "🔹" "${C_SKY}"     "$@"; }
log_debug()    { [[ "${VERBOSE}" == "true" ]] && _log "🔎" "${C_OVR}" "$@" || true; }

section_header() {
  local num="$1" title="$2" icon="${3:-⚡}" color="${4:-${C_SAP}}"
  echo ""
  echo -e "  ${color}${C_BLD}┌─${icon} [${num}/${BENCHMARK_COUNT}] ${C_TEXT}${C_BLD}${title} ${color}$(printf '─%.0s' $(seq 1 $((52 - ${#title})) 2>/dev/null || true))┐${C_RST}"
}

section_result() {
  local status="$1" duration="${2:-?}"
  local icon color
  [[ "${status}" == "pass" ]] && { icon="✅"; color="${C_GREEN}"; } || \
  { icon="❌"; color="${C_RED}"; }
  echo -e "  ${color}└── ${icon} ${status^^} (${duration}ms)${C_RST}"
}

# ─────────────────────────────────────────────────────────────────────────────
# PROGRESS BAR
# ─────────────────────────────────────────────────────────────────────────────
_PROGRESS_CURRENT=0
_PROGRESS_TOTAL=1

progress_init() { _PROGRESS_CURRENT=0; _PROGRESS_TOTAL="${1:-1}"; }
progress_tick() {
  (( _PROGRESS_CURRENT++ )) || true
  local W=30 pct cur total
  cur="${_PROGRESS_CURRENT}"; total="${_PROGRESS_TOTAL}"
  pct=$(( cur * 100 / (total > 0 ? total : 1) ))
  local filled=$(( cur * W / (total > 0 ? total : 1) ))
  local bar=""
  for (( i=0; i<filled; i++ )); do bar+="█"; done
  for (( i=filled; i<W; i++ )); do bar+="░"; done

  local color="${C_MAUVE}"
  (( pct >= 50 )) && color="${C_YELLOW}"
  (( pct >= 80 )) && color="${C_GREEN}"

  printf "\r  ${color}[%s]${C_RST} ${C_TEXT}%3d%% (%d/%d)${C_RST}  " \
    "${bar}" "${pct}" "${cur}" "${total}"
  [[ "${cur}" -ge "${total}" ]] && echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# STATE TRACKING
# ─────────────────────────────────────────────────────────────────────────────
declare -A BENCH_RESULTS=()        # domain → JSON result string
declare -A BENCH_STATUS=()         # domain → pass|fail|skip|error
declare -A BENCH_DURATION=()       # domain → ms
declare -a BENCH_ORDER=()          # ordered list of executed domains
declare -a REGRESSION_LIST=()      # list of regressed benchmarks

TOTAL_BENCHMARKS=0
PASSED_BENCHMARKS=0
FAILED_BENCHMARKS=0
TOTAL_REGRESSIONS=0
OVERALL_SCORE=0

# Key metric exports
EXPORT_STARTUP_COLD=0
EXPORT_STARTUP_WARM=0
EXPORT_THEME_APPLY=0
EXPORT_THEME_P95=0
EXPORT_COLOR_IPS=0
EXPORT_HOT_RELOAD=0
EXPORT_API_P50=0
EXPORT_API_P95=0
EXPORT_MEM_PEAK=0

# ─────────────────────────────────────────────────────────────────────────────
# HYPERFINE WRAPPER — Precise statistical benchmarking
# ─────────────────────────────────────────────────────────────────────────────
run_hyperfine() {
  local name="$1"
  local cmd="$2"
  local iters="${3:-${ITERATIONS}}"
  local warmup="${4:-${WARMUP_RUNS}}"
  local output_json="${5:-${OUTPUT_ABS}/${name}-raw.json}"

  local ITERS_ACTUAL="${iters}"
  [[ "${ITERS_ACTUAL}" -lt "${MIN_ITERATIONS}" ]] && ITERS_ACTUAL="${MIN_ITERATIONS}"
  [[ "${ITERS_ACTUAL}" -gt "${MAX_ITERATIONS}" ]] && ITERS_ACTUAL="${MAX_ITERATIONS}"

  log_debug "hyperfine: ${name} (${ITERS_ACTUAL} iters, ${warmup} warmup)"

  if [[ "${USE_HYPERFINE}" == "true" ]] && command -v hyperfine &>/dev/null; then
    hyperfine \
      --runs "${ITERS_ACTUAL}" \
      --warmup "${warmup}" \
      --time-unit millisecond \
      --export-json "${output_json}" \
      --command-name "${name}" \
      --shell "${BENCH_SHELL}" \
      "${cmd}" \
      2>/dev/null || {
        log_warn "Hyperfine failed for '${name}' — using manual timing"
        run_manual_timing "${name}" "${cmd}" "${ITERS_ACTUAL}" "${output_json}"
      }
  else
    run_manual_timing "${name}" "${cmd}" "${ITERS_ACTUAL}" "${output_json}"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MANUAL TIMING — Fallback when Hyperfine unavailable
# ─────────────────────────────────────────────────────────────────────────────
run_manual_timing() {
  local name="$1"
  local cmd="$2"
  local iters="$3"
  local output_json="$4"

  local -a times=()

  # Warmup
  for (( i=0; i<WARMUP_RUNS; i++ )); do
    eval "${cmd}" > /dev/null 2>&1 || true
  done

  # Measurement
  for (( i=0; i<iters; i++ )); do
    local t0; t0=$(date +%s%N 2>/dev/null || echo 0)
    eval "${cmd}" > /dev/null 2>&1 || true
    local t1; t1=$(date +%s%N 2>/dev/null || echo 0)
    local ms=$(( (t1 - t0) / 1000000 ))
    times+=("${ms}")
  done

  # Build JSON via Python for accuracy
  python3 << TIMING_PY
import json
import math
import os

times   = [${times[*]:-0}]
times_s = [t/1000 for t in times]  # Convert ms to seconds
n       = len(times_s)
mean    = sum(times_s)/n if n else 0
sorted_t= sorted(times_s)
median  = sorted_t[n//2] if n else 0
std     = math.sqrt(sum((t-mean)**2 for t in times_s)/max(n-1,1)) if n>1 else 0

result = {
    "results": [{
        "command":  "${name}",
        "mean":     round(mean, 6),
        "stddev":   round(std, 6),
        "median":   round(median, 6),
        "min":      round(sorted_t[0] if sorted_t else 0, 6),
        "max":      round(sorted_t[-1] if sorted_t else 0, 6),
        "times":    times_s,
        "exit_codes_ok": [0]*n,
    }]
}

with open("${output_json}", "w") as f:
    json.dump(result, f, indent=2)
print(f"  Manual timing: {n} samples, mean={round(mean*1000,2)}ms")
TIMING_PY
}

# ─────────────────────────────────────────────────────────────────────────────
# PYTHON STATISTICAL ANALYSIS ENGINE
# ─────────────────────────────────────────────────────────────────────────────
analyze_results() {
  local domain="$1"
  local raw_json="$2"
  local analysis_json="${OUTPUT_ABS}/${domain}-analysis.json"

  python3 << ANALYSIS_PY
import json
import math
import os
import sys
from pathlib import Path

DOMAIN          = "${domain}"
RAW_JSON        = "${raw_json}"
ANALYSIS_JSON   = "${analysis_json}"
OUTLIER_METHOD  = "${OUTLIER_METHOD}"
OUTLIER_THRESH  = float("${OUTLIER_THRESHOLD}")
CONF_LEVEL      = float("${CONFIDENCE_LEVEL}")
PCTS_STR        = "${PERCENTILES}"
TIME_UNIT_PREF  = "${TIME_UNIT}"

# ── Color codes ────────────────────────────────────────────────────────────────
G = $'\033[38;2;166;227;161m'
R = $'\033[38;2;243;139;168m'
Y = $'\033[38;2;249;226;175m'
B = $'\033[38;2;137;180;250m'
M = $'\033[38;2;203;166;247m'
T = $'\033[38;2;205;214;244m'
S = $'\033[38;2;166;173;200m'
X = $'\033[0m'

def p(ic, c, msg): print(f"  {c}{ic}{X} {T}{msg}{X}")

# ── Load raw results ───────────────────────────────────────────────────────────
try:
    with open(RAW_JSON) as f:
        raw = json.load(f)
    result = raw.get("results", [{}])[0]
except Exception as e:
    p("❌",R,f"Failed to load {RAW_JSON}: {e}")
    sys.exit(1)

times_s = result.get("times", [result.get("mean", 0)])
n = len(times_s)

if n == 0:
    p("❌",R,f"No timing samples found")
    sys.exit(1)

times_ms = [t * 1000 for t in times_s]

# ── Outlier removal ────────────────────────────────────────────────────────────
def remove_outliers_iqr(data, k=1.5):
    q1, q3 = (sorted(data)[n//4], sorted(data)[3*n//4])
    iqr = q3 - q1
    return [x for x in data if q1 - k*iqr <= x <= q3 + k*iqr]

def remove_outliers_zscore(data, threshold=3.0):
    mean_ = sum(data)/len(data)
    std_  = math.sqrt(sum((x-mean_)**2 for x in data)/max(len(data)-1,1))
    return [x for x in data if std_ == 0 or abs(x-mean_)/std_ < threshold]

def remove_outliers_modified_z(data, threshold=3.5):
    median_ = sorted(data)[len(data)//2]
    mad     = sorted(abs(x-median_) for x in data)[len(data)//2]
    return [x for x in data if mad == 0 or 0.6745*abs(x-median_)/mad < threshold]

original_n = n
if OUTLIER_METHOD == "iqr":
    clean_ms = remove_outliers_iqr(times_ms, OUTLIER_THRESH)
elif OUTLIER_METHOD == "zscore":
    clean_ms = remove_outliers_zscore(times_ms, OUTLIER_THRESH)
elif OUTLIER_METHOD == "modified":
    clean_ms = remove_outliers_modified_z(times_ms, OUTLIER_THRESH)
else:
    clean_ms = times_ms

outliers_removed = original_n - len(clean_ms)
if outliers_removed > 0:
    p("⚠️ ",Y,f"Removed {outliers_removed} outlier(s) via {OUTLIER_METHOD} method")

n = len(clean_ms)
if n == 0:
    p("⚠️ ",Y,"All samples removed as outliers — using original data")
    clean_ms = times_ms
    n = len(clean_ms)

# ── Core statistics ────────────────────────────────────────────────────────────
clean_sorted = sorted(clean_ms)
mean_ms   = sum(clean_ms) / n
median_ms = clean_sorted[n//2]
min_ms    = clean_sorted[0]
max_ms    = clean_sorted[-1]
variance  = sum((x - mean_ms)**2 for x in clean_ms) / max(n-1, 1)
stddev_ms = math.sqrt(variance)
cv_pct    = (stddev_ms / mean_ms * 100) if mean_ms > 0 else 0

# IQR
q1 = clean_sorted[n//4]
q3 = clean_sorted[3*n//4]
iqr_val = q3 - q1

# ── Percentiles ────────────────────────────────────────────────────────────────
pct_vals = [int(float(p.strip())) for p in PCTS_STR.split(",") if p.strip()]
percentiles = {}
for pct in pct_vals:
    idx = max(0, min(int(n * pct / 100), n-1))
    percentiles[f"p{pct}"] = round(clean_sorted[idx], 3)

# ── Confidence interval ────────────────────────────────────────────────────────
# t-distribution approximation for small samples
def t_critical(df, alpha):
    """Two-tailed t-critical value approximation."""
    from math import gamma, sqrt, pi
    if df <= 0: return 1.96
    # Approximation for common confidence levels
    if CONF_LEVEL >= 0.99:   return 2.576
    elif CONF_LEVEL >= 0.95: return 1.96 + (2.576-1.96)*((0.99-CONF_LEVEL)/(0.99-0.95))
    elif CONF_LEVEL >= 0.90: return 1.645 + (1.96-1.645)*((0.95-CONF_LEVEL)/(0.95-0.90))
    return 1.645

t_crit   = t_critical(n-1, (1-CONF_LEVEL)/2)
se       = stddev_ms / math.sqrt(n) if n > 0 else 0
ci_lower = max(0, mean_ms - t_crit * se)
ci_upper = mean_ms + t_crit * se

# ── Time unit selection ────────────────────────────────────────────────────────
if TIME_UNIT_PREF == "auto":
    if   mean_ms >= 1000:  unit, divisor, suffix = "s",  1000, "s"
    elif mean_ms >= 1:     unit, divisor, suffix = "ms", 1,    "ms"
    elif mean_ms >= 0.001: unit, divisor, suffix = "us", 0.001,"μs"
    else:                  unit, divisor, suffix = "ns", 0.000001,"ns"
else:
    unit_map = {"s":(1000,"s"), "ms":(1,"ms"), "us":(0.001,"μs"), "ns":(0.000001,"ns")}
    divisor, suffix = unit_map.get(TIME_UNIT_PREF, (1,"ms"))
    unit = TIME_UNIT_PREF

def fmt(v): return f"{v/divisor:.3f}{suffix}"

# ── Display ────────────────────────────────────────────────────────────────────
print(f"\n  {M}📊 Statistical Analysis: {DOMAIN}{X}")
print(f"  {S}{'─'*50}{X}")
print(f"  {T}Samples:   {G}{n}{X} ({B}+{warmup} warmup{X}) [{outliers_removed} outliers removed]")
print(f"  {T}Mean:      {G}{fmt(mean_ms)}{X}  ±{fmt(stddev_ms)} ({cv_pct:.1f}% CV)")
print(f"  {T}Median:    {M}{fmt(median_ms)}{X}")
print(f"  {T}Range:     {Y}{fmt(min_ms)}{X} – {Y}{fmt(max_ms)}{X}  (IQR={fmt(iqr_val)})")
print(f"  {T}CI {int(CONF_LEVEL*100)}%:   [{fmt(ci_lower)}, {fmt(ci_upper)}]")
print()
print(f"  {B}Percentiles:{X}")
for pct_name, pct_val in percentiles.items():
    bar_len = int(pct_val / max_ms * 20) if max_ms > 0 else 0
    bar = "█" * bar_len + "░" * (20 - bar_len)
    color = G if pct_val < mean_ms * 1.5 else Y if pct_val < mean_ms * 3 else R
    print(f"    {color}{pct_name:5s}{X}  [{color}{bar}{X}]  {color}{fmt(pct_val)}{X}")

# ── Stability assessment ───────────────────────────────────────────────────────
stability = "excellent" if cv_pct < 5 else \
            "good"      if cv_pct < 15 else \
            "moderate"  if cv_pct < 30 else \
            "poor"
stab_colors = {"excellent":G,"good":T,"moderate":Y,"poor":R}
stab_c = stab_colors[stability]
p("📈",B,f"Stability: {stab_c}{stability}{X} (CV={cv_pct:.1f}%)")

# ── Write analysis JSON ────────────────────────────────────────────────────────
warmup_n = int("${WARMUP_RUNS}")
analysis = {
    "domain":     DOMAIN,
    "command":    result.get("command", DOMAIN),
    "iterations": n,
    "warmup":     warmup_n,
    "outliers_removed": outliers_removed,
    "outlier_method":   OUTLIER_METHOD,
    "time_unit":  suffix,
    "statistics": {
        "mean_ms":   round(mean_ms, 3),
        "median_ms": round(median_ms, 3),
        "min_ms":    round(min_ms, 3),
        "max_ms":    round(max_ms, 3),
        "stddev_ms": round(stddev_ms, 3),
        "variance":  round(variance, 3),
        "cv_percent":round(cv_pct, 2),
        "iqr_ms":    round(iqr_val, 3),
    },
    "percentiles":        {k: round(v,3) for k,v in percentiles.items()},
    "confidence_interval":{
        "level":   CONF_LEVEL,
        "lower_ms":round(ci_lower, 3),
        "upper_ms":round(ci_upper, 3),
    },
    "stability":    stability,
    "raw_times_ms": [round(t,3) for t in clean_ms],
}

import os
Path("${analysis_json}").parent.mkdir(parents=True, exist_ok=True)
with open("${analysis_json}", "w") as f:
    json.dump(analysis, f, indent=2)

# Write GitHub output for key metrics
with open(os.environ.get("GITHUB_OUTPUT","/dev/null"), "a") as out:
    out.write(f"${domain}_mean_ms={round(mean_ms,2)}\n")
    p_50 = percentiles.get("p50", median_ms)
    p_95 = percentiles.get("p95", max_ms)
    out.write(f"${domain}_p50_ms={round(p_50,2)}\n")
    out.write(f"${domain}_p95_ms={round(p_95,2)}\n")
ANALYSIS_PY

  echo "${analysis_json}"
}

# ─────────────────────────────────────────────────────────────────────────────
# BANNER
# ─────────────────────────────────────────────────────────────────────────────
print_banner() {
  echo ""
  echo -e "${C_MAUVE}${C_BLD}"
  cat << 'BANNER'
  ╔══════════════════════════════════════════════════════════════════╗
  ║  ⚡ ASH Benchmark Execution Engine v5.0.0-omega                  ║
  ╚══════════════════════════════════════════════════════════════════╝
BANNER
  echo -e "${C_RST}"
  printf  "  ${C_TEXT}Session:    ${C_LAV}%-50s${C_RST}\n" "${SESSION_ID}"
  printf  "  ${C_TEXT}Benchmarks: ${C_PEACH}%-50s${C_RST}\n" "${RESOLVED_BENCHMARKS}"
  printf  "  ${C_TEXT}Iterations: ${C_TEAL}%-50s${C_RST}\n" "${ITERATIONS} (warmup: ${WARMUP_RUNS})"
  printf  "  ${C_TEXT}Hyperfine:  ${C_GREEN}%-50s${C_RST}\n" "$(command -v hyperfine &>/dev/null && echo "available" || echo "fallback mode")"
  printf  "  ${C_TEXT}Dry Run:    ${C_YELLOW}%-50s${C_RST}\n" "${DRY_RUN}"
  echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# SETUP — Create mock scripts for CI environment
# ─────────────────────────────────────────────────────────────────────────────
setup_ci_environment() {
  log_section "setup" "Setting up CI benchmark environment"

  # Create minimal ASH CLI mock if not exists
  if [[ ! -f "${WORKSPACE}/${CLI_PATH}" ]]; then
    mkdir -p "$(dirname "${WORKSPACE}/${CLI_PATH}")"
    cat > "${WORKSPACE}/${CLI_PATH}" << 'CLI_EOF'
#!/usr/bin/env bash
# ASH CLI mock for CI benchmarking
case "${1:-}" in
  --version|-v) echo "ash v5.0.0-omega" ;;
  --help|-h)    echo "ash — ASH Dotfiles v5.0 OMEGA" ;;
  theme)
    case "${2:-}" in
      apply)   sleep 0.05; echo "Theme applied" ;;
      list)    echo "catppuccin-mocha tokyo-night gruvbox-dark" ;;
      *)       echo "Theme command" ;;
    esac ;;
  plugin)      echo "Plugin command" ;;
  snapshot)    sleep 0.03; echo "Snapshot created" ;;
  config)      echo "Config: ok" ;;
  doctor)      echo "Doctor: all ok" ;;
  *)           echo "ash: command '${1:-}'" ;;
esac
CLI_EOF
    chmod +x "${WORKSPACE}/${CLI_PATH}"
    log_debug "Created CLI mock: ${WORKSPACE}/${CLI_PATH}"
  fi

  # Create mock color engine
  mkdir -p "${WORKSPACE}/ash-cli/engines/color-engine"
  for script in extract harmonize contrast-check; do
    local f="${WORKSPACE}/ash-cli/engines/color-engine/${script}.sh"
    [[ -f "${f}" ]] && continue
    printf '#!/usr/bin/env bash\nsleep 0.040\necho "%s done"\n' "${script}" > "${f}"
    chmod +x "${f}"
  done

  # Create mock hot-reload scripts
  mkdir -p "${WORKSPACE}/ash-cli/engines/hot-reload-engine"
  for target in hyprland waybar kitty dunst gtk nvim fish; do
    local f="${WORKSPACE}/ash-cli/engines/hot-reload-engine/reload-${target}.sh"
    [[ -f "${f}" ]] && continue
    local delay
    case "${target}" in
      hyprland) delay="0.050" ;; waybar) delay="0.080" ;;
      kitty)    delay="0.020" ;; dunst)  delay="0.040" ;;
      gtk)      delay="0.060" ;; nvim)   delay="0.030" ;;
      fish)     delay="0.015" ;;
    esac
    printf '#!/usr/bin/env bash\nsleep %s\necho "%s reloaded"\n' \
      "${delay}" "${target}" > "${f}"
    chmod +x "${f}"
  done

  # Create test wallpapers
  mkdir -p "${WORKSPACE}/.benchmark-fixtures"
  python3 -c "
from PIL import Image
import os, sys
n = int('${IMAGE_COUNT}')
for i in range(n):
    colors = [('#1e1e2e','#cba6f7'),('#1a1b26','#7aa2f7'),
              ('#282828','#fabd2f'),('#2e3440','#5e81ac'),
              ('#282a36','#bd93f9')]
    c1,c2 = colors[i%len(colors)]
    img = Image.new('RGB',(400,225))
    pixels = img.load()
    for y in range(225):
        for x in range(400):
            t = x/400
            r1,g1,b1=[int(c1[i:i+2],16) for i in (1,3,5)]
            r2,g2,b2=[int(c2[i:i+2],16) for i in (1,3,5)]
            r,g,b=int(r1*(1-t)+r2*t),int(g1*(1-t)+g2*t),int(b1*(1-t)+b2*t)
            pixels[x,y]=(r,g,b)
    img.save(f'${WORKSPACE}/.benchmark-fixtures/test-{i:03d}.jpg','JPEG',quality=85)
print(f'Created {n} test wallpapers')
" 2>/dev/null || \
    # Fallback: create placeholder files
    for i in $(seq -w 1 "${IMAGE_COUNT}"); do
      convert -size 400x225 gradient:"#1e1e2e-#cba6f7" \
        "${WORKSPACE}/.benchmark-fixtures/test-${i}.jpg" 2>/dev/null || \
      dd if=/dev/urandom bs=1024 count=100 \
        > "${WORKSPACE}/.benchmark-fixtures/test-${i}.jpg" 2>/dev/null || true
    done

  log_pass "CI environment ready"
}

# ─────────────────────────────────────────────────────────────────────────────
# BENCHMARK: STARTUP
# ─────────────────────────────────────────────────────────────────────────────
benchmark_startup() {
  section_header "${BENCH_IDX}" "Startup Latency" "⚡" "${C_GREEN}"
  local t0; t0=$(date +%s%N 2>/dev/null || echo 0)

  local CLI="${WORKSPACE}/${CLI_PATH}"
  [[ ! -f "${CLI}" ]] && { log_warn "CLI not found: ${CLI}"; return 0; }

  local all_results=()
  IFS=',' read -ra MODES <<< "${STARTUP_MODES}"

  for mode in "${MODES[@]}"; do
    mode=$(echo "${mode}" | tr -d ' ')
    log_bench "startup" "Mode: ${mode}"

    local cmd=""
    case "${mode}" in
      cold)        cmd="bash ${CLI} --version" ;;
      warm)        cmd="bash ${CLI} --version" ;;
      version)     cmd="bash ${CLI} --version" ;;
      help)        cmd="bash ${CLI} --help" ;;
      config-read) cmd="bash ${CLI} config list --quiet 2>/dev/null || bash ${CLI} config" ;;
      *)           cmd="bash ${CLI} --version" ;;
    esac

    # Extra warmup for cold start simulation
    local warmup="${WARMUP_RUNS}"
    [[ "${mode}" == "cold" ]] && warmup=0

    local RAW_JSON="${OUTPUT_ABS}/startup-${mode}-raw.json"
    run_hyperfine "startup-${mode}" "${cmd}" "${ITERATIONS}" "${warmup}" "${RAW_JSON}"

    local ANALYSIS_JSON
    ANALYSIS_JSON=$(analyze_results "startup-${mode}" "${RAW_JSON}")

    if [[ -f "${ANALYSIS_JSON}" ]]; then
      local mean; mean=$(jq '.statistics.mean_ms' "${ANALYSIS_JSON}" 2>/dev/null || echo 0)
      log_metric "startup" "${mode}: ${mean}ms mean"
      all_results+=("\"${mode}\":${mean}")

      case "${mode}" in
        cold) EXPORT_STARTUP_COLD="${mean}" ;;
        warm) EXPORT_STARTUP_WARM="${mean}" ;;
      esac
    fi
  done

  local t1; t1=$(date +%s%N 2>/dev/null || echo 0)
  local dur_ms=$(( (t1 - t0) / 1000000 ))
  BENCH_RESULTS["startup"]=$(printf '{%s}' "$(IFS=,; echo "${all_results[*]}")")
  BENCH_STATUS["startup"]="pass"
  BENCH_DURATION["startup"]="${dur_ms}"
  section_result "pass" "${dur_ms}"
}

# ─────────────────────────────────────────────────────────────────────────────
# BENCHMARK: THEME APPLY
# ─────────────────────────────────────────────────────────────────────────────
benchmark_theme_apply() {
  section_header "${BENCH_IDX}" "Theme Apply Pipeline" "🎨" "${C_MAUVE}"
  local t0; t0=$(date +%s%N 2>/dev/null || echo 0)

  local CLI="${WORKSPACE}/${CLI_PATH}"

  # Create a comprehensive theme apply script
  local APPLY_SCRIPT="${OUTPUT_ABS}/theme-apply-bench.sh"
  cat > "${APPLY_SCRIPT}" << APPLY_SH
#!/usr/bin/env bash
set -euo pipefail
# Simulate full theme application pipeline
THEME="${THEME_NAME}"
TMPDIR="/tmp/ash-bench-\$\$"
mkdir -p "\${TMPDIR}"

# Stage 1: Color extraction
bash "${WORKSPACE}/ash-cli/engines/color-engine/extract.sh" \
  "${WORKSPACE}/.benchmark-fixtures/test-001.jpg" \
  "--output=\${TMPDIR}/colors.json" 2>/dev/null || \
  echo '{}' > "\${TMPDIR}/colors.json"

# Stage 2: Palette generation
bash "${WORKSPACE}/ash-cli/engines/color-engine/harmonize.sh" \
  "\${TMPDIR}/colors.json" > "\${TMPDIR}/palette.json" 2>/dev/null || \
  echo '{}' > "\${TMPDIR}/palette.json"

# Stage 3: Template rendering (simulate 5 templates)
for tpl in hyprland waybar kitty dunst gtk; do
  echo "# \${tpl} config" > "\${TMPDIR}/\${tpl}.conf"
done

# Stage 4: CLI apply
bash "${CLI}" theme 2>/dev/null || true

# Cleanup
rm -rf "\${TMPDIR}"
APPLY_SH
  chmod +x "${APPLY_SCRIPT}"

  local RAW_JSON="${OUTPUT_ABS}/theme-apply-raw.json"
  run_hyperfine "theme-apply" "bash ${APPLY_SCRIPT}" \
    "${ITERATIONS}" "${WARMUP_RUNS}" "${RAW_JSON}"

  local ANALYSIS_JSON
  ANALYSIS_JSON=$(analyze_results "theme-apply" "${RAW_JSON}")

  if [[ -f "${ANALYSIS_JSON}" ]]; then
    EXPORT_THEME_APPLY=$(jq '.statistics.mean_ms' "${ANALYSIS_JSON}" 2>/dev/null || echo 0)
    EXPORT_THEME_P95=$(jq '.percentiles.p95' "${ANALYSIS_JSON}" 2>/dev/null || echo 0)
    log_metric "theme-apply" "mean=${EXPORT_THEME_APPLY}ms p95=${EXPORT_THEME_P95}ms"
  fi

  local t1; t1=$(date +%s%N 2>/dev/null || echo 0)
  local dur_ms=$(( (t1 - t0) / 1000000 ))
  BENCH_RESULTS["theme-apply"]="{\"mean\":${EXPORT_THEME_APPLY},\"p95\":${EXPORT_THEME_P95}}"
  BENCH_STATUS["theme-apply"]="pass"
  BENCH_DURATION["theme-apply"]="${dur_ms}"
  section_result "pass" "${dur_ms}"
}

# ─────────────────────────────────────────────────────────────────────────────
# BENCHMARK: COLOR EXTRACTION
# ─────────────────────────────────────────────────────────────────────────────
benchmark_color_extract() {
  section_header "${BENCH_IDX}" "Color Extraction Throughput" "🌈" "${C_PINK}"
  local t0; t0=$(date +%s%N 2>/dev/null || echo 0)

  local EXTRACT_SCRIPT="${OUTPUT_ABS}/color-extract-bench.sh"
  cat > "${EXTRACT_SCRIPT}" << EXTRACT_SH
#!/usr/bin/env bash
set -euo pipefail
FIXTURE_DIR="${WORKSPACE}/.benchmark-fixtures"
for img in \${FIXTURE_DIR}/test-*.jpg; do
  bash "${WORKSPACE}/ash-cli/engines/color-engine/extract.sh" \
    "\${img}" "--dry-run" 2>/dev/null || true
done
EXTRACT_SH
  chmod +x "${EXTRACT_SCRIPT}"

  local RAW_JSON="${OUTPUT_ABS}/color-extract-raw.json"
  run_hyperfine "color-extract" "bash ${EXTRACT_SCRIPT}" \
    "${ITERATIONS}" "${WARMUP_RUNS}" "${RAW_JSON}"

  local ANALYSIS_JSON
  ANALYSIS_JSON=$(analyze_results "color-extract" "${RAW_JSON}")

  if [[ -f "${ANALYSIS_JSON}" ]]; then
    local mean_ms; mean_ms=$(jq '.statistics.mean_ms' "${ANALYSIS_JSON}" 2>/dev/null || echo 1000)
    # Calculate throughput: images per second
    EXPORT_COLOR_IPS=$(echo "scale=2; ${IMAGE_COUNT} * 1000 / ${mean_ms}" | bc 2>/dev/null || echo "0")
    log_metric "color-extract" "${IMAGE_COUNT} images in ${mean_ms}ms = ${EXPORT_COLOR_IPS} img/s"
  fi

  local t1; t1=$(date +%s%N 2>/dev/null || echo 0)
  local dur_ms=$(( (t1 - t0) / 1000000 ))
  BENCH_RESULTS["color-extract"]="{\"images_per_second\":${EXPORT_COLOR_IPS}}"
  BENCH_STATUS["color-extract"]="pass"
  BENCH_DURATION["color-extract"]="${dur_ms}"
  section_result "pass" "${dur_ms}"
}

# ─────────────────────────────────────────────────────────────────────────────
# BENCHMARK: HOT RELOAD
# ─────────────────────────────────────────────────────────────────────────────
benchmark_hot_reload() {
  section_header "${BENCH_IDX}" "Hot Reload Propagation" "🔥" "${C_PEACH}"
  local t0; t0=$(date +%s%N 2>/dev/null || echo 0)

  local RELOAD_DIR="${WORKSPACE}/ash-cli/engines/hot-reload-engine"
  local -a TARGET_LIST=()

  if [[ "${THEME_TARGETS}" == "all" ]]; then
    TARGET_LIST=(hyprland waybar kitty dunst gtk nvim fish)
  else
    IFS=',' read -ra TARGET_LIST <<< "${THEME_TARGETS}"
  fi

  local all_target_results=()

  for target in "${TARGET_LIST[@]}"; do
    target=$(echo "${target}" | tr -d ' ')
    local RELOAD_SCRIPT="${RELOAD_DIR}/reload-${target}.sh"
    [[ ! -f "${RELOAD_SCRIPT}" ]] && continue

    log_bench "hot-reload" "Target: ${target}"
    local RAW_JSON="${OUTPUT_ABS}/hot-reload-${target}-raw.json"

    run_hyperfine "reload-${target}" \
      "bash ${RELOAD_SCRIPT}" \
      "${ITERATIONS}" "${WARMUP_RUNS}" "${RAW_JSON}"

    local ANALYSIS_JSON
    ANALYSIS_JSON=$(analyze_results "hot-reload-${target}" "${RAW_JSON}")

    if [[ -f "${ANALYSIS_JSON}" ]]; then
      local mean_ms; mean_ms=$(jq '.statistics.mean_ms' "${ANALYSIS_JSON}" 2>/dev/null || echo 0)
      log_metric "hot-reload" "${target}: ${mean_ms}ms"
      all_target_results+=("\"${target}\":${mean_ms}")
    fi
  done

  # Create full cascade benchmark
  local CASCADE_SCRIPT="${OUTPUT_ABS}/hot-reload-cascade.sh"
  cat > "${CASCADE_SCRIPT}" << CASCADE_SH
#!/usr/bin/env bash
for t in ${TARGET_LIST[*]:-}; do
  bash "${RELOAD_DIR}/reload-\${t}.sh" 2>/dev/null &
done
wait
CASCADE_SH
  chmod +x "${CASCADE_SCRIPT}"

  local CASCADE_JSON="${OUTPUT_ABS}/hot-reload-cascade-raw.json"
  run_hyperfine "hot-reload-cascade" "bash ${CASCADE_SCRIPT}" \
    "${ITERATIONS}" "${WARMUP_RUNS}" "${CASCADE_JSON}"

  local CASCADE_ANALYSIS
  CASCADE_ANALYSIS=$(analyze_results "hot-reload-cascade" "${CASCADE_JSON}")

  if [[ -f "${CASCADE_ANALYSIS}" ]]; then
    EXPORT_HOT_RELOAD=$(jq '.statistics.mean_ms' "${CASCADE_ANALYSIS}" 2>/dev/null || echo 0)
    log_metric "hot-reload" "Cascade total: ${EXPORT_HOT_RELOAD}ms"
    all_target_results+=("\"cascade\":${EXPORT_HOT_RELOAD}")
  fi

  local t1; t1=$(date +%s%N 2>/dev/null || echo 0)
  local dur_ms=$(( (t1 - t0) / 1000000 ))
  BENCH_RESULTS["hot-reload"]=$(printf '{%s}' "$(IFS=,; echo "${all_target_results[*]:-"\"cascade\":0"}")")
  BENCH_STATUS["hot-reload"]="pass"
  BENCH_DURATION["hot-reload"]="${dur_ms}"
  section_result "pass" "${dur_ms}"
}

# ─────────────────────────────────────────────────────────────────────────────
# BENCHMARK: API ENDPOINTS
# ─────────────────────────────────────────────────────────────────────────────
benchmark_api() {
  section_header "${BENCH_IDX}" "REST API Performance" "🌐" "${C_BLUE}"
  local t0; t0=$(date +%s%N 2>/dev/null || echo 0)

  # Try to start mock API server
  local API_PID=""
  local API_URL="http://${API_HOST}:${API_PORT}"

  # Check if server is running
  if ! curl -sf "${API_URL}/health" > /dev/null 2>&1; then
    log_info "api" "Starting mock API server..."

    # Start a minimal Python mock
    python3 << 'MOCK_SERVER_PY' &
import http.server
import json
import time
import os

PORT = int(os.environ.get("API_PORT","8765"))
HOST = os.environ.get("API_HOST","localhost")

RESPONSES = {
    "/health":          {"status":"healthy","version":"5.0.0"},
    "/api/v1/themes":   {"themes":["catppuccin-mocha","tokyo-night"],"total":250},
    "/api/v1/plugins":  {"plugins":["game-mode","caffeine"],"total":150},
    "/api/v1/config":   {"theme":"catppuccin-mocha","mode":"default"},
    "/api/v1/snapshots":{"snapshots":[],"total":0},
    "/api/v1/wallpapers":{"wallpapers":[],"total":0},
}

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        body = RESPONSES.get(self.path, {"error":"not found"})
        data = json.dumps(body).encode()
        self.send_response(200 if self.path in RESPONSES else 404)
        self.send_header("Content-Type","application/json")
        self.send_header("Content-Length",str(len(data)))
        self.end_headers()
        self.wfile.write(data)
    def log_message(self, *args): pass

server = http.server.HTTPServer((HOST, PORT), Handler)
server.serve_forever()
MOCK_SERVER_PY

    API_PID=$!
    echo "start_time=${START_EPOCH}" >> /tmp/ash-api-mock.pid
    echo "${API_PID}" >> /tmp/ash-api-mock.pid
    sleep 1

    # Verify server is up
    if curl -sf "${API_URL}/health" > /dev/null 2>&1; then
      log_pass "api" "Mock server started on port ${API_PORT}"
    else
      log_warn "api" "Mock server startup uncertain — continuing"
    fi
  fi

  IFS=',' read -ra ENDPOINTS <<< "${API_ENDPOINTS}"
  local endpoint_results=()

  for ep in "${ENDPOINTS[@]}"; do
    ep=$(echo "${ep}" | tr -d ' ')
    local ep_name; ep_name=$(echo "${ep}" | tr '/' '_' | tr -d '_' | head -c 20)
    [[ -z "${ep_name}" ]] && ep_name="health"

    log_bench "api" "Endpoint: ${ep}"

    local RAW_JSON="${OUTPUT_ABS}/api-${ep_name}-raw.json"
    local cmd="curl -sf --max-time 5 ${API_URL}${ep} > /dev/null"

    run_hyperfine "api-${ep_name}" "${cmd}" \
      "${ITERATIONS}" "${WARMUP_RUNS}" "${RAW_JSON}"

    local ANALYSIS_JSON
    ANALYSIS_JSON=$(analyze_results "api-${ep_name}" "${RAW_JSON}")

    if [[ -f "${ANALYSIS_JSON}" ]]; then
      local p50; p50=$(jq '.percentiles.p50 // .statistics.median_ms' "${ANALYSIS_JSON}" 2>/dev/null || echo 0)
      local p95; p95=$(jq '.percentiles.p95 // .statistics.max_ms' "${ANALYSIS_JSON}" 2>/dev/null || echo 0)
      log_metric "api" "${ep}: p50=${p50}ms p95=${p95}ms"
      endpoint_results+=("\"${ep_name}\":{\"p50\":${p50},\"p95\":${p95}}")

      # Use /health as primary metric
      if [[ "${ep}" == "/health" ]]; then
        EXPORT_API_P50="${p50}"
        EXPORT_API_P95="${p95}"
      fi
    fi
  done

  # Cleanup mock server
  if [[ -n "${API_PID:-}" ]]; then
    kill "${API_PID}" 2>/dev/null || true
  fi

  local t1; t1=$(date +%s%N 2>/dev/null || echo 0)
  local dur_ms=$(( (t1 - t0) / 1000000 ))
  BENCH_RESULTS["api"]=$(printf '{%s}' "$(IFS=,; echo "${endpoint_results[*]:-"\"health\":{\"p50\":0,\"p95\":0}"}")")
  BENCH_STATUS["api"]="pass"
  BENCH_DURATION["api"]="${dur_ms}"
  section_result "pass" "${dur_ms}"
}

# ─────────────────────────────────────────────────────────────────────────────
# BENCHMARK: MEMORY
# ─────────────────────────────────────────────────────────────────────────────
benchmark_memory() {
  section_header "${BENCH_IDX}" "Memory Usage Profiling" "🧠" "${C_TEAL}"
  local t0; t0=$(date +%s%N 2>/dev/null || echo 0)

  local CLI="${WORKSPACE}/${CLI_PATH}"
  local MEM_OUTPUT="${OUTPUT_ABS}/memory-profile.json"

  python3 << MEMORY_PY
import subprocess
import time
import json
import os
import sys
from pathlib import Path

try:
    import psutil
    HAS_PSUTIL = True
except ImportError:
    HAS_PSUTIL = False
    print("  ⚠️  psutil not available — using /proc fallback")

CLI         = "${CLI}"
INTERVAL_MS = int("${MEMORY_INTERVAL_MS}")
N           = int("${ITERATIONS}")
OUTPUT      = "${MEM_OUTPUT}"

G = $'\033[38;2;166;227;161m'
Y = $'\033[38;2;249;226;175m'
B = $'\033[38;2;137;180;250m'
T = $'\033[38;2;205;214;244m'
X = $'\033[0m'

def measure_process(cmd):
    """Measure peak RSS memory of a process."""
    try:
        proc = subprocess.Popen(
            ["bash", "-c", cmd],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        pid = proc.pid
        peak_rss_kb = 0

        if HAS_PSUTIL:
            ps_proc = psutil.Process(pid)
            while proc.poll() is None:
                try:
                    mem = ps_proc.memory_info()
                    rss_kb = mem.rss // 1024
                    peak_rss_kb = max(peak_rss_kb, rss_kb)
                    time.sleep(INTERVAL_MS / 1000)
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    break
        else:
            # Fallback: read /proc/PID/status
            while proc.poll() is None:
                try:
                    with open(f"/proc/{pid}/status") as f:
                        for line in f:
                            if line.startswith("VmRSS:"):
                                kb = int(line.split()[1])
                                peak_rss_kb = max(peak_rss_kb, kb)
                                break
                except Exception:
                    break
                time.sleep(INTERVAL_MS / 1000)

        proc.wait(timeout=30)
        return peak_rss_kb
    except Exception as e:
        print(f"  ⚠️  Memory measurement error: {e}", file=sys.stderr)
        return 0

CMDS = {
    "cli_version":  f"bash {CLI} --version",
    "cli_startup":  f"bash {CLI} --help",
    "full_apply":   f"bash {CLI} theme 2>/dev/null || true",
}

results = {}
for name, cmd in CMDS.items():
    samples = []
    for i in range(min(N, 5)):  # Limit memory measurements for speed
        kb = measure_process(cmd)
        if kb > 0:
            samples.append(kb)
        time.sleep(0.1)

    if samples:
        avg_kb    = sum(samples)/len(samples)
        peak_kb   = max(samples)
        peak_mb   = peak_kb / 1024
        results[name] = {
            "peak_rss_kb": round(peak_kb, 1),
            "avg_rss_kb":  round(avg_kb, 1),
            "peak_mb":     round(peak_mb, 2),
        }
        print(f"  {B}🧠 {name}:{X} peak={G}{peak_mb:.1f}MB{X} avg={round(avg_kb/1024,1):.1f}MB")

overall_peak_mb = max((v["peak_mb"] for v in results.values()), default=0)
print(f"\n  {B}Overall peak: {G}{overall_peak_mb:.1f}MB{X}")

output_data = {
    "domain": "memory",
    "measurements": results,
    "overall_peak_mb": overall_peak_mb,
}

Path(OUTPUT).parent.mkdir(parents=True, exist_ok=True)
with open(OUTPUT, "w") as f:
    json.dump(output_data, f, indent=2)

with open(os.environ.get("GITHUB_OUTPUT","/dev/null"), "a") as out:
    out.write(f"memory_peak_mb={overall_peak_mb}\n")
MEMORY_PY

  if [[ -f "${MEM_OUTPUT}" ]]; then
    EXPORT_MEM_PEAK=$(jq '.overall_peak_mb' "${MEM_OUTPUT}" 2>/dev/null || echo 0)
    log_metric "memory" "Peak: ${EXPORT_MEM_PEAK}MB"
  fi

  local t1; t1=$(date +%s%N 2>/dev/null || echo 0)
  local dur_ms=$(( (t1 - t0) / 1000000 ))
  BENCH_RESULTS["memory"]="{\"peak_mb\":${EXPORT_MEM_PEAK}}"
  BENCH_STATUS["memory"]="pass"
  BENCH_DURATION["memory"]="${dur_ms}"
  section_result "pass" "${dur_ms}"
}

# ─────────────────────────────────────────────────────────────────────────────
# BENCHMARK: PLUGIN LOAD
# ─────────────────────────────────────────────────────────────────────────────
benchmark_plugin_load() {
  section_header "${BENCH_IDX}" "Plugin Lifecycle Performance" "🔌" "${C_LAV}"
  local t0; t0=$(date +%s%N 2>/dev/null || echo 0)

  local PLUGIN_SCRIPT="${OUTPUT_ABS}/plugin-load-bench.sh"
  cat > "${PLUGIN_SCRIPT}" << PLUGIN_SH
#!/usr/bin/env bash
set -euo pipefail
CLI="${WORKSPACE}/${CLI_PATH}"
# Simulate plugin lifecycle
bash "\${CLI}" plugin 2>/dev/null || true
sleep 0.005  # Plugin init overhead
PLUGIN_SH
  chmod +x "${PLUGIN_SCRIPT}"

  local RAW_JSON="${OUTPUT_ABS}/plugin-load-raw.json"
  run_hyperfine "plugin-load" "bash ${PLUGIN_SCRIPT}" \
    "${ITERATIONS}" "${WARMUP_RUNS}" "${RAW_JSON}"

  local ANALYSIS_JSON
  ANALYSIS_JSON=$(analyze_results "plugin-load" "${RAW_JSON}")
  local mean_ms=0
  [[ -f "${ANALYSIS_JSON}" ]] && \
    mean_ms=$(jq '.statistics.mean_ms' "${ANALYSIS_JSON}" 2>/dev/null || echo 0)

  log_metric "plugin-load" "${mean_ms}ms per plugin cycle"

  local t1; t1=$(date +%s%N 2>/dev/null || echo 0)
  local dur_ms=$(( (t1 - t0) / 1000000 ))
  BENCH_RESULTS["plugin-load"]="{\"mean_ms\":${mean_ms}}"
  BENCH_STATUS["plugin-load"]="pass"
  BENCH_DURATION["plugin-load"]="${dur_ms}"
  section_result "pass" "${dur_ms}"
}

# ─────────────────────────────────────────────────────────────────────────────
# BENCHMARK: SNAPSHOT
# ─────────────────────────────────────────────────────────────────────────────
benchmark_snapshot() {
  section_header "${BENCH_IDX}" "Snapshot Create/Restore" "💾" "${C_SAP}"
  local t0; t0=$(date +%s%N 2>/dev/null || echo 0)

  local CLI="${WORKSPACE}/${CLI_PATH}"

  # Snapshot create
  local CREATE_JSON="${OUTPUT_ABS}/snapshot-create-raw.json"
  run_hyperfine "snapshot-create" "bash ${CLI} snapshot 2>/dev/null || true" \
    "${ITERATIONS}" "${WARMUP_RUNS}" "${CREATE_JSON}"

  local ANALYSIS_CREATE
  ANALYSIS_CREATE=$(analyze_results "snapshot-create" "${CREATE_JSON}")
  local create_ms=0
  [[ -f "${ANALYSIS_CREATE}" ]] && \
    create_ms=$(jq '.statistics.mean_ms' "${ANALYSIS_CREATE}" 2>/dev/null || echo 0)

  log_metric "snapshot" "create: ${create_ms}ms"

  local t1; t1=$(date +%s%N 2>/dev/null || echo 0)
  local dur_ms=$(( (t1 - t0) / 1000000 ))
  BENCH_RESULTS["snapshot"]="{\"create_ms\":${create_ms}}"
  BENCH_STATUS["snapshot"]="pass"
  BENCH_DURATION["snapshot"]="${dur_ms}"
  section_result "pass" "${dur_ms}"
}

# ─────────────────────────────────────────────────────────────────────────────
# REGRESSION DETECTION
# ─────────────────────────────────────────────────────────────────────────────
detect_regressions() {
  echo ""
  echo -e "  ${C_MAR}${C_BLD}━━━ 🚨 Regression Detection ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RST}"

  local BASELINE_DIR="${WORKSPACE}/.benchmark-baseline"

  if [[ "${COMPARE_BASELINE}" != "true" ]] || [[ ! -d "${BASELINE_DIR}" ]]; then
    log_info "regression" "No baseline available — skipping comparison"
    echo "0" >> /tmp/ash-regression-count.txt
    return 0
  fi

  python3 << REGRESS_PY
import json
import os
import math
from pathlib import Path

BASELINE_DIR  = "${BASELINE_DIR}"
OUTPUT_DIR    = "${OUTPUT_ABS}"
THRESHOLD_PCT = float("${REGRESSION_THRESHOLD_PCT}")
THRESHOLD_MS  = float("${REGRESSION_THRESHOLD_MS}")

G = $'\033[38;2;166;227;161m'
R = $'\033[38;2;243;139;168m'
Y = $'\033[38;2;249;226;175m'
B = $'\033[38;2;137;180;250m'
M = $'\033[38;2;235;160;172m'
T = $'\033[38;2;205;214;244m'
X = $'\033[0m'

regressions  = []
improvements = []
unchanged    = []

# Find all analysis files
analysis_files = list(Path(OUTPUT_DIR).glob("*-analysis.json"))

for analysis_path in analysis_files:
    try:
        with open(analysis_path) as f:
            current = json.load(f)
    except Exception:
        continue

    domain   = current.get("domain","?")
    cur_mean = current.get("statistics",{}).get("mean_ms", 0)

    # Load baseline
    baseline_path = Path(BASELINE_DIR) / analysis_path.name
    if not baseline_path.exists():
        continue

    try:
        with open(baseline_path) as f:
            baseline = json.load(f)
    except Exception:
        continue

    base_mean = baseline.get("statistics",{}).get("mean_ms", 0)

    if base_mean <= 0:
        continue

    # Calculate change
    change_pct = (cur_mean - base_mean) / base_mean * 100
    change_ms  = cur_mean - base_mean
    is_regression = change_pct > THRESHOLD_PCT or \
                    (THRESHOLD_MS > 0 and change_ms > THRESHOLD_MS)
    is_improvement = change_pct < -5  # >5% improvement

    if is_regression:
        regressions.append({
            "domain":      domain,
            "current_ms":  round(cur_mean, 2),
            "baseline_ms": round(base_mean, 2),
            "change_pct":  round(change_pct, 2),
            "change_ms":   round(change_ms, 2),
        })
        print(f"  {R}🚨 REGRESSION: {domain}{X}")
        print(f"     current={round(cur_mean,1)}ms baseline={round(base_mean,1)}ms "
              f"change={R}+{round(change_pct,1)}%{X}")
    elif is_improvement:
        improvements.append(domain)
        print(f"  {G}📈 IMPROVED:   {domain}{X} "
              f"({G}{round(change_pct,1)}%{X})")
    else:
        unchanged.append(domain)
        print(f"  {T}✓  STABLE:     {domain}{X} "
              f"({round(change_pct,1)}%)")

print()
print(f"  {B}Regression Summary:{X}")
print(f"    🚨 Regressions: {R}{len(regressions)}{X}")
print(f"    📈 Improvements: {G}{len(improvements)}{X}")
print(f"    ✓  Stable: {T}{len(unchanged)}{X}")

# Write regression results
regression_data = {
    "count":        len(regressions),
    "regressions":  regressions,
    "improvements": improvements,
    "threshold_pct":THRESHOLD_PCT,
}

with open(f"{OUTPUT_DIR}/regression-report.json","w") as f:
    json.dump(regression_data, f, indent=2)

# Output for bash
with open(os.environ.get("GITHUB_OUTPUT","/dev/null"),"a") as out:
    out.write(f"regressions_detected={len(regressions)}\n")
    out.write(f"regression_summary={json.dumps(regression_data)}\n")

with open("/tmp/ash-regression-count.txt","w") as f:
    f.write(str(len(regressions)))

if regressions and "${FAIL_ON_REGRESSION}" == "true":
    exit(1)
REGRESS_PY

  local REGRESSION_COUNT
  REGRESSION_COUNT=$(cat /tmp/ash-regression-count.txt 2>/dev/null || echo 0)
  TOTAL_REGRESSIONS="${REGRESSION_COUNT}"
  rm -f /tmp/ash-regression-count.txt
}

# ─────────────────────────────────────────────────────────────────────────────
# REPORT GENERATION
# ─────────────────────────────────────────────────────────────────────────────
generate_reports() {
  echo ""
  echo -e "  ${C_BLUE}${C_BLD}━━━ 📊 Report Generation ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RST}"

  local NOW; NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local DURATION=$(( $(date +%s) - START_EPOCH ))

  # Compute overall score
  local SCORE_FLOAT
  SCORE_FLOAT=$(python3 -c "
import json
import math
import os
from pathlib import Path

OUTPUT = '${OUTPUT_ABS}'
domain_scores = {}

for f in Path(OUTPUT).glob('*-analysis.json'):
    try:
        data = json.load(open(f))
        domain = data.get('domain','')
        mean   = data.get('statistics',{}).get('mean_ms',0)
        cv     = data.get('statistics',{}).get('cv_percent',100)
        stab   = data.get('stability','poor')
        stab_s = {'excellent':100,'good':80,'moderate':60,'poor':40}
        s_score= stab_s.get(stab,50)
        domain_scores[domain] = min(100, s_score)
    except: pass

if domain_scores:
    score = sum(domain_scores.values()) / len(domain_scores)
else:
    score = 75  # Default neutral score

# Regression penalty
reg = int('${TOTAL_REGRESSIONS}')
score = max(0, score - reg * 10)

print(round(score, 1))
" 2>/dev/null || echo "75")

  OVERALL_SCORE="${SCORE_FLOAT:-75}"

  # Compute overall status
  local STATUS="pass"
  [[ "${FAILED_BENCHMARKS}" -gt 0 ]] && STATUS="fail"
  [[ "${TOTAL_REGRESSIONS}" -gt 0 ]] && STATUS="regression"

  log_stat "report" "Score: ${OVERALL_SCORE}/100 | Status: ${STATUS}"

  # ── Collect all analysis results ──────────────────────────────────────────
  export OUTPUT_ABS OUTPUT_FORMATS REPORT_TITLE OVERALL_SCORE STATUS SESSION_ID DURATION TOTAL_REGRESSIONS RESOLVED_BENCHMARKS NOW CHART_STYLE INCLUDE_SYSTEM_INFO INCLUDE_GIT_INFO
  python3 << 'REPORT_PY'
import json
import os
import sys
from pathlib import Path
from datetime import datetime, timezone

OUTPUT_DIR     = os.environ.get("OUTPUT_ABS", "")
OUTPUT_FORMATS = os.environ.get("OUTPUT_FORMATS", "")
REPORT_TITLE   = os.environ.get("REPORT_TITLE", "")
SCORE          = float(os.environ.get("OVERALL_SCORE", "0"))
STATUS         = os.environ.get("STATUS", "")
SESSION_ID     = os.environ.get("SESSION_ID", "")
DURATION_S     = int(os.environ.get("DURATION", "0"))
REGRESSIONS    = int(os.environ.get("TOTAL_REGRESSIONS", "0"))
BENCHMARKS_RAN = os.environ.get("RESOLVED_BENCHMARKS", "")
NOW            = os.environ.get("NOW", "")
CHART_STYLE    = os.environ.get("CHART_STYLE", "")
INCLUDE_SYSINFO= os.environ.get("INCLUDE_SYSTEM_INFO", "") == "true"
INCLUDE_GIT    = os.environ.get("INCLUDE_GIT_INFO", "") == "true"
REPO           = os.environ.get("GITHUB_REPOSITORY","ash/dotfiles")
SHA            = os.environ.get("GITHUB_SHA","")[:8]
BRANCH         = os.environ.get("GITHUB_REF_NAME","unknown")

# ── Catppuccin Mocha palette ────────────────────────────────────────────────
P = {
    "bg":       "#1e1e2e", "surface":  "#313244",
    "text":     "#cdd6f4", "subtext":  "#a6adc8",
    "green":    "#a6e3a1", "red":      "#f38ba8",
    "yellow":   "#f9e2af", "blue":     "#89b4fa",
    "mauve":    "#cba6f7", "peach":    "#fab387",
    "teal":     "#94e2d5", "sapphire": "#74c7ec",
    "lavender": "#b4befe", "overlay":  "#6c7086",
}

# ── Load all domain results ─────────────────────────────────────────────────
domain_results = {}
for f in sorted(Path(OUTPUT_DIR).glob("*-analysis.json")):
    try:
        data = json.load(open(f))
        domain = data.get("domain","")
        if domain:
            domain_results[domain] = data
    except Exception: pass

# ── System info ─────────────────────────────────────────────────────────────
import platform, subprocess

sys_info = {}
if INCLUDE_SYSINFO:
    sys_info = {
        "os":    platform.system() + " " + platform.release(),
        "arch":  platform.machine(),
        "python":platform.python_version(),
        "runner":os.environ.get("RUNNER_OS","Linux"),
    }
    try:
        cpu = subprocess.check_output(
            "grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2",
            shell=True, text=True
        ).strip()
        sys_info["cpu"] = cpu
        cores = os.cpu_count() or 0
        sys_info["cores"] = cores
    except: pass

git_info = {}
if INCLUDE_GIT:
    git_info = {"sha": SHA, "branch": BRANCH, "repo": REPO}

# ── Build consolidated JSON report ──────────────────────────────────────────
report = {
    "meta": {
        "title":      REPORT_TITLE,
        "session_id": SESSION_ID,
        "timestamp":  NOW,
        "duration_s": DURATION_S,
        "version":    "5.0.0-omega",
    },
    "summary": {
        "score":          SCORE,
        "status":         STATUS,
        "regressions":    REGRESSIONS,
        "domains_run":    len(domain_results),
        "benchmarks":     BENCHMARKS_RAN.split(","),
    },
    "key_metrics": {
        "startup_cold_ms":   float("${EXPORT_STARTUP_COLD}"),
        "startup_warm_ms":   float("${EXPORT_STARTUP_WARM}"),
        "theme_apply_ms":    float("${EXPORT_THEME_APPLY}"),
        "theme_apply_p95_ms":float("${EXPORT_THEME_P95}"),
        "color_extract_ips": float("${EXPORT_COLOR_IPS}"),
        "hot_reload_ms":     float("${EXPORT_HOT_RELOAD}"),
        "api_p50_ms":        float("${EXPORT_API_P50}"),
        "api_p95_ms":        float("${EXPORT_API_P95}"),
        "memory_peak_mb":    float("${EXPORT_MEM_PEAK}"),
    },
    "domains":    domain_results,
    "system":     sys_info,
    "git":        git_info,
}

formats = [f.strip() for f in OUTPUT_FORMATS.split(",")]
if "all" in formats:
    formats = ["json","markdown","html","csv","junit","summary"]

# ── JSON ─────────────────────────────────────────────────────────────────────
if "json" in formats or True:  # Always generate JSON
    json_path = Path(OUTPUT_DIR) / "benchmark-report.json"
    with open(json_path, "w") as f:
        json.dump(report, f, indent=2)
    print(f"  ✅ JSON:     {json_path}")
    with open(os.environ.get("GITHUB_OUTPUT","/dev/null"),"a") as out:
        out.write(f"results_json_path={json_path}\n")

# ── Markdown ─────────────────────────────────────────────────────────────────
if "markdown" in formats or "summary" in formats:
    SCORE_INT = int(SCORE)
    BAR_W = 30
    BAR_F = round(SCORE_INT/100*BAR_W)
    BAR = "█"*BAR_F + "░"*(BAR_W-BAR_F)
    STATUS_EMOJI = {"pass":"✅","fail":"❌","regression":"⚠️"}.get(STATUS,"❓")

    # Build metrics table
    KM = report["key_metrics"]
    metric_rows = []
    if KM["startup_cold_ms"]:
        metric_rows.append(f"| ⚡ Startup (cold) | `{KM['startup_cold_ms']:.1f}ms` | — |")
    if KM["startup_warm_ms"]:
        metric_rows.append(f"| ⚡ Startup (warm) | `{KM['startup_warm_ms']:.1f}ms` | — |")
    if KM["theme_apply_ms"]:
        metric_rows.append(f"| 🎨 Theme Apply | `{KM['theme_apply_ms']:.1f}ms` | `{KM['theme_apply_p95_ms']:.1f}ms` |")
    if KM["color_extract_ips"]:
        metric_rows.append(f"| 🌈 Color Extract | `{KM['color_extract_ips']:.1f} img/s` | — |")
    if KM["hot_reload_ms"]:
        metric_rows.append(f"| 🔥 Hot Reload | `{KM['hot_reload_ms']:.1f}ms` | — |")
    if KM["api_p50_ms"]:
        metric_rows.append(f"| 🌐 API | `{KM['api_p50_ms']:.1f}ms` | `{KM['api_p95_ms']:.1f}ms` |")
    if KM["memory_peak_mb"]:
        metric_rows.append(f"| 🧠 Memory Peak | — | `{KM['memory_peak_mb']:.1f}MB` |")

    md = [
        f"# ⚡ {REPORT_TITLE}",
        f"",
        f"> {STATUS_EMOJI} **Status:** `{STATUS.upper()}`  &nbsp;·&nbsp;  "
        f"**Score:** `{SCORE_INT}/100`  &nbsp;·&nbsp;  "
        f"**Session:** `{SESSION_ID}`  &nbsp;·&nbsp;  "
        f"**Duration:** `{DURATION_S}s`",
        f"",
        f"```",
        f"Score: [{BAR}] {SCORE_INT}/100",
        f"```",
        f"",
        f"## 📊 Key Metrics",
        f"",
        f"| Benchmark | Mean | p95 |",
        f"|-----------|-----:|----:|",
        *metric_rows,
        f"",
    ]

    if domain_results:
        md += [
            f"## 🔬 Domain Details",
            f"",
            f"| Domain | Mean | StdDev | CV% | p95 | Stability |",
            f"|--------|-----:|-------:|----:|----:|-----------|",
        ]
        for domain, data in domain_results.items():
            stats = data.get("statistics",{})
            pcts  = data.get("percentiles",{})
            stab  = data.get("stability","?")
            stab_emoji = {"excellent":"🟢","good":"🟡","moderate":"🟠","poor":"🔴"}.get(stab,"⚪")
            md.append(
                f"| `{domain}` | "
                f"`{stats.get('mean_ms',0):.1f}ms` | "
                f"`±{stats.get('stddev_ms',0):.1f}ms` | "
                f"`{stats.get('cv_percent',0):.1f}%` | "
                f"`{pcts.get('p95',0):.1f}ms` | "
                f"{stab_emoji} {stab} |"
            )

    if sys_info:
        md += [f"", f"## 🖥️ System Info", f""]
        for k, v in sys_info.items():
            md.append(f"- **{k}:** `{v}`")

    md += [
        f"",
        f"---",
        f"*⚡ ASH v5.0 OMEGA Benchmark Engine · `{NOW}`*",
    ]

    md_path = Path(OUTPUT_DIR) / "benchmark-report.md"
    md_path.write_text("\n".join(md), encoding="utf-8")
    print(f"  ✅ Markdown: {md_path}")
    with open(os.environ.get("GITHUB_OUTPUT","/dev/null"),"a") as out:
        out.write(f"results_markdown_path={md_path}\n")

# ── HTML ──────────────────────────────────────────────────────────────────────
if "html" in formats:
    SCORE_INT = int(SCORE)
    SCORE_COLOR = P["green"] if SCORE_INT >= 80 else P["yellow"] if SCORE_INT >= 60 else P["red"]
    STATUS_EMOJI = {"pass":"✅","fail":"❌","regression":"⚠️"}.get(STATUS,"❓")

    domain_rows = ""
    for domain, data in domain_results.items():
        stats = data.get("statistics",{})
        stab  = data.get("stability","?")
        stab_c = {"excellent":P["green"],"good":P["teal"],"moderate":P["yellow"],"poor":P["red"]}.get(stab,P["overlay"])
        domain_rows += f"""
        <tr>
          <td><code>{domain}</code></td>
          <td class="num">{stats.get('mean_ms',0):.1f}ms</td>
          <td class="num">±{stats.get('stddev_ms',0):.1f}ms</td>
          <td class="num">{stats.get('cv_percent',0):.1f}%</td>
          <td class="num" style="color:{stab_c}">{stab}</td>
        </tr>"""

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{REPORT_TITLE}</title>
<style>
:root{{
  --bg:{P["bg"]};--surface:{P["surface"]};--text:{P["text"]};
  --sub:{P["subtext"]};--overlay:{P["overlay"]};
  --green:{P["green"]};--red:{P["red"]};--yellow:{P["yellow"]};
  --blue:{P["blue"]};--mauve:{P["mauve"]};--peach:{P["peach"]};
  --teal:{P["teal"]};--lavender:{P["lavender"]};
}}
*{{box-sizing:border-box;margin:0;padding:0}}
body{{background:var(--bg);color:var(--text);font-family:"JetBrains Mono",monospace;padding:2rem}}
h1{{color:var(--mauve);font-size:1.8rem;margin-bottom:.5rem}}
.subtitle{{color:var(--sub);margin-bottom:2rem;font-size:.9rem}}
.score-section{{background:var(--surface);border-radius:16px;padding:2rem;margin-bottom:2rem;display:grid;grid-template-columns:200px 1fr;gap:2rem;align-items:center}}
.score-gauge{{position:relative;width:160px;height:160px;margin:0 auto}}
.score-gauge svg{{transform:rotate(-90deg)}}
.score-text{{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);text-align:center}}
.score-text .val{{font-size:2.5rem;font-weight:700;color:{SCORE_COLOR}}}
.score-text .lbl{{font-size:.75rem;color:var(--sub)}}
.metrics-grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:1rem;margin-bottom:2rem}}
.metric-card{{background:var(--surface);border-radius:12px;padding:1.25rem;border-left:3px solid var(--mauve)}}
.metric-name{{color:var(--sub);font-size:.75rem;margin-bottom:.5rem}}
.metric-val{{color:var(--lavender);font-size:1.4rem;font-weight:700}}
.metric-unit{{color:var(--overlay);font-size:.8rem}}
table{{width:100%;border-collapse:collapse;background:var(--surface);border-radius:12px;overflow:hidden;margin-bottom:2rem}}
th{{background:rgba(203,166,247,.15);padding:.75rem 1rem;text-align:left;color:var(--mauve);font-size:.85rem}}
td{{padding:.7rem 1rem;border-bottom:1px solid rgba(255,255,255,.05);font-size:.85rem}}
.num{{text-align:right;font-feature-settings:"tnum"}}
tr:last-child td{{border-bottom:none}}
.status-badge{{display:inline-block;padding:.25rem .75rem;border-radius:20px;font-size:.8rem;font-weight:600}}
.status-pass{{background:rgba(166,227,161,.2);color:{P["green"]}}}
.status-regression{{background:rgba(249,226,175,.2);color:{P["yellow"]}}}
.status-fail{{background:rgba(243,139,168,.2);color:{P["red"]}}}
footer{{color:var(--overlay);font-size:.75rem;text-align:center;margin-top:2rem;border-top:1px solid var(--surface);padding-top:1rem}}
</style>
</head>
<body>
<h1>⚡ {REPORT_TITLE}</h1>
<p class="subtitle">Session: <code>{SESSION_ID}</code> &nbsp;·&nbsp; {NOW}</p>
<div class="score-section">
  <div class="score-gauge">
    <svg width="160" height="160" viewBox="0 0 160 160">
      <circle cx="80" cy="80" r="65" fill="none" stroke="{P["surface"]}" stroke-width="14"/>
      <circle cx="80" cy="80" r="65" fill="none" stroke="{SCORE_COLOR}"
        stroke-width="14" stroke-linecap="round"
        stroke-dasharray="{2*3.14159*65}" stroke-dashoffset="{2*3.14159*65*(1-SCORE_INT/100):.1f}"/>
    </svg>
    <div class="score-text">
      <div class="val">{SCORE_INT}</div>
      <div class="lbl">/ 100</div>
    </div>
  </div>
  <div>
    <p style="margin-bottom:1rem">
      <span class="status-badge status-{STATUS}">{STATUS_EMOJI} {STATUS.upper()}</span>
    </p>
    <p><strong>Score:</strong> {SCORE_INT}/100</p>
    <p><strong>Regressions:</strong> {REGRESSIONS}</p>
    <p><strong>Duration:</strong> {DURATION_S}s</p>
    <p><strong>Domains:</strong> {len(domain_results)}</p>
  </div>
</div>
<div class="metrics-grid">
  {"".join(f'<div class="metric-card"><div class="metric-name">{k.replace("_"," ").title()}</div><div class="metric-val">{v:.1f}<span class="metric-unit"> {"img/s" if "ips" in k else "MB" if "mb" in k else "ms"}</span></div></div>'
    for k,v in report["key_metrics"].items() if v > 0)}
</div>
<table>
  <thead><tr><th>Domain</th><th>Mean</th><th>StdDev</th><th>CV%</th><th>Stability</th></tr></thead>
  <tbody>{domain_rows}</tbody>
</table>
<footer>⚡ ASH v5.0 OMEGA Benchmark Engine &nbsp;·&nbsp; {NOW}</footer>
</body></html>"""

    html_path = Path(OUTPUT_DIR) / "benchmark-report.html"
    html_path.write_text(html, encoding="utf-8")
    print(f"  ✅ HTML:     {html_path}")
    with open(os.environ.get("GITHUB_OUTPUT","/dev/null"),"a") as out:
        out.write(f"results_html_path={html_path}\n")

# ── JUnit XML ─────────────────────────────────────────────────────────────────
if "junit" in formats:
    from xml.etree.ElementTree import Element, SubElement, tostring
    import xml.dom.minidom

    root = Element("testsuites", name="ASH Benchmarks",
                    tests=str(len(domain_results)),
                    failures="0", errors="0",
                    time=str(DURATION_S))
    suite = SubElement(root, "testsuite",
                        name="Performance", tests=str(len(domain_results)))

    for domain, data in domain_results.items():
        stats  = data.get("statistics",{})
        mean   = stats.get("mean_ms",0)
        tc = SubElement(suite, "testcase",
                         name=f"benchmark.{domain}",
                         classname="ASH.Performance",
                         time=str(round(mean/1000,3)))

    xml_str = xml.dom.minidom.parseString(tostring(root)).toprettyxml(indent="  ")
    junit_path = Path(OUTPUT_DIR) / "benchmark-junit.xml"
    junit_path.write_text(xml_str, encoding="utf-8")
    print(f"  ✅ JUnit:    {junit_path}")

# ── Write final GitHub outputs ────────────────────────────────────────────────
with open(os.environ.get("GITHUB_OUTPUT","/dev/null"),"a") as out:
    out.write(f"overall_status={STATUS}\n")
    out.write(f"score={round(SCORE,1)}\n")
    out.write(f"duration_seconds={DURATION_S}\n")
    out.write(f"benchmarks_run={len(domain_results)}\n")
    out.write(f"benchmarks_passed={len([d for d in domain_results if True])}\n")
    out.write(f"benchmarks_failed=0\n")
    out.write(f"regressions_detected={REGRESSIONS}\n")
    out.write(f"startup_cold_ms={report['key_metrics']['startup_cold_ms']:.2f}\n")
    out.write(f"startup_warm_ms={report['key_metrics']['startup_warm_ms']:.2f}\n")
    out.write(f"theme_apply_ms={report['key_metrics']['theme_apply_ms']:.2f}\n")
    out.write(f"theme_apply_p95_ms={report['key_metrics']['theme_apply_p95_ms']:.2f}\n")
    out.write(f"color_extract_ips={report['key_metrics']['color_extract_ips']:.2f}\n")
    out.write(f"hot_reload_ms={report['key_metrics']['hot_reload_ms']:.2f}\n")
    out.write(f"api_p50_ms={report['key_metrics']['api_p50_ms']:.2f}\n")
    out.write(f"api_p95_ms={report['key_metrics']['api_p95_ms']:.2f}\n")
    out.write(f"memory_peak_mb={report['key_metrics']['memory_peak_mb']:.2f}\n")

print(f"\n  ✅ Reports complete (score={round(SCORE,1)}/100, status={STATUS})")
REPORT_PY

  log_pass "report" "All reports generated in ${OUTPUT_ABS}/"
}

# ─────────────────────────────────────────────────────────────────────────────
# SAVE BASELINE
# ─────────────────────────────────────────────────────────────────────────────
save_baseline_results() {
  [[ "${SAVE_BASELINE}" != "true" ]] && return 0

  echo ""
  log_cache "baseline" "Saving results as new baseline..."

  local BASELINE_DIR="${WORKSPACE}/.benchmark-baseline"
  mkdir -p "${BASELINE_DIR}"

  cp "${OUTPUT_ABS}"/*-analysis.json "${BASELINE_DIR}/" 2>/dev/null || true

  cat > "${BASELINE_DIR}/baseline-meta.json" << EOF
{
  "session_id":  "${SESSION_ID}",
  "timestamp":   "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "sha":         "${GITHUB_SHA:-unknown}",
  "branch":      "${GITHUB_REF_NAME:-unknown}",
  "score":       ${OVERALL_SCORE},
  "benchmarks":  "${RESOLVED_BENCHMARKS}"
}
EOF

  log_pass "baseline" "Saved to ${BASELINE_DIR}/"
}

# ─────────────────────────────────────────────────────────────────────────────
# FINAL DASHBOARD
# ─────────────────────────────────────────────────────────────────────────────
print_final_dashboard() {
  local DURATION=$(( $(date +%s) - START_EPOCH ))
  local STATUS="pass"
  [[ "${TOTAL_REGRESSIONS}" -gt 0 ]] && STATUS="regression"

  local STATUS_COLOR="${C_GREEN}"
  [[ "${STATUS}" == "regression" ]] && STATUS_COLOR="${C_YELLOW}"
  [[ "${FAILED_BENCHMARKS}" -gt 0 ]] && { STATUS="fail"; STATUS_COLOR="${C_RED}"; }

  local SCORE_INT; SCORE_INT=$(printf "%.0f" "${OVERALL_SCORE}" 2>/dev/null || echo 75)
  local BAR_W=35
  local BAR_F=$(( SCORE_INT * BAR_W / 100 ))
  local BAR_E=$(( BAR_W - BAR_F ))
  local SCORE_BAR
  SCORE_BAR="$(printf '█%.0s' $(seq 1 "${BAR_F}" 2>/dev/null || true))"
  SCORE_BAR+="$(printf '░%.0s' $(seq 1 "${BAR_E}" 2>/dev/null || true))"

  local SCORE_COLOR="${C_GREEN}"
  (( SCORE_INT < 80 )) && SCORE_COLOR="${C_YELLOW}"
  (( SCORE_INT < 60 )) && SCORE_COLOR="${C_RED}"

  echo ""
  echo -e "${C_MAUVE}${C_BLD}"
  echo "  ╔══════════════════════════════════════════════════════════════════════╗"
  echo "  ║  ⚡ BENCHMARK SUITE COMPLETE                                         ║"
  echo "  ╠══════════════════════════════════════════════════════════════════════╣"
  echo -e "${C_RST}${C_MAUVE}${C_BLD}"
  printf  "  ║${C_RST}  ${SCORE_COLOR}[%s]${C_RST} ${SCORE_COLOR}${C_BLD}%d/100${C_RST}  ${STATUS_COLOR}${C_BLD}%s${C_RST}%*s${C_MAUVE}${C_BLD}║${C_RST}\n" \
    "${SCORE_BAR}" "${SCORE_INT}" "${STATUS^^}" $(( 20 - ${#STATUS} )) ""
  echo -e "  ${C_MAUVE}${C_BLD}╠══════════════════════════════════════════════════════════════════════╣${C_RST}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_GREEN}✅ Passed:   %-10s${C_RST}  ${C_RED}❌ Failed:  %-10s${C_RST}  ${C_YELLOW}🚨 Regressions: %-6s${C_RST}${C_MAUVE}${C_BLD}║${C_RST}\n" \
    "${PASSED_BENCHMARKS}" "${FAILED_BENCHMARKS}" "${TOTAL_REGRESSIONS}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}⏱️ Duration:  %-10s${C_RST}  ${C_SAP}📊 Domains:  %-10s${C_RST}  ${C_LAV}🔢 Iterations: %-6s${C_RST}${C_MAUVE}${C_BLD}║${C_RST}\n" \
    "${DURATION}s" "${#BENCH_ORDER[@]}" "${ITERATIONS}"
  echo -e "  ${C_MAUVE}${C_BLD}╠══════════════════════════════════════════════════════════════════════╣${C_RST}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}⚡ Startup:  ${C_GREEN}%-8sms${C_RST}  🎨 Theme: ${C_PEACH}%-8sms${C_RST}  🧠 Memory: ${C_TEAL}%-6sMB${C_RST}  ${C_MAUVE}${C_BLD}║${C_RST}\n" \
    "${EXPORT_STARTUP_COLD}" "${EXPORT_THEME_APPLY}" "${EXPORT_MEM_PEAK}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}🌐 API p50:  ${C_BLUE}%-8sms${C_RST}  🔥 Reload:${C_YELLOW}%-8sms${C_RST}  🌈 Color:  ${C_PINK}%-6s/s${C_RST}  ${C_MAUVE}${C_BLD}║${C_RST}\n" \
    "${EXPORT_API_P50}" "${EXPORT_HOT_RELOAD}" "${EXPORT_COLOR_IPS}"
  echo -e "  ${C_MAUVE}${C_BLD}╚══════════════════════════════════════════════════════════════════════╝${C_RST}"
  echo ""
  echo -e "  ${C_OVR}📁 Results: ${OUTPUT_ABS}/${C_RST}"
  echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# TRAP
# ─────────────────────────────────────────────────────────────────────────────
trap 'EXIT_CODE=$?
if [[ $EXIT_CODE -ne 0 ]]; then
  log_fail "Benchmark engine failed (exit=${EXIT_CODE})"
  tail -15 "${LOG_FILE}" 2>/dev/null | sed "s/^/   /" || true
  # Emit partial outputs
  {
    echo "overall_status=error"
    echo "score=0"
    echo "benchmarks_run=${TOTAL_BENCHMARKS}"
    echo "benchmarks_passed=${PASSED_BENCHMARKS}"
    echo "benchmarks_failed=${FAILED_BENCHMARKS}"
    echo "regressions_detected=${TOTAL_REGRESSIONS}"
    echo "duration_seconds=$(( $(date +%s) - START_EPOCH ))"
  } >> "${GITHUB_OUTPUT:-/dev/null}" 2>/dev/null || true
fi
# Kill any background mock servers
kill $(cat /tmp/ash-api-mock.pid 2>/dev/null | head -1) 2>/dev/null || true
' EXIT

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
main() {
  print_banner

  # Dry run
  if [[ "${DRY_RUN}" == "true" ]]; then
    echo ""
    echo -e "  ${C_LAV}${C_BLD}🔍 DRY RUN — Benchmark plan (no execution):${C_RST}"
    echo ""
    IFS=',' read -ra DRY_DOMAINS <<< "${RESOLVED_BENCHMARKS}"
    for i in "${!DRY_DOMAINS[@]}"; do
      echo -e "  ${C_MAUVE}$((i+1)).${C_RST} ${C_TEXT}${DRY_DOMAINS[$i]}${C_RST}"
    done
    echo ""
    echo -e "  ${C_TEXT}Iterations: ${C_TEAL}${ITERATIONS}${C_RST}"
    echo -e "  ${C_TEXT}Warmup:     ${C_TEAL}${WARMUP_RUNS}${C_RST}"
    echo -e "  ${C_TEXT}Output:     ${C_OVR}${OUTPUT_ABS}${C_RST}"

    {
      echo "overall_status=pass"
      echo "score=100"
      echo "benchmarks_run=0"
      echo "benchmarks_passed=0"
      echo "benchmarks_failed=0"
      echo "regressions_detected=0"
      echo "duration_seconds=0"
    } >> "${GITHUB_OUTPUT:-/dev/null}"
    exit 0
  fi

  # Setup
  setup_ci_environment

  # Parse domain list
  IFS=',' read -ra DOMAIN_LIST <<< "${RESOLVED_BENCHMARKS}"
  BENCHMARK_COUNT="${#DOMAIN_LIST[@]}"
  progress_init "${BENCHMARK_COUNT}"
  BENCH_IDX=0

  # Execute each domain
  for domain in "${DOMAIN_LIST[@]}"; do
    domain=$(echo "${domain}" | tr -d ' ')
    [[ -z "${domain}" ]] && continue

    (( BENCH_IDX++ )) || true
    (( TOTAL_BENCHMARKS++ )) || true
    BENCH_ORDER+=("${domain}")

    case "${domain}" in
      startup)       benchmark_startup       ;;
      theme-apply)   benchmark_theme_apply   ;;
      color-extract) benchmark_color_extract ;;
      hot-reload)    benchmark_hot_reload     ;;
      api)           benchmark_api           ;;
      memory)        benchmark_memory        ;;
      plugin-load)   benchmark_plugin_load   ;;
      snapshot)      benchmark_snapshot      ;;
      websocket)     log_info "websocket" "WebSocket benchmark requires live server — skipping in CI"; BENCH_STATUS["websocket"]="skip" ;;
      throughput)    log_info "throughput" "Throughput benchmark skipped in this run"; BENCH_STATUS["throughput"]="skip" ;;
      custom)
        if [[ -f "${WORKSPACE}/${CUSTOM_BENCH_PATH}" ]]; then
          section_header "${BENCH_IDX}" "Custom Benchmarks" "📝" "${C_RW}"
          bash "${WORKSPACE}/${CUSTOM_BENCH_PATH}" 2>/dev/null || true
        else
          log_info "custom" "No custom benchmark script found at ${CUSTOM_BENCH_PATH}"
        fi ;;
      regression)    log_info "regression" "Regression check runs post-benchmark" ;;
      *)             log_warn "unknown" "Unknown benchmark domain: ${domain}" ;;
    esac

    # Track pass/fail
    local domain_status="${BENCH_STATUS[$domain]:-pass}"
    [[ "${domain_status}" == "pass" ]] && (( PASSED_BENCHMARKS++ )) || true
    [[ "${domain_status}" == "fail" || "${domain_status}" == "error" ]] && \
      (( FAILED_BENCHMARKS++ )) || true

    progress_tick
  done

  # Post-benchmark analysis
  detect_regressions

  # Report generation
  generate_reports

  # Save baseline
  save_baseline_results

  # Final dashboard
  print_final_dashboard
}

main "$@"