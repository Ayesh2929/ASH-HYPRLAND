# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — GitHub CLI Ultra Configuration                     ║
# ║  gh CLI with PRs, issues, Actions, releases, Copilot & full GH ecosystem   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_ghcli_loaded && exit 0
set --global _ash_ghcli_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 DETECTION                                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

command -q gh || exit 0

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_gh_log      "$HOME/.local/share/ash/logs/ghcli.log"
set --global _ash_gh_cache    "$HOME/.local/share/ash/cache/ghcli"
set --global _ash_gh_cache_ttl 120

mkdir -p (dirname $_ash_gh_log) 2>/dev/null
mkdir -p $_ash_gh_cache         2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _gh_reset   (set_color normal)
set -g _gh_bold    (set_color --bold)
set -g _gh_cyan    (set_color cyan)
set -g _gh_green   (set_color green)
set -g _gh_yellow  (set_color yellow)
set -g _gh_red     (set_color red)
set -g _gh_blue    (set_color blue)
set -g _gh_purple  (set_color 6e40c9)   # GitHub purple
set -g _gh_dim     (set_color brblack)
set -g _gh_white   (set_color white)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  ENVIRONMENT SETUP                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── GH_CONFIG_DIR (XDG-aware) ─────────────────────────────────────────────────
set --export GH_CONFIG_DIR "$HOME/.config/gh"

# ── Default editor for gh edit commands ───────────────────────────────────────
set --export GH_EDITOR (set -q VISUAL && echo $VISUAL || set -q EDITOR && echo $EDITOR || echo nvim)

# ── Pager ─────────────────────────────────────────────────────────────────────
if command -q bat
    set --export GH_PAGER "bat --style=plain --color=always"
else
    set --export GH_PAGER "less -R"
end

# ── Host (for GitHub Enterprise) ──────────────────────────────────────────────
# set --export GH_HOST "github.mycompany.com"

# ── Shell completions ──────────────────────────────────────────────────────────
gh completion --shell fish 2>/dev/null | source

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎯 CACHING HELPERS                                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __gh_cached --description "Cached gh CLI result"
    set -l key   $argv[1]
    set -l cmd   $argv[2..-1]
    set -l cache "$_ash_gh_cache/$key"

    if test -f $cache
        set -l age (math (date +%s) - (stat -c %Y $cache 2>/dev/null; or echo 0))
        test $age -lt $_ash_gh_cache_ttl && cat $cache && return
    end

    set -l result (eval $cmd 2>/dev/null)
    echo $result > $cache 2>/dev/null
    echo $result
end

function __gh_current_repo --description "Get current GitHub repo (owner/name)"
    gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null
end

function __gh_default_branch --description "Get default branch of current repo"
    gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📋 PULL REQUESTS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── gh-pr-ls: Rich PR listing ────────────────────────────────────────────────
function gh-pr-ls --description "List pull requests with rich formatting"
    set -l state $argv[1]
    test -z "$state" && set state open

    set -l reset (set_color normal)
    set -l bold  (set_color --bold)
    set -l cyan  (set_color cyan)
    set -l green (set_color green)
    set -l red   (set_color red)
    set -l dim   (set_color brblack)
    set -l purple (set_color 6e40c9)

    echo ""
    echo $bold$purple"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$purple"  ║     🔀  Pull Requests ($state)                        ║"$reset
    echo $bold$purple"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    gh pr list \
        --state $state \
        --json number,title,author,headRefName,reviewDecision,isDraft,createdAt,additions,deletions \
        --jq '.[] |
            "\(.number)\t\(.title)\t\(.author.login)\t\(.headRefName)\t\(.reviewDecision // "PENDING")\t\(.isDraft)\t+\(.additions)/-\(.deletions)"
        ' 2>/dev/null | \
    while read -l line
        set -l parts (string split \t $line)
        set -l num    $parts[1]
        set -l title  $parts[2]
        set -l author $parts[3]
        set -l branch $parts[4]
        set -l review $parts[5]
        set -l draft  $parts[6]
        set -l diff   $parts[7]

        set -l review_icon ""
        switch $review
            case APPROVED
                set review_icon (set_color green)"✓"$reset
            case CHANGES_REQUESTED
                set review_icon (set_color red)"✗"$reset
            case '*'
                set review_icon (set_color brblack)"⋯"$reset
        end

        set -l draft_icon ""
        test "$draft" = true && set draft_icon $dim"[draft] "$reset

        printf "  $purple#%-5s$reset  $review_icon  $draft_icon%-40s  $dim%-15s$reset  $cyan%s$reset\n" \
            $num (string sub --length 40 $title) $author $diff
    end
    echo ""
