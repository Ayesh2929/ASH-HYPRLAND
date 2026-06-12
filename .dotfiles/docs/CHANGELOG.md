# 📋 ASH DOTFILES — CHANGELOG

## v3.1.0 — "Innovation Release" (Latest)

### 🌟 New Unique Features

#### 🎵 Music Reactive Theme (`ash music`)
- Album art color extraction on every song change
- Applies dominant vibrant color as desktop accent
- Updates: Hyprland borders, Waybar, Kitty terminal
- Zero-config — works with any MPRIS player
- `ash music enable` — start daemon
- `ash music once` — apply current song color

#### 🏥 Desktop Health Score (`ash score`)
- Gamified system health: 0-100 score
- 6 categories: Performance, Security, Cleanliness,
  Updates, Backups, Desktop
- Letter grades: S+ S A B C D F
- `ash score fix` — auto-fix all detected issues
- Score history tracking with 30-entry log

#### 📁 Workspace Profiles (`ash workspace`)
- Save complete workspace state as named profile
- Restores: apps, layout, wallpaper, power profile, font size
- Built-in profiles: coding, gaming, meeting
- `ash workspace create coding` — save current
- `ash workspace apply gaming` — restore any time

#### 🌤️ Smart Wallpaper Engine (`ash smart`)
- Time-based wallpaper scheduling (morning/day/evening/night)
- Weather-reactive wallpapers (sunny/rainy/cloudy/stormy)
- Custom schedule file: `~/.config/hypr/smart-wallpaper-schedule.conf`
- `ash smart enable` — start auto-switching daemon

#### 📊 Desktop Analytics (`ash analytics`)
- Track app usage, workspace switches, theme changes
- SQLite database for persistent history
- Beautiful dashboard: top apps, workspace usage
- `ash analytics export json` — export your data
- Privacy-first: all data stays local

#### 🤖 AI Theme Generator (`ash theme ai`)
- Generate color palettes from text descriptions
- `ash theme ai "cyberpunk purple neon rain"`
- `ash theme ai from-image ~/photo.jpg`
- Local AI via Ollama (no internet required)
- Algorithmic fallback (always works without Ollama)

#### ↩️ Theme Undo System (`ash theme undo`)
- Auto-saves theme state before every change
- `ash theme undo` — restore previous theme
- `ash theme history` — browse + restore any past theme
- Keeps last 20 theme snapshots

#### ☀️🌙 Light/Dark Mode (`ash theme mode`)
- Full light mode with Catppuccin Latte palette
- `ash theme mode light` — switch to light
- `ash theme mode dark` — switch to dark
- `ash theme mode toggle` — toggle between
- `ash theme mode auto` — time-based auto-switch
- `ash theme mode schedule` — systemd timer setup

### ⚖️ Legal
- Added `ATTRIBUTION.md` with all third-party credits
- Clarified MPV script stubs with download instructions
- Added API attribution (wttr.in, ipinfo.io)

---

## v3.0.0 — "Foundation Release"

### Features
- Dynamic theme engine (wallpaper → 24 colors → 12 apps)
- 274+ configuration files
- ASH CLI with 50+ commands
- 60+ health checks (ash doctor)
- Complete Neovim IDE (31+ plugins, LSP, DAP)
- AGS + EWW widget systems
- Session save/restore
- Multi-GPU monitoring (AMD/NVIDIA/Intel)
- Multi-battery support
- VPN detection (5 backends)
- OCR screenshot mode
- GIF recording
- Complete CI/CD pipeline (7 GitHub Actions)