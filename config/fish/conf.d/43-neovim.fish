# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — Neovim Ultra Configuration                         ║
# ║  Neovim environment, version switching, plugin management & IDE integration ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_nvim_loaded && exit 0
set --global _ash_nvim_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 DETECTION                                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Support nvim, neovide, and Bob (neovim version manager)
function __ash_nvim_find --description "Find best neovim binary"
    # Bob-managed nvim (takes priority)
    if test -x "$HOME/.local/share/bob/nvim-bin/nvim"
        echo "$HOME/.local/share/bob/nvim-bin/nvim"; return
    end

    # Direct command
    command -q nvim && begin; echo (command -v nvim); return; end

    # Common paths
    for candidate in \
        "/usr/local/bin/nvim" \
        "/opt/nvim/bin/nvim" \
        "$HOME/.local/bin/nvim"
        test -x $candidate && echo $candidate && return
    end

    echo ""
end

set --global _ash_nvim_bin (__ash_nvim_find)

# Exit early if neovim not available at all
if test -z "$_ash_nvim_bin"
    # Still set up aliases for potential later install
    function nvim --description "Neovim not installed"
        echo "  ✗ Neovim not found. Install: curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz"
    end
    exit 0
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_nvim_log        "$HOME/.local/share/ash/logs/nvim.log"
set --global _ash_nvim_cache      "$HOME/.local/share/ash/cache/nvim"
set --global _ash_nvim_config_dir "$HOME/.config/nvim"
set --global _ash_nvim_data_dir   "$HOME/.local/share/nvim"
set --global _ash_nvim_state_dir  "$HOME/.local/state/nvim"
set --global _ash_nvim_cache_dir  "$HOME/.cache/nvim"
set --global _ash_nvim_lazy_lock  "$HOME/.config/nvim/lazy-lock.json"

mkdir -p (dirname $_ash_nvim_log) 2>/dev/null
mkdir -p $_ash_nvim_cache         2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _nv_reset   (set_color normal)
set -g _nv_bold    (set_color --bold)
set -g _nv_cyan    (set_color cyan)
set -g _nv_green   (set_color green)
set -g _nv_yellow  (set_color yellow)
set -g _nv_red     (set_color red)
set -g _nv_blue    (set_color blue)
set -g _nv_purple  (set_color magenta)
set -g _nv_dim     (set_color brblack)
set -g _nv_nvim    (set_color 57A143)   # Neovim green

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  ENVIRONMENT SETUP                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Default editor ────────────────────────────────────────────────────────────
set --export EDITOR  nvim
set --export VISUAL  nvim
set --export MANPAGER "nvim +Man!"
set --export DIFFPROG "nvim -d"

# ── Neovim config directory ────────────────────────────────────────────────────
set --export NVIM_APPNAME nvim   # Default app name

# ── Bob (Neovim version manager) PATH ─────────────────────────────────────────
if test -d "$HOME/.local/share/bob/nvim-bin"
    fish_add_path --prepend --global "$HOME/.local/share/bob/nvim-bin"
end

# ── Neovide (GUI) configuration ───────────────────────────────────────────────
if command -q neovide
    set --export NEOVIDE_MULTIGRID true
    set --export NEOVIDE_FRAME       buttonless
end

# ── Python provider ───────────────────────────────────────────────────────────
if command -q python3
    set --export PYTHON3_HOST_PROG (command -v python3)
end

# ── Node provider ─────────────────────────────────────────────────────────────
if command -q node
    set --export NODE_HOST_PROG (command -v node)
end

# ── Perl provider ─────────────────────────────────────────────────────────────
if command -q perl
    set --export PERL_HOST_PROG (command -v perl)
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🚀 SMART EDITOR FUNCTIONS                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── nvim: Enhanced wrapper with context detection ────────────────────────────
function nvim --wraps='nvim' --description "Smart Neovim launcher"
    set -l args $argv

    # No args: open dashboard (alpha/snacks)
    if test (count $args) -eq 0
        $_ash_nvim_bin
        return
    end

    # Git commit: use minimal config
    if string match -q 'COMMIT_EDITMSG*' $args
        $_ash_nvim_bin -c "setlocal filetype=gitcommit" $args
        return
    end

    # sudoedit: pipe through nvim with sudo
    if test $args[1] = sudo && test (count $args) -ge 3 && test $args[2] = nvim
        command sudo EDITOR=$_ash_nvim_bin VISUAL=$_ash_nvim_bin $args
        return
    end

    # Handle stdin pipe: put content in scratch buffer
    if not isatty stdin
        set -l tmp (mktemp --suffix=.txt)
        cat > $tmp
        $_ash_nvim_bin $tmp $args
        rm -f $tmp
        return
    end

    $_ash_nvim_bin $args
