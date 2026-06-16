#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                           ║
# ║  🔌 ASH DOTFILES v5.0 OMEGA — PLUGIN VALIDATION ENGINE                                   ║
# ║                                                                                           ║
# ║  ██████╗ ██╗     ██╗   ██╗ ██████╗ ██╗███╗   ██╗                                         ║
# ║  ██╔══██╗██║     ██║   ██║██╔════╝ ██║████╗  ██║                                         ║
# ║  ██████╔╝██║     ██║   ██║██║  ███╗██║██╔██╗ ██║                                         ║
# ║  ██╔═══╝ ██║     ██║   ██║██║   ██║██║██║╚██╗██║                                         ║
# ║  ██║     ███████╗╚██████╔╝╚██████╔╝██║██║ ╚████║                                         ║
# ║  ╚═╝     ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝  ╚═══╝                                         ║
# ║                                                                                           ║
# ║  ██╗   ██╗ █████╗ ██╗     ██╗██████╗  █████╗ ████████╗ ██████╗ ██████╗                   ║
# ║  ██║   ██║██╔══██╗██║     ██║██╔══██╗██╔══██╗╚══██╔══╝██╔═══██╗██╔══██╗                  ║
# ║  ██║   ██║███████║██║     ██║██║  ██║███████║   ██║   ██║   ██║██████╔╝                  ║
# ║  ╚██╗ ██╔╝██╔══██║██║     ██║██║  ██║██╔══██║   ██║   ██║   ██║██╔══██╗                  ║
# ║   ╚████╔╝ ██║  ██║███████╗██║██████╔╝██║  ██║   ██║   ╚██████╔╝██║  ██║                  ║
# ║    ╚═══╝  ╚═╝  ╚═╝╚══════╝╚═╝╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝                  ║
# ║                                                                                           ║
# ║  Version:    5.0.0-omega                                                                 ║
# ║  Pipeline:   manifest → structure → shellcheck → security → api →                       ║
# ║              deps → tests → docs → naming → lifecycle → performance                     ║
# ║                                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────
readonly VALIDATOR_VERSION="5.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly START_NS=$(date +%s%N)

# ─────────────────────────────────────────────────────────────────────────────
# ENVIRONMENT VARIABLES (from action.yml env block)
# ─────────────────────────────────────────────────────────────────────────────
PLUGIN_DIR="${PLUGIN_DIR:?PLUGIN_DIR is required}"
PLUGIN_NAME="${PLUGIN_NAME:-$(basename "${PLUGIN_DIR}")}"
WORK_DIR="${WORK_DIR:-/tmp/.plugin-validator}"
VALIDATION_LEVEL="${VALIDATION_LEVEL:-standard}"
RUN_SHELLCHECK="${RUN_SHELLCHECK:-true}"
SC_SEVERITY="${SC_SEVERITY:-warning}"
FAIL_ON_SC="${FAIL_ON_SC:-true}"
SECURITY_SCAN="${SECURITY_SCAN:-true}"
FAIL_ON_SECURITY="${FAIL_ON_SECURITY:-true}"
ALLOWED_CMDS="${ALLOWED_CMDS:-}"
REQUIRED_SCRIPTS="${REQUIRED_SCRIPTS:-init.sh,enable.sh,disable.sh,status.sh}"
CHECK_API="${CHECK_API:-true}"
REQUIRED_FUNCTIONS="${REQUIRED_FUNCTIONS:-ash_plugin_init,ash_plugin_info,ash_plugin_help}"
CHECK_LIFECYCLE="${CHECK_LIFECYCLE:-true}"
REQUIRED_META="${REQUIRED_META:-name,version,author,category,description,license}"
VALID_CATEGORIES="${VALID_CATEGORIES:-core,integration,theme,performance,accessibility,gaming,productivity,media,system,network,security,developer}"
ENFORCE_SEMVER="${ENFORCE_SEMVER:-true}"
CHECK_DEPS="${CHECK_DEPS:-true}"
FAIL_ON_DEPS="${FAIL_ON_DEPS:-false}"
CHECK_TESTS="${CHECK_TESTS:-true}"
MIN_TESTS="${MIN_TESTS:-1}"
CHECK_DOCS="${CHECK_DOCS:-true}"
MIN_README_LINES="${MIN_README_LINES:-20}"
MAX_SCRIPT_LINES="${MAX_SCRIPT_LINES:-500}"
MAX_SIZE_KB="${MAX_SIZE_KB:-5120}"
MINIMUM_SCORE="${MINIMUM_SCORE:-65}"
VERBOSE="${VERBOSE:-false}"

# ─────────────────────────────────────────────────────────────────────────────
# CATPPUCCIN MOCHA ANSI PALETTE
# ─────────────────────────────────────────────────────────────────────────────
C_R='\033[0m'        C_B='\033[1m'        C_D='\033[2m'
C_MAUVE='\033[38;2;203;166;247m'   C_BLUE='\033[38;2;137;180;250m'
C_GREEN='\033[38;2;166;227;161m'   C_RED='\033[38;2;243;139;168m'
C_YELLOW='\033[38;2;249;226;175m'  C_PEACH='\033[38;2;250;179;135m'
C_TEAL='\033[38;2;148;226;213m'    C_SAP='\033[38;2;116;199;236m'
C_SKY='\033[38;2;137;220;235m'     C_PINK='\033[38;2;245;194;231m'
C_LAV='\033[38;2;180;190;254m'     C_TEXT='\033[38;2;205;214;244m'
C_SUB='\033[38;2;166;173;200m'     C_OVR='\033[38;2;108;112;134m'
C_MAR='\033[38;2;235;160;172m'     C_RW='\033[38;2;245;224;220m'

# ─────────────────────────────────────────────────────────────────────────────
# LOGGING ENGINE
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p "${WORK_DIR}"
readonly LOG_FILE="${WORK_DIR}/validate.log"

_log() {
  local icon="$1" color="$2"; shift 2
  local ts; ts=$(date +%H:%M:%S)
  echo -e "${color}${icon}${C_R} ${C_D}[${ts}]${C_R} ${C_TEXT}$*${C_R}"
  echo "[${ts}] ${icon} $*" >> "${LOG_FILE}"
}

log_pass()    { _log "✅" "${C_GREEN}"   "$@"; }
log_fail()    { _log "❌" "${C_RED}"     "$@"; }
log_warn()    { _log "⚠️ " "${C_YELLOW}"  "$@"; }
log_info()    { _log "ℹ️ " "${C_BLUE}"    "$@"; }
log_check()   { _log "🔍" "${C_MAUVE}"   "$@"; }
log_section() { _log "🔌" "${C_SAP}"     "$@"; }
log_score()   { _log "📊" "${C_LAV}"     "$@"; }
log_debug()   { [[ "${VERBOSE}" == "true" ]] && _log "🔎" "${C_OVR}" "$@" || true; }
log_shell()   { _log "🐚" "${C_TEAL}"    "$@"; }
log_sec()     { _log "🔐" "${C_MAR}"     "$@"; }

section_header() {
  local num="$1" title="$2" color="${3:-${C_SAP}}"
  echo ""
  echo -e "  ${color}${C_B}━━━ Check ${num}: ${title} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_R}"
}

# ─────────────────────────────────────────────────────────────────────────────
# VALIDATION STATE
# ─────────────────────────────────────────────────────────────────────────────
declare -a ERRORS=()
declare -a WARNINGS=()

# Score components
SC_MANIFEST=0
SC_STRUCTURE=0
SC_SHELLCHECK=0
SC_SECURITY=0
SC_API=0
SC_DEPS=0
SC_TESTS=0
SC_DOCS=0
SC_NAMING=0
SC_LIFECYCLE=0
SC_PERFORMANCE=0

# Pass/fail flags
FL_MANIFEST="false"
FL_STRUCTURE="false"
FL_SHELLCHECK="false"
FL_SECURITY="false"
FL_API="false"
FL_DEPS="false"
FL_TESTS="false"
FL_DOCS="false"
FL_NAMING="false"
FL_LIFECYCLE="false"

# Plugin metadata
P_NAME="${PLUGIN_NAME}"
P_VERSION="0.0.0"
P_CATEGORY="unknown"
P_AUTHOR="unknown"
P_DESCRIPTION=""
P_LICENSE="unknown"

# Counters
SC_ERR_COUNT=0
SC_WARN_COUNT=0
SEC_THREAT_COUNT=0
TEST_COUNT=0

add_error()   { ERRORS+=("$*");   log_fail   "$*"; }
add_warning() { WARNINGS+=("$*"); log_warn   "$*"; }
add_pass()    { log_pass "$*"; }