end

# ─── gh-pr-smart: Interactive PR operations ───────────────────────────────────
function gh-pr-smart --description "Interactive PR operations with fzf"
    command -q fzf || begin; gh pr list; return; end

    set -l action $argv[1]
    test -z "$action" && set action view

    set -l pr_num (
        gh pr list \
            --state open \
            --json number,title,author,reviewDecision,additions,deletions \
            --jq '.[] | "#\(.number) \(.title) [\(.author.login)] +\(.additions)/-\(.deletions)"' 2>/dev/null |
        fzf --ansi \
            --border-label "  🔀 Pull Requests " \
            --border rounded \
            --prompt "  🔀 " \
            --pointer "▶" \
            --preview 'gh pr view {1} --comments 2>/dev/null | head -60' \
            --preview-window 'right:55%:border-rounded:wrap' \
            --header "  Enter:$action  Ctrl-O:browser  Ctrl-C:checkout  Ctrl-M:merge  " \
            --bind 'ctrl-o:execute(gh pr view {1} --web)' \
            --bind 'ctrl-c:execute(gh pr checkout {1})+abort' \
            --bind 'ctrl-m:execute(gh pr merge {1} --merge)+abort' \
        | awk '{gsub("#",""); print $1}'
    )
    test -z "$pr_num" && return 0

    switch $action
        case view
            gh pr view $pr_num --comments
        case checkout
            gh pr checkout $pr_num
        case merge
            gh pr merge $pr_num --merge
        case close
            gh pr close $pr_num
        case reopen
            gh pr reopen $pr_num
        case review
            gh pr review $pr_num
    end
end

# ─── gh-pr-create-smart: Smart PR creation ────────────────────────────────────
function gh-pr-create-smart --description "Create PR with smart defaults"
    set -l base   $argv[1]
    set -l title  $argv[2]

    test -z "$base" && set base (__gh_default_branch)

    echo ""
    echo $_gh_purple"  🔀 Creating Pull Request"$_gh_reset

    set -l branch (git branch --show-current 2>/dev/null)
    echo "  Branch: "$_gh_cyan$branch$_gh_reset
    echo "  Base:   "$_gh_cyan$base$_gh_reset
    echo ""

    set -l create_args "--base $base"

    # Auto-title from branch name
    if test -z "$title"
        set title (string replace -r '^(feat|fix|chore|docs|refactor|style|test|ci|perf)/' '' $branch | \
            string replace -a '-' ' ' | \
            string replace -a '_' ' ')
        set title (string upper -- (string sub --length 1 -- $title))(string sub --start 2 -- $title)
    end

    # Detect if draft
    read -P "  Create as draft? [y/N] " is_draft
    string match -qi 'y*' $is_draft && set create_args "$create_args --draft"

    gh pr create \
        --base $base \
        --title "$title" \
        $create_args \
        --fill \
        $argv[3..-1]

    and begin
        echo ""
        echo $_gh_green"  ✓ PR created"$_gh_reset
        gh pr view --web 2>/dev/null
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐛 ISSUES                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── gh-issue-ls: Rich issue listing ──────────────────────────────────────────
function gh-issue-ls --description "List issues with rich formatting"
    set -l state $argv[1]
    set -l label $argv[2]
    test -z "$state" && set state open

    echo ""
    echo $_gh_bold$_gh_purple"  🐛 Issues ($state)"$_gh_reset
    echo ""

    set -l jq_filter '.[] |
        "#\(.number)\t\(.title)\t\(.author.login)\t\(.labels[].name // "")\t\(.createdAt)"'

    set -l list_args "--state $state"
    test -n "$label" && set list_args "$list_args --label $label"

    gh issue list $list_args \
        --json number,title,author,labels,createdAt \
        --jq "$jq_filter" 2>/dev/null | \
    while read -l line
        set -l parts (string split \t $line)
        printf "  $_gh_purple%-8s$_gh_reset  %-42s  $_gh_dim%s$_gh_reset\n" \
            $parts[1] (string sub --length 42 $parts[2]) $parts[3]
    end
    echo ""
