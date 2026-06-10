-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — LANGUAGE-SPECIFIC PLUGINS                    ║
-- ║           Rust, Go, TypeScript, Python, Markdown, LaTeX                   ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

return {

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🦀 RUST — rustaceanvim (replaces rust-tools)
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "mrcjkb/rustaceanvim",
        version = "^4",
        ft      = { "rust" },
        opts    = {
            server = {
                on_attach = function(client, bufnr)
                    require("lsp.init").on_attach(client, bufnr)
                    -- Rust-specific keymaps
                    local map = function(key, cmd, desc)
                        vim.keymap.set("n", key, cmd,
                            { buffer = bufnr, silent = true, desc = desc })
                    end
                    map("<leader>cR", function() vim.cmd.RustLsp("codeAction") end,       "Rust: Code Action")
                    map("<leader>rm", function() vim.cmd.RustLsp("expandMacro") end,      "Rust: Expand Macro")
                    map("<leader>rp", function() vim.cmd.RustLsp("parentModule") end,     "Rust: Parent Module")
                    map("<leader>rd", function() vim.cmd.RustLsp("openDocs") end,         "Rust: Open Docs")
                    map("<leader>re", function() vim.cmd.RustLsp("explainError") end,     "Rust: Explain Error")
                    map("<leader>rr", function() vim.cmd.RustLsp("runnables") end,        "Rust: Runnables")
                    map("<leader>rt", function() vim.cmd.RustLsp("testables") end,        "Rust: Testables")
                    map("<leader>rD", function() vim.cmd.RustLsp("debuggables") end,      "Rust: Debuggables")
                    map("<leader>rj", function() vim.cmd.RustLsp("joinLines") end,        "Rust: Join Lines")
                    map("<leader>rs", function() vim.cmd.RustLsp("ssr") end,              "Rust: SSR")
                end,
                settings = {
                    ["rust-analyzer"] = {
                        cargo = {
                            allFeatures         = true,
                            loadOutDirsFromCheck = true,
                            runBuildScripts     = true,
                        },
                        checkOnSave = {
                            allFeatures   = true,
                            command       = "clippy",
                            extraArgs     = { "--no-deps" },
                        },
                        procMacro = {
                            enable         = true,
                            ignored        = {
                                ["async-trait"] = { "async_trait" },
                                ["napi-derive"] = { "napi" },
                                ["async-recursion"] = { "async_recursion" },
                            },
                        },
                        completion = {
                            postfix    = { enable = false },
                            privateEditable = { enable = true },
                        },
                        inlayHints = {
                            bindingModeHints        = { enable = false },
                            chainingHints           = { enable = true },
                            closingBraceHints       = { enable = true, minLines = 25 },
                            closureReturnTypeHints  = { enable = "with_block" },
                            lifetimeElisionHints    = { enable = "skip_trivial", useParameterNames = true },
                            maxLength               = 25,
                            parameterHints          = { enable = true },
                            reborrowHints           = { enable = "skip_trivial" },
                            renderColons            = true,
                            typeHints               = { enable = true, hideClosureInitialization = false, hideNamedConstructor = false },
                        },
                    },
                },
            },
        },
        config = function(_, opts)
            vim.g.rustaceanvim = opts
        end,
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🐹 GO — go.nvim
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "ray-x/go.nvim",
        dependencies = {
            "ray-x/guihua.lua",
            "neovim/nvim-lspconfig",
            "nvim-treesitter/nvim-treesitter",
        },
        ft    = { "go", "gomod", "gowork", "gotmpl" },
        build = ':lua require("go.install").update_all_sync()',
        opts  = {
            goimports         = "gopls",
            gofmt             = "gopls",
            max_line_len      = 120,
            tag_transform     = false,
            test_dir          = "",
            comment_placeholder = " 🦊 ",
            icons = {
                breakpoint  = "🧘",
                currentpos  = "🏃",
            },
            verbose           = false,
            log_path          = vim.fn.expand("$HOME") .. "/tmp/gonvim.log",
            lsp_cfg           = false,  -- Handled by mason-lspconfig
            lsp_gofumpt       = true,
            lsp_on_attach     = false,
            dap_debug         = true,
            dap_debug_keymap  = true,
            dap_debug_gui     = true,
            dap_debug_vt      = true,
            dap_port          = 38697,
            build_tags        = "",
            textobj_enabled   = true,
            diagnostic        = { hdlr = true, underline = true, update_in_insert = false },
            lsp_document_formatting = true,
            lsp_inlay_hints   = { enable = true },
            test_runner       = "go",
            verbose_tests     = true,
            run_in_floaterm   = false,
        },
        config = function(_, opts)
            require("go").setup(opts)

            -- Format on save for Go files
            local go_group = vim.api.nvim_create_augroup("GoFormat", { clear = true })
            vim.api.nvim_create_autocmd("BufWritePre", {
                pattern  = "*.go",
                group    = go_group,
                callback = function()
                    require("go.format").goimports()
                end,
            })
        end,
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🟨 TYPESCRIPT — typescript-tools.nvim
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "pmizio/typescript-tools.nvim",
        dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
        ft           = { "javascript", "javascriptreact", "javascript.jsx",
                         "typescript", "typescriptreact", "typescript.tsx" },
        opts = {
            on_attach = require("lsp.init").on_attach,
            settings  = {
                separate_diagnostic_server = true,
                publish_diagnostic_on      = "insert_leave",
                expose_as_code_action      = {},
                tsserver_path              = nil,
                tsserver_plugins           = {},
                tsserver_max_memory        = "auto",
                tsserver_format_options    = {
                    allowIncompleteCompletions = false,
                    allowRenameOfImportPath    = false,
                },
                tsserver_file_preferences  = {
                    includeInlayParameterNameHints            = "all",
                    includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                    includeInlayFunctionParameterTypeHints    = true,
                    includeInlayVariableTypeHints             = false,
                    includeInlayVariableTypeHintsWhenTypeMatchesName = false,
                    includeInlayPropertyDeclarationTypeHints  = true,
                    includeInlayFunctionLikeReturnTypeHints   = true,
                    includeInlayEnumMemberValueHints          = true,
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🐍 PYTHON — venv-selector + extra tools
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "linux-cultist/venv-selector.nvim",
        dependencies = {
            "neovim/nvim-lspconfig",
            "nvim-telescope/telescope.nvim",
        },
        ft   = "python",
        cmd  = "VenvSelect",
        keys = {
            { "<leader>pv", "<cmd>VenvSelect<CR>",        desc = "Select Python venv" },
            { "<leader>pV", "<cmd>VenvSelectCached<CR>",  desc = "Select cached venv" },
        },
        opts = {
            name                 = { "venv", ".venv", "env", ".env", "virtualenv" },
            auto_refresh         = false,
            search               = true,
            parents              = 0,
            dap_enabled          = true,
            poetry_path          = "poetry",
            pipenv_path          = "pipenv",
            notify_user_on_venv_activation = true,
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 📝 MARKDOWN — render-markdown.nvim
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons",
        },
        ft   = { "markdown", "Avante" },
        opts = {
            enabled             = true,
            max_file_size       = 1.5,
            debounce            = 100,
            render_modes        = { "n", "c" },
            anti_conceal        = { enabled = true },
            heading = {
                enabled      = true,
                sign         = true,
                position     = "overlay",
                icons        = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
                backgrounds  = {
                    "RenderMarkdownH1Bg",
                    "RenderMarkdownH2Bg",
                    "RenderMarkdownH3Bg",
                    "RenderMarkdownH4Bg",
                    "RenderMarkdownH5Bg",
                    "RenderMarkdownH6Bg",
                },
                foregrounds  = {
                    "RenderMarkdownH1",
                    "RenderMarkdownH2",
                    "RenderMarkdownH3",
                    "RenderMarkdownH4",
                    "RenderMarkdownH5",
                    "RenderMarkdownH6",
                },
            },
            code = {
                enabled      = true,
                sign         = true,
                style        = "full",
                position     = "left",
                language_pad = 0,
                disable_background = { "diff" },
                width        = "full",
                left_pad     = 0,
                right_pad    = 0,
                min_width    = 0,
                border       = "thin",
                above        = "▄",
                below        = "▀",
                highlight    = "RenderMarkdownCode",
                highlight_inline = "RenderMarkdownCodeInline",
            },
            bullet = {
                enabled = true,
                icons   = { "●", "○", "◆", "◇" },
                left_pad  = 0,
                right_pad = 1,
            },
            checkbox = {
                enabled   = true,
                unchecked = { icon = "󰄱 ", highlight = "RenderMarkdownUnchecked" },
                checked   = { icon = "󰱒 ", highlight = "RenderMarkdownChecked" },
                custom    = { todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" } },
            },
            quote = {
                enabled   = true,
                icon      = "▋",
                repeat_linebreak = false,
                highlight = "RenderMarkdownQuote",
            },
            pipe_table = {
                enabled   = true,
                preset    = "round",
                style     = "full",
                cell      = "padded",
                alignment_indicator = "━",
                border    = { "╭", "┬", "╮", "├", "┼", "┤", "╰", "┴", "╯", "│", "─" },
            },
            callout = {
                note    = { raw = "[!NOTE]",    rendered = "󰋽 Note",    highlight = "RenderMarkdownInfo" },
                tip     = { raw = "[!TIP]",     rendered = "󰌶 Tip",     highlight = "RenderMarkdownSuccess" },
                important = { raw = "[!IMPORTANT]", rendered = "󰅾 Important", highlight = "RenderMarkdownHint" },
                warning = { raw = "[!WARNING]", rendered = "󰀪 Warning", highlight = "RenderMarkdownWarn" },
                caution = { raw = "[!CAUTION]", rendered = "󰳦 Caution", highlight = "RenderMarkdownError" },
                abstract = { raw = "[!ABSTRACT]", rendered = "󰨸 Abstract", highlight = "RenderMarkdownInfo" },
            },
            link = {
                enabled    = true,
                footnote   = { superscript = true, prefix = "", suffix = "" },
                image      = "󰥶 ",
                email      = "󰀓 ",
                hyperlink  = "󰌹 ",
                highlight  = "RenderMarkdownLink",
                custom     = {},
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🔷 TROUBLE — Diagnostic list
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        cmd  = { "Trouble", "TroubleToggle" },
        keys = {
            { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>",                          desc = "Diagnostics (Trouble)" },
            { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>",             desc = "Buffer Diagnostics" },
            { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<CR>",                  desc = "Symbols (Trouble)" },
            { "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<CR>",   desc = "LSP (Trouble)" },
            { "<leader>xL", "<cmd>Trouble loclist toggle<CR>",                              desc = "Location List (Trouble)" },
            { "<leader>xQ", "<cmd>Trouble qflist toggle<CR>",                              desc = "Quickfix List (Trouble)" },
        },
        opts = {
            modes = {
                lsp = {
                    win = { position = "right" },
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 📐 AERIAL — Symbol outline
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "stevearc/aerial.nvim",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons",
        },
        keys = {
            { "<leader>co", "<cmd>AerialToggle<CR>",  desc = "Toggle Aerial outline" },
            { "<leader>cO", "<cmd>AerialNavToggle<CR>", desc = "Toggle Aerial nav" },
            { "{",  "<cmd>AerialPrev<CR>",             desc = "Aerial prev symbol" },
            { "}",  "<cmd>AerialNext<CR>",             desc = "Aerial next symbol" },
        },
        opts = {
            backends    = { "treesitter", "lsp", "markdown", "asciidoc", "man" },
            layout = {
                max_width   = { 40, 0.2 },
                width       = nil,
                min_width   = 10,
                win_opts    = {},
                default_direction = "prefer_right",
                placement   = "window",
                resize_to_content = true,
                preserve_equality = false,
            },
            show_guides  = true,
            guides = {
                mid_item   = "├─ ",
                last_item  = "└─ ",
                nested_top = "│  ",
                whitespace = "   ",
            },
            filter_kind = {
                "Array", "Boolean", "Class", "Constant", "Constructor",
                "Enum", "EnumMember", "Event", "Field", "File",
                "Function", "Interface", "Key", "Method", "Module",
                "Namespace", "Null", "Number", "Object", "Operator",
                "Package", "Property", "String", "Struct", "TypeParameter",
                "Variable",
            },
        },
    },
}