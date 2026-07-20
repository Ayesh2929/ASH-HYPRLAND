#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ███████╗██╗   ██╗███████╗     █████╗ ██████╗ ██████╗ ██████╗ ███████╗         ║
# ║  ██╔════╝╚██╗ ██╔╝██╔════╝    ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝         ║
# ║  ███████╗ ╚████╔╝ ███████╗    ███████║██████╔╝██████╔╝██████╔╝███████╗         ║
# ║  ╚════██║  ╚██╔╝  ╚════██║    ██╔══██║██╔══██╗██╔══██╗██╔══██╗╚════██║         ║
# ║  ███████║   ██║   ███████║    ██║  ██║██████╔╝██████╔╝██║  ██║███████║         ║
# ║  ╚══════╝   ╚═╝   ╚══════╝    ╚═╝  ╚═╝╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝         ║
# ║                                                                                  ║
# ║   ⚙️  SYSTEM ABBREVIATIONS — ASH Dotfiles v5.0 OMEGA                            ║
# ║   Shell • Navigation • Packages • Systemd • Process • ASH CLI                   ║
# ║                                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

status is-interactive || exit 0
set -q __ash_abbr_system_initialized && exit 0
set -g __ash_abbr_system_initialized 1


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🐚 SHELL — Session management
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a q      "exit"
abbr -a :q     "exit"
abbr -a :wq    "exit"
abbr -a :qa    "exit"
abbr -a cl     "clear"
abbr -a clc    "clear && printf '\033[3J'"         # Full clear (scroll buffer too)
abbr -a reload "exec fish"
abbr -a re     "exec fish"
abbr -a resrc  "source $FISH_CONFIG_DIR/config.fish"
abbr -a fishrc "nvim $FISH_CONFIG_DIR/config.fish"
abbr -a fishedit "nvim $FISH_CONFIG_DIR/config.fish && exec fish"

# ── Shell info ────────────────────────────────────────────────────────────────
abbr -a path   "echo $PATH | string split ':' | nl"
abbr -a fpath  "echo $fish_function_path | string split ':' | nl"
abbr -a abbrs  "abbr --show"                       # List all abbreviations
abbr -a funcs  "functions"                         # List all functions
abbr -a envs   "env | sort | bat --language ini --style plain 2>/dev/null || env | sort"
abbr -a exports "set --export | sort"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧭 NAVIGATION — Directories
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a ".."   "cd .."
abbr -a "..."  "cd ../.."
abbr -a "...." "cd ../../.."
abbr -a "....." "cd ../../../.."
abbr -a "~"    "cd $HOME"
abbr -a "-"    "cd -"

# ── Common destinations ───────────────────────────────────────────────────────
abbr -a cdh   "cd $HOME"
abbr -a cdc   "cd $XDG_CONFIG_HOME"
abbr -a cdl   "cd $HOME/.local"
abbr -a cddl  "cd $XDG_DOWNLOAD_DIR"
abbr -a cdt   "cd /tmp"
abbr -a cdr   "cd /"
abbr -a cddev "cd $HOME/dev 2>/dev/null || cd $HOME/projects 2>/dev/null || cd $HOME"
abbr -a cdgit "cd (git rev-parse --show-toplevel 2>/dev/null || echo .)"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ✏️  EDITORS — Launch shortcuts
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a v     "nvim"
abbr -a vi    "nvim"
abbr -a vim   "nvim"
abbr -a nv    "nvim"
abbr -a sv    "sudoedit"
abbr -a svi   "sudo nvim"

