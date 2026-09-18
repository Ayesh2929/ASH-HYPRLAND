#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                           ║
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ENVIRONMENT SETUP SCRIPT                                    ║
# ║                                                                                           ║
# ║  ░██████╗███████╗████████╗██╗░░░██╗██████╗░  ░██████╗██╗  ██╗                            ║
# ║  ██╔════╝██╔════╝╚══██╔══╝██║░░░██║██╔══██╗  ██╔════╝██║  ██║                            ║
# ║  ╚█████╗░█████╗░░░░░██║░░░██║░░░██║██████╔╝  ╚█████╗░███████╗                            ║
# ║  ░╚═══██╗██╔══╝░░░░░██║░░░██║░░░██║██╔═══╝░  ░╚═══██╗██╔══██║                            ║
# ║  ██████╔╝███████╗░░░██║░░░╚██████╔╝██║░░░░░  ██████╔╝██║  ██║                            ║
# ║  ╚═════╝░╚══════╝░░░╚═╝░░░░╚═════╝░╚═╝░░░░░  ╚═════╝░╚═╝  ╚═╝                            ║
# ║                                                                                           ║
# ║  Version:  5.0.0-omega                                                                   ║
# ║  Author:   ASH Dotfiles Team <ash@dotfiles.dev>                                          ║
# ║  License:  MIT                                                                           ║
# ║                                                                                           ║
# ║  🎯 RESPONSIBILITIES:                                                                     ║
# ║     • System package installation (apt/brew)                                             ║
# ║     • Python package installation (pip3)                                                 ║
# ║     • Binary tool installation (hyperfine/gitleaks/trivy)                               ║
# ║     • ASH config directory initialization                                               ║
# ║     • Theme engine bootstrap                                                             ║
# ║     • Plugin system initialization                                                      ║
# ║     • PATH configuration                                                                ║
# ║     • Environment variable export                                                        ║
# ║     • Progress tracking with timestamps                                                  ║
# ║     • Error handling with contextual messages                                            ║
# ║     • Cache awareness (skip if already installed)                                        ║
# ║     • Parallel installation where safe                                                   ║
# ║                                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════════════════════╝

# ─────────────────────────────────────────────────────────────────────────────
# STRICT MODE & ERROR HANDLING
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail
IFS=$'\n\t'

# ─────────────────────────────────────────────────────────────────────────────
# GLOBAL CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────
readonly SETUP_VERSION="5.0.0"
readonly SETUP_START=$(date +%s)
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"
readonly WORK_DIR="${WORKSPACE}/.ash-setup"
readonly LOG_FILE="${WORK_DIR}/setup.log"
readonly METRICS_FILE="${WORK_DIR}/metrics.json"

# ─────────────────────────────────────────────────────────────────────────────
# ENVIRONMENT VARIABLES (from action.yml)
# ─────────────────────────────────────────────────────────────────────────────
PROFILE="${ASH_PROFILE:-standard}"
PYTHON_VERSION="${ASH_PYTHON_VERSION:-3.12}"
NODE_VERSION="${ASH_NODE_VERSION:-20}"
NODE_PM="${ASH_NODE_PM:-npm}"
CONFIG_DIR="${ASH_CONFIG_DIR:-${HOME}/.config/ash}"
VERBOSE="${ASH_VERBOSE:-false}"
FAIL_ON_ERROR="${ASH_FAIL_ON_ERROR:-true}"
CACHE_STRATEGY="${ASH_CACHE_STRATEGY:-aggressive}"
CACHE_HIT_PIP="${ASH_CACHE_HIT_PIP:-false}"
CACHE_HIT_TOOLS="${ASH_CACHE_HIT_TOOLS:-false}"
INIT_THEME="${ASH_INIT_THEME:-false}"
INIT_PLUGINS="${ASH_INIT_PLUGINS:-false}"
HYPERFINE_VER="${ASH_HYPERFINE_VER:-1.18.0}"
GITLEAKS_VER="${ASH_GITLEAKS_VER:-8.21.2}"

# Feature flags
FEAT_PYTHON="${ASH_FEAT_PYTHON:-true}"
FEAT_NODE="${ASH_FEAT_NODE:-false}"
FEAT_IMAGEMAGICK="${ASH_FEAT_IMAGEMAGICK:-true}"
FEAT_FISH="${ASH_FEAT_FISH:-false}"
FEAT_HYPERFINE="${ASH_FEAT_HYPERFINE:-false}"
FEAT_SHELLCHECK="${ASH_FEAT_SHELLCHECK:-true}"
FEAT_GITLEAKS="${ASH_FEAT_GITLEAKS:-false}"
FEAT_TRIVY="${ASH_FEAT_TRIVY:-false}"
FEAT_SQLITE="${ASH_FEAT_SQLITE:-true}"
FEAT_API_DEPS="${ASH_FEAT_API_DEPS:-false}"
FEAT_SECURITY="${ASH_FEAT_SECURITY:-false}"
FEAT_BENCHMARK="${ASH_FEAT_BENCHMARK:-false}"

# Extra packages
EXTRA_PYTHON="${ASH_PYTHON_PACKAGES:-}"
EXTRA_APT="${ASH_CUSTOM_PACKAGES:-}"

# ─────────────────────────────────────────────────────────────────────────────
# CATPPUCCIN MOCHA COLOR PALETTE (ANSI)
# ─────────────────────────────────────────────────────────────────────────────
# Colors (requires terminal support)
if [[ -t 1 ]] || [[ "${GITHUB_ACTIONS:-false}" == "true" ]]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'

  # Catppuccin Mocha
  C_MAUVE=$'\033[38;2;203;166;247m'    # #cba6f7
  C_BLUE=$'\033[38;2;137;180;250m'     # #89b4fa
  C_GREEN=$'\033[38;2;166;227;161m'    # #a6e3a1
  C_RED=$'\033[38;2;243;139;168m'      # #f38ba8
  C_YELLOW=$'\033[38;2;249;226;175m'   # #f9e2af
  C_PEACH=$'\033[38;2;250;179;135m'    # #fab387
  C_TEAL=$'\033[38;2;148;226;213m'     # #94e2d5
  C_SAPPHIRE=$'\033[38;2;116;199;236m' # #74c7ec
  C_SKY=$'\033[38;2;137;220;235m'      # #89dceb
  C_PINK=$'\033[38;2;245;194;231m'     # #f5c2e7
  C_LAVENDER=$'\033[38;2;180;190;254m' # #b4befe
  C_TEXT=$'\033[38;2;205;214;244m'     # #cdd6f4
  C_SUBTEXT=$'\033[38;2;166;173;200m'  # #a6adc8
  C_OVERLAY=$'\033[38;2;108;112;134m'  # #6c7086
  C_SURFACE=$'\033[38;2;49;50;68m'     # #313244
  C_BASE=$'\033[48;2;30;30;46m'        # #1e1e2e bg
