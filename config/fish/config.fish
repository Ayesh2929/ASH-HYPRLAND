#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║   ░█████╗░░██████╗██╗░░██╗  ███████╗██╗░██████╗██╗░░██╗                        ║
# ║   ██╔══██╗██╔════╝██║░░██║  ██╔════╝██║██╔════╝██║░░██║                        ║
# ║   ███████║╚█████╗░███████║  █████╗░░██║╚█████╗░███████║                        ║
# ║   ██╔══██║░╚═══██╗██╔══██║  ██╔══╝░░██║░╚═══██╗██╔══██║                        ║
# ║   ██║░░██║██████╔╝██║░░██║  ██║░░░░░██║██████╔╝██║░░██║                        ║
# ║   ╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝  ╚═╝░░░░░╚═╝╚═════╝░╚═╝░░╚═╝                        ║
# ║                                                                                  ║
# ║   🐟 ASH DOTFILES v5.0 OMEGA — Fish Shell Configuration                        ║
# ║   ⚡ Ultra-optimized • AI-native • Theme-aware • Performance-first              ║
# ║                                                                                  ║
# ║   Author  : Ash Dotfiles Project                                                 ║
# ║   Version : 5.0.0-omega                                                         ║
# ║   License : MIT                                                                  ║
# ║   Repo    : github.com/ash-dotfiles/omega                                       ║
# ║                                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🚀 PERFORMANCE GUARD — Skip non-interactive shells instantly
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
status is-interactive || exit 0


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ⏱️  STARTUP TIMER — Measure shell init performance
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -g __ash_fish_start_time (date +%s%N 2>/dev/null || echo 0)


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🏠 XDG BASE DIRECTORIES — Strict specification compliance
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -q XDG_CONFIG_HOME  || set -gx XDG_CONFIG_HOME  "$HOME/.config"
set -q XDG_DATA_HOME    || set -gx XDG_DATA_HOME    "$HOME/.local/share"
set -q XDG_CACHE_HOME   || set -gx XDG_CACHE_HOME   "$HOME/.cache"
set -q XDG_STATE_HOME   || set -gx XDG_STATE_HOME   "$HOME/.local/state"
set -q XDG_RUNTIME_DIR  || set -gx XDG_RUNTIME_DIR  "/run/user/(id -u)"

# ASH-specific XDG-compliant paths
set -gx ASH_HOME         "$XDG_DATA_HOME/ash"
set -gx ASH_CONFIG       "$XDG_CONFIG_HOME/ash"
set -gx ASH_CACHE        "$XDG_CACHE_HOME/ash"
set -gx ASH_STATE        "$XDG_STATE_HOME/ash"
set -gx ASH_LOGS         "$XDG_STATE_HOME/ash/logs"
set -gx ASH_PLUGINS      "$ASH_HOME/plugins"
set -gx ASH_THEMES       "$ASH_HOME/themes"
set -gx ASH_SNAPSHOTS    "$ASH_HOME/snapshots"
set -gx ASH_PROFILES     "$ASH_HOME/profiles"
set -gx ASH_VERSION      "5.0.0-omega"

# Fish-specific XDG paths
set -gx FISH_CONFIG_DIR  "$XDG_CONFIG_HOME/fish"
set -gx FISH_DATA_DIR    "$XDG_DATA_HOME/fish"
set -gx FISH_CACHE_DIR   "$XDG_CACHE_HOME/fish"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📂 DIRECTORY BOOTSTRAP — Ensure required dirs exist
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
for __dir in \
    $ASH_HOME $ASH_CONFIG $ASH_CACHE $ASH_STATE $ASH_LOGS \
    $ASH_PLUGINS $ASH_THEMES $ASH_SNAPSHOTS $ASH_PROFILES \
    $XDG_STATE_HOME/bash $XDG_STATE_HOME/less \
    $FISH_CACHE_DIR/completions $FISH_DATA_DIR/generated_completions
    test -d $__dir || command mkdir -p $__dir 2>/dev/null
end
set -e __dir


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ⚡ CONF.D LOADER — Source all modular configuration files
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# conf.d files are auto-sourced by Fish in alphabetical order.
# This section handles any that need explicit control or ordering.
# Most configuration lives in: $FISH_CONFIG_DIR/conf.d/
#
# Load order is guaranteed by numeric prefixes (00- through 99-):
#   00-09 → Core environment (XDG, PATH, env vars)
#   10-19 → Aliases & abbreviations
#   20-39 → Tool integrations (fzf, zoxide, starship, etc.)
#   40-49 → Language runtimes (rust, go, python, node, etc.)
#   99    → Local overrides (gitignored)


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 CORE SHELL OPTIONS — Fine-tuned Fish behavior
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Greeting ──────────────────────────────────────────────────────────────────
# Disabled here; handled by functions/fish_greeting.fish for full UI control
set -g fish_greeting ""

# ── History ───────────────────────────────────────────────────────────────────
set -g fish_history_max     100000          # Maximum history entries
set -g fish_history_file    "$FISH_DATA_DIR/fish_history"

