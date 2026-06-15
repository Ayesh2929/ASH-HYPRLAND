#!/bin/bash
set -euo pipefail

echo "Setting up systemd user services..."

mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/hyprpaper.service << 'EOF'
[Unit]
Description=Hyprpaper Wallpaper Daemon
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/hyprpaper
Restart=on-failure

[Install]
WantedBy=graphical-session.target
EOF

cat > ~/.config/systemd/user/waybar.service << 'EOF'
[Unit]
Description=Waybar Status Bar
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/waybar
Restart=on-failure

[Install]
WantedBy=graphical-session.target
EOF

cat > ~/.config/systemd/user/swaync.service << 'EOF'
[Unit]
Description=Sway Notification Center
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/swaync
Restart=on-failure

[Install]
WantedBy=graphical-session.target
EOF

systemctl --user daemon-reload
systemctl --user enable hyprpaper waybar swaync

echo "Services configured. Start with: systemctl --user start hyprpaper waybar swaync"