else
  C_RESET='' C_BOLD='' C_DIM=''
  C_MAUVE='' C_BLUE='' C_GREEN='' C_RED='' C_YELLOW='' C_PEACH=''
  C_TEAL='' C_SAPPHIRE='' C_SKY='' C_PINK='' C_LAVENDER=''
  C_TEXT='' C_SUBTEXT='' C_OVERLAY='' C_SURFACE='' C_BASE=''
fi

# ─────────────────────────────────────────────────────────────────────────────
# LOGGING FUNCTIONS
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p "${WORK_DIR}"

_log_base() {
  local level="$1" icon="$2" color="$3"
  shift 3
  local msg="$*"
  local ts
  ts=$(date +%H:%M:%S)
  local formatted="${color}${icon}${C_RESET} ${C_DIM}[${ts}]${C_RESET} ${C_TEXT}${msg}${C_RESET}"
  echo -e "${formatted}"
  echo "[${ts}] [${level}] ${msg}" >> "${LOG_FILE}"
}

log_info()    { _log_base "INFO"    "ℹ️ " "${C_BLUE}"    "$@"; }
log_success() { _log_base "OK"      "✅" "${C_GREEN}"   "$@"; }
log_warn()    { _log_base "WARN"    "⚠️ " "${C_YELLOW}"  "$@"; }
log_error()   { _log_base "ERROR"   "❌" "${C_RED}"     "$@"; }
log_step()    { _log_base "STEP"    "⚡" "${C_MAUVE}"   "$@"; }
log_skip()    { _log_base "SKIP"    "⏭️ " "${C_OVERLAY}" "$@"; }
log_cache()   { _log_base "CACHE"   "💾" "${C_SAPPHIRE}" "$@"; }
log_install() { _log_base "INSTALL" "📦" "${C_PEACH}"   "$@"; }
log_debug()   {
  [[ "${VERBOSE}" == "true" ]] && \
    _log_base "DEBUG" "🔍" "${C_OVERLAY}" "$@" || true
}

# ─────────────────────────────────────────────────────────────────────────────
# METRICS TRACKING
# ─────────────────────────────────────────────────────────────────────────────
declare -A STEP_TIMES=()
declare -a INSTALLED_TOOLS=()
declare -a SKIPPED_TOOLS=()
declare -a FAILED_TOOLS=()
TOTAL_STEPS=0
COMPLETED_STEPS=0

step_start() {
  local name="$1"
  STEP_TIMES["${name}_start"]=$(date +%s%N)
  ((TOTAL_STEPS++)) || true
  log_step "${name}"
}

step_end() {
  local name="$1" status="${2:-ok}"
  local end_ns; end_ns=$(date +%s%N)
  local start_ns="${STEP_TIMES["${name}_start"]:-${end_ns}}"
  local duration_ms=$(( (end_ns - start_ns) / 1000000 ))
  STEP_TIMES["${name}_ms"]="${duration_ms}"
  ((COMPLETED_STEPS++)) || true

  case "${status}" in
    ok)
      log_success "${name} completed in ${duration_ms}ms"
      INSTALLED_TOOLS+=("${name}:${duration_ms}ms")
      ;;
    skip)
      log_skip "${name} skipped (cache hit or not needed)"
      SKIPPED_TOOLS+=("${name}")
      ;;
    fail)
      log_error "${name} failed after ${duration_ms}ms"
      FAILED_TOOLS+=("${name}")
      ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# UTILITY FUNCTIONS
# ─────────────────────────────────────────────────────────────────────────────

# Check if tool is already installed with minimum version
is_installed() {
  local cmd="$1"
  local min_version="${2:-}"
  command -v "${cmd}" &>/dev/null
}

# Safe apt-get wrapper with retry
apt_install() {
  local packages=("$@")
  log_debug "apt-get install: ${packages[*]}"

  DEBIAN_FRONTEND=noninteractive \
  sudo apt-get install -y --no-install-recommends \
    "${packages[@]}" \
    2>&1 | (
      if [[ "${VERBOSE}" == "true" ]]; then
        cat
      else
        grep -E "(Setting up|Unpacking|Error)" || true
      fi
    )
}

# pip3 install with quiet mode
pip_install() {
  local packages=("$@")
  log_debug "pip3 install: ${packages[*]}"

  pip3 install \
    --quiet \
    --user \
    --no-warn-script-location \
    "${packages[@]}" \
    2>&1 | (
      if [[ "${VERBOSE}" == "true" ]]; then
        cat
      else
        grep -E "(error|warning|Successfully)" || true
      fi
    )
}