# ── Completion behavior ───────────────────────────────────────────────────────
set -g fish_complete_path   $FISH_DATA_DIR/generated_completions \
                            $FISH_CONFIG_DIR/completions \
                            $FISH_DATA_DIR/completions

# ── Pager ─────────────────────────────────────────────────────────────────────
set -g fish_pager_color_progress        brblack   # Pager progress indicator
set -g fish_pager_color_background                # Default background
set -g fish_pager_color_prefix          cyan      # Matched prefix highlight
set -g fish_pager_color_completion      white     # Completion text
set -g fish_pager_color_description     brblack   # Description text
set -g fish_pager_color_selected_background  --background=brblack
set -g fish_pager_color_selected_prefix       cyan
set -g fish_pager_color_selected_completion   white

# ── Vi mode ───────────────────────────────────────────────────────────────────
# Enabled via fish_user_key_bindings.fish; cursor shape per mode
set -g fish_cursor_default      block
set -g fish_cursor_insert       line
set -g fish_cursor_replace_one  underscore
set -g fish_cursor_visual       block


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🌈 FISH COLOR SCHEME — Synchronized with ASH theme engine
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Colors are overridden dynamically by ash-cli theme engine via:
#   $ASH_CONFIG/fish/active-theme.fish → sourced below
# These defaults match Catppuccin Mocha (fallback theme)

set -g fish_color_normal              cdd6f4   # Default text
set -g fish_color_command             89b4fa   # Commands
set -g fish_color_keyword             cba6f7   # Keywords (if, for, while)
set -g fish_color_quote               a6e3a1   # Quoted strings
set -g fish_color_redirection         f38ba8   # Redirections (>, >>)
set -g fish_color_end                 fab387   # Statement terminators (;, &)
set -g fish_color_error               f38ba8   # Errors
set -g fish_color_param               cdd6f4   # Parameters
set -g fish_color_comment             6c7086   # Comments
set -g fish_color_selection           --background=313244   # Selected text
set -g fish_color_search_match        f5c2e7   # Search matches
set -g fish_color_operator            89dceb   # Operators
set -g fish_color_escape              eba0ac   # Escape sequences
set -g fish_color_cwd                 89b4fa   # Current directory in prompt
set -g fish_color_cwd_root            f38ba8   # Root cwd color
set -g fish_color_valid_path          --underline  # Valid path underlining
set -g fish_color_autosuggestion      6c7086   # Autosuggestion ghost text
set -g fish_color_user                a6e3a1   # Username in prompt
set -g fish_color_host                89b4fa   # Hostname in prompt
set -g fish_color_host_remote         eba0ac   # Remote hostname
set -g fish_color_status              f38ba8   # Exit status
set -g fish_color_match               f5c2e7   # Matching parentheses
set -g fish_color_cancel              f38ba8   # Canceled operations

# ── Dynamic theme override ─────────────────────────────────────────────────────
set __ash_fish_theme "$ASH_CONFIG/fish/active-theme.fish"
test -f $__ash_fish_theme && source $__ash_fish_theme
set -e __ash_fish_theme


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🛤️  PATH CONSTRUCTION — Deduplicated, ordered, fast
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Fish handles PATH deduplication via fish_add_path (uses fish_user_paths)
# This ensures idempotency across re-sources.

# ── User local binaries ────────────────────────────────────────────────────────
fish_add_path --prepend --path "$HOME/.local/bin"
fish_add_path --prepend --path "$HOME/bin"
fish_add_path --prepend --path "$ASH_HOME/bin"

# ── System snap/flatpak ────────────────────────────────────────────────────────
test -d "/snap/bin"                       && fish_add_path "/snap/bin"
test -d "/var/lib/flatpak/exports/bin"    && fish_add_path "/var/lib/flatpak/exports/bin"
test -d "$HOME/.local/share/flatpak/exports/bin" \
    && fish_add_path "$HOME/.local/share/flatpak/exports/bin"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🌍 CORE ENVIRONMENT VARIABLES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Editor hierarchy ──────────────────────────────────────────────────────────
set -gx EDITOR      nvim
set -gx VISUAL      nvim
set -gx GIT_EDITOR  nvim
set -gx SUDO_EDITOR nvim

# ── Pager ─────────────────────────────────────────────────────────────────────
set -gx PAGER       less
set -gx MANPAGER    "sh -c 'col -bx | bat -l man -p'"  # bat-powered man pages
set -gx LESS        "--RAW-CONTROL-CHARS --quit-if-one-screen --no-init \
                     --ignore-case --LONG-PROMPT --tabs=4 --mouse \
                     --wheel-lines=3"
set -gx LESSHISTFILE "$XDG_STATE_HOME/less/history"

# ── Terminal ──────────────────────────────────────────────────────────────────
set -gx TERMINAL    kitty
set -gx TERM        xterm-256color

# ── Browser ───────────────────────────────────────────────────────────────────
if command -sq firefox
    set -gx BROWSER firefox
else if command -sq chromium
    set -gx BROWSER chromium
end

# ── Locale ────────────────────────────────────────────────────────────────────
set -gx LANG     en_US.UTF-8
set -gx LC_ALL   en_US.UTF-8
set -gx LC_CTYPE en_US.UTF-8

