# 🌟 ASH DOTFILES v3.0 — UNIQUE FEATURES GUIDE

Features found **only** in ASH Dotfiles — not in HyDE, Hyprdots, or any other dotfiles.

---

## 🎵 Music Reactive Theme

Desktop colors automatically sync with your music's album art.

```bash
ash music enable          # Start the daemon
ash music once            # Apply current song color
ash music status          # Check if running
ash music disable         # Stop the daemon
ash music reset           # Reset to wallpaper colors
```

**How it works:**
1. Monitors playerctl for song changes
2. Downloads album art from MPRIS metadata
3. Extracts most vibrant color using ImageMagick
4. Updates Hyprland borders + Waybar + Kitty

**Works with:** Spotify, ncspot, mpv, VLC, any MPRIS player

---

## 🏥 Desktop Health Score

Gamified system health monitoring with auto-fix.

```bash
ash score               # Show score dashboard (0-100)
ash score fix           # Auto-fix all detected issues
ash score history       # Score history over time
ash score export        # Export score data as JSON
ash score quick         # One-line score for scripts
```

**Categories scored:**
- ⚡ Performance (CPU, RAM, swap, disk, zombies)
- 🔒 Security (firewall, SSH, screen lock, keys)
- 🧹 Cleanliness (cache, logs, orphan packages)
- 📦 Updates (system packages, dotfiles)
- 💾 Backups (frequency, count)
- 🖥️ Desktop (running services, theme)

**Grades:** S+ S A B C D F

---

## 📁 Workspace Profiles

Save and restore complete workspace environments.

```bash
ash workspace create coding     # Save current workspace
ash workspace apply coding      # Restore workspace
ash workspace list              # Browse profiles (Rofi)
ash workspace delete old        # Remove profile
ash workspace init              # Install built-in profiles
```

**Built-in profiles:**
- `coding` — kitty + firefox + lazygit, performance mode
- `gaming` — steam, no animations, no blur
- `meeting` — browser fullscreen, large fonts, DND

**What's saved:**
- All open apps and their workspaces
- Wallpaper + color theme
- Power profile (performance/balanced/saver)
- Font size settings
- Animation on/off state

---

## 🌤️ Smart Wallpaper Engine

Wallpapers that change automatically based on time and weather.

```bash
ash smart enable          # Start auto-switching
ash smart disable         # Stop auto-switching
ash smart now             # Apply time-based wallpaper now
ash smart weather         # Apply weather-reactive wallpaper
ash smart schedule        # View schedule
ash smart edit-schedule   # Edit schedule in nvim
```

**Schedule format** (`~/.config/hypr/smart-wallpaper-schedule.conf`):
```
06 morning      # 6am → bright nature wallpapers
09 landscapes   # 9am → landscape photos
18 dark         # 6pm → dark wallpapers
21 minimal      # 9pm → minimal designs
```

**Weather modes:**
- ☀️ Sunny → landscapes
- 🌧️ Rainy → dark moody
- ❄️ Snowy → minimal
- ⛈️ Stormy → dark dramatic

---

## 📊 Desktop Analytics

Track and visualize how you use your desktop.

```bash
ash analytics show            # Usage dashboard
ash analytics start           # Start tracking
ash analytics stop            # Stop tracking
ash analytics export json     # Export data
ash analytics export csv      # Export as CSV
ash analytics reset           # Delete all data
```

**What's tracked:**
- App usage (which apps, how long)
- Workspace switches (how often, patterns)
- Theme changes (when, which wallpapers)
- System metrics (CPU, RAM over time)

**Privacy:** All data stays local in `~/.cache/ash-dots/analytics/desktop.db`

---

## 🤖 AI Theme Generator

Generate color palettes from text descriptions using local AI.

```bash
# Text-based generation
ash theme ai "dark cyberpunk purple neon rain"
ash theme ai "warm golden sunset autumn leaves"
ash theme ai "ocean blue deep midnight starry"
ash theme ai "forest green nature calm peaceful"

# Image-based generation
ash theme ai from-image ~/vacation.jpg

# Browse saved AI palettes
ash theme ai list

# Apply a saved palette
ash theme ai apply cyberpunk-purple-neon

# Check AI backend status
ash theme ai status

# Install Ollama for best results
ash theme ai install-ollama
```

**Backends:**
1. **Ollama** (local LLM) — best results, private
2. **Python algorithmic** — always works, no AI needed

---

## ↩️ Theme Undo System

Never lose a theme you liked again.

```bash
ash theme undo              # Restore previous theme
ash theme history           # Browse theme history (Rofi)
```

**How it works:**
- Auto-saves before every theme change
- Keeps last 20 snapshots
- Each snapshot includes: wallpaper, colors, Hyprland config
- Rofi browser shows color swatches + wallpaper name

---

## ☀️🌙 Light/Dark Mode

Full light theme support with Catppuccin Latte.

```bash
ash theme mode light        # Switch to light mode
ash theme mode dark         # Switch to dark mode
ash theme mode toggle       # Toggle between modes
ash theme mode auto         # Time-based auto-switch
ash theme mode schedule     # Setup systemd timer
```

**Applies to:** Hyprland, Waybar, Kitty, Fish, GTK 3/4

---

## 🎭 Context-Aware Theming

Desktop colors change based on what app is focused.

```bash
ash context enable          # Start context daemon
ash context disable         # Stop context daemon
ash context toggle          # Toggle on/off
ash context status          # Show current context
ash context config          # Edit app→theme mappings
```

**App → Theme mappings:**
- Spotify, ncspot → Purple (music)
- Steam, Lutris → Red (gaming)
- kitty, alacritty → Green (terminal)
- Firefox, Chromium → Blue (browser)
- VS Code, Neovim → Mauve (coding)
- MPV, VLC → Orange (cinema)
- Discord, Telegram → Teal (social)

**Customize:** `~/.config/hypr/context-themes.conf`

---

## 💡 Usage Tips

```bash
# Start all unique features at boot
# Add to ~/.config/hypr/modules/autostart.conf:
exec-once = ash music enable
exec-once = ash smart enable
exec-once = ash analytics start
exec-once = ash context enable

# Or start manually anytime:
ash music enable && ash smart enable && ash analytics start

# Check everything is working:
ash music status
ash smart status
ash analytics status
ash context status
```