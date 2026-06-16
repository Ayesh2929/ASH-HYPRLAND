#!/bin/bash
set -euo pipefail

THEMES_DIR="${HOME}/.config/hypr/themes"
mkdir -p "$THEMES_DIR"

cat > "$THEMES_DIR/everforest.conf" << 'EOF'
# Everforest Theme
$bg = rgba(2d353bee)
$fg = rgba(d3c6aaee)
$accent = rgba(a7c080ee)
$surface = rgba(343f44ee)
general { col.active_border = $accent $accent 45deg; col.inactive_border = $surface; }
decoration { col.shadow = $bg; }
EOF

cat > "$THEMES_DIR/gruvbox.conf" << 'EOF'
# Gruvbox Theme
$bg = rgba(282828ee)
$fg = rgba(ebdbb2ee)
$accent = rgba(fabd2fee)
$surface = rgba(3c3836ee)
general { col.active_border = $accent $accent 45deg; col.inactive_border = $surface; }
decoration { col.shadow = $bg; }
EOF

cat > "$THEMES_DIR/rose-pine.conf" << 'EOF'
# Rose Pine Theme
$bg = rgba(191724ee)
$fg = rgba(e0def4ee)
$accent = rgba(ebbcbaee)
$surface = rgba(1f1d2eee)
general { col.active_border = $accent $accent 45deg; col.inactive_border = $surface; }
decoration { col.shadow = $bg; }
EOF

cat > "$THEMES_DIR/kanagawa.conf" << 'EOF'
# Kanagawa Theme
$bg = rgba(1f1f28ee)
$fg = rgba(dcd7baee)
$accent = rgba(7e9cd8ee)
$surface = rgba(2a2a37ee)
general { col.active_border = $accent $accent 45deg; col.inactive_border = $surface; }
decoration { col.shadow = $bg; }
EOF

echo "Generated 4 additional themes"