# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — UPDATE FISH FUNCTION                         ║
# ║           Update dotfiles and system packages                              ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function update -d "Update ASH dotfiles and system packages"
    set -l c_ok    (set_color a6e3a1)
    set -l c_err   (set_color f38ba8)
    set -l c_info  (set_color 89b4fa)
    set -l c_warn  (set_color f9e2af)
    set -l c_title (set_color -o cba6f7)
    set -l c_reset (set_color normal)

    set -l mode "all"
    if test (count $argv) -gt 0
        set mode $argv[1]
    end

    echo ""
    echo -e "  $c_title📦 ASH Update System$c_reset"
    echo ""

    switch $mode
        case all "" --all
            update dots
            update system
            update nvim

        case dots -d --dotfiles
            echo -e "  $c_info→$c_reset Updating dotfiles..."

            if command -q ash
                ash update
            else if test -d ~/.dotfiles/.git
                cd ~/.dotfiles
                git pull origin (git branch --show-current 2>/dev/null || echo "main") 2>/dev/null
                and echo -e "  $c_ok✓$c_reset Dotfiles updated"
                or echo -e "  $c_err✗$c_reset Update failed"
                cd -
            else
                echo -e "  $c_warn⚠$c_reset No git repo found at ~/.dotfiles"
            end

        case system -s --system
            echo -e "  $c_info→$c_reset Updating system packages..."

            set -l aur_helper ""
            if command -q paru;     set aur_helper paru
            else if command -q yay; set aur_helper yay
            end

            if test -n "$aur_helper"
                echo -e "  $c_info→$c_reset Using $aur_helper..."
                $aur_helper -Syu --noconfirm 2>/dev/null
                and echo -e "  $c_ok✓$c_reset System packages updated"
                or echo -e "  $c_warn⚠$c_reset Update had issues — check manually"
            else
                echo -e "  $c_info→$c_reset Using pacman..."
                sudo pacman -Syu --noconfirm 2>/dev/null
                and echo -e "  $c_ok✓$c_reset System updated"
                or echo -e "  $c_warn⚠$c_reset Update failed"
            end

        case nvim --neovim
            echo -e "  $c_info→$c_reset Updating Neovim plugins..."
            if command -q nvim
                nvim --headless "+Lazy! sync" +qa 2>/dev/null
                and echo -e "  $c_ok✓$c_reset Neovim plugins updated"
                or echo -e "  $c_warn⚠$c_reset Neovim update failed"
            else
                echo -e "  $c_warn⚠$c_reset Neovim not installed"
            end

        case fish --fish
            echo -e "  $c_info→$c_reset Updating Fish plugins..."
            if functions -q fisher
                fisher update 2>/dev/null
                and echo -e "  $c_ok✓$c_reset Fish plugins updated"
                or echo -e "  $c_warn⚠$c_reset Fisher update failed"
            else
                echo -e "  $c_warn⚠$c_reset Fisher not installed"
            end

        case theme --theme
            echo -e "  $c_info→$c_reset Reapplying theme..."
            ash theme reapply 2>/dev/null
            and echo -e "  $c_ok✓$c_reset Theme reapplied"
            or echo -e "  $c_warn⚠$c_reset Theme reapply failed"

        case check --check
            echo -e "  $c_info→$c_reset Checking for updates..."
            if test -d ~/.dotfiles/.git
                cd ~/.dotfiles
                git fetch origin 2>/dev/null
                set -l behind (git rev-list HEAD...origin/main --count 2>/dev/null || echo 0)
                if test $behind -gt 0
                    echo -e "  $c_warn⚠$c_reset $behind update(s) available — run: update dots"
                else
                    echo -e "  $c_ok✓$c_reset Dotfiles up to date"
                end
                cd -
            end

            # Check system
            if command -q checkupdates
                set -l sys_updates (checkupdates 2>/dev/null | wc -l)
                echo -e "  $c_info→$c_reset System updates available: $sys_updates"
            end

        case help -h --help
            echo ""
            echo "  update [mode]"
            echo ""
            echo "  all       Update everything (default)"
            echo "  dots      Update dotfiles repository"
            echo "  system    Update system packages"
            echo "  nvim      Update Neovim plugins"
            echo "  fish      Update Fish plugins"
            echo "  theme     Reapply current theme"
            echo "  check     Check for available updates"
            echo ""

        case '*'
            echo -e "  $c_err✗$c_reset Unknown mode: $mode"
            echo "  Run: update help"
    end

    echo ""
end

complete -c update -f
complete -c update -n "__fish_use_subcommand" -a all    -d "Update everything"
complete -c update -n "__fish_use_subcommand" -a dots   -d "Update dotfiles"
complete -c update -n "__fish_use_subcommand" -a system -d "Update system"
complete -c update -n "__fish_use_subcommand" -a nvim   -d "Update Neovim"
complete -c update -n "__fish_use_subcommand" -a fish   -d "Update Fish plugins"
complete -c update -n "__fish_use_subcommand" -a theme  -d "Reapply theme"
complete -c update -n "__fish_use_subcommand" -a check  -d "Check updates"