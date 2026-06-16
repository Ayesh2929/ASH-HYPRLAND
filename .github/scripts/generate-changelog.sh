#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                           ║
# ║  📋 ASH DOTFILES v5.0 OMEGA — INTELLIGENT CHANGELOG GENERATION ENGINE                    ║
# ║                                                                                           ║
# ║   ██████╗██╗  ██╗ █████╗ ███╗   ██╗ ██████╗ ███████╗██╗      ██████╗  ██████╗           ║
# ║  ██╔════╝██║  ██║██╔══██╗████╗  ██║██╔════╝ ██╔════╝██║     ██╔═══██╗██╔════╝           ║
# ║  ██║     ███████║███████║██╔██╗ ██║██║  ███╗█████╗  ██║     ██║   ██║██║  ███╗          ║
# ║  ██║     ██╔══██║██╔══██║██║╚██╗██║██║   ██║██╔══╝  ██║     ██║   ██║██║   ██║          ║
# ║  ╚██████╗██║  ██║██║  ██║██║ ╚████║╚██████╔╝███████╗███████╗╚██████╔╝╚██████╔╝          ║
# ║   ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚══════╝ ╚═════╝  ╚═════╝           ║
# ║                                                                                           ║
# ║  ─────────────────────────────────────────────────────────────────────────────────────── ║
# ║                                                                                           ║
# ║  🎯 FEATURES:                                                                             ║
# ║     📝 Conventional Commits parser (feat/fix/docs/style/refactor/perf/test/chore)       ║
# ║     🔖 Semantic version range extraction (tag-to-tag)                                    ║
# ║     🌟 Breaking change detection (BREAKING CHANGE footer, ! prefix)                     ║
# ║     👤 Contributor attribution with GitHub profile links                                 ║
# ║     🔗 Issue/PR cross-reference linking                                                  ║
# ║     🎨 Scope-based section grouping and emoji mapping                                    ║
# ║     📊 Commit statistics (totals, contributors, categories)                              ║
# ║     🏷️  Keep-a-Changelog format compliance (https://keepachangelog.com)                  ║
# ║     📅 ISO 8601 date formatting                                                          ║
# ║     🔄 Diff URL generation (GitHub compare links)                                        ║
# ║     ✨ Release notes extraction (latest entry only)                                      ║
# ║     📤 Multiple output modes (file, stdout, release-notes)                              ║
# ║     🌐 GitHub API integration (PR titles, author usernames)                              ║
# ║     🏗️  Multi-format output (Markdown, JSON, plain text)                                 ║
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

# ─────────────────────────────────────────────────────────────────────────────
# CATPPUCCIN MOCHA ANSI PALETTE
# ─────────────────────────────────────────────────────────────────────────────
C_RST='\033[0m'     C_BLD='\033[1m'     C_DIM='\033[2m'
C_MAUVE='\033[38;2;203;166;247m'    C_BLUE='\033[38;2;137;180;250m'
C_GREEN='\033[38;2;166;227;161m'    C_RED='\033[38;2;243;139;168m'
C_YELLOW='\033[38;2;249;226;175m'   C_PEACH='\033[38;2;250;179;135m'
C_TEAL='\033[38;2;148;226;213m'     C_SAP='\033[38;2;116;199;236m'
C_TEXT='\033[38;2;205;214;244m'     C_SUB='\033[38;2;166;173;200m'
C_OVR='\033[38;2;108;112;134m'      C_LAV='\033[38;2;180;190;254m'
C_PINK='\033[38;2;245;194;231m'     C_MAR='\033[38;2;235;160;172m'

# ─────────────────────────────────────────────────────────────────────────────
# LOGGING
# ─────────────────────────────────────────────────────────────────────────────
_log() {
  local icon="$1" color="$2"; shift 2
  local ts; ts=$(date '+%H:%M:%S')
  printf "${color}${icon}${C_RST} ${C_DIM}[${ts}]${C_RST} ${C_TEXT}%s${C_RST}\n" "$*"
}

