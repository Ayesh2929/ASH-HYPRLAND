# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — FISH ABBREVIATIONS (100+)                    ║
# ║           Expanding abbreviations for maximum productivity                 ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# 📦 PACKAGE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

# Paru/Yay shortcuts
abbr -a p    'paru'
abbr -a pi   'paru -S'
abbr -a pr   'paru -Rns'
abbr -a pu   'paru -Syu'
abbr -a ps   'paru -Ss'
abbr -a pq   'paru -Q'
abbr -a pqi  'paru -Qi'
abbr -a pql  'paru -Ql'
abbr -a pqe  'paru -Qe'
abbr -a pqo  'paru -Qo'

# Pacman shortcuts
abbr -a pac  'sudo pacman'
abbr -a pacs 'sudo pacman -S'
abbr -a pacr 'sudo pacman -Rns'
abbr -a pacu 'sudo pacman -Syu'
abbr -a pacss 'pacman -Ss'
abbr -a pacq  'pacman -Q'

# ═══════════════════════════════════════════════════════════════════════════════
# 📁 FILE SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

# eza (modern ls)
abbr -a ls   'eza --icons --group-directories-first'
abbr -a ll   'eza -la --icons --group-directories-first --git'
abbr -a la   'eza -a --icons --group-directories-first'
abbr -a lt   'eza --tree --icons --group-directories-first'
abbr -a llt  'eza -la --tree --icons --group-directories-first --git'
abbr -a l    'eza -1 --icons'

# Navigation
abbr -a ..   'cd ..'
abbr -a ...  'cd ../..'
abbr -a .... 'cd ../../..'
abbr -a ~    'cd ~'

# File operations
abbr -a cp   'cp -iv'
abbr -a mv   'mv -iv'
abbr -a rm   'rm -Iv'
abbr -a mkdir 'mkdir -pv'
abbr -a ln   'ln -v'
abbr -a chmod 'chmod -v'
abbr -a chown 'chown -v'

# Directory shortcuts
abbr -a docs 'cd ~/Documents'
abbr -a dl   'cd ~/Downloads'
abbr -a pics 'cd ~/Pictures'
abbr -a vids 'cd ~/Videos'
abbr -a music 'cd ~/Music'
abbr -a walls 'cd ~/Pictures/Wallpapers'
abbr -a shots 'cd ~/Pictures/Screenshots'

# File viewing
abbr -a cat  'bat'
abbr -a less 'bat'
abbr -a head 'bat --line-range :20'
abbr -a more 'bat'

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 SEARCH
# ═══════════════════════════════════════════════════════════════════════════════

abbr -a grep  'grep --color=auto'
abbr -a rg    'rg --color=always --smart-case'
abbr -a fd    'fd --hidden'
abbr -a fda   'fd --hidden --no-ignore'
abbr -a find  'fd'

# ═══════════════════════════════════════════════════════════════════════════════
# 🐙 GIT
# ═══════════════════════════════════════════════════════════════════════════════

abbr -a g    'git'
abbr -a gi   'git init'
abbr -a ga   'git add'
abbr -a gaa  'git add --all'
abbr -a gau  'git add --update'
abbr -a gc   'git commit'
abbr -a gcm  'git commit -m'
abbr -a gca  'git commit --amend'
abbr -a gcam 'git commit -am'
abbr -a gd   'git diff'
abbr -a gdc  'git diff --cached'
abbr -a gds  'git diff --stat'
abbr -a gs   'git status'
abbr -a gss  'git status --short'
abbr -a gl   'git log --oneline --graph --decorate'
abbr -a gll  'git log --graph --decorate --all'
abbr -a glo  'git log --oneline -20'
abbr -a gp   'git push'
abbr -a gpf  'git push --force-with-lease'
abbr -a gpo  'git push origin'
abbr -a gpu  'git pull'
abbr -a gpuo 'git pull origin'
abbr -a gf   'git fetch'
abbr -a gfa  'git fetch --all'
abbr -a gco  'git checkout'
abbr -a gcb  'git checkout -b'
abbr -a gb   'git branch'
abbr -a gba  'git branch --all'
abbr -a gbd  'git branch --delete'
abbr -a gm   'git merge'
abbr -a gr   'git rebase'
abbr -a gri  'git rebase --interactive'
abbr -a gst  'git stash'
abbr -a gstp 'git stash pop'
abbr -a gstl 'git stash list'
abbr -a gcl  'git clone'
abbr -a grs  'git restore'
abbr -a grst 'git restore --staged'
abbr -a glg  'lazygit'
abbr -a gwt  'git worktree'