# ── Color support ─────────────────────────────────────────────────────────────
set -gx COLORTERM truecolor
set -gx TERM_PROGRAM_VERSION (fish --version 2>&1 | string match -r '\d+\.\d+\.\d+')
set -gx CLICOLOR  1
set -gx CLICOLOR_FORCE 0

# ── Man page colors via less/terminfo ─────────────────────────────────────────
set -gx LESS_TERMCAP_mb (printf "\e[01;31m")   # Begin blinking
set -gx LESS_TERMCAP_md (printf "\e[01;36m")   # Begin bold
set -gx LESS_TERMCAP_me (printf "\e[0m")        # End mode
set -gx LESS_TERMCAP_se (printf "\e[0m")        # End standout-mode
set -gx LESS_TERMCAP_so (printf "\e[01;44;33m") # Begin standout-mode
set -gx LESS_TERMCAP_ue (printf "\e[0m")        # End underline
set -gx LESS_TERMCAP_us (printf "\e[01;32m")   # Begin underline

# ── Ripgrep ───────────────────────────────────────────────────────────────────
set -gx RIPGREP_CONFIG_PATH "$XDG_CONFIG_HOME/ripgrep/config"

# ── FZF global defaults ───────────────────────────────────────────────────────
set -gx FZF_DEFAULT_COMMAND  "fd --type f --hidden --follow --exclude .git"
set -gx FZF_DEFAULT_OPTS     "
    --height=60%
    --min-height=20
    --layout=reverse
    --border=rounded
    --border-label=' 🔍 ASH Search '
    --border-label-pos=3
    --info=inline
    --prompt=' '
    --pointer='▶'
    --marker='✓'
    --preview-window=right:55%:border-left
    --bind='ctrl-/:toggle-preview'
    --bind='ctrl-a:select-all'
    --bind='ctrl-d:deselect-all'
    --bind='ctrl-f:page-down'
    --bind='ctrl-b:page-up'
    --bind='alt-j:preview-down'
    --bind='alt-k:preview-up'
    --bind='ctrl-y:execute-silent(echo -n {+} | wl-copy 2>/dev/null)'
    --bind='ctrl-e:execute(\$EDITOR {} >/dev/tty)'
    --bind='?:toggle-preview'
    --color='bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8'
    --color='fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc'
    --color='marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8'
    --color='border:#313244,label:#cba6f7,preview-border:#313244'
    --ansi"
set -gx FZF_CTRL_T_COMMAND  $FZF_DEFAULT_COMMAND
set -gx FZF_ALT_C_COMMAND   "fd --type d --hidden --follow --exclude .git"
set -gx FZF_CTRL_T_OPTS     "
    --preview='bat --style=numbers,changes --color=always --line-range=:300 {} 2>/dev/null \
               || eza --tree --color=always --icons {} 2>/dev/null \
               || cat {}'
    --header='  CTRL-/ toggle preview • CTRL-Y copy path'"
set -gx FZF_ALT_C_OPTS      "
    --preview='eza --tree --color=always --icons --level=3 {}'
    --header='  ALT-C cd into directory'"

# ── bat (better cat) ──────────────────────────────────────────────────────────
set -gx BAT_THEME         "ash-dynamic"
set -gx BAT_PAGER         "less -R"
set -gx BAT_STYLE         "numbers,changes,header-filename,rule,snip"

# ── eza (better ls) ───────────────────────────────────────────────────────────
set -gx EZA_ICONS_AUTO    1
set -gx EZA_COLORS        "da=36:di=34;1:fi=0:ln=35:ex=32;1:*.zip=33:*.tar=33"

# ── Zoxide ────────────────────────────────────────────────────────────────────
set -gx _ZO_DATA_DIR      "$XDG_DATA_HOME/zoxide"
set -gx _ZO_ECHO          1
set -gx _ZO_EXCLUDE_DIRS  "$HOME:$HOME/Downloads"
set -gx _ZO_FZF_OPTS      "$FZF_DEFAULT_OPTS --height=50% --no-preview"

# ── Docker ────────────────────────────────────────────────────────────────────
set -gx DOCKER_BUILDKIT      1
set -gx COMPOSE_DOCKER_CLI_BUILD 1
set -gx DOCKER_CONFIG        "$XDG_CONFIG_HOME/docker"

# ── Kubernetes ────────────────────────────────────────────────────────────────
set -gx KUBECONFIG           "$XDG_CONFIG_HOME/kube/config"
set -gx KUBECTL_EXTERNAL_DIFF "dyff between --omit-header --set-exit-code"

# ── Terraform ─────────────────────────────────────────────────────────────────
set -gx TF_CLI_ARGS_plan     "-compact-warnings"
set -gx TF_LOG_PATH          "$ASH_LOGS/terraform.log"

# ── GPG ───────────────────────────────────────────────────────────────────────
set -gx GNUPGHOME            "$XDG_DATA_HOME/gnupg"
set -gx GPG_TTY              (tty)

# ── SSH ───────────────────────────────────────────────────────────────────────
set -gx SSH_AUTH_SOCK        "$XDG_RUNTIME_DIR/ssh-agent.socket"

