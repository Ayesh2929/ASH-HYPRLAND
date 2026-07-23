# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — ripgrep Ultra Configuration                        ║
# ║  Blazing-fast grep with smart defaults, fzf integration & rich output      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Require ripgrep ────────────────────────────────────────────────────
command -q rg || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_rg_loaded && exit 0
set --global _ash_rg_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_rg_log     "$HOME/.local/share/ash/logs/rg.log"
set --global _ash_rg_cache   "$HOME/.local/share/ash/cache/rg"
set --global _ash_rg_config  "$HOME/.config/ripgrep/ripgreprc"
set --global _ash_rg_ignore  "$HOME/.config/ripgrep/.ignore"

mkdir -p (dirname $_ash_rg_log)    2>/dev/null
mkdir -p $_ash_rg_cache             2>/dev/null
mkdir -p (dirname $_ash_rg_config)  2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _rg_reset   (set_color normal)
set -g _rg_bold    (set_color --bold)
set -g _rg_cyan    (set_color cyan)
set -g _rg_green   (set_color green)
set -g _rg_yellow  (set_color yellow)
set -g _rg_red     (set_color red)
set -g _rg_blue    (set_color blue)
set -g _rg_dim     (set_color brblack)
set -g _rg_orange  (set_color FF6B35)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  ENVIRONMENT CONFIGURATION                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Config file ───────────────────────────────────────────────────────────────
set --export RIPGREP_CONFIG_PATH $_ash_rg_config

# ── Write config if missing ───────────────────────────────────────────────────
if not test -f $_ash_rg_config
    echo '# ── ripgrep Configuration — ASH DOTFILES v5.0 ──────────────────────────────

# Smart case: case-insensitive unless pattern has uppercase
--smart-case

# Always use color
--color=always

# Show line numbers
--line-number

# Show column numbers
--column

# Follow symlinks
--follow

# Show context around matches (configurable per-command)
# --context=2

# Sorting (can be: none | path | modified | accessed | created)
--sort=path

# Glob patterns to always ignore
--glob=!.git
--glob=!node_modules
--glob=!.cache
--glob=!__pycache__
--glob=!target
--glob=!dist
--glob=!build
--glob=!.next
--glob=!.nuxt
--glob=!*.min.js
--glob=!*.min.css
--glob=!*.lock
--glob=!pnpm-lock.yaml
--glob=!package-lock.json
--glob=!yarn.lock
--glob=!bun.lockb
--glob=!*.pb.go
--glob=!*.pb.ts
--glob=!.svelte-kit

# Type definitions for custom file types
--type-add=config:*.conf
--type-add=config:*.cfg
--type-add=config:*.ini
--type-add=config:*.toml
--type-add=config:*.yaml
--type-add=config:*.yml
--type-add=config:*.json
--type-add=config:*.jsonc
--type-add=env:*.env
--type-add=env:.env
--type-add=env:.env.*
--type-add=fish:*.fish
--type-add=hypr:*.conf
--type-add=rasi:*.rasi
--type-add=nix:*.nix
--type-add=lua:*.lua
--type-add=hcl:*.hcl
--type-add=hcl:*.tf
--type-add=helm:*.yaml
--type-add=helm:Chart.yaml
--type-add=kdl:*.kdl

# Max file size to search (skip huge binaries)
--max-filesize=50M

# Colors (Catppuccin Mocha palette)
--colors=match:fg:203,166,247
--colors=match:style:bold
--colors=line:fg:137,180,250
--colors=path:fg,166,227,161
--colors=path:style:bold
--colors=column:fg:148,226,213' > $_ash_rg_config
end

# ── Write .ignore file ────────────────────────────────────────────────────────
if not test -f $_ash_rg_ignore
    echo '# ripgrep global .ignore — ASH DOTFILES v5.0
.git/
node_modules/
target/
dist/
build/
.cache/
__pycache__/
*.pyc
*.pyo
*.class
*.o
*.so
*.dylib
*.dll
*.exe
*.bin
*.out
*.jar
*.war
*.ear
*.zip
*.tar
*.tar.gz
*.tar.bz2
*.tar.xz
*.rar
*.7z
*.gz
*.bz2
*.xz
*.zst
*.db
*.sqlite
*.sqlite3
*.lock
*.sum
package-lock.json
pnpm-lock.yaml
yarn.lock
bun.lockb
Cargo.lock
poetry.lock
.terraform/
.vagrant/' > $_ash_rg_ignore
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 SMART SEARCH FUNCTIONS                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── rga: ripgrep with all hidden files ────────────────────────────────────────
function rga --description "rg including hidden files"
    rg --hidden $argv
end

# ─── rgu: ripgrep without .gitignore (unrestricted) ────────────────────────────
function rgu --description "rg without .gitignore restrictions"
    rg --no-ignore --hidden $argv
end

