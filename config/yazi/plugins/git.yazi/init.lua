--- ╔══════════════════════════════════════════════════════════════════════════╗
--- ║  ASH DOTFILES v5.0 — YAZI PLUGIN: GIT STATUS                          ║
--- ║                                                                        ║
--- ║  Shows Git status indicators on files and directories                  ║
--- ║  in the Yazi file manager.                                             ║
--- ║                                                                        ║
--- ║  Status Icons (Nerd Fonts v3):                                         ║
--- ║  ● Modified (unstaged)     ✓ Clean/Committed                          ║
--- ║  ✗ Deleted                 ⊕ Added/Staged                             ║
--- ║  ⋯ Untracked               ⚡ Renamed                                  ║
--- ║  ⚠ Conflicted              ─ Ignored                                   ║
--- ╚══════════════════════════════════════════════════════════════════════╝

local M = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  CONFIGURATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Catppuccin Mocha colors for git status indicators
local colors = {
    -- Modified — Peach (warm warning)
    modified        = ui.Color.from_rgb(250, 179, 135),  -- #fab387
    -- Staged/Added — Green (success)
    staged          = ui.Color.from_rgb(166, 227, 161),  -- #a6e3a1
    -- Untracked — Blue (info, new content)
    untracked       = ui.Color.from_rgb(137, 180, 250),  -- #89b4fa
    -- Deleted — Red (danger)
    deleted         = ui.Color.from_rgb(243, 139, 168),  -- #f38ba8
    -- Renamed — Sapphire (changed identity)
    renamed         = ui.Color.from_rgb(116, 199, 236),  -- #74c7ec
    -- Conflicted — Red (critical)
    conflicted      = ui.Color.from_rgb(243, 139, 168),  -- #f38ba8
    -- Ignored — Muted overlay
    ignored         = ui.Color.from_rgb(108, 112, 134),  -- #6c7086
    -- Clean/committed — Teal (all good)
    clean           = ui.Color.from_rgb(148, 226, 213),  -- #94e2d5
    -- Ahead — Mauve (outstanding push)
    ahead           = ui.Color.from_rgb(203, 166, 247),  -- #cba6f7
    -- Behind — Flamingo (needs pull)
    behind          = ui.Color.from_rgb(242, 205, 205),  -- #f2cdcd
}

