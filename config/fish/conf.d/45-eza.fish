# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — eza Ultra Configuration                            ║
# ║  Modern ls replacement with icons, git, timestamps & full theme sync       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Require eza ────────────────────────────────────────────────────────
command -q eza || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_eza_loaded && exit 0
set --global _ash_eza_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_eza_log    "$HOME/.local/share/ash/logs/eza.log"
set --global _ash_eza_cache  "$HOME/.local/share/ash/cache/eza"

mkdir -p (dirname $_ash_eza_log) 2>/dev/null
mkdir -p $_ash_eza_cache          2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _ez_reset   (set_color normal)
set -g _ez_bold    (set_color --bold)
set -g _ez_cyan    (set_color cyan)
set -g _ez_green   (set_color green)
set -g _ez_yellow  (set_color yellow)
set -g _ez_red     (set_color red)
set -g _ez_dim     (set_color brblack)
set -g _ez_blue    (set_color blue)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  ENVIRONMENT CONFIGURATION                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── EZA_COLORS: Dynamic color theme sync with ASH ─────────────────────────────
function __ash_eza_build_colors --description "Build EZA_COLORS from ASH theme"
    set -l state_file "$HOME/.local/share/ash/state/current-theme.json"
    set -l cache      "$_ash_eza_cache/colors"

    # Fast path: use cache
    if test -f $cache
        set -l age (math (date +%s) - (stat -c %Y $cache 2>/dev/null; or echo 0))
        test $age -lt 10 && cat $cache && return
    end

    # ── Base eza color spec ────────────────────────────────────────────────────
    # Format: TYPE=ANSI_CODE:TYPE=ANSI_CODE:...
    # We use 24-bit colors where possible via eza's color spec
    set -l colors \
        "da=38;2;166;227;161"   \  # date — green
        "fi=38;2;205;214;244"   \  # regular file — text
        "di=38;2;137;180;250"   \  # directory — blue (bold done via eza flag)
        "ex=38;2;166;227;161"   \  # executable — green
        "ln=38;2;249;226;175"   \  # symlink — yellow
        "or=38;2;243;139;168"   \  # orphan symlink — red
        "pi=38;2;148;226;213"   \  # pipe — teal
        "so=38;2;203;166;247"   \  # socket — mauve
        "bd=38;2;243;139;168"   \  # block device — red
        "cd=38;2;243;139;168"   \  # char device — red
        "ur=38;2;166;227;161"   \  # user read — green
        "uw=38;2;249;226;175"   \  # user write — yellow
        "ux=38;2;243;139;168"   \  # user exec — red
        "ue=38;2;243;139;168"   \  # user exec other — red
        "gr=38;2;166;227;161"   \  # group read — green
        "gw=38;2;249;226;175"   \  # group write — yellow
        "gx=38;2;243;139;168"   \  # group exec — red
        "tr=38;2;166;227;161"   \  # other read — green
        "tw=38;2;249;226;175"   \  # other write — yellow
        "tx=38;2;243;139;168"   \  # other exec — red
        "sn=38;2;148;226;213"   \  # filesize number — teal
        "sb=38;2;166;173;200"   \  # filesize unit — subtext
        "uu=38;2;203;166;247"   \  # user (you) — mauve
        "un=38;2;243;139;168"   \  # user (not you) — red
        "gu=38;2;137;180;250"   \  # group (yours) — blue
        "gn=38;2;243;139;168"   \  # group (not yours) — red
        "lc=38;2;249;226;175"   \  # hard link count — yellow
        "lm=38;2;243;139;168"   \  # hard link count (multiple) — red
        "ga=38;2;166;227;161"   \  # git added — green
        "gm=38;2;137;180;250"   \  # git modified — blue
        "gd=38;2;243;139;168"   \  # git deleted — red
        "gv=38;2;203;166;247"   \  # git renamed — mauve
        "gt=38;2;249;226;175"   \  # git type changed — yellow
        "gi=38;2;166;173;200"   \  # git ignored — subtext0
        "gc=38;2;148;226;213"   \  # git conflicted — teal
        "Gm=38;2;137;180;250"   \  # git branch modified — blue
        "Go=38;2;249;226;175"   \  # git branch staged — yellow
        "Gc=38;2;166;227;161"   \  # git branch clean — green
        "Gd=38;2;243;139;168"   \  # git branch dirty — red
        "xx=38;2;108;112;134"   \  # punctuation — overlay0
        "df=38;2;148;226;213"   \  # device — teal
        "ds=38;2;166;173;200"   \  # device ID — subtext0
        "mp=38;2;137;180;250"   \  # mount point — blue
        "im=38;2;203;166;247"   \  # image file — mauve
        "vi=38;2;243;139;168"   \  # video file — red
        "mu=38;2;166;227;161"   \  # music file — green
        "lo=38;2;249;226;175"   \  # log file — yellow
        "cr=38;2;243;139;168"   \  # crypto file — red
        "do=38;2;137;180;250"   \  # document — blue
        "co=38;2;249;226;175"   \  # compressed — yellow
        "tm=38;2;166;173;200"   \  # temporary — subtext0
        "cm=38;2;148;226;213"   \  # cmake/make — teal
        "bu=38;2;249;226;175"   \  # build — yellow
        "sc=38;2;203;166;247"   \  # source — mauve
        "cf=38;2;148;226;213"   \  # config — teal
        "ht=38;2;243;139;168"   \  # html/template — red
        "aw=38;2;137;180;250"   \  # audio work — blue
        "ng=38;2;243;139;168"   \  # ninja build — red
        "sh=38;2;166;227;161"   \  # shell script — green
        "bd=38;2;249;226;175"   \  # build def — yellow
        "bl=38;2;166;173;200"   \  # blank/empty — subtext0
        "ed=38;2;203;166;247"   \  # editor — mauve
        "co=38;2;249;226;175"   \  # compressed arch — yellow
        "js=38;2;249;226;175"   \  # javascript — yellow
        "ts=38;2;137;180;250"   \  # typescript — blue
        "py=38;2;148;226;213"   \  # python — teal
        "rs=38;2;249;226;175"   \  # rust — orange-ish
        "go=38;2;148;226;213"   \  # go — teal
        "rb=38;2;243;139;168"   \  # ruby — red
        "jv=38;2;249;226;175"   \  # java — yellow
        "kt=38;2;203;166;247"   \  # kotlin — mauve
        "sw=38;2;243;139;168"   \  # swift — red
        "cs=38;2;203;166;247"   \  # csharp — mauve
        "hs=38;2;203;166;247"   \  # haskell — mauve
        "lu=38;2;137;180;250"   \  # lua — blue
        "cp=38;2;137;180;250"   \  # cpp — blue
        "cc=38;2;137;180;250"   \  # c — blue
        "ni=38;2;166;227;161"   \  # nix — green
        "pl=38;2;137;180;250"   \  # perl — blue
        "pp=38;2;249;226;175"   \  # php — yellow
        "zg=38;2;249;226;175"   \  # zig — yellow
        "el=38;2;203;166;247"   \  # elixir — mauve
        "ex=38;2;203;166;247"   \  # erlang — mauve
        "cl=38;2;249;226;175"   \  # clojure — yellow
        "oc=38;2;249;226;175"   \  # ocaml — yellow
        "gr=38;2;137;180;250"   \  # graphql — blue
        "ql=38;2;148;226;213"   \  # sql — teal
        "xt=38;2;166;173;200"   \  # xml/html — subtext
        "md=38;2;137;180;250"   \  # markdown — blue
        "rt=38;2;166;173;200"   \  # rst — subtext
        "to=38;2;249;226;175"   \  # toml — yellow
        "ya=38;2;249;226;175"   \  # yaml — yellow
        "jn=38;2;249;226;175"   \  # json — yellow
        "in=38;2;166;173;200"   \  # ini — subtext
        "en=38;2;249;226;175"   \  # env — yellow
        "dc=38;2;137;180;250"   \  # docker — blue
        "tf=38;2;203;166;247"   \  # terraform — mauve
        "hm=38;2;148;226;213"   \  # helm — teal
        "gi=38;2;166;173;200"   \  # gitignore — subtext
        "lk=38;2;249;226;175"   \  # lock files — yellow
        "pk=38;2;166;227;161"   \  # package files — green
        "dn=38;2;243;139;168"   \  # dotfile — red
        "Sn=38;2;148;226;213"   \  # symlink num — teal
        "bW=38;2;243;139;168"   \  # broken links — red
        "Sn=38;2;148;226;213"   \  # socket num — teal
        "hd=38;2;166;173;200"     # header — subtext

    set -l result (string join ':' $colors)
    echo $result > $cache 2>/dev/null
    echo $result