# ─── rgf: ripgrep in specific file types ──────────────────────────────────────
function rgf --description "rg filtered by file type (rgf <type> <pattern>)"
    set -l filetype $argv[1]
    set -l pattern  $argv[2]

    if test -z "$filetype" || test -z "$pattern"
        echo "  Usage: rgf <filetype> <pattern> [path]"
        echo ""
        echo "  Types: py rs go ts js lua fish sh yaml json toml md config env hypr"
        return 1
    end

    rg --type=$filetype $pattern $argv[3..-1]
end

# ─── rgc: Count matches per file ──────────────────────────────────────────────
function rgc --description "Count pattern matches per file"
    set -l pattern $argv[1]
    test -z "$pattern" && begin; echo "  Usage: rgc <pattern> [path]"; return 1; end

    rg --count --sort=count $pattern $argv[2..-1] | \
        sort -t: -k2 -rn | head -30 | \
        while read -l line
            set -l file  (echo $line | cut -d: -f1)
            set -l count (echo $line | cut -d: -f2)
            printf "  $_rg_cyan%-6s$_rg_reset  %s\n" $count $file
        end
end

# ─── rgl: rg + bat preview (live grep) ────────────────────────────────────────
function rgl --description "Live interactive ripgrep with fzf + bat preview"
    command -q fzf || begin; rg $argv; return; end

    set -l initial_query (string join ' ' $argv)

    set -l result (
        FZF_DEFAULT_COMMAND="rg --column --line-number --no-heading \
            --color=always --smart-case -- '$initial_query' 2>/dev/null || true" \
        fzf --ansi \
            --disabled \
            --query "$initial_query" \
            --border-label "  🔍 Live Search " \
            --border rounded \
            --prompt "  🔍 " \
            --pointer "▶" \
            --delimiter : \
            --preview '
                file={1}
                line={2}
                bat --color=always --style=numbers,changes \
                    --highlight-line $line \
                    --line-range (math $line - 5):(math $line + 30) \
                    "$file" 2>/dev/null || cat "$file"
            ' \
            --preview-window 'right:55%:border-rounded:wrap' \
            --header '  Type to search  Enter:open  Ctrl-Y:copy path  ' \
            --bind "change:reload:rg --column --line-number --no-heading \
                --color=always --smart-case -- {q} 2>/dev/null || true" \
            --bind 'ctrl-y:execute-silent(echo {1} | wl-copy 2>/dev/null || xclip -selection clipboard 2>/dev/null)' \
            --bind 'ctrl-o:execute-silent(xdg-open {1} 2>/dev/null)'
    )

    if test -n "$result"
        set -l file (echo $result | cut -d: -f1)
        set -l line (echo $result | cut -d: -f2)
        set -l editor (set -q VISUAL && echo $VISUAL || echo nvim)
        $editor +"$line" "$file"
    end
end

# ─── rgr: Replace pattern in files ────────────────────────────────────────────
function rgr --description "Replace pattern across files (preview before replacing)"
    set -l pattern $argv[1]
    set -l replace $argv[2]
    set -l path    $argv[3]
    test -z "$path" && set path "."

    if test -z "$pattern" || test -z "$replace"
        echo "  Usage: rgr <pattern> <replacement> [path]"
        echo "  Example: rgr 'old_func' 'new_func' ./src"
        return 1
    end

    echo ""
    echo $_rg_cyan"  🔄 Replace preview: '$pattern' → '$replace'"$_rg_reset
    echo ""

    # Show what will change
    rg "$pattern" $path --color=always -l 2>/dev/null | head -20 | while read -l file
        echo "  "$_rg_dim"Will modify: "$file$_rg_reset
    end

    set -l match_count (rg "$pattern" $path -c 2>/dev/null | \
        awk -F: '{sum+=$2} END{print sum}')

    echo ""
    echo "  Total matches: "$_rg_yellow$match_count$_rg_reset
    echo ""
    read -P "  Apply replacements? [y/N] " confirm
    string match -qi 'y*' $confirm || return 0

    # Use sd (sed replacement) if available, else sed
    if command -q sd
        rg --files-with-matches "$pattern" $path 2>/dev/null | \
            xargs -r sd "$pattern" "$replace"
    else
        rg --files-with-matches "$pattern" $path 2>/dev/null | \
            xargs -r sed -i "s/$pattern/$replace/g"
    end

    and echo $_rg_green"  ✓ Replacements applied"$_rg_reset
end

# ─── rgsym: Search including symlinks ─────────────────────────────────────────
function rgsym --description "rg following symlinks"
    rg --follow $argv
end

# ─── rgw: Search whole words only ─────────────────────────────────────────────
function rgw --description "rg searching whole words only"
    rg --word-regexp $argv
end

# ─── rgt: Search with context ─────────────────────────────────────────────────
function rgt --description "rg with before/after context lines"
    set -l context $argv[1]
    set -l pattern $argv[2]

    if not string match -qr '^\d+$' $context
        set pattern $context
        set context 3
    end

    test -z "$pattern" && begin; echo "  Usage: rgt [context_lines] <pattern>"; return 1; end

    rg --context=$context $pattern $argv[3..-1]
end

