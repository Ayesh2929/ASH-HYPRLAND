# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — FCD FUNCTION                                 ║
# ║           FZF-powered interactive cd                                        ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function fcd -d "FZF interactive directory changer"
    set -l c_ok    (set_color green)
    set -l c_info  (set_color cyan)
    set -l c_reset (set_color normal)

    set -l search_root "${argv[1]:-$HOME}"

    if not command -q fzf
        echo "fzf not installed — using basic cd"
        cd $argv
        return
    end

    set -l selected (
        fd --type directory \
           --hidden \
           --follow \
           --exclude .git \
           --exclude node_modules \
           --exclude __pycache__ \
           --exclude .cargo \
           . $search_root 2>/dev/null |
        fzf --height 60% \
            --reverse \
            --border rounded \
            --prompt "  cd > " \
            --pointer "▶" \
            --marker "✓" \
            --preview 'eza --tree --color=always --icons --level=2 {} 2>/dev/null | head -30' \
            --preview-window 'right:45%:border-left' \
            --bind 'ctrl-/:toggle-preview' \
            --color "bg+:#313244,bg:#1e1e2e,hl:#89b4fa,fg:#cdd6f4" \
            --color "border:#45475a,prompt:#94e2d5,pointer:#94e2d5"
    )

    if test -n "$selected"
        cd "$selected"
        echo -s $c_ok"📂 "$ c_reset(pwd)
    end
end

complete -c fcd -F