end

# ─── nv: Quick alias variants ─────────────────────────────────────────────────
function nv --wraps='nvim' --description "Neovim shorthand"
    nvim $argv
end

function nvi --description "Open multiple files in splits"
    nvim -o $argv
end

function nvv --description "Open multiple files in vertical splits"
    nvim -O $argv
end

function nvt --description "Open multiple files in tabs"
    nvim -p $argv
end

function nvd --description "Open Neovim as diff tool (2 files)"
    if test (count $argv) -eq 2
        nvim -d $argv
    else
        echo "  Usage: nvd <file1> <file2>"
        return 1
    end
end

function nvr --description "Open Neovim in read-only mode"
    nvim -R $argv
end

# ─── nvim-sudo: Edit file with sudo via nvim ──────────────────────────────────
function nvim-sudo --description "Edit file with root privileges via nvim"
    set -l file $argv[1]
    test -z "$file" && begin; echo "  Usage: nvim-sudo <file>"; return 1; end

    echo $_nv_yellow"  ⚠  Editing with root: $file"$_nv_reset
    sudo EDITOR=$_ash_nvim_bin VISUAL=$_ash_nvim_bin nvim $file
end

# ─── nf: Open file via fzf ────────────────────────────────────────────────────
function nf --description "Fuzzy-find and open file in Neovim"
    command -q fzf || begin; nvim; return; end
    command -q fd  || begin
        set -l file (find . -type f 2>/dev/null | fzf --prompt "  📝 ")
        test -n "$file" && nvim $file
        return
    end

    set -l files (
        fd --type f --hidden --follow \
           --exclude .git --exclude node_modules \
           --exclude .cache --exclude __pycache__ \
           --color always 2>/dev/null |
        fzf --ansi \
            --multi \
            --border-label "  📝 Open in Neovim " \
            --border rounded \
            --prompt "  📝 " \
            --pointer "▶" \
            --marker "✓" \
            --preview 'bat --color=always --style=numbers,changes --line-range=:200 {} 2>/dev/null || cat {}' \
            --preview-window 'right:55%:border-rounded:wrap' \
            --header '  Enter:open  Tab:multi-select  Ctrl-/:preview  ' \
            --bind 'ctrl-/:toggle-preview'
    )

    test -n "$files" && nvim $files
end

# ─── ng: Grep and open at line ────────────────────────────────────────────────
function ng --description "Grep pattern and open result in Neovim at line"
    set -l pattern $argv[1]

    if test -z "$pattern"
        read -P "  Search pattern: " pattern
    end
    test -z "$pattern" && return 1

    command -q rg || begin; echo "  ripgrep not found"; return 1; end
    command -q fzf || begin; rg $pattern; return; end

    set -l result (
        rg --column --line-number --no-heading --color=always --smart-case \
            "$pattern" 2>/dev/null |
        fzf --ansi \
            --border-label "  🔍 Grep: $pattern " \
            --border rounded \
            --prompt "  🔍 " \
            --pointer "▶" \
            --delimiter : \
            --preview 'bat --color=always --style=numbers,changes \
                --highlight-line {2} \
                --line-range (math {2} - 5):(math {2} + 30) \
                {1} 2>/dev/null' \
            --preview-window 'right:55%:border-rounded:wrap' \
            --header '  Enter:open at line  '
    )

    if test -n "$result"
        set -l file (echo $result | cut -d: -f1)
        set -l line (echo $result | cut -d: -f2)
        nvim +"$line" "$file"
    end
end

