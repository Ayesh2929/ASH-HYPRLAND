# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — CDF FUNCTION                                 ║
# ║           cd into directory containing a specific file (fzf-powered)       ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function cdf -d "CD to directory containing a file (fzf)"
    set -l c_ok    (set_color green)
    set -l c_reset (set_color normal)

    set -l query "${argv[1]:-}"

    if not command -q fzf
        echo "fzf not installed"
        return 1
    end

    set -l selected (
        fd --type f \
           --hidden \
           --follow \
           --exclude .git \
           --exclude node_modules \
           $query 2>/dev/null |
        fzf --height 60% \
            --reverse \
            --border rounded \
            --prompt "  File > " \
            --pointer "▶" \
            --preview 'bat --color=always --style=numbers --line-range :30 {}' \
            --preview-window 'right:50%:border-left' \
            --color "border:#45475a,prompt:#f9e2af,pointer:#f9e2af" \
            --query "$query"
    )

    if test -n "$selected"
        set -l dir (dirname "$selected")
        cd "$dir"
        echo -s $c_ok"📂 "$c_reset(pwd)
        echo -s "  File: "(basename "$selected")
    end
end

complete -c cdf -F