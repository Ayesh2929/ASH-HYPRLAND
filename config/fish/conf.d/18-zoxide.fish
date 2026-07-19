# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — Zoxide Ultra Configuration                         ║
# ║  Smarter directory jumping with frecency-based ranking & fzf integration   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Require zoxide ─────────────────────────────────────────────────────
command -q zoxide || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_zoxide_loaded && exit 0
set --global _ash_zoxide_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  ZOXIDE CONFIGURATION                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Data directory — store DB in XDG-compliant location
set --export ZOXIDE_DATA_DIR "$HOME/.local/share/zoxide"
mkdir -p $ZOXIDE_DATA_DIR 2>/dev/null

# Hook mode: pwd hooks are fired on every prompt (fastest)
# Options: none | prompt | pwd
set --global ZOXIDE_HOOK_MODE pwd

# Exclude paths from being tracked
set --export _ZO_EXCLUDE_DIRS \
    "$HOME" \
    "$HOME/Downloads" \
    "$HOME/.cache" \
    "$HOME/.local/share/Trash" \
    "/tmp" \
    "/var/tmp" \
    "/run"

# Resolve symlinks before storing (consistent paths)
set --export _ZO_RESOLVE_SYMLINKS 1

# Maximum number of results returned by query
set --export _ZO_MAXAGE 10000

