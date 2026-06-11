# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — CDF FUNCTION                                 ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function cdf -d "CD to directory of file found by fzf"
    set -l c_ok    (set_color a6e3a1)
    set -l c_reset (set_color normal)

    if not command -q fzf
        echo "fzf not installed (paru -S fzf)"
        return 1
    end

    set -l query $argv[1]

    set -l selected (
        fd --type f --hidden --follow \
           --exclude .git --exclude node_modules \
           $query 2>/dev/null |
        fzf --height 60% \
            --reverse \
            --border rounded \
            --prompt "  File → cd to dir > " \
            --pointer "▶" \
            --preview 'bat --color=always --style=numbers --line-range :30 {} 2>/dev/null || cat {}' \
            --preview-window 'right:50%:border-left' \
            --color "border:#45475a,prompt:#f9e2af,pointer:#f9e2af" \
            --query "$query"
    )

    if test -n "$selected"
        set -l dir (dirname "$selected")
        cd "$dir"
        echo -s $c_ok"📂 "$c_reset(pwd)
        echo "  File: "(basename "$selected")
    end
end

complete -c cdf -F