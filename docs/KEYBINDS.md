# ⌨️ ASH DOTFILES v3.0 — COMPLETE KEYBIND REFERENCE

> All keybinds use `SUPER` (Windows/Meta key) as the primary modifier.

---

## 🖥️ SYSTEM & SESSION

| Keybind | Action |
|---------|--------|
| `SUPER + SHIFT + R` | Reload Hyprland config |
| `SUPER + SHIFT + Q` | Force kill active window |
| `SUPER + Q` | Close active window |
| `SUPER + Escape` | Power menu |
| `SUPER + SHIFT + Escape` | Exit Hyprland |
| `SUPER + SHIFT + L` | Lock screen |
| `CTRL + ALT + L` | Lock screen (alternative) |
| `SUPER + ALT + P` | Power profile picker |

---

## 📟 TERMINALS

| Keybind | Action |
|---------|--------|
| `SUPER + Return` | Open Kitty terminal |
| `SUPER + SHIFT + Return` | Floating terminal |
| `` SUPER + ` `` | Scratch terminal (toggle) |
| `SUPER + ALT + Return` | WezTerm |
| `CTRL + ALT + T` | Alacritty |

---

## 🚀 LAUNCHERS

| Keybind | Action |
|---------|--------|
| `SUPER + Space` | App launcher (Rofi drun) |
| `SUPER + SHIFT + Space` | Full launcher (multi-mode) |
| `SUPER + R` | Command runner |
| `SUPER + Tab` | Window switcher |
| `SUPER + ALT + S` | SSH launcher |
| `SUPER + ALT + E` | Emoji picker |
| `SUPER + ALT + C` | Calculator |
| `SUPER + ALT + M` | Man page viewer |
| `SUPER + ALT + F` | File picker |
| `SUPER + ALT + T` | Translator |
| `SUPER + SHIFT + /` | Keybind reference viewer |

---

## 🎨 THEME & WALLPAPER

| Keybind | Action |
|---------|--------|
| `SUPER + ALT + W` | Wallpaper picker (interactive) |
| `SUPER + SHIFT + W` | Random wallpaper |
| `SUPER + CTRL + W` | Previous wallpaper |
| `SUPER + ALT + A` | Re-apply current theme |
| `SUPER + ALT + K` | Color picker |
| `SUPER + ALT + G` | Cycle screen shader |

---

## 📸 SCREENSHOTS

| Keybind | Action |
|---------|--------|
| `Print` | Full screen capture |
| `SHIFT + Print` | Area selection |
| `ALT + Print` | Active window |
| `CTRL + Print` | Current monitor |
| `SUPER + Print` | Area → edit (swappy) |
| `SUPER + SHIFT + Print` | Area → OCR (text) |
| `SUPER + CTRL + Print` | Color picker |
| `SUPER + ALT + Print` | Delayed (3s) |

---

## 🎬 RECORDING

| Keybind | Action |
|---------|--------|
| `SUPER + F10` | Toggle screen recording |
| `SUPER + SHIFT + F10` | Record area |
| `SUPER + CTRL + F10` | Record with audio |
| `SUPER + ALT + F10` | Stop recording |

---

## 🔊 AUDIO (Hardware Keys)

| Keybind | Action |
|---------|--------|
| `XF86AudioRaiseVolume` | Volume up 5% |
| `XF86AudioLowerVolume` | Volume down 5% |
| `XF86AudioMute` | Toggle mute |
| `XF86AudioMicMute` | Microphone mute |
| `XF86AudioPlay` | Play/Pause |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Previous track |
| `XF86AudioStop` | Stop playback |

---

## ☀️ BRIGHTNESS

| Keybind | Action |
|---------|--------|
| `XF86MonBrightnessUp` | Brightness +5% |
| `XF86MonBrightnessDown` | Brightness -5% |
| `SUPER + F5` | Toggle night light |

---

## 🪟 WINDOW MANAGEMENT

| Keybind | Action |
|---------|--------|
| `SUPER + F` | Toggle floating |
| `SUPER + F11` | Fullscreen |
| `SUPER + SHIFT + F` | Maximize (fake fullscreen) |
| `SUPER + P` | Toggle pseudo-tiling |
| `SUPER + J` | Toggle split direction |
| `SUPER + C` | Center window |
| `SUPER + SHIFT + P` | Pin window (all workspaces) |

---

## 🔍 FOCUS NAVIGATION

| Keybind | Action |
|---------|--------|
| `SUPER + H` or `SUPER + ←` | Focus left |
| `SUPER + J` or `SUPER + ↓` | Focus down |
| `SUPER + K` or `SUPER + ↑` | Focus up |
| `SUPER + L` or `SUPER + →` | Focus right |
| `ALT + Tab` | Cycle windows forward |
| `ALT + SHIFT + Tab` | Cycle windows backward |

---

## 📦 WINDOW MOVEMENT

| Keybind | Action |
|---------|--------|
| `SUPER + SHIFT + H/J/K/L` | Move window |
| `SUPER + ALT + H/J/K/L` | Move floating (30px) |
| `SUPER + CTRL + H/J/K/L` | Resize window |

---

## 🗂️ WORKSPACES

| Keybind | Action |
|---------|--------|
| `SUPER + 1-0` | Switch to workspace 1-10 |
| `SUPER + [` | Previous workspace |
| `SUPER + ]` | Next workspace |
| `SUPER + \` | Toggle last workspace |
| `SUPER + N` | Go to empty workspace |
| `SUPER + SHIFT + 1-0` | Move window to workspace |
| `SUPER + -` | Toggle magic scratchpad |
| `SUPER + M` | Toggle music scratchpad |

---

## 🖥️ MONITORS

| Keybind | Action |
|---------|--------|
| `SUPER + .` | Focus next monitor |
| `SUPER + ,` | Focus prev monitor |
| `SUPER + SHIFT + .` | Move window to next monitor |
| `SUPER + ALT + O` | Monitor layout picker |

---

## 🖱️ MOUSE BINDS

| Action | Bind |
|--------|------|
| Move window | `SUPER + LMB drag` |
| Resize window | `SUPER + RMB drag` |
| Toggle float | `SUPER + Middle click` |
| Workspace scroll | `SUPER + Scroll wheel` |

---

## 🏃 SUBMAPS (Hold then press)

### Resize Mode: `SUPER + R`
| Key | Action |
|-----|--------|
| `H/J/K/L` | Resize window |
| `←/↓/↑/→` | Resize window |
| `Escape` | Exit submap |

### Power Mode: `SUPER + Escape`
- Opens power menu (via Rofi)

---

*Full configuration: `~/.config/hypr/modules/keybinds.conf`*