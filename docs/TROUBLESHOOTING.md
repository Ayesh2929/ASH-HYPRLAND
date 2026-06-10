# 🔧 ASH DOTFILES v3.0 — TROUBLESHOOTING GUIDE

Common issues and their solutions.

---

## 🚨 QUICK FIXES

```bash
# Run health check first
ash doctor

# Reload everything
ash reload all

# Check logs
ash log 100 install
ash log 100 theme-engine
```

---

## 🖥️ HYPRLAND ISSUES

### Black screen / Hyprland won't start

```bash
# Check logs
journalctl --user -u hyprland -n 50

# Verify GPU driver
lspci | grep -i vga
ls /dev/dri/

# NVIDIA: ensure these are in env.conf
# env = GBM_BACKEND,nvidia-drm
# env = __GLX_VENDOR_LIBRARY_NAME,nvidia
# env = WLR_NO_HARDWARE_CURSORS,1
```

### Config errors after edit

```bash
# Test config without reloading
hyprctl reload 2>&1 | head -20

# Check syntax
grep -n "^source" ~/.config/hypr/hyprland.conf
```

### Keybinds not working

```bash
# View active keybinds
hyprctl binds | grep -i "your-key"

# Reload keybinds
hyprctl reload
```

---

## 📊 WAYBAR ISSUES

### Waybar blank / not showing

```bash
# Restart Waybar
pkill waybar; waybar &

# Check config syntax
waybar --log-level debug 2>&1 | head -30

# Validate JSON
python3 -m json.tool ~/.config/waybar/configs/top.jsonc
```

### Module not updating

```bash
# Check specific module
~/.config/waybar/scripts/hardware/gpu.sh status
~/.config/waybar/scripts/system/updates.sh

# Send signal to refresh
pkill -SIGRTMIN+8 waybar    # Volume signal
pkill -SIGRTMIN+9 waybar    # Brightness signal
```

### Weather not showing

```bash
# Check internet
curl -s "wttr.in?format=3"

# Clear cache and retry
rm ~/.cache/ash-dots/weather-cache.json
~/.config/waybar/scripts/utils/weather.sh refresh
```

---

## 🎨 THEME ENGINE ISSUES

### Colors not applying

```bash
# Check ImageMagick
convert -version

# Manual extraction test
convert ~/Pictures/test.jpg \
    -resize 200x200^ \
    -colors 8 \
    -unique-colors \
    -format "%[hex:u]\n" info:

# Force reapply
ash theme reapply
```

### Waybar colors wrong

```bash
# Check colors file exists
cat ~/.config/waybar/styles/colors.css | head -10

# Regenerate
~/.config/hypr/scripts/theme/theme-engine.sh "" reapply
```

---

## 🔊 AUDIO ISSUES

### No sound

```bash
# Check PipeWire status
systemctl --user status pipewire wireplumber

# Restart audio
systemctl --user restart pipewire pipewire-pulse wireplumber

# Check devices
wpctl status
pactl list sinks short
```

### Volume keys not working

```bash
# Test volume script
~/.config/hypr/scripts/media/volume.sh up 5

# Check backend
~/.config/hypr/scripts/media/volume.sh backend

# Check key binding
hyprctl binds | grep -i "XF86Audio"
```

---

## 📸 SCREENSHOT ISSUES

### grim/slurp errors

```bash
# Check installation
command -v grim slurp swappy

# Install if missing
sudo pacman -S grim slurp
paru -S swappy

# Test basic screenshot
grim /tmp/test.png && echo "Works!"
```

### OCR not working

```bash
# Install tesseract
sudo pacman -S tesseract tesseract-data-eng

# Test OCR
echo "Hello World" | tesseract stdin stdout
```

---

## 🔒 LOCK SCREEN ISSUES

### Hyprlock crashes / fails

```bash
# Check hyprlock config
hyprlock --debug 2>&1 | head -30

# Test with minimal config
hyprlock

# Check wallpaper path
cat ~/.cache/ash-dots/wallpaper/last
```

### Lock screen colors wrong

```bash
# Regenerate hyprlock colors
~/.config/hypr/scripts/theme/theme-engine.sh "" reapply

# Check hyprlock config
grep "color" ~/.config/hyprlock/hyprlock.conf | head -10
```

---

## 🐟 FISH SHELL ISSUES

### Fish not default shell

```bash
# Add to /etc/shells
echo $(which fish) | sudo tee -a /etc/shells

# Change default
chsh -s $(which fish)

# Verify
getent passwd $USER | cut -d: -f7
```

### Prompt not showing (Starship)

```bash
# Test starship
starship prompt

# Check config
cat ~/.config/starship.toml | head -5

# Re-install
curl -sS https://starship.rs/install.sh | sh
```

---

## 📝 NEOVIM ISSUES

### Plugins not loading

```bash
# Open Neovim and run
nvim -c "Lazy"
# Then press: S (sync)

# From terminal
nvim --headless "+Lazy! sync" +qa
```

### LSP not working

```bash
# Check Mason
nvim -c "Mason"

# Install missing LSP
nvim -c "MasonInstall lua-language-server"

# Check LSP status in Neovim
:LspInfo
```

---

## 🔵 BLUETOOTH ISSUES

### Bluetooth not starting

```bash
# Enable service
sudo systemctl enable --now bluetooth

# Check status
bluetoothctl show

# Restart
sudo systemctl restart bluetooth
```

### Device not connecting

```bash
# Scan for devices
bluetoothctl scan on

# Pair device
bluetoothctl pair XX:XX:XX:XX:XX:XX

# Connect
bluetoothctl connect XX:XX:XX:XX:XX:XX
```

---

## 🌐 NETWORK ISSUES

### WiFi not working

```bash
# Check NetworkManager
systemctl status NetworkManager

# List WiFi networks
nmcli dev wifi list

# Connect to network
nmcli dev wifi connect "SSID" password "password"
```

---

## 🆘 NUCLEAR OPTION (Full Reset)

If nothing works:

```bash
# 1. Backup current state
ash backup

# 2. Soft reset (try this first)
ash-reset soft

# 3. Theme reset
ash-reset theme

# 4. Hard reset (⚠️ destructive)
ash-reset hard

# 5. Reinstall
bash ~/.dotfiles/install.sh --from-phase 4
```

---

## 📋 COLLECTING DEBUG INFO

When reporting issues, include:

```bash
# System info
fastfetch

# Hyprland version
hyprctl version

# Dotfiles version
ash version

# Recent logs
ash log 100 install
ash log 100 theme-engine

# Health check
ash doctor
```