# ─── ncd: cd to directory and open nvim ───────────────────────────────────────
function ncd --description "Change to directory and open Neovim"
    set -l dir $argv[1]
    test -z "$dir" && set dir .

    if test -d $dir
        cd $dir && nvim
    else
        echo "  Not a directory: $dir"
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔌 PLUGIN MANAGEMENT                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── nvim-lazy: Lazy.nvim plugin operations ────────────────────────────────────
function nvim-lazy --description "Manage Lazy.nvim plugins"
    set -l action $argv[1]
    test -z "$action" && set action sync

    switch $action
        case sync
            echo $_nv_cyan"  🔌 Syncing plugins..."$_nv_reset
            nvim --headless "+Lazy! sync" +qa 2>/dev/null
            and echo $_nv_green"  ✓ Plugins synced"$_nv_reset

        case update up
            echo $_nv_cyan"  🔄 Updating plugins..."$_nv_reset
            nvim --headless "+Lazy! update" +qa 2>/dev/null
            and echo $_nv_green"  ✓ Plugins updated"$_nv_reset

        case install
            echo $_nv_cyan"  📦 Installing plugins..."$_nv_reset
            nvim --headless "+Lazy! install" +qa 2>/dev/null
            and echo $_nv_green"  ✓ Plugins installed"$_nv_reset

        case clean
            echo $_nv_cyan"  🧹 Cleaning unused plugins..."$_nv_reset
            nvim --headless "+Lazy! clean" +qa 2>/dev/null
            and echo $_nv_green"  ✓ Plugins cleaned"$_nv_reset

        case restore
            echo $_nv_cyan"  ⏮ Restoring plugins from lazy-lock.json..."$_nv_reset
            nvim --headless "+Lazy! restore" +qa 2>/dev/null
            and echo $_nv_green"  ✓ Plugins restored from lockfile"$_nv_reset

        case lock
            echo $_nv_cyan"  🔒 Freezing plugin versions..."$_nv_reset
            nvim --headless "+Lazy! lock" +qa 2>/dev/null
            and echo $_nv_green"  ✓ lazy-lock.json updated"$_nv_reset

        case profile
            echo $_nv_cyan"  📊 Running startup profiler..."$_nv_reset
            nvim --headless "+Lazy! profile" +qa 2>/dev/null

        case ls list
            if test -f $_ash_nvim_lazy_lock && command -q jq
                echo ""
                echo $_nv_bold$_nv_nvim"  🔌 Installed Plugins (lazy-lock.json)"$_nv_reset
                echo ""
                jq -r 'to_entries[] | "\(.key)\t\(.value.commit[0:7])"' \
                    $_ash_nvim_lazy_lock 2>/dev/null | \
                while read -l line
                    set -l parts (string split \t $line)
                    printf "  $_nv_cyan%-45s$_nv_reset  $_nv_dim%s$_nv_reset\n" $parts[1] $parts[2]
                end
                echo ""
                set -l count (jq 'keys | length' $_ash_nvim_lazy_lock 2>/dev/null)
                echo "  Total: "$_nv_cyan$count$_nv_reset" plugins"
                echo ""
            else
                nvim --headless "+Lazy! list" +qa 2>/dev/null
            end

        case '*'
            echo "  Usage: nvim-lazy <sync|update|install|clean|restore|lock|ls>"
    end
end

