# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — FISH VI MODE PROMPT                          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function fish_mode_prompt -d "Display Vi mode indicator"
    # Only show in Vi mode
    if test "$fish_key_bindings" = "fish_vi_key_bindings"
        switch $fish_bind_mode
            case default
                set_color --bold red
                echo '[N] '
            case insert
                set_color --bold green
                echo '[I] '
            case replace_one
                set_color --bold yellow
                echo '[R] '
            case replace
                set_color --bold yellow
                echo '[R] '
            case visual
                set_color --bold blue
                echo '[V] '
            case '*'
                set_color --bold red
                echo '[?] '
        end
        set_color normal
    end
end