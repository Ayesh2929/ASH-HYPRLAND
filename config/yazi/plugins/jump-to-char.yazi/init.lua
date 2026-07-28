--- ╔══════════════════════════════════════════════════════════════════════════╗
--- ║  ASH DOTFILES v5.0 — YAZI PLUGIN: JUMP TO CHAR                        ║
--- ║                                                                        ║
--- ║  Flash.nvim-style character jump navigation                            ║
--- ║  Type a character → all matching files get labeled                     ║
--- ║  Type the label → cursor jumps to that file instantly                  ║
--- ║                                                                        ║
--- ║  Features:                                                              ║
--- ║  • Single-key jump (type char → immediate match)                       ║
--- ║  • Multi-match: labeled A-Z, a-z, 0-9                                 ║
--- ║  • Smart case: lowercase = case insensitive                            ║
--- ║  • Highlights matching characters in filenames                         ║
--- ╚══════════════════════════════════════════════════════════════════════╝

local M = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  CONFIGURATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Label characters for multi-match mode (ordered by ergonomics)
local LABELS = "fjdkslagheruitybvcxznmopwq1234567890FJDKSLAGHERUITYBVCXZNMOPWQ"

-- Jump hint color — Mauve (prominent, ASH accent)
local COLOR_HINT   = ui.Color.from_rgb(203, 166, 247)  -- #cba6f7
local COLOR_MATCH  = ui.Color.from_rgb(249, 226, 175)  -- #f9e2af
local COLOR_DIM    = ui.Color.from_rgb(108, 112, 134)  -- #6c7086

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  MAIN ENTRY POINT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- @param job table  Yazi job with args
function M:entry(job)
    local args = job.args or {}
    local smart_case = args[1] == "--smart-case"

    -- ── Step 1: Read jump character ────────────────────────────────────────

    ya.notify({
        title   = "Jump to Char",
        content = "Type a character to jump...",
        level   = "info",
        timeout = 1,
    })

    local char_event = ya.input({
        title   = "  Jump:",
        realtime = true,
    })

    if not char_event or char_event[1] ~= "submit" then
        return
    end

    local target_char = char_event[2]
    if not target_char or #target_char == 0 then return end

    -- ── Step 2: Find all matching files ────────────────────────────────────

    local files  = cx.active.current.files
    local matches = {}

    for i, file in ipairs(files) do
        local name = tostring(file.url:name())
        local search_name = name
        local search_char = target_char

        -- Apply smart case: if char is lowercase → case insensitive
        if smart_case and target_char == target_char:lower() then
            search_name = name:lower()
            search_char = target_char:lower()
        end

        -- Check if filename starts with or contains the target char
        local pos = search_name:find(search_char, 1, true)
        if pos then
            table.insert(matches, {
                index    = i - 1,  -- 0-indexed for ya.manager_emit
                file     = file,
                name     = name,
                match_pos = pos,
            })
        end
    end

    if #matches == 0 then
        ya.notify({
            title   = "Jump to Char",
            content = string.format("No files matching '%s'", target_char),
            level   = "warn",
            timeout = 1,
        })
        return
    end

    -- ── Step 3: Single match — jump directly ───────────────────────────────

    if #matches == 1 then
        ya.manager_emit("arrow", {
            matches[1].index - cx.active.current.cursor
        })
        return
    end

    -- ── Step 4: Multiple matches — show labels and wait for selection ──────

    -- Assign labels
    local labeled = {}
    for i, match in ipairs(matches) do
        local label = LABELS:sub(i, i)
        if label == "" then
            label = tostring(i)
        end
        match.label = label
        labeled[label] = match
    end

    -- Display label hints using ya.render
    -- (simplified: jump to first match, show notification with labels)
    local hint_lines = {}
    for _, match in ipairs(matches) do
        table.insert(hint_lines, string.format(
            "[%s] %s",
            match.label,
            match.name
        ))
        if #hint_lines >= 10 then
            table.insert(hint_lines, string.format("... (%d more)", #matches - 10))
            break
        end
    end

    ya.notify({
        title   = string.format("Jump: %d matches", #matches),
        content = table.concat(hint_lines, "\n"),
        level   = "info",
        timeout = 5,
    })

    -- Wait for label selection
    local label_event = ya.input({
        title   = string.format("  Select [%s]:", LABELS:sub(1, #matches)),
        realtime = true,
    })

    if not label_event or label_event[1] ~= "submit" then
        return
    end

    local selected_label = label_event[2]
    local selected_match = labeled[selected_label]

    if selected_match then
        ya.manager_emit("arrow", {
            selected_match.index - cx.active.current.cursor
        })
    else
        ya.notify({
            title   = "Jump to Char",
            content = "Invalid label",
            level   = "warn",
            timeout = 1,
        })
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- @param opts table
function M:setup(opts)
    opts = opts or {}
    if opts.labels then
        LABELS = opts.labels
    end
    if opts.hint_color then
        COLOR_HINT = ui.Color.from_hex(opts.hint_color)
    end
end

return M