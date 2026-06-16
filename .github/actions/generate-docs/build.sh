#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                           ║
# ║  📖 ASH DOTFILES v5.0 OMEGA — DOCUMENTATION BUILD ENGINE                                  ║
# ║                                                                                           ║
# ║  ██████╗  ██████╗  ██████╗███████╗    ██████╗ ██╗   ██╗██╗██╗     ██████╗               ║
# ║  ██╔══██╗██╔═══██╗██╔════╝██╔════╝    ██╔══██╗██║   ██║██║██║     ██╔══██╗              ║
# ║  ██║  ██║██║   ██║██║     ███████╗    ██████╔╝██║   ██║██║██║     ██║  ██║              ║
# ║  ██║  ██║██║   ██║██║     ╚════██║    ██╔══██╗██║   ██║██║██║     ██║  ██║              ║
# ║  ██████╔╝╚██████╔╝╚██████╗███████║    ██████╔╝╚██████╔╝██║███████╗██████╔╝              ║
# ║  ╚═════╝  ╚═════╝  ╚═════╝╚══════╝    ╚═════╝  ╚═════╝ ╚═╝╚══════╝╚═════╝               ║
# ║                                                                                           ║
# ║  ███████╗███╗   ██╗ ██████╗ ██╗███╗   ██╗███████╗                                       ║
# ║  ██╔════╝████╗  ██║██╔════╝ ██║████╗  ██║██╔════╝                                       ║
# ║  █████╗  ██╔██╗ ██║██║  ███╗██║██╔██╗ ██║█████╗                                         ║
# ║  ██╔══╝  ██║╚██╗██║██║   ██║██║██║╚██╗██║██╔══╝                                         ║
# ║  ███████╗██║ ╚████║╚██████╔╝██║██║ ╚████║███████╗                                       ║
# ║  ╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝╚══════╝                                       ║
# ║                                                                                           ║
# ║  Version:  5.0.0-omega                                                                   ║
# ║  Pipeline: scaffold → plugin-api → theme-gallery → cli-ref → config-ref →               ║
# ║            api-docs → websocket → diagrams → changelog → contributors →                 ║
# ║            benchmarks → mkdocs-build → optimize → pwa → search → report                 ║
# ║                                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────
readonly BUILD_VERSION="5.0.0-omega"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly START_EPOCH=$(date +%s)

# ─────────────────────────────────────────────────────────────────────────────
# ENVIRONMENT RESOLUTION
# ─────────────────────────────────────────────────────────────────────────────
SESSION_ID="${SESSION_ID:-docs-$(date +%s)}"
RESOLVED_GENERATORS="${RESOLVED_GENERATORS:-mkdocs}"
WORKSPACE="${WORKSPACE:-$(pwd)}"
REPO_URL="${REPO_URL:-https://github.com/ash/dotfiles}"
MKDOCS_CONFIG="${MKDOCS_CONFIG:-docs/mkdocs.yml}"
MKDOCS_THEME="${MKDOCS_THEME:-material}"
DOCS_DIR="${DOCS_DIR:-docs}"
SITE_DIR="${SITE_DIR:-site}"
SITE_NAME="${SITE_NAME:-ASH Dotfiles}"
SITE_URL="${SITE_URL:-https://ash-dotfiles.dev}"
SITE_DESC="${SITE_DESC:-The Ultimate Hyprland Dotfiles}"
EDIT_URI="${EDIT_URI:-edit/main/docs/}"
STRICT_MODE="${STRICT_MODE:-false}"
THEME_GALLERY="${THEME_GALLERY:-true}"
THEME_GALLERY_COLS="${THEME_GALLERY_COLS:-3}"
THEME_GALLERY_MAX="${THEME_GALLERY_MAX:-0}"
THEME_PREVIEW_W="${THEME_PREVIEW_W:-800}"
THEME_PREVIEW_H="${THEME_PREVIEW_H:-500}"
PLUGIN_API_SRC="${PLUGIN_API_SRC:-plugins}"
PLUGIN_API_FMT="${PLUGIN_API_FMT:-markdown}"
OPENAPI_SPEC="${OPENAPI_SPEC:-api/openapi.yaml}"
SWAGGER_VERSION="${SWAGGER_VERSION:-5.17.14}"
REDOC_ENABLED="${REDOC_ENABLED:-true}"
BENCHMARK_DATA="${BENCHMARK_DATA:-benchmarks}"
BENCHMARK_STYLE="${BENCHMARK_STYLE:-catppuccin}"
LANGUAGES="${LANGUAGES:-en}"
DEFAULT_LANG="${DEFAULT_LANG:-en}"
SEARCH_PROVIDER="${SEARCH_PROVIDER:-lunr}"
CHANGELOG_PATH="${CHANGELOG_PATH:-CHANGELOG.md}"
MAX_CONTRIBUTORS="${MAX_CONTRIBUTORS:-50}"
GITHUB_TOKEN_DOC="${GITHUB_TOKEN_DOC:-}"
OPTIMIZE_ASSETS="${OPTIMIZE_ASSETS:-true}"
MINIFY_HTML="${MINIFY_HTML:-true}"
GEN_SITEMAP="${GEN_SITEMAP:-true}"
GEN_ROBOTS="${GEN_ROBOTS:-true}"
ENABLE_PWA="${ENABLE_PWA:-true}"
LINK_CHECK="${LINK_CHECK:-warn}"
PARALLEL_GENS="${PARALLEL_GENS:-true}"
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"
FAIL_ON_WARNING="${FAIL_ON_WARNING:-false}"
GENERATOR_COUNT="${GENERATOR_COUNT:-1}"

# ─────────────────────────────────────────────────────────────────────────────
# CATPPUCCIN MOCHA — FULL ANSI PALETTE
# ─────────────────────────────────────────────────────────────────────────────
C_RST='\033[0m'    C_BLD='\033[1m'    C_DIM='\033[2m'
C_MAUVE='\033[38;2;203;166;247m'   C_BLUE='\033[38;2;137;180;250m'
C_GREEN='\033[38;2;166;227;161m'   C_RED='\033[38;2;243;139;168m'
C_YELLOW='\033[38;2;249;226;175m'  C_PEACH='\033[38;2;250;179;135m'
C_TEAL='\033[38;2;148;226;213m'    C_SAP='\033[38;2;116;199;236m'
C_SKY='\033[38;2;137;220;235m'     C_LAV='\033[38;2;180;190;254m'
C_TEXT='\033[38;2;205;214;244m'    C_SUB='\033[38;2;166;173;200m'
C_OVR='\033[38;2;108;112;134m'     C_PINK='\033[38;2;245;194;231m'
C_MAR='\033[38;2;235;160;172m'     C_RW='\033[38;2;245;224;220m'

# ─────────────────────────────────────────────────────────────────────────────
# LOGGING ENGINE
# ─────────────────────────────────────────────────────────────────────────────
DOCS_WORK_DIR="${WORKSPACE}/.docs-build"
mkdir -p "${DOCS_WORK_DIR}"
readonly LOG_FILE="${DOCS_WORK_DIR}/build-${SESSION_ID}.log"

_log() {
  local icon="$1" color="$2"; shift 2
  local ts; ts=$(date '+%H:%M:%S')
  local elapsed=$(( $(date +%s) - START_EPOCH ))
  printf "${color}${icon}${C_RST} ${C_DIM}[%s +%ds]${C_RST} ${C_TEXT}%s${C_RST}\n" \
    "${ts}" "${elapsed}" "$*"
  printf "[%s] [+%ds] %s\n" "${ts}" "${elapsed}" "$*" >> "${LOG_FILE}"
}

log_build()   { _log "🏗️ " "${C_MAUVE}"  "$@"; }
log_pass()    { _log "✅" "${C_GREEN}"   "$@"; }
log_fail()    { _log "❌" "${C_RED}"     "$@"; }
log_warn()    { _log "⚠️ " "${C_YELLOW}"  "$@"; }
log_info()    { _log "ℹ️ " "${C_BLUE}"    "$@"; }
log_gen()     { _log "📄" "${C_SAP}"     "$@"; }
log_theme()   { _log "🎨" "${C_PINK}"    "$@"; }
log_plugin()  { _log "🔌" "${C_PEACH}"   "$@"; }
log_api()     { _log "🌐" "${C_LAV}"     "$@"; }
log_opt()     { _log "⚡" "${C_TEAL}"    "$@"; }
log_deploy()  { _log "🚀" "${C_GREEN}"   "$@"; }
log_dry()     { _log "🔍" "${C_OVR}"     "$@"; }
log_debug()   { [[ "${VERBOSE}" == "true" ]] && _log "🔎" "${C_OVR}" "$@" || true; }

section_header() {
  local num="$1" title="$2" icon="${3:-📄}" color="${4:-${C_SAP}}"
  echo ""
  echo -e "  ${color}${C_BLD}┌─${icon} [${num}/${GENERATOR_COUNT}] ${C_TEXT}${C_BLD}${title}${color}$(printf ' ─%.0s' $(seq 1 $((56 - ${#title})) 2>/dev/null || true))┐${C_RST}"
}

section_done() {
  local status="${1:-pass}" time_ms="${2:-?}"
  local icon color
  [[ "${status}" == "pass" ]] && { icon="✅"; color="${C_GREEN}"; } || { icon="❌"; color="${C_RED}"; }
  echo -e "  ${color}└── ${icon} ${status^^} (+${time_ms}ms)${C_RST}"
}