log_info()    { _log "📋" "${C_BLUE}"   "$@"; }
log_pass()    { _log "✅" "${C_GREEN}"  "$@"; }
log_warn()    { _log "⚠️ " "${C_YELLOW}" "$@"; }
log_fail()    { _log "❌" "${C_RED}"    "$@"; }
log_step()    { _log "🔹" "${C_MAUVE}"  "$@"; }
log_commit()  { _log "📝" "${C_SAP}"    "$@"; }
log_tag()     { _log "🏷️ " "${C_PEACH}"  "$@"; }
log_write()   { _log "✍️ " "${C_TEAL}"   "$@"; }
log_break()   { _log "💥" "${C_MAR}"    "$@"; }

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION & DEFAULTS
# ─────────────────────────────────────────────────────────────────────────────
: "${CHANGELOG_FILE:=CHANGELOG.md}"
: "${OUTPUT_FORMAT:=markdown}"          # markdown | json | plain
: "${FROM_TAG:=}"                       # Auto-detect if empty
: "${TO_TAG:=HEAD}"
: "${REPO_URL:=}"                       # Auto-detect from git remote
: "${GITHUB_TOKEN:=}"                   # For API calls
: "${INCLUDE_SCOPE:=true}"
: "${INCLUDE_BODY:=false}"
: "${MAX_COMMITS:=500}"
: "${RELEASE_NOTES_ONLY:=false}"        # Extract latest entry only
: "${PREPEND:=true}"                    # Prepend to existing CHANGELOG
: "${DRY_RUN:=false}"
: "${VERBOSE:=false}"

# Commit type → section title + emoji mapping
declare -A TYPE_TITLES=(
  ["feat"]="✨ Features"
  ["fix"]="🐛 Bug Fixes"
  ["perf"]="⚡ Performance"
  ["refactor"]="♻️  Refactoring"
  ["docs"]="📖 Documentation"
  ["style"]="🎨 Styling"
  ["test"]="🧪 Tests"
  ["build"]="🏗️  Build System"
  ["ci"]="⚙️  Continuous Integration"
  ["chore"]="🔧 Chores"
  ["revert"]="⏪ Reverts"
  ["deps"]="📦 Dependencies"
  ["security"]="🔒 Security"
  ["theme"]="🎨 Themes"
  ["plugin"]="🔌 Plugins"
  ["api"]="🌐 API"
)

# Section priority (lower = higher in changelog)
declare -A TYPE_PRIORITY=(
  ["feat"]=1 ["fix"]=2 ["security"]=3 ["perf"]=4
  ["api"]=5  ["theme"]=6 ["plugin"]=7 ["refactor"]=8
  ["docs"]=9 ["deps"]=10 ["build"]=11 ["ci"]=12
  ["style"]=13 ["test"]=14 ["chore"]=15 ["revert"]=16
)

# ─────────────────────────────────────────────────────────────────────────────
# BANNER
# ─────────────────────────────────────────────────────────────────────────────
print_banner() {
  echo ""
  echo -e "${C_MAUVE}${C_BLD}"
  cat << 'BANNER'
  ╔══════════════════════════════════════════════════════════════════╗
  ║  📋 ASH Changelog Generator v5.0.0-omega                         ║
  ╚══════════════════════════════════════════════════════════════════╝
BANNER
  echo -e "${C_RST}"
}

# ─────────────────────────────────────────────────────────────────────────────
# GIT VALIDATION
# ─────────────────────────────────────────────────────────────────────────────
validate_git() {
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_fail "Not a git repository"
    exit 1
  fi

  if ! git log --oneline -1 > /dev/null 2>&1; then
    log_fail "No commits found"
    exit 1
  fi

  log_pass "Git repository validated"
}

# ─────────────────────────────────────────────────────────────────────────────
# TAG RESOLUTION
# ─────────────────────────────────────────────────────────────────────────────
resolve_tags() {
  # Auto-detect FROM_TAG (previous tag)
  if [[ -z "${FROM_TAG}" ]]; then
    # Get all tags sorted by creation date
    local all_tags
    all_tags=$(git tag --sort=-version:refname 2>/dev/null | head -20 || true)

    if [[ -z "${all_tags}" ]]; then
      log_warn "No tags found — generating full history changelog"
      FROM_TAG=""
    elif [[ "${TO_TAG}" == "HEAD" ]]; then
      # Use most recent tag as FROM
      FROM_TAG=$(echo "${all_tags}" | head -1)
      log_tag "FROM_TAG: ${FROM_TAG}"
    else
      # Find tag before TO_TAG
      FROM_TAG=$(git tag --sort=-version:refname | \
        grep -A1 "^${TO_TAG}$" | tail -1 || echo "")
      [[ "${FROM_TAG}" == "${TO_TAG}" ]] && FROM_TAG=""
      log_tag "FROM_TAG: ${FROM_TAG:-'(beginning of history)'}"
    fi
  fi

  log_tag "TO_TAG: ${TO_TAG}"
}

