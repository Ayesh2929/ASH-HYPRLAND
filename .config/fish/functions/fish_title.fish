# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — FISH WINDOW TITLE                            ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function fish_title
    # Set terminal window title dynamically
    set -l cwd (prompt_pwd --full-length-dirs=2)
    set cwd (string replace -r "^$HOME" "~" $cwd)

    # Show running command if available
    if test -n "$argv"
        set -l cmd (string split " " $argv[1])[1]
        echo "⚡ $cmd · $cwd"
    else
        echo "🐟 $cwd — "(string upper $USER)
    end
end