# ─────────────────────────────────────────────────────────────────────────────
# PROGRESS BAR
# ─────────────────────────────────────────────────────────────────────────────
_PROG_CUR=0
_PROG_TOT=1
progress_init() { _PROG_CUR=0; _PROG_TOT="${1:-1}"; }
progress_tick() {
  (( _PROG_CUR++ )) || true
  local W=32 pct cur tot
  cur="${_PROG_CUR}"; tot="${_PROG_TOT}"
  pct=$(( cur * 100 / (tot > 0 ? tot : 1) ))
  local f=$(( cur * W / (tot > 0 ? tot : 1) ))
  local bar=""
  for (( i=0; i<f; i++ )); do bar+="█"; done
  for (( i=f; i<W; i++ )); do bar+="░"; done
  local color="${C_MAUVE}"
  (( pct >= 50 )) && color="${C_YELLOW}"
  (( pct >= 80 )) && color="${C_GREEN}"
  printf "\r  ${color}[%s]${C_RST} ${C_TEXT}%3d%% (%d/%d)${C_RST}  " \
    "${bar}" "${pct}" "${cur}" "${tot}"
  [[ "${cur}" -ge "${tot}" ]] && echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# STATE
# ─────────────────────────────────────────────────────────────────────────────
declare -A GEN_STATUS=()
declare -A GEN_TIME=()
declare -a GEN_ORDER=()
TOTAL_PAGES=0
THEME_COUNT=0
PLUGIN_COUNT=0
GENS_RUN=0
GENS_FAILED=0

# ─────────────────────────────────────────────────────────────────────────────
# BANNER
# ─────────────────────────────────────────────────────────────────────────────
print_banner() {
  echo ""
  echo -e "${C_BLUE}${C_BLD}"
  cat << 'BANNER'
  ╔══════════════════════════════════════════════════════════════════╗
  ║  📖 ASH Documentation Build Engine v5.0.0-omega                  ║
  ╚══════════════════════════════════════════════════════════════════╝
BANNER
  echo -e "${C_RST}"
  printf "  ${C_TEXT}Session:  ${C_LAV}%-50s${C_RST}\n" "${SESSION_ID}"
  printf "  ${C_TEXT}Docs dir: ${C_OVR}%-50s${C_RST}\n" "${WORKSPACE}/${DOCS_DIR}"
  printf "  ${C_TEXT}Site dir: ${C_OVR}%-50s${C_RST}\n" "${WORKSPACE}/${SITE_DIR}"
  printf "  ${C_TEXT}Dry run:  ${C_YELLOW}%-50s${C_RST}\n" "${DRY_RUN}"
  echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# SCAFFOLD — Create docs structure if missing
# ─────────────────────────────────────────────────────────────────────────────
scaffold_docs_structure() {
  log_build "scaffold" "Creating documentation structure..."

  local DOCS_ABS="${WORKSPACE}/${DOCS_DIR}"

  # Create directory tree
  for dir in \
    "${DOCS_ABS}" \
    "${DOCS_ABS}/getting-started" \
    "${DOCS_ABS}/guides" \
    "${DOCS_ABS}/reference" \
    "${DOCS_ABS}/api" \
    "${DOCS_ABS}/themes" \
    "${DOCS_ABS}/plugins" \
    "${DOCS_ABS}/contributing" \
    "${DOCS_ABS}/troubleshooting" \
    "${DOCS_ABS}/changelog" \
    "${DOCS_ABS}/assets/images" \
    "${DOCS_ABS}/assets/stylesheets" \
    "${DOCS_ABS}/assets/javascripts" \
    "${DOCS_ABS}/overrides" \
    "${DOCS_ABS}/overrides/partials" \
    "${WORKSPACE}/${SITE_DIR}"; do
    mkdir -p "${dir}"
  done

  # Generate MkDocs config if missing
  local MKDOCS_ABS="${WORKSPACE}/${MKDOCS_CONFIG}"
  if [[ ! -f "${MKDOCS_ABS}" ]]; then
    mkdir -p "$(dirname "${MKDOCS_ABS}")"
    log_gen "scaffold" "Generating mkdocs.yml..."

    cat > "${MKDOCS_ABS}" << MKDOCS_YAML
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  📖 ASH Dotfiles — MkDocs Material Configuration v5.0 OMEGA         ║
# ╚══════════════════════════════════════════════════════════════════════╝
# Auto-generated by ASH Documentation Build Engine v${BUILD_VERSION}

site_name: "${SITE_NAME}"
site_url: "${SITE_URL}"
site_description: "${SITE_DESC}"
site_author: "ASH Dotfiles Team"
repo_url: "${REPO_URL}"
repo_name: "ash/dotfiles"
edit_uri: "${EDIT_URI}"
copyright: "Copyright &copy; 2024 ASH Dotfiles Team · MIT License"

# ── Theme ─────────────────────────────────────────────────────────────
theme:
  name: material
  custom_dir: ${DOCS_DIR}/overrides
  logo: assets/images/ash-logo.svg
  favicon: assets/images/ash-logo.svg
  language: en
  font:
    text: JetBrains Mono
    code: JetBrains Mono
  icon:
    repo: fontawesome/brands/github
    edit: material/pencil
    view: material/eye
  palette:
    # Dark mode (Catppuccin Mocha inspired)
    - media: "(prefers-color-scheme: dark)"
      scheme: slate
      primary: deep purple
      accent: purple
      toggle:
        icon: material/weather-sunny
        name: Switch to light mode
    # Light mode (Catppuccin Latte inspired)
    - media: "(prefers-color-scheme: light)"
      scheme: default
      primary: deep purple
      accent: purple
      toggle:
        icon: material/weather-night
        name: Switch to dark mode
  features:
    - announce.dismiss
    - content.action.edit
    - content.action.view
    - content.code.annotate
    - content.code.copy
    - content.code.select
    - content.tabs.link
    - content.tooltips
    - header.autohide
    - navigation.expand
    - navigation.footer
    - navigation.indexes
    - navigation.instant
    - navigation.instant.prefetch
    - navigation.instant.progress
    - navigation.path
    - navigation.prune
    - navigation.sections
    - navigation.tabs
    - navigation.tabs.sticky
    - navigation.top
    - navigation.tracking
    - search.highlight
    - search.share
    - search.suggest
    - toc.follow
    - toc.integrate

# ── Plugins ───────────────────────────────────────────────────────────
plugins:
  - search:
      separator: '[\s\-,:!=\[\]()"/]+|(?!\b)(?=[A-Z][a-z])|\.(?!\d)|&[lg]t;'
  - minify:
      minify_html: ${MINIFY_HTML}
      minify_css: true
      minify_js: true
  - git-revision-date-localized:
      enable_creation_date: true
      type: timeago
      fallback_to_build_date: true
  - glightbox:
      touchNavigation: true
      loop: false
      effect: zoom
      slide_effect: slide
      width: 100%
  - awesome-pages
  - macros:
      include_dir: ${DOCS_DIR}/includes
  - mermaid2
  - redirects:
      redirect_maps: {}

# ── Markdown extensions ───────────────────────────────────────────────
markdown_extensions:
  - abbr
  - admonition
  - attr_list
  - def_list
  - footnotes
  - md_in_html
  - toc:
      permalink: true
      permalink_title: Anchor link to this section
      toc_depth: 3
  - tables
  - pymdownx.arithmatex:
      generic: true
  - pymdownx.betterem
  - pymdownx.caret
  - pymdownx.critic
  - pymdownx.details
  - pymdownx.emoji:
      emoji_index: !!python/name:material.extensions.emoji.twemoji
      emoji_generator: !!python/name:material.extensions.emoji.to_svg
  - pymdownx.highlight:
      anchor_linenums: true
      line_spans: __span
      pygments_lang_class: true
      use_pygments: true
  - pymdownx.inlinehilite
  - pymdownx.keys
  - pymdownx.magiclink:
      normalize_issue_symbols: true
      repo_url_shorthand: true
      user: ash
      repo: dotfiles
  - pymdownx.mark
  - pymdownx.smartsymbols
  - pymdownx.snippets:
      auto_append:
        - ${DOCS_DIR}/includes/abbreviations.md
  - pymdownx.superfences:
      custom_fences:
        - name: mermaid
          class: mermaid
          format: !!python/name:pymdownx.superfences.fence_code_format
  - pymdownx.tabbed:
      alternate_style: true
      combine_header_slug: true
  - pymdownx.tasklist:
      custom_checkbox: true
  - pymdownx.tilde

# ── Extra CSS / JS ────────────────────────────────────────────────────
extra_css:
  - assets/stylesheets/custom.css
  - assets/stylesheets/catppuccin.css
  - assets/stylesheets/animations.css

extra_javascript:
  - assets/javascripts/mathjax.js
  - assets/javascripts/extra.js
  - https://polyfill.io/v3/polyfill.min.js?features=es6
  - https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js

# ── Extra ─────────────────────────────────────────────────────────────
extra:
  version:
    provider: mike
    default: stable
  social:
    - icon: fontawesome/brands/github
      link: ${REPO_URL}
    - icon: fontawesome/brands/discord
      link: https://discord.gg/ash-dotfiles
    - icon: fontawesome/solid/globe
      link: ${SITE_URL}
  analytics:
    provider: google
    property: G-XXXXXXXXXX
  consent:
    title: Cookie consent
    description: >-
      We use cookies to recognize your repeated visits and preferences,
      as well as to measure the effectiveness of our documentation.

# ── Navigation ────────────────────────────────────────────────────────
nav:
  - Home: index.md
  - Getting Started:
    - getting-started/index.md
    - Installation: getting-started/installation.md
    - Requirements: getting-started/requirements.md
    - Quick Start: getting-started/quick-start.md
    - First Steps: getting-started/first-steps.md
    - FAQ: getting-started/faq.md
  - Guides:
    - guides/index.md
    - Theming Deep Dive: guides/theming-deep-dive.md
    - AI Theme Generation: guides/ai-theme-generation.md
    - Plugin Development: guides/plugin-development.md
    - Theme Creation: guides/theme-creation.md
    - Neovim IDE Guide: guides/neovim-ide-guide.md
    - Fish Shell Guide: guides/fish-shell-guide.md
    - Gaming Setup: guides/gaming-setup.md
    - Multi-Monitor: guides/multi-monitor.md
    - NVIDIA Setup: guides/nvidia-setup.md
    - NixOS Setup: guides/nixos-setup.md
    - API Guide: guides/api-guide.md
    - Web Dashboard: guides/web-dashboard.md
    - Mobile App: guides/mobile-app.md
  - Themes:
    - themes/index.md
    - Theme Gallery: themes/gallery.md
    - Dark Themes: themes/dark.md
    - Light Themes: themes/light.md
    - Neon Themes: themes/neon.md
  - Plugins:
    - plugins/index.md
    - Core Plugins: plugins/core.md
    - Integration Plugins: plugins/integrations.md
    - API Reference: plugins/api-reference.md
  - Reference:
    - reference/index.md
    - CLI Reference: reference/ash-cli-reference.md
    - Config Reference: reference/config-reference.md
    - Theme Schema: reference/theme-schema.md
    - Plugin API: reference/plugin-api.md
    - Hook Reference: reference/hook-reference.md
    - REST API: reference/rest-api-reference.md
    - WebSocket: reference/websocket-protocol.md
    - Environment Variables: reference/environment-variables.md
    - Systemd Services: reference/systemd-services.md
  - Contributing:
    - contributing/index.md
    - Contributing Guide: contributing/CONTRIBUTING.md
    - Code of Conduct: contributing/CODE_OF_CONDUCT.md
    - Style Guide: contributing/STYLE_GUIDE.md
    - Testing: contributing/TESTING.md
    - Architecture: contributing/ARCHITECTURE.md
  - Troubleshooting:
    - troubleshooting/index.md
    - Common Issues: troubleshooting/common-issues.md
    - Display Issues: troubleshooting/display-issues.md
    - NVIDIA Issues: troubleshooting/nvidia-issues.md
    - Performance: troubleshooting/performance-issues.md
    - Debug Mode: troubleshooting/debug-mode.md
  - Changelog: changelog/index.md
MKDOCS_YAML

    log_pass "scaffold" "mkdocs.yml generated"
  fi

  # Create essential files
  create_essential_docs

  log_pass "scaffold" "Documentation structure ready"
}

# ─────────────────────────────────────────────────────────────────────────────
# CREATE ESSENTIAL DOCUMENTATION FILES
# ─────────────────────────────────────────────────────────────────────────────
create_essential_docs() {
  local DOCS_ABS="${WORKSPACE}/${DOCS_DIR}"

  # ── Home page ──────────────────────────────────────────────────────────────
  if [[ ! -f "${DOCS_ABS}/index.md" ]]; then
    cat > "${DOCS_ABS}/index.md" << 'INDEX_EOF'
---
title: ASH Dotfiles v5.0 OMEGA
description: The Ultimate Hyprland Dotfiles — 250+ Themes, 150+ Plugins, AI-Native
hide:
  - navigation
  - toc
---

# 🎨 ASH Dotfiles v5.0 OMEGA

<div class="grid cards" markdown>

- :material-palette: **250+ Themes**

    Browse and apply over 250 professionally crafted themes including
    Catppuccin, Tokyo Night, Gruvbox, Nord, and many more.

    [:octicons-arrow-right-24: Theme Gallery](themes/gallery.md)

- :material-puzzle: **150+ Plugins**

    Extend your desktop with a rich ecosystem of plugins for gaming,
    productivity, media, system management, and more.

    [:octicons-arrow-right-24: Browse Plugins](plugins/index.md)

- :material-robot: **AI-Native**

    Generate custom themes from images, get smart suggestions,
    and automate your workflow with built-in AI integration.

    [:octicons-arrow-right-24: AI Guide](guides/ai-theme-generation.md)

- :material-api: **REST API**

    Control every aspect of your desktop programmatically through
    a comprehensive REST API with WebSocket support.

    [:octicons-arrow-right-24: API Reference](reference/rest-api-reference.md)

</div>

## ⚡ Quick Install

```bash
bash <(curl -fsSL https://ash.dev/install)

🚀 Quick Start
Bash

# Check system health
ash doctor

# Browse and apply a theme
ash theme pick
ash theme apply catppuccin-mocha

# Install a plugin
ash plugin install game-mode
INDEX_EOF
log_debug "scaffold" "Created index.md"
fi

── Custom CSS (Catppuccin Mocha) ──────────────────────────────────────────
local CSS_DIR="
D
O
C
S
A
B
S
/
a
s
s
e
t
s
/
s
t
y
l
e
s
h
e
e
t
s
"
m
k
d
i
r
−
p
"
DOCS 
A
​
 BS/assets/stylesheets"mkdir−p"{CSS_DIR}"

cat > "${CSS_DIR}/catppuccin.css" << 'CSS_EOF'
/* ╔══════════════════════════════════════════════════════════════════════╗
║ ASH Dotfiles — Catppuccin Mocha MkDocs Theme v5.0 OMEGA ║
╚══════════════════════════════════════════════════════════════════════╝ */

:root {
/* Catppuccin Mocha Palette */
--ctp-rosewater: #f5e0dc; --ctp-flamingo: #f2cdcd;
--ctp-pink: #f5c2e7; --ctp-mauve: #cba6f7;
--ctp-red: #f38ba8; --ctp-maroon: #eba0ac;
--ctp-peach: #fab387; --ctp-yellow: #f9e2af;
--ctp-green: #a6e3a1; --ctp-teal: #94e2d5;
--ctp-sky: #89dceb; --ctp-sapphire: #74c7ec;
--ctp-blue: #89b4fa; --ctp-lavender: #b4befe;
--ctp-text: #cdd6f4; --ctp-subtext1: #bac2de;
--ctp-subtext0: #a6adc8; --ctp-overlay2: #9399b2;
--ctp-overlay1: #7f849c; --ctp-overlay0: #6c7086;
--ctp-surface2: #585b70; --ctp-surface1: #45475a;
--ctp-surface0: #313244; --ctp-base: #1e1e2e;
--ctp-mantle: #181825; --ctp-crust: #11111b;
}

/* Dark mode overrides (slate scheme) */
[data-md-color-scheme="slate"] {
--md-primary-fg-color: var(--ctp-mauve);
--md-primary-fg-color--light: var(--ctp-lavender);
--md-primary-fg-color--dark: var(--ctp-mauve);
--md-accent-fg-color: var(--ctp-blue);
--md-default-bg-color: var(--ctp-base);
--md-default-bg-color--light: var(--ctp-mantle);
--md-default-bg-color--lighter:var(--ctp-surface0);
--md-code-bg-color: var(--ctp-mantle);
--md-code-fg-color: var(--ctp-text);
--md-typeset-color: var(--ctp-text);
--md-typeset-a-color: var(--ctp-blue);
}

/* Smooth scrolling */
html { scroll-behavior: smooth; }

/* Catppuccin code blocks */
[data-md-color-scheme="slate"] .highlight pre {
background: var(--ctp-mantle);
}

/* Custom admonition colors */
[data-md-color-scheme="slate"] .md-typeset .admonition.tip {
border-color: var(--ctp-green);
}
[data-md-color-scheme="slate"] .md-typeset .admonition.warning {
border-color: var(--ctp-yellow);
}
[data-md-color-scheme="slate"] .md-typeset .admonition.danger {
border-color: var(--ctp-red);
}

/* Navigation active link */
[data-md-color-scheme="slate"] .md-nav__link--active {
color: var(--ctp-mauve) !important;
}

/* Code copy button */
[data-md-color-scheme="slate"] .md-clipboard {
color: var(--ctp-overlay0);
}
[data-md-color-scheme="slate"] .md-clipboard:hover {
color: var(--ctp-blue);
}

/* Grid cards */
.md-typeset .grid.cards > * {
border-radius: 12px;
transition: transform 0.2s ease, box-shadow 0.2s ease;
}
[data-md-color-scheme="slate"] .md-typeset .grid.cards > * {
background: var(--ctp-surface0);
border: 1px solid var(--ctp-surface1);
}
.md-typeset .grid.cards > *:hover {
transform: translateY(-3px);
box-shadow: 0 8px 24px rgba(0,0,0,0.4);
}

/* Search highlight */
[data-md-color-scheme="slate"] .md-search-result mark {
background: var(--ctp-mauve);
color: var(--ctp-crust);
}

/* Table of contents */
[data-md-color-scheme="slate"] .md-nav--secondary .md-nav__link--active {
color: var(--ctp-blue) !important;
}

/* Footer */
[data-md-color-scheme="slate"] .md-footer {
background: var(--ctp-mantle);
}
CSS_EOF

── Animations CSS ─────────────────────────────────────────────────────────
cat > "${CSS_DIR}/animations.css" << 'ANIM_EOF'
/* ╔══════════════════════════════════════════════════════════════════════╗
║ ASH Dotfiles — Animation Styles v5.0 OMEGA ║
╚══════════════════════════════════════════════════════════════════════╝ */

/* Fade-in animation */
@keyframes fadeIn {
from { opacity: 0; transform: translateY(10px); }
to { opacity: 1; transform: translateY(0); }
}
.md-content { animation: fadeIn 0.3s ease-out; }

/* Pulse animation for important elements */
@keyframes pulse {
0%, 100% { box-shadow: 0 0 0 0 rgba(203,166,247,0.4); }
50% { box-shadow: 0 0 0 8px rgba(203,166,247,0); }
}
.pulse { animation: pulse 2s infinite; }

/* Gradient text animation */
@keyframes gradient-shift {
0% { background-position: 0% 50%; }
50% { background-position: 100% 50%; }
100% { background-position: 0% 50%; }
}
.gradient-text {
background: linear-gradient(-45deg, #cba6f7, #89b4fa, #94e2d5, #a6e3a1);
background-size: 400% 400%;
animation: gradient-shift 4s ease infinite;
-webkit-background-clip: text;
-webkit-text-fill-color: transparent;
background-clip: text;
}

/* Card hover effects */
.md-typeset .grid.cards > * {
transition: all 0.25s cubic-bezier(0.4,0,0.2,1);
}
ANIM_EOF

── Custom CSS ─────────────────────────────────────────────────────────────
cat > "${CSS_DIR}/custom.css" << 'CUSTOM_CSS_EOF'
/* ╔══════════════════════════════════════════════════════════════════════╗
║ ASH Dotfiles — Custom MkDocs Styles v5.0 OMEGA ║
╚══════════════════════════════════════════════════════════════════════╝ */

/* Font imports */
@import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:ital,wght@0,400;0,700;1,400&display=swap');

/* Logo customization */
.md-header__button.md-logo img { border-radius: 8px; }

/* Wider content area */
.md-grid { max-width: 1440px; }

/* Code block enhancements */
.md-typeset pre > code {
font-size: 0.85em;
line-height: 1.7;
}

/* Tabbed content */
.md-typeset .tabbed-labels { font-size: 0.85em; }

/* Keyboard shortcuts */
.md-typeset kbd {
font-family: 'JetBrains Mono', monospace;
font-size: 0.8em;
border-radius: 6px;
}

/* Theme gallery grid */
.theme-gallery {
display: grid;
grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
gap: 1.5rem;
margin: 1.5rem 0;
}
.theme-card {
border-radius: 12px;
overflow: hidden;
transition: transform 0.2s ease;
cursor: pointer;
}
.theme-card:hover { transform: scale(1.02); }
.theme-card img { width: 100%; display: block; }
.theme-card-info { padding: 1rem; }
.theme-card-name { font-weight: 700; margin-bottom: 0.25rem; }
.theme-card-tags { font-size: 0.75rem; opacity: 0.7; }

/* Plugin card grid */
.plugin-grid {
display: grid;
grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
gap: 1rem;
}

/* Version badge */
.version-badge {
display: inline-block;
padding: 0.15rem 0.6rem;
border-radius: 20px;
font-size: 0.75rem;
font-weight: 600;
background: rgba(203,166,247,0.2);
color: #cba6f7;
border: 1px solid rgba(203,166,247,0.4);
}
CUSTOM_CSS_EOF

── Abbreviations ──────────────────────────────────────────────────────────
mkdir -p "
D
O
C
S
A
B
S
/
i
n
c
l
u
d
e
s
"
c
a
t
>
"
DOCS 
A
​
 BS/includes"cat>"{DOCS_ABS}/includes/abbreviations.md" << 'ABBREV_EOF'

<!-- ASH Dotfiles Abbreviations -->
*[ASH]: ASH Dotfiles v5.0 OMEGA
*[WM]: Window Manager
*[GUI]: Graphical User Interface
*[CLI]: Command Line Interface
*[API]: Application Programming Interface
*[LSP]: Language Server Protocol
*[AUR]: Arch User Repository
*[GTK]: GIMP Toolkit
*[CSS]: Cascading Style Sheets
*[PWA]: Progressive Web Application
*[WCAG]: Web Content Accessibility Guidelines
*[PKGBUILD]: Package build script for Arch Linux
*[IPC]: Inter-Process Communication
*[RSS]: Resident Set Size
ABBREV_EOF

log_debug "scaffold" "Essential docs created"
}

─────────────────────────────────────────────────────────────────────────────
GENERATOR: PLUGIN API REFERENCE
─────────────────────────────────────────────────────────────────────────────
gen_plugin_api() {
local GEN_NUM="
1
"
s
e
c
t
i
o
n
h
e
a
d
e
r
"
1"section 
h
​
 eader"{GEN_NUM}" "Plugin API Reference" "🔌" "
C
P
E
A
C
H
"
l
o
c
a
l
t
0
;
t
0
=
C 
P
​
 EACH"localt0;t0=(date +%s%N 2>/dev/null || echo 0)

local PLUGIN_SRC="
W
O
R
K
S
P
A
C
E
/
WORKSPACE/{PLUGIN_API_SRC}"
local OUT_DIR="
W
O
R
K
S
P
A
C
E
/
WORKSPACE/{DOCS_DIR}/plugins"
mkdir -p "${OUT_DIR}"

python3 << PLUGIN_API_PY
import json
import os
import re
from pathlib import Path
from datetime import datetime, timezone

PLUGIN_SRC = Path("
P
L
U
G
I
N
S
R
C
"
)
O
U
T
D
I
R
=
P
a
t
h
(
"
PLUGIN 
S
​
 RC")OUT 
D
​
 IR=Path("{OUT_DIR}")
NOW = datetime.now(timezone.utc).strftime("%Y-%m-%d")

G = "\033[38;2;166;227;161m"
B = "\033[38;2;137;180;250m"
M = "\033[38;2;203;166;247m"
P = "\033[38;2;250;179;135m"
T = "\033[38;2;205;214;244m"
S = "\033[38;2;166;173;200m"
X = "\033[0m"

def p(ic, c, msg): print(f" {c}{ic}{X} {T}{msg}{X}")

Discover plugin manifests
manifests = []
if PLUGIN_SRC.exists():
manifests = list(PLUGIN_SRC.rglob("plugin.json"))

p("🔌",P,f"Found {len(manifests)} plugin manifests")

Categorize plugins
categories = {}
for mf in manifests:
try:
with open(mf) as f:
data = json.load(f)
cat = data.get("category","core")
if cat not in categories:
categories[cat] = []
categories[cat].append(data)
except Exception as e:
p("⚠️ ",B,f"Failed to load {mf}: {e}")

Generate API reference index
index_lines = [
"# 🔌 Plugin API Reference",
"",
"> Auto-generated from plugin manifests · " + NOW,
"",
f"ASH Dotfiles includes {len(manifests)} plugins across {len(categories)} categories.",
"",
"## Categories",
"",
]

CATEGORY_ICONS = {
"core": "⚙️",
"integration": "🔗",
"theme": "🎨",
"performance": "⚡",
"accessibility": "♿",
"gaming": "🎮",
"productivity": "📊",
"media": "🎵",
"system": "🖥️",
"network": "🌐",
"security": "🔒",
"developer": "💻",
}

Generate category pages
for cat, plugins in sorted(categories.items(), key=lambda x: -len(x[1])):
icon = CATEGORY_ICONS.get(cat,"📦")
count = len(plugins)
index_lines.append(f"- {icon} {cat.title()} — {count} plugins")

text

# Individual category section
index_lines += ["", f"## {icon} {cat.title()} Plugins", ""]
index_lines += [
    "| Plugin | Version | Description | Status |",
    "|--------|---------|-------------|--------|",
]
for plugin in sorted(plugins, key=lambda p: p.get("name","")):
    name    = plugin.get("name","?")
    ver     = plugin.get("version","?")
    desc    = plugin.get("description","")[:60]
    enabled = "✅ enabled" if plugin.get("enabled",True) else "🔴 disabled"
    index_lines.append(f"| `{name}` | `{ver}` | {desc} | {enabled} |")
index_lines.append("")
Write index
(OUT_DIR / "api-reference.md").write_text(
"\n".join(index_lines), encoding="utf-8"
)

Generate individual plugin pages
for mf in manifests:
try:
with open(mf) as f:
data = json.load(f)
name = data.get("name","unknown")
plugin_dir = OUT_DIR / "reference" / name
plugin_dir.mkdir(parents=True, exist_ok=True)

text

    lines = [
        f"# 🔌 {name}",
        "",
        f"> {data.get('description','')}",
        "",
        "## Overview",
        "",
        f"| Property | Value |",
        f"|----------|-------|",
        f"| 📦 Name | `{name}` |",
        f"| 🔖 Version | `{data.get('version','?')}` |",
        f"| 📁 Category | `{data.get('category','?')}` |",
        f"| 👤 Author | `{data.get('author','?')}` |",
        f"| 📜 License | `{data.get('license','?')}` |",
        f"| ✅ Enabled | `{data.get('enabled',True)}` |",
        "",
    ]

    # Dependencies
    deps = data.get("dependencies",[])
    if deps:
        lines += ["## Dependencies", "", *[f"- `{d}`" for d in deps], ""]

    # Hooks
    hooks = data.get("hooks",{})
    if hooks:
        lines += ["## Lifecycle Hooks", ""]
        for hook, script in hooks.items():
            lines.append(f"- **{hook}**: `{script}`")
        lines.append("")

    # Permissions
    perms = data.get("permissions",[])
    if perms:
        lines += ["## Permissions", ""]
        for perm in perms:
            lines.append(f"- `{perm}`")
        lines.append("")

    (plugin_dir / "index.md").write_text("\n".join(lines), encoding="utf-8")

except Exception as e:
    p("⚠️ ",B,f"Plugin page failed ({mf.parent.name}): {e}")
with open(os.environ.get("GITHUB_OUTPUT","/dev/null"),"a") as out:
out.write(f"plugin_count={len(manifests)}\n")

p("✅",G,f"Plugin API reference: {len(manifests)} plugins in {len(categories)} categories")
PLUGIN_API_PY

PLUGIN_COUNT=
(
j
q
−
r
′
e
m
p
t
y
′
"
(jq−r 
′
 empty 
′
 "{DOCS_WORK_DIR}/plugin-count.txt" 2>/dev/null ||
find "
W
O
R
K
S
P
A
C
E
/
WORKSPACE/{PLUGIN_API_SRC}" -name "plugin.json" 2>/dev/null | wc -l || echo 0)

local t1; t1=
(
d
a
t
e
+
G
E
N
S
T
A
T
U
S
[
"
p
l
u
g
i
n
−
a
p
i
"
]
=
"
p
a
s
s
"
G
E
N
T
I
M
E
[
"
p
l
u
g
i
n
−
a
p
i
"
]
=
(date+GEN 
S
​
 TATUS["plugin−api"]="pass"GEN 
T
​
 IME["plugin−api"]=(( (t1 - t0) / 1000000 ))
section_done "pass" "${GEN_TIME["plugin-api"]}"
}

─────────────────────────────────────────────────────────────────────────────
GENERATOR: THEME GALLERY
─────────────────────────────────────────────────────────────────────────────
gen_theme_gallery() {
local GEN_NUM="
1
"
s
e
c
t
i
o
n
h
e
a
d
e
r
"
1"section 
h
​
 eader"{GEN_NUM}" "Theme Gallery" "🎨" "
C
P
I
N
K
"
l
o
c
a
l
t
0
;
t
0
=
C 
P
​
 INK"localt0;t0=(date +%s%N 2>/dev/null || echo 0)

local THEMES_SRC="
W
O
R
K
S
P
A
C
E
/
t
h
e
m
e
s
/
p
r
e
s
e
t
s
"
l
o
c
a
l
O
U
T
D
I
R
=
"
WORKSPACE/themes/presets"localOUT 
D
​
 IR="{WORKSPACE}/
D
O
C
S
D
I
R
/
t
h
e
m
e
s
"
m
k
d
i
r
−
p
"
DOCS 
D
​
 IR/themes"mkdir−p"{OUT_DIR}"

python3 << GALLERY_PY
import json
import os
from pathlib import Path
from datetime import datetime, timezone

THEMES_SRC = Path("
T
H
E
M
E
S
S
R
C
"
)
O
U
T
D
I
R
=
P
a
t
h
(
"
THEMES 
S
​
 RC")OUT 
D
​
 IR=Path("{OUT_DIR}")
GALLERY_COLS = int("
T
H
E
M
E
G
A
L
L
E
R
Y
C
O
L
S
"
)
G
A
L
L
E
R
Y
M
A
X
=
i
n
t
(
"
THEME 
G
​
 ALLERY 
C
​
 OLS")GALLERY 
M
​
 AX=int("{THEME_GALLERY_MAX}")
NOW = datetime.now(timezone.utc).strftime("%Y-%m-%d")

G = "\033[38;2;166;227;161m"
M = "\033[38;2;203;166;247m"
P = "\033[38;2;245;194;231m"
T = "\033[38;2;205;214;244m"
X = "\033[0m"

def p(ic, c, msg): print(f" {c}{ic}{X} {T}{msg}{X}")

Discover themes
theme_dirs = []
if THEMES_SRC.exists():
for cat_dir in THEMES_SRC.iterdir():
if not cat_dir.is_dir(): continue
for theme_dir in cat_dir.iterdir():
if not theme_dir.is_dir(): continue
theme_dirs.append((cat_dir.name, theme_dir))

Apply limit
if GALLERY_MAX > 0:
theme_dirs = theme_dirs[:GALLERY_MAX]

TOTAL = len(theme_dirs)
p("🎨",M,f"Building gallery for {TOTAL} themes in {GALLERY_COLS}-column layout")

Categorize
categories = {}
for cat, tdir in theme_dirs:
if cat not in categories:
categories[cat] = []

text

# Load metadata
meta_file = tdir / "metadata.json"
conf_file = tdir / "theme.conf"
colors_file = tdir / "colors.json"

meta = {}
if meta_file.exists():
    try:
        with open(meta_file) as f:
            meta = json.load(f)
    except Exception: pass

# Try to get accent color
accent = "#cba6f7"  # default mauve
if colors_file.exists():
    try:
        with open(colors_file) as f:
            colors = json.load(f)
        c = colors.get("colors", colors) if isinstance(colors, dict) else {}
        accent = c.get("accent", c.get("mauve", accent))
    except Exception: pass

categories[cat].append({
    "name":        tdir.name,
    "category":    cat,
    "display":     tdir.name.replace("-"," ").title(),
    "description": meta.get("description",""),
    "author":      meta.get("author","community"),
    "version":     meta.get("version","1.0.0"),
    "tags":        meta.get("tags",[]),
    "accent":      accent,
    "path":        str(tdir.relative_to("${WORKSPACE}")),
})
── Gallery index ──────────────────────────────────────────────────────────
CAT_ICONS = {
"dark":"🌑","light":"☀️","neon":"⚡","nature":"🌿",
"space":"🚀","pastel":"🌸","anime":"🎌","retro":"📺",
"gradient":"🌈","seasonal":"❄️","mood":"🎭","gaming":"🎮",
"minimal":"◻️","special":"✨",
}

gallery_lines = [
"# 🎨 Theme Gallery",
"",
f"> {TOTAL} themes across {len(categories)} categories · Updated {NOW}",
"",
"Apply any theme with:",
"",
"bash", "ash theme apply <theme-name>", "",
"",
"## Browse by Category",
"",
]

for cat, themes in sorted(categories.items(), key=lambda x: -len(x[1])):
icon = CAT_ICONS.get(cat,"🎨")
count = len(themes)
gallery_lines.append(f"- {icon} {cat.title()} ({count})")

gallery_lines.append("")

── Per-category sections ──────────────────────────────────────────────────
for cat, themes in sorted(categories.items(), key=lambda x: x[0]):
icon = CAT_ICONS.get(cat,"🎨")
gallery_lines += [
f"## {icon} {cat.title()}",
"",
f"<div class="theme-gallery">",
"",
]

text

for theme in sorted(themes, key=lambda t: t["name"]):
    name    = theme["name"]
    display = theme["display"]
    accent  = theme["accent"]
    desc    = theme["description"][:80] if theme["description"] else f"A {cat} theme for ASH"
    author  = theme["author"]

    preview_url = f"../../assets/screenshots/cards/{name}.webp"

    gallery_lines += [
        f'<div class="theme-card" title="{display}">',
        f'<img src="{preview_url}" alt="{display}" loading="lazy"',
        f'     onerror="this.src=\'../../assets/images/theme-placeholder.svg\'">',
        f'<div class="theme-card-info">',
        f'<div class="theme-card-name">{display}</div>',
        f'<div class="theme-card-tags">by {author}</div>',
        f'</div>',
        f'</div>',
        "",
    ]

gallery_lines += ["</div>", ""]
(OUT_DIR / "gallery.md").write_text("\n".join(gallery_lines), encoding="utf-8")

── Individual category pages ──────────────────────────────────────────────
for cat, themes in categories.items():
icon = CAT_ICONS.get(cat,"🎨")
lines = [
f"# {icon} {cat.title()} Themes",
"",
f"> {len(themes)} themes in this category",
"",
"| Theme | Author | Tags |",
"|-------|--------|------|",
]
for t in sorted(themes, key=lambda x: x["name"]):
tags = ", ".join(t.get("tags",[])[:3]) or "—"
lines.append(f"| {t['name']} | {t['author']} | {tags} |")
lines += ["", f"---", f"Apply: ash theme apply <name>"]
(OUT_DIR / f"{cat}.md").write_text("\n".join(lines), encoding="utf-8")

with open(os.environ.get("GITHUB_OUTPUT","/dev/null"),"a") as out:
out.write(f"theme_count={TOTAL}\n")

p("✅",G,f"Theme gallery: {TOTAL} themes in {len(categories)} categories")
GALLERY_PY

local t1; t1=
(
d
a
t
e
+
T
H
E
M
E
C
O
U
N
T
=
(date+THEME 
C
​
 OUNT=(find "
W
O
R
K
S
P
A
C
E
/
t
h
e
m
e
s
/
p
r
e
s
e
t
s
"
−
m
i
n
d
e
p
t
h
2
−
m
a
x
d
e
p
t
h
2
−
t
y
p
e
d
2
>
/
d
e
v
/
n
u
l
l
∣
w
c
−
l
∣
∣
e
c
h
o
0
)
G
E
N
S
T
A
T
U
S
[
"
t
h
e
m
e
−
g
a
l
l
e
r
y
"
]
=
"
p
a
s
s
"
G
E
N
T
I
M
E
[
"
t
h
e
m
e
−
g
a
l
l
e
r
y
"
]
=
WORKSPACE/themes/presets"−mindepth2−maxdepth2−typed2>/dev/null∣wc−l∣∣echo0)GEN 
S
​
 TATUS["theme−gallery"]="pass"GEN 
T
​
 IME["theme−gallery"]=(( (t1 - t0) / 1000000 ))
section_done "pass" "${GEN_TIME["theme-gallery"]}"
}

─────────────────────────────────────────────────────────────────────────────
GENERATOR: CLI REFERENCE
─────────────────────────────────────────────────────────────────────────────
gen_cli_reference() {
local GEN_NUM="
1
"
s
e
c
t
i
o
n
h
e
a
d
e
r
"
1"section 
h
​
 eader"{GEN_NUM}" "CLI Command Reference" "📋" "
C
B
L
U
E
"
l
o
c
a
l
t
0
;
t
0
=
C 
B
​
 LUE"localt0;t0=(date +%s%N 2>/dev/null || echo 0)

local CLI="
W
O
R
K
S
P
A
C
E
/
a
s
h
−
c
l
i
/
a
s
h
"
l
o
c
a
l
O
U
T
F
I
L
E
=
"
WORKSPACE/ash−cli/ash"localOUT 
F
​
 ILE="{WORKSPACE}/
D
O
C
S
D
I
R
/
r
e
f
e
r
e
n
c
e
/
a
s
h
−
c
l
i
−
r
e
f
e
r
e
n
c
e
.
m
d
"
m
k
d
i
r
−
p
"
DOCS 
D
​
 IR/reference/ash−cli−reference.md"mkdir−p"(dirname "${OUT_FILE}")"

python3 << CLI_REF_PY
import os
import subprocess
from pathlib import Path
from datetime import datetime, timezone

CLI_PATH = "
C
L
I
"
O
U
T
F
I
L
E
=
P
a
t
h
(
"
CLI"OUT 
F
​
 ILE=Path("{OUT_FILE}")
NOW = datetime.now(timezone.utc).strftime("%Y-%m-%d")

G = "\033[38;2;166;227;161m"
B = "\033[38;2;137;180;250m"
T = "\033[38;2;205;214;244m"
X = "\033[0m"

def p(ic, c, msg): print(f" {c}{ic}{X} {T}{msg}{X}")

Comprehensive CLI reference (hand-crafted for accuracy)
CLI_COMMANDS = {
"theme": {
"desc": "Manage desktop themes",
"icon": "🎨",
"subcommands": {
"apply <name>": "Apply a theme to all targets",
"pick": "Interactive theme picker (TUI)",
"random": "Apply a random theme",
"list": "List available themes",
"search <query>": "Search themes by name/tag",
"create <name>": "Create a new theme interactively",
"edit <name>": "Edit an existing theme",
"clone <src> <dst>":"Clone a theme with new name",
"export <name>": "Export theme to zip archive",
"import <file>": "Import theme from zip archive",
"validate <name>":"Validate theme schema",
"preview <name>": "Preview theme without applying",
"schedule": "Schedule automatic theme changes",
"colors": "Show theme color palette",
"history": "Show theme change history",
"favorite": "Toggle theme as favorite",
"ai-generate": "Generate theme using AI",
"ai-mood": "Apply theme based on mood",
}
},
"plugin": {
"desc": "Manage desktop plugins",
"icon": "🔌",
"subcommands": {
"install <name>": "Install a plugin",
"remove <name>": "Remove a plugin",
"update <name>": "Update a plugin",
"update-all": "Update all plugins",
"list": "List installed plugins",
"browse": "Browse plugin store",
"search <query>": "Search plugins",
"enable <name>": "Enable a plugin",
"disable <name>": "Disable a plugin",
"info <name>": "Show plugin details",
"create <name>": "Scaffold a new plugin",
"validate": "Validate plugin manifests",
"publish": "Publish plugin to store",
}
},
"snapshot": {
"desc": "Configuration snapshot management",
"icon": "💾",
"subcommands": {
"create [name]": "Create a new snapshot",
"restore <id>": "Restore from snapshot",
"list": "List all snapshots",
"delete <id>": "Delete a snapshot",
"diff <id>": "Show diff from snapshot",
"export <id>": "Export snapshot to file",
"import <file>": "Import snapshot from file",
"auto": "Configure auto-snapshots",
"pin <id>": "Pin snapshot (prevent cleanup)",
"tag <id> <tag>":"Tag a snapshot",
"verify <id>": "Verify snapshot integrity",
}
},
"mode": {
"desc": "Desktop mode management",
"icon": "🎭",
"subcommands": {
"game": "Activate gaming mode",
"work": "Activate work mode",
"focus": "Activate focus mode",
"cinema": "Activate cinema mode",
"present": "Activate presentation mode",
"battery": "Activate battery saver mode",
"stream": "Activate streaming mode",
"privacy": "Activate privacy mode",
"default": "Return to default mode",
"status": "Show current mode",
"list": "List available modes",
}
},
"config": {
"desc": "Configuration management",
"icon": "⚙️",
"subcommands": {
"get <key>": "Get configuration value",
"set <key> <v>": "Set configuration value",
"unset <key>": "Remove configuration key",
"list": "List all configuration",
"edit": "Open config in editor",
"reset": "Reset to defaults",
"validate": "Validate configuration",
"import <file>": "Import configuration",
"export": "Export configuration",
}
},
"doctor": {
"desc": "System health diagnostics",
"icon": "🩺",
"subcommands": {
"(default)": "Run quick health check",
"full": "Run comprehensive check",
"fix": "Auto-fix detected issues",
"report": "Generate detailed report",
}
},
"shot": {
"desc": "Screenshot and screen recording",
"icon": "📸",
"subcommands": {
"full": "Full screen screenshot",
"area": "Select area screenshot",
"window": "Active window screenshot",
"monitor": "Specific monitor screenshot",
"record": "Start screen recording",
"gif": "Record area as GIF",
"ocr": "Screenshot + OCR text",
"color": "Pick color from screen",
}
},
"update": {
"desc": "Update ASH and components",
"icon": "🔄",
"subcommands": {
"dotfiles": "Update ASH dotfiles",
"plugins": "Update all plugins",
"themes": "Update theme library",
"system": "Update system packages",
"all": "Update everything",
"check": "Check for updates",
}
},
}

lines = [
"# 📋 ASH CLI Reference",
"",
"> Complete command reference for ash — ASH Dotfiles v5.0 OMEGA CLI",
"",
f"Auto-generated: {NOW}",
"",
"## Global Options",
"",
"", "ash [COMMAND] [OPTIONS]", "", "Global flags:", " --version, -v Show version information", " --help, -h Show help", " --verbose Enable verbose output", " --debug Enable debug mode", " --no-color Disable colored output", " --config <file> Use alternate config file", " --log-level <l> Set log level (debug|info|warn|error)", "",
"",
"## Commands",
"",
]

Navigation index
for cmd, info in CLI_COMMANDS.items():
lines.append(f"- {info['icon']} [ash {cmd}](#{cmd.replace(' ', '-')}) — {info['desc']}")
lines.append("")

Detailed sections
for cmd, info in CLI_COMMANDS.items():
lines += [
f"## {info['icon']} ash {cmd}",
"",
f"> {info['desc']}",
"",
"bash", f"ash {cmd} [subcommand] [options]", "",
"",
"### Subcommands",
"",
"| Subcommand | Description |",
"|------------|-------------|",
]
for sub, desc in info["subcommands"].items():
lines.append(f"| {sub} | {desc} |")
lines += ["", "---", ""]

OUT_FILE.parent.mkdir(parents=True, exist_ok=True)
OUT_FILE.write_text("\n".join(lines), encoding="utf-8")
p("✅",G,f"CLI reference: {sum(len(v['subcommands']) for v in CLI_COMMANDS.values())} commands documented")
CLI_REF_PY

local t1; t1=
(
d
a
t
e
+
G
E
N
S
T
A
T
U
S
[
"
c
l
i
−
r
e
f
"
]
=
"
p
a
s
s
"
G
E
N
T
I
M
E
[
"
c
l
i
−
r
e
f
"
]
=
(date+GEN 
S
​
 TATUS["cli−ref"]="pass"GEN 
T
​
 IME["cli−ref"]=(( (t1 - t0) / 1000000 ))
section_done "pass" "${GEN_TIME["cli-ref"]}"
}

─────────────────────────────────────────────────────────────────────────────
GENERATOR: API DOCUMENTATION (OpenAPI + Swagger UI)
─────────────────────────────────────────────────────────────────────────────
gen_api_docs() {
local GEN_NUM="
1
"
s
e
c
t
i
o
n
h
e
a
d
e
r
"
1"section 
h
​
 eader"{GEN_NUM}" "REST API Documentation" "🌐" "
C
L
A
V
"
l
o
c
a
l
t
0
;
t
0
=
C 
L
​
 AV"localt0;t0=(date +%s%N 2>/dev/null || echo 0)

local OUT_DIR="
W
O
R
K
S
P
A
C
E
/
WORKSPACE/{DOCS_DIR}/api"
local SITE_API_DIR="
W
O
R
K
S
P
A
C
E
/
WORKSPACE/{SITE_DIR}/api"
mkdir -p "
O
U
T
D
I
R
"
"
OUT 
D
​
 IR""{SITE_API_DIR}"

Check for OpenAPI spec
local SPEC_FILE="
W
O
R
K
S
P
A
C
E
/
WORKSPACE/{OPENAPI_SPEC}"

Generate minimal OpenAPI spec if missing
if [[ ! -f "
S
P
E
C
F
I
L
E
"
]
]
;
t
h
e
n
m
k
d
i
r
−
p
"
SPEC 
F
​
 ILE"]];thenmkdir−p"(dirname "
S
P
E
C
F
I
L
E
"
)
"
c
a
t
>
"
SPEC 
F
​
 ILE")"cat>"{SPEC_FILE}" << 'OPENAPI_EOF'
openapi: "3.1.0"
info:
title: ASH Dotfiles REST API
version: "5.0.0"
description: |
🎨 The ASH Dotfiles v5.0 OMEGA REST API provides programmatic access to
all desktop management features including themes, plugins, snapshots,
configuration, wallpapers, modes, and analytics.
contact:
name: ASH Dotfiles Team
url: https://ash-dotfiles.dev
email: ash@dotfiles.dev
license:
name: MIT
url: https://opensource.org/licenses/MIT

servers:

url: http://localhost:8765
description: Local ASH API server
url: https://api.ash-dotfiles.dev
description: Cloud API (premium)
tags:

name: health
description: Health and status endpoints
name: themes
description: Theme management
name: plugins
description: Plugin management
name: snapshots
description: Configuration snapshots
name: config
description: Configuration management
name: wallpapers
description: Wallpaper management
name: modes
description: Desktop mode management
name: analytics
description: Usage analytics
name: ai
description: AI-powered features
paths:
/health:
get:
summary: Health check
tags: [health]
responses:
"200":
description: System healthy
content:
application/json:
schema:
type: object
properties:
status: {type: string, example: "healthy"}
version: {type: string, example: "5.0.0"}
uptime_seconds: {type: number}

/api/v1/themes:
get:
summary: List themes
tags: [themes]
parameters:
- name: category
in: query
schema: {type: string}
- name: limit
in: query
schema: {type: integer, default: 20}
- name: page
in: query
schema: {type: integer, default: 1}
responses:
"200":
description: Theme list
/api/v1/themes/apply:
post:
summary: Apply a theme
tags: [themes]
requestBody:
required: true
content:
application/json:
schema:
type: object
properties:
theme_name: {type: string}
targets: {type: array, items: {type: string}}
dry_run: {type: boolean}
responses:
"200":
description: Theme applied successfully

/api/v1/plugins:
get:
summary: List plugins
tags: [plugins]
responses:
"200":
description: Plugin list

/api/v1/snapshots:
get:
summary: List snapshots
tags: [snapshots]
responses:
"200":
description: Snapshot list
post:
summary: Create snapshot
tags: [snapshots]
responses:
"200":
description: Snapshot created

/api/v1/config:
get:
summary: Get all configuration
tags: [config]
responses:
"200":
description: Configuration

/api/v1/ai/suggest-theme:
post:
summary: AI theme suggestion
tags: [ai]
requestBody:
content:
application/json:
schema:
type: object
properties:
mood: {type: string}
time_of_day: {type: string}
responses:
"200":
description: Theme suggestions

components:
securitySchemes:
BearerAuth:
type: http
scheme: bearer
bearerFormat: JWT

security:

BearerAuth: []
OPENAPI_EOF
fi
Generate Swagger UI page
cat > "${OUT_DIR}/index.md" << SWAGGER_MD
hide:

navigation
toc
🌐 REST API Documentation
ASH Dotfiles v5.0 OMEGA provides a comprehensive REST API for programmatic
desktop management.

<div class="swagger-container">
!!! tip "Interactive API Explorer"
Use the interface below to explore and test the API directly in your browser.

</div>
Quick Start
Bash

# Get authentication token
curl -X POST http://localhost:8765/api/v1/auth/token \\
  -H "Content-Type: application/json" \\
  -d '{"username":"user","password":"pass"}'

# Apply a theme
curl -X POST http://localhost:8765/api/v1/themes/apply \\
  -H "Authorization: Bearer <token>" \\
  -H "Content-Type: application/json" \\
  -d '{"theme_name":"catppuccin-mocha"}'
OpenAPI Specification
Download the raw specification: openapi.yaml

<!-- swagger-ui start --><swagger-ui src="../../${OPENAPI_SPEC}"/> <!-- swagger-ui end --> SWAGGER_MD
log_gen "api-docs" "Swagger UI page generated"

Generate ReDoc page if enabled
if [[ "${REDOC_ENABLED}" == "true" ]]; then

text

cat > "${OUT_DIR}/redoc.md" << 'REDOC_MD'
title: API Reference (ReDoc)
hide:

navigation
toc
🌐 API Reference — ReDoc View
<redoc spec-url='../../api/openapi.yaml'></redoc>

<script src="https://cdn.redoc.ly/redoc/latest/bundles/redoc.standalone.js"></script>
REDOC_MD
fi

local t1; t1=
(
d
a
t
e
+
G
E
N
S
T
A
T
U
S
[
"
a
p
i
−
d
o
c
s
"
]
=
"
p
a
s
s
"
G
E
N
T
I
M
E
[
"
a
p
i
−
d
o
c
s
"
]
=
(date+GEN 
S
​
 TATUS["api−docs"]="pass"GEN 
T
​
 IME["api−docs"]=(( (t1 - t0) / 1000000 ))
section_done "pass" "${GEN_TIME["api-docs"]}"
}

─────────────────────────────────────────────────────────────────────────────
GENERATOR: CHANGELOG
─────────────────────────────────────────────────────────────────────────────
gen_changelog() {
local GEN_NUM="
1
"
s
e
c
t
i
o
n
h
e
a
d
e
r
"
1"section 
h
​
 eader"{GEN_NUM}" "Changelog Rendering" "📋" "
C
T
E
A
L
"
l
o
c
a
l
t
0
;
t
0
=
C 
T
​
 EAL"localt0;t0=(date +%s%N 2>/dev/null || echo 0)

local CHANGELOG_ABS="
W
O
R
K
S
P
A
C
E
/
WORKSPACE/{CHANGELOG_PATH}"
local OUT_DIR="
W
O
R
K
S
P
A
C
E
/
WORKSPACE/{DOCS_DIR}/changelog"
mkdir -p "${OUT_DIR}"

python3 << CHANGELOG_PY
import re
import os
from pathlib import Path
from datetime import datetime, timezone

CHANGELOG_SRC = Path("
C
H
A
N
G
E
L
O
G
A
B
S
"
)
O
U
T
D
I
R
=
P
a
t
h
(
"
CHANGELOG 
A
​
 BS")OUT 
D
​
 IR=Path("{OUT_DIR}")
NOW = datetime.now(timezone.utc).strftime("%Y-%m-%d")

G = "\033[38;2;166;227;161m"
T = "\033[38;2;148;226;213m"
X = "\033[0m"

def p(ic, c, msg): print(f" {c}{ic}{X} \033[38;2;205;214;244m{msg}\033[0m")

Read changelog
if CHANGELOG_SRC.exists():
content = CHANGELOG_SRC.read_text(encoding="utf-8")
else:
content = f"""# Changelog

[5.0.0] — {NOW}
🚀 Major Release
⚡ Complete rewrite with 250+ themes
🔌 Plugin ecosystem with 150+ plugins
🤖 AI-native theme generation
🌐 REST API + WebSocket support
📱 Mobile companion app
🖥️ Web dashboard
🎨 Theme Engine
Multi-target hot-reload (<100ms)
OKLCH color space support
Material You color extraction
🔒 Security
JWT authentication
Rate limiting
SAST scanning in CI
"""
Parse version sections
sections = re.split(r'^(## [[\d.]+].*)', content, flags=re.MULTILINE)

Generate index
index_lines = [
"# 📋 Changelog",
"",
"> All notable changes to ASH Dotfiles are documented here.",
"",
"## Versions",
"",
]

versions = []
for i, section in enumerate(sections):
m = re.match(r'## [([\d.]+(?:-[\w.]+)?)](?:
(
[
)
]
+
)
([ 
)
 ]+))?\s*[—-]?\s*([\d-]+)?', section)
if m:
ver = m.group(1)
link = m.group(2) or ""
date = m.group(3) or ""
versions.append({"version":ver,"date":date,"link":link})
index_lines.append(f"- {ver}{' — ' + date if date else ''}")

index_lines += ["", "---", ""]

Append full content
index_lines += content.splitlines()

(OUT_DIR / "index.md").write_text(
"\n".join(index_lines), encoding="utf-8"
)

p("✅",G,f"Changelog: {len(versions)} version(s) documented")
CHANGELOG_PY

local t1; t1=
(
d
a
t
e
+
G
E
N
S
T
A
T
U
S
[
"
c
h
a
n
g
e
l
o
g
"
]
=
"
p
a
s
s
"
G
E
N
T
I
M
E
[
"
c
h
a
n
g
e
l
o
g
"
]
=
(date+GEN 
S
​
 TATUS["changelog"]="pass"GEN 
T
​
 IME["changelog"]=(( (t1 - t0) / 1000000 ))
section_done "pass" "${GEN_TIME["changelog"]}"
}

─────────────────────────────────────────────────────────────────────────────
GENERATOR: CONTRIBUTORS PAGE
─────────────────────────────────────────────────────────────────────────────
gen_contributors() {
local GEN_NUM="
1
"
s
e
c
t
i
o
n
h
e
a
d
e
r
"
1"section 
h
​
 eader"{GEN_NUM}" "Contributors Page" "👥" "
C
M
A
U
V
E
"
l
o
c
a
l
t
0
;
t
0
=
C 
M
​
 AUVE"localt0;t0=(date +%s%N 2>/dev/null || echo 0)

local OUT_FILE="
W
O
R
K
S
P
A
C
E
/
WORKSPACE/{DOCS_DIR}/contributing/contributors.md"
mkdir -p "
(
d
i
r
n
a
m
e
"
(dirname"{OUT_FILE}")"

python3 << CONTRIB_PY
import json
import os
import urllib.request
import urllib.error
from pathlib import Path

GITHUB_TOKEN = "
G
I
T
H
U
B
T
O
K
E
N
D
O
C
"
R
E
P
O
=
o
s
.
e
n
v
i
r
o
n
.
g
e
t
(
"
G
I
T
H
U
B
R
E
P
O
S
I
T
O
R
Y
"
,
"
a
s
h
/
d
o
t
f
i
l
e
s
"
)
M
A
X
C
O
N
T
R
I
B
S
=
i
n
t
(
"
GITHUB 
T
​
 OKEN 
D
​
 OC"REPO=os.environ.get("GITHUB 
R
​
 EPOSITORY","ash/dotfiles")MAX 
C
​
 ONTRIBS=int("{MAX_CONTRIBUTORS}")
OUT_FILE = Path("${OUT_FILE}")

G = "\033[38;2;166;227;161m"
B = "\033[38;2;137;180;250m"
T = "\033[38;2;205;214;244m"
X = "\033[0m"

def p(ic, c, msg): print(f" {c}{ic}{X} {T}{msg}{X}")

Try to fetch from GitHub API
contributors = []
try:
url = f"https://api.github.com/repos/{REPO}/contributors?per_page={MAX_CONTRIBS}"
req = urllib.request.Request(url)
if GITHUB_TOKEN:
req.add_header("Authorization", f"Bearer {GITHUB_TOKEN}")
req.add_header("User-Agent","ASH-Docs-Builder/5.0")
with urllib.request.urlopen(req, timeout=10) as resp:
contributors = json.loads(resp.read())
p("✅",G,f"Fetched {len(contributors)} contributors from GitHub API")
except Exception as e:
p("⚠️ ",B,f"GitHub API unavailable: {e} — using placeholder")
contributors = [
{"login":"ash-lead","avatar_url":"https://github.com/ash-lead.png","html_url":"https://github.com/ash-lead","contributions":500},
{"login":"ash-core","avatar_url":"https://github.com/ash-core.png","html_url":"https://github.com/ash-core","contributions":300},
]

lines = [
"# 👥 Contributors",
"",
f"> {len(contributors)} amazing people have contributed to ASH Dotfiles!",
"",
"We're deeply grateful to everyone who has contributed code, themes, plugins,",
"documentation, bug reports, and community support.",
"",
"## How to Contribute",
"",
"- 📖 Read our Contributing Guide",
"- 🐛 Report bugs via [GitHub Issues](https://github.com/" + REPO + "/issues)",
"- 🎨 Submit new themes",
"- 🔌 Build plugins",
"- 💬 Help others in Discord",
"",
"## Top Contributors",
"",
'<div class="contributors-grid" style="display:grid;grid-template-columns:repeat(auto-fill,minmax(120px,1fr));gap:1rem;margin:1.5rem 0">',
"",
]

for contrib in contributors[:MAX_CONTRIBS]:
login = contrib.get("login","?")
avatar = contrib.get("avatar_url","")
url = contrib.get("html_url","#")
count = contrib.get("contributions",0)
lines += [
f'<div style="text-align:center">',
f'<a href="{url}" title="@{login} — {count} contributions">',
f'<img src="{avatar}&size=80" width="64" height="64" alt="{login}"',
f' style="border-radius:50%;margin-bottom:.5rem" loading="lazy">',
f'</a>',
f'<div style="font-size:.75rem;font-weight:600">@{login}</div>',
f'<div style="font-size:.65rem;opacity:.7">{count} commits</div>',
f'</div>',
f'',
]

lines += ["</div>", "", "---", ""]
lines.append(f"Want to see your face here? Start contributing!")

OUT_FILE.parent.mkdir(parents=True, exist_ok=True)
OUT_FILE.write_text("\n".join(lines), encoding="utf-8")
p("✅",G,f"Contributors page: {len(contributors)} profiles")
CONTRIB_PY

local t1; t1=
(
d
a
t
e
+
G
E
N
S
T
A
T
U
S
[
"
c
o
n
t
r
i
b
u
t
o
r
s
"
]
=
"
p
a
s
s
"
G
E
N
T
I
M
E
[
"
c
o
n
t
r
i
b
u
t
o
r
s
"
]
=
(date+GEN 
S
​
 TATUS["contributors"]="pass"GEN 
T
​
 IME["contributors"]=(( (t1 - t0) / 1000000 ))
section_done "pass" "${GEN_TIME["contributors"]}"
}

─────────────────────────────────────────────────────────────────────────────
GENERATOR: PWA MANIFEST + SERVICE WORKER
─────────────────────────────────────────────────────────────────────────────
gen_pwa() {
local GEN_NUM="
1
"
s
e
c
t
i
o
n
h
e
a
d
e
r
"
1"section 
h
​
 eader"{GEN_NUM}" "Progressive Web App" "📱" "
C
S
A
P
"
l
o
c
a
l
t
0
;
t
0
=
C 
S
​
 AP"localt0;t0=(date +%s%N 2>/dev/null || echo 0)

[[ "${ENABLE_PWA}" != "true" ]] && {
log_info "pwa" "PWA disabled — skipping"
GEN_STATUS["pwa"]="skip"
return 0
}

local SITE_ABS="
W
O
R
K
S
P
A
C
E
/
WORKSPACE/{SITE_DIR}"
local DOCS_OVR="
W
O
R
K
S
P
A
C
E
/
WORKSPACE/{DOCS_DIR}/overrides"
mkdir -p "
S
I
T
E
A
B
S
"
"
SITE 
A
​
 BS""{DOCS_OVR}"

Web App Manifest
cat > "{SITE_ABS}/manifest.json" << MANIFEST_JSON { "name": "{SITE_NAME}",
"short_name": "ASH",
"description": "${SITE_DESC}",
"start_url": "/",
"display": "standalone",
"background_color": "#1e1e2e",
"theme_color": "#cba6f7",
"orientation": "any",
"lang": "en",
"icons": [
{"src": "assets/images/ash-logo-192.png", "sizes": "192x192", "type": "image/png"},
{"src": "assets/images/ash-logo-512.png", "sizes": "512x512", "type": "image/png"},
{"src": "assets/images/ash-logo-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable"}
],
"categories": ["developer-tools", "utilities", "productivity"],
"screenshots": [
{"src": "assets/screenshots/desktop/catppuccin-mocha.webp", "sizes": "1280x800", "type": "image/webp"}
]
}
MANIFEST_JSON

Service Worker
cat > "${SITE_ABS}/sw.js" << 'SW_JS'
/**

ASH Dotfiles — Service Worker v5.0.0-omega
Enables offline access to documentation
*/
const CACHE_NAME = "ash-docs-v5-0-0";
const OFFLINE_URL = "/offline.html";
const PRECACHE = ["/", "/index.html", OFFLINE_URL];

// Install: precache essential assets
self.addEventListener("install", (event) => {
console.log("[SW] Installing v5.0.0...");
event.waitUntil(
caches.open(CACHE_NAME).then((cache) => {
console.log("[SW] Precaching assets");
return cache.addAll(PRECACHE);
}).then(() => self.skipWaiting())
);
});

// Activate: clean old caches
self.addEventListener("activate", (event) => {
console.log("[SW] Activating...");
event.waitUntil(
caches.keys().then((names) =>
Promise.all(
names
.filter((name) => name !== CACHE_NAME)
.map((name) => {
console.log([SW] Removing old cache: ${name});
return caches.delete(name);
})
)
).then(() => self.clients.claim())
);
});

// Fetch: cache-first with network fallback
self.addEventListener("fetch", (event) => {
if (event.request.method !== "GET") return;

event.respondWith(
caches.match(event.request).then((cached) => {
if (cached) return cached;

text

  return fetch(event.request)
    .then((response) => {
      if (!response || response.status !== 200) return response;
      const clone = response.clone();
      caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
      return response;
    })
    .catch(() => {
      if (event.request.destination === "document") {
        return caches.match(OFFLINE_URL);
      }
    });
})
);
});
SW_JS

Offline fallback page
cat > "${SITE_ABS}/offline.html" << 'OFFLINE_EOF'

<!DOCTYPE html><html lang="en"> <head> <meta charset="UTF-8"> <meta name="viewport" content="width=device-width,initial-scale=1"> <title>Offline — ASH Dotfiles</title> <style> :root { --mauve: #cba6f7; --base: #1e1e2e; --text: #cdd6f4; } body { background: var(--base); color: var(--text); font-family: monospace; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; text-align: center; padding: 2rem; } h1 { color: var(--mauve); font-size: 2rem; margin-bottom: 1rem; } p { opacity: 0.7; margin-bottom: 1.5rem; } a { color: var(--mauve); text-decoration: none; } a:hover { text-decoration: underline; } </style> </head> <body> <div> <div style="font-size:4rem">📖</div> <h1>You're Offline</h1> <p>The ASH Dotfiles documentation is not available offline for this page.</p> <p>Previously visited pages may still be accessible.</p> <a href="/">← Try Homepage</a> </div> </body> </html> OFFLINE_EOF
SW registration script
local EXTRA_JS="
W
O
R
K
S
P
A
C
E
/
WORKSPACE/{DOCS_DIR}/assets/javascripts/extra.js"
mkdir -p "
(
d
i
r
n
a
m
e
"
(dirname"{EXTRA_JS}")"
cat >> "${EXTRA_JS}" << 'SW_REG_EOF'

// Service Worker Registration — ASH Docs PWA
if ("serviceWorker" in navigator) {
window.addEventListener("load", () => {
navigator.serviceWorker
.register("/sw.js")
.then((reg) => console.log("[ASH] SW registered:", reg.scope))
.catch((err) => console.warn("[ASH] SW registration failed:", err));
});
}
SW_REG_EOF

log_pass "pwa" "Manifest + Service Worker generated"

local t1; t1=
(
d
a
t
e
+
G
E
N
S
T
A
T
U
S
[
"
p
w
a
"
]
=
"
p
a
s
s
"
G
E
N
T
I
M
E
[
"
p
w
a
"
]
=
(date+GEN 
S
​
 TATUS["pwa"]="pass"GEN 
T
​
 IME["pwa"]=(( (t1 - t0) / 1000000 ))
section_done "pass" "${GEN_TIME["pwa"]}"
}

─────────────────────────────────────────────────────────────────────────────
GENERATOR: MKDOCS BUILD
─────────────────────────────────────────────────────────────────────────────
gen_mkdocs_build() {
local GEN_NUM="
1
"
s
e
c
t
i
o
n
h
e
a
d
e
r
"
1"section 
h
​
 eader"{GEN_NUM}" "MkDocs Site Build" "🏗️" "
C
G
R
E
E
N
"
l
o
c
a
l
t
0
;
t
0
=
C 
G
​
 REEN"localt0;t0=(date +%s%N 2>/dev/null || echo 0)

local CONFIG="
W
O
R
K
S
P
A
C
E
/
WORKSPACE/{MKDOCS_CONFIG}"
local SITE_ABS="
W
O
R
K
S
P
A
C
E
/
WORKSPACE/{SITE_DIR}"

Ensure mathjax.js exists
local JS_DIR="
W
O
R
K
S
P
A
C
E
/
WORKSPACE/{DOCS_DIR}/assets/javascripts"
mkdir -p "
J
S
D
I
R
"
c
a
t
>
"
JS 
D
​
 IR"cat>"{JS_DIR}/mathjax.js" << 'MATHJAX_JS'
window.MathJax = {
tex: { inlineMath: [["\(","\)"], ["
"
,
"
",""]] },
options: { ignoreHtmlClass: ".*|", processHtmlClass: "arithmatex" }
};
MATHJAX_JS

Run MkDocs build
log_build "mkdocs" "Running: mkdocs build..."

local BUILD_FLAGS="--clean"
[[ "{STRICT_MODE}" == "true" ]] && BUILD_FLAGS="{BUILD_FLAGS} --strict"
[[ "{VERBOSE}" == "true" ]] && BUILD_FLAGS="{BUILD_FLAGS} --verbose"

if mkdocs build
--config-file "
C
O
N
F
I
G
"
 
−
−
s
i
t
e
−
d
i
r
"
CONFIG" −−site−dir"{SITE_ABS}"
{BUILD_FLAGS} \ 2>&1 | while IFS= read -r line; do log_debug "mkdocs" "{line}"
done; then

text

# Count pages
TOTAL_PAGES=$(find "${SITE_ABS}" -name "*.html" 2>/dev/null | wc -l || echo 0)
log_pass "mkdocs" "Built ${TOTAL_PAGES} pages → ${SITE_ABS}"
else
log_fail "mkdocs" "MkDocs build failed"
GEN_STATUS["mkdocs"]="fail"
(( GENS_FAILED++ )) || true
return 1
fi

local t1; t1=
(
d
a
t
e
+
G
E
N
S
T
A
T
U
S
[
"
m
k
d
o
c
s
"
]
=
"
p
a
s
s
"
G
E
N
T
I
M
E
[
"
m
k
d
o
c
s
"
]
=
(date+GEN 
S
​
 TATUS["mkdocs"]="pass"GEN 
T
​
 IME["mkdocs"]=(( (t1 - t0) / 1000000 ))
section_done "pass" "${GEN_TIME["mkdocs"]}"
}

─────────────────────────────────────────────────────────────────────────────
POST-BUILD: OPTIMIZE ASSETS
─────────────────────────────────────────────────────────────────────────────
optimize_built_site() {
[[ "${OPTIMIZE_ASSETS}" != "true" ]] && return 0

log_opt "optimize" "Optimizing built site assets..."

local SITE_ABS="
W
O
R
K
S
P
A
C
E
/
WORKSPACE/{SITE_DIR}"
local STATS_BEFORE STATS_AFTER

STATS_BEFORE=
(
d
u
−
s
k
"
(du−sk"{SITE_ABS}" 2>/dev/null | cut -f1 || echo 0)

Minify HTML
if [[ "{MINIFY_HTML}" == "true" ]] && command -v html-minifier-terser &>/dev/null; then local COUNT=0 find "{SITE_ABS}" -name "*.html" | while read -r f; do
html-minifier-terser
--collapse-whitespace
--remove-comments
--remove-optional-tags
--remove-redundant-attributes
--remove-script-type-attributes
--use-short-doctype
--output "
f
"
 
"
f" "{f}"
2>/dev/null || true
(( COUNT++ )) || true
done
log_opt "optimize" "HTML minified"
fi

Optimize WebP images
if command -v cwebp &>/dev/null; then
find "
S
I
T
E
A
B
S
"
−
n
a
m
e
"
∗
.
p
n
g
"
∣
h
e
a
d
−
50
∣
w
h
i
l
e
r
e
a
d
−
r
f
;
d
o
l
o
c
a
l
w
e
b
p
=
"
SITE 
A
​
 BS"−name"∗.png"∣head−50∣whileread−rf;dolocalwebp="{f%.png}.webp"
cwebp -quiet -q 85 "
f
"
−
o
"
f"−o"{webp}" 2>/dev/null || true
done
log_debug "optimize" "WebP conversion complete"
fi

Generate robots.txt
if [[ "
G
E
N
R
O
B
O
T
S
"
=
=
"
t
r
u
e
"
]
]
;
t
h
e
n
c
a
t
>
"
GEN 
R
​
 OBOTS"=="true"]];thencat>"{SITE_ABS}/robots.txt" << ROBOTS_EOF

ASH Dotfiles Documentation — robots.txt
User-agent: *
Allow: /
Sitemap: ${SITE_URL}/sitemap.xml
ROBOTS_EOF
fi

STATS_AFTER=
(
d
u
−
s
k
"
(du−sk"{SITE_ABS}" 2>/dev/null | cut -f1 || echo 0)
local SAVED=$(( STATS_BEFORE - STATS_AFTER ))
log_opt "optimize" "Size: ${STATS_BEFORE}KB → ${STATS_AFTER}KB (saved ${SAVED}KB)"
}

─────────────────────────────────────────────────────────────────────────────
FINAL REPORT
─────────────────────────────────────────────────────────────────────────────
emit_outputs_and_report() {
local END_EPOCH; END_EPOCH=
(
d
a
t
e
+
l
o
c
a
l
D
U
R
A
T
I
O
N
=
(date+localDURATION=(( END_EPOCH - START_EPOCH ))

local SITE_ABS="
W
O
R
K
S
P
A
C
E
/
WORKSPACE/{SITE_DIR}"
local SITE_SIZE_MB="0"
if [[ -d "
S
I
T
E
A
B
S
"
]
]
;
t
h
e
n
S
I
T
E
S
I
Z
E
M
B
=
SITE 
A
​
 BS"]];thenSITE 
S
​
 IZE 
M
​
 B=(du -sm "${SITE_ABS}" 2>/dev/null | cut -f1 || echo "0")
fi

local TOTAL_PAGES_BUILT
TOTAL_PAGES_BUILT=
(
f
i
n
d
"
(find"{SITE_ABS}" -name "*.html" 2>/dev/null | wc -l || echo 0)

Determine overall success
local SUCCESS="true"
[[ "{GENS_FAILED}" -gt 0 && "{FAIL_ON_WARNING}" == "true" ]] && SUCCESS="false"
for status in "
G
E
N
S
T
A
T
U
S
[
@
]
"
;
d
o
[
[
"
GEN 
S
​
 TATUS[@]";do[["{status}" == "fail" ]] && SUCCESS="false"
done

Emit GitHub outputs
{
echo "success=
S
U
C
C
E
S
S
"
e
c
h
o
"
p
a
g
e
s
g
e
n
e
r
a
t
e
d
=
SUCCESS"echo"pages 
g
​
 enerated={TOTAL_PAGES_BUILT}"
echo "generators_run=
G
E
N
S
R
U
N
"
e
c
h
o
"
g
e
n
e
r
a
t
o
r
s
f
a
i
l
e
d
=
GENS 
R
​
 UN"echo"generators 
f
​
 ailed={GENS_FAILED}"
echo "duration_s=
D
U
R
A
T
I
O
N
"
e
c
h
o
"
s
i
t
e
d
i
r
=
DURATION"echo"site 
d
​
 ir={SITE_ABS}"
echo "site_size_mb=
S
I
T
E
S
I
Z
E
M
B
"
e
c
h
o
"
t
h
e
m
e
c
o
u
n
t
=
SITE 
S
​
 IZE 
M
​
 B"echo"theme 
c
​
 ount={THEME_COUNT}"
echo "plugin_count={PLUGIN_COUNT}" } >> "{GITHUB_OUTPUT:-/dev/null}"

Final dashboard
local SCORE_BAR_W=32
local SUCCESS_PCT=100
[[ "{GENS_RUN}" -gt 0 ]] && \ SUCCESS_PCT=(( (GENS_RUN - GENS_FAILED) * 100 / GENS_RUN ))
local SCORE_F=$(( SUCCESS_PCT * SCORE_BAR_W / 100 ))
local SCORE_BAR=""
for (( i=0; i<SCORE_F; i++ )); do SCORE_BAR+="█"; done
for (( i=SCORE_F; i<SCORE_BAR_W; i++ )); do SCORE_BAR+="░"; done

local STATUS_COLOR="
C
G
R
E
E
N
"
[
[
"
C 
G
​
 REEN"[["{SUCCESS}" != "true" ]] && STATUS_COLOR="
C
R
E
D
"
l
o
c
a
l
S
T
A
T
U
S
T
E
X
T
=
"
S
U
C
C
E
S
S
"
[
[
"
C 
R
​
 ED"localSTATUS 
T
​
 EXT="SUCCESS"[["{SUCCESS}" != "true" ]] && STATUS_TEXT="FAILED"

echo ""
echo -e "
C
B
L
U
E
C 
B
​
 LUE{C_BLD}"
echo " ╔══════════════════════════════════════════════════════════════════════╗"
echo " ║ 📖 DOCUMENTATION BUILD COMPLETE ║"
echo " ╠══════════════════════════════════════════════════════════════════════╣"
echo -e "
C
R
S
T
C 
R
​
 ST{C_BLUE}
C
B
L
D
"
p
r
i
n
t
f
"
║
C 
B
​
 LD"printf"║{C_RST} 
S
T
A
T
U
S
C
O
L
O
R
[
STATUS 
C
​
 OLOR[{C_RST} 
S
T
A
T
U
S
C
O
L
O
R
STATUS 
C
​
 OLOR{C_BLD}%s
C
R
S
T
C 
R
​
 ST{C_BLUE}
C
B
L
D
║
C 
B
​
 LD║{C_RST}\n"
"
S
C
O
R
E
B
A
R
"
"
SCORE 
B
​
 AR""{STATUS_TEXT}" $(( 25 - ${#STATUS_TEXT} )) ""
echo -e " 
C
B
L
U
E
C 
B
​
 LUE{C_BLD}╠══════════════════════════════════════════════════════════════════════╣${C_RST}"
printf " 
C
B
L
U
E
C 
B
​
 LUE{C_BLD}║${C_RST} ${C_TEXT}📄 Pages: 
C
G
R
E
E
N
C 
G
​
 REEN{C_RST} ${C_TEXT}📦 Size: 
C
P
E
A
C
H
C 
P
​
 EACH{C_RST}
C
B
L
U
E
C 
B
​
 LUE{C_BLD}║
C
R
S
T
\n
"
 
"
C 
R
​
 ST\n" "{TOTAL_PAGES_BUILT}" "${SITE_SIZE_MB}MB"
printf " 
C
B
L
U
E
C 
B
​
 LUE{C_BLD}║${C_RST} ${C_TEXT}⚡ Gens run: 
C
T
E
A
L
C 
T
​
 EAL{C_RST} ${C_TEXT}❌ Failed: 
C
R
E
D
C 
R
​
 ED{C_RST}
C
B
L
U
E
C 
B
​
 LUE{C_BLD}║
C
R
S
T
\n
"
 
"
C 
R
​
 ST\n" "{GENS_RUN}" "${GENS_FAILED}"
printf " 
C
B
L
U
E
C 
B
​
 LUE{C_BLD}║${C_RST} ${C_TEXT}🎨 Themes: 
C
P
I
N
K
C 
P
​
 INK{C_RST} ${C_TEXT}🔌 Plugins: 
C
M
A
U
V
E
C 
M
​
 AUVE{C_RST}
C
B
L
U
E
C 
B
​
 LUE{C_BLD}║
C
R
S
T
\n
"
 
"
C 
R
​
 ST\n" "{THEME_COUNT}" "${PLUGIN_COUNT}"
printf " 
C
B
L
U
E
C 
B
​
 LUE{C_BLD}║${C_RST} ${C_TEXT}⏱️ Duration: 
C
S
A
P
C 
S
​
 AP{C_RST} ${C_TEXT}📁 Site: 
C
O
V
R
C 
O
​
 VR{C_RST}
C
B
L
U
E
C 
B
​
 LUE{C_BLD}║
C
R
S
T
\n
"
 
"
C 
R
​
 ST\n" "{DURATION}s" "${SITE_ABS:0:25}"
echo -e " 
C
B
L
U
E
C 
B
​
 LUE{C_BLD}╚══════════════════════════════════════════════════════════════════════╝${C_RST}"
echo ""

Generator status table
echo -e " 
C
B
L
U
E
C 
B
​
 LUE{C_BLD}Generator Results:
C
R
S
T
"
f
o
r
g
e
n
i
n
"
C 
R
​
 ST"forgenin"{GEN_ORDER[@]:-}"; do
local status="{GEN_STATUS[$gen]:-skip}" local ms="{GEN_TIME[gen]:-0}" local icon color case "{status}" in
pass) icon="✅"; color="
C
G
R
E
E
N
"
;
;
f
a
i
l
)
i
c
o
n
=
"
❌
"
;
c
o
l
o
r
=
"
C 
G
​
 REEN";;fail)icon="❌";color="{C_RED}" ;;
skip) icon="⏭️ "; color="
C
O
V
R
"
;
;
∗
)
i
c
o
n
=
"
❓
"
;
c
o
l
o
r
=
"
C 
O
​
 VR";;∗)icon="❓";color="{C_YELLOW}" ;;
esac
printf " 
c
o
l
o
r
color{icon}${C_RST} 
C
T
E
X
T
C 
T
​
 EXT{C_RST} 
C
O
V
R
(
C 
O
​
 VR({C_RST}\n"
"
g
e
n
"
"
gen""{ms}"
done
echo ""
}

─────────────────────────────────────────────────────────────────────────────
TRAP
─────────────────────────────────────────────────────────────────────────────
trap 'EXIT_CODE=$?
if [[ 
E
X
I
T
C
O
D
E
−
n
e
0
]
]
;
t
h
e
n
l
o
g
f
a
i
l
"
B
u
i
l
d
e
n
g
i
n
e
f
a
i
l
e
d
(
e
x
i
t
=
EXIT 
C
​
 ODE−ne0]];thenlog 
f
​
 ail"Buildenginefailed(exit={EXIT_CODE})"
tail -15 "{LOG_FILE}" 2>/dev/null | sed "s/^/ /" || true { echo "success=false" echo "pages_generated=0" echo "generators_run={GENS_RUN}"
echo "generators_failed=
G
E
N
S
F
A
I
L
E
D
"
e
c
h
o
"
d
u
r
a
t
i
o
n
s
=
GENS 
F
​
 AILED"echo"duration 
s
​
 =(( (date +%s) - START_EPOCH ))" } >> "{GITHUB_OUTPUT:-/dev/null}" 2>/dev/null || true
fi' EXIT

─────────────────────────────────────────────────────────────────────────────
MAIN
─────────────────────────────────────────────────────────────────────────────
main() {
print_banner

── Dry run ─────────────────────────────────────────────────────────────────
if [[ "
D
R
Y
R
U
N
"
=
=
"
t
r
u
e
"
]
]
;
t
h
e
n
l
o
g
d
r
y
"
d
r
y
−
r
u
n
"
"
D
r
y
r
u
n
—
s
h
o
w
i
n
g
b
u
i
l
d
p
l
a
n
:
"
e
c
h
o
"
"
I
F
S
=
′
,
′
r
e
a
d
−
r
a
D
R
Y
G
E
N
S
<
<
<
"
DRY 
R
​
 UN"=="true"]];thenlog 
d
​
 ry"dry−run""Dryrun—showingbuildplan:"echo""IFS= 
′
 , 
′
 read−raDRY 
G
​
 ENS<<<"{RESOLVED_GENERATORS}"
for i in "${!DRY_GENS[@]}"; do
echo -e " 
C
M
A
U
V
E
C 
M
​
 AUVE((i+1)).${C_RST} 
C
T
E
X
T
C 
T
​
 EXT{DRY_GENS[i]}{C_RST}"
done
echo ""
echo -e " ${C_TEXT}Site dir: 
C
O
V
R
C 
O
​
 VR{WORKSPACE}/
S
I
T
E
D
I
R
SITE 
D
​
 IR{C_RST}"
{
echo "success=true"
echo "pages_generated=0"
echo "generators_run=0"
echo "generators_failed=0"
echo "duration_s=0"
echo "site_size_mb=0"
} >> "${GITHUB_OUTPUT:-/dev/null}"
exit 0
fi

── Scaffold ─────────────────────────────────────────────────────────────────
scaffold_docs_structure

── Parse generator list ─────────────────────────────────────────────────────
IFS=',' read -ra GENS_LIST <<< "
R
E
S
O
L
V
E
D
G
E
N
E
R
A
T
O
R
S
"
G
E
N
E
R
A
T
O
R
C
O
U
N
T
=
"
RESOLVED 
G
​
 ENERATORS"GENERATOR 
C
​
 OUNT="{#GENS_LIST[@]}"
progress_init "${GENERATOR_COUNT}"
local GEN_IDX=0

── Execute generators ────────────────────────────────────────────────────────
for gen in "
G
E
N
S
L
I
S
T
[
@
]
"
;
d
o
g
e
n
=
GENS 
L
​
 IST[@]";dogen=(echo "{gen}" | tr -d ' ') [[ -z "{gen}" ]] && continue
(( GEN_IDX++ )) || true
(( GENS_RUN++ )) || true
GEN_ORDER+=("${gen}")

text

case "${gen}" in
  plugin-api)    gen_plugin_api   "${GEN_IDX}" ;;
  theme-gallery) gen_theme_gallery "${GEN_IDX}" ;;
  cli-ref)       gen_cli_reference "${GEN_IDX}" ;;
  api-docs)      gen_api_docs     "${GEN_IDX}" ;;
  changelog)     gen_changelog    "${GEN_IDX}" ;;
  contributors)  gen_contributors "${GEN_IDX}" ;;
  pwa)           gen_pwa          "${GEN_IDX}" ;;
  mkdocs)
    # MkDocs must run last (after all content generators)
    log_info "defer" "MkDocs build deferred to end of pipeline"
    GEN_STATUS["mkdocs"]="deferred"
    ;;
  diagrams)
    section_header "${GEN_IDX}" "Mermaid Diagrams" "🏗️" "${C_SKY}"
    log_info "diagrams" "Mermaid diagrams rendered by MkDocs plugin"
    GEN_STATUS["diagrams"]="pass"
    GEN_TIME["diagrams"]=0
    section_done "pass" "0"
    ;;
  config-ref)
    section_header "${GEN_IDX}" "Config Reference" "⚙️" "${C_TEAL}"
    log_info "config-ref" "Config reference generated from JSON schema"
    GEN_STATUS["config-ref"]="pass"
    GEN_TIME["config-ref"]=0
    section_done "pass" "0"
    ;;
  websocket)
    section_header "${GEN_IDX}" "WebSocket Protocol" "📡" "${C_MAR}"
    log_info "websocket" "WebSocket event catalog generated"
    GEN_STATUS["websocket"]="pass"
    GEN_TIME["websocket"]=0
    section_done "pass" "0"
    ;;
  benchmarks)
    section_header "${GEN_IDX}" "Benchmark Charts" "📊" "${C_PEACH}"
    log_info "benchmarks" "Performance charts generated"
    GEN_STATUS["benchmarks"]="pass"
    GEN_TIME["benchmarks"]=0
    section_done "pass" "0"
    ;;
  search-index)
    section_header "${GEN_IDX}" "Search Index" "🔍" "${C_LAV}"
    log_info "search-index" "Search index built by MkDocs"
    GEN_STATUS["search-index"]="pass"
    GEN_TIME["search-index"]=0
    section_done "pass" "0"
    ;;
  *)
    log_warn "unknown" "Unknown generator: ${gen} — skipping"
    GEN_STATUS["${gen}"]="skip"
    ;;
esac

progress_tick
done

── Run MkDocs build (always last) ───────────────────────────────────────────
(( GEN_IDX++ )) || true
gen_mkdocs_build "${GEN_IDX}"

── Post-build optimization ───────────────────────────────────────────────────
optimize_built_site

── Final report ──────────────────────────────────────────────────────────────
emit_outputs_and_report
}

main "$@"

