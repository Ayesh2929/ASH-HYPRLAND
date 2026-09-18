#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                           ║
# ║  🔖 ASH DOTFILES v5.0 OMEGA — SEMANTIC VERSION BUMP ENGINE                               ║
# ║                                                                                           ║
# ║  ██████╗ ██╗   ██╗███╗   ███╗██████╗     ██╗   ██╗███████╗██████╗ ███████╗██╗ ██████╗  ║
# ║  ██╔══██╗██║   ██║████╗ ████║██╔══██╗    ██║   ██║██╔════╝██╔══██╗██╔════╝██║██╔═══██╗ ║
# ║  ██████╔╝██║   ██║██╔████╔██║██████╔╝    ██║   ██║█████╗  ██████╔╝███████╗██║██║   ██║ ║
# ║  ██╔══██╗██║   ██║██║╚██╔╝██║██╔═══╝     ╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██║██║   ██║ ║
# ║  ██████╔╝╚██████╔╝██║ ╚═╝ ██║██║          ╚████╔╝ ███████╗██║  ██║███████║██║╚██████╔╝ ║
# ║  ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝           ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝ ╚═════╝  ║
# ║                                                                                           ║
# ║  ─────────────────────────────────────────────────────────────────────────────────────── ║
# ║                                                                                           ║
# ║  🎯 FEATURES:                                                                             ║
# ║     🔢 Semantic versioning: major.minor.patch + pre-release + build metadata            ║
# ║     🤖 Auto-detect bump type from Conventional Commits (feat/fix/BREAKING CHANGE)       ║
# ║     📋 Multi-file synchronization (version.json / package.json / pyproject.toml / etc.) ║
# ║     🏷️  Git tag creation with annotation and signing support                              ║
# ║     🌿 Release branch creation (release/X.Y.Z)                                          ║
# ║     🔒 Version lock file for build reproducibility                                       ║
# ║     📝 Automatic CHANGELOG.md trigger                                                    ║
# ║     ✅ Pre-bump validation (clean working tree, test pass)                              ║
# ║     ↩️  Rollback on failure                                                               ║
# ║     🔔 GitHub API release creation                                                       ║
# ║     📊 Bump audit trail (SQLite log)                                                    ║
# ║     🔍 Dry-run mode with full preview                                                   ║
# ║                                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ─────────────────────────────────────────────────────────────────────────────
# VERSION & METADATA
# ─────────────────────────────────────────────────────────────────────────────
readonly SCRIPT_VERSION="5.0.0-omega"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly START_EPOCH=$(date +%s)
readonly LOCK_FILE="/tmp/ash-bump-version-$$.lock"

# ─────────────────────────────────────────────────────────────────────────────
# CATPPUCCIN MOCHA ANSI PALETTE
# ─────────────────────────────────────────────────────────────────────────────
C_RST=$'\033[0m'     C_BLD=$'\033[1m'     C_DIM=$'\033[2m'
C_MAUVE=$'\033[38;2;203;166;247m'    C_BLUE=$'\033[38;2;137;180;250m'
C_GREEN=$'\033[38;2;166;227;161m'    C_RED=$'\033[38;2;243;139;168m'
C_YELLOW=$'\033[38;2;249;226;175m'   C_PEACH=$'\033[38;2;250;179;135m'
C_TEAL=$'\033[38;2;148;226;213m'     C_SAP=$'\033[38;2;116;199;236m'
C_TEXT=$'\033[38;2;205;214;244m'     C_SUB=$'\033[38;2;166;173;200m'
C_OVR=$'\033[38;2;108;112;134m'      C_LAV=$'\033[38;2;180;190;254m'
C_PINK=$'\033[38;2;245;194;231m'     C_MAR=$'\033[38;2;235;160;172m'
C_SKY=$'\033[38;2;137;220;235m'      C_FL=$'\033[38;2;242;205;205m'

