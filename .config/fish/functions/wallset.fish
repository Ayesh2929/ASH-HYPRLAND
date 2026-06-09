# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WALLSET FUNCTION                             ║
# ║           Quick wallpaper setter with theme engine integration             ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function wallset -d "Set wallpaper and apply theme"
    set -l c_ok    (set_color a6e3a1)
    set -l c_err   (set_color f38ba8)
    set -l c_info  (set_color 89b4fa)
    set -l c_warn  (set_color f9e2af)
    set -l c_reset (set_color normal)

    set -l wall_picker ~/.config/hypr/scripts/theme/wallpaper-picker.sh
    set -l theme_engine ~/.config/hypr/scripts/theme/theme-engine.sh

    # No arguments — open picker
    if test -z "$argv"
        if test -x $wall_picker
            $wall_picker
        else
            echo -s $c_err"❌ Wallpaper picker not found"$c_reset
            return 1
        end
        return 0
    end

    switch $argv[1]
        case random r
            echo -s $c_info"🎲 Setting random wallpaper..."$c_reset
            $wall_picker random
        case next n
            $wall_picker next
        case prev p previous
            $wall_picker prev
        case list l
            $wall_picker list
        case '*'
            # Treat as file path
            set -l wall_path $argv[1]

            # Expand ~ manually
            set wall_path (string replace -r "^~" $HOME $wall_path)

            if not test -f "$wall_path"
                echo -s $c_err"❌ File not found: $wall_path"$c_reset
                return 1
            end

            echo -s $c_info"🖼️ Setting wallpaper: "(basename $wall_path)$c_reset

            if test -x $theme_engine
                $theme_engine "$wall_path" apply &
                echo -s $c_ok"✅ Theme engine started in background"$c_reset
            else if command -q swww
                swww img "$wall_path" \
                    --transition-type grow \
                    --transition-duration 2 \
                    2>/dev/null
                echo -s $c_ok"✅ Wallpaper set via swww"$c_reset
            else
                echo -s $c_warn"⚠ No wallpaper setter available"$c_reset
            end
    end
end

complete -c wallset -f
complete -c wallset -n "__fish_use_subcommand" -a random  -d "Random wallpaper"
complete -c wallset -n "__fish_use_subcommand" -a next    -d "Next wallpaper"
complete -c wallset -n "__fish_use_subcommand" -a prev    -d "Previous wallpaper"
complete -c wallset -n "__fish_use_subcommand" -a list    -d "List wallpapers"
complete -c wallset -F