# ═══════════════════════════════════════════════════════════════════════════════
# 💻 EDITORS
# ═══════════════════════════════════════════════════════════════════════════════

abbr -a v    'nvim'
abbr -a vi   'nvim'
abbr -a vim  'nvim'
abbr -a nv   'nvim'
abbr -a nano 'nvim'
abbr -a e    'nvim'

# Config editing
abbr -a vhypr  'nvim ~/.config/hypr/hyprland.conf'
abbr -a vfish  'nvim ~/.config/fish/config.fish'
abbr -a vnvim  'nvim ~/.config/nvim/init.lua'
abbr -a vway   'nvim ~/.config/waybar/configs/top.jsonc'
abbr -a vuser  'nvim ~/.config/hypr/UserOverrides/user.conf'
abbr -a vstar  'nvim ~/.config/starship.toml'

# ═══════════════════════════════════════════════════════════════════════════════
# 🐳 DOCKER / CONTAINERS
# ═══════════════════════════════════════════════════════════════════════════════

abbr -a d    'docker'
abbr -a dc   'docker compose'
abbr -a dcu  'docker compose up -d'
abbr -a dcd  'docker compose down'
abbr -a dcl  'docker compose logs -f'
abbr -a dps  'docker ps'
abbr -a dpsa 'docker ps -a'
abbr -a di   'docker images'
abbr -a drm  'docker rm'
abbr -a drmi 'docker rmi'
abbr -a dex  'docker exec -it'
abbr -a dl   'docker logs'
abbr -a dlf  'docker logs -f'

# Podman (drop-in Docker replacement)
abbr -a pod  'podman'
abbr -a podc 'podman compose'

# ═══════════════════════════════════════════════════════════════════════════════
# 🐍 PYTHON
# ═══════════════════════════════════════════════════════════════════════════════

abbr -a py   'python3'
abbr -a py3  'python3'
abbr -a pip  'pip3'
abbr -a pipi 'pip3 install'
abbr -a pipu 'pip3 install --upgrade'
abbr -a venv 'python3 -m venv'
abbr -a va   'source .venv/bin/activate.fish'
abbr -a vd   'deactivate'

# ═══════════════════════════════════════════════════════════════════════════════
# 🦀 RUST
# ═══════════════════════════════════════════════════════════════════════════════

abbr -a cr   'cargo run'
abbr -a cb   'cargo build'
abbr -a cbt  'cargo build --release'
abbr -a ct   'cargo test'
abbr -a cc   'cargo check'
abbr -a cf   'cargo fmt'
abbr -a ccl  'cargo clippy'
abbr -a cu   'cargo update'
abbr -a cadd 'cargo add'
abbr -a crm  'cargo remove'

# ═══════════════════════════════════════════════════════════════════════════════
# 🌐 NETWORKING
# ═══════════════════════════════════════════════════════════════════════════════

abbr -a ping  'ping -c 5'
abbr -a p8    'ping 8.8.8.8'
abbr -a myip  "curl -s 'https://ipinfo.io/ip'"
abbr -a localip "ip -4 addr show | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}' | grep -v 127"
abbr -a ports 'ss -tulpn'
abbr -a wgup  'sudo wg-quick up'
abbr -a wgdn  'sudo wg-quick down'
abbr -a speedtest 'curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -'
abbr -a wget  'wget --show-progress'
abbr -a curl  'curl --progress-bar'

# HTTP server (quick)
abbr -a serve 'python3 -m http.server'
abbr -a serve8 'python3 -m http.server 8080'

# ═══════════════════════════════════════════════════════════════════════════════
# 🖥️ SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

abbr -a top   'btop'
abbr -a htop  'btop'
abbr -a neofetch 'fastfetch'
abbr -a fetch 'fastfetch'
abbr -a sysctl 'sudo sysctl'
abbr -a journalctl 'sudo journalctl'
abbr -a systemctl 'sudo systemctl'
abbr -a sc    'sudo systemctl'
abbr -a scu   'systemctl --user'
abbr -a df    'df -h'
abbr -a du    'du -sh'
abbr -a duh   'du -sh * | sort -h'
abbr -a free  'free -h'
abbr -a lsmem 'sudo lshw -short'
abbr -a cpuinfo 'cat /proc/cpuinfo | grep "model name" | head -1'
abbr -a gpuinfo 'lspci | grep -i vga'
abbr -a meminfo 'cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable|SwapTotal|SwapFree"'
abbr -a killall 'pkill -x'
abbr -a pkill  'pkill -x'

# Process management
abbr -a psa  'ps aux'
abbr -a psg  'ps aux | grep'
abbr -a k9   'kill -9'
abbr -a k15  'kill -15'

