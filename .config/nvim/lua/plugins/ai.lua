-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — AI PLUGINS                                   ║
-- ║           Codeium, Copilot, Ollama local AI integration                   ║
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
        config = function()
            require("codeium").setup({
                enable_cmp_source  = true,
                virtual_text = {
                    enabled          = true,
                    filetypes        = {},
                    default_filetype_enabled = true,
                    idle_delay       = 75,
                    virtual_text_priority = 65535,
                    map_keys         = true,
                    accept_fallback  = nil,
                    key_bindings = {
                        accept          = "<A-Enter>",
                        accept_word     = "<A-w>",
                        accept_line     = "<A-l>",
                        clear           = false,
                        next            = "<A-]>",
                        prev            = "<A-[>",
                    },
                },
            })

            -- Add to cmp sources
            local ok, cmp = pcall(require, "cmp")
            if ok then
                local sources = cmp.get_config().sources or {}
                table.insert(sources, 1, { name = "codeium", priority = 1100 })
                cmp.setup({ sources = sources })
            end
        end,
        keys = {
            { "<leader>ai",  "<cmd>Codeium Auth<CR>",         desc = "Codeium: Authenticate" },
            { "<leader>at",  "<cmd>Codeium Toggle<CR>",       desc = "Codeium: Toggle" },
            { "<A-Enter>",   function() return vim.fn["codeium#Accept"]() end,
              expr = true, silent = true, mode = "i", desc = "Accept Codeium suggestion" },
            { "<A-]>",       function() return vim.fn["codeium#CycleCompletions"](1) end,
              expr = true, silent = true, mode = "i", desc = "Next Codeium suggestion" },
            { "<A-[>",       function() return vim.fn["codeium#CycleCompletions"](-1) end,
              expr = true, silent = true, mode = "i", desc = "Prev Codeium suggestion" },
            { "<A-x>",       function() return vim.fn["codeium#Clear"]() end,
              expr = true, silent = true, mode = "i", desc = "Clear Codeium suggestion" },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🦙 OLLAMA.NVIM — Local AI via Ollama
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "nomnivore/ollama.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        cmd          = { "Ollama", "OllamaModel", "OllamaServe", "OllamaServeStop" },
        keys = {
            { "<leader>ao",  ":<c-u>lua require('ollama').prompt()<cr>",
              desc = "Ollama: Prompt", mode = { "n", "v" } },
            { "<leader>aO",  ":<c-u>lua require('ollama').prompt('Generate_Code')<cr>",
              desc = "Ollama: Generate Code", mode = { "n", "v" } },
            { "<leader>as",  "<cmd>OllamaModel<CR>",  desc = "Ollama: Select Model" },
        },
        opts = {
            model    = "codellama",
            url      = "http://127.0.0.1:11434",
            serve    = {
                on_start = false,
                command  = "ollama",
                args     = { "serve" },
                stop_command = "pkill",
                stop_args    = { "-SIGTERM", "ollama" },
            },
            display  = {
                title  = " Ollama",
                ratio  = 0.4,
                wrap   = true,
                buffered = false,
                format = "unified",
            },
            prompts  = {
                Sample_Data = {
                    prompt   = "Generate realistic sample/mock data for this code:\n$sel",
                    action   = "display",
                    input    = "selection",
                },
                Explain_Code = {
                    prompt   = "Explain this code step by step:\n$sel",
                    action   = "display",
                    input    = "selection",
                },
                Generate_Code = {
                    prompt   = "Generate Neovim-compatible code to: $input\nContext:\n$sel",
                    action   = "insert",
                    input    = "selection",
                },
                Optimize = {
                    prompt   = "Optimize this code for performance and readability:\n$sel",
                    action   = "display",
                    input    = "selection",
                },
                Fix_Bug = {
                    prompt   = "Find and fix bugs in this code:\n$sel",
                    action   = "display",
                    input    = "selection",
                },
                Add_Tests = {
                    prompt   = "Write comprehensive tests for this code:\n$sel",
                    action   = "display",
                    input    = "selection",
                },
                Document = {
                    prompt   = "Add comprehensive docstrings/comments to:\n$sel",
                    action   = "insert",
                    input    = "selection",
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 💬 CHATGPT.NVIM — ChatGPT integration (requires API key)
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "jackMort/ChatGPT.nvim",
        enabled      = false,  -- Enable if you have an OpenAI API key
        event        = "VeryLazy",
        dependencies = {
            "MunifTanjim/nui.nvim",
            "nvim-lua/plenary.nvim",
            "folke/trouble.nvim",
            "nvim-telescope/telescope.nvim",
        },
        config = function()
            require("chatgpt").setup({
                api_key_cmd  = "pass show openai/api-key",
                yank_register  = "+",
                edit_with_instructions = {
                    diff    = false,
                    keymaps = {
                        close           = "<C-c>",
                        accept          = "<M-CR>",
                        toggle_diff     = "<M-d>",
                        toggle_settings = "<M-o>",
                        toggle_help     = "<M-h>",
                        cycle_windows   = "<Tab>",
                        use_output_as_input = "<M-i>",
                    },
                },
                chat = {
                    welcome_message   = "ASH AI Assistant — Powered by ChatGPT",
                    loading_text      = "Loading...",
                    question_sign     = "  ",
                    answer_sign       = "󰚩 ",
                    border_left_sign  = "",
                    border_right_sign = "",
                    max_line_length   = 120,
                    sessions_window = {
                        active_sign     = " 󰁔 ",
                        inactive_sign   = " 󰁕 ",
                        current_line_sign = "",
                    },
                },
                popup_layout = {
                    default = "center",
                    center = { width = "80%", height = "80%" },
                    right = {
                        width = "40%",
                        width_settings_open = "50%",
                    },
                },
                popup_window = {
                    border        = { highlight = "FloatBorder", style = "rounded", text = { top = " ChatGPT " } },
                    win_options   = { wrap = true, linebreak = true, foldcolumn = "1", winhighlight = "Normal:Normal" },
                    buf_options   = { filetype = "markdown" },
                },
            })
        end,
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🧠 GEN.NVIM — Local LLM integration (Ollama/GPT4All)
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "David-Kunz/gen.nvim",
        cmd    = "Gen",
        keys   = {
            { "<leader>ag",  "<cmd>Gen<CR>",                           desc = "AI: Gen (local LLM)", mode = { "n", "v" } },
            { "<leader>agc", ":Gen Chat<CR>",                          desc = "AI: Chat" },
            { "<leader>age", ":Gen Enhance_Code<CR>",                  desc = "AI: Enhance code",  mode = { "n", "v" } },
            { "<leader>ags", ":Gen Summarize<CR>",                     desc = "AI: Summarize",     mode = { "v" } },
        },
        opts = {
            model     = "mistral",
            host      = "localhost",
            port      = "11434",
            quit_map  = "q",
            retry_map = "<c-r>",
            accept_map = "<c-cr>",
            display_mode = "float",
            show_prompt  = false,
            show_model   = false,
            no_auto_close = false,
            hidden        = false,
            file          = false,
            init          = function() pcall(io.popen, "ollama serve > /dev/null 2>&1 &") end,
            command       = function(opts)
                local body = { model = opts.model, stream = true }
                return "curl --silent --no-buffer -X POST http://"
                    .. opts.host .. ":" .. opts.port
                    .. "/api/chat -d $body"
            end,
            debug        = false,
        },
    },
}