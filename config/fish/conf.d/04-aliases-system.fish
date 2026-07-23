#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║   ██████╗ ██╗  ██╗     █████╗ ██╗     ██╗ █████╗ ███████╗███████╗███████╗      ║
# ║  ██╔═══██╗██║  ██║    ██╔══██╗██║     ██║██╔══██╗██╔════╝██╔════╝██╔════╝      ║
# ║  ██║   ██║███████║    ███████║██║     ██║███████║███████╗█████╗  ███████╗      ║
# ║  ██║   ██║╚════██║    ██╔══██║██║     ██║██╔══██║╚════██║██╔══╝  ╚════██║      ║
# ║  ╚██████╔╝     ██║    ██║  ██║███████╗██║██║  ██║███████║███████╗███████║      ║
# ║   ╚═════╝      ╚═╝    ╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝      ║
# ║                                                                                  ║
# ║   🖥️  SYSTEM ALIASES — ASH Dotfiles v5.0 OMEGA                                 ║
# ║   Modern Unix tool replacements • Safety nets • Power shortcuts                 ║
# ║                                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

status is-interactive || exit 0
set -q __ash_aliases_system_initialized && exit 0
set -g __ash_aliases_system_initialized 1


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 INTERNAL HELPER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Smart alias: only define if the target command exists
function __ash_alias
    # Usage: __ash_alias <name> <cmd_to_check> <full_alias_body>
    set -l name   $argv[1]
    set -l check  $argv[2]
    set -l body   $argv[3..-1]
    command -sq $check && alias $name $body
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📁 FILE LISTING — eza (modern ls replacement)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq eza
    # ── Core listing ──────────────────────────────────────────────────────────
    alias ls   "eza \
                  --icons=always \
                  --color=always \
                  --group-directories-first \
                  --hyperlink"

    alias ll   "eza \
                  --icons=always \
                  --color=always \
                  --group-directories-first \
                  --long \
                  --header \
                  --git \
                  --git-repos \
                  --time-style=relative \
                  --hyperlink"

    alias la   "eza \
                  --icons=always \
                  --color=always \
                  --group-directories-first \
                  --long \
                  --header \
                  --git \
                  --git-repos \
                  --all \
                  --time-style=relative \
                  --hyperlink"

    alias l    "eza \
                  --icons=always \
                  --color=always \
                  --group-directories-first \
                  --oneline"

    alias lh   "eza \
                  --icons=always \
                  --color=always \
                  --group-directories-first \
                  --long \
                  --header \
                  --all \
                  --sort=size \
                  --reverse \
                  --hyperlink"

    # ── Tree views ────────────────────────────────────────────────────────────
    alias lt   "eza \
                  --icons=always \
                  --color=always \
                  --group-directories-first \
                  --tree \
                  --level=3 \
                  --git-ignore"

    alias lt2  "eza \
                  --icons=always \
                  --color=always \
                  --group-directories-first \
                  --tree \
                  --level=2"

    alias lt4  "eza \
                  --icons=always \
                  --color=always \
                  --group-directories-first \
                  --tree \
                  --level=4"

    alias lta  "eza \
                  --icons=always \
                  --color=always \
                  --group-directories-first \
                  --tree \
                  --level=3 \
                  --all"

    alias ltl  "eza \
                  --icons=always \
                  --color=always \
                  --group-directories-first \
                  --tree \
                  --level=3 \
                  --long \
                  --header \
                  --git"

    # ── Sorted views ──────────────────────────────────────────────────────────
    alias lss  "eza \
                  --icons=always \
                  --color=always \
                  --long \
                  --sort=size \
                  --reverse \
                  --header"                 # Sort by size (largest first)

    alias lsm  "eza \
                  --icons=always \
                  --color=always \
                  --long \
                  --sort=modified \
                  --reverse \
                  --header"                 # Sort by modified (newest first)

    alias lsc  "eza \
                  --icons=always \
                  --color=always \
                  --long \
                  --sort=created \
                  --reverse \
                  --header"                 # Sort by created (newest first)

    alias lse  "eza \
                  --icons=always \
                  --color=always \
                  --long \
                  --sort=extension \
                  --header"                 # Sort by extension

    # ── Filter views ──────────────────────────────────────────────────────────
    alias lf   "eza \
                  --icons=always \
                  --color=always \
                  --only-files"             # Files only

    alias ld   "eza \
                  --icons=always \
                  --color=always \
                  --only-dirs \
                  --long \
                  --header"                 # Directories only

    alias lg   "eza \
                  --icons=always \
                  --color=always \
                  --long \
                  --header \
                  --git \
                  --git-repos \
                  --all \
                  --git-ignore"             # Git-aware listing

    # ── Special formats ───────────────────────────────────────────────────────
    alias lx   "eza \
                  --icons=always \
                  --color=always \
                  --long \
                  --header \
                  --extended"               # Show extended attributes

    alias lk   "eza \
                  --icons=always \
                  --color=always \
                  --long \
                  --header \
                  --blocksize"              # Show block sizes

    alias lno  "eza \
                  --color=always \
                  --group-directories-first \
                  --no-icons"               # No icons (scripts/slow terminals)

