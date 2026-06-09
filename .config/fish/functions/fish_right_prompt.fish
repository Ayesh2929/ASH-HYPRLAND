function fish_right_prompt
    if not set -q STARSHIP_SHELL
    set_color brblack
    echo -n (date "+%H:%M:%S")
    set_color normal
    end
    end