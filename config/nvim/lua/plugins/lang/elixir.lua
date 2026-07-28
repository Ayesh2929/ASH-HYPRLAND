-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       💜 ELIXIR — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                            ║
-- ║   elixir-ls · credo · dialyzer · phoenix · mix · exunit                       ║
-- ║   pattern matching · macros · protocols · ASH theme-synced                    ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "@lsp.type.module.elixir",        { bold = true,   fg = "#cba6f7" })
    hl(0, "@lsp.type.function.elixir",      { fg = "#89b4fa"                })
    hl(0, "@lsp.type.macro.elixir",         { bold = true,   fg = "#cba6f7" })
    hl(0, "@lsp.type.atom.elixir",          { fg = "#a6e3a1"                })
    hl(0, "@lsp.type.variable.elixir",      { fg = "#cdd6f4"                })
    hl(0, "@lsp.type.parameter.elixir",     { italic = true, fg = "#c8c8c8" })
    hl(0, "@lsp.type.struct.elixir",        { bold = true,   fg = "#f9e2af" })
    hl(0, "@lsp.type.protocol.elixir",      { italic = true, fg = "#94e2d5" })
  
    -- Elixir-specific token types
    hl(0, "@module.elixir",       { bold = true,   fg = "#cba6f7" })
    hl(0, "@atom.elixir",         { fg = "#a6e3a1"                })
    hl(0, "@sigil.elixir",        { fg = "#f5c2e7"                })
    hl(0, "ElixirAtom",           { fg = "#a6e3a1"                })
    hl(0, "ElixirMacro",          { bold = true,   fg = "#cba6f7" })
    hl(0, "ElixirProtocol",       { italic = true, fg = "#94e2d5" })
    hl(0, "ElixirGuard",          { italic = true, fg = "#f9e2af" })
    hl(0, "ElixirPipe",           { bold = true,   fg = "#89b4fa" })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.mauve  then
        hl(0, "@lsp.type.module.elixir",  { bold = true, fg = p.mauve })
        hl(0, "@lsp.type.macro.elixir",   { bold = true, fg = p.mauve })
        hl(0, "ElixirMacro",              { bold = true, fg = p.mauve })
      end
      if p.blue   then
        hl(0, "@lsp.type.function.elixir",{ fg = p.blue })
        hl(0, "ElixirPipe",               { bold = true, fg = p.blue })
      end
      if p.green  then
        hl(0, "@lsp.type.atom.elixir",    { fg = p.green })
        hl(0, "ElixirAtom",               { fg = p.green })
      end
      if p.teal   then hl(0, "@lsp.type.protocol.elixir", { italic = true, fg = p.teal }) end
      if p.yellow then hl(0, "@lsp.type.struct.elixir",   { bold = true,   fg = p.yellow }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 ELIXIR UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function get_elixir_version()
    return vim.fn.trim(vim.fn.system("elixir --version 2>/dev/null | head -2"))
  end
  
  local function is_phoenix()
    return vim.fn.filereadable(vim.fn.getcwd() .. "/mix.exs") == 1
      and vim.fn.system("grep -q 'phoenix' " .. vim.fn.getcwd() .. "/mix.exs 2>/dev/null")
      and vim.v.shell_error == 0
  end
  
  local function run_mix_cmd(cmd)
    local ok_term, term = pcall(require, "toggleterm.terminal")
    local full_cmd = "mix " .. cmd
    if ok_term then
      term.Terminal:new({
        cmd          = full_cmd,
        direction    = "float",
        display_name = "💜 mix " .. cmd,
        float_opts   = { border = "rounded" },
        close_on_exit = false,
      }):toggle()
    else
      vim.cmd("split term://" .. full_cmd)
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "nvim-treesitter/nvim-treesitter",
      opts = function(_, opts)
        opts.ensure_installed = opts.ensure_installed or {}
        vim.list_extend(opts.ensure_installed, { "elixir", "heex", "eex" })
      end,
    },
  
    {
      "elixir-tools/elixir-tools.nvim",
      version      = "*",
      ft           = { "elixir", "eelixir", "heex", "surface" },
      dependencies = { "nvim-lua/plenary.nvim" },
      event        = { "BufReadPre", "BufNewFile" },
  
      keys = {
        { "<leader>elt", function() run_mix_cmd("test")                     end, ft = { "elixir", "heex" }, desc = "💜 Elixir: mix test"           },
        { "<leader>elT", function() run_mix_cmd("test --only focus")        end, ft = { "elixir", "heex" }, desc = "💜 Elixir: mix test (focus)"   },
        { "<leader>elc", function() run_mix_cmd("credo --strict")           end, ft = { "elixir", "heex" }, desc = "💜 Elixir: mix credo"          },
        { "<leader>elf", function() run_mix_cmd("format")                   end, ft = { "elixir", "heex" }, desc = "💜 Elixir: mix format"         },
        { "<leader>eld", function() run_mix_cmd("dialyzer")                 end, ft = { "elixir", "heex" }, desc = "💜 Elixir: mix dialyzer"       },
        { "<leader>elg", function() run_mix_cmd("deps.get")                 end, ft = { "elixir", "heex" }, desc = "💜 Elixir: mix deps.get"       },
        { "<leader>els", function() run_mix_cmd("phx.server")               end, ft = { "elixir", "heex" }, desc = "💜 Elixir: mix phx.server"     },
        { "<leader>eli", function() run_mix_cmd("phx.gen.auth Accounts User users") end, ft = { "elixir", "heex" }, desc = "💜 Elixir: Phoenix auth gen" },
        {
          "<leader>elI",
          function()
            vim.notify(
              table.concat({
                "💜 Elixir Environment",
                "──────────────────────────────────",
                get_elixir_version(),
                string.format("  Phoenix:  %s", is_phoenix() and "✅" or "⭕"),
                string.format("  credo:    %s", vim.fn.executable("mix") == 1 and "available" or "⭕"),
                string.format("  dialyzer: %s", vim.fn.executable("mix") == 1 and "available" or "⭕"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "Elixir Info" }
            )
          end,
          ft   = { "elixir", "heex" },
          desc = "💜 Elixir: Environment info",
        },
      },
  
      opts = {
        elixirls = {
          enable   = true,
          tag      = "v0.21.3",
          settings = ElixirLS.settings {
            dialyzerEnabled      = true,
            fetchDeps            = false,
            enableTestLenses     = true,
            suggestSpecs         = true,
            signatureAfterComplete = true,
            mixEnv               = "dev",
            autoInsertRequiredAlias = true,
            autoBuild            = true,
          },
          on_attach = function(client, bufnr)
            if client.supports_method("textDocument/inlayHint") then
              vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
            end
            -- Format on save
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer   = bufnr,
              callback = function()
                vim.lsp.buf.format({ bufnr = bufnr, async = false })
              end,
            })
            local global = _G.AshLspOnAttach
            if global then global(client, bufnr) end
          end,
        },
        credo = {
          enable       = true,
          strict       = true,
        },
        nextls = {
          enable = false,  -- use elixirls by default
        },
      },
  
      config = function(_, opts)
        -- Safe fallback: ElixirLS.settings might not exist yet
        if type(ElixirLS) == "nil" then
          opts.elixirls.settings = {
            dialyzerEnabled      = true,
            fetchDeps            = false,
            enableTestLenses     = true,
            suggestSpecs         = true,
            signatureAfterComplete = true,
          }
        end
  
        require("elixir").setup(opts)
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshElixir", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = { "elixir", "eelixir", "heex" },
          callback = function()
            vim.opt_local.expandtab   = true
            vim.opt_local.shiftwidth  = 2
            vim.opt_local.tabstop     = 2
            vim.opt_local.softtabstop = 2
            vim.opt_local.textwidth   = 98
            vim.opt_local.colorcolumn = "99"
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("💜 Elixir highlights synced", vim.log.levels.INFO,
              { title = "ASH Elixir", timeout = 1200 })
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            "💜 Elixir loaded",
            vim.log.levels.DEBUG,
            { title = "ASH Elixir" }
          )
        end
      end,
    },
  }