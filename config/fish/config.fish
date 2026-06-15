# Fish Configuration

# Path
set -gx PATH $HOME/.local/bin $PATH

# Editor
set -gx EDITOR nvim
set -gx VISUAL nvim

# Aliases
alias ls='eza --icons'
alias ll='eza -la --icons'
alias lt='eza --tree --icons'
alias cat='bat'
alias grep='rg'
alias find='fd'
alias vim='nvim'
alias vi='nvim'

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -10'
alias gd='git diff'

# Hyprland
alias hypr='hyprctl'
alias reload='hyprctl reload'
alias hyprpaper='hyprctl hyprpaper'

# Functions
function ash
    ~/.config/hypr/scripts/ash $argv
end

# Prompt
fish_add_path $HOME/.local/bin

# Starship
starship init fish | source