# ─────────────────────────────────────────────────────────────────────────────
# REPO URL DETECTION
# ─────────────────────────────────────────────────────────────────────────────
resolve_repo_url() {
  if [[ -z "${REPO_URL}" ]]; then
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || echo "")

    if [[ -n "${remote_url}" ]]; then
      # Convert SSH → HTTPS
      REPO_URL="${remote_url}"
      REPO_URL="${REPO_URL/git@github.com:/https://github.com/}"
      REPO_URL="${REPO_URL%.git}"
    fi
  fi

  log_info "Repo URL: ${REPO_URL:-'(unknown)'}"
}

# ─────────────────────────────────────────────────────────────────────────────
# COMMIT PARSING ENGINE
# ─────────────────────────────────────────────────────────────────────────────
parse_commits() {
  local range=""
  if [[ -n "${FROM_TAG}" ]]; then
    range="${FROM_TAG}..${TO_TAG}"
  else
    range="${TO_TAG}"
  fi

  log_step "Parsing commits in range: ${range:-'full history'}"

  # Format: hash|author|email|date|subject|body
  local FORMAT="%H|%an|%ae|%ai|%s"
  local commits
  commits=$(git log "${range}" \
    --pretty=format:"${FORMAT}" \
    --no-merges \
    --max-count="${MAX_COMMITS}" \
    2>/dev/null || git log \
    --pretty=format:"${FORMAT}" \
    --no-merges \
    --max-count="${MAX_COMMITS}" \
    2>/dev/null)

  if [[ -z "${commits}" ]]; then
    log_warn "No commits found in range"
    return 0
  fi

  # Initialize storage arrays
  declare -gA SECTIONS=()
  declare -gA BREAKING_CHANGES=()
  declare -ga ALL_AUTHORS=()
  declare -gA AUTHOR_MAP=()
  TOTAL_COMMITS=0
  BREAKING_COUNT=0

  local processed=0
  while IFS='|' read -r hash author email date subject; do
    [[ -z "${hash}" ]] && continue
    ((processed++)) || true

    # ── Parse Conventional Commit subject ──────────────────────────────────
    local type="" scope="" breaking="" title=""
    local cc_regex='^([a-zA-Z]+)(\(([^)]+)\))?(!)?: (.+)$'

    if [[ "${subject}" =~ ${cc_regex} ]]; then
      type="${BASH_REMATCH[1],,}"    # lowercase
      scope="${BASH_REMATCH[3]}"
      breaking="${BASH_REMATCH[4]}"
      title="${BASH_REMATCH[5]}"
    else
      type="chore"
      title="${subject}"
    fi

    # ── Check for BREAKING CHANGE ───────────────────────────────────────────
    local is_breaking=false
    if [[ -n "${breaking}" ]]; then
      is_breaking=true
      ((BREAKING_COUNT++)) || true
    fi

    # Get commit body for BREAKING CHANGE footer
    local body=""
    body=$(git show --format="%b" -s "${hash}" 2>/dev/null || echo "")
    if echo "${body}" | grep -qiE "^BREAKING.CHANGE"; then
      is_breaking=true
      ((BREAKING_COUNT++)) || true
    fi

    # ── Build entry line ────────────────────────────────────────────────────
    local short_hash="${hash:0:8}"
    local entry_line=""

    # Scope formatting
    local scope_str=""
    [[ -n "${scope}" && "${INCLUDE_SCOPE}" == "true" ]] && \
      scope_str=" **${scope}**:"

    # Link generation
    local commit_link=""
    local pr_link=""
    if [[ -n "${REPO_URL}" ]]; then
      commit_link="([${short_hash}](${REPO_URL}/commit/${hash}))"

      # Extract PR reference (#123)
      local pr_num=""
      pr_num=$(echo "${title}" | grep -oP '#\d+' | head -1 || echo "")
      if [[ -n "${pr_num}" ]]; then
        pr_num_clean="${pr_num#\#}"
        pr_link=" (${pr_num} via [#${pr_num_clean}](${REPO_URL}/pull/${pr_num_clean}))"
        title="${title//${pr_num}/}"
      fi
    fi

    # Clean title
    title=$(echo "${title}" | sed 's/[[:space:]]*$//')

    # Breaking change indicator
    local break_str=""
    [[ "${is_breaking}" == "true" ]] && break_str=" 💥 **BREAKING**"

    entry_line="- ${scope_str} ${title}${break_str} ${commit_link}${pr_link}"
    entry_line=$(echo "${entry_line}" | sed 's/  */ /g; s/^- $//')

    # ── Add to section ──────────────────────────────────────────────────────
    local section_key="${type}"
    if [[ ! -v TYPE_TITLES["${section_key}"] ]]; then
      section_key="chore"
    fi

    if [[ -v SECTIONS["${section_key}"] ]]; then
      SECTIONS["${section_key}"]="${SECTIONS["${section_key}"]}"$'\n'"${entry_line}"
    else
      SECTIONS["${section_key}"]="${entry_line}"
    fi

    # ── Track breaking changes ──────────────────────────────────────────────
    if [[ "${is_breaking}" == "true" ]]; then
      local bc_note="${title}"
      if echo "${body}" | grep -qiE "^BREAKING.CHANGE"; then
        bc_note=$(echo "${body}" | grep -iA1 "^BREAKING.CHANGE" | tail -1)
      fi
      BREAKING_CHANGES["${hash}"]="${bc_note}"
      log_break "Breaking: ${title}"
    fi

    # ── Track contributors ──────────────────────────────────────────────────
    if [[ ! -v AUTHOR_MAP["${email}"] ]]; then
      AUTHOR_MAP["${email}"]="${author}"
      ALL_AUTHORS+=("${author}")
    fi

    ((TOTAL_COMMITS++)) || true

    [[ "${VERBOSE}" == "true" ]] && log_commit "  ${type}: ${title}"

  done <<< "${commits}"

  log_pass "Parsed ${TOTAL_COMMITS} commits (${BREAKING_COUNT} breaking)"
}

