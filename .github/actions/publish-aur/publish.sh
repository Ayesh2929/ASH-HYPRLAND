#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                           ║
# ║  🏗️ ASH DOTFILES v5.0 OMEGA — AUR PUBLICATION ENGINE                                     ║
# ║                                                                                           ║
# ║  ██████╗ ██╗   ██╗██████╗ ██╗     ██╗███████╗██╗  ██╗  ░██████╗██╗  ██╗                 ║
# ║  ██╔══██╗██║   ██║██╔══██╗██║     ██║██╔════╝██║  ██║  ██╔════╝██║  ██║                 ║
# ║  ██████╔╝██║   ██║██████╔╝██║     ██║███████╗███████║  ╚█████╗░███████╗                 ║
# ║  ██╔═══╝ ██║   ██║██╔══██╗██║     ██║╚════██║██╔══██║  ░╚═══██╗██╔══██╗                 ║
# ║  ██║     ╚██████╔╝██████╔╝███████╗██║███████║██║  ██║  ██████╔╝██║  ██║                 ║
# ║  ╚═╝      ╚═════╝ ╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝  ╚═════╝░╚═╝  ╚═╝                 ║
# ║                                                                                           ║
# ║  ─────────────────────────────────────────────────────────────────────────────────────── ║
# ║                                                                                           ║
# ║  Version:  5.0.0-omega                                                                   ║
# ║  Pipeline: preflight → ssh-setup → aur-check → srcinfo → aur-clone →                    ║
# ║            aur-update → aur-push → api-verify → github-tag → cleanup                    ║
# ║                                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ─────────────────────────────────────────────────────────────────────────────
# VERSION & CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────
readonly PUBLISH_VERSION="5.0.0-omega"
readonly START_EPOCH=$(date +%s)
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─────────────────────────────────────────────────────────────────────────────
# ENVIRONMENT VARIABLES (from action.yml env block)
# ─────────────────────────────────────────────────────────────────────────────
PACKAGE_NAME="${PACKAGE_NAME:?PACKAGE_NAME required}"
PACKAGE_VERSION="${PACKAGE_VERSION:?PACKAGE_VERSION required}"
PACKAGE_RELEASE="${PACKAGE_RELEASE:-1}"
FULL_VERSION="${FULL_VERSION:-${PACKAGE_VERSION}-${PACKAGE_RELEASE}}"
AUR_GIT_URL="${AUR_GIT_URL:?AUR_GIT_URL required}"
SOURCE_URL="${SOURCE_URL:-}"
SHA256SUM="${SHA256SUM:-SKIP}"
DESCRIPTION="${DESCRIPTION:-ASH Dotfiles v5.0 OMEGA}"
AUR_SSH_PRIVATE_KEY="${AUR_SSH_PRIVATE_KEY:?AUR_SSH_PRIVATE_KEY required}"
AUR_USERNAME="${AUR_USERNAME:-ash-dotfiles-bot}"
AUR_EMAIL="${AUR_EMAIL:-ash-bot@dotfiles.dev}"
DRY_RUN="${DRY_RUN:-false}"
FORCE_PUSH="${FORCE_PUSH:-false}"
SKIP_IF_PUBLISHED="${SKIP_IF_PUBLISHED:-true}"
MAX_RETRIES="${MAX_RETRIES:-3}"
RETRY_DELAY="${RETRY_DELAY:-10}"
ROLLBACK="${ROLLBACK:-true}"
COMMIT_MSG_TPL="${COMMIT_MSG_TPL:-upgpkg: {PACKAGE_NAME} {VERSION}-{PKGREL}}"
VERBOSE="${VERBOSE:-false}"
WORK_DIR="${WORK_DIR:-/tmp/.aur-publish}"
WORKSPACE="${WORKSPACE:-$(pwd)}"
START_TIME="${START_TIME:-${START_EPOCH}}"

# ─────────────────────────────────────────────────────────────────────────────
# CATPPUCCIN MOCHA ANSI PALETTE
# ─────────────────────────────────────────────────────────────────────────────
C_RST=$'\033[0m'   C_BLD=$'\033[1m'   C_DIM=$'\033[2m'
C_MAUVE=$'\033[38;2;203;166;247m'   C_BLUE=$'\033[38;2;137;180;250m'
C_GREEN=$'\033[38;2;166;227;161m'   C_RED=$'\033[38;2;243;139;168m'
C_YELLOW=$'\033[38;2;249;226;175m'  C_PEACH=$'\033[38;2;250;179;135m'
C_TEAL=$'\033[38;2;148;226;213m'    C_SAP=$'\033[38;2;116;199;236m'
C_TEXT=$'\033[38;2;205;214;244m'    C_SUB=$'\033[38;2;166;173;200m'
C_OVR=$'\033[38;2;108;112;134m'     C_LAV=$'\033[38;2;180;190;254m'
C_PINK=$'\033[38;2;245;194;231m'    C_MAR=$'\033[38;2;235;160;172m'

