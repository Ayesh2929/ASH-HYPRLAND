#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  🌊 WAYLAND / HYPRLAND ENVIRONMENT ENGINE                                       ║
# ║                                                                                  ║
# ║  03-wayland.fish — Complete Wayland environment configuration                  ║
# ║  Depends on: 00-xdg.fish, 01-path.fish, 02-env.fish                           ║
# ║                                                                                  ║
# ║  Sections:                                                                       ║
# ║    • Wayland session detection & validation                                      ║
# ║    • XDG session variables                                                       ║
# ║    • Qt Wayland backend & scaling                                                ║
# ║    • GTK Wayland backend                                                         ║
# ║    • Application-specific Wayland flags                                          ║
# ║    • GPU-specific overrides (AMD / NVIDIA / Intel)                               ║
# ║    • Hyprland-specific environment                                               ║
# ║    • Multi-monitor & HiDPI                                                       ║
# ║    • X11 compatibility layer (XWayland)                                          ║
# ║    • Clipboard & portal setup                                                    ║
# ║    • Cursor & input configuration                                                ║
# ║                                                                                  ║
# ║  ASH Dotfiles v5.0 OMEGA                                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

status is-interactive || exit 0
set -q __ash_wayland_initialized && exit 0
set -g __ash_wayland_initialized 1


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔍 SESSION DETECTION — Determine compositor and display server
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Active session type ───────────────────────────────────────────────────────
set -g __ash_is_wayland 0
set -g __ash_is_hyprland 0
set -g __ash_is_sway 0
set -g __ash_is_gnome_wayland 0
set -g __ash_is_kde_wayland 0
set -g __ash_is_x11 0
set -g __ash_is_ssh 0

# SSH session detection
test -n "$SSH_CLIENT" || test -n "$SSH_TTY" && set -g __ash_is_ssh 1

# Wayland detection (multiple methods for robustness)
if test -n "$WAYLAND_DISPLAY"
    set -g __ash_is_wayland 1
else if test -n "$XDG_SESSION_TYPE" && test "$XDG_SESSION_TYPE" = "wayland"
    set -g __ash_is_wayland 1
end

# X11 detection
if test -n "$DISPLAY" && test $__ash_is_wayland -eq 0
    set -g __ash_is_x11 1
end

# Compositor-specific detection
if test $__ash_is_wayland -eq 1
    # Hyprland
    if test -n "$HYPRLAND_INSTANCE_SIGNATURE" \
        || test "$XDG_CURRENT_DESKTOP" = "Hyprland" \
        || command -sq hyprctl
        set -g __ash_is_hyprland 1
    end

    # Sway
    if test -n "$SWAYSOCK" || test "$XDG_CURRENT_DESKTOP" = "sway"
        set -g __ash_is_sway 1
    end

    # GNOME Wayland
    if test "$XDG_CURRENT_DESKTOP" = "GNOME" \
        || test "$XDG_CURRENT_DESKTOP" = "ubuntu:GNOME"
        set -g __ash_is_gnome_wayland 1
    end

    # KDE Plasma Wayland
    if test "$XDG_CURRENT_DESKTOP" = "KDE"
        set -g __ash_is_kde_wayland 1
    end
end

# ── Skip non-Wayland sessions ─────────────────────────────────────────────────
# (X11 env vars are handled by the display server itself)
if test $__ash_is_wayland -eq 0
    # Still set sensible defaults for X11 / headless
    test -n "$DISPLAY" || set -gx DISPLAY ":0"
    set -e __ash_is_wayland __ash_is_hyprland __ash_is_sway
    set -e __ash_is_gnome_wayland __ash_is_kde_wayland
    set -e __ash_is_x11 __ash_is_ssh
    exit 0
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🪪 XDG SESSION IDENTITY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -gx XDG_SESSION_TYPE    wayland

if test $__ash_is_hyprland -eq 1
    set -gx XDG_SESSION_DESKTOP  Hyprland
    set -gx XDG_CURRENT_DESKTOP  Hyprland
    set -gx DESKTOP_SESSION      Hyprland
else if test $__ash_is_sway -eq 1
    set -gx XDG_SESSION_DESKTOP  sway
    set -gx XDG_CURRENT_DESKTOP  sway
    set -gx DESKTOP_SESSION      sway