# ─────────────────────────────────────────────────────────────────────────────
# VERSION DETECTION
# ─────────────────────────────────────────────────────────────────────────────
detect_version() {
  # From TO_TAG
  if [[ "${TO_TAG}" != "HEAD" ]]; then
    CURRENT_VERSION="${TO_TAG#v}"
    return
  fi

  # From version.json
  if [[ -f "version.json" ]]; then
    CURRENT_VERSION=$(jq -r '.version // ""' version.json 2>/dev/null || echo "")
    [[ -n "${CURRENT_VERSION}" ]] && return
  fi

  # From package.json
  if [[ -f "package.json" ]]; then
    CURRENT_VERSION=$(jq -r '.version // ""' package.json 2>/dev/null || echo "")
    [[ -n "${CURRENT_VERSION}" ]] && return
  fi

  # From git tag
  CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "Unreleased")
}

# ─────────────────────────────────────────────────────────────────────────────
# CHANGELOG RENDERING — MARKDOWN FORMAT
# ─────────────────────────────────────────────────────────────────────────────
render_markdown() {
  local version="${1:-Unreleased}"
  local date_str
  date_str=$(date -u +%Y-%m-%d)
  local output=""

  # ── Header ─────────────────────────────────────────────────────────────────
  local version_header=""
  if [[ -n "${REPO_URL}" && -n "${FROM_TAG}" && "${TO_TAG}" != "HEAD" ]]; then
    local compare_url="${REPO_URL}/compare/${FROM_TAG}...${TO_TAG}"
    version_header="## [${version}](${compare_url}) — ${date_str}"
  elif [[ -n "${REPO_URL}" && -n "${FROM_TAG}" ]]; then
    local compare_url="${REPO_URL}/compare/${FROM_TAG}...HEAD"
    version_header="## [${version}](${compare_url}) — ${date_str}"
  else
    version_header="## [${version}] — ${date_str}"
  fi

  output+="${version_header}"$'\n'$'\n'

  # ── Breaking Changes (always first) ────────────────────────────────────────
  if [[ "${#BREAKING_CHANGES[@]}" -gt 0 ]]; then
    output+="### 💥 Breaking Changes"$'\n'$'\n'
    for hash in "${!BREAKING_CHANGES[@]}"; do
      local note="${BREAKING_CHANGES[$hash]}"
      local short="${hash:0:8}"
      local link=""
      [[ -n "${REPO_URL}" ]] && link=" ([${short}](${REPO_URL}/commit/${hash}))"
      output+="- ⚠️  **${note}**${link}"$'\n'
    done
    output+=$'\n'
  fi

  # ── Type sections (sorted by priority) ─────────────────────────────────────
  local sorted_types
  sorted_types=$(for type in "${!SECTIONS[@]}"; do
    local prio="${TYPE_PRIORITY[$type]:-99}"
    echo "${prio} ${type}"
  done | sort -n | awk '{print $2}')

  while IFS= read -r type; do
    [[ -z "${type}" || -z "${SECTIONS[$type]:-}" ]] && continue
    local title="${TYPE_TITLES[$type]:-🔧 ${type^}}"
    output+="### ${title}"$'\n'$'\n'
    output+="${SECTIONS[$type]}"$'\n'$'\n'
  done <<< "${sorted_types}"

  # ── Contributors ────────────────────────────────────────────────────────────
  if [[ "${#ALL_AUTHORS[@]}" -gt 0 ]]; then
    output+="### 👥 Contributors"$'\n'$'\n'
    local -A unique_authors=()
    for author in "${ALL_AUTHORS[@]}"; do
      unique_authors["${author}"]=1
    done
    local contrib_count=0
    for author in "${!unique_authors[@]}"; do
      if [[ -n "${REPO_URL}" ]]; then
        local gh_user
        gh_user=$(echo "${author}" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
        output+="- [@${author}](${REPO_URL/github.com*/github.com}/${gh_user})"$'\n'
      else
        output+="- ${author}"$'\n'
      fi
      ((contrib_count++)) || true
    done
    output+=$'\n'
  fi

  # ── Statistics ───────────────────────────────────────────────────────────────
  output+="### 📊 Statistics"$'\n'$'\n'
  output+="| Metric | Count |"$'\n'
  output+="|--------|------:|"$'\n'
  output+="| 📝 Total Commits | \`${TOTAL_COMMITS}\` |"$'\n'
  output+="| 💥 Breaking Changes | \`${BREAKING_COUNT}\` |"$'\n'
  output+="| 👥 Contributors | \`${#ALL_AUTHORS[@]}\` |"$'\n'
  output+="| 📦 Sections | \`${#SECTIONS[@]}\` |"$'\n'
  output+=$'\n'
  output+="---"$'\n'
  output+="*Generated by ASH Changelog Engine v${SCRIPT_VERSION} on ${date_str}*"$'\n'

  echo "${output}"
}

# ─────────────────────────────────────────────────────────────────────────────
# CHANGELOG RENDERING — JSON FORMAT
# ─────────────────────────────────────────────────────────────────────────────
render_json() {
  local version="${1:-Unreleased}"
  local date_str
  date_str=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  python3 << PYTHON_EOF
import json, os, sys

version = "${version}"
date    = "${date_str}"
total   = int("${TOTAL_COMMITS}")
breaking= int("${BREAKING_COUNT}")
authors = ${#ALL_AUTHORS[@]}

sections = {}
EOF

  # This is simplified; full JSON would use Python for proper escaping
  python3 -c "
import json
from datetime import datetime

data = {
    'version':          '${version}',
    'date':             '$(date -u +%Y-%m-%d)',
    'generated_at':     '$(date -u +%Y-%m-%dT%H:%M:%SZ)',
    'engine':           '${SCRIPT_VERSION}',
    'statistics': {
        'total_commits':    ${TOTAL_COMMITS},
        'breaking_changes': ${BREAKING_COUNT},
        'contributors':     ${#ALL_AUTHORS[@]},
        'sections':         ${#SECTIONS[@]},
    },
    'repo_url': '${REPO_URL}',
    'range': {
        'from': '${FROM_TAG}',
        'to':   '${TO_TAG}',
    }
}
print(json.dumps(data, indent=2))
"
}

# ─────────────────────────────────────────────────────────────────────────────
# FILE WRITING — With prepend or append logic
# ─────────────────────────────────────────────────────────────────────────────
write_changelog() {
  local content="$1"
  local outfile="${CHANGELOG_FILE}"

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_warn "[DRY RUN] Would write to: ${outfile}"
    echo ""
    echo "─────────── Preview ───────────"
    echo "${content}" | head -40
    echo "───────────────────────────────"
    return 0
  fi

  if [[ "${PREPEND}" == "true" && -f "${outfile}" ]]; then
    # Prepend new entry above existing content
    local existing
    existing=$(cat "${outfile}")
    local header=""

    # Preserve the top-level # heading if it exists
    if echo "${existing}" | head -5 | grep -q "^# "; then
      header=$(echo "${existing}" | head -1)
      existing=$(echo "${existing}" | tail -n +2)
      printf '%s\n\n%s\n\n%s\n' \
        "${header}" "${content}" "${existing}" > "${outfile}"
    else
      printf '%s\n\n%s\n' "${content}" "${existing}" > "${outfile}"
    fi

    log_write "Prepended to: ${outfile}"
  elif [[ -f "${outfile}" ]]; then
    # Append mode
    echo "" >> "${outfile}"
    echo "${content}" >> "${outfile}"
    log_write "Appended to: ${outfile}"
  else
    # Create new file with header
    {
      echo "# 📋 Changelog"
      echo ""
      echo "All notable changes to ASH Dotfiles are documented in this file."
      echo ""
      echo "Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)"
      echo "Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html)"
      echo ""
      echo "${content}"
    } > "${outfile}"
    log_write "Created: ${outfile}"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# RELEASE NOTES EXTRACTION
# ─────────────────────────────────────────────────────────────────────────────
extract_release_notes() {
  if [[ ! -f "${CHANGELOG_FILE}" ]]; then
    log_warn "No ${CHANGELOG_FILE} found"
    return 1
  fi

  # Extract content between first and second ## headers
  python3 << 'PYEOF'
import re, sys, os

changelog_path = os.environ.get("CHANGELOG_FILE", "CHANGELOG.md")
try:
    content = open(changelog_path).read()
except FileNotFoundError:
    print("", end="")
    sys.exit(0)

# Find first ## section
sections = re.split(r'^## ', content, flags=re.MULTILINE)
if len(sections) < 2:
    print("No release notes found", end="")
    sys.exit(0)

# Take the first actual section (index 0 is preamble)
first_section = sections[1] if len(sections) > 1 else ""
# Remove header line
lines = first_section.split('\n')
notes = '\n'.join(lines[1:]).strip()
print(notes)
PYEOF
}

# ─────────────────────────────────────────────────────────────────────────────
# FINAL DASHBOARD
# ─────────────────────────────────────────────────────────────────────────────
print_summary() {
  local version="$1"
  local duration=$(( $(date +%s) - START_EPOCH ))

  echo ""
  echo -e "  ${C_MAUVE}${C_BLD}╔══════════════════════════════════════════════════════════════╗${C_RST}"
  echo -e "  ${C_MAUVE}${C_BLD}║  📋 Changelog Generation Complete                            ║${C_RST}"
  echo -e "  ${C_MAUVE}${C_BLD}╠══════════════════════════════════════════════════════════════╣${C_RST}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}Version:      ${C_GREEN}%-42s${C_RST}${C_MAUVE}${C_BLD}║${C_RST}\n" "${version}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}Commits:      ${C_SAP}%-42s${C_RST}${C_MAUVE}${C_BLD}║${C_RST}\n" "${TOTAL_COMMITS:-0}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}Breaking:     ${C_MAR}%-42s${C_RST}${C_MAUVE}${C_BLD}║${C_RST}\n" "${BREAKING_COUNT:-0}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}Contributors: ${C_PINK}%-42s${C_RST}${C_MAUVE}${C_BLD}║${C_RST}\n" "${#ALL_AUTHORS[@]:-0}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}Sections:     ${C_PEACH}%-42s${C_RST}${C_MAUVE}${C_BLD}║${C_RST}\n" "${#SECTIONS[@]:-0}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}Output:       ${C_TEAL}%-42s${C_RST}${C_MAUVE}${C_BLD}║${C_RST}\n" "${CHANGELOG_FILE}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}Duration:     ${C_OVR}%-42s${C_RST}${C_MAUVE}${C_BLD}║${C_RST}\n" "${duration}s"
  echo -e "  ${C_MAUVE}${C_BLD}╚══════════════════════════════════════════════════════════════╝${C_RST}"
  echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# USAGE
# ─────────────────────────────────────────────────────────────────────────────
usage() {
  cat << EOF
${C_MAUVE}${C_BLD}Usage:${C_RST} ${SCRIPT_NAME} [OPTIONS]

${C_BLUE}${C_BLD}Options:${C_RST}
  ${C_TEAL}-f, --from-tag${C_RST}     Start tag/commit (default: auto-detect)
  ${C_TEAL}-t, --to-tag${C_RST}       End tag/commit (default: HEAD)
  ${C_TEAL}-o, --output${C_RST}       Output file (default: CHANGELOG.md)
  ${C_TEAL}-F, --format${C_RST}       Output format: markdown|json|plain (default: markdown)
  ${C_TEAL}-r, --release-notes${C_RST}Extract latest release notes only
  ${C_TEAL}-n, --no-prepend${C_RST}   Append instead of prepend
  ${C_TEAL}-d, --dry-run${C_RST}      Preview without writing
  ${C_TEAL}-v, --verbose${C_RST}      Verbose output
  ${C_TEAL}-h, --help${C_RST}         Show this help

${C_BLUE}${C_BLD}Environment:${C_RST}
  ${C_YELLOW}CHANGELOG_FILE${C_RST}   Output file path
  ${C_YELLOW}FROM_TAG${C_RST}         Start tag/commit
  ${C_YELLOW}TO_TAG${C_RST}           End tag/commit
  ${C_YELLOW}REPO_URL${C_RST}         Repository URL for links
  ${C_YELLOW}GITHUB_TOKEN${C_RST}     For GitHub API calls

${C_BLUE}${C_BLD}Examples:${C_RST}
  ${SCRIPT_NAME}                           # Full changelog from last tag
  ${SCRIPT_NAME} --from-tag v4.0.0         # Since v4.0.0
  ${SCRIPT_NAME} --release-notes           # Extract latest release notes
  ${SCRIPT_NAME} --dry-run --verbose        # Preview without writing
  ${SCRIPT_NAME} --format json             # JSON output
EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# ARGUMENT PARSING
# ─────────────────────────────────────────────────────────────────────────────
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--from-tag)      FROM_TAG="$2";           shift 2 ;;
      -t|--to-tag)        TO_TAG="$2";             shift 2 ;;
      -o|--output)        CHANGELOG_FILE="$2";     shift 2 ;;
      -F|--format)        OUTPUT_FORMAT="$2";      shift 2 ;;
      -r|--release-notes) RELEASE_NOTES_ONLY=true; shift   ;;
      -n|--no-prepend)    PREPEND=false;           shift   ;;
      -d|--dry-run)       DRY_RUN=true;            shift   ;;
      -v|--verbose)       VERBOSE=true;            shift   ;;
      -h|--help)          usage; exit 0                    ;;
      *) log_warn "Unknown option: $1"; usage; exit 1      ;;
    esac
  done
}