# ── Quick config edits ────────────────────────────────────────────────────────
abbr -a vfish   "nvim $FISH_CONFIG_DIR/config.fish"
abbr -a vhypr   "nvim $XDG_CONFIG_HOME/hypr/hyprland.conf"
abbr -a vnvim   "nvim $XDG_CONFIG_HOME/nvim/init.lua"
abbr -a vway    "nvim $XDG_CONFIG_HOME/waybar/config.jsonc"
abbr -a vrofi   "nvim $XDG_CONFIG_HOME/rofi/config.rasi"
abbr -a vkitty  "nvim $XDG_CONFIG_HOME/kitty/kitty.conf"
abbr -a vstar   "nvim $XDG_CONFIG_HOME/starship/starship.toml"
abbr -a vdunst  "nvim $XDG_CONFIG_HOME/dunst/dunstrc"
abbr -a vssh    "nvim $HOME/.ssh/config"
abbr -a vgit    "nvim $XDG_CONFIG_HOME/git/.gitconfig"
abbr -a vhosts  "sudo nvim /etc/hosts"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔐 SUDO & PRIVILEGES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a s     "sudo"
abbr -a se    "sudoedit"
abbr -a please "sudo !!"
abbr -a fuck  "sudo !!"
abbr -a pls   "sudo !!"
abbr -a root  "sudo --shell fish"
abbr -a scat  "sudo bat 2>/dev/null || sudo cat"
abbr -a sls   "sudo eza --icons 2>/dev/null || sudo ls --color"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📦 PACKAGE MANAGEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Arch Linux (paru > yay > pacman) ─────────────────────────────────────────
if command -sq paru
    abbr -a pac    "paru"
    abbr -a pacs   "paru --sync"
    abbr -a pacr   "paru --remove --nosave --recursive"
    abbr -a pacu   "paru --sync --sysupgrade"
    abbr -a pacua  "paru --sync --sysupgrade --aur"
    abbr -a paci   "paru --query --info"
    abbr -a pacl   "paru --query --explicit"
    abbr -a pacd   "paru --query --deps --unrequired"
    abbr -a pacc   "paru --sync --clean"
    abbr -a pacss  "paru --sync --search"
    abbr -a pacf   "paru --query --owns"
    abbr -a pacfl  "paru --query --list"
    abbr -a paco   "paru --query --deps --unrequired"  # Orphans
    abbr -a paclog "bat /var/log/pacman.log"
    abbr -a pacchk "paru --query --check"

else if command -sq yay
    abbr -a pac    "yay"
    abbr -a pacs   "yay -S"
    abbr -a pacr   "yay -Rns"
    abbr -a pacu   "yay -Syu"
    abbr -a paci   "yay -Qi"
    abbr -a pacl   "yay -Qe"
    abbr -a pacd   "yay -Qdt"
    abbr -a pacc   "yay -Sc"

else if command -sq pacman
    abbr -a pac    "sudo pacman"
    abbr -a pacs   "sudo pacman -S"
    abbr -a pacr   "sudo pacman -Rns"
    abbr -a pacu   "sudo pacman -Syu"
    abbr -a paci   "sudo pacman -Qi"
    abbr -a pacl   "sudo pacman -Qe"
    abbr -a pacd   "sudo pacman -Qdt"
    abbr -a pacc   "sudo pacman -Sc"
    abbr -a paclog "bat /var/log/pacman.log"
end

# ── Fedora / RHEL (dnf) ───────────────────────────────────────────────────────
if command -sq dnf
    abbr -a dnf    "sudo dnf"
    abbr -a dnfi   "sudo dnf install"
    abbr -a dnfr   "sudo dnf remove"
    abbr -a dnfu   "sudo dnf upgrade"
    abbr -a dnfs   "dnf search"
    abbr -a dnfl   "dnf list installed"
    abbr -a dnfi   "dnf info"
    abbr -a dnfc   "sudo dnf autoremove && sudo dnf clean all"
end

# ── Flatpak (universal) ───────────────────────────────────────────────────────
if command -sq flatpak
    abbr -a fps    "flatpak search"
    abbr -a fpi    "flatpak install"
    abbr -a fpu    "flatpak update"
    abbr -a fpr    "flatpak uninstall --delete-data"
    abbr -a fpl    "flatpak list --app"
    abbr -a fprun  "flatpak run"
    abbr -a fprepo "flatpak remote-list"
    abbr -a fprep  "flatpak repair"
end