# ── History deduplication helpers ─────────────────────────────────────────────
set -gx HISTCONTROL          "ignoreboth:erasedups"

# ── Atuin shell history ───────────────────────────────────────────────────────
set -gx ATUIN_CONFIG_DIR     "$XDG_CONFIG_HOME/atuin"
set -gx ATUIN_DATA_DIR       "$XDG_DATA_HOME/atuin"
set -gx ATUIN_SESSION        (uuidgen 2>/dev/null || echo "ash-session")

# ── Wakatime ──────────────────────────────────────────────────────────────────
set -gx WAKATIME_HOME        "$XDG_CONFIG_HOME/wakatime"

# ── Go ────────────────────────────────────────────────────────────────────────
set -gx GOPATH               "$XDG_DATA_HOME/go"
set -gx GOMODCACHE           "$XDG_CACHE_HOME/go/mod"
set -gx GOTELEMETRY          off

# ── Cargo / Rust ──────────────────────────────────────────────────────────────
set -gx CARGO_HOME           "$XDG_DATA_HOME/cargo"
set -gx RUSTUP_HOME          "$XDG_DATA_HOME/rustup"
set -gx CARGO_NET_GIT_FETCH_WITH_CLI true

# ── Node / npm ────────────────────────────────────────────────────────────────
set -gx NPM_CONFIG_USERCONFIG  "$XDG_CONFIG_HOME/npm/npmrc"
set -gx NPM_CONFIG_CACHE       "$XDG_CACHE_HOME/npm"
set -gx NPM_CONFIG_PREFIX      "$HOME/.local"
set -gx NVM_DIR                "$XDG_DATA_HOME/nvm"
set -gx PNPM_HOME              "$XDG_DATA_HOME/pnpm"
set -gx BUN_INSTALL            "$XDG_DATA_HOME/bun"

# ── Python ────────────────────────────────────────────────────────────────────
set -gx PYTHONSTARTUP          "$XDG_CONFIG_HOME/python/pythonstartup.py"
set -gx PYTHONPYCACHEPREFIX    "$XDG_CACHE_HOME/python"
set -gx PYTHONUSERBASE         "$HOME/.local"
set -gx VIRTUAL_ENV_PROMPT     ""  # Let starship handle this
set -gx UV_CACHE_DIR           "$XDG_CACHE_HOME/uv"
set -gx PYENV_ROOT             "$XDG_DATA_HOME/pyenv"

# ── Java ──────────────────────────────────────────────────────────────────────
set -gx JAVA_TOOL_OPTIONS  "-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java"
set -gx _JAVA_OPTIONS      "-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true"
set -gx GRADLE_USER_HOME   "$XDG_DATA_HOME/gradle"
set -gx MAVEN_OPTS         "-Dmaven.repo.local=$XDG_CACHE_HOME/maven/repository"

# ── Ansible ───────────────────────────────────────────────────────────────────
set -gx ANSIBLE_HOME           "$XDG_DATA_HOME/ansible"
set -gx ANSIBLE_CONFIG         "$XDG_CONFIG_HOME/ansible/ansible.cfg"

# ── AWS CLI ───────────────────────────────────────────────────────────────────
set -gx AWS_CONFIG_FILE        "$XDG_CONFIG_HOME/aws/config"
set -gx AWS_SHARED_CREDENTIALS_FILE "$XDG_CONFIG_HOME/aws/credentials"

# ── LS Colors ─────────────────────────────────────────────────────────────────
set -gx LS_COLORS \
    "di=1;34:ln=35:so=32:pi=33:ex=1;32:bd=34;46:cd=34;43:su=30;41:sg=30;46:\
     tw=30;42:ow=34;42:*.tar=1;31:*.tgz=1;31:*.zip=1;31:*.gz=1;31:*.bz2=1;31:\
     *.jpg=35:*.jpeg=35:*.png=35:*.gif=35:*.webp=35:*.svg=35:\
     *.mp4=36:*.mkv=36:*.mp3=36:*.flac=36:\
     *.py=33:*.rs=1;33:*.go=36:*.ts=34:*.lua=34:*.sh=32:\
     *.json=33:*.toml=33:*.yaml=33:*.yml=33:*.conf=33:\
     *.md=37:*.txt=37:*.pdf=35:\
     *.db=31:*.sqlite=31:\
     *.lock=90:*.log=90:*.bak=90"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🌊 WAYLAND / HYPRLAND ENVIRONMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if test -n "$WAYLAND_DISPLAY"
    # ── XDG session type ──────────────────────────────────────────────────────
    set -gx XDG_SESSION_TYPE         wayland
    set -gx XDG_SESSION_DESKTOP      Hyprland
    set -gx XDG_CURRENT_DESKTOP      Hyprland

    # ── Qt Wayland ────────────────────────────────────────────────────────────
    set -gx QT_QPA_PLATFORM          "wayland;xcb"
    set -gx QT_WAYLAND_DISABLE_WINDOWDECORATION 1
    set -gx QT_QPA_PLATFORMTHEME     qt6ct
    set -gx QT_AUTO_SCREEN_SCALE_FACTOR 1
    set -gx QT_ENABLE_HIGHDPI_SCALING 1

    # ── GTK Wayland ───────────────────────────────────────────────────────────
    set -gx GDK_BACKEND              "wayland,x11"
    set -gx CLUTTER_BACKEND          wayland

    # ── SDL Wayland ───────────────────────────────────────────────────────────
    set -gx SDL_VIDEODRIVER          wayland

    # ── Mozilla / Firefox ────────────────────────────────────────────────────
    set -gx MOZ_ENABLE_WAYLAND       1
    set -gx MOZ_DBUS_REMOTE          1

    # ── Java AWT ─────────────────────────────────────────────────────────────
    set -gx _JAVA_AWT_WM_NONREPARENTING 1
    set -gx AWT_TOOLKIT              MToolkit

    # ── Electron ─────────────────────────────────────────────────────────────
    set -gx ELECTRON_OZONE_PLATFORM_HINT wayland

    # ── Chromium ─────────────────────────────────────────────────────────────
    set -gx CHROMIUM_FLAGS           "--ozone-platform=wayland --enable-features=WaylandWindowDecorations"

    # ── Clipboard ─────────────────────────────────────────────────────────────
    set -gx CLIPBOARD_MANAGER        cliphist
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎮 GPU / DISPLAY ACCELERATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── AMD GPU ───────────────────────────────────────────────────────────────────
if test -d "/dev/dri" && lspci 2>/dev/null | grep -qi "AMD/ATI"
    set -gx LIBVA_DRIVER_NAME        radeonsi
    set -gx VDPAU_DRIVER             radeonsi
    set -gx AMD_VULKAN_ICD           RADV
    set -gx MESA_DISK_CACHE_SINGLE_FILE 1