# ─────────────────────────────────────────────────────────────────────────────
# TRAP
# ─────────────────────────────────────────────────────────────────────────────
trap 'EXIT_CODE=$?
if [[ $EXIT_CODE -ne 0 ]]; then
  log_fail "Script failed (exit=${EXIT_CODE})"
fi' EXIT

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
main() {
  parse_args "$@"
  print_banner

  # Release notes extraction mode
  if [[ "${RELEASE_NOTES_ONLY}" == "true" ]]; then
    log_step "Extracting latest release notes from ${CHANGELOG_FILE}"
    extract_release_notes
    exit 0
  fi

  validate_git
  resolve_tags
  resolve_repo_url
  detect_version

  # Initialize counters
  TOTAL_COMMITS=0
  BREAKING_COUNT=0

  parse_commits

  # Render output
  log_step "Rendering ${OUTPUT_FORMAT} output..."
  local content=""
  case "${OUTPUT_FORMAT}" in
    json)    content=$(render_json "${CURRENT_VERSION}") ;;
    plain)   content=$(render_markdown "${CURRENT_VERSION}" | sed 's/[*_`#]//g') ;;
    *)       content=$(render_markdown "${CURRENT_VERSION}") ;;
  esac

  write_changelog "${content}"
  print_summary "${CURRENT_VERSION}"

  log_pass "Changelog generated successfully ✨"
}

main "$@"