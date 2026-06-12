-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — NEOVIM PLUGINS INDEX                         ║
-- ║           Root plugin loader — imports all plugin modules                  ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

-- This file serves as the plugin index
-- All plugin specs are split across dedicated modules:
--   plugins/ui.lua     — UI plugins (Noice, NvimTree, Bufferline, etc.)
--   plugins/lsp.lua    — LSP, completion, formatting, linting
--   plugins/editor.lua — Editor enhancements (autopairs, surround, etc.)
--   plugins/tools.lua  — Telescope, LazyGit, Gitsigns, ToggleTerm
--   plugins/debug.lua  — DAP debugging + Neotest
--   plugins/lang.lua   — Language-specific plugins
--   plugins/ai.lua     — AI completion (Codeium, Ollama)

-- Additional global plugins not in other files:
return {
    -- ── Plenary (required by many plugins) ───────────────────────────────────
    {
        "nvim-lua/plenary.nvim",
        lazy = true,
    },

    -- ── SchemaStore (JSON/YAML schemas) ──────────────────────────────────────
    {
        "b0o/SchemaStore.nvim",
        lazy = true,
        version = false,
    },

    -- ── Mini.nvim extras ─────────────────────────────────────────────────────
    {
        "echasnovski/mini.nvim",
        version = "*",
        lazy = true,
    },

    -- ── Vim-sleuth (auto-detect indentation) ─────────────────────────────────
    {
        "tpope/vim-sleuth",
        event = "BufReadPre",
    },

    -- ── Repeat (. repeat for plugins) ────────────────────────────────────────
    {
        "tpope/vim-repeat",
        event = "BufReadPost",
    },

    -- ── Snacks (QoL improvements) ─────────────────────────────────────────────
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy     = false,
        opts = {
            bigfile  = { enabled = true },
            notifier = { enabled = true },
            quickfile = { enabled = true },
            statuscolumn = { enabled = true },
            words    = { enabled = true },
        },
    },

    -- ── Better escape ─────────────────────────────────────────────────────────
    {
        "max397574/better-escape.nvim",
        event = "InsertEnter",
        opts  = {
            mappings = {
                i = { j = { k = "<Esc>", j = "<Esc>" } },
                v = { j = { k = "<Esc>" } },
                s = { j = { k = "<Esc>" } },
            },
        },
    },

    -- ── Flash.nvim (enhanced motion) ─────────────────────────────────────────
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        opts  = {
            modes = {
                search = { enabled = false },
                char   = { enabled = true, jump_labels = true },
            },
        },
        keys  = {
            { "s",     mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash" },
            { "S",     mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },
            { "r",     mode = "o",               function() require("flash").remote() end,             desc = "Remote Flash" },
            { "R",     mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
            { "<C-s>", mode = { "c" },           function() require("flash").toggle() end,            desc = "Toggle Flash Search" },
        },
    },

    -- ── Persistence (session management) ─────────────────────────────────────
    {
        "folke/persistence.nvim",
        event = "BufReadPre",
        opts  = {
            dir     = vim.fn.stdpath("state") .. "/sessions/",
            options = { "buffers", "curdir", "tabpages", "winsize", "help", "blank", "terminal" },
            pre_save = nil,
        },
        keys  = {
            { "<leader>qs", function() require("persistence").load() end,                desc = "Restore session" },
            { "<leader>qS", function() require("persistence").select() end,              desc = "Select session" },
            { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
            { "<leader>qd", function() require("persistence").stop() end,               desc = "Stop persistence" },
        },
    },

    -- ── Undotree (visual undo history) ───────────────────────────────────────
    {
        "mbbill/undotree",
        cmd  = "UndotreeToggle",
        keys = {
            { "<leader>uu", "<cmd>UndotreeToggle<CR>", desc = "Undo Tree" },
        },
    },

    -- ── Markdown preview (handled in lang.lua) ────────────────────────────────

    -- ── Wakatime (time tracking — optional) ──────────────────────────────────
    -- { "wakatime/vim-wakatime", event = "VeryLazy" },
}