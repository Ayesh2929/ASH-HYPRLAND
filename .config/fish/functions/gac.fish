# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — GIT ADD & COMMIT FUNCTION                    ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function gac -d "Git add all and commit with message"
    set -l c_ok    (set_color a6e3a1)
    set -l c_err   (set_color f38ba8)
    set -l c_info  (set_color 89b4fa)
    set -l c_muted (set_color 7f849c)
    set -l c_reset (set_color normal)

    # Ensure we're in a git repo
    if not git rev-parse --git-dir > /dev/null 2>&1
        echo -s $c_err"❌ Not a git repository"$c_reset
        return 1
    end

    # Build commit message from args
    set -l commit_msg (string join " " $argv)

    # Interactive if no message
    if test -z "$commit_msg"
        # Show current status
        echo -s $c_info"📊 Current git status:"$c_reset
        git status --short
        echo ""

        # Prompt for message
        read -P "💬 Commit message: " commit_msg
        if test -z "$commit_msg"
            echo -s $c_err"❌ Commit message cannot be empty"$c_reset
            return 1
        end
    end

    # Show what will be committed
    echo -s $c_info"📁 Files to commit:"$c_reset
    git status --short

    # Add all changes
    git add --all
    if test $status -ne 0
        echo -s $c_err"❌ git add failed"$c_reset
        return 1
    end

    # Commit
    git commit -m "$commit_msg"
    set -l commit_status $status

    if test $commit_status -eq 0
        set -l hash (git rev-parse --short HEAD)
        set -l branch (git branch --show-current)
        echo ""
        echo -s $c_ok"✅ Committed "$c_muted"[$branch $hash]"$c_reset": $commit_msg"

        # Offer to push
        set -l remote (git remote 2>/dev/null | head -1)
        if test -n "$remote"
            read -P "🚀 Push to $remote? [y/N]: " do_push
            if test (string lower $do_push) = "y"
                git push $remote $branch
                and echo -s $c_ok"✅ Pushed to $remote/$branch"$c_reset
                or echo -s $c_err"❌ Push failed"$c_reset
            end
        end
    else
        echo -s $c_err"❌ Commit failed"$c_reset
        return $commit_status
    end
end

complete -c gac -d "Git add all and commit"