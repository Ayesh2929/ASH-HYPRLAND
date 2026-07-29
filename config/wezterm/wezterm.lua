-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  ASH DOTFILES v5.0 OMEGA — WEZTERM ULTRA CONFIGURATION                   ║
-- ║                                                                            ║
-- ║  ██╗░░░░░░█████╗░███████╗████████╗███████╗██████╗░███╗░░░███╗            ║
-- ║  ██║░░░░░██╔══██╗╚════██║╚══██╔══╝██╔════╝██╔══██╗████╗░████║           ║
-- ║  ██║░░░░░███████║░░███╔═╝░░░██║░░░█████╗░░██████╔╝██╔████╔██║           ║
-- ║  ██║░░░░░██╔══██║██╔══╝░░░░░██║░░░██╔══╝░░██╔══██╗██║╚██╔╝██║           ║
-- ║  ███████╗██║░░██║███████╗░░░██║░░░███████╗██║░░██║██║░╚═╝░██║           ║
-- ║  ╚══════╝╚═╝░░╚═╝╚══════╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝           ║
-- ║                                                                            ║
-- ║  GPU-Accelerated Terminal — ASH Integration                               ║
-- ║  Features: Wayland-native • True color • Ligatures • Tab bar             ║
-- ║            Multiplexing • SSH • GPU rendering • Animations               ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

local wezterm = require "wezterm"
local act     = wezterm.action
local mux     = wezterm.mux

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  UTILITY FUNCTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- Check if running on Wayland
local function is_wayland()
    return os.getenv("WAYLAND_DISPLAY") ~= nil
end

--- Get current ASH theme from state file
--- @return string  Theme name
local function get_ash_theme()
    local f = io.open(os.getenv("HOME") .. "/.config/ash/state/current-theme.json", "r")
    if not f then return "catppuccin-mocha" end
    local content = f:read("*all")
    f:close()
    -- Simple JSON field extraction (no json lib needed)
    local name = content:match('"name"%s*:%s*"([^"]+)"')
    return name or "catppuccin-mocha"
end

--- Get current ASH mode
--- @return string  Mode name
local function get_ash_mode()
    local f = io.open(os.getenv("HOME") .. "/.config/ash/state/current-mode.json", "r")
    if not f then return "default" end
    local content = f:read("*all")
    f:close()
    local mode = content:match('"mode"%s*:%s*"([^"]+)"')
    return mode or "default"
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  STARTUP HOOK
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