end

# ─── gh-issue-smart: Interactive issue operations ─────────────────────────────
function gh-issue-smart --description "Interactive issue operations"
    command -q fzf || begin; gh issue list; return; end

    set -l action $argv[1]
    test -z "$action" && set action view

    set -l issue_num (
        gh issue list \
            --state open \
            --json number,title,author,labels \
            --jq '.[] | "#\(.number) \(.title) [\(.author.login)]"' 2>/dev/null |
        fzf --ansi \
            --border-label "  🐛 Issues " \
            --border rounded \
            --prompt "  🐛 " \
            --pointer "▶" \
            --preview 'gh issue view {1} 2>/dev/null | head -50' \
            --preview-window 'right:55%:border-rounded:wrap' \
            --header "  Enter:$action  Ctrl-O:browser  Ctrl-C:comment  " \
            --bind 'ctrl-o:execute(gh issue view {1} --web)' \
        | awk '{gsub("#",""); print $1}'
    )
    test -z "$issue_num" && return 0

    switch $action
        case view
            gh issue view $issue_num --comments | \
                command -q bat && bat --language=markdown --style=plain --color=always || cat
        case close
            gh issue close $issue_num
        case reopen
            gh issue reopen $issue_num
        case comment
            gh issue comment $issue_num
        case assign
            gh issue edit $issue_num --add-assignee @me
    end
end

# ─── gh-issue-create-smart: Smart issue creation ──────────────────────────────
function gh-issue-create-smart --description "Create issue with template selection"
    set -l title $argv[1]

    echo ""
    echo $_gh_cyan"  🐛 Creating Issue"$_gh_reset

    # Template selection
    set -l templates (gh issue list --json title 2>/dev/null | jq -r 'empty')
    set -l template_args ""

    if command -q fzf
        set -l tmpl (
            printf "Bug Report\nFeature Request\nDocumentation\nPerformance\nQuestion\n" |
            fzf --border-label "  📋 Issue Template " \
                --border rounded \
                --prompt "  " \
                --no-multi
        )
        test -n "$tmpl" && set template_args "--template '$tmpl'"
    end

    gh issue create \
        --assignee @me \
        $template_args \
        $argv[2..-1]

    and echo $_gh_green"  ✓ Issue created"$_gh_reset
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ GITHUB ACTIONS                                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── gh-runs: List workflow runs ──────────────────────────────────────────────
function gh-runs --description "List and monitor GitHub Actions workflow runs"
    set -l workflow $argv[1]

    echo ""
    echo $_gh_bold$_gh_purple"  ⚡ Workflow Runs"$_gh_reset
    echo ""

    set -l list_args ""
    test -n "$workflow" && set list_args "--workflow $workflow"

    gh run list $list_args \
        --json databaseId,workflowName,status,conclusion,createdAt,headBranch \
        --jq '.[] |
            "\(.databaseId)\t\(.workflowName)\t\(.status)\t\(.conclusion // "running")\t\(.headBranch)\t\(.createdAt)"
        ' 2>/dev/null | head -20 | \
    while read -l line
        set -l parts (string split \t $line)
        set -l id         $parts[1]
        set -l workflow   $parts[2]
        set -l status     $parts[3]
        set -l conclusion $parts[4]
        set -l branch     $parts[5]
        set -l created    $parts[6]

        set -l status_icon
        switch $conclusion
            case success completed
                set status_icon $_gh_green"✓"$_gh_reset
            case failure
                set status_icon $_gh_red"✗"$_gh_reset
            case cancelled
                set status_icon $_gh_yellow"○"$_gh_reset
            case '*'
                set status_icon $_gh_cyan"⋯"$_gh_reset
        end

        printf "  %s  %-10s  %-35s  $_gh_dim%s$_gh_reset\n" \
            $status_icon $_gh_dim$id$_gh_reset (string sub --length 35 $workflow) $branch
    end
    echo ""
