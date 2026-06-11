# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — FISH ALIASES                                 ║
# ║           Function-based aliases for frequently used commands              ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# 📁 NAVIGATION
# ═══════════════════════════════════════════════════════════════════════════════

# Enhanced ls using eza
if command -q eza
    function ls   ; eza --icons --group-directories-first $argv; end
    function ll   ; eza -la --icons --group-directories-first --git --time-style=relative $argv; end
    function la   ; eza -a --icons --group-directories-first $argv; end
    function lt   ; eza --tree --icons --group-directories-first -L 2 $argv; end
    function llt  ; eza -la --tree --icons --group-directories-first --git -L 2 $argv; end
    function l    ; eza -1 --icons $argv; end
    function tree ; eza --tree --icons $argv; end
end

# Quick directory jumps
function ..   ; cd ..; end
function ...  ; cd ../..; end
function .... ; cd ../../..; end

# ═══════════════════════════════════════════════════════════════════════════════
# 🐱 CAT / PAGER
# ═══════════════════════════════════════════════════════════════════════════════

if command -q bat
    function cat  ; bat --style=numbers,changes $argv; end
    function catp ; bat --style=plain $argv; end
    function less ; bat --style=numbers,changes --pager="less -R" $argv; end
    function more ; bat $argv; end
end

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 SEARCH
# ═══════════════════════════════════════════════════════════════════════════════

if command -q rg
    function grep  ; rg --color=always $argv; end
    function grepi ; rg --color=always --ignore-case $argv; end
end

if command -q fd
    function find ; fd $argv; end
end

# ═══════════════════════════════════════════════════════════════════════════════
# 🌐 NETWORK
# ═══════════════════════════════════════════════════════════════════════════════

function myip
    curl -s "https://ipinfo.io/ip" 2>/dev/null
    echo ""
end

function localip
    ip -4 addr show 2>/dev/null | grep -oP '(?<=inet )[\d.]+(?=/)' | grep -v '^127'
end

function ports
    ss -tulpn 2>/dev/null || netstat -tulpn 2>/dev/null
end

function ping
    command ping -c 5 $argv
end

# ═══════════════════════════════════════════════════════════════════════════════
# 🔊 AUDIO / MEDIA
# ═══════════════════════════════════════════════════════════════════════════════

function vol
    ~/.config/hypr/scripts/media/volume.sh $argv
end

function bright
    ~/.config/hypr/scripts/media/brightness.sh $argv
end

# ═══════════════════════════════════════════════════════════════════════════════
# 🖥️ SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

# Process management
function psa  ; ps aux $argv; end
function psg  ; ps aux | grep $argv; end

# System info
function sysinfo ; ~/.config/fish/functions/sysinfo.fish; end
function df   ; command df -h $argv; end
function du   ; command du -sh $argv; end
function free ; command free -h $argv; end

# Quick editor
function e    ; nvim $argv; end
function v    ; nvim $argv; end

# Sudo shortcut
function please ; sudo $argv; end

# System services
function sc   ; sudo systemctl $argv; end
function scu  ; systemctl --user $argv; end
function jc   ; sudo journalctl $argv; end
function jcf  ; sudo journalctl -f $argv; end
function jcu  ; journalctl --user $argv; end

# ═══════════════════════════════════════════════════════════════════════════════
# 🐙 GIT SHORTCUTS (function-based for complex behavior)
# ═══════════════════════════════════════════════════════════════════════════════

function git-clean-branches
    git branch --merged | grep -v "\*\|main\|master\|develop" \
        | xargs -r git branch -d
    echo "✓ Cleaned merged branches"
end

function git-recent
    git log --oneline --decorate --all -n 20
end

function git-conflicts
    git diff --name-only --diff-filter=U
end

function git-root
    cd (git rev-parse --show-toplevel 2>/dev/null || echo ".")
end

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 HYPRLAND / ASH
# ═══════════════════════════════════════════════════════════════════════════════

function hypr-reload
    hyprctl reload && echo "✓ Hyprland reloaded"
end

function waybar-reload
    pkill -SIGUSR2 waybar 2>/dev/null; or (pkill waybar; waybar &)
    echo "✓ Waybar reloaded"
end

function wall
    ash theme pick
end

function theme-random
    ash theme random
end

# ═══════════════════════════════════════════════════════════════════════════════
# 🧹 CLEANUP
# ═══════════════════════════════════════════════════════════════════════════════

function clean-cache
    ash clean deep
    echo "✓ Cache cleaned"
end

function clean-pkgs
    sudo pacman -Sc --noconfirm
    sudo pacman -Qdtq | sudo pacman -Rns - 2>/dev/null
    echo "✓ Packages cleaned"
end

# ═══════════════════════════════════════════════════════════════════════════════
# 💡 MISC
# ═══════════════════════════════════════════════════════════════════════════════

function reload-fish
    source ~/.config/fish/config.fish
    echo "✓ Fish config reloaded"
end

function now
    date '+%Y-%m-%d %H:%M:%S'
end

function week
    date +%V
end

function timestamp
    date +%s
end

function uuid
    cat /proc/sys/kernel/random/uuid
end

function genpass
    openssl rand -base64 32 | tr -d '/+' | cut -c1-24
end

function sha256
    command sha256sum $argv
end

function clip
    if test (count $argv) -gt 0
        echo $argv | wl-copy
    else
        wl-copy
    end
    echo "✓ Copied to clipboard"
end

function paste
    wl-paste
end

function open
    xdg-open $argv &
    disown
end

function qr
    # Generate QR code from text
    if command -q qrencode
        qrencode -t UTF8 "$argv"
    else
        echo "Install: paru -S qrencode"
    end
end

function colors-256
    # Show 256 color palette
    for i in (seq 0 255)
        printf "\e[38;5;%dm %3d \e[0m" $i $i
        test (math "$i % 16") -eq 15 && echo
    end
end

function colors-true
    # Test true color support
    awk 'BEGIN{
        s="/\\/\\/\\/\\/\\"; s=s s s s s s s s;
        for (colnum = 0; colnum<77; colnum++) {
            r = 255-(colnum*255/76);
            g = (colnum*510/76);
            b = (colnum*255/76);
            if (g>255) g = 510-g;
            printf "\033[48;2;%d;%d;%dm", r,g,b;
            printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
            printf "%s\033[0m", substr(s,colnum+1,1);
        }
        printf "\n";
    }'
end