end

# ── NVIDIA GPU ────────────────────────────────────────────────────────────────
if command -sq nvidia-smi
    set -gx __GL_GSYNC_ALLOWED       0
    set -gx __GL_VRR_ALLOWED         0
    set -gx LIBVA_DRIVER_NAME        nvidia
    set -gx __GLX_VENDOR_LIBRARY_NAME nvidia
    set -gx GBM_BACKEND              nvidia-drm
    set -gx WLR_NO_HARDWARE_CURSORS  1
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔌 TOOL INTEGRATIONS — Lazy & conditional initialization
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Each tool is only initialized if installed.
# Heavy tools use deferred loading via __ash_lazy_init pattern.

# ── Starship prompt ───────────────────────────────────────────────────────────
if command -sq starship
    set -gx STARSHIP_CONFIG    "$XDG_CONFIG_HOME/starship/starship.toml"
    set -gx STARSHIP_CACHE     "$XDG_CACHE_HOME/starship"
    set -gx STARSHIP_LOG       "error"
    starship init fish | source
end

# ── Zoxide (smart cd) ─────────────────────────────────────────────────────────
if command -sq zoxide
    zoxide init fish --cmd cd | source
end

# ── fzf key bindings ─────────────────────────────────────────────────────────
if command -sq fzf
    fzf --fish | source 2>/dev/null
    # Override fzf defaults set above (belt-and-suspenders)
    bind \ct '__fzf_search_current_dir'
    bind \cr '__fzf_search_history'
    bind \ec '__fzf_search_directory'
end

# ── Atuin (shell history) ────────────────────────────────────────────────────
if command -sq atuin
    atuin init fish --disable-up-arrow | source
end

# ── Direnv ────────────────────────────────────────────────────────────────────
if command -sq direnv
    direnv hook fish | source
end

# ── Thefuck ───────────────────────────────────────────────────────────────────
if command -sq thefuck
    thefuck --alias fk | source
end

# ── Conda / Mamba ─────────────────────────────────────────────────────────────
if test -f "$HOME/miniconda3/etc/fish/conf.d/conda.fish"
    source "$HOME/miniconda3/etc/fish/conf.d/conda.fish"
else if test -f "$HOME/mambaforge/etc/fish/conf.d/mamba.fish"
    source "$HOME/mambaforge/etc/fish/conf.d/mamba.fish"
end

# ── Pyenv ─────────────────────────────────────────────────────────────────────
if test -d $PYENV_ROOT
    fish_add_path "$PYENV_ROOT/bin" "$PYENV_ROOT/shims"
    status --is-interactive && pyenv init - fish | source
end

# ── PNPM ──────────────────────────────────────────────────────────────────────
if test -d $PNPM_HOME
    fish_add_path $PNPM_HOME
end

# ── Bun ───────────────────────────────────────────────────────────────────────
if test -d $BUN_INSTALL
    fish_add_path "$BUN_INSTALL/bin"
    test -f "$BUN_INSTALL/_bun" && source "$BUN_INSTALL/_bun"
end

# ── Deno ──────────────────────────────────────────────────────────────────────
if test -d "$XDG_DATA_HOME/deno"
    set -gx DENO_INSTALL "$XDG_DATA_HOME/deno"
    fish_add_path "$DENO_INSTALL/bin"
end

# ── Cargo / Rust binaries ─────────────────────────────────────────────────────
test -d "$CARGO_HOME/bin" && fish_add_path "$CARGO_HOME/bin"

