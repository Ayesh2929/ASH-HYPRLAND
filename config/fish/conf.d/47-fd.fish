# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — fd Ultra Configuration                             ║
# ║  Fast find alternative with smart defaults, fzf integration & rich output  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Require fd ─────────────────────────────────────────────────────────
command -q fd || command -q fdfind || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_fd_loaded && exit 0
set --global _ash_fd_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_fd_log    "$HOME/.local/share/ash/logs/fd.log"
set --global _ash_fd_cache  "$HOME/.local/share/ash/cache/fd"

mkdir -p (dirname $_ash_fd_log) 2>/dev/null
mkdir -p $_ash_fd_cache          2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 BINARY DETECTION: fd vs fdfind                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_fd_bin --description "Resolve correct fd binary"
    command -q fd     && echo fd     && return
    command -q fdfind && echo fdfind && return
    echo fd
end

set --global _ash_fd_exe (__ash_fd_bin)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _fd_reset   (set_color normal)
set -g _fd_bold    (set_color --bold)
set -g _fd_cyan    (set_color cyan)
set -g _fd_green   (set_color green)
set -g _fd_yellow  (set_color yellow)
set -g _fd_red     (set_color red)
set -g _fd_dim     (set_color brblack)
set -g _fd_blue    (set_color blue)
set -g _fd_purple  (set_color magenta)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  ENVIRONMENT CONFIGURATION                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── FD_OPTIONS: Default flags for all fd invocations ─────────────────────────
set --export FD_OPTIONS "\
    --hidden \
    --follow \
    --exclude .git \
    --exclude node_modules \
    --exclude .cache \
    --exclude __pycache__ \
    --exclude target \
    --exclude dist \
    --exclude build \
    --exclude .next \
    --exclude .svelte-kit \
    --exclude .terraform"

# ── Color output ──────────────────────────────────────────────────────────────
set --export LS_COLORS "$LS_COLORS:di=34;1:fi=37:ln=36;1:ex=32;1"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 CORE fd WRAPPERS                                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── fd: Override with smart defaults ──────────────────────────────────────────
function fd --wraps=$_ash_fd_exe --description "fd with smart defaults"
    $_ash_fd_exe --color=always $argv
end

# ── fdf: Find files only ──────────────────────────────────────────────────────
function fdf --description "Find files only (no directories)"
    $_ash_fd_exe --type f --color=always $argv
end

# ── fdd: Find directories only ────────────────────────────────────────────────
function fdd --description "Find directories only"
    $_ash_fd_exe --type d --color=always $argv
end

# ── fdl: Find symlinks ────────────────────────────────────────────────────────
function fdl --description "Find symlinks"
    $_ash_fd_exe --type l --color=always $argv
end

# ── fdx: Find executables ─────────────────────────────────────────────────────
function fdx --description "Find executable files"
    $_ash_fd_exe --type x --color=always $argv
end

# ── fde: Find by extension ────────────────────────────────────────────────────
function fde --description "Find files by extension (fde <ext> [path])"
    set -l ext  $argv[1]
    set -l path $argv[2]
    test -z "$path" && set path "."

    if test -z "$ext"
        echo "  Usage: fde <extension> [path]"
        echo "  Example: fde py ./src"
        return 1
    end

    # Strip leading dot
    set ext (string replace -r '^\.' '' $ext)
    $_ash_fd_exe --extension $ext --type f --color=always $path
end

# ── fdh: Include hidden files ─────────────────────────────────────────────────
function fdh --description "fd including hidden files"
    $_ash_fd_exe --hidden --color=always $argv
end

# ── fda: Unrestricted search (no .gitignore, include hidden) ──────────────────
function fda --description "fd unrestricted (no .gitignore, all hidden)"
    $_ash_fd_exe --no-ignore --hidden --color=always $argv
end

# ── fds: Find by size ─────────────────────────────────────────────────────────
function fds --description "Find files by size (fds [+/-]<size><unit> [path])"
    set -l size_spec $argv[1]
    set -l path      $argv[2]
    test -z "$path" && set path "."

    if test -z "$size_spec"
        echo "  Usage: fds [+/-]<size><unit> [path]"
        echo "  Units: b k m g"
        echo "  Example: fds +1m ./        (files > 1MB)"
        echo "           fds -10k ./logs/  (files < 10KB)"
        return 1
    end

    $_ash_fd_exe --size $size_spec --type f --color=always $path
end

