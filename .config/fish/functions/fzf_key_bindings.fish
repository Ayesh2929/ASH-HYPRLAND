# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — FZF KEY BINDINGS FOR FISH                    ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function fzf_key_bindings -d "Set up FZF key bindings for Fish"
    # Only set up if fzf is installed
    if not command -q fzf
        return 0
    end

    # CTRL+R — History search
    bind \cr __fzf_history_search

    # CTRL+T — File search
    bind \ct __fzf_file_search

    # ALT+C — Directory jump
    bind \ec __fzf_dir_jump

    # CTRL+F — Find and open file
    bind \cf __fzf_file_open

    function __fzf_history_search
        set -l query (commandline)
        set -l result (
            history |
            fzf --query "$query" \
                --no-sort \
                --height 40% \
                --reverse \
                --border rounded \
                --prompt "  History > " \
                --pointer "▶" \
                --color "bg+:#313244,fg:#cdd6f4,hl:#cba6f7,border:#45475a,prompt:#cba6f7"
        )
        if test -n "$result"
            commandline -- $result
        end
        commandline -f repaint
    end

    function __fzf_file_search
        set -l result (
            fd --type f --hidden --follow --exclude .git 2>/dev/null |
            fzf --height 60% \
                --reverse \
                --border rounded \
                --prompt "  File > " \
                --pointer "▶" \
                --preview 'bat --color=always --line-range :50 {} 2>/dev/null' \
                --preview-window 'right:50%:border-left' \
                --color "bg+:#313244,fg:#cdd6f4,hl:#89b4fa,border:#45475a,prompt:#89b4fa"
        )
        if test -n "$result"
            commandline -i -- (string escape $result)
        end
        commandline -f repaint
    end

    function __fzf_dir_jump
        set -l result (
            fd --type d --hidden --follow --exclude .git 2>/dev/null |
            fzf --height 40% \
                --reverse \
                --border rounded \
                --prompt "  Jump > " \
                --pointer "▶" \
                --preview 'eza --color=always --icons {} 2>/dev/null | head -15' \
                --preview-window 'right:35%:border-left' \
                --color "bg+:#313244,fg:#cdd6f4,hl:#94e2d5,border:#45475a,prompt:#94e2d5"
        )
        if test -n "$result"
            cd "$result"
            commandline -f repaint
        end
    end

    function __fzf_file_open
        set -l result (
            fd --type f --hidden --follow --exclude .git 2>/dev/null |
            fzf --height 60% \
                --reverse \
                --border rounded \
                --prompt "  Open > " \
                --pointer "▶" \
                --preview 'bat --color=always --style=numbers --line-range :50 {} 2>/dev/null' \
                --preview-window 'right:55%:border-left' \
                --color "bg+:#313244,fg:#cdd6f4,hl:#f9e2af,border:#45475a,prompt:#f9e2af"
        )
        if test -n "$result"
            nvim "$result"
        end
        commandline -f repaint
    end
end

# Auto-initialize bindings
fzf_key_bindings