end

# Ensure D-Bus is aware of the session type
set -gx DBUS_SESSION_BUS_ADDRESS (
    test -n "$DBUS_SESSION_BUS_ADDRESS" \
        && echo $DBUS_SESSION_BUS_ADDRESS \
        || echo "unix:path=$XDG_RUNTIME_DIR/bus"
)


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎨 QT — Wayland backend, scaling, theming
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# QPA platform: prefer wayland, fallback to xcb for unsupported apps
set -gx QT_QPA_PLATFORM                 "wayland;xcb"
set -gx QT_WAYLAND_DISABLE_WINDOWDECORATION 1   # Let compositor draw decorations
set -gx QT_WAYLAND_RECONNECT_TRIES      10
set -gx QT_WAYLAND_FORCE_DPI            96

# Qt scaling — let Hyprland handle per-monitor scaling
set -gx QT_AUTO_SCREEN_SCALE_FACTOR     1
set -gx QT_ENABLE_HIGHDPI_SCALING       1
set -gx QT_SCALE_FACTOR_ROUNDING_POLICY PassThrough

# Qt theme integration
if test $__ash_is_kde_wayland -eq 0
    # Non-KDE: use qt6ct/qt5ct for consistent theming
    if command -sq qt6ct
        set -gx QT_QPA_PLATFORMTHEME qt6ct
    else if command -sq qt5ct
        set -gx QT_QPA_PLATFORMTHEME qt5ct
    end
end

# Qt style via kvantum (SVG-based, theme-engine compatible)
command -sq kvantummanager \
    && set -gx QT_STYLE_OVERRIDE kvantum

# Qt Accessibility
set -gx QT_ACCESSIBILITY 1

# Qt WebEngine (Chromium-based Qt apps)
set -gx QTWEBENGINE_CHROMIUM_FLAGS \
    "--enable-features=WebRTCPipeWireCapturer \
     --ozone-platform=wayland \
     --enable-gpu-rasterization \
     --enable-zero-copy"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🖼️  GTK — Wayland backend, scaling, theming
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# GDK: prefer wayland, fallback to x11 for apps needing XWayland
set -gx GDK_BACKEND                 "wayland,x11,*"
set -gx GDK_SCALE                   1    # Managed by compositor
set -gx GDK_DPI_SCALE               1    # Managed by compositor

# GTK portal integration
set -gx GTK_USE_PORTAL              1

# GTK theme (read from ASH state)
set -l __ash_gtk_theme (cat "$ASH_STATE/gtk-theme" 2>/dev/null || echo "ash-dark")
set -gx GTK_THEME                   $__ash_gtk_theme
set -e __ash_gtk_theme

# GTK CSD (client-side decorations) — enabled for Hyprland compatibility
set -gx GTK_CSD                     1

# GTK accessibility
set -gx GTK_A11Y                    none   # Disable AT-SPI scanning (perf)

# Clutter (GTK multimedia framework)
set -gx CLUTTER_BACKEND             wayland


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎮 SDL — Wayland backend for games & multimedia
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -gx SDL_VIDEODRIVER             wayland
set -gx SDL_AUDIODRIVER             pipewire   # PipeWire audio for SDL apps
set -gx SDL_JOYSTICK_HIDAPI         0          # Prefer evdev over HIDAPI for gamepads


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🌐 BROWSER WAYLAND FLAGS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Mozilla Firefox / Thunderbird ─────────────────────────────────────────────
set -gx MOZ_ENABLE_WAYLAND           1
set -gx MOZ_DBUS_REMOTE              1
set -gx MOZ_WEBRENDER                1    # Enable GPU-accelerated WebRender
set -gx MOZ_USE_XINPUT2              0    # Use Wayland input instead
set -gx MOZ_ACCELERATED              1    # Force GPU acceleration

# ── Chromium / Chrome / Brave ────────────────────────────────────────────────
set -gx CHROMIUM_FLAGS (string join " " \
    "--ozone-platform=wayland" \
    "--enable-features=WaylandWindowDecorations,UseOzonePlatform,WebRTCPipeWireCapturer" \
    "--enable-gpu-rasterization" \
    "--enable-zero-copy" \
    "--enable-accelerated-video-decode" \
    "--use-gl=desktop" \
    "--ignore-gpu-blocklist" \
    "--enable-oop-rasterization"
)

