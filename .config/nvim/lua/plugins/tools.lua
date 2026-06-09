-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — TOOLS PLUGINS                                ║
-- ║           Telescope, LazyGit, Gitsigns, ToggleTerm, Spectre               ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

return {

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🔭 TELESCOPE — Fuzzy finder
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "nvim-telescope/telescope.nvim",
        tag          = "0.1.x",
        cmd          = "Telescope",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim",
              build = "make",
              cond  = function() return vim.fn.executable("make") == 1 end,
            },
            "nvim-telescope/telescope-file-browser.nvim",
            "nvim-telescope/telescope-ui-select.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        keys = {
            { "<leader><leader>", "<cmd>Telescope find_files<CR>",       desc = "Find files" },
            { "<leader>sf",       "<cmd>Telescope find_files<CR>",       desc = "Find files" },
            { "<leader>sg",       "<cmd>Telescope live_grep<CR>",        desc = "Live grep" },
            { "<leader>sb",       "<cmd>Telescope buffers<CR>",          desc = "Buffers" },
            { "<leader>sh",       "<cmd>Telescope help_tags<CR>",        desc = "Help tags" },
            { "<leader>sr",       "<cmd>Telescope oldfiles<CR>",         desc = "Recent files" },
            { "<leader>sk",       "<cmd>Telescope keymaps<CR>",          desc = "Keymaps" },
            { "<leader>sc",       "<cmd>Telescope commands<CR>",         desc = "Commands" },
            { "<leader>sd",       "<cmd>Telescope diagnostics<CR>",      desc = "Diagnostics" },
            { "<leader>sm",       "<cmd>Telescope marks<CR>",            desc = "Marks" },
            { "<leader>st",       "<cmd>Telescope treesitter<CR>",       desc = "Treesitter" },
            { "<leader>gb",       "<cmd>Telescope git_branches<CR>",     desc = "Git branches" },
            { "<leader>gc",       "<cmd>Telescope git_commits<CR>",      desc = "Git commits" },
            { "<leader>gC",       "<cmd>Telescope git_bcommits<CR>",     desc = "Git buffer commits" },
            { "<leader>.",        "<cmd>Telescope file_browser<CR>",     desc = "File browser" },
        },
        config = function()
            local telescope = require("telescope")
            local actions   = require("telescope.actions")
            local fb_actions = require("telescope").extensions.file_browser and
                require("telescope._extensions.file_browser.actions") or {}

            telescope.setup({
                defaults = {
                    prompt_prefix    = "   ",
                    selection_caret  = "  ",
                    entry_prefix     = "  ",
                    multi_icon       = "  ",
                    initial_mode     = "insert",
                    selection_strategy = "reset",
                    path_display     = { "truncate" },
                    color_devicons   = true,
                    set_env          = { ["COLORTERM"] = "truecolor" },
                    border           = true,
                    borderchars      = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
                    results_title    = false,
                    layout_strategy  = "horizontal",
                    layout_config = {
                        horizontal = {
                            prompt_position = "top",
                            preview_width   = 0.55,
                            results_width   = 0.8,
                        },
                        vertical = {
                            mirror = false,
                        },
                        width    = 0.87,
                        height   = 0.80,
                        preview_cutoff = 120,
                    },
                    sorting_strategy = "ascending",
                    file_sorter      = require("telescope.sorters").get_fuzzy_file,
                    file_ignore_patterns = {
                        "%.git/", "node_modules/", "__pycache__/",
                        "%.pyc", "%.pyo", "%.class",
                        "target/", "dist/", "build/",
                    },
                    generic_sorter    = require("telescope.sorters").get_generic_fuzzy_sorter,
                    winblend          = 10,
                    mappings = {
                        i = {
                            ["<C-j>"]  = actions.move_selection_next,
                            ["<C-k>"]  = actions.move_selection_previous,
                            ["<C-n>"]  = actions.cycle_history_next,
                            ["<C-p>"]  = actions.cycle_history_prev,
                            ["<C-c>"]  = actions.close,
                            ["<Esc>"]  = actions.close,
                            ["<CR>"]   = actions.select_default,
                            ["<C-x>"]  = actions.select_horizontal,
                            ["<C-v>"]  = actions.select_vertical,
                            ["<C-t>"]  = actions.select_tab,
                            ["<C-u>"]  = actions.preview_scrolling_up,
                            ["<C-d>"]  = actions.preview_scrolling_down,
                            ["<C-q>"]  = actions.send_to_qflist + actions.open_qflist,
                            ["<M-q>"]  = actions.send_selected_to_qflist + actions.open_qflist,
                            ["<C-l>"]  = actions.complete_tag,
                            ["<Tab>"]  = actions.toggle_selection + actions.move_selection_worse,
                            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
                            ["<C-a>"]  = actions.select_all,
                            ["<C-/>"]  = actions.which_key,
                        },
                        n = {
                            ["q"]      = actions.close,
                            ["<Esc>"]  = actions.close,
                            ["<CR>"]   = actions.select_default,
                            ["<C-x>"]  = actions.select_horizontal,
                            ["<C-v>"]  = actions.select_vertical,
                            ["<C-t>"]  = actions.select_tab,
                            ["j"]      = actions.move_selection_next,
                            ["k"]      = actions.move_selection_previous,
                            ["gg"]     = actions.move_to_top,
                            ["G"]      = actions.move_to_bottom,
                            ["<C-u>"]  = actions.preview_scrolling_up,
                            ["<C-d>"]  = actions.preview_scrolling_down,
                            ["<Tab>"]  = actions.toggle_selection + actions.move_selection_worse,
                            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
                            ["<C-q>"]  = actions.send_to_qflist + actions.open_qflist,
                            ["?"]      = actions.which_key,
                        },
                    },
                },
                pickers = {
                    find_files = {
                        find_command = { "fd", "--type", "f", "--hidden", "--follow",
                                         "--exclude", ".git", "--exclude", "node_modules" },
                    },
                    live_grep = {
                        additional_args = { "--hidden", "--glob", "!.git/*" },
                    },
                    buffers = {
                        sort_mru    = true,
                        sort_lastused = true,
                        ignore_current_buffer = true,
                    },
                    git_commits = {
                        mappings = {
                            i = { ["<CR>"] = actions.git_checkout },
                        },
                    },
                    colorscheme = { enable_preview = true },
                },
                extensions = {
                    fzf = {
                        fuzzy                   = true,
                        override_generic_sorter = true,
                        override_file_sorter    = true,
                        case_mode               = "smart_case",
                    },
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown({
                            winblend = 10,
                            border   = true,
                        }),
                    },
                    file_browser = {
                        hijack_netrw = false,
                        hidden       = true,
                        dir_icon     = "",
                        grouped      = true,
                        files        = true,
                        auto_depth   = true,
                    },
                },
            })

            -- Load extensions
            pcall(telescope.load_extension, "fzf")
            pcall(telescope.load_extension, "ui-select")
            pcall(telescope.load_extension, "file_browser")
            pcall(telescope.load_extension, "notify")
        end,
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🐙 GITSIGNS — Git decorations
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            signs = {
                add          = { text = "▎" },
                change       = { text = "▎" },
                delete       = { text = "" },
                topdelete    = { text = "" },
                changedelete = { text = "▎" },
                untracked    = { text = "▎" },
            },
            signs_staged = {
                add          = { text = "▎" },
                change       = { text = "▎" },
                delete       = { text = "" },
                topdelete    = { text = "" },
                changedelete = { text = "▎" },
            },
            signs_staged_enable  = true,
            signcolumn           = true,
            numhl                = true,
            linehl               = false,
            word_diff            = false,
            watch_gitdir         = { follow_files = true },
            auto_attach          = true,
            attach_to_untracked  = false,
            current_line_blame   = false,
            current_line_blame_opts = {
                virt_text         = true,
                virt_text_pos     = "eol",
                delay             = 1000,
                ignore_whitespace = false,
                virt_text_priority = 100,
            },
            current_line_blame_formatter = "<author>, <author_time:%R> • <summary>",
            sign_priority        = 6,
            update_debounce      = 100,
            status_formatter     = nil,
            max_file_length      = 40000,
            preview_config = {
                border   = "rounded",
                style    = "minimal",
                relative = "cursor",
                row      = 0,
                col      = 1,
            },
            on_attach = function(bufnr)
                local gs = package.loaded.gitsigns

                local function map(mode, l, r, desc)
                    vim.keymap.set(mode, l, r,
                        { buffer = bufnr, desc = desc, noremap = true, silent = true })
                end

                -- Navigation
                map("n", "]h", function()
                    if vim.wo.diff then vim.cmd.normal({ "]c", bang = true })
                    else gs.next_hunk() end
                end, "Next hunk")

                map("n", "[h", function()
                    if vim.wo.diff then vim.cmd.normal({ "[c", bang = true })
                    else gs.prev_hunk() end
                end, "Prev hunk")

                -- Actions
                map("n", "<leader>gp", gs.preview_hunk,         "Preview hunk")
                map("n", "<leader>gP", gs.preview_hunk_inline,  "Preview hunk inline")
                map("n", "<leader>gs", gs.stage_hunk,           "Stage hunk")
                map("n", "<leader>gS", gs.stage_buffer,         "Stage buffer")
                map("n", "<leader>gr", gs.reset_hunk,           "Reset hunk")
                map("n", "<leader>gR", gs.reset_buffer,         "Reset buffer")
                map("n", "<leader>gu", gs.undo_stage_hunk,      "Undo stage hunk")
                map("n", "<leader>gd", gs.diffthis,             "Diff this")
                map("n", "<leader>gl", gs.blame_line,           "Blame line")
                map("n", "<leader>gL", gs.toggle_current_line_blame, "Toggle blame")
                map("n", "<leader>gw", gs.toggle_word_diff,     "Toggle word diff")

                -- Visual mode
                map("v", "<leader>gs", function()
                    gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, "Stage selected hunk")
                map("v", "<leader>gr", function()
                    gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, "Reset selected hunk")

                -- Text objects
                map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select hunk")
            end,
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 💻 TOGGLETERM — Terminal integration
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        keys    = {
            { "<C-\\>",     "<cmd>ToggleTerm<CR>",         desc = "Toggle terminal" },
            { "<leader>tf", "<cmd>ToggleTerm direction=float<CR>",      desc = "Float terminal" },
            { "<leader>th", "<cmd>ToggleTerm direction=horizontal<CR>", desc = "Horizontal terminal" },
            { "<leader>tv", "<cmd>ToggleTerm direction=vertical<CR>",   desc = "Vertical terminal" },
        },
        opts = {
            size = function(term)
                if term.direction == "horizontal" then return 18
                elseif term.direction == "vertical" then
                    return math.floor(vim.o.columns * 0.4)
                end
            end,
            open_mapping   = [[<C-\>]],
            hide_numbers   = true,
            shade_filetypes = {},
            autochdir      = true,
            highlights = {
                Normal         = { link = "Normal" },
                NormalFloat    = { link = "NormalFloat" },
                FloatBorder    = { link = "FloatBorder" },
            },
            shade_terminals  = false,
            start_in_insert  = true,
            insert_mappings  = true,
            terminal_mappings = true,
            persist_size     = true,
            persist_mode     = true,
            direction        = "float",
            close_on_exit    = true,
            shell            = vim.o.shell,
            auto_scroll      = true,
            float_opts = {
                border        = "curved",
                width         = function() return math.floor(vim.o.columns * 0.85) end,
                height        = function() return math.floor(vim.o.lines * 0.85) end,
                winblend      = 10,
                zindex        = 200,
                title_pos     = "center",
            },
            winbar = {
                enabled    = false,
                name_formatter = function(term)
                    return term.name
                end,
            },
        },
        config = function(_, opts)
            require("toggleterm").setup(opts)

            -- Custom terminal instances
            local Terminal = require("toggleterm.terminal").Terminal

            -- LazyGit
            local lazygit = Terminal:new({
                cmd        = "lazygit",
                dir        = "git_dir",
                direction  = "float",
                hidden     = true,
                on_open    = function(term)
                    vim.cmd("startinsert!")
                    vim.keymap.set("n", "q", "<cmd>close<CR>",
                        { buffer = term.bufnr, noremap = true, silent = true })
                end,
                float_opts = {
                    border   = "curved",
                    width    = function() return math.floor(vim.o.columns * 0.95) end,
                    height   = function() return math.floor(vim.o.lines * 0.95) end,
                },
            })

            -- btop system monitor
            local btop = Terminal:new({
                cmd       = "btop",
                direction = "float",
                hidden    = true,
                float_opts = {
                    border = "curved",
                    width  = function() return math.floor(vim.o.columns * 0.95) end,
                    height = function() return math.floor(vim.o.lines * 0.95) end,
                },
            })

            -- Python REPL
            local python = Terminal:new({
                cmd       = "python3",
                direction = "horizontal",
                hidden    = true,
            })

            -- Global functions for keymaps
            _G.ash_lazygit = function() lazygit:toggle() end
            _G.ash_btop    = function() btop:toggle() end
            _G.ash_python  = function() python:toggle() end

            -- Keymaps
            vim.keymap.set("n", "<leader>tg", _G.ash_lazygit, { desc = "LazyGit" })
            vim.keymap.set("n", "<leader>tm", _G.ash_btop,    { desc = "System Monitor (btop)" })
            vim.keymap.set("n", "<leader>tp", _G.ash_python,  { desc = "Python REPL" })
        end,
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🔍 SPECTRE — Find and replace across files
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "nvim-pack/nvim-spectre",
        cmd  = "Spectre",
        keys = {
            { "<leader>rS", function() require("spectre").toggle() end,           desc = "Spectre toggle" },
            { "<leader>rw", function() require("spectre").open_visual({ select_word = true }) end,
              desc = "Search word (Spectre)", mode = { "n", "v" } },
            { "<leader>rf", function() require("spectre").open_file_search({ select_word = true }) end,
              desc = "Replace in file (Spectre)" },
        },
        opts = {
            color_devicons = true,
            open_cmd       = "vnew",
            live_update    = false,
            lnum_for_results = true,
            line_sep_start  = "┌─────────────────────────────────────────",
            result_padding  = "│  ",
            line_sep        = "└─────────────────────────────────────────",
            highlight = {
                ui      = "String",
                search  = "DiffChange",
                replace = "DiffDelete",
            },
            mapping = {
                ["toggle_line"] = {
                    map  = "dd",
                    cmd  = "<cmd>lua require('spectre').toggle_line()<CR>",
                    desc = "Toggle current item",
                },
                ["enter_file"] = {
                    map  = "<cr>",
                    cmd  = "<cmd>lua require('spectre.actions').select_entry()<CR>",
                    desc = "Go to file",
                },
                ["send_to_qf"] = {
                    map  = "<leader>q",
                    cmd  = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
                    desc = "Send to quickfix",
                },
                ["replace_cmd"] = {
                    map  = "<leader>c",
                    cmd  = "<cmd>lua require('spectre.actions').replace_cmd()<CR>",
                    desc = "Input replace command",
                },
                ["show_option_menu"] = {
                    map  = "<leader>o",
                    cmd  = "<cmd>lua require('spectre').show_options()<CR>",
                    desc = "Show option",
                },
                ["run_current_replace"] = {
                    map  = "<leader>rc",
                    cmd  = "<cmd>lua require('spectre.actions').run_current_replace()<CR>",
                    desc = "Replace current line",
                },
                ["run_replace"] = {
                    map  = "<leader>R",
                    cmd  = "<cmd>lua require('spectre.actions').run_replace()<CR>",
                    desc = "Replace all",
                },
            },
        },
    },
}