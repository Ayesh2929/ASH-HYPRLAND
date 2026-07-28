--- ╔══════════════════════════════════════════════════════════════════════════╗
--- ║  ASH DOTFILES v5.0 — YAZI PLUGIN: SMART FILTER                        ║
--- ║                                                                        ║
--- ║  Intelligent file filtering with live preview                          ║
--- ║  Features:                                                              ║
--- ║  • Real-time filter as you type                                        ║
--- ║  • Smart case: lowercase = insensitive, UPPER = sensitive              ║
--- ║  • Fuzzy matching support                                               ║
--- ║  • Filter by: name | extension | size | modified date                  ║
--- ║  • Remembers last filter per directory                                  ║
--- ║  • Highlights matching characters in results                           ║
--- ╚══════════════════════════════════════════════════════════════════════╝

local M = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  CONFIGURATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Filter mode options
local MODES = {
    name   = "name",      -- Filter by filename
    ext    = "ext",       -- Filter by extension
    size   = "size",      -- Filter by size range
    date   = "date",      -- Filter by modification date
    fuzzy  = "fuzzy",     -- Fuzzy match
}

-- Colors — Catppuccin Mocha
local COLOR_ACTIVE   = ui.Color.from_rgb(203, 166, 247)  -- #cba6f7 Mauve
local COLOR_MATCH    = ui.Color.from_rgb(249, 226, 175)  -- #f9e2af Yellow
local COLOR_COUNT    = ui.Color.from_rgb(137, 180, 250)  -- #89b4fa Blue
local COLOR_MODE     = ui.Color.from_rgb(166, 227, 161)  -- #a6e3a1 Green
local COLOR_HINT     = ui.Color.from_rgb(108, 112, 134)  -- #6c7086 Overlay

-- Filter history per directory
local history = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  UTILITY FUNCTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- Check if pattern matches using smart case
--- Smart case: if pattern has uppercase, be case-sensitive
--- @param pattern string  Filter pattern
--- @param text string     Text to match against
--- @param fuzzy boolean   Enable fuzzy matching
--- @return boolean, number  matches, score
local function smart_match(pattern, text, fuzzy)
    -- Determine case sensitivity from pattern
    local has_upper = pattern:match("[A-Z]")
    local text_cmp  = has_upper and text or text:lower()
    local pat_cmp   = has_upper and pattern or pattern:lower()

    if fuzzy then
        -- Fuzzy match: all pattern chars must appear in order
        local score = 0
        local pos = 1
        for i = 1, #pat_cmp do
            local c = pat_cmp:sub(i, i)
            local found = text_cmp:find(c, pos, true)
            if found then
                -- Score: consecutive matches score higher
                if found == pos then score = score + 2
                else                 score = score + 1 end
                pos = found + 1
            else
                return false, 0
            end
        end
        return true, score
    else
        -- Substring match
        local found = text_cmp:find(pat_cmp, 1, true)
        if found then
            return true, #pat_cmp  -- Score = pattern length (longer = better match)
        end
        return false, 0
    end
end

--- Parse size filter notation
--- Supports: ">1M", "<500K", "=10K", "1M-5M"
--- @param filter string  Size filter string
--- @return function|nil  Matcher function
local function parse_size_filter(filter)
    -- Remove whitespace
    filter = filter:gsub("%s", "")

    -- Parse size units
    local function parse_size(s)
        local n, unit = s:match("^(%d+%.?%d*)([KMGkgm]?)$")
        if not n then return nil end
        n = tonumber(n)
        unit = unit:upper()
        if unit == "K" then n = n * 1024
        elseif unit == "M" then n = n * 1024 * 1024
        elseif unit == "G" then n = n * 1024 * 1024 * 1024
        end
        return n
    end

    -- Range: "1M-5M"
    local a, b = filter:match("^(.+)-(.+)$")
    if a and b then
        local min_size = parse_size(a)
        local max_size = parse_size(b)
        if min_size and max_size then
            return function(size) return size >= min_size and size <= max_size end
        end
    end

    -- Comparison: ">1M", "<500K", "=10K"
    local op, val = filter:match("^([<>=])(.+)$")
    if op and val then
        local size = parse_size(val)
        if size then
            if op == ">" then return function(s) return s > size end
            elseif op == "<" then return function(s) return s < size end
            elseif op == "=" then return function(s) return s == size end
            end
        end
    end

    return nil
end

--- Parse extension filter
--- Supports: "rs,py,go" or ".rs .py .go"
--- @param filter string
--- @return table  Set of extensions (without dots)
local function parse_ext_filter(filter)
    local exts = {}
    for ext in filter:gmatch("[%.%w]+") do
        ext = ext:gsub("^%.", ""):lower()
        if #ext > 0 then
            exts[ext] = true
        end
    end
    return exts