# ── Electron apps (VSCode, Discord, Obsidian, etc.) ──────────────────────────
set -gx ELECTRON_OZONE_PLATFORM_HINT    wayland
set -gx ELECTRON_ENABLE_LOGGING         false

# Electron flags file (used by apps that read it)
set -l __electron_flags_dir "$XDG_CONFIG_HOME"
for __electron_app in \
    code code-flags.conf \
    discord discord-flags.conf \
    obsidian obsidian-flags.conf
    # Individual app flags are managed by their own configs
end

# ── CEF (Chromium Embedded Framework) ────────────────────────────────────────
set -gx CEF_DISABLE_SANDBOX 1   # Required for some Electron apps


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ☕ JAVA & JVM WAYLAND
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Java AWT must be told about the non-reparenting WM
set -gx _JAVA_AWT_WM_NONREPARENTING 1

# Swing: use GTK LAF for native-ish appearance
set -gx AWT_TOOLKIT         MToolkit


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎮 GPU — Driver-specific Wayland overrides
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Detect GPU vendor ─────────────────────────────────────────────────────────
set -g __ash_gpu_vendor "unknown"
set -g __ash_gpu_driver "unknown"

if test -f /sys/class/drm/card0/device/vendor
    set -l __vendor_id (cat /sys/class/drm/card0/device/vendor 2>/dev/null)
    switch $__vendor_id
        case "0x1002"
            set -g __ash_gpu_vendor "amd"
        case "0x10de"
            set -g __ash_gpu_vendor "nvidia"
        case "0x8086"
            set -g __ash_gpu_vendor "intel"
    end
end

# Fallback: lspci detection
if test $__ash_gpu_vendor = "unknown" && command -sq lspci
    set -l __lspci_out (lspci 2>/dev/null | string lower)
    if echo $__lspci_out | grep -q "amd\|radeon\|ati"
        set -g __ash_gpu_vendor "amd"
    else if echo $__lspci_out | grep -q "nvidia"
        set -g __ash_gpu_vendor "nvidia"
    else if echo $__lspci_out | grep -q "intel"
        set -g __ash_gpu_vendor "intel"
    end
end

