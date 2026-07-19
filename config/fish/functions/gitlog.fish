# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — gitlog Ultra                                       ║
# ║  Beautiful git history: graph, stats, author view, search & fzf browser    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function gitlog --description "Beautiful git history viewer with rich formatting"

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 COLORS                                                              ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l R      (set_color normal)
    set -l BOLD   (set_color --bold)
    set -l DIM    (set_color brblack)
    set -l GREEN  (set_color green)
    set -l YELLOW (set_color yellow)
    set -l RED    (set_color red)
    set -l CYAN   (set_color cyan)
    set -l BLUE   (set_color blue)
    set -l PURPLE (set_color magenta)
    set -l ORANGE (set_color FF9F43)
    set -l PINK   (set_color F5C2E7)

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 VERIFY GIT REPO                                                     ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    command -q git || begin
        printf "  $RED✗$R  git not installed\n"
        return 1
    end

    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || begin
        printf "  $RED✗$R  Not in a git repository\n"
        return 1
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 HELP                                                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __gl_help --description "Print gitlog help"
        echo ""
        echo $BOLD$PURPLE"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$PURPLE"  ║      gitlog — Beautiful Git History Viewer          ║"$R
        echo $BOLD$PURPLE"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Usage:$R  gitlog [mode] [options]"
        echo ""
        echo "  $BOLD Modes:$R"
        printf "    $CYAN%-20s$R  %s\n" \
            "(none)"         "Pretty graph log" \
            "graph"          "Detailed graph with stats" \
            "oneline"        "Compact one-line format" \
            "full"           "Full commit details" \
            "stat"           "Show file change statistics" \
            "patch"          "Show diffs inline" \
            "files"          "List changed files per commit" \
            "author <name>"  "Filter by author" \
            "search <term>"  "Search commit messages" \
            "since <date>"   "Commits since date" \
            "between <r>..<r>" "Commits between refs" \
            "branch"         "Branch comparison view" \
            "tags"           "Show tag history" \
            "stats"          "Repository statistics" \
            "pick"           "Interactive fzf browser" \
            "blame <file>"   "File blame view" \
            "changed <file>" "Commits touching a file"
        echo ""
        echo "  $BOLD Options:$R"
        printf "    $CYAN%-18s$R  %s\n" \
            "-n <N>"         "Limit to N commits (default: 20)" \
            "--all"          "Show all branches" \
            "--no-graph"     "Disable graph decoration" \
            "--no-color"     "Disable colors" \
            "--reverse"      "Reverse order (oldest first)" \
            "--follow <f>"   "Follow file renames" \
            "-h, --help"     "Show this help"
        echo ""
        echo "  $BOLD Examples:$R"
        printf "    $DIM%s$R\n" \
            "gitlog                          # Pretty graph (last 20)" \
            "gitlog -n 50                    # Last 50 commits" \
            "gitlog graph                    # Detailed graph + stats" \
            "gitlog author 'Alice'           # Alice's commits" \
            "gitlog search 'fix: auth'       # Search messages" \
            "gitlog since '1 week ago'       # Last week" \
            "gitlog files                    # Files changed per commit" \
            "gitlog stats                    # Repository statistics" \
            "gitlog pick                     # Interactive browser" \
            "gitlog blame README.md          # File blame" \
            "gitlog changed src/auth.ts      # History of a file"
        echo ""
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 ARGUMENT PARSING                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _mode    pretty   # pretty | graph | oneline | full | stat | patch | files
                             # | author | search | since | between | branch | tags
                             # | stats | pick | blame | changed
    set -l _n       20
    set -l _all     0
    set -l _graph   1
    set -l _reverse 0
    set -l _target  ""       # author name / search term / file / date
    set -l _range   ""       # commit range
    set -l _follow  ""
    set -l _extra_args

    if test (count $argv) -gt 0 && test "$argv[1]" = "--help" -o "$argv[1]" = "-h"
        __gl_help; return 0
    end

    # Parse first arg as mode
    set -l first_arg $argv[1]
    switch $first_arg
        case graph detailed;          set _mode graph;   set argv $argv[2..-1]
        case oneline short compact;   set _mode oneline; set argv $argv[2..-1]
        case full verbose;            set _mode full;    set argv $argv[2..-1]
        case stat stats-files;        set _mode stat;    set argv $argv[2..-1]
        case patch diff;              set _mode patch;   set argv $argv[2..-1]
        case files changed-files;     set _mode files;   set argv $argv[2..-1]
        case author by;               set _mode author; set _target $argv[2]; set argv $argv[3..-1]
        case search grep find;        set _mode search; set _target $argv[2]; set argv $argv[3..-1]
        case since after;             set _mode since;  set _target $argv[2]; set argv $argv[3..-1]
        case between range;           set _mode between; set _range $argv[2]; set argv $argv[3..-1]
        case branch branches;         set _mode branch;  set argv $argv[2..-1]
        case tags tag;                set _mode tags;    set argv $argv[2..-1]
        case stats repository;        set _mode stats;   set argv $argv[2..-1]
        case pick interactive fzf;    set _mode pick;    set argv $argv[2..-1]
        case blame annotate;          set _mode blame; set _target $argv[2]; set argv $argv[3..-1]
        case changed history;         set _mode changed; set _target $argv[2]; set argv $argv[3..-1]
        case '' pretty default;       set _mode pretty;  set argv $argv[2..-1]
    end

    # Parse remaining options
    for arg in $argv
        switch $arg
            case -n=*
                set _n (string replace '-n=' '' $arg)
            case --all -a
                set _all 1
            case --no-graph
                set _graph 0
            case --reverse
                set _reverse 1
            case --follow
                set _follow "--follow"
            case '*'
                set --append _extra_args $arg
        end
    end

    # -n as separate arg
    for i in (seq (count $argv))
        if test $argv[$i] = "-n" && test (count $argv) -gt $i
            set _n $argv[(math $i + 1)]
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 FORMAT STRINGS                                                      ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # Color codes using git's built-in %C() format
    set -l FMT_HASH    "%C(yellow)%h%C(reset)"
    set -l FMT_DATE    "%C(cyan)%ad%C(reset)"
    set -l FMT_AUTHOR  "%C(green)%an%C(reset)"
    set -l FMT_MSG     "%C(white)%s%C(reset)"
    set -l FMT_REFS    "%C(magenta)%D%C(reset)"
    set -l FMT_BODY    "%C(dim white)%b%C(reset)"

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🛠️  COMMON GIT FLAGS                                                   ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _git_flags ""
    test $_all     -eq 1 && set _git_flags "$_git_flags --all"
    test $_reverse -eq 1 && set _git_flags "$_git_flags --reverse"

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🚀 MODE DISPATCH                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    switch $_mode

        # ── Pretty graph (default) ────────────────────────────────────────────
        case pretty
            printf "\n  $BOLD$PURPLE  Repository: $(git remote get-url origin 2>/dev/null | \
                string replace 'https://github.com/' '' | \
                string replace 'git@github.com:' '' || \
                basename (git rev-parse --show-toplevel))$R\n"
            printf "  $DIM  Branch: $(git branch --show-current)  ·  $(git log --oneline 2>/dev/null | wc -l | string trim) commits total$R\n\n"

            set -l graph_flag ""
            test $_graph -eq 1 && set graph_flag "--graph"

            git log \
                --color=always \
                $graph_flag \
                --abbrev-commit \
                --decorate \
                --date=relative \
                --format=format:"$FMT_HASH $FMT_DATE $FMT_AUTHOR $FMT_REFS %n%w(80,3,3)$FMT_MSG%n" \
                -n $_n \
                $_git_flags \
                2>/dev/null | \
            command -q bat && bat --language=git-log --style=plain --color=always --paging=always || \
            less -R

        # ── Detailed graph with stats ─────────────────────────────────────────
        case graph
            git log \
                --color=always \
                --graph \
                --abbrev-commit \
                --decorate \
                --date=short \
                --stat \
                --format=format:"$BOLD%C(yellow)%h%C(reset) %C(magenta)%D%C(reset)%n%C(cyan)%ad%C(reset) · %C(green)%an%C(reset) · %C(white)%s%C(reset)%n" \
                -n $_n \
                $_git_flags \
                2>/dev/null | less -R

        # ── Compact one-liner ─────────────────────────────────────────────────
        case oneline
            printf "\n  $BOLD$PURPLE   Git Log (compact)$R  $DIM— last $_n commits$R\n\n"

            git log \
                --color=always \
                --oneline \
                --decorate \
                -n $_n \
                $_git_flags \
                2>/dev/null | \
            while read -l line
                printf "  %s\n" $line
            end
            printf "\n"

        # ── Full commit details ───────────────────────────────────────────────
        case full
            git log \
                --color=always \
                --abbrev-commit \
                --decorate \
                --date=iso \
                --format=format:"
