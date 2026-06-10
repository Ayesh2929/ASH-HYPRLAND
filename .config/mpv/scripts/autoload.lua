-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — MPV AUTOLOAD SCRIPT                          ║
-- ║           Auto-load next/previous files in directory                       ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

local options = {
    disabled       = false,
    images         = true,
    videos         = true,
    audio          = true,
    additional_image_exts = { "png", "jpg", "jpeg", "gif", "bmp", "webp", "avif", "heic" },
    additional_video_exts = { "mp4", "mkv", "avi", "mov", "webm", "flv", "wmv", "m4v" },
    additional_audio_exts = { "mp3", "flac", "ogg", "wav", "aac", "opus", "m4a" },
    ignore_hidden  = true,
    same_type      = true,
    directory_mode = "recursive",
}

local EXTS = {
    video = {
        "3g2", "3gp", "asf", "avi", "f4v", "flv", "h264", "h265", "m2ts",
        "m4v", "mkv", "mov", "mp4", "mpeg", "mpg", "ogm", "ogv", "rm",
        "rmvb", "ts", "vob", "webm", "wmv", "wtv", "hevc",
    },
    audio = {
        "aif", "aiff", "ape", "au", "flac", "m4a", "mka", "mp3", "ogg",
        "ogm", "opus", "wav", "wma", "wv",
    },
    image = {
        "bmp", "gif", "jpeg", "jpg", "png", "svg", "tga", "tif", "tiff",
        "webp", "avif", "heic", "heif",
    },
}

-- Build extensions set
local function build_ext_set()
    local set = {}
    if options.videos then
        for _, ext in ipairs(EXTS.video) do set[ext] = true end
        for _, ext in ipairs(options.additional_video_exts) do set[ext] = true end
    end
    if options.audio then
        for _, ext in ipairs(EXTS.audio) do set[ext] = true end
        for _, ext in ipairs(options.additional_audio_exts) do set[ext] = true end
    end
    if options.images then
        for _, ext in ipairs(EXTS.image) do set[ext] = true end
        for _, ext in ipairs(options.additional_image_exts) do set[ext] = true end
    end
    return set
end

local function get_extension(path)
    local ext = path:match("%.([^./]+)$")
    return ext and ext:lower() or ""
end

local function is_hidden(path)
    local name = path:match("([^/\\]+)$") or path
    return name:sub(1, 1) == "."
end

local function escape_pattern(str)
    return str:gsub("[%(%)%.%+%-%*%?%[%^%$%%]", "%%%1")
end

local function get_files_in_dir(dir)
    local files = {}
    local ext_set = build_ext_set()

    local handle = io.popen(
        string.format('ls -1 "%s" 2>/dev/null', dir:gsub('"', '\\"'))
    )
    if not handle then return files end

    for name in handle:lines() do
        if not (options.ignore_hidden and is_hidden(name)) then
            local ext = get_extension(name)
            if ext_set[ext] then
                table.insert(files, dir .. "/" .. name)
            end
        end
    end

    handle:close()
    table.sort(files)
    return files
end

-- Main autoload logic
local function autoload()
    if options.disabled then return end

    local path = mp.get_property("path")
    if not path then return end

    local dir = path:match("(.+)/[^/]*$") or path:match("(.+)\\[^\\]*$") or "."
    local files = get_files_in_dir(dir)

    if #files < 2 then return end

    -- Clear current playlist and rebuild
    local playlist = mp.get_property_native("playlist")
    if #playlist == 1 then
        -- Only add files if we started with a single file
        local current_idx = 1
        for i, file in ipairs(files) do
            if file == path then
                current_idx = i
                break
            end
        end

        mp.commandv("playlist-clear")
        for i, file in ipairs(files) do
            if i == 1 then
                mp.commandv("loadfile", file, "replace")
            else
                mp.commandv("loadfile", file, "append")
            end
        end

        mp.commandv("playlist-play-index", current_idx - 1)
        mp.msg.info(string.format("[autoload] Loaded %d files from: %s", #files, dir))
    end
end

mp.register_event("file-loaded", autoload)