# ─── nvim-mason: Mason LSP/DAP manager ────────────────────────────────────────
function nvim-mason --description "Manage Mason LSP/DAP/Formatter installs"
    set -l action $argv[1]
    test -z "$action" && set action list

    switch $action
        case install
            set -l pkg $argv[2]
            test -z "$pkg" && begin; echo "  Usage: nvim-mason install <package>"; return 1; end
            echo $_nv_cyan"  📦 Installing Mason package: $pkg"$_nv_reset
            nvim --headless "+MasonInstall $pkg" +qa 2>/dev/null

        case update
            echo $_nv_cyan"  🔄 Updating all Mason packages..."$_nv_reset
            nvim --headless "+MasonUpdate" +qa 2>/dev/null
            and echo $_nv_green"  ✓ Mason packages updated"$_nv_reset

        case ls list
            set -l mason_dir "$_ash_nvim_data_dir/mason/packages"
            if test -d $mason_dir
                echo ""
                echo $_nv_bold$_nv_nvim"  🔧 Mason Packages"$_nv_reset
                echo ""
                for pkg_dir in $mason_dir/*/
                    set -l pkg_name (basename $pkg_dir)
                    # Try to get version from package.json
                    set -l version ""
                    if test -f "$pkg_dir/package.json" && command -q jq
                        set version (jq -r '.version // ""' "$pkg_dir/package.json" 2>/dev/null)
                    end
                    printf "  $_nv_green✓$_nv_reset  $_nv_cyan%-35s$_nv_reset  $_nv_dim%s$_nv_reset\n" \
                        $pkg_name $version
                end

                set -l count (count $mason_dir/*/)
                echo ""
                echo "  "$_nv_dim"Total: $count packages"$_nv_reset
                echo ""
            else
                echo $_nv_yellow"  ℹ  Mason data not found at: $mason_dir"$_nv_reset
            end

        case '*'
            echo "  Usage: nvim-mason <list|install|update>"
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔄 VERSION MANAGEMENT (Bob)                                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── nvim-bob: Bob neovim version manager ─────────────────────────────────────
function nvim-bob --description "Bob neovim version manager"
    command -q bob || begin
        echo $_nv_yellow"  💡 Install Bob: cargo install bob-nvim"$_nv_reset
        return 1
    end

    set -l action $argv[1]
    test -z "$action" && set action list

    switch $action
        case ls list
            echo ""
            echo $_nv_bold$_nv_nvim"  🔢 Neovim Versions (Bob)"$_nv_reset
            echo ""
            bob list 2>/dev/null | while read -l line
                if string match -q '*used*' $line
                    echo "  "$_nv_green"▶ "$line$_nv_reset
                else
                    echo "  "$_nv_dim"  "$line$_nv_reset
                end
            end
            echo ""

        case use switch
            set -l version $argv[2]
            if test -z "$version" && command -q fzf
                set version (
                    bob list 2>/dev/null |
                    fzf --border-label "  🔢 Select Neovim Version " \
                        --border rounded \
                        --prompt "  " \
                        --pointer "▶" \
                    | awk '{print $1}'
                )
                test -z "$version" && return 0
            end
            test -z "$version" && begin; echo "  Usage: nvim-bob use <version>"; return 1; end
            bob use $version
            and echo $_nv_green"  ✓ Switched to Neovim $version"$_nv_reset

        case install
            set -l version $argv[2]
            test -z "$version" && set version stable
            echo $_nv_cyan"  📦 Installing Neovim $version..."$_nv_reset
            bob install $version
            and echo $_nv_green"  ✓ Installed: $version"$_nv_reset

        case update
            echo $_nv_cyan"  🔄 Updating to latest Neovim..."$_nv_reset
            bob install nightly 2>/dev/null || bob update 2>/dev/null
            and echo $_nv_green"  ✓ Neovim updated"$_nv_reset

        case stable
            bob use stable 2>/dev/null
            and echo $_nv_green"  ✓ Switched to stable Neovim"$_nv_reset

        case nightly
            bob install nightly 2>/dev/null
            bob use nightly 2>/dev/null
            and echo $_nv_green"  ✓ Switched to nightly Neovim"$_nv_reset

        case erase rm
            set -l version $argv[2]
            test -z "$version" && begin; echo "  Usage: nvim-bob erase <version>"; return 1; end
            bob erase $version
            and echo $_nv_yellow"  ✓ Removed: $version"$_nv_reset

        case '*'
            echo "  Usage: nvim-bob <list|use|install|update|stable|nightly|erase>"
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔧 CONFIG MANAGEMENT                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── nvim-config: Open/manage Neovim config ────────────────────────────────────
function nvim-config --description "Open Neovim configuration"
    set -l target $argv[1]

    switch $target
        case init
            nvim "$_ash_nvim_config_dir/init.lua"

        case plugins
            nvim "$_ash_nvim_config_dir/lua/plugins/"

        case keys keymaps
            nvim "$_ash_nvim_config_dir/lua/core/keymaps.lua"

        case opts options
            nvim "$_ash_nvim_config_dir/lua/core/options.lua"

        case lazy
            nvim "$_ash_nvim_lazy_lock"

        case dir
            cd $_ash_nvim_config_dir && nvim

        case '*'
            # Fuzzy-find config file
            if command -q fzf && test -d $_ash_nvim_config_dir
                set -l cfg_file (
                    fd --type f \
                       --extension lua \
                       --extension vim \
                       --extension toml \
                       . $_ash_nvim_config_dir 2>/dev/null |
                    fzf --ansi \
                        --border-label "  ⚙️  Neovim Config " \
                        --border rounded \
                        --prompt "  📝 " \
                        --pointer "▶" \
                        --preview 'bat --color=always --style=numbers {} 2>/dev/null || cat {}' \
                        --preview-window 'right:55%:border-rounded:wrap'
                )
                test -n "$cfg_file" && nvim $cfg_file
            else
                nvim $_ash_nvim_config_dir
            end
    end