# ── Go binaries ───────────────────────────────────────────────────────────────
test -d "$GOPATH/bin" && fish_add_path "$GOPATH/bin"

# ── Lua Language Server ───────────────────────────────────────────────────────
test -d "$HOME/.local/lib/lua-language-server/bin" \
    && fish_add_path "$HOME/.local/lib/lua-language-server/bin"

# ── Gem (Ruby) ────────────────────────────────────────────────────────────────
if command -sq ruby
    set -gx GEM_HOME "$XDG_DATA_HOME/gem"
    set -gx GEM_SPEC_CACHE "$XDG_CACHE_HOME/gem"
    fish_add_path "$GEM_HOME/bin"
end

# ── Mcfly (smart history) ─────────────────────────────────────────────────────
if command -sq mcfly
    set -gx MCFLY_KEY_SCHEME vim
    set -gx MCFLY_FUZZY 2
    set -gx MCFLY_RESULTS 50
    set -gx MCFLY_INTERFACE_VIEW BOTTOM
    mcfly init fish | source
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🪄 ABBREVIATIONS — Expand-on-space, fully visible history
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Core abbreviations are defined here; language-specific ones live in conf.d/
# Abbreviations expand in-place — prefer them over aliases for discoverability.

# ── Git core ─────────────────────────────────────────────────────────────────
abbr -a g       git
abbr -a ga      git add
abbr -a gaa     git add --all
abbr -a gapa    git add --patch
abbr -a gb      git branch
abbr -a gba     git branch --all
abbr -a gbd     git branch --delete
abbr -a gbD     git branch --delete --force
abbr -a gc      git commit --verbose
abbr -a gcm     git commit --message
abbr -a gca     git commit --all --verbose
abbr -a gcam    git commit --all --message
abbr -a gcf     git commit --fixup
abbr -a gcl     git clone --recurse-submodules
abbr -a gco     git checkout
abbr -a gcob    git checkout -b
abbr -a gcp     git cherry-pick
abbr -a gd      git diff
abbr -a gds     git diff --staged
abbr -a gf      git fetch --all --prune
abbr -a gl      git pull
abbr -a glog    git log --oneline --decorate --graph --all
abbr -a gm      git merge
abbr -a gmom    git merge origin/main
abbr -a gp      git push
abbr -a gpf     git push --force-with-lease
abbr -a gpsup   git push --set-upstream origin (git branch --show-current)
abbr -a gr      git remote
abbr -a grb     git rebase
abbr -a grbi    git rebase --interactive
abbr -a grbm    git rebase main
abbr -a grh     git reset HEAD
abbr -a grhh    git reset HEAD --hard
abbr -a grs     git restore
abbr -a grss    git restore --staged
abbr -a gs      git status --short --branch
abbr -a gst     git stash
abbr -a gstp    git stash pop
abbr -a gstd    git stash drop
abbr -a gstl    git stash list
abbr -a gsw     git switch
abbr -a gswc    git switch --create
abbr -a gt      git tag
abbr -a gunwip  git log -n 1 --format=%s | grep -q "\-\-wip\-\-" && git reset HEAD~1

# ── Docker core ───────────────────────────────────────────────────────────────
abbr -a d       docker
abbr -a dc      docker compose
abbr -a dcu     docker compose up
abbr -a dcud    docker compose up --detach
abbr -a dcd     docker compose down
abbr -a dcl     docker compose logs --follow
abbr -a dce     docker compose exec
abbr -a dps     docker ps
abbr -a dpsa    docker ps --all
abbr -a dex     docker exec --interactive --tty
abbr -a dim     docker images
abbr -a drm     docker rm
abbr -a drmi    docker rmi
abbr -a dprune  docker system prune --all --volumes

# ── Kubernetes core ──────────────────────────────────────────────────────────
abbr -a k       kubectl
abbr -a kg      kubectl get
abbr -a kd      kubectl describe
abbr -a kl      kubectl logs --follow
abbr -a ke      kubectl exec --stdin --tty
abbr -a ka      kubectl apply --filename
abbr -a kdl     kubectl delete
abbr -a kns     kubectl config set-context --current --namespace
abbr -a kctx    kubectl config use-context
abbr -a kgp     kubectl get pods --all-namespaces
abbr -a kgs     kubectl get services
abbr -a kgn     kubectl get nodes

# ── System shortcuts ──────────────────────────────────────────────────────────
abbr -a s       sudo
abbr -a se      sudoedit
abbr -a sv      sudo nvim
abbr -a mkdir   mkdir --parents --verbose
abbr -a cp      cp --interactive --verbose
abbr -a mv      mv --interactive --verbose
abbr -a rm      rm --interactive=once --verbose
abbr -a ln      ln --interactive --verbose
abbr -a df      df --human-readable
abbr -a du      du --human-readable --summarize
abbr -a free    free --human
abbr -a pgrep   pgrep --list-name
abbr -a pkill   pkill --echo

# ── Neovim ────────────────────────────────────────────────────────────────────
abbr -a v       nvim
abbr -a vi      nvim
abbr -a vim     nvim
abbr -a nv      nvim
abbr -a svim    sudo nvim
abbr -a vz      nvim "$FISH_CONFIG_DIR/config.fish"
abbr -a vhp     nvim "$XDG_CONFIG_HOME/hypr/hyprland.conf"