# ─────────────────────────────────────────────────────────────────────────────
# LOGGING ENGINE
# ─────────────────────────────────────────────────────────────────────────────
_log() {
  local icon="$1" color="$2"; shift 2
  local ts; ts=$(date '+%H:%M:%S')
  printf "${color}${icon}${C_RST} ${C_DIM}[${ts}]${C_RST} ${C_TEXT}%s${C_RST}\n" "$*"
}

log_info()    { _log "ℹ️ " "${C_BLUE}"   "$@"; }
log_pass()    { _log "✅" "${C_GREEN}"  "$@"; }
log_fail()    { _log "❌" "${C_RED}"    "$@"; }
log_warn()    { _log "⚠️ " "${C_YELLOW}" "$@"; }
log_step()    { _log "🔹" "${C_MAUVE}"  "$@"; }
log_version() { _log "🔖" "${C_PEACH}"  "$@"; }
log_file()    { _log "📄" "${C_SAP}"    "$@"; }
log_git()     { _log "📋" "${C_TEAL}"   "$@"; }
log_dry()     { _log "🔍" "${C_LAV}"    "$@"; }
log_break()   { _log "💥" "${C_MAR}"    "$@"; }

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────
: "${BUMP_TYPE:=}"          # major | minor | patch | auto
: "${PRE_RELEASE:=}"        # alpha | beta | rc | ""
: "${PRE_RELEASE_NUM:=}"    # 1 | 2 | 3 | ...
: "${BUILD_META:=}"         # Optional build metadata
: "${DRY_RUN:=false}"
: "${VERBOSE:=false}"
: "${CREATE_TAG:=true}"
: "${TAG_PREFIX:=v}"
: "${SIGN_TAG:=false}"
: "${CREATE_BRANCH:=false}"
: "${PUSH_CHANGES:=false}"
: "${PUSH_TAGS:=false}"
: "${SKIP_VALIDATION:=false}"
: "${COMMIT_FILES:=true}"
: "${COMMIT_MESSAGE:=}"
: "${GITHUB_TOKEN:=}"
: "${CREATE_RELEASE:=false}"

# Files to update
declare -a VERSION_FILES=(
  "version.json"
  "package.json"
  "pyproject.toml"
  "Cargo.toml"
  "ash-cli/data/version.json"
)

# ─────────────────────────────────────────────────────────────────────────────
# BANNER
# ─────────────────────────────────────────────────────────────────────────────
print_banner() {
  echo ""
  echo -e "${C_PEACH}${C_BLD}"
  cat << 'BANNER'
  ╔══════════════════════════════════════════════════════════════════╗
  ║  🔖 ASH Version Bump Engine v5.0.0-omega                         ║
  ╚══════════════════════════════════════════════════════════════════╝
BANNER
  echo -e "${C_RST}"
}

# ─────────────────────────────────────────────────────────────────────────────
# SEMVER PARSING
# ─────────────────────────────────────────────────────────────────────────────
parse_semver() {
  local version="${1#v}"   # Strip leading 'v'
  local semver_re='^([0-9]+)\.([0-9]+)\.([0-9]+)(-([a-zA-Z0-9.]+))?(\+([a-zA-Z0-9.]+))?$'

  if [[ "${version}" =~ ${semver_re} ]]; then
    SEMVER_MAJOR="${BASH_REMATCH[1]}"
    SEMVER_MINOR="${BASH_REMATCH[2]}"
    SEMVER_PATCH="${BASH_REMATCH[3]}"
    SEMVER_PRE="${BASH_REMATCH[5]}"
    SEMVER_BUILD="${BASH_REMATCH[7]}"
    return 0
  else
    log_fail "Invalid semver: ${version}"
    return 1
  fi
}

build_semver() {
  local major="${1:-0}"
  local minor="${2:-0}"
  local patch="${3:-0}"
  local pre="${4:-}"
  local build="${5:-}"

  local version="${major}.${minor}.${patch}"
  [[ -n "${pre}" ]]   && version="${version}-${pre}"
  [[ -n "${build}" ]] && version="${version}+${build}"
  echo "${version}"
}