-- Status indicator glyphs (Nerd Fonts v3)
local icons = {
    modified    = "●",   -- Modified (unstaged changes)
    staged      = "⊕",   -- Staged for commit
    untracked   = "⋯",   -- Untracked new file
    deleted     = "✗",   -- Deleted
    renamed     = "⚡",   -- Renamed/moved
    conflicted  = "⚠",   -- Merge conflict
    ignored     = "─",   -- Git ignored
    clean       = "✓",   -- Clean, committed
    ahead       = "↑",   -- Commits ahead of remote
    behind      = "↓",   -- Commits behind remote
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  GIT STATUS CACHE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Cache git status per repository root to avoid re-running git for each file
local cache = {}
local cache_ttl = 5  -- seconds before cache expires

--- Get the git repository root for a given path
--- @param path string  Absolute file path
--- @return string|nil  Repository root or nil if not in git repo
local function get_git_root(path)
    local handle = io.popen(
        string.format("git -C %q rev-parse --show-toplevel 2>/dev/null", path)
    )
    if not handle then return nil end
    local root = handle:read("*l")
    handle:close()
    return root ~= "" and root or nil
end

--- Parse git status output into a status map
--- @param root string  Git repository root
--- @return table  Map of relative_path → status_code
local function parse_git_status(root)
    local statuses = {}

    -- Run git status --porcelain=v1 for machine-readable output
    local handle = io.popen(
        string.format(
            "git -C %q status --porcelain=v1 --untracked-files=all 2>/dev/null",
            root
        )
    )
    if not handle then return statuses end

    for line in handle:lines() do
        if #line >= 4 then
            local xy   = line:sub(1, 2)   -- Two-letter status code
            local path = line:sub(4)       -- Relative path

            -- Handle renamed files (format: "R old -> new")
            if xy:sub(1, 1) == "R" or xy:sub(2, 2) == "R" then
                local arrow = path:find(" -> ")
                if arrow then
                    path = path:sub(arrow + 4)
                end
            end

            -- Strip leading/trailing quotes from paths with spaces
            path = path:gsub('^"', ""):gsub('"$', "")

            statuses[path] = xy
        end
    end

    handle:close()
    return statuses
end

--- Determine display status from git XY code
--- @param xy string  Two-letter git status code
--- @return string  Status key from icons/colors table
local function classify_status(xy)
    local x, y = xy:sub(1, 1), xy:sub(2, 2)

    -- Conflicted (merge conflicts)
    if x == "U" or y == "U"
    or (x == "A" and y == "A")
    or (x == "D" and y == "D") then
        return "conflicted"
    end

    -- Staged changes (index)
    if x == "A" then return "staged" end
    if x == "M" then return "staged" end
    if x == "D" then return "deleted" end
    if x == "R" then return "renamed" end
    if x == "C" then return "renamed" end

    -- Unstaged changes (working tree)
    if y == "M" then return "modified" end
    if y == "D" then return "deleted" end
    if y == "R" then return "renamed" end

    -- Untracked
    if x == "?" and y == "?" then return "untracked" end

    -- Ignored
    if x == "!" and y == "!" then return "ignored" end

    return "clean"
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  FETCHER — Called for each file in the listing
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- @param job table  Yazi job object containing file information
function M:fetch(job)
    local files = job.files
    if not files or #files == 0 then
        return 1
    end

    -- Get the directory containing the first file
    local first_url = files[1].url
    local dir = first_url:parent()
    if not dir then return 1 end

    local dir_path = tostring(dir)

    -- Find git root
    local git_root = get_git_root(dir_path)
    if not git_root then
        return 1  -- Not in a git repository
    end

    -- Check cache
    local now = os.time()
    if cache[git_root] and (now - cache[git_root].time) < cache_ttl then
        -- Use cached status
    else
        -- Refresh status
        local statuses = parse_git_status(git_root)
        cache[git_root] = {
            time     = now,
            statuses = statuses,
        }
    end

    local statuses = cache[git_root].statuses

    -- Apply status to each file
    for _, file in ipairs(files) do
        local abs_path  = tostring(file.url)
        local rel_path  = abs_path:sub(#git_root + 2)  -- Remove root + slash

        local xy = statuses[rel_path]

        -- For directories: check if any child has a status
        if file.cha.is_dir then
            local dir_status = nil
            for status_path, status_xy in pairs(statuses) do
                if status_path:sub(1, #rel_path + 1) == rel_path .. "/" then
                    -- Prioritize: conflicted > modified > staged > untracked
                    local s = classify_status(status_xy)
                    if s == "conflicted" then
                        dir_status = "conflicted"
                        break
                    elseif s == "modified" and dir_status ~= "conflicted" then
                        dir_status = "modified"
                    elseif s == "staged" and not dir_status then
                        dir_status = "staged"
                    elseif s == "untracked" and not dir_status then
                        dir_status = "untracked"
                    elseif s == "deleted" and not dir_status then
                        dir_status = "deleted"
                    end
                end
            end
            if dir_status then
                xy = dir_status ~= "clean" and "M " or nil
            end
        end

        if xy then
            local status_key = classify_status(xy)
            local color  = colors[status_key] or colors.clean
            local symbol = icons[status_key] or icons.clean

            -- Set the file's git status data for rendering
            ya.file_emit(file, {
                tag = "git",
                data = {
                    status  = status_key,
                    symbol  = symbol,
                    color   = color,
                }
            })
        end
    end

    return 0
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  SPOT — Quick status display in status bar
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- @param job table  Yazi job
function M:spot(job)
    local file = job.file
    if not file then return end

    local git_data = file:find_tag("git")
    if not git_data then return end

    local data = git_data.data
    local color = data.color
    local symbol = data.symbol
    local status = data.status

    -- Render status in the spot area
    job:push({
        ui.Span(string.format(" %s %s", symbol, status))
            :fg(color)
            :bold(),
    })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  SETUP — Plugin initialization
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- @param opts table  Plugin options from yazi.toml
function M:setup(opts)
    opts = opts or {}
    if opts.cache_ttl then
        cache_ttl = opts.cache_ttl
    end
end

return M