wezterm.on("gui-startup", function(cmd)
    local tab, pane, window = mux.spawn_window(cmd or {})

    -- Maximize window on startup
    window:gui_window():maximize()
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  DYNAMIC TITLE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

wezterm.on("format-window-title", function(tab, pane, tabs, panes, config)
    local zoomed = ""
    if tab.active_pane.is_zoomed then
        zoomed = "󰍉  "
    end

    local index = ""
    if #tabs > 1 then
        index = string.format("[%d/%d] ", tab.tab_index + 1, #tabs)
    end

    return string.format("%s%s%s", zoomed, index, tab.active_pane.title)
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TAB BAR RENDERING — Premium Catppuccin Mocha tab bar
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Catppuccin Mocha palette (module-level)
local palette = {
    crust    = "#11111b",
    mantle   = "#181825",
    base     = "#1e1e2e",
    surface0 = "#313244",
    surface1 = "#45475a",
    surface2 = "#585b70",
    overlay0 = "#6c7086",
    overlay1 = "#7f849c",
    overlay2 = "#9399b2",
    subtext0 = "#a6adc8",
    subtext1 = "#bac2de",
    text     = "#cdd6f4",
    lavender = "#b4befe",
    blue     = "#89b4fa",
    sapphire = "#74c7ec",
    sky      = "#89dceb",
    teal     = "#94e2d5",
    green    = "#a6e3a1",
    yellow   = "#f9e2af",
    peach    = "#fab387",
    maroon   = "#eba0ac",
    red      = "#f38ba8",
    mauve    = "#cba6f7",
    pink     = "#f5c2e7",
    flamingo = "#f2cdcd",
    rosewater = "#f5e0dc",
}

--- Format a single tab for the tab bar
--- @param tab table  Tab information from WezTerm
--- @param tabs table  All tabs
--- @param panes table  All panes
--- @param config table  Config object
--- @param hover boolean  Is this tab being hovered?
--- @param max_width number  Max tab width
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    local is_active = tab.is_active

    -- Tab title (process name or title, truncated)
    local title = tab.tab_title
    if not title or #title == 0 then
        title = tab.active_pane.title
    end

    -- Truncate long titles
    if #title > max_width - 6 then
        title = wezterm.truncate_right(title, max_width - 7) .. "…"
    end

    -- Tab index (1-based display)
    local index = string.format("%d", tab.tab_index + 1)

    -- Zoom indicator
    local zoom = tab.active_pane.is_zoomed and "󰍉 " or ""

    -- Process icon based on running program
    local pane = tab.active_pane
    local process = pane.foreground_process_name or ""
    local icon = "  "

    if     process:find("nvim")    then icon = "  "
    elseif process:find("vim")     then icon = "  "
    elseif process:find("fish")    then icon = " 󰈺 "
    elseif process:find("bash")    then icon = "  "
    elseif process:find("zsh")     then icon = "  "
    elseif process:find("python")  then icon = "  "
    elseif process:find("node")    then icon = "  "
    elseif process:find("cargo")   then icon = "  "
    elseif process:find("git")     then icon = "  "
    elseif process:find("lazygit") then icon = "  "
    elseif process:find("btop")    then icon = " 󰨟 "
    elseif process:find("htop")    then icon = " 󰨟 "
    elseif process:find("yazi")    then icon = " 󰉋 "
    elseif process:find("ssh")     then icon = " 󰣀 "
    elseif process:find("docker")  then icon = "  "
    elseif process:find("kubectl") then icon = " 󱃾 "
    elseif process:find("make")    then icon = "  "
    end

    -- Build tab format
    if is_active then
        return {
            { Background = { Color = palette.mauve  } },
            { Foreground = { Color = palette.base   } },
            { Text = string.format(" %s%s%s%s ", index, icon, zoom, title) },
        }
    elseif hover then
        return {
            { Background = { Color = palette.surface1 } },
            { Foreground = { Color = palette.subtext1  } },
            { Text = string.format(" %s%s%s%s ", index, icon, zoom, title) },
        }
    else
        return {
            { Background = { Color = palette.surface0  } },
            { Foreground = { Color = palette.overlay1   } },
            { Text = string.format(" %s%s%s%s ", index, icon, zoom, title) },
        }
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  STATUS BAR (RIGHT) — System info displayed in tab bar right side
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

wezterm.on("update-status", function(window, pane)
    -- Get battery information
    local battery_info = ""
    local batteries = wezterm.battery_info()
    if batteries and #batteries > 0 then
        local bat = batteries[1]
        local pct = math.floor(bat.state_of_charge * 100)
        local icon

        if bat.state == "Charging" then
            icon = pct >= 80 and "󰂅" or pct >= 60 and "󰂄" or pct >= 40 and "󰂃" or "󰂆"
            battery_info = string.format(" %s %d%%", icon, pct)
        else
            icon = pct >= 90 and "󰁹" or pct >= 75 and "󰂂" or pct >= 60 and "󰂁"
                or pct >= 45 and "󰁿" or pct >= 30 and "󰁽" or pct >= 15 and "󰁻" or "󰁺"
            battery_info = string.format(" %s %d%%", icon, pct)
        end
    end

    -- Date and time
    local date  = wezterm.strftime " 󰨲 %a %d %b"
    local time  = wezterm.strftime " 󱑍 %H:%M "

    -- ASH mode indicator
    local ash_mode = os.getenv("ASH_MODE") or ""
    local mode_str = ""
    if ash_mode ~= "" and ash_mode ~= "default" then
        local mode_icons = {
            game        = "󰊗",
            focus       = "󰱫",
            work        = "󰒲",
            cinema      = "󰚺",
            battery     = "󰁻",
            stream      = "󰑊",
            privacy     = "󰌾",
            present     = "󰋛",
        }
        local mi = mode_icons[ash_mode] or "󰮔"
        mode_str = string.format(" %s %s ", mi, ash_mode)
    end

    -- Leader key indicator
    local leader_str = ""
    if window:leader_is_active() then
        leader_str = " ⌨ "
    end

    -- Compose right status
    window:set_right_status(wezterm.format {
        -- Leader indicator
        { Background = { Color = palette.mauve   } },
        { Foreground = { Color = palette.base    } },
        { Attribute  = { Intensity = "Bold"      } },
        { Text       = leader_str                  },

        -- Mode indicator
        { Background = { Color = palette.peach   } },
        { Foreground = { Color = palette.base    } },
        { Text       = mode_str                    },

        -- Battery
        { Background = { Color = palette.surface1 } },
        { Foreground = { Color = palette.subtext0  } },
        { Text       = battery_info                  },

        -- Date
        { Background = { Color = palette.surface0 } },
        { Foreground = { Color = palette.subtext1  } },
        { Text       = date                          },

        -- Time
        { Background = { Color = palette.blue     } },
        { Foreground = { Color = palette.base     } },
        { Attribute  = { Intensity = "Bold"       } },
        { Text       = time                          },
    })
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  BUILD CONFIGURATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local config = wezterm.config_builder()

-- ── Load Dynamic Theme ────────────────────────────────────────────────────────
local ash_theme = require("themes/ash-dynamic")
ash_theme.apply(config, palette)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  🖥️  RENDERING — GPU acceleration
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- GPU rendering backend
-- "WebGpu" = best cross-platform | "Gl" = OpenGL | "Cpu" = software fallback
config.front_end = "WebGpu"

-- GPU adapter preference
-- "HighPerformance" = dedicated GPU | "LowPower" = integrated | "None" = auto
config.webgpu_power_preference = "HighPerformance"

-- Force use of specific GPU (useful for multi-GPU systems)
-- config.webgpu_preferred_adapter = ...

-- Anti-aliasing for text rendering
-- "None" | "Grayscale" | "Subpixel"
-- Use "Grayscale" for most displays, "Subpixel" only for non-HiDPI LCDs
config.freetype_load_target    = "Light"
config.freetype_render_target  = "HorizontalLcd"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  🔠  FONTS — Premium monospace configuration
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Primary font (priority: JetBrainsMono → CaskaydiaCove → FiraCode → fallback)
config.font = wezterm.font_with_fallback {
    -- Primary: JetBrainsMono Nerd Font — excellent ligatures + Nerd Fonts
    {
        family   = "JetBrainsMono Nerd Font",
        weight   = "Regular",
        harfbuzz_features = {
            "calt=1",  -- Contextual alternates (ligatures)
            "clig=1",  -- Contextual ligatures
            "liga=1",  -- Standard ligatures
            "zero=1",  -- Slashed zero (distinguishes 0 from O)
            "ss19=1",  -- Script-specific
        },
    },
    -- Secondary: CaskaydiaCove (Cascadia Code with NF patches)
    {
        family   = "CaskaydiaCove Nerd Font",
        weight   = "Regular",
    },
    -- Tertiary: FiraCode
    {
        family   = "FiraCode Nerd Font",
        weight   = "Regular",
    },
    -- Emoji fallback
    { family = "Noto Color Emoji"         },
    { family = "Twitter Color Emoji"      },
    -- Symbol fallback
    { family = "Symbols Nerd Font Mono"   },
    { family = "Noto Sans Symbols"        },
    { family = "Noto Sans Symbols 2"      },
}

-- Font size (pixels)
config.font_size = 13.0

-- Line height (1.0 = default, 1.1 = slightly more spacious)
config.line_height = 1.1

-- Cell width scaling (0.9 = slightly narrower, good for dense info)
config.cell_width = 1.0

-- Bold font weights
config.bold_brightens_ansi_colors = "BrightAndBold"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  🪟  WINDOW — Appearance and behavior
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── Window Decorations ────────────────────────────────────────────────────────
-- "TITLE"       = system title bar only
-- "RESIZE"      = resize handles only
-- "NONE"        = no decorations (Hyprland handles window chrome)
-- "TITLE|RESIZE"= both
config.window_decorations = "NONE"

-- ── Padding ───────────────────────────────────────────────────────────────────
config.window_padding = {
    left   = 14,
    right  = 14,
    top    = 10,
    bottom = 10,
}

-- ── Background ────────────────────────────────────────────────────────────────
-- Translucency: 0.0 = fully transparent, 1.0 = fully opaque
-- Pair with Hyprland blur for glassmorphism effect
config.window_background_opacity = 0.92

-- Text background opacity (independent from window)
config.text_background_opacity = 1.0

-- ── Blur (handled by Hyprland) ────────────────────────────────────────────────
-- If using macOS:
-- config.macos_window_background_blur = 20

-- ── Window Close Confirmation ─────────────────────────────────────────────────
-- "AlwaysPrompt" | "NeverPrompt" | "OnlyIfActivePaneWasRunningAnApplication"
config.window_close_confirmation = "NeverPrompt"

-- ── Initial window size ───────────────────────────────────────────────────────
config.initial_cols = 220
config.initial_rows = 50

-- ── Window frame ─────────────────────────────────────────────────────────────
config.window_frame = {
    -- Font for system tab bar (if using system decorations)
    font = wezterm.font { family = "Inter", weight = "Bold" },
    font_size = 12.0,

    -- Tab bar colors
    active_titlebar_bg   = palette.mantle,
    inactive_titlebar_bg = palette.crust,
    active_titlebar_fg   = palette.text,
    inactive_titlebar_fg = palette.overlay0,
    button_fg            = palette.overlay1,
    button_bg            = palette.mantle,
    button_hover_fg      = palette.text,
    button_hover_bg      = palette.surface0,
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  📑  TAB BAR
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Use retro tab bar (allows full customization via format-tab-title)
-- "Fancy" = modern look | "Retro" = fully customizable
config.use_fancy_tab_bar = false

-- Show tab bar
config.enable_tab_bar = true

-- Hide tab bar when only one tab
config.hide_tab_bar_if_only_one_tab = false

-- Tab bar position: "Top" | "Bottom"
config.tab_bar_at_bottom = false

-- Tab max width (characters)
config.tab_max_width = 28

-- Show new tab button in tab bar
config.show_new_tab_button_in_tab_bar = true

-- Show close buttons in tabs
config.show_close_tab_button_in_tabs = true

-- Tab colors (overridden by format-tab-title event)
config.colors = {
    tab_bar = {
        background         = palette.mantle,
        new_tab            = { bg_color = palette.surface0, fg_color = palette.overlay1 },
        new_tab_hover      = { bg_color = palette.surface1, fg_color = palette.text     },
        active_tab         = { bg_color = palette.mauve,    fg_color = palette.base,    intensity = "Bold" },
        inactive_tab       = { bg_color = palette.surface0, fg_color = palette.overlay1 },
        inactive_tab_hover = { bg_color = palette.surface1, fg_color = palette.subtext1 },
        inactive_tab_edge  = palette.mantle,
    },
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  🖱️  MOUSE — Mouse behavior
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Hide mouse cursor when typing
config.hide_mouse_cursor_when_typing = true

-- Copy on select (without needing Ctrl+C)
config.copy_on_select = false

-- Default selection behavior
config.default_cursor_style = "BlinkingBar"

-- Cursor blink rate (ms)
config.cursor_blink_rate = 800

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  📜  SCROLLBACK — Buffer configuration
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Scrollback buffer lines
config.scrollback_lines = 10000

-- Enable scroll bar (right side)
config.enable_scroll_bar = false

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  🐚  SHELL & PROGRAMS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Default shell
config.default_prog = { "/usr/bin/fish", "-l" }

-- SSH backend
-- "Ssh2" | "LibSsh"
config.ssh_backend = "Ssh2"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  🔗  HYPERLINKS — URL detection and opening
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Enable automatic hyperlink detection
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- Add custom URL patterns
table.insert(config.hyperlink_rules, {
    -- Git shorthand: user/repo
    regex   = [[\b([a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+)\b]],
    format  = "https://github.com/$1",
})

table.insert(config.hyperlink_rules, {
    -- Issue numbers: #123
    regex  = [[\b#(\d+)\b]],
    format = "https://github.com/issues/$1",
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  ⌨️  KEYBINDINGS — Comprehensive key configuration
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Disable default keybindings (use our own complete set)
config.disable_default_key_bindings = true

-- Leader key: Ctrl+a (like tmux)
-- Press leader then another key for two-key bindings
config.leader = {
    key     = "a",
    mods    = "CTRL",
    timeout_milliseconds = 2000,
}

config.keys = {

    -- ── Clipboard ─────────────────────────────────────────────────────────

    { key = "c",          mods = "CTRL|SHIFT",  action = act.CopyTo "Clipboard"           },
    { key = "v",          mods = "CTRL|SHIFT",  action = act.PasteFrom "Clipboard"        },
    { key = "Insert",     mods = "CTRL",        action = act.CopyTo "PrimarySelection"    },
    { key = "Insert",     mods = "SHIFT",       action = act.PasteFrom "PrimarySelection" },

    -- ── Tab Management ────────────────────────────────────────────────────

    { key = "t",          mods = "CTRL|SHIFT",  action = act.SpawnTab "CurrentPaneDomain" },
    { key = "w",          mods = "CTRL|SHIFT",  action = act.CloseCurrentTab { confirm = false } },
    { key = "Tab",        mods = "CTRL",        action = act.ActivateTabRelative(1)        },
    { key = "Tab",        mods = "CTRL|SHIFT",  action = act.ActivateTabRelative(-1)       },
    { key = "PageUp",     mods = "CTRL|SHIFT",  action = act.ActivateTabRelative(-1)       },
    { key = "PageDown",   mods = "CTRL|SHIFT",  action = act.ActivateTabRelative(1)        },

    -- Tab number shortcuts
    { key = "1", mods = "ALT", action = act.ActivateTab(0) },
    { key = "2", mods = "ALT", action = act.ActivateTab(1) },
    { key = "3", mods = "ALT", action = act.ActivateTab(2) },
    { key = "4", mods = "ALT", action = act.ActivateTab(3) },
    { key = "5", mods = "ALT", action = act.ActivateTab(4) },
    { key = "6", mods = "ALT", action = act.ActivateTab(5) },
    { key = "7", mods = "ALT", action = act.ActivateTab(6) },
    { key = "8", mods = "ALT", action = act.ActivateTab(7) },
    { key = "9", mods = "ALT", action = act.ActivateTab(-1) },

    -- Move tabs
    { key = "PageUp",   mods = "CTRL|ALT", action = act.MoveTabRelative(-1) },
    { key = "PageDown", mods = "CTRL|ALT", action = act.MoveTabRelative(1)  },

    -- ── Pane Splitting ────────────────────────────────────────────────────

    { key = "|",  mods = "CTRL|SHIFT",
      action = act.SplitHorizontal { domain = "CurrentPaneDomain" }          },
    { key = "_",  mods = "CTRL|SHIFT",
      action = act.SplitVertical { domain = "CurrentPaneDomain" }             },
    { key = "\\", mods = "CTRL|SHIFT",
      action = act.SplitHorizontal { domain = "CurrentPaneDomain" }          },
    { key = "-",  mods = "CTRL|SHIFT",
      action = act.SplitVertical { domain = "CurrentPaneDomain" }             },

    -- ── Pane Navigation ───────────────────────────────────────────────────

    { key = "h",    mods = "ALT",       action = act.ActivatePaneDirection "Left"  },
    { key = "j",    mods = "ALT",       action = act.ActivatePaneDirection "Down"  },
    { key = "k",    mods = "ALT",       action = act.ActivatePaneDirection "Up"    },
    { key = "l",    mods = "ALT",       action = act.ActivatePaneDirection "Right" },
    { key = "Left",  mods = "ALT",      action = act.ActivatePaneDirection "Left"  },
    { key = "Down",  mods = "ALT",      action = act.ActivatePaneDirection "Down"  },
    { key = "Up",    mods = "ALT",      action = act.ActivatePaneDirection "Up"    },
    { key = "Right", mods = "ALT",      action = act.ActivatePaneDirection "Right" },

    -- ── Pane Resize ───────────────────────────────────────────────────────

    { key = "H", mods = "ALT|SHIFT",    action = act.AdjustPaneSize { "Left",  5 } },
    { key = "J", mods = "ALT|SHIFT",    action = act.AdjustPaneSize { "Down",  5 } },
    { key = "K", mods = "ALT|SHIFT",    action = act.AdjustPaneSize { "Up",    5 } },
    { key = "L", mods = "ALT|SHIFT",    action = act.AdjustPaneSize { "Right", 5 } },

    -- ── Pane Zoom ─────────────────────────────────────────────────────────

    { key = "z",  mods = "CTRL|SHIFT",  action = act.TogglePaneZoomState },
    { key = "x",  mods = "CTRL|SHIFT",  action = act.CloseCurrentPane { confirm = false } },

    -- ── Scrollback ────────────────────────────────────────────────────────

    { key = "PageUp",   mods = "SHIFT", action = act.ScrollByPage(-1) },
    { key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1)  },
    { key = "Home",     mods = "SHIFT", action = act.ScrollToTop      },
    { key = "End",      mods = "SHIFT", action = act.ScrollToBottom   },
    { key = "k",   mods = "CTRL|SHIFT", action = act.ScrollByLine(-1) },
    { key = "j",   mods = "CTRL|SHIFT", action = act.ScrollByLine(1)  },
    { key = "u",   mods = "CTRL|SHIFT", action = act.ScrollByPage(-0.5) },
    { key = "d",   mods = "CTRL|SHIFT", action = act.ScrollByPage(0.5)  },

    -- ── Search ────────────────────────────────────────────────────────────

    { key = "f",    mods = "CTRL|SHIFT",
      action = act.Search { CaseInSensitiveString = "" }                       },
    { key = "r",    mods = "CTRL|SHIFT",
      action = act.Search { Regex = "" }                                        },

    -- ── Font Size ─────────────────────────────────────────────────────────

    { key = "+",    mods = "CTRL",      action = act.IncreaseFontSize           },
    { key = "-",    mods = "CTRL",      action = act.DecreaseFontSize           },
    { key = "=",    mods = "CTRL",      action = act.ResetFontSize              },
    { key = "0",    mods = "CTRL",      action = act.ResetFontSize              },

    -- ── Copy Mode ─────────────────────────────────────────────────────────

    { key = "[",    mods = "CTRL|SHIFT", action = act.ActivateCopyMode          },

    -- ── Quick Select ──────────────────────────────────────────────────────
    -- Highlight text patterns for fast copy
    { key = "Space", mods = "CTRL|SHIFT", action = act.QuickSelect              },

    -- ── Command Palette ───────────────────────────────────────────────────

    { key = "p",    mods = "CTRL|SHIFT", action = act.ActivateCommandPalette    },

    -- ── Launcher ──────────────────────────────────────────────────────────

    { key = "l",    mods = "CTRL|SHIFT",
      action = act.ShowLauncherArgs { flags = "FUZZY|TABS|LAUNCH_MENU_ITEMS" }  },

    -- ── Window ────────────────────────────────────────────────────────────

    { key = "n",    mods = "CTRL|SHIFT", action = act.SpawnWindow               },
    { key = "m",    mods = "CTRL|SHIFT",
      action = act.ToggleFullScreen                                              },
    { key = "F11",  mods = "NONE",       action = act.ToggleFullScreen          },

    -- ── Reload Config ─────────────────────────────────────────────────────

    { key = "r",    mods = "CTRL|SHIFT|ALT",
      action = act.ReloadConfiguration                                           },

    -- ── Debug ─────────────────────────────────────────────────────────────

    { key = "i",    mods = "CTRL|SHIFT",
      action = act.ShowDebugOverlay                                              },

    -- ── Leader-based bindings ─────────────────────────────────────────────

    -- Leader + g: open lazygit
    { key = "g",    mods = "LEADER",
      action = act.SpawnCommandInNewTab {
          args = { "/usr/bin/fish", "-c", "lazygit" },
      }
    },

    -- Leader + t: open btop
    { key = "t",    mods = "LEADER",
      action = act.SpawnCommandInNewTab {
          args = { "/usr/bin/fish", "-c", "btop" },
      }
    },

    -- Leader + y: open yazi
    { key = "y",    mods = "LEADER",
      action = act.SpawnCommandInNewTab {
          args = { "/usr/bin/fish", "-c", "yazi" },
      }
    },

    -- Leader + T: ASH theme picker
    { key = "T",    mods = "LEADER",
      action = act.SpawnCommandInNewTab {
          args = { "/usr/bin/fish", "-c", "ash theme pick" },
      }
    },

    -- Leader + r: reload wezterm config
    { key = "r",    mods = "LEADER",
      action = act.ReloadConfiguration
    },

    -- Leader + e: edit wezterm config
    { key = "e",    mods = "LEADER",
      action = act.SpawnCommandInNewTab {
          args = { "/usr/bin/fish", "-c",
                   "nvim ~/.config/wezterm/wezterm.lua" },
      }
    },
}

-- ── Mouse Bindings ─────────────────────────────────────────────────────────

config.mouse_bindings = {

    -- Ctrl+click to open URLs
    {
        event  = { Up = { streak = 1, button = "Left" } },
        mods   = "CTRL",
        action = act.OpenLinkAtMouseCursor,
    },

    -- Right-click to paste
    {
        event  = { Down = { streak = 1, button = "Right" } },
        mods   = "NONE",
        action = act.PasteFrom "Clipboard",
    },

    -- Double-click to select word
    {
        event  = { Down = { streak = 2, button = "Left" } },
        mods   = "NONE",
        action = act.SelectTextAtMouseCursor "Word",
    },

    -- Triple-click to select line
    {
        event  = { Down = { streak = 3, button = "Left" } },
        mods   = "NONE",
        action = act.SelectTextAtMouseCursor "Line",
    },

    -- Scroll up
    {
        event  = { Down = { streak = 1, button = { WheelUp = 1 } } },
        mods   = "NONE",
        action = act.ScrollByLine(-3),
    },

    -- Scroll down
    {
        event  = { Down = { streak = 1, button = { WheelDown = 1 } } },
        mods   = "NONE",
        action = act.ScrollByLine(3),
    },
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  📋  LAUNCH MENU — Quick program launcher
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

config.launch_menu = {
    { label = "  Fish Shell",     args = { "fish" }                          },
    { label = "  Bash",           args = { "bash" }                          },
    { label = "  Neovim",        args = { "fish", "-c", "nvim" }            },
    { label = "  Lazygit",       args = { "fish", "-c", "lazygit" }         },
    { label = " 󰨟 Btop",          args = { "fish", "-c", "btop" }            },
    { label = " 󰉋 Yazi",          args = { "fish", "-c", "yazi" }            },
    { label = "  Python REPL",   args = { "fish", "-c", "python3" }         },
    { label = "  SSH Connect",   args = { "fish", "-c", "ssh" }             },
    { label = " ✨ ASH Config",   args = { "fish", "-c", "ash config edit" } },
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  🔔  BELL — Notification on terminal bell
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- "Disabled" | "SystemBeep" | "Visual" | { Audio = {...}, Visual = {} }
config.audible_bell = "Disabled"
config.visual_bell = {
    fade_in_function   = "EaseIn",
    fade_in_duration_ms  = 150,
    fade_out_function  = "EaseOut",
    fade_out_duration_ms = 150,
    target             = "BackgroundColor",
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  🌐  WAYLAND — Wayland-specific settings
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if is_wayland() then
    -- Enable Wayland (prefer over X11)
    config.enable_wayland = true

    -- Wayland-specific: use IME for CJK input
    config.use_ime = true

    -- DPI detection for HiDPI Wayland displays
    config.dpi = 96.0
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  🔧  MISC — Various settings
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Automatically check for updates
config.check_for_updates                    = false

-- Prefer EGL over GLX on Linux
config.prefer_egl                          = true

-- Term name reported to applications
config.term                                = "wezterm"

-- Detect if the running program has exited and close the tab
config.exit_behavior                       = "CloseOnCleanExit"

-- Delay before closing tab after command exits (ms)
config.exit_behavior_messaging             = "Brief"

-- Max frames per second (limit for battery savings)
config.max_fps                             = 60

-- Animation FPS
config.animation_fps                       = 60

-- Quick select patterns for fast text extraction
config.quick_select_patterns = {
    -- Git hashes
    "[0-9a-f]{7,40}",
    -- File paths
    "(?:[~/.]?[\\w./\\-]+(?:\\.\\w+)?)",
    -- URLs
    "https?://\\S+",
    -- IP addresses
    "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}",
    -- Email addresses
    "[\\w.]+@[\\w.]+\\.\\w+",
    -- UUIDs
    "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
}

return config