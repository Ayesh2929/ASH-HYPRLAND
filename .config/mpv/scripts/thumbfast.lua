-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — THUMBFAST MPV SCRIPT                         ║
-- ║           High-performance on-the-fly thumbnailer for mpv                  ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

--[[
    thumbfast.lua
    High-performance on-the-fly thumbnailer

    Note: This is a simplified version. Install the full version from:
    https://github.com/po5/thumbfast

    Usage: Place in ~/.config/mpv/scripts/thumbfast.lua
    Thumbnails appear when hovering over the progress bar (requires uosc or similar)
--]]

local options = {
    -- Socket path for communication
    socket       = "/tmp/thumbfast",

    -- Thumbnail file path (temp file)
    thumbnail    = "/tmp/thumbfast.png",

    -- Maximum thumbnail size
    max_height   = 200,
    max_width    = 200,

    -- Overlay ID
    overlay_id   = 42,

    -- Spawn thumbfast only when needed
    spawn_first  = false,

    -- Network stream support
    network      = false,

    -- Audio file support
    audio        = false,

    -- Thumbnail cleanup on exit
    quit_after_inactivity = 0,

    -- Debug logging
    debug        = false,
}

local script_name = mp.get_script_name()
local spawn_cmd   = nil
local last_seek   = 0
local is_active   = false

local function info(...)
    if options.debug then
        mp.msg.info(...)
    end
end

local function err(...)
    mp.msg.error(...)
end

-- Determine if current file supports thumbnails
local function can_thumbnail()
    local path = mp.get_property("path")
    if not path then return false end

    -- Skip audio-only files
    local vid = mp.get_property("vid")
    if vid == "no" or vid == nil then
        return options.audio
    end

    -- Skip network streams by default
    if path:match("^https?://") or path:match("^rtmp://") then
        return options.network
    end

    return true
end

-- Request thumbnail at current time position
local function request_thumbnail(time)
    if not is_active then return end
    if not can_thumbnail() then return end

    local delta = math.abs(time - last_seek)
    if delta < 0.1 then return end -- Debounce

    last_seek = time

    -- Write seek position to socket
    local f = io.open(options.socket, "w")
    if f then
        f:write(tostring(time) .. "\n")
        f:close()
        info("[thumbfast] Requesting thumbnail at: " .. time)
    end
end

-- Show thumbnail overlay
local function show_thumbnail()
    local f = io.open(options.thumbnail, "rb")
    if not f then return end
    f:close()

    -- Use mpv's overlay system to display thumbnail
    mp.commandv("overlay-add", options.overlay_id,
        0, 0, options.thumbnail, 0, "bgra", options.max_width, options.max_height,
        options.max_width * 4)
end

-- Hide thumbnail overlay
local function hide_thumbnail()
    mp.commandv("overlay-remove", options.overlay_id)
end

-- Start thumbfast background process
local function start_thumbfast()
    if not can_thumbnail() then return end

    local path = mp.get_property("path")
    if not path then return end

    -- Check if thumbfast binary exists
    if not spawn_cmd then
        -- Try to find thumbfast
        local handle = io.popen("which thumbfast 2>/dev/null")
        if handle then
            local result = handle:read("*l")
            handle:close()
            if result and result ~= "" then
                spawn_cmd = result
            end
        end
    end

    is_active = true
    info("[thumbfast] Thumbnailing active for: " .. path)
end

local function stop_thumbfast()
    is_active = false
    hide_thumbnail()
    info("[thumbfast] Thumbnailing stopped")
end

-- Register events
mp.register_event("file-loaded",  start_thumbfast)
mp.register_event("end-file",     stop_thumbfast)
mp.register_event("seek",         function()
    request_thumbnail(mp.get_property_number("time-pos") or 0)
end)

-- Expose API for uosc/other scripts
mp.register_script_message("thumb", function(time_str)
    local time = tonumber(time_str)
    if time then
        request_thumbnail(time)
    end
end)

mp.register_script_message("thumbfast-show", show_thumbnail)
mp.register_script_message("thumbfast-hide", hide_thumbnail)

info("[thumbfast] Loaded — socket: " .. options.socket)