# ── fdm: Find recently modified ────────────────────────────────────────────────
function fdm --description "Find files modified within N time (fdm <duration>)"
    set -l duration $argv[1]
    set -l path     $argv[2]
    test -z "$path"     && set path "."
    test -z "$duration" && set duration "1d"

    # Valid: 10s, 1h, 2d, 3w, 1m, 1y
    $_ash_fd_exe \
        --newer-than "now - $duration" \
        --type f \
        --color=always \
        $path 2>/dev/null || \
    $_ash_fd_exe \
        --changed-within $duration \
        --type f \
        --color=always \
        $path
end

# ── fdn: Find by name pattern ─────────────────────────────────────────────────
function fdn --description "Find files by name pattern (glob or regex)"
    set -l pattern $argv[1]
    test -z "$pattern" && begin; echo "  Usage: fdn <pattern>"; return 1; end

    # Auto-detect glob vs regex
    if string match -q '*[*?[]]*' $pattern
        $_ash_fd_exe --glob "$pattern" --color=always $argv[2..-1]
    else
        $_ash_fd_exe "$pattern" --color=always $argv[2..-1]
    end
end

# ── fdi: Case-insensitive search ───────────────────────────────────────────────
function fdi --description "fd case-insensitive search"
    $_ash_fd_exe --ignore-case $argv
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🚀 FZF INTEGRATION: Interactive file finding                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── fzfd: Interactive fd + fzf file picker ───────────────────────────────────
function fzfd --description "Interactive fd + fzf file picker"
    command -q fzf || begin; fd $argv; return; end

    set -l type   $argv[1]   # file | dir | all
    set -l query  $argv[2]
    set -l action $argv[3]   # edit | cd | copy | print

    test -z "$type" && set type file

    set -l fd_cmd
    switch $type
        case file f
            set fd_cmd "$_ash_fd_exe --type f --hidden --follow --color=always \
                --exclude .git --exclude node_modules --exclude .cache"
        case dir d
            set fd_cmd "$_ash_fd_exe --type d --hidden --follow --color=always \
                --exclude .git --exclude node_modules"
        case all a '*'
            set fd_cmd "$_ash_fd_exe --hidden --follow --color=always \
                --exclude .git --exclude node_modules"
    end

    set -l header_text "  Files  "
    test "$type" = dir && set header_text "  Dirs  "

    set -l selected (
        eval $fd_cmd 2>/dev/null |
        fzf --ansi \
            --multi \
            --border-label "  🔍 fd Picker ($type) " \
            --border rounded \
            --prompt "  🔍 " \
            --pointer "▶" \
            --marker "✓" \
            --query "$query" \
            --preview '
                item={}
                if [ -d "$item" ]; then
                    eza --icons=always --color=always --group-directories-first -la "$item" 2>/dev/null || ls -la "$item"
                elif [ -f "$item" ]; then
                    bat --color=always --style=numbers,changes --line-range=:200 "$item" 2>/dev/null || cat "$item"
                fi
            ' \
            --preview-window 'right:55%:border-rounded:wrap' \
            --header "  Enter:open  Tab:multi  Ctrl-E:editor  Ctrl-Y:copy  Ctrl-D:cd  " \
            --bind 'ctrl-e:execute(nvim {+} </dev/tty >/dev/tty)' \
            --bind 'ctrl-y:execute-silent(echo -n {+} | wl-copy 2>/dev/null || xclip -selection clipboard 2>/dev/null)' \
            --bind 'ctrl-o:execute-silent(xdg-open {} 2>/dev/null)' \
            --bind 'ctrl-d:execute(cd {} && fish)+abort' 2>/dev/null
    )

    test -z "$selected" && return 0

    # Determine action
    switch $action
        case edit e
            nvim $selected
        case cd c
            if test -d $selected
                cd $selected
            else
                cd (dirname $selected)
            end
        case copy y
            echo -n $selected | wl-copy 2>/dev/null; or echo -n $selected | xclip -selection clipboard 2>/dev/null
            echo $_fd_green"  ✓ Copied: $selected"$_fd_reset
        case '*'
            echo $selected
    end
end

# ─── fzfdir: Interactive directory changer ────────────────────────────────────
function fzfdir --description "Fuzzy directory jump with fd + fzf"
    command -q fzf || begin
        cd ($_ash_fd_exe --type d 2>/dev/null | head -1)
        return
    end

    set -l path $argv[1]
    test -z "$path" && set path "."

    set -l target (
        $_ash_fd_exe \
            --type d \
            --hidden \
            --follow \
            --exclude .git \
            --exclude node_modules \
            --color=always \
            . $path 2>/dev/null |
        fzf --ansi \
            --border-label "  📁 Jump To Directory " \
            --border rounded \
            --prompt "  📁 " \
            --pointer "▶" \
            --preview 'eza --icons=always --color=always --group-directories-first -la {} 2>/dev/null || ls -la {}' \
            --preview-window 'right:50%:border-rounded' \
            --header '  Enter:cd  Ctrl-O:open  '
    )

    test -n "$target" && cd $target
