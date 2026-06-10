-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — QUALITY MENU MPV SCRIPT                      ║
-- ║           Stream quality selector for YouTube and other streams            ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

--[[
    quality-menu.lua
    Provides a keybindable menu for switching video/audio quality (ytdl-format)

    Note: Full version available at:
    https://github.com/christoph-heinrich/mpv-quality-menu

    Keybind: Ctrl+F to open quality menu (configurable)
--]]

local utils  = require("mp.utils")
local msg    = require("mp.msg")

local options = {
    -- Format selection menu
    format_menu = {
        -- Video quality options
        { label = "4K (2160p)",    format = "bestvideo[height<=2160]+bestaudio/best[height<=2160]" },
        { label = "1080p HD",      format = "bestvideo[height<=1080]+bestaudio/best[height<=1080]" },
        { label = "720p HD",       format = "bestvideo[height<=720]+bestaudio/best[height<=720]"   },
        { label = "480p",          format = "bestvideo[height<=480]+bestaudio/best[height<=480]"   },
        { label = "360p",          format = "bestvideo[height<=360]+bestaudio/best[height<=360]"   },
        { label = "Audio only",    format = "bestaudio/best"                                        },
        { label = "Best (auto)",   format = "bestvideo+bestaudio/best"                              },
    },

    -- Keybinds
    keybind_open  = "ctrl+f",
    keybind_close = "ESC",
    keybind_select = "ENTER",
    keybind_up    = "UP",
    keybind_down  = "DOWN",

    -- UI settings
    menu_timeout  = 0,       -- 0 = no timeout
    title_text    = "🎬 Quality Selection",
}

local current_format = nil
local menu_open      = false
local selected_idx   = 1

-- Get current video quality info
local function get_current_info()
    local path = mp.get_property("path") or ""
    local height = mp.get_property_number("height") or 0
    local fps    = mp.get_property_number("fps") or 0
    local vcodec = mp.get_property("video-codec") or "?"
    local acodec = mp.get_property("audio-codec") or "?"

    return string.format(
        "Current: %dp @ %.0ffps | Video: %s | Audio: %s",
        height, fps, vcodec, acodec
    )
end

-- Apply quality format
local function apply_format(format_entry)
    if not format_entry then return end

    local path = mp.get_property("path")
    if not path then
        mp.osd_message("No file loaded", 2)
        return
    end

    -- Check if this is a streamable URL
    if not (path:match("^https?://") or path:match("^ytdl://")) then
        mp.osd_message("Quality switching only works for streams", 3)
        return
    end

    current_format = format_entry.format

    -- Reload with new format
    local pos  = mp.get_property_number("time-pos") or 0
    local pause = mp.get_property_bool("pause") or false

    mp.commandv("set", "ytdl-format", current_format)

    -- Reload file at current position
    mp.commandv("loadfile", path, "replace",
        "start=" .. tostring(pos))

    if pause then
        mp.commandv("cycle", "pause")
    end

    mp.osd_message(string.format(
        "🎬 Quality: %s\n%s",
        format_entry.label,
        format_entry.format
    ), 3)

    msg.info("[quality-menu] Applied format: " .. current_format)
end

-- Display quality menu using OSD
local function show_menu()
    if menu_open then
        hide_menu()
        return
    end

    menu_open   = true
    selected_idx = 1

    local function update_osd()
        local lines = { options.title_text, "" }
        local current_info = get_current_info()
        lines[#lines+1] = current_info
        lines[#lines+1] = ""
        lines[#lines+1] = "─────────────────────"

        for i, entry in ipairs(options.format_menu) do
            local marker = (i == selected_idx) and "▶ " or "  "
            local current_marker = (entry.format == current_format) and " ✓" or ""
            lines[#lines+1] = marker .. entry.label .. current_marker
        end

        lines[#lines+1] = ""
        lines[#lines+1] = "↑↓: Navigate  ENTER: Select  ESC: Close"

        mp.osd_message(table.concat(lines, "\n"), 999)
    end

    -- Navigation bindings
    local bindings = {
        { options.keybind_up, function()
            selected_idx = ((selected_idx - 2) % #options.format_menu) + 1
            update_osd()
        end },
        { options.keybind_down, function()
            selected_idx = (selected_idx % #options.format_menu) + 1
            update_osd()
        end },
        { options.keybind_select, function()
            apply_format(options.format_menu[selected_idx])
            hide_menu()
        end },
        { options.keybind_close, hide_menu },
    }

    for _, bind in ipairs(bindings) do
        mp.add_forced_key_binding(bind[1], "quality-menu-" .. bind[1], bind[2])
    end

    update_osd()
end

function hide_menu()
    if not menu_open then return end
    menu_open = false

    local binding_keys = {
        options.keybind_up, options.keybind_down,
        options.keybind_select, options.keybind_close,
    }

    for _, key in ipairs(binding_keys) do
        mp.remove_key_binding("quality-menu-" .. key)
    end

    mp.osd_message("", 0)
end

-- Register main keybind
mp.add_key_binding(options.keybind_open, "quality-menu-open", show_menu)

-- Show current quality on file load
mp.register_event("file-loaded", function()
    local format = mp.get_property("ytdl-format")
    if format then
        current_format = format
    end
end)

msg.info("[quality-menu] Loaded — Press " .. options.keybind_open .. " to open")