end

set --export EZA_COLORS (__ash_eza_build_colors)

# ── Icon theme (requires Nerd Font) ──────────────────────────────────────────
set --export EZA_ICONS_AUTO 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🗂️  SMART ls REPLACEMENTS                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Core flag sets ─────────────────────────────────────────────────────────────
set --global _ez_base    "--icons=always --group-directories-first --color=always"
set --global _ez_detail  "--long --git --git-repos --no-user --time-style=relative"
set --global _ez_all     "--all"
set --global _ez_header  "--header"
set --global _ez_sort    "--sort=name"
set --global _ez_octal   "--octal-permissions"
set --global _ez_total   "--total-size"

# ── ls: Main replacement ──────────────────────────────────────────────────────
function ls --wraps='eza' --description "eza-powered ls replacement"
    eza $_ez_base $_ez_sort $argv
end

# ── la: Long + hidden ─────────────────────────────────────────────────────────
function la --description "Long listing with hidden files"
    eza $_ez_base $_ez_detail $_ez_all $_ez_header $_ez_octal $argv
end

# ── ll: Long listing ──────────────────────────────────────────────────────────
function ll --description "Detailed long listing"
    eza $_ez_base $_ez_detail $_ez_header $_ez_total $argv
end

# ── l: Compact long listing ───────────────────────────────────────────────────
function l --description "Compact long listing (no user/group)"
    eza $_ez_base --long --git --no-user --no-permissions $argv
