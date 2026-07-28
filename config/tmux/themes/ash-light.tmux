# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 — TMUX THEME: ASH LIGHT                               ║
# ║                                                                            ║
# ║  Base:    Catppuccin Latte                                                 ║
# ║  Accent:  Mauve #8839ef                                                    ║
# ║  Style:   Clean light with warm cream tones                               ║
# ╚══════════════════════════════════════════════════════════════════════════╝

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🎨  CATPPUCCIN LATTE PALETTE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

thm_crust="#dce0e8"
thm_mantle="#e6e9ef"
thm_base="#eff1f5"
thm_surface0="#ccd0da"
thm_surface1="#bcc0cc"
thm_surface2="#acb0be"
thm_overlay0="#9ca0b0"
thm_overlay1="#8c8fa1"
thm_overlay2="#7c7f93"
thm_subtext0="#6c6f85"
thm_subtext1="#5c5f77"
thm_text="#4c4f69"
thm_rosewater="#dc8a78"
thm_flamingo="#dd7878"
thm_pink="#ea76cb"
thm_mauve="#8839ef"
thm_red="#d20f39"
thm_maroon="#e64553"
thm_peach="#fe640b"
thm_yellow="#df8e1d"
thm_green="#40a02b"
thm_teal="#179299"
thm_sky="#04a5e5"
thm_sapphire="#209fb5"
thm_blue="#1e66f5"
thm_lavender="#7287fd"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  📐  SEPARATORS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

sep_right=""
sep_left=""
sep_right_thin=""
sep_left_thin=""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🖥️  STATUS BAR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -g status-style "bg=$thm_mantle,fg=$thm_text"

set -g status-left "\
#[fg=$thm_base,bg=$thm_mauve,bold] 󰊠 #S \
#[fg=$thm_mauve,bg=$thm_surface0]$sep_right\
#[fg=$thm_subtext1,bg=$thm_surface0] #{?client_prefix,⌨ ,  }\
#[fg=$thm_surface0,bg=$thm_mantle]$sep_right \
"

set -g status-right "\
#{prefix_highlight}\
#[fg=$thm_surface0,bg=$thm_mantle]$sep_left\
#[fg=$thm_overlay1,bg=$thm_surface0]  #(uptime -p | sed 's/up //' | sed 's/ days\\?,/d/' | sed 's/ hours\\?,/h/' | sed 's/ minutes\\?/m/') \
#[fg=$thm_surface1,bg=$thm_surface0]$sep_left\
#[fg=$thm_subtext0,bg=$thm_surface1] 󰨲  %a %d %b \
#[fg=$thm_base,bg=$thm_blue,bold] 󱑍  %H:%M \
#[fg=$thm_blue,bg=$thm_mantle]$sep_left\
#[fg=$thm_overlay0,bg=$thm_mantle] #H \
"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🗂️  WINDOW TABS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

setw -g window-status-separator ""

setw -g window-status-format "\
#[fg=$thm_mantle,bg=$thm_surface0]$sep_right\
#[fg=$thm_overlay1,bg=$thm_surface0] #I #{?window_activity_flag,󰐰 ,}#W \
#[fg=$thm_surface0,bg=$thm_mantle]$sep_right\
"

setw -g window-status-current-format "\
#[fg=$thm_mantle,bg=$thm_mauve]$sep_right\
#[fg=$thm_base,bg=$thm_mauve,bold] #I #{?window_zoomed_flag,󰍉 ,}#W \
#[fg=$thm_mauve,bg=$thm_mantle]$sep_right\
"

setw -g window-status-bell-style    "fg=$thm_red,bg=$thm_mantle,bold"
setw -g window-status-current-style "fg=$thm_mauve,bg=$thm_mantle,bold"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  📐  PANE BORDERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -g pane-border-style        "fg=$thm_surface1"
set -g pane-active-border-style "fg=$thm_mauve"
set -g popup-border-style       "fg=$thm_mauve,bg=$thm_base"
set -g popup-border-lines       rounded
set -g message-style            "fg=$thm_text,bg=$thm_surface0,bold"
set -g message-command-style    "fg=$thm_mauve,bg=$thm_mantle,bold"
setw -g mode-style              "fg=$thm_base,bg=$thm_mauve,bold"
set -g display-panes-colour     "$thm_overlay0"
set -g display-panes-active-colour "$thm_mauve"