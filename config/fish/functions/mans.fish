#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📚 MANS.FISH — Ultra Man Page System with Search & Preview                 ║
# ║  ASH Dotfiles v5.0 OMEGA • Ultra-Grade Function                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE:
#   mans <topic>              — Open man page with bat/rich pager
#   mans -s / --search <term> — Search man pages (apropos)
#   mans -i / --interactive   — FZF interactive man page browser
#   mans -k / --keyword <kw>  — Search by keyword (whatis)
#   mans -f / --fuzzy         — Fuzzy search all man pages
#   mans -e / --export <page> — Export man page to file
#   mans -l / --list <sec>    — List pages in section
#   mans -w / --which <cmd>   — Show man page path
#   mans --section <n> <cmd>  — Open specific section
#   mans --web <topic>        — Open man page online
#   mans --tldr <topic>       — Show tldr instead

# ─── Constants ────────────────────────────────────────────────────────────────

set -l __MANS_VERSION "5.0.0"
set -l __MANS_CACHE_DIR "$HOME/.cache/ash/mans"
set -l __MANS_EXPORT_DIR "$HOME/Documents/manpages"
set -l __MANS_ONLINE_URL "https://man7.org/linux/man-pages/man"

# ─── Color Palette ─────────────────────────────────────────────────────────────

set -l CLR_RESET    (set_color normal)
set -l CLR_BOLD     (set_color --bold)
set -l CLR_DIM      (set_color brblack)
set -l CLR_RED      (set_color red)
set -l CLR_GREEN    (set_color green)
set -l CLR_YELLOW   (set_color yellow)
set -l CLR_BLUE     (set_color blue)
set -l CLR_CYAN     (set_color cyan)
set -l CLR_MAGENTA  (set_color magenta)
set -l CLR_BRED     (set_color brred)
set -l CLR_BGREEN   (set_color brgreen)
set -l CLR_BYELLOW  (set_color bryellow)
set -l CLR_BBLUE    (set_color brblue)
set -l CLR_BCYAN    (set_color brcyan)
set -l CLR_BMAGENTA (set_color brmagenta)

# ─── Man Section Labels ────────────────────────────────────────────────────────

function __mans_section_label -a n
    switch $n
        case 1;  echo "User Commands"
        case 2;  echo "System Calls"
        case 3;  echo "Library Functions"
        case 4;  echo "Special Files"
        case 5;  echo "File Formats"
        case 6;  echo "Games"
        case 7;  echo "Miscellaneous"
        case 8;  echo "System Administration"
        case 9;  echo "Kernel Routines"
        case '*'; echo "Unknown"
    end
end

# ─── Print Helpers ─────────────────────────────────────────────────────────────

function __mans_ok    -a msg; echo $CLR_BGREEN"  ✅  $msg"$CLR_RESET; end
function __mans_err   -a msg; echo $CLR_BRED"  ❌  $msg"$CLR_RESET >&2; end
function __mans_warn  -a msg; echo $CLR_BYELLOW"  ⚠️   $msg"$CLR_RESET; end
function __mans_tip   -a msg; echo $CLR_BCYAN"  💡  $msg"$CLR_RESET; end
function __mans_info  -a msg; echo $CLR_BBLUE"  ℹ️   $msg"$CLR_RESET; end
function __mans_dim   -a msg; echo $CLR_DIM"       $msg"$CLR_RESET; end

# ─── Section Separator ─────────────────────────────────────────────────────────

function __mans_section -a label
    echo ""
    echo $CLR_BBLUE"┌─ "$CLR_BYELLOW"$label "$CLR_BBLUE"────────────────────────────────"$CLR_RESET
end

# ─── Banner ────────────────────────────────────────────────────────────────────

function __mans_banner
    echo ""
    echo $CLR_BBLUE"╔════════════════════════════════════════════════╗"$CLR_RESET
    echo $CLR_BBLUE"║  "$CLR_BCYAN"📚  ASH MANS v$__MANS_VERSION — Ultra Man Browser  "$CLR_BBLUE"║"$CLR_RESET
    echo $CLR_BBLUE"╚════════════════════════════════════════════════╝"$CLR_RESET
    echo ""
end

# ─── Ensure Dirs ──────────────────────────────────────────────────────────────

function __mans_ensure_dirs
    for d in $__MANS_CACHE_DIR $__MANS_EXPORT_DIR
        test -d $d; or mkdir -p $d
    end
end

# ─── Detect Pager ─────────────────────────────────────────────────────────────

function __mans_pager_cmd
    if command -q bat
        # bat with man syntax highlighting
        set -l theme (set -q BAT_THEME; and echo $BAT_THEME; or echo "Monokai Extended")
        echo "bat --style=full --color=always --paging=always --language=man --theme='$theme'"
    else if command -q most
        echo "most"
    else
        echo "less -R"
    end