end

# ── lt: Tree view ─────────────────────────────────────────────────────────────
function lt --description "Tree view with configurable depth"
    set -l depth $argv[1]
    set -l path  $argv[2]

    # If first arg is not a number, treat as path
    if not string match -qr '^\d+$' $depth
        set path  $depth
        set depth 3
    end

    test -z "$depth" && set depth 3
    test -z "$path"  && set path  "."

    eza $_ez_base --tree --level=$depth $argv[3..-1] $path
end

# ── lta: Tree view with hidden ────────────────────────────────────────────────
function lta --description "Tree view including hidden files"
    set -l depth $argv[1]
    set -l path  $argv[2]

    if not string match -qr '^\d+$' $depth
        set path  $depth
        set depth 3
    end

    test -z "$depth" && set depth 3
    test -z "$path"  && set path  "."

    eza $_ez_base --tree --level=$depth --all $argv[3..-1] $path
end

# ── llt: Long tree ────────────────────────────────────────────────────────────
function llt --description "Long listing in tree format"
    set -l depth $argv[1]
    set -l path  $argv[2]

    if not string match -qr '^\d+$' $depth
        set path  $depth
        set depth 2
    end

    test -z "$depth" && set depth 2
    test -z "$path"  && set path  "."

    eza $_ez_base $_ez_detail --tree --level=$depth $argv[3..-1] $path
end

# ── lg: Long with git status ──────────────────────────────────────────────────
function lg --description "Long listing with full git status"
    eza $_ez_base --long \
        --git \
        --git-repos \
        --git-ignore \
        --header \
        --all \
        $argv
end

# ── lk: Sort by size ──────────────────────────────────────────────────────────
function lk --description "List sorted by file size (largest first)"
    eza $_ez_base --long \
        --sort=size \
        --reverse \
        --total-size \
        --no-user \
        $argv
end

# ── ln: Sort by name ──────────────────────────────────────────────────────────
function lsn --description "List sorted by name (explicit)"
    eza $_ez_base --sort=name $argv
end

# ── lm: Sort by modification time ─────────────────────────────────────────────
function lm --description "List sorted by modification time (newest first)"
    eza $_ez_base --long \
        --sort=modified \
        --reverse \
        --time-style=long-iso \
        --no-user \
        $argv
