-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🐹 GO — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                                ║
-- ║   gopls · gofumpt · golangci-lint · structtag · iferr · fillstruct            ║
-- ║   test coverage · benchmarks · pkg docs · ASH theme-synced                    ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "@lsp.type.namespace.go",       { fg = "#89b4fa", italic = true  })
    hl(0, "@lsp.type.type.go",            { fg = "#94e2d5"                 })
    hl(0, "@lsp.type.interface.go",       { fg = "#94e2d5", italic = true  })
    hl(0, "@lsp.type.struct.go",          { fg = "#f9e2af", bold = true    })
    hl(0, "@lsp.type.function.go",        { fg = "#89b4fa"                 })
    hl(0, "@lsp.type.method.go",          { fg = "#89b4fa"                 })
    hl(0, "@lsp.type.variable.go",        { fg = "#cdd6f4"                 })
    hl(0, "@lsp.type.parameter.go",       { fg = "#c8c8c8", italic = true  })
    hl(0, "@lsp.type.typeParameter.go",   { fg = "#94e2d5", italic = true  })
    hl(0, "@lsp.type.builtinType.go",     { fg = "#89dceb"                 })
    hl(0, "@lsp.type.keyword.go",         { fg = "#f38ba8"                 })
    hl(0, "@lsp.typemod.function.async.go",{ fg = "#89b4fa", italic = true })
  
    -- Go test highlights
    hl(0, "GoTestPass",    { bold = true, fg = "#9ece6a" })
    hl(0, "GoTestFail",    { bold = true, fg = "#f38ba8" })
    hl(0, "GoTestSkip",    { fg = "#9399b2"              })
    hl(0, "GoTestBench",   { bold = true, fg = "#89b4fa" })
    hl(0, "GoTestCoverage",{ bold = true, fg = "#f9e2af" })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then
        hl(0, "@lsp.type.function.go",  { fg = p.blue })
        hl(0, "@lsp.type.namespace.go", { fg = p.blue, italic = true })
      end
      if p.teal   then hl(0, "@lsp.type.interface.go",    { fg = p.teal, italic = true }) end
      if p.yellow then hl(0, "@lsp.type.struct.go",       { fg = p.yellow, bold = true }) end
      if p.green  then hl(0, "GoTestPass",                { bold = true, fg = p.green }) end
      if p.red    then hl(0, "GoTestFail",                { bold = true, fg = p.red   }) end
      if p.blue   then hl(0, "GoTestBench",               { bold = true, fg = p.blue  }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 GO UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function get_go_version()
    return vim.fn.trim(vim.fn.system("go version 2>/dev/null"))
      :match("go version go([%d%.]+)") or "unknown"
  end
  
  local function get_module_name()
    local f = io.open(vim.fn.getcwd() .. "/go.mod", "r")
    if not f then return nil end
    for line in f:lines() do
      local mod = line:match("^module%s+(.+)$")
      if mod then f:close(); return vim.fn.trim(mod) end
    end
    f:close()
    return nil
  end
  
  local function run_go_test()
    local file = vim.api.nvim_buf_get_name(0)
    local pkg   = vim.fn.fnamemodify(file, ":h")
  
    vim.notify("🐹 Running tests…", vim.log.levels.INFO,
      { title = "Go", timeout = 1000 })
  
    vim.fn.jobstart(
      { "go", "test", "-v", "-count=1", pkg },
      {
        stdout_buffered = true,
        on_stdout = function(_, data)
          if not data then return end
          local lines = vim.tbl_filter(function(l) return l ~= "" end, data)
          if #lines > 0 then
            local has_fail = vim.tbl_contains(lines, function(l)
              return l:match("^--- FAIL")
            end)
            vim.notify(
              table.concat(lines, "\n"),
              has_fail and vim.log.levels.ERROR or vim.log.levels.INFO,
              { title = "Go Test" }
            )
          end
        end,
      }
    )
  end
  
  local function show_coverage()
    local cwd     = vim.fn.getcwd()
    local covfile = "/tmp/go_coverage_" .. os.time() .. ".out"
  
    vim.notify("🐹 Generating coverage…", vim.log.levels.INFO,
      { title = "Go", timeout = 2000 })
  
    vim.fn.jobstart(
      { "go", "test", "-coverprofile=" .. covfile, "./..." },
      {
        on_exit = function(_, code)
          if code ~= 0 then
            vim.notify("🐹 Coverage generation failed", vim.log.levels.ERROR,
              { title = "Go" })
            return
          end
          vim.cmd("!go tool cover -html=" .. covfile)
        end,
      }
    )
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "ray-x/go.nvim",
      dependencies = {
        "ray-x/guihua.lua",
        "neovim/nvim-lspconfig",
        "nvim-treesitter/nvim-treesitter",
        { "nvim-telescope/telescope.nvim", optional = true },
      },
      ft    = { "go", "gomod", "gowork", "gotmpl" },
      build = ':lua require("go.install").update_all_sync()',
  
      keys = {
        -- ── Run / Build ────────────────────────────────────────────────────────
        { "<leader>gr",  "<cmd>GoRun<cr>",           ft = "go", desc = "🐹 Go: Run"            },
        { "<leader>gb",  "<cmd>GoBuild<cr>",          ft = "go", desc = "🐹 Go: Build"          },
        { "<leader>gB",  "<cmd>GoBuild -v .<cr>",     ft = "go", desc = "🐹 Go: Build verbose"  },
  
        -- ── Tests ──────────────────────────────────────────────────────────────
        { "<leader>gtt", "<cmd>GoTest<cr>",           ft = "go", desc = "🐹 Go: Test package"   },
        { "<leader>gtf", "<cmd>GoTestFile<cr>",       ft = "go", desc = "🐹 Go: Test file"      },
        { "<leader>gtF", "<cmd>GoTestFunc<cr>",       ft = "go", desc = "🐹 Go: Test function"  },
        { "<leader>gtc", show_coverage,               ft = "go", desc = "🐹 Go: Coverage"       },
        { "<leader>gtb", "<cmd>GoBench<cr>",          ft = "go", desc = "🐹 Go: Benchmark"      },
  
        -- ── Code generation ────────────────────────────────────────────────────
        { "<leader>gfs", "<cmd>GoFillStruct<cr>",     ft = "go", desc = "🐹 Go: Fill struct"    },
        { "<leader>gfe", "<cmd>GoIfErr<cr>",          ft = "go", desc = "🐹 Go: Add if err"     },
        { "<leader>gft", "<cmd>GoAddTag<cr>",         ft = "go", desc = "🐹 Go: Add struct tags"},
        { "<leader>gfT", "<cmd>GoRmTag<cr>",          ft = "go", desc = "🐹 Go: Remove struct tags"},
        { "<leader>gfI", "<cmd>GoImpl<cr>",           ft = "go", desc = "🐹 Go: Implement interface"},
        { "<leader>gfm", "<cmd>GoMockgen<cr>",        ft = "go", desc = "🐹 Go: Generate mock"  },
        { "<leader>gfc", "<cmd>GoGenReturn<cr>",      ft = "go", desc = "🐹 Go: Generate return values"},
  
        -- ── Imports ────────────────────────────────────────────────────────────
        { "<leader>gai", "<cmd>GoImport<cr>",         ft = "go", desc = "🐹 Go: Add import"     },
        { "<leader>gri", "<cmd>GoImportRemove<cr>",   ft = "go", desc = "🐹 Go: Remove import"  },
  
        -- ── Docs / Info ────────────────────────────────────────────────────────
        { "<leader>gd",  "<cmd>GoDoc<cr>",            ft = "go", desc = "🐹 Go: Pkg docs"       },
        { "<leader>gD",  "<cmd>GoDocBrowser<cr>",     ft = "go", desc = "🐹 Go: Pkg docs (browser)"},
        { "<leader>gi",  function()
            vim.notify(
              table.concat({
                "🐹 Go Environment",
                "──────────────────────────────────",
                string.format("  Version: %s", get_go_version()),
                string.format("  Module:  %s", get_module_name() or "(no module)"),
                string.format("  GOPATH:  %s", os.getenv("GOPATH") or "(not set)"),
                string.format("  GOROOT:  %s", vim.fn.trim(vim.fn.system("go env GOROOT 2>/dev/null"))),
                string.format("  CGO:     %s", vim.fn.trim(vim.fn.system("go env CGO_ENABLED 2>/dev/null"))),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "Go Info" }
            )
          end,
          ft = "go", desc = "🐹 Go: Environment info",
        },
  
        -- ── Lint ───────────────────────────────────────────────────────────────
        { "<leader>gl",  "<cmd>GoLint<cr>",           ft = "go", desc = "🐹 Go: Lint"           },
        { "<leader>gL",  "<cmd>GoVet<cr>",            ft = "go", desc = "🐹 Go: Vet"            },
  
        -- ── Alternate (impl ↔ test) ────────────────────────────────────────────
        { "<leader>ga",  "<cmd>GoAlt<cr>",            ft = "go", desc = "🐹 Go: Toggle test/impl"},
        { "<leader>gA",  "<cmd>GoAltV<cr>",           ft = "go", desc = "🐹 Go: Toggle test/impl (vsplit)"},
      },
  
      opts = {
        -- ── General ────────────────────────────────────────────────────────────
        disable_defaults      = false,
  
        -- ── Tools ──────────────────────────────────────────────────────────────
        go                    = "go",
        goimport              = "gopls",
        fillstruct            = "gopls",
        gofmt                 = "gofumpt",
  
        -- ── Formatting ────────────────────────────────────────────────────────
        max_line_len          = 120,
        tag_transform         = false,
        tag_options           = "json=omitempty",
  
        -- ── Testing ────────────────────────────────────────────────────────────
        gotests_template      = "",
        gotests_template_dir  = "",
        comment_placeholder   = "  ",
        icons                 = { breakpoint = " ", currentpos = "󰁕 " },
        sign_priority         = 12,
  
        -- ── Verbose / Debug ────────────────────────────────────────────────────
        verbose_tests         = true,
        run_in_floaterm       = false,
  
        -- ── LSP ───────────────────────────────────────────────────────────────
        lsp_cfg               = true,
        lsp_gofumpt           = true,
        lsp_on_attach         = function(client, bufnr)
          -- Format on save
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer   = bufnr,
            callback = function()
              vim.lsp.buf.format({
                bufnr  = bufnr,
                async  = false,
                filter = function(c) return c.name == "gopls" end,
              })
            end,
          })
  
          local global = _G.AshLspOnAttach
          if global then global(client, bufnr) end
        end,
        lsp_codelens          = true,
        lsp_diag_hdlr         = true,
        lsp_inlay_hints       = {
          enable              = true,
          style               = "eol",
          parameter_hints     = true,
          type_hints          = true,
        },
  
        -- gopls settings
        lsp_keymaps           = false,  -- we manage our own
        lsp_document_formatting = true,
        lsp_semantic_tokens   = true,
  
        -- ── Diagnostic ────────────────────────────────────────────────────────
        diagnostic             = {
          hdlr             = true,
          underline        = true,
          virtual_text     = { space = 0, prefix = "●" },
          signs            = true,
          update_in_insert = false,
        },
  
        -- ── Test output ────────────────────────────────────────────────────────
        test_efm              = false,
        test_runner           = "go",
        test_runner_args      = { "-count=1", "-timeout=30s" },
      },
  
      config = function(_, opts)
        require("go").setup(opts)
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshGo", { clear = true })
  
        -- Format on save
        vim.api.nvim_create_autocmd("BufWritePre", {
          group   = aug,
          pattern = "*.go",
          callback = function()
            local ok, format = pcall(require, "go.format")
            if ok then format.goimport() end
          end,
        })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = { "go", "gomod" },
          callback = function()
            vim.opt_local.expandtab   = false  -- Go uses tabs
            vim.opt_local.tabstop     = 4
            vim.opt_local.shiftwidth  = 4
            vim.opt_local.textwidth   = 120
            vim.opt_local.colorcolumn = "121"
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🐹 Go highlights synced", vim.log.levels.INFO,
              { title = "ASH Go", timeout = 1200 })
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            string.format("🐹 Go loaded — go%s", get_go_version()),
            vim.log.levels.DEBUG,
            { title = "ASH Go" }
          )
        end
      end,
    },
  }