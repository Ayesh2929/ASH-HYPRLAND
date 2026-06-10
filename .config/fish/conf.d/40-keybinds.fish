# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — FISH CUSTOM KEYBINDS                         ║
# ║           Custom keyboard shortcuts for Fish shell                         ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

# Run after default key bindings are loaded
function fish_user_key_bindings

    # ── FZF Integration ───────────────────────────────────────────────────────

    # CTRL+R — FZF history search (override default)
    if command -q fzf
        bind \cr __fzf_history
        bind \cf __fzf_find_file
        bind \ce __fzf_cd
    end

    # ── Navigation ────────────────────────────────────────────────────────────

    # ALT+. — Insert last argument from previous command
    bind \e. 'history-token-search-backward'

    # CTRL+F — Accept autosuggestion word by word
    bind \cf forward-word

    # CTRL+D — Delete word forward
    bind \cd delete-word

    # ALT+BACKSPACE — Delete word backward
    bind \e\b backward-kill-word

    # ── Editing ───────────────────────────────────────────────────────────────

    # CTRL+X+E — Edit command in $EDITOR
    bind \cx\ce edit_command_buffer

    # CTRL+U — Clear line before cursor (already default, but ensure it)
    bind \cu backward-kill-line

    # CTRL+K — Clear line after cursor
    bind \ck kill-line

    # ── History ───────────────────────────────────────────────────────────────

    # CTRL+P/N — History navigation
    bind \cp up-or-search
    bind \cn down-or-search

    # ── Custom ────────────────────────────────────────────────────────────────

    # ALT+W — Set wallpaper (if in Hyprland)
    bind \ew 'ash theme pick &; commandline -f repaint'

    # ALT+L — Clear screen (keep scrollback)
    bind \el 'clear; commandline -f repaint'

    # CTRL+G — Open Lazygit
    bind \cg 'lazygit; commandline -f repaint'

    # CTRL+O — Open file manager
    bind \co 'nemo . &; commandline -f repaint'

end

# ── FZF Helper Functions ───────────────────────────────────────────────────────

function __fzf_history
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
            --color "border:#45475a,prompt:#cba6f7,pointer:#cba6f7"
    )
    if test -n "$result"
        commandline -- $result
    end
    commandline -f repaint
end

function __fzf_find_file
    set -l result (
        fd --type f --hidden --follow --exclude .git 2>/dev/null |
        fzf --height 60% \
            --reverse \
            --border rounded \
            --prompt "  Files > " \
            --pointer "▶" \
            --preview 'bat --color=always --style=numbers --line-range :50 {}' \
            --preview-window 'right:55%:border-left' \
            --color "border:#45475a,prompt:#89b4fa,pointer:#89b4fa"
    )
    if test -n "$result"
        commandline -i -- (string escape $result)
    end
    commandline -f repaint
end

function __fzf_cd
    set -l result (
        fd --type d --hidden --follow --exclude .git 2>/dev/null |
        fzf --height 40% \
            --reverse \
            --border rounded \
            --prompt "  Dirs > " \
            --pointer "▶" \
            --preview 'eza --tree --color=always --icons {} | head -20' \
            --preview-window 'right:40%:border-left' \
            --color "border:#45475a,prompt:#94e2d5,pointer:#94e2d5"
    )
    if test -n "$result"
        cd $result
        commandline -f repaint
    end
end