end

# ── lc: Sort by creation time ─────────────────────────────────────────────────
function lc --description "List sorted by creation time (newest first)"
    eza $_ez_base --long \
        --sort=created \
        --reverse \
        --time=created \
        --no-user \
        $argv
end

# ── lx: Sort by extension ─────────────────────────────────────────────────────
function lx --description "List sorted by extension"
    eza $_ez_base --sort=extension $argv
end

# ── ld: List only directories ─────────────────────────────────────────────────
function ld --description "List only directories"
    eza $_ez_base --only-dirs $argv
end

# ── lf: List only files ───────────────────────────────────────────────────────
function lf --description "List only files (no directories)"
    eza $_ez_base --only-files $argv
end

# ── lh: List hidden only ──────────────────────────────────────────────────────
function lh --description "List only hidden files/directories"
    eza $_ez_base --all $argv | grep --color=never '^\.'
end

# ── lp: Show with octal permissions ───────────────────────────────────────────
function lp --description "List with octal permissions"
    eza $_ez_base --long \
        --octal-permissions \
        --no-permissions \
        --no-user \
        --no-time \
        $argv
end

# ── lz: Large files ───────────────────────────────────────────────────────────
function lz --description "List large files (> 1MB)"
    eza $_ez_base --long \
        --sort=size \
        --reverse \
        --total-size \
        --no-user \
        $argv | \
        # Filter by size: keep header + large files
        awk 'NR==1 || /[0-9]+(M|G|T)/'
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 SMART SEARCH FUNCTIONS                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── lgrep: Filter listing by pattern ─────────────────────────────────────────
function lgrep --description "List files matching a pattern"
    set -l pattern $argv[1]
    set -l path    $argv[2]
    test -z "$path" && set path "."

    if test -z "$pattern"
        echo "  Usage: lgrep <pattern> [path]"
        return 1
    end

    eza $_ez_base $path | grep --color=always -i $pattern
end

# ─── ltree: Interactive tree navigator ────────────────────────────────────────
function ltree --description "Interactive directory tree navigator (fzf)"
    command -q fzf || begin; lt 3 $argv; return; end

    set -l root $argv[1]
    test -z "$root" && set root "."

    set -l selected (
        eza --tree --level=8 --all --icons=always --color=always $root 2>/dev/null |
        fzf --ansi \
            --border-label "  🌲 Directory Tree " \
            --border rounded \
            --prompt "  🗂  " \
            --pointer "▶" \
            --preview '
                item=$(echo {} | sed "s/^[^a-zA-Z.]*//" | string trim)
                if [ -d "$item" ]; then
                    eza --icons=always --color=always --group-directories-first -la "$item" 2>/dev/null
                elif [ -f "$item" ]; then
                    bat --color=always --style=numbers,changes --line-range=:100 "$item" 2>/dev/null || cat "$item"
                fi
            ' \
            --preview-window 'right:55%:border-rounded:wrap' \
            --header '  Enter:open  Ctrl-O:open dir  ' \
            --bind 'ctrl-o:execute(eza --icons=always --color=always -la {} 2>/dev/null | less -R)' \
            --multi
    )

    test -n "$selected" && echo $selected | string trim | string replace -r '^[^a-zA-Z.]*' ''
end

# ─── ldepth: Show directory depth statistics ───────────────────────────────────
function ldepth --description "Show directory structure depth analysis"
    set -l path $argv[1]
    test -z "$path" && set path "."

    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$cyan"  📊 Directory Analysis: $path"$reset
    echo ""

    # Count files at each depth
    for depth in 1 2 3 4 5
        set -l count (find $path -maxdepth $depth -mindepth $depth -type f 2>/dev/null | wc -l | string trim)
        set -l dirs  (find $path -maxdepth $depth -mindepth $depth -type d 2>/dev/null | wc -l | string trim)

        printf "  $bold%-8s$reset  $cyan%6s files$reset  $dim%6s dirs$reset\n" \
            "depth/$depth" $count $dirs
    end

    echo ""

    # Total size
    set -l total_size (du -sh $path 2>/dev/null | awk '{print $1}')
    set -l file_count (find $path -type f 2>/dev/null | wc -l | string trim)
    set -l dir_count  (find $path -type d 2>/dev/null | wc -l | string trim)

    echo "  "$bold"Total size:  "$reset $cyan$total_size$reset
    echo "  "$bold"Total files: "$reset $cyan$file_count$reset
    echo "  "$bold"Total dirs:  "$reset $cyan$dir_count$reset
    echo ""
