#!/bin/bash
set -euo pipefail

echo "Installing ASH Dotfiles dependencies..."

pkgs=(
    hyprland waybar rofi-wayland kitty fish neovim
    swaylock swaync hyprpaper grim slurp wl-clipboard
    brightnessctl pipewire wireplumber pavucontrol
    jq sqlite3 socat curl eza bat fd ripgrep
    starship zoxide fzf
    noto-fonts noto-fonts-emoji ttf-jetbrains-mono-nerd
    papirus-icon-theme adw-gtk-theme
    blueman network-manager-applet
)

paru -S --needed "${pkgs[@]}"

echo "Creating symlinks..."
mkdir -p ~/.config
ln -sf "$(pwd)/config/hypr" ~/.config/hypr
ln -sf "$(pwd)/config/waybar" ~/.config/waybar
ln -sf "$(pwd)/config/rofi" ~/.config/rofi
ln -sf "$(pwd)/config/kitty" ~/.config/kitty
ln -sf "$(pwd)/config/fish" ~/.config/fish
ln -sf "$(pwd)/config/nvim" ~/.config/nvim
ln -sf "$(pwd)/config/gtk-3.0" ~/.config/gtk-3.0
ln -sf "$(pwd)/config/gtk-4.0" ~/.config/gtk-4.0
ln -sf "$(pwd)/config/eww" ~/.config/eww
ln -sf "$(pwd)/config/swaync" ~/.config/swaync
ln -sf "$(pwd)/config/mako" ~/.config/mako

echo "Installation complete! Run 'ash reload' to apply."