# ── Package management (Arch) ─────────────────────────────────────────────────
if command -sq paru
    abbr -a pac    paru
    abbr -a pacs   paru -S
    abbr -a pacr   paru -Rns
    abbr -a pacu   paru -Syu
    abbr -a paci   paru -Qi
    abbr -a pacl   paru -Qe
    abbr -a pacc   paru -Sc
    abbr -a paco   paru -Qdt
else if command -sq yay
    abbr -a pac    yay
    abbr -a pacs   yay -S
    abbr -a pacr   yay -Rns
    abbr -a pacu   yay -Syu
else if command -sq pacman
    abbr -a pac    sudo pacman
    abbr -a pacs   sudo pacman -S
    abbr -a pacr   sudo pacman -Rns
    abbr -a pacu   sudo pacman -Syu
end

# ── ASH CLI shortcuts ─────────────────────────────────────────────────────────
abbr -a at      ash theme
abbr -a ata     ash theme apply
abbr -a atp     ash theme pick
abbr -a atr     ash theme random
abbr -a am      ash mode
abbr -a amg     ash mode game
abbr -a amf     ash mode focus
abbr -a amw     ash mode work
abbr -a ap      ash plugin
abbr -a api     ash plugin install
abbr -a apl     ash plugin list
abbr -a ass     ash snapshot
abbr -a assc    ash snapshot create
abbr -a assr    ash snapshot restore
abbr -a assl    ash snapshot list
abbr -a ad      ash doctor
abbr -a au      ash update all
abbr -a ahw     ash hw full-report
abbr -a aai     ash ai chat

# ── Misc quality of life ──────────────────────────────────────────────────────
abbr -a cl      clear
abbr -a q       exit
abbr -a :q      exit
abbr -a path    echo $PATH | tr : '\n' | nl
abbr -a reload  exec fish
abbr -a pubip   curl -s ifconfig.me
abbr -a ports   ss -tulpn
abbr -a week    date +%V
abbr -a now     date +'%Y-%m-%d %H:%M:%S'
abbr -a epoch   date +%s


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔗 ALIASES — When abbreviations aren't appropriate
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Aliases are for tool substitutions with default flags, not abbreviations.
# They don't expand in-place (invisible in history) — use sparingly.

# ── Modern Unix tool replacements ─────────────────────────────────────────────
if command -sq eza
    alias ls     "eza --icons --group-directories-first --color=always"
    alias ll     "eza --icons --group-directories-first --color=always --long --header --git"
    alias la     "eza --icons --group-directories-first --color=always --long --header --git --all"
    alias lt     "eza --icons --group-directories-first --color=always --tree --level=3"
    alias lta    "eza --icons --group-directories-first --color=always --tree --level=3 --all"
    alias l      "eza --icons --group-directories-first --color=always --oneline"
else
    alias ls     "ls --color=always --group-directories-first --human-readable"
    alias ll     "ls --color=always --group-directories-first --human-readable -l"
    alias la     "ls --color=always --group-directories-first --human-readable -la"
end

command -sq bat  && alias cat  "bat --style=plain"
command -sq bat  && alias catn "bat"
command -sq fd   && alias find "fd"
command -sq rg   && alias grep "rg --smart-case"
command -sq htop && ! command -sq btop && alias top htop
command -sq btop && alias top  "btop"
command -sq procs && alias ps  "procs"
command -sq dust && alias du   "dust"
command -sq duf  && alias df   "duf"
command -sq delta && alias diff "delta"
command -sq gping && alias ping "gping"
command -sq tldr && alias man  "tldr"
command -sq zellij && alias ta "zellij attach"

# ── lazygit / lazydocker ──────────────────────────────────────────────────────
command -sq lazygit    && alias lg    "lazygit"
command -sq lazydocker && alias lzd   "lazydocker"

# ── Clipboard (Wayland) ───────────────────────────────────────────────────────
if command -sq wl-copy
    alias pbcopy   "wl-copy"
    alias pbpaste  "wl-paste"
    alias xclip    "wl-copy"
    alias xsel     "wl-paste"
end

# ── Python shortcuts ──────────────────────────────────────────────────────────
alias python       "python3"
alias pip          "pip3"
alias venv         "python3 -m venv"
alias activate     "source .venv/bin/activate.fish"
alias deactivate   "deactivate"

# ── Safety nets ───────────────────────────────────────────────────────────────
alias chmod        "chmod --verbose"
alias chown        "chown --verbose"

# ── Hyprland shortcuts ────────────────────────────────────────────────────────
command -sq hyprctl && alias hypr-reload "hyprctl reload && echo '✓ Hyprland config reloaded'"
command -sq hyprctl && alias hypr-info   "hyprctl version && hyprctl monitors"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔑 KEY BINDINGS — Interactive keybinds beyond fzf/atuin defaults
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Complex bindings live in functions/fish_user_key_bindings.fish
# Simple binds defined here for discoverability

