-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — EDITOR PLUGINS                               ║
-- ║           Autopairs, commenting, surround, dressing, mini                 ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

return {

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🤖 AUTOPAIRS — Auto-close brackets/quotes
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "windwp/nvim-autopairs",
        event  = "InsertEnter",
        opts = {
            check_ts            = true,
            ts_config           = {
                lua  = { "string", "source" },
                javascript = { "string", "template_string" },
                java = false,
            },
            disable_filetype    = { "TelescopePrompt", "vim" },
            fast_wrap           = {
                map             = "<M-e>",
                chars           = { "{", "[", "(", '"', "'" },
                pattern         = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
                offset          = 0,
                end_key         = "$",
                keys            = "qwertyuiopzxcvbnmasdfghjkl",
                check_comma     = true,
                highlight       = "PmenuSel",
                highlight_grey  = "LineNr",
            },
        },
        config = function(_, opts)
            local autopairs = require("nvim-autopairs")
            autopairs.setup(opts)

            -- Integration with nvim-cmp
            local cmp_autopairs = require("nvim-autopairs.completion.cmp")
            local ok, cmp = pcall(require, "cmp")
            if ok then
                cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
            end
        end,
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 💬 COMMENT.NVIM — Smart commenting
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "numToStr/Comment.nvim",
        event = "BufReadPost",
        dependencies = {
            "JoosepAlviste/nvim-ts-context-commentstring",
        },
        config = function()
            require("Comment").setup({
                padding    = true,
                sticky     = true,
                ignore     = "^$",
                toggler    = { line = "gcc", block = "gbc" },
                opleader   = { line = "gc",  block = "gb" },
                extra      = { above = "gcO", below = "gco", eol = "gcA" },
                mappings   = { basic = true, extra = true },
                pre_hook   = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
            })
        end,
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🔤 NVIM-SURROUND — Surround with pairs
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "kylechui/nvim-surround",
        version = "*",
        event   = "BufReadPost",
        opts    = {
            keymaps = {
                insert          = "<C-g>s",
                insert_line     = "<C-g>S",
                normal          = "ys",
                normal_cur      = "yss",
                normal_line     = "yS",
                normal_cur_line = "ySS",
                visual          = "S",
                visual_line     = "gS",
                delete          = "ds",
                change          = "cs",
                change_line     = "cS",
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🎭 NVIM-DRESSING — Better UI for vim.ui
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "stevearc/dressing.nvim",
        event = "VeryLazy",
        opts  = {
            input = {
                enabled       = true,
                default_prompt = "Input:",
                trim_prompt   = true,
                title_pos     = "left",
                insert_only   = true,
                start_in_insert = true,
                border        = "rounded",
                relative      = "cursor",
                prefer_width  = 40,
                width         = nil,
                max_width     = { 140, 0.9 },
                min_width     = { 20,  0.2 },
                win_options   = {
                    winblend    = 10,
                    wrap        = false,
                    list        = true,
                    listchars   = "precedes:…,extends:…",
                    sidescrolloff = 0,
                },
                mappings = {
                    n = { ["<Esc>"] = "Close", ["<CR>"] = "Confirm" },
                    i = {
                        ["<C-c>"] = "Close",
                        ["<CR>"]  = "Confirm",
                        ["<Up>"]  = "HistoryPrev",
                        ["<Down>"] = "HistoryNext",
                    },
                },
            },
            select = {
                enabled       = true,
                backend       = { "telescope", "fzf_lua", "fzf", "builtin", "nui" },
                trim_prompt   = true,
                telescope     = require("telescope.themes").get_dropdown({
                    winblend  = 10,
                    width     = 0.5,
                }),
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 📑 TODO COMMENTS — Highlight TODO/FIXME/NOTE
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        event        = "BufReadPost",
        keys         = {
            { "<leader>xt", "<cmd>TodoTelescope<CR>",     desc = "TODO list" },
            { "<leader>xT", "<cmd>TodoTrouble<CR>",       desc = "TODO (Trouble)" },
            { "]t",  function() require("todo-comments").jump_next() end, desc = "Next TODO" },
            { "[t",  function() require("todo-comments").jump_prev() end, desc = "Prev TODO" },
        },
        opts = {
            signs      = true,
            sign_priority = 8,
            keywords   = {
                FIX      = { icon = " ", color = "error",   alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
                TODO     = { icon = " ", color = "info" },
                HACK     = { icon = " ", color = "warning", alt = { "TRICK", "WORKAROUND" } },
                WARN     = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
                PERF     = { icon = " ", color = "default", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
                NOTE     = { icon = " ", color = "hint",    alt = { "INFO", "NOTE" } },
                TEST     = { icon = "⏲ ", color = "test",   alt = { "TESTING", "PASSED", "FAILED" } },
            },
            gui_style  = { fg = "NONE",   bg = "BOLD" },
            merge_keywords = true,
            highlight  = {
                multiline         = true,
                multiline_pattern = "^.",
                multiline_context = 10,
                before            = "",
                keyword           = "wide",
                after             = "fg",
                pattern           = [[.*<(KEYWORDS)\s*:]],
                comments_only     = true,
                max_line_len      = 400,
                exclude           = {},
            },
            colors = {
                error   = { "DiagnosticError",   "ErrorMsg",   "#f38ba8" },
                warning = { "DiagnosticWarn",    "WarningMsg", "#f9e2af" },
                info    = { "DiagnosticInfo",               "#89b4fa" },
                hint    = { "DiagnosticHint",               "#a6e3a1" },
                default = { "Identifier",                   "#cba6f7" },
                test    = { "Identifier",                   "#94e2d5" },
            },
            search = {
                command    = "rg",
                args       = { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column" },
                pattern    = [[\b(KEYWORDS):]],
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 📏 MINI.INDENTSCOPE — Animated indent scope
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "echasnovski/mini.indentscope",
        version = "*",
        event   = "BufReadPost",
        init    = function()
            vim.api.nvim_create_autocmd("FileType", {
                pattern  = { "help", "alpha", "dashboard", "NvimTree", "lazy", "mason", "notify" },
                callback = function() vim.b.miniindentscope_disable = true end,
            })
        end,
        opts = {
            symbol   = "│",
            options  = { try_as_border = true },
            draw     = {
                delay    = 100,
                animation = require("mini.indentscope").gen_animation.none(),
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🔎 NVIM-HLSEARCH — Better search highlighting
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "nvimdev/hlsearch.nvim",
        event = "BufReadPost",
        opts  = {},
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- ✨ YANKY — Enhanced yank/paste
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "gbprod/yanky.nvim",
        dependencies = { "kkharji/sqlite.lua", optional = true },
        event        = "BufReadPost",
        keys = {
            { "y",    "<Plug>(YankyYank)",         mode = { "n", "x" },   desc = "Yank" },
            { "p",    "<Plug>(YankyPutAfter)",      mode = { "n", "x" },   desc = "Put after" },
            { "P",    "<Plug>(YankyPutBefore)",     mode = { "n", "x" },   desc = "Put before" },
            { "gp",   "<Plug>(YankyGPutAfter)",     mode = { "n", "x" },   desc = "GPut after" },
            { "gP",   "<Plug>(YankyGPutBefore)",    mode = { "n", "x" },   desc = "GPut before" },
            { "<C-p>", "<Plug>(YankyCycleForward)",  desc = "Cycle yank forward" },
            { "<C-n>", "<Plug>(YankyCycleBackward)", desc = "Cycle yank backward" },
            { "<leader>yh", "<cmd>YankyRingHistory<CR>",  desc = "Yank history" },
        },
        opts = {
            ring = {
                history_length    = 100,
                storage           = "shada",
                storage_path      = vim.fn.stdpath("data") .. "/databases/yanky.db",
                sync_with_numbered_registers = true,
                cancel_event      = "update",
                ignore_registers  = { "_" },
            },
            picker = {
                select   = { action = nil },
                telescope = {
                    use_default_mappings = true,
                },
            },
            system_clipboard = {
                sync_with_ring = true,
            },
            highlight = {
                on_put  = true,
                on_yank = true,
                timer   = 200,
            },
            preserve_cursor_position = {
                enabled = true,
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🔍 BETTER QUICKFIX
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "kevinhwang91/nvim-bqf",
        ft   = "qf",
        opts = {
            auto_enable   = true,
            auto_resize_height = true,
            preview = {
                win_height        = 12,
                win_vheight       = 12,
                delay_syntax      = 80,
                border            = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
                show_title        = false,
                should_preview_cb = function(bufnr, qwinid)
                    local ret = true
                    local bufname = vim.api.nvim_buf_get_name(bufnr)
                    local fsize   = vim.fn.getfsize(bufname)
                    if fsize > 100 * 1024 then ret = false end
                    return ret
                end,
            },
            func_map = {
                drop       = "o",
                openc      = "O",
                split      = "<C-s>",
                tabdrop    = "<C-t>",
                tabc       = "",
                ptogglemode = "z,",
            },
        },
    },
}