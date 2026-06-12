#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — DIRECTORY STRUCTURE INITIALIZER              ║
# ║           Creates all required directories for the dotfiles system         ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly HOME_DIR="${HOME}"
readonly CONFIG_DIR="${HOME}/.config"
readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOCAL_DIR="${HOME}/.local"

echo ""
echo "  🏗️  Initializing ASH Dotfiles directory structure..."
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# 📁 CREATE ALL DIRECTORIES
# ═══════════════════════════════════════════════════════════════════════════════

create_dir() {
    local dir="$1"
    if [[ ! -d "${dir}" ]]; then
        mkdir -p "${dir}"
        echo "  → Created: ${dir/$HOME/~}"
    fi
}

# Hyprland
create_dir "${CONFIG_DIR}/hypr/core"
create_dir "${CONFIG_DIR}/hypr/modules"
create_dir "${CONFIG_DIR}/hypr/rules"
create_dir "${CONFIG_DIR}/hypr/scripts/theme"
create_dir "${CONFIG_DIR}/hypr/scripts/media"
create_dir "${CONFIG_DIR}/hypr/scripts/system"
create_dir "${CONFIG_DIR}/hypr/scripts/hardware"
create_dir "${CONFIG_DIR}/hypr/scripts/network"
create_dir "${CONFIG_DIR}/hypr/scripts/utils"
create_dir "${CONFIG_DIR}/hypr/assets/shaders"
create_dir "${CONFIG_DIR}/hypr/assets/sounds"
create_dir "${CONFIG_DIR}/hypr/themes"
create_dir "${CONFIG_DIR}/hypr/UserOverrides"
create_dir "${CONFIG_DIR}/hypr/plugins"

# Waybar
create_dir "${CONFIG_DIR}/waybar/configs"
create_dir "${CONFIG_DIR}/waybar/styles"
create_dir "${CONFIG_DIR}/waybar/scripts/hardware"
create_dir "${CONFIG_DIR}/waybar/scripts/system"
create_dir "${CONFIG_DIR}/waybar/scripts/media"
create_dir "${CONFIG_DIR}/waybar/scripts/network"
create_dir "${CONFIG_DIR}/waybar/scripts/utils"
create_dir "${CONFIG_DIR}/waybar/modules"

# Rofi
create_dir "${CONFIG_DIR}/rofi/themes"
create_dir "${CONFIG_DIR}/rofi/launchers"
create_dir "${CONFIG_DIR}/rofi/powermenu"
create_dir "${CONFIG_DIR}/rofi/scripts"

# Notifications
create_dir "${CONFIG_DIR}/dunst/scripts"
create_dir "${CONFIG_DIR}/swaync"

# Lock/Idle
create_dir "${CONFIG_DIR}/hyprlock/scripts"
create_dir "${CONFIG_DIR}/hyprlock/assets"
create_dir "${CONFIG_DIR}/hypridle"

# Terminals
create_dir "${CONFIG_DIR}/kitty/themes"
create_dir "${CONFIG_DIR}/kitty/kittens"
create_dir "${CONFIG_DIR}/wezterm"
create_dir "${CONFIG_DIR}/alacritty"

# Shell
create_dir "${CONFIG_DIR}/fish/conf.d"
create_dir "${CONFIG_DIR}/fish/functions"
create_dir "${CONFIG_DIR}/fish/completions"
create_dir "${CONFIG_DIR}/fish/themes"

# Neovim
create_dir "${CONFIG_DIR}/nvim/lua/core"
create_dir "${CONFIG_DIR}/nvim/lua/plugins"
create_dir "${CONFIG_DIR}/nvim/lua/lsp"
create_dir "${CONFIG_DIR}/nvim/lua/themes"
create_dir "${CONFIG_DIR}/nvim/lua/utils"
create_dir "${CONFIG_DIR}/nvim/lua/ui"
create_dir "${CONFIG_DIR}/nvim/after/plugin"
create_dir "${CONFIG_DIR}/nvim/snippets"

# Widget Systems
create_dir "${CONFIG_DIR}/ags/modules"
create_dir "${CONFIG_DIR}/ags/services"
create_dir "${CONFIG_DIR}/ags/styles"
create_dir "${CONFIG_DIR}/ags/widgets"
create_dir "${CONFIG_DIR}/eww/dashboard"
create_dir "${CONFIG_DIR}/eww/bar"
create_dir "${CONFIG_DIR}/eww/scripts/system"
create_dir "${CONFIG_DIR}/eww/scripts/media"

# GTK / Qt
create_dir "${CONFIG_DIR}/gtk-2.0"
create_dir "${CONFIG_DIR}/gtk-3.0"
create_dir "${CONFIG_DIR}/gtk-4.0"
create_dir "${CONFIG_DIR}/qt5ct/colors"
create_dir "${CONFIG_DIR}/qt6ct/colors"
create_dir "${CONFIG_DIR}/Kvantum/AshTheme"

# Media
create_dir "${CONFIG_DIR}/mpv/scripts"
create_dir "${CONFIG_DIR}/mpv/script-opts"

# System Tools
create_dir "${CONFIG_DIR}/btop/themes"
create_dir "${CONFIG_DIR}/fastfetch/themes"
create_dir "${CONFIG_DIR}/ripgrep"
create_dir "${CONFIG_DIR}/python"

# Systemd
create_dir "${CONFIG_DIR}/systemd/user"
create_dir "${CONFIG_DIR}/environment.d"

# Cache
create_dir "${CACHE_DIR}/colors"
create_dir "${CACHE_DIR}/wallpaper"
create_dir "${CACHE_DIR}/thumbnails"
create_dir "${CACHE_DIR}/logs"

# State
create_dir "${HOME}/.local/state/ash-dots/sessions"
create_dir "${HOME}/.local/state/ash-dots/theme-history"

# Local
create_dir "${LOCAL_DIR}/bin"
create_dir "${LOCAL_DIR}/share/applications"
create_dir "${LOCAL_DIR}/share/ash-dots/backups"
create_dir "${LOCAL_DIR}/share/ash-dots/themes"

# Wallpapers
create_dir "${HOME}/Pictures/Wallpapers/dark"
create_dir "${HOME}/Pictures/Wallpapers/light"
create_dir "${HOME}/Pictures/Wallpapers/cyberpunk"
create_dir "${HOME}/Pictures/Wallpapers/anime"
create_dir "${HOME}/Pictures/Wallpapers/abstract"
create_dir "${HOME}/Pictures/Wallpapers/nature"
create_dir "${HOME}/Pictures/Wallpapers/landscapes"
create_dir "${HOME}/Pictures/Wallpapers/space"
create_dir "${HOME}/Pictures/Wallpapers/minimal"
create_dir "${HOME}/Pictures/Wallpapers/gradient"

# Screenshots
create_dir "${HOME}/Pictures/Screenshots"
create_dir "${HOME}/Pictures/Recordings"
create_dir "${HOME}/Pictures/ColorPicker"
create_dir "${HOME}/Pictures/Edited"

echo ""
echo "  ✅ Directory structure initialized!"
echo "  Total: $(find "${CONFIG_DIR}" "${CACHE_DIR}" -type d 2>/dev/null | wc -l) directories"
echo ""