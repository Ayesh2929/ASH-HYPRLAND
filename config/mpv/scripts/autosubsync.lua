-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  ASH DOTFILES v5.0 — MPV SCRIPT: AUTOSUBSYNC                             ║
-- ║                                                                            ║
-- ║  Automatic subtitle synchronization using:                                ║
-- ║  • ffsubsync — audio-based sync (fastest, works on most content)          ║
-- ║  • alass     — timing-based sync (works without audio analysis)           ║
-- ║                                                                            ║
-- ║  How it works:                                                             ║
-- ║  1. User presses the sync keybind (default: n)                            ║
-- ║  2. Script detects active external subtitle track                         ║
-- ║  3. Runs ffsubsync/alass on the subtitle file vs video audio              ║
-- ║  4. Creates a synced .srt file and loads it as the active track          ║
-- ║                                                                            ║
-- ║  Requirements:                                                             ║
-- ║  • pip install ffsubsync   (faster, audio-based)                          ║
-- ║  • pip install alass-cli   (alternative, timing-based)                   ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

local mp         = require "mp"
local utils      = require "mp.utils"
local msg        = require "mp.msg"
local options    = require "mp.options"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  CONFIGURATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local o = {
    -- Auto-sync on subtitle track load
    autoload           = false,

    -- Binary paths (check PATH automatically)
    ffsubsync_path     = "ffsubsync",
    alass_path         = "alass",

    -- Prefer alass over ffsubsync (alass is faster but less accurate on some content)
    prefer_alass       = false,

    -- Sync timeout in seconds (ffsubsync can be slow on long videos)
    timeout            = 120,

    -- Keep the original subtitle file (don't delete after sync)
    keep_original      = true,

    -- Suffix added to synced subtitle filename
    synced_suffix      = ".synced",

    -- OSD display duration (ms)
    osd_duration       = 4000,
}

options.read_options(o, "autosubsync")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  STATE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local sync_in_progress = false
local synced_files     = {}  -- Track files we've already synced to avoid re-sync

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  UTILITY FUNCTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- Display OSD message with Catppuccin-themed icon prefix
--- @param msg_text string    Message content
--- @param level string       "info" | "warn" | "error"
local function osd(msg_text, level)
    local icons = {
        info  = "󰋽",  -- Info icon (Nerd Fonts)
        warn  = "󰀦",  -- Warning icon
        error = "󰅚",  -- Error icon
    }
    local icon = icons[level] or icons.info
    mp.osd_message(string.format("%s  %s", icon, msg_text), o.osd_duration / 1000)
    msg[level or "info"](msg_text)
end

--- Check if a binary exists and is executable
--- @param binary string  Binary name or path
--- @return boolean
local function binary_exists(binary)
    local result = utils.subprocess({
        args = { "which", binary },
        capture_stdout = true,
        capture_stderr = true,
    })
    return result.status == 0 and result.stdout ~= ""
end

--- Get the file extension from a path
--- @param path string
--- @return string  Extension without leading dot
local function get_extension(path)
    return path:match("%.([^%.]+)$") or ""
end

--- Strip extension from filename
--- @param path string
--- @return string  Path without extension
local function strip_extension(path)
    return path:match("(.+)%.[^%.]+$") or path
end

--- Get the currently active external subtitle file path
--- @return string|nil  Subtitle file path or nil
local function get_active_sub_file()
    local track_list = mp.get_property_native("track-list")
    if not track_list then return nil end

    for _, track in ipairs(track_list) do
        if track.type == "sub"
        and track.selected
        and track.external
        and track["external-filename"] then
            return track["external-filename"]
        end
    end

    return nil
end

--- Generate synced subtitle output path
--- @param sub_path string  Original subtitle path
--- @return string  Output path for synced subtitle
local function get_output_path(sub_path)
    local base = strip_extension(sub_path)
    local ext  = get_extension(sub_path)
    return string.format("%s%s.%s", base, o.synced_suffix, ext)
end

--- Remove temporary synced subtitle files older than current session
local function cleanup_synced(sub_path)
    local output = get_output_path(sub_path)
    if not o.keep_original then
        os.remove(sub_path)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  SYNC ENGINES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- Run ffsubsync to sync subtitles against video audio
--- Audio-based: highly accurate, uses speech detection
--- @param video_path string   Video file path
--- @param sub_path string     Subtitle file path
--- @param output_path string  Output synced subtitle path
--- @return boolean, string    success, error message
local function run_ffsubsync(video_path, sub_path, output_path)
    msg.info(string.format(
        "Running ffsubsync: video=%s sub=%s out=%s",
        video_path, sub_path, output_path
    ))

    local result = utils.subprocess({
        args = {
            o.ffsubsync_path,
            video_path,
            "-i", sub_path,
            "-o", output_path,
            "--max-offset-seconds", "60",
            "--frame-rate", tostring(mp.get_property_number("container-fps") or 24),
        },
        capture_stdout = true,
        capture_stderr = true,
        cancellable    = false,
    })

    if result.status == 0 then
        msg.info("ffsubsync completed successfully")
        return true, nil
    else
        local err = result.stderr or "Unknown error"
        msg.error("ffsubsync failed: " .. err)
        return false, err
    end
end

--- Run alass to sync subtitles
--- Timing-based: uses existing subtitle timing as reference
--- @param video_path string   Video file path (unused by alass, uses embedded subs)
--- @param sub_path string     Subtitle file to sync
--- @param output_path string  Output path
--- @return boolean, string    success, error message
local function run_alass(video_path, sub_path, output_path)
    msg.info(string.format(
        "Running alass: video=%s sub=%s out=%s",
        video_path, sub_path, output_path
    ))

    -- alass uses video (with embedded subs as reference) and syncs external subs
    local result = utils.subprocess({
        args = {
            o.alass_path,
            video_path,
            sub_path,
            output_path,
            "--allow-negative-timestamps",
            "--interval", "1",
            "--split-penalty", "7",
        },
        capture_stdout = true,
        capture_stderr = true,
        cancellable    = false,
    })

    if result.status == 0 then
        msg.info("alass completed successfully")
        return true, nil
    else
        local err = result.stderr or result.stdout or "Unknown error"
        msg.error("alass failed: " .. err)
        return false, err
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  MAIN SYNC FUNCTION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- Main subtitle sync orchestrator
--- @param force boolean  Force re-sync even if already synced
local function sync_subtitles(force)
    if sync_in_progress then
        osd("Sync already in progress...", "warn")
        return
    end

    -- Get video path
    local video_path = mp.get_property("path")
    if not video_path then
        osd("No video file loaded", "error")
        return
    end

    -- Get active subtitle path
    local sub_path = get_active_sub_file()
    if not sub_path then
        osd("No external subtitle track active", "warn")
        return
    end

    -- Check if already synced
    if synced_files[sub_path] and not force then
        osd("Subtitles already synced (press again to re-sync)", "info")
        synced_files[sub_path] = nil  -- Clear so next press re-syncs
        return
    end

    -- Validate subtitle file exists
    local stat = utils.file_info(sub_path)
    if not stat then
        osd(string.format("Subtitle file not found: %s", sub_path), "error")
        return
    end

    -- Determine sync tool
    local use_alass = o.prefer_alass and binary_exists(o.alass_path)
    local use_ffsubsync = binary_exists(o.ffsubsync_path)

    if not use_alass and not use_ffsubsync then
        osd("Neither ffsubsync nor alass found! Install one:\n  pip install ffsubsync", "error")
        return
    end

    -- Determine output path
    local output_path = get_output_path(sub_path)

    -- Start sync
    sync_in_progress = true
    local tool_name = (use_alass and "alass") or "ffsubsync"

    osd(string.format("󰋽  Syncing subtitles with %s...", tool_name), "info")
    msg.info(string.format("Starting subtitle sync with %s", tool_name))

    -- Remember current position to restore after track reload
    local position = mp.get_property_number("time-pos") or 0

    -- Run synchronization
    local success, error_msg

    if use_alass then
        success, error_msg = run_alass(video_path, sub_path, output_path)
    else
        success, error_msg = run_ffsubsync(video_path, sub_path, output_path)
    end

    sync_in_progress = false

    if not success then
        osd(string.format("Sync failed: %s", error_msg or "Unknown"), "error")
        return
    end

    -- Verify output file was created
    local output_stat = utils.file_info(output_path)
    if not output_stat or output_stat.size == 0 then
        osd("Sync produced empty output file", "error")
        return
    end

    -- Load the synced subtitle
    -- Remove current external subtitle
    local sid = mp.get_property_native("sid")

    -- Add synced subtitle file
    mp.commandv("sub-add", output_path, "select")

    -- Restore position
    if position > 1 then
        mp.set_property_number("time-pos", position)
    end

    -- Mark as synced
    synced_files[sub_path] = output_path

    -- Success notification
    local size_kb = math.floor(output_stat.size / 1024)
    osd(string.format(
        "✓  Subtitles synced with %s (%dKB)\n%s",
        tool_name,
        size_kb,
        output_path:match("([^/]+)$") or output_path
    ), "info")

    msg.info(string.format("Subtitle sync complete: %s", output_path))
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  AUTO-LOAD HOOK
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Auto-sync when a subtitle is loaded (if enabled)
mp.observe_property("current-tracks/sub/src-id", "number", function(name, value)
    if not o.autoload then return end
    if not value then return end

    -- Small delay to ensure subtitle is fully loaded
    mp.add_timeout(0.5, function()
        local sub_path = get_active_sub_file()
        if sub_path and not synced_files[sub_path] then
            msg.info("Auto-syncing subtitle: " .. sub_path)
            sync_subtitles(false)
        end
    end)
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  KEY BINDINGS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Main sync binding (registered with input.conf as: n autosubsync/autosubsync)
mp.add_key_binding(nil, "autosubsync", function()
    sync_subtitles(false)
end)

-- Force re-sync binding
mp.add_key_binding(nil, "load_autosubsync", function()
    sync_subtitles(true)
end)

-- Status info binding
mp.add_key_binding(nil, "autosubsync_status", function()
    local sub_path = get_active_sub_file()
    if not sub_path then
        osd("No external subtitle active", "info")
        return
    end

    if synced_files[sub_path] then
        osd(string.format(
            "✓ Synced: %s",
            synced_files[sub_path]:match("([^/]+)$") or "unknown"
        ), "info")
    else
        local use_alass    = o.prefer_alass and binary_exists(o.alass_path)
        local use_ffsubsync = binary_exists(o.ffsubsync_path)
        local available = use_alass and "alass"
                       or (use_ffsubsync and "ffsubsync")
                       or "none"

        osd(string.format(
            "Subtitle: %s\nTool: %s\nPress n to sync",
            sub_path:match("([^/]+)$") or sub_path,
            available
        ), "info")
    end
end)

msg.info("autosubsync loaded — press n to sync subtitles")