# Sudo
abbr -a s    'sudo'
abbr -a sn   'sudo -n'
abbr -a please 'sudo'

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 HYPRLAND / ASH SPECIFIC
# ═══════════════════════════════════════════════════════════════════════════════

abbr -a hypr  'hyprctl'
abbr -a hctl  'hyprctl'
abbr -a hrl   'hyprctl reload'
abbr -a hkil  'hyprctl kill'
abbr -a hmon  'hyprctl monitors'
abbr -a hwins 'hyprctl clients'
abbr -a hws   'hyprctl workspaces'

# ASH CLI
abbr -a ash-theme    'ash theme pick'
abbr -a ash-random   'ash theme random'
abbr -a ash-reload   'ash reload'
abbr -a ash-lock     'ash lock'
abbr -a ash-check    'ash doctor'

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 MONITORING
# ═══════════════════════════════════════════════════════════════════════════════

abbr -a watch 'watch -n 2'
abbr -a wm    'watch -n 1 free -h'
abbr -a wc    'watch -n 1 "cat /proc/cpuinfo | grep MHz | head -$(nproc)"'
abbr -a wt    'watch -n 2 sensors'

# ═══════════════════════════════════════════════════════════════════════════════
# 🗜️ ARCHIVE
# ═══════════════════════════════════════════════════════════════════════════════

abbr -a tgz    'tar czf'
abbr -a tgzx   'tar xzf'
abbr -a tbz    'tar cjf'
abbr -a tbzx   'tar xjf'
abbr -a txz    'tar cJf'
abbr -a txzx   'tar xJf'
abbr -a zip    'zip -r'
abbr -a unzip  'unzip -v'
abbr -a 7z     '7z a'
abbr -a 7zx    '7z x'

# ═══════════════════════════════════════════════════════════════════════════════
# 🔐 SECURITY
# ═══════════════════════════════════════════════════════════════════════════════

abbr -a genpass  "openssl rand -base64 32 | tr -d '/+' | cut -c1-24"
abbr -a sha256   'sha256sum'
abbr -a md5      'md5sum'
abbr -a ssha     'ssh-add'
abbr -a sshl     'ssh-add -l'
abbr -a keygen   'ssh-keygen -t ed25519 -C'

# ═══════════════════════════════════════════════════════════════════════════════
# 🧹 CLEANUP
# ═══════════════════════════════════════════════════════════════════════════════

abbr -a clean     'ash clean'
abbr -a paccl     'sudo pacman -Sc --noconfirm'
abbr -a paclean   'sudo pacman -Qdtq | sudo pacman -Rns - 2>/dev/null; sudo pacman -Sc --noconfirm'
abbr -a journalcl 'sudo journalctl --vacuum-time=7d'

# ═══════════════════════════════════════════════════════════════════════════════
# 🎬 MEDIA
# ═══════════════════════════════════════════════════════════════════════════════

abbr -a mpv      'mpv --no-terminal'
abbr -a ytdl     'yt-dlp'
abbr -a ytaudio  'yt-dlp -x --audio-format mp3'
abbr -a ytvideo  'yt-dlp -f "bestvideo+bestaudio"'
abbr -a ffmpeg   'ffmpeg -hide_banner'
abbr -a fprobe   'ffprobe -hide_banner'

# ═══════════════════════════════════════════════════════════════════════════════
# 💡 MISC
# ═══════════════════════════════════════════════════════════════════════════════

abbr -a q    'exit'
abbr -a quit 'exit'
abbr -a bye  'exit'
abbr -a cls  'clear'
abbr -a clr  'clear'
abbr -a h    'history'
abbr -a tf   'tail -f'
abbr -a now  'date "+%Y-%m-%d %H:%M:%S"'
abbr -a epoch 'date +%s'
abbr -a week  'date +%V'
abbr -a c    'wl-copy'
abbr -a paste 'wl-paste'
abbr -a copy  'wl-copy'
abbr -a open  'xdg-open'
abbr -a o     'xdg-open'
abbr -a todo  'nvim ~/todo.md'
abbr -a note  'nvim ~/notes/'
abbr -a calc  'python3 -c "import math; from math import *"'
abbr -a weather 'curl -s "wttr.in?format=3"'
abbr -a wttr  'curl -s "wttr.in"'
abbr -a moon  'curl -s "wttr.in/Moon"'
abbr -a timer 'sleep'
abbr -a rng   'shuf -i 1-100 -n 1'
abbr -a uuid  'cat /proc/sys/kernel/random/uuid'
abbr -a lorem 'echo "Lorem ipsum dolor sit amet, consectetur adipiscing elit."'