# ─── rgd: Search in current git diff ──────────────────────────────────────────
function rgd --description "Search within current git diff changes"
    set -l pattern $argv[1]
    test -z "$pattern" && begin; echo "  Usage: rgd <pattern>"; return 1; end

    command -q git || begin; echo "  Not in a git repo"; return 1; end

    git diff HEAD 2>/dev/null | rg "$pattern" --passthru $argv[2..-1]
end

# ─── rgstat: Statistics on search ─────────────────────────────────────────────
function rgstat --description "Show ripgrep match statistics"
    set -l pattern $argv[1]
    set -l path    $argv[2]
    test -z "$path" && set path "."

    if test -z "$pattern"
        echo "  Usage: rgstat <pattern> [path]"
        return 1
    end

    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l yellow (set_color yellow)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$_rg_orange"  📊 ripgrep Statistics: '$pattern'"$reset
    echo ""

    set -l matches (rg "$pattern" $path --count 2>/dev/null)

    set -l total_files  (echo $matches | wc -l | string trim)
    set -l total_hits   (echo $matches | awk -F: '{sum+=$2} END{print sum}')

    echo "  "$bold"Files with matches: "$reset $cyan$total_files$reset
    echo "  "$bold"Total occurrences:  "$reset $cyan$total_hits$reset
    echo ""

    # Top files
    echo "  "$bold"Top files:"$reset
    echo $matches | sort -t: -k2 -rn | head -10 | \
    while read -l line
        set -l file  (echo $line | cut -d: -f1)
        set -l count (echo $line | cut -d: -f2)
        printf "  $yellow%-6s$reset  $dim%s$reset\n" $count $file
    end
    echo ""

    # Extension breakdown
    echo "  "$bold"By extension:"$reset
    echo $matches | cut -d: -f1 | \
        rev | cut -d. -f1 | rev | sort | uniq -c | sort -rn | head -10 | \
        while read -l count ext
            printf "  $cyan%-12s$reset  $dim%s matches$reset\n" ".$ext" $count
        end
    echo ""
end

# ─── rgi: Ripgrep info dashboard ─────────────────────────────────────────────
function rgi --description "Show ripgrep configuration and info"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l orange (set_color FF6B35)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$orange"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$orange"  ║     🔍  ripgrep Dashboard                            ║"$reset
    echo $bold$orange"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"Version:     "$reset $cyan(rg --version 2>/dev/null | head -1)$reset
    echo "  "$bold"Config:      "$reset $dim$RIPGREP_CONFIG_PATH$reset
    echo "  "$bold"Ignore file: "$reset $dim$_ash_rg_ignore$reset
    echo ""

    # Available type definitions
    set -l type_count (rg --type-list 2>/dev/null | wc -l | string trim)
    echo "  "$bold"File types:  "$reset $cyan$type_count$reset
    echo ""

    echo "  "$bold"Smart aliases:"$reset
    printf "  $green%-8s$reset  %s\n" "rga"   "search hidden files"
    printf "  $green%-8s$reset  %s\n" "rgu"   "no .gitignore restrictions"
    printf "  $green%-8s$reset  %s\n" "rgf"   "search specific file type"
    printf "  $green%-8s$reset  %s\n" "rgc"   "count matches per file"
    printf "  $green%-8s$reset  %s\n" "rgl"   "live interactive search (fzf)"
    printf "  $green%-8s$reset  %s\n" "rgr"   "find and replace"
    printf "  $green%-8s$reset  %s\n" "rgt"   "search with context"
    printf "  $green%-8s$reset  %s\n" "rgstat" "match statistics"
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Core rg
abbr --add rg     'rg'
abbr --add rga    'rga'
abbr --add rgu    'rgu'
abbr --add rgf    'rgf'
abbr --add rgc    'rgc'
abbr --add rgl    'rgl'
abbr --add rgr    'rgr'
abbr --add rgw    'rgw'
abbr --add rgt    'rgt'
abbr --add rgd    'rgd'
abbr --add rgstat 'rgstat'
abbr --add rgsym  'rgsym'
abbr --add rginfo 'rgi'

# Type shortcuts
abbr --add rgpy   'rg --type=py'
abbr --add rgrs   'rg --type=rust'
abbr --add rggo   'rg --type=go'
abbr --add rgts   'rg --type=ts'
abbr --add rgjs   'rg --type=js'
abbr --add rglua  'rg --type=lua'
abbr --add rgsh   'rg --type=sh'
abbr --add rgmd   'rg --type=md'
abbr --add rgjson 'rg --type=json'
abbr --add rgyml  'rg --type=yaml'
abbr --add rgtoml 'rg --type=toml'
abbr --add rgcss  'rg --type=css'
abbr --add rghtml 'rg --type=html'
abbr --add rgdkr  'rg --type=docker'
abbr --add rgfish 'rgf fish'
abbr --add rghypr 'rgf hypr'
abbr --add rgnix  'rgf nix'
abbr --add rghcl  'rgf hcl'

# Useful flags
abbr --add rgls   'rg --files'
abbr --add rgtypes 'rg --type-list'
abbr --add rgnoi  'rg --no-ignore'
abbr --add rgcase 'rg --case-sensitive'
abbr --add rgfix  'rg --fixed-strings'