end

# ─── Open Man With Rich Pager ─────────────────────────────────────────────────

function __mans_open -a page -a section
    if not command -q man
        __mans_err "man not found"
        return 1
    end

    # Build man arguments
    set -l man_args
    if test -n "$section"
        set man_args $section $page
    else
        set man_args $page
    end

    # Use bat if available for beautiful rendering
    if command -q bat
        set -l theme (set -q BAT_THEME; and echo $BAT_THEME; or echo "Monokai Extended")
        # MANPAGER trick with bat for rich colors
        set -lx MANPAGER "sh -c 'col -bx | bat --style=full --color=always --paging=always --language=man --theme=\"$theme\"'"
        set -lx MANROFFOPT "-c"
        man $man_args
    else if command -q most
        set -lx PAGER most
        man $man_args
    else
        set -lx LESS "-R"
        man $man_args
    end

    return $status
end

# ─── Interactive FZF Man Browser ──────────────────────────────────────────────

function __mans_interactive
    if not command -q fzf
        __mans_err "fzf required for interactive mode"
        __mans_tip  "Install: paru -S fzf"
        return 1
    end

    if not command -q man
        __mans_err "man not installed"
        return 1
    end

    set -l selection (man -k '' 2>/dev/null | \
        sort | \
        fzf \
            --prompt "  📚 Man Page ❯ " \
            --header "Enter: open | Ctrl+/ toggle preview | Ctrl+C: exit" \
            --preview 'echo {} | awk "{print \$1}" | xargs -I{} man {} 2>/dev/null | head -80 | col -bx | bat --color=always --style=plain --language=man 2>/dev/null || echo "No preview"' \
            --preview-window 'right:55%:wrap:hidden' \
            --bind 'ctrl-/:toggle-preview' \
            --color 'header:italic:blue,prompt:cyan,pointer:magenta' \
            --border rounded \
            --height 85% \
            --reverse \
            --ansi)

    if test -n "$selection"
        set -l page (echo $selection | awk '{print $1}' | string replace -r '\(\d+\)$' '')
        set -l section (echo $selection | string match -r '\((\d+)\)' | tail -1)
        __mans_open $page $section
    end
end

# ─── Fuzzy Search ─────────────────────────────────────────────────────────────

function __mans_fuzzy
    if not command -q fzf
        __mans_err "fzf required"
        return 1
    end

    set -l query $argv

    set -l selection (man -k '' 2>/dev/null | \
        fzf \
            --prompt "  🔍 Search Man ❯ " \
            --query "$query" \
            --header "Fuzzy search all man pages | Enter: open" \
            --preview 'echo {} | awk "{print \$1}" | sed "s/(.*)//" | xargs -I{} man {} 2>/dev/null | head -60 | col -bx | bat --color=always --style=plain --language=man 2>/dev/null' \
            --preview-window 'right:55%:wrap' \
            --color 'header:italic:blue,prompt:cyan' \
            --border rounded \
            --height 80% \
            --reverse \
            --ansi)

    if test -n "$selection"
        set -l page (echo $selection | awk '{print $1}' | string replace -r '\(\d+\)' '')
        mans $page
    end
end

# ─── Search (apropos) ─────────────────────────────────────────────────────────

function __mans_search -a term
    if test -z "$term"
        __mans_err "Search term required"
        return 1
    end

    __mans_section "🔍  Searching man pages: '$term'"
    echo ""

    if not command -q apropos
        __mans_err "apropos not found"
        return 1
    end

    set -l results (apropos $term 2>/dev/null)

    if test -z "$results"
        __mans_warn "No man pages found for: '$term'"
        __mans_tip  "Try: mans --fuzzy $term"
        return 1
    end

    # Parse & display results nicely
    echo $results | while read -l line
        set -l page    (echo $line | awk '{print $1}')
        set -l section (echo $line | grep -oP '\(\K[^)]+')
        set -l desc    (echo $line | sed 's/^[^ ]* \([^ ]* \)\?- //')

        set -l sec_label (__mans_section_label $section)

        printf "  $CLR_BGREEN%-25s$CLR_RESET $CLR_DIM[%s] %-20s$CLR_RESET %s\n" \
            $page \
            $section \
            $sec_label \
            $CLR_WHITE$desc$CLR_RESET
    end
    echo ""

    # If fzf available, offer interactive selection
    if command -q fzf
        echo $CLR_DIM"  💡 Run 'mans -i' for interactive selection"$CLR_RESET
        echo ""
    end
end

# ─── Keyword / Whatis ─────────────────────────────────────────────────────────

