-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — NEOVIM UTILITY FUNCTIONS                     ║
-- ║           Shared utilities used across the configuration                   ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

local M = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔧 FILE UTILITIES
-- ═══════════════════════════════════════════════════════════════════════════════

-- Check if file exists
function M.file_exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

-- Read file contents
function M.read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*all")
    f:close()
    return content
end

-- Write file contents
function M.write_file(path, content)
    local f = io.open(path, "w")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

-- Get file modification time
function M.get_mtime(path)
    local ok, stat = pcall(vim.loop.fs_stat, path)
    if ok and stat then return stat.mtime.sec end
    return 0
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🎨 COLOR UTILITIES
-- ═══════════════════════════════════════════════════════════════════════════════

-- Convert hex color to RGB table
function M.hex_to_rgb(hex)
    hex = hex:gsub("^#", "")
    if #hex ~= 6 then return nil end
    return {
        r = tonumber(hex:sub(1, 2), 16),
        g = tonumber(hex:sub(3, 4), 16),
        b = tonumber(hex:sub(5, 6), 16),
    }
end

-- Mix two hex colors
function M.mix_colors(hex1, hex2, ratio)
    ratio = ratio or 0.5
    local c1 = M.hex_to_rgb(hex1)
    local c2 = M.hex_to_rgb(hex2)
    if not c1 or not c2 then return hex1 end

    local r = math.floor(c1.r * (1 - ratio) + c2.r * ratio)
    local g = math.floor(c1.g * (1 - ratio) + c2.g * ratio)
    local b = math.floor(c1.b * (1 - ratio) + c2.b * ratio)

    return string.format("#%02x%02x%02x", r, g, b)
end

-- Add alpha to hex color (returns rgba CSS format)
function M.hex_with_alpha(hex, alpha)
    local rgb = M.hex_to_rgb(hex)
    if not rgb then return hex end
    return string.format("rgba(%d, %d, %d, %.2f)", rgb.r, rgb.g, rgb.b, alpha)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🪟 WINDOW UTILITIES
-- ═══════════════════════════════════════════════════════════════════════════════

-- Create a floating window
function M.create_float(opts)
    local defaults = {
        width    = math.floor(vim.o.columns * 0.8),
        height   = math.floor(vim.o.lines * 0.8),
        border   = "rounded",
        title    = "",
        relative = "editor",
    }
    opts = vim.tbl_extend("force", defaults, opts or {})

    local buf = vim.api.nvim_create_buf(false, true)

    local win_opts = {
        relative = opts.relative,
        width    = opts.width,
        height   = opts.height,
        col      = math.floor((vim.o.columns - opts.width) / 2),
        row      = math.floor((vim.o.lines - opts.height) / 2),
        border   = opts.border,
        style    = "minimal",
        zindex   = 100,
    }

    if opts.title ~= "" then
        win_opts.title     = opts.title
        win_opts.title_pos = "center"
    end

    local win = vim.api.nvim_open_win(buf, true, win_opts)

    vim.api.nvim_win_set_option(win, "winblend", 10)

    -- Close on Escape or q
    vim.keymap.set("n", "q",   "<cmd>close<CR>", { buffer = buf, silent = true })
    vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = buf, silent = true })

    return buf, win
end

-- Toggle fold method between treesitter and indent
function M.toggle_fold()
    if vim.opt_local.foldmethod:get() == "expr" then
        vim.opt_local.foldmethod = "indent"
        vim.notify("Fold: indent", vim.log.levels.INFO, { title = "Neovim" })
    else
        vim.opt_local.foldmethod = "expr"
        vim.opt_local.foldexpr   = "nvim_treesitter#foldexpr()"
        vim.notify("Fold: treesitter", vim.log.levels.INFO, { title = "Neovim" })
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🚀 CODE RUNNER
-- ═══════════════════════════════════════════════════════════════════════════════

