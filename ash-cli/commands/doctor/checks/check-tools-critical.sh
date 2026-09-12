#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ████████╗ ██████╗  ██████╗ ██╗     ███████╗                                    ║
# ║  ╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝                                    ║
# ║     ██║   ██║   ██║██║   ██║██║     ███████╗                                    ║
# ║     ██║   ██║   ██║██║   ██║██║     ╚════██║                                    ║
# ║     ██║   ╚██████╔╝╚██████╔╝███████╗███████║                                    ║
# ║     ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝                                    ║
# ║                ██████╗██████╗ ██╗████████╗██╗ ██████╗ █████╗ ██╗                 ║
# ║               ██╔════╝██╔══██╗██║╚══██╔══╝██║██╔════╝██╔══██╗██║                 ║
# ║               ██║     ██████╔╝██║   ██║   ██║██║     ███████║██║                 ║
# ║               ██║     ██╔══██╗██║   ██║   ██║██║     ██╔══██║██║                 ║
# ║               ╚██████╗██║  ██║██║   ██║   ██║╚██████╗██║  ██║███████╗            ║
# ║                ╚═════╝╚═╝  ╚═╝╚═╝   ╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝            ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  DOCTOR CHECK: CRITICAL TOOLS                            ║
# ║  Every binary ASH depends on — grouped, versioned, with install hints           ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CHECK_TOOLS_CRITICAL_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CHECK_TOOLS_CRITICAL_LOADED=1

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
# 🔷  TOOL PROBE HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g _TOOLS_PASS=0
declare -g _TOOLS_WARN=0
declare -g _TOOLS_FAIL=0
declare -ga _TOOLS_MISSING_CRITICAL=()
declare -ga _TOOLS_MISSING_OPTIONAL=()

