-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🎯 KOTLIN — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                            ║
-- ║   kotlin-language-server · ktfmt · gradle · coroutines · Android               ║
-- ║   Spring Boot · serialization · ASH theme-synced                               ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "@lsp.type.class.kotlin",           { bold = true,   fg = "#f9e2af" })
    hl(0, "@lsp.type.interface.kotlin",       { italic = true, fg = "#94e2d5" })
    hl(0, "@lsp.type.object.kotlin",          { bold = true,   fg = "#fab387" })
    hl(0, "@lsp.type.enum.kotlin",            { fg = "#89dceb"                })
    hl(0, "@lsp.type.enumMember.kotlin",      { fg = "#89dceb"                })
    hl(0, "@lsp.type.function.kotlin",        { fg = "#89b4fa"                })
    hl(0, "@lsp.type.method.kotlin",          { fg = "#89b4fa"                })
    hl(0, "@lsp.type.annotation.kotlin",      { italic = true, fg = "#cba6f7" })
    hl(0, "@lsp.type.typeParameter.kotlin",   { italic = true, fg = "#94e2d5" })
    hl(0, "@lsp.type.parameter.kotlin",       { italic = true, fg = "#c8c8c8" })
    hl(0, "@lsp.type.variable.kotlin",        { fg = "#cdd6f4"                })
    hl(0, "@lsp.type.namespace.kotlin",       { italic = true, fg = "#89b4fa" })
    hl(0, "@lsp.typemod.function.suspend.kotlin",  { italic = true, fg = "#89b4fa" })
    hl(0, "@lsp.typemod.method.suspend.kotlin",    { italic = true, fg = "#89b4fa" })
    hl(0, "KotlinDataClass",   { bold = true, fg = "#f9e2af"   })
    hl(0, "KotlinSealedClass", { bold = true, fg = "#f38ba8"   })
    hl(0, "KotlinCoroutine",   { italic = true, fg = "#89b4fa" })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.yellow then hl(0, "@lsp.type.class.kotlin",  { bold = true, fg = p.yellow }) end
      if p.teal   then hl(0, "@lsp.type.interface.kotlin", { italic = true, fg = p.teal }) end
      if p.peach  then hl(0, "@lsp.type.object.kotlin",  { bold = true, fg = p.peach  }) end
      if p.blue   then
        hl(0, "@lsp.type.function.kotlin", { fg = p.blue })
        hl(0, "@lsp.typemod.function.suspend.kotlin", { italic = true, fg = p.blue })
      end
      if p.mauve  then hl(0, "@lsp.type.annotation.kotlin", { italic = true, fg = p.mauve }) end
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
        vim.list_extend(opts.ensure_installed, { "kotlin", "groovy" })
      end,
    },
  
    {
      "neovim/nvim-lspconfig",
      ft   = "kotlin",
      opts = {
        servers = {
          kotlin_language_server = {
            on_attach = function(client, bufnr)
              if client.supports_method("textDocument/inlayHint") then
                vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
              end
              local global = _G.AshLspOnAttach
              if global then global(client, bufnr) end
            end,
            settings = {
              kotlin = {
                compiler      = { jvm = { target = "21" } },
                debugAdapter  = { enabled = true, path = vim.fn.stdpath("data") .. "/mason/packages/kotlin-debug-adapter/adapter/bin/kotlin-debug-adapter" },
                externalSources = { useKlsScheme = true, autoConvertToKotlin = true },
                hints         = {
                  typeHints         = true,
                  parameterHints    = true,
                  chainedHints      = true,
                },
                completion    = { snippets = { enabled = true } },
                formatting    = { formatter = "ktfmt" },
                indexing      = { enabled = true },
                linting       = {
                  severity = "error",
                  debounceTime = 500,
                },
              },
            },
          },
        },
      },
    },
  
    {
      "nvim-lua/plenary.nvim",
      ft = "kotlin",
  
      keys = {
        {
          "<leader>kgi",
          function()
            local ver = vim.fn.trim(vim.fn.system("java -version 2>&1 | head -1"))
            vim.notify(
              table.concat({
                "🎯 Kotlin Environment",
                "──────────────────────────────────",
                string.format("  Java:   %s", ver),
                string.format("  gradle: %s", vim.fn.executable("gradle") == 1
                  and vim.fn.trim(vim.fn.system("gradle --version 2>/dev/null | head -1")) or "not found"),
                string.format("  ktfmt:  %s", vim.fn.executable("ktfmt") == 1 and "✅" or "⭕"),
                string.format("  KLS:    %s",
                  vim.fn.executable(vim.fn.stdpath("data") .. "/mason/packages/kotlin-language-server/server/bin/kotlin-language-server") == 1
                    and "✅" or "⭕"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "Kotlin Info" }
            )
          end,
          ft   = "kotlin",
          desc = "🎯 Kotlin: Environment info",
        },
        {
          "<leader>kgb",
          function()
            local ok_term, term = pcall(require, "toggleterm.terminal")
            local cmd = vim.fn.filereadable(vim.fn.getcwd() .. "/gradlew") == 1
              and "./gradlew build" or "gradle build"
            if ok_term then
              term.Terminal:new({
                cmd          = cmd,
                direction    = "float",
                display_name = "🎯 Gradle Build",
                float_opts   = { border = "rounded" },
                close_on_exit = false,
              }):toggle()
            else
              vim.cmd("split term://" .. cmd)
            end
          end,
          ft   = "kotlin",
          desc = "🎯 Kotlin: Gradle build",
        },
        {
          "<leader>kgt",
          function()
            local cmd = vim.fn.filereadable(vim.fn.getcwd() .. "/gradlew") == 1
              and "./gradlew test" or "gradle test"
            local ok_term, term = pcall(require, "toggleterm.terminal")
            if ok_term then
              term.Terminal:new({
                cmd          = cmd,
                direction    = "float",
                display_name = "🎯 Gradle Test",
                float_opts   = { border = "rounded" },
                close_on_exit = false,
              }):toggle()
            else
              vim.cmd("split term://" .. cmd)
            end
          end,
          ft   = "kotlin",
          desc = "🎯 Kotlin: Gradle test",
        },
      },
  
      config = function()
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshKotlin", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = "kotlin",
          callback = function()
            vim.opt_local.expandtab   = true
            vim.opt_local.shiftwidth  = 4
            vim.opt_local.tabstop     = 4
            vim.opt_local.softtabstop = 4
            vim.opt_local.textwidth   = 120
            vim.opt_local.colorcolumn = "121"
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🎯 Kotlin highlights synced", vim.log.levels.INFO,
              { title = "ASH Kotlin", timeout = 1200 })
          end,
        })
      end,
    },
  }