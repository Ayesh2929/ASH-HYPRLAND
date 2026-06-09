-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — NEOVIM AUTOCOMMANDS                         ║
-- ║           25+ autocommand groups for intelligent behavior                 ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

local function group(name)
    return augroup("ASH_" .. name, { clear = true })
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ✨ HIGHLIGHT ON YANK
-- ═══════════════════════════════════════════════════════════════════════════════

autocmd("TextYankPost", {
    group = group("YankHighlight"),
    desc  = "Flash highlight on yank",
    callback = function()
        vim.highlight.on_yank({
            higroup  = "IncSearch",
            timeout  = 200,
            on_macro = true,
        })
    end,
})

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📐 SMART RELATIVE NUMBERS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Show relative numbers in normal mode, absolute in insert mode
local rn_group = group("SmartRelativeNumbers")

autocmd({ "BufEnter", "FocusGained", "InsertLeave", "WinEnter" }, {
    group    = rn_group,
    desc     = "Enable relative numbers",
    callback = function()
        if vim.opt.number:get() and vim.fn.mode() ~= "i" then
            vim.opt.relativenumber = true
        end
    end,
})

autocmd({ "BufLeave", "FocusLost", "InsertEnter", "WinLeave" }, {
    group    = rn_group,
    desc     = "Disable relative numbers",
    callback = function()
        if vim.opt.number:get() then
            vim.opt.relativenumber = false
        end
    end,
})

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📄 AUTO READ EXTERNAL CHANGES
-- ═══════════════════════════════════════════════════════════════════════════════

autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    group    = group("AutoRead"),
    desc     = "Auto-reload files changed outside Neovim",
    callback = function()
        if vim.fn.mode() ~= "c" and vim.fn.getcmdwintype() == "" then
            vim.cmd("checktime")
        end
    end,
})

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📏 RESTORE CURSOR POSITION
-- ═══════════════════════════════════════════════════════════════════════════════

autocmd("BufReadPost", {
    group    = group("RestoreCursor"),
    desc     = "Restore cursor position on file open",
    callback = function(ev)
        local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
        local lcount = vim.api.nvim_buf_line_count(ev.buf)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🗂️ FILETYPE SPECIFIC SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════════

local ft_group = group("FiletypeSettings")

-- 2-space indent filetypes
autocmd("FileType", {
    group   = ft_group,
    pattern = {
        "lua", "yaml", "json", "jsonc", "html", "css", "scss",
        "javascript", "typescript", "jsx", "tsx", "vue", "svelte",
        "ruby", "toml", "xml", "fish", "sh", "bash",
    },
    desc    = "2-space indent for web/script files",
    callback = function()
        vim.opt_local.tabstop     = 2
        vim.opt_local.shiftwidth  = 2
        vim.opt_local.softtabstop = 2
    end,
})

-- 4-space indent filetypes
autocmd("FileType", {
    group   = ft_group,
    pattern = {
        "python", "rust", "go", "c", "cpp", "java",
        "kotlin", "swift", "php",
    },
    desc    = "4-space indent for systems/backend files",
    callback = function()
        vim.opt_local.tabstop     = 4
        vim.opt_local.shiftwidth  = 4
        vim.opt_local.softtabstop = 4
    end,
})

-- Tab-based indent (Makefile, Go)
autocmd("FileType", {
    group   = ft_group,
    pattern = { "make", "go", "gitconfig" },
    desc    = "Tab-based indent for make/go files",
    callback = function()
        vim.opt_local.expandtab = false
        vim.opt_local.tabstop   = 4
        vim.opt_local.shiftwidth = 4
    end,
})

-- Markdown/text: wrap enabled
autocmd("FileType", {
    group   = ft_group,
    pattern = { "markdown", "text", "tex", "rst", "org" },
    desc    = "Enable wrap for prose files",
    callback = function()
        vim.opt_local.wrap      = true
        vim.opt_local.spell     = true
        vim.opt_local.textwidth = 80
        vim.opt_local.colorcolumn = "80"
    end,
})

-- Git commits: textwidth
autocmd("FileType", {
    group   = ft_group,
    pattern = { "gitcommit", "gitrebase" },
    desc    = "Git commit message settings",
    callback = function()
        vim.opt_local.textwidth   = 72
        vim.opt_local.colorcolumn = "72"
        vim.opt_local.spell       = true
        vim.opt_local.wrap        = true
        -- Jump to top of file
        vim.cmd("0")
    end,
})

-- JSON: show conceal
autocmd("FileType", {
    group   = ft_group,
    pattern = { "json", "jsonc" },
    callback = function()
        vim.opt_local.conceallevel = 0
    end,
})

-- Help: q to close, easier navigation
autocmd("FileType", {
    group   = ft_group,
    pattern = "help",
    callback = function()
        vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = true, silent = true })
    end,
})

-- Man pages: q to close
autocmd("FileType", {
    group   = ft_group,
    pattern = "man",
    callback = function()
        vim.keymap.set("n", "q", "<cmd>quit<CR>", { buffer = true, silent = true })
    end,
})

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔇 DISABLE THINGS IN SPECIAL BUFFERS
-- ═══════════════════════════════════════════════════════════════════════════════