# ── Nix (NixOS / nix-env) ─────────────────────────────────────────────────────
if command -sq nix
    abbr -a nxi    "nix-env --install --attr"
    abbr -a nxr    "nix-env --uninstall"
    abbr -a nxu    "nix-channel --update && nix-env --upgrade"
    abbr -a nxs    "nix-env --query --available"
    abbr -a nxl    "nix-env --query --installed"
    abbr -a nxgc   "nix-collect-garbage --delete-old"
    abbr -a nxshell "nix-shell"
    abbr -a nxrun  "nix run"
    abbr -a nxdev  "nix develop"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ⚙️  SYSTEMD — Service management
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq systemctl
    # ── System services ───────────────────────────────────────────────────────
    abbr -a sc      "sudo systemctl"
    abbr -a scstart "sudo systemctl start"
    abbr -a scstop  "sudo systemctl stop"
    abbr -a screst  "sudo systemctl restart"
    abbr -a scstat  "sudo systemctl status"
    abbr -a scen    "sudo systemctl enable --now"
    abbr -a scdi    "sudo systemctl disable --now"
    abbr -a screl   "sudo systemctl reload"
    abbr -a scdr    "sudo systemctl daemon-reload"
    abbr -a scls    "sudo systemctl list-units --type=service --state=running"
    abbr -a sclsa   "sudo systemctl list-units --type=service --all"
    abbr -a scfail  "sudo systemctl list-units --state=failed"
    abbr -a scisc   "sudo systemctl is-active"
    abbr -a scisen  "sudo systemctl is-enabled"
    abbr -a scmask  "sudo systemctl mask"
    abbr -a scunmask "sudo systemctl unmask"
    abbr -a sccat   "sudo systemctl cat"
    abbr -a scedit  "sudo systemctl edit"

    # ── User services ─────────────────────────────────────────────────────────
    abbr -a scu     "systemctl --user"
    abbr -a scustart "systemctl --user start"
    abbr -a scustop "systemctl --user stop"
    abbr -a scurest "systemctl --user restart"
    abbr -a scustat "systemctl --user status"
    abbr -a scuen   "systemctl --user enable --now"
    abbr -a scudi   "systemctl --user disable --now"
    abbr -a scudr   "systemctl --user daemon-reload"
    abbr -a sculs   "systemctl --user list-units --type=service --state=running"
    abbr -a scufail "systemctl --user list-units --state=failed"
end

# ── journalctl ────────────────────────────────────────────────────────────────
if command -sq journalctl
    abbr -a jc      "journalctl"
    abbr -a jcf     "journalctl --follow"
    abbr -a jce     "journalctl --priority=err"
    abbr -a jcw     "journalctl --priority=warning"
    abbr -a jcb     "journalctl --boot"
    abbr -a jcbl    "journalctl --list-boots"
    abbr -a jck     "journalctl --dmesg"
    abbr -a jcu     "journalctl --user"
    abbr -a jcuf    "journalctl --user --follow"
    abbr -a jcuu    "journalctl --user --unit"
    abbr -a jcsize  "journalctl --disk-usage"
    abbr -a jcvac   "sudo journalctl --vacuum-time=7d"  # Clean old logs
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ⚡ PROCESS — Management & monitoring
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a psg    "ps aux | grep --ignore-case"
abbr -a psgrep "pgrep --list-name --ignore-case"
abbr -a kk     "pkill --ignore-case"
abbr -a k9     "kill -9"
abbr -a killall "killall --verbose --ignore-case"

# ── Resource usage ────────────────────────────────────────────────────────────
abbr -a memuse "ps aux --sort=-%mem | head -20"
abbr -a cpuuse "ps aux --sort=-%cpu | head -20"
abbr -a diskuse "du --human-readable --summarize --total * | sort --human-numeric-sort --reverse | head -20"
abbr -a openf  "lsof -p"                           # Open files by PID
abbr -a iowait "iostat -x 1 5"                     # IO wait stats


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🖥️  HYPRLAND & WAYLAND
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq hyprctl
    abbr -a hpr    "hyprctl"
    abbr -a hprrel "hyprctl reload"
    abbr -a hprmon "hyprctl monitors"
    abbr -a hprwin "hyprctl clients --json | jq '.[] | {title,class,workspace}'"
    abbr -a hprws  "hyprctl workspaces --json | jq '.[] | {id,name,windows}'"
    abbr -a hpract "hyprctl activewindow"
    abbr -a hprkey "hyprctl binds --json | jq '.[] | {key,dispatcher,arg}'"
    abbr -a hprver "hyprctl version"
    abbr -a hprlog "journalctl --user --unit=hyprland --follow --output=cat"
    abbr -a hprkw  "hyprctl keyword"
    abbr -a hprdis "hyprctl dispatch"
end