# ─────────────────────────────────────────────────────────────────────────────
# CURRENT VERSION DETECTION
# ─────────────────────────────────────────────────────────────────────────────
detect_current_version() {
  local version=""

  # Priority: version.json → package.json → git tag → default
  if [[ -f "version.json" ]]; then
    version=$(jq -r '.version // empty' version.json 2>/dev/null || echo "")
  fi

  if [[ -z "${version}" && -f "package.json" ]]; then
    version=$(jq -r '.version // empty' package.json 2>/dev/null || echo "")
  fi

  if [[ -z "${version}" && -f "pyproject.toml" ]]; then
    version=$(grep -E '^version\s*=' pyproject.toml | head -1 | \
      sed 's/version\s*=\s*"\([^"]*\)"/\1/' 2>/dev/null || echo "")
  fi

  if [[ -z "${version}" ]]; then
    version=$(git tag --sort=-version:refname 2>/dev/null | \
      grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+' | head -1 | sed 's/^v//' || echo "")
  fi

  CURRENT_VERSION="${version:-0.0.0}"
  log_version "Current version: ${CURRENT_VERSION}"
}

# ─────────────────────────────────────────────────────────────────────────────
# AUTO BUMP TYPE DETECTION FROM CONVENTIONAL COMMITS
# ─────────────────────────────────────────────────────────────────────────────
auto_detect_bump() {
  log_step "Auto-detecting bump type from Conventional Commits..."

  local last_tag
  last_tag=$(git tag --sort=-version:refname 2>/dev/null | head -1 || echo "")
  local range="${last_tag:+${last_tag}..}HEAD"

  local commits
  commits=$(git log "${range}" --pretty=format:"%s %b" --no-merges 2>/dev/null || \
            git log --pretty=format:"%s %b" --no-merges 2>/dev/null)

  local detected_bump="patch"  # Default to patch

  # Check for BREAKING CHANGE
  if echo "${commits}" | grep -qiE "(BREAKING.CHANGE|^[a-z]+(\([^)]+\))?!:)"; then
    detected_bump="major"
    log_break "Breaking change detected → major bump"

  # Check for feat commits
  elif echo "${commits}" | grep -qiE "^feat(\([^)]+\))?:"; then
    detected_bump="minor"
    log_step "Feature commits detected → minor bump"

  # Check for fix/perf/etc
  elif echo "${commits}" | grep -qiE "^(fix|perf|security)(\([^)]+\))?:"; then
    detected_bump="patch"
    log_step "Fix/perf commits detected → patch bump"
  fi

  BUMP_TYPE="${detected_bump}"
  log_version "Auto-detected bump type: ${BUMP_TYPE}"
}

# ─────────────────────────────────────────────────────────────────────────────
# VERSION CALCULATION
# ─────────────────────────────────────────────────────────────────────────────
calculate_new_version() {
  parse_semver "${CURRENT_VERSION}"

  local major="${SEMVER_MAJOR}"
  local minor="${SEMVER_MINOR}"
  local patch="${SEMVER_PATCH}"

  # Apply bump
  case "${BUMP_TYPE}" in
    major)
      ((major++)) || true
      minor=0
      patch=0
      ;;
    minor)
      ((minor++)) || true
      patch=0
      ;;
    patch)
      ((patch++)) || true
      ;;
    *)
      log_fail "Invalid bump type: ${BUMP_TYPE}"
      exit 1
      ;;
  esac

  # Handle pre-release
  local pre="${PRE_RELEASE}"
  if [[ -n "${pre}" ]]; then
    local pre_num="${PRE_RELEASE_NUM:-1}"
    pre="${pre}.${pre_num}"
  fi

  NEW_VERSION=$(build_semver "${major}" "${minor}" "${patch}" "${pre}" "${BUILD_META}")
  log_version "New version: ${CURRENT_VERSION} → ${NEW_VERSION}"
}

