# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 — TMUX THEME: ASH DARK                                ║
# ║                                                                            ║
# ║  Base:    Catppuccin Mocha                                                 ║
# ║  Accent:  Mauve #cba6f7                                                    ║
# ║  Style:   Powerline separators + Nerd Fonts v3 icons                      ║
# ║  Usage:   source ~/.config/tmux/themes/ash-dark.tmux                      ║
# ╚══════════════════════════════════════════════════════════════════════════╝

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🎨  CATPPUCCIN MOCHA PALETTE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Base surfaces
thm_crust="#11111b"
thm_mantle="#181825"
thm_base="#1e1e2e"
thm_surface0="#313244"
thm_surface1="#45475a"
thm_surface2="#585b70"

# Overlays (used for muted text)
thm_overlay0="#6c7086"
thm_overlay1="#7f849c"
thm_overlay2="#9399b2"

# Text
thm_subtext0="#a6adc8"
thm_subtext1="#bac2de"
thm_text="#cdd6f4"

# Accent spectrum
thm_rosewater="#f5e0dc"
thm_flamingo="#f2cdcd"
thm_pink="#f5c2e7"
thm_mauve="#cba6f7"
thm_red="#f38ba8"
thm_maroon="#eba0ac"
thm_peach="#fab387"
thm_yellow="#f9e2af"
thm_green="#a6e3a1"
thm_teal="#94e2d5"
thm_sky="#89dceb"
thm_sapphire="#74c7ec"
thm_blue="#89b4fa"
thm_lavender="#b4befe"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  📐  SEPARATORS — Powerline glyphs
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

sep_right=""    # Powerline right solid
sep_left=""     # Powerline left solid
sep_right_thin=""  # Powerline right thin
sep_left_thin=""   # Powerline left thin

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🖥️  STATUS BAR — Left section
#  Layout: [session] [window list] ... [right modules]
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Status bar background ─────────────────────────────────────────────────────
set -g status-style "bg=$thm_mantle,fg=$thm_text"

# ── Left: Session indicator ───────────────────────────────────────────────────
#  ██ 󰊠 session-name ██▓▒░
#  Mauve block → session icon + name → fade to background

set -g status-left "\
#[fg=$thm_base,bg=$thm_mauve,bold] 󰊠 #S \
#[fg=$thm_mauve,bg=$thm_surface0]$sep_right\
#[fg=$thm_subtext1,bg=$thm_surface0] #{?client_prefix,⌨ ,  }\
#[fg=$thm_surface0,bg=$thm_mantle]$sep_right \
"

# ── Right: System info modules ────────────────────────────────────────────────
#  Modules: prefix indicator | uptime | date | time

set -g status-right "\
#{prefix_highlight}\
#[fg=$thm_surface0,bg=$thm_mantle]$sep_left\
#[fg=$thm_overlay1,bg=$thm_surface0] #{?window_zoomed_flag,󰍉 zoom ,}\
#[fg=$thm_surface0,bg=$thm_mantle]$sep_left\
#[fg=$thm_surface1,bg=$thm_mantle]$sep_left\
#[fg=$thm_overlay1,bg=$thm_surface1]  #(uptime -p | sed 's/up //' | sed 's/ days\\?,/d/' | sed 's/ hours\\?,/h/' | sed 's/ minutes\\?/m/') \
#[fg=$thm_surface0,bg=$thm_surface1]$sep_left\
#[fg=$thm_subtext0,bg=$thm_surface0] 󰨲  %a %d %b \
#[fg=$thm_surface1,bg=$thm_surface0]$sep_left\
#[fg=$thm_base,bg=$thm_surface1] \
#[fg=$thm_base,bg=$thm_blue,bold] 󱑍  %H:%M \
#[fg=$thm_blue,bg=$thm_mantle]$sep_left\
#[fg=$thm_overlay0,bg=$thm_mantle] #H \
"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🗂️  WINDOW TABS — Active and inactive styling
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Separator between window names
setw -g window-status-separator ""

# ── Inactive window tab ───────────────────────────────────────────────────────
setw -g window-status-format "\
#[fg=$thm_mantle,bg=$thm_surface0]$sep_right\
#[fg=$thm_overlay1,bg=$thm_surface0] #I #{?window_activity_flag,󰐰 ,}#W \
#[fg=$thm_surface0,bg=$thm_mantle]$sep_right\
"

# ── Active window tab ─────────────────────────────────────────────────────────
#  Bold, accent-colored, with zoom indicator
setw -g window-status-current-format "\
#[fg=$thm_mantle,bg=$thm_mauve]$sep_right\
#[fg=$thm_base,bg=$thm_mauve,bold] #I #{?window_zoomed_flag,󰍉 ,}#W \
#[fg=$thm_mauve,bg=$thm_mantle]$sep_right\
"

# Window status bell (activity notification)
setw -g window-status-bell-style "fg=$thm_red,bg=$thm_mantle,bold"

# Window status current style (fallback)
setw -g window-status-current-style "fg=$thm_mauve,bg=$thm_mantle,bold"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  📐  PANE BORDERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -g pane-border-style         "fg=$thm_surface0"
set -g pane-active-border-style  "fg=$thm_mauve"

# Pane border status (title in the border)
# set -g pane-border-status top
# set -g pane-border-format "#[fg=$thm_mauve] #{pane_title} "

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🖥️  POPUP STYLE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -g popup-style               "bg=$thm_base"
set -g popup-border-style        "fg=$thm_mauve,bg=$thm_base"
set -g popup-border-lines        rounded

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  📩  MESSAGE / COPY MODE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -g message-style             "fg=$thm_text,bg=$thm_surface0,bold"
set -g message-command-style     "fg=$thm_mauve,bg=$thm_mantle,bold"
setw -g mode-style               "fg=$thm_base,bg=$thm_mauve,bold"
set -g display-panes-colour      "$thm_overlay0"
set -g display-panes-active-colour "$thm_mauve"