# Probe a single tool
# Args: binary  display_name  package  critical(1|0)  version_flag  min_version
_probe_tool() {
    local binary="$1"
    local display="${2:-$1}"
    local package="${3:-$1}"
    local critical="${4:-1}"
    local ver_flag="${5:---version}"
    local min_ver="${6:-}"

    if command -v "$binary" &>/dev/null; then
        # Get version string
        local ver_raw ver_str
        ver_raw="$("$binary" "$ver_flag" 2>&1 | head -1 || echo '')"
        ver_str="$(printf '%s' "$ver_raw" | grep -oP '[\d]+\.[\d.]+' | head -1 || echo 'installed')"

        # Optional minimum version check
        local ver_note=""
        if [[ -n "$min_ver" ]] && [[ -n "$ver_str" ]] && [[ "$ver_str" != "installed" ]]; then
            local cur_major min_major
            cur_major="${ver_str%%.*}"
            min_major="${min_ver%%.*}"

            if (( cur_major < min_major )); then
                ver_note="  ⚠️  (min ${min_ver} required)"
                _check_report $CHECK_WARN \
                    "${display}" \
                    "v${ver_str}${ver_note}" \
                    "Update: paru -Su ${package}"
                (( _TOOLS_WARN++ )) || true
                return $CHECK_WARN
            fi
        fi

        _check_report $CHECK_PASS \
            "$display" \
            "v${ver_str}"
        (( _TOOLS_PASS++ )) || true
        return $CHECK_PASS

    else
        if [[ "$critical" == "1" ]]; then
            _check_report $CHECK_FAIL \
                "$display" \
                "MISSING  (required)" \
                "Install: paru -S $package"
            _TOOLS_MISSING_CRITICAL+=("$binary")
            (( _TOOLS_FAIL++ )) || true
            return $CHECK_FAIL
        else
            _check_report $CHECK_INFO \
                "$display" \
                "not installed  (optional)" \
                "Install: paru -S $package"
            _TOOLS_MISSING_OPTIONAL+=("$binary")
            return $CHECK_PASS
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 01 — CORE COMPOSITOR STACK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_tools_compositor() {
    _check_header "💎 Core Compositor Stack"

    _probe_tool "Hyprland"      "Hyprland"           "hyprland"            1 "--version"  "0.40"
    _probe_tool "hyprctl"       "hyprctl"            "hyprland"            1 "--version"
    _probe_tool "hyprpm"        "hyprpm"             "hyprland"            1 "--version"
    _probe_tool "waybar"        "Waybar"             "waybar"              1 "--version"  "0.9"
    _probe_tool "swww"          "swww"               "swww"                1 "--version"
    _probe_tool "swww-daemon"   "swww-daemon"        "swww"                1 "--version"
    _probe_tool "hyprlock"      "Hyprlock"           "hyprlock"            1 "--version"
    _probe_tool "hypridle"      "Hypridle"           "hypridle"            1 "--version"
    _probe_tool "rofi"          "Rofi"               "rofi-wayland"        1 "--version"  "1.7"
    _probe_tool "dunst"         "Dunst"              "dunst"               0 "--version"
    _probe_tool "swaync"        "SwayNC"             "swaync"              0 "--version"
    _probe_tool "wlogout"       "Wlogout"            "wlogout"             0 "--version"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 02 — TERMINAL & SHELL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_tools_terminal() {
    _check_header "🖥️  Terminal & Shell"

    _probe_tool "kitty"         "Kitty terminal"     "kitty"               1 "--version"  "0.30"
    _probe_tool "fish"          "Fish shell"         "fish"                1 "--version"  "3.6"
    _probe_tool "bash"          "Bash"               "bash"                1 "--version"  "4.4"
    _probe_tool "starship"      "Starship prompt"    "starship"            1 "--version"  "1.0"
    _probe_tool "zoxide"        "Zoxide"             "zoxide"              1 "--version"
    _probe_tool "fzf"           "fzf"                "fzf"                 1 "--version"  "0.40"
    _probe_tool "atuin"         "Atuin"              "atuin"               0 "--version"
    _probe_tool "wezterm"       "WezTerm"            "wezterm"             0 "--version"
    _probe_tool "foot"          "Foot"               "foot"                0 "--version"
    _probe_tool "tmux"          "Tmux"               "tmux"                0 "-V"
    _probe_tool "zellij"        "Zellij"             "zellij"              0 "--version"
    _probe_tool "fastfetch"     "Fastfetch"          "fastfetch"           1 "--version"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 03 — EDITOR & IDE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_tools_editor() {
    _check_header "📝 Editor & IDE"

    _probe_tool "nvim"          "Neovim"             "neovim"              1 "--version"  "0.9"
    _probe_tool "lazygit"       "LazyGit"            "lazygit"             1 "--version"
    _probe_tool "helix"         "Helix editor"       "helix"               0 "--version"
    _probe_tool "code"          "VS Code"            "visual-studio-code-bin" 0 "--version"
    _probe_tool "zed"           "Zed editor"         "zed"                 0 "--version"
    _probe_tool "micro"         "Micro editor"       "micro"               0 "--version"
    _probe_tool "nano"          "Nano"               "nano"                0 "--version"
    _probe_tool "vim"           "Vim"                "vim"                 0 "--version"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 04 — WAYLAND UTILITIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_tools_wayland() {
    _check_header "🌊 Wayland Utilities"

    _probe_tool "grim"          "Grim  (screenshot)"   "grim"               1 "--version"
    _probe_tool "slurp"         "Slurp  (area select)" "slurp"              1 "--version"
    _probe_tool "wl-copy"       "wl-copy  (clipboard)" "wl-clipboard"       1 "--version"
    _probe_tool "wl-paste"      "wl-paste  (clipboard)" "wl-clipboard"      1 "--version"
    _probe_tool "cliphist"      "Cliphist"             "cliphist"           1 "--version"
    _probe_tool "swappy"        "Swappy  (annotate)"   "swappy"             0 "--version"
    _probe_tool "satty"         "Satty  (annotate)"    "satty"              0 "--version"
    _probe_tool "wf-recorder"   "wf-recorder"          "wf-recorder"        0 "--version"
    _probe_tool "wtype"         "wtype  (input)"       "wtype"              0 "--version"
    _probe_tool "hyprpicker"    "Hyprpicker"           "hyprpicker"         0 "--version"
    _probe_tool "brightnessctl" "brightnessctl"        "brightnessctl"      1 "--version"
    _probe_tool "playerctl"     "playerctl"            "playerctl"          1 "--version"
    _probe_tool "pamixer"       "Pamixer"              "pamixer"            1 "--version"
    _probe_tool "pactl"         "Pactl (PulseAudio)"   "libpulse"           1 "--version"
    _probe_tool "wpctl"         "Wpctl (WirePlumber)"  "wireplumber"        1 "--version"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 05 — FILE & SYSTEM TOOLS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_tools_system() {
    _check_header "⚙️  File & System Tools"

    _probe_tool "eza"           "eza  (ls replacement)"     "eza"           1 "--version"
    _probe_tool "bat"           "bat  (cat replacement)"    "bat"           1 "--version"  "0.22"
    _probe_tool "fd"            "fd  (find replacement)"    "fd"            1 "--version"
    _probe_tool "rg"            "ripgrep"                   "ripgrep"       1 "--version"
    _probe_tool "sd"            "sd  (sed replacement)"     "sd"            0 "--version"
    _probe_tool "delta"         "delta  (diff)"             "git-delta"     0 "--version"
    _probe_tool "yazi"          "Yazi  (file manager)"      "yazi"          0 "--version"
    _probe_tool "lf"            "lf  (file manager)"        "lf"            0 "--version"
    _probe_tool "broot"         "Broot"                     "broot"         0 "--version"
    _probe_tool "jq"            "jq  (JSON)"                "jq"            1 "--version"
    _probe_tool "yq"            "yq  (YAML/JSON)"           "yq"            0 "--version"
    _probe_tool "python3"       "Python 3"                  "python"        1 "--version"  "3.10"
    _probe_tool "curl"          "cURL"                      "curl"          1 "--version"
    _probe_tool "wget"          "Wget"                      "wget"          0 "--version"
    _probe_tool "rsync"         "Rsync"                     "rsync"         1 "--version"
    _probe_tool "btop"          "btop"                      "btop"          1 "--version"
    _probe_tool "htop"          "htop"                      "htop"          0 "--version"
    _probe_tool "ncdu"          "ncdu  (disk usage)"        "ncdu"          0 "--version"
    _probe_tool "duf"           "duf  (disk usage fancy)"   "duf"           0 "--version"
    _probe_tool "tldr"          "tldr  (man pages)"         "tldr"          0 "--version"
    _probe_tool "trash"         "trash-cli"                 "trash-cli"     0 "--version"
    _probe_tool "pv"            "pv  (pipe viewer)"         "pv"            0 "--version"
    _probe_tool "lsb_release"   "lsb_release"               "lsb-release"  0 "--version"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 06 — GIT & DEVELOPMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_tools_dev() {
    _check_header "🛠️  Git & Development"

    _probe_tool "git"           "Git"                "git"                 1 "--version"  "2.40"
    _probe_tool "gh"            "GitHub CLI"         "github-cli"          0 "--version"
    _probe_tool "lazygit"       "LazyGit"            "lazygit"             0 "--version"
    _probe_tool "cargo"         "Rust/Cargo"         "rust"                0 "--version"
    _probe_tool "rustc"         "Rust compiler"      "rust"                0 "--version"
    _probe_tool "go"            "Go"                 "go"                  0 "version"
    _probe_tool "node"          "Node.js"            "nodejs"              0 "--version"  "18"
    _probe_tool "npm"           "npm"                "npm"                 0 "--version"
    _probe_tool "pnpm"          "pnpm"               "pnpm"                0 "--version"
    _probe_tool "bun"           "Bun"                "bun"                 0 "--version"
    _probe_tool "deno"          "Deno"               "deno"                0 "--version"
    _probe_tool "pip"           "pip  (Python)"      "python-pip"          0 "--version"
    _probe_tool "make"          "Make"               "make"                0 "--version"
    _probe_tool "cmake"         "CMake"              "cmake"               0 "--version"
    _probe_tool "meson"         "Meson"              "meson"               0 "--version"
    _probe_tool "ninja"         "Ninja"              "ninja"               0 "--version"
    _probe_tool "gcc"           "GCC"                "gcc"                 0 "--version"
    _probe_tool "clang"         "Clang"              "clang"               0 "--version"
    _probe_tool "docker"        "Docker"             "docker"              0 "--version"
    _probe_tool "podman"        "Podman"             "podman"              0 "--version"
    _probe_tool "kubectl"       "kubectl"            "kubectl"             0 "--version" --client
    _probe_tool "terraform"     "Terraform"          "terraform"           0 "--version"
    _probe_tool "ansible"       "Ansible"            "ansible"             0 "--version"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 07 — PACKAGE MANAGER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_tools_pkgmgr() {
    _check_header "📦 Package Manager"

    # ── AUR helpers ───────────────────────────────────────────────────────────────
    if command -v paru &>/dev/null; then
        local paru_ver
        paru_ver="$(paru --version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo '?')"
        _check_report $CHECK_PASS \
            "paru  (AUR helper)" \
            "v${paru_ver}  ✓ recommended"
        (( _TOOLS_PASS++ )) || true
    else
        _check_report $CHECK_WARN \
            "paru  (AUR helper)" \
            "Not installed" \
            "Install: git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si"
        (( _TOOLS_WARN++ )) || true
    fi

    if command -v yay &>/dev/null; then
        local yay_ver
        yay_ver="$(yay --version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo '?')"
        _check_report $CHECK_INFO \
            "yay  (AUR helper alt)" \
            "v${yay_ver}"
    fi

    # ── System package manager ────────────────────────────────────────────────────
    if command -v pacman &>/dev/null; then
        local pacman_ver
        pacman_ver="$(pacman --version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo '?')"
        _check_report $CHECK_PASS \
            "pacman" \
            "v${pacman_ver}"
        (( _TOOLS_PASS++ )) || true

        # Check for pending updates
        local updates_available=0
        if command -v checkupdates &>/dev/null; then
            local update_count
            update_count="$(checkupdates 2>/dev/null | wc -l || echo 0)"
            if (( update_count > 0 )); then
                _check_report $CHECK_INFO \
                    "Pending updates" \
                    "${update_count} package(s) can be updated" \
                    "Update: paru -Su"
            else
                _check_report $CHECK_PASS \
                    "Pending updates" \
                    "System is up to date"
            fi
        fi

        # Pacman lock file
        if [[ -f /var/lib/pacman/db.lck ]]; then
            _check_report $CHECK_WARN \
                "pacman lock" \
                "/var/lib/pacman/db.lck exists  (another process running?)" \
                "Remove if stale: sudo rm /var/lib/pacman/db.lck"
        fi
    fi

    # ── Flatpak ──────────────────────────────────────────────────────────────────
    _probe_tool "flatpak" "Flatpak" "flatpak" 0 "--version"

    # ── Nix ──────────────────────────────────────────────────────────────────────
    _probe_tool "nix" "Nix" "nix" 0 "--version"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 08 — SECURITY & PRIVACY TOOLS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_tools_security() {
    _check_header "🔒 Security & Privacy Tools"

    _probe_tool "gpg"           "GnuPG"              "gnupg"               1 "--version"
    _probe_tool "ssh"           "SSH client"         "openssh"             1 "-V"
    _probe_tool "sshd"          "SSH daemon"         "openssh"             0 "-V"
    _probe_tool "age"           "age  (encryption)"  "age"                 0 "--version"
    _probe_tool "pass"          "pass  (passwords)"  "pass"                0 "--version"
    _probe_tool "keepassxc-cli" "KeePassXC CLI"      "keepassxc"           0 "--version"
    _probe_tool "wg"            "WireGuard"          "wireguard-tools"     0 "--version"
    _probe_tool "openssl"       "OpenSSL"            "openssl"             1 "version"
    _probe_tool "nmap"          "Nmap"               "nmap"                0 "--version"
    _probe_tool "fail2ban-client" "Fail2ban"         "fail2ban"            0 "--version"
    _probe_tool "rkhunter"      "rkhunter"           "rkhunter"            0 "--version"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 09 — MEDIA & GRAPHICS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_tools_media() {
    _check_header "🎬 Media & Graphics Tools"

    _probe_tool "mpv"           "MPV"                "mpv"                 1 "--version"
    _probe_tool "ffmpeg"        "FFmpeg"             "ffmpeg"              1 "-version"
    _probe_tool "imagemagick"   "ImageMagick"        "imagemagick"         0 "--version"
    _probe_tool "convert"       "convert  (IM)"      "imagemagick"         1 "--version"
    _probe_tool "magick"        "magick  (IM7)"      "imagemagick"         0 "--version"
    _probe_tool "gimp"          "GIMP"               "gimp"                0 "--version"
    _probe_tool "inkscape"      "Inkscape"           "inkscape"            0 "--version"
    _probe_tool "krita"         "Krita"              "krita"               0 "--version"
    _probe_tool "obs"           "OBS Studio"         "obs-studio"          0 "--version"
    _probe_tool "cava"          "CAVA  (visualizer)" "cava"                0 "--version"
    _probe_tool "yt-dlp"        "yt-dlp"             "yt-dlp"              0 "--version"
    _probe_tool "spotdl"        "spotdl"             "python-spotdl"       0 "--version"
    _probe_tool "spicetify"     "Spicetify"          "spicetify-cli"       0 "-v"
    _probe_tool "spotify"       "Spotify"            "spotify"             0 "--version"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 10 — GAMING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_tools_gaming() {
    _check_header "🎮 Gaming Tools"

    _probe_tool "steam"         "Steam"              "steam"               0 "--version"
    _probe_tool "lutris"        "Lutris"             "lutris"              0 "--version"
    _probe_tool "heroic"        "Heroic"             "heroic-games-launcher" 0 "--version"
    _probe_tool "mangohud"      "MangoHUD"           "mangohud"            0 "--version"
    _probe_tool "gamemoded"     "GameMode"           "gamemode"            0 "--version"
    _probe_tool "wine"          "Wine"               "wine"                0 "--version"
    _probe_tool "winetricks"    "Winetricks"         "winetricks"          0 "--version"
    _probe_tool "protonup-qt"   "ProtonUp-Qt"        "protonup-qt"         0 "--version"
    _probe_tool "bottles"       "Bottles"            "bottles"             0 "--version"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 11 — NETWORK TOOLS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_tools_network() {
    _check_header "🌐 Network Tools"

    _probe_tool "ip"            "iproute2  (ip)"     "iproute2"            1 "--version"
    _probe_tool "ss"            "ss  (socket stats)" "iproute2"            1 "--version"
    _probe_tool "ping"          "ping"               "iputils"             1 "--version"
    _probe_tool "dig"           "dig  (DNS)"         "bind"                1 "-v"
    _probe_tool "nslookup"      "nslookup"           "bind"                0 "--version"
    _probe_tool "traceroute"    "traceroute"         "traceroute"          0 "--version"
    _probe_tool "mtr"           "mtr"                "mtr"                 0 "--version"
    _probe_tool "nc"            "netcat"             "openbsd-netcat"      0 "--version"
    _probe_tool "socat"         "socat"              "socat"               0 "--version"
    _probe_tool "iw"            "iw  (WiFi)"         "iw"                  0 "--version"
    _probe_tool "nmcli"         "nmcli  (NM)"        "networkmanager"      0 "--version"
    _probe_tool "bluetoothctl"  "bluetoothctl"       "bluez-utils"         1 "--version"
    _probe_tool "rfkill"        "rfkill"             "util-linux"          0 "--version"
    _probe_tool "speedtest-cli" "speedtest-cli"      "speedtest-cli"       0 "--version"
    _probe_tool "bandwhich"     "bandwhich"          "bandwhich"           0 "--version"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CRITICAL TOOLS SUMMARY TABLE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_tools_final_report() {
    local total=$(( _TOOLS_PASS + _TOOLS_WARN + _TOOLS_FAIL ))

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;203;166;247m'
        printf '  ┌─────────────────────────────────────────────────────────┐\n'
        printf '  │  📊  TOOLS AUDIT SUMMARY                                 │\n'
        printf '  ├─────────────────────────────────────────────────────────┤\n'
        printf '  │  \033[38;2;166;227;161m✓ %-4d installed\033[38;2;203;166;247m  •  \033[38;2;249;226;175m▲ %-4d warn\033[38;2;203;166;247m  •  \033[38;2;243;139;168m✗ %-4d missing\033[38;2;203;166;247m  │\n' \
            "$_TOOLS_PASS" "$_TOOLS_WARN" "$_TOOLS_FAIL"
        printf '  │  %-4d total tools scanned                                │\n' "$total"
        printf '  └─────────────────────────────────────────────────────────┘\033[0m\n'
    else
        printf '\n  TOOLS SUMMARY: %d pass  •  %d warn  •  %d missing  •  %d total\n' \
            "$_TOOLS_PASS" "$_TOOLS_WARN" "$_TOOLS_FAIL" "$total"
    fi

    # ── List critical missing tools with one install command ─────────────────────
    if [[ ${#_TOOLS_MISSING_CRITICAL[@]} -gt 0 ]]; then
        printf '\n'
        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
            printf '\033[1;38;2;243;139;168m  🚨 CRITICAL MISSING TOOLS:\033[0m\n'
        else
            printf '  CRITICAL MISSING:\n'
        fi

        local missing_list
        missing_list="${_TOOLS_MISSING_CRITICAL[*]}"

        printf '  %s\n' "${_TOOLS_MISSING_CRITICAL[@]/#/  • }"
        printf '\n'

        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
            printf '\033[38;2;108;112;134m'
        fi
        printf '  Quick install: paru -S %s\n' \
            "$(printf '%s\n' "${_TOOLS_MISSING_CRITICAL[@]}" | tr '\n' ' ')"
        [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '\033[0m' || true
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_check_tools_critical() {
    local mode="${1:-full}"   # quick | full | compositor | terminal | wayland | dev | media | gaming

    _CHECK_PASS_COUNT=0;  _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0;  _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=();   _CHECK_WARNINGS=()
    _TOOLS_PASS=0;        _TOOLS_WARN=0
    _TOOLS_FAIL=0
    _TOOLS_MISSING_CRITICAL=()
    _TOOLS_MISSING_OPTIONAL=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;250;179;135m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🔧  ASH DOCTOR — CRITICAL TOOLS CHECK                   ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  Compositor • Terminal • Editor • Wayland • Dev • Media  ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n=== ASH DOCTOR — CRITICAL TOOLS CHECK ===\n'
    fi

    case "$mode" in
        quick)
            _chk_tools_compositor
            _chk_tools_terminal
            _chk_tools_wayland
            ;;
        compositor) _chk_tools_compositor ;;
        terminal)   _chk_tools_terminal   ;;
        wayland)    _chk_tools_wayland    ;;
        dev)        _chk_tools_dev        ;;
        media)      _chk_tools_media      ;;
        gaming)     _chk_tools_gaming     ;;
        network)    _chk_tools_network    ;;
        full|*)
            _chk_tools_compositor
            _chk_tools_terminal
            _chk_tools_editor
            _chk_tools_wayland
            _chk_tools_system
            _chk_tools_dev
            _chk_tools_pkgmgr
            _chk_tools_security
            _chk_tools_media
            _chk_tools_gaming
            _chk_tools_network
            ;;
    esac

    _chk_tools_final_report
    _ash_check_system_summary
}

ash_check_tools_critical_quick() {
    local issues=0
    local -a must_have=( "Hyprland" "hyprctl" "waybar" "kitty" "fish" "rofi" "grim" "wl-copy" )
    for bin in "${must_have[@]}"; do
        command -v "$bin" &>/dev/null || (( issues++ )) || true
    done
    if (( issues == 0 )); then
        ash_log_success "Critical tools: OK  (${#must_have[@]}/${#must_have[@]} core binaries present)"
    else
        ash_log_warn "Critical tools: ${issues} missing — run 'ash doctor full --tools'"
        return 1
    fi
}