function __mans_keyword -a term
    if test -z "$term"
        __mans_err "Keyword required"
        return 1
    end

    __mans_section "🔑  whatis: '$term'"
    echo ""

    if command -q whatis
        set -l result (whatis $term 2>/dev/null)
        if test -n "$result"
            echo $result | while read -l line
                printf "  $CLR_BCYAN%s$CLR_RESET\n" $line
            end
        else
            __mans_warn "No exact match for: $term"
            __mans_tip  "Try: mans --search $term"
        end
    else
        __mans_err "whatis not found"
        return 1
    end
    echo ""
end

# ─── List Section ─────────────────────────────────────────────────────────────

function __mans_list_section -a section
    if test -z "$section"
        # Show all sections
        __mans_section "📋  Man Page Sections"
        echo ""
        for n in 1 2 3 4 5 6 7 8 9
            set -l label (__mans_section_label $n)
            printf "  $CLR_BYELLOW%-4s$CLR_RESET $CLR_BBLUE%-10s$CLR_RESET %s\n" \
                "($n)" "Section $n:" $CLR_WHITE"$label"$CLR_RESET
        end
        echo ""
        __mans_tip "List pages in a section: mans --list 1"
        echo ""
        return 0
    end

    set -l label (__mans_section_label $section)
    __mans_section "📋  Section $section — $label"
    echo ""

    set -l pages (man -k . -s $section 2>/dev/null | sort | awk '{print $1}')
    if test -z "$pages"
        __mans_warn "No pages found in section $section"
        return 1
    end

    set -l count 0
    printf "  "
    for page in $pages
        set page (string replace -r '\(\d+\)$' '' $page)
        printf "$CLR_BGREEN%-20s$CLR_RESET" $page
        set count (math $count + 1)
        if test (math $count % 4) -eq 0
            printf "\n  "
        end
    end
    echo ""
    echo ""
    __mans_info "Total: "(count $pages)" pages in section $section"
    echo ""
end

# ─── Which (show path) ────────────────────────────────────────────────────────

function __mans_which -a page
    if test -z "$page"
        __mans_err "Page name required"
        return 1
    end

    __mans_section "📂  Man Page Location: '$page'"
    echo ""

    if command -q man
        set -l path (man -w $page 2>/dev/null)
        if test $status -eq 0 -a -n "$path"
            printf "  %-15s $CLR_BCYAN%s$CLR_RESET\n" "Path:" $path
            # Show file info
            if test -f $path
                set -l size (du -h $path | cut -f1)
                set -l mtime (stat -c '%y' $path 2>/dev/null | cut -d'.' -f1)
                printf "  %-15s $CLR_DIM%s$CLR_RESET\n" "Size:" $size
                printf "  %-15s $CLR_DIM%s$CLR_RESET\n" "Modified:" $mtime
            end
        else
            __mans_warn "No man page found for: $page"
        end
    end
    echo ""
end

# ─── Export Man Page ──────────────────────────────────────────────────────────

function __mans_export -a page -a format
    if test -z "$page"
        __mans_err "Page name required"
        return 1
    end

    __mans_ensure_dirs

    set -l fmt (test -n "$format"; and echo $format; or echo "txt")
    set -l out_file "$__MANS_EXPORT_DIR/$page.$fmt"

    __mans_info "Exporting man page: $page → $out_file"

    switch $fmt
        case txt
            man $page 2>/dev/null | col -bx > $out_file
        case md markdown
            # Convert to markdown-ish format
            man $page 2>/dev/null | col -bx | \
                sed 's/^[A-Z ]*$/## &/; s/  \(.*\)$/  \1/' > $out_file
        case html
            if command -q man2html
                man $page 2>/dev/null | man2html > $out_file
            else
                man $page 2>/dev/null | col -bx > $out_file
                __mans_warn "man2html not found, exported as plain text"
            end
        case pdf
            if command -q man
                man -Tpdf $page 2>/dev/null > $out_file
            else
                __mans_err "PDF export requires man with PDF support"
                return 1
            end
        case '*'
            __mans_err "Unknown format: $fmt (txt/md/html/pdf)"
            return 1
    end

    if test $status -eq 0
        __mans_ok "Exported: $out_file"
        __mans_dim "Open: bat $out_file"
    else
        __mans_err "Export failed"
        return 1
    end
end

# ─── Open Online ──────────────────────────────────────────────────────────────

function __mans_web -a page
    if test -z "$page"
        __mans_err "Page name required"
        return 1
    end

    # Try to detect section
    set -l section (man -w $page 2>/dev/null | grep -oP 'man\K\d+' | head -1)
    test -z "$section"; and set section 1

    set -l url "$__MANS_ONLINE_URL$section/$page.$section.html"
    __mans_info "Opening: $url"

    if command -q xdg-open
        xdg-open $url
    else
        echo $CLR_BCYAN"  🌐 $url"$CLR_RESET
    end