local RUNNERS = {
    python     = "python3 %s",
    javascript = "node %s",
    typescript = "ts-node %s",
    lua        = "lua %s",
    sh         = "bash %s",
    bash       = "bash %s",
    fish       = "fish %s",
    rust       = "cargo run",
    go         = "go run %s",
    c          = "gcc %s -o /tmp/nvim-run && /tmp/nvim-run",
    cpp        = "g++ %s -o /tmp/nvim-run && /tmp/nvim-run",
    ruby       = "ruby %s",
    php        = "php %s",
    julia      = "julia %s",
    r          = "Rscript %s",
    haskell    = "runhaskell %s",
}

function M.run_file()
    local ft   = vim.bo.filetype
    local file = vim.fn.expand("%:p")
    local cmd  = RUNNERS[ft]

    if not cmd then
        vim.notify(
            "No runner for filetype: " .. ft,
            vim.log.levels.WARN,
            { title = "Run File" }
        )
        return
    end

    cmd = cmd:format(file)

    -- Run in toggleterm if available
    local ok, toggleterm = pcall(require, "toggleterm.terminal")
    if ok then
        local term = toggleterm.Terminal:new({
            cmd       = cmd,
            direction = "horizontal",
            close_on_exit = false,
            auto_scroll   = true,
        })
        term:toggle()
    else
        vim.cmd("!" .. cmd)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔎 SEARCH UTILITIES
-- ═══════════════════════════════════════════════════════════════════════════════

-- Search for pattern in current buffer
function M.buf_search(pattern)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local results = {}

    for i, line in ipairs(lines) do
        if line:match(pattern) then
            table.insert(results, { line = i, text = line })
        end
    end

    return results
end

-- Get word under cursor
function M.get_word_under_cursor()
    return vim.fn.expand("<cword>")
end

-- Get visual selection
function M.get_visual_selection()
    local _, ls, cs = table.unpack(vim.fn.getpos("'<"))
    local _, le, ce = table.unpack(vim.fn.getpos("'>"))
    local lines = vim.api.nvim_buf_get_lines(0, ls - 1, le, false)

    if #lines == 0 then return "" end
    if #lines == 1 then
        return lines[1]:sub(cs, ce)
    end

    lines[1]    = lines[1]:sub(cs)
    lines[#lines] = lines[#lines]:sub(1, ce)
    return table.concat(lines, "\n")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📊 BUFFER UTILITIES
-- ═══════════════════════════════════════════════════════════════════════════════

-- Get all loaded buffers
function M.get_loaded_bufs()
    return vim.tbl_filter(function(b)
        return vim.api.nvim_buf_is_loaded(b)
            and vim.api.nvim_buf_get_name(b) ~= ""
    end, vim.api.nvim_list_bufs())
end

-- Count lines in current buffer
function M.line_count()
    return vim.api.nvim_buf_line_count(0)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔧 MISC UTILITIES
-- ═══════════════════════════════════════════════════════════════════════════════

-- Debounce a function call
function M.debounce(fn, delay)
    local timer = nil
    return function(...)
        local args = { ... }
        if timer then
            timer:stop()
        end
        timer = vim.loop.new_timer()
        timer:start(delay, 0, vim.schedule_wrap(function()
            fn(table.unpack(args))
            timer = nil
        end))
    end
end

-- Safe require (returns nil on failure instead of erroring)
function M.safe_require(module)
    local ok, result = pcall(require, module)
    return ok and result or nil
end

-- Check if plugin is available
function M.has_plugin(plugin)
    return M.safe_require(plugin) ~= nil
end

-- Get plugin version
function M.plugin_version(plugin)
    local m = M.safe_require(plugin)
    if not m then return nil end
    return m.version or m.VERSION or "unknown"
end

-- Pretty print a table
function M.dump(t, indent)
    indent = indent or 0
    if type(t) ~= "table" then
        print(string.rep("  ", indent) .. tostring(t))
        return
    end
    for k, v in pairs(t) do
        if type(v) == "table" then
            print(string.rep("  ", indent) .. tostring(k) .. ":")
            M.dump(v, indent + 1)
        else
            print(string.rep("  ", indent) .. tostring(k) .. " = " .. tostring(v))
        end
    end
end

-- Global helper shorthand
_G.dump = M.dump

return M