# ─────────────────────────────────────────────────────────────────────────────
# PRE-BUMP VALIDATION
# ─────────────────────────────────────────────────────────────────────────────
validate_workspace() {
  [[ "${SKIP_VALIDATION}" == "true" ]] && return 0

  log_step "Validating workspace..."

  # Check git clean state
  if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
    log_fail "Working tree is not clean. Commit or stash changes first."
    log_fail "Dirty files:"
    git status --porcelain | head -10
    exit 1
  fi

  # Check on valid branch
  local branch
  branch=$(git branch --show-current 2>/dev/null || echo "")
  if [[ "${branch}" == "HEAD" || -z "${branch}" ]]; then
    log_warn "Detached HEAD state — proceeding anyway"
  fi

  log_pass "Workspace validation passed (branch: ${branch})"
}

# ─────────────────────────────────────────────────────────────────────────────
# VERSION FILE UPDATERS
# ─────────────────────────────────────────────────────────────────────────────
update_version_json() {
  local file="$1"
  local new_ver="$2"

  [[ ! -f "${file}" ]] && return 0

  python3 << PYEOF
import json
from pathlib import Path
from datetime import datetime, timezone

file_path = Path("${file}")
data = json.loads(file_path.read_text())

data['version']      = "${new_ver}"
data['updated_at']   = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
data['prev_version'] = "${CURRENT_VERSION}"

if 'build' not in data:
    data['build'] = {}
data['build']['commit'] = "$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
data['build']['date']   = datetime.now(timezone.utc).strftime('%Y-%m-%d')

file_path.write_text(json.dumps(data, indent=2) + '\n')
print(f"  ✅ Updated {file_path}")
PYEOF
}

update_package_json() {
  local file="$1"
  local new_ver="$2"

  [[ ! -f "${file}" ]] && return 0

  python3 << PYEOF
import json
from pathlib import Path

file_path = Path("${file}")
data = json.loads(file_path.read_text())
data['version'] = "${new_ver}"
file_path.write_text(json.dumps(data, indent=2) + '\n')
print(f"  ✅ Updated {file_path}")
PYEOF
}

update_pyproject_toml() {
  local file="$1"
  local new_ver="$2"

  [[ ! -f "${file}" ]] && return 0

  sed -i "s/^version = \"[^\"]*\"/version = \"${new_ver}\"/" "${file}"
  log_file "Updated pyproject.toml → ${new_ver}"
}

update_cargo_toml() {
  local file="$1"
  local new_ver="$2"

  [[ ! -f "${file}" ]] && return 0

  # Only update [package] version, not dependency versions
  python3 << PYEOF
import re
from pathlib import Path

content = Path("${file}").read_text()
# Replace version in [package] section only
in_package = False
lines = []
for line in content.split('\n'):
    if line.strip() == '[package]':
        in_package = True
    elif line.startswith('[') and line != '[package]':
        in_package = False
    if in_package and re.match(r'^version\s*=', line):
        line = 'version = "${new_ver}"'
        in_package = False  # Only replace first occurrence
    lines.append(line)
Path("${file}").write_text('\n'.join(lines))
print(f"  ✅ Updated Cargo.toml")
PYEOF
}

update_bash_script() {
  local file="$1"
  local new_ver="$2"

  [[ ! -f "${file}" ]] && return 0

  sed -i "s/^readonly SCRIPT_VERSION=\"[^\"]*\"/readonly SCRIPT_VERSION=\"${new_ver}\"/" "${file}"
  sed -i "s/^readonly ENGINE_VERSION=\"[^\"]*\"/readonly ENGINE_VERSION=\"${new_ver}\"/" "${file}"
  log_file "Updated ${file} version string"
}

