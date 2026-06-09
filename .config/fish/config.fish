# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — FISH SHELL MAIN CONFIG                       ║
# ║           Fast, friendly, feature-rich shell configuration                 ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# Load order:
#   1. This file (config.fish)
#   2. conf.d/*.fish (alphabetically sorted — numbered for control)
#   3. functions/*.fish (lazy-loaded on first call)
#   4. completions/*.fish (tab completion)

# ═══════════════════════════════════════════════════════════════════════════════
# ⚡ PERFORMANCE — Only run in interactive sessions
# ═══════════════════════════════════════════════════════════════════════════════

status is-interactive || exit

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 THEME — Source generated colors
# ═══════════════════════════════════════════════════════════════════════════════

if test -f ~/.config/fish/themes/current.fish
    source ~/.config/fish/themes/current.fish
end

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 CORE SETTINGS
# ═══════════════════════════════════════════════════════════════════════════════

# Disable default greeting (custom greeting in functions/fish_greeting.fish)
set -g fish_greeting ""

# Vi mode (change to 'insert' for emacs-style)
# fish_vi_key_bindings
# Use custom keybinds from conf.d/40-keybinds.fish instead

# History settings
set -g fish_history_max 10000
set -g fish_history_merge 1

# ═══════════════════════════════════════════════════════════════════════════════
# 🌊 WAYLAND ENVIRONMENT
# ═══════════════════════════════════════════════════════════════════════════════

# Set Wayland-specific variables if running under Wayland
if test -n "$WAYLAND_DISPLAY"
    # Mozilla Firefox Wayland
    set -gx MOZ_ENABLE_WAYLAND 1
    set -gx MOZ_WAYLAND_USE_VAAPI 1

    # Qt Wayland
    set -gx QT_QPA_PLATFORM "wayland;xcb"
    set -gx QT_WAYLAND_DISABLE_WINDOWDECORATION 1

    # GTK
    set -gx GDK_BACKEND "wayland,x11"

    # SDL
    set -gx SDL_VIDEODRIVER wayland

    # Clutter
    set -gx CLUTTER_BACKEND wayland

    # Electron
    set -gx ELECTRON_OZONE_PLATFORM_HINT auto
end

# ═══════════════════════════════════════════════════════════════════════════════
# 📁 PATH CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

# User binaries (highest priority)
fish_add_path ~/.local/bin
fish_add_path ~/.dotfiles/bin

# Cargo (Rust)
fish_add_path ~/.cargo/bin

# Go
fish_add_path ~/go/bin

# Node.js (nvm-managed)
fish_add_path ~/.nvm/versions/node/*/bin

# Python user installs
fish_add_path ~/.local/lib/python3.*/site-packages/bin 2>/dev/null

# Snap (if installed)
fish_add_path /snap/bin 2>/dev/null

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 DEFAULT PROGRAMS
# ═══════════════════════════════════════════════════════════════════════════════

set -gx EDITOR    nvim
set -gx VISUAL    nvim
set -gx PAGER     less
set -gx BROWSER   firefox
set -gx TERMINAL  kitty
set -gx MANPAGER  "nvim +Man!"

# Less options
set -gx LESS "-R --mouse --wheel-lines=3 --no-init --quit-if-one-screen"
set -gx LESSHISTFILE /dev/null

# ═══════════════════════════════════════════════════════════════════════════════
# 🌈 COLORS FOR TOOLS
# ═══════════════════════════════════════════════════════════════════════════════

# ls colors
set -gx LS_COLORS "di=1;34:ln=1;36:pi=33:so=1;35:do=1;35:bd=33;1:cd=33;1:or=1;31:mi=0;31:ex=1;32:*.tar=0;31:*.zip=0;31:*.jpg=1;35:*.png=1;35:*.mp3=0;36:*.mp4=0;36"

# FZF default options (theme integrated)
set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --follow --exclude .git"
set -gx FZF_DEFAULT_OPTS "
    --height 60%
    --layout reverse
    --border rounded
    --info inline
    --prompt '🔍 '
    --pointer '▶'
    --marker '✓'
    --color 'bg+:#313244,bg:#1e1e2e,spinner:#cba6f7,hl:#89b4fa'
    --color 'fg:#cdd6f4,header:#89b4fa,info:#cba6f7,pointer:#cba6f7'
    --color 'marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#89b4fa'
    --color 'border:#45475a,label:#cba6f7'
    --bind 'ctrl-/:toggle-preview'
    --bind 'ctrl-a:select-all'
    --bind 'ctrl-d:deselect-all'
    --preview-window 'right:55%:border-left'
