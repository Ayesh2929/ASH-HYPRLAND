-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — LANGUAGE SPECIFIC PLUGINS                    ║
-- ║           Rust, Go, TypeScript, Python, Markdown, LaTeX                   ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

return {

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🦀 RUSTACEANVIM — Enhanced Rust development
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "mrcjkb/rustaceanvim",
        version  = "^4",
        ft       = { "rust" },
        opts = {
            server = {
                on_attach = function(client, bufnr)
                    -- Use rustaceanvim specific keymaps
                    local map = function(keys, func, desc)
                        vim.keymap.set("n", keys, func,
                            { buffer = bufnr, desc = "Rust: " .. desc })
                    end

                    map("K",           function() vim.cmd.RustLsp("hover", "actions") end, "Hover Actions")
                    map("<leader>cA",  function() vim.cmd.RustLsp("codeAction") end,       "Code Action")
                    map("<leader>re",  function() vim.cmd.RustLsp("explainError") end,     "Explain Error")
                    map("<leader>rd",  function() vim.cmd.RustLsp("openDocs") end,         "Open Docs")
                    map("<leader>rp",  function() vim.cmd.RustLsp("parentModule") end,     "Parent Module")
                    map("<leader>rj",  function() vim.cmd.RustLsp("joinLines") end,        "Join Lines")
                    map("<leader>rm",  function() vim.cmd.RustLsp("expandMacro") end,      "Expand Macro")
                    map("<leader>rc",  function() vim.cmd.RustLsp("openCargo") end,        "Open Cargo.toml")
                    map("<leader>rr",  function() vim.cmd.RustLsp("runnables") end,        "Runnables")
                    map("<leader>rR",  function() vim.cmd.RustLsp("debuggables") end,      "Debuggables")
                    map("<leader>rt",  function() vim.cmd.RustLsp("testables") end,        "Testables")
                end,
                settings = {
                    ["rust-analyzer"] = {
                        cargo = {
                            allFeatures  = true,
                            loadOutDirsFromCheck = true,
                            runBuildScripts = true,
                        },
                        checkOnSave  = {
                            allFeatures  = true,
                            command      = "clippy",
                            extraArgs    = { "--no-deps", "--", "-W", "clippy::pedantic" },
                        },
                        inlayHints = {
                            bindingModeHints = { enable = false },
                            chainingHints    = { enable = true },
                            closingBraceHints = { enable = true, minLines = 25 },
                            closureReturnTypeHints = { enable = "with_block" },
                            lifetimeElisionHints = { enable = "skip_trivial", useParameterNames = false },
                            maxLength        = { enable = true, value = 25 },
                            parameterHints   = { enable = true },
                            renderColons     = true,
                            typeHints        = { enable = true, hideClosureInitialization = false, hideNamedConstructor = false },
                        },
                        procMacro  = {
                            enable = true,
                            ignored = {
                                ["async-trait"]    = { "async_trait" },
                                ["napi-derive"]    = { "napi" },
                                ["async-recursion"] = { "async_recursion" },
                            },
                        },
                        files = {
                            excludeDirs = { ".direnv", ".git", "node_modules", "target" },
                        },
                    },
                },
            },
            dap = {
                adapter = require("rustaceanvim.config.server").get_codelldb_adapter(
                    vim.fn.exepath("codelldb"),
                    vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/lldb/lib/liblldb.so"
                ),
            },
        },
        config = function(_, opts)
            vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})
        end,
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🐹 GO.NVIM — Go language support
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "ray-x/go.nvim",
        dependencies = {
            "ray-x/guihua.lua",
            "neovim/nvim-lspconfig",
            "nvim-treesitter/nvim-treesitter",
        },
        config = function()
            require("go").setup({
                go        = "go",
                goimports = "gopls",
                gofmt     = "gofumpt",
                max_line_len = 128,
                tag_transform = false,
                test_dir  = "",
                comment_placeholder = "  ",
                icons     = { breakpoint = "🔴", currentpos = "▶️" },
                verbose   = false,
                log_path  = vim.fn.expand("$HOME") .. "/tmp/gonvim.log",
                lsp_cfg   = false,  -- Handled by mason-lspconfig
                lsp_gofumpt = true,
                lsp_on_attach = nil,
                lsp_keymaps = false,
                lsp_codelens = true,
                lsp_diag_hdlr = true,
                lsp_diag_virtual_text  = { space = 0, prefix = "■" },
                lsp_inlay_hints = {
                    enable       = true,
                    only_current_line = false,
                    only_current_line_autocmd = "CursorHold",
                    show_variable_name = true,
                    parameter_hints_prefix = "  ",
                    other_hints_prefix = "  => ",
                    max_len_align = false,
                    max_len_align_padding = 1,
                    right_align = false,
                    right_align_padding = 7,
                    highlight = "Comment",
                },
                gopls_cmd     = { "gopls" },
                gopls_remote  = nil,
                gocoverage_sign = "█",
                sign_covered_hl  = "GitSignsAdd",
                sign_uncovered_hl = "DiagnosticError",
                launch_json   = nil,
                dap_debug     = true,
                dap_debug_keymap = false,
                dap_debug_gui = {},
                dap_debug_vt  = true,
                textobjects   = true,
                test_runner   = "go",
                run_in_floaterm = false,
                floaterm = {
                    postion    = "auto",
                    width      = 0.45,
                    height     = 0.98,
                    title_colors = "nord",
                },
            })
        end,
        ft   = { "go", "gomod" },
        build = ':lua require("go.install").update_all_sync()',
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 📝 MARKDOWN PREVIEW
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "iamcco/markdown-preview.nvim",
        cmd    = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        build  = function() vim.fn["mkdp#util#install"]() end,
        ft     = { "markdown" },
        config = function()
            vim.g.mkdp_auto_start     = 0
            vim.g.mkdp_auto_close     = 1
            vim.g.mkdp_refresh_slow   = 0
            vim.g.mkdp_command_for_global = 0
            vim.g.mkdp_open_to_the_world = 0
            vim.g.mkdp_browser        = "firefox"
            vim.g.mkdp_port           = "8888"
            vim.g.mkdp_page_title     = "「${name}」"
            vim.g.mkdp_preview_options = {
                mkit           = {},
                katex          = {},
                uml            = {},
                maid           = {},
                disable_sync_scroll = 0,
                sync_scroll_type    = "middle",
                hide_yaml_meta      = 1,
                sequence_diagrams   = {},
                flowchart_diagrams  = {},
                content_editable    = false,
                disable_filename    = 0,
                toc                 = {},
            }
        end,
        keys = {
            { "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", desc = "Markdown Preview", ft = "markdown" },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 📄 RENDER-MARKDOWN — Beautiful markdown in Neovim
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons",
        },
        ft   = { "markdown", "norg", "rmd", "org", "quarto" },
        opts = {
            enabled     = true,
            max_file_size = 10.0,
            debounce    = 100,
            render_modes = { "n", "c" },
            anti_conceal = {
                enabled = true,
                ignore = {
                    code_background = true,
                    sign            = true,
                },
                above = 0,
                below = 0,
            },
            heading = {
                enabled    = true,
                sign       = true,
                position   = "overlay",
                icons      = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
                signs      = { "󰫎 " },
                width      = "full",
                left_pad   = 0,
                right_pad  = 0,
                min_width  = 0,
                border     = false,
                above      = "▄",
                below      = "▀",
                backgrounds = {
                    "RenderMarkdownH1Bg", "RenderMarkdownH2Bg",
                    "RenderMarkdownH3Bg", "RenderMarkdownH4Bg",
                    "RenderMarkdownH5Bg", "RenderMarkdownH6Bg",
                },
                foregrounds = {
                    "RenderMarkdownH1", "RenderMarkdownH2",
                    "RenderMarkdownH3", "RenderMarkdownH4",
                    "RenderMarkdownH5", "RenderMarkdownH6",
                },
            },
            code = {
                enabled       = true,
                sign          = true,
                style         = "full",
                position      = "left",
                language_pad  = 0,
                disable_background = { "diff" },
                width         = "full",
                left_pad      = 1,
                right_pad     = 0,
                min_width     = 0,
                border        = "thin",
                above         = "▄",
                below         = "▀",
                highlight     = "RenderMarkdownCode",
                highlight_inline = "RenderMarkdownCodeInline",
            },
            dash = {
                enabled   = true,
                icon      = "─",
                width     = "full",
                highlight = "RenderMarkdownDash",
            },
            bullet = {
                enabled   = true,
                icons     = { "●", "○", "◆", "◇" },
                left_pad  = 0,
                right_pad = 0,
                highlight = "RenderMarkdownBullet",
            },
            checkbox = {
                enabled   = true,
                position  = "inline",
                unchecked = { icon = "󰄱 ", highlight = "RenderMarkdownUnchecked" },
                checked   = { icon = "󰱒 ", highlight = "RenderMarkdownChecked" },
                custom    = {
                    todo  = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
                },
            },
            quote = {
                enabled   = true,
                icon      = "▋",
                repeat_linebreak = false,
                highlight = "RenderMarkdownQuote",
            },
            table = {
                enabled      = true,
                preset       = "none",
                style        = "full",
                cell         = "padded",
                border       = { "┌", "┬", "┐", "├", "┼", "┤", "└", "┴", "┘", "│", "─" },
                alignment_indicator = "━",
                head         = "RenderMarkdownTableHead",
                row          = "RenderMarkdownTableRow",
                filler       = "RenderMarkdownTableFill",
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🌊 TYPESCRIPT TOOLS
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "pmizio/typescript-tools.nvim",
        dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
        ft   = { "javascript", "javascriptreact", "javascript.jsx",
                 "typescript", "typescriptreact", "typescript.tsx" },
        opts = {
            settings = {
                separate_diagnostic_server     = true,
                publish_diagnostic_on          = "insert_leave",
                expose_as_code_action          = { "fix_all", "add_missing_imports", "remove_unused" },
                tsserver_path                  = nil,
                tsserver_max_memory            = "auto",
                tsserver_format_options        = {},
                tsserver_file_preferences      = {
                    includeInlayParameterNameHints = "all",
                    includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                    includeInlayFunctionParameterTypeHints = true,
                    includeInlayVariableTypeHints = true,
                    includeInlayPropertyDeclarationTypeHints = true,
                    includeInlayFunctionLikeReturnTypeHints = true,
                    includeInlayEnumMemberValueHints = true,
                    importModuleSpecifierEnding = "auto",
                },
                tsserver_locale = "en",
                complete_function_calls = false,
                include_completions_with_insert_text = true,
                jsx_close_tag = {
                    enable   = true,
                    filetypes = { "javascriptreact", "typescriptreact" },
                },
            },
        },
    },
}