autocmd("FileType", {
    group   = group("SpecialBuffers"),
    pattern = {
        "NvimTree", "Trouble", "lazy", "mason", "lspinfo",
        "checkhealth", "notify", "spectre_panel", "TelescopePrompt",
        "Outline", "aerial", "tagbar", "undotree",
    },
    callback = function()
        vim.opt_local.number         = false
        vim.opt_local.relativenumber = false
        vim.opt_local.signcolumn     = "no"
        vim.opt_local.spell          = false
        vim.opt_local.statuscolumn   = ""
    end,
})

-- ═══════════════════════════════════════════════════════════════════════════════
-- 💾 AUTO SAVE (on focus loss)
-- ═══════════════════════════════════════════════════════════════════════════════

autocmd({ "FocusLost", "BufLeave" }, {
    group    = group("AutoSave"),
    desc     = "Auto-save on focus loss",
    callback = function(ev)
        local buf = ev.buf
        -- Only save normal files (not special buffers, terminals, etc.)
        if vim.api.nvim_buf_get_option(buf, "buftype") == ""
            and vim.api.nvim_buf_get_option(buf, "modifiable")
            and vim.api.nvim_buf_get_option(buf, "modified")
            and vim.api.nvim_buf_get_name(buf) ~= ""
        then
            vim.cmd("silent! write")
        end
    end,
})

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔧 FORMAT ON SAVE (per buffer, controlled by LSP/conform)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Handled in after/plugin/format.lua

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🚪 AUTO CLOSE SPECIFIC FILETYPES WITH q
-- ═══════════════════════════════════════════════════════════════════════════════

autocmd("FileType", {
    group   = group("QuickClose"),
    pattern = {
        "qf", "help", "man", "notify", "lazy", "mason",
        "lspinfo", "toggleterm", "spectre_panel", "neotest-output",
        "neotest-summary", "neotest-output-panel", "aerial",
    },
    callback = function()
        vim.keymap.set("n", "q", "<cmd>close<CR>",
            { buffer = true, silent = true, desc = "Close window" })
    end,
})

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🎨 ASH THEME RELOAD
-- ═══════════════════════════════════════════════════════════════════════════════

-- Watch for ASH color changes and reload theme
autocmd({ "FocusGained", "BufEnter" }, {
    group    = group("AshThemeSync"),
    desc     = "Check for ASH theme updates",
    once     = false,
    callback = function()
        -- Check if color file was modified
        local color_file = vim.fn.expand("~/.cache/ash-dots/colors/current.sh")
        if vim.fn.filereadable(color_file) == 1 then
            -- Defer to avoid blocking
            vim.defer_fn(function()
                local ok, theme = pcall(require, "themes.ash")
                if ok and theme.needs_update and theme.needs_update() then
                    theme.apply()
                end
            end, 100)
        end
    end,
})

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📊 STATUS LINE REFRESH
-- ═══════════════════════════════════════════════════════════════════════════════

autocmd({ "DiagnosticChanged", "LspAttach", "LspDetach" }, {
    group    = group("StatusRefresh"),
    desc     = "Refresh statusline on LSP events",
    callback = function()
        vim.cmd("redrawstatus")
    end,
})

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🌳 TREESITTER FOLDING FIX
-- ═══════════════════════════════════════════════════════════════════════════════

-- Fix treesitter fold when entering buffer
autocmd("BufReadPost", {
    group    = group("TSFoldFix"),
    callback = function()
        if vim.fn.exists(":TSEnable") == 2 then
            vim.cmd("normal! zx")
        end
    end,
})

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔤 LARGE FILE OPTIMIZATION
-- ═══════════════════════════════════════════════════════════════════════════════

autocmd("BufReadPre", {
    group    = group("LargeFileOpt"),
    desc     = "Disable heavy features for large files",
    callback = function(ev)
        local MAX_SIZE = 1024 * 1024  -- 1MB
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(ev.buf))
        if ok and stats and stats.size > MAX_SIZE then
            vim.notify(
                "Large file — some features disabled",
                vim.log.levels.WARN,
                { title = "Neovim" }
            )
            vim.opt_local.syntax        = "off"
            vim.opt_local.spell         = false
            vim.opt_local.undofile      = false
            vim.opt_local.swapfile      = false
            vim.b.large_file            = true

            -- Disable treesitter for large files
            vim.cmd("TSDisable highlight")
        end
    end,
})

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📁 CREATE DIRS ON SAVE
-- ═══════════════════════════════════════════════════════════════════════════════

autocmd("BufWritePre", {
    group    = group("MkdirOnSave"),
    desc     = "Create parent directories on save",
    callback = function(ev)
        local file = vim.api.nvim_buf_get_name(ev.buf)
        local dir  = vim.fn.fnamemodify(file, ":p:h")
        if vim.fn.isdirectory(dir) == 0 then
            vim.fn.mkdir(dir, "p")
        end
    end,
})