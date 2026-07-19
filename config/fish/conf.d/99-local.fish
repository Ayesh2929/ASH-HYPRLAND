# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — Local Overrides Ultra (99-local.fish)              ║
# ║  Machine-specific config: last loaded, highest priority, never committed   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_local_loaded && exit 0
set --global _ash_local_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 LOCAL INCLUDE DIRECTORIES                                               ║
# ╔══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_local_dirs \
    "$HOME/.config/fish/local.d" \
    "$HOME/.config/fish/conf.d/local" \
    "$HOME/.local/share/ash/local" \
    "$HOME/.ash-local"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _lo_reset   (set_color normal)
set -g _lo_bold    (set_color --bold)
set -g _lo_cyan    (set_color cyan)
set -g _lo_green   (set_color green)
set -g _lo_yellow  (set_color yellow)
set -g _lo_red     (set_color red)
set -g _lo_dim     (set_color brblack)
set -g _lo_purple  (set_color magenta)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🖥️  HOSTNAME DETECTION: Load machine-specific config                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_hostname  (hostname -s 2>/dev/null; or hostname 2>/dev/null; or echo "unknown")
set --global _ash_fqdn      (hostname -f 2>/dev/null; or echo $_ash_hostname)
set --global _ash_username  $USER
set --global _ash_home_dir  $HOME
set --global _ash_os        (uname -s 2>/dev/null | string lower)
set --global _ash_arch      (uname -m 2>/dev/null)
set --global _ash_distro    ""

# Detect Linux distro
if test -f /etc/os-release
    set _ash_distro (grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 | string trim -c '"')
end

