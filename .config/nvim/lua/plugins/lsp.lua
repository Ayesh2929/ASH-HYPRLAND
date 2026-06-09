-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — LSP PLUGIN CONFIGURATION                     ║
-- ║           Mason, lspconfig, nvim-cmp, conform, nvim-lint                  ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

return {

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 📦 MASON — LSP/DAP/Linter/Formatter installer
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "williamboman/mason.nvim",
        cmd  = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate" },
        keys = { { "<leader>m", "<cmd>Mason<CR>", desc = "Mason Package Manager" } },
        build = ":MasonUpdate",
        opts = {
            ui = {
                check_outdated_packages_on_open = true,
                border  = "rounded",
                width   = 0.8,
                height  = 0.8,
                icons = {
                    package_installed   = "✓",
                    package_pending     = "➜",
                    package_uninstalled = "✗",
                },
                keymaps = {
                    toggle_package_expand   = "<CR>",
                    install_package         = "i",
                    update_package          = "u",
                    check_package_version   = "c",
                    update_all_packages     = "U",
                    check_outdated_packages = "C",
                    uninstall_package       = "X",
                    cancel_installation     = "<C-c>",
                    apply_language_filter   = "<C-f>",
                },
            },
            pip = { upgrade_pip = true },
            log_level   = vim.log.levels.INFO,
            max_concurrent_installers = 6,
            registries = {
                "github:mason-org/mason-registry",
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🔧 MASON-LSPCONFIG — Bridge between Mason and lspconfig
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim" },
        event        = { "BufReadPre", "BufNewFile" },
        opts = {
            -- Auto-install these LSP servers
            ensure_installed = {
                -- Web
                "html",
                "cssls",
                "tsserver",
                "eslint",
                "tailwindcss",
                "jsonls",
                "graphql",
                "prismals",
                -- Systems
                "lua_ls",
                "rust_analyzer",
                "clangd",
                "gopls",
                -- Python
                "pyright",
                "ruff_lsp",
                -- Shell
                "bashls",
                -- Config
                "yamlls",
                "taplo",
                "dockerls",
                "docker_compose_language_service",
                -- Markup
                "marksman",
                "ltex",
            },
            automatic_installation = true,
            handlers            = nil,
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🧠 NVIM-LSPCONFIG — LSP client configuration
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "neovim/nvim-lspconfig",
        event        = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
            "folke/neodev.nvim",
            "folke/neoconf.nvim",
            { "j-hui/fidget.nvim", opts = {
                progress = {
                    display = {
                        render_limit = 16,
                        done_ttl     = 3,
                        done_icon    = "✓",
                        progress_icon = { pattern = "meter", period = 1 },
                    },
                },
                notification = {
                    window = { border = "rounded", winblend = 10 },
                },
            }},
        },
        config = function()
            require("lsp.init")
        end,
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🔗 NEODEV — Neovim Lua development
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "folke/neodev.nvim",
        opts = {
            library = {
                enabled      = true,
                runtime      = true,
                types        = true,
                plugins      = true,
            },
            setup_jsonls = true,
            override     = function(root_dir, library)
                if root_dir:find("/.dotfiles", 1, true) or
                   root_dir:find("/nvim", 1, true) then
                    library.enabled = true
                    library.plugins = true
                end
            end,
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- ✅ NVIM-CMP — Completion engine
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "hrsh7th/nvim-cmp",
        version      = false,
        event        = { "InsertEnter", "CmdlineEnter" },
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "hrsh7th/cmp-nvim-lua",
            "saadparwaiz1/cmp_luasnip",
            "onsails/lspkind.nvim",
            {
                "L3MON4D3/LuaSnip",
                version      = "v2.*",
                build        = "make install_jsregexp",
                dependencies = {
                    "rafamadriz/friendly-snippets",
                    config = function()
                        require("luasnip.loaders.from_vscode").lazy_load()
                        require("luasnip.loaders.from_vscode").lazy_load({
                            paths = { vim.fn.stdpath("config") .. "/snippets" },
                        })
                    end,
                },
            },
        },
        config = function()
            local cmp      = require("cmp")
            local luasnip  = require("luasnip")
            local lspkind  = require("lspkind")

            -- Helper: check if there are words before cursor
            local function has_words_before()
                local line, col = table.unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0
                    and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
                        :sub(col, col):match("%s") == nil
            end

            cmp.setup({
                -- ── Snippet engine ────────────────────────────────────────
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },

                -- ── Completion behavior ───────────────────────────────────
                completion = {
                    completeopt = "menu,menuone,noinsert",
                },
                preselect = cmp.PreselectMode.None,

                -- ── Window appearance ─────────────────────────────────────
                window = {
                    completion = {
                        border          = "rounded",
                        winhighlight    = "Normal:CmpNormal,FloatBorder:CmpBorder,CursorLine:CmpSel,Search:None",
                        scrollbar       = true,
                        col_offset      = -3,
                        side_padding    = 0,
                    },
                    documentation = {
                        border       = "rounded",
                        winhighlight = "Normal:CmpDocNormal,FloatBorder:CmpDocBorder",
                        max_width    = 60,
                        max_height   = 20,
                    },
                },

                -- ── Key mappings ──────────────────────────────────────────
                mapping = cmp.mapping.preset.insert({
                    -- Navigate completion menu
                    ["<C-j>"]   = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
                    ["<C-k>"]   = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
                    ["<Down>"]  = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
                    ["<Up>"]    = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),

                    -- Scroll docs
                    ["<C-b>"]   = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"]   = cmp.mapping.scroll_docs(4),

                    -- Trigger / abort
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"]     = cmp.mapping.abort(),
                    ["<C-c>"]     = cmp.mapping.close(),

                    -- Confirm selection
                    ["<CR>"]  = cmp.mapping.confirm({
                        behavior = cmp.ConfirmBehavior.Replace,
                        select   = false,
                    }),
                    ["<S-CR>"] = cmp.mapping.confirm({
                        behavior = cmp.ConfirmBehavior.Replace,
                        select   = true,
                    }),

                    -- Tab navigation (snippets + completion)
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_locally_jumpable() then
                            luasnip.expand_or_jump()
                        elseif has_words_before() then
                            cmp.complete()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),

                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.locally_jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),

                -- ── Sources (priority order) ──────────────────────────────
                sources = cmp.config.sources({
                    { name = "nvim_lsp",               priority = 1000 },
                    { name = "luasnip",                priority = 900  },
                    { name = "nvim_lua",               priority = 800  },
                    { name = "path",                   priority = 700  },
                }, {
                    { name = "buffer",                 priority = 500,
                      keyword_length = 3,
                      option = {
                          get_bufnrs = function()
                              return vim.api.nvim_list_bufs()
                          end,
                      },
                    },
                }),

                -- ── Formatting (icons + kind) ─────────────────────────────
                formatting = {
                    expandable_indicator = true,
                    fields   = { "kind", "abbr", "menu" },
                    format   = lspkind.cmp_format({
                        mode          = "symbol_text",
                        maxwidth      = 50,
                        ellipsis_char = "…",
                        show_labelDetails = true,
                        before        = function(entry, vim_item)
                            -- Source label
                            vim_item.menu = ({
                                nvim_lsp = "[LSP]",
                                luasnip  = "[Snip]",
                                buffer   = "[Buf]",
                                path     = "[Path]",
                                nvim_lua = "[Lua]",
                            })[entry.source.name]
                            return vim_item
                        end,
                    }),
                },

                -- ── Experimental ─────────────────────────────────────────
                experimental = {
                    ghost_text = {
                        hl_group = "CmpGhostText",
                    },
                },

                -- ── Sorting ──────────────────────────────────────────────
                sorting = {
                    priority_weight = 2,
                    comparators = {
                        cmp.config.compare.offset,
                        cmp.config.compare.exact,
                        cmp.config.compare.score,
                        cmp.config.compare.recently_used,
                        cmp.config.compare.locality,
                        cmp.config.compare.kind,
                        cmp.config.compare.length,
                        cmp.config.compare.order,
                    },
                },
            })

            -- ── Cmdline completion ────────────────────────────────────────
            cmp.setup.cmdline({ "/", "?" }, {
                mapping = cmp.mapping.preset.cmdline(),
                sources = { { name = "buffer" } },
            })

            cmp.setup.cmdline(":", {
                mapping  = cmp.mapping.preset.cmdline(),
                sources  = cmp.config.sources(
                    { { name = "path" } },
                    { { name = "cmdline", option = { ignore_cmds = { "Man", "!" } } } }
                ),
            })
        end,
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 📐 CONFORM — Code formatter
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd   = { "ConformInfo" },
        keys = {
            {
                "<leader>cf",
                function()
                    require("conform").format({ async = true, lsp_fallback = true })
                end,
                desc = "Format file",
                mode = { "n", "v" },
            },
        },
        opts = {
            formatters_by_ft = {
                lua           = { "stylua" },
                python        = { "isort", "black" },
                rust          = { "rustfmt" },
                go            = { "goimports", "gofmt" },
                javascript    = { "prettier" },
                typescript    = { "prettier" },
                javascriptreact = { "prettier" },
                typescriptreact = { "prettier" },
                vue           = { "prettier" },
                svelte        = { "prettier" },
                css           = { "prettier" },
                scss          = { "prettier" },
                html          = { "prettier" },
                json          = { "prettier" },
                jsonc         = { "prettier" },
                yaml          = { "prettier" },
                markdown      = { "prettier" },
                graphql       = { "prettier" },
                sh            = { "shfmt" },
                bash          = { "shfmt" },
                fish          = { "fish_indent" },
                c             = { "clang_format" },
                cpp           = { "clang_format" },
                cs            = { "csharpier" },
                java          = { "google-java-format" },
                kotlin        = { "ktlint" },
                sql           = { "sql_formatter" },
                toml          = { "taplo" },
                xml           = { "xmlformat" },
                ["*"]         = { "trim_whitespace" },
            },
            format_on_save = function(bufnr)
                -- Disable for certain filetypes or large files
                local disable_filetypes = { "c", "cpp" }
                if vim.tbl_contains(disable_filetypes, vim.bo[bufnr].filetype) then
                    return
                end
                if vim.b[bufnr].large_file then
                    return
                end
                return {
                    timeout_ms   = 3000,
                    lsp_fallback = true,
                }
            end,
            formatters = {
                shfmt = {
                    prepend_args = { "-i", "4", "-ci", "-sr" },
                },
                black = {
                    prepend_args = { "--line-length", "120" },
                },
                prettier = {
                    prepend_args = {
                        "--tab-width", "2",
                        "--single-quote",
                        "--trailing-comma", "es5",
                        "--print-width", "120",
                    },
                },
                stylua = {
                    prepend_args = {
                        "--indent-type", "Spaces",
                        "--indent-width", "4",
                        "--column-width", "120",
                    },
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🔍 NVIM-LINT — Async linter
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPost", "BufNewFile", "BufWritePost" },
        config = function()
            local lint = require("lint")

            lint.linters_by_ft = {
                python     = { "flake8", "mypy" },
                javascript = { "eslint_d" },
                typescript = { "eslint_d" },
                lua        = { "luacheck" },
                sh         = { "shellcheck" },
                bash       = { "shellcheck" },
                fish       = { "fish" },
                dockerfile = { "hadolint" },
                yaml       = { "yamllint" },
                json       = { "jsonlint" },
                markdown   = { "markdownlint" },
                css        = { "stylelint" },
                scss       = { "stylelint" },
                go         = { "golangcilint" },
                rust       = {},  -- handled by rust-analyzer
            }

            -- Auto-lint on events
            local lint_augroup = vim.api.nvim_create_augroup("AshLint", { clear = true })
            vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
                group    = lint_augroup,
                callback = function()
                    if vim.bo.modifiable then
                        require("lint").try_lint()
                    end
                end,
            })
        end,
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🌳 TREESITTER — Syntax highlighting and parsing
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "nvim-treesitter/nvim-treesitter",
        version  = false,
        build    = ":TSUpdate",
        event    = { "BufReadPost", "BufNewFile" },
        cmd      = { "TSInstall", "TSUpdate", "TSUninstall", "TSUpdateSync" },
        dependencies = {
            "nvim-treesitter/nvim-treesitter-textobjects",
            "nvim-treesitter/nvim-treesitter-context",
            "windwp/nvim-ts-autotag",
            "JoosepAlviste/nvim-ts-context-commentstring",
        },
        opts = {
            ensure_installed = {
                "bash", "c", "cmake", "comment", "cpp", "css", "csv",
                "diff", "dockerfile", "dot", "fish", "git_config",
                "git_rebase", "gitattributes", "gitcommit", "gitignore",
                "go", "gomod", "gosum", "gowork", "graphql", "html",
                "http", "ini", "java", "javascript", "jsdoc", "json",
                "json5", "jsonc", "julia", "kotlin", "latex", "lua",
                "luadoc", "luap", "make", "markdown", "markdown_inline",
                "matlab", "nix", "ocaml", "php", "python", "query",
                "regex", "rst", "ruby", "rust", "scala", "scss",
                "sql", "svelte", "swift", "toml", "tsx", "typescript",
                "vim", "vimdoc", "vue", "xml", "yaml", "zig",
            },
            sync_install    = false,
            auto_install    = true,
            ignore_install  = {},
            highlight = {
                enable                            = true,
                disable                           = function(lang, buf)
                    -- Disable for very large files
                    local max_size = 1024 * 1024  -- 1MB
                    local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
                    if ok and stats and stats.size > max_size then
                        return true
                    end
                    -- Disable for specific languages where it causes issues
                    return vim.tbl_contains({ "latex" }, lang)
                end,
                additional_vim_regex_highlighting = false,
            },
            indent = {
                enable  = true,
                disable = { "yaml", "python" },
            },
            incremental_selection = {
                enable  = true,
                keymaps = {
                    init_selection    = "<C-space>",
                    node_incremental  = "<C-space>",
                    scope_incremental = "<C-s>",
                    node_decremental  = "<M-space>",
                },
            },
            textobjects = {
                select = {
                    enable    = true,
                    lookahead = true,
                    keymaps = {
                        ["af"] = { query = "@function.outer",  desc = "Select outer function" },
                        ["if"] = { query = "@function.inner",  desc = "Select inner function" },
                        ["ac"] = { query = "@class.outer",     desc = "Select outer class" },
                        ["ic"] = { query = "@class.inner",     desc = "Select inner class" },
                        ["aa"] = { query = "@parameter.outer", desc = "Select outer parameter" },
                        ["ia"] = { query = "@parameter.inner", desc = "Select inner parameter" },
                        ["ab"] = { query = "@block.outer",     desc = "Select outer block" },
                        ["ib"] = { query = "@block.inner",     desc = "Select inner block" },
                        ["al"] = { query = "@loop.outer",      desc = "Select outer loop" },
                        ["il"] = { query = "@loop.inner",      desc = "Select inner loop" },
                        ["ai"] = { query = "@conditional.outer", desc = "Select outer conditional" },
                        ["ii"] = { query = "@conditional.inner", desc = "Select inner conditional" },
                    },
                    selection_modes = {
                        ["@parameter.outer"] = "v",
                        ["@function.outer"]  = "V",
                        ["@class.outer"]     = "<c-v>",
                    },
                    include_surrounding_whitespace = true,
                },
                move = {
                    enable             = true,
                    set_jumps          = true,
                    goto_next_start = {
                        ["]f"] = { query = "@function.outer", desc = "Next function start" },
                        ["]c"] = { query = "@class.outer",    desc = "Next class start" },
                        ["]a"] = { query = "@parameter.inner",desc = "Next parameter" },
                        ["]b"] = { query = "@block.outer",    desc = "Next block start" },
                        ["]l"] = { query = "@loop.outer",     desc = "Next loop start" },
                    },
                    goto_next_end = {
                        ["]F"] = "@function.outer",
                        ["]C"] = "@class.outer",
                    },
                    goto_previous_start = {
                        ["[f"] = "@function.outer",
                        ["[c"] = "@class.outer",
                        ["[a"] = "@parameter.inner",
                        ["[b"] = "@block.outer",
                        ["[l"] = "@loop.outer",
                    },
                    goto_previous_end = {
                        ["[F"] = "@function.outer",
                        ["[C"] = "@class.outer",
                    },
                },
                swap = {
                    enable = true,
                    swap_next = {
                        ["<leader>sn"] = "@parameter.inner",
                    },
                    swap_previous = {
                        ["<leader>sp"] = "@parameter.inner",
                    },
                },
                lsp_interop = {
                    enable         = true,
                    border         = "rounded",
                    floating_preview_opts = {},
                    peek_definition_code = {
                        ["<leader>cpf"] = "@function.outer",
                        ["<leader>cpc"] = "@class.outer",
                    },
                },
            },
            autotag = { enable = true },
            context_commentstring = { enable = true, enable_autocmd = false },
        },
        config = function(_, opts)
            require("nvim-treesitter.configs").setup(opts)
        end,
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 💬 TREESITTER CONTEXT — Show current code context
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "nvim-treesitter/nvim-treesitter-context",
        event = "BufReadPost",
        opts = {
            enable          = true,
            max_lines       = 4,
            min_window_height = 20,
            line_numbers    = true,
            multiline_threshold = 20,
            trim_scope      = "outer",
            mode            = "cursor",
            separator       = nil,
            zindex          = 20,
            on_attach       = nil,
        },
        keys = {
            { "[C", function() require("treesitter-context").go_to_context(vim.v.count1) end,
              silent = true, desc = "Go to context" },
        },
    },
}