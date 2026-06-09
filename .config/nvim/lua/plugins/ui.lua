-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — UI PLUGINS                                   ║
-- ║           Noice, Notify, NvimTree, Bufferline, Dashboard                  ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

return {

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🎨 COLORSCHEME — Catppuccin (base theme, overridden by ASH theme)
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "catppuccin/nvim",
        name     = "catppuccin",
        priority = 1000,
        lazy     = false,
        opts = {
            flavour             = "mocha",
            background          = { light = "latte", dark = "mocha" },
            transparent_background = false,
            show_end_of_buffer  = false,
            term_colors         = true,
            dim_inactive        = { enabled = false },
            no_italic           = false,
            no_bold             = false,
            no_underline        = false,
            styles = {
                comments    = { "italic" },
                conditionals = { "italic" },
                loops       = {},
                functions   = { "bold" },
                keywords    = { "italic" },
                strings     = {},
                variables   = {},
                numbers     = {},
                booleans    = {},
                properties  = {},
                types       = { "bold" },
                operators   = {},
            },
            integrations = {
                cmp            = true,
                gitsigns       = true,
                nvimtree       = true,
                treesitter     = true,
                telescope      = { enabled = true, style = "nvchad" },
                which_key      = true,
                bufferline     = true,
                mason          = true,
                noice          = true,
                notify         = true,
                native_lsp     = {
                    enabled = true,
                    virtual_text = {
                        errors      = { "italic" },
                        hints       = { "italic" },
                        warnings    = { "italic" },
                        information = { "italic" },
                    },
                    underlines = {
                        errors      = { "underline" },
                        hints       = { "underline" },
                        warnings    = { "underline" },
                        information = { "underline" },
                    },
                    inlay_hints = { background = true },
                },
                mini           = { enabled = true, indentscope_color = "" },
            },
        },
        config = function(_, opts)
            require("catppuccin").setup(opts)
            -- Will be overridden by ASH theme engine
            vim.cmd("colorscheme catppuccin")
        end,
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🔔 NOICE — Enhanced UI (cmdline, messages, notifications)
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "folke/noice.nvim",
        event   = "VeryLazy",
        dependencies = {
            "MunifTanjim/nui.nvim",
            "rcarriga/nvim-notify",
        },
        opts = {
            lsp = {
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"]                = true,
                    ["cmp.entry.get_documentation"]                  = true,
                },
                hover    = { enabled = true },
                signature = { enabled = true },
                progress  = { enabled = true, throttle = 1000 / 30 },
                message   = { enabled = true },
            },
            routes = {
                -- Hide "written" messages
                { filter = { event = "msg_done",  find = "%d+L, %d+B" },       view = "mini" },
                { filter = { event = "msg_show",  find = "%d+ lines, %d+ bytes" }, view = "mini" },
                { filter = { event = "msg_show",  kind = "search_count" },      opts = { skip = true } },
                -- Hide nvim-cmp completion docs
                { filter = { event = "msg_show",  find = "^/" },                opts = { skip = true } },
                -- Reroute long messages to split
                { filter = { event = "msg_show",  min_height = 20 },            view = "split" },
                -- Cmdline
                { filter = { cmdline = true },                                  view = "cmdline" },
            },
            presets = {
                bottom_search          = true,    -- Classic bottom-of-screen cmdline
                command_palette        = true,    -- Positioning for command palette
                long_message_to_split  = true,    -- Long messages in split
                inc_rename             = true,    -- Rename input in the correct position
                lsp_doc_border         = true,    -- Border for LSP docs
            },
            views = {
                cmdline_popup = {
                    position = { row = "50%", col = "50%" },
                    size     = { width = 60, height = "auto" },
                    border   = { style = "rounded", padding = { 0, 1 } },
                    win_options = {
                        winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
                    },
                },
                popupmenu = {
                    relative = "editor",
                    position = { row = "57%", col = "50%" },
                    size     = { width = 60, height = 10 },
                    border   = { style = "rounded", padding = { 0, 1 } },
                },
            },
        },
        keys = {
            { "<leader>nh",  function() require("noice").cmd("history")  end, desc = "Noice history" },
            { "<leader>na",  function() require("noice").cmd("all")      end, desc = "Noice all messages" },
            { "<leader>nd",  function() require("noice").cmd("dismiss")  end, desc = "Noice dismiss" },
            { "<leader>nl",  function() require("noice").cmd("last")     end, desc = "Noice last message" },
            { "<C-f>", function()
                if not require("noice.lsp").scroll(4) then return "<C-f>" end
            end, silent = true, expr = true, desc = "Scroll forward", mode = { "i", "n", "s" } },
            { "<C-b>", function()
                if not require("noice.lsp").scroll(-4) then return "<C-b>" end
            end, silent = true, expr = true, desc = "Scroll back", mode = { "i", "n", "s" } },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🔔 NVIM-NOTIFY — Notification system
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "rcarriga/nvim-notify",
        event = "VeryLazy",
        opts = {
            timeout     = 3000,
            max_height  = function() return math.floor(vim.o.lines * 0.75) end,
            max_width   = function() return math.floor(vim.o.columns * 0.75) end,
            on_open     = function(win)
                vim.api.nvim_win_set_config(win, { zindex = 100 })
            end,
            render      = "wrapped-compact",
            stages      = "fade_in_slide_out",
            top_down    = false,
            background_colour = "NotifyBackground",
            icons = {
                DEBUG = "",
                ERROR = "",
                INFO  = "",
                TRACE = "✎",
                WARN  = "",
            },
        },
        config = function(_, opts)
            require("notify").setup(opts)
            vim.notify = require("notify")
        end,
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 📁 NVIM-TREE — File explorer
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        cmd          = { "NvimTreeToggle", "NvimTreeOpen", "NvimTreeFocus", "NvimTreeFindFile" },
        keys = {
            { "<leader>e",  "<cmd>NvimTreeToggle<CR>",   desc = "File Explorer" },
            { "<leader>E",  "<cmd>NvimTreeFocus<CR>",    desc = "Focus Explorer" },
            { "<leader>ef", "<cmd>NvimTreeFindFile<CR>", desc = "Find in Explorer" },
        },
        opts = {
            hijack_cursor           = true,
            auto_reload_on_write    = true,
            disable_netrw           = true,
            hijack_netrw            = true,
            hijack_unnamed_buffer_when_opening = false,
            sort = {
                sorter = "case_sensitive",
                folders_first = true,
            },
            sync_root_with_cwd      = true,
            reload_on_bufenter      = false,
            respect_buf_cwd         = false,
            on_attach = function(bufnr)
                local api = require("nvim-tree.api")
                local function opt(desc)
                    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
                end

                api.config.mappings.default_on_attach(bufnr)

                -- Custom mappings
                vim.keymap.set("n", "l",    api.node.open.edit,          opt("Open"))
                vim.keymap.set("n", "h",    api.node.navigate.parent_close, opt("Close Directory"))
                vim.keymap.set("n", "v",    api.node.open.vertical,      opt("Open: Vertical Split"))
                vim.keymap.set("n", "s",    api.node.open.horizontal,    opt("Open: Horizontal Split"))
                vim.keymap.set("n", "?",    api.tree.toggle_help,        opt("Help"))
            end,
            view = {
                width           = 32,
                side            = "left",
                preserve_window_proportions = false,
                number          = false,
                relativenumber  = false,
                signcolumn      = "yes",
            },
            renderer = {
                root_folder_label   = ":~:s?$?/..?",
                add_trailing        = true,
                full_name           = false,
                highlight_git       = true,
                highlight_opened_files = "name",
                highlight_modified  = "none",
                highlight_bookmarks = "none",
                indent_markers = {
                    enable     = true,
                    inline_arrows = true,
                    icons = { corner = "└", edge = "│", item = "│", bottom = "─", none = " " },
                },
                icons = {
                    webdev_colors   = true,
                    git_placement   = "before",
                    modified_placement = "after",
                    show = { file = true, folder = true, folder_arrow = true, git = true, modified = true },
                    glyphs = {
                        default     = "󰈚",
                        symlink     = "",
                        bookmark    = "󰆤",
                        modified    = "●",
                        folder = {
                            arrow_closed = "",
                            arrow_open   = "",
                            default      = "",
                            open         = "",
                            empty        = "󰉖",
                            empty_open   = "󰷏",
                            symlink      = "",
                            symlink_open = "",
                        },
                        git = {
                            unstaged  = "✗",
                            staged    = "✓",
                            unmerged  = "",
                            renamed   = "➜",
                            untracked = "★",
                            deleted   = "",
                            ignored   = "◌",
                        },
                    },
                },
            },
            filters = {
                dotfiles = false,
                git_clean = false,
                no_buffer = false,
                custom    = { "^.git$", "__pycache__", ".DS_Store" },
                exclude   = {},
            },
            git = {
                enable   = true,
                show_on_dirs = true,
                show_on_open_dirs = true,
                disable_for_dirs = {},
                timeout  = 400,
            },
            actions = {
                use_system_clipboard = true,
                change_dir = {
                    enable         = true,
                    global         = false,
                    restrict_above_cwd = false,
                },
                open_file = {
                    quit_on_open  = false,
                    eject         = true,
                    resize_window = true,
                    window_picker = {
                        enable        = true,
                        picker        = "default",
                        chars         = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
                        exclude = {
                            filetype = { "notify", "lazy", "qf", "diff", "fugitive", "fugitiveblame" },
                            buftype  = { "nofile", "terminal", "help" },
                        },
                    },
                },
            },
            diagnostics = {
                enable              = true,
                show_on_dirs        = true,
                show_on_open_dirs   = true,
                debounce_delay      = 50,
                severity = {
                    min = vim.diagnostic.severity.HINT,
                    max = vim.diagnostic.severity.ERROR,
                },
                icons = {
                    hint    = "",
                    info    = "",
                    warning = "",
                    error   = "",
                },
            },
            modified = {
                enable          = true,
                show_on_dirs    = true,
                show_on_open_dirs = true,
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 📊 BUFFERLINE — Tab bar for buffers
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "akinsho/bufferline.nvim",
        version      = "*",
        event        = "BufReadPre",
        dependencies = "nvim-tree/nvim-web-devicons",
        opts = {
            options = {
                mode                   = "buffers",
                numbers                = "none",
                close_command          = "Bdelete! %d",
                right_mouse_command    = "Bdelete! %d",
                left_mouse_command     = "buffer %d",
                middle_mouse_command   = nil,
                indicator              = { icon = "▎", style = "icon" },
                buffer_close_icon      = "󰅖",
                modified_icon          = "●",
                close_icon             = "",
                left_trunc_marker      = "",
                right_trunc_marker     = "",
                diagnostics            = "nvim_lsp",
                diagnostics_update_in_insert = false,
                diagnostics_indicator  = function(count, level, diagnostics_dict, context)
                    local icon = level:match("error") and " " or " "
                    return " " .. icon .. count
                end,
                offsets = {
                    {
                        filetype   = "NvimTree",
                        text       = " File Explorer",
                        text_align = "left",
                        separator  = true,
                        highlight  = "Directory",
                    },
                },
                color_icons            = true,
                show_buffer_icons      = true,
                show_buffer_close_icons = true,
                show_close_icon        = true,
                show_tab_indicators    = true,
                show_duplicate_prefix  = true,
                persist_buffer_sort    = true,
                separator_style        = "thin",
                enforce_regular_tabs   = false,
                always_show_bufferline = true,
                sort_by                = "insert_after_current",
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- ✨ WHICH-KEY — Keybind popup helper
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        init  = function()
            vim.o.timeout    = true
            vim.o.timeoutlen = 300
        end,
        opts = {
            plugins = {
                marks     = true,
                registers = true,
                spelling  = { enabled = true, suggestions = 20 },
                presets = {
                    operators    = false,
                    motions      = true,
                    text_objects = true,
                    windows      = true,
                    nav          = true,
                    z            = true,
                    g            = true,
                },
            },
            operators = { gc = "Comments" },
            key_labels = {},
            icons = {
                breadcrumb = "»",
                separator  = "➜",
                group      = "+ ",
            },
            popup_mappings = {
                scroll_down = "<c-d>",
                scroll_up   = "<c-u>",
            },
            window = {
                border   = "rounded",
                position = "bottom",
                margin   = { 1, 0, 1, 0 },
                padding  = { 1, 2, 1, 2 },
                winblend = 10,
                zindex   = 1000,
            },
            layout = {
                height   = { min = 4, max = 25 },
                width    = { min = 20, max = 50 },
                spacing  = 3,
                align    = "left",
            },
            ignore_missing   = false,
            hidden           = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "^:", "^ ", "^call ", "^lua " },
            show_help        = true,
            show_keys        = true,
            triggers         = "auto",
            triggers_nowait  = { "`", "'", "g`", "g'", '"', "<c-r>", "z=" },
            triggers_blacklist = {
                i = { "j", "k" },
                v = { "j", "k" },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 📊 DASHBOARD — Start screen
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "goolord/alpha-nvim",
        event        = "VimEnter",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            local alpha   = require("alpha")
            local dashboard = require("alpha.themes.dashboard")

            -- Header
            local header_lines = {
                "                                                                     ",
                "       ████████╗    ██╗  ██╗██╗   ██╗██████╗ ██╗      █████╗ ███╗   ██╗██████╗  ",
                "       ██╔══════╝   ██║  ██║╚██╗ ██╔╝██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗ ",
                "       ███████╗     ███████║ ╚████╔╝ ██████╔╝██║     ███████║██╔██╗ ██║██║  ██║ ",
                "       ██╔════╝     ██╔══██║  ╚██╔╝  ██╔═══╝ ██║     ██╔══██║██║╚██╗██║██║  ██║ ",
                "       ████████╗    ██║  ██║   ██║   ██║     ███████╗██║  ██║██║ ╚████║██████╔╝ ",
                "       ╚═══════╝    ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝  ",
                "                                                                     ",
                "                       ASH DOTFILES v3.0 — Neovim IDE               ",
                "                                                                     ",
            }

            dashboard.section.header.val  = header_lines
            dashboard.section.header.opts = {
                hl       = "AlphaHeader",
                position = "center",
            }

            -- Buttons
            dashboard.section.buttons.val = {
                dashboard.button("SPC SPC", "󰍉  Find File",      "<cmd>Telescope find_files<CR>"),
                dashboard.button("SPC s g", "  Find Text",       "<cmd>Telescope live_grep<CR>"),
                dashboard.button("SPC s r", "  Recent Files",    "<cmd>Telescope oldfiles<CR>"),
                dashboard.button("SPC s s", "  File Sessions",   "<cmd>SessionManager load_session<CR>"),
                dashboard.button("SPC e",   "  File Explorer",   "<cmd>NvimTreeToggle<CR>"),
                dashboard.button("SPC l",   "󰒲  Lazy Plugins",    "<cmd>Lazy<CR>"),
                dashboard.button("SPC c r", "  Config",          "<cmd>edit $MYVIMRC<CR>"),
                dashboard.button("q",       "  Quit",            "<cmd>qa<CR>"),
            }

            -- Footer
            local lazy_stats = require("lazy").stats()
            local footer_text = string.format(
                "  ASH Dotfiles v3.0  ·  %d plugins  ·  loaded in %.2fms",
                lazy_stats.count,
                lazy_stats.startuptime
            )

            dashboard.section.footer.val  = footer_text
            dashboard.section.footer.opts = {
                hl       = "AlphaFooter",
                position = "center",
            }

            -- Layout
            dashboard.config.layout = {
                { type = "padding", val = 2 },
                dashboard.section.header,
                { type = "padding", val = 2 },
                dashboard.section.buttons,
                { type = "padding", val = 1 },
                dashboard.section.footer,
            }

            alpha.setup(dashboard.config)

            -- Hide statusline and tabline on dashboard
            vim.api.nvim_create_autocmd("User", {
                pattern  = "AlphaReady",
                callback = function()
                    vim.cmd("set showtabline=0 | autocmd BufUnload <buffer> set showtabline=2")
                    vim.cmd("set laststatus=0 | autocmd BufUnload <buffer> set laststatus=3")
                end,
            })
        end,
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🔢 INDENT GUIDES
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "lukas-reineke/indent-blankline.nvim",
        main  = "ibl",
        event = "BufReadPost",
        opts = {
            indent = {
                char            = "│",
                tab_char        = "│",
                highlight       = "IblIndent",
                smart_indent_cap = true,
            },
            scope = {
                enabled         = true,
                show_start      = true,
                show_end        = false,
                injected_languages = false,
                highlight       = { "IblScope" },
                priority        = 500,
            },
            exclude = {
                filetypes = {
                    "help", "dashboard", "alpha", "NvimTree",
                    "lazy", "mason", "notify", "toggleterm",
                    "lazyterm", "telescope", "",
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🎨 WEB DEVICONS
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "nvim-tree/nvim-web-devicons",
        lazy = true,
        opts = { default = true },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🌅 TRANSPARENT BACKGROUND
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "xiyaowong/transparent.nvim",
        event = "VeryLazy",
        opts = {
            groups = {
                "Normal", "NormalNC", "Comment", "Constant", "Special",
                "Identifier", "Statement", "PreProc", "Type", "Underlined",
                "Todo", "String", "Function", "Conditional", "Repeat",
                "Operator", "Structure", "LineNr", "NonText", "SignColumn",
                "CursorLineNr", "EndOfBuffer",
            },
            extra_groups = { "NormalFloat", "NvimTreeNormal", "NvimTreeEndOfBuffer" },
            exclude_groups = {},
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🎭 ZEN MODE — Distraction-free writing
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "folke/zen-mode.nvim",
        cmd  = "ZenMode",
        keys = { { "<leader>uz", "<cmd>ZenMode<CR>", desc = "Zen Mode" } },
        opts = {
            window = {
                backdrop = 0.85,
                width    = 120,
                height   = 1,
                options  = {
                    signcolumn    = "no",
                    number        = false,
                    relativenumber = false,
                    cursorline    = false,
                    foldcolumn    = "0",
                    list          = false,
                },
            },
            plugins = {
                gitsigns    = { enabled = false },
                tmux        = { enabled = false },
                twilight    = { enabled = true },
                kitty       = { enabled = false, font = "+4" },
                alacritty   = { enabled = false, font = "14" },
                wezterm     = { enabled = false, font = "+4" },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🔦 TWILIGHT — Dim inactive code in zen mode
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "folke/twilight.nvim",
        cmd  = { "Twilight", "TwilightEnable", "TwilightDisable" },
        opts = {
            dimming      = { alpha = 0.25, color = { "Normal", "#ffffff" }, term_bg = "#000000", inactive = false },
            context      = 10,
            treesitter   = true,
            expand        = { "function", "method", "table", "if_statement" },
            exclude       = {},
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🌈 COLOR PREVIEW
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "NvChad/nvim-colorizer.lua",
        event = "BufReadPre",
        opts = {
            filetypes = { "*", "!lazy", "!mason" },
            user_default_options = {
                RGB           = true,
                RRGGBB        = true,
                names         = true,
                RRGGBBAA      = true,
                AARRGGBB      = false,
                rgb_fn        = true,
                hsl_fn        = true,
                css           = true,
                css_fn        = true,
                mode          = "virtualtext",
                virtualtext   = "■",
                always_update = false,
            },
            buftypes = {},
        },
    },
}