# ─────────────────────────────────────────────────────────────────────────────
# LOGGING
# ─────────────────────────────────────────────────────────────────────────────
readonly LOG_FILE="${WORK_DIR}/publish-${PACKAGE_NAME}.log"
mkdir -p "${WORK_DIR}"

_log() {
  local icon="$1" color="$2"; shift 2
  local ts; ts=$(date '+%H:%M:%S')
  local elapsed=$(( $(date +%s) - START_EPOCH ))
  printf "${color}${icon}${C_RST} ${C_DIM}[%s +%ds]${C_RST} ${C_TEXT}%s${C_RST}\n" \
    "${ts}" "${elapsed}" "$*"
  printf "[%s] %s %s\n" "${ts}" "${icon}" "$*" >> "${LOG_FILE}"
}

log_step()    { _log "🔹" "${C_MAUVE}"  "$@"; }
log_pass()    { _log "✅" "${C_GREEN}"  "$@"; }
log_fail()    { _log "❌" "${C_RED}"    "$@"; }
log_warn()    { _log "⚠️ " "${C_YELLOW}" "$@"; }
log_info()    { _log "ℹ️ " "${C_BLUE}"   "$@"; }
log_aur()     { _log "🏗️ " "${C_SAP}"    "$@"; }
log_git()     { _log "📋" "${C_PEACH}"  "$@"; }
log_ssh()     { _log "🔑" "${C_TEAL}"   "$@"; }
log_dry()     { _log "🔍" "${C_LAV}"    "$@"; }
log_debug()   { [[ "${VERBOSE}" == "true" ]] && _log "🔎" "${C_OVR}" "$@" || true; }

section() {
  local title="$1" icon="${2:-🔹}" color="${3:-${C_SAP}}"
  echo ""
  echo -e "  ${color}${C_BLD}━━━ ${icon} ${title} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RST}"
}

# ─────────────────────────────────────────────────────────────────────────────
# STATE TRACKING
# ─────────────────────────────────────────────────────────────────────────────
PUBLISHED="false"
SKIPPED="false"
ROLLEDBACK="false"
AUR_GIT_COMMIT=""
PREVIOUS_VERSION=""
AUR_CLONED="false"
AUR_CLONE_DIR="${WORK_DIR}/aur-repo"

