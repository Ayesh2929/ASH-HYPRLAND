# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — fish_mode_prompt Ultra                             ║
# ║  Vi/Normal/Replace/Visual mode indicator with animations & ASH theming     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function fish_mode_prompt --description "ASH ultra vi-mode indicator"

    # ── Skip if vi mode is disabled ───────────────────────────────────────────
    test "$fish_key_bindings" = fish_default_key_bindings && return 0

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 COLOR RESOLUTION — ASH theme sync                                   ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __mode_color --description "Resolve color from ASH theme or fallback"
        set -l key "ASH_COLOR_"(string upper $argv[1])
        set -l fallback $argv[2]
        if set -q $key
            set_color (string replace '#' '' $$key) 2>/dev/null && return
        end
        set_color $fallback 2>/dev/null
    end

    set -l R     (set_color normal)
    set -l BOLD  (set_color --bold)
    set -l DIM   (set_color brblack)

    set -l COL_INSERT   (__mode_color mauve   magenta)
    set -l COL_NORMAL   (__mode_color blue    blue)
    set -l COL_VISUAL   (__mode_color yellow  yellow)
    set -l COL_REPLACE  (__mode_color red     red)
    set -l COL_REPLACE1 (__mode_color peach   FF9F43)
    set -l COL_SEARCH   (__mode_color green   green)

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎭 MODE CONFIGURATION                                                  ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # Style: block | compact | minimal | icon | powerline
    set -l style (set -q ASH_MODE_PROMPT_STYLE && echo $ASH_MODE_PROMPT_STYLE || echo block)

    # ── Ensure bind mode is set ────────────────────────────────────────────────
    set -q fish_bind_mode || set -g fish_bind_mode insert

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 STYLE: BLOCK (default)                                              ║
    # ╔══════════════════════════════════════════════════════════════════════════╝

    function __mode_block --description "Render block-style mode indicator"
        switch $fish_bind_mode
            case insert
                printf "%s%s INSERT %s " $COL_INSERT $BOLD $R
            case default normal
                printf "%s%s NORMAL %s " $COL_NORMAL $BOLD $R
            case visual
                printf "%s%s VISUAL %s " $COL_VISUAL $BOLD $R
            case replace
                printf "%s%s REPLACE %s " $COL_REPLACE $BOLD $R
            case replace_one
                printf "%s%s REPLACE(1) %s " $COL_REPLACE1 $BOLD $R
            case '*'
                printf "%s%s %s %s " $DIM $BOLD (string upper $fish_bind_mode) $R
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 STYLE: COMPACT                                                      ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __mode_compact --description "Render compact mode indicator"
        switch $fish_bind_mode
            case insert
                printf "%s[I]%s " $COL_INSERT $R
            case default normal
                printf "%s[N]%s " $BOLD$COL_NORMAL $R
            case visual
                printf "%s[V]%s " $BOLD$COL_VISUAL $R
            case replace
                printf "%s[R]%s " $BOLD$COL_REPLACE $R
            case replace_one
                printf "%s[r]%s " $COL_REPLACE1 $R
            case '*'
                printf "%s[?]%s " $DIM $R
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 STYLE: MINIMAL (cursor hint only)                                   ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __mode_minimal --description "Render minimal mode indicator"
        # Only show non-insert modes
        switch $fish_bind_mode
            case insert
                return   # nothing shown in insert
            case default normal
                printf "%s❮%s " $BOLD$COL_NORMAL $R
            case visual
                printf "%s◆%s " $BOLD$COL_VISUAL $R
            case replace replace_one
                printf "%s▶%s " $COL_REPLACE $R
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 STYLE: ICON                                                         ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __mode_icon --description "Render icon-style mode indicator"
        switch $fish_bind_mode
            case insert
                printf "%s%s ✎  %s" $COL_INSERT $BOLD $R
            case default normal
                printf "%s%s   %s" $BOLD$COL_NORMAL $BOLD $R
            case visual
                printf "%s%s   %s" $BOLD$COL_VISUAL $BOLD $R
            case replace
                printf "%s%s   %s" $BOLD$COL_REPLACE $BOLD $R
            case replace_one
                printf "%s%s   %s" $COL_REPLACE1 $BOLD $R
            case '*'
                printf "%s%s   %s" $DIM $BOLD $R
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 STYLE: POWERLINE                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __mode_powerline --description "Render powerline-style mode indicator"
        set -l bg_col
        set -l fg_col (set_color white)
        set -l label

        switch $fish_bind_mode
            case insert
                set bg_col $COL_INSERT
                set label "  INSERT"
            case default normal
                set bg_col $COL_NORMAL
                set label "  NORMAL"
            case visual
                set bg_col $COL_VISUAL
                set label "  VISUAL"
            case replace
                set bg_col $COL_REPLACE
                set label "  REPLACE"
            case replace_one
                set bg_col $COL_REPLACE1
                set label "  R-ONE"
            case '*'
                set bg_col $DIM
                set label "  (string upper $fish_bind_mode)"
        end

        printf "%s%s%s%s%s%s " \
            $BOLD $fg_col $bg_col \
            " $label " \
            $R $bg_col "❯" $R
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🖨️  DISPATCH STYLE                                                      ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    switch $style
        case block
            __mode_block
        case compact
            __mode_compact
        case minimal
            __mode_minimal
        case icon
            __mode_icon
        case powerline
            __mode_powerline
        case '*'
            __mode_block
    end

    # ── Cursor shape: change per mode ─────────────────────────────────────────
    # Only works in terminals that support DECSCUSR (most modern ones do)
    if set -q ASH_VI_CURSOR && test "$ASH_VI_CURSOR" = 1
        switch $fish_bind_mode
            case insert
                printf '\e[5 q'   # blinking bar
            case default normal
                printf '\e[1 q'   # blinking block
            case visual
                printf '\e[3 q'   # blinking underline
            case replace replace_one
                printf '\e[3 q'   # blinking underline
        end
    end

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __mode_color __mode_block __mode_compact \
        __mode_minimal __mode_icon __mode_powerline 2>/dev/null

end