end

# ─── fzfedit: Fuzzy file open ─────────────────────────────────────────────────
function fzfedit --description "Fuzzy find and open file in Neovim"
    set -l query  $argv[1]
    set -l editor (set -q VISUAL && echo $VISUAL || set -q EDITOR && echo $EDITOR || echo nvim)

    set -l files (
        $_ash_fd_exe \
            --type f \
            --hidden \
            --follow \
            --exclude .git \
            --exclude node_modules \
            --color=always \
            2>/dev/null |
        fzf --ansi \
            --multi \
            --border-label "  📝 Open in $editor " \
            --border rounded \
            --prompt "  📝 " \
            --pointer "▶" \
            --marker "✓" \
            --query "$query" \
            --preview 'bat --color=always --style=numbers,changes --line-range=:200 {} 2>/dev/null || cat {}' \
            --preview-window 'right:55%:border-rounded:wrap' \
            --header '  Enter:open  Tab:multi-select  '
    )

    test -n "$files" && $editor $files
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔧 ADVANCED OPERATIONS                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── fdopen: Find and open with xdg-open ──────────────────────────────────────
function fdopen --description "Find and open file with xdg-open"
    set -l pattern $argv[1]

    if test -z "$pattern"
        echo "  Usage: fdopen <pattern>"
        return 1
    end

    set -l files ($_ash_fd_exe --type f "$pattern" --color=never 2>/dev/null)

    if test -z "$files"
        echo $_fd_yellow"  ℹ  No files found matching: $pattern"$_fd_reset
        return 1
    end

    set -l count (count $files)

    if test $count -eq 1
        xdg-open $files[1] 2>/dev/null
        echo $_fd_green"  ✓ Opened: $files[1]"$_fd_reset
    else
        # Multiple matches — use fzf
        set -l selected (echo $files | tr ' ' '\n' | fzf \
            --border-label "  📂 Open File " \
            --border rounded \
            --prompt "  " \
            --pointer "▶" \
            --preview 'bat --color=always --style=plain {} 2>/dev/null || cat {}' \
            --preview-window 'right:50%:border-rounded' \
            --multi)
        test -n "$selected" && xdg-open $selected 2>/dev/null
    end
end

# ─── fdcount: Count files matching pattern ────────────────────────────────────
function fdcount --description "Count files matching a pattern"
    set -l pattern $argv[1]
    set -l path    $argv[2]
    test -z "$path" && set path "."

    set -l fd_args "--type f $path"
    test -n "$pattern" && set fd_args "$pattern --type f $path"

    set -l count (eval $_ash_fd_exe $fd_args --color=never 2>/dev/null | wc -l | string trim)
    echo "$count files"(test -n "$pattern" && echo " matching '$pattern'")
end

# ─── fddupes: Find duplicate files ────────────────────────────────────────────
function fddupes --description "Find potential duplicate files by name"
    set -l path $argv[1]
    test -z "$path" && set path "."

    echo ""
    echo $_fd_cyan"  🔍 Finding duplicate file names in: $path"$_fd_reset
    echo ""

    $_ash_fd_exe --type f --color=never $path 2>/dev/null | \
        xargs -r -I{} basename {} | \
        sort | uniq -d | \
        while read -l dup_name
            echo "  "$_fd_yellow"Duplicate: $dup_name"$_fd_reset
            $_ash_fd_exe --type f --glob "*$dup_name" $path 2>/dev/null | \
                while read -l f
                    set -l size (du -sh $f 2>/dev/null | awk '{print $1}')
                    echo "    "$_fd_dim"$f ($size)"$_fd_reset
                end
        end
    echo ""
end

# ─── fdlarge: Find large files ────────────────────────────────────────────────
function fdlarge --description "Find files larger than specified size"
    set -l size $argv[1]
    set -l path $argv[2]
    test -z "$size" && set size "+10m"
    test -z "$path" && set path "."

    echo ""
    echo $_fd_cyan"  📦 Files larger than $size in $path:"$_fd_reset
    echo ""

    $_ash_fd_exe --type f --size $size --color=never $path 2>/dev/null | \
        xargs -r -I{} sh -c 'du -sh {} 2>/dev/null | awk "{print \$1, \$2}"' | \
        sort -rh | head -30 | \
        while read -l size_str file
            printf "  $_fd_yellow%-10s$_fd_reset  $_fd_dim%s$_fd_reset\n" $size_str $file
        end
    echo ""
end

