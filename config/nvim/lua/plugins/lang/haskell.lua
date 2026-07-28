-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       λ HASKELL — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                            ║
-- ║   haskell-tools · hls · fourmolu · hlint · cabal · stack · ghci               ║
-- ║   type info · hole fitting · refactoring · ASH theme-synced                   ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── HLS semantic tokens ───────────────────────────────────────────────────
    hl(0, "@lsp.type.type.haskell",           { bold = true,   fg = "#f9e2af" })
    hl(0, "@lsp.type.class.haskell",          { italic = true, fg = "#94e2d5" })
    hl(0, "@lsp.type.function.haskell",       { fg = "#89b4fa"                })
    hl(0, "@lsp.type.variable.haskell",       { fg = "#cdd6f4"                })
    hl(0, "@lsp.type.typeVariable.haskell",   { italic = true, fg = "#94e2d5" })
    hl(0, "@lsp.type.typeConstructor.haskell",{ bold = true,   fg = "#f9e2af" })
    hl(0, "@lsp.type.dataConstructor.haskell",{ fg = "#89dceb"                })
    hl(0, "@lsp.type.module.haskell",         { italic = true, fg = "#cba6f7" })
    hl(0, "@lsp.type.keyword.haskell",        { bold = true,   fg = "#f38ba8" })
    hl(0, "@lsp.type.operator.haskell",       { fg = "#89b4fa"                })
    hl(0, "@lsp.type.wildcard.haskell",       { fg = "#9399b2"                })
    hl(0, "@lsp.type.hole.haskell",           { bold = true, underline = true, fg = "#f9e2af" })
  
    -- ── Treesitter Haskell ─────────────────────────────────────────────────────
    hl(0, "@constructor.haskell",             { fg = "#89dceb"                })
    hl(0, "@type.builtin.haskell",            { italic = true, fg = "#89dceb" })
    hl(0, "@punctuation.special.haskell",     { fg = "#89b4fa"                })
  
    -- ── Special Haskell concepts ──────────────────────────────────────────────
    hl(0, "HaskellTypeClass",   { italic = true, fg = "#94e2d5"    })
    hl(0, "HaskellKind",        { bold = true,   fg = "#f9e2af"    })
    hl(0, "HaskellHole",        { bold = true,   underline = true, fg = "#f9e2af" })
    hl(0, "HaskellWhere",       { bold = true,   fg = "#cba6f7"    })
    hl(0, "HaskellLet",         { bold = true,   fg = "#cba6f7"    })
    hl(0, "HaskellDo",          { bold = true,   fg = "#cba6f7"    })
    hl(0, "HaskellOperator",    { fg = "#89b4fa"                   })
    hl(0, "HaskellImport",      { italic = true, fg = "#9399b2"    })
    hl(0, "HaskellPragma",      { italic = true, fg = "#9399b2"    })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.yellow then
        hl(0, "@lsp.type.type.haskell",           { bold = true, fg = p.yellow })
        hl(0, "@lsp.type.typeConstructor.haskell", { bold = true, fg = p.yellow })
        hl(0, "HaskellKind",                       { bold = true, fg = p.yellow })
      end
      if p.teal   then
        hl(0, "@lsp.type.class.haskell",      { italic = true, fg = p.teal })
        hl(0, "@lsp.type.typeVariable.haskell",{ italic = true, fg = p.teal })
        hl(0, "HaskellTypeClass",             { italic = true, fg = p.teal })
      end
      if p.blue   then
        hl(0, "@lsp.type.function.haskell",   { fg = p.blue })
        hl(0, "@lsp.type.operator.haskell",   { fg = p.blue })
        hl(0, "HaskellOperator",              { fg = p.blue })
      end
      if p.mauve  then
        hl(0, "@lsp.type.module.haskell",     { italic = true, fg = p.mauve })
        hl(0, "HaskellWhere",                 { bold = true,   fg = p.mauve })
        hl(0, "HaskellLet",                   { bold = true,   fg = p.mauve })
        hl(0, "HaskellDo",                    { bold = true,   fg = p.mauve })
      end
      if p.cyan   then hl(0, "@lsp.type.dataConstructor.haskell", { fg = p.cyan }) end
      if p.red    then hl(0, "@lsp.type.keyword.haskell",         { bold = true, fg = p.red }) end
      if p.yellow then
        hl(0, "@lsp.type.hole.haskell", { bold = true, underline = true, fg = p.yellow })
        hl(0, "HaskellHole",            { bold = true, underline = true, fg = p.yellow })
      end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 HASKELL UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function find_hls()
    local mason = vim.fn.stdpath("data") .. "/mason/bin/haskell-language-server-wrapper"
    if vim.fn.executable(mason) == 1 then return mason end
  
    local which = vim.fn.trim(vim.fn.system("which haskell-language-server-wrapper 2>/dev/null"))
    return which ~= "" and which or "haskell-language-server-wrapper"
  end
  
  local function detect_build_tool()
    local cwd = vim.fn.getcwd()
    if vim.fn.filereadable(cwd .. "/cabal.project") == 1 then return "cabal" end
    if vim.fn.filereadable(cwd .. "/stack.yaml")    == 1 then return "stack" end
    if vim.fn.glob(cwd .. "/*.cabal")               ~= "" then return "cabal" end
    return "cabal"
  end
  
  local function run_haskell_cmd(cmd)
    local tool    = detect_build_tool()
    local full    = tool .. " " .. cmd
    local ok_term, term = pcall(require, "toggleterm.terminal")
    if ok_term then
      term.Terminal:new({
        cmd          = full,
        direction    = "float",
        display_name = "λ " .. full,
        float_opts   = { border = "rounded" },
        close_on_exit = false,
      }):toggle()
    else
      vim.cmd("split term://" .. full)
    end
  end
  
  -- Open GHCi REPL
  local function open_ghci()
    local tool    = detect_build_tool()
    local cmd     = tool == "stack" and "stack ghci" or "cabal repl"
    local ok_term, term = pcall(require, "toggleterm.terminal")
    if ok_term then
      term.Terminal:new({
        cmd          = cmd,
        direction    = "float",
        display_name = "λ GHCi",
        float_opts   = { border = "rounded" },
        close_on_exit = false,
      }):toggle()
    else
      vim.cmd("split term://" .. cmd)
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    -- ── haskell-tools.nvim — main Haskell IDE plugin ─────────────────────────────
    {
      "mrcjkb/haskell-tools.nvim",
      version      = "^3",
      ft           = { "haskell", "lhaskell", "cabal", "cabalproject" },
      dependencies = { "nvim-lua/plenary.nvim" },
  
      keys = {
        -- ── haskell-tools actions ──────────────────────────────────────────────
        { "<leader>hhr", function() vim.cmd.Haskell("repl")                 end, ft = { "haskell", "lhaskell" }, desc = "λ Haskell: Toggle REPL"           },
        { "<leader>hhR", function() vim.cmd.Haskell({ "repl", "buf" })      end, ft = { "haskell", "lhaskell" }, desc = "λ Haskell: Buffer REPL"           },
        { "<leader>hhq", function() vim.cmd.Haskell({ "repl", "quit" })     end, ft = { "haskell", "lhaskell" }, desc = "λ Haskell: Quit REPL"             },
        { "<leader>hht", function() vim.cmd.Haskell("type_signature")        end, ft = { "haskell", "lhaskell" }, desc = "λ Haskell: Type signature (hover)" },
        { "<leader>hhp", function() vim.cmd.Haskell("project_file")          end, ft = { "haskell", "lhaskell" }, desc = "λ Haskell: Project file"          },
        { "<leader>hhf", function() vim.cmd.Haskell("package_cabal_file")    end, ft = { "haskell", "lhaskell" }, desc = "λ Haskell: Cabal file"            },
        { "<leader>hhl", open_ghci,                                           ft = { "haskell", "lhaskell" }, desc = "λ Haskell: Open GHCi"             },
  
        -- ── Build / Test ───────────────────────────────────────────────────────
        { "<leader>hhb", function() run_haskell_cmd("build")                end, ft = { "haskell", "lhaskell" }, desc = "λ Haskell: Build"                 },
        { "<leader>hhT", function() run_haskell_cmd("test")                 end, ft = { "haskell", "lhaskell" }, desc = "λ Haskell: Test"                  },
        { "<leader>hhc", function() run_haskell_cmd("clean")                end, ft = { "haskell", "lhaskell" }, desc = "λ Haskell: Clean"                 },
        { "<leader>hhi", function() run_haskell_cmd("install")              end, ft = { "haskell", "lhaskell" }, desc = "λ Haskell: Install"               },
  
        -- ── Format / Lint ──────────────────────────────────────────────────────
        { "<leader>hhF", function() vim.lsp.buf.format({ async = true })    end, ft = { "haskell", "lhaskell" }, desc = "λ Haskell: Format (fourmolu)"     },
  
        -- ── Info ───────────────────────────────────────────────────────────────
        {
          "<leader>hhI",
          function()
            local hls    = find_hls()
            local tool   = detect_build_tool()
            local ghc_v  = vim.fn.trim(vim.fn.system("ghc --version 2>/dev/null"))
            local cabal_v= vim.fn.trim(vim.fn.system("cabal --version 2>/dev/null | head -1"))
            local stack_v= vim.fn.trim(vim.fn.system("stack --version 2>/dev/null | head -1"))
            vim.notify(
              table.concat({
                "λ Haskell Environment",
                "──────────────────────────────────",
                string.format("  GHC:    %s", ghc_v),
                string.format("  cabal:  %s", cabal_v),
                string.format("  stack:  %s", stack_v),
                string.format("  HLS:    %s", vim.fn.executable(hls) == 1 and "✅" or "⭕"),
                string.format("  Tool:   %s", tool),
                string.format("  fourmolu: %s", vim.fn.executable("fourmolu") == 1 and "✅" or "⭕"),
                string.format("  hlint:    %s", vim.fn.executable("hlint") == 1 and "✅" or "⭕"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "Haskell Info" }
            )
          end,
          ft   = { "haskell", "lhaskell", "cabal" },
          desc = "λ Haskell: Environment info",
        },
      },
  
      ---@type HaskellToolsOpts
      opts = function()
        local ht  = require("haskell-tools")
        local hls = find_hls()
  
        return {
          -- ── Tools ────────────────────────────────────────────────────────────
          tools = {
            codeLens = {
              autoRefresh = true,
            },
            hoogle = {
              mode           = "auto",
              enable         = true,
              keymaps        = {
                hoogle_signature  = "<leader>hhs",
              },
            },
            hover = {
              enable         = true,
              border         = vim.g.border or "rounded",
              stylize_markdown = true,
              auto_focus     = false,
            },
            definition = {
              hoogle_signature = { enable = false },
            },
            repl = {
              handler    = "toggleterm",
              prefer     = function()
                return detect_build_tool() == "stack" and ht.repl.mk_repl_cmd or nil
              end,
              auto_focus = false,
            },
            tags = {
              enable = vim.fn.executable("fast-tags") == 1,
            },
            log = {
              level = vim.log.levels.WARN,
            },
          },
  
          -- ── HLS server ───────────────────────────────────────────────────────
          hls = {
            on_attach = function(client, bufnr, ht_)
              -- Inlay hints
              if client.supports_method("textDocument/inlayHint") then
                vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
              end
  
              -- Codelens refresh
              if client.supports_method("textDocument/codeLens") then
                vim.api.nvim_create_autocmd(
                  { "BufEnter", "CursorHold", "InsertLeave" },
                  {
                    buffer   = bufnr,
                    callback = function() pcall(vim.lsp.codelens.refresh) end,
                  }
                )
              end
  
              -- Format on save via fourmolu
              vim.api.nvim_create_autocmd("BufWritePre", {
                buffer   = bufnr,
                callback = function()
                  local ok_conform, conform = pcall(require, "conform")
                  if ok_conform then
                    conform.format({ bufnr = bufnr, async = false, timeout_ms = 5000 })
                  else
                    vim.lsp.buf.format({ bufnr = bufnr, async = false })
                  end
                end,
              })
  
              local global = _G.AshLspOnAttach
              if global then global(client, bufnr) end
            end,
  
            cmd     = { hls, "--lsp" },
  
            default_settings = {
              haskell = {
                cabalFormattingProvider  = "cabalfmt",
                formattingProvider       = "fourmolu",
                checkProject             = true,
                maxCompletions           = 40,
                checkParents             = "CheckOnSave",
                completionSnippetsOn     = true,
                hlintOn                  = true,
  
                plugin = {
                  alternateNumberFormat  = { globalOn = true },
                  callHierarchy          = { globalOn = true },
                  changeTypeSignature    = { globalOn = true },
                  class = {
                    codeLensOn = true,
                    globalOn   = true,
                  },
                  eval               = { globalOn = true, config = { diff = true } },
                  explicitFixity     = { globalOn = true },
                  gadt               = { globalOn = true },
                  ghcide_code_actions_bindings       = { globalOn = true },
                  ghcide_code_actions_fill_holes     = { globalOn = true },
                  ghcide_code_actions_imports_exports= { globalOn = true },
                  ghcide_code_actions_type_signatures= { globalOn = true },
                  ghcide_completions  = {
                    globalOn       = true,
                    config         = {
                      autoExtendOn = true,
                      snippetsOn   = true,
                    },
                  },
                  ghcide_hover_and_symbols = {
                    hoverOn   = true,
                    symbolsOn = true,
                  },
                  ghcide_type_lenses = {
                    globalOn = true,
                    codeLensOn = true,
                    config   = { mode = "always" },
                  },
                  hlint              = { diagnosticsOn = true, globalOn = true },
                  importLens         = { globalOn = true, codeLensOn = true },
                  moduleName         = { globalOn = true },
                  pragmas            = { codeLensOn = true, completionOn = true },
                  qualifyImportedNames={ globalOn = true },
                  refineImports      = { globalOn = true, codeLensOn = true },
                  rename             = { globalOn = true, config = { crossModule = true } },
                  retrie             = { globalOn = true },
                  splice             = { globalOn = true },
                  stan               = { globalOn = false },   -- too noisy by default
                  tactics = {
                    globalOn   = true,
                    hoverOn    = true,
                    codeLensOn = true,
                    config     = {
                      auto_gas                    = 4,
                      timeout_duration            = 2,
                      max_use_ctor_actions        = 5,
                      hole_severity               = nil,
                      proofstate_styling          = true,
                    },
                  },
                },
              },
            },
          },
        }
      end,
  
      config = function(_, opts)
        -- haskell-tools manages its own LSP attachment via BufEnter
        vim.g.haskell_tools = opts
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshHaskell", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = { "haskell", "lhaskell" },
          callback = function()
            vim.opt_local.expandtab   = true
            vim.opt_local.shiftwidth  = 2
            vim.opt_local.tabstop     = 2
            vim.opt_local.softtabstop = 2
            vim.opt_local.textwidth   = 100
            vim.opt_local.colorcolumn = "101"
            -- Haskell-specific folds
            vim.opt_local.foldmethod  = "indent"
            vim.opt_local.foldlevel   = 4
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("λ Haskell highlights synced", vim.log.levels.INFO,
              { title = "ASH Haskell", timeout = 1200 })
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            string.format(
              "λ Haskell loaded — HLS: %s | Tool: %s",
              vim.fn.executable(find_hls()) == 1 and "✅" or "⭕",
              detect_build_tool()
            ),
            vim.log.levels.DEBUG,
            { title = "ASH Haskell" }
          )
        end
      end,
    },
  }