# ─────────────────────────────────────────────────────────────────────────────
# BANNER
# ─────────────────────────────────────────────────────────────────────────────
print_banner() {
  echo ""
  echo -e "${C_BLUE}${C_B}"
  cat << 'BANNER'
  ╔══════════════════════════════════════════════════════════════════╗
  ║  🔌 ASH Plugin Validation Engine v5.0.0-omega                    ║
  ╚══════════════════════════════════════════════════════════════════╝
BANNER
  echo -e "${C_R}"
  echo -e "  ${C_TEXT}Plugin:  ${C_BLUE}${C_B}${PLUGIN_NAME}${C_R}"
  echo -e "  ${C_TEXT}Dir:     ${C_OVR}${PLUGIN_DIR}${C_R}"
  echo -e "  ${C_TEXT}Level:   ${C_MAUVE}${VALIDATION_LEVEL}${C_R}"
  echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 1 — Manifest Schema (plugin.json)
# ─────────────────────────────────────────────────────────────────────────────
check_manifest() {
  section_header "1" "Manifest Schema (plugin.json)" "${C_SAP}"

  local MANIFEST="${PLUGIN_DIR}/plugin.json"
  local score=100

  if [[ ! -f "${MANIFEST}" ]]; then
    add_error "plugin.json not found — this is the core manifest file"
    SC_MANIFEST=0
    FL_MANIFEST="false"
    return
  fi

  # JSON syntax check
  if ! jq empty "${MANIFEST}" 2>/dev/null; then
    add_error "plugin.json contains invalid JSON syntax"
    SC_MANIFEST=0
    FL_MANIFEST="false"
    return
  fi

  add_pass "plugin.json: valid JSON syntax"

  # Run Python schema validator
  python3 << PYEOF
import json
import re
import os
import sys
from pathlib import Path

MANIFEST_FILE  = "${MANIFEST}"
WORK_DIR       = "${WORK_DIR}"
REQUIRED_META  = "${REQUIRED_META}".split(",")
VALID_CATS     = "${VALID_CATEGORIES}".split(",")
ENFORCE_SEMVER = "${ENFORCE_SEMVER}" == "true"

# ANSI
G = "\033[38;2;166;227;161m"
R = "\033[38;2;243;139;168m"
Y = "\033[38;2;249;226;175m"
B = "\033[38;2;137;180;250m"
M = "\033[38;2;203;166;247m"
T = "\033[38;2;205;214;244m"
S = "\033[38;2;166;173;200m"
X = "\033[0m"

def p(ic, c, msg): print(f"  {c}{ic}{X} {T}{msg}{X}")

errors   = []
warnings = []
score    = 100

with open(MANIFEST_FILE) as f:
    manifest = json.load(f)

# ── Required fields ──────────────────────────────────────────────────────────
p("📋", B, "Checking required fields...")
missing = []
for field in REQUIRED_META:
    field = field.strip()
    val   = manifest.get(field)
    if not val or str(val).strip() in ("", "null", "undefined"):
        missing.append(field)
        p("❌", R, f"Missing required field: {field}")
        score -= 12
    else:
        p("✅", G, f"{field}: {str(val)[:60]}")

if missing:
    errors.append(f"Missing required fields: {', '.join(missing)}")

# ── Version format ────────────────────────────────────────────────────────────
version = manifest.get("version","0.0.0")
if ENFORCE_SEMVER:
    SEMVER = re.compile(r'^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?(\+[a-zA-Z0-9.]+)?$')
    if SEMVER.match(str(version)):
        p("✅", G, f"Version semver valid: {version}")
    else:
        errors.append(f"Version not semver: '{version}' (expected X.Y.Z)")
        p("❌", R, f"Version not semver: '{version}'")
        score -= 8

# ── Category validation ───────────────────────────────────────────────────────
category = manifest.get("category","")
VALID_CATS_CLEAN = [c.strip() for c in VALID_CATS]
if category in VALID_CATS_CLEAN:
    p("✅", G, f"Category valid: {category}")
else:
    errors.append(f"Invalid category: '{category}'. Valid: {VALID_CATS_CLEAN}")
    p("❌", R, f"Invalid category: '{category}'")
    score -= 10

# ── Dependencies field ────────────────────────────────────────────────────────
deps = manifest.get("dependencies", [])
if isinstance(deps, list):
    p("✅", G, f"Dependencies: {len(deps)} declared")
    for dep in deps[:10]:
        p("  ℹ️", S, f"dep: {dep}")
else:
    warnings.append("dependencies field should be an array")
    score -= 3

# ── Hooks field ───────────────────────────────────────────────────────────────
hooks = manifest.get("hooks", {})
if isinstance(hooks, dict) and hooks:
    p("✅", G, f"Hooks defined: {list(hooks.keys())[:5]}")
elif isinstance(hooks, list):
    warnings.append("hooks should be an object not array")
    score -= 2

# ── Permissions field ─────────────────────────────────────────────────────────
perms = manifest.get("permissions", [])
if isinstance(perms, list):
    DANGEROUS_PERMS = {"root","sudo","network-unrestricted","filesystem-all"}
    dangerous = [p for p in perms if p in DANGEROUS_PERMS]
    if dangerous:
        warnings.append(f"Dangerous permissions requested: {dangerous}")
        p("⚠️ ", Y, f"Dangerous permissions: {dangerous}")
        score -= 5
    elif perms:
        p("✅", G, f"Permissions: {perms[:5]}")

# ── Config schema ─────────────────────────────────────────────────────────────
config_schema = manifest.get("config_schema", {})
if config_schema:
    p("✅", G, "Config schema defined")
    score += 3

# ── Tags ──────────────────────────────────────────────────────────────────────
tags = manifest.get("tags", [])
if isinstance(tags, list) and tags:
    p("✅", G, f"Tags: {tags[:5]}")
    score += 2
else:
    warnings.append("tags array is empty or missing (recommended)")

# ── Finalize ──────────────────────────────────────────────────────────────────
score = max(0, min(100, score))
passed = len(errors) == 0

result = {
    "passed":    passed,
    "score":     score,
    "errors":    errors,
    "warnings":  warnings,
    "metadata": {
        "name":        manifest.get("name",     PLUGIN_NAME   if True else ""),
        "version":     manifest.get("version",  "0.0.0"),
        "category":    manifest.get("category", "unknown"),
        "author":      manifest.get("author",   "unknown"),
        "description": manifest.get("description",""),
        "license":     manifest.get("license",  "unknown"),
    }
}

Path(WORK_DIR).mkdir(parents=True, exist_ok=True)
with open(f"{WORK_DIR}/manifest-result.json","w") as f:
    json.dump(result, f, indent=2)

with open(os.environ.get("GITHUB_OUTPUT","/dev/null"),"a") as out:
    out.write(f"manifest_passed={'true' if passed else 'false'}\n")
    out.write(f"manifest_score={score}\n")

icon = "✅" if passed else "❌"
col  = G if passed else R
print(f"\n  {col}{icon} Manifest: {'PASSED' if passed else 'FAILED'} (score={score}/100){X}")
PYEOF

  # Load results
  if [[ -f "${WORK_DIR}/manifest-result.json" ]]; then
    SC_MANIFEST=$(jq '.score'         "${WORK_DIR}/manifest-result.json" 2>/dev/null || echo 0)
    FL_MANIFEST=$(jq -r '.passed'     "${WORK_DIR}/manifest-result.json" 2>/dev/null || echo "false")
    P_NAME=$(jq -r '.metadata.name'       "${WORK_DIR}/manifest-result.json" 2>/dev/null || echo "${PLUGIN_NAME}")
    P_VERSION=$(jq -r '.metadata.version' "${WORK_DIR}/manifest-result.json" 2>/dev/null || echo "0.0.0")
    P_CATEGORY=$(jq -r '.metadata.category' "${WORK_DIR}/manifest-result.json" 2>/dev/null || echo "unknown")
    P_AUTHOR=$(jq -r '.metadata.author'   "${WORK_DIR}/manifest-result.json" 2>/dev/null || echo "unknown")

    while IFS= read -r err; do [[ -n "${err}" ]] && ERRORS+=("manifest: ${err}"); done < \
      <(jq -r '.errors[]' "${WORK_DIR}/manifest-result.json" 2>/dev/null || true)
    while IFS= read -r wrn; do [[ -n "${wrn}" ]] && WARNINGS+=("manifest: ${wrn}"); done < \
      <(jq -r '.warnings[]' "${WORK_DIR}/manifest-result.json" 2>/dev/null || true)
  fi

  log_score "Manifest score: ${SC_MANIFEST}/100"
}

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 2 — File Structure
# ─────────────────────────────────────────────────────────────────────────────
check_structure() {
  section_header "2" "File Structure & Lifecycle Scripts" "${C_SAP}"

  local score=100
  local all_present=true

  # Parse required scripts
  IFS=',' read -ra REQ_SCRIPTS <<< "${REQUIRED_SCRIPTS}"

  echo "  📋 Required lifecycle scripts:"
  for script in "${REQ_SCRIPTS[@]}"; do
    script=$(echo "${script}" | tr -d ' ')
    local full_path="${PLUGIN_DIR}/${script}"
    if [[ -f "${full_path}" ]]; then
      local lines; lines=$(wc -l < "${full_path}" 2>/dev/null || echo 0)
      local is_exec; is_exec=$(test -x "${full_path}" && echo "✓" || echo "✗")
      add_pass "${script} — ${lines} lines, executable: ${is_exec}"

      # Check shebang
      local first_line; first_line=$(head -1 "${full_path}" 2>/dev/null || echo "")
      if ! echo "${first_line}" | grep -qE '^#!.*/(bash|sh|env bash|env sh)'; then
        add_warning "${script}: missing or invalid shebang (found: '${first_line:0:30}')"
        score=$((score - 5))
      fi

      # Check executable bit
      if [[ ! -x "${full_path}" ]]; then
        add_warning "${script}: not executable (chmod +x recommended)"
        score=$((score - 3))
      fi
    else
      add_error "Missing required script: ${script}"
      score=$((score - 20))
      all_present=false
    fi
  done

  # Optional but recommended files
  echo ""
  echo "  📁 Optional files:"
  declare -A OPTIONAL_FILES=(
    ["README.md"]="Documentation"
    ["config.json"]="Plugin configuration schema"
    ["tests/test-main.sh"]="Test suite"
    ["CHANGELOG.md"]="Change history"
    ["LICENSE"]="License file"
  )

  for file in "${!OPTIONAL_FILES[@]}"; do
    if [[ -f "${PLUGIN_DIR}/${file}" ]]; then
      log_debug "Optional present: ${file}"
      score=$((score + 2))
    fi
  done

  # Detect unexpected files
  local total_files; total_files=$(find "${PLUGIN_DIR}" -type f 2>/dev/null | wc -l)
  log_debug "Total files in plugin: ${total_files}"

  SC_STRUCTURE=$(( score < 0 ? 0 : score > 100 ? 100 : score ))
  [[ "${all_present}" == "true" ]] && FL_STRUCTURE="true" || FL_STRUCTURE="false"

  log_score "Structure score: ${SC_STRUCTURE}/100"
}

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 3 — ShellCheck Linting
# ─────────────────────────────────────────────────────────────────────────────
check_shellcheck() {
  section_header "3" "ShellCheck Lint Analysis" "${C_TEAL}"

  [[ "${RUN_SHELLCHECK}" != "true" ]] && {
    log_info "ShellCheck disabled — skipping"
    SC_SHELLCHECK=85
    FL_SHELLCHECK="true"
    return
  }

  if ! command -v shellcheck &>/dev/null; then
    add_warning "shellcheck not available — install shellcheck for linting"
    SC_SHELLCHECK=70
    FL_SHELLCHECK="true"
    return
  fi

  local SC_VER; SC_VER=$(shellcheck --version 2>/dev/null | grep "version:" | head -1 || echo "?")
  log_shell "ShellCheck ${SC_VER}"

  local score=100
  local total_errors=0
  local total_warnings=0
  local total_info=0
  local files_checked=0
  local files_clean=0

  # Find all shell scripts
  mapfile -t SHELL_FILES < <(
    find "${PLUGIN_DIR}" \
      \( -name "*.sh" -o -name "*.bash" \) \
      -not -path "*/node_modules/*" \
      -not -path "*/.git/*" \
      2>/dev/null | sort
  )

  echo "  🐚 Checking ${#SHELL_FILES[@]} shell script(s)..."

  for script in "${SHELL_FILES[@]}"; do
    local fname; fname=$(basename "${script}")
    local rel_path; rel_path="${script#${PLUGIN_DIR}/}"
    ((files_checked++))

    # Run ShellCheck with JSON output
    local SC_OUTPUT
    SC_OUTPUT=$(shellcheck \
      --format=json \
      --severity="${SC_SEVERITY}" \
      --shell=bash \
      "${script}" 2>/dev/null || true)

    local file_errors=0
    local file_warns=0
    local file_info=0

    if [[ -n "${SC_OUTPUT}" && "${SC_OUTPUT}" != "[]" && "${SC_OUTPUT}" != "null" ]]; then
      file_errors=$(echo "${SC_OUTPUT}" | jq '[.[] | select(.level=="error")]   | length' 2>/dev/null || echo 0)
      file_warns=$(echo "${SC_OUTPUT}"  | jq '[.[] | select(.level=="warning")] | length' 2>/dev/null || echo 0)
      file_info=$(echo "${SC_OUTPUT}"   | jq '[.[] | select(.level=="info")]    | length' 2>/dev/null || echo 0)
    fi

    total_errors=$((total_errors + file_errors))
    total_warnings=$((total_warnings + file_warns))
    total_info=$((total_info + file_info))

    if [[ "${file_errors}" -eq 0 && "${file_warns}" -eq 0 ]]; then
      add_pass "${rel_path}: clean ✨"
      ((files_clean++))
    else
      if [[ "${file_errors}" -gt 0 ]]; then
        log_fail "${rel_path}: ${file_errors} error(s), ${file_warns} warning(s)"
        ERRORS+=("ShellCheck: ${rel_path} — ${file_errors} error(s), ${file_warns} warning(s)")
      else
        add_warning "${rel_path}: ${file_warns} warning(s)"
        WARNINGS+=("ShellCheck: ${rel_path} — ${file_warns} warning(s)")
      fi

      # Show top issues
      if [[ -n "${SC_OUTPUT}" && "${SC_OUTPUT}" != "[]" ]]; then
        echo "${SC_OUTPUT}" | python3 << 'SC_DISPLAY_EOF'
import json
import sys

data = json.load(sys.stdin) if sys.stdin else []

RED    = "\033[38;2;243;139;168m"
YELLOW = "\033[38;2;249;226;175m"
BLUE   = "\033[38;2;137;180;250m"
TEXT   = "\033[38;2;205;214;244m"
SUB    = "\033[38;2;166;173;200m"
RST    = "\033[0m"

for issue in data[:5]:
    level = issue.get("level","?")
    code  = issue.get("code",0)
    msg   = issue.get("message","")[:70]
    line  = issue.get("line",0)
    col   = issue.get("column",0)
    color = RED if level == "error" else YELLOW if level == "warning" else BLUE
    print(f"     {color}SC{code}{RST} {SUB}L{line}:{col}{RST} {TEXT}{msg}{RST}")
SC_DISPLAY_EOF
      fi
    fi

    # Save detailed output
    if [[ -n "${SC_OUTPUT}" ]]; then
      echo "${SC_OUTPUT}" > "${WORK_DIR}/shellcheck-${fname}.json" 2>/dev/null || true
    fi
  done

  SC_ERR_COUNT="${total_errors}"
  SC_WARN_COUNT="${total_warnings}"

  # Score calculation
  if [[ "${files_checked}" -eq 0 ]]; then
    score=80    # No scripts — neutral
    add_warning "No shell scripts found to check"
  else
    score=$(( 100 - (total_errors * 15) - (total_warnings * 5) - (total_info * 1) ))
    score=$(( score < 0 ? 0 : score > 100 ? 100 : score ))
  fi

  SC_SHELLCHECK="${score}"

  # Pass/fail determination
  if [[ "${FAIL_ON_SC}" == "true" ]]; then
    [[ "${total_errors}" -eq 0 ]] && FL_SHELLCHECK="true" || FL_SHELLCHECK="false"
  else
    FL_SHELLCHECK="true"
  fi

  echo ""
  echo -e "  ${C_TEAL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_R}"
  printf  "  ${C_TEXT}Files: %d checked · %d clean · ❌ %d errors · ⚠️  %d warnings\n${C_R}" \
    "${files_checked}" "${files_clean}" "${total_errors}" "${total_warnings}"
  echo -e "  ${C_TEAL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_R}"

  log_score "ShellCheck score: ${SC_SHELLCHECK}/100"
}

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 4 — Security Scan
# ─────────────────────────────────────────────────────────────────────────────
check_security() {
  section_header "4" "Security Threat Analysis" "${C_MAR}"

  [[ "${SECURITY_SCAN}" != "true" ]] && {
    log_info "Security scan disabled"
    SC_SECURITY=100
    FL_SECURITY="true"
    return
  }

  local score=100
  local threat_count=0
  local security_passed=true

  # Parse allowed commands
  declare -A ALLOWED_MAP=()
  IFS=',' read -ra ALLOWED_ARR <<< "${ALLOWED_CMDS}"
  for cmd in "${ALLOWED_ARR[@]}"; do
    cmd=$(echo "${cmd}" | tr -d ' ')
    [[ -n "${cmd}" ]] && ALLOWED_MAP["${cmd}"]=1
  done

  # ── Threat pattern definitions ─────────────────────────────────────────────
  python3 << 'SEC_EOF'
import re
import os
import json
from pathlib import Path

PLUGIN_DIR = "${PLUGIN_DIR}"
WORK_DIR   = "${WORK_DIR}"
ALLOWED    = set("${ALLOWED_CMDS}".split(",")) if "${ALLOWED_CMDS}" else set()

# ANSI
R = "\033[38;2;243;139;168m"
Y = "\033[38;2;249;226;175m"
G = "\033[38;2;166;227;161m"
B = "\033[38;2;137;180;250m"
T = "\033[38;2;205;214;244m"
S = "\033[38;2;166;173;200m"
M = "\033[38;2;235;160;172m"
X = "\033[0m"

THREATS = {
    # Critical
    "CMD_INJECTION_EVAL":      (r'\beval\s+\$|\beval\s+`',                   "critical", "eval with variable — RCE risk"),
    "CMD_INJECTION_EXEC":      (r'\bexec\s+\$|\bexec\s+`',                   "critical", "exec with variable — RCE risk"),
    "CURL_PIPE_SHELL":         (r'curl\s+[^|]*\|\s*(bash|sh)',               "critical", "curl piped to shell — supply chain attack"),
    "WGET_PIPE_SHELL":         (r'wget\s+[^|]*-O\s*-[^|]*\|\s*(bash|sh)',   "critical", "wget piped to shell"),
    "RM_RF_ROOT":              (r'rm\s+-[rRf]{1,3}\s+/\s*$|rm\s+-[rRf]{1,3}\s+/[^/]', "critical", "rm -rf on root/critical path"),

    # High
    "WORLD_WRITABLE_CHMOD":    (r'chmod\s+(777|a\+w|o\+w)',                  "high",     "world-writable file permission"),
    "HARDCODED_PASSWORD":      (r'(?i)(password|passwd|secret|token|key)\s*=\s*["\'][^"\']{4,}["\']', "high", "potential hardcoded credential"),
    "SUDO_NOPASSWD":           (r'NOPASSWD|sudo\s+-n\s',                     "high",     "passwordless sudo usage"),
    "PATH_TRAVERSAL":          (r'\.\.\/\.\.\/\.\.',                          "high",     "deep path traversal"),
    "INSECURE_CURL":           (r'curl\s+.*(-k|--insecure)',                  "high",     "TLS verification disabled"),

    # Medium
    "PREDICTABLE_TMPFILE":     (r'/tmp/[a-zA-Z_]+[^/\$]*$',                 "medium",   "predictable temp file (use mktemp)"),
    "UNQUOTED_VARIABLE":       (r'\$\w+\s+[|&;>]',                           "medium",   "potentially unquoted variable in command"),
    "HISTORY_LEAK":            (r'set\s+-o\s+history|HISTFILE\s*=\s*/dev/null', "medium", "shell history manipulation"),
    "NETWORK_BACKDOOR":        (r'nc\s+.*-l|netcat\s+.*-l|socat\s+.*LISTEN', "medium",   "network listener opened"),

    # Low
    "DEBUGGER_LEFT_IN":        (r'\bset\s+-x\b|\bxtrace\b',                  "low",      "debug mode (xtrace) left enabled"),
    "TODO_SECURITY":           (r'(?i)#\s*(todo|fixme|hack|xxx)\s*:?\s*(security|auth|cred|pass)', "low", "security TODO comment"),
}

findings     = []
total_threats= 0
CRITICAL_COUNT = 0

print(f"  {B}🔐 Scanning {len(list(Path(PLUGIN_DIR).rglob('*.sh')))} shell scripts...{X}")

SCAN_EXTS = {".sh", ".bash", ".fish", ".json", ".conf"}
for file_path in Path(PLUGIN_DIR).rglob("*"):
    if not file_path.is_file():
        continue
    if file_path.suffix not in SCAN_EXTS:
        continue
    if ".git" in file_path.parts:
        continue

    try:
        content  = file_path.read_text(errors="ignore")
        rel_path = str(file_path.relative_to(PLUGIN_DIR))
    except Exception:
        continue

    for rule_id, (pattern, severity, description) in THREATS.items():
        try:
            matches = re.findall(pattern, content, re.MULTILINE)
            if not matches:
                continue

            # Find line numbers
            for i, line in enumerate(content.splitlines(), 1):
                if re.search(pattern, line, re.MULTILINE):
                    finding = {
                        "rule":       rule_id,
                        "severity":   severity,
                        "description":description,
                        "file":       rel_path,
                        "line":       i,
                        "snippet":    line.strip()[:80],
                    }
                    findings.append(finding)
                    total_threats += 1
                    if severity == "critical":
                        CRITICAL_COUNT += 1

                    sev_color = R if severity == "critical" else \
                               M if severity == "high" else \
                               Y if severity == "medium" else S
                    print(
                        f"  {sev_color}[{severity.upper():<8}]{X} {T}{rule_id}{X}\n"
                        f"           {S}{rel_path}:{i}{X} — {T}{description}{X}"
                    )
                    break  # One finding per rule per file
        except re.error:
            continue

if total_threats == 0:
    print(f"  {G}✅ No security threats detected{X}")

result = {
    "passed":         total_threats == 0 or CRITICAL_COUNT == 0,
    "threat_count":   total_threats,
    "critical_count": CRITICAL_COUNT,
    "findings":       findings[:50],
}

Path(WORK_DIR).mkdir(parents=True, exist_ok=True)
with open(f"{WORK_DIR}/security-result.json","w") as f:
    json.dump(result, f, indent=2)

with open(os.environ.get("GITHUB_OUTPUT","/dev/null"),"a") as out:
    out.write(f"security_passed={'true' if result['passed'] else 'false'}\n")
    out.write(f"security_threats={total_threats}\n")
    out.write(f"security_critical={CRITICAL_COUNT}\n")

icon = "✅" if result["passed"] else "❌"
col  = G if result["passed"] else R
print(f"\n  {col}{icon} Security: {total_threats} threat(s) found (critical: {CRITICAL_COUNT}){X}")
SEC_EOF

  # Load results
  if [[ -f "${WORK_DIR}/security-result.json" ]]; then
    local sec_passed; sec_passed=$(jq -r '.passed' "${WORK_DIR}/security-result.json" 2>/dev/null || echo "false")
    local threat_count; threat_count=$(jq '.threat_count' "${WORK_DIR}/security-result.json" 2>/dev/null || echo 0)
    local critical_count; critical_count=$(jq '.critical_count' "${WORK_DIR}/security-result.json" 2>/dev/null || echo 0)

    SEC_THREAT_COUNT="${threat_count}"
    FL_SECURITY="${sec_passed}"

    # Score
    score=$(( 100 - (critical_count * 30) - ((threat_count - critical_count) * 10) ))
    SC_SECURITY=$(( score < 0 ? 0 : score > 100 ? 100 : score ))

    # Add errors for critical threats
    if [[ "${critical_count}" -gt 0 ]]; then
      ERRORS+=("Security: ${critical_count} CRITICAL threat(s) found")
      [[ "${FAIL_ON_SECURITY}" == "true" ]] && FL_SECURITY="false"
    fi

    # Add warnings for other threats
    if [[ "${threat_count}" -gt "${critical_count}" ]]; then
      WARNINGS+=("Security: $((threat_count - critical_count)) medium/low threat(s) found")
    fi
  fi

  log_score "Security score: ${SC_SECURITY}/100"
}

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 5 — API Contract
# ─────────────────────────────────────────────────────────────────────────────
check_api_contract() {
  section_header "5" "API Contract Verification" "${C_MAUVE}"

  [[ "${CHECK_API}" != "true" ]] && {
    log_info "API contract check disabled"
    SC_API=80; FL_API="true"
    return
  }

  local INIT_SCRIPT="${PLUGIN_DIR}/init.sh"
  local score=100

  if [[ ! -f "${INIT_SCRIPT}" ]]; then
    add_warning "init.sh not found — cannot verify API contract"
    SC_API=50; FL_API="false"
    return
  fi

  echo "  🔢 Checking required API functions in init.sh..."

  IFS=',' read -ra REQ_FUNCS <<< "${REQUIRED_FUNCTIONS}"
  local missing_funcs=0
  local found_funcs=0

  for func in "${REQ_FUNCS[@]}"; do
    func=$(echo "${func}" | tr -d ' ')
    # Check for function definition (multiple shell styles)
    if grep -qE "^(function\s+)?${func}\s*\(\)" "${INIT_SCRIPT}" 2>/dev/null || \
       grep -qE "^${func}\(\)" "${INIT_SCRIPT}" 2>/dev/null; then
      add_pass "API function: ${func}()"
      ((found_funcs++))
    else
      add_error "Missing API function: ${func}() in init.sh"
      score=$((score - 20))
      ((missing_funcs++))
    fi
  done

  # Check for source-guard pattern
  if grep -qE '^(if|#\s*Source guard|\[\[.*BASH_SOURCE)' "${INIT_SCRIPT}" 2>/dev/null; then
    add_pass "Source guard pattern detected"
    score=$((score + 5))
  else
    add_warning "No source guard in init.sh (recommended: \${BASH_SOURCE[0]} check)"
    score=$((score - 3))
  fi

  # Check for set -euo pipefail
  if grep -qE '^set\s+-[^-]*(e|u|o\s+pipefail)' "${INIT_SCRIPT}" 2>/dev/null || \
     grep -q 'set -euo pipefail' "${INIT_SCRIPT}" 2>/dev/null; then
    add_pass "Strict mode (set -euo pipefail) present"
    score=$((score + 3))
  else
    add_warning "Strict mode not set in init.sh (recommended: set -euo pipefail)"
  fi

  SC_API=$(( score < 0 ? 0 : score > 100 ? 100 : score ))
  [[ "${missing_funcs}" -eq 0 ]] && FL_API="true" || FL_API="false"

  log_score "API contract score: ${SC_API}/100 (${found_funcs}/${#REQ_FUNCS[@]} functions)"
}

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 6 — Dependency Verification
# ─────────────────────────────────────────────────────────────────────────────
check_dependencies() {
  section_header "6" "Dependency Verification" "${C_BLUE}"

  [[ "${CHECK_DEPS}" != "true" ]] && {
    log_info "Dependency check disabled"
    SC_DEPS=80; FL_DEPS="true"
    return
  }

  local MANIFEST="${PLUGIN_DIR}/plugin.json"
  local score=100

  if [[ ! -f "${MANIFEST}" ]]; then
    log_info "No manifest — skipping dependency check"
    SC_DEPS=70; FL_DEPS="true"
    return
  fi

  # Extract declared dependencies
  local deps_raw; deps_raw=$(jq -r '.dependencies[]?' "${MANIFEST}" 2>/dev/null || echo "")
  if [[ -z "${deps_raw}" ]]; then
    log_info "No dependencies declared in plugin.json"
    SC_DEPS=90; FL_DEPS="true"
    return
  fi

  echo "  📊 Checking declared dependencies..."

  local found_count=0
  local missing_count=0
  local total_deps=0

  while IFS= read -r dep; do
    [[ -z "${dep}" ]] && continue
    ((total_deps++))

    # Check if command exists
    if command -v "${dep}" &>/dev/null; then
      local ver; ver=$(${dep} --version 2>/dev/null | head -1 || echo "found")
      add_pass "Dependency: ${dep} — ${ver:0:40}"
      ((found_count++))
    else
      local msg="Dependency not found: ${dep}"
      if [[ "${FAIL_ON_DEPS}" == "true" ]]; then
        add_error "${msg}"
        score=$((score - 15))
      else
        add_warning "${msg} (will need installation)"
        score=$((score - 5))
      fi
      ((missing_count++))
    fi
  done <<< "${deps_raw}"

  SC_DEPS=$(( score < 0 ? 0 : score > 100 ? 100 : score ))
  [[ "${missing_count}" -eq 0 || "${FAIL_ON_DEPS}" != "true" ]] && FL_DEPS="true" || FL_DEPS="false"

  log_score "Dependencies: ${found_count}/${total_deps} available · score: ${SC_DEPS}/100"
}

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 7 — Test Coverage
# ─────────────────────────────────────────────────────────────────────────────
check_tests() {
  section_header "7" "Test Coverage Analysis" "${C_GREEN}"

  [[ "${CHECK_TESTS}" != "true" ]] && {
    log_info "Test coverage check disabled"
    SC_TESTS=70; FL_TESTS="true"
    return
  }

  local score=0
  local test_count=0

  # Find test files
  local TEST_DIRS=("tests" "test" "spec" "__tests__")
  local FOUND_TEST_DIR=""

  for dir in "${TEST_DIRS[@]}"; do
    if [[ -d "${PLUGIN_DIR}/${dir}" ]]; then
      FOUND_TEST_DIR="${PLUGIN_DIR}/${dir}"
      break
    fi
  done

  # Also look for test files in root
  mapfile -t TEST_FILES < <(
    find "${PLUGIN_DIR}" \
      \( -name "test-*.sh" -o -name "*-test.sh" -o -name "*.test.sh" -o -name "*_test.sh" \) \
      -type f 2>/dev/null
  )

  if [[ -d "${FOUND_TEST_DIR}" ]]; then
    local dir_tests; dir_tests=$(find "${FOUND_TEST_DIR}" -name "*.sh" -type f 2>/dev/null | wc -l)
    add_pass "Test directory found: ${FOUND_TEST_DIR#${PLUGIN_DIR}/} (${dir_tests} files)"
    test_count=$((test_count + dir_tests))
    score=$((score + 40))
  fi

  if [[ "${#TEST_FILES[@]}" -gt 0 ]]; then
    add_pass "Test files found: ${#TEST_FILES[@]}"
    test_count=$((test_count + ${#TEST_FILES[@]}))
    score=$((score + 20))
  fi

  # Count individual test cases (grep for test functions)
  local actual_tests=0
  local all_test_files=("${TEST_FILES[@]}")
  [[ -d "${FOUND_TEST_DIR}" ]] && mapfile -ta DIR_TEST_FILES < <(find "${FOUND_TEST_DIR}" -name "*.sh" 2>/dev/null)
  all_test_files+=("${DIR_TEST_FILES[@]:-}")

  for tf in "${all_test_files[@]:-}"; do
    [[ -f "${tf}" ]] || continue
    local tc; tc=$(grep -cE '^(function\s+)?(test_|it_|should_|assert_)' "${tf}" 2>/dev/null || echo 0)
    actual_tests=$((actual_tests + tc))
  done

  TEST_COUNT="${actual_tests}"

  if [[ "${actual_tests}" -ge "${MIN_TESTS}" ]]; then
    add_pass "Test cases: ${actual_tests} (minimum: ${MIN_TESTS})"
    score=$((score + 40))
    FL_TESTS="true"
  elif [[ "${actual_tests}" -gt 0 ]]; then
    add_warning "Too few tests: ${actual_tests} < ${MIN_TESTS} minimum"
    score=$((score + 20))
    FL_TESTS="true"
  else
    add_warning "No test cases found (add tests for better quality)"
    FL_TESTS="false"
  fi

  SC_TESTS=$(( score > 100 ? 100 : score ))
  log_score "Tests: ${actual_tests} cases · score: ${SC_TESTS}/100"
}

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 8 — Documentation Quality
# ─────────────────────────────────────────────────────────────────────────────
check_documentation() {
  section_header "8" "Documentation Quality" "${C_PEACH}"

  [[ "${CHECK_DOCS}" != "true" ]] && {
    log_info "Documentation check disabled"
    SC_DOCS=70; FL_DOCS="true"
    return
  }

  local score=0

  local README="${PLUGIN_DIR}/README.md"
  if [[ ! -f "${README}" ]]; then
    add_warning "README.md missing — documentation recommended"
    SC_DOCS=20; FL_DOCS="false"
    return
  fi

  local lines; lines=$(wc -l < "${README}" 2>/dev/null || echo 0)
  local chars; chars=$(wc -c < "${README}" 2>/dev/null || echo 0)

  if [[ "${lines}" -ge "${MIN_README_LINES}" ]]; then
    add_pass "README.md: ${lines} lines ≥ ${MIN_README_LINES} minimum"
    score=$((score + 30))
    FL_DOCS="true"
  else
    add_warning "README.md too short: ${lines} lines < ${MIN_README_LINES} minimum"
    score=$((score + 10))
    FL_DOCS="false"
  fi

  # Check for required README sections
  declare -A README_SECTIONS=(
    ["installation"]="## Installation\|## Install\|## Setup"
    ["usage"]="## Usage\|## How to Use\|## Getting Started"
    ["configuration"]="## Config\|## Configuration\|## Options"
    ["commands"]="## Commands\|## Usage\|## API"
  )

  for section in "${!README_SECTIONS[@]}"; do
    local pattern="${README_SECTIONS[$section]}"
    if grep -qiE "${pattern}" "${README}" 2>/dev/null; then
      log_debug "README section found: ${section}"
      score=$((score + 10))
    else
      add_warning "README.md missing section: ${section}"
    fi
  done

  # Check for code examples
  if grep -q '```' "${README}" 2>/dev/null; then
    add_pass "README.md: code examples present"
    score=$((score + 10))
  else
    add_warning "README.md: no code examples found"
  fi

  # Check for badges / shields
  if grep -qE '!\[.*\]\(https://(img\.shields\.io|badge\.fury\.io)' "${README}" 2>/dev/null; then
    add_pass "README.md: badges present"
    score=$((score + 5))
  fi

  SC_DOCS=$(( score > 100 ? 100 : score < 0 ? 0 : score ))
  log_score "Documentation score: ${SC_DOCS}/100 (README: ${lines} lines)"
}

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 9 — Naming Convention
# ─────────────────────────────────────────────────────────────────────────────
check_naming() {
  section_header "9" "Naming Convention" "${C_SKY}"

  local score=100
  local naming_passed=true
  local dir_name; dir_name=$(basename "${PLUGIN_DIR}")

  # Directory name: must be kebab-case
  if echo "${dir_name}" | grep -qE '^[a-z][a-z0-9-]+$'; then
    add_pass "Directory name: '${dir_name}' (valid kebab-case)"
  elif echo "${dir_name}" | grep -q ' '; then
    add_error "Directory name has spaces: '${dir_name}'"
    score=$((score - 30)); naming_passed=false
  elif echo "${dir_name}" | grep -qE '[A-Z]'; then
    add_warning "Directory has uppercase: '${dir_name}' (use lowercase)"
    score=$((score - 15))
  elif echo "${dir_name}" | grep -qE '[_]'; then
    add_warning "Directory uses underscores: '${dir_name}' (use hyphens)"
    score=$((score - 10))
  fi

  # Length check
  if [[ "${#dir_name}" -gt 64 ]]; then
    add_warning "Plugin name too long: ${#dir_name} chars (max 64)"
    score=$((score - 10))
  fi

  # Plugin name in manifest should match dir
  if [[ -f "${PLUGIN_DIR}/plugin.json" ]]; then
    local manifest_name; manifest_name=$(jq -r '.name // empty' "${PLUGIN_DIR}/plugin.json" 2>/dev/null || echo "")
    if [[ -n "${manifest_name}" && "${manifest_name}" != "${dir_name}" ]]; then
      add_warning "Manifest name '${manifest_name}' ≠ dir name '${dir_name}'"
      score=$((score - 8))
    elif [[ -n "${manifest_name}" ]]; then
      add_pass "Manifest name matches directory: '${manifest_name}'"
    fi
  fi

  # Script naming: should be kebab-case .sh
  find "${PLUGIN_DIR}" -maxdepth 1 -name "*.sh" 2>/dev/null | while read -r script; do
    local sname; sname=$(basename "${script}" .sh)
    if ! echo "${sname}" | grep -qE '^[a-z][a-z0-9-]*$'; then
      add_warning "Script filename not kebab-case: $(basename "${script}")"
      score=$((score - 3))
    fi
  done

  SC_NAMING=$(( score < 0 ? 0 : score > 100 ? 100 : score ))
  FL_NAMING="${naming_passed}"

  log_score "Naming score: ${SC_NAMING}/100"
}

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 10 — Lifecycle Symmetry
# ─────────────────────────────────────────────────────────────────────────────
check_lifecycle() {
  section_header "10" "Lifecycle Symmetry (enable ↔ disable)" "${C_PINK}"

  [[ "${CHECK_LIFECYCLE}" != "true" ]] && {
    log_info "Lifecycle check disabled"
    SC_LIFECYCLE=80; FL_LIFECYCLE="true"
    return
  }

  local ENABLE="${PLUGIN_DIR}/enable.sh"
  local DISABLE="${PLUGIN_DIR}/disable.sh"
  local STATUS="${PLUGIN_DIR}/status.sh"
  local score=100

  if [[ ! -f "${ENABLE}" && ! -f "${DISABLE}" ]]; then
    add_warning "No enable/disable scripts found"
    SC_LIFECYCLE=50; FL_LIFECYCLE="false"
    return
  fi

  # Analyze enable.sh
  local ENABLE_OPS=()
  if [[ -f "${ENABLE}" ]]; then
    # Extract operations (what enable does)
    mapfile -t ENABLE_OPS < <(
      grep -E '^\s*(systemctl\s+start|systemctl\s+enable|ln\s+-s|mkdir|cp\s+|install\s+|echo\s+.*>)' \
        "${ENABLE}" 2>/dev/null || true
    )
    add_pass "enable.sh: ${#ENABLE_OPS[@]} operation(s) detected"
  fi

  # Analyze disable.sh
  local DISABLE_OPS=()
  if [[ -f "${DISABLE}" ]]; then
    mapfile -t DISABLE_OPS < <(
      grep -E '^\s*(systemctl\s+stop|systemctl\s+disable|rm\s+|unlink\s+|rmdir)' \
        "${DISABLE}" 2>/dev/null || true
    )
    add_pass "disable.sh: ${#DISABLE_OPS[@]} operation(s) detected"
  fi

  # Symmetry heuristic: disable should undo enable operations
  if [[ "${#ENABLE_OPS[@]}" -gt 0 && "${#DISABLE_OPS[@]}" -eq 0 ]]; then
    add_warning "enable.sh has operations but disable.sh has none — may not fully undo"
    score=$((score - 20))
  elif [[ "${#ENABLE_OPS[@]}" -gt 0 && "${#DISABLE_OPS[@]}" -gt 0 ]]; then
    add_pass "Lifecycle appears symmetric"
    score=$((score + 5))
  fi

  # Status script checks
  if [[ -f "${STATUS}" ]]; then
    if grep -qE 'exit\s+(0|1)' "${STATUS}" 2>/dev/null; then
      add_pass "status.sh: uses exit codes (0=enabled, 1=disabled)"
    else
      add_warning "status.sh: no exit codes found (should exit 0 if enabled, 1 if disabled)"
      score=$((score - 10))
    fi
  fi

  # Idempotency check (enable called twice should be safe)
  if [[ -f "${ENABLE}" ]]; then
    if grep -qE '\[\[\s*-[fd]\s+' "${ENABLE}" 2>/dev/null || \
       grep -qE 'systemctl\s+is-active\|command\s+-v' "${ENABLE}" 2>/dev/null; then
      add_pass "enable.sh: appears idempotent (guards detected)"
      score=$((score + 5))
    else
      add_warning "enable.sh: may not be idempotent (add existence checks)"
    fi
  fi

  SC_LIFECYCLE=$(( score < 0 ? 0 : score > 100 ? 100 : score ))
  FL_LIFECYCLE="true"

  log_score "Lifecycle score: ${SC_LIFECYCLE}/100"
}

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 11 — Performance
# ─────────────────────────────────────────────────────────────────────────────
check_performance() {
  [[ "${VALIDATION_LEVEL}" == "quick" ]] && return

  section_header "11" "Performance & Size Analysis" "${C_YELLOW}"

  local score=100

  # Total size
  local total_kb; total_kb=$(du -sk "${PLUGIN_DIR}" 2>/dev/null | cut -f1 || echo 0)
  if [[ "${total_kb}" -le "${MAX_SIZE_KB}" ]]; then
    add_pass "Plugin size: ${total_kb}KB ≤ ${MAX_SIZE_KB}KB limit"
  else
    add_warning "Plugin too large: ${total_kb}KB > ${MAX_SIZE_KB}KB"
    score=$((score - 20))
  fi

  # Script complexity (line count per file)
  find "${PLUGIN_DIR}" -name "*.sh" -type f 2>/dev/null | while read -r script; do
    local lines; lines=$(wc -l < "${script}" 2>/dev/null || echo 0)
    local fname; fname=$(basename "${script}")
    if [[ "${lines}" -gt "${MAX_SCRIPT_LINES}" ]]; then
      add_warning "${fname}: ${lines} lines > ${MAX_SCRIPT_LINES} max (consider splitting)"
      score=$((score - 10))
    else
      log_debug "${fname}: ${lines} lines"
    fi
  done

  # Nested loop depth check (Python analysis)
  python3 << 'PERF_PY_EOF'
import re
import os
from pathlib import Path

PLUGIN_DIR      = "${PLUGIN_DIR}"
MAX_NEST_DEPTH  = 3
findings        = []

for sh in Path(PLUGIN_DIR).rglob("*.sh"):
    try:
        content  = sh.read_text(errors="ignore")
        rel_path = str(sh.relative_to(PLUGIN_DIR))
    except Exception:
        continue

    # Measure loop nesting depth
    depth = 0; max_depth = 0
    for line in content.splitlines():
        stripped = line.strip()
        if re.match(r'\b(for|while|until)\b', stripped):
            depth += 1
            max_depth = max(max_depth, depth)
        elif stripped == "done":
            depth = max(0, depth - 1)

    if max_depth > MAX_NEST_DEPTH:
        findings.append(f"{rel_path}: deeply nested loops (depth={max_depth})")

if findings:
    for f in findings[:3]:
        print(f"  \033[38;2;249;226;175m⚠️  Performance: {f}\033[0m")
else:
    print(f"  \033[38;2;166;227;161m✅ No deep loop nesting detected\033[0m")
PERF_PY_EOF

  SC_PERFORMANCE=$(( score < 0 ? 0 : score > 100 ? 100 : score ))
  log_score "Performance score: ${SC_PERFORMANCE}/100"
}

# ─────────────────────────────────────────────────────────────────────────────
# FINAL SCORE CALCULATION & REPORT
# ─────────────────────────────────────────────────────────────────────────────
calculate_and_report() {
  section_header "📊" "Final Score Calculation" "${C_LAV}"

  # Weighted scoring (total = 100)
  local W_MANIFEST=20
  local W_STRUCTURE=15
  local W_SHELLCHECK=15
  local W_SECURITY=20
  local W_API=10
  local W_DEPS=5
  local W_TESTS=5
  local W_DOCS=5
  local W_NAMING=3
  local W_LIFECYCLE=2

  local WEIGHTED=$(echo "scale=2; \
    (${SC_MANIFEST}   * ${W_MANIFEST}   + \
     ${SC_STRUCTURE}  * ${W_STRUCTURE}  + \
     ${SC_SHELLCHECK} * ${W_SHELLCHECK} + \
     ${SC_SECURITY}   * ${W_SECURITY}   + \
     ${SC_API}        * ${W_API}        + \
     ${SC_DEPS}       * ${W_DEPS}       + \
     ${SC_TESTS}      * ${W_TESTS}      + \
     ${SC_DOCS}       * ${W_DOCS}       + \
     ${SC_NAMING}     * ${W_NAMING}     + \
     ${SC_LIFECYCLE}  * ${W_LIFECYCLE}) / 100" | bc 2>/dev/null || echo "0")

  local FINAL_SCORE; FINAL_SCORE=$(printf "%.0f" "${WEIGHTED}" 2>/dev/null || echo "0")
  FINAL_SCORE=$(( FINAL_SCORE < 0 ? 0 : FINAL_SCORE > 100 ? 100 : FINAL_SCORE ))

  # Grade
  local GRADE
  if   [[ "${FINAL_SCORE}" -ge 95 ]]; then GRADE="A+"
  elif [[ "${FINAL_SCORE}" -ge 90 ]]; then GRADE="A"
  elif [[ "${FINAL_SCORE}" -ge 80 ]]; then GRADE="B"
  elif [[ "${FINAL_SCORE}" -ge 70 ]]; then GRADE="C"
  elif [[ "${FINAL_SCORE}" -ge 60 ]]; then GRADE="D"
  else GRADE="F"
  fi

  # Overall pass/fail
  local PASSED="true"
  [[ "${FINAL_SCORE}" -lt "${MINIMUM_SCORE}" ]] && PASSED="false"
  [[ "${#ERRORS[@]}" -gt 0 ]] && PASSED="false"
  [[ "${FL_SECURITY}" != "true" && "${FAIL_ON_SECURITY}" == "true" ]] && PASSED="false"

  # Score bar (40 wide)
  local BAR_FILLED=$(( FINAL_SCORE * 40 / 100 ))
  local BAR_EMPTY=$(( 40 - BAR_FILLED ))
  local SCORE_BAR
  SCORE_BAR="$(printf '█%.0s' $(seq 1 ${BAR_FILLED} 2>/dev/null || true))"
  SCORE_BAR+="$(printf '░%.0s' $(seq 1 ${BAR_EMPTY}  2>/dev/null || true))"

  local GRADE_COLOR="${C_GREEN}"
  [[ "${GRADE}" == "B" ]]            && GRADE_COLOR="${C_TEAL}"
  [[ "${GRADE}" == "C" ]]            && GRADE_COLOR="${C_YELLOW}"
  [[ "${GRADE}" == "D" || "${GRADE}" == "F" ]] && GRADE_COLOR="${C_RED}"

  # ── Display final score dashboard ─────────────────────────────────────────
  echo ""
  echo -e "  ${C_BLUE}${C_B}╔══════════════════════════════════════════════════════════════╗${C_R}"
  echo -e "  ${C_BLUE}${C_B}║  📊 PLUGIN QUALITY SCORE                                     ║${C_R}"
  echo -e "  ${C_BLUE}${C_B}╠══════════════════════════════════════════════════════════════╣${C_R}"
  printf  "  ${C_BLUE}${C_B}║${C_R}  ${GRADE_COLOR}${C_B}[%s]${C_R} ${GRADE_COLOR}${C_B}%d/100${C_R} — Grade: ${GRADE_COLOR}${C_B}%s${C_R}%*s${C_BLUE}${C_B}║${C_R}\n" \
    "${SCORE_BAR}" "${FINAL_SCORE}" "${GRADE}" $((9 - ${#GRADE})) ""
  echo -e "  ${C_BLUE}${C_B}╠══════════════════════════════════════════════════════════════╣${C_R}"

  # Component scores table
  declare -a SCORE_ROWS=(
    "📋 Manifest      [${SC_MANIFEST}]    🔌 ShellCheck   [${SC_SHELLCHECK}]"
    "📁 Structure     [${SC_STRUCTURE}]   🔐 Security     [${SC_SECURITY}]"
    "🔢 API Contract  [${SC_API}]        📊 Dependencies [${SC_DEPS}]"
    "🧪 Tests         [${SC_TESTS}]      📖 Docs         [${SC_DOCS}]"
    "🔤 Naming        [${SC_NAMING}]     🔄 Lifecycle    [${SC_LIFECYCLE}]"
  )
  for row in "${SCORE_ROWS[@]}"; do
    printf "  ${C_BLUE}${C_B}║${C_R}  ${C_TEXT}%-61s${C_BLUE}${C_B}║${C_R}\n" "${row}"
  done

  echo -e "  ${C_BLUE}${C_B}╠══════════════════════════════════════════════════════════════╣${C_R}"
  printf  "  ${C_BLUE}${C_B}║${C_R}  ❌ Errors:  %-5d  ⚠️  Warnings: %-5d  🎯 Min: %-3d/100      ${C_BLUE}${C_B}║${C_R}\n" \
    "${#ERRORS[@]}" "${#WARNINGS[@]}" "${MINIMUM_SCORE}"
  printf  "  ${C_BLUE}${C_B}║${C_R}  🐚 SC:  e%-3d/w%-3d  🔐 Threats: %-4d  🧪 Tests: %-3d         ${C_BLUE}${C_B}║${C_R}\n" \
    "${SC_ERR_COUNT}" "${SC_WARN_COUNT}" "${SEC_THREAT_COUNT}" "${TEST_COUNT}"
  echo -e "  ${C_BLUE}${C_B}╚══════════════════════════════════════════════════════════════╝${C_R}"

  # ── Emit GitHub outputs ────────────────────────────────────────────────────
  {
    echo "validation_passed=${PASSED}"
    echo "score=${FINAL_SCORE}"
    echo "grade=${GRADE}"
    echo "plugin_name=${P_NAME}"
    echo "plugin_version=${P_VERSION}"
    echo "plugin_category=${P_CATEGORY}"
    echo "plugin_author=${P_AUTHOR}"
    echo "manifest_passed=${FL_MANIFEST}"
    echo "structure_passed=${FL_STRUCTURE}"
    echo "shellcheck_passed=${FL_SHELLCHECK}"
    echo "shellcheck_errors=${SC_ERR_COUNT}"
    echo "shellcheck_warnings=${SC_WARN_COUNT}"
    echo "security_passed=${FL_SECURITY}"
    echo "security_threats=${SEC_THREAT_COUNT}"
    echo "api_passed=${FL_API}"
    echo "deps_passed=${FL_DEPS}"
    echo "tests_passed=${FL_TESTS}"
    echo "test_count=${TEST_COUNT}"
    echo "docs_passed=${FL_DOCS}"
    echo "naming_passed=${FL_NAMING}"
    echo "lifecycle_passed=${FL_LIFECYCLE}"
    echo "error_count=${#ERRORS[@]}"
    echo "warning_count=${#WARNINGS[@]}"
    echo "errors_json=$(printf '%s\n' "${ERRORS[@]:-}" | jq -R . | jq -s -c . 2>/dev/null || echo '[]')"
    echo "warnings_json=$(printf '%s\n' "${WARNINGS[@]:-}" | jq -R . | jq -s -c . 2>/dev/null || echo '[]')"
  } >> "${GITHUB_OUTPUT:-/dev/null}"

  # Save error/warning files
  printf '%s\n' "${ERRORS[@]:-}"   | jq -R . | jq -s . > "${WORK_DIR}/errors.json"   2>/dev/null || echo '[]' > "${WORK_DIR}/errors.json"
  printf '%s\n' "${WARNINGS[@]:-}" | jq -R . | jq -s . > "${WORK_DIR}/warnings.json" 2>/dev/null || echo '[]' > "${WORK_DIR}/warnings.json"

  # ── Generate Markdown report ──────────────────────────────────────────────
  local NOW; NOW=$(date -u +"%Y-%m-%d %H:%M UTC")
  local REPORT_MD="${WORK_DIR}/plugin-report.md"

  cat > "${REPORT_MD}" << REPORT_EOF
# 🔌 ASH Plugin Validation Report

> **Plugin:** \`${P_NAME}\` &nbsp;·&nbsp; **v${P_VERSION}** &nbsp;·&nbsp; **Category:** \`${P_CATEGORY}\` &nbsp;·&nbsp; **Author:** \`${P_AUTHOR}\`
> Engine: ASH v${VALIDATOR_VERSION} &nbsp;·&nbsp; Level: \`${VALIDATION_LEVEL}\` &nbsp;·&nbsp; Generated: \`${NOW}\`

## 📊 Quality Score

\`\`\`
Score: [${SCORE_BAR}] ${FINAL_SCORE}/100   Grade: ${GRADE}
Status: $([[ "${PASSED}" == "true" ]] && echo "✅ PASSED" || echo "❌ FAILED")
Errors: ${#ERRORS[@]}   Warnings: ${#WARNINGS[@]}   SC Errors: ${SC_ERR_COUNT}   Threats: ${SEC_THREAT_COUNT}
\`\`\`

## 🔍 Validation Results

| Check | Score | Status | Details |
|-------|------:|:------:|---------|
| 📋 Manifest Schema | \`${SC_MANIFEST}/100\` | $([[ "${FL_MANIFEST}" == "true" ]] && echo "✅" || echo "❌") | plugin.json conformance |
| 📁 File Structure | \`${SC_STRUCTURE}/100\` | $([[ "${FL_STRUCTURE}" == "true" ]] && echo "✅" || echo "❌") | Lifecycle scripts |
| 🐚 ShellCheck | \`${SC_SHELLCHECK}/100\` | $([[ "${FL_SHELLCHECK}" == "true" ]] && echo "✅" || echo "❌") | \`${SC_ERR_COUNT}\` errors · \`${SC_WARN_COUNT}\` warnings |
| 🔐 Security | \`${SC_SECURITY}/100\` | $([[ "${FL_SECURITY}" == "true" ]] && echo "✅" || echo "❌") | \`${SEC_THREAT_COUNT}\` threat(s) |
| 🔢 API Contract | \`${SC_API}/100\` | $([[ "${FL_API}" == "true" ]] && echo "✅" || echo "❌") | Required functions |
| 📊 Dependencies | \`${SC_DEPS}/100\` | $([[ "${FL_DEPS}" == "true" ]] && echo "✅" || echo "❌") | Declared deps verified |
| 🧪 Tests | \`${SC_TESTS}/100\` | $([[ "${FL_TESTS}" == "true" ]] && echo "✅" || echo "❌") | \`${TEST_COUNT}\` test case(s) |
| 📖 Documentation | \`${SC_DOCS}/100\` | $([[ "${FL_DOCS}" == "true" ]] && echo "✅" || echo "❌") | README.md quality |
| 🔤 Naming | \`${SC_NAMING}/100\` | $([[ "${FL_NAMING}" == "true" ]] && echo "✅" || echo "❌") | Naming conventions |
| 🔄 Lifecycle | \`${SC_LIFECYCLE}/100\` | $([[ "${FL_LIFECYCLE}" == "true" ]] && echo "✅" || echo "❌") | enable↔disable symmetry |

REPORT_EOF

  if [[ "${#ERRORS[@]}" -gt 0 ]]; then
    echo "## ❌ Errors (${#ERRORS[@]})" >> "${REPORT_MD}"
    echo "" >> "${REPORT_MD}"
    for err in "${ERRORS[@]}"; do
      echo "- ❌ ${err}" >> "${REPORT_MD}"
    done
    echo "" >> "${REPORT_MD}"
  fi

  if [[ "${#WARNINGS[@]}" -gt 0 ]]; then
    echo "## ⚠️ Warnings (${#WARNINGS[@]})" >> "${REPORT_MD}"
    echo "" >> "${REPORT_MD}"
    for warn in "${WARNINGS[@]}"; do
      echo "- ⚠️ ${warn}" >> "${REPORT_MD}"
    done
    echo "" >> "${REPORT_MD}"
  fi

  cat >> "${REPORT_MD}" << FOOTER_EOF

## 🔌 Plugin Details

| Property | Value |
|----------|-------|
| 🏷️ Name | \`${P_NAME}\` |
| 🔖 Version | \`${P_VERSION}\` |
| 📁 Category | \`${P_CATEGORY}\` |
| 👤 Author | \`${P_AUTHOR}\` |
| 🐚 ShellCheck | \`${SC_ERR_COUNT}\` errors · \`${SC_WARN_COUNT}\` warnings |
| 🔐 Security | \`${SEC_THREAT_COUNT}\` threats |
| 🧪 Tests | \`${TEST_COUNT}\` cases |

---
*🔌 ASH Dotfiles v5.0 OMEGA Plugin Validation Engine · [github.com/ash/dotfiles](https://github.com/ash/dotfiles)*
FOOTER_EOF

  echo "report_path=${REPORT_MD}" >> "${GITHUB_OUTPUT:-/dev/null}"

  # ── JSON report ────────────────────────────────────────────────────────────
  cat > "${WORK_DIR}/plugin-report.json" << JSON_EOF
{
  "plugin_name":   "${P_NAME}",
  "version":       "${P_VERSION}",
  "category":      "${P_CATEGORY}",
  "author":        "${P_AUTHOR}",
  "score":         ${FINAL_SCORE},
  "grade":         "${GRADE}",
  "passed":        ${PASSED},
  "timestamp":     "${NOW}",
  "engine":        "${VALIDATOR_VERSION}",
  "level":         "${VALIDATION_LEVEL}",
  "scores": {
    "manifest":    ${SC_MANIFEST},
    "structure":   ${SC_STRUCTURE},
    "shellcheck":  ${SC_SHELLCHECK},
    "security":    ${SC_SECURITY},
    "api":         ${SC_API},
    "deps":        ${SC_DEPS},
    "tests":       ${SC_TESTS},
    "docs":        ${SC_DOCS},
    "naming":      ${SC_NAMING},
    "lifecycle":   ${SC_LIFECYCLE}
  },
  "results": {
    "manifest_passed":   ${FL_MANIFEST},
    "structure_passed":  ${FL_STRUCTURE},
    "shellcheck_passed": ${FL_SHELLCHECK},
    "security_passed":   ${FL_SECURITY},
    "api_passed":        ${FL_API},
    "deps_passed":       ${FL_DEPS},
    "tests_passed":      ${FL_TESTS},
    "docs_passed":       ${FL_DOCS},
    "naming_passed":     ${FL_NAMING},
    "lifecycle_passed":  ${FL_LIFECYCLE}
  },
  "counters": {
    "errors":            ${#ERRORS[@]},
    "warnings":          ${#WARNINGS[@]},
    "shellcheck_errors": ${SC_ERR_COUNT},
    "shellcheck_warns":  ${SC_WARN_COUNT},
    "security_threats":  ${SEC_THREAT_COUNT},
    "test_count":        ${TEST_COUNT}
  }
}
JSON_EOF

  log_pass "Reports: ${WORK_DIR}/plugin-report.md + .json"

  # ── Timing ────────────────────────────────────────────────────────────────
  local END_NS; END_NS=$(date +%s%N)
  local DUR_MS=$(( (END_NS - START_NS) / 1000000 ))
  log_info "Validation complete in ${DUR_MS}ms"
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
main() {
  print_banner

  # Run checks based on validation level
  check_manifest      # Always
  check_structure     # Always
  check_naming        # Always

  if [[ "${VALIDATION_LEVEL}" != "quick" ]]; then
    check_shellcheck
    check_security
    check_api_contract
    check_dependencies
    check_lifecycle
  fi

  if [[ "${VALIDATION_LEVEL}" == "strict" || "${VALIDATION_LEVEL}" == "paranoid" ]]; then
    check_tests
    check_documentation
    check_performance
  fi

  calculate_and_report
}

# ─────────────────────────────────────────────────────────────────────────────
# TRAP & ENTRY
# ─────────────────────────────────────────────────────────────────────────────
trap 'EXIT_CODE=$?
if [[ $EXIT_CODE -ne 0 ]]; then
  echo ""
  echo -e "\033[38;2;243;139;168m❌ validate.sh failed (exit=${EXIT_CODE})\033[0m"
  tail -15 "${LOG_FILE}" 2>/dev/null | sed "s/^/   /" || true
fi' EXIT

main "$@"