set -gx ASH_GPU_VENDOR $__ash_gpu_vendor


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔴 AMD GPU — RADV / Mesa / VA-API
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if test $__ash_gpu_vendor = "amd"
    # RADV (open-source Vulkan) — prefer over AMDVLK for gaming
    set -gx AMD_VULKAN_ICD           RADV
    set -gx VK_ICD_FILENAMES        /usr/share/vulkan/icd.d/radeon_icd.x86_64.json

    # VA-API hardware video decode
    set -gx LIBVA_DRIVER_NAME        radeonsi
    set -gx LIBVA_DISPLAY            wayland

    # VDPAU (compatibility layer for older apps)
    set -gx VDPAU_DRIVER             radeonsi

    # Mesa performance tuning
    set -gx MESA_DISK_CACHE_SINGLE_FILE 1        # Single-file shader cache
    set -gx MESA_DISK_CACHE_DATABASE    1        # Enable shader cache database
    set -gx MESA_LOADER_DRIVER_OVERRIDE radeonsi # Force correct driver
    set -gx MESA_VK_WSI_PRESENT_MODE   mailbox  # Low-latency present mode
    set -gx radv_enable_mrt_output_nan_fixup 1  # Fix some game artifacts

    # WLR backend for AMD
    set -gx WLR_RENDERER             vulkan

    # AMD power management
    set -gx MESA_GL_VERSION_OVERRIDE ""    # Don't override GL version

    set -g __ash_gpu_driver "radv/mesa"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🟢 NVIDIA GPU — Proprietary driver Wayland fixes
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if test $__ash_gpu_vendor = "nvidia"
    # Force GBM backend (required for Wayland with proprietary driver)
    set -gx GBM_BACKEND              nvidia-drm
    set -gx __GLX_VENDOR_LIBRARY_NAME nvidia

    # VA-API via NVDEC (hardware video decode)
    set -gx LIBVA_DRIVER_NAME        nvidia
    set -gx LIBVA_DISPLAY            wayland

    # Disable hardware cursors (broken on NVIDIA Wayland)
    set -gx WLR_NO_HARDWARE_CURSORS  1

    # NVIDIA modeset (must match kernel parameter)
    set -gx __NV_PRIME_RENDER_OFFLOAD 1
    set -gx __VK_LAYER_NV_optimus     NVIDIA_only

    # Hyprland NVIDIA-specific
    if test $__ash_is_hyprland -eq 1
        # Force EGL streams backend for NVIDIA
        set -gx HYPRLAND_BACKEND     drm
    end

    # G-Sync / VRR (enable only if supported)
    set -gx __GL_GSYNC_ALLOWED       0    # Let Hyprland manage VRR
    set -gx __GL_VRR_ALLOWED         0

    # NVIDIA performance
    set -gx __GL_MaxFramesAllowed    1    # Reduce input latency
    set -gx __GL_YIELD               NOTHING  # No CPU yield on GL calls

    # Vulkan ICD for NVIDIA
    set -gx VK_ICD_FILENAMES \
        /usr/share/vulkan/icd.d/nvidia_icd.json:\
        /usr/share/vulkan/icd.d/nvidia_layers.json

    # EGL platform
    set -gx EGL_PLATFORM             wayland

    set -g __ash_gpu_driver "nvidia-proprietary"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔵 INTEL GPU — ANV / VA-API / Mesa
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if test $__ash_gpu_vendor = "intel"
    # ANV (open-source Vulkan for Intel)
    set -gx VK_ICD_FILENAMES \
        /usr/share/vulkan/icd.d/intel_icd.x86_64.json

    # VA-API hardware video decode
    set -gx LIBVA_DRIVER_NAME        i965    # iHD for newer, i965 for older
    test -d /usr/lib/dri/iHD_drv_video.so \
        && set -gx LIBVA_DRIVER_NAME iHD
    set -gx LIBVA_DISPLAY            wayland

    # VDPAU via VAAPI
    set -gx VDPAU_DRIVER             va_gl

    # Intel power management
    set -gx MESA_LOADER_DRIVER_OVERRIDE iris  # Iris for Gen 11+, i965 for older
    test (lspci 2>/dev/null | grep -i "Intel" | grep -c "HD Graphics [0-9][0-9][0-9] ") -gt 0 \
        && set -gx MESA_LOADER_DRIVER_OVERRIDE i965  # Older Intel

    set -g __ash_gpu_driver "iris/mesa"
end

# Export GPU driver for diagnostics
set -gx ASH_GPU_DRIVER $__ash_gpu_driver


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔥 HYPRLAND-SPECIFIC ENVIRONMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if test $__ash_is_hyprland -eq 1
    # ── Hyprland socket & IPC ─────────────────────────────────────────────────
    # HYPRLAND_INSTANCE_SIGNATURE is set by Hyprland itself
    # Expose socket path for tools that need it
    if set -q HYPRLAND_INSTANCE_SIGNATURE
        set -gx HYPRLAND_IPC_SOCKET \
            "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock"
        set -gx HYPRLAND_IPC_SOCKET2 \
            "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
    end

    # ── Hyprland logging ──────────────────────────────────────────────────────
    set -gx HYPRLAND_LOG_WLR         0    # Disable verbose WLR logging
    set -gx HYPRLAND_TRACE           0    # Disable trace (set to 1 for debug)

    # ── Hyprland plugins (hyprhook) ───────────────────────────────────────────
    set -gx HYPRLAND_PLUGIN_DIR "$XDG_DATA_HOME/hyprland/plugins"

    # ── Portal integration ────────────────────────────────────────────────────
    set -gx XDG_SESSION_TYPE            wayland
    set -gx HYPRLAND_PORTAL_BACKEND     wlr   # Use wlr-portal for screencapture

    # ── Tearing / VRR ────────────────────────────────────────────────────────
    # These are hints to apps; actual control is in hyprland.conf
    set -gx MESA_VK_WSI_PRESENT_MODE   mailbox  # or fifo for power saving
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🖼️  XWAYLAND — X11 compatibility layer
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DISPLAY is needed for XWayland apps even on pure Wayland sessions
set -q DISPLAY || set -gx DISPLAY ":0"