else
    # ── Fallback to GNU ls ────────────────────────────────────────────────────
    alias ls   "ls --color=always --group-directories-first --human-readable"
    alias ll   "ls --color=always --group-directories-first --human-readable -l"
    alias la   "ls --color=always --group-directories-first --human-readable -la"
    alias l    "ls --color=always --group-directories-first --human-readable -1"
    alias lh   "ls --color=always --human-readable -lSr"
    alias lsm  "ls --color=always --human-readable -lt"
    alias ld   "ls --color=always --human-readable -ld */"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🐱 FILE VIEWING — bat (syntax-highlighted cat)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq bat
    # cat: plain output (no line numbers) for piping
    alias cat   "bat \
                   --style=plain \
                   --pager=never"

    # bat: full experience with numbers and decorations
    alias bat   "bat \
                   --style=numbers,changes,header-filename,rule,snip \
                   --italic-text=always"

    # catn: cat with line numbers only
    alias catn  "bat \
                   --style=numbers \
                   --pager=never"

    # batp: bat with pager
    alias batp  "bat \
                   --style=numbers,changes,header-filename,rule,snip \
                   --paging=always"

    # batd: bat with diff highlighting
    alias batd  "bat \
                   --style=numbers,changes \
                   --diff"

    # batman: bat-powered man pages (fallback if MANPAGER not set)
    alias batman "bat \
                    --language=man \
                    --style=plain"

    # head/tail with syntax highlighting
    alias head  "bat \
                   --style=numbers,header-filename \
                   --pager=never \
                   --line-range=:20"

    alias tail  "bat \
                   --style=numbers,header-filename \
                   --pager=never \
                   --line-range=-20:"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔍 SEARCH & FIND — fd, ripgrep, fzf
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq fd
    # fd: user-friendly find replacement
    alias find   "fd"
    alias fda    "fd \
                    --hidden \
                    --no-ignore"                    # Find all (hidden + ignored)
    alias fdf    "fd \
                    --type f"                       # Files only
    alias fdd    "fd \
                    --type d"                       # Dirs only
    alias fdl    "fd \
                    --type l"                       # Symlinks only
    alias fdx    "fd \
                    --type x"                       # Executables only
    alias fde    "fd \
                    --extension"                    # Find by extension: fde py
    alias fds    "fd \
                    --size"                         # Find by size: fds +1M
end

