# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — Z FUNCTION                                   ║
# ║           Jump to frequently visited directories (zoxide wrapper)          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function z -d "Jump to a frequently visited directory"
    # If zoxide is available, use it
    if command -q zoxide
        if test (count $argv) -eq 0
            # No args: go home
            cd ~
        else if test "$argv[1]" = "-"
            # Go to previous directory
            cd -
        else
            # Use zoxide
            set -l result (zoxide query -- $argv 2>/dev/null)
            if test $status -eq 0 -a -n "$result"
                cd "$result"
            else
                # Fallback: try direct cd
                cd $argv 2>/dev/null
                or echo "z: directory not found: $argv"
            end
        end
    else
        # No zoxide: basic cd
        cd $argv 2>/dev/null
        or echo "z: not found: $argv (install zoxide for smart jumping)"
    end
end

# Interactive jump with fzf
function zi -d "Interactive directory jump (zoxide + fzf)"
    if command -q zoxide
        if command -q fzf
            set -l result (
                zoxide query --list --score 2>/dev/null |
                fzf --height 40% \
                    --reverse \
                    --border rounded \
                    --prompt "  Jump > " \
                    --pointer "▶" \
                    --color "border:#45475a,prompt:#cba6f7,pointer:#cba6f7" \
                    --with-nth=2 \
                    --preview 'eza --color=always --icons {2} 2>/dev/null | head -10' \
                    --preview-window 'right:35%:border-left'
            )
            if test -n "$result"
                set -l dir (echo $result | awk '{print $2}')
                cd "$dir"
                zoxide add "$dir"
            end
        else
            zoxide query --interactive
        end
    else
        echo "zi: zoxide not installed (paru -S zoxide)"
    end
end

complete -c z  -f -a "(zoxide query --list --score 2>/dev/null | awk '{print \$2}')"
complete -c zi -f