# XWayland scaling (for legacy HiDPI apps)
set -gx GDK_SCALE               1   # Don't double-scale through GDK
set -gx XCURSOR_SIZE            24  # Consistent cursor size (match hyprland.conf)

# X11 input method
set -gx GTK_IM_MODULE       wayland
set -gx QT_IM_MODULE        wayland
set -gx XMODIFIERS          "@im=fcitx"  # If using fcitx5

# XDG Activation Token (focus stealing prevention)
set -gx XDG_ACTIVATION_TOKEN ""


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📋 CLIPBOARD — Wayland clipboard integration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# wl-clipboard provides wl-copy / wl-paste
if command -sq wl-copy
    set -gx CLIPBOARD_MANAGER   wl-clipboard

    # Neovim clipboard integration
    set -gx NVIM_CLIPBOARD_TOOL wl-copy

    # Override X11 clipboard tools with Wayland equivalents
    # (for apps that hardcode xclip/xsel)
    function xclip
        if contains -- "-selection" $argv
            wl-copy $argv
        else
            wl-paste $argv
        end
    end
    function xsel
        if contains -- "--clipboard" $argv; or contains -- "-b" $argv
            wl-paste --no-newline
        else
            wl-paste --no-newline
        end
    end
end

# cliphist (clipboard history daemon)
command -sq cliphist \
    && set -gx CLIPHIST_MAX_ITEMS 1000


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🖱️  CURSOR — Consistent cursor theme across Wayland and XWayland
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Read from ASH state (set by theme engine)
set -l __ash_cursor_theme \
    (cat "$ASH_STATE/cursor-theme" 2>/dev/null || echo "ash-cursors-rounded")
set -l __ash_cursor_size \
    (cat "$ASH_STATE/cursor-size" 2>/dev/null || echo "24")

set -gx XCURSOR_THEME   $__ash_cursor_theme
set -gx XCURSOR_SIZE    $__ash_cursor_size
set -gx HYPRCURSOR_THEME $__ash_cursor_theme
set -gx HYPRCURSOR_SIZE  $__ash_cursor_size

set -e __ash_cursor_theme __ash_cursor_size


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔊 PIPEWIRE / AUDIO — Wayland-native audio environment
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq pipewire
    set -gx PIPEWIRE_RUNTIME_DIR    $XDG_RUNTIME_DIR
    set -gx PIPEWIRE_LATENCY        "256/48000"   # Low latency default

    # PulseAudio compatibility via pipewire-pulse
    set -gx PULSE_RUNTIME_PATH      "$XDG_RUNTIME_DIR/pulse"
    set -gx PULSE_SERVER             "unix:$XDG_RUNTIME_DIR/pulse/native"

    # JACK compatibility via pipewire-jack
    set -gx JACK_DRIVER_CLOCK_SOURCE c
    set -gx DISABLE_RTKIT            0   # Allow real-time priority for audio
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📡 XDG DESKTOP PORTALS — Wayland file picker, screen capture, etc.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Portals are configured in /usr/share/xdg-desktop-portal/
# These env vars influence which portal implementation is chosen

if test $__ash_is_hyprland -eq 1
    # xdg-desktop-portal-hyprland for screencapture
    # xdg-desktop-portal-gtk for file picker (fallback)
    set -gx PORTAL_IMPLEMENTATION    hyprland,gtk
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📺 MULTI-MONITOR & HIDPI
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Hyprland handles per-monitor scaling in hyprland.conf
# These env vars set cross-application scaling hints

# Detect HiDPI (primary monitor scale > 1)
set -g __ash_hidpi 0
if test $__ash_is_hyprland -eq 1 && command -sq hyprctl
    set -l __scale (hyprctl monitors -j 2>/dev/null \
        | string match -r '"scale":\s*([\d.]+)' \
        | tail -n 1 \
        | string replace -r '"scale":\s*' '' \
        | string trim)
    if test -n "$__scale" && math "$__scale > 1" >/dev/null 2>&1
        set -g __ash_hidpi 1
        set -gx ASH_HIDPI 1
        set -gx ASH_PRIMARY_SCALE $__scale
    end
end

