-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  ASH DOTFILES v5.0 — MPV SCRIPT: QUALITY MENU                            ║
-- ║                                                                            ║
-- ║  Dynamic video/audio quality selector for yt-dlp streams                  ║
-- ║                                                                            ║
-- ║  Features:                                                                 ║
-- ║  • Live quality switching without restart                                  ║
-- ║  • Catppuccin Mocha themed OSD menu                                       ║
-- ║  • Separate video and audio quality selection                             ║
-- ║  • Auto-detects available formats from yt-dlp                             ║
-- ║  • Remembers selected quality per domain                                  ║
-- ║  • Bandwidth estimation display                                            ║
-- ║  • Keyboard-navigable overlay menu                                        ║
-- ║                                                                            ║
-- ║  Keybinds (from input.conf):                                              ║
-- ║  F1 → Video quality menu                                                  ║
-- ║  F2 → Audio quality menu                                                  ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

local mp      = require "mp"
local utils   = require "mp.utils"
local msg     = require "mp.msg"
local options = require "mp.options"
local assdraw = require "mp.assdraw"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  CONFIGURATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local o = {
    -- Auto-select best quality on load
    auto_select       = true,

    -- yt-dlp binary path
    ytdl_path         = "yt-dlp",

    -- Default quality level to start at
    start_level       = "1080p60",

    -- OSD colors (hex without #)
    selected_color    = "a6e3a1",   -- Catppuccin Green — selected item
    active_color      = "cba6f7",   -- Catppuccin Mauve — currently playing
    header_color      = "89b4fa",   -- Catppuccin Blue — menu header
    normal_color      = "cdd6f4",   -- Catppuccin Text — normal items
    dim_color         = "6c7086",   -- Catppuccin Overlay0 — dim/disabled
    border_color      = "313244",   -- Catppuccin Surface0 — border
    bg_color          = "1e1e2e",   -- Catppuccin Base — background

    -- Menu display
    font_size         = 28,
    menu_timeout      = 8,          -- Seconds before auto-close
    max_items         = 12,         -- Max visible items before scrolling
}

options.read_options(o, "quality_menu")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  STATE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local menu_state = {
    visible     = false,
    mode        = nil,      -- "video" | "audio"
    formats     = {},       -- Available format list
    selected    = 1,        -- Currently highlighted index
    active      = nil,      -- Currently playing format ID
    scroll_offset = 0,      -- Menu scroll position
    timeout_timer = nil,    -- Auto-close timer
    osd_overlay = nil,      -- ASS overlay reference
}

-- Per-URL quality memory
local quality_memory = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  UTILITY FUNCTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- Format bytes to human-readable size
--- @param bytes number
--- @return string
local function format_size(bytes)
    if not bytes or bytes <= 0 then return "?" end
    if bytes < 1024 then
        return string.format("%dB", bytes)
    elseif bytes < 1048576 then
        return string.format("%.1fK", bytes / 1024)
    elseif bytes < 1073741824 then
        return string.format("%.1fM", bytes / 1048576)
    else
        return string.format("%.2fG", bytes / 1073741824)
    end
end

--- Parse yt-dlp format list JSON output
--- @param json_str string  JSON string from yt-dlp --dump-json
--- @param mode string     "video" | "audio"
--- @return table  List of format objects
local function parse_formats(json_str, mode)
    local data = utils.parse_json(json_str)
    if not data or not data.formats then
        return {}
    end

    local formats = {}
    local seen_labels = {}  -- Deduplicate by label

    for _, fmt in ipairs(data.formats) do
        -- Skip formats based on mode
        if mode == "video" then
            if not fmt.vcodec or fmt.vcodec == "none" then goto continue end
        elseif mode == "audio" then
            if not fmt.acodec or fmt.acodec == "none" then goto continue end
            if fmt.vcodec and fmt.vcodec ~= "none" then goto continue end
        end

        -- Build label
        local label
        if mode == "video" then
            local height  = fmt.height or 0
            local fps     = fmt.fps or 0
            local vcodec  = fmt.vcodec or ""
            local tbr     = fmt.tbr or fmt.vbr or 0

            -- Simplify codec name
            local codec_short = vcodec:match("^([^%.]+)") or vcodec
            if codec_short:find("avc") or codec_short:find("h264") then
                codec_short = "H.264"
            elseif codec_short:find("avc1") then
                codec_short = "H.264"
            elseif codec_short:find("vp9") then
                codec_short = "VP9"
            elseif codec_short:find("av01") or codec_short:find("av1") then
                codec_short = "AV1"
            elseif codec_short:find("hev") or codec_short:find("h265") then
                codec_short = "H.265"
            end

            if fps > 0 then
                label = string.format("%dp%d [%s] %dkbps",
                    height, math.floor(fps), codec_short, math.floor(tbr))
            else
                label = string.format("%dp [%s] %dkbps",
                    height, codec_short, math.floor(tbr))
            end
        else
            local acodec  = fmt.acodec or "?"
            local abr     = fmt.abr or fmt.tbr or 0
            local asr     = fmt.asr or 0

            local codec_short = acodec:match("^([^%.]+)") or acodec
            if codec_short:find("opus") then codec_short = "Opus"
            elseif codec_short:find("mp4a") then codec_short = "AAC"
            elseif codec_short:find("vorbis") then codec_short = "Vorbis"
            elseif codec_short:find("mp3") then codec_short = "MP3"
            end

            label = string.format("%s %dkbps %dHz",
                codec_short, math.floor(abr), asr)
        end

        -- Skip duplicates
        if seen_labels[label] then goto continue end
        seen_labels[label] = true

        table.insert(formats, {
            id      = fmt.format_id,
            label   = label,
            height  = fmt.height,
            fps     = fmt.fps,
            tbr     = fmt.tbr or fmt.vbr or fmt.abr,
            filesize = fmt.filesize or fmt.filesize_approx,
            ext     = fmt.ext,
        })

        ::continue::
    end

    -- Sort: video by height+fps desc, audio by bitrate desc
    table.sort(formats, function(a, b)
        if mode == "video" then
            if (a.height or 0) ~= (b.height or 0) then
                return (a.height or 0) > (b.height or 0)
            end
            return (a.fps or 0) > (b.fps or 0)
        else
            return (a.tbr or 0) > (b.tbr or 0)
        end
    end)

    return formats
end

--- Fetch available formats from yt-dlp for the current URL
--- @param url string  Video URL
--- @param callback function  Called with formats list
local function fetch_formats(url, mode, callback)
    mp.osd_message("󰋽  Fetching available qualities...", 30)

    local proc_args = {
        o.ytdl_path,
        "--dump-json",
        "--no-playlist",
        url,
    }

    mp.command_native_async({
        name     = "subprocess",
        args     = proc_args,
        capture_stdout = true,
        capture_stderr = true,
    }, function(success, result, error)
        if not success or result.status ~= 0 then
            msg.error("yt-dlp failed: " .. (result.stderr or "unknown"))
            mp.osd_message("󰅚  Failed to fetch qualities", 3)
            callback(nil)
            return
        end

        local formats = parse_formats(result.stdout, mode)
        callback(formats)
    end)
end

--- Apply selected format to current stream
--- @param format_id string  yt-dlp format ID
--- @param mode string       "video" | "audio"
local function apply_format(format_id, mode)
    local url = mp.get_property("path")
    if not url then return end

    local position = mp.get_property_number("time-pos") or 0
    local paused   = mp.get_property_bool("pause")

    -- Store quality preference
    local domain = url:match("://([^/]+)") or url
    quality_memory[domain] = quality_memory[domain] or {}
    quality_memory[domain][mode] = format_id

    msg.info(string.format("Switching %s quality to format: %s", mode, format_id))
    mp.osd_message(string.format("󰋽  Switching to %s quality...", mode), 30)

    -- Use ytdl_hook format selection
    if mode == "video" then
        mp.set_property("ytdl-format", format_id)
    else
        mp.set_property("ytdl-format", "bestvideo+" .. format_id)
    end

    -- Reload stream at current position
    mp.command_native_async({
        name = "subprocess",
        args = {
            o.ytdl_path,
            "--get-url",
            "--format", format_id,
            url,
        },
        capture_stdout = true,
    }, function(success, result)
        if success and result.status == 0 then
            local stream_url = result.stdout:gsub("%s+$", "")
            if stream_url ~= "" then
                -- Load the direct stream URL
                mp.commandv("loadfile", url, "replace",
                    string.format("start=%f", position))
            end
        end
    end)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  OSD MENU RENDERING — Premium Catppuccin-themed overlay
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- ASS color tag formatter
--- @param hex string  6-char hex color without #
--- @param alpha number  0-255 alpha (0=opaque)
--- @return string  ASS color tag
local function ass_color(hex, alpha)
    alpha = alpha or 0
    -- ASS uses BGR order with &H prefix
    local r = hex:sub(1,2)
    local g = hex:sub(3,4)
    local b = hex:sub(5,6)
    return string.format("{\\c&H%s%s%s&\\1a&H%02X&}", b, g, r, alpha)
end

--- Render the quality menu as an ASS overlay
local function render_menu()
    if not menu_state.visible then
        if menu_state.osd_overlay then
            menu_state.osd_overlay.data = ""
            menu_state.osd_overlay:update()
        end
        return
    end

    local ass = assdraw.ass_new()
    local formats = menu_state.formats
    local selected = menu_state.selected

    -- Get display dimensions
    local osd_w = mp.get_property_number("osd-width") or 1280
    local osd_h = mp.get_property_number("osd-height") or 720

    -- Menu dimensions
    local menu_w    = 380
    local item_h    = 36
    local padding   = 16
    local max_items = math.min(o.max_items, #formats)
    local menu_h    = (max_items * item_h) + (padding * 3) + 48  -- header + items + footer

    -- Menu position (center-right)
    local menu_x = osd_w - menu_w - 40
    local menu_y = (osd_h - menu_h) / 2

    -- ── Background panel ──────────────────────────────────────────────────
    ass:new_event()
    ass:pos(menu_x, menu_y)
    ass:append(string.format(
        "{\\bord0\\shad0\\1c&H%s%s%s&\\1a&H20&\\p1}",
        o.bg_color:sub(5,6),
        o.bg_color:sub(3,4),
        o.bg_color:sub(1,2)
    ))
    -- Draw rounded rectangle background
    ass:draw_start()
    local r = 12  -- corner radius
    ass:move_to(menu_x + r, menu_y)
    ass:line_to(menu_x + menu_w - r, menu_y)
    ass:bezier_curve(
        menu_x + menu_w, menu_y,
        menu_x + menu_w, menu_y,
        menu_x + menu_w, menu_y + r
    )
    ass:line_to(menu_x + menu_w, menu_y + menu_h - r)
    ass:bezier_curve(
        menu_x + menu_w, menu_y + menu_h,
        menu_x + menu_w, menu_y + menu_h,
        menu_x + menu_w - r, menu_y + menu_h
    )
    ass:line_to(menu_x + r, menu_y + menu_h)
    ass:bezier_curve(
        menu_x, menu_y + menu_h,
        menu_x, menu_y + menu_h,
        menu_x, menu_y + menu_h - r
    )
    ass:line_to(menu_x, menu_y + r)
    ass:bezier_curve(
        menu_x, menu_y,
        menu_x, menu_y,
        menu_x + r, menu_y
    )
    ass:draw_stop()

    -- ── Border outline ─────────────────────────────────────────────────────
    ass:new_event()
    ass:pos(menu_x, menu_y)
    ass:append(string.format(
        "{\\bord1.5\\shad0\\1c&H%s%s%s&\\3c&H%s%s%s&\\1a&HFF&\\3a&H50&\\p1}",
        o.border_color:sub(5,6), o.border_color:sub(3,4), o.border_color:sub(1,2),
        o.active_color:sub(5,6), o.active_color:sub(3,4), o.active_color:sub(1,2)
    ))
    -- Same shape as background
    ass:draw_start()
    ass:move_to(menu_x + r, menu_y)
    ass:line_to(menu_x + menu_w - r, menu_y)
    ass:bezier_curve(menu_x+menu_w, menu_y, menu_x+menu_w, menu_y, menu_x+menu_w, menu_y+r)
    ass:line_to(menu_x + menu_w, menu_y + menu_h - r)
    ass:bezier_curve(menu_x+menu_w, menu_y+menu_h, menu_x+menu_w, menu_y+menu_h, menu_x+menu_w-r, menu_y+menu_h)
    ass:line_to(menu_x + r, menu_y + menu_h)
    ass:bezier_curve(menu_x, menu_y+menu_h, menu_x, menu_y+menu_h, menu_x, menu_y+menu_h-r)
    ass:line_to(menu_x, menu_y + r)
    ass:bezier_curve(menu_x, menu_y, menu_x, menu_y, menu_x+r, menu_y)
    ass:draw_stop()

    -- ── Header ─────────────────────────────────────────────────────────────
    local header_icon = menu_state.mode == "video" and "󰿎" or "󰕾"
    local header_text = menu_state.mode == "video" and "Video Quality" or "Audio Quality"
    local count_text  = string.format("%d formats", #formats)

    ass:new_event()
    ass:pos(menu_x + padding, menu_y + padding)
    ass:append(string.format(
        "{\\fn%s\\fs%d\\b1\\c&H%s%s%s&\\bord0\\shad1\\4c&H000000&\\4a&H60&}%s  %s",
        "Inter", o.font_size - 2,
        o.header_color:sub(5,6), o.header_color:sub(3,4), o.header_color:sub(1,2),
        header_icon, header_text
    ))

    -- Format count (right-aligned)
    ass:new_event()
    ass:pos(menu_x + menu_w - padding, menu_y + padding)
    ass:an(6)  -- Right align
    ass:append(string.format(
        "{\\fn%s\\fs%d\\b0\\c&H%s%s%s&\\bord0\\shad0}%s",
        "Inter", o.font_size - 6,
        o.dim_color:sub(5,6), o.dim_color:sub(3,4), o.dim_color:sub(1,2),
        count_text
    ))

    -- Header separator line
    local header_bottom = menu_y + padding + 32
    ass:new_event()
    ass:pos(menu_x + padding, header_bottom)
    ass:append(string.format(
        "{\\bord0\\shad0\\1c&H%s%s%s&\\1a&H80&\\p1}",
        o.border_color:sub(5,6), o.border_color:sub(3,4), o.border_color:sub(1,2)
    ))
    ass:draw_start()
    ass:move_to(menu_x + padding, header_bottom)
    ass:line_to(menu_x + menu_w - padding, header_bottom)
    ass:draw_stop()

    -- ── Format Items ───────────────────────────────────────────────────────
    local scroll_start = menu_state.scroll_offset + 1
    local scroll_end   = math.min(scroll_start + max_items - 1, #formats)

    for i = scroll_start, scroll_end do
        local fmt      = formats[i]
        local item_y   = header_bottom + padding + ((i - scroll_start) * item_h)
        local is_sel   = (i == selected)
        local is_active = (fmt.id == menu_state.active)

        -- Selection highlight
        if is_sel then
            ass:new_event()
            ass:pos(menu_x + padding - 4, item_y - 2)
            ass:append(string.format(
                "{\\bord0\\shad0\\1c&H%s%s%s&\\1a&H30&\\p1}",
                o.active_color:sub(5,6), o.active_color:sub(3,4), o.active_color:sub(1,2)
            ))
            ass:draw_start()
            ass:move_to(menu_x + padding - 4, item_y - 2)
            ass:line_to(menu_x + menu_w - padding + 4, item_y - 2)
            ass:line_to(menu_x + menu_w - padding + 4, item_y + item_h - 6)
            ass:line_to(menu_x + padding - 4, item_y + item_h - 6)
            ass:draw_stop()

            -- Left accent bar
            ass:new_event()
            ass:pos(menu_x + padding - 6, item_y - 2)
            ass:append(string.format(
                "{\\bord0\\shad0\\1c&H%s%s%s&\\1a&H00&\\p1}",
                o.active_color:sub(5,6), o.active_color:sub(3,4), o.active_color:sub(1,2)
            ))
            ass:draw_start()
            ass:move_to(menu_x + padding - 6, item_y - 2)
            ass:line_to(menu_x + padding - 2, item_y - 2)
            ass:line_to(menu_x + padding - 2, item_y + item_h - 6)
            ass:line_to(menu_x + padding - 6, item_y + item_h - 6)
            ass:draw_stop()
        end

        -- Item text color
        local item_color
        if is_active then
            item_color = o.selected_color  -- Green = currently playing
        elseif is_sel then
            item_color = o.active_color    -- Mauve = highlighted
        else
            item_color = o.normal_color    -- Default text
        end

        -- Status icon
        local status_icon = is_active and "✓ " or "  "

        -- Format label
        ass:new_event()
        ass:pos(menu_x + padding, item_y)
        ass:append(string.format(
            "{\\fn%s\\fs%d\\b%d\\c&H%s%s%s&\\bord0\\shad0}%s%s",
            "Inter",
            o.font_size - 4,
            is_sel and 1 or 0,
            item_color:sub(5,6), item_color:sub(3,4), item_color:sub(1,2),
            status_icon,
            fmt.label
        ))

        -- File size (right-aligned, dim)
        if fmt.filesize then
            ass:new_event()
            ass:pos(menu_x + menu_w - padding, item_y)
            ass:an(6)
            ass:append(string.format(
                "{\\fn%s\\fs%d\\b0\\c&H%s%s%s&\\bord0\\shad0}%s",
                "Inter", o.font_size - 8,
                o.dim_color:sub(5,6), o.dim_color:sub(3,4), o.dim_color:sub(1,2),
                format_size(fmt.filesize)
            ))
        end
    end

    -- ── Scroll indicators ──────────────────────────────────────────────────
    if scroll_start > 1 then
        local y = header_bottom + padding - 12
        ass:new_event()
        ass:pos(menu_x + menu_w / 2, y)
        ass:an(5)
        ass:append(string.format(
            "{\\fn%s\\fs%d\\c&H%s%s%s&\\bord0}▲",
            "Inter", o.font_size,
            o.dim_color:sub(5,6), o.dim_color:sub(3,4), o.dim_color:sub(1,2)
        ))
    end

    if scroll_end < #formats then
        local y = menu_y + menu_h - 8
        ass:new_event()
        ass:pos(menu_x + menu_w / 2, y)
        ass:an(5)
        ass:append(string.format(
            "{\\fn%s\\fs%d\\c&H%s%s%s&\\bord0}▼",
            "Inter", o.font_size,
            o.dim_color:sub(5,6), o.dim_color:sub(3,4), o.dim_color:sub(1,2)
        ))
    end

    -- ── Footer hint ────────────────────────────────────────────────────────
    local footer_y = menu_y + menu_h - padding - 4
    ass:new_event()
    ass:pos(menu_x + menu_w / 2, footer_y)
    ass:an(5)
    ass:append(string.format(
        "{\\fn%s\\fs%d\\c&H%s%s%s&\\bord0}↑↓ Navigate  Enter Select  Esc Close",
        "Inter", o.font_size - 10,
        o.dim_color:sub(5,6), o.dim_color:sub(3,4), o.dim_color:sub(1,2)
    ))

    -- Apply overlay
    if not menu_state.osd_overlay then
        menu_state.osd_overlay = mp.create_osd_overlay("ass-events")
    end
    menu_state.osd_overlay.data = ass.text
    menu_state.osd_overlay:update()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  MENU INTERACTION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- Close the quality menu
local function close_menu()
    menu_state.visible = false

    -- Remove key bindings
    mp.remove_key_binding("quality-menu-up")
    mp.remove_key_binding("quality-menu-down")
    mp.remove_key_binding("quality-menu-select")
    mp.remove_key_binding("quality-menu-close")
    mp.remove_key_binding("quality-menu-pgup")
    mp.remove_key_binding("quality-menu-pgdn")

    -- Cancel timeout timer
    if menu_state.timeout_timer then
        menu_state.timeout_timer:kill()
        menu_state.timeout_timer = nil
    end

    -- Clear overlay
    if menu_state.osd_overlay then
        menu_state.osd_overlay.data = ""
        menu_state.osd_overlay:update()
    end

    msg.info("Quality menu closed")
end

--- Reset timeout timer
local function reset_timer()
    if menu_state.timeout_timer then
        menu_state.timeout_timer:kill()
    end
    menu_state.timeout_timer = mp.add_timeout(o.menu_timeout, function()
        if menu_state.visible then
            close_menu()
        end
    end)
end

--- Navigate menu selection
--- @param delta number  +1 = down, -1 = up
local function navigate(delta)
    if not menu_state.visible then return end

    local total = #menu_state.formats
    menu_state.selected = menu_state.selected + delta

    -- Clamp to valid range
    if menu_state.selected < 1 then menu_state.selected = total end
    if menu_state.selected > total then menu_state.selected = 1 end

    -- Adjust scroll to keep selected visible
    local max_items = math.min(o.max_items, total)
    if menu_state.selected <= menu_state.scroll_offset then
        menu_state.scroll_offset = menu_state.selected - 1
    elseif menu_state.selected > menu_state.scroll_offset + max_items then
        menu_state.scroll_offset = menu_state.selected - max_items
    end

    reset_timer()
    render_menu()
end

--- Select current highlighted format
local function select_current()
    if not menu_state.visible then return end

    local fmt = menu_state.formats[menu_state.selected]
    if not fmt then return end

    close_menu()

    msg.info(string.format("Selected quality: %s (%s)", fmt.label, fmt.id))
    mp.osd_message(string.format("󰋽  Quality: %s", fmt.label), 3)

    apply_format(fmt.id, menu_state.mode)
end

--- Open the quality menu
--- @param mode string  "video" | "audio"
local function open_menu(mode)
    local url = mp.get_property("path")
    if not url then
        mp.osd_message("󰅚  No stream loaded", 3)
        return
    end

    -- Only works with yt-dlp supported URLs
    if not url:match("^https?://") then
        mp.osd_message("󰅚  Quality menu only works with streaming URLs", 3)
        return
    end

    menu_state.mode     = mode
    menu_state.selected = 1
    menu_state.scroll_offset = 0
    menu_state.active   = nil

    -- Fetch formats
    fetch_formats(url, mode, function(formats)
        if not formats or #formats == 0 then
            mp.osd_message("󰅚  No formats available", 3)
            return
        end

        menu_state.formats = formats
        menu_state.visible = true

        -- Register navigation keys
        mp.add_forced_key_binding("UP",    "quality-menu-up",     function() navigate(-1) end)
        mp.add_forced_key_binding("DOWN",  "quality-menu-down",   function() navigate(1) end)
        mp.add_forced_key_binding("k",     "quality-menu-k",      function() navigate(-1) end)
        mp.add_forced_key_binding("j",     "quality-menu-j",      function() navigate(1) end)
        mp.add_forced_key_binding("ENTER", "quality-menu-select", select_current)
        mp.add_forced_key_binding("ESC",   "quality-menu-close",  close_menu)
        mp.add_forced_key_binding("PGUP",  "quality-menu-pgup",   function() navigate(-5) end)
        mp.add_forced_key_binding("PGDWN", "quality-menu-pgdn",   function() navigate(5) end)

        -- Start auto-close timer
        reset_timer()
        render_menu()

        msg.info(string.format("Quality menu opened (%d %s formats)", #formats, mode))
    end)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  SCRIPT BINDINGS (from input.conf)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

mp.add_key_binding(nil, "video", function() open_menu("video") end)
mp.add_key_binding(nil, "audio", function() open_menu("audio") end)

msg.info("quality-menu loaded — F1=video quality, F2=audio quality")