end

# ─── nvim-profile-startup: Benchmark startup time ─────────────────────────────
function nvim-profile-startup --description "Profile Neovim startup time"
    set -l n $argv[1]
    test -z "$n" && set n 10

    echo ""
    echo $_nv_cyan"  ⏱  Benchmarking Neovim startup ($n runs)..."$_nv_reset
    echo ""

    set -l total 0
    set -l min 999999
    set -l max 0

    for i in (seq $n)
        set -l start (date +%s%N 2>/dev/null; or date +%s)000000000
        nvim --headless +qa 2>/dev/null
        set -l end (date +%s%N 2>/dev/null; or date +%s)000000000
        set -l ms (math "($end - $start) / 1000000")

        set total (math $total + $ms)
        test $ms -lt $min && set min $ms
        test $ms -gt $max && set max $ms

        printf "  Run %-3s  %sms\n" $i $ms
    end

    set -l avg (math --scale 1 "$total / $n")

    echo ""
    printf "  $_nv_bold%-12s$_nv_reset  %sms\n" "Average:" $avg
    printf "  $_nv_green%-12s$_nv_reset  %sms\n" "Fastest:" $min
    printf "  $_nv_yellow%-12s$_nv_reset  %sms\n" "Slowest:" $max
    echo ""

    # Grade the startup time
    if test (math "int($avg)") -lt 100
        echo "  "$_nv_green"⚡ Excellent startup time!"$_nv_reset
    else if test (math "int($avg)") -lt 300
        echo "  "$_nv_yellow"✓ Good startup time"$_nv_reset
    else
        echo "  "$_nv_red"⚠ Slow startup — check plugins"$_nv_reset
    end
    echo ""
end

# ─── nvim-check-health: Run checkhealth ───────────────────────────────────────
function nvim-check-health --description "Run Neovim health checks"
    set -l module $argv[1]

    echo ""
    echo $_nv_cyan"  🏥 Running Neovim health checks..."$_nv_reset
    echo ""

    if test -n "$module"
        nvim -c "checkhealth $module"
    else
        nvim -c "checkhealth"
    end
end

# ─── nvim-clean-cache: Clean Neovim caches ────────────────────────────────────
function nvim-clean-cache --description "Clean Neovim cache directories"
    echo ""
    echo $_nv_yellow"  🧹 Cleaning Neovim caches..."$_nv_reset
    echo ""

    for cache_dir in $_ash_nvim_cache_dir "$HOME/.local/share/nvim/lazy" \
                     "$HOME/.local/share/nvim/mason/cache"
        if test -d $cache_dir
            set -l size (du -sh $cache_dir 2>/dev/null | awk '{print $1}')
            read -P "  Clean $cache_dir ($size)? [y/N] " confirm
            if string match -qi 'y*' $confirm
                rm -rf $cache_dir
                echo $_nv_green"  ✓ Cleaned ($size)"$_nv_reset
            end
        end
    end
    echo ""
end