end

# ─── gh-run-watch: Watch a workflow run ───────────────────────────────────────
function gh-run-watch --description "Watch a GitHub Actions workflow run"
    set -l run_id $argv[1]

    if test -z "$run_id"
        if command -q fzf
            set run_id (
                gh run list \
                    --json databaseId,workflowName,status,headBranch \
                    --jq '.[] | "\(.databaseId)\t\(.workflowName) [\(.headBranch)] - \(.status)"' 2>/dev/null |
                fzf --ansi \
                    --border-label "  ⚡ Select Run " \
                    --border rounded \
                    --prompt "  ⚡ " \
                    --pointer "▶" \
                    --preview 'gh run view {1} 2>/dev/null | head -40' \
                    --preview-window 'right:50%:border-rounded:wrap' \
                | awk '{print $1}'
            )
            test -z "$run_id" && return 0
        else
            echo "  Usage: gh-run-watch <run-id>"
            return 1
        end
    end

    gh run watch $run_id
end

# ─── gh-run-logs: View run logs ───────────────────────────────────────────────
function gh-run-logs --description "View GitHub Actions run logs"
    set -l run_id $argv[1]

    if test -z "$run_id"
        set run_id (
            gh run list \
                --json databaseId,workflowName,conclusion \
                --jq '.[] | "\(.databaseId)\t\(.workflowName) (\(.conclusion // "running"))"' 2>/dev/null |
            fzf --border-label "  📋 Select Run Logs " \
                --border rounded \
                --prompt "  " \
                --pointer "▶" \
            | awk '{print $1}'
        )
        test -z "$run_id" && return 0
    end

    gh run view $run_id --log 2>/dev/null | \
        command -q bat && bat --language=log --style=plain --color=always --paging=never || cat
end

# ─── gh-workflow-trigger: Manually trigger workflow ───────────────────────────
function gh-workflow-trigger --description "Manually trigger a GitHub Actions workflow"
    set -l workflow $argv[1]
    set -l branch   $argv[2]

    if test -z "$workflow" && command -q fzf
        set workflow (
            gh workflow list \
                --json id,name,state \
                --jq '.[] | "\(.name)"' 2>/dev/null |
            fzf --border-label "  ⚡ Select Workflow " \
                --border rounded \
                --prompt "  " \
                --pointer "▶"
        )
        test -z "$workflow" && return 0
    end

    test -z "$branch" && set branch (git branch --show-current 2>/dev/null)

    echo ""
    echo $_gh_cyan"  ⚡ Triggering: $workflow ($branch)"$_gh_reset
    gh workflow run "$workflow" --ref $branch $argv[3..-1]
    and begin
        echo $_gh_green"  ✓ Workflow triggered"$_gh_reset
        sleep 2
        gh-runs
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📦 RELEASES                                                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── gh-release-ls: List releases ─────────────────────────────────────────────
function gh-release-ls --description "List GitHub releases"
    echo ""
    echo $_gh_bold$_gh_purple"  📦 Releases"$_gh_reset
    echo ""

    gh release list \
        --json tagName,name,isDraft,isPrerelease,createdAt,publishedAt \
        --jq '.[] |
            "\(.tagName)\t\(.name)\t\(if .isDraft then "[DRAFT]" elif .isPrerelease then "[PRE]" else "" end)\t\(.publishedAt // .createdAt)"
        ' 2>/dev/null | \
    while read -l line
        set -l parts (string split \t $line)
        set -l flag_color ""
        string match -q '*DRAFT*' $parts[3]  && set flag_color $_gh_yellow
        string match -q '*PRE*'   $parts[3]  && set flag_color $_gh_cyan

        printf "  $_gh_purple%-15s$_gh_reset  %-30s  $flag_color%-10s$_gh_reset  $_gh_dim%s$_gh_reset\n" \
            $parts[1] (string sub --length 30 $parts[2]) $parts[3] $parts[4]
    end
    echo ""
end

