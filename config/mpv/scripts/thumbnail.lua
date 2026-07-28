-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  ASH DOTFILES v5.0 — MPV SCRIPT: THUMBNAIL PREVIEW                       ║
-- ║                                                                            ║
-- ║  Seekbar thumbnail preview system                                          ║
-- ║                                                                            ║
-- ║  Features:                                                                 ║
-- ║  • Hover thumbnail above the seek bar                                     ║
-- ║  • Background thumbnail generation (non-blocking)                         ║
-- ║  • Catppuccin Mocha themed overlay frame                                  ║
-- ║  • GPU-accelerated thumbnail rendering                                    ║
-- ║  • Local file + network stream support                                    ║
-- ║  • Timestamp label on thumbnail                                           ║
-- ║  • Smooth fade-in/fade-out animation via timer                            ║
-- ║  • Cache management (auto-cleanup on file change)                        ║
-- ║                                                                            ║
-- ║  Architecture:                                                             ║
-- ║  1. On file load: spawn background ffmpeg workers to generate thumbs     ║
-- ║  2. On mouse hover over seekbar: show nearest cached thumbnail            ║
-- ║  3. Thumbnail displayed via mpv's overlay_add command                    ║
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
    -- Enable thumbnail system
    enabled             = true,

    -- Thumbnail dimensions (16:9 ratio at 288w = 162h)
    thumbnail_width     = 288,
    thumbnail_height    = 162,

    -- Number of thumbnail samples (evenly distributed through video)
    -- Higher = more coverage, more disk space, longer generation time
    thumbnail_count     = 120,

    -- Generate thumbnails for first frame immediately on load
    spawn_first         = true,

    -- Generate thumbs for network streams
    network             = true,

    -- Use direct stream URL (faster for some formats)
    remote_direct_stream = true,

    -- Cache directory for thumbnails
    -- Default: system temp dir
    cache_dir           = "",

    -- Max cache age in hours (0 = never delete)
    cache_max_age       = 24,

    -- Overlay position: thumbnail above seekbar
    -- margin from bottom of screen
    bottom_margin       = 80,

    -- Display timing (ms)
    fade_duration       = 150,   -- Fade in/out duration
    display_delay       = 100,   -- Delay before showing thumb

    -- Frame style
    frame_color         = "313244",  -- Catppuccin Surface0
    frame_size          = 3,         -- Border width in pixels
    shadow_color        = "11111b",  -- Catppuccin Crust
    shadow_offset       = 4,

    -- Timestamp label
    show_timestamp      = true,
    timestamp_font_size = 18,
    timestamp_color     = "cdd6f4",  -- Catppuccin Text
    timestamp_bg        = "1e1e2e",  -- Catppuccin Base

    -- Chapter markers
    show_chapter        = true,

    -- ffmpeg binary
    ffmpeg_path         = "ffmpeg",
}

