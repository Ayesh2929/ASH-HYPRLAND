#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  🐚 SCRIPT NAME — ASH DOTFILES v5.0 OMEGA                                      ║
# ║  Description  : Brief description of what this script does                     ║
# ║  Author       : ash                                                             ║
# ║  Created      : 2024-01-01                                                      ║
# ║  Usage        : ./script.sh [OPTIONS] <arguments>                              ║
# ║  Dependencies : bash >= 5.0, coreutils                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝
#
# DESCRIPTION:
#   Longer description of what this script does, its design decisions,
#   and any important notes for future maintainers.
#
# OPTIONS:
#   -h, --help       Show this help message and exit
#   -v, --verbose    Enable verbose/debug output
#   -n, --dry-run    Show what would be done without doing it
#   -o, --output     Output file path (default: stdout)
#
# EXAMPLES:
#   ./script.sh --verbose input.txt
#   ./script.sh --dry-run --output result.txt input.txt
#
# EXIT CODES:
#   0  Success
#   1  General error
#   2  Misuse of shell command
#   3  Input/output error
#   4  Dependency not found
#
# NOTES:
#   - Requires bash 5.0+ for associative array features
#   - Set DEBUG=1 to enable debug output without modifying the script

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ⚙️  STRICT MODE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📋 CONSTANTS & GLOBALS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_PID=$$

# ── Colours (check terminal support) ─────────────────────────────────────────────
if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
  readonly COL_RED=$'\033[0;31m'
  readonly COL_GRN=$'\033[0;32m'
  readonly COL_YLW=$'\033[0;33m'
  readonly COL_BLU=$'\033[0;34m'
  readonly COL_MAG=$'\033[0;35m'
  readonly COL_CYN=$'\033[0;36m'
  readonly COL_BLD=$'\033[1m'
  readonly COL_DIM=$'\033[2m'
  readonly COL_RST=$'\033[0m'
else
  readonly COL_RED='' COL_GRN='' COL_YLW='' COL_BLU=''
  readonly COL_MAG='' COL_CYN='' COL_BLD='' COL_DIM='' COL_RST=''
fi

# ── Default option values ─────────────────────────────────────────────────────────
VERBOSE=false
DRY_RUN=false
OUTPUT_FILE=""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📢 LOGGING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

log::info() {
  printf "${COL_BLU}[INFO]${COL_RST}  %s\n" "$*" >&2
}

log::ok() {
  printf "${COL_GRN}[ OK ]${COL_RST}  %s\n" "$*" >&2
}

log::warn() {
  printf "${COL_YLW}[WARN]${COL_RST}  %s\n" "$*" >&2
}

log::error() {
  printf "${COL_RED}[ERR ]${COL_RST}  %s\n" "$*" >&2
}

log::debug() {
  "${VERBOSE}" || return 0
  printf "${COL_DIM}[DBG ]  %s${COL_RST}\n" "$*" >&2
}

log::step() {
  printf "${COL_MAG}${COL_BLD}  ➜  ${COL_RST}%s\n" "$*" >&2
}

