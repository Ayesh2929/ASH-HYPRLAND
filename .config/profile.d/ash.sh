#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — PROFILE.D SCRIPT                             ║
# ║           Loaded by login shell for environment setup                      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

# Only run once per login session
if [[ -n "${ASH_PROFILE_LOADED:-}" ]]; then
    return 0
fi
export ASH_PROFILE_LOADED=1

# ══════════════════════════════════════════════════════════════════════════════
# 📁 PATH ADDITIONS
# ══════════════════════════════════════════════════════════════════════════════

# User binaries
[[ -d "${HOME}/.local/bin" ]] && export PATH="${HOME}/.local/bin:${PATH}"

# Dotfiles bin
[[ -d "${HOME}/.dotfiles/bin" ]] && export PATH="${HOME}/.dotfiles/bin:${PATH}"

# Cargo (Rust)
[[ -d "${HOME}/.cargo/bin" ]] && export PATH="${HOME}/.cargo/bin:${PATH}"

# Go
[[ -d "${HOME}/go/bin" ]] && export PATH="${HOME}/go/bin:${PATH}"

# ══════════════════════════════════════════════════════════════════════════════
# 🖥️ WAYLAND AUTO-START
# ══════════════════════════════════════════════════════════════════════════════

# Auto-start Hyprland on TTY1 login (optional)
# Uncomment to enable:
# if [[ -z "${DISPLAY}" ]] && [[ -z "${WAYLAND_DISPLAY}" ]]; then
#     if [[ "$(tty)" == "/dev/tty1" ]]; then
#         if command -v Hyprland &>/dev/null; then
#             exec Hyprland
#         fi
#     fi
# fi

# ══════════════════════════════════════════════════════════════════════════════
# 🔐 SSH AGENT
# ══════════════════════════════════════════════════════════════════════════════

# Start SSH agent if not running
if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
    if command -v ssh-agent &>/dev/null; then
        eval "$(ssh-agent -s)" > /dev/null 2>&1
    fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# 🎨 WAYLAND ENVIRONMENT
# ══════════════════════════════════════════════════════════════════════════════

# Set Wayland-related variables early
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM="wayland;xcb"
export QT_QPA_PLATFORMTHEME="qt6ct"
export GDK_BACKEND="wayland,x11"
export ELECTRON_OZONE_PLATFORM_HINT="auto"
export SDL_VIDEODRIVER="wayland"

# ══════════════════════════════════════════════════════════════════════════════
# 🔧 DEFAULT PROGRAMS
# ══════════════════════════════════════════════════════════════════════════════

export EDITOR="nvim"
export VISUAL="nvim"
export BROWSER="firefox"
export TERMINAL="kitty"
export PAGER="less"

# ══════════════════════════════════════════════════════════════════════════════
# 📦 XDG BASE DIRECTORIES
# ══════════════════════════════════════════════════════════════════════════════

export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_STATE_HOME="${HOME}/.local/state"

# ══════════════════════════════════════════════════════════════════════════════
# 🎯 ASH VARIABLES
# ══════════════════════════════════════════════════════════════════════════════

export ASH_DOTFILES="${HOME}/.dotfiles"
export ASH_VERSION="3.0.0"
export ASH_CACHE="${HOME}/.cache/ash-dots"