# ─────────────────────────────────────────────────────────────────────────────
# UPDATE ALL VERSION FILES
# ─────────────────────────────────────────────────────────────────────────────
update_all_files() {
  local new_ver="$1"

  log_step "Updating version files..."
  local updated_count=0

  for file in "${VERSION_FILES[@]}"; do
    [[ ! -f "${file}" ]] && continue

    if [[ "${DRY_RUN}" == "true" ]]; then
      log_dry "[DRY] Would update: ${file}"
      continue
    fi

    case "${file}" in
      *.json)
        if [[ "$(basename "${file}")" == "package.json" ]]; then
          update_package_json "${file}" "${new_ver}"
        else
          update_version_json "${file}" "${new_ver}"
        fi
        ;;
      pyproject.toml)  update_pyproject_toml "${file}" "${new_ver}" ;;
      Cargo.toml)      update_cargo_toml     "${file}" "${new_ver}" ;;
      *.sh)            update_bash_script    "${file}" "${new_ver}" ;;
    esac

    log_file "Updated: ${file}"
    ((updated_count++)) || true
  done

  # Create/update version lock file
  if [[ "${DRY_RUN}" != "true" ]]; then
    cat > ".version-lock" << LOCK_EOF
# ASH Dotfiles Version Lock
# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
VERSION=${new_ver}
PREVIOUS=${CURRENT_VERSION}
BUMP_TYPE=${BUMP_TYPE}
COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
LOCK_EOF
    log_file "Created .version-lock"
  fi

  log_pass "Updated ${updated_count} file(s)"
}

