#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██████╗ ███████╗██████╗ ███████╗███╗   ██╗██████╗ ███████╗███╗   ██╗ ██████╗  ║
# ║  ██╔══██╗██╔════╝██╔══██╗██╔════╝████╗  ██║██╔══██╗██╔════╝████╗  ██║██╔════╝  ║
# ║  ██║  ██║█████╗  ██████╔╝█████╗  ██╔██╗ ██║██║  ██║█████╗  ██╔██╗ ██║██║       ║
# ║  ██║  ██║██╔══╝  ██╔═══╝ ██╔══╝  ██║╚██╗██║██║  ██║██╔══╝  ██║╚██╗██║██║       ║
# ║  ██████╔╝███████╗██║     ███████╗██║ ╚████║██████╔╝███████╗██║ ╚████║╚██████╗  ║
# ║  ╚═════╝ ╚══════╝╚═╝     ╚══════╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═══╝ ╚═════╝  ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  DOCTOR CHECK: DEPENDENCIES                              ║
# ║                                                                                  ║
# ║  Comprehensive dependency graph verification:                                   ║
# ║  shared libraries • python packages • node modules • runtime environments       ║
# ║  language runtimes • package manager health • AUR helper state                  ║
# ║                                                                                  ║
# ║  Author   : ash-dotfiles                                                         ║
# ║  License  : MIT                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CHECK_DEPENDENCIES_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CHECK_DEPENDENCIES_LOADED=1

# Sourced as a library by _common.sh, so shell options are only
# tightened when this file is EXECUTED directly. A sourced file that
# sets -e/-u rewrites the options of whoever loaded it — the first
# module would make the whole doctor process abort on any non-zero
# status or unset variable.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
fi
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  DEPENDENCY RESULT TRACKING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g  _DEP_PASS=0
declare -g  _DEP_WARN=0
declare -g  _DEP_FAIL=0
declare -ga _DEP_MISSING_PKGS=()
declare -ga _DEP_BROKEN=()

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Check a shared library via ldconfig
_dep_lib() {
    local lib_pattern="$1"
    local label="${2:-$lib_pattern}"
    local pkg="${3:-}"
    local critical="${4:-0}"

    local found
    found="$(ldconfig -p 2>/dev/null | grep "$lib_pattern" | \
             awk '{print $1}' | head -1 || echo '')"

    if [[ -n "$found" ]]; then
        _check_report $CHECK_PASS \
            "lib: ${label}" \
            "Found: ${found}"
        (( _DEP_PASS++ )) || true
    else
        # Try direct find in common lib dirs
        local direct_find
        direct_find="$(find /usr/lib /usr/lib64 /usr/local/lib \
                       -name "${lib_pattern}*" 2>/dev/null | head -1 || echo '')"

        if [[ -n "$direct_find" ]]; then
            _check_report $CHECK_PASS \
                "lib: ${label}" \
                "${direct_find}"
            (( _DEP_PASS++ )) || true
        elif [[ "$critical" == "1" ]]; then
            _check_report $CHECK_FAIL \
                "lib: ${label}" \
                "NOT found  (${lib_pattern})" \
                "Install: paru -S ${pkg}"
            _DEP_MISSING_PKGS+=("${pkg}")
            (( _DEP_FAIL++ )) || true
        else
            _check_report $CHECK_INFO \
                "lib: ${label}" \
                "Not found  (optional)" \
                "Install: paru -S ${pkg}"
            (( _DEP_WARN++ )) || true
        fi
    fi
}

# Check Python package
_dep_python() {
    local module="$1"
    local label="${2:-$module}"
    local pip_name="${3:-$module}"
    local critical="${4:-0}"

    if command -v python3 &>/dev/null && \
       python3 -c "import ${module}" &>/dev/null 2>&1; then
        local ver
        ver="$(python3 -c "import ${module}; \
               print(getattr(${module},'__version__',getattr(${module},'version','ok')))" \
               2>/dev/null || echo 'installed')"
        _check_report $CHECK_PASS \
            "py: ${label}" \
            "v${ver}"
        (( _DEP_PASS++ )) || true
    else
        if [[ "$critical" == "1" ]]; then
            _check_report $CHECK_FAIL \
                "py: ${label}" \
                "NOT installed" \
                "Install: pip install ${pip_name}  or  paru -S python-${pip_name}"
            (( _DEP_FAIL++ )) || true
        else
            _check_report $CHECK_INFO \
                "py: ${label}" \
                "Not installed  (optional)" \
                "pip install ${pip_name}"
            (( _DEP_WARN++ )) || true
        fi
    fi
}

