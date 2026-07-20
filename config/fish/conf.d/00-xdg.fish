#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ░░░░  XDG BASE DIRECTORY SPECIFICATION  ░░░░                                  ║
# ║                                                                                  ║
# ║  00-xdg.fish — Loaded FIRST in conf.d (alphabetical order)                     ║
# ║  Establishes the entire XDG directory foundation that ALL other                 ║
# ║  configs depend on. Nothing else should run before this.                        ║
# ║                                                                                  ║
# ║  Spec: https://specifications.freedesktop.org/basedir-spec/latest/             ║
# ║  ASH Dotfiles v5.0 OMEGA                                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

# ── Guard: skip non-interactive & already-initialized ─────────────────────────
status is-interactive || exit 0
set -q __ash_xdg_initialized && exit 0
set -g __ash_xdg_initialized 1


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📐 XDG BASE DIRECTORIES — Core Four
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Only set if not already exported by PAM/systemd/pam_env
# Using `set -q` to preserve user overrides

# XDG_CONFIG_HOME — User-specific config files (~/.config)
set -q XDG_CONFIG_HOME \
    || set -gx XDG_CONFIG_HOME "$HOME/.config"

# XDG_DATA_HOME — User-specific data files (~/.local/share)
set -q XDG_DATA_HOME \
    || set -gx XDG_DATA_HOME "$HOME/.local/share"

# XDG_CACHE_HOME — User-specific non-essential data (~/.cache)
set -q XDG_CACHE_HOME \
    || set -gx XDG_CACHE_HOME "$HOME/.cache"

# XDG_STATE_HOME — User-specific state data (~/.local/state) [XDG v0.8+]
set -q XDG_STATE_HOME \
    || set -gx XDG_STATE_HOME "$HOME/.local/state"

# XDG_RUNTIME_DIR — Runtime files (/run/user/UID) [set by PAM in practice]
if not set -q XDG_RUNTIME_DIR
    set -gx XDG_RUNTIME_DIR "/run/user/(id -u)"
    # Create fallback if PAM didn't set it (headless/SSH edge case)
    test -d $XDG_RUNTIME_DIR \
        || command mkdir -p --mode=0700 $XDG_RUNTIME_DIR 2>/dev/null
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📂 XDG USER DIRECTORIES — Desktop integration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Sourced from xdg-user-dirs config; fallback to sane defaults
set -l __xdg_user_dirs_config "$XDG_CONFIG_HOME/user-dirs.dirs"

if test -f $__xdg_user_dirs_config
    # Parse and export; xdg-user-dirs uses sh syntax: VAR="$HOME/..."
    for __line in (grep -v '^#' $__xdg_user_dirs_config | grep '=')
        set -l __key   (string split '=' $__line)[1]
        set -l __value (string split '=' $__line)[2] \
            | string replace -r '^"(.*)"$' '$1' \
            | string replace "\$HOME" $HOME
        set -gx $__key $__value
    end
else
    # Fallback XDG user dirs
    set -gx XDG_DESKTOP_DIR     "$HOME/Desktop"
    set -gx XDG_DOWNLOAD_DIR    "$HOME/Downloads"
    set -gx XDG_TEMPLATES_DIR   "$HOME/Templates"
    set -gx XDG_PUBLICSHARE_DIR "$HOME/Public"
    set -gx XDG_DOCUMENTS_DIR   "$HOME/Documents"
    set -gx XDG_MUSIC_DIR       "$HOME/Music"
    set -gx XDG_PICTURES_DIR    "$HOME/Pictures"
    set -gx XDG_VIDEOS_DIR      "$HOME/Videos"
end

# ASH-specific user dirs (beyond XDG spec)
set -gx ASH_SCREENSHOTS_DIR    "$HOME/Pictures/Screenshots"
set -gx ASH_RECORDINGS_DIR     "$HOME/Videos/Recordings"
set -gx ASH_WALLPAPERS_DIR     "$HOME/Pictures/Wallpapers"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🏠 ASH XDG-COMPLIANT PATHS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -gx ASH_HOME        "$XDG_DATA_HOME/ash"         # Persistent data
set -gx ASH_CONFIG      "$XDG_CONFIG_HOME/ash"        # Configuration
set -gx ASH_CACHE       "$XDG_CACHE_HOME/ash"         # Ephemeral cache
set -gx ASH_STATE       "$XDG_STATE_HOME/ash"         # Runtime state
set -gx ASH_RUNTIME     "$XDG_RUNTIME_DIR/ash"        # Session runtime
set -gx ASH_LOGS        "$XDG_STATE_HOME/ash/logs"    # Log files
set -gx ASH_PLUGINS     "$ASH_HOME/plugins"           # Installed plugins
set -gx ASH_THEMES      "$ASH_HOME/themes"            # Installed themes
set -gx ASH_SNAPSHOTS   "$ASH_HOME/snapshots"         # Config snapshots
set -gx ASH_PROFILES    "$ASH_HOME/profiles"          # User profiles
set -gx ASH_BACKUPS     "$ASH_HOME/backups"           # Backups
set -gx ASH_BIN         "$ASH_HOME/bin"               # ASH executables


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🐟 FISH SHELL XDG PATHS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -gx FISH_CONFIG_DIR  "$XDG_CONFIG_HOME/fish"
set -gx FISH_DATA_DIR    "$XDG_DATA_HOME/fish"
set -gx FISH_CACHE_DIR   "$XDG_CACHE_HOME/fish"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 XDG-COMPLIANT TOOL PATHS — Move tools out of $HOME
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Each block moves a tool's data/config to XDG locations.
# Tools are checked with `command -sq` before setting to avoid
# polluting the environment on machines where they're absent.