$BOLD%C(yellow)━━━ %h %C(magenta)%D%C(reset)
$BOLD  Subject:  %C(white)%s%C(reset)
  Author:   %C(green)%an <%ae>%C(reset)
  Date:     %C(cyan)%ad%C(reset)
  Committer:%C(green)%cn%C(reset)
  Parents:  %P%n%C(dim white)%b%C(reset)" \
                -n $_n \
                $_git_flags \
                2>/dev/null | less -R

        # ── File stats per commit ─────────────────────────────────────────────
        case stat
            git log \
                --color=always \
                --stat \
                --stat-width=80 \
                --abbrev-commit \
                --date=short \
                --format=format:"$BOLD%C(yellow)%h%C(reset) %C(cyan)%ad%C(reset) %C(green)%an%C(reset) — %C(white)%s%C(reset) %C(magenta)%D%C(reset)" \
                -n $_n \
                $_git_flags \
                2>/dev/null | less -R

        # ── Patch/diff per commit ─────────────────────────────────────────────
        case patch
            git log \
                --color=always \
                --patch \
                --abbrev-commit \
                --date=short \
                --format=format:"$BOLD%C(yellow)%h%C(reset) %C(cyan)%ad%C(reset) %C(green)%an%C(reset) — %C(white)%s%C(reset)" \
                -n $_n \
                $_git_flags \
                2>/dev/null | \
            command -q delta && delta --side-by-side 2>/dev/null || \
            command -q bat   && bat --language=diff --style=plain --color=always || \
            less -R

        # ── Files changed ──────────────────────────────────────────────────────
        case files
            printf "\n  $BOLD$PURPLE   Changed Files per Commit$R  $DIM— last $_n commits$R\n\n"

            git log \
                --color=always \
                --name-only \
                --abbrev-commit \
                --date=short \
                --format=format:"$BOLD%C(yellow)%h%C(reset) $CYAN%ad$R $GREEN%an$R — $WHITE%s$R $PURPLE%D$R" \
                -n $_n \
                $_git_flags \
                2>/dev/null | \
            while read -l line
                if string match -qr '^[0-9a-f]{7}' (string replace -r '\033\[[^m]*m' '' $line)
                    printf "\n  %s\n" $line
                else if test -n "$line"
                    printf "     $DIM›$R  $DIM%s$R\n" $line
                end
            end
            printf "\n"

        # ── Author filter ──────────────────────────────────────────────────────
        case author
            set -l author_name $_target
            test -z "$author_name" && set author_name (git config user.name 2>/dev/null)

            printf "\n  $BOLD$GREEN   Commits by: $author_name$R\n\n"

            git log \
                --color=always \
                --oneline \
                --decorate \
                --author="$author_name" \
                --date=short \
                -n $_n \
                $_git_flags \
                2>/dev/null | \
            while read -l line; printf "  %s\n" $line; end
            printf "\n"

        # ── Search commits ────────────────────────────────────────────────────
        case search
            if test -z "$_target"
                printf "  $RED✗$R  Usage: gitlog search <term>\n"
                return 1
            end
            printf "\n  $BOLD$CYAN  🔍 Searching: \"$_target\"$R\n\n"

            git log \
                --color=always \
                --all \
                --oneline \
                --decorate \
                --grep="$_target" \
                --regexp-ignore-case \
                -n $_n \
                2>/dev/null | \
            while read -l line
                # Highlight search term
                printf "  %s\n" (string replace -i "$_target" $YELLOW"$_target"$R $line)
            end
            printf "\n"

        # ── Since a date ──────────────────────────────────────────────────────
        case since
            set -l since_date $_target
            test -z "$since_date" && set since_date "1 week ago"

            printf "\n  $BOLD$CYAN   Commits since: $since_date$R\n\n"

            git log \
                --color=always \
                --oneline \
                --decorate \
                --since="$since_date" \
                $_git_flags \
                2>/dev/null | \
            while read -l line; printf "  %s\n" $line; end

            # Count
            set -l cnt (git log --oneline --since="$since_date" $_git_flags 2>/dev/null | wc -l | string trim)
            printf "\n  $DIM  $cnt commits in period$R\n\n"

        # ── Between refs ──────────────────────────────────────────────────────
        case between
            if test -z "$_range"
                printf "  $RED✗$R  Usage: gitlog between <ref1>..<ref2>\n"
                return 1
            end
            printf "\n  $BOLD$CYAN   Commits between: $_range$R\n\n"

            git log \
                --color=always \
                --oneline \
                --decorate \
                $_range \
                2>/dev/null | \
            while read -l line; printf "  %s\n" $line; end
            printf "\n"

        # ── Branch view ───────────────────────────────────────────────────────
        case branch
            set -l default_branch (git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | \
                string replace 'origin/' '' || echo "main")

            printf "\n  $BOLD$PURPLE   Branch History$R  $DIM— current branch vs $default_branch$R\n\n"

            git log \
                --color=always \
                --graph \
                --oneline \
                --decorate \
                --all \
                -n $_n \
                2>/dev/null | less -R

        # ── Tag history ───────────────────────────────────────────────────────
        case tags
            printf "\n  $BOLD$YELLOW  🏷️  Tag History$R\n\n"
            printf "  $BOLD$YELLOW%-15s  %-12s  %-20s  %s$R\n" "TAG" "DATE" "AUTHOR" "MESSAGE"
            printf "  $DIM%s$R\n" (string repeat -n 65 "─")

            git log \
                --color=always \
                --simplify-by-decoration \
                --decorate=full \
                --date=short \
                --format=format:"%D|%ad|%an|%s" \
                2>/dev/null | \
            grep 'tag:' | head -$_n | \
            while read -l line
                set -l parts (string split '|' $line)
                set -l tag_info (echo $parts[1] | grep -oP 'tag: [^\s,]+' | head -1 | string replace 'tag: ' '')
                set -l date   $parts[2]
                set -l author $parts[3]
                set -l msg    $parts[4]

                printf "  $YELLOW%-15s$R  $CYAN%-12s$R  $GREEN%-20s$R  $DIM%s$R\n" \
                    (string sub --length 15 $tag_info) $date \
                    (string sub --length 20 $author) \
                    (string sub --length 30 $msg)
            end
            printf "\n"

        # ── Repository statistics ──────────────────────────────────────────────
        case stats
            printf "\n  $BOLD$PURPLE╔══════════════════════════════════════════════════════╗$R\n"
            printf "  $BOLD$PURPLE║     📊  Repository Statistics                        ║$R\n"
            printf "  $BOLD$PURPLE╚══════════════════════════════════════════════════════╝$R\n\n"

            # Basic stats
            set -l total_commits (git rev-list --count HEAD 2>/dev/null)
            set -l total_files   (git ls-files 2>/dev/null | wc -l | string trim)
            set -l first_commit  (git log --reverse --date=short --format="%ad" 2>/dev/null | head -1)
            set -l last_commit   (git log -1 --date=short --format="%ad" 2>/dev/null)
            set -l branches      (git branch -r 2>/dev/null | wc -l | string trim)
            set -l tags_count    (git tag 2>/dev/null | wc -l | string trim)

            printf "  $BOLD%-20s$R  $CYAN%s$R\n" "Total commits:" $total_commits
            printf "  $BOLD%-20s$R  $CYAN%s$R\n" "Tracked files:" $total_files
            printf "  $BOLD%-20s$R  $CYAN%s$R\n" "First commit:"  $first_commit
            printf "  $BOLD%-20s$R  $CYAN%s$R\n" "Last commit:"   $last_commit
            printf "  $BOLD%-20s$R  $CYAN%s$R\n" "Remote branches:" $branches
            printf "  $BOLD%-20s$R  $CYAN%s$R\n" "Tags:" $tags_count
            printf "\n"

            # Top contributors
            printf "  $BOLD$GREEN  🏆 Top Contributors:$R\n\n"
            printf "  $BOLD$GREEN%-5s  %-25s  %-6s  %s$R\n" "RANK" "AUTHOR" "COMMITS" "BAR"
            printf "  $DIM%s$R\n" (string repeat -n 55 "─")

            set -l max_commits 0
            set -l author_data (git shortlog -sne --no-merges HEAD 2>/dev/null | head -10)

            # Get max for bar scaling
            for line in $author_data
                set -l cnt (echo $line | awk '{print $1}')
                test $cnt -gt $max_commits && set max_commits $cnt
            end

            set -l rank 1
            for line in $author_data
                set -l cnt    (echo $line | awk '{print $1}')
                set -l author (echo $line | awk '{$1=""; print $0}' | string trim | \
                    string replace -r ' <.*>' '')

                # Progress bar
                set -l bar_len (math --scale 0 "$cnt * 20 / (max(1, $max_commits))")
                set -l bar     (string repeat -n $bar_len "█")
                set -l bar_empty (string repeat -n (math 20 - $bar_len) "░")

                set -l medal ""
                switch $rank
                    case 1; set medal "🥇"
                    case 2; set medal "🥈"
                    case 3; set medal "🥉"
                    case '*'; set medal "   $rank."
                end

                printf "  %s  $GREEN%-25s$R  $CYAN%-6s$R  $ORANGE%s$R$DIM%s$R\n" \
                    $medal (string sub --length 25 $author) $cnt $bar $bar_empty
                set rank (math $rank + 1)
            end
            printf "\n"

            # File type breakdown
            printf "  $BOLD$BLUE  📁 File Types:$R\n\n"
            git ls-files 2>/dev/null | \
                grep -oP '\.[^.]+$' | sort | uniq -c | sort -rn | head -10 | \
            while read -l line
                set -l cnt (echo $line | awk '{print $1}')
                set -l ext (echo $line | awk '{print $2}')
                printf "    $CYAN%-8s$R  $DIM%d files$R\n" $ext $cnt
            end

            # Recent activity (commits per week)
            printf "\n  $BOLD$PURPLE  📈 Recent Activity (last 4 weeks):$R\n\n"
            for weeks_ago in 3 2 1 0
                set -l since_str "$weeks_ago weeks ago"
                set -l until_str (math $weeks_ago - 1)" weeks ago"
                test $weeks_ago -eq 0 && set until_str "now"

                set -l cnt (git log --oneline \
                    --since="$since_str" \
                    --until="$until_str" \
                    2>/dev/null | wc -l | string trim)

                set -l bar_len (math --scale 0 "min(40, $cnt)")
                set -l bar     (string repeat -n $bar_len "▪")
                set -l label   (date -d "$since_str" '+%b %d' 2>/dev/null || echo "week -$weeks_ago")

                printf "    $DIM%-10s$R  $PURPLE%s$R  $DIM%d$R\n" $label $bar $cnt
            end
            printf "\n"

        # ── Interactive fzf picker ─────────────────────────────────────────────
        case pick
            if not command -q fzf
                printf "  $YELLOW⚠$R  fzf required — showing compact log\n\n"
                gitlog oneline
                return 0
            end

            set -l selected (
                git log \
                    --color=always \
                    --oneline \
                    --decorate \
                    --all \
                    -n 500 \
                    2>/dev/null |
                fzf --ansi \
                    --no-sort \
                    --reverse \
                    --border-label "   Git Log Browser " \
                    --border rounded \
                    --prompt "  🔍 " \
                    --pointer "▶" \
                    --preview '
                        hash=$(echo {} | awk "{print \$1}" | sed "s/\*//")
                        git show --color=always --stat "$hash" 2>/dev/null | head -40
                        echo ""
                        git show --color=always "$hash" -- 2>/dev/null | head -60
                    ' \
                    --preview-window 'right:55%:border-rounded:wrap' \
                    --header '  Enter:show  Ctrl-D:diff  Ctrl-C:checkout  Ctrl-R:reset  Ctrl-Y:copy hash  ' \
                    --bind 'ctrl-d:execute(git show --color=always --stat {1} | less -R)' \
                    --bind 'ctrl-c:execute(git checkout {1})+abort' \
                    --bind 'ctrl-r:execute(
                        echo "Reset to {1}? [y/N]" && read c
                        test "$c" = y && git reset --soft {1}
                    )+abort' \
                    --bind 'ctrl-y:execute-silent(echo -n {1} | wl-copy 2>/dev/null || xclip -selection clipboard 2>/dev/null)' \
                    --height 80%
            )

            if test -n "$selected"
                set -l hash (echo $selected | awk '{print $1}')
                printf "\n  $CYAN  Selected: $hash$R\n"
                git show --color=always --stat $hash 2>/dev/null | head -30
                printf "\n"
            end

        # ── Blame ─────────────────────────────────────────────────────────────
        case blame
            if test -z "$_target"
                printf "  $RED✗$R  Usage: gitlog blame <file>\n"
                return 1
            end
            if not test -f "$_target"
                printf "  $RED✗$R  File not found: $_target\n"
                return 1
            end

            printf "\n  $BOLD$PURPLE  📝 Git Blame: $_target$R\n\n"

            if command -q delta
                git blame --color-lines --color-by-age $_follow "$_target" 2>/dev/null | \
                    delta --blame-format='{commit}  {author:<15}  {age:<12}  {timestamp}' 2>/dev/null || \
                    git blame "$_target" 2>/dev/null | less -R
            else
                git blame \
                    --color-by-age \
                    --date=short \
                    $_follow \
                    "$_target" \
                    2>/dev/null | \
                while read -l line
                    printf "  %s\n" $line
                end | less -R
            end

        # ── File history ───────────────────────────────────────────────────────
        case changed
            if test -z "$_target"
                printf "  $RED✗$R  Usage: gitlog changed <file>\n"
                return 1
            end

            printf "\n  $BOLD$CYAN  📄 History: $_target$R\n\n"

            git log \
                --color=always \
                --follow \
                --oneline \
                --decorate \
                --stat \
                --date=short \
                --format=format:"$BOLD%C(yellow)%h$R %C(cyan)%ad$R %C(green)%an$R — $WHITE%s$R %C(magenta)%D$R" \
                -n $_n \
                -- "$_target" \
                2>/dev/null | \
            command -q bat && bat --language=git-log --style=plain --color=always --paging=always || \
            less -R
    end

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __gl_help 2>/dev/null

end