# GDK Wayland backend handles per-monitor scaling natively
# Do NOT set GDK_SCALE to >1 with fractional scaling (causes blurriness)
set -gx GDK_SCALE 1

# Electron HiDPI
if test $__ash_hidpi -eq 1
    set -gx ELECTRON_FORCE_DEVICE_SCALE_FACTOR 1  # Let Wayland handle it
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎞️  HARDWARE VIDEO ACCELERATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# mpv hardware decode
if command -sq mpv
    set -gx MPV_HOME "$XDG_CONFIG_HOME/mpv"
    # hwdec configured in mpv.conf per-GPU
end

# FFmpeg hardware acceleration hint
set -gx FFMPEG_VAAPI_DEVICE /dev/dri/renderD128  # AMD/Intel primary GPU


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🕹️  GAMING — Wayland gaming environment
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Steam Wayland
set -gx STEAM_FORCE_DESKTOPUI_SCALING 1
set -gx PROTON_ENABLE_WAYLAND         1   # Experimental native Wayland for Proton

# MangoHud
command -sq mangohud \
    && set -gx MANGOHUD_CONFIG         "$XDG_CONFIG_HOME/MangoHud/MangoHud.conf"

# GameMode
command -sq gamemoded \
    && set -gx ENABLE_GAMEMODERUN      1


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔐 POLKIT — Authentication agent for Wayland
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Polkit agent is started by Hyprland autostart (see config/hypr/autostart.conf)
# Expose expected socket for tools that need it
set -gx POLKIT_AUTH_AGENT_SOCKET "$XDG_RUNTIME_DIR/polkit-agent"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📋 ENVIRONMENT EXPORT TO SYSTEMD USER SESSION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Propagate critical Wayland vars to systemd --user daemons
# (services started by systemd don't inherit shell env)
if command -sq systemctl && systemctl --user is-system-running &>/dev/null
    systemctl --user import-environment \
        WAYLAND_DISPLAY \
        DISPLAY \
        XDG_SESSION_TYPE \
        XDG_CURRENT_DESKTOP \
        XDG_SESSION_DESKTOP \
        QT_QPA_PLATFORM \
        GDK_BACKEND \
        XCURSOR_THEME \
        XCURSOR_SIZE \
        LIBVA_DRIVER_NAME \
        HYPRCURSOR_THEME \
        HYPRCURSOR_SIZE \
        HYPRLAND_INSTANCE_SIGNATURE \
        ASH_CURRENT_THEME \
        ASH_CURRENT_MODE \
        ASH_GPU_VENDOR \
        2>/dev/null

    # Update dbus activation environment
    command -sq dbus-update-activation-environment \
        && dbus-update-activation-environment --systemd \
            WAYLAND_DISPLAY \
            DISPLAY \
            XDG_SESSION_TYPE \
            XDG_CURRENT_DESKTOP \
            QT_QPA_PLATFORM \
            GDK_BACKEND \
            HYPRLAND_INSTANCE_SIGNATURE \
            2>/dev/null
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🩺 WAYLAND DIAGNOSTICS — Available via `ash doctor --check wayland`
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Write session info to state file for doctor reads
if test $__ash_is_wayland -eq 1
    set -l __wayland_state_file "$ASH_STATE/wayland.json"
    printf '{"compositor":"%s","gpu_vendor":"%s","gpu_driver":"%s","hidpi":%s,"display":"%s","timestamp":"%s"}\n' \
        (test $__ash_is_hyprland -eq 1 && echo "hyprland" || echo "other") \
        $__ash_gpu_vendor \
        $__ash_gpu_driver \
        (test $__ash_hidpi -eq 1 && echo "true" || echo "false") \
        "$WAYLAND_DISPLAY" \
        (date -Iseconds 2>/dev/null || date) \
        > $__wayland_state_file 2>/dev/null
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧹 CLEANUP — Remove temporary variables
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -e __ash_is_wayland
set -e __ash_is_hyprland
set -e __ash_is_sway
set -e __ash_is_gnome_wayland
set -e __ash_is_kde_wayland
set -e __ash_is_x11
set -e __ash_is_ssh
set -e __ash_gpu_vendor
set -e __ash_gpu_driver
set -e __ash_hidpi
set -e __scale
set -e __electron_flags_dir
set -e __wayland_state_file