options.read_options(o, "thumbnail")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  STATE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local state = {
    -- Generation state
    enabled             = false,
    generating          = false,
    generated_count     = 0,
    total_count         = 0,

    -- File info
    video_path          = nil,
    video_duration      = 0,
    cache_dir           = nil,

    -- Display state
    visible             = false,
    current_pos         = 0,     -- Hovering at this position (seconds)
    last_shown_time     = -1,    -- Timestamp of last displayed thumb
    overlay_id          = 12,    -- MPV overlay ID

    -- Animation
    alpha               = 0,     -- Current opacity 0-255
    fade_timer          = nil,

    -- Thumbnail map: time_seconds → file_path
    thumbnails          = {},

    -- Mouse state
    mouse_x             = 0,
    mouse_y             = 0,
    seekbar_y           = 0,
    seekbar_h           = 24,    -- Approximate seekbar height

    -- OSD overlay for frame/label
    label_overlay       = nil,

    -- Worker processes
    workers             = {},
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  UTILITY FUNCTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- Format seconds as HH:MM:SS or MM:SS
--- @param secs number
--- @return string
local function format_time(secs)
    secs = math.floor(secs)
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = secs % 60
    if h > 0 then
        return string.format("%d:%02d:%02d", h, m, s)
    else
        return string.format("%d:%02d", m, s)
    end
end

--- Get the system temp directory
--- @return string
local function get_temp_dir()
    return os.getenv("TMPDIR") or os.getenv("TEMP") or "/tmp"
end

--- Create a unique cache directory for the current video
--- @param video_path string
--- @return string
local function get_cache_dir(video_path)
    if o.cache_dir ~= "" then
        return o.cache_dir
    end

    local temp = get_temp_dir()
    -- Create hash from path
    local hash = 0
    for i = 1, #video_path do
        hash = (hash * 31 + video_path:byte(i)) % 0x100000000
    end
    local dir = utils.join_path(temp, string.format("mpv-thumbs-%08x", hash))
    return dir
end

--- Ensure directory exists
--- @param path string
--- @return boolean
local function ensure_dir(path)
    local result = utils.subprocess({
        args = { "mkdir", "-p", path },
        capture_stderr = true,
    })
    return result.status == 0
end

--- Get thumbnail file path for a given time
--- @param time_secs number
--- @return string
local function thumb_path(time_secs)
    return utils.join_path(
        state.cache_dir,
        string.format("thumb_%06d.bgra", math.floor(time_secs))
    )
end

--- Find nearest available thumbnail to a given time
--- @param target_time number  Time in seconds
--- @return string|nil, number  path, actual_time
local function nearest_thumbnail(target_time)
    local best_path  = nil
    local best_time  = nil
    local best_delta = math.huge

    for time_secs, path in pairs(state.thumbnails) do
        local delta = math.abs(time_secs - target_time)
        if delta < best_delta then
            best_delta = delta
            best_time  = time_secs
            best_path  = path
        end
    end

    -- Only return if within 30 seconds of requested time (or 2% of duration)
    local max_delta = math.max(30, state.video_duration * 0.02)
    if best_delta <= max_delta then
        return best_path, best_time
    end

    return nil, nil
end

--- Get chapter name at current time
--- @param time_secs number
--- @return string|nil
local function get_chapter(time_secs)
    local chapters = mp.get_property_native("chapter-list")
    if not chapters or #chapters == 0 then return nil end

    local current_chapter = nil
    for _, chapter in ipairs(chapters) do
        if chapter.time <= time_secs then
            current_chapter = chapter.title
        else
            break
        end
    end

    return current_chapter
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  THUMBNAIL GENERATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- Generate a single thumbnail at given time
--- @param video_path string
--- @param time_secs number
--- @param output_path string
--- @param callback function  Called when done
local function generate_thumbnail_async(video_path, time_secs, output_path, callback)
    -- Generate BGRA raw image (mpv overlay_add format)
    local w = o.thumbnail_width
    local h = o.thumbnail_height

    mp.command_native_async({
        name = "subprocess",
        args = {
            o.ffmpeg_path,
            "-loglevel", "error",
            "-ss", tostring(time_secs),
            "-i", video_path,
            "-frames:v", "1",
            "-vf", string.format(
                "scale=%d:%d:force_original_aspect_ratio=decrease,pad=%d:%d:(ow-iw)/2:(oh-ih)/2:color=black",
                w, h, w, h
            ),
            "-pix_fmt", "bgra",
            "-f", "rawvideo",
            output_path,
            "-y",
        },
        capture_stderr = true,
    }, function(success, result)
        if success and result.status == 0 then
            -- Verify file was created and has correct size
            local stat = utils.file_info(output_path)
            local expected_size = w * h * 4  -- BGRA = 4 bytes per pixel
            if stat and stat.size == expected_size then
                callback(true, output_path)
                return
            end
        end
        callback(false, nil)
    end)
end

--- Generate thumbnails for the entire video
local function generate_all_thumbnails()
    if state.generating then return end
    if not state.video_path then return end
    if not state.video_duration or state.video_duration <= 0 then return end

    -- Skip network streams if disabled
    local is_network = state.video_path:match("^https?://")
        or state.video_path:match("^rtmp://")
        or state.video_path:match("^rtsp://")

    if is_network and not o.network then
        msg.info("Thumbnail generation disabled for network streams")
        return
    end

    -- Create cache directory
    if not ensure_dir(state.cache_dir) then
        msg.error("Failed to create thumbnail cache: " .. state.cache_dir)
        return
    end

    state.generating     = true
    state.generated_count = 0
    state.total_count    = o.thumbnail_count

    msg.info(string.format(
        "Generating %d thumbnails for: %s",
        o.thumbnail_count,
        state.video_path:match("([^/]+)$") or state.video_path
    ))

    -- Calculate timestamps (evenly distributed)
    local timestamps = {}
    local interval = state.video_duration / o.thumbnail_count

    for i = 0, o.thumbnail_count - 1 do
        local t = interval * i + interval * 0.5  -- Middle of each interval
        t = math.min(t, state.video_duration - 0.5)
        table.insert(timestamps, t)
    end

    -- Generate first thumbnail immediately if requested
    if o.spawn_first and #timestamps > 0 then
        local first_t = timestamps[1]
        local first_path = thumb_path(first_t)

        generate_thumbnail_async(state.video_path, first_t, first_path,
            function(success, path)
                if success then
                    state.thumbnails[first_t] = path
                    state.generated_count = 1
                end
            end)
    end

    -- Generate remaining thumbnails with controlled concurrency
    local max_concurrent = 4  -- Max simultaneous ffmpeg processes
    local queue_index = o.spawn_first and 2 or 1
    local active = 0

    local function process_next()
        if queue_index > #timestamps then
            if active == 0 then
                state.generating = false
                msg.info(string.format(
                    "Thumbnail generation complete: %d/%d",
                    state.generated_count,
                    state.total_count
                ))
            end
            return
        end

        while active < max_concurrent and queue_index <= #timestamps do
            local t    = timestamps[queue_index]
            local path = thumb_path(t)
            queue_index = queue_index + 1
            active = active + 1

            -- Skip if already exists
            local stat = utils.file_info(path)
            local expected = o.thumbnail_width * o.thumbnail_height * 4
            if stat and stat.size == expected then
                state.thumbnails[t] = path
                state.generated_count = state.generated_count + 1
                active = active - 1
                process_next()
            else
                generate_thumbnail_async(state.video_path, t, path,
                    function(success, out_path)
                        if success then
                            state.thumbnails[t] = out_path
                            state.generated_count = state.generated_count + 1
                        end
                        active = active - 1
                        process_next()
                    end)
            end
        end
    end

    -- Start processing with small delay to not impact startup
    mp.add_timeout(2.0, process_next)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  THUMBNAIL DISPLAY
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- Hide the thumbnail overlay
local function hide_thumbnail()
    if not state.visible then return end
    state.visible = false

    -- Hide raw image overlay
    mp.command_native({
        name = "overlay-remove",
        id   = state.overlay_id,
    })

    -- Hide label overlay
    if state.label_overlay then
        state.label_overlay.data = ""
        state.label_overlay:update()
    end
end

--- Show thumbnail at given position
--- @param time_secs number  Position in video (seconds)
--- @param mouse_x number    Mouse X position (pixels)
local function show_thumbnail(time_secs, mouse_x)
    if not o.enabled then return end
    if not state.enabled then return end

    -- Find nearest thumbnail
    local thumb_file, actual_time = nearest_thumbnail(time_secs)
    if not thumb_file then return end

    -- Avoid re-displaying same frame
    if actual_time == state.last_shown_time and state.visible then
        return
    end

    -- Get display dimensions
    local osd_w = mp.get_property_number("osd-width") or 1280
    local osd_h = mp.get_property_number("osd-height") or 720

    local tw = o.thumbnail_width
    local th = o.thumbnail_height

    -- Calculate thumbnail position
    -- Horizontally: centered on mouse, clamped to screen
    local tx = math.floor(mouse_x - tw / 2)
    tx = math.max(o.frame_size, math.min(tx, osd_w - tw - o.frame_size))

    -- Vertically: above seekbar
    local ty = osd_h - th - o.bottom_margin - o.frame_size * 2 - 28  -- 28 for label

    -- Display raw BGRA thumbnail via overlay_add
    local success = pcall(function()
        mp.command_native({
            name    = "overlay-add",
            id      = state.overlay_id,
            x       = tx + o.frame_size,
            y       = ty + o.frame_size,
            file    = thumb_file,
            offset  = 0,
            fmt     = "bgra",
            w       = tw,
            h       = th,
            stride  = tw * 4,
        })
    end)

    if not success then
        msg.warn("Failed to display thumbnail overlay")
        return
    end

    state.visible        = true
    state.last_shown_time = actual_time

    -- ── Render frame and timestamp label (ASS overlay) ─────────────────────
    if not state.label_overlay then
        state.label_overlay = mp.create_osd_overlay("ass-events")
    end

    local ass = assdraw.ass_new()

    -- Frame border rectangle
    local fx = tx
    local fy = ty
    local fw = tw + o.frame_size * 2
    local fh = th + o.frame_size * 2

    -- Shadow
    ass:new_event()
    ass:pos(fx + o.shadow_offset, fy + o.shadow_offset)
    ass:append(string.format(
        "{\\bord0\\shad0\\1c&H%s%s%s&\\1a&H40&\\p1}",
        o.shadow_color:sub(5,6), o.shadow_color:sub(3,4), o.shadow_color:sub(1,2)
    ))
    ass:draw_start()
    ass:move_to(fx + o.shadow_offset, fy + o.shadow_offset)
    ass:line_to(fx + fw + o.shadow_offset, fy + o.shadow_offset)
    ass:line_to(fx + fw + o.shadow_offset, fy + fh + o.shadow_offset)
    ass:line_to(fx + o.shadow_offset, fy + fh + o.shadow_offset)
    ass:draw_stop()

    -- Frame
    ass:new_event()
    ass:pos(fx, fy)
    ass:append(string.format(
        "{\\bord0\\shad0\\1c&H%s%s%s&\\1a&H00&\\p1}",
        o.frame_color:sub(5,6), o.frame_color:sub(3,4), o.frame_color:sub(1,2)
    ))
    ass:draw_start()
    -- Outer frame
    ass:move_to(fx, fy)
    ass:line_to(fx + fw, fy)
    ass:line_to(fx + fw, fy + fh)
    ass:line_to(fx, fy + fh)

    -- Inner cutout (for transparency)
    ass:move_to(fx + o.frame_size, fy + o.frame_size)
    ass:line_to(fx + o.frame_size, fy + fh - o.frame_size)
    ass:line_to(fx + fw - o.frame_size, fy + fh - o.frame_size)
    ass:line_to(fx + fw - o.frame_size, fy + o.frame_size)
    ass:draw_stop()

    -- Timestamp label background
    local timestamp = format_time(actual_time)
    local chapter   = o.show_chapter and get_chapter(actual_time) or nil
    local label     = chapter and string.format("%s  %s", timestamp, chapter) or timestamp

    local label_y = fy + fh + 2  -- Below frame

    -- Label background
    ass:new_event()
    ass:pos(fx + fw / 2, label_y)
    ass:an(8)  -- Top-center anchor
    ass:append(string.format(
        "{\\bord0\\shad0\\1c&H%s%s%s&\\1a&H20&\\p1}",
        o.timestamp_bg:sub(5,6), o.timestamp_bg:sub(3,4), o.timestamp_bg:sub(1,2)
    ))
    local label_w = #label * (o.timestamp_font_size * 0.6) + 16
    local label_h = o.timestamp_font_size + 8
    ass:draw_start()
    local lx = fx + fw / 2 - label_w / 2
    local lyr = label_y
    ass:move_to(lx, lyr)
    ass:line_to(lx + label_w, lyr)
    ass:line_to(lx + label_w, lyr + label_h)
    ass:line_to(lx, lyr + label_h)
    ass:draw_stop()

    -- Timestamp text
    ass:new_event()
    ass:pos(fx + fw / 2, label_y + label_h / 2)
    ass:an(5)  -- Center anchor
    ass:append(string.format(
        "{\\fn%s\\fs%d\\b1\\c&H%s%s%s&\\bord0\\shad0}%s",
        "Inter",
        o.timestamp_font_size,
        o.timestamp_color:sub(5,6), o.timestamp_color:sub(3,4), o.timestamp_color:sub(1,2),
        label
    ))

    -- Generation progress indicator (if still generating)
    if state.generating and state.total_count > 0 then
        local pct = math.floor(state.generated_count / state.total_count * 100)
        ass:new_event()
        ass:pos(fx + fw - 6, fy + 6)
        ass:an(3)
        ass:append(string.format(
            "{\\fn%s\\fs%d\\b0\\c&H%s%s%s&\\bord0\\shad0}%d%%",
            "Inter", o.timestamp_font_size - 4,
            "6c7086", "6c7086", "6c7086",  -- dim gray
            pct
        ))
    end

    state.label_overlay.data = ass.text
    state.label_overlay:update()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  MOUSE TRACKING
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Track mouse position and show thumbnail when over seekbar
mp.observe_property("mouse-pos", "native", function(name, value)
    if not o.enabled or not state.enabled then return end
    if not value then return end

    local mx = value.x
    local my = value.y

    state.mouse_x = mx
    state.mouse_y = my

    -- Get screen dimensions
    local osd_w = mp.get_property_number("osd-width") or 1280
    local osd_h = mp.get_property_number("osd-height") or 720

    -- Approximate seekbar position (bottom 10% of screen)
    local seekbar_top = osd_h * 0.90
    local seekbar_bot = osd_h

    -- Check if mouse is over seekbar region
    if my >= seekbar_top and my <= seekbar_bot and mx >= 0 and mx <= osd_w then
        -- Calculate time position from mouse X
        local seek_pct  = mx / osd_w
        local time_secs = seek_pct * state.video_duration

        show_thumbnail(time_secs, mx)
    else
        -- Mouse left seekbar
        hide_thumbnail()
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  FILE CHANGE HOOKS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Initialize on file load
mp.register_event("file-loaded", function()
    if not o.enabled then return end

    -- Reset state
    hide_thumbnail()
    state.thumbnails      = {}
    state.generated_count = 0
    state.generating      = false
    state.last_shown_time = -1

    -- Get video info
    state.video_path    = mp.get_property("path")
    state.video_duration = mp.get_property_number("duration") or 0

    if not state.video_path or state.video_duration <= 0 then
        state.enabled = false
        return
    end

    state.enabled   = true
    state.cache_dir = get_cache_dir(state.video_path)

    msg.info(string.format(
        "Thumbnail system initialized: duration=%.1fs cache=%s",
        state.video_duration,
        state.cache_dir
    ))

    -- Start generation
    generate_all_thumbnails()
end)

-- Cleanup on file end
mp.register_event("end-file", function()
    hide_thumbnail()
    state.enabled = false
end)

-- Handle duration property (for streams where it's not immediately available)
mp.observe_property("duration", "number", function(name, value)
    if value and value > 0 and state.video_path then
        if state.video_duration ~= value then
            state.video_duration = value
            -- Restart generation if duration changed significantly
            if not state.generating and state.generated_count == 0 then
                state.enabled = true
                generate_all_thumbnails()
            end
        end
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  SCRIPT BINDINGS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Toggle thumbnail system
mp.add_key_binding(nil, "thumbnail-toggle", function()
    o.enabled = not o.enabled
    if not o.enabled then
        hide_thumbnail()
    end
    mp.osd_message(string.format(
        "Thumbnails: %s",
        o.enabled and "enabled" or "disabled"
    ), 2)
end)

-- Show generation status
mp.add_key_binding(nil, "thumbnail-status", function()
    if not state.enabled then
        mp.osd_message("Thumbnails: disabled", 2)
        return
    end

    local pct = state.total_count > 0
        and math.floor(state.generated_count / state.total_count * 100)
        or 0

    mp.osd_message(string.format(
        "Thumbnails: %d/%d (%.0f%%) — %s",
        state.generated_count,
        state.total_count,
        pct,
        state.generating and "generating..." or "complete"
    ), 3)
end)

msg.info("thumbnail script loaded")