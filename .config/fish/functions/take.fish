# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — TAKE FUNCTION                                ║
# ║           Create directory and cd into it (zsh-style)                     ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function take -d "Create directory tree and cd into it"
    if test (count $argv) -eq 0
        echo "Usage: take <directory>"
        return 1
    end

    set -l target $argv[1]
    mkdir -p $target
    and cd $target
    and echo (set_color green)"✓"(set_color normal)" Created and entered: "(pwd)
end

complete -c take -F