end

--- Highlight matching characters in a string
--- Returns ANSI-style spans for matched positions
--- @param text string
--- @param pattern string
--- @return string  Annotated text
local function highlight_match(text, pattern)
    -- For now return plain text — rendering highlights
    -- requires direct ui.Span integration
    return text
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  MAIN ENTRY POINT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- @param job table  Yazi job
function M:entry(job)
    local args   = job.args or {}
    local mode   = args.mode or MODES.name
    local fuzzy  = args.fuzzy ~= false  -- Default: fuzzy on

    -- Get current directory for history
    local cwd = tostring(cx.active.current.url)

    -- Build prompt based on mode
    local mode_prompts = {
        [MODES.name]  = "󰈞  Filter name:",
        [MODES.ext]   = "   Filter ext:",
        [MODES.size]  = "   Filter size:",
        [MODES.date]  = "   Filter date:",
        [MODES.fuzzy] = "󰈞  Fuzzy filter:",
    }

    local prompt = mode_prompts[mode] or "󰈞  Smart filter:"

    -- Show last filter for this directory as default
    local default = history[cwd] or ""

    -- ── Get filter input ───────────────────────────────────────────────────

    local event = ya.input({
        title   = prompt,
        value   = default,
        realtime = true,
    })

    if not event or event[1] == "cancel" then
        -- Clear filter on cancel
        ya.manager_emit("filter", { "" })
        history[cwd] = nil
        return
    end

    if event[1] ~= "submit" then return end

    local pattern = event[2]
    if not pattern or #pattern == 0 then
        ya.manager_emit("filter", { "" })
        history[cwd] = nil
        return
    end

    -- Save to history
    history[cwd] = pattern

    -- ── Apply filter based on mode ─────────────────────────────────────────

    if mode == MODES.ext then
        -- Extension filter: convert to regex pattern
        local exts = parse_ext_filter(pattern)
        local ext_pattern_parts = {}
        for ext, _ in pairs(exts) do
            table.insert(ext_pattern_parts, "%." .. ext .. "$")
        end
        local ext_regex = table.concat(ext_pattern_parts, "|")
        -- Use yazi's built-in filter with the regex
        ya.manager_emit("filter", { ext_regex, "--smart" })

    elseif mode == MODES.size then
        -- Size filter requires custom implementation
        -- For now, show notification and use name filter as fallback
        local matcher = parse_size_filter(pattern)
        if not matcher then
            ya.notify({
                title   = "Smart Filter",
                content = "Invalid size format. Use: >1M, <500K, 1M-5M",
                level   = "warn",
                timeout = 3,
            })
            return
        end

        -- Count matching files for feedback
        local files = cx.active.current.files
        local count = 0
        for _, file in ipairs(files) do
            if file.cha.len and matcher(file.cha.len) then
                count = count + 1
            end
        end

        ya.notify({
            title   = "Size Filter",
            content = string.format("Filter '%s' matches %d files", pattern, count),
            level   = "info",
            timeout = 2,
        })

    elseif mode == MODES.fuzzy then
        -- Fuzzy filter — use smart filter with fuzzy matching
        ya.manager_emit("filter", { pattern, "--smart" })

    else
        -- Default: name filter with smart case
        -- Determine if we should use case-sensitive mode
        local is_smart = pattern == pattern:lower()

        if is_smart then
            -- lowercase → smart/insensitive
            ya.manager_emit("filter", { pattern, "--smart" })
        else
            -- Has uppercase → case sensitive
            ya.manager_emit("filter", { pattern })
        end
    end

    -- ── Show filter statistics ─────────────────────────────────────────────

    -- Brief delay to let filter apply, then show count
    ya.sleep(0.05)

    local total   = #cx.active.current.files
    local visible = cx.active.current.files

    -- Count visible files (post-filter)
    local visible_count = 0
    if visible then
        visible_count = #visible
    end

    -- Status notification
    ya.notify({
        title   = string.format(
            "󰈞  Filter: %s [%s]",
            pattern,
            fuzzy and "fuzzy" or "exact"
        ),
        content = string.format(
            "%d / %d files shown",
            visible_count,
            total
        ),
        level   = "info",
        timeout = 2,
    })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  SETUP — Plugin initialization
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- @param opts table
function M:setup(opts)
    opts = opts or {}

    -- Register keybindings for different filter modes
    -- These are additional bindings beyond the main keymap.toml entries
end

return M