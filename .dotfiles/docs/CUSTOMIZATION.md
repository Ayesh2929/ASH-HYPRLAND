# 🎨 ASH DOTFILES v3.0 — CUSTOMIZATION GUIDE

Everything you need to personalize ASH Dotfiles.

---

## 🔑 THE GOLDEN RULE

**All personal customizations go in ONE file:**

```
~/.config/hypr/UserOverrides/user.conf
```

This file:
- ✅ Is **NOT** tracked by git
- ✅ **Survives** `ash update`
- ✅ Is loaded **LAST** (highest priority)
- ✅ Overrides **everything**

---

## 🖥️ MONITOR SETUP

```ini
# ~/.config/hypr/UserOverrides/user.conf

# Single monitor
monitor = DP-1, 1920x1080@144, 0x0, 1

# Dual monitors
monitor = DP-1, 2560x1440@165, 0x0, 1
monitor = HDMI-A-1, 1920x1080@60, 2560x0, 1

# HiDPI (4K with 1.5x scaling)
monitor = DP-1, 3840x2160@60, 0x0, 1.5

# Find your monitor names:
# hyprctl monitors
# wlr-randr
```

---

## ⌨️ CUSTOM KEYBINDS

```ini
# Add to UserOverrides/user.conf

# Open your browser
bind = SUPER, B, exec, firefox

# Custom terminal
bind = SUPER, T, exec, wezterm

# Launch script
bind = SUPER ALT, X, exec, /path/to/your/script.sh
```

---

## 🎨 CUSTOM THEME COLORS

```bash
# Create a custom palette file
cat > ~/.cache/ash-dots/colors/current.sh << 'EOF'
ASH_PRIMARY="cba6f7"      # Your accent color
ASH_BASE="1e1e2e"         # Background
ASH_TEXT="cdd6f4"         # Text color
# ... etc
EOF

# Apply it
ash theme reapply
```

---

## 🚀 CUSTOM STARTUP APPS

```ini
# Add to UserOverrides/user.conf

# Start browser on workspace 2
exec-once = [workspace 2 silent] firefox

# Start terminal app on workspace 1
exec-once = [workspace 1 silent] kitty

# Custom daemon
exec-once = /path/to/your/daemon
```

---

## 🪟 CUSTOM WINDOW RULES

```ini
# Float specific apps
windowrulev2 = float, class:^(your-app)$
windowrulev2 = size 800 600, class:^(your-app)$
windowrulev2 = center, class:^(your-app)$

# Send to specific workspace
windowrulev2 = workspace 3 silent, class:^(code)$

# Custom opacity
windowrulev2 = opacity 0.90 0.85, class:^(your-app)$
```

---

## 🐟 FISH CUSTOMIZATION

```fish
# ~/.config/fish/conf.d/99-custom.fish (create this file)

# Add your aliases
alias myalias 'your-command'

# Custom function
function myfunction
    echo "Hello from custom function!"
end

# Custom env var
set -gx MY_VAR "my-value"
```

---

## 📊 WAYBAR CUSTOMIZATION

Add custom modules to `~/.config/waybar/configs/top.jsonc`:

```jsonc
// Add to modules-right
"custom/my-module",

// Define the module
"custom/my-module": {
    "exec": "echo 'Hello'",
    "interval": 5,
    "format": "{}",
    "tooltip": false
}
```

Style in `~/.config/waybar/styles/main.css`:

```css
#custom-my-module {
    color: @primary;
    padding: 2px 10px;
}
```

---

## 🔧 PERFORMANCE TUNING

```ini
# ~/.config/hypr/UserOverrides/user.conf

# Gaming mode — disable eye candy
decoration {
    blur { enabled = false }
    shadow { enabled = false }
}
animations { enabled = false }
general { allow_tearing = true }

# Or use the keybind: SUPER + CTRL + S → then press 'p' for performance
```

---

## 💡 TIPS

1. **Run `ash doctor`** after major changes
2. **Run `ash reload`** to apply without logout
3. **Use `ash theme reapply`** to re-apply colors
4. **Keep UserOverrides minimal** — only your truly personal stuff
5. **Backup before changes**: `ash backup`