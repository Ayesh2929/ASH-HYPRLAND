-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — LAZY.NVIM BOOTSTRAP                         ║
-- ║           Plugin manager setup with performance optimizations              ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📦 BOOTSTRAP LAZY.NVIM
-- ═══════════════════════════════════════════════════════════════════════════════

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
    vim.notify("Installing lazy.nvim...", vim.log.levels.INFO)
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--single-branch",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end

vim.opt.runtimepath:prepend(lazypath)

-- ═══════════════════════════════════════════════════════════════════════════════
-- ⚙️ LAZY CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════════════════

require("lazy").setup({

    -- ── Plugin specs ─────────────────────────────────────────────────────────
    spec = {
        { import = "plugins" },      -- lua/plugins/init.lua
        { import = "plugins.ui" },
        { import = "plugins.lsp" },
        { import = "plugins.editor" },
        { import = "plugins.tools" },
        { import = "plugins.debug" },
        { import = "plugins.lang" },
        { import = "plugins.ai" },
    },

    -- ── Defaults ─────────────────────────────────────────────────────────────
    defaults = {
        lazy    = true,       -- All plugins lazy by default
        version = nil,        -- Use latest commits (not versioned releases)
    },

    -- ── Install ───────────────────────────────────────────────────────────────
    install = {
        missing     = true,   -- Auto-install missing plugins on startup
        colorscheme = { "habamax" },  -- Fallback colorscheme during install
    },

    -- ── UI ────────────────────────────────────────────────────────────────────
    ui = {
        size    = { width = 0.85, height = 0.85 },
        border  = "rounded",
        backdrop = 85,
        title   = "  lazy.nvim — ASH Plugin Manager",
        title_pos = "center",
        pills   = true,
        icons = {
            cmd        = " ",
            config     = "",
            event      = " ",
            ft         = " ",
            init       = " ",
            import     = " ",
            keys       = " ",
            lazy       = "󰒲 ",
            loaded     = "● ",
            not_loaded = "○ ",
            plugin     = " ",
            runtime    = " ",
            require    = "󰢱 ",
            source     = " ",
            start      = " ",
            task       = "✔ ",
            list = {
                "●",
                "➜",
                "★",
                "‒",
            },
        },
    },

    -- ── Checker ───────────────────────────────────────────────────────────────
    checker = {
        enabled = true,        -- Check for updates automatically
        notify  = false,       -- Don't notify (check via :Lazy check)
        frequency = 3600,      -- Check every hour
    },

    -- ── Change detection ──────────────────────────────────────────────────────
    change_detection = {
        enabled = true,        -- Auto-detect config changes
        notify  = true,        -- Notify on change detection
    },

    -- ── Performance ───────────────────────────────────────────────────────────
    performance = {
        cache = {
            enabled = true,
            path    = vim.fn.stdpath("cache") .. "/lazy/cache",
        },
        reset_packpath = true,
        rtp = {
            reset  = true,
            disabled_plugins = {
                "gzip",
                "matchit",
                "matchparen",
                "netrwPlugin",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
            },
        },
    },

    -- ── Lockfile ──────────────────────────────────────────────────────────────
    lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",

}, {
    -- ── Setup options ─────────────────────────────────────────────────────────
    root      = vim.fn.stdpath("data") .. "/lazy",
    concurrency = 8,
})

-- ═══════════════════════════════════════════════════════════════════════════════
-- ⌨️ LAZY KEYMAPS
-- ═══════════════════════════════════════════════════════════════════════════════

vim.keymap.set("n", "<leader>l",  "<cmd>Lazy<CR>",        { desc = "Lazy plugin manager" })
vim.keymap.set("n", "<leader>lu", "<cmd>Lazy update<CR>", { desc = "Lazy update plugins" })
vim.keymap.set("n", "<leader>ls", "<cmd>Lazy sync<CR>",   { desc = "Lazy sync plugins" })
vim.keymap.set("n", "<leader>lc", "<cmd>Lazy clean<CR>",  { desc = "Lazy clean plugins" })