# ─── gh-release-create: Create a new release ──────────────────────────────────
function gh-release-create --description "Create a new GitHub release"
    set -l tag   $argv[1]
    set -l title $argv[2]

    if test -z "$tag"
        set -l latest (git describe --tags --abbrev=0 2>/dev/null)
        echo ""
        echo "  Latest tag: "$_gh_dim$latest$_gh_reset
        read -P "  New tag: " tag
    end
    test -z "$tag" && return 1

    test -z "$title" && set title $tag

    echo ""
    echo $_gh_cyan"  📦 Creating release: $tag"$_gh_reset

    read -P "  Pre-release? [y/N] " is_pre
    set -l pre_flag ""
    string match -qi 'y*' $is_pre && set pre_flag "--prerelease"

    gh release create $tag \
        --title "$title" \
        --generate-notes \
        $pre_flag \
        $argv[3..-1]

    and echo $_gh_green"  ✓ Release created: $tag"$_gh_reset
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 REPOSITORY MANAGEMENT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── gh-repo-ls: List user repositories ──────────────────────────────────────
function gh-repo-ls --description "List GitHub repositories"
    set -l filter $argv[1]

    echo ""
    echo $_gh_bold$_gh_purple"  📁 Repositories"$_gh_reset
    echo ""

    set -l list_args ""
    test -n "$filter" && set list_args "--source" # owned repos only

    gh repo list \
        --json nameWithOwner,description,isPrivate,stargazerCount,primaryLanguage,updatedAt \
        --limit 30 \
        --jq '.[] |
            "\(.nameWithOwner)\t\(.description // "")\t\(.primaryLanguage.name // "")\t⭐\(.stargazerCount)\t\(if .isPrivate then "🔒" else "🌐" end)"
        ' 2>/dev/null | \
    while read -l line
        set -l parts (string split \t $line)
        printf "  $_gh_purple%-40s$_gh_reset  $_gh_cyan%-10s$_gh_reset  %-12s  $_gh_dim%s$_gh_reset\n" \
            $parts[1] $parts[3] $parts[4] (string sub --length 35 $parts[2])
    end
    echo ""
end

# ─── gh-repo-clone-smart: Clone with directory setup ─────────────────────────
function gh-repo-clone-smart --description "Clone GitHub repo with smart setup"
    set -l repo $argv[1]
    set -l dir  $argv[2]

    if test -z "$repo"
        if command -q fzf
            set repo (
                gh repo list \
                    --json nameWithOwner,description,isPrivate \
                    --jq '.[] | "\(.nameWithOwner)\t\(.description // "")"' 2>/dev/null |
                fzf --ansi \
                    --border-label "  📁 Select Repository " \
                    --border rounded \
                    --prompt "  🔍 " \
                    --pointer "▶" \
                    --preview 'gh repo view {1} 2>/dev/null | head -30' \
                    --preview-window 'right:50%:border-rounded:wrap' \
                | awk '{print $1}'
            )
            test -z "$repo" && return 0
        else
            echo "  Usage: gh-repo-clone-smart <owner/repo>"
            return 1
        end
    end

    echo ""
    echo $_gh_cyan"  📥 Cloning: $repo"$_gh_reset
    gh repo clone $repo $dir $argv[3..-1]

    set -l clone_dir (test -n "$dir" && echo $dir || basename $repo)

    if test $status -eq 0 && test -d $clone_dir
        cd $clone_dir
        echo $_gh_green"  ✓ Cloned → $clone_dir"$_gh_reset
        echo ""

        # Show repo info
        gh repo view --json name,description,stargazerCount,forkCount \
            --jq '"  ⭐ Stars: \(.stargazerCount)  🍴 Forks: \(.forkCount)"' 2>/dev/null
        echo ""
    end
end