# ── Yazi file manager ─────────────────────────────────────────────────────────
# Ctrl-O → open yazi, cd to last directory on exit
if command -sq yazi
    function __ash_yazi_cd
        set -l tmp (mktemp -t "yazi-cwd.XXXXX")
        yazi $argv --cwd-file="$tmp"
        if test -s "$tmp"
            set -l cwd (cat "$tmp")
            test -n "$cwd" && test "$cwd" != "$PWD" && cd "$cwd"
        end
        command rm -f "$tmp"
    end
    bind \co '__ash_yazi_cd; commandline -f repaint'
end

# ── Quick edits ───────────────────────────────────────────────────────────────
bind \cg\cf 'nvim "$FISH_CONFIG_DIR/config.fish"; source "$FISH_CONFIG_DIR/config.fish"'
bind \cg\ch 'nvim "$XDG_CONFIG_HOME/hypr/hyprland.conf"'
bind \cg\cn 'nvim "$XDG_CONFIG_HOME/nvim/init.lua"'
bind \cg\cw 'nvim "$XDG_CONFIG_HOME/waybar/config.jsonc"'

# ── ASH quick actions ─────────────────────────────────────────────────────────
bind \ca\ct 'ash theme pick; commandline -f repaint'
bind \ca\cm 'ash mode status; commandline -f repaint'
bind \ca\cs 'ash snapshot create; commandline -f repaint'


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎪 EVENT HANDLERS — React to Fish events
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Trigger ssh-agent on first interactive shell ───────────────────────────────
function __ash_start_ssh_agent --on-event fish_login
    if not ssh-add -l &>/dev/null
        test -f "$SSH_AUTH_SOCK" || eval (ssh-agent -s -a "$SSH_AUTH_SOCK") &>/dev/null
    end
end

# ── Sync ASH theme state on directory change ──────────────────────────────────
function __ash_on_pwd_change --on-variable PWD
    # Notify direnv and any watchers of directory change
    command -sq direnv && direnv export fish | source 2>/dev/null
end

# ── Virtual environment auto-activate ─────────────────────────────────────────
function __ash_venv_auto_activate --on-variable PWD
    # Activate .venv if present, deactivate when leaving
    set -l venv_path "$PWD/.venv/bin/activate.fish"
    if test -f "$venv_path"
        set -q VIRTUAL_ENV || source "$venv_path"
    else if set -q VIRTUAL_ENV
        # Check if we've left the venv directory
        string match -q "$VIRTUAL_ENV*" "$PWD" || deactivate 2>/dev/null
    end
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔒 PRIVATE MODE — Detect and configure secure environments
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if set -q ASH_PRIVACY_MODE && test "$ASH_PRIVACY_MODE" = "1"
    set -gx HISTFILE            /dev/null
    set -g  fish_history        ""
    set -gx fish_history_max    0
    functions --erase __ash_on_pwd_change  # No tracking in privacy mode
    functions --erase __ash_venv_auto_activate
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📊 STARTUP TELEMETRY — Optional performance logging
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function __ash_log_startup_time --on-event fish_prompt
    # Only runs once on first prompt render
    functions --erase __ash_log_startup_time

    set -l end_time   (date +%s%N 2>/dev/null || echo 0)
    set -l start_time $__ash_fish_start_time

    if test "$start_time" != "0" && test "$end_time" != "0"
        set -l elapsed (math "($end_time - $start_time) / 1000000")
        set -g __ash_fish_startup_ms $elapsed

        # Log if analytics enabled and startup is slow
        if set -q ASH_ANALYTICS && test "$ASH_ANALYTICS" = "1"
            set -l log_entry "{\"event\":\"fish_startup\",\"ms\":$elapsed,\"ts\":(date +%s)}"
            echo $log_entry >> "$ASH_LOGS/startup.jsonl" 2>/dev/null
        end

        # Warn if startup > 500ms
        if test $elapsed -gt 500
            echo "⚠️  Fish startup took {$elapsed}ms — run 'fish --profile /tmp/fish.profile' to diagnose"
        end
    end

    set -e __ash_fish_start_time
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🤖 ASH INTEGRATION — Theme engine & CLI awareness
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Set terminal title with ASH context ──────────────────────────────────────
function fish_title
    set -l cmd (status current-command 2>/dev/null || echo fish)
    set -l dir (prompt_pwd --dir-length 2 2>/dev/null || echo (basename $PWD))
    set -l theme (cat "$ASH_STATE/current-theme" 2>/dev/null || echo "default")

    if test "$cmd" = fish
        echo "🐟 $dir [$theme]"
    else
        echo "⚡ $cmd — $dir"
    end
end

# ── ASH mode indicator for prompt ─────────────────────────────────────────────
function __ash_get_mode
    cat "$ASH_STATE/current-mode" 2>/dev/null || echo "default"
end

# ── Source local overrides (gitignored, machine-specific) ─────────────────────
set __ash_local_config "$FISH_CONFIG_DIR/conf.d/99-local.fish"
test -f $__ash_local_config && source $__ash_local_config
set -e __ash_local_config

# ── Expose ASH version to shell ───────────────────────────────────────────────
set -gx ASH_SHELL    fish
set -gx ASH_SHELL_V  (fish --version 2>&1 | string match -r '\d+\.\d+\.\d+')