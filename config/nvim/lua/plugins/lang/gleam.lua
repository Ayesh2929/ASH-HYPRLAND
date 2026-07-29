-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       ✨ GLEAM — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                             ║
-- ║   gleam language server · gleam format · gleam test · beam · ASH theme-synced  ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "@lsp.type.type.gleam",        { bold = true,   fg = "#f9e2af" })
    hl(0, "@lsp.type.constructor.gleam", { bold = true,   fg = "#89dceb" })
    hl(0, "@lsp.type.function.gleam",    { fg = "#89b4fa"                })
    hl(0, "@lsp.type.variable.gleam",    { fg = "#cdd6f4"                })
    hl(0, "@lsp.type.parameter.gleam",   { italic = true, fg = "#c8c8c8" })
    hl(0, "@lsp.type.module.gleam",      { italic = true, fg = "#cba6f7" })
    hl(0, "@lsp.type.keyword.gleam",     { bold = true,   fg = "#f38ba8" })
    hl(0, "@lsp.type.operator.gleam",    { fg = "#89b4fa"                })
    hl(0, "@lsp.type.string.gleam",      { fg = "#a6e3a1"                })
    hl(0, "@lsp.type.atom.gleam",        { fg = "#a6e3a1"                })
    hl(0, "@lsp.type.bitString.gleam",   { fg = "#fab387"                })
    hl(0, "@lsp.type.label.gleam",       { italic = true, fg = "#89b4fa" })
  
    hl(0, "GleamPipeline",  { bold = true, fg = "#89b4fa"   })
    hl(0, "GleamUseExpr",   { bold = true, fg = "#cba6f7"   })
    hl(0, "GleamCase",      { bold = true, fg = "#f9e2af"   })
    hl(0, "GleamTestPass",  { bold = true, fg = "#9ece6a"   })
    hl(0, "GleamTestFail",  { bold = true, fg = "#f38ba8"   })
    hl(0, "GleamTuple",     { fg = "#94e2d5"                })
    hl(0, "GleamTypeVar",   { italic = true, fg = "#94e2d5" })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.yellow then hl(0, "@lsp.type.type.gleam", { bold = true, fg = p.yellow }) end
      if p.blue   then
        hl(0, "@lsp.type.function.gleam",{ fg = p.blue })
        hl(0, "GleamPipeline",           { bold = true, fg = p.blue })
      end
      if p.mauve  then
        hl(0, "@lsp.type.module.gleam",{ italic = true, fg = p.mauve })
        hl(0, "GleamUseExpr",          { bold = true,   fg = p.mauve })
      end
      if p.green  then
        hl(0, "@lsp.type.string.gleam",{ fg = p.green })
        hl(0, "GleamTestPass",         { bold = true, fg = p.green })
      end
      if p.teal   then
        hl(0, "GleamTuple",  { fg = p.teal })
        hl(0, "GleamTypeVar",{ italic = true, fg = p.teal })
      end
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
        vim.list_extend(opts.ensure_installed, { "gleam" })
      end,
    },
  
    {
      "neovim/nvim-lspconfig",
      ft   = "gleam",
      opts = {
        servers = {
          gleam = {
            on_attach = function(client, bufnr)
              if client.supports_method("textDocument/inlayHint") then
                vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
              end
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
        },
      },
    },
  
    {
      "nvim-lua/plenary.nvim",
      ft = "gleam",
  
      keys = {
        {
          "<leader>glb",
          function()
            local ok_term, term = pcall(require, "toggleterm.terminal")
            if ok_term then
              term.Terminal:new({
                cmd = "gleam build", direction = "float",
                display_name = "✨ gleam build",
                float_opts = { border = "rounded" }, close_on_exit = false,
              }):toggle()
            end
          end,
          ft   = "gleam",
          desc = "✨ Gleam: Build",
        },
        {
          "<leader>glt",
          function()
            local ok_term, term = pcall(require, "toggleterm.terminal")
            if ok_term then
              term.Terminal:new({
                cmd = "gleam test", direction = "float",
                display_name = "✨ gleam test",
                float_opts = { border = "rounded" }, close_on_exit = false,
              }):toggle()
            end
          end,
          ft   = "gleam",
          desc = "✨ Gleam: Test",
        },
        {
          "<leader>glr",
          function()
            local ok_term, term = pcall(require, "toggleterm.terminal")
            if ok_term then
              term.Terminal:new({
                cmd = "gleam run", direction = "float",
                display_name = "✨ gleam run",
                float_opts = { border = "rounded" }, close_on_exit = false,
              }):toggle()
            end
          end,
          ft   = "gleam",
          desc = "✨ Gleam: Run",
        },
        {
          "<leader>gli",
          function()
            local ver = vim.fn.trim(vim.fn.system("gleam --version 2>/dev/null"))
            vim.notify(
              table.concat({
                "✨ Gleam Environment",
                "──────────────────────────────────",
                string.format("  Gleam: %s", ver),
                string.format("  LSP:   %s", vim.fn.executable("gleam") == 1 and "✅" or "⭕"),
                string.format("  gleam.toml: %s", vim.fn.filereadable(vim.fn.getcwd() .. "/gleam.toml") == 1 and "✅" or "⭕"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "Gleam Info" }
            )
          end,
          ft   = "gleam",
          desc = "✨ Gleam: Environment info",
        },
      },
  
      config = function()
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshGleam", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = "gleam",
          callback = function()
            vim.opt_local.expandtab   = true
            vim.opt_local.shiftwidth  = 2
            vim.opt_local.tabstop     = 2
            vim.opt_local.softtabstop = 2
            vim.opt_local.textwidth   = 100
            vim.opt_local.colorcolumn = "101"
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("✨ Gleam highlights synced", vim.log.levels.INFO,
              { title = "ASH Gleam", timeout = 1200 })
          end,
        })
      end,
    },
  }