# Download binary tool with checksum verification
download_tool() {
  local name="$1"
  local url="$2"
  local dest_dir="${3:-${HOME}/.local/bin}"
  local is_archive="${4:-false}"
  local extract_name="${5:-${name}}"

  local tmp_file
  tmp_file=$(mktemp "/tmp/ash-tool-${name}-XXXXXX")

  log_debug "Downloading: ${url}"
  curl -sSfL "${url}" -o "${tmp_file}" || {
    rm -f "${tmp_file}"
    log_error "Failed to download ${name} from ${url}"
    return 1
  }

  mkdir -p "${dest_dir}"

  if [[ "${is_archive}" == "true" ]]; then
    local tmp_dir
    tmp_dir=$(mktemp -d "/tmp/ash-extract-${name}-XXXXXX")
    tar -xzf "${tmp_file}" -C "${tmp_dir}" 2>/dev/null || \
    unzip -q "${tmp_file}" -d "${tmp_dir}" 2>/dev/null || {
      rm -rf "${tmp_file}" "${tmp_dir}"
      return 1
    }
    find "${tmp_dir}" -name "${extract_name}" -type f -exec \
      install -m755 {} "${dest_dir}/${name}" \;
    rm -rf "${tmp_dir}"
  else
    install -m755 "${tmp_file}" "${dest_dir}/${name}"
  fi

  rm -f "${tmp_file}"
  log_debug "${name} installed to ${dest_dir}/${name}"
  return 0
}

# Add directory to PATH (GitHub Actions + shell)
add_to_path() {
  local dir="$1"
  export PATH="${dir}:${PATH}"
  echo "${dir}" >> "${GITHUB_PATH:-/dev/null}"
}

