# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — FISH ENVIRONMENT VARIABLES                   ║
# ║           Core environment setup (loaded first)                             ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# 📁 XDG BASE DIRECTORIES
# ═══════════════════════════════════════════════════════════════════════════════

set -gx XDG_CONFIG_HOME     "$HOME/.config"
set -gx XDG_DATA_HOME       "$HOME/.local/share"
set -gx XDG_CACHE_HOME      "$HOME/.cache"
set -gx XDG_STATE_HOME      "$HOME/.local/state"
set -gx XDG_RUNTIME_DIR     "/run/user/(id -u)"

# XDG User directories
set -gx XDG_DESKTOP_DIR     "$HOME/Desktop"
set -gx XDG_DOWNLOAD_DIR    "$HOME/Downloads"
set -gx XDG_DOCUMENTS_DIR   "$HOME/Documents"
set -gx XDG_PICTURES_DIR    "$HOME/Pictures"
set -gx XDG_MUSIC_DIR       "$HOME/Music"
set -gx XDG_VIDEOS_DIR      "$HOME/Videos"

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 DEFAULT APPLICATIONS
# ═══════════════════════════════════════════════════════════════════════════════

set -gx EDITOR              "nvim"
set -gx VISUAL              "nvim"
set -gx SUDO_EDITOR         "nvim"
set -gx PAGER               "less"
set -gx MANPAGER            "nvim +Man!"
set -gx BROWSER             "firefox"
set -gx TERMINAL            "kitty"

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 TERMINAL & COLORS
# ═══════════════════════════════════════════════════════════════════════════════

# Color support
set -gx COLORTERM            "truecolor"
set -gx TERM_ITALICS         "true"

# Bat configuration
set -gx BAT_THEME            "Catppuccin-mocha"
set -gx BAT_STYLE            "numbers,changes,header-filename,grid"

# Less colors (syntax highlighted man pages via bat)
set -gx LESS                "-R --mouse --wheel-lines=3"
set -gx LESS_TERMCAP_mb     "\e[1;32m"
set -gx LESS_TERMCAP_md     "\e[1;32m"
set -gx LESS_TERMCAP_me     "\e[0m"
set -gx LESS_TERMCAP_se     "\e[0m"
set -gx LESS_TERMCAP_so     "\e[01;33m"
set -gx LESS_TERMCAP_ue     "\e[0m"
set -gx LESS_TERMCAP_us     "\e[1;4;31m"

# ═══════════════════════════════════════════════════════════════════════════════
# 🔨 BUILD TOOLS
# ═══════════════════════════════════════════════════════════════════════════════

# Parallel make jobs (use all CPUs)
set -gx MAKEFLAGS            "-j(nproc)"

# CMake
set -gx CMAKE_GENERATOR      "Ninja"
set -gx CMAKE_EXPORT_COMPILE_COMMANDS 1

# GCC colors
set -gx GCC_COLORS "error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01"

# ═══════════════════════════════════════════════════════════════════════════════
# 🦀 RUST
# ═══════════════════════════════════════════════════════════════════════════════

set -gx CARGO_HOME           "$HOME/.cargo"
set -gx RUSTUP_HOME          "$HOME/.rustup"
set -gx RUST_BACKTRACE       1
set -gx RUSTFLAGS            "-C target-cpu=native"

# ═══════════════════════════════════════════════════════════════════════════════
# 🐹 GO
# ═══════════════════════════════════════════════════════════════════════════════

set -gx GOPATH               "$HOME/go"
set -gx GOBIN                "$HOME/go/bin"
set -gx GOPROXY              "https://proxy.golang.org,direct"
set -gx GONOSUMCHECK         "github.com/*"

# ═══════════════════════════════════════════════════════════════════════════════
# 🐍 PYTHON
# ═══════════════════════════════════════════════════════════════════════════════

set -gx PYTHONSTARTUP        "$HOME/.config/python/startup.py"
set -gx PYTHONDONTWRITEBYTECODE 1
set -gx PYTHONPYCACHEPREFIX  "$HOME/.cache/python"
set -gx PYTHONBREAKPOINT     "ipdb.set_trace"
set -gx PIP_REQUIRE_VIRTUALENV 0

# ═══════════════════════════════════════════════════════════════════════════════
# 📦 NODE.JS
# ═══════════════════════════════════════════════════════════════════════════════

set -gx NVM_DIR              "$HOME/.nvm"
set -gx NODE_REPL_HISTORY    "$HOME/.cache/node_repl_history"
set -gx NPM_CONFIG_PREFIX    "$HOME/.local"
set -gx NPM_CONFIG_CACHE     "$HOME/.cache/npm"

# ═══════════════════════════════════════════════════════════════════════════════
# 🔐 SECURITY & SSH
# ═══════════════════════════════════════════════════════════════════════════════

set -gx GPG_TTY              (tty)
set -gx SSH_AUTH_SOCK        "$XDG_RUNTIME_DIR/ssh-agent.socket"

# ═══════════════════════════════════════════════════════════════════════════════
# 🌐 MISC TOOLS
# ═══════════════════════════════════════════════════════════════════════════════

# Ripgrep config
set -gx RIPGREP_CONFIG_PATH  "$HOME/.config/ripgrep/config"

# Zoxide (smart cd)
set -gx _ZO_DATA_DIR         "$HOME/.local/share/zoxide"
set -gx _ZO_ECHO             1
set -gx _ZO_EXCLUDE_DIRS     "$HOME"

# wget history
set -gx WGETRC               "$HOME/.config/wget/wgetrc"

# ASH specific
set -gx ASH_DOTFILES         "$HOME/.dotfiles"
set -gx ASH_CACHE            "$HOME/.cache/ash-dots"
set -gx ASH_VERSION          "3.0.0"