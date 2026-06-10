-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — AI PLUGINS                                   ║
-- ║           Codeium (free AI completion) + Avante (Claude/GPT chat)         ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

return {

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🤖 CODEIUM — Free AI code completion
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "Exafunction/codeium.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "hrsh7th/nvim-cmp",
        },
        event  = "InsertEnter",
        build  = ":Codeium Auth",
        config = function()
            require("codeium").setup({
                enable_chat      = true,
                enable_local_search = true,
                enable_index_service = true,
                search_max_workspace_file_count = 5000,
            })

            -- Add Codeium to cmp sources
            local ok, cmp = pcall(require, "cmp")
            if ok then
                local sources = cmp.get_config().sources or {}
                table.insert(sources, 1, { name = "codeium", priority = 1100 })
                cmp.setup({ sources = sources })
            end
        end,
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🧠 COPILOT — GitHub Copilot (requires subscription)
    -- ═══════════════════════════════════════════════════════════════════════════
    -- Uncomment if you have GitHub Copilot:
    -- {
    --     "zbirenbaum/copilot.nvim",
    --     cmd   = "Copilot",
    --     event = "InsertEnter",
    --     opts  = {
    --         panel = { enabled = false },
    --         suggestion = {
    --             enabled       = true,
    --             auto_trigger  = true,
    --             debounce      = 75,
    --             keymap = {
    --                 accept       = "<Tab>",
    --                 accept_word  = false,
    --                 accept_line  = false,
    --                 next         = "<M-]>",
    --                 prev         = "<M-[>",
    --                 dismiss      = "<C-]>",
    --             },
    --         },
    --         filetypes = {
    --             yaml         = false,
    --             markdown      = false,
    --             help          = false,
    --             gitcommit     = false,
    --             gitrebase     = false,
    --             hgcommit      = false,
    --             svn           = false,
    --             cvs           = false,
    --             ["."]         = false,
    --         },
    --     },
    -- },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 💬 AVANTE — AI chat assistant (Claude/GPT/Gemini in Neovim)
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "yetone/avante.nvim",
        event        = "VeryLazy",
        version      = false,
        build        = "make",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "stevearc/dressing.nvim",
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons",
            "zbirenbaum/copilot.lua",
            {
                "HakonHarnes/img-clip.nvim",
                event = "VeryLazy",
                opts  = {
                    default = {
                        embed_image_as_base64 = false,
                        prompt_for_file_name  = false,
                        drag_and_drop = { insert_mode = true },
                        use_absolute_path = true,
                    },
                },
            },
            {
                "MeanderingProgrammer/render-markdown.nvim",
                opts = { file_types = { "markdown", "Avante" } },
                ft   = { "markdown", "Avante" },
            },
        },
        opts = {
            -- Provider: claude, openai, azure, gemini, copilot, ollama
            provider      = "claude",

            -- Auto-suggestions
            auto_suggestions_provider = "codeium",

            claude = {
                endpoint    = "https://api.anthropic.com",
                model       = "claude-3-5-sonnet-20241022",
                temperature = 0,
                max_tokens  = 8000,
            },

            openai = {
                endpoint    = "https://api.openai.com/v1",
                model       = "gpt-4o",
                temperature = 0,
                max_tokens  = 4096,
            },

            -- Ollama (local AI — no API key needed)
            -- ollama = {
            --     endpoint = "http://127.0.0.1:11434",
            --     model    = "llama3.1",
            -- },

            -- UI settings
            behaviour = {
                auto_suggestions               = false,
                auto_set_highlight_group       = true,
                auto_set_keymaps               = true,
                auto_apply_diff_after_generation = true,
                support_paste_from_clipboard   = false,
            },

            mappings = {
                diff = {
                    ours    = "co",
                    theirs  = "ct",
                    all_theirs = "ca",
                    both    = "cb",
                    cursor  = "cc",
                    next    = "]x",
                    prev    = "[x",
                },
                suggestion = {
                    accept = "<M-l>",
                    next   = "<M-]>",
                    prev   = "<M-[>",
                    dismiss = "<C-]>",
                },
                jump = {
                    next = "]]",
                    prev = "[[",
                },
                submit = {
                    normal = "<CR>",
                    insert = "<C-s>",
                },
                sidebar = {
                    apply_all   = "A",
                    apply_cursor = "a",
                    switch_windows = "<Tab>",
                    reverse_switch_windows = "<S-Tab>",
                },
            },

            hints = { enabled = true },

            windows = {
                position          = "right",
                wrap              = true,
                width             = 36,
                sidebar_header = {
                    align   = "center",
                    rounded = true,
                },
                input = {
                    prefix = "> ",
                    height = 8,
                },
                edit = {
                    border      = "rounded",
                    start_insert = true,
                },
                ask = {
                    floating      = false,
                    start_insert  = true,
                    border        = "rounded",
                    focused_sign  = "> ",
                },
            },

            highlights = {
                diff = {
                    current  = "DiffText",
                    incoming = "DiffAdd",
                },
            },

            diff = {
                autojump        = false,
                list_opener     = "copen",
                override_timeoutlen = 500,
            },
        },

        keys = {
            { "<leader>aa", function() require("avante.api").ask()     end, desc = "Avante: Ask",     mode = { "n", "v" } },
            { "<leader>ae", function() require("avante.api").edit()    end, desc = "Avante: Edit",    mode = { "n", "v" } },
            { "<leader>ar", function() require("avante.api").refresh() end, desc = "Avante: Refresh" },
            { "<leader>at", "<cmd>AvanteToggle<CR>",                        desc = "Avante: Toggle" },
            { "<leader>ac", "<cmd>AvanteChat<CR>",                          desc = "Avante: Chat" },
            { "<leader>am", "<cmd>AvanteModel<CR>",                         desc = "Avante: Change Model" },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🔮 OLLAMA.NVIM — Local AI via Ollama
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "nomnivore/ollama.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        cmd          = { "Ollama", "OllamaModel", "OllamaServe", "OllamaServeStop" },
        keys = {
            { "<leader>ao", ":<c-u>lua require('ollama').prompt()<cr>",     desc = "Ollama prompt",       mode = { "n", "v" } },
            { "<leader>aG", ":<c-u>lua require('ollama').prompt('Generate_Code')<cr>", desc = "Ollama generate",  mode = { "n", "v" } },
        },
        opts = {
            model         = "llama3.1",
            url           = "http://127.0.0.1:11434",
            serve = {
                on_start  = false,
                command   = "ollama",
                args      = { "serve" },
                stop_command = "pkill",
                stop_args = { "-SIGTERM", "ollama" },
            },
            prompts = {
                Sample_Data = {
                    prompt = "Generate sample data based on this schema:\n$sel",
                    action = "display",
                },
                Explain_Code = {
                    prompt  = "Explain this code:\n$sel",
                    action  = "display",
                    extract = "```$ftype\n(.-)```",
                },
                Generate_Code = {
                    prompt  = "Generate code based on this description:\n$sel",
                    action  = "replace",
                    extract = "```$ftype\n(.-)```",
                },
                Improve_Code = {
                    prompt  = "Improve and refactor this code:\n$sel",
                    action  = "replace",
                    extract = "```$ftype\n(.-)```",
                },
                Fix_Code = {
                    prompt  = "Fix bugs in this code:\n$sel",
                    action  = "replace",
                    extract = "```$ftype\n(.-)```",
                },
            },
        },
    },
}