# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WALLSET FISH FUNCTION                        ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function wallset -d "Set wallpaper and apply theme"
    set -l c_ok    (set_color a6e3a1)
    set -l c_info  (set_color 89b4fa)
    set -l c_warn  (set_color f9e2af)
    set -l c_reset (set_color normal)

    set -l picker  ~/.config/hypr/scripts/theme/wallpaper-picker.sh
    set -l engine  ~/.config/hypr/scripts/theme/theme-engine.sh

    if test (count $argv) -eq 0
        echo -e "  $c_info→$c_reset Opening wallpaper picker..."
        test -x $picker && $picker || echo -e "  $c_warn⚠$c_reset Picker not found"
        return
    end

    switch $argv[1]
        case random r
            echo -e "  $c_info→$c_reset Random wallpaper..."
            test -x $picker && $picker random $argv[2..-1]
        case next n
            test -x $picker && $picker next
        case prev p previous
            test -x $picker && $picker prev
        case list l
            test -x $picker && $picker list
        case '*'
            set -l wall_path (string replace -r "^~" $HOME $argv[1])
            if test -f "$wall_path"
                echo -e "  $c_info→$c_reset Setting: "(basename $wall_path)
                if test -x $engine
                    $engine "$wall_path" apply &
                    echo -e "  $c_ok✓$c_reset Theme engine started"
                else if command -q swww
                    swww img "$wall_path" --transition-type grow --transition-duration 2
                    echo -e "  $c_ok✓$c_reset Wallpaper set"
                else
                    echo -e "  $c_warn⚠$c_reset No wallpaper setter available"
                end
            else
                echo -e "  Not found: $wall_path"
            end
    end
end

complete -c wallset -f
complete -c wallset -n "__fish_use_subcommand" -a random -d "Random wallpaper"
complete -c wallset -n "__fish_use_subcommand" -a next   -d "Next wallpaper"
complete -c wallset -n "__fish_use_subcommand" -a prev   -d "Previous wallpaper"
complete -c wallset -n "__fish_use_subcommand" -a list   -d "List wallpapers"
complete -c wallset -F