# ─── gh-repo-info: Show repository information ────────────────────────────────
function gh-repo-info --description "Show current repository information"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l purple (set_color 6e40c9)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l yellow (set_color yellow)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$purple"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$purple"  ║     🐙  Repository Dashboard                         ║"$reset
    echo $bold$purple"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    set -l repo_info (gh repo view \
        --json nameWithOwner,description,stargazerCount,forkCount,watchers,openIssuesCount,\
primaryLanguage,isPrivate,isArchived,defaultBranchRef,homepageUrl,createdAt \
        2>/dev/null)

    if test -z "$repo_info" || not command -q jq
        echo "  "$yellow"Not in a GitHub repository or not logged in"$reset
        return 1
    end

    set -l name     (echo $repo_info | jq -r '.nameWithOwner')
    set -l desc     (echo $repo_info | jq -r '.description // "(no description)"')
    set -l stars    (echo $repo_info | jq -r '.stargazerCount')
    set -l forks    (echo $repo_info | jq -r '.forkCount')
    set -l issues   (echo $repo_info | jq -r '.openIssuesCount')
    set -l lang     (echo $repo_info | jq -r '.primaryLanguage.name // "Unknown"')
    set -l private  (echo $repo_info | jq -r '.isPrivate')
    set -l branch   (echo $repo_info | jq -r '.defaultBranchRef.name // "main"')
    set -l homepage (echo $repo_info | jq -r '.homepageUrl // ""')

    echo "  "$bold"Repo:    "$reset $purple$name$reset (test "$private" = true && echo $_gh_yellow" 🔒 private"$_gh_reset || echo $_gh_green" 🌐 public"$_gh_reset)
    echo "  "$bold"Desc:    "$reset $dim$desc$reset
    echo "  "$bold"Branch:  "$reset $cyan$branch$reset
    echo "  "$bold"Lang:    "$reset $cyan$lang$reset
    echo ""
    echo "  "$bold"⭐ Stars:  "$reset $yellow$stars$reset
    echo "  "$bold"🍴 Forks:  "$reset $cyan$forks$reset
    echo "  "$bold"🐛 Issues: "$reset $dim$issues$reset
    test -n "$homepage" && echo "  "$bold"🌐 Web:    "$reset $dim$homepage$reset

    echo ""
    echo "  "$bold"Open PRs:   "$reset (gh pr list --json number --jq 'length' 2>/dev/null)
    echo "  "$bold"Workflows:  "$reset (gh workflow list --json id --jq 'length' 2>/dev/null)
    echo ""
end

# ─── gh-gist: Gist management ─────────────────────────────────────────────────
function gh-gist --description "GitHub Gist management"
    set -l action $argv[1]

    switch $action
        case ls list
            gh gist list --json id,description,isPublic,createdAt \
                --jq '.[] | "\(.id)\t\(.description // "(no desc)")\t\(if .isPublic then "public" else "secret" end)"' \
                2>/dev/null | \
            while read -l line
                set -l parts (string split \t $line)
                printf "  $_gh_purple%-35s$_gh_reset  %-35s  $_gh_dim%s$_gh_reset\n" \
                    $parts[1] (string sub --length 35 $parts[2]) $parts[3]
            end

        case create
            set -l file $argv[2]
            set -l desc $argv[3]
            test -z "$file" && begin; echo "  Usage: gh-gist create <file> [description]"; return 1; end
            set -l create_args ""
            test -n "$desc" && set create_args "--desc '$desc'"
            eval gh gist create $file $create_args
            and echo $_gh_green"  ✓ Gist created"$_gh_reset

        case view
            if command -q fzf
                set -l gist_id (
                    gh gist list \
                        --json id,description \
                        --jq '.[] | "\(.id)\t\(.description // "(no desc)")"' 2>/dev/null |
                    fzf --border-label "  📝 Select Gist " \
                        --border rounded \
                        --prompt "  " \
                        --pointer "▶" \
                        --preview 'gh gist view {1} 2>/dev/null | head -40' \
                        --preview-window 'right:55%:border-rounded:wrap' \
                    | awk '{print $1}'
                )
                test -n "$gist_id" && gh gist view $gist_id
            else
                gh gist list
            end

        case '*'
            echo "  Usage: gh-gist <list|create|view>"
    end
end

# ─── gh-copilot: GitHub Copilot CLI ───────────────────────────────────────────
function gh-copilot --description "GitHub Copilot CLI assistant"
    command -q gh-copilot || begin
        gh extension install github/gh-copilot 2>/dev/null
    end

    set -l action $argv[1]

    switch $action
        case suggest
            gh copilot suggest $argv[2..-1]
        case explain
            gh copilot explain $argv[2..-1]
        case '*'
            echo "  Usage: gh-copilot <suggest|explain> <prompt>"
    end