# Echo the matched directory before changing into it
set --export _ZO_ECHO 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🚀 INITIALIZE ZOXIDE                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Initialize with 'z' as the command name and 'zi' for interactive
zoxide init fish \
    --cmd z \
    --hook $ZOXIDE_HOOK_MODE \
    | source

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 FZF INTEGRATION: zi with rich preview                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Override 'zi' for enhanced fzf experience if fzf is available
if command -q fzf
    function zi --wraps='z' --description "Interactive zoxide jump with fzf preview"
        # Capture arguments for initial query
        set -l query (string join ' ' $argv)

        set -l selected (
            zoxide query --list --score 2>/dev/null |
            fzf --ansi \
                --no-sort \
                --border-label '  Jump To ' \
                --border rounded \
                --margin 1,2 \
                --padding 1 \
                --reverse \
                --height 60% \
                --min-height 15 \
                --query "$query" \
                --prompt '  ' \
                --pointer '▶' \
                --marker '✓' \
                --preview '
                    dir=$(echo {} | awk "{print \$2}")
                    if command -v eza >/dev/null 2>&1; then
                        eza --all --long --icons --color=always \
                            --group-directories-first \
                            --no-user --no-permissions \
                            "$dir" 2>/dev/null | head -30
                    else
                        ls -lah --color=always "$dir" 2>/dev/null | head -30
                    fi
                ' \
                --preview-window 'right:50%:border-rounded:wrap' \
                --header '  Score | Directory    [Enter:jump] [Ctrl-X:remove] [Ctrl-O:open] ' \
                --header-first \
                --bind 'ctrl-x:execute(zoxide remove {2})+reload(zoxide query --list --score 2>/dev/null)' \
                --bind 'ctrl-o:execute-silent(xdg-open {2} 2>/dev/null)' \
                --bind 'ctrl-y:execute-silent(echo -n {2} | wl-copy 2>/dev/null)' \
            | awk '{print $2}'
        )

        if test -n "$selected"
            # Validate directory still exists
            if test -d "$selected"
                z "$selected"
            else
                echo "  Directory no longer exists: $selected" >&2
                zoxide remove "$selected" 2>/dev/null
                return 1
            end
        end
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🏠 ENHANCED CD WRAPPER: Track every directory change                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Wrap builtin cd to also inform zoxide of manual changes
function cd --wraps='builtin cd' --description "cd with zoxide tracking"
    if test (count $argv) -eq 0
        # `cd` with no args → go home
        builtin cd $HOME
        and zoxide add $HOME 2>/dev/null
        return
    end

    switch $argv[1]
        case '-'
            # `cd -` → previous directory
            builtin cd $OLDPWD 2>/dev/null
            and zoxide add (pwd) 2>/dev/null
        case '--'
            builtin cd $argv[2..-1]
            and zoxide add (pwd) 2>/dev/null
        case '*'
            builtin cd $argv
            and zoxide add (pwd) 2>/dev/null
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔢 ZS: Score-based jump (jump to most-visited matching dir)                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function zs --description "Jump to highest-scored matching directory"
    if test (count $argv) -eq 0
        echo "  Usage: zs <query>"
        return 1
    end

    set -l target (zoxide query --score $argv 2>/dev/null | head -1 | awk '{print $2}')

    if test -n "$target" && test -d "$target"
        z "$target"
    else
        echo "  No match found for: $argv" >&2
        return 1
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📋 ZL: List zoxide database entries                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function zl --description "List zoxide entries sorted by frecency score"
    set -l count $argv[1]
    test -z "$count" && set count 30

    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l yellow (set_color yellow)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$cyan"  ╔═════════════════════════════════════════════════════╗"$reset
    echo $bold$cyan"  ║  📊 Zoxide Frecency Database (top $count)            ║"$reset
    echo $bold$cyan"  ╚═════════════════════════════════════════════════════╝"$reset
    echo ""
    printf "  $bold$yellow%-10s  %s$reset\n" "Score" "Directory"
    printf "  $dim%s$reset\n" "──────────────────────────────────────────────────"

    zoxide query --list --score 2>/dev/null |
    head -n $count |
    while read -l score dir
        # Highlight home directory specially
        if string match -q "$HOME*" $dir
            set dir_display (string replace $HOME "~" $dir)
        else
            set dir_display $dir
        end

        # Color by score
        if test (math "int($score)") -gt 100
            printf "  $green%-10.1f$reset  %s\n" $score $dir_display
        else if test (math "int($score)") -gt 50
            printf "  $yellow%-10.1f$reset  %s\n" $score $dir_display
        else
            printf "  $dim%-10.1f$reset  %s\n" $score $dir_display
        end
    end
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🧹 ZCLEAN: Remove non-existent paths from zoxide DB                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function zclean --description "Remove dead paths from zoxide database"
    set -l removed 0
    set -l kept 0

    echo ""
    echo "  🧹 Cleaning zoxide database..."
    echo ""

    for entry in (zoxide query --list 2>/dev/null)
        if not test -d $entry
            zoxide remove $entry 2>/dev/null
            echo "  ✗ Removed: $entry"
            set removed (math $removed + 1)
        else
            set kept (math $kept + 1)
        end
    end

    echo ""
    echo "  ✓ Kept:    $kept entries"
    echo "  ✗ Removed: $removed entries"
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🏔️  ZTOP: Most-visited directories                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function ztop --description "Show top N most-visited directories"
    set -l n $argv[1]
    test -z "$n" && set n 10

    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l yellow (set_color yellow)

    echo ""
    echo $bold$cyan"  🏔️  Top $n most-visited directories:"$reset
    echo ""

    set -l rank 1
    zoxide query --list --score 2>/dev/null | head -n $n | while read -l score dir
        set -l display (string replace $HOME "~" $dir)

        switch $rank
            case 1; set medal "🥇"
            case 2; set medal "🥈"
            case 3; set medal "🥉"
            case '*'; set medal "  $rank."
        end

        printf "  %s  $green%-6.0f$reset  %s\n" $medal $score $display
        set rank (math $rank + 1)
    end
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔗 ZCD: Smart project root finder                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function zroot --description "Jump to project root (git root or first parent with marker)"
    # Walk up looking for project root markers
    set -l markers \
        ".git" \
        "Cargo.toml" \
        "go.mod" \
        "pyproject.toml" \
        "package.json" \
        "flake.nix" \
        "Makefile" \
        "justfile" \
        "Dockerfile" \
        ".editorconfig"

    set -l current (pwd)
    set -l found ""

    while test "$current" != "/"
        for marker in $markers
            if test -e "$current/$marker"
                set found $current
                break
            end
        end
        test -n "$found" && break
        set current (dirname $current)
    end

    if test -n "$found"
        z $found
        echo "  ↳ Project root: $found"
    else
        echo "  No project root found" >&2
        return 1
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📡 ZOXIDE COMPLETIONS for z and zi                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __zoxide_complete_z
    set -l token (commandline -tc)
    zoxide query --list 2>/dev/null | \
        string replace $HOME '~' | \
        grep -i -- "$token"
end

complete -c z  -f -a '(__zoxide_complete_z)' --description 'zoxide directory'
complete -c zi -f -a '(__zoxide_complete_z)' --description 'zoxide directory (interactive)'
complete -c zs -f -a '(__zoxide_complete_z)' --description 'zoxide directory (scored)'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add zq    'zoxide query'
abbr --add zqs   'zoxide query --score'
abbr --add zql   'zoxide query --list'
abbr --add za    'zoxide add'
abbr --add zrm   'zoxide remove'
abbr --add zedit 'zoxide edit'
abbr --add zdb   'zl'
abbr --add ztop  'ztop'
abbr --add zcl   'zclean'
abbr --add zr    'zroot'