if command -sq rg
    # rg: blazing fast grep replacement
    alias grep   "rg \
                    --smart-case \
                    --hidden \
                    --glob='!.git'"

    alias rg     "rg \
                    --smart-case \
                    --hidden \
                    --glob='!.git' \
                    --glob='!node_modules'"

    alias rgh    "rg \
                    --smart-case \
                    --hidden \
                    --no-ignore"                    # Search hidden & ignored

    alias rgf    "rg \
                    --smart-case \
                    --files-with-matches"           # Only show matching filenames

    alias rgl    "rg \
                    --smart-case \
                    --files-without-match"          # Files WITHOUT match

    alias rgc    "rg \
                    --smart-case \
                    --count"                        # Count matches per file

    alias rgj    "rg \
                    --smart-case \
                    --json"                         # JSON output (for tooling)

    alias rgt    "rg \
                    --smart-case \
                    --type"                         # Filter by type: rgt py <pattern>

    alias rgn    "rg \
                    --no-ignore \
                    --hidden \
                    --smart-case"                   # rg nuclear (search everything)
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 💾 DISK & FILESYSTEM — dust, duf, ncdu
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq dust
    alias du    "dust"                              # Modern du with visual bars
    alias duh   "dust \
                    --apparent-size"                # Apparent size (not disk usage)
    alias dud   "dust \
                    --depth=1"                      # One level deep
    alias duf5  "dust \
                    --number-of-lines=5"            # Top 5 largest items
    alias duf20 "dust \
                    --number-of-lines=20"           # Top 20 largest items
else
    alias du    "du \
                    --human-readable \
                    --total"
    alias duh   "du \
                    --human-readable \
                    --summarize \
                    --total"
end

if command -sq duf
    alias df    "duf"                               # Beautiful disk usage
    alias dfa   "duf \
                    --all"                          # Show all filesystems
    alias dfj   "duf \
                    --json"                         # JSON output
else
    alias df    "df \
                    --human-readable \
                    --print-type"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📊 PROCESS MONITORING — btop, htop, procs
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq btop
    alias top     "btop"
    alias htop    "btop"
    alias btop    "btop \
                     --utf-force"
else if command -sq htop
    alias top     "htop"
    alias htop    "htop \
                     --delay=5"
end

if command -sq procs
    alias ps      "procs"
    alias psa     "procs \
                     --tree"                        # Process tree
    alias psk     "procs \
                     --sortd cpu"                   # Sort by CPU
    alias psm     "procs \
                     --sortd mem"                   # Sort by memory
    alias psf     "procs \
                     --watch-interval=1"            # Live updating
else
    alias ps      "ps \
                     auxf"
    alias psa     "ps \
                     aux \
                     --sort=-%cpu"
    alias psm     "ps \
                     aux \
                     --sort=-%mem"
end

# pgrep / pkill: verbose by default
alias pgrep   "pgrep \
                 --list-name \
                 --ignore-case"
alias pkill   "pkill \
                 --echo \
                 --ignore-case"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔄 DIFF & PATCH — delta (beautiful diffs)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq delta
    alias diff    "delta"
    alias diffn   "delta \
                     --line-numbers"
    alias diffw   "delta \
                     --side-by-side"                # Side-by-side diff
    alias diffww  "delta \
                     --side-by-side \
                     --wrap-max-lines=unlimited"
else if command -sq colordiff
    alias diff    "colordiff \
                     --unified"
else
    alias diff    "diff \
                     --color=always \
                     --unified"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🏓 NETWORK DIAGNOSTICS — gping, dogdns, bandwhich
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq gping
    alias ping    "gping"                           # Visual ping with graphs
    alias ping4   "gping \
                     --ipv4"
    alias ping6   "gping \
                     --ipv6"
else
    alias ping    "ping \
                     -c 5 \
                     -W 3"
end

if command -sq dog
    alias dig     "dog"                             # Modern DNS lookup
    alias nslookup "dog"
else if command -sq drill
    alias dig     "drill"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📖 HELP & DOCUMENTATION — tldr, cheat, man
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq tldr
    alias tldr    "tldr \
                     --color \
                     --compact"
    alias h       "tldr"                            # Quick help shortcut
    # Don't override man — keep both
