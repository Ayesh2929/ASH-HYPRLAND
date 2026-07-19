# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — git_branch_cleanup Ultra                           ║
# ║  Smart git branch pruning: merged, stale, remote-gone & interactive modes  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function git_branch_cleanup --description "Smart git branch cleanup: merged, stale & orphaned"

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

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 VERIFY GIT REPO                                                     ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    command -q git || begin
        printf "  $RED✗$R  git not installed\n"; return 1
    end

    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || begin
        printf "  $RED✗$R  Not in a git repository\n"; return 1
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 HELP                                                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __gbc_help --description "Print help"
        echo ""
        echo $BOLD$PURPLE"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$PURPLE"  ║      git_branch_cleanup — Branch Pruning System     ║"$R
        echo $BOLD$PURPLE"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Usage:$R  git_branch_cleanup [mode] [options]"
        echo ""
        echo "  $BOLD Modes:$R"
        printf "    $CYAN%-22s$R  %s\n" \
            "(none)"          "Interactive cleanup (recommended)" \
            "merged"          "Delete local branches merged into default" \
            "gone"            "Delete branches whose remote is gone" \
            "stale [days]"    "Delete branches with no commits for N days" \
            "remote"          "Prune remote tracking branches" \
            "list"            "List all branches with metadata" \
            "status"          "Show branch health overview" \
            "all"             "Run all cleanup operations"
        echo ""
        echo "  $BOLD Options:$R"
        printf "    $CYAN%-22s$R  %s\n" \
            "--dry-run, -n"       "Preview without deleting" \
            "--force, -f"         "Force delete (even unmerged)" \
            "--remote, -r"        "Also delete remote branches" \
            "--default <branch>"  "Override default branch detection" \
            "--keep <pattern>"    "Protect branches matching pattern" \
            "--quiet, -q"         "Minimal output" \
            "--help, -h"          "Show this help"
        echo ""
        echo "  $BOLD Examples:$R"
        printf "    $DIM%s$R\n" \
            "git_branch_cleanup               # Interactive picker" \
            "git_branch_cleanup merged        # Remove merged branches" \
            "git_branch_cleanup gone          # Remove orphaned branches" \
            "git_branch_cleanup stale 30      # Remove branches inactive 30+ days" \
            "git_branch_cleanup all --dry-run # Preview all cleanup" \
            "git_branch_cleanup list          # View all branches with info" \
            "git_branch_cleanup status        # Health overview"
        echo ""
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 ARGUMENT PARSING                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _mode     interactive
    set -l _dry_run  0
    set -l _force    0
    set -l _remote   0
    set -l _quiet    0
    set -l _default  ""
    set -l _keep     ""
    set -l _stale_days 30
    set -l _target   ""

    if contains -- --help $argv; or contains -- -h $argv
        __gbc_help; return 0
    end

    # First arg: mode
    if test (count $argv) -gt 0
        switch $argv[1]
            case merged gone remote stale all list status
                set _mode $argv[1]
                set argv $argv[2..-1]
                # Stale can have a day count
                if test "$_mode" = stale && string match -qr '^\d+$' $argv[1]
                    set _stale_days $argv[1]
                    set argv $argv[2..-1]
                end
        end
    end

    for arg in $argv
        switch $arg
            case --dry-run -n;   set _dry_run 1
            case --force -f;     set _force   1
            case --remote -r;    set _remote  1
            case --quiet -q;     set _quiet   1
            case --default=*
                set _default (string replace '--default=' '' $arg)
            case --keep=*
                set _keep (string replace '--keep=' '' $arg)
            case --default
                set _default $argv[(math (contains -i -- $arg $argv) + 1)]
            case --keep
                set _keep $argv[(math (contains -i -- $arg $argv) + 1)]
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 HELPER FUNCTIONS                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── Detect default branch ─────────────────────────────────────────────────
    function __gbc_default_branch --description "Detect default/main branch"
        test -n "$_default" && echo $_default && return

        # Try common methods in order
        git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | \
            string replace 'refs/remotes/origin/' '' && return

        for branch in main master develop trunk
            git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null && \
                echo $branch && return
        end

        git branch --show-current 2>/dev/null
    end

    set -l _default_branch (__gbc_default_branch)

    # ── Current branch ─────────────────────────────────────────────────────────
    set -l _current_branch (git branch --show-current 2>/dev/null)

    # ── Protected branches ────────────────────────────────────────────────────
    function __gbc_is_protected --description "Check if branch is protected"
        set -l br $argv[1]

        # Always protect
        for protected in main master develop release staging production \
            hotfix HEAD $_current_branch $_default_branch
            test "$br" = "$protected" && return 0
        end

        # User-defined keep pattern
        if test -n "$_keep"
            string match -q "$_keep" $br && return 0
        end

        return 1
    end

    # ── Output helpers ────────────────────────────────────────────────────────
    function __gbc_ok   --description "OK line"
        test $_quiet -eq 1 && return
        printf "  $GREEN✓$R  %s\n" $argv[1]
    end
    function __gbc_del  --description "Deleted line"
        printf "  $RED✗$R  $RED%s$R\n" $argv[1]
    end
    function __gbc_skip --description "Skip line"
        test $_quiet -eq 1 && return
        printf "  $DIM○  %s (protected)$R\n" $argv[1]
    end
    function __gbc_info --description "Info line"
        test $_quiet -eq 1 && return
        printf "  $CYAN›$R  $DIM%s$R\n" $argv[1]
    end
    function __gbc_warn --description "Warn line"
        printf "  $YELLOW⚠$R  %s\n" $argv[1]
    end
    function __gbc_dry  --description "Dry-run line"
        printf "  $YELLOW[DRY]$R  would delete: $YELLOW%s$R\n" $argv[1]
    end

    # ── Delete a branch ───────────────────────────────────────────────────────
    function __gbc_delete_branch --description "Delete a local branch safely"
        set -l br $argv[1]

        __gbc_is_protected $br && begin; __gbc_skip $br; return 0; end

        if test $_dry_run -eq 1
            __gbc_dry $br
            return 0
        end

        set -l flag -d
        test $_force -eq 1 && set flag -D

        git branch $flag $br 2>/dev/null
        if test $status -eq 0
            __gbc_del $br
            return 0
        else
            __gbc_warn "Could not delete '$br' — use --force if unmerged"
            return 1
        end
    end

    # ── Delete remote branch ───────────────────────────────────────────────────
    function __gbc_delete_remote --description "Delete a remote branch"
        set -l br     $argv[1]
        set -l remote $argv[2]
        test -z "$remote" && set remote origin

        test $_dry_run -eq 1 && begin
            __gbc_dry "remote $remote/$br"
            return 0
        end

        git push $remote --delete $br 2>/dev/null
        and __gbc_del "remote: $remote/$br"
        or  __gbc_warn "Could not delete remote '$remote/$br'"
    end

    # ── Branch age in days ────────────────────────────────────────────────────
    function __gbc_branch_age --description "Days since last commit on branch"
        set -l br $argv[1]
        set -l last_ts (git log -1 --format="%at" $br 2>/dev/null)
        test -z "$last_ts" && echo 9999 && return
        math --scale 0 "($(date +%s) - $last_ts) / 86400"
    end

    # ── Branch last commit date ───────────────────────────────────────────────
    function __gbc_branch_date --description "Last commit date for branch"
        git log -1 --format="%ar" $argv[1] 2>/dev/null
    end

    # ── Branch author ──────────────────────────────────────────────────────────
    function __gbc_branch_author --description "Last commit author for branch"
        git log -1 --format="%an" $argv[1] 2>/dev/null
    end

    # ── Branch merged status ───────────────────────────────────────────────────
    function __gbc_is_merged --description "Check if branch is merged into default"
        set -l br $argv[1]
        git branch --merged $_default_branch 2>/dev/null | \
            string trim | grep -q "^$br\$"
    end

    # ── Remote tracking status ─────────────────────────────────────────────────
    function __gbc_remote_status --description "Get remote tracking status"
        set -l br $argv[1]
        set -l tracking (git for-each-ref --format='%(upstream:short)' "refs/heads/$br" 2>/dev/null)

        if test -z "$tracking"
            echo "no-remote"
            return
        end

        git show-ref --verify --quiet "refs/remotes/$tracking" 2>/dev/null \
            && echo "tracked" \
            || echo "gone"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 GATHER ALL BRANCH DATA                                              ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __gbc_all_branches --description "Get all local branches except current"
        git branch --format='%(refname:short)' 2>/dev/null | \
            grep -v "^\*" | string trim
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🖨️  BANNER                                                              ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _repo_name (basename (git rev-parse --show-toplevel 2>/dev/null))
    set -l _branch_count (git branch 2>/dev/null | wc -l | string trim)

    if test $_quiet -eq 0
        printf "\n"
        printf "  $BOLD$PURPLE╔══════════════════════════════════════════════════════╗$R\n"
        printf "  $BOLD$PURPLE║      Git Branch Cleanup                             ║$R\n"
        printf "  $BOLD$PURPLE║  %-52s║$R\n" \
            "  Repo: $_repo_name  ·  Branches: $_branch_count  ·  Default: $_default_branch"
        printf "  $BOLD$PURPLE╚══════════════════════════════════════════════════════╝$R\n\n"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🚀 MODE DISPATCH                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _deleted  0
    set -l _skipped  0
    set -l _ts_start (date +%s)

    switch $_mode

        # ── LIST: Show all branches with metadata ──────────────────────────────
        case list
            printf "  $BOLD$CYAN%-30s  %-8s  %-18s  %-12s  %-8s  %s$R\n" \
                "BRANCH" "MERGED" "LAST COMMIT" "AUTHOR" "REMOTE" "AGE"
            printf "  $DIM%s$R\n" (string repeat -n 85 "─")

            for br in (__gbc_all_branches)
                set -l is_merged  (__gbc_is_merged $br && echo "✓" || echo "✗")
                set -l last_date  (__gbc_branch_date $br)
                set -l author     (string sub --length 12 (__gbc_branch_author $br))
                set -l remote_st  (__gbc_remote_status $br)
                set -l age        (__gbc_branch_age $br)
                set -l protected  (__gbc_is_protected $br && echo "🔒" || echo "")

                # Color by status
                set -l br_color $R
                test "$is_merged" = "✓" && set br_color $GREEN
                test "$remote_st" = "gone" && set br_color $RED
                test "$age" -gt 90 2>/dev/null && set br_color $YELLOW

                set -l remote_icon
                switch $remote_st
                    case tracked;   set remote_icon $GREEN"tracked"$R
                    case gone;      set remote_icon $RED"gone"$R
                    case no-remote; set remote_icon $DIM"local"$R
                end

                printf "  $br_color%-30s$R  %-8s  %-18s  %-12s  %-8s  $DIM%dd$R  %s\n" \
                    (string sub --length 30 $br) \
                    (test "$is_merged" = "✓" && echo $GREEN"merged"$R || echo $DIM"open"$R) \
                    $last_date $author $remote_icon $age $protected
            end
            printf "\n"
            return 0

        # ── STATUS: Health overview ────────────────────────────────────────────
        case status
            set -l total     (__gbc_all_branches | count)
            set -l merged    0
            set -l gone      0
            set -l stale_30  0
            set -l stale_90  0
            set -l no_remote 0

            for br in (__gbc_all_branches)
                __gbc_is_merged $br && set merged (math $merged + 1)
                set -l rs (__gbc_remote_status $br)
                test "$rs" = gone      && set gone      (math $gone + 1)
                test "$rs" = no-remote && set no_remote (math $no_remote + 1)
                set -l age (__gbc_branch_age $br)
                test $age -gt 30 2>/dev/null && set stale_30 (math $stale_30 + 1)
                test $age -gt 90 2>/dev/null && set stale_90 (math $stale_90 + 1)
            end

            printf "  $BOLD$CYAN  📊 Branch Health Status$R\n\n"
            printf "  $BOLD%-25s$R  $CYAN%s$R\n" "Total local branches:" $total
            printf "  $BOLD%-25s$R  $GREEN%s$R\n" "Merged (safe to delete):" $merged
            printf "  $BOLD%-25s$R  $RED%s$R\n"   "Remote tracking gone:" $gone
            printf "  $BOLD%-25s$R  $DIM%s$R\n"   "Local only (no remote):" $no_remote
            printf "  $BOLD%-25s$R  $YELLOW%s$R\n" "Stale > 30 days:" $stale_30
            printf "  $BOLD%-25s$R  $ORANGE%s$R\n" "Stale > 90 days:" $stale_90
            printf "\n"

            # Recommendation
            set -l cleanup_count (math $merged + $gone)
            if test $cleanup_count -gt 0
                printf "  $YELLOW💡$R  $cleanup_count branch(es) ready to clean\n"
                printf "  $DIM  Run: git_branch_cleanup merged   to remove merged$R\n"
                printf "  $DIM  Run: git_branch_cleanup gone     to remove orphaned$R\n"
                printf "  $DIM  Run: git_branch_cleanup          for interactive mode$R\n"
            else
                printf "  $GREEN✓$R  Branches look healthy!\n"
            end
            printf "\n"
            return 0

        # ── MERGED: Delete branches merged into default ────────────────────────
        case merged
            __gbc_info "Fetching latest from remote..."
            git fetch --prune --quiet 2>/dev/null

            printf "  $BOLD$GREEN  Merged branches (safe to delete):$R\n\n"

            set -l merged_branches (
                git branch --merged $_default_branch 2>/dev/null | \
                    string trim | grep -v "^\*"
            )

            if test (count $merged_branches) -eq 0
                printf "  $GREEN✓$R  No merged branches found\n\n"
                return 0
            end

            for br in $merged_branches
                set -l br_clean (string trim $br)
                test -z "$br_clean" && continue

                __gbc_delete_branch $br_clean
                and set _deleted (math $_deleted + 1)
                or  set _skipped (math $_skipped + 1)

                # Also delete remote if requested
                test $_remote -eq 1 && __gbc_delete_remote $br_clean
            end

        # ── GONE: Delete branches whose remote tracking is gone ────────────────
        case gone
            __gbc_info "Pruning remote tracking references..."
            git remote prune origin --dry-run 2>/dev/null
            git fetch --prune --quiet 2>/dev/null

            printf "  $BOLD$RED  Branches with gone remote tracking:$R\n\n"

            set -l gone_branches

            for br in (__gbc_all_branches)
                set -l rs (__gbc_remote_status $br)
                if test "$rs" = gone
                    set --append gone_branches $br
                end
            end

            if test (count $gone_branches) -eq 0
                printf "  $GREEN✓$R  No orphaned branches found\n\n"
                return 0
            end

            for br in $gone_branches
                set -l age   (__gbc_branch_age $br)
                set -l date  (__gbc_branch_date $br)
                set -l author (__gbc_branch_author $br)

                printf "  $DIM  %-35s  last: %-15s  by: %s$R\n" \
                    (string sub --length 35 $br) $date (string sub --length 20 $author)

                __gbc_delete_branch $br
                and set _deleted (math $_deleted + 1)
                or  set _skipped (math $_skipped + 1)
            end

        # ── STALE: Delete branches with no activity ────────────────────────────
        case stale
            printf "  $BOLD$YELLOW  Stale branches (no commits in %d+ days):$R\n\n" $_stale_days

            set -l stale_branches

            for br in (__gbc_all_branches)
                set -l age (__gbc_branch_age $br)
                if test $age -gt $_stale_days 2>/dev/null
                    set --append stale_branches "$age:$br"
                end
            end

            if test (count $stale_branches) -eq 0
                printf "  $GREEN✓$R  No stale branches (inactive > %d days)\n\n" $_stale_days
                return 0
            end

            # Sort by age (oldest first)
            for entry in (string join \n $stale_branches | sort -rn)
                set -l age (string split ':' $entry)[1]
                set -l br  (string split ':' $entry)[2]
                set -l author (__gbc_branch_author $br)
                set -l merged (__gbc_is_merged $br && echo $GREEN"[merged]"$R || echo $DIM"[open]"$R)

                printf "  $ORANGE%-4d days$R  $DIM%-35s$R  %-12s  %s\n" \
                    $age (string sub --length 35 $br) \
                    (string sub --length 12 $author) $merged

                __gbc_delete_branch $br
                and set _deleted (math $_deleted + 1)
                or  set _skipped (math $_skipped + 1)
            end

        # ── REMOTE: Prune remote tracking branches ─────────────────────────────
        case remote
            printf "  $BOLD$BLUE  Pruning remote tracking branches:$R\n\n"

            set -l remotes (git remote 2>/dev/null)

            for remote in $remotes
                __gbc_info "Pruning remote: $remote"
                if test $_dry_run -eq 1
                    git remote prune --dry-run $remote 2>/dev/null | \
                        while read -l line; printf "  $YELLOW[DRY]$R  %s\n" $line; end
                else
                    git remote prune $remote 2>/dev/null
                    and __gbc_ok "Pruned: $remote"
                    or  __gbc_warn "No prunable refs in: $remote"
                end
            end
            printf "\n"
            return 0

        # ── ALL: Run all cleanup operations ────────────────────────────────────
        case all
            printf "  $BOLD$PURPLE  Running all cleanup operations...$R\n\n"

            # 1. Prune remotes
            __gbc_info "[1/4] Pruning remote tracking refs..."
            git fetch --prune --quiet 2>/dev/null
            __gbc_ok "Remote tracking pruned"
            printf "\n"

            # 2. Merged branches
            printf "  $BOLD  [2/4] Merged branches:$R\n"
            for br in (git branch --merged $_default_branch 2>/dev/null | string trim | grep -v '^\*')
                test -z "$br" && continue
                __gbc_delete_branch $br
                and set _deleted (math $_deleted + 1)
                or  set _skipped (math $_skipped + 1)
            end
            printf "\n"

            # 3. Gone tracking
            printf "  $BOLD  [3/4] Gone-tracking branches:$R\n"
            for br in (__gbc_all_branches)
                test (__gbc_remote_status $br) = gone || continue
                __gbc_delete_branch $br
                and set _deleted (math $_deleted + 1)
                or  set _skipped (math $_skipped + 1)
            end
            printf "\n"

            # 4. Stale > 90 days
            printf "  $BOLD  [4/4] Stale branches (>90 days):$R\n"
            for br in (__gbc_all_branches)
                set -l age (__gbc_branch_age $br)
                test $age -gt 90 2>/dev/null || continue
                __gbc_delete_branch $br
                and set _deleted (math $_deleted + 1)
                or  set _skipped (math $_skipped + 1)
            end

        # ── INTERACTIVE: fzf-powered cleanup picker ────────────────────────────
        case interactive
            if not command -q fzf
                printf "  $YELLOW⚠$R  fzf not found — running 'merged' mode\n\n"
                set _mode merged
                # Recurse into merged
                git_branch_cleanup merged $_dry_run
                return $status
            end

            # Fetch latest
            git fetch --prune --quiet 2>/dev/null

            # Build branch data with metadata
            set -l branch_lines

            for br in (__gbc_all_branches)
                set -l merged  (__gbc_is_merged $br && echo "merged" || echo "open")
                set -l remote  (__gbc_remote_status $br)
                set -l age     (__gbc_branch_age $br)
                set -l date    (__gbc_branch_date $br)
                set -l author  (string sub --length 15 (__gbc_branch_author $br))
                set -l protected (__gbc_is_protected $br && echo "🔒" || echo "  ")

                # Status badge
                set -l status_badge
                if test "$merged" = merged
                    set status_badge $GREEN"[merged]"$R
                else if test "$remote" = gone
                    set status_badge $RED"[gone]"$R
                else if test $age -gt 90 2>/dev/null
                    set status_badge $ORANGE"[stale>90d]"$R
                else if test $age -gt 30 2>/dev/null
                    set status_badge $YELLOW"[stale>30d]"$R
                else
                    set status_badge $DIM"[active]"$R
                end

                set --append branch_lines \
                    "$protected $br | $status_badge | $date | $author | $remote"
            end

            if test (count $branch_lines) -eq 0
                printf "  $GREEN✓$R  No branches to clean up\n\n"
                return 0
            end

            printf "  $DIM  Select branches to delete (Tab = multi-select)$R\n\n"

            set -l selected (
                printf '%s\n' $branch_lines |
                fzf --ansi \
                    --multi \
                    --no-sort \
                    --border-label "   Git Branch Cleanup " \
                    --border rounded \
                    --prompt "  🌿 " \
                    --pointer "▶" \
                    --marker "✓" \
                    --preview '
                        br=$(echo {} | awk -F"|" "{print \$1}" | string trim | sed "s/🔒//;s/  //")
                        echo ""
                        echo "  Branch: $br"
                        echo ""
                        git log --color=always --oneline -10 "$br" 2>/dev/null
                        echo ""
                        git diff --color=always --stat origin/'"$_default_branch"'..."$br" 2>/dev/null | head -20
                    ' \
                    --preview-window 'right:50%:border-rounded:wrap' \
                    --header "  Default: $_default_branch  ·  Current: $_current_branch  ·  Tab:multi  Enter:delete  " \
                    --header-first \
                    --height 80%
            )

            if test -z "$selected"
                printf "  $DIM  No branches selected$R\n\n"
                return 0
            end

            printf "\n  $BOLD$RED  Branches selected for deletion:$R\n\n"

            set -l to_delete
            for line in $selected
                set -l br (echo $line | awk -F"|" '{print $1}' | string trim | \
                    string replace '🔒' '' | string trim)
                test -n "$br" && set --append to_delete $br
                printf "    $RED•$R  %s\n" $br
            end

            printf "\n"

            if test $_dry_run -eq 0
                read -P "  Delete $(count $to_delete) branch(es)? [y/N] " confirm
                string match -qi 'y*' $confirm || begin
                    printf "  $DIM  Cancelled$R\n\n"; return 0
                end
            end

            printf "\n"
            for br in $to_delete
                __gbc_delete_branch $br
                and set _deleted (math $_deleted + 1)
                or  set _skipped (math $_skipped + 1)

                # Remote deletion if requested
                test $_remote -eq 1 && __gbc_delete_remote $br
            end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 SUMMARY                                                             ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _elapsed (math (date +%s) - $_ts_start)

    printf "\n"
    printf "  $DIM%s$R\n" (string repeat -n 55 "─")
    if test $_dry_run -eq 1
        printf "  $YELLOW⚠$R  DRY-RUN: %d would be deleted, %d protected\n" \
            $_deleted $_skipped
    else
        printf "  $GREEN✓$R  %d branch(es) deleted  $DIM·$R  %d protected  $DIM·$R  $DIM%ds$R\n" \
            $_deleted $_skipped $_elapsed
    end

    # Remaining branch count
    set -l remaining (git branch 2>/dev/null | wc -l | string trim)
    printf "  $DIM  Remaining branches: %s$R\n\n" $remaining

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __gbc_help __gbc_default_branch __gbc_is_protected \
        __gbc_ok __gbc_del __gbc_skip __gbc_info __gbc_warn __gbc_dry \
        __gbc_delete_branch __gbc_delete_remote __gbc_branch_age \
        __gbc_branch_date __gbc_branch_author __gbc_is_merged \
        __gbc_remote_status __gbc_all_branches 2>/dev/null

    return 0

end