# ── Shell histories ───────────────────────────────────────────────────────────
set -gx HISTFILE            "$XDG_STATE_HOME/bash/history"   # bash compat
set -gx LESSHISTFILE        "$XDG_STATE_HOME/less/history"
set -gx SQLITE_HISTORY      "$XDG_STATE_HOME/sqlite/history"
set -gx PSQL_HISTORY        "$XDG_STATE_HOME/psql/history"
set -gx MYSQL_HISTFILE      "$XDG_STATE_HOME/mysql/history"
set -gx PYTHON_HISTORY      "$XDG_STATE_HOME/python/history"
set -gx IPYTHON_DIR         "$XDG_CONFIG_HOME/ipython"

# ── Editors ───────────────────────────────────────────────────────────────────
set -gx VIMINFOPATH         "$XDG_STATE_HOME/vim"
set -gx NVIM_LOG_FILE       "$XDG_STATE_HOME/nvim/log"
set -gx HELIX_RUNTIME       "$XDG_DATA_HOME/helix"

# ── VCS ───────────────────────────────────────────────────────────────────────
set -gx GIT_CEILING_DIRECTORIES "$HOME/tmp:$HOME/Downloads"

# ── Security tools ────────────────────────────────────────────────────────────
set -gx GNUPGHOME           "$XDG_DATA_HOME/gnupg"
set -gx PASSWORD_STORE_DIR  "$XDG_DATA_HOME/pass"
set -gx WGETRC              "$XDG_CONFIG_HOME/wget/wgetrc"
set -gx CURLOPT_CAPATH      "/etc/ssl/certs"

# ── Language runtimes ─────────────────────────────────────────────────────────
# Rust / Cargo
set -gx CARGO_HOME          "$XDG_DATA_HOME/cargo"
set -gx RUSTUP_HOME         "$XDG_DATA_HOME/rustup"
set -gx CARGO_REGISTRIES_CRATES_IO_PROTOCOL sparse  # faster index

# Go
set -gx GOPATH              "$XDG_DATA_HOME/go"
set -gx GOMODCACHE          "$XDG_CACHE_HOME/go/mod"
set -gx GOCACHE             "$XDG_CACHE_HOME/go/build"
set -gx GOTMPDIR            "$XDG_CACHE_HOME/go/tmp"
set -gx GOENV               "$XDG_CONFIG_HOME/go/env"
set -gx GOTELEMETRY         off

# Python
set -gx PYTHONPYCACHEPREFIX "$XDG_CACHE_HOME/python"
set -gx PYTHONUSERBASE      "$HOME/.local"
set -gx PYTHONSTARTUP       "$XDG_CONFIG_HOME/python/pythonstartup.py"
set -gx PYENV_ROOT          "$XDG_DATA_HOME/pyenv"
set -gx VIRTUAL_ENV_DISABLE_PROMPT 1  # Let starship handle it
set -gx PIP_CACHE_DIR       "$XDG_CACHE_HOME/pip"
set -gx PIP_CONFIG_FILE     "$XDG_CONFIG_HOME/pip/pip.conf"
set -gx PIPX_HOME           "$XDG_DATA_HOME/pipx"
set -gx PIPENV_VENV_IN_PROJECT 1       # Create .venv inside project
set -gx UV_CACHE_DIR        "$XDG_CACHE_HOME/uv"
set -gx UV_PYTHON_DOWNLOADS "$XDG_DATA_HOME/uv/pythons"
set -gx MYPY_CACHE_DIR      "$XDG_CACHE_HOME/mypy"
set -gx RUFF_CACHE_DIR      "$XDG_CACHE_HOME/ruff"

