-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — WEZTERM CONFIGURATION                        ║
-- ║           GPU-accelerated terminal with dynamic theme support              ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

local wezterm = require("wezterm")
local act     = wezterm.action
local mux     = wezterm.mux

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🎨 DYNAMIC COLOR LOADING
-- ═══════════════════════════════════════════════════════════════════════════════

local function load_ash_colors()
    local home    = os.getenv("HOME") or ""
    local cache   = home .. "/.cache/ash-dots/colors/current.json"

    -- Default palette (Catppuccin Mocha)
    local defaults = {
        base      = "#1e1e2e",
        mantle    = "#181825",
        crust     = "#11111b",
        surface0  = "#313244",
        surface1  = "#45475a",
        surface2  = "#585b70",
        overlay0  = "#6c7086",
        overlay1  = "#7f849c",
        primary   = "#cba6f7",
        secondary = "#89b4fa",
        tertiary  = "#94e2d5",
        text      = "#cdd6f4",
        subtext1  = "#bac2de",
        subtext0  = "#a6adc8",
        success   = "#a6e3a1",
        warning   = "#f9e2af",
        error     = "#f38ba8",
        info      = "#89b4fa",
    }

    -- Try to load from cache
    local f = io.open(cache, "r")
    if not f then
        return defaults
    end

    local content = f:read("*all")
    f:close()

    if not content or content == "" then
        return defaults
    end

    -- Parse JSON manually (basic extraction)
    local colors = {}
    for key, val in content:gmatch('"([%w]+)"%s*:%s*"(#[%x]+)"') do
        colors[key] = val
    end

    -- Merge with defaults
    return setmetatable(colors, { __index = defaults })
end

local C = load_ash_colors()

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🎨 COLOR SCHEME
-- ═══════════════════════════════════════════════════════════════════════════════