# ─── fdempty: Find empty files and directories ────────────────────────────────
function fdempty --description "Find empty files and directories"
    set -l path $argv[1]
    test -z "$path" && set path "."
    set -l type $argv[2]

    echo ""
    echo $_fd_cyan"  🕸  Empty files/directories in: $path"$_fd_reset
    echo ""

    if test "$type" != dir
        echo "  "$_fd_bold"Empty files:"$_fd_reset
        $_ash_fd_exe --type f --size -1b $path --color=never 2>/dev/null | \
            while read -l f; echo "    "$_fd_dim$f$_fd_reset; end
    end

    if test "$type" != file
        echo "  "$_fd_bold"Empty directories:"$_fd_reset
        $_ash_fd_exe --type d --size -1b $path --color=never 2>/dev/null | \
            while read -l d; echo "    "$_fd_dim$d$_fd_reset; end
    end
    echo ""
end

# ─── fdexec: Find and execute command on each match ───────────────────────────
function fdexec --description "Find files and execute command on each"
    set -l pattern $argv[1]
    set -l cmd     $argv[2..-1]

    if test -z "$pattern" || test -z "$cmd"
        echo "  Usage: fdexec <pattern> <command>"
        echo "  Example: fdexec '*.log' 'wc -l'"
        echo "           fdexec '*.py'  'python -m py_compile'"
        return 1
    end

    echo ""
    echo $_fd_cyan"  ⚡ Finding '$pattern' and running: $cmd"$_fd_reset
    echo ""

    $_ash_fd_exe --type f --glob "$pattern" --color=never 2>/dev/null | \
        while read -l file
            echo "  "$_fd_dim"→ $file"$_fd_reset
            eval $cmd $file
        end
end

# ─── fd-info: fd environment dashboard ────────────────────────────────────────
function fd-info --description "Show fd environment information"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l blue   (set_color blue)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$blue"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$blue"  ║     🔍  fd Dashboard                                 ║"$reset
    echo $bold$blue"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"Binary:   "$reset $dim$_ash_fd_exe$reset
    echo "  "$bold"Version:  "$reset $cyan($_ash_fd_exe --version 2>/dev/null)$reset
    echo ""

    echo "  "$bold"Smart aliases:"$reset
    printf "  $green%-10s$reset  %s\n" "fd"      "files + dirs (smart defaults)"
    printf "  $green%-10s$reset  %s\n" "fdf"     "files only"
    printf "  $green%-10s$reset  %s\n" "fdd"     "directories only"
    printf "  $green%-10s$reset  %s\n" "fdl"     "symlinks only"
    printf "  $green%-10s$reset  %s\n" "fdx"     "executables only"
    printf "  $green%-10s$reset  %s\n" "fde"     "find by extension"
    printf "  $green%-10s$reset  %s\n" "fds"     "find by size"
    printf "  $green%-10s$reset  %s\n" "fdm"     "find by modification time"
    printf "  $green%-10s$reset  %s\n" "fda"     "unrestricted (no gitignore)"
    printf "  $green%-10s$reset  %s\n" "fzfd"    "interactive fzf picker"
    printf "  $green%-10s$reset  %s\n" "fzfdir"  "fuzzy directory jump"
    printf "  $green%-10s$reset  %s\n" "fzfedit" "fuzzy file editor"
    printf "  $green%-10s$reset  %s\n" "fdlarge" "find large files"
    printf "  $green%-10s$reset  %s\n" "fddupes" "find duplicate filenames"
    printf "  $green%-10s$reset  %s\n" "fdempty" "find empty files/dirs"
    printf "  $green%-10s$reset  %s\n" "fdexec"  "find + execute command"
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Core fd
abbr --add fd     'fd'
abbr --add fdf    'fdf'
abbr --add fdd    'fdd'
abbr --add fdl    'fdl'
abbr --add fdx    'fdx'
abbr --add fde    'fde'
abbr --add fds    'fds'
abbr --add fdm    'fdm'
abbr --add fdn    'fdn'
abbr --add fdi    'fdi'
abbr --add fdh    'fdh'
abbr --add fda    'fda'

# Advanced
abbr --add fdopen  'fdopen'
abbr --add fdcount 'fdcount'
abbr --add fddupes 'fddupes'
abbr --add fdlarge 'fdlarge'
abbr --add fdempty 'fdempty'
abbr --add fdexec  'fdexec'

# FZF integration
abbr --add fzfd   'fzfd'
abbr --add fzfdir 'fzfdir'
abbr --add fzfe   'fzfedit'

# Info
abbr --add fdinfo 'fd-info'
abbr --add fdver  "$_ash_fd_exe --version"

# find compat aliases
abbr --add find   "$_ash_fd_exe"