# Node / npm / pnpm / bun
set -gx NODE_REPL_HISTORY   "$XDG_STATE_HOME/node/repl_history"
set -gx NPM_CONFIG_USERCONFIG "$XDG_CONFIG_HOME/npm/npmrc"
set -gx NPM_CONFIG_CACHE    "$XDG_CACHE_HOME/npm"
set -gx NPM_CONFIG_PREFIX   "$HOME/.local"
set -gx NPM_CONFIG_INIT_MODULE "$XDG_CONFIG_HOME/npm/npm-init.js"
set -gx NVM_DIR             "$XDG_DATA_HOME/nvm"
set -gx PNPM_HOME           "$XDG_DATA_HOME/pnpm"
set -gx BUN_INSTALL         "$XDG_DATA_HOME/bun"
set -gx DENO_DIR            "$XDG_CACHE_HOME/deno"
set -gx DENO_INSTALL        "$XDG_DATA_HOME/deno"

# Ruby
set -gx GEM_HOME            "$XDG_DATA_HOME/gem"
set -gx GEM_SPEC_CACHE      "$XDG_CACHE_HOME/gem"
set -gx BUNDLE_USER_CONFIG  "$XDG_CONFIG_HOME/bundle"
set -gx BUNDLE_USER_CACHE   "$XDG_CACHE_HOME/bundle"
set -gx BUNDLE_USER_PLUGIN  "$XDG_DATA_HOME/bundle"

# Java / JVM
set -gx JAVA_TOOL_OPTIONS   "-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java"
set -gx GRADLE_USER_HOME    "$XDG_DATA_HOME/gradle"
set -gx MAVEN_OPTS          "-Dmaven.repo.local=$XDG_CACHE_HOME/maven/repository"
set -gx SBT_OPTS            "-Dsbt.global.base=$XDG_DATA_HOME/sbt \
                              -Dsbt.ivy.home=$XDG_CACHE_HOME/ivy2 \
                              -Dsbt.boot.directory=$XDG_CACHE_HOME/sbt/boot"
set -gx COURSIER_CACHE      "$XDG_CACHE_HOME/coursier/v1"
set -gx COURSIER_CONFIG_DIR "$XDG_CONFIG_HOME/coursier"

# .NET
set -gx DOTNET_CLI_HOME     "$XDG_DATA_HOME/dotnet"
set -gx NUGET_PACKAGES      "$XDG_CACHE_HOME/NuGetPackages"

# Haskell / Stack / GHC
set -gx STACK_ROOT          "$XDG_DATA_HOME/stack"
set -gx CABAL_DIR           "$XDG_DATA_HOME/cabal"
set -gx GHCUP_USE_XDG_DIRS  1

# Lua
set -gx LUA_PATH            "$XDG_DATA_HOME/lua/?.lua;;"
set -gx LUAROCKS_HOME       "$XDG_DATA_HOME/luarocks"

# Zig
set -gx ZIG_GLOBAL_CACHE_DIR "$XDG_CACHE_HOME/zig"

# ── DevOps / Cloud tools ──────────────────────────────────────────────────────
# Docker
set -gx DOCKER_CONFIG       "$XDG_CONFIG_HOME/docker"
set -gx MACHINE_STORAGE_PATH "$XDG_DATA_HOME/docker-machine"

# Kubernetes
set -gx KUBECONFIG          "$XDG_CONFIG_HOME/kube/config"
set -gx HELM_CACHE_HOME     "$XDG_CACHE_HOME/helm"
set -gx HELM_CONFIG_HOME    "$XDG_CONFIG_HOME/helm"
set -gx HELM_DATA_HOME      "$XDG_DATA_HOME/helm"
set -gx MINIKUBE_HOME       "$XDG_DATA_HOME/minikube"
set -gx KIND_EXPERIMENTAL_PROVIDER podman  # Use podman if available

# Terraform
set -gx TF_PLUGIN_CACHE_DIR "$XDG_CACHE_HOME/terraform/plugin-cache"
set -gx TF_LOG_PATH         "$XDG_STATE_HOME/ash/logs/terraform.log"
set -gx TERRAGRUNT_CACHE    "$XDG_CACHE_HOME/terragrunt"

# Ansible
set -gx ANSIBLE_HOME        "$XDG_DATA_HOME/ansible"
set -gx ANSIBLE_CONFIG      "$XDG_CONFIG_HOME/ansible/ansible.cfg"

# AWS
set -gx AWS_CONFIG_FILE     "$XDG_CONFIG_HOME/aws/config"
set -gx AWS_SHARED_CREDENTIALS_FILE "$XDG_CONFIG_HOME/aws/credentials"
set -gx AWS_CLI_HISTORY_FILE "$XDG_STATE_HOME/aws/history"

