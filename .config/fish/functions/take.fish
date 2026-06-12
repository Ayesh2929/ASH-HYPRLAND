# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — TAKE FUNCTION (VERIFIED)                     ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function take -d "Create directory and cd into it (zsh-style)"
    if test (count $argv) -eq 0
        echo "Usage: take <directory>"
        return 1
    end

    set -l c_ok    (set_color a6e3a1)
    set -l c_reset (set_color normal)

    set -l target $argv[1]

    mkdir -p $target
    and cd $target
    and echo -e "  $c_ok📂$c_reset "(pwd)
end

complete -c take -F