# ─── nvim-info: Rich Neovim environment dashboard ─────────────────────────────
function nvim-info --description "Show complete Neovim environment information"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l nvim   (set_color 57A143)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l yellow (set_color yellow)
    set -l dim    (set_color brblack)
    set -l red    (set_color red)

    echo ""
    echo $bold$nvim"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$nvim"  ║     📝  Neovim Development Environment               ║"$reset
    echo $bold$nvim"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"Binary:   "$reset $dim$_ash_nvim_bin$reset
    echo "  "$bold"Version:  "$reset $cyan(nvim --version 2>/dev/null | head -1)$reset
    echo "  "$bold"Config:   "$reset $dim$_ash_nvim_config_dir$reset
    echo "  "$bold"Data:     "$reset $dim$_ash_nvim_data_dir$reset
    echo "  "$bold"Cache:    "$reset $dim$_ash_nvim_cache_dir$reset
    echo ""

    # Provider status
    echo "  "$bold"Providers:"$reset
    for provider in python3 node ruby perl
        set -l cmd_check ""
        switch $provider
            case python3; set cmd_check "python3"
            case node;    set cmd_check "node"
            case ruby;    set cmd_check "ruby"
            case perl;    set cmd_check "perl"
        end

        if command -q $cmd_check
            set -l ver ($cmd_check --version 2>/dev/null | head -1 | awk '{print $NF}')
            echo "    "$green"✓ "$reset$provider $dim$ver$reset
        else
            echo "    "$dim"✗ "$reset$provider $dim"(not found)"$reset
        end
    end
    echo ""

    # Plugin info
    if test -f $_ash_nvim_lazy_lock && command -q jq
        set -l plugin_count (jq 'keys | length' $_ash_nvim_lazy_lock 2>/dev/null)
        echo "  "$bold"Plugins:  "$reset $cyan$plugin_count$reset" (lazy.nvim)"
    end

    # Mason packages
    set -l mason_dir "$_ash_nvim_data_dir/mason/packages"
    if test -d $mason_dir
        set -l mason_count (count $mason_dir/*/)
        echo "  "$bold"Mason:    "$reset $cyan$mason_count$reset" packages installed"
    end

    # Disk usage
    echo ""
    echo "  "$bold"Disk Usage:"$reset
    for d in $_ash_nvim_config_dir $_ash_nvim_data_dir $_ash_nvim_cache_dir
        if test -d $d
            set -l size (du -sh $d 2>/dev/null | awk '{print $1}')
            printf "    $dim%-35s$reset  $cyan%s$reset\n" $d $size
        end
    end
    echo ""

    # Bob version manager
    if command -q bob
        echo "  "$bold"Bob (version mgr):"$reset
        bob list 2>/dev/null | head -5 | while read -l line
            echo "    "$dim$line$reset
        end
        echo ""
    end

    # Tools
    echo "  "$bold"Related Tools:"$reset
    for tool in neovide lazygit ranger yazi wezterm kitty
        if command -q $tool
            echo "    "$green"✓ "$reset$tool
        end
    end
    echo ""
end

# ─── nvim-appname: Switch Neovim config profile ────────────────────────────────
function nvim-appname --description "Switch Neovim config via NVIM_APPNAME"
    set -l appname $argv[1]

    if test -z "$appname"
        # List available configs
        set -l configs (find "$HOME/.config" -maxdepth 1 -type d \
            -name "*nvim*" 2>/dev/null | xargs -I{} basename {})

        if command -q fzf
            set appname (
                printf '%s\n' $configs |
                fzf --border-label "  📝 Select Neovim Config " \
                    --border rounded \
                    --prompt "  " \
                    --pointer "▶" \
                    --preview 'ls -la "$HOME/.config/{}" 2>/dev/null | head -20' \
                    --preview-window 'right:40%:border-rounded'
            )
            test -z "$appname" && return 0
        else
            echo ""
            echo "  Available Neovim configs:"
            for cfg in $configs
                set -l active ""
                test "$cfg" = "$NVIM_APPNAME" && set active $_nv_green" ← active"$_nv_reset
                echo "    "$_nv_dim"• "$_nv_reset$cfg$active
            end
            echo ""
            read -P "  Select config: " appname
        end
    end

    test -z "$appname" && return 1

    set --export NVIM_APPNAME $appname
    echo $_nv_green"  ✓ NVIM_APPNAME=$appname"$_nv_reset
    echo "  Start nvim to use this configuration"
end

# ─── nvim-format: Format file with LSP ────────────────────────────────────────
function nvim-format --description "Format file headlessly via Neovim LSP"
    set -l file $argv[1]

    if test -z "$file"
        echo "  Usage: nvim-format <file>"
        return 1
    end

    if not test -f $file
        echo $_nv_red"  ✗ File not found: $file"$_nv_reset
        return 1
    end

    echo $_nv_cyan"  🎨 Formatting: $file"$_nv_reset
    nvim --headless \
        -c "lua vim.lsp.start_client({name='fmt'})" \
        -c "lua vim.lsp.buf.format({async=false})" \
        -c "write" \
        -c "quit" \
        $file 2>/dev/null

    and echo $_nv_green"  ✓ Formatted: $file"$_nv_reset
end

# ─── nvim-git: Open lazygit inside Neovim ─────────────────────────────────────
function nvim-git --description "Open git integration inside Neovim"
    if command -q lazygit
        nvim -c "LazyGit" 2>/dev/null || lazygit
    else
        nvim -c "Neogit" 2>/dev/null || \
            nvim -c "Git" 2>/dev/null || \
            echo $_nv_yellow"  💡 Install lazygit for git integration"$_nv_reset
    end
end

# ─── nvim-update: Full Neovim environment update ──────────────────────────────
function nvim-update --description "Update Neovim, plugins, and Mason packages"
    echo ""
    echo $_nv_bold$_nv_nvim"  ╔══════════════════════════════════════╗"$_nv_reset
    echo $_nv_bold$_nv_nvim"  ║  🔄 Full Neovim Update               ║"$_nv_reset
    echo $_nv_bold$_nv_nvim"  ╚══════════════════════════════════════╝"$_nv_reset
    echo ""

    # 1. Bob update (if available)
    if command -q bob
        echo $_nv_cyan"  [1/3] Updating Neovim binary (Bob)..."$_nv_reset
        nvim-bob update
        echo ""
    end

    # 2. Lazy.nvim sync
    echo $_nv_cyan"  [2/3] Syncing plugins (Lazy.nvim)..."$_nv_reset
    nvim-lazy sync
    echo ""

    # 3. Mason update
    echo $_nv_cyan"  [3/3] Updating Mason packages..."$_nv_reset
    nvim-mason update
    echo ""

    echo $_nv_green"  ✓ Full Neovim environment updated"$_nv_reset
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 THEME INTEGRATION: Sync ASH theme with Neovim                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_nvim_on_theme_change --on-event ash_theme_changed \
    --description "Notify Neovim instances of ASH theme change"
    set -l theme_name $argv[1]

    # Write theme signal file for live Neovim instances
    echo $theme_name > "$HOME/.local/share/ash/state/nvim-theme-signal" 2>/dev/null

    # Send signal to all running nvim instances via nvim socket
    for sock in "$HOME/.local/share/nvim/server-"*.sock
        test -S $sock || continue
        nvim --server $sock \
             --remote-send "<cmd>lua if pcall(require, 'ash') then require('ash').sync_theme() end<cr>" \
             2>/dev/null
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Core editing
abbr --add v      'nvim'
abbr --add vi     'nvim'
abbr --add vim    'nvim'
abbr --add nv     'nvim'
abbr --add nvi    'nvi'
abbr --add nvv    'nvv'
abbr --add nvt    'nvt'
abbr --add nvd    'nvd'
abbr --add nvr    'nvr'
abbr --add nf     'nf'
abbr --add ng     'ng'
abbr --add ncd    'ncd'
abbr --add svim   'nvim-sudo'

# Config management
abbr --add nvcfg  'nvim-config'
abbr --add nvinit 'nvim-config init'
abbr --add nvplugs 'nvim-config plugins'
abbr --add nvkeys 'nvim-config keys'
abbr --add nvopts 'nvim-config opts'
abbr --add nvlazy 'nvim-config lazy'
abbr --add nvdir  'nvim-config dir'
abbr --add nvapp  'nvim-appname'

# Plugin management
abbr --add nvls   'nvim-lazy list'
abbr --add nvsync 'nvim-lazy sync'
abbr --add nvupd  'nvim-lazy update'
abbr --add nvclean 'nvim-lazy clean'
abbr --add nvlock 'nvim-lazy lock'
abbr --add nvrestore 'nvim-lazy restore'

# Mason
abbr --add nvmls  'nvim-mason list'
abbr --add nvminst 'nvim-mason install'
abbr --add nvmupd 'nvim-mason update'

# Bob version manager
abbr --add nvbob  'nvim-bob'
abbr --add nvbls  'nvim-bob list'
abbr --add nvbuse 'nvim-bob use'
abbr --add nvbst  'nvim-bob stable'
abbr --add nvbn   'nvim-bob nightly'

# Maintenance
abbr --add nvinfo  'nvim-info'
abbr --add nvhealth 'nvim-check-health'
abbr --add nvbench 'nvim-profile-startup'
abbr --add nvcache 'nvim-clean-cache'
abbr --add nvfmt   'nvim-format'
abbr --add nvgit   'nvim-git'
abbr --add nvall   'nvim-update'
abbr --add nvver   'nvim --version'
abbr --add nvhead  'nvim --headless +qa'