end

# ─── Show TLDR ────────────────────────────────────────────────────────────────

function __mans_tldr -a page
    if test -z "$page"
        __mans_err "Page name required"
        return 1
    end

    if command -q tldr
        tldr $page
    else if command -q curl
        __mans_info "Fetching tldr page..."
        set -l url "https://raw.githubusercontent.com/tldr-pages/tldr/main/pages/common/$page.md"
        curl -s --max-time 8 $url | bat --language=md --style=full --color=always --paging=auto 2>/dev/null
            or curl -s --max-time 8 $url | less -R
    else
        __mans_err "tldr not installed. Install: paru -S tldr"
        return 1
    end
end

# ─── Help ─────────────────────────────────────────────────────────────────────

function __mans_help
    __mans_banner
    echo $CLR_BYELLOW"  USAGE"$CLR_RESET
    echo $CLR_DIM"  ──────────────────────────────────────────────────"$CLR_RESET
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "mans <topic>" "Open man page (bat pager)"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "mans -s / --search <term>" "Search (apropos)"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "mans -i / --interactive" "FZF browser"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "mans -f / --fuzzy [term]" "Fuzzy search"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "mans -k / --keyword <kw>" "whatis lookup"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "mans -e / --export <page> [fmt]" "Export (txt/md/html/pdf)"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "mans -l / --list [section]" "List sections/pages"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "mans -w / --which <page>" "Show man file path"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "mans --section <n> <page>" "Open specific section"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "mans --web <page>" "Open online"
    printf "  $CLR_BGREEN%-38s$CLR_RESET %s\n" "mans --tldr <page>" "Show tldr page"
    echo ""
    echo $CLR_BYELLOW"  SECTIONS"$CLR_RESET
    echo $CLR_DIM"  ──────────────────────────────────────────────────"$CLR_RESET
    for n in 1 2 3 4 5 6 7 8
        set -l label (__mans_section_label $n)
        printf "  $CLR_BYELLOW(%s)$CLR_RESET %-12s %s\n" $n "Section $n:" $CLR_DIM$label$CLR_RESET
    end
    echo ""
    echo $CLR_BYELLOW"  EXAMPLES"$CLR_RESET
    echo $CLR_DIM"  ──────────────────────────────────────────────────"$CLR_RESET
    echo $CLR_DIM"  mans curl"$CLR_RESET
    echo $CLR_DIM"  mans --section 3 printf"$CLR_RESET
    echo $CLR_DIM"  mans --search 'network'"$CLR_RESET
    echo $CLR_DIM"  mans --interactive"$CLR_RESET
    echo $CLR_DIM"  mans --export curl pdf"$CLR_RESET
    echo ""
end

# ═══════════════════════════════════════════════════════════════════════════════
# ─── MAIN FUNCTION ─────────────────────────────────────────────────────────────
# ═══════════════════════════════════════════════════════════════════════════════

function mans
    # ── No args ───────────────────────────────────────────────────────────────
    if test (count $argv) -eq 0
        __mans_help
        return 0
    end

    # ── Parse flags ───────────────────────────────────────────────────────────
    switch $argv[1]

        case -h --help
            __mans_help

        case -s --search
            if test (count $argv) -lt 2
                __mans_err "Usage: mans --search <term>"
                return 1
            end
            __mans_search $argv[2..-1]

        case -i --interactive
            __mans_interactive

        case -f --fuzzy
            __mans_fuzzy $argv[2..-1]

        case -k --keyword
            if test (count $argv) -lt 2
                __mans_err "Usage: mans --keyword <term>"
                return 1
            end
            __mans_keyword $argv[2]

        case -e --export
            if test (count $argv) -lt 2
                __mans_err "Usage: mans --export <page> [format]"
                return 1
            end
            __mans_export $argv[2] $argv[3]

        case -l --list
            __mans_list_section $argv[2]

        case -w --which
            if test (count $argv) -lt 2
                __mans_err "Usage: mans --which <page>"
                return 1
            end
            __mans_which $argv[2]

        case --section
            if test (count $argv) -lt 3
                __mans_err "Usage: mans --section <n> <page>"
                return 1
            end
            __mans_open $argv[3] $argv[2]

        case --web
            if test (count $argv) -lt 2
                __mans_err "Usage: mans --web <page>"
                return 1
            end
            __mans_web $argv[2]

        case --tldr
            if test (count $argv) -lt 2
                __mans_err "Usage: mans --tldr <page>"
                return 1
            end
            __mans_tldr $argv[2]

        case --version
            echo $CLR_BCYAN"  📚 ASH Mans v$__MANS_VERSION"$CLR_RESET

        case '*'
            __mans_open $argv[1] ""
    end
end