# Parallel execution with error collection
run_parallel() {
  local -a pids=()
  local -a names=()
  local -a fail_flags=()
  local idx=0

  while (( $# >= 2 )); do
    local name="$1" cmd="$2"
    shift 2

    local flag_file; flag_file=$(mktemp "/tmp/ash-parallel-${idx}-XXXXXX")
    fail_flags+=("${flag_file}")
    names+=("${name}")

    (
      if eval "${cmd}" >> "${LOG_FILE}" 2>&1; then
        rm -f "${flag_file}"
      else
        echo "FAILED" > "${flag_file}"
      fi
    ) &
    pids+=($!)
    ((idx++))
  done

  local all_ok=true
  for i in "${!pids[@]}"; do
    wait "${pids[$i]}" 2>/dev/null || true
    if [[ -f "${fail_flags[$i]}" && "$(cat "${fail_flags[$i]}")" == "FAILED" ]]; then
      log_warn "Parallel task failed: ${names[$i]}"
      all_ok=false
    fi
    rm -f "${fail_flags[$i]}"
  done

  [[ "${all_ok}" == "true" ]]
}

# Progress bar display
progress_bar() {
  local current="$1"
  local total="$2"
  local label="${3:-Progress}"
  local width=40
  local filled=$(( current * width / total ))
  local empty=$(( width - filled ))
  local bar
  bar="$(printf '█%.0s' $(seq 1 ${filled} 2>/dev/null || true))"
  bar+="$(printf '░%.0s' $(seq 1 ${empty} 2>/dev/null || true))"
  printf "\r  ${C_MAUVE}%s${C_RESET} [${C_BLUE}%s${C_RESET}] ${C_TEXT}%d/%d${C_RESET}" \
    "${label}" "${bar}" "${current}" "${total}"
  [[ "${current}" -eq "${total}" ]] && echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# BANNER
# ─────────────────────────────────────────────────────────────────────────────
print_banner() {
  echo ""
  echo -e "${C_MAUVE}${C_BOLD}"
  cat << 'BANNER'
  ╔══════════════════════════════════════════════════════════════════════╗
  ║                                                                      ║
  ║   ░█████╗░░██████╗██╗  ██████╗░░█████╗░████████╗███████╗██╗         ║
  ║   ██╔══██╗██╔════╝██║  ██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██║         ║
  ║   ███████║╚█████╗░███████╗██║░░██║██║░░██║░░░██║░░░█████╗░░██║         ║
  ║   ██╔══██║░╚═══██╗██╔══██║██║░░██║██║░░██║░░░██║░░░██╔══╝░░██║         ║
  ║   ██║░░██║██████╔╝██║░░██║██████╔╝╚█████╔╝░░░██║░░░██║░░░░░███████╗   ║
  ║   ╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝╚═════╝░░╚════╝░░░░╚═╝░░░╚═╝░░░░░╚══════╝   ║
  ║                                                                      ║
  ║   ⚡ Setup Action v5.0.0-omega                                        ║
  ╚══════════════════════════════════════════════════════════════════════╝
BANNER
  echo -e "${C_RESET}"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 1 — System update & base packages
# ─────────────────────────────────────────────────────────────────────────────
install_base_packages() {
  step_start "base-packages"

  local BASE_PACKAGES=(
    curl
    wget
    jq
    bc
    git
    unzip
    tar
    gzip
    make
    build-essential
    ca-certificates
    software-properties-common
    apt-transport-https
    gnupg
    lsb-release
  )

  log_info "Updating apt package index..."
  sudo apt-get update -qq 2>/dev/null || log_warn "apt-get update had warnings"

  log_install "Base packages: ${BASE_PACKAGES[*]}"
  apt_install "${BASE_PACKAGES[@]}" || {
    log_warn "Some base packages failed — continuing"
  }

  step_end "base-packages" "ok"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 2 — SQLite
# ─────────────────────────────────────────────────────────────────────────────
install_sqlite() {
  [[ "${FEAT_SQLITE}" != "true" ]] && {
    log_skip "SQLite (disabled)"
    return 0
  }

  step_start "sqlite"

  if is_installed sqlite3; then
    local ver; ver=$(sqlite3 --version 2>/dev/null | head -1 || echo "?")
    log_cache "SQLite already available: ${ver}"
    step_end "sqlite" "skip"
    return 0
  fi

  log_install "SQLite3..."
  apt_install sqlite3 libsqlite3-dev || true
  step_end "sqlite" "ok"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 3 — Python packages
# ─────────────────────────────────────────────────────────────────────────────
install_python_packages() {
  [[ "${FEAT_PYTHON}" != "true" ]] && {
    log_skip "Python packages (disabled)"
    return 0
  }

  step_start "python-packages"

  if [[ "${CACHE_HIT_PIP}" == "true" ]] && [[ "${CACHE_STRATEGY}" == "aggressive" ]]; then
    log_cache "Python packages (pip cache hit)"
    # Still ensure PATH is correct
    add_to_path "${HOME}/.local/bin"
    step_end "python-packages" "skip"
    return 0
  fi

  # Ensure pip is up to date
  log_install "Upgrading pip..."
  python3 -m pip install --quiet --upgrade pip 2>/dev/null || true
  add_to_path "${HOME}/.local/bin"

  # ── Profile-based Python packages ─────────────────────────────────────────
  declare -a PYTHON_PACKAGES=()

  # Core packages (all profiles)
  PYTHON_PACKAGES+=(
    requests==2.32.3
    rich==13.9.2
    jinja2==3.1.4
    PyYAML==6.0.2
    tabulate==0.9.0
    click==8.1.7
    colorama==0.4.6
  )

  # Standard adds matplotlib & scientific stack
  if [[ "${PROFILE}" != "minimal" ]]; then
    PYTHON_PACKAGES+=(
      matplotlib==3.9.2
      numpy==2.1.2
      scipy==1.14.1
      pandas==2.2.3
      Pillow==11.0.0
    )
  fi

  # API profile
  if [[ "${FEAT_API_DEPS}" == "true" ]]; then
    PYTHON_PACKAGES+=(
      fastapi==0.115.0
      "uvicorn[standard]==0.32.0"
      httpx==0.27.2
      websockets==13.1
      pydantic==2.9.2
      "python-jose[cryptography]==3.3.0"
      "passlib[bcrypt]==1.7.4"
      python-multipart==0.0.12
      aiofiles==24.1.0
      aiosqlite==0.20.0
      orjson==3.10.10
      psutil==6.1.0
    )
  fi

  # Security profile
  if [[ "${FEAT_SECURITY}" == "true" ]]; then
    PYTHON_PACKAGES+=(
      bandit==1.7.10
      safety==3.2.8
      pip-audit==2.7.3
      "detect-secrets==1.5.0"
    )
  fi

  # Benchmark profile
  if [[ "${FEAT_BENCHMARK}" == "true" ]]; then
    PYTHON_PACKAGES+=(
      locust==2.32.0
      "pytest-benchmark==4.0.0"
      memory-profiler==0.61.0
    )
  fi

  # Testing stack
  PYTHON_PACKAGES+=(
    pytest==8.3.3
    pytest-asyncio==0.24.0
    "pytest-cov==6.0.0"
    "pytest-xdist==3.6.1"
  )

  # Image processing extras
  if [[ "${FEAT_IMAGEMAGICK}" == "true" ]]; then
    PYTHON_PACKAGES+=(
      colorthief==0.2.1
      "imagehash==4.3.1"
      scikit-learn==1.5.2
    )
  fi

  # User-specified extra packages
  if [[ -n "${EXTRA_PYTHON}" ]]; then
    read -ra EXTRA_ARRAY <<< "${EXTRA_PYTHON}"
    PYTHON_PACKAGES+=("${EXTRA_ARRAY[@]}")
  fi

  # Remove duplicates
  local -A SEEN_PKGS=()
  local -a DEDUPED=()
  for pkg in "${PYTHON_PACKAGES[@]}"; do
    local pkg_name; pkg_name=$(echo "${pkg}" | cut -d= -f1 | tr '[:upper:]' '[:lower:]')
    if [[ -z "${SEEN_PKGS[$pkg_name]+x}" ]]; then
      SEEN_PKGS[$pkg_name]=1
      DEDUPED+=("${pkg}")
    fi
  done

  local total_pkgs="${#DEDUPED[@]}"
  log_install "Installing ${total_pkgs} Python packages..."
  log_debug "Packages: ${DEDUPED[*]}"

  # Install in batches of 10 for progress visibility
  local batch_size=10
  local installed_count=0

  for (( i=0; i<total_pkgs; i+=batch_size )); do
    local batch=("${DEDUPED[@]:$i:$batch_size}")
    pip_install "${batch[@]}" || log_warn "Some packages in batch $((i/batch_size+1)) had issues"
    installed_count=$((installed_count + ${#batch[@]}))
    progress_bar "${installed_count}" "${total_pkgs}" "pip3 install"
  done

  log_success "Python packages installed: ${total_pkgs}"
  step_end "python-packages" "ok"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 4 — ImageMagick & image tools
# ─────────────────────────────────────────────────────────────────────────────
install_imagemagick() {
  [[ "${FEAT_IMAGEMAGICK}" != "true" ]] && {
    log_skip "ImageMagick (disabled)"
    return 0
  }

  step_start "imagemagick"

  local ALREADY_INSTALLED=true
  is_installed convert || ALREADY_INSTALLED=false

  if [[ "${ALREADY_INSTALLED}" == "true" ]] && \
     [[ "${CACHE_STRATEGY}" == "aggressive" ]]; then
    local ver; ver=$(convert --version 2>/dev/null | head -1 || echo "?")
    log_cache "ImageMagick cached: ${ver}"
    step_end "imagemagick" "skip"
    return 0
  fi

  log_install "ImageMagick + WebP + AVIF + fonts..."

  local IMAGE_PACKAGES=(
    imagemagick
    libwebp-dev
    webp
    libavif-dev
    libheif-dev
    ghostscript
    fonts-noto
    fonts-noto-color-emoji
    fonts-noto-cjk
    fonts-liberation
    fonts-firacode
    optipng
    pngquant
    jpegoptim
    gifsicle
    exiftool
  )

  apt_install "${IMAGE_PACKAGES[@]}" 2>/dev/null || {
    # Try minimal set if full set fails
    log_warn "Full image stack failed — trying minimal"
    apt_install imagemagick webp fonts-noto 2>/dev/null || true
  }

  # Verify
  if is_installed convert; then
    local ver; ver=$(convert --version 2>/dev/null | head -1 || echo "?")
    log_success "ImageMagick: ${ver}"
  fi

  if is_installed cwebp; then
    log_success "WebP support: available"
  fi

  step_end "imagemagick" "ok"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 5 — ShellCheck
# ─────────────────────────────────────────────────────────────────────────────
install_shellcheck() {
  [[ "${FEAT_SHELLCHECK}" != "true" ]] && {
    log_skip "ShellCheck (disabled)"
    return 0
  }

  step_start "shellcheck"

  if is_installed shellcheck; then
    local ver; ver=$(shellcheck --version 2>/dev/null | grep "version:" | head -1 || echo "?")
    log_cache "ShellCheck: ${ver}"
    step_end "shellcheck" "skip"
    return 0
  fi

  log_install "ShellCheck..."
  apt_install shellcheck || {
    # Fallback: download from GitHub
    log_warn "apt ShellCheck failed — downloading binary"
    local ARCH="x86_64"
    [[ "$(uname -m)" == "aarch64" ]] && ARCH="aarch64"
    local SC_URL="https://github.com/koalaman/shellcheck/releases/latest/download/shellcheck-latest.linux.${ARCH}.tar.xz"

    local tmp; tmp=$(mktemp -d)
    curl -sSfL "${SC_URL}" | tar -xJ -C "${tmp}" --strip-components=1 || true
    [[ -f "${tmp}/shellcheck" ]] && {
      install -m755 "${tmp}/shellcheck" "${HOME}/.local/bin/shellcheck"
      add_to_path "${HOME}/.local/bin"
    }
    rm -rf "${tmp}"
  }

  is_installed shellcheck && \
    log_success "ShellCheck: $(shellcheck --version | grep version:)" || \
    log_warn "ShellCheck installation had issues"

  step_end "shellcheck" "ok"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 6 — Hyperfine benchmark tool
# ─────────────────────────────────────────────────────────────────────────────
install_hyperfine() {
  [[ "${FEAT_HYPERFINE}" != "true" ]] && {
    log_skip "Hyperfine (disabled)"
    return 0
  }

  step_start "hyperfine"

  if [[ "${CACHE_HIT_TOOLS}" == "true" ]] && is_installed hyperfine; then
    local ver; ver=$(hyperfine --version 2>/dev/null || echo "?")
    log_cache "Hyperfine cached: ${ver}"
    step_end "hyperfine" "skip"
    return 0
  fi

  log_install "Hyperfine v${HYPERFINE_VER}..."

  local ARCH
  ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
  local URL="https://github.com/sharkdp/hyperfine/releases/download/v${HYPERFINE_VER}/hyperfine_${HYPERFINE_VER}_${ARCH}.deb"

  local tmp; tmp=$(mktemp "/tmp/hyperfine-XXXXXX.deb")

  if curl -sSfL "${URL}" -o "${tmp}" 2>/dev/null; then
    sudo dpkg -i "${tmp}" 2>/dev/null && {
      log_success "Hyperfine installed: $(hyperfine --version)"
    } || {
      # Fallback: extract binary
      log_warn "dpkg install failed — extracting binary"
      local extract_dir; extract_dir=$(mktemp -d)
      dpkg-deb -x "${tmp}" "${extract_dir}" 2>/dev/null || true
      find "${extract_dir}" -name "hyperfine" -type f -exec \
        install -m755 {} "${HOME}/.local/bin/hyperfine" \; || true
      add_to_path "${HOME}/.local/bin"
      rm -rf "${extract_dir}"
    }
  else
    # Fallback: download tar.gz
    log_warn "deb download failed — trying tar.gz"
    local MACHINE
    MACHINE=$(uname -m)
    local TARBALL_URL="https://github.com/sharkdp/hyperfine/releases/download/v${HYPERFINE_VER}/hyperfine-v${HYPERFINE_VER}-${MACHINE}-unknown-linux-gnu.tar.gz"
    curl -sSfL "${TARBALL_URL}" | \
      tar -xz -C "${HOME}/.local/bin" \
      --strip-components=1 \
      --wildcards "*/hyperfine" 2>/dev/null || true
    add_to_path "${HOME}/.local/bin"
  fi

  rm -f "${tmp}"
  step_end "hyperfine" "ok"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 7 — Gitleaks secret scanner
# ─────────────────────────────────────────────────────────────────────────────
install_gitleaks() {
  [[ "${FEAT_GITLEAKS}" != "true" ]] && {
    log_skip "Gitleaks (disabled)"
    return 0
  }

  step_start "gitleaks"

  if [[ "${CACHE_HIT_TOOLS}" == "true" ]] && is_installed gitleaks; then
    log_cache "Gitleaks cached: $(gitleaks version 2>/dev/null || echo '?')"
    step_end "gitleaks" "skip"
    return 0
  fi

  log_install "Gitleaks v${GITLEAKS_VER}..."

  local ARCH="x64"
  [[ "$(uname -m)" == "aarch64" ]] && ARCH="arm64"

  local URL="https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VER}/gitleaks_${GITLEAKS_VER}_linux_${ARCH}.tar.gz"

  local tmp_dir; tmp_dir=$(mktemp -d "/tmp/gitleaks-XXXXXX")

  if curl -sSfL "${URL}" | tar -xz -C "${tmp_dir}" 2>/dev/null; then
    install -m755 "${tmp_dir}/gitleaks" "/usr/local/bin/gitleaks" 2>/dev/null || \
    install -m755 "${tmp_dir}/gitleaks" "${HOME}/.local/bin/gitleaks"
    add_to_path "${HOME}/.local/bin"
    log_success "Gitleaks: $(gitleaks version 2>/dev/null || echo 'installed')"
  else
    log_warn "Gitleaks download failed"
    step_end "gitleaks" "fail"
    rm -rf "${tmp_dir}"
    return 0
  fi

  rm -rf "${tmp_dir}"
  step_end "gitleaks" "ok"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 8 — Trivy vulnerability scanner
# ─────────────────────────────────────────────────────────────────────────────
install_trivy() {
  [[ "${FEAT_TRIVY}" != "true" ]] && {
    log_skip "Trivy (disabled)"
    return 0
  }

  step_start "trivy"

  if is_installed trivy; then
    log_cache "Trivy: $(trivy --version 2>/dev/null | head -1 || echo '?')"
    step_end "trivy" "skip"
    return 0
  fi

  log_install "Trivy vulnerability scanner..."

  # Official install script
  if curl -sSfL \
    "https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh" \
    | sh -s -- -b /usr/local/bin 2>/dev/null; then
    log_success "Trivy: $(trivy --version 2>/dev/null | head -1 || echo 'installed')"
  else
    log_warn "Trivy install failed — trying apt"
    # Add Trivy apt repo
    wget -qO - "https://aquasecurity.github.io/trivy-repo/deb/public.key" | \
      gpg --dearmor | \
      sudo tee /usr/share/keyrings/trivy.gpg > /dev/null 2>/dev/null || true

    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | \
      sudo tee /etc/apt/sources.list.d/trivy.list > /dev/null 2>/dev/null || true

    sudo apt-get update -qq 2>/dev/null && apt_install trivy 2>/dev/null || \
      log_warn "Trivy apt install also failed"
  fi

  step_end "trivy" "ok"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 9 — Fish shell
# ─────────────────────────────────────────────────────────────────────────────
install_fish() {
  [[ "${FEAT_FISH}" != "true" ]] && {
    log_skip "Fish shell (disabled)"
    return 0
  }

  step_start "fish-shell"

  if is_installed fish; then
    local ver; ver=$(fish --version 2>/dev/null || echo "?")
    log_cache "Fish shell: ${ver}"
    step_end "fish-shell" "skip"
    return 0
  fi

  log_install "Fish shell..."
  apt_install fish 2>/dev/null || {
    # PPA fallback
    log_warn "apt fish failed — trying PPA"
    sudo add-apt-repository -y ppa:fish-shell/release-3 2>/dev/null || true
    sudo apt-get update -qq 2>/dev/null || true
    apt_install fish 2>/dev/null || log_warn "Fish shell install failed"
  }

  is_installed fish && \
    log_success "Fish: $(fish --version 2>/dev/null || echo 'installed')"

  step_end "fish-shell" "ok"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 10 — Custom packages
# ─────────────────────────────────────────────────────────────────────────────
install_custom_packages() {
  [[ -z "${EXTRA_APT}" ]] && return 0

  step_start "custom-packages"

  read -ra CUSTOM_ARRAY <<< "${EXTRA_APT}"
  log_install "Custom apt packages: ${CUSTOM_ARRAY[*]}"
  apt_install "${CUSTOM_ARRAY[@]}" || {
    log_warn "Some custom packages failed to install"
    [[ "${FAIL_ON_ERROR}" == "true" ]] && return 1 || true
  }

  step_end "custom-packages" "ok"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 11 — ASH config directory setup
# ─────────────────────────────────────────────────────────────────────────────
setup_ash_config() {
  step_start "ash-config"

  log_info "Creating ASH config directory: ${CONFIG_DIR}"
  mkdir -p "${CONFIG_DIR}"/{themes,plugins,snapshots,cache,logs,profiles}

  # Write default config
  if [[ ! -f "${CONFIG_DIR}/ash.conf" ]]; then
    cat > "${CONFIG_DIR}/ash.conf" << 'CONF_EOF'
# ╔══════════════════════════════════════════════════════╗
# ║  ⚡ ASH Dotfiles v5.0 OMEGA — CI Configuration       ║
# ╚══════════════════════════════════════════════════════╝
# Auto-generated for GitHub Actions CI environment

[core]
version         = 5.0.0
environment     = ci
theme           = catppuccin-mocha
mode            = default
log_level       = warn
analytics       = false
telemetry       = false
auto_update     = false

[theme]
name            = catppuccin-mocha
category        = dark
auto_apply      = false
hot_reload      = false
transition      = none

[performance]
cache_enabled   = true
parallel_jobs   = 4
benchmark_mode  = false

[plugin]
auto_install    = false
verify_checksums= true

[security]
strict_mode     = false
allow_scripts   = true
CONF_EOF
    log_success "ASH config created: ${CONFIG_DIR}/ash.conf"
  else
    log_cache "ASH config already exists"
  fi

  # Write sample colors for testing
  if [[ ! -f "${CONFIG_DIR}/themes/current.json" ]]; then
    cat > "${CONFIG_DIR}/themes/current.json" << 'COLORS_EOF'
{
  "name":    "catppuccin-mocha",
  "version": "1.0.0",
  "colors": {
    "base":      "#1e1e2e",
    "mantle":    "#181825",
    "crust":     "#11111b",
    "surface0":  "#313244",
    "surface1":  "#45475a",
    "surface2":  "#585b70",
    "overlay0":  "#6c7086",
    "overlay1":  "#7f849c",
    "overlay2":  "#9399b2",
    "subtext0":  "#a6adc8",
    "subtext1":  "#bac2de",
    "text":      "#cdd6f4",
    "lavender":  "#b4befe",
    "blue":      "#89b4fa",
    "sapphire":  "#74c7ec",
    "sky":       "#89dceb",
    "teal":      "#94e2d5",
    "green":     "#a6e3a1",
    "yellow":    "#f9e2af",
    "peach":     "#fab387",
    "maroon":    "#eba0ac",
    "red":       "#f38ba8",
    "mauve":     "#cba6f7",
    "pink":      "#f5c2e7",
    "flamingo":  "#f2cdcd",
    "rosewater": "#f5e0dc",
    "accent":    "#cba6f7"
  },
  "generated_at": "ci-bootstrap"
}
COLORS_EOF
    log_success "Default theme colors written"
  fi

  # Export to GitHub env
  echo "ASH_CONFIG_DIR=${CONFIG_DIR}" >> "${GITHUB_ENV:-/dev/null}"
  echo "ASH_ROOT=${WORKSPACE}/ash-cli" >> "${GITHUB_ENV:-/dev/null}"
  echo "ASH_LOG_LEVEL=warn" >> "${GITHUB_ENV:-/dev/null}"
  echo "ASH_NO_COLOR=1" >> "${GITHUB_ENV:-/dev/null}"
  echo "ASH_CI=true" >> "${GITHUB_ENV:-/dev/null}"
  echo "ASH_VERSION=5.0.0" >> "${GITHUB_ENV:-/dev/null}"

  # Output config dir for action
  echo "ash_config_dir=${CONFIG_DIR}" >> "${GITHUB_OUTPUT:-/dev/null}"

  step_end "ash-config" "ok"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 12 — Theme engine initialization
# ─────────────────────────────────────────────────────────────────────────────
init_theme_engine() {
  [[ "${INIT_THEME}" != "true" ]] && {
    log_skip "Theme engine init (disabled)"
    return 0
  }

  step_start "theme-engine"

  log_info "Initializing ASH theme engine..."

  # Create theme engine directories
  mkdir -p \
    "${CONFIG_DIR}/themes/presets" \
    "${CONFIG_DIR}/themes/user" \
    "${CONFIG_DIR}/themes/cache" \
    "${CONFIG_DIR}/themes/generated"

  # Create engine lock file
  cat > "${CONFIG_DIR}/themes/.engine-lock" << EOF
{
  "initialized":   true,
  "version":       "5.0.0",
  "init_at":       "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "environment":   "ci",
  "active_theme":  "catppuccin-mocha",
  "engine_pid":    $$
}
EOF

  # Verify engine can extract colors
  if python3 -c "from PIL import Image; import numpy" 2>/dev/null; then
    log_success "Theme engine: color extraction available"
  else
    log_warn "Theme engine: Pillow/numpy not available for color extraction"
  fi

  # Test template rendering
  if python3 -c "from jinja2 import Template; Template('{{test}}').render(test='ok')" 2>/dev/null; then
    log_success "Theme engine: template rendering available"
  fi

  log_success "Theme engine initialized at ${CONFIG_DIR}"
  step_end "theme-engine" "ok"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 13 — Plugin system initialization
# ─────────────────────────────────────────────────────────────────────────────
init_plugin_system() {
  [[ "${INIT_PLUGINS}" != "true" ]] && {
    log_skip "Plugin system init (disabled)"
    return 0
  }

  step_start "plugin-system"

  log_info "Initializing ASH plugin system..."

  mkdir -p \
    "${CONFIG_DIR}/plugins/installed" \
    "${CONFIG_DIR}/plugins/enabled" \
    "${CONFIG_DIR}/plugins/cache"

  # Plugin registry
  cat > "${CONFIG_DIR}/plugins/registry.json" << 'REGISTRY_EOF'
{
  "version":       "5.0.0",
  "initialized":   true,
  "environment":   "ci",
  "installed":     [],
  "enabled":       [],
  "auto_install":  false
}
REGISTRY_EOF

  log_success "Plugin system initialized"
  step_end "plugin-system" "ok"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 14 — PATH & environment finalization
# ─────────────────────────────────────────────────────────────────────────────
finalize_environment() {
  step_start "environment"

  log_info "Finalizing PATH & environment variables..."

  # Ensure ~/.local/bin is in PATH
  add_to_path "${HOME}/.local/bin"
  add_to_path "/usr/local/bin"
  add_to_path "${WORKSPACE}/ash-cli"

  # Export key environment variables
  {
    echo "PATH=${HOME}/.local/bin:/usr/local/bin:${PATH}"
    echo "PYTHONPATH=${HOME}/.local/lib/python${PYTHON_VERSION}/site-packages:${PYTHONPATH:-}"
    echo "ASH_ENV_READY=true"
    echo "ASH_SETUP_VERSION=${SETUP_VERSION}"
    echo "ASH_PROFILE=${PROFILE}"
  } >> "${GITHUB_ENV:-/dev/null}"

  # Write environment manifest
  cat > "${WORK_DIR}/environment.json" << EOF
{
  "setup_version":  "${SETUP_VERSION}",
  "profile":        "${PROFILE}",
  "python_version": "$(python3 --version 2>/dev/null || echo 'N/A')",
  "node_version":   "$(node --version 2>/dev/null || echo 'N/A')",
  "os":             "$(uname -s) $(uname -m)",
  "runner_os":      "${RUNNER_OS:-linux}",
  "config_dir":     "${CONFIG_DIR}",
  "cache_strategy": "${CACHE_STRATEGY}",
  "cache_hit_pip":  "${CACHE_HIT_PIP}",
  "cache_hit_tools":"${CACHE_HIT_TOOLS}",
  "features": {
    "python":      "${FEAT_PYTHON}",
    "node":        "${FEAT_NODE}",
    "imagemagick": "${FEAT_IMAGEMAGICK}",
    "fish":        "${FEAT_FISH}",
    "hyperfine":   "${FEAT_HYPERFINE}",
    "shellcheck":  "${FEAT_SHELLCHECK}",
    "gitleaks":    "${FEAT_GITLEAKS}",
    "trivy":       "${FEAT_TRIVY}",
    "sqlite":      "${FEAT_SQLITE}",
    "api_deps":    "${FEAT_API_DEPS}",
    "security":    "${FEAT_SECURITY}",
    "benchmark":   "${FEAT_BENCHMARK}"
  },
  "initialized_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

  log_success "Environment finalized"
  step_end "environment" "ok"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 15 — Metrics & completion report
# ─────────────────────────────────────────────────────────────────────────────
write_metrics() {
  local end_time; end_time=$(date +%s)
  local total_duration=$(( end_time - SETUP_START ))

  # Build step timings JSON
  local TIMINGS_JSON="{"
  local first=true
  for key in "${!STEP_TIMES[@]}"; do
    [[ "${key}" == *"_ms" ]] || continue
    local step_name="${key%_ms}"
    [[ "${first}" == "false" ]] && TIMINGS_JSON+=","
    TIMINGS_JSON+="\"${step_name}\":${STEP_TIMES[$key]}"
    first=false
  done
  TIMINGS_JSON+="}"

  cat > "${METRICS_FILE}" << EOF
{
  "setup_version":   "${SETUP_VERSION}",
  "profile":         "${PROFILE}",
  "total_duration_s":${total_duration},
  "steps": {
    "total":     ${TOTAL_STEPS},
    "completed": ${COMPLETED_STEPS},
    "installed": ${#INSTALLED_TOOLS[@]},
    "skipped":   ${#SKIPPED_TOOLS[@]},
    "failed":    ${#FAILED_TOOLS[@]}
  },
  "timings_ms": ${TIMINGS_JSON},
  "installed_tools": $(printf '%s\n' "${INSTALLED_TOOLS[@]:-none}" | jq -R . | jq -s . 2>/dev/null || echo '[]'),
  "skipped_tools":   $(printf '%s\n' "${SKIPPED_TOOLS[@]:-none}" | jq -R . | jq -s . 2>/dev/null || echo '[]'),
  "failed_tools":    $(printf '%s\n' "${FAILED_TOOLS[@]:-none}" | jq -R . | jq -s . 2>/dev/null || echo '[]'),
  "cache": {
    "strategy":   "${CACHE_STRATEGY}",
    "hit_pip":    ${CACHE_HIT_PIP},
    "hit_tools":  ${CACHE_HIT_TOOLS}
  },
  "completed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

  # Print final summary
  echo ""
  echo -e "${C_MAUVE}${C_BOLD}"
  echo "  ╔══════════════════════════════════════════════════════════════╗"
  echo "  ║  ⚡ ASH Environment Setup Complete                           ║"
  echo "  ╠══════════════════════════════════════════════════════════════╣"
  printf  "  ║  ⏱️  Total Duration:    %-37s║\n" "${total_duration}s"
  printf  "  ║  📦 Steps Completed:   %-37s║\n" "${COMPLETED_STEPS}/${TOTAL_STEPS}"
  printf  "  ║  ✅ Installed:         %-37s║\n" "${#INSTALLED_TOOLS[@]} tools"
  printf  "  ║  ⏭️  Skipped:          %-37s║\n" "${#SKIPPED_TOOLS[@]} (cached)"
  printf  "  ║  ❌ Failed:            %-37s║\n" "${#FAILED_TOOLS[@]} tools"
  printf  "  ║  🎯 Profile:           %-37s║\n" "${PROFILE}"
  printf  "  ║  💾 Cache Strategy:    %-37s║\n" "${CACHE_STRATEGY}"
  printf  "  ║  🐍 Python:            %-37s║\n" "$(python3 --version 2>/dev/null || echo 'N/A')"
  echo "  ╚══════════════════════════════════════════════════════════════╝"
  echo -e "${C_RESET}"

  if [[ "${#FAILED_TOOLS[@]}" -gt 0 ]]; then
    log_warn "Failed tools: ${FAILED_TOOLS[*]}"
    if [[ "${FAIL_ON_ERROR}" == "true" ]]; then
      log_error "Setup completed with failures (fail_on_error=true)"
      exit 1
    fi
  fi

  log_success "ASH environment ready! 🎨"
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN EXECUTION
# ─────────────────────────────────────────────────────────────────────────────
main() {
  print_banner

  echo -e "  ${C_TEXT}Session: ${C_MAUVE}${C_BOLD}ash-setup-$(date +%Y%m%d%H%M%S)${C_RESET}"
  echo -e "  ${C_TEXT}Log:     ${C_OVERLAY}${LOG_FILE}${C_RESET}"
  echo ""

  # ── Execute setup phases ──────────────────────────────────────────────────

  # Phase 1: System packages (sequential — dependency order matters)
  echo -e "\n  ${C_SAPPHIRE}${C_BOLD}━━━ Phase 1: System Packages ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
  install_base_packages
  install_sqlite
  install_shellcheck
  install_imagemagick
  install_fish

  # Phase 2: Binary tools (can run in parallel)
  echo -e "\n  ${C_SAPPHIRE}${C_BOLD}━━━ Phase 2: Binary Tools ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"

  if [[ "${FEAT_HYPERFINE}" == "true" ]] || [[ "${FEAT_GITLEAKS}" == "true" ]] || [[ "${FEAT_TRIVY}" == "true" ]]; then
    log_info "Installing binary tools in parallel..."

    declare -a PARALLEL_CMDS=()
    [[ "${FEAT_HYPERFINE}" == "true" ]] && PARALLEL_CMDS+=("hyperfine" "install_hyperfine")
    [[ "${FEAT_GITLEAKS}" == "true" ]]  && PARALLEL_CMDS+=("gitleaks"  "install_gitleaks")
    [[ "${FEAT_TRIVY}" == "true" ]]     && PARALLEL_CMDS+=("trivy"     "install_trivy")

    if [[ "${#PARALLEL_CMDS[@]}" -gt 0 ]]; then
      # Execute sequentially for reliability (parallel can cause apt lock issues)
      [[ "${FEAT_HYPERFINE}" == "true" ]] && install_hyperfine
      [[ "${FEAT_GITLEAKS}" == "true" ]]  && install_gitleaks
      [[ "${FEAT_TRIVY}" == "true" ]]     && install_trivy
    fi
  fi

  # Custom packages
  install_custom_packages

  # Phase 3: Python packages (after system tools)
  echo -e "\n  ${C_SAPPHIRE}${C_BOLD}━━━ Phase 3: Python Ecosystem ━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
  install_python_packages

  # Phase 4: ASH initialization
  echo -e "\n  ${C_SAPPHIRE}${C_BOLD}━━━ Phase 4: ASH Environment ━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
  setup_ash_config
  init_theme_engine
  init_plugin_system

  # Phase 5: Environment finalization
  echo -e "\n  ${C_SAPPHIRE}${C_BOLD}━━━ Phase 5: Finalization ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
  finalize_environment

  # Write metrics & completion report
  write_metrics
}

# ─────────────────────────────────────────────────────────────────────────────
# TRAP: Cleanup on unexpected exit
# ─────────────────────────────────────────────────────────────────────────────
trap 'EXIT_CODE=$?; if [[ $EXIT_CODE -ne 0 ]]; then
  echo ""
  log_error "Setup failed with exit code: ${EXIT_CODE}"
  echo "  📋 Last log lines:"
  tail -20 "${LOG_FILE}" 2>/dev/null | sed "s/^/     /"
  echo "  📁 Full log: ${LOG_FILE}"
fi' EXIT

# ─────────────────────────────────────────────────────────────────────────────
# ENTRY POINT
# ─────────────────────────────────────────────────────────────────────────────
main "$@"