# ── Waybar ────────────────────────────────────────────────────────────────────
if command -sq waybar
    abbr -a wbrel  "pkill -SIGUSR2 waybar"
    abbr -a wbkill "pkill waybar"
    abbr -a wbstart "waybar &"
    abbr -a wblog  "journalctl --user --unit=waybar --follow"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ⚡ ASH CLI — Dotfiles management
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq ash
    # ── Theme ─────────────────────────────────────────────────────────────────
    abbr -a at     "ash theme"
    abbr -a ata    "ash theme apply"
    abbr -a atp    "ash theme pick"
    abbr -a atr    "ash theme random"
    abbr -a atl    "ash theme list"
    abbr -a ats    "ash theme search"
    abbr -a atc    "ash theme create"
    abbr -a ate    "ash theme edit"
    abbr -a atv    "ash theme preview"
    abbr -a atfav  "ash theme favorite"
    abbr -a atsched "ash theme schedule"
    abbr -a atai   "ash theme ai-generate"
    abbr -a atwal  "ash theme wallpaper"
    abbr -a atexp  "ash theme export"
    abbr -a atimp  "ash theme import"

    # ── Mode ──────────────────────────────────────────────────────────────────
    abbr -a am     "ash mode"
    abbr -a amg    "ash mode game"
    abbr -a amf    "ash mode focus"
    abbr -a amw    "ash mode work"
    abbr -a amc    "ash mode cinema"
    abbr -a amp    "ash mode privacy"
    abbr -a amst   "ash mode stream"
    abbr -a amb    "ash mode battery"
    abbr -a amd    "ash mode default"
    abbr -a amst   "ash mode status"
    abbr -a amls   "ash mode list"

    # ── Plugin ────────────────────────────────────────────────────────────────
    abbr -a ap     "ash plugin"
    abbr -a api    "ash plugin install"
    abbr -a apr    "ash plugin remove"
    abbr -a apu    "ash plugin update"
    abbr -a apua   "ash plugin update-all"
    abbr -a apl    "ash plugin list"
    abbr -a aps    "ash plugin search"
    abbr -a apb    "ash plugin browse"
    abbr -a apen   "ash plugin enable"
    abbr -a apdi   "ash plugin disable"
    abbr -a apinfo "ash plugin info"
    abbr -a apval  "ash plugin validate"
    abbr -a appub  "ash plugin publish"

    # ── Snapshot ──────────────────────────────────────────────────────────────
    abbr -a as     "ash snapshot"
    abbr -a asc    "ash snapshot create"
    abbr -a asr    "ash snapshot restore"
    abbr -a asl    "ash snapshot list"
    abbr -a asd    "ash snapshot diff"
    abbr -a asde   "ash snapshot delete"
    abbr -a ase    "ash snapshot export"
    abbr -a asi    "ash snapshot import"
    abbr -a asp    "ash snapshot pin"
    abbr -a ast    "ash snapshot tag"
    abbr -a asv    "ash snapshot verify"

    # ── Config ────────────────────────────────────────────────────────────────
    abbr -a ac     "ash config"
    abbr -a acg    "ash config get"
    abbr -a acset  "ash config set"
    abbr -a acl    "ash config list"
    abbr -a ace    "ash config edit"
    abbr -a acval  "ash config validate"
    abbr -a acexp  "ash config export"
    abbr -a acimp  "ash config import"

    # ── Doctor ────────────────────────────────────────────────────────────────
    abbr -a ad     "ash doctor"
    abbr -a adq    "ash doctor quick"
    abbr -a adf    "ash doctor full"
    abbr -a adfix  "ash doctor fix"
    abbr -a adrep  "ash doctor report"

    # ── Update ────────────────────────────────────────────────────────────────
    abbr -a au     "ash update all"
    abbr -a aus    "ash update system"
    abbr -a aud    "ash update dotfiles"
    abbr -a aup    "ash update plugins"
    abbr -a auc    "ash update check"

    # ── Hardware ──────────────────────────────────────────────────────────────
    abbr -a ahw    "ash hw full-report"
    abbr -a ahwcpu "ash hw cpu"
    abbr -a ahwgpu "ash hw gpu"
    abbr -a ahwmem "ash hw memory"
    abbr -a ahwdsk "ash hw disk"
    abbr -a ahwmon "ash hw monitor"
    abbr -a ahwbat "ash hw battery"
    abbr -a ahwnet "ash hw network"

    # ── Screenshot ────────────────────────────────────────────────────────────
    abbr -a ashot  "ash shot area"
    abbr -a ashotf "ash shot full"
    abbr -a ashotw "ash shot window"
    abbr -a ashotr "ash shot record"
    abbr -a ashotg "ash shot gif"
    abbr -a ashoto "ash shot ocr"

    # ── Wallpaper ─────────────────────────────────────────────────────────────
    abbr -a awp    "ash wallpaper"
    abbr -a awps   "ash wallpaper set"
    abbr -a awpr   "ash wallpaper random"
    abbr -a awpp   "ash wallpaper pick"
    abbr -a awpd   "ash wallpaper download"
    abbr -a awpg   "ash wallpaper generate"
    abbr -a awpai  "ash wallpaper generate-ai"
    abbr -a awpsl  "ash wallpaper slideshow"

    # ── AI ────────────────────────────────────────────────────────────────────
    abbr -a aai    "ash ai chat"
    abbr -a aait   "ash ai suggest-theme"
    abbr -a aaio   "ash ai optimize-config"
    abbr -a aaif   "ash ai fix-issue"
    abbr -a aaie   "ash ai explain"

    # ── Misc ──────────────────────────────────────────────────────────────────
    abbr -a abar   "ash bar reload"
    abbr -a abarl  "ash bar layout"
    abbr -a anet   "ash net status"
    abbr -a anets  "ash net speed"
    abbr -a alock  "ash power lock"
    abbr -a aclout "ash power logout"
    abbr -a asleep "ash power suspend"
    abbr -a aoff   "ash power shutdown"
    abbr -a areboot "ash power reboot"
    abbr -a aprof  "ash profile switch"
    abbr -a aprofl "ash profile list"
    abbr -a aback  "ash backup create"
    abbr -a abackl "ash backup list"
    abbr -a abackr "ash backup restore"
    abbr -a aban   "ash analytics dashboard"
    abbr -a async  "ash cloud sync-up"
    abbr -a async! "ash cloud sync-down"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🕐 TIME & DATE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a now    "date +'%Y-%m-%d %H:%M:%S'"