end

# ─── lhist: Most recently modified files ──────────────────────────────────────
function lhist --description "Show recently modified files across the tree"
    set -l n    $argv[1]
    set -l path $argv[2]
    test -z "$n"    && set n 20
    test -z "$path" && set path "."

    echo ""
    echo $_ez_bold$_ez_cyan"  🕐 Recently Modified Files (top $n)"$_ez_reset
    echo ""

    find $path -type f -not -path "*/.git/*" 2>/dev/null |
        xargs -r stat --format="%Y %n" 2>/dev/null |
        sort -rn | head -$n |
        while read -l ts file
            set -l time (date -d @$ts '+%Y-%m-%d %H:%M' 2>/dev/null; \
                or date -r $ts '+%Y-%m-%d %H:%M' 2>/dev/null)
            printf "  $_ez_dim%s$_ez_reset  %s\n" $time $file
        end
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📊 EZA INFO & MANAGEMENT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── eza-info: eza environment dashboard ──────────────────────────────────────
function eza-info --description "Show eza environment information"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)
    set -l blue   (set_color blue)

    echo ""
    echo $bold$blue"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$blue"  ║     📁  eza Environment Dashboard                    ║"$reset
    echo $bold$blue"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"Version:    "$reset $cyan(eza --version 2>/dev/null | head -1)$reset
    echo "  "$bold"Icons:      "$reset (test "$EZA_ICONS_AUTO" = 1 && echo $green"enabled"$reset || echo $dim"disabled"$reset)
    echo "  "$bold"Colors:     "$reset $dim"(EZA_COLORS set)"$reset
    echo ""

    echo "  "$bold"Aliases:"$reset
    printf "  $green%-8s$reset  %s\n" "ls"  "basic listing with icons"
    printf "  $green%-8s$reset  %s\n" "ll"  "long detailed listing"
    printf "  $green%-8s$reset  %s\n" "la"  "long listing + hidden files"
    printf "  $green%-8s$reset  %s\n" "lt"  "tree view (lt [depth] [path])"
    printf "  $green%-8s$reset  %s\n" "lg"  "listing with git status"
    printf "  $green%-8s$reset  %s\n" "lk"  "sort by size"
    printf "  $green%-8s$reset  %s\n" "lm"  "sort by modification time"
    printf "  $green%-8s$reset  %s\n" "ld"  "directories only"
    printf "  $green%-8s$reset  %s\n" "lf"  "files only"
    printf "  $green%-8s$reset  %s\n" "lz"  "large files (>1MB)"
    printf "  $green%-8s$reset  %s\n" "lp"  "with octal permissions"
    echo ""
end

# ── Theme sync ────────────────────────────────────────────────────────────────
function __ash_eza_on_theme_change --on-event ash_theme_changed \
    --description "Rebuild EZA_COLORS on ASH theme change"
    rm -f "$_ash_eza_cache/colors" 2>/dev/null
    set --export EZA_COLORS (__ash_eza_build_colors)
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Listing variants
abbr --add ls    'ls'
abbr --add ll    'll'
abbr --add la    'la'
abbr --add l     'l'
abbr --add lt    'lt'
abbr --add lta   'lta'
abbr --add llt   'llt'
abbr --add lg    'lg'
abbr --add lk    'lk'
abbr --add lm    'lm'
abbr --add lc    'lc'
abbr --add lx    'lx'
abbr --add ld    'ld'
abbr --add lf    'lf'
abbr --add lh    'lh'
abbr --add lp    'lp'
abbr --add lz    'lz'

# Search & nav
abbr --add lgrep 'lgrep'
abbr --add ltree 'ltree'
abbr --add ldep  'ldepth'
abbr --add lhist 'lhist'

# Info
abbr --add ezinfo 'eza-info'
abbr --add ezver  'eza --version'