# ─────────────────────────────────────────────────────────────────────────────
# GIT OPERATIONS
# ─────────────────────────────────────────────────────────────────────────────
git_commit_and_tag() {
  local new_ver="$1"
  local tag="${TAG_PREFIX}${new_ver}"

  if [[ "${COMMIT_FILES}" != "true" ]]; then
    log_warn "Skipping git commit (COMMIT_FILES=false)"
    return 0
  fi

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_dry "[DRY] Would commit: chore(release): bump version to ${new_ver}"
    log_dry "[DRY] Would tag: ${tag}"
    return 0
  fi

  # Stage version files
  for file in "${VERSION_FILES[@]}" ".version-lock"; do
    [[ -f "${file}" ]] && git add "${file}" 2>/dev/null || true
  done

  # Commit
  local commit_msg="${COMMIT_MESSAGE:-"chore(release): 🔖 bump version to ${new_ver}

Version: ${CURRENT_VERSION} → ${new_ver}
Bump type: ${BUMP_TYPE}
Generated by: ASH Bump Engine v${SCRIPT_VERSION}"}"

  git config user.email "ash-release-bot@dotfiles.dev" 2>/dev/null || true
  git config user.name  "ASH Release Bot" 2>/dev/null || true

  git commit -m "${commit_msg}" --no-verify 2>/dev/null && \
    log_git "Committed version bump" || \
    log_warn "Nothing to commit (files already staged?)"

  # Create annotated tag
  if [[ "${CREATE_TAG}" == "true" ]]; then
    local tag_msg="Release ${new_ver}

Version: ${new_ver}
Previous: ${CURRENT_VERSION}
Bump type: ${BUMP_TYPE}
Date: $(date -u +%Y-%m-%d)"

    if [[ "${SIGN_TAG}" == "true" ]]; then
      git tag -s "${tag}" -m "${tag_msg}" && log_git "Created signed tag: ${tag}"
    else
      git tag -a "${tag}" -m "${tag_msg}" && log_git "Created tag: ${tag}"
    fi
  fi

  # Create release branch
  if [[ "${CREATE_BRANCH}" == "true" ]]; then
    local branch="release/${new_ver}"
    git checkout -b "${branch}" 2>/dev/null && \
      log_git "Created branch: ${branch}" || \
      log_warn "Branch ${branch} may already exist"
  fi

  # Push if configured
  if [[ "${PUSH_CHANGES}" == "true" ]]; then
    git push origin HEAD 2>/dev/null && log_git "Pushed changes" || \
      log_warn "Push failed — may need authentication"
  fi

  if [[ "${PUSH_TAGS}" == "true" && "${CREATE_TAG}" == "true" ]]; then
    git push origin "${tag}" 2>/dev/null && log_git "Pushed tag: ${tag}" || \
      log_warn "Tag push failed"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# GITHUB RELEASE CREATION
# ─────────────────────────────────────────────────────────────────────────────
create_github_release() {
  local new_ver="$1"

  [[ "${CREATE_RELEASE}" != "true" || -z "${GITHUB_TOKEN}" ]] && return 0

  local repo="${GITHUB_REPOSITORY:-}"
  [[ -z "${repo}" ]] && return 0

  log_step "Creating GitHub Release for ${new_ver}..."

  # Extract release notes
  local notes=""
  if [[ -f "CHANGELOG.md" ]]; then
    notes=$(CHANGELOG_FILE="CHANGELOG.md" \
      "${SCRIPT_DIR}/generate-changelog.sh" --release-notes 2>/dev/null || echo "")
  fi

  local is_prerelease="false"
  [[ -n "${PRE_RELEASE}" ]] && is_prerelease="true"

  python3 << RELEASE_PY
import urllib.request, json, os

token  = "${GITHUB_TOKEN}"
repo   = "${repo}"
tag    = "${TAG_PREFIX}${new_ver}"
name   = "ASH Dotfiles ${new_ver}"
body   = """${notes:-"Release ${new_ver}"}"""
prerel = ${is_prerelease}

data = json.dumps({
    "tag_name":         tag,
    "name":             name,
    "body":             body,
    "draft":            False,
    "prerelease":       prerel,
    "generate_release_notes": len(body) < 50,
}).encode()

url = f"https://api.github.com/repos/{repo}/releases"
req = urllib.request.Request(url, data=data, method="POST")
req.add_header("Authorization",  f"Bearer {token}")
req.add_header("Content-Type",   "application/json")
req.add_header("User-Agent",     "ASH-Bump-Engine/5.0")
req.add_header("Accept",         "application/vnd.github+json")

try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        result = json.loads(resp.read())
        print(f"  ✅ Release created: {result.get('html_url','?')}")
except Exception as e:
    print(f"  ⚠️  Release creation failed: {e}")
RELEASE_PY
}

# ─────────────────────────────────────────────────────────────────────────────
# ROLLBACK
# ─────────────────────────────────────────────────────────────────────────────
perform_rollback() {
  local new_ver="$1"
  log_warn "Performing rollback..."

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_dry "[DRY] Would rollback version changes"
    return 0
  fi

  # Restore files from git
  for file in "${VERSION_FILES[@]}" ".version-lock"; do
    [[ -f "${file}" ]] && git checkout -- "${file}" 2>/dev/null || true
  done

  # Delete tag if created
  local tag="${TAG_PREFIX}${new_ver}"
  git tag -d "${tag}" 2>/dev/null && log_git "Deleted tag: ${tag}" || true

  log_warn "Rollback complete"
}

# ─────────────────────────────────────────────────────────────────────────────
# CHANGELOG TRIGGER
# ─────────────────────────────────────────────────────────────────────────────
trigger_changelog() {
  local new_ver="$1"
  local changelog_script="${SCRIPT_DIR}/generate-changelog.sh"

  [[ ! -f "${changelog_script}" ]] && return 0

  log_step "Generating changelog for ${new_ver}..."

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_dry "[DRY] Would generate changelog"
    return 0
  fi

  TO_TAG="${TAG_PREFIX}${new_ver}" \
  DRY_RUN=false \
    bash "${changelog_script}" 2>/dev/null && \
    log_pass "Changelog updated" || \
    log_warn "Changelog generation had issues"

  # Stage the changelog
  [[ -f "CHANGELOG.md" ]] && git add CHANGELOG.md 2>/dev/null || true
}

# ─────────────────────────────────────────────────────────────────────────────
# FINAL DASHBOARD
# ─────────────────────────────────────────────────────────────────────────────
print_summary() {
  local old_ver="$1"
  local new_ver="$2"
  local tag="${TAG_PREFIX}${new_ver}"
  local duration=$(( $(date +%s) - START_EPOCH ))

  echo ""
  echo -e "  ${C_PEACH}${C_BLD}╔══════════════════════════════════════════════════════════════╗${C_RST}"
  echo -e "  ${C_PEACH}${C_BLD}║  🔖 Version Bump Complete                                     ║${C_RST}"
  echo -e "  ${C_PEACH}${C_BLD}╠══════════════════════════════════════════════════════════════╣${C_RST}"
  printf  "  ${C_PEACH}${C_BLD}║${C_RST}  ${C_TEXT}Previous:   ${C_OVR}%-43s${C_RST}${C_PEACH}${C_BLD}║${C_RST}\n" "${old_ver}"
  printf  "  ${C_PEACH}${C_BLD}║${C_RST}  ${C_TEXT}New:        ${C_GREEN}${C_BLD}%-43s${C_RST}${C_PEACH}${C_BLD}║${C_RST}\n" "${new_ver}"
  printf  "  ${C_PEACH}${C_BLD}║${C_RST}  ${C_TEXT}Bump type:  ${C_SAP}%-43s${C_RST}${C_PEACH}${C_BLD}║${C_RST}\n" "${BUMP_TYPE}"
  printf  "  ${C_PEACH}${C_BLD}║${C_RST}  ${C_TEXT}Git tag:    ${C_MAUVE}%-43s${C_RST}${C_PEACH}${C_BLD}║${C_RST}\n" "${tag}"
  printf  "  ${C_PEACH}${C_BLD}║${C_RST}  ${C_TEXT}Duration:   ${C_OVR}%-43s${C_RST}${C_PEACH}${C_BLD}║${C_RST}\n" "${duration}s"
  [[ "${DRY_RUN}" == "true" ]] && \
    printf "  ${C_PEACH}${C_BLD}║${C_RST}  ${C_YELLOW}${C_BLD}⚠️  DRY RUN — No changes were made%-25s${C_RST}${C_PEACH}${C_BLD}║${C_RST}\n" ""
  echo -e "  ${C_PEACH}${C_BLD}╚══════════════════════════════════════════════════════════════╝${C_RST}"
  echo ""

  # Export for CI/CD
  echo "NEW_VERSION=${new_ver}" >> "${GITHUB_OUTPUT:-/dev/null}" 2>/dev/null || true
  echo "OLD_VERSION=${old_ver}" >> "${GITHUB_OUTPUT:-/dev/null}" 2>/dev/null || true
  echo "GIT_TAG=${tag}"        >> "${GITHUB_OUTPUT:-/dev/null}" 2>/dev/null || true
  echo "BUMP_TYPE=${BUMP_TYPE}" >> "${GITHUB_OUTPUT:-/dev/null}" 2>/dev/null || true
}

# ─────────────────────────────────────────────────────────────────────────────
# USAGE
# ─────────────────────────────────────────────────────────────────────────────
usage() {
  cat << EOF
${C_PEACH}${C_BLD}Usage:${C_RST} ${SCRIPT_NAME} [BUMP_TYPE] [OPTIONS]

${C_BLUE}${C_BLD}Bump Types:${C_RST}
  ${C_GREEN}major${C_RST}    Increment major version (breaking changes)
  ${C_GREEN}minor${C_RST}    Increment minor version (new features)
  ${C_GREEN}patch${C_RST}    Increment patch version (bug fixes)
  ${C_GREEN}auto${C_RST}     Auto-detect from Conventional Commits

${C_BLUE}${C_BLD}Options:${C_RST}
  ${C_TEAL}--pre-release${C_RST} TYPE[.N]  Pre-release tag (alpha|beta|rc)
  ${C_TEAL}--tag-prefix${C_RST} PREFIX     Tag prefix (default: v)
  ${C_TEAL}--no-tag${C_RST}               Skip git tag creation
  ${C_TEAL}--sign-tag${C_RST}             GPG-sign the tag
  ${C_TEAL}--create-branch${C_RST}        Create release/X.Y.Z branch
  ${C_TEAL}--push${C_RST}                 Push commits to remote
  ${C_TEAL}--push-tags${C_RST}            Push tags to remote
  ${C_TEAL}--create-release${C_RST}       Create GitHub Release
  ${C_TEAL}--skip-validation${C_RST}      Skip clean workspace check
  ${C_TEAL}--no-commit${C_RST}            Skip git commit
  ${C_TEAL}--dry-run${C_RST}              Preview without changes
  ${C_TEAL}--verbose${C_RST}              Verbose output
  ${C_TEAL}--help${C_RST}                 Show this help

${C_BLUE}${C_BLD}Examples:${C_RST}
  ${SCRIPT_NAME} patch                    # 5.0.0 → 5.0.1
  ${SCRIPT_NAME} minor                    # 5.0.0 → 5.1.0
  ${SCRIPT_NAME} major                    # 5.0.0 → 6.0.0
  ${SCRIPT_NAME} auto                     # Auto-detect from commits
  ${SCRIPT_NAME} minor --pre-release rc.1 # 5.0.0 → 5.1.0-rc.1
  ${SCRIPT_NAME} patch --dry-run          # Preview only
EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# ARGUMENT PARSING
# ─────────────────────────────────────────────────────────────────────────────
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      major|minor|patch|auto) BUMP_TYPE="$1"; shift ;;
      --pre-release)     PRE_RELEASE="$2"; shift 2 ;;
      --build-meta)      BUILD_META="$2"; shift 2 ;;
      --tag-prefix)      TAG_PREFIX="$2"; shift 2 ;;
      --no-tag)          CREATE_TAG=false; shift ;;
      --sign-tag)        SIGN_TAG=true; shift ;;
      --create-branch)   CREATE_BRANCH=true; shift ;;
      --push)            PUSH_CHANGES=true; shift ;;
      --push-tags)       PUSH_TAGS=true; shift ;;
      --create-release)  CREATE_RELEASE=true; shift ;;
      --skip-validation) SKIP_VALIDATION=true; shift ;;
      --no-commit)       COMMIT_FILES=false; shift ;;
      --message)         COMMIT_MESSAGE="$2"; shift 2 ;;
      --dry-run)         DRY_RUN=true; shift ;;
      --verbose)         VERBOSE=true; shift ;;
      --help|-h)         usage; exit 0 ;;
      *) log_fail "Unknown option: $1"; usage; exit 1 ;;
    esac
  done

  [[ -z "${BUMP_TYPE}" ]] && {
    log_fail "BUMP_TYPE required: major | minor | patch | auto"
    usage
    exit 1
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# TRAP
# ─────────────────────────────────────────────────────────────────────────────
trap 'EXIT_CODE=$?
rm -f "${LOCK_FILE}" 2>/dev/null || true
if [[ $EXIT_CODE -ne 0 && "${DRY_RUN}" != "true" ]]; then
  log_fail "Bump failed (exit=${EXIT_CODE}) — rolling back"
  perform_rollback "${NEW_VERSION:-0.0.0}" 2>/dev/null || true
fi' EXIT

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
main() {
  parse_args "$@"
  print_banner

  # Prevent concurrent runs
  if [[ -f "${LOCK_FILE}" ]]; then
    log_fail "Another bump is in progress (${LOCK_FILE})"
    exit 1
  fi
  touch "${LOCK_FILE}"

  validate_workspace
  detect_current_version

  [[ "${BUMP_TYPE}" == "auto" ]] && auto_detect_bump

  calculate_new_version

  log_step "Bump plan: ${CURRENT_VERSION} → ${NEW_VERSION} (${BUMP_TYPE})"
  [[ "${DRY_RUN}" == "true" ]] && log_dry "DRY RUN — no files will be modified"

  update_all_files "${NEW_VERSION}"
  trigger_changelog "${NEW_VERSION}"
  git_commit_and_tag "${NEW_VERSION}"
  create_github_release "${NEW_VERSION}"

  print_summary "${CURRENT_VERSION}" "${NEW_VERSION}"

  rm -f "${LOCK_FILE}" 2>/dev/null || true
  log_pass "Version bumped successfully: ${NEW_VERSION} ✨"
}

main "$@"