# ── Export for use in local configs ───────────────────────────────────────────
set --export ASH_HOSTNAME  $_ash_hostname
set --export ASH_USERNAME  $_ash_username
set --export ASH_OS        $_ash_os
set --export ASH_ARCH      $_ash_arch
set --export ASH_DISTRO    $_ash_distro

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📂 SOURCE LOCAL CONFIGS: Load in priority order                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_source_local_dir --description "Source all .fish files in a directory"
    set -l dir $argv[1]
    test -d $dir || return 0

    set -l files (ls -1 $dir/*.fish 2>/dev/null | sort)
    for f in $files
        test -f $f || continue
        source $f 2>/dev/null
        and echo $_lo_dim"  [local] sourced: $f"$_lo_reset
        or  echo $_lo_yellow"  [local] ⚠ error: $f"$_lo_reset
    end
end

# Source all local directories
for dir in $_ash_local_dirs
    __ash_source_local_dir $dir
end

# ── Hostname-specific config ───────────────────────────────────────────────────
for hostname_cfg in \
    "$HOME/.config/fish/hosts/$_ash_hostname.fish" \
    "$HOME/.config/fish/hosts/$_ash_fqdn.fish" \
    "$HOME/.ash-local/hosts/$_ash_hostname.fish"
    if test -f $hostname_cfg
        source $hostname_cfg 2>/dev/null
        and echo $_lo_dim"  [local] host config: $hostname_cfg"$_lo_reset
    end
end

# ── Username-specific config ───────────────────────────────────────────────────
for user_cfg in \
    "$HOME/.config/fish/users/$_ash_username.fish" \
    "$HOME/.ash-local/users/$_ash_username.fish"
    if test -f $user_cfg
        source $user_cfg 2>/dev/null
    end
end

# ── Distro-specific config ─────────────────────────────────────────────────────
if test -n "$_ash_distro"
    for distro_cfg in \
        "$HOME/.config/fish/distro/$_ash_distro.fish" \
        "$HOME/.ash-local/distro/$_ash_distro.fish"
        if test -f $distro_cfg
            source $distro_cfg 2>/dev/null
        end
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔧 LOCAL SCAFFOLD: Create local config directory on first run              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function ash-local-init --description "Initialize local override directory"
    set -l local_dir "$HOME/.config/fish/local.d"

    if test -d $local_dir && count $local_dir/*.fish &>/dev/null
        echo $_lo_dim"  Local config already exists: $local_dir"$_lo_reset
        return
    end

    mkdir -p $local_dir
    mkdir -p "$HOME/.config/fish/hosts"
    mkdir -p "$HOME/.config/fish/users"

    # Create template local.fish
    cat > "$local_dir/00-local.fish" << 'LOCALEOF'
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES — Local Overrides                                         ║
# ║  Machine: HOST | User: USER                                                 ║
# ║  This file is NOT tracked by git — add your personal overrides here        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# 📁 PATH ADDITIONS
# ══════════════════════════════════════════════════════════════════════════════

# fish_add_path --prepend --global "$HOME/.local/my-tools/bin"
# fish_add_path --append  --global "/opt/custom-sdk/bin"

# ══════════════════════════════════════════════════════════════════════════════
# 🔑 ENVIRONMENT VARIABLES
# ══════════════════════════════════════════════════════════════════════════════

# Work/Personal variables
# set --export WORK_EMAIL    "you@company.com"
# set --export PERSONAL_EMAIL "you@personal.com"
# set --export COMPANY       "My Company"

# API Keys (prefer a secrets manager like `pass` or `age` instead)
# set --export OPENAI_API_KEY   (cat ~/.secrets/openai-key)
# set --export ANTHROPIC_API_KEY (cat ~/.secrets/anthropic-key)
# set --export GITHUB_TOKEN      (cat ~/.secrets/github-token)

# Cloud credentials
# set --export AWS_PROFILE      "my-profile"
# set --export AWS_DEFAULT_REGION "us-east-1"
# set --export GOOGLE_PROJECT   "my-gcp-project"
# set --export AZURE_SUBSCRIPTION "my-sub-id"

# ══════════════════════════════════════════════════════════════════════════════
# 🎨 ASH OVERRIDES
# ══════════════════════════════════════════════════════════════════════════════

# Override default theme
# ash theme apply catppuccin-mocha 2>/dev/null

# Override default mode
# ash mode work 2>/dev/null

# ══════════════════════════════════════════════════════════════════════════════
# 🔌 TOOL CONFIGURATIONS
# ══════════════════════════════════════════════════════════════════════════════

# Git local config
# git config --global user.name  "Your Name"
# git config --global user.email "you@email.com"
# git config --global core.sshCommand "ssh -i ~/.ssh/work_ed25519"

# Custom proxy settings
# set --export HTTP_PROXY  "http://proxy.company.com:8080"
# set --export HTTPS_PROXY $HTTP_PROXY
# set --export NO_PROXY    "localhost,127.0.0.1,.company.com"

# ══════════════════════════════════════════════════════════════════════════════
# ⌨️  PERSONAL ALIASES & ABBREVIATIONS
# ══════════════════════════════════════════════════════════════════════════════

# abbr --add myalias 'my long command here'
# abbr --add proj    'cd ~/projects'
# abbr --add work    'cd ~/work/my-company'

# ══════════════════════════════════════════════════════════════════════════════
# 🐟 PERSONAL FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

# function my-function --description "My custom function"
#     echo "Hello from local config!"
# end

LOCALEOF

    # Replace placeholders
    sed -i "s/HOST/$_ash_hostname/" "$local_dir/00-local.fish"
    sed -i "s/USER/$_ash_username/" "$local_dir/00-local.fish"

    echo ""
    echo $_lo_green"  ✓ Local config initialized"$_lo_reset
    echo "  "$_lo_dim"Directory: $local_dir"$_lo_reset
    echo "  "$_lo_dim"Template:  $local_dir/00-local.fish"$_lo_reset
    echo ""
    echo "  Edit with: "$_lo_cyan"nvim $local_dir/00-local.fish"$_lo_reset
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📊 LOCAL CONFIG STATUS                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function ash-local-status --description "Show local configuration status"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l purple (set_color magenta)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l yellow (set_color yellow)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$purple"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$purple"  ║     🖥️   Local Configuration Status                  ║"$reset
    echo $bold$purple"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"Hostname: "$reset $cyan$_ash_hostname$reset
    echo "  "$bold"FQDN:     "$reset $dim$_ash_fqdn$reset
    echo "  "$bold"User:     "$reset $cyan$_ash_username$reset
    echo "  "$bold"OS:       "$reset $cyan$_ash_os$reset" ($dim"$_ash_arch$reset")"
    test -n "$_ash_distro" && echo "  "$bold"Distro:   "$reset $cyan$_ash_distro$reset
    echo ""

    echo "  "$bold"Local config directories:"$reset
    for dir in $_ash_local_dirs
        if test -d $dir
            set -l count (count $dir/*.fish 2>/dev/null; or echo 0)
            echo "    "$green"✓ "$reset$dim$dir$reset" ($cyan$count$reset files)"
        else
            echo "    "$dim"○ $dir (not found)"$reset
        end
    end

    echo ""
    echo "  "$bold"Hostname configs:"$reset
    for f in \
        "$HOME/.config/fish/hosts/$_ash_hostname.fish" \
        "$HOME/.config/fish/hosts/$_ash_fqdn.fish"
        if test -f $f
            echo "    "$green"✓ "$reset$dim$f$reset
        end
    end

    echo ""
    echo "  "$bold"ASH State:"$reset
    for state_file in \
        "$HOME/.local/share/ash/state/current-theme.json" \
        "$HOME/.local/share/ash/state/current-mode.json" \
        "$HOME/.local/share/ash/state/node.json"
        if test -f $state_file
            echo "    "$green"✓ "$reset$dim$state_file$reset
        end
    end
    echo ""
end

# ─── ash-local-edit: Quick edit local config ──────────────────────────────────
function ash-local-edit --description "Edit local configuration file"
    set -l local_dir "$HOME/.config/fish/local.d"

    if not test -d $local_dir
        ash-local-init
        return
    end

    set -l files (ls $local_dir/*.fish 2>/dev/null)
    set -l editor (set -q VISUAL && echo $VISUAL || set -q EDITOR && echo $EDITOR || echo nvim)

    if test (count $files) -eq 1
        $editor $files[1]
    else if test (count $files) -gt 1 && command -q fzf
        set -l selected (
            printf '%s\n' $files |
            fzf --border-label "  📝 Edit Local Config " \
                --border rounded \
                --prompt "  " \
                --pointer "▶" \
                --preview "bat --color=always --style=numbers {} 2>/dev/null || cat {}" \
                --preview-window 'right:60%:border-rounded'
        )
        test -n "$selected" && $editor $selected
    else
        ash-local-init
        $editor "$local_dir/00-local.fish"
    end
end

# ─── ash-local-reload: Reload all local configs ────────────────────────────────
function ash-local-reload --description "Reload all local configuration files"
    echo ""
    echo $_lo_cyan"  🔄 Reloading local configurations..."$_lo_reset
    echo ""

    set -l sourced 0

    for dir in $_ash_local_dirs
        test -d $dir || continue
        for f in $dir/*.fish
            test -f $f || continue
            source $f 2>/dev/null
            and begin
                echo "  "$_lo_green"✓ "$f$_lo_reset
                set sourced (math $sourced + 1)
            end
        end
    end

    echo ""
    echo $_lo_green"  ✓ Reloaded $sourced local file(s)"$_lo_reset
    echo ""
end

# ─── ash-local-backup: Backup local configs ────────────────────────────────────
function ash-local-backup --description "Backup local configuration files"
    set -l backup_dir "$HOME/.ash-backups/local-"(date +%Y%m%d%H%M%S)
    mkdir -p $backup_dir

    set -l backed_up 0

    for dir in $_ash_local_dirs
        test -d $dir || continue
        cp -r $dir $backup_dir/ 2>/dev/null
        and set backed_up (math $backed_up + 1)
    end

    echo $_lo_green"  ✓ Local configs backed up: $backup_dir"$_lo_reset
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔧 MACHINE-SPECIFIC DEFAULTS                                               ║
# ║  Sensible defaults that can be overridden in local.d/                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Auto-detect work/personal context from hostname ────────────────────────────
function __ash_local_detect_context --description "Detect work vs personal context"
    # Work patterns: hostname contains work indicators
    for work_pattern in work corp company office dev-machine laptop-work
        string match -qi "*$work_pattern*" $_ash_hostname && echo work && return
    end

    # Check for work-specific files
    test -f "$HOME/.work-profile" && echo work && return

    echo personal
end

set --global ASH_CONTEXT (__ash_local_detect_context)
set --export ASH_CONTEXT $ASH_CONTEXT

# ── Context-specific settings ─────────────────────────────────────────────────
switch $ASH_CONTEXT
    case work
        # Work defaults (can be overridden in local.d/)
        set --export GIT_AUTHOR_EMAIL (
            git config --global user.email 2>/dev/null; or echo ""
        )

        # Longer session timeouts for work
        set --export TMOUT 0

    case personal
        # Personal defaults
        set --export TMOUT 0
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔔 STARTUP NOTIFICATION: Only on first interactive shell                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_local_startup_check --description "Run startup checks on first shell"
    # Only run once per login session
    set -l session_flag "$XDG_RUNTIME_DIR/ash-startup-"(date +%Y%m%d)
    test -f $session_flag && return 0
    touch $session_flag 2>/dev/null

    # Check for pending updates
    set -l update_flag "$HOME/.local/share/ash/state/update-available"
    if test -f $update_flag
        set -l update_info (cat $update_flag 2>/dev/null)
        echo ""
        echo $_lo_yellow"  💡 ASH update available: $update_info"$_lo_reset
        echo "  Run: "$_lo_cyan"ash update all"$_lo_reset
        echo ""
    end

    # Check for failed systemd user services
    if command -q systemctl
        set -l failed (systemctl --user list-units --state=failed --no-legend 2>/dev/null | wc -l | string trim)
        if test "$failed" -gt 0
            echo $_lo_yellow"  ⚠ $failed systemd user service(s) failed"$_lo_reset
            echo "  Run: "$_lo_cyan"systemctl --user list-units --state=failed"$_lo_reset
            echo ""
        end
    end
end

# Run startup check asynchronously (don't block prompt)
__ash_local_startup_check &

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🏁 FINAL INITIALIZATION: Emit ASH ready event                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Set global ready flag
set --global ASH_FISH_LOADED 1
set --global ASH_FISH_LOAD_TIME (date +%s%N 2>/dev/null; or date +%s)

# Emit ASH ready event (plugins/components can listen for this)
emit ash_fish_ready $_ash_hostname

# ── Debug mode: show what's loaded ────────────────────────────────────────────
if set -q ASH_DEBUG && test "$ASH_DEBUG" = 1
    echo ""
    echo $_lo_dim"  [ASH] Fish configuration loaded"$_lo_reset
    echo $_lo_dim"  [ASH] Host: $_ash_hostname | User: $_ash_username | OS: $_ash_os"$_lo_reset
    echo $_lo_dim"  [ASH] Context: $ASH_CONTEXT | Theme: $ASH_THEME_NAME"$_lo_reset
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add local-init   'ash-local-init'
abbr --add local-edit   'ash-local-edit'
abbr --add local-reload 'ash-local-reload'
abbr --add local-status 'ash-local-status'
abbr --add local-backup 'ash-local-backup'

# Quick host info
abbr --add myhost  'echo $ASH_HOSTNAME'
abbr --add myuser  'echo $ASH_USERNAME'
abbr --add myctx   'echo $ASH_CONTEXT'
abbr --add myos    'echo $ASH_OS $ASH_ARCH $ASH_DISTRO'
abbr --add myenv   'ash-local-status'