end

# ─── gh-notify: Show GitHub notifications ─────────────────────────────────────
function gh-notify --description "Show and manage GitHub notifications"
    set -l count $argv[1]
    test -z "$count" && set count 15

    echo ""
    echo $_gh_bold$_gh_purple"  🔔 GitHub Notifications"$_gh_reset
    echo ""

    if command -q gh-notify
        gh notify -s -n $count
        return
    end

    gh api notifications \
        --paginate \
        --jq '.[].subject | "\(.type)\t\(.title)\t\(.url)"' 2>/dev/null | \
        head -$count | \
    while read -l line
        set -l parts (string split \t $line)
        printf "  $_gh_cyan%-15s$_gh_reset  %s\n" $parts[1] $parts[2]
    end
    echo ""
end

# ─── gh-info: Complete GitHub CLI dashboard ────────────────────────────────────
function gh-info --description "Show GitHub CLI environment information"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l purple (set_color 6e40c9)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$purple"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$purple"  ║     🐙  GitHub CLI Dashboard                         ║"$reset
    echo $bold$purple"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"Version:  "$reset $dim(gh --version 2>/dev/null | head -1)$reset
    echo "  "$bold"Config:   "$reset $dim$GH_CONFIG_DIR$reset
    echo ""

    # Auth status
    set -l auth (gh auth status 2>&1)
    if echo $auth | grep -q "Logged in"
        set -l username (gh api user --jq '.login' 2>/dev/null)
        set -l plan     (gh api user --jq '.plan.name // "free"' 2>/dev/null)
        echo "  "$bold"User:     "$reset $purple$username$reset
        echo "  "$bold"Plan:     "$reset $cyan$plan$reset
    else
        echo "  "$yellow"⚠  Not logged in"$reset
    end

    # Extensions
    echo ""
    echo "  "$bold"Extensions:"$reset
    gh extension list 2>/dev/null | while read -l ext
        echo "    "$dim"• "$reset$ext
    end
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Pull Requests
abbr --add ghpr    'gh-pr-ls'
abbr --add ghprs   'gh-pr-smart'
abbr --add ghprc   'gh-pr-create-smart'
abbr --add ghprco  'gh pr checkout'
abbr --add ghprm   'gh pr merge'
abbr --add ghprv   'gh pr view'
abbr --add ghprw   'gh pr view --web'

# Issues
abbr --add ghis    'gh-issue-ls'
abbr --add ghiss   'gh-issue-smart'
abbr --add ghisc   'gh-issue-create-smart'
abbr --add ghisv   'gh issue view'
abbr --add ghisw   'gh issue view --web'

# Actions
abbr --add ghrun   'gh-runs'
abbr --add ghrunw  'gh-run-watch'
abbr --add ghrunl  'gh-run-logs'
abbr --add ghwf    'gh workflow list'
abbr --add ghwft   'gh-workflow-trigger'

# Releases
abbr --add ghrel   'gh-release-ls'
abbr --add ghrelc  'gh-release-create'
abbr --add ghreld  'gh release download'

# Repos
abbr --add ghrl    'gh-repo-ls'
abbr --add ghrc    'gh-repo-clone-smart'
abbr --add ghri    'gh-repo-info'
abbr --add ghrv    'gh repo view --web'
abbr --add ghrcrte 'gh repo create'
abbr --add ghrfork 'gh repo fork'

# Auth
abbr --add ghauth  'gh auth login'
abbr --add ghwho   'gh auth status'
abbr --add ghinfo  'gh-info'

# Gist
abbr --add ghgist  'gh-gist list'
abbr --add ghgistc 'gh-gist create'
abbr --add ghgistv 'gh-gist view'

# Copilot
abbr --add ghcp    'gh-copilot suggest'
abbr --add ghce    'gh-copilot explain'
abbr --add ghnot   'gh-notify'

# SSH keys
abbr --add ghkeys  'gh ssh-key list'
abbr --add ghkeya  'gh ssh-key add'

# General
abbr --add ghver   'gh --version'
abbr --add ghext   'gh extension list'
abbr --add ghexi   'gh extension install'