# GCloud
set -gx CLOUDSDK_CONFIG     "$XDG_CONFIG_HOME/gcloud"

# Azure
set -gx AZURE_CONFIG_DIR    "$XDG_CONFIG_HOME/azure"

# Vagrant
set -gx VAGRANT_HOME        "$XDG_DATA_HOME/vagrant"
set -gx VAGRANT_ALIAS_FILE  "$XDG_DATA_HOME/vagrant/aliases"

# ── Shell tools ───────────────────────────────────────────────────────────────
# Atuin
set -gx ATUIN_CONFIG_DIR    "$XDG_CONFIG_HOME/atuin"
set -gx ATUIN_DATA_DIR      "$XDG_DATA_HOME/atuin"

# Zoxide
set -gx _ZO_DATA_DIR        "$XDG_DATA_HOME/zoxide"

# Starship
set -gx STARSHIP_CONFIG     "$XDG_CONFIG_HOME/starship/starship.toml"
set -gx STARSHIP_CACHE      "$XDG_CACHE_HOME/starship"

# Ripgrep
set -gx RIPGREP_CONFIG_PATH "$XDG_CONFIG_HOME/ripgrep/config"

# bat
set -gx BAT_CONFIG_PATH     "$XDG_CONFIG_HOME/bat/config"
set -gx BAT_CONFIG_DIR      "$XDG_CONFIG_HOME/bat"

# fd
set -gx FD_IGNORE           "$XDG_CONFIG_HOME/fd/ignore"

# fzf
set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --follow --exclude .git"

# yazi
set -gx YAZI_CONFIG_HOME    "$XDG_CONFIG_HOME/yazi"

# Mcfly
set -gx MCFLY_HISTFILE      "$XDG_DATA_HOME/fish/fish_history"

# Wakatime
set -gx WAKATIME_HOME       "$XDG_CONFIG_HOME/wakatime"

# ── Multimedia ────────────────────────────────────────────────────────────────
set -gx FFMPEG_DATADIR      "$XDG_DATA_HOME/ffmpeg"
set -gx MPLAYER_HOME        "$XDG_CONFIG_HOME/mplayer"
set -gx MPV_HOME            "$XDG_CONFIG_HOME/mpv"

# ── Misc ──────────────────────────────────────────────────────────────────────
set -gx KDEHOME             "$XDG_DATA_HOME/kde4"
set -gx WINEPREFIX          "$XDG_DATA_HOME/wine"
set -gx SCREENRC            "$XDG_CONFIG_HOME/screen/screenrc"
set -gx READLINE_INPUTRC    "$XDG_CONFIG_HOME/readline/inputrc"
set -gx INPUTRC             "$XDG_CONFIG_HOME/readline/inputrc"
set -gx ERRFILE             "$XDG_CACHE_HOME/X11/xsession-errors"
set -gx ASPELL_CONF         "per-conf $XDG_CONFIG_HOME/aspell/aspell.conf"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📁 DIRECTORY BOOTSTRAP — Create required directories
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Create all required XDG dirs atomically.
# Only dirs that should always exist — NOT tool-specific dirs
# (those are created lazily by the tools themselves or by 01-path.fish)

set -l __xdg_required_dirs \
    $XDG_CONFIG_HOME \
    $XDG_DATA_HOME \
    $XDG_CACHE_HOME \
    $XDG_STATE_HOME \
    $ASH_HOME \
    $ASH_CONFIG \
    $ASH_CACHE \
    $ASH_STATE \
    $ASH_RUNTIME \
    $ASH_LOGS \
    $ASH_PLUGINS \
    $ASH_THEMES \
    $ASH_SNAPSHOTS \
    $ASH_PROFILES \
    $ASH_BACKUPS \
    $ASH_BIN \
    $FISH_CACHE_DIR \
    "$XDG_STATE_HOME/bash" \
    "$XDG_STATE_HOME/less" \
    "$XDG_STATE_HOME/node" \
    "$XDG_STATE_HOME/sqlite" \
    "$XDG_CACHE_HOME/python" \
    "$XDG_CACHE_HOME/go/mod" \
    "$GNUPGHOME" \
    "$ASH_SCREENSHOTS_DIR" \
    "$ASH_RECORDINGS_DIR" \
    "$ASH_WALLPAPERS_DIR"

for __dir in $__xdg_required_dirs
    test -d $__dir || command mkdir -p $__dir 2>/dev/null
end

# GPG requires strict permissions
test -d $GNUPGHOME && command chmod 700 $GNUPGHOME 2>/dev/null

set -e __xdg_required_dirs
set -e __xdg_user_dirs_config
set -e __line __key __value