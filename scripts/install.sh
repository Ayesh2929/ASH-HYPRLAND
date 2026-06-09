
set -euo pipefail
IFS=$'\n\t'
##################################################
# CONSTANTS #
##################################################
readonly ASH_VERSION="3.0"
readonly ASH_REPO="https://github.com/yourusername/ash-dots"
readonly ASH_MIN_KERNEL="6.1"
readonly ASH_REQUIRED_ARCH="x86_64"
readonly DOTS="$HOME/.dotfiles"
readonly CFG="$HOME/.config"
readonly LOCAL="$HOME/.local"
readonly CACHE="$HOME/.cache/ash-dots"
readonly STATE="$HOME/.local/state/ash-dots"
readonly LOG_DIR="$CACHE/logs"
readonly LOG="$LOG_DIR/install-$(date +%Y%m%d_%H%M%S).log"
readonly LOCK_FILE="/tmp/ash-install.lock"
readonly BACKUP_DIR="$HOME/.ash-backup-$(date +%Y%m%d_%H%M%S)"
##################################################
# COLORS #
##################################################
readonly R='\033[0;31m'
readonly G='\033[0;32m'
readonly Y='\033[1;33m'
readonly B='\033[0;34m'
readonly P='\033[0;35m'
readonly C='\033[0;36m'
readonly W='\033[1;37m'
readonly N='\033[0m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly IT='\033[3m'
readonly BG_P='\033[45m'
##################################################
# ERROR HANDLER #
##################################################
trap_error() {
local EXIT_CODE=$?
local LINE_NUMBER=$1
echo ""
echo -e "${R}${BOLD}[FATAL] Error at line $LINE_NUMBER (exit: $EXIT_CODE)${N}"
echo -e "${R}Check log: $LOG${N}"
echo ""
# Cleanup lock
rm -f "$LOCK_FILE"
# Show last 10 log lines
if [ -f "$LOG" ]; then
echo -e "${DIM}Last log entries:${N}"
tail -10 "$LOG" | while IFS= read -r line; do
echo -e " ${DIM}$line${N}"
done
fi
exit "$EXIT_CODE"
}
trap 'trap_error $LINENO' ERR
trap 'rm -f "$LOCK_FILE"; echo -e "\n${Y}Installation interrupted${N}"; exit 1' INT TERM
##################################################
# LOGGING #
##################################################
_ts() { date '+%Y-%m-%d %H:%M:%S'; }
_log() { echo "[$(_ts)] [$1] ${*:2}" &gt;&gt; "$LOG" 2&gt;/dev/null || true; }
log() {
echo -e "${G} ✓${N} ${BOLD}$*${N}"
_log "OK" "$*"
}
warn() {
echo -e "${Y} ■${N} ${IT}$*${N}"
_log "WN" "$*"
}
err() {
echo -e "${R} ✗${N} ${BOLD}$*${N}"
_log "ER" "$*"
exit 1
}
info() {
echo -e "${C} ■${N} $*"
_log "IN" "$*"
}
step() {
echo -e " ${P}›${N} ${DIM}$*${N}"
_log "ST" "$*"
}
section() {
echo ""
echo -e "${BG_P}${W}${BOLD} ■■ $* ■■ ${N}"
echo ""
_log "==" "SECTION: $*"
}
ask() {
echo -ne "${Y} ?${N} ${BOLD}$*${N} ${DIM}[y/N]${N}: "
read -r REPLY
[[ "$REPLY" =~ ^[Yy]$ ]]
}
##################################################
# LOCK MECHANISM #
##################################################
acquire_lock() {
if [ -f "$LOCK_FILE" ]; then
local OLD_PID
OLD_PID=$(cat "$LOCK_FILE" 2&gt;/dev/null || echo "")
if kill -0 "${OLD_PID}" 2&gt;/dev/null; then
err "Another install is running (PID: $OLD_PID)"
fi
rm -f "$LOCK_FILE"
fi
echo $$ &gt; "$LOCK_FILE"
}
##################################################
# BANNER #
##################################################
show_banner() {
clear
echo -e "${P}${BOLD}"
cat &lt;&lt; 'BANNER'
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
■ ■
■ ■■■■■■ ■■■■■■■■■■■ ■■■ ■■■■■■■ ■■■■■■■ ■■■■■■■■■■■■■■■■■ ■
■ ■■■■■■■■■■■■■■■■■■■ ■■■ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ ■
■ ■■■■■■■■■■■■■■■■■■■■■■■■ ■■■ ■■■■■■ ■■■ ■■■ ■■■■■■■■ ■
■ ■■■■■■■■■■■■■■■■■■■■■■■■ ■■■ ■■■■■■ ■■■ ■■■ ■■■■■■■■ ■
■ ■■■ ■■■■■■■■■■■■■■ ■■■ ■■■■■■■■■■■■■■■■■ ■■■ ■■■■■■■■ ■
■ ■■■ ■■■■■■■■■■■■■■ ■■■ ■■■■■■■ ■■■■■■■ ■■■ ■■■■■■■■ ■
■ ■
■ ■ PRODUCTION INSTALLER v3.0 ■ ■
■ Zero-bug · Validated · Complete ■
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
BANNER
echo -e "${N}"
echo -e " ${BOLD}System Information:${N}"
echo -e " ${C}OS:${N} $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo 'Unknown')"
echo -e " ${C}Kernel:${N} $(uname -r)"
echo -e " ${C}User:${N} $USER"
echo -e " ${C}Home:${N} $HOME"
echo -e " ${C}Shell:${N} $SHELL"
echo -e " ${C}Log:${N} $LOG"
echo ""
}
##################################################
# PRE-FLIGHT SYSTEM VALIDATION #
##################################################
validate_system() {
section "Pre-flight System Validation"
local ERRORS=0
# Check architecture
local ARCH
ARCH=$(uname -m)
if [ "$ARCH" = "$ASH_REQUIRED_ARCH" ]; then
log "Architecture: $ARCH"
else
warn "Architecture $ARCH (expected $ASH_REQUIRED_ARCH) — may have issues"
ERRORS=$((ERRORS + 1))
fi
# Check kernel version
local KERNEL_VER
KERNEL_VER=$(uname -r | grep -oP '^\d+\.\d+')
local KERNEL_OK
KERNEL_OK=$(awk \
"BEGIN {print (\"$KERNEL_VER\" &gt;= \"$ASH_MIN_KERNEL\") ? 1 : 0}")
if [ "$KERNEL_OK" = "1" ]; then
log "Kernel: $(uname -r)"
else
warn "Kernel $(uname -r) may be too old (min: $ASH_MIN_KERNEL)"
ERRORS=$((ERRORS + 1))
fi
# Check Arch Linux
if [ -f /etc/arch-release ]; then
log "Distribution: Arch Linux"
elif [ -f /etc/os-release ]; then
local ID
ID=$(grep '^ID' /etc/os-release | cut -d= -f2 | tr -d '"')
local ID_LIKE
ID_LIKE=$(grep '^ID_LIKE' /etc/os-release 2&gt;/dev/null | \
cut -d= -f2 | tr -d '"' || echo "")
if echo "$ID $ID_LIKE" | grep -qi "arch"; then
log "Distribution: Arch-based ($ID)"
else
warn "Distribution: $ID (not Arch-based — may have issues)"
ERRORS=$((ERRORS + 1))
fi
fi
# Check running as user (not root)
if [ "$EUID" -eq 0 ]; then
err "Do NOT run installer as root! Run as your regular user."
fi
log "Running as user: $USER"
# Check internet connectivity
if ping -c 1 -W 3 archlinux.org &amp;&gt;/dev/null 2&gt;&amp;1; then
log "Internet: Connected"
else
warn "Internet: No connection — package installation may fail"
ERRORS=$((ERRORS + 1))
fi
# Check disk space (need at least 5GB free)
local FREE_GB
FREE_GB=$(df -BG "$HOME" | tail -1 | awk '{print $4}' | tr -d 'G')
if [ "${FREE_GB:-0}" -ge 5 ]; then
log "Disk space: ${FREE_GB}GB free"
else
warn "Low disk space: ${FREE_GB}GB (recommend 5GB+)"
ERRORS=$((ERRORS + 1))
if [ "$ERRORS" -gt 0 ]; then
warn "$ERRORS validation warning(s) — continuing anyway"
sleep 2
else
log "All validation checks passed!"
fi
# Check sudo access
if sudo -n true 2&gt;/dev/null; then
log "Sudo: Available (cached)"
else
info "Sudo will prompt for password when needed"
fi
# Check git
if command -v git &amp;&gt;/dev/null; then
log "Git: $(git --version | head -1)"
else
err "Git not installed: sudo pacman -S git"
fi
##################################################
# DETECT PACKAGE MANAGER #
##################################################
detect_pm() {
section "Detecting Package Manager"
if command -v paru &amp;&gt;/dev/null; then
PM="paru"
PM_FLAGS="-S --needed --noconfirm --noprogressbar"
log "Using: paru (recommended)"
elif command -v yay &amp;&gt;/dev/null; then
PM="yay"
PM_FLAGS="-S --needed --noconfirm"
log "Using: yay"
elif command -v pacman &amp;&gt;/dev/null; then
PM="sudo pacman"
PM_FLAGS="-S --needed --noconfirm"
log "Using: pacman (AUR packages will be skipped)"
warn "Consider installing paru for full AUR support"
else
	err "No package manager found (pacman/paru/yay)"
fi
}
##################################################
# INSTALL AUR HELPER (if needed) #
##################################################
install_aur_helper() {
if command -v paru &amp;&gt;/dev/null || command -v yay &amp;&gt;/dev/null; then
return 0
fi
section "Installing AUR Helper (paru)"
if ! ask "Install paru (AUR helper)?"; then
warn "Skipping AUR helper — AUR packages won't install"
return 0
fi
# Install base-devel if missing
sudo pacman -S --needed --noconfirm base-devel git 2&gt;&gt;"$LOG"
# Clone and build paru
local PARU_TMP="/tmp/ash-paru-$$"
git clone --depth 1 https://aur.archlinux.org/paru.git \
"$PARU_TMP" 2&gt;&gt;"$LOG"
cd "$PARU_TMP"
makepkg -si --noconfirm 2&gt;&gt;"$LOG"
cd "$HOME"
rm -rf "$PARU_TMP"
if command -v paru &amp;&gt;/dev/null; then
log "paru installed successfully"
PM="paru"
PM_FLAGS="-S --needed --noconfirm --noprogressbar"
else
	warn "paru install failed — using pacman"
fi
}
##################################################
# PACKAGE DEFINITIONS #
##################################################
# Core packages (required for basic functionality)
declare -a PKGS_CORE=(
# System base
"base-devel"
"git"
"curl"
"wget"
"jq"
# Hyprland ecosystem
"hyprland"
"hyprlock"
"hypridle"
"hyprpicker"
"xdg-desktop-portal-hyprland"
"xdg-desktop-portal-gtk"
"xdg-utils"
"xdg-user-dirs"
# Display
"wayland"
"wayland-protocols"
"xorg-xwayland"
"libxkbcommon"
"libxkbcommon-x11"
# Wallpaper
"swww"
# Status bar
"waybar"
# Launcher
"rofi-wayland"
# Notifications
"dunst"
"libnotify"
# Screenshot
"grim"
"slurp"
"swappy"
# Clipboard
"wl-clipboard"
"cliphist"
# Audio
"pipewire"
"pipewire-pulse"
"pipewire-alsa"
"pipewire-jack"
"wireplumber"
"pavucontrol"
# Network
"networkmanager"
"network-manager-applet"
"iwd"
# Bluetooth
"bluez"
"bluez-utils"
"blueman"
# Authentication
"polkit-gnome"
"gnome-keyring"
"libsecret"
# File management
"thunar"
"thunar-archive-plugin"
"thunar-volman"
"gvfs"
"gvfs-mtp"
"gvfs-smb"
"gvfs-gphoto2"
"udiskie"
"udisks2"
# Image handling
"imagemagick"
"imv"
# Media
"mpv"
"playerctl"
# Fonts (critical)
"ttf-jetbrains-mono-nerd"
"ttf-nerd-fonts-symbols"
"ttf-nerd-fonts-symbols-mono"
"noto-fonts"
"noto-fonts-emoji"
"noto-fonts-cjk"
"ttf-liberation"
# Cursor
"bibata-cursor-theme"
# Icons
"papirus-icon-theme"
# GTK theme
"adw-gtk3"
# Qt theming
"qt5ct"
"qt6ct"
"kvantum"
"qt5-wayland"
"qt6-wayland"
# Terminal
"kitty"
# Shell
"fish"
"starship"
# Editor
"neovim"
# System tools
"brightnessctl"
"btop"
"fastfetch"
"fd"
"ripgrep"
"fzf"
"bat"
"eza"
"zoxide"
# Archive tools
"p7zip"
"unzip"
"zip"
"tar"
)
# Optional packages (user choice)
declare -a PKGS_OPTIONAL=(
"wf-recorder"
"obs-studio"
"swaync"
"eww"
"tesseract"
"tesseract-data-eng"
"wtype"
"wlr-randr"
"wdisplays"
"gammastep"
"zathura"
"zathura-pdf-mupdf"
"firefox"
"discord"
"telegram-desktop"
"spotify"
"gimp"
"inkscape"
"lazygit"
"git-delta"
"python-pip"
"nodejs"
"npm"
"rust"
"go"
"docker"
"docker-compose"
"nvtop"
"htop"
"neofetch"
"figlet"
"lolcat"
"cava"
"pipes.sh"
)
# GPU-specific packages
declare -a PKGS_AMD=(
"mesa"
"vulkan-radeon"
"libva-mesa-driver"
"mesa-vdpau"
"xf86-video-amdgpu"
"radeontop"
)
declare -a PKGS_NVIDIA=(
"nvidia"
"nvidia-utils"
"nvidia-settings"
"libva-nvidia-driver"
"egl-wayland"
"nvtop"
)
declare -a PKGS_INTEL=(
"mesa"
"vulkan-intel"
"intel-media-driver"
"libva-intel-driver"
)
##################################################
# DETECT GPU TYPE #
##################################################
detect_gpu() {
section "Detecting GPU"
GPU_TYPE="unknown"
local GPU_INFO
GPU_INFO=$(lspci 2&gt;/dev/null | grep -iE "VGA|3D|Display" || echo "")
if echo "$GPU_INFO" | grep -qi "nvidia"; then
GPU_TYPE="nvidia"
log "GPU: NVIDIA detected"
elif echo "$GPU_INFO" | grep -qi "amd\|radeon\|rx [0-9]"; then
GPU_TYPE="amd"
log "GPU: AMD detected"
elif echo "$GPU_INFO" | grep -qi "intel"; then
GPU_TYPE="intel"
log "GPU: Intel detected"
else
# Try /sys
if [ -d /sys/class/drm ]; then
local DRM_INFO
DRM_INFO=$(ls /sys/class/drm/ 2&gt;/dev/null | \
xargs -I{} cat /sys/class/drm/{}/device/vendor \
2&gt;/dev/null | head -1 || echo "")
case "$DRM_INFO" in
"0x10de") GPU_TYPE="nvidia"; log "GPU: NVIDIA (via DRM)" ;;
"0x1002") GPU_TYPE="amd"; log "GPU: AMD (via DRM)" ;;
"0x8086") GPU_TYPE="intel"; log "GPU: Intel (via DRM)" ;;
*) warn "GPU: Unknown (manual setup may be needed)" ;;
esac
fi
fi
}
##################################################
# INSTALL PACKAGES (ROBUST) #
##################################################
install_package() {
local PKG="$1"
local REQUIRED="${2:-optional}"
step "Installing: $PKG"
if $PM $PM_FLAGS "$PKG" &gt;&gt;"$LOG" 2&gt;&amp;1; then
_log "OK" "Installed: $PKG"
return 0
else
if [ "$REQUIRED" = "required" ]; then
warn "Failed to install required package: $PKG"
warn "Attempting alternative install..."
if sudo pacman -S --needed --noconfirm "$PKG" &gt;&gt;"$LOG" 2&gt;&amp;1; then
log "Installed via pacman: $PKG"
return 0
fi
return 1
else
_log "WN" "Optional package failed: $PKG"
return 0
fi
fi
}
install_packages() {
section "Installing Core Packages"
local TOTAL=${#PKGS_CORE[@]}
local COUNT=0
local FAILED=()
# Update package databases first
step "Updating package databases..."
sudo pacman -Sy &gt;&gt;"$LOG" 2&gt;&amp;1 || warn "Package sync failed"
for PKG in "${PKGS_CORE[@]}"; do
COUNT=$((COUNT + 1))
local PCT=$(( COUNT * 100 / TOTAL ))
printf "\r ${P}[%3d%%]${N} ${DIM}%-40s${N}" \
"$PCT" "$PKG"
if $PM $PM_FLAGS "$PKG" &gt;&gt;"$LOG" 2&gt;&amp;1; then
_log "OK" "Installed: $PKG"
else
_log "WN" "Failed: $PKG"
FAILED+=("$PKG")
fi
done
echo ""
echo ""
if [ "${#FAILED[@]}" -gt 0 ]; then
warn "Failed packages (${#FAILED[@]}):"
for PKG in "${FAILED[@]}"; do
step "$PKG"
done
fi
log "Core packages: $((TOTAL - ${#FAILED[@]}))/$TOTAL installed"
# GPU packages
section "Installing GPU Packages ($GPU_TYPE)"
case "$GPU_TYPE" in
amd)
for PKG in "${PKGS_AMD[@]}"; do
install_package "$PKG" "required"
done
;;
nvidia)
for PKG in "${PKGS_NVIDIA[@]}"; do
install_package "$PKG" "required"
done
# Configure NVIDIA for Wayland
setup_nvidia
;;
intel)
for PKG in "${PKGS_INTEL[@]}"; do
install_package "$PKG" "required"
done
;;
esac
# Optional packages
if ask "Install optional packages (OBS, EWW, AGS, etc.)?"; then
section "Installing Optional Packages"
for PKG in "${PKGS_OPTIONAL[@]}"; do
install_package "$PKG" "optional"
done
fi
}
##################################################
# NVIDIA WAYLAND SETUP #
##################################################
setup_nvidia() {
section "Configuring NVIDIA for Wayland"
step "Setting DRM modeset..."
local MODPROBE_FILE="/etc/modprobe.d/nvidia-wayland.conf"
if [ ! -f "$MODPROBE_FILE" ]; then
echo "options nvidia_drm modeset=1 fbdev=1" | \
sudo tee "$MODPROBE_FILE" &gt; /dev/null
log "NVIDIA DRM modeset enabled"
fi
step "Rebuilding initramfs..."
sudo mkinitcpio -P &gt;&gt;"$LOG" 2&gt;&amp;1 &amp;&amp; \
log "Initramfs rebuilt" || \
warn "Initramfs rebuild failed — rerun: sudo mkinitcpio -P"
step "Creating NVIDIA env overrides..."
mkdir -p "$CFG/hypr/UserOverrides"
cat &gt;&gt; "$CFG/hypr/UserOverrides/user.conf" &lt;&lt; 'NVIDIA_CONF'
# ■■ NVIDIA Wayland Configuration ■■■■■■■■■■■■■■■■■■■■■■■■■■■■
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = LIBVA_DRIVER_NAME,nvidia
env = WLR_DRM_NO_ATOMIC,1
env = NVD_BACKEND,direct
env = __NV_PRIME_RENDER_OFFLOAD,1
env = __VK_LAYER_NV_optimus,NVIDIA_only
NVIDIA_CONF
log "NVIDIA configuration applied"
}
##################################################
# CREATE DIRECTORY STRUCTURE #
##################################################
create_directories() {
section "Creating Directory Structure"
local DIRS=(
# Hyprland
"$CFG/hypr/core"
"$CFG/hypr/modules"
"$CFG/hypr/themes/presets"
"$CFG/hypr/themes/generated"
"$CFG/hypr/scripts/system"
"$CFG/hypr/scripts/media"
"$CFG/hypr/scripts/visual"
"$CFG/hypr/scripts/utils"
"$CFG/hypr/assets/shaders"
"$CFG/hypr/assets/icons/svg"
"$CFG/hypr/assets/icons/png"
"$CFG/hypr/assets/sounds"
"$CFG/hypr/assets/animations"
"$CFG/hypr/UserOverrides"
"$CFG/hypr/rules"
"$CFG/hypr/plugins"
# Waybar
"$CFG/waybar/configs"
"$CFG/waybar/styles/themes"
"$CFG/waybar/styles/modules"
"$CFG/waybar/scripts"
"$CFG/waybar/assets/icons"
"$CFG/waybar/modules"
# Rofi
"$CFG/rofi/launchers"
"$CFG/rofi/powermenu"
"$CFG/rofi/themes"
"$CFG/rofi/scripts"
"$CFG/rofi/assets/icons"
# AGS
"$CFG/ags/modules"
"$CFG/ags/services"
"$CFG/ags/styles"
"$CFG/ags/assets"
"$CFG/ags/scripts"
# EWW
"$CFG/eww/dashboard/widgets"
"$CFG/eww/dashboard/scripts"
"$CFG/eww/bar/widgets"
"$CFG/eww/bar/scripts"
"$CFG/eww/sidebar/widgets"
"$CFG/eww/scripts/system"
"$CFG/eww/scripts/media"
"$CFG/eww/assets/icons"
"$CFG/eww/assets/images"
"$CFG/eww/styles"
# Dunst / SwayNC
"$CFG/dunst/scripts"
"$CFG/dunst/icons"
"$CFG/dunst/themes"
"$CFG/swaync/styles"
"$CFG/swaync/scripts"
# Hyprlock
"$CFG/hyprlock/scripts"
"$CFG/hyprlock/assets"
"$CFG/hyprlock/themes"
# Hypridle
"$CFG/hypridle"
# Terminals
"$CFG/kitty/themes"
"$CFG/kitty/scripts"
"$CFG/kitty/kittens"
"$CFG/wezterm"
"$CFG/alacritty"
# Shell
"$CFG/fish/functions"
"$CFG/fish/completions"
"$CFG/fish/conf.d"
"$CFG/fish/themes"
"$CFG/fish/prompts"
# Editor
"$CFG/nvim/lua/core"
"$CFG/nvim/lua/plugins"
"$CFG/nvim/lua/themes"
"$CFG/nvim/lua/utils"
"$CFG/nvim/lua/lsp"
"$CFG/nvim/lua/ui"
"$CFG/nvim/snippets"
"$CFG/nvim/after/plugin"
# GTK / Qt
"$CFG/gtk-3.0"
"$CFG/gtk-4.0"
"$CFG/gtk-2.0"
"$CFG/qt5ct/colors"
"$CFG/qt6ct/colors"
"$CFG/Kvantum/AshTheme"
# Media
"$CFG/mpv/scripts"
"$CFG/mpv/shaders"
# System tools
"$CFG/btop/themes"
"$CFG/fastfetch/themes"
"$CFG/ripgrep"
"$CFG/python"
"$CFG/starship/themes"
# Systemd
"$CFG/systemd/user"
"$CFG/environment.d"
# Local
"$LOCAL/bin"
"$LOCAL/share/fonts/AshFonts"
"$LOCAL/share/icons/AshIcons"
"$LOCAL/share/themes/AshTheme"
"$LOCAL/share/applications"
# Cache
"$CACHE/colors"
"$CACHE/wallpaper"
"$CACHE/thumbnails"
"$CACHE/generated"
"$CACHE/backup"
"$CACHE/logs"
# State
"$STATE"
"$STATE/sessions"
# Wallpapers
"$HOME/Pictures/Wallpapers/dark"
"$HOME/Pictures/Wallpapers/light"
"$HOME/Pictures/Wallpapers/anime"
"$HOME/Pictures/Wallpapers/abstract"
"$HOME/Pictures/Wallpapers/cyberpunk"
"$HOME/Pictures/Wallpapers/nature"
"$HOME/Pictures/Screenshots"
"$HOME/Pictures/Recordings"
"$HOME/Documents/Notes"
"$HOME/Projects"
)
local TOTAL=${#DIRS[@]}
local COUNT=0
for DIR in "${DIRS[@]}"; do
mkdir -p "$DIR" 2&gt;&gt;"$LOG" || true
COUNT=$((COUNT + 1))
local PCT=$(( COUNT * 100 / TOTAL ))
printf "\r ${P}[%3d%%]${N} ${DIM}%-55s${N}" \
"$PCT" "${DIR/$HOME/\~}"
done
echo ""
log "Created $TOTAL directories"
# Initialize user dirs
xdg-user-dirs-update 2&gt;&gt;"$LOG" || true
}
##################################################
# BACKUP EXISTING CONFIGS #
##################################################
backup_existing() {
section "Backing Up Existing Configurations"
local CONFIGS=(
"hypr" "waybar" "rofi" "kitty" "dunst"
"hyprlock" "hypridle" "fish" "nvim" "btop"
"gtk-3.0" "gtk-4.0" "swaync" "wezterm"
"alacritty" "mpv" "fastfetch"
)
local HAS_BACKUP=false
for CFG_NAME in "${CONFIGS[@]}"; do
local TARGET="$CFG/$CFG_NAME"
if [ -e "$TARGET" ] &amp;&amp; [ ! -L "$TARGET" ]; then
mkdir -p "$BACKUP_DIR"
cp -r "$TARGET" "$BACKUP_DIR/" 2&gt;&gt;"$LOG"
step "Backed up: $CFG_NAME"
HAS_BACKUP=true
fi
done
# Backup shell configs
for F in ".bashrc" ".bash_profile" ".profile" ".zshrc"; do
[ -f "$HOME/$F" ] &amp;&amp; {
mkdir -p "$BACKUP_DIR"
cp "$HOME/$F" "$BACKUP_DIR/" 2&gt;&gt;"$LOG"
step "Backed up: $F"
HAS_BACKUP=true
}
done
if [ "$HAS_BACKUP" = "true" ]; then
log "Backup saved: $BACKUP_DIR"
else
log "No existing configs to backup"
##################################################
# SYMLINK ALL CONFIGURATIONS #
##################################################
symlink_configs() {
section "Symlinking Configurations"
local SYMLINKS=(
"hypr:$CFG/hypr"
"waybar:$CFG/waybar"
"rofi:$CFG/rofi"
"kitty:$CFG/kitty"
"dunst:$CFG/dunst"
"hyprlock:$CFG/hyprlock"
"hypridle:$CFG/hypridle"
"swaync:$CFG/swaync"
"ags:$CFG/ags"
"eww:$CFG/eww"
"fish:$CFG/fish"
"nvim:$CFG/nvim"
"btop:$CFG/btop"
"fastfetch:$CFG/fastfetch"
"mpv:$CFG/mpv"
"wezterm:$CFG/wezterm"
"alacritty:$CFG/alacritty"
"starship.toml:$CFG/starship.toml"
)
for PAIR in "${SYMLINKS[@]}"; do
local SRC_NAME="${PAIR%%:*}"
local DST="${PAIR##*:}"
local SRC="$DOTS/config/$SRC_NAME"
# Skip if source doesn't exist in dotfiles repo
[ -e "$SRC" ] || continue
# Remove existing (file, dir, or broken link)
if [ -L "$DST" ]; then
rm -f "$DST"
elif [ -e "$DST" ]; then
mv "$DST" "${DST}.old-$(date +%s)" 2&gt;&gt;"$LOG" || true
fi
# Create symlink
ln -sfn "$SRC" "$DST" 2&gt;&gt;"$LOG"
step "Linked: ${DST/$HOME/\~} → ${SRC/$HOME/\~}"
done
# Special: starship.toml
if [ -f "$DOTS/config/starship.toml" ]; then
ln -sfn "$DOTS/config/starship.toml" \
"$CFG/starship.toml" 2&gt;&gt;"$LOG"
fi
log "Symlinks created"
}
##################################################
# SET SCRIPT PERMISSIONS #
##################################################
set_permissions() {
section "Setting Permissions"
local SCRIPT_DIRS=(
"$CFG/hypr/scripts"
"$CFG/waybar/scripts"
"$CFG/rofi/scripts"
"$CFG/hyprlock/scripts"
"$CFG/ags/scripts"
"$CFG/eww/scripts"
"$CFG/dunst/scripts"
"$LOCAL/bin"
"$DOTS/scripts"
)
local COUNT=0
for DIR in "${SCRIPT_DIRS[@]}"; do
[ -d "$DIR" ] || continue
while IFS= read -r -d '' SCRIPT; do
chmod +x "$SCRIPT" 2&gt;&gt;"$LOG"
COUNT=$((COUNT + 1))
done &lt; &lt;(find "$DIR" -type f \
\( -name "*.sh" -o -name "*.py" -o -name "*.fish" \) \
-print0 2&gt;/dev/null)
done
# Set local/bin scripts executable
while IFS= read -r -d '' BIN; do
[ -f "$BIN" ] &amp;&amp; chmod +x "$BIN" 2&gt;&gt;"$LOG"
COUNT=$((COUNT + 1))
done &lt; &lt;(find "$LOCAL/bin" -type f -print0 2&gt;/dev/null)
log "Set permissions on $COUNT scripts"
}
##################################################
# SETUP FISH SHELL #
##################################################
setup_fish() {
section "Setting Up Fish Shell"
# Install fish if missing
if ! command -v fish &amp;&gt;/dev/null; then
install_package "fish" "required"
fi
# Add fish to /etc/shells
local FISH_PATH
FISH_PATH=$(command -v fish)
if ! grep -qF "$FISH_PATH" /etc/shells; then
echo "$FISH_PATH" | sudo tee -a /etc/shells &gt;/dev/null
log "Added fish to /etc/shells"
fi
# Set fish as default shell
if [ "$SHELL" != "$FISH_PATH" ]; then
if ask "Set Fish as default shell?"; then
chsh -s "$FISH_PATH" "$USER"
log "Fish set as default shell"
fi
else
log "Fish already default shell"
fi
# Install Fisher
if ! fish -c "type -q fisher" 2&gt;/dev/null; then
step "Installing Fisher plugin manager..."
fish -c "
curl -sL \
'https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish' \
| source &amp;&amp; fisher install jorgebucaran/fisher
" 2&gt;&gt;"$LOG" &amp;&amp; log "Fisher installed" || \
warn "Fisher install failed"
else
log "Fisher already installed"
fi
# Install fish plugins
local FISH_PLUGINS=(
"jorgebucaran/autopair.fish"
"patrickf1/fzf.fish"
"meaningful-ooo/sponge"
"nickeb96/puffer-fish"
"gazorby/fish-abbreviation-tips"
"franciscolourenco/done"
)
for PLUGIN in "${FISH_PLUGINS[@]}"; do
step "Fish plugin: $PLUGIN"
fish -c "fisher install $PLUGIN" &gt;&gt;"$LOG" 2&gt;&amp;1 || \
warn "Plugin failed: $PLUGIN"
done
log "Fish setup complete"
##################################################
# SETUP NEOVIM #
##################################################
setup_neovim() {
section "Setting Up Neovim"
if ! command -v nvim &amp;&gt;/dev/null; then
install_package "neovim" "required"
fi
local NVIM_VERSION
NVIM_VERSION=$(nvim --version 2&gt;/dev/null | head -1 | \
grep -oP 'v[\d.]+' || echo "unknown")
log "Neovim: $NVIM_VERSION"
# Install plugins headlessly
if ask "Install Neovim plugins now (takes 2-5 minutes)?"; then
step "Installing Lazy.nvim plugins..."
timeout 300 nvim --headless \
"+Lazy! sync" \
"+sleep 3000ms" \
"+qall!" \
&gt;&gt;"$LOG" 2&gt;&amp;1 &amp;&amp; \
log "Neovim plugins installed" || \
warn "Neovim plugin install timed out — run :Lazy sync manually"
# Install LSP servers via Mason
step "Installing LSP servers..."
timeout 300 nvim --headless \
"+MasonInstall lua-language-server pyright bash-language-server stylua" \
"+sleep 10000ms" \
"+qall!" \
&gt;&gt;"$LOG" 2&gt;&amp;1 &amp;&amp; \
log "LSP servers installed" || \
warn "LSP install timed out — run :Mason manually"
fi
}
##################################################
# SETUP SYSTEMD SERVICES #
##################################################
setup_systemd() {
section "Setting Up Systemd Services"
# Create user systemd service directory
mkdir -p "$CFG/systemd/user"
# Enable system services
local SYSTEM_SERVICES=(
"NetworkManager"
"bluetooth"
"udisks2"
)
for SVC in "${SYSTEM_SERVICES[@]}"; do
if systemctl is-enabled "$SVC" &amp;&gt;/dev/null; then
log "$SVC already enabled"
else
sudo systemctl enable --now "$SVC" &gt;&gt;"$LOG" 2&gt;&amp;1 &amp;&amp; \
log "Enabled: $SVC" || \
warn "Failed to enable: $SVC"
fi
done
# Enable user services
local USER_SERVICES=(
"pipewire"
"pipewire-pulse"
"wireplumber"
)
for SVC in "${USER_SERVICES[@]}"; do
if systemctl --user is-enabled "$SVC" &amp;&gt;/dev/null; then
log "$SVC already enabled"
else
systemctl --user enable --now "$SVC" &gt;&gt;"$LOG" 2&gt;&amp;1 &amp;&amp; \
log "Enabled (user): $SVC" || \
warn "Failed to enable: $SVC"
fi
done
# Reload user daemon
systemctl --user daemon-reload 2&gt;&gt;"$LOG" || true
log "Systemd services configured"
}
##################################################
# SETUP DISPLAY MANAGER #
##################################################
setup_display_manager() {
section "Setting Up Display Manager"
# Check if SDDM is installed
if ! command -v sddm &amp;&gt;/dev/null; then
if ask "Install SDDM (display manager)?"; then
install_package "sddm" "required"
else
info "Skipping display manager — you can start Hyprland manually"
return 0
fi
fi
# Enable SDDM
if ! systemctl is-enabled sddm &amp;&gt;/dev/null; then
sudo systemctl enable sddm &gt;&gt;"$LOG" 2&gt;&amp;1 &amp;&amp; \
log "SDDM enabled" || \
warn "SDDM enable failed"
log "SDDM already enabled"
else
fi
# Create SDDM Hyprland session
local SESSION_DIR="/usr/share/wayland-sessions"
sudo mkdir -p "$SESSION_DIR"
if [ ! -f "$SESSION_DIR/hyprland.desktop" ]; then
sudo tee "$SESSION_DIR/hyprland.desktop" &gt; /dev/null &lt;&lt; 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
DesktopNames=Hyprland
EOF
log "Hyprland session file created"
else
log "Hyprland session already exists"
fi
# Install SDDM theme
if ask "Install SDDM Sugar Dark theme?"; then
install_package "sddm-theme-sugar-dark" "optional" || \
install_package "sddm-sugar-dark" "optional" || \
warn "SDDM theme not available in repos"
fi
}
##################################################
# INSTALL FONTS #
##################################################
install_fonts() {
section "Installing Fonts"
bash "$DOTS/scripts/install-fonts.sh" all 2&gt;&gt;"$LOG" &amp;&amp; \
log "Fonts installed" || \
warn "Font install had errors"
}
##################################################
# INSTALL THEMES #
##################################################
install_themes() {
section "Installing Themes"
bash "$DOTS/scripts/install-themes.sh" all 2&gt;&gt;"$LOG" &amp;&amp; \
log "Themes installed" || \
warn "Theme install had errors"
}
##################################################
# CONFIGURE GTK #
##################################################
configure_gtk() {
section "Configuring GTK"
# GTK 2 settings
cat &gt; "$CFG/gtk-2.0/gtkrc" &lt;&lt; 'GTK2'
gtk-theme-name="adw-gtk3-dark"
gtk-icon-theme-name="Papirus-Dark"
gtk-cursor-theme-name="Bibata-Modern-Ice"
gtk-cursor-theme-size=24
gtk-font-name="JetBrainsMono Nerd Font 11"
GTK2
# GTK 3 settings.ini
cat &gt; "$CFG/gtk-3.0/settings.ini" &lt;&lt; 'GTK3'
[Settings]
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-font-name=JetBrainsMono Nerd Font 11
gtk-application-prefer-dark-theme=true
gtk-enable-animations=true
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
GTK3
# GTK 4 settings.ini
cat &gt; "$CFG/gtk-4.0/settings.ini" &lt;&lt; 'GTK4'
[Settings]
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-font-name=JetBrainsMono Nerd Font 11
gtk-application-prefer-dark-theme=true
gtk-enable-animations=true
GTK4
# Apply via gsettings
if command -v gsettings &amp;&gt;/dev/null; then
gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" 2&gt;/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark" 2&gt;/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Ice" 2&gt;/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size 24 2&gt;/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2&gt;/dev/null || true
gsettings set org.gnome.desktop.interface font-name "JetBrainsMono Nerd Font 11" 2&gt;/dev/null || true
log "GTK settings applied via gsettings"
fi
# Cursor symlink for X11 compatibility
mkdir -p "$HOME/.icons/default"
cat &gt; "$HOME/.icons/default/index.theme" &lt;&lt; 'CURSOR'
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=Bibata-Modern-Ice
CURSOR
log "GTK configured"
}
##################################################
# CONFIGURE QT #
##################################################
configure_qt() {
section "Configuring Qt"
# qt5ct.conf
cat &gt; "$CFG/qt5ct/qt5ct.conf" &lt;&lt; 'QT5'
[Appearance]
style=kvantum-dark
color_scheme_path=~/.config/qt5ct/colors/ash-dark.conf
icon_theme=Papirus-Dark
custom_palette=true
[Fonts]
general=@Variant(\0\0\0@\0\0\0\x1eJetBrainsMono Nerd Font\0\0\0\0\0\0\0\0\0\x9c\0\0\0\n\0\0\0\0\0\0)
fixed=@Variant(\0\0\0@\0\0\0\x1eJetBrainsMono Nerd Font\0\0\0\0\0\0\0\0\0\x9c\0\0\0\n\0\0\0\0\0\0)
QT5
# qt6ct.conf
cat &gt; "$CFG/qt6ct/qt6ct.conf" &lt;&lt; 'QT6'
[Appearance]
style=kvantum-dark
color_scheme_path=~/.config/qt6ct/colors/ash-dark.conf
icon_theme=Papirus-Dark
custom_palette=true
[Fonts]
general=@Variant(\0\0\0@\0\0\0\x1eJetBrainsMono Nerd Font\0\0\0\0\0\0\0\0\0\x9c\0\0\0\n\0\0\0\0\0\0)
fixed=@Variant(\0\0\0@\0\0\0\x1eJetBrainsMono Nerd Font\0\0\0\0\0\0\0\0\0\x9c\0\0\0\n\0\0\0\0\0\0)
QT6
# Apply Kvantum theme
if command -v kvantummanager &amp;&gt;/dev/null; then
kvantummanager --set AshTheme 2&gt;&gt;"$LOG" || true
fi
log "Qt configured"
}
##################################################
# SETUP INITIAL WALLPAPER #
##################################################
setup_wallpaper() {
section "Setting Up Initial Wallpaper"
local WALL_DIRS=(
"$HOME/Pictures/Wallpapers/dark"
"$HOME/Pictures/Wallpapers"
"$HOME/Pictures/Wallpapers/anime"
"$HOME/Pictures/Wallpapers/abstract"
)
# Download default wallpaper if none exist
local HAS_WALL=false
for DIR in "${WALL_DIRS[@]}"; do
if [ -n "$(find "$DIR" -maxdepth 1 -type f \
\( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \) \
2&gt;/dev/null | head -1)" ]; then
HAS_WALL=true
break
fi
done
if [ "$HAS_WALL" = "false" ]; then
step "Downloading default wallpapers..."
local WALLPAPERS=(
"https://raw.githubusercontent.com/linuxdotexe/nordic-wallpapers/master/wallpapers/ign_HighFalls.jpg"
"https://raw.githubusercontent.com/linuxdotexe/nordic-wallpapers/master/wallpapers/ign_Bonito_Pattern.jpg"
)
for URL in "${WALLPAPERS[@]}"; do
local FNAME
FNAME=$(basename "$URL")
curl -Lo "$HOME/Pictures/Wallpapers/dark/$FNAME" \
"$URL" --max-time 30 --silent &amp;&amp; \
step "Downloaded: $FNAME" || true
done
fi
# Set first found wallpaper as default
local FIRST_WALL=""
for DIR in "${WALL_DIRS[@]}"; do
FIRST_WALL=$(find "$DIR" -maxdepth 1 -type f \
\( -name "*.jpg" -o -name "*.jpeg" \
-o -name "*.png" -o -name "*.webp" \) \
2&gt;/dev/null | head -1 || echo "")
[ -n "$FIRST_WALL" ] &amp;&amp; break
done
if [ -n "$FIRST_WALL" ]; then
echo "$FIRST_WALL" &gt; "$CACHE/wallpaper/last"
log "Default wallpaper: $(basename "$FIRST_WALL")"
else
warn "No wallpaper found — add images to ~/Pictures/Wallpapers/"
fi
}
##################################################
# GENERATE INITIAL THEME #
##################################################
generate_initial_theme() {
section "Generating Initial Theme"
local LAST_WALL
LAST_WALL=$(cat "$CACHE/wallpaper/last" 2&gt;/dev/null || echo "")
if [ -z "$LAST_WALL" ] || [ ! -f "$LAST_WALL" ]; then
warn "No wallpaper to generate theme from"
info "After first boot: ash theme pick"
return 0
fi
if [ -f "$CFG/hypr/scripts/theme-engine.sh" ] &amp;&amp; \
[ -x "$CFG/hypr/scripts/theme-engine.sh" ]; then
step "Running theme engine on $(basename "$LAST_WALL")..."
bash "$CFG/hypr/scripts/theme-engine.sh" \
"$LAST_WALL" silent 2&gt;&gt;"$LOG" &amp;&amp; \
log "Initial theme generated" || \
warn "Theme generation failed — will retry on first boot"
else
fi
warn "Theme engine not found — will apply on first boot"
}
##################################################
# CONFIGURE ENVIRONMENT #
##################################################
configure_environment() {
section "Configuring Environment"
# environment.d (systemd)
mkdir -p "$CFG/environment.d"
cat &gt; "$CFG/environment.d/ash.conf" &lt;&lt; EOF
# ASH Hyprland Dotfiles v3.0 Environment
ASH_DOTS=$HOME/.dotfiles
ASH_VERSION=3.0
ASH_CFG=$HOME/.config
ASH_CACHE=$HOME/.cache/ash-dots
ASH_STATE=$HOME/.local/state/ash-dots
EDITOR=nvim
VISUAL=nvim
BROWSER=firefox
TERMINAL=kitty
QT_QPA_PLATFORM=wayland;xcb
QT_QPA_PLATFORMTHEME=qt6ct
MOZ_ENABLE_WAYLAND=1
XCURSOR_THEME=Bibata-Modern-Ice
XCURSOR_SIZE=24
HYPRCURSOR_THEME=Bibata-Modern-Ice
HYPRCURSOR_SIZE=24
EOF
# profile.d
mkdir -p "$CFG/profile.d"
cat &gt; "$CFG/profile.d/ash.sh" &lt;&lt; EOF
#!/bin/sh
# ASH Hyprland Dotfiles v3.0
export ASH_DOTS="$HOME/.dotfiles"
export ASH_VERSION="3.0"
export PATH="$HOME/.local/bin:\$PATH"
EOF
# /etc/environment (system-wide)
if ask "Add Wayland env vars to /etc/environment?"; then
sudo tee -a /etc/environment &gt; /dev/null &lt;&lt; 'ENV'
# ASH Hyprland Wayland Environment
QT_QPA_PLATFORM=wayland;xcb
QT_AUTO_SCREEN_SCALE_FACTOR=1
MOZ_ENABLE_WAYLAND=1
XCURSOR_SIZE=24
ENV
log "/etc/environment updated"
fi
log "Environment configured"
}
##################################################
# INSTALL CLI TOOLS #
##################################################
install_cli_tools() {
section "Installing ASH CLI Tools"
local BINS=(
"ash"
"ash-theme"
"ash-wall"
"ash-doctor"
"ash-update"
"ash-backup"
"ash-reset"
"ash-clean"
)
for BIN in "${BINS[@]}"; do
local SRC="$DOTS/bin/$BIN"
local DST="$LOCAL/bin/$BIN"
if [ -f "$SRC" ]; then
ln -sfn "$SRC" "$DST" 2&gt;&gt;"$LOG"
chmod +x "$DST"
step "Installed: $BIN"
fi
done
# Verify PATH includes ~/.local/bin
if echo "$PATH" | grep -q "$HOME/.local/bin"; then
log "~/.local/bin is in PATH"
else
warn "~/.local/bin not in PATH — add to shell config"
fi
log "CLI tools installed"
}
##################################################
# SETUP AVATAR #
##################################################
setup_avatar() {
section "Setting Up Lock Screen Avatar"
if [ -x "$CFG/hyprlock/assets/avatar.sh" ]; then
bash "$CFG/hyprlock/assets/avatar.sh" setup 2&gt;&gt;"$LOG" &amp;&amp; \
log "Avatar configured" || \
warn "Avatar setup failed — place photo at ~/.face"
else
# Create minimal avatar placeholder
if command -v magick &amp;&gt;/dev/null; then
magick \
-size 200x200 \
"xc:#7c3aed" \
-font "DejaVu-Sans" \
-pointsize 80 \
-fill white \
-gravity center \
-annotate 0 "${USER:0:1}" \
"$HOME/.face" \
2&gt;&gt;"$LOG" &amp;&amp; \
log "Generated initials avatar" || \
warn "Could not generate avatar"
fi
fi
}
##################################################
# FINAL VALIDATION #
##################################################
final_validation() {
section "Final Validation"
local ERRORS=0
local WARNINGS=0
# Check critical files
declare -A CRITICAL_FILES=(
["$CFG/hypr/hyprland.conf"]="Hyprland main config"
["$CFG/hypr/core/env.conf"]="Environment config"
["$CFG/hypr/modules/keybinds.conf"]="Keybindings"
["$CFG/waybar/configs/top-bar.jsonc"]="Waybar config"
["$CFG/kitty/kitty.conf"]="Kitty config"
["$CFG/fish/config.fish"]="Fish config"
)
for FILE in "${!CRITICAL_FILES[@]}"; do
if [ -f "$FILE" ] || [ -L "$FILE" ]; then
log "✓ ${CRITICAL_FILES[$FILE]}"
else
warn "Missing: ${CRITICAL_FILES[$FILE]} ($FILE)"
WARNINGS=$((WARNINGS + 1))
fi
done
# Check critical commands
local CRITICAL_CMDS=(
"hyprland:Hyprland compositor"
"waybar:Status bar"
"rofi:App launcher"
"dunst:Notifications"
"kitty:Terminal"
"fish:Shell"
"nvim:Editor"
"swww:Wallpaper daemon"
"grim:Screenshots"
"convert:ImageMagick (theme engine)"
)
for PAIR in "${CRITICAL_CMDS[@]}"; do
local CMD="${PAIR%%:*}"
local DESC="${PAIR##*:}"
if command -v "$CMD" &amp;&gt;/dev/null; then
log "✓ $DESC ($CMD)"
else
warn "Missing: $DESC ($CMD)"
WARNINGS=$((WARNINGS + 1))
fi
done
# Check fonts
if fc-list 2&gt;/dev/null | grep -qi "JetBrains"; then
log "✓ JetBrainsMono Nerd Font"
else
warn "JetBrainsMono Nerd Font not found"
step "Fix: paru -S ttf-jetbrains-mono-nerd &amp;&amp; fc-cache -fv"
WARNINGS=$((WARNINGS + 1))
fi
# Check permissions
local PERM_ERRORS
PERM_ERRORS=$(find "$CFG/hypr/scripts" \
-name "*.sh" ! -perm -u+x \
2&gt;/dev/null | wc -l || echo "0")
if [ "$PERM_ERRORS" -eq 0 ]; then
log "✓ Script permissions correct"
else
warn "$PERM_ERRORS scripts need +x"
find "$CFG/hypr/scripts" -name "*.sh" ! -perm -u+x \
-exec chmod +x {} \; 2&gt;/dev/null || true
log "Permissions fixed"
fi
echo ""
echo -e " ${BOLD}Validation Summary:${N}"
echo -e " ${G}Passed:${N} echo -e " ${Y}Warnings:${N} $WARNINGS"
echo -e " ${R}Errors:${N} $ERRORS"
$(( $(grep -c "^.*✓" &lt;&lt;&lt; "$(log 2&gt;/dev/null || echo '')") )) checks"
if [ "$ERRORS" -gt 0 ]; then
echo ""
err "Installation has critical errors — check $LOG"
elif [ "$WARNINGS" -gt 0 ]; then
echo ""
warn "Installation complete with $WARNINGS warning(s)"
info "Run 'ash doctor' after first boot to fix warnings"
else
echo ""
log "Validation passed — installation is production-ready!"
fi
}
##################################################
# SHOW FINAL SUMMARY #
##################################################
show_summary() {
local TOTAL_DIRS
TOTAL_DIRS=$(find "$CFG" -type d 2&gt;/dev/null | wc -l || echo "?")
local TOTAL_FILES
TOTAL_FILES=$(find "$CFG/hypr" -type f 2&gt;/dev/null | wc -l || echo "?")
echo ""
echo -e "${P}${BOLD}"
cat &lt;&lt; 'SUMMARY'
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
■ ■
■ ■ ASH HYPRLAND DOTFILES v3.0 — INSTALLATION COMPLETE! ■
■ ■
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
■ ■
■ NEXT STEPS: ■
■ ■
■ 1. REBOOT your system ■
■ sudo reboot ■
■ ■
■ 2. At login screen, select HYPRLAND ■
■ ■
■ 3. Open terminal (SUPER + Return) ■
■ ■
■ 4. Pick your wallpaper + theme: ■
■ ash theme pick ■
■ ■
■ 5. Run health check: ■
■ ash doctor ■
■ ■
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
■ ■
■ ESSENTIAL KEYBINDS: ■
■ ■
■ SUPER + Return Open Terminal ■
■ SUPER + Space App Launcher ■
■ SUPER + Q Close Window ■
■ SUPER + ALT + W Wallpaper Picker ■
■ SUPER + SHIFT + R Reload Config ■
■ SUPER + Escape Power Menu ■
■ SUPER + / Keybind Help ■
■ ■
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
■ ■
■ ASH CLI: ■
■ ash theme pick Pick wallpaper + apply theme ■
■ ash shot area Screenshot ■
■ ash vol up Volume up ■
■ ash doctor System health check ■
■ ash update Update dotfiles ■
■ ash backup Backup configs ■
■ ■
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
SUMMARY
echo -e "${N}"
echo -e " ${C}Install log:${N} $LOG"
echo -e " ${C}Backup:${N} $BACKUP_DIR"
echo ""
}
##################################################
# MAIN #
##################################################
main() {
# Setup log
mkdir -p "$LOG_DIR"
echo "# ASH Install Log — $(date)" &gt; "$LOG"
# Acquire lock
acquire_lock
# Show banner
show_banner
# Confirm
echo -e " ${Y}${BOLD}This installer will:${N}"
echo -e " ${DIM}• Install 50+ packages${N}"
echo -e " ${DIM}• Create 200+ config files${N}"
echo -e " ${DIM}• Backup existing configs to $BACKUP_DIR${N}"
echo -e " ${DIM}• Set Fish as default shell (optional)${N}"
echo -e " ${DIM}• Enable systemd services${N}"
echo ""
ask "Begin production installation?" || {
echo -e " ${Y}Installation cancelled${N}"
rm -f "$LOCK_FILE"
exit 0
}
# Run all phases
validate_system
detect_pm
install_aur_helper
detect_gpu
backup_existing
create_directories
install_packages
install_fonts
install_themes
symlink_configs
set_permissions
setup_fish
setup_neovim
configure_gtk
configure_qt
configure_environment
setup_display_manager
setup_systemd
install_cli_tools
setup_avatar
setup_wallpaper
generate_initial_theme
final_validation
# Release lock
rm -f "$LOCK_FILE"
show_summary
}
main "$@"