log::die() {
  log::error "$*"
  exit 1
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧹 CLEANUP & ERROR HANDLING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Temporary files / dirs registered for cleanup
declare -a _CLEANUP_FILES=()
declare -a _CLEANUP_DIRS=()

cleanup::register_file() { _CLEANUP_FILES+=("$1"); }
cleanup::register_dir()  { _CLEANUP_DIRS+=("$1");  }

cleanup::run() {
  local exit_code=$?
  log::debug "Running cleanup (exit_code=${exit_code})"

  for f in "${_CLEANUP_FILES[@]+"${_CLEANUP_FILES[@]}"}"; do
    [[ -f "$f" ]] && rm -f -- "$f"
  done

  for d in "${_CLEANUP_DIRS[@]+"${_CLEANUP_DIRS[@]}"}"; do
    [[ -d "$d" ]] && rm -rf -- "$d"
  done

  exit "${exit_code}"
}

trap cleanup::run EXIT INT TERM HUP

error::handler() {
  local exit_code=$?
  local line_no=${1:-?}
  log::error "Unhandled error at line ${line_no} (exit code: ${exit_code})"
}

trap 'error::handler "${LINENO}"' ERR

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 UTILITIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Check that required commands exist
require() {
  for cmd in "$@"; do
    if ! command -v "${cmd}" &>/dev/null; then
      log::die "Required command not found: ${cmd}"
    fi
  done
  log::debug "Dependencies satisfied: $*"
}

# Make a temp file and register it for cleanup
make_temp_file() {
  local tmp
  tmp="$(mktemp)" || log::die "Failed to create temp file"
  cleanup::register_file "${tmp}"
  printf '%s' "${tmp}"
}

# Make a temp directory and register it for cleanup
make_temp_dir() {
  local tmp
  tmp="$(mktemp -d)" || log::die "Failed to create temp directory"
  cleanup::register_dir "${tmp}"
  printf '%s' "${tmp}"
}

# Run a command, honouring --dry-run
run() {
  if "${DRY_RUN}"; then
    log::info "[DRY-RUN] $*"
    return 0
  fi
  log::debug "Running: $*"
  "$@"
}

# Confirm action with user (y/N prompt)
confirm() {
  local prompt="${1:-Continue?} [y/N] "
  local answer
  read -rp "${prompt}" answer
  [[ "${answer,,}" =~ ^(y|yes)$ ]]
}

# Retry a command up to N times with exponential backoff
retry() {
  local max="${1}"; shift
  local attempt=0
  until "$@"; do
    attempt=$(( attempt + 1 ))
    [[ "${attempt}" -ge "${max}" ]] \
      && log::die "Command failed after ${max} attempts: $*"
    local wait=$(( 2 ** attempt ))
    log::warn "Attempt ${attempt}/${max} failed; retrying in ${wait}s…"
    sleep "${wait}"
  done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📖 HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

usage() {
  cat <<EOF
${COL_BLD}${SCRIPT_NAME}${COL_RST} v${SCRIPT_VERSION}

${COL_BLD}USAGE:${COL_RST}
  ${SCRIPT_NAME} [OPTIONS] <input>

${COL_BLD}OPTIONS:${COL_RST}
  ${COL_GRN}-h, --help${COL_RST}        Show this help message
  ${COL_GRN}-v, --verbose${COL_RST}     Enable verbose output
  ${COL_GRN}-n, --dry-run${COL_RST}     Show what would be done
  ${COL_GRN}-o, --output${COL_RST} FILE Output file path

${COL_BLD}EXAMPLES:${COL_RST}
  ${SCRIPT_NAME} --verbose input.txt
  ${SCRIPT_NAME} --dry-run --output result.txt input.txt

${COL_BLD}EXIT CODES:${COL_RST}
  0  Success
  1  General error
  4  Dependency not found
EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎛️  ARGUMENT PARSING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

parse_args() {
  local -a positional=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage; exit 0 ;;
      -v|--verbose)
        VERBOSE=true; shift ;;
      -n|--dry-run)
        DRY_RUN=true; shift ;;
      -o|--output)
        [[ -n "${2:-}" ]] || log::die "--output requires an argument"
        OUTPUT_FILE="$2"; shift 2 ;;
      --output=*)
        OUTPUT_FILE="${1#*=}"; shift ;;
      --)
        shift; positional+=("$@"); break ;;
      -*)
        log::die "Unknown option: $1 (use --help for usage)" ;;
      *)
        positional+=("$1"); shift ;;
    esac
  done

  # Restore positional args
  set -- "${positional[@]+"${positional[@]}"}"

  # Validate required arguments
  [[ $# -ge 1 ]] || log::die "Missing required argument: <input> (use --help)"

  INPUT_FILE="$1"
  [[ -f "${INPUT_FILE}" ]] || log::die "Input file not found: ${INPUT_FILE}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🚀 MAIN LOGIC
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
  parse_args "$@"

  # Check dependencies
  require cat grep sed awk

  log::info "Starting ${SCRIPT_NAME} v${SCRIPT_VERSION}"
  "${DRY_RUN}" && log::warn "DRY-RUN mode enabled — no changes will be made"
  log::debug "Input: ${INPUT_FILE}"
  log::debug "Output: ${OUTPUT_FILE:-stdout}"

  # ── Core logic ────────────────────────────────────────────────────────────────
  log::step "Processing ${INPUT_FILE}…"

  local tmp
  tmp="$(make_temp_file)"

  # Do actual work here
  run cat "${INPUT_FILE}" > "${tmp}"

  # ── Output ────────────────────────────────────────────────────────────────────
  if [[ -n "${OUTPUT_FILE}" ]]; then
    run cp -- "${tmp}" "${OUTPUT_FILE}"
    log::ok "Written to ${OUTPUT_FILE}"
  else
    cat "${tmp}"
  fi

  log::ok "Done."
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔌 ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main "$@"