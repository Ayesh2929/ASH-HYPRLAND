# 🎨 ASH DOTFILES v3.0 — THEMING GUIDE

Complete guide to the ASH dynamic theme engine.

---

## 🎯 HOW IT WORKS

```
📸 Wallpaper
    ↓
🎨 ImageMagick (extracts 24 dominant colors)
    ↓
🧠 Color Sorter (sorts by luminance, finds saturated accents)
    ↓
📌 Semantic Role Assignment (base, primary, text, success, etc.)
    ↓
🖌️ Theme Generation (12 target applications)
    ↓
🔄 Hot-Reload (all apps update instantly)
```

---

## ⚡ QUICK START

```bash
# Pick a wallpaper interactively
ash theme pick

# Apply a specific wallpaper
ash theme apply ~/Pictures/Wallpapers/dark/my-wallpaper.jpg

# Random wallpaper from a category
ash theme random cyberpunk

# Re-apply current colors (no wallpaper change)
ash theme reapply

# Show current palette
ash theme colors
```

---

## 🎨 COLOR ROLES

| Role | Purpose | Example |
|------|---------|---------|
| `base` | Main background (darkest) | `#1e1e2e` |
| `mantle` | Secondary background | `#181825` |
| `crust` | Deepest background | `#11111b` |
| `surface0` | Cards, raised elements | `#313244` |
| `surface1` | Hover states | `#45475a` |
| `surface2` | Borders, dividers | `#585b70` |
| `overlay0` | Muted text, icons | `#6c7086` |
| `overlay1` | Disabled elements | `#7f849c` |
| `overlay2` | Placeholder text | `#9399b2` |
| `primary` | Main accent color | `#cba6f7` |
| `secondary` | Secondary accent | `#89b4fa` |
| `tertiary` | Third accent | `#94e2d5` |
| `text` | Primary text | `#cdd6f4` |
| `subtext1` | Secondary text | `#bac2de` |
| `subtext0` | Tertiary text | `#a6adc8` |
| `muted` | Very dim text | `#7f849c` |
| `success` | Success/positive | `#a6e3a1` |
| `warning` | Warning/caution | `#f9e2af` |
| `error` | Error/danger | `#f38ba8` |
| `info` | Information | `#89b4fa` |

---

## 🎯 THEME TARGETS

The theme engine applies colors to **12 applications**:

| App | What Changes |
|-----|-------------|
| **Hyprland** | Border colors (animated gradient), shadow color, group bar |
| **Waybar** | All CSS color variables (50+ modules update instantly) |
| **Kitty** | All 16 terminal colors, background, cursor, tabs |
| **WezTerm** | Color scheme, tab bar, cursor |
| **Alacritty** | Color palette, cursor |
| **Rofi** | Complete dynamic theme (background, accent, selection) |
| **Dunst** | Notification colors per urgency level |
| **Hyprlock** | Lock screen overlay, input field colors |
| **GTK 3/4** | CSS overrides for buttons, menus, entries |
| **Qt5/Qt6** | Color palette via qt5ct/qt6ct |
| **Fish shell** | All syntax highlighting colors |
| **AGS/EWW** | Widget colors via CSS variables |

---

## 📁 WALLPAPER ORGANIZATION

```
~/Pictures/Wallpapers/
├── dark/          # Dark-toned wallpapers (best for theme engine)
├── light/         # Light wallpapers
├── cyberpunk/     # Neon/cyberpunk aesthetics
├── anime/         # Anime artwork
├── abstract/      # Abstract art
├── nature/        # Nature photography
├── landscapes/    # Landscape photography
├── space/         # Space/astronomy
├── minimal/       # Minimalist designs
└── gradient/      # Gradient backgrounds
```

### Best Wallpapers for Theme Engine

✅ **Works great:**
- High contrast images with strong accent colors
- Cyberpunk / neon aesthetics (bright purples, blues, teals)
- Sunset photography (warm oranges, purples)
- Abstract art with defined color blocks
- Anime with colored hair/clothing

❌ **Avoid:**
- Pure white or pure black images
- Very grey/desaturated photos
- Images without distinct color groups

---

## 🔧 MANUAL COLOR OVERRIDE

If you want to use specific colors regardless of wallpaper,
create a custom palette file:

```bash
# Create custom palette
cat > ~/.cache/ash-dots/colors/custom.sh << 'EOF'
ASH_BASE="1a1a2e"
ASH_MANTLE="16213e"
ASH_SURFACE0="0f3460"
ASH_PRIMARY="e94560"
ASH_SECONDARY="533483"
ASH_TERTIARY="0f3460"
ASH_TEXT="eaeaea"
# ... etc
EOF

# Apply custom palette (without wallpaper change)
source ~/.cache/ash-dots/colors/custom.sh
~/.config/hypr/scripts/theme/theme-engine.sh "" reapply
```

---

## 🎛️ TRANSITION EFFECTS

The wallpaper transition can be customized in `wallpaper-picker.sh`:

```bash
# Available swww transitions:
# simple, fade, left, right, top, bottom, wipe, wave, grow, center, any, outer, random

swww img "${wallpaper}" \
    --transition-type grow \          # ← Change this
    --transition-pos "0.5,0.5" \
    --transition-duration 2.5 \
    --transition-fps 60 \
    --transition-bezier "0.34,1.56,0.64,1.0"
```

---

## 💡 TROUBLESHOOTING

**Theme not applying?**
```bash
# Check theme engine
ash doctor

# Manual apply
~/.config/hypr/scripts/theme/theme-engine.sh ~/Pictures/my-wall.jpg apply

# Check logs
ash log 50 theme-engine
```

**Colors look wrong?**
```bash
# View current palette
ash theme colors | python3 -m json.tool

# Force re-extract
rm ~/.cache/ash-dots/colors/current.json
ash theme reapply
```

**Waybar not updating?**
```bash
pkill -SIGUSR2 waybar || (pkill waybar; waybar &)
```