# ─────────────────────────────────────────────────────────────────────────────
# BANNER
# ─────────────────────────────────────────────────────────────────────────────
print_banner() {
  echo ""
  echo -e "${C_BLUE}${C_BLD}"
  cat << 'BANNER'
  ╔══════════════════════════════════════════════════════════════════╗
  ║  🏗️  ASH AUR Publication Engine v5.0.0-omega                     ║
  ╚══════════════════════════════════════════════════════════════════╝
BANNER
  echo -e "${C_RST}"
  printf  "  ${C_TEXT}Package:   ${C_MAUVE}${C_BLD}%-40s${C_RST}\n" "${PACKAGE_NAME}"
  printf  "  ${C_TEXT}Version:   ${C_SAP}%-40s${C_RST}\n" "${FULL_VERSION}"
  printf  "  ${C_TEXT}AUR URL:   ${C_OVR}%-40s${C_RST}\n" "${AUR_GIT_URL}"
  printf  "  ${C_TEXT}Dry Run:   ${C_YELLOW}%-40s${C_RST}\n" "${DRY_RUN}"
  echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# SSH SETUP
# ─────────────────────────────────────────────────────────────────────────────
setup_ssh() {
  section "SSH Key Setup" "🔑" "${C_TEAL}"

  SSH_DIR="${HOME}/.ssh"
  mkdir -p "${SSH_DIR}"
  chmod 700 "${SSH_DIR}"

  # Write private key
  local KEY_FILE="${SSH_DIR}/aur_ed25519"
  printf '%s' "${AUR_SSH_PRIVATE_KEY}" > "${KEY_FILE}"
  chmod 600 "${KEY_FILE}"
  log_ssh "Private key written to ${KEY_FILE}"

  # Configure SSH for AUR
  cat > "${SSH_DIR}/config" << SSH_CONF
Host aur.archlinux.org
    HostName aur.archlinux.org
    User aur
    IdentityFile ${KEY_FILE}
    IdentitiesOnly yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
    ConnectTimeout 30
    ServerAliveInterval 60
    ServerAliveCountMax 3
SSH_CONF
  chmod 600 "${SSH_DIR}/config"
  log_pass "SSH config written"

  # Validate key format
  if ssh-keygen -lf "${KEY_FILE}" &>/dev/null; then
    local KEY_TYPE; KEY_TYPE=$(ssh-keygen -lf "${KEY_FILE}" 2>/dev/null | awk '{print $4}')
    log_pass "SSH key valid: ${KEY_TYPE}"
  else
    log_warn "Could not validate SSH key format — continuing"
  fi

  # Test AUR connectivity (non-fatal)
  log_ssh "Testing AUR SSH connectivity..."
  if timeout 15 ssh -q -o BatchMode=yes \
    -o ConnectTimeout=10 \
    -o StrictHostKeyChecking=no \
    aur@aur.archlinux.org help 2>/dev/null; then
    log_pass "AUR SSH connection: OK"
  else
    log_warn "AUR SSH test inconclusive (may still work)"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# AUR VERSION CHECK
# ─────────────────────────────────────────────────────────────────────────────
check_aur_version() {
  section "AUR Version Check" "🔍" "${C_YELLOW}"

  log_info "Querying AUR API for current version..."

  local AUR_API="https://aur.archlinux.org/rpc/v5/info/${PACKAGE_NAME}"
  local RESPONSE
  RESPONSE=$(curl -sSf \
    --retry 3 --retry-delay 2 \
    --connect-timeout 10 \
    --max-time 30 \
    "${AUR_API}" 2>/dev/null || echo '{"resultcount":0}')

  local RESULT_COUNT; RESULT_COUNT=$(echo "${RESPONSE}" | jq '.resultcount // 0' 2>/dev/null || echo 0)

  if [[ "${RESULT_COUNT}" -eq 0 ]]; then
    log_info "Package not found on AUR — will create new entry"
    PREVIOUS_VERSION="none"
    return 0
  fi

  local CURRENT_VER; CURRENT_VER=$(echo "${RESPONSE}" | jq -r '.results[0].Version // "unknown"' 2>/dev/null || echo "unknown")
  local CURRENT_VOTES; CURRENT_VOTES=$(echo "${RESPONSE}" | jq -r '.results[0].NumVotes // 0' 2>/dev/null || echo 0)
  local CURRENT_POPULARITY; CURRENT_POPULARITY=$(echo "${RESPONSE}" | jq -r '.results[0].Popularity // 0' 2>/dev/null || echo 0)

  PREVIOUS_VERSION="${CURRENT_VER}"

  log_info "Current AUR version: ${CURRENT_VER}"
  log_info "Votes: ${CURRENT_VOTES} · Popularity: ${CURRENT_POPULARITY}"

  if [[ "${CURRENT_VER}" == "${FULL_VERSION}" ]] && \
     [[ "${SKIP_IF_PUBLISHED}" == "true" ]] && \
     [[ "${FORCE_PUSH}" != "true" ]]; then
    log_warn "Version ${FULL_VERSION} already published on AUR"
    SKIPPED="true"
    return 1
  fi

  if [[ "${CURRENT_VER}" == "${FULL_VERSION}" ]]; then
    log_warn "Same version — force_push will update PKGBUILD only"
  else
    log_pass "Version update: ${CURRENT_VER} → ${FULL_VERSION}"
  fi

  return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# GENERATE .SRCINFO
# ─────────────────────────────────────────────────────────────────────────────
generate_srcinfo() {
  section ".SRCINFO Generation" "📋" "${C_BLUE}"

  local PKGBUILD="${WORK_DIR}/PKGBUILD"
  local SRCINFO="${WORK_DIR}/.SRCINFO"

  if [[ ! -f "${PKGBUILD}" ]]; then
    log_fail "PKGBUILD not found at ${PKGBUILD}"
    return 1
  fi

  log_info "Generating .SRCINFO from PKGBUILD..."

  # Generate .SRCINFO from PKGBUILD using Python (no makepkg available)
  python3 << SRCINFO_EOF
import re
import os
from pathlib import Path

PKGBUILD_PATH = "${WORK_DIR}/PKGBUILD"
SRCINFO_PATH  = "${WORK_DIR}/.SRCINFO"
PKG_NAME    = "${PACKAGE_NAME}"
VERSION     = "${PACKAGE_VERSION}"
PKGREL      = "${PACKAGE_RELEASE}"
SHA256      = "${SHA256SUM}"
SOURCE_URL  = "${SOURCE_URL}"
DESCRIPTION = "${DESCRIPTION}"
REPO        = os.environ.get("GITHUB_REPOSITORY","ash/dotfiles")

content = Path(PKGBUILD_PATH).read_text()

def extract_array(field, text):
    """Extract array value from PKGBUILD."""
    # Match: field=('a' 'b' 'c') or field=("a" "b" "c")
    pattern = rf"^{field}=\(([^)]+)\)"
    m = re.search(pattern, text, re.MULTILINE | re.DOTALL)
    if m:
        items = re.findall(r"['\"]([^'\"]+)['\"]|(\S+)", m.group(1))
        return [a or b for a, b in items if a or b]
    return []

def extract_value(field, text, default=""):
    """Extract single value from PKGBUILD."""
    m = re.search(rf'^{field}=["\']?([^"\'\\n]+)["\']?', text, re.MULTILINE)
    return m.group(1).strip() if m else default

# Parse PKGBUILD fields
arch     = extract_array("arch",     content) or ["x86_64", "aarch64"]
depends  = extract_array("depends",  content) or []
optdeps  = extract_array("optdepends",content) or []
makedeps = extract_array("makedepends",content) or []
conflicts= extract_array("conflicts",content) or []
provides = extract_array("provides", content) or []
url      = extract_value("url",      content, f"https://github.com/{REPO}")
license_ = extract_array("license",  content) or ["MIT"]

# Build .SRCINFO
lines = [
    "pkgbase = " + PKG_NAME,
    "\tpkgdesc = " + DESCRIPTION,
    "\tpkgver = " + VERSION,
    "\tpkgrel = " + PKGREL,
    "\turl = " + url,
]

for a in arch:
    lines.append(f"\tarch = {a}")
for lic in license_:
    lines.append(f"\tlicense = {lic}")
for dep in makedeps:
    lines.append(f"\tmakedepends = {dep}")
for dep in depends:
    lines.append(f"\tdepends = {dep}")
for dep in optdeps:
    lines.append(f"\toptdepends = {dep}")
for c in conflicts:
    lines.append(f"\tconflicts = {c}")
for p in provides:
    lines.append(f"\tprovides = {p}")

# Source entry
src_name = f"{PKG_NAME}-{VERSION}.tar.gz"
lines.append(f"\tsource = {src_name}::{SOURCE_URL}")
lines.append(f"\tsha256sums = {SHA256}")

lines.append("")
lines.append("pkgname = " + PKG_NAME)
lines.append("")

SRCINFO_CONTENT = "\n".join(lines)
Path(SRCINFO_PATH).write_text(SRCINFO_CONTENT)

print(f"  ✅ .SRCINFO generated ({len(lines)} lines)")
print(f"     pkgver: {VERSION}")
print(f"     arch:   {', '.join(arch)}")
print(f"     deps:   {len(depends)} runtime, {len(makedeps)} build")
SRCINFO_EOF

  log_pass ".SRCINFO generated: ${SRCINFO}"
}

# ─────────────────────────────────────────────────────────────────────────────
# AUR CLONE
# ─────────────────────────────────────────────────────────────────────────────
clone_aur() {
  section "AUR Repository Clone" "📋" "${C_PEACH}"

  rm -rf "${AUR_CLONE_DIR}"
  mkdir -p "$(dirname "${AUR_CLONE_DIR}")"

  log_git "Cloning AUR repo: ${AUR_GIT_URL}"

  local attempt=0
  while (( attempt < MAX_RETRIES )); do
    ((attempt++)) || true
    log_debug "Clone attempt ${attempt}/${MAX_RETRIES}"

    if git clone \
      --config "user.name=${AUR_USERNAME}" \
      --config "user.email=${AUR_EMAIL}" \
      "${AUR_GIT_URL}" \
      "${AUR_CLONE_DIR}" \
      2>/dev/null; then
      AUR_CLONED="true"
      break
    fi

    if [[ "${attempt}" -ge "${MAX_RETRIES}" ]]; then
      log_warn "AUR clone failed — initializing new repository"
      # Package doesn't exist on AUR yet — create new
      mkdir -p "${AUR_CLONE_DIR}"
      git -C "${AUR_CLONE_DIR}" init
      git -C "${AUR_CLONE_DIR}" remote add origin "${AUR_GIT_URL}"
      git -C "${AUR_CLONE_DIR}" config user.name "${AUR_USERNAME}"
      git -C "${AUR_CLONE_DIR}" config user.email "${AUR_EMAIL}"
      AUR_CLONED="true"
      break
    fi

    log_warn "Clone attempt ${attempt} failed — retrying in ${RETRY_DELAY}s"
    sleep "${RETRY_DELAY}"
  done

  if [[ "${AUR_CLONED}" != "true" ]]; then
    log_fail "Failed to clone/init AUR repository"
    return 1
  fi

  # Configure git for AUR
  git -C "${AUR_CLONE_DIR}" config user.name  "${AUR_USERNAME}"
  git -C "${AUR_CLONE_DIR}" config user.email "${AUR_EMAIL}"
  git -C "${AUR_CLONE_DIR}" config core.autocrlf false

  # Save previous version if exists
  if [[ -f "${AUR_CLONE_DIR}/PKGBUILD" ]]; then
    PREVIOUS_PKGBUILD=$(cat "${AUR_CLONE_DIR}/PKGBUILD")
    log_info "Previous PKGBUILD preserved for rollback"
  fi

  log_pass "AUR repository ready at ${AUR_CLONE_DIR}"
}

# ─────────────────────────────────────────────────────────────────────────────
# AUR UPDATE & PUSH
# ─────────────────────────────────────────────────────────────────────────────
update_and_push() {
  section "AUR Update & Push" "🚀" "${C_MAUVE}"

  # Copy generated files to AUR clone
  log_aur "Copying PKGBUILD and .SRCINFO to AUR clone..."
  cp "${WORK_DIR}/PKGBUILD" "${AUR_CLONE_DIR}/PKGBUILD"
  cp "${WORK_DIR}/.SRCINFO" "${AUR_CLONE_DIR}/.SRCINFO"

  # Copy install file if exists
  if [[ -f "${WORK_DIR}/ash-dotfiles.install" ]]; then
    cp "${WORK_DIR}/ash-dotfiles.install" "${AUR_CLONE_DIR}/${PACKAGE_NAME}.install"
    log_debug "Install file copied"
  fi

  # Show diff
  cd "${AUR_CLONE_DIR}"
  if git diff --quiet && git diff --staged --quiet; then
    if [[ "${FORCE_PUSH}" != "true" ]]; then
      log_warn "No changes detected in PKGBUILD — skipping push"
      log_warn "Use force_push=true to override"
      SKIPPED="true"
      return 0
    fi
    log_warn "No changes detected but force_push=true — continuing"
  fi

  log_aur "Git diff summary:"
  git diff --stat 2>/dev/null | head -10 || true

  # Stage all files
  git add -A
  git status --short | while IFS= read -r line; do
    log_debug "git: ${line}"
  done

  # Build commit message
  local DATE; DATE=$(date +%Y-%m-%d)
  local COMMIT_MSG="${COMMIT_MSG_TPL}"
  COMMIT_MSG="${COMMIT_MSG//\{PACKAGE_NAME\}/${PACKAGE_NAME}}"
  COMMIT_MSG="${COMMIT_MSG//\{VERSION\}/${PACKAGE_VERSION}}"
  COMMIT_MSG="${COMMIT_MSG//\{PKGREL\}/${PACKAGE_RELEASE}}"
  COMMIT_MSG="${COMMIT_MSG//\{DATE\}/${DATE}}"

  log_git "Commit: ${COMMIT_MSG}"

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_dry "[DRY RUN] Would commit: ${COMMIT_MSG}"
    log_dry "[DRY RUN] Would push to: ${AUR_GIT_URL}"
    AUR_GIT_COMMIT="dryrun-$(date +%s)"
    PUBLISHED="true"
    log_pass "Dry run complete — no actual push performed"
    return 0
  fi

  # Commit
  git commit -m "${COMMIT_MSG}" \
    --allow-empty-message=false \
    2>&1 | while IFS= read -r line; do
      log_debug "commit: ${line}"
    done

  AUR_GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
  log_pass "Committed: ${AUR_GIT_COMMIT:0:12}"

  # Push with retry
  local PUSH_SUCCESS=false
  local attempt=0

  while (( attempt < MAX_RETRIES )) && [[ "${PUSH_SUCCESS}" == "false" ]]; do
    ((attempt++)) || true
    log_aur "Push attempt ${attempt}/${MAX_RETRIES}..."

    if git push origin master 2>&1 | while IFS= read -r line; do
        log_debug "push: ${line}"
      done; then
      PUSH_SUCCESS=true
      PUBLISHED="true"
      log_pass "Pushed to AUR: ${PACKAGE_NAME} ${FULL_VERSION}"
    else
      if [[ "${attempt}" -lt "${MAX_RETRIES}" ]]; then
        log_warn "Push attempt ${attempt} failed — retrying in ${RETRY_DELAY}s"
        sleep "${RETRY_DELAY}"
        # Re-pull in case of conflict
        git pull --rebase origin master 2>/dev/null || true
      fi
    fi
  done

  if [[ "${PUSH_SUCCESS}" == "false" ]]; then
    log_fail "All push attempts failed"
    return 1
  fi

  cd "${WORKSPACE}"
}

# ─────────────────────────────────────────────────────────────────────────────
# ROLLBACK
# ─────────────────────────────────────────────────────────────────────────────
perform_rollback() {
  section "Rollback" "🔄" "${C_RED}"

  if [[ "${ROLLBACK}" != "true" ]]; then
    log_warn "Rollback disabled (rollback_on_failure=false)"
    return 0
  fi

  if [[ "${AUR_CLONED}" != "true" ]] || [[ ! -d "${AUR_CLONE_DIR}" ]]; then
    log_warn "AUR clone not available — cannot rollback"
    return 0
  fi

  if [[ -z "${PREVIOUS_PKGBUILD:-}" ]]; then
    log_warn "No previous PKGBUILD saved — cannot rollback"
    return 0
  fi

  log_aur "Attempting rollback to ${PREVIOUS_VERSION}..."

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_dry "[DRY RUN] Would rollback to ${PREVIOUS_VERSION}"
    ROLLEDBACK="true"
    return 0
  fi

  cd "${AUR_CLONE_DIR}"

  # Try git reset first
  if git log --oneline -2 2>/dev/null | grep -q "."; then
    git reset --hard HEAD~1 2>/dev/null || true
    if git push --force-with-lease origin master 2>/dev/null; then
      ROLLEDBACK="true"
      log_pass "Rolled back to ${PREVIOUS_VERSION}"
      return 0
    fi
  fi

  # Fallback: restore previous PKGBUILD content
  echo "${PREVIOUS_PKGBUILD}" > "${AUR_CLONE_DIR}/PKGBUILD"
  git add PKGBUILD
  git commit -m "revert: rollback from ${FULL_VERSION} to ${PREVIOUS_VERSION}" \
    2>/dev/null || true

  if git push origin master 2>/dev/null; then
    ROLLEDBACK="true"
    log_pass "Rollback push successful"
  else
    log_fail "Rollback push failed — manual intervention required"
  fi

  cd "${WORKSPACE}"
}

# ─────────────────────────────────────────────────────────────────────────────
# POST-PUBLISH API VERIFICATION
# ─────────────────────────────────────────────────────────────────────────────
verify_publication() {
  section "Post-Publish Verification" "📡" "${C_GREEN}"

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_dry "[DRY RUN] Skipping AUR API verification"
    return 0
  fi

  log_info "Waiting 30s for AUR to index new package..."
  sleep 30

  local AUR_API="https://aur.archlinux.org/rpc/v5/info/${PACKAGE_NAME}"
  local MAX_WAIT=120
  local WAIT_INTERVAL=15
  local WAITED=0
  local VERIFIED=false

  while [[ "${WAITED}" -lt "${MAX_WAIT}" ]]; do
    local RESPONSE
    RESPONSE=$(curl -sSf \
      --retry 2 --retry-delay 3 \
      --connect-timeout 10 \
      --max-time 20 \
      "${AUR_API}" 2>/dev/null || echo '{"resultcount":0}')

    local AUR_VER
    AUR_VER=$(echo "${RESPONSE}" | jq -r '.results[0].Version // ""' 2>/dev/null || echo "")

    if [[ "${AUR_VER}" == "${FULL_VERSION}" ]]; then
      log_pass "AUR API confirms: ${PACKAGE_NAME} ${FULL_VERSION} ✅"
      VERIFIED=true
      break
    fi

    log_info "AUR shows: ${AUR_VER:-not indexed yet} — waiting ${WAIT_INTERVAL}s..."
    sleep "${WAIT_INTERVAL}"
    WAITED=$(( WAITED + WAIT_INTERVAL ))
  done

  if [[ "${VERIFIED}" == "false" ]]; then
    log_warn "AUR verification timed out — package may need more time to index"
    log_warn "Manual check: https://aur.archlinux.org/packages/${PACKAGE_NAME}"
  fi

  echo "aur_url=https://aur.archlinux.org/packages/${PACKAGE_NAME}" >> "${GITHUB_OUTPUT:-/dev/null}"
}

# ─────────────────────────────────────────────────────────────────────────────
# GITHUB TAG CREATION
# ─────────────────────────────────────────────────────────────────────────────
create_github_tag() {
  section "GitHub Tag" "🏷️" "${C_LAVENDER}"

  local TAG_PREFIX="${GIT_TAG_PREFIX:-v}"
  local TAG_NAME="${TAG_PREFIX}${PACKAGE_VERSION}"

  if [[ "${CREATE_GIT_TAG:-true}" != "true" ]]; then
    log_info "Git tag creation disabled"
    return 0
  fi

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_dry "[DRY RUN] Would create tag: ${TAG_NAME}"
    return 0
  fi

  # Check if tag already exists
  if git tag -l "${TAG_NAME}" 2>/dev/null | grep -q "${TAG_NAME}"; then
    log_info "Tag ${TAG_NAME} already exists — skipping"
    return 0
  fi

  git config user.name  "${AUR_USERNAME}"
  git config user.email "${AUR_EMAIL}"

  git tag -a "${TAG_NAME}" \
    -m "Release ${PACKAGE_VERSION} — AUR: ${FULL_VERSION}" \
    2>/dev/null && \
    log_pass "Tag created: ${TAG_NAME}" || \
    log_warn "Tag creation failed — continuing"

  # Push tag (non-fatal)
  git push origin "${TAG_NAME}" 2>/dev/null && \
    log_pass "Tag pushed: ${TAG_NAME}" || \
    log_warn "Tag push failed — continuing"
}

# ─────────────────────────────────────────────────────────────────────────────
# FINAL REPORTING
# ─────────────────────────────────────────────────────────────────────────────
emit_outputs() {
  local END_EPOCH; END_EPOCH=$(date +%s)
  local DURATION=$(( END_EPOCH - START_EPOCH ))

  {
    echo "published=${PUBLISHED}"
    echo "skipped=${SKIPPED}"
    echo "rolledback=${ROLLEDBACK}"
    echo "aur_git_commit=${AUR_GIT_COMMIT}"
    echo "aur_url=https://aur.archlinux.org/packages/${PACKAGE_NAME}"
    echo "duration_s=${DURATION}"
  } >> "${GITHUB_OUTPUT:-/dev/null}"
}

print_final_summary() {
  local END_EPOCH; END_EPOCH=$(date +%s)
  local DURATION=$(( END_EPOCH - START_EPOCH ))

  local STATUS_ICON STATUS_TEXT STATUS_COLOR
  if [[ "${PUBLISHED}" == "true" ]]; then
    STATUS_ICON="✅"; STATUS_TEXT="PUBLISHED"; STATUS_COLOR="${C_GREEN}"
  elif [[ "${SKIPPED}" == "true" ]]; then
    STATUS_ICON="⏭️"; STATUS_TEXT="SKIPPED";   STATUS_COLOR="${C_YELLOW}"
  elif [[ "${ROLLEDBACK}" == "true" ]]; then
    STATUS_ICON="🔄"; STATUS_TEXT="ROLLED BACK";STATUS_COLOR="${C_MAR}"
  else
    STATUS_ICON="❌"; STATUS_TEXT="FAILED";    STATUS_COLOR="${C_RED}"
  fi

  echo ""
  echo -e "  ${C_BLUE}${C_BLD}╔══════════════════════════════════════════════════════════════╗${C_RST}"
  echo -e "  ${C_BLUE}${C_BLD}║  🏗️  AUR PUBLISH COMPLETE                                     ║${C_RST}"
  echo -e "  ${C_BLUE}${C_BLD}╠══════════════════════════════════════════════════════════════╣${C_RST}"
  printf  "  ${C_BLUE}${C_BLD}║${C_RST}  ${C_TEXT}Status:   ${STATUS_COLOR}${C_BLD}%-52s${C_RST}${C_BLUE}${C_BLD}║${C_RST}\n" "${STATUS_ICON} ${STATUS_TEXT}"
  printf  "  ${C_BLUE}${C_BLD}║${C_RST}  ${C_TEXT}Package:  ${C_MAUVE}%-52s${C_RST}${C_BLUE}${C_BLD}║${C_RST}\n" "${PACKAGE_NAME}"
  printf  "  ${C_BLUE}${C_BLD}║${C_RST}  ${C_TEXT}Version:  ${C_SAP}%-52s${C_RST}${C_BLUE}${C_BLD}║${C_RST}\n" "${FULL_VERSION}"
  printf  "  ${C_BLUE}${C_BLD}║${C_RST}  ${C_TEXT}Commit:   ${C_PEACH}%-52s${C_RST}${C_BLUE}${C_BLD}║${C_RST}\n" "${AUR_GIT_COMMIT:0:12:-...}"
  printf  "  ${C_BLUE}${C_BLD}║${C_RST}  ${C_TEXT}Duration: ${C_TEAL}%-52s${C_RST}${C_BLUE}${C_BLD}║${C_RST}\n" "${DURATION}s"
  echo -e "  ${C_BLUE}${C_BLD}╚══════════════════════════════════════════════════════════════╝${C_RST}"
  echo ""

  local AUR_PAGE="https://aur.archlinux.org/packages/${PACKAGE_NAME}"
  echo -e "  ${C_OVR}📖 AUR Page: ${AUR_PAGE}${C_RST}"

  if [[ "${PUBLISHED}" == "true" && "${DRY_RUN}" != "true" ]]; then
    echo ""
    echo -e "  ${C_GREEN}${C_BLD}Install with paru:${C_RST}"
    echo -e "  ${C_TEXT}  paru -S ${PACKAGE_NAME}${C_RST}"
    echo ""
    echo -e "  ${C_GREEN}${C_BLD}Install with yay:${C_RST}"
    echo -e "  ${C_TEXT}  yay -S ${PACKAGE_NAME}${C_RST}"
  fi

  echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# TRAP — Graceful failure & rollback
# ─────────────────────────────────────────────────────────────────────────────
trap 'EXIT_CODE=$?
if [[ $EXIT_CODE -ne 0 ]]; then
  log_fail "Pipeline failed with exit code ${EXIT_CODE}"
  if [[ "${PUBLISHED}" != "true" && "${AUR_CLONED}" == "true" ]]; then
    perform_rollback || true
  fi
  emit_outputs
  print_final_summary
fi
# Cleanup SSH key
rm -f "${HOME}/.ssh/aur_ed25519" 2>/dev/null || true
' EXIT

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
main() {
  print_banner

  # ── SSH Setup ──────────────────────────────────────────────────────────────
  setup_ssh || {
    log_fail "SSH setup failed"
    exit 1
  }

  # ── AUR Version Check ──────────────────────────────────────────────────────
  if ! check_aur_version; then
    if [[ "${SKIPPED}" == "true" ]]; then
      log_info "Package already at ${FULL_VERSION} on AUR — skipping"
      emit_outputs
      print_final_summary
      exit 0
    fi
    exit 1
  fi

  # ── Generate .SRCINFO ─────────────────────────────────────────────────────
  generate_srcinfo || {
    log_fail ".SRCINFO generation failed"
    exit 1
  }

  # ── Clone AUR repo ────────────────────────────────────────────────────────
  clone_aur || {
    log_fail "AUR clone failed"
    exit 1
  }

  # ── Update & Push ─────────────────────────────────────────────────────────
  update_and_push || {
    log_fail "AUR push failed"
    perform_rollback || true
    emit_outputs
    exit 1
  }

  # ── Post-publish verification ─────────────────────────────────────────────
  [[ "${PUBLISHED}" == "true" ]] && verify_publication || true

  # ── GitHub tag ────────────────────────────────────────────────────────────
  [[ "${PUBLISHED}" == "true" ]] && create_github_tag || true

  # ── Final outputs ─────────────────────────────────────────────────────────
  emit_outputs
  print_final_summary

  [[ "${PUBLISHED}" == "true" || "${SKIPPED}" == "true" ]]
}

main "$@"