abbr -a today  "date +'%Y-%m-%d'"
abbr -a week   "date +'Week %V of %Y'"
abbr -a epoch  "date +%s"
abbr -a utc    "date -u +'%Y-%m-%dT%H:%M:%SZ'"
abbr -a cal    "cal -3"
abbr -a calv   "cal --year"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🌐 NETWORK — Quick shortcuts
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a ports  "ss --tcp --udp --listening --numeric --processes"
abbr -a pubip  "curl --silent --max-time 5 ifconfig.me && echo"
abbr -a myip   "curl --silent ipinfo.io | jq '{ip,city,country,org}'"
abbr -a dns    "dog 2>/dev/null || dig +short"
abbr -a serve  "python3 -m http.server 8000"
abbr -a curl   "curl --silent --show-error --location"
abbr -a wget   "wget --quiet --show-progress --continue"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 MISC QUALITY OF LIFE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a mkdir  "mkdir --parents --verbose"
abbr -a cp     "cp --interactive --verbose --preserve=all"
abbr -a mv     "mv --interactive --verbose"
abbr -a rm     "rm --interactive=once --verbose"
abbr -a ln     "ln --interactive --verbose"
abbr -a df     "duf 2>/dev/null || df --human-readable"
abbr -a du     "dust 2>/dev/null || du --human-readable --summarize"
abbr -a free   "free --human --si --total"
abbr -a diff   "delta 2>/dev/null || diff --color=always --unified"
abbr -a top    "btop 2>/dev/null || htop 2>/dev/null || top"
abbr -a cat    "bat --style=plain --pager=never 2>/dev/null || cat"
abbr -a ping   "gping 2>/dev/null || ping --count=5"
abbr -a less   "bat 2>/dev/null || less"
abbr -a find   "fd 2>/dev/null || find"
abbr -a grep   "rg --smart-case 2>/dev/null || grep --color=always"
abbr -a size   "du --human-readable --summarize"
abbr -a count  "wc --lines"
abbr -a which  "type --all"
abbr -a wtf    "tldr 2>/dev/null || man"