else if command -sq cheat
    alias h       "cheat"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ✏️  EDITORS — Smart nvim wrappers
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq nvim
    alias v       "nvim"
    alias vi      "nvim"
    alias vim     "nvim"
    alias nv      "nvim"
    alias svim    "sudo \
                     --edit"                        # Sudo edit via SUDO_EDITOR
    alias nvimd   "nvim \
                     --headless \
                     '+Lazy sync' \
                     '+qa'"                         # Headless plugin sync
    alias nvimlog "nvim \
                     --startuptime /tmp/nvim-startuptime.log \
                     +q \
                     && bat /tmp/nvim-startuptime.log"

    # Quick config edits
    alias vfish   "nvim $FISH_CONFIG_DIR/config.fish"
    alias vhypr   "nvim $XDG_CONFIG_HOME/hypr/hyprland.conf"
    alias vnvim   "nvim $XDG_CONFIG_HOME/nvim/init.lua"
    alias vwaybar "nvim $XDG_CONFIG_HOME/waybar/config.jsonc"
    alias vstarship "nvim $XDG_CONFIG_HOME/starship/starship.toml"
    alias vkitty  "nvim $XDG_CONFIG_HOME/kitty/kitty.conf"
    alias vdunst  "nvim $XDG_CONFIG_HOME/dunst/dunstrc"
    alias vrofi   "nvim $XDG_CONFIG_HOME/rofi/config.rasi"
else if command -sq hx
    alias v       "hx"
    alias vi      "hx"
    alias vim     "hx"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📁 FILE MANAGEMENT — yazi, ranger, mc
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq yazi
    alias y       "yazi"
    alias ya      "yazi \
                     --cwd-file=/tmp/yazi-cwd"      # Save cwd on exit
else if command -sq ranger
    alias y       "ranger"
else if command -sq mc
    alias y       "mc"
end

if command -sq lazygit
    alias lg      "lazygit"
    alias lgg     "lazygit"
end

if command -sq lazydocker
    alias lzd     "lazydocker"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📦 ARCHIVE & COMPRESSION — auto-detect format
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq ouch
    # ouch: unified archive tool (handles any format)
    alias compress "ouch compress"
    alias decomp   "ouch decompress"
    alias lsarch   "ouch list"
else
    alias decomp   "extract"                        # falls back to fish function
end

# tar with sane defaults
alias tar      "tar \
                  --verbose"
alias tarz     "tar \
                  --create \
                  --gzip \
                  --verbose \
                  --file"                           # Create .tar.gz
alias tarx     "tar \
                  --extract \
                  --verbose \
                  --file"                           # Extract any tar


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🛡️  SAFETY NETS — Prevent accidental overwrites/deletions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# rm: interactive mode (prompt before each removal)
alias rm      "rm \
                 --interactive=once \
                 --verbose"

# cp: interactive + verbose + preserve metadata
alias cp      "cp \
                 --interactive \
                 --verbose \
                 --preserve=timestamps,links"

# mv: interactive + verbose
alias mv      "mv \
                 --interactive \
                 --verbose"

# ln: interactive + verbose
alias ln      "ln \
                 --interactive \
                 --verbose"

# mkdir: create parents + verbose
alias mkdir   "mkdir \
                 --parents \
                 --verbose"

# chmod / chown: verbose
alias chmod   "chmod \
                 --verbose"
alias chown   "chown \
                 --verbose"

# Trash-cli (safer rm via freedesktop trash)
if command -sq trash
    alias del     "trash"                           # Move to trash
    alias trash-l "trash-list"                      # List trash contents
    alias trash-e "trash-empty"                     # Empty trash
    alias trash-r "trash-restore"                   # Restore from trash
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 💻 SYSTEM INFO & MONITORING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Memory: human-readable free
alias free    "free \
                 --human \
                 --si \
                 --total"

# Uptime with load averages
alias uptime  "uptime \
                 --pretty"

# CPU info
alias cpuinfo "lscpu \
                 --output-all \
                 --json"

# Temperature sensors
command -sq sensors \
    && alias temp   "sensors \
                       --no-adapter"

# GPU info shortcuts
if command -sq nvidia-smi
    alias nvsmi   "nvidia-smi \
                     --query-gpu=name,temperature.gpu,utilization.gpu,\
utilization.memory,memory.used,memory.free \
                     --format=csv,noheader,nounits"
    alias nvwatch "watch \
                     --interval=1 \
                     nvidia-smi"