# Check package version from package manager
_dep_pkg() {
    local pkg_name="$1"
    local label="${2:-$pkg_name}"
    local min_ver="${3:-}"
    local critical="${4:-1}"

    local installed_ver=""

    if command -v pacman &>/dev/null; then
        installed_ver="$(pacman -Q "$pkg_name" 2>/dev/null | awk '{print $2}' || echo '')"
    elif command -v dpkg &>/dev/null; then
        installed_ver="$(dpkg -l "$pkg_name" 2>/dev/null | \
                        awk '/^ii/{print $3}' | head -1 || echo '')"
    elif command -v rpm &>/dev/null; then
        installed_ver="$(rpm -q --qf '%{VERSION}' "$pkg_name" 2>/dev/null || echo '')"
    fi

    if [[ -n "$installed_ver" ]]; then
        _check_report $CHECK_PASS \
            "pkg: ${label}" \
            "v${installed_ver}"
        (( _DEP_PASS++ )) || true
    else
        if [[ "$critical" == "1" ]]; then
            _check_report $CHECK_FAIL \
                "pkg: ${label}" \
                "NOT installed" \
                "Install: paru -S ${pkg_name}"
            _DEP_MISSING_PKGS+=("$pkg_name")
            (( _DEP_FAIL++ )) || true
        else
            _check_report $CHECK_INFO \
                "pkg: ${label}" \
                "Not installed  (optional)"
            (( _DEP_WARN++ )) || true
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 01 — PACKAGE MANAGER HEALTH
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_dep_pacman() {
    _check_header "📦 Package Manager Health"

    if ! command -v pacman &>/dev/null; then
        _check_report $CHECK_SKIP \
            "pacman" \
            "Not available  (non-Arch system)"
        return $CHECK_SKIP
    fi

    # ── Pacman lock file ──────────────────────────────────────────────────────────
    if [[ -f /var/lib/pacman/db.lck ]]; then
        _check_report $CHECK_WARN \
            "pacman db.lck" \
            "Lock file exists  (another process running?)" \
            "Remove if stale: sudo rm /var/lib/pacman/db.lck"
    else
        _check_report $CHECK_PASS \
            "pacman db.lck" \
            "No lock file  ✓"
    fi

    # ── Package database integrity ────────────────────────────────────────────────
    local db_dir="/var/lib/pacman/local"
    if [[ -d "$db_dir" ]]; then
        local pkg_count
        pkg_count="$(find "$db_dir" -maxdepth 1 -mindepth 1 -type d | wc -l)"
        _check_report $CHECK_INFO \
            "Installed packages" \
            "${pkg_count} packages installed"
    fi

    # ── Orphaned packages ─────────────────────────────────────────────────────────
    local orphans
    orphans="$(pacman -Qdtq 2>/dev/null | wc -l || echo 0)"
    if (( orphans > 0 )); then
        _check_report $CHECK_INFO \
            "Orphaned packages" \
            "${orphans} package(s) not required by any other" \
            "Review: pacman -Qdtq  •  Remove: paru -Rns \$(pacman -Qdtq)"
    else
        _check_report $CHECK_PASS \
            "Orphaned packages" \
            "None  ✓"
    fi

    # ── Pacman key trust ──────────────────────────────────────────────────────────
    local untrusted_keys
    untrusted_keys="$(pacman-key --list-keys 2>/dev/null | \
                     grep -c 'not certified\|unknown' || echo 0)"
    if (( untrusted_keys > 0 )); then
        _check_report $CHECK_WARN \
            "Pacman untrusted keys" \
            "${untrusted_keys} key(s) not trusted" \
            "Refresh: sudo pacman-key --refresh-keys"
    else
        _check_report $CHECK_PASS \
            "Pacman keyring" \
            "All keys trusted"
    fi

    # ── AUR helper ───────────────────────────────────────────────────────────────
    local aur_helper=""
    local aur_ver=""
    if command -v paru &>/dev/null; then
        aur_helper="paru"
        aur_ver="$(paru --version 2>/dev/null | grep -oP '[\d]+\.[\d.]+' | head -1 || echo '?')"
    elif command -v yay &>/dev/null; then
        aur_helper="yay"
        aur_ver="$(yay --version 2>/dev/null | grep -oP '[\d]+\.[\d.]+' | head -1 || echo '?')"
    fi

    if [[ -n "$aur_helper" ]]; then
        _check_report $CHECK_PASS \
            "AUR helper" \
            "${aur_helper} v${aur_ver}"

        # Check for AUR updates
        local aur_updates
        aur_updates="$($aur_helper -Qua 2>/dev/null | wc -l || echo '?')"
        if [[ "$aur_updates" =~ ^[0-9]+$ ]]; then
            if (( aur_updates > 0 )); then
                _check_report $CHECK_INFO \
                    "AUR updates available" \
                    "${aur_updates} package(s)  — run: ${aur_helper} -Su"
            else
                _check_report $CHECK_PASS \
                    "AUR packages" \
                    "All up to date"
            fi
        fi
    else
        _check_report $CHECK_WARN \
            "AUR helper" \
            "Not found" \
            "Install paru: git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si"
    fi

    # ── Pacman config ─────────────────────────────────────────────────────────────
    local pacman_conf="/etc/pacman.conf"
    if [[ -f "$pacman_conf" ]]; then
        # Check Color / ILoveCandy / ParallelDownloads
        local parallel_dl
        parallel_dl="$(grep -oP '(?<=ParallelDownloads = )\d+' \
                      "$pacman_conf" 2>/dev/null || echo '')"
        if [[ -n "$parallel_dl" ]]; then
            _check_report $CHECK_PASS \
                "pacman ParallelDownloads" \
                "${parallel_dl} parallel downloads"
        else
            _check_report $CHECK_INFO \
                "pacman ParallelDownloads" \
                "Not set  (default: 1)" \
                "Enable in /etc/pacman.conf: ParallelDownloads = 5"
        fi

        local color
        color="$(grep -c '^Color' "$pacman_conf" 2>/dev/null || echo 0)"
        if (( color > 0 )); then
            _check_report $CHECK_PASS "pacman Color" "Enabled"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 02 — SHARED LIBRARIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_dep_shared_libs() {
    _check_header "🔗 Critical Shared Libraries"

    # ── Wayland / Compositor libraries ───────────────────────────────────────────
    _dep_lib "libwayland-client.so"  "libwayland-client"   "wayland"         1
    _dep_lib "libwayland-server.so"  "libwayland-server"   "wayland"         1
    _dep_lib "libwayland-egl.so"     "libwayland-egl"      "wayland"         1
    _dep_lib "libwlroots.so"         "wlroots"             "wlroots"         1
    _dep_lib "libxkbcommon.so"       "xkbcommon"           "libxkbcommon"    1
    _dep_lib "libinput.so"           "libinput"            "libinput"        1
    _dep_lib "libudev.so"            "libudev"             "systemd-libs"    1
    _dep_lib "libseat.so"            "libseat"             "seatd"           0

    # ── Graphics / EGL ───────────────────────────────────────────────────────────
    _dep_lib "libEGL.so"             "libEGL"              "libglvnd"        1
    _dep_lib "libGL.so"              "libGL"               "libglvnd"        1
    _dep_lib "libGLESv2.so"          "libGLESv2"           "libglvnd"        1
    _dep_lib "libvulkan.so"          "libvulkan"           "vulkan-icd-loader" 1
    _dep_lib "libdrm.so"             "libdrm"              "libdrm"          1
    _dep_lib "libgbm.so"             "libgbm"              "mesa"            1

    # ── Mesa ─────────────────────────────────────────────────────────────────────
    _dep_lib "libGL.so"              "Mesa libGL"          "mesa"            1

    # ── GTK ──────────────────────────────────────────────────────────────────────
    _dep_lib "libgtk-3.so"           "GTK 3"               "gtk3"            1
    _dep_lib "libgtk-4.so"           "GTK 4"               "gtk4"            1
    _dep_lib "libglib-2.0.so"        "GLib 2"              "glib2"           1
    _dep_lib "libgio-2.0.so"         "GIO 2"               "glib2"           1
    _dep_lib "libgdk-3.so"           "GDK 3"               "gtk3"            0

    # ── Qt ───────────────────────────────────────────────────────────────────────
    _dep_lib "libQt6Core.so"         "Qt6 Core"            "qt6-base"        0
    _dep_lib "libQt6Widgets.so"      "Qt6 Widgets"         "qt6-base"        0
    _dep_lib "libQt5Core.so"         "Qt5 Core"            "qt5-base"        0

    # ── Audio ─────────────────────────────────────────────────────────────────────
    _dep_lib "libpipewire-0.3.so"    "libpipewire"         "pipewire"        1
    _dep_lib "libpulse.so"           "libpulse"            "libpulse"        1
    _dep_lib "libasound.so"          "ALSA (libasound)"    "alsa-lib"        1

    # ── Image processing ─────────────────────────────────────────────────────────
    _dep_lib "libMagickWand"         "ImageMagick Wand"    "imagemagick"     1
    _dep_lib "libMagickCore"         "ImageMagick Core"    "imagemagick"     1
    _dep_lib "libpng16.so"           "libpng"              "libpng"          1
    _dep_lib "libjpeg.so"            "libjpeg"             "libjpeg-turbo"   1
    _dep_lib "libwebp.so"            "libwebp"             "libwebp"         0
    _dep_lib "libexif.so"            "libexif"             "libexif"         0

    # ── Crypto / Security ────────────────────────────────────────────────────────
    _dep_lib "libssl.so"             "OpenSSL"             "openssl"         1
    _dep_lib "libgcrypt.so"          "libgcrypt"           "libgcrypt"       1
    _dep_lib "libsodium.so"          "libsodium"           "libsodium"       0

    # ── D-Bus ────────────────────────────────────────────────────────────────────
    _dep_lib "libdbus-1.so"          "libdbus"             "dbus"            1

    # ── Lua (Neovim) ─────────────────────────────────────────────────────────────
    _dep_lib "liblua"                "Lua library"         "lua"             0
    _dep_lib "libluajit"             "LuaJIT"              "luajit"          0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 03 — PYTHON ECOSYSTEM
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_dep_python() {
    _check_header "🐍 Python Ecosystem"

    # ── Python version ────────────────────────────────────────────────────────────
    if ! command -v python3 &>/dev/null; then
        _check_report $CHECK_FAIL \
            "Python 3" \
            "Not installed" \
            "Install: paru -S python"
        (( _DEP_FAIL++ )) || true
        return $CHECK_FAIL
    fi

    local py_ver
    py_ver="$(python3 --version 2>&1 | grep -oP '[\d]+\.[\d.]+' || echo '?')"
    local py_major py_minor
    py_major="${py_ver%%.*}"
    py_minor="$(printf '%s' "$py_ver" | cut -d. -f2)"

    if [[ "$py_major" =~ ^[0-9]+$ ]] && (( py_major >= 3 )) && (( py_minor >= 10 )); then
        _check_report $CHECK_PASS \
            "Python version" \
            "v${py_ver}  ✓"
    elif [[ "$py_major" =~ ^[0-9]+$ ]] && (( py_major >= 3 )) && (( py_minor >= 8 )); then
        _check_report $CHECK_WARN \
            "Python version" \
            "v${py_ver}  (3.10+ recommended)" \
            "Update: paru -Su python"
    else
        _check_report $CHECK_FAIL \
            "Python version" \
            "v${py_ver}  (too old)" \
            "Update: paru -Su python"
    fi

    # ── pip ───────────────────────────────────────────────────────────────────────
    if command -v pip &>/dev/null || command -v pip3 &>/dev/null; then
        local pip_cmd
        command -v pip3 &>/dev/null && pip_cmd="pip3" || pip_cmd="pip"
        local pip_ver
        pip_ver="$($pip_cmd --version 2>/dev/null | grep -oP '[\d]+\.[\d.]+' | head -1 || echo '?')"
        _check_report $CHECK_PASS \
            "pip" \
            "v${pip_ver}"
    else
        _check_report $CHECK_WARN \
            "pip" \
            "Not found" \
            "Install: paru -S python-pip"
    fi

    # ── Critical Python packages ──────────────────────────────────────────────────
    _dep_python "json"      "json (stdlib)"     ""           1
    _dep_python "tomllib"   "tomllib (stdlib)"  ""           0
    _dep_python "yaml"      "PyYAML"            "pyyaml"     1
    _dep_python "requests"  "requests"          "requests"   1
    _dep_python "PIL"       "Pillow"            "pillow"     1
    _dep_python "colormath" "colormath"         "colormath"  0
    _dep_python "numpy"     "NumPy"             "numpy"      0
    _dep_python "colorthief" "ColorThief"       "colorthief" 0
    _dep_python "dbus"      "dbus-python"       "dbus-python" 0
    _dep_python "gi"        "PyGObject"         "pygobject"  0
    _dep_python "rich"      "Rich"              "rich"       0
    _dep_python "click"     "Click"             "click"      0

    # ── Virtual environment check ─────────────────────────────────────────────────
    local ash_venv="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}/.venv"
    if [[ -d "$ash_venv" ]]; then
        local venv_py
        venv_py="${ash_venv}/bin/python3"
        if [[ -x "$venv_py" ]]; then
            _check_report $CHECK_PASS \
                "ASH Python venv" \
                "${ash_venv}"
        else
            _check_report $CHECK_WARN \
                "ASH Python venv" \
                "Broken — python3 not executable in ${ash_venv}"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 04 — NODE / JAVASCRIPT ECOSYSTEM
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_dep_node() {
    _check_header "🟢 Node.js / JavaScript Ecosystem"

    if ! command -v node &>/dev/null; then
        _check_report $CHECK_INFO \
            "Node.js" \
            "Not installed  (needed for AGS, web dashboard)" \
            "Install: paru -S nodejs npm"
        return $CHECK_PASS
    fi

    local node_ver
    node_ver="$(node --version 2>/dev/null | tr -d 'v' || echo '?')"
    local node_major="${node_ver%%.*}"

    if [[ "$node_major" =~ ^[0-9]+$ ]]; then
        if (( node_major >= 20 )); then
            _check_report $CHECK_PASS \
                "Node.js" \
                "v${node_ver}  (LTS — excellent)"
        elif (( node_major >= 18 )); then
            _check_report $CHECK_PASS \
                "Node.js" \
                "v${node_ver}  (LTS)"
        elif (( node_major >= 16 )); then
            _check_report $CHECK_WARN \
                "Node.js" \
                "v${node_ver}  (old LTS — update recommended)" \
                "Update: nvm install --lts"
        else
            _check_report $CHECK_FAIL \
                "Node.js" \
                "v${node_ver}  (EOL — upgrade required)" \
                "Update: paru -Su nodejs"
        fi
    fi

    # ── npm / pnpm / bun ──────────────────────────────────────────────────────────
    local -a js_pkg_mgrs=( "npm:npm" "pnpm:pnpm" "bun:bun" "deno:deno" )
    for pm_entry in "${js_pkg_mgrs[@]}"; do
        IFS=':' read -r cmd label <<< "$pm_entry"
        if command -v "$cmd" &>/dev/null; then
            local pm_ver
            pm_ver="$("$cmd" --version 2>/dev/null | grep -oP '[\d]+\.[\d.]+' | head -1 || echo '?')"
            _check_report $CHECK_PASS "JS: ${label}" "v${pm_ver}"
        else
            _check_report $CHECK_INFO "JS: ${label}" "not installed"
        fi
    done

    # ── AGS (Aylur's GTK Shell) dependencies ─────────────────────────────────────
    _dep_pkg "ags"        "AGS (Aylur's GTK Shell)" ""  0
    _dep_pkg "gjs"        "GJS (JavaScript GTK)"    ""  0
    _dep_pkg "mutter"     "Mutter (MGS backend)"    ""  0

    # ── TypeScript ────────────────────────────────────────────────────────────────
    if command -v tsc &>/dev/null; then
        local tsc_ver
        tsc_ver="$(tsc --version 2>/dev/null | grep -oP '[\d]+\.[\d.]+' || echo '?')"
        _check_report $CHECK_PASS \
            "TypeScript compiler" \
            "v${tsc_ver}"
    else
        _check_report $CHECK_INFO \
            "TypeScript compiler" \
            "Not installed  (needed for AGS/web dashboard)" \
            "Install: npm install -g typescript"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 05 — RUST ECOSYSTEM
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_dep_rust() {
    _check_header "🦀 Rust Ecosystem"

    if ! command -v cargo &>/dev/null; then
        _check_report $CHECK_INFO \
            "Rust / Cargo" \
            "Not installed  (needed for some ASH tools)" \
            "Install: paru -S rust  or  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        return $CHECK_PASS
    fi

    local rust_ver
    rust_ver="$(rustc --version 2>/dev/null | grep -oP '[\d]+\.[\d.]+' | head -1 || echo '?')"
    local cargo_ver
    cargo_ver="$(cargo --version 2>/dev/null | grep -oP '[\d]+\.[\d.]+' | head -1 || echo '?')"

    _check_report $CHECK_PASS \
        "Rust toolchain" \
        "rustc v${rust_ver}  •  cargo v${cargo_ver}"

    # ── Rust tools used by ASH ────────────────────────────────────────────────────
    local -a rust_tools=(
        "eza:eza (ls replacement)"
        "bat:bat (cat replacement)"
        "fd:fd (find replacement)"
        "rg:ripgrep"
        "sd:sd (sed replacement)"
        "delta:delta (git diff)"
        "starship:Starship prompt"
        "zoxide:Zoxide"
        "hyperfine:Hyperfine (benchmarker)"
        "tokei:Tokei (code counter)"
        "atuin:Atuin (shell history)"
        "just:Just (task runner)"
        "ouch:Ouch (compress/decompress)"
        "yazi:Yazi (file manager)"
    )

    local rust_tools_installed=0
    for rt_entry in "${rust_tools[@]}"; do
        IFS=':' read -r rt_bin rt_label <<< "$rt_entry"
        if command -v "$rt_bin" &>/dev/null; then
            local rtv
            rtv="$("$rt_bin" --version 2>/dev/null | \
                   grep -oP '[\d]+\.[\d.]+' | head -1 || echo 'ok')"
            _check_report $CHECK_PASS \
                "Rust tool: ${rt_label}" \
                "v${rtv}"
            (( rust_tools_installed++ )) || true
        else
            _check_report $CHECK_INFO \
                "Rust tool: ${rt_label}" \
                "not installed" \
                "paru -S ${rt_bin}"
        fi
    done

    _check_report $CHECK_INFO \
        "Rust tools installed" \
        "${rust_tools_installed}/${#rust_tools[@]}"

    # ── Cargo registry cache ──────────────────────────────────────────────────────
    local cargo_cache="${CARGO_HOME:-$HOME/.cargo}"
    if [[ -d "$cargo_cache" ]]; then
        local cache_size
        cache_size="$(du -sh "$cargo_cache" 2>/dev/null | cut -f1 || echo '?')"
        _check_report $CHECK_INFO \
            "Cargo cache" \
            "${cache_size}  (${cargo_cache})"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 06 — RUNTIME ENVIRONMENTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_dep_runtimes() {
    _check_header "🏃 Language Runtime Environments"

    # ── Go ────────────────────────────────────────────────────────────────────────
    if command -v go &>/dev/null; then
        local go_ver
        go_ver="$(go version 2>/dev/null | grep -oP 'go[\d.]+' | tr -d 'go' || echo '?')"
        _check_report $CHECK_PASS "Go" "v${go_ver}"
        local gopath="${GOPATH:-$HOME/go}"
        local gopath_size
        gopath_size="$(du -sh "$gopath" 2>/dev/null | cut -f1 || echo '?')"
        _check_report $CHECK_INFO "  GOPATH" "${gopath}  (${gopath_size})"
    else
        _check_report $CHECK_INFO "Go" "not installed"
    fi

    # ── Java ─────────────────────────────────────────────────────────────────────
    if command -v java &>/dev/null; then
        local java_ver
        java_ver="$(java -version 2>&1 | grep -oP '[\d]+\.[\d.]+_?[\d]*' | head -1 || echo '?')"
        _check_report $CHECK_INFO "Java" "v${java_ver}"
        local java_home="${JAVA_HOME:-}"
        [[ -n "$java_home" ]] && _check_report $CHECK_INFO "  JAVA_HOME" "$java_home"
    else
        _check_report $CHECK_INFO "Java" "not installed"
    fi

    # ── Ruby ─────────────────────────────────────────────────────────────────────
    if command -v ruby &>/dev/null; then
        local ruby_ver
        ruby_ver="$(ruby --version 2>/dev/null | grep -oP '[\d]+\.[\d.]+p?[\d]*' | head -1 || echo '?')"
        _check_report $CHECK_INFO "Ruby" "v${ruby_ver}"
    fi

    # ── Lua ───────────────────────────────────────────────────────────────────────
    if command -v lua &>/dev/null || command -v lua5.4 &>/dev/null; then
        local lua_cmd
        command -v lua5.4 &>/dev/null && lua_cmd="lua5.4" || lua_cmd="lua"
        local lua_ver
        lua_ver="$("$lua_cmd" -v 2>&1 | grep -oP '[\d]+\.[\d.]+' | head -1 || echo '?')"
        _check_report $CHECK_PASS "Lua" "v${lua_ver}  (needed by Neovim)"
    else
        _check_report $CHECK_WARN "Lua" "not installed"
    fi

    # ── LuaJIT ───────────────────────────────────────────────────────────────────
    if command -v luajit &>/dev/null; then
        local luajit_ver
        luajit_ver="$(luajit -v 2>&1 | grep -oP '[\d]+\.[\d.]+' | head -1 || echo '?')"
        _check_report $CHECK_PASS "LuaJIT" "v${luajit_ver}"
    fi

    # ── Zig ──────────────────────────────────────────────────────────────────────
    if command -v zig &>/dev/null; then
        local zig_ver
        zig_ver="$(zig version 2>/dev/null || echo '?')"
        _check_report $CHECK_INFO "Zig" "v${zig_ver}"
    fi

    # ── Haskell ───────────────────────────────────────────────────────────────────
    if command -v ghc &>/dev/null; then
        local ghc_ver
        ghc_ver="$(ghc --version 2>/dev/null | grep -oP '[\d]+\.[\d.]+' | head -1 || echo '?')"
        _check_report $CHECK_INFO "GHC (Haskell)" "v${ghc_ver}"
    fi

    # ── Elixir ────────────────────────────────────────────────────────────────────
    if command -v elixir &>/dev/null; then
        local elixir_ver
        elixir_ver="$(elixir --version 2>/dev/null | grep -oP '[\d]+\.[\d.]+' | head -1 || echo '?')"
        _check_report $CHECK_INFO "Elixir" "v${elixir_ver}"
    fi

    # ── Version managers ─────────────────────────────────────────────────────────
    local -a version_managers=(
        "nvm:Node Version Manager"
        "rbenv:Ruby Env"
        "pyenv:Python Env"
        "asdf:ASDF (polyglot)"
        "mise:mise (modern asdf)"
        "fnm:Fast Node Manager"
        "volta:Volta (Node manager)"
    )

    for vm_entry in "${version_managers[@]}"; do
        IFS=':' read -r cmd label <<< "$vm_entry"
        if command -v "$cmd" &>/dev/null; then
            local vm_ver
            vm_ver="$("$cmd" --version 2>/dev/null | \
                      grep -oP '[\d]+\.[\d.]+' | head -1 || echo 'installed')"
            _check_report $CHECK_INFO "VM: ${label}" "v${vm_ver}"
        fi
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 07 — MISSING PACKAGES REPORT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_dep_report() {
    local total=$(( _DEP_PASS + _DEP_WARN + _DEP_FAIL ))
    local pass_pct=0
    (( total > 0 )) && pass_pct=$(( _DEP_PASS * 100 / total ))

    # Bar
    local bar_w=40
    local filled=$(( pass_pct * bar_w / 100 ))
    local empty=$(( bar_w - filled ))
    local bar=""
    local i
    for (( i=0; i<filled; i++ )); do bar+='█'; done
    for (( i=0; i<empty;  i++ )); do bar+='░'; done

    local bar_color
    if   (( pass_pct >= 90 )); then bar_color=$'\033[38;2;166;227;161m'
    elif (( pass_pct >= 75 )); then bar_color=$'\033[38;2;249;226;175m'
    else                            bar_color=$'\033[38;2;243;139;168m'
    fi

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;137;180;250m'
        printf '  ╔══════════════════════════════════════════════════════════╗\n'
        printf '  ║  📦  DEPENDENCY HEALTH REPORT                            ║\n'
        printf '  ╠══════════════════════════════════════════════════════════╣\n'
        printf '  ║  %s%s\033[0m\033[1;38;2;137;180;250m  %3d%%                              ║\n' \
            "$bar_color" "$bar" "$pass_pct"
        printf '  ║  \033[38;2;166;227;161m%-4d satisfied\033[38;2;137;180;250m  •  ' "$_DEP_PASS"
        printf '\033[38;2;108;112;134m%-4d missing/warn\033[38;2;137;180;250m  •  ' "$_DEP_WARN"
        printf '\033[38;2;243;139;168m%-4d critical\033[38;2;137;180;250m    ║\n' "$_DEP_FAIL"
        printf '  ╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n  DEPENDENCY HEALTH: %d/%d satisfied (%d%%)\n' \
            "$_DEP_PASS" "$total" "$pass_pct"
    fi

    # ── Missing critical packages one-liner ───────────────────────────────────────
    if [[ ${#_DEP_MISSING_PKGS[@]} -gt 0 ]]; then
        printf '\n'
        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
            printf '\033[1;38;2;243;139;168m  🚨 CRITICAL MISSING PACKAGES:\033[0m\n'
        else
            printf '  CRITICAL MISSING:\n'
        fi

        for pkg in "${_DEP_MISSING_PKGS[@]}"; do
            printf '    • %s\n' "$pkg"
        done

        printf '\n'
        local install_cmd="paru -S ${_DEP_MISSING_PKGS[*]}"
        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
            printf '  \033[38;2;166;227;161mQuick install:\033[0m\n'
            printf '  \033[38;2;116;199;236m$\033[0m  \033[38;2;205;214;244m%s\033[0m\n\n' \
                "$install_cmd"
        else
            printf '  Quick install:\n  $ %s\n\n' "$install_cmd"
        fi
    fi

    # ── Broken deps ───────────────────────────────────────────────────────────────
    if [[ ${#_DEP_BROKEN[@]} -gt 0 ]]; then
        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
            printf '\033[1;38;2;249;226;175m  ⚠️  BROKEN DEPENDENCIES:\033[0m\n'
        else
            printf '  BROKEN:\n'
        fi
        for b in "${_DEP_BROKEN[@]}"; do
            printf '    • %s\n' "$b"
        done
        printf '\n'
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_check_dependencies() {
    local mode="${1:-full}"

    _CHECK_PASS_COUNT=0;  _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0;  _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=();   _CHECK_WARNINGS=()
    _DEP_PASS=0; _DEP_WARN=0; _DEP_FAIL=0
    _DEP_MISSING_PKGS=(); _DEP_BROKEN=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;137;180;250m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  📦  ASH DOCTOR — DEPENDENCIES CHECK                     ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  pacman • shared libs • Python • Node • Rust • runtimes  ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n=== ASH DOCTOR — DEPENDENCIES CHECK ===\n'
    fi

    case "$mode" in
        quick)
            _chk_dep_pacman
            _chk_dep_shared_libs
            ;;
        python)    _chk_dep_python    ;;
        node)      _chk_dep_node      ;;
        rust)      _chk_dep_rust      ;;
        libs)      _chk_dep_shared_libs ;;
        pacman)    _chk_dep_pacman    ;;
        full|*)
            _chk_dep_pacman
            _chk_dep_shared_libs
            _chk_dep_python
            _chk_dep_node
            _chk_dep_rust
            _chk_dep_runtimes
            ;;
    esac

    _chk_dep_report
    _ash_check_system_summary
}

ash_check_dependencies_quick() {
    local issues=0

    # Quick pacman check
    [[ -f /var/lib/pacman/db.lck ]] && (( issues++ )) || true

    # Quick lib check
    ldconfig -p 2>/dev/null | grep -q 'libwayland-client' || (( issues++ )) || true
    ldconfig -p 2>/dev/null | grep -q 'libpipewire'       || (( issues++ )) || true

    if (( issues == 0 )); then
        ash_log_success "Dependencies: OK  (pacman healthy  •  critical libs present)"
    else
        ash_log_warn "Dependencies: ${issues} issue(s) — run 'ash doctor full --deps'"
        return 1
    fi
}