local color_scheme = {
    foreground            = C.text,
    background            = C.base,

    cursor_bg             = C.primary,
    cursor_fg             = C.base,
    cursor_border         = C.primary,

    selection_fg          = C.text,
    selection_bg          = C.surface1,

    scrollbar_thumb       = C.surface1,
    split                 = C.overlay0,

    -- ANSI colors (16 terminal colors)
    ansi = {
        C.crust,      -- Black
        C.error,      -- Red
        C.success,    -- Green
        C.warning,    -- Yellow
        C.info,       -- Blue
        C.primary,    -- Magenta
        C.tertiary,   -- Cyan
        C.subtext0,   -- White
    },
    brights = {
        C.surface1,   -- Bright Black
        C.error,      -- Bright Red
        C.success,    -- Bright Green
        C.warning,    -- Bright Yellow
        C.secondary,  -- Bright Blue
        C.primary,    -- Bright Magenta
        C.tertiary,   -- Bright Cyan
        C.text,       -- Bright White
    },

    -- Tab bar colors
    tab_bar = {
        background = C.mantle,
        active_tab = {
            bg_color  = C.primary,
            fg_color  = C.base,
            intensity = "Bold",
        },
        inactive_tab = {
            bg_color  = C.surface0,
            fg_color  = C.subtext0,
        },
        inactive_tab_hover = {
            bg_color  = C.surface1,
            fg_color  = C.text,
        },
        new_tab = {
            bg_color  = C.mantle,
            fg_color  = C.subtext1,
        },
        new_tab_hover = {
            bg_color  = C.primary,
            fg_color  = C.base,
        },
    },
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ⚙️ MAIN CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════════════════

local config = wezterm.config_builder()

-- ── Appearance ─────────────────────────────────────────────────────────────────
config.color_schemes           = { ["ASH Dynamic"] = color_scheme }
config.color_scheme            = "ASH Dynamic"
config.window_background_opacity = 0.92
config.text_background_opacity = 1.0
config.macos_window_background_blur = 30  -- macOS only

-- Window decorations
config.window_decorations      = "RESIZE"
config.window_padding          = {
    left   = 14,
    right  = 14,
    top    = 10,
    bottom = 10,
}

-- ── Fonts ──────────────────────────────────────────────────────────────────────
config.font = wezterm.font_with_fallback({
    {
        family   = "JetBrainsMono Nerd Font",
        weight   = "Regular",
        harfbuzz_features = {
            "zero=1",   -- Slashed zero
            "ss01=1",   -- Alternative character set 1
            "ss02=1",   -- Alternative character set 2
            "calt=1",   -- Contextual alternates (ligatures)
        },
    },
    "Noto Color Emoji",
    "Symbols Nerd Font Mono",
})

config.font_size               = 12.0
config.bold_brightens_ansi_colors = true
config.line_height             = 1.1
config.cell_width              = 1.0

-- Font for specific rules
config.font_rules = {
    {
        intensity = "Bold",
        font      = wezterm.font("JetBrainsMono Nerd Font", { weight = "Bold" }),
    },
    {
        italic = true,
        font   = wezterm.font("JetBrainsMono Nerd Font", { italic = true }),
    },
    {
        intensity = "Bold",
        italic    = true,
        font      = wezterm.font("JetBrainsMono Nerd Font", { weight = "Bold", italic = true }),
    },
}

-- ── Cursor ─────────────────────────────────────────────────────────────────────
config.default_cursor_style    = "BlinkingBar"
config.cursor_blink_rate       = 500
config.cursor_blink_ease_in    = "Linear"
config.cursor_blink_ease_out   = "Linear"
config.cursor_thickness        = 2

-- ── Performance ────────────────────────────────────────────────────────────────
config.front_end               = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.animation_fps           = 60
config.max_fps                 = 144

-- ── Scrollback ─────────────────────────────────────────────────────────────────
config.scrollback_lines        = 10000
config.enable_scroll_bar       = false

-- ── Tab bar ────────────────────────────────────────────────────────────────────
config.use_fancy_tab_bar       = false
config.tab_bar_at_bottom       = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_max_width           = 32
config.show_tab_index_in_tab_bar = false

-- Tab title format
wezterm.on("format-tab-title", function(tab, tabs, panes, cfg, hover, max_width)
    local pane   = tab.active_pane
    local title  = pane.title
    local icon   = "  "

    -- Shorten title
    if #title > 20 then
        title = title:sub(1, 19) .. "…"
    end

    -- Process indicators
    local process = pane.foreground_process_name or ""
    if process:find("nvim") then        icon = "  "
    elseif process:find("fish") then    icon = "  "
    elseif process:find("git") then     icon = "  "
    elseif process:find("ssh") then     icon = "  "
    elseif process:find("python") then  icon = "  "
    elseif process:find("cargo") then   icon = "  "
    end

    local prefix = tab.is_active and "▌ " or "  "

    return {
        { Text = prefix .. icon .. title .. "  " },
    }
end)

-- ── Multiplexer ────────────────────────────────────────────────────────────────
config.enable_wayland          = true

-- ── Bell ───────────────────────────────────────────────────────────────────────
config.audible_bell            = "Disabled"
config.visual_bell = {
    fade_in_duration_ms  = 75,
    fade_out_duration_ms = 75,
    target               = "CursorColor",
}

-- ── Hyperlinks ─────────────────────────────────────────────────────────────────
config.hyperlink_rules         = wezterm.default_hyperlink_rules()
-- Add custom hyperlink rules
table.insert(config.hyperlink_rules, {
    regex  = [[\b[tT]asks?:? #(\d+)\b]],
    format = "https://github.com/issues/$1",
})

-- ── Shell Integration ──────────────────────────────────────────────────────────
config.set_environment_variables = {
    TERM           = "xterm-256color",
    COLORTERM      = "truecolor",
    TERM_PROGRAM   = "WezTerm",
}

-- Default shell
config.default_prog = { "/usr/bin/fish", "-l" }

-- ═══════════════════════════════════════════════════════════════════════════════
-- ⌨️ KEYBINDS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Leader key (CTRL+A like tmux, but not intercepted unless double-pressed)
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
    -- ── Copy/Paste ──────────────────────────────────────────────────────────
    { key = "c",         mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
    { key = "v",         mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
    { key = "v",         mods = "CTRL|SHIFT", action = act.PasteFrom("PrimarySelection") },

    -- ── Tabs ────────────────────────────────────────────────────────────────
    { key = "t",         mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
    { key = "w",         mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
    { key = "Tab",       mods = "CTRL",        action = act.ActivateTabRelative(1) },
    { key = "Tab",       mods = "CTRL|SHIFT",  action = act.ActivateTabRelative(-1) },
    { key = "1",         mods = "ALT",         action = act.ActivateTab(0) },
    { key = "2",         mods = "ALT",         action = act.ActivateTab(1) },
    { key = "3",         mods = "ALT",         action = act.ActivateTab(2) },
    { key = "4",         mods = "ALT",         action = act.ActivateTab(3) },
    { key = "5",         mods = "ALT",         action = act.ActivateTab(4) },

    -- ── Panes ───────────────────────────────────────────────────────────────
    { key = "\\",        mods = "CTRL|SHIFT",  action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "-",         mods = "CTRL|SHIFT",  action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
    { key = "h",         mods = "CTRL|SHIFT",  action = act.ActivatePaneDirection("Left") },
    { key = "l",         mods = "CTRL|SHIFT",  action = act.ActivatePaneDirection("Right") },
    { key = "k",         mods = "CTRL|SHIFT",  action = act.ActivatePaneDirection("Up") },
    { key = "j",         mods = "CTRL|SHIFT",  action = act.ActivatePaneDirection("Down") },
    { key = "z",         mods = "CTRL|SHIFT",  action = act.TogglePaneZoomState },
    { key = "x",         mods = "CTRL|SHIFT",  action = act.CloseCurrentPane({ confirm = true }) },

    -- ── Font Size ───────────────────────────────────────────────────────────
    { key = "=",         mods = "CTRL",        action = act.IncreaseFontSize },
    { key = "-",         mods = "CTRL",        action = act.DecreaseFontSize },
    { key = "0",         mods = "CTRL",        action = act.ResetFontSize },

    -- ── Scrollback ──────────────────────────────────────────────────────────
    { key = "PageUp",    mods = "SHIFT",        action = act.ScrollByPage(-1) },
    { key = "PageDown",  mods = "SHIFT",        action = act.ScrollByPage(1) },
    { key = "k",         mods = "CTRL|ALT",     action = act.ScrollByLine(-5) },
    { key = "j",         mods = "CTRL|ALT",     action = act.ScrollByLine(5) },

    -- ── Opacity ─────────────────────────────────────────────────────────────
    { key = "m",         mods = "CTRL|SHIFT",  action = wezterm.action_callback(function(window, _)
        local opacity = window:get_config_overrides()
        local current = (opacity and opacity.window_background_opacity) or 0.92
        local new_opacity = math.max(0.1, current - 0.05)
        window:set_config_overrides({ window_background_opacity = new_opacity })
    end) },
    { key = "p",         mods = "CTRL|SHIFT",  action = wezterm.action_callback(function(window, _)
        local opacity = window:get_config_overrides()
        local current = (opacity and opacity.window_background_opacity) or 0.92
        local new_opacity = math.min(1.0, current + 0.05)
        window:set_config_overrides({ window_background_opacity = new_opacity })
    end) },

    -- ── Search ──────────────────────────────────────────────────────────────
    { key = "f",         mods = "CTRL|SHIFT",  action = act.Search({ CaseSensitiveString = "" }) },

    -- ── Reload Config ───────────────────────────────────────────────────────
    { key = "r",         mods = "CTRL|SHIFT",  action = act.ReloadConfiguration },

    -- ── Debug Overlay ───────────────────────────────────────────────────────
    { key = "d",         mods = "CTRL|SHIFT|ALT", action = act.ShowDebugOverlay },

    -- ── Launcher ────────────────────────────────────────────────────────────
    { key = "n",         mods = "CTRL|SHIFT",  action = act.SpawnWindow },

    -- Leader-based binds
    { key = "c",         mods = "LEADER",       action = act.SpawnTab("CurrentPaneDomain") },
    { key = "n",         mods = "LEADER",       action = act.ActivateTabRelative(1) },
    { key = "p",         mods = "LEADER",       action = act.ActivateTabRelative(-1) },
    { key = "|",         mods = "LEADER",       action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "-",         mods = "LEADER",       action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
    { key = "z",         mods = "LEADER",       action = act.TogglePaneZoomState },
    { key = "d",         mods = "LEADER",       action = act.CloseCurrentPane({ confirm = true }) },
    { key = "a",         mods = "LEADER",       action = act.SendKey({ key = "a", mods = "CTRL" }) },
}

-- Mouse binds
config.mouse_bindings = {
    -- Right click pastes
    {
        event  = { Down = { streak = 1, button = "Right" } },
        mods   = "NONE",
        action = act.PasteFrom("Clipboard"),
    },
    -- CTRL+click opens URL
    {
        event  = { Up = { streak = 1, button = "Left" } },
        mods   = "CTRL",
        action = act.OpenLinkAtMouseCursor,
    },
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔔 EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Update title with current directory
wezterm.on("update-right-status", function(window, pane)
    local cwd_uri = pane:get_current_working_dir()
    local cwd     = ""

    if cwd_uri then
        if type(cwd_uri) == "userdata" then
            cwd = cwd_uri.file_path or ""
        else
            cwd = cwd_uri:gsub("^file://[^/]*", "")
        end
        -- Shorten home
        cwd = cwd:gsub(os.getenv("HOME") or "", "~")
    end

    local date = wezterm.strftime("%H:%M")

    window:set_right_status(wezterm.format({
        { Foreground = { Color = C.overlay0 } },
        { Text = "  " .. cwd .. "  " .. date .. "  " },
    }))
end)

-- Maximize on startup
wezterm.on("gui-startup", function(cmd)
    local _, _, window = mux.spawn_window(cmd or {})
    window:gui_window():maximize()
end)

return config