end

if command -sq radeontop
    alias gpuwatch "radeontop \
                      --color"
end

# Kernel/OS info
alias kernel  "uname \
                 --kernel-release \
                 --kernel-version \
                 --machine \
                 --operating-system"
alias os      "cat /etc/os-release"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📦 PACKAGE MANAGEMENT — Arch Linux (paru/yay/pacman)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq paru
    # ── Full-featured AUR helper ───────────────────────────────────────────────
    alias pac       "paru"
    alias pacs      "paru \
                       --sync"                      # Install package
    alias pacr      "paru \
                       --remove \
                       --nosave \
                       --recursive"                 # Remove with deps
    alias pacu      "paru \
                       --sync \
                       --sysupgrade"                # Update all
    alias pacuaur   "paru \
                       --sync \
                       --sysupgrade \
                       --aur"                       # Update AUR only
    alias paci      "paru \
                       --query \
                       --info"                      # Package info
    alias pacl      "paru \
                       --query \
                       --explicit"                  # Explicitly installed
    alias pacd      "paru \
                       --query \
                       --deps \
                       --unrequired"                # Orphaned deps
    alias pacc      "paru \
                       --sync \
                       --clean"                     # Clean package cache
    alias pacs      "paru \
                       --sync \
                       --search"                    # Search packages
    alias pacf      "paru \
                       --query \
                       --owns"                      # Which package owns file
    alias pacfl     "paru \
                       --query \
                       --list"                      # List files from package
    alias pacchk    "paru \
                       --query \
                       --check"                     # Check package integrity
    alias paclog    "bat /var/log/pacman.log"       # View pacman log
    alias pacexpl   "paru \
                       --query \
                       --explicit \
                       --info \
                       --quiet"                     # List explicitly installed (quiet)

else if command -sq yay
    alias pac       "yay"
    alias pacs      "yay -S"
    alias pacr      "yay -Rns"
    alias pacu      "yay -Syu"
    alias paci      "yay -Qi"
    alias pacd      "yay -Qdt"
    alias pacc      "yay -Sc"

else if command -sq pacman
    alias pac       "sudo pacman"
    alias pacs      "sudo pacman -S"
    alias pacr      "sudo pacman -Rns"
    alias pacu      "sudo pacman -Syu"
    alias paci      "sudo pacman -Qi"
    alias pacd      "sudo pacman -Qdt"
    alias pacc      "sudo pacman -Sc"
    alias paclog    "bat /var/log/pacman.log"
end

# Flatpak (cross-distro)
if command -sq flatpak
    alias fps     "flatpak search"
    alias fpi     "flatpak install"
    alias fpu     "flatpak update"
    alias fpr     "flatpak uninstall \
                     --delete-data"
    alias fpl     "flatpak list \
                     --app"
    alias fprun   "flatpak run"
    alias fprepo  "flatpak remote-list"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🐍 PYTHON — Virtual environments & package management
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias python    "python3"
alias py        "python3"
alias pip       "pip3 \
                   --require-virtualenv"            # Enforce venv usage
alias pip!      "pip3"                              # pip without venv enforcement
alias pipi      "pip3 install"
alias pipu      "pip3 install \
                   --upgrade"
alias pipx      "pipx"
alias venv      "python3 \
                   -m venv \
                   .venv"                           # Create venv in .venv/
alias activate  "source .venv/bin/activate.fish"
alias mkenv     "python3 -m venv .venv && source .venv/bin/activate.fish"