"

# FZF ctrl+t options (file finder)
set -gx FZF_CTRL_T_COMMAND "${FZF_DEFAULT_COMMAND}"
set -gx FZF_CTRL_T_OPTS "
    --preview 'bat --color=always --style=numbers --line-range :100 {}'
    --preview-window 'right:55%:border-left'
"

# FZF alt+c options (cd into directory)
set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --follow --exclude .git"
set -gx FZF_ALT_C_OPTS "
    --preview 'eza --tree --color=always --icons {} | head -40'
"

# Bat (syntax highlighting)
set -gx BAT_THEME "Catppuccin-mocha"
set -gx BAT_STYLE "numbers,changes,header,grid"

# Ripgrep
set -gx RIPGREP_CONFIG_PATH ~/.config/ripgrep/config

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 TOOL INITIALIZATION
# ═══════════════════════════════════════════════════════════════════════════════

# Starship prompt
if command -v starship > /dev/null
    starship init fish | source
end

# Zoxide (smart cd)
if command -v zoxide > /dev/null
    zoxide init fish | source
end

# Atuin (shell history sync) — optional
if command -v atuin > /dev/null
    atuin init fish | source
end

# NVM (Node Version Manager)
if test -f ~/.nvm/nvm.sh
    bass source ~/.nvm/nvm.sh 2>/dev/null
end

# OPAM (OCaml) — optional
if test -f ~/.opam/opam-init/init.fish
    source ~/.opam/opam-init/init.fish
end

# ═══════════════════════════════════════════════════════════════════════════════
# 📝 ABBREVIATIONS (fast-expanding aliases)
# ═══════════════════════════════════════════════════════════════════════════════
# Full list in conf.d/30-abbr.fish
# Adding here too for visibility

# Quick navigation
abbr -a -- - 'cd -'
abbr -a dotfiles 'cd ~/.dotfiles'
abbr -a dots 'cd ~/.dotfiles'
abbr -a conf 'cd ~/.config'

# ASH CLI shortcuts
abbr -a at   'ash theme'
abbr -a aw   'ash wall'
abbr -a ad   'ash doctor'
abbr -a ar   'ash reload'
abbr -a ab   'ash backup'

# ═══════════════════════════════════════════════════════════════════════════════
# 🐟 FISH-SPECIFIC SETTINGS
# ═══════════════════════════════════════════════════════════════════════════════

# Tab completion settings
set -g fish_complete_path $fish_complete_path ~/.config/fish/completions

# Autosuggest settings
set -g fish_autosuggestion_enabled 1

# Syntax highlighting (set in conf.d/90-prompt.fish)
# set -g fish_color_* values come from themes/current.fish

# Word separators
set -g fish_word_separator ' :/\\@.'

# ═══════════════════════════════════════════════════════════════════════════════
# 🔔 SSH AGENT
# ═══════════════════════════════════════════════════════════════════════════════

# Start ssh-agent if not running
if not set -q SSH_AUTH_SOCK
    eval (ssh-agent -c) > /dev/null
end

# ═══════════════════════════════════════════════════════════════════════════════
# 🖥️ DISPLAY ENVIRONMENT
# ═══════════════════════════════════════════════════════════════════════════════

# Set TERM properly
if test "$TERM" = "xterm"
    set -gx TERM xterm-256color
end

# Kitty integration
if test "$TERM" = "xterm-kitty"
    alias ssh="kitty +kitten ssh"
    alias icat="kitty +kitten icat"
    alias diff="kitty +kitten diff"
end

# ═══════════════════════════════════════════════════════════════════════════════
# 📦 PACKAGE MANAGER SHORTCUTS
# ═══════════════════════════════════════════════════════════════════════════════

# Detect AUR helper
if command -v paru > /dev/null
    set -gx AUR_HELPER paru
else if command -v yay > /dev/null
    set -gx AUR_HELPER yay
end