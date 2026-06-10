-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — DEBUG PLUGINS (DAP)                          ║
-- ║           nvim-dap with Python, Go, Rust, C/C++ adapters + Neotest        ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

return {

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🐛 NVIM-DAP — Debug Adapter Protocol
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "rcarriga/nvim-dap-ui",
            "nvim-neotest/nvim-nio",
            "williamboman/mason.nvim",
            "jay-babu/mason-nvim-dap.nvim",
            "theHamsta/nvim-dap-virtual-text",

            -- Language-specific adapters
            "mfussenegger/nvim-dap-python",
            "leoluz/nvim-dap-go",
        },
        keys = {
            -- ── Breakpoints ───────────────────────────────────────────────────
            { "<leader>db", function() require("dap").toggle_breakpoint() end,             desc = "Toggle Breakpoint" },
            { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Conditional Breakpoint" },
            { "<leader>dl", function() require("dap").set_breakpoint(nil, nil, vim.fn.input("Log message: ")) end, desc = "Log Point" },
            { "<leader>dr", function() require("dap").clear_breakpoints() end,             desc = "Clear Breakpoints" },

            -- ── Session ───────────────────────────────────────────────────────
            { "<leader>dc", function() require("dap").continue() end,                     desc = "Continue / Start" },
            { "<leader>dC", function() require("dap").run_to_cursor() end,                desc = "Run to Cursor" },
            { "<leader>dq", function() require("dap").terminate() end,                    desc = "Terminate Session" },
            { "<leader>dR", function() require("dap").restart() end,                      desc = "Restart" },

            -- ── Stepping ──────────────────────────────────────────────────────
            { "<F5>",  function() require("dap").continue() end,                          desc = "DAP: Continue" },
            { "<F10>", function() require("dap").step_over() end,                         desc = "DAP: Step Over" },
            { "<F11>", function() require("dap").step_into() end,                         desc = "DAP: Step Into" },
            { "<F12>", function() require("dap").step_out() end,                          desc = "DAP: Step Out" },

            { "<leader>dj", function() require("dap").step_over() end,                   desc = "Step Over" },
            { "<leader>di", function() require("dap").step_into() end,                   desc = "Step Into" },
            { "<leader>do", function() require("dap").step_out() end,                    desc = "Step Out" },
            { "<leader>dk", function() require("dap").up() end,                          desc = "Up in Call Stack" },

            -- ── UI ────────────────────────────────────────────────────────────
            { "<leader>du", function() require("dapui").toggle() end,                    desc = "Toggle DAP UI" },
            { "<leader>de", function() require("dapui").eval() end,                      desc = "Evaluate Expr", mode = { "n", "v" } },
            { "<leader>dw", function() require("dap.ui.widgets").hover() end,            desc = "Hover Widget" },
            { "<leader>dW", function()
                local widgets = require("dap.ui.widgets")
                widgets.centered_float(widgets.scopes)
            end, desc = "Scopes" },

            -- ── Language ──────────────────────────────────────────────────────
            { "<leader>dP", function() require("dap-python").test_method() end,          desc = "Python: Test Method" },
            { "<leader>dF", function() require("dap-python").test_class() end,           desc = "Python: Test Class" },
            { "<leader>dG", function() require("dap-go").debug_test() end,               desc = "Go: Debug Test" },
        },

        config = function()
            local dap    = require("dap")
            local dapui  = require("dapui")

            -- Auto-open/close DAP UI
            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close()
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close()
            end

            -- ── Signs ─────────────────────────────────────────────────────────
            local breakpoint_icons = {
                Breakpoint          = { "●", "DiagnosticError" },
                BreakpointCondition = { "◉", "DiagnosticWarn" },
                LogPoint            = { "◆", "DiagnosticInfo" },
                Stopped             = { "→", "DiagnosticHint" },
                BreakpointRejected  = { "○", "DiagnosticError" },
            }

            for name, config in pairs(breakpoint_icons) do
                vim.fn.sign_define("Dap" .. name, {
                    text   = config[1],
                    texthl = config[2],
                    linehl = "",
                    numhl  = "",
                })
            end

            -- ── Python ────────────────────────────────────────────────────────
            require("dap-python").setup(
                require("mason-registry").get_package("debugpy"):get_install_path()
                .. "/venv/bin/python"
            )

            -- ── Go ────────────────────────────────────────────────────────────
            require("dap-go").setup({
                dap_configurations = {
                    {
                        type    = "go",
                        name    = "Debug Package",
                        request = "launch",
                        program = "${fileDirname}",
                    },
                },
            })

            -- ── Rust / C / C++ ────────────────────────────────────────────────
            dap.adapters.codelldb = {
                type    = "server",
                port    = "${port}",
                executable = {
                    command = require("mason-registry")
                        .get_package("codelldb"):get_install_path() .. "/codelldb",
                    args    = { "--port", "${port}" },
                },
            }

            for _, lang in ipairs({ "c", "cpp", "rust" }) do
                dap.configurations[lang] = {
                    {
                        name            = "Launch file",
                        type            = "codelldb",
                        request         = "launch",
                        program         = function()
                            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                        end,
                        cwd             = "${workspaceFolder}",
                        stopOnEntry     = false,
                    },
                    {
                        name            = "Attach to process",
                        type            = "codelldb",
                        request         = "attach",
                        pid             = require("dap.utils").pick_process,
                        cwd             = "${workspaceFolder}",
                    },
                }
            end

            -- ── JavaScript / TypeScript ────────────────────────────────────────
            for _, lang in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
                dap.configurations[lang] = {
                    {
                        type          = "pwa-node",
                        request       = "launch",
                        name          = "Launch file",
                        program       = "${file}",
                        cwd           = "${workspaceFolder}",
                    },
                    {
                        type          = "pwa-node",
                        request       = "attach",
                        name          = "Attach",
                        processId     = require("dap.utils").pick_process,
                        cwd           = "${workspaceFolder}",
                    },
                }
            end
        end,
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🎨 DAP-UI — Debug interface
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "rcarriga/nvim-dap-ui",
        dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
        opts = {
            controls = {
                enabled    = true,
                element    = "repl",
                icons = {
                    pause         = "⏸",
                    play          = "▶",
                    step_into     = "⏎",
                    step_over     = "⏭",
                    step_out      = "⏮",
                    step_back     = "⏪",
                    run_last      = "↺",
                    terminate     = "⏹",
                    disconnect    = "⏏",
                },
            },
            element_mappings  = {},
            expand_lines      = true,
            floating = {
                border   = "rounded",
                mappings = { close = { "q", "<Esc>" } },
            },
            force_buffers     = true,
            icons = {
                collapsed = "",
                current_frame = "",
                expanded  = "",
            },
            layouts = {
                {
                    elements  = {
                        { id = "scopes",      size = 0.35 },
                        { id = "breakpoints", size = 0.15 },
                        { id = "stacks",      size = 0.30 },
                        { id = "watches",     size = 0.20 },
                    },
                    position  = "left",
                    size      = 40,
                },
                {
                    elements  = {
                        { id = "repl",    size = 0.5 },
                        { id = "console", size = 0.5 },
                    },
                    position  = "bottom",
                    size      = 12,
                },
            },
            mappings = {
                edit   = "e",
                expand = { "<CR>", "<2-LeftMouse>" },
                open   = "o",
                remove = "d",
                repl   = "r",
                toggle = "t",
            },
            render = {
                indent       = 1,
                max_type_length = nil,
                max_value_lines = 100,
            },
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 💬 DAP VIRTUAL TEXT — Show values inline
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "theHamsta/nvim-dap-virtual-text",
        dependencies = { "mfussenegger/nvim-dap", "nvim-treesitter/nvim-treesitter" },
        opts = {
            enabled                  = true,
            enabled_commands         = true,
            highlight_changed_variables = true,
            highlight_new_as_changed = true,
            show_stop_reason         = true,
            commented                = false,
            only_first_definition    = true,
            all_references           = false,
            filter_references_pattern = "<module",
            virt_text_pos            = "eol",
            all_frames               = false,
            virt_lines               = false,
            virt_text_win_col        = nil,
        },
    },

    -- ═══════════════════════════════════════════════════════════════════════════
    -- 🧪 NEOTEST — Testing framework
    -- ═══════════════════════════════════════════════════════════════════════════
    {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            "nvim-neotest/nvim-nio",
            "nvim-neotest/neotest-python",
            "nvim-neotest/neotest-go",
            "nvim-neotest/neotest-jest",
            "rouge8/neotest-rust",
        },
        keys = {
            { "<leader>tt", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run file tests" },
            { "<leader>tT", function() require("neotest").run.run(vim.loop.cwd())    end,  desc = "Run all tests" },
            { "<leader>tr", function() require("neotest").run.run()                  end,  desc = "Run nearest test" },
            { "<leader>ts", function() require("neotest").summary.toggle()           end,  desc = "Test summary" },
            { "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show test output" },
            { "<leader>tO", function() require("neotest").output_panel.toggle()      end,  desc = "Toggle output panel" },
            { "<leader>tS", function() require("neotest").run.stop()                 end,  desc = "Stop tests" },
            { "]n", function() require("neotest").jump.next({ status = "failed" })   end,  desc = "Next failed test" },
            { "[n", function() require("neotest").jump.prev({ status = "failed" })   end,  desc = "Prev failed test" },
        },
        config = function()
            require("neotest").setup({
                adapters = {
                    require("neotest-python")({
                        dap = { justMyCode = false },
                        runner = "pytest",
                        python = function()
                            local venv = vim.fn.findfile("pyproject.toml", vim.fn.getcwd() .. ";")
                            if venv ~= "" then
                                return vim.fn.getcwd() .. "/.venv/bin/python"
                            end
                            return "python3"
                        end,
                    }),
                    require("neotest-go")({
                        experimental = { test_table = true },
                        args         = { "-count=1", "-timeout=60s" },
                    }),
                    require("neotest-jest")({
                        jestCommand      = "npm test --",
                        jestConfigFile   = "jest.config.ts",
                        env              = { CI = true },
                        cwd              = function(path)
                            return vim.fn.getcwd()
                        end,
                    }),
                    require("neotest-rust")({
                        args = { "--no-capture" },
                    }),
                },
                status = {
                    virtual_text = true,
                    signs        = true,
                },
                output = {
                    open_on_run = "short",
                },
                quickfix = {
                    open = function()
                        vim.cmd("Trouble quickfix")
                    end,
                },
                summary = {
                    mappings = {
                        expand      = "<CR>",
                        run         = "r",
                        stop        = "s",
                        attach      = "a",
                        jumpto      = "i",
                        output      = "o",
                        short       = "O",
                        mark        = "m",
                        clear_marked = "M",
                    },
                },
                icons = {
                    running_animated = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
                    passed          = "✓",
                    failed          = "✗",
                    skipped         = "⊘",
                    unknown         = "?",
                    running         = "",
                },
            })
        end,
    },
}