if command -sq uv
    alias uvs     "uv sync"
    alias uva     "uv add"
    alias uvr     "uv remove"
    alias uvrun   "uv run"
    alias uvlock  "uv lock"
    alias uvup    "uv lock --upgrade"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🦀 RUST — Cargo shortcuts
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq cargo
    alias cb      "cargo build"
    alias cbr     "cargo build \
                     --release"
    alias cc      "cargo check"
    alias ct      "cargo test"
    alias ctw     "cargo watch \
                     --exec test"
    alias cr      "cargo run"
    alias crr     "cargo run \
                     --release"
    alias cw      "cargo watch \
                     --exec run"
    alias clf     "cargo clippy \
                     --all-targets \
                     --all-features \
                     -- -D warnings"
    alias cfmt    "cargo fmt \
                     --all"
    alias cdoc    "cargo doc \
                     --open \
                     --no-deps"
    alias cclean  "cargo clean"
    alias cupdate "cargo update"
    alias cinst   "cargo install"
    alias cnew    "cargo new"
    alias cinit   "cargo init"
    alias cadd    "cargo add"
    alias crem    "cargo remove"
    alias cbench  "cargo bench"
    alias cexpand "cargo expand"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🏃 MAKE / JUST / TASK — Build system shortcuts
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias make    "make \
                 --jobs=(nproc) \
                 --output-sync=target"
alias mk      "make"
alias mkc     "make clean"
alias mka     "make all"
alias mkt     "make test"
alias mkf     "make format"
alias mki     "make install"

if command -sq just
    alias j     "just"
    alias jl    "just \
                   --list"
    alias jr    "just \
                   --dry-run"
end

if command -sq task
    alias tk    "task"
    alias tkl   "task \
                   --list"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔐 SUDO & PRIVILEGES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias s       "sudo"
alias se      "sudoedit"
alias sv      "sudo nvim"
alias scat    "sudo bat"
alias sls     "sudo eza \
                 --icons=always \
                 --color=always"
alias please  "sudo !!"                             # Re-run last cmd as root
alias fuck    "sudo !!"                             # Alias for the frustrated
alias root    "sudo \
                 --shell"                           # Root shell
alias rootfish "sudo \
                 --shell \
                 fish"                              # Root fish shell


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🖥️  WAYLAND / HYPRLAND SYSTEM SHORTCUTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq hyprctl
    alias hypr-reload  "hyprctl reload && echo '✓ Hyprland reloaded'"
    alias hypr-kill    "hyprctl kill"
    alias hypr-info    "hyprctl version && hyprctl monitors"
    alias hypr-mon     "hyprctl monitors"
    alias hypr-win     "hyprctl clients \
                          --json \
                        | jq '.[] | {title,class,workspace}'"
    alias hypr-ws      "hyprctl workspaces \
                          --json \
                        | jq '.[] | {id,name,windows}'"
    alias hypr-active  "hyprctl activewindow"
    alias hypr-keybind "hyprctl binds \
                          --json \
                        | jq '.[] | {key,dispatcher,arg}'"
    alias hypr-log     "journalctl \
                          --user \
                          --unit=hyprland \
                          --follow \
                          --output=cat"
end

# Waybar
command -sq waybar && begin
    alias waybar-reload "pkill -SIGUSR2 waybar && echo '✓ Waybar reloaded'"
    alias waybar-kill   "pkill waybar"
    alias waybar-start  "waybar &"
end

# Swww wallpaper
command -sq swww && begin
    alias wp        "swww img"
    alias wp-clear  "swww clear"
    alias wp-query  "swww query"
end

# Clipboard (Wayland)
if command -sq wl-copy
    alias pbcopy    "wl-copy"
    alias pbpaste   "wl-paste"
    alias clip      "wl-copy"
    alias paste     "wl-paste"
    alias xclip     "wl-copy"
    alias xsel      "wl-paste \
                       --no-newline"
end

# Screenshots
if command -sq grimblast
    alias shot      "grimblast \
                       --notify \
                       copysave \
                       area"
    alias shotfull  "grimblast \
                       --notify \
                       copysave \
                       screen"
    alias shotwin   "grimblast \
                       --notify \
                       copysave \
                       active"
else if command -sq grim
    alias shot      "grim \
                       -g \
                       (slurp) \
                       $ASH_SCREENSHOTS_DIR/(date +%Y%m%d_%H%M%S).png"
end

# Screen recording
command -sq wf-recorder && begin
    alias rec       "wf-recorder \
                       --audio \
                       --file=$ASH_RECORDINGS_DIR/(date +%Y%m%d_%H%M%S).mp4"
    alias recstop   "pkill -INT wf-recorder"
end

# Color picker
command -sq hyprpicker && begin
    alias pick      "hyprpicker \
                       --autocopy \
                       --format=hex"
    alias pickrgb   "hyprpicker \
                       --autocopy \
                       --format=rgb"
end

# rofi launchers
command -sq rofi && begin
    alias run       "rofi \
                       -show drun"
    alias launcher  "rofi \
                       -show drun"
    alias rofiwin   "rofi \
                       -show window"
    alias rofirun   "rofi \
                       -show run"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ⚡ ASH CLI SHORTCUTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq ash
    alias at      "ash theme"
    alias ata     "ash theme apply"
    alias atp     "ash theme pick"
    alias atr     "ash theme random"
    alias atl     "ash theme list"
    alias ats     "ash theme schedule"
    alias am      "ash mode"
    alias amg     "ash mode game"
    alias amf     "ash mode focus"
    alias amw     "ash mode work"
    alias amc     "ash mode cinema"
    alias amp     "ash mode privacy"
    alias amd     "ash mode default"
    alias ap      "ash plugin"
    alias api     "ash plugin install"
    alias apl     "ash plugin list"
    alias aps     "ash plugin search"
    alias ass     "ash snapshot"
    alias assc    "ash snapshot create"
    alias assr    "ash snapshot restore"
    alias assl    "ash snapshot list"
    alias assd    "ash snapshot diff"
    alias ad      "ash doctor"
    alias adq     "ash doctor quick"
    alias adf     "ash doctor full"
    alias au      "ash update all"
    alias aus     "ash update system"
    alias ahw     "ash hw full-report"
    alias aai     "ash ai chat"
    alias aas     "ash ai suggest-theme"
    alias awp     "ash wallpaper"
    alias awps    "ash wallpaper set"
    alias awpr    "ash wallpaper random"
    alias abar    "ash bar reload"
    alias anet    "ash net status"
    alias ashot   "ash shot area"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 QUALITY OF LIFE — Shell usability
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Navigation
alias ..      "cd .."
alias ...     "cd ../.."
alias ....    "cd ../../.."
alias .....   "cd ../../../.."
alias ~       "cd $HOME"
alias -- -    "cd -"                                # Toggle prev/current dir
alias back    "cd -"

# Shell session
alias cl      "clear"
alias q       "exit"
alias reload  "exec fish"
alias re      "exec fish"
alias resrc   "source $FISH_CONFIG_DIR/config.fish"
alias fishrc  "nvim $FISH_CONFIG_DIR/config.fish && exec fish"

# Time & date
alias now     "date +'%Y-%m-%d %H:%M:%S'"
alias today   "date +'%Y-%m-%d'"
alias week    "date +'Week %V of %Y'"
alias epoch   "date +%s"
alias utc     "date -u +'%Y-%m-%dT%H:%M:%SZ'"

# PATH inspection
alias path    "echo \$PATH | string split ':' | cat -n"
alias fpath   "echo \$fish_function_path | string split ':' | cat -n"

# Misc
alias ports   "ss \
                 --tcp \
                 --udp \
                 --listening \
                 --numeric \
                 --processes"
alias pubip   "curl \
                 --silent \
                 --max-time 5 \
                 ifconfig.me && echo"
alias localip "ip \
                 --brief \
                 address"
alias myip    "curl \
                 --silent \
                 ipinfo.io \
               | jq '{ip,city,region,country,org}'"
alias size    "du \
                 --human-readable \
                 --summarize"
alias biggest "du \
                 --human-readable \
                 --all \
               | sort \
                 --human-numeric-sort \
                 --reverse \
               | head -20"
alias empty   "cat /dev/null >"                     # Truncate a file
alias count   "wc -l"
alias trim    "string trim"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧹 CLEANUP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
functions --erase __ash_alias