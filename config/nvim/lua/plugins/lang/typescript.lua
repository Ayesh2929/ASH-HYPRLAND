-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📘 TYPESCRIPT — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                        ║
-- ║   typescript-tools · tsserver · tsc · eslint · prettier · import sorting      ║
-- ║   JSX/TSX · Vue · Svelte · Astro · type exploration · ASH theme-synced        ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── TypeScript semantic tokens ────────────────────────────────────────────
    hl(0, "@lsp.type.class.typescript",          { bold = true,   fg = "#f9e2af"  })
    hl(0, "@lsp.type.interface.typescript",      { italic = true, fg = "#94e2d5"  })
    hl(0, "@lsp.type.enum.typescript",           { fg = "#89dceb"                 })
    hl(0, "@lsp.type.enumMember.typescript",     { fg = "#89dceb"                 })
    hl(0, "@lsp.type.function.typescript",       { fg = "#89b4fa"                 })
    hl(0, "@lsp.type.method.typescript",         { fg = "#89b4fa"                 })
    hl(0, "@lsp.type.namespace.typescript",      { italic = true, fg = "#cba6f7"  })
    hl(0, "@lsp.type.typeParameter.typescript",  { italic = true, fg = "#94e2d5"  })
    hl(0, "@lsp.type.parameter.typescript",      { italic = true, fg = "#c8c8c8"  })
    hl(0, "@lsp.type.property.typescript",       { fg = "#cdd6f4"                 })
    hl(0, "@lsp.type.variable.typescript",       { fg = "#cdd6f4"                 })
    hl(0, "@lsp.type.decorator.typescript",      { italic = true, fg = "#cba6f7"  })
    hl(0, "@lsp.typemod.function.async.typescript",{ italic = true, fg = "#89b4fa" })
    hl(0, "@lsp.typemod.variable.readonly.typescript", { italic = true            })
  
    -- Apply same to TSX / JS variants
    local ts_variants = {
      "typescriptreact", "javascript", "javascriptreact",
    }
    for _, variant in ipairs(ts_variants) do
      for kind, attrs in pairs({
        class       = { bold = true,   fg = "#f9e2af" },
        interface   = { italic = true, fg = "#94e2d5" },
        ["function"]= { fg = "#89b4fa" },
        method      = { fg = "#89b4fa" },
      }) do
        hl(0, "@lsp.type." .. kind .. "." .. variant, attrs)
      end
    end
  
    -- ── JSX / TSX ─────────────────────────────────────────────────────────────
    hl(0, "@tag.tsx",              { bold = true, fg = "#89b4fa"  })
    hl(0, "@tag.jsx",              { bold = true, fg = "#89b4fa"  })
    hl(0, "@tag.attribute.tsx",    { italic = true, fg = "#9399b2" })
    hl(0, "@tag.attribute.jsx",    { italic = true, fg = "#9399b2" })
    hl(0, "@tag.delimiter.tsx",    { fg = "#6e738d"               })
    hl(0, "@tag.delimiter.jsx",    { fg = "#6e738d"               })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.yellow then
        hl(0, "@lsp.type.class.typescript",     { bold = true,   fg = p.yellow })
      end
      if p.teal   then
        hl(0, "@lsp.type.interface.typescript", { italic = true, fg = p.teal   })
        hl(0, "@lsp.type.typeParameter.typescript", { italic = true, fg = p.teal })
      end
      if p.blue   then
        hl(0, "@lsp.type.function.typescript",  { fg = p.blue })
        hl(0, "@tag.tsx",  { bold = true, fg = p.blue })
        hl(0, "@tag.jsx",  { bold = true, fg = p.blue })
        hl(0, "@lsp.typemod.function.async.typescript", { italic = true, fg = p.blue })
      end
      if p.mauve  then
        hl(0, "@lsp.type.namespace.typescript", { italic = true, fg = p.mauve })
        hl(0, "@lsp.type.decorator.typescript", { italic = true, fg = p.mauve })
      end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 TYPESCRIPT UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function get_ts_version()
    local cwd  = vim.fn.getcwd()
    local tsck = cwd .. "/node_modules/typescript/package.json"
    local f    = io.open(tsck, "r")
    if not f then return "unknown" end
  
    local content = f:read("*a")
    f:close()
  
    local ok, pkg = pcall(vim.fn.json_decode, content)
    return (ok and pkg.version) or "unknown"
  end
  
  local function detect_framework()
    local cwd  = vim.fn.getcwd()
    local pkg  = cwd .. "/package.json"
    local f    = io.open(pkg, "r")
    if not f then return nil end
  
    local content = f:read("*a")
    f:close()
  
    local ok, data = pcall(vim.fn.json_decode, content)
    if not ok then return nil end
  
    local deps = vim.tbl_extend("force",
      data.dependencies    or {},
      data.devDependencies or {}
    )
  
    if deps["next"]           then return "Next.js"     end
    if deps["nuxt"]           then return "Nuxt"        end
    if deps["@remix-run/node"]then return "Remix"       end
    if deps["@sveltejs/kit"]  then return "SvelteKit"   end
    if deps["svelte"]         then return "Svelte"      end
    if deps["vue"]            then return "Vue"         end
    if deps["astro"]          then return "Astro"       end
    if deps["react"]          then return "React"       end
  
    return nil
  end
  
  local function get_tsconfig()
    local names = { "tsconfig.json", "tsconfig.app.json", "tsconfig.base.json" }
    for _, name in ipairs(names) do
      local path = vim.fn.getcwd() .. "/" .. name
      if vim.fn.filereadable(path) == 1 then return path end
    end
    return nil
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    -- ── typescript-tools.nvim ─────────────────────────────────────────────────────
    {
      "pmizio/typescript-tools.nvim",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "neovim/nvim-lspconfig",
      },
      ft = {
        "typescript", "typescriptreact", "javascript", "javascriptreact",
        "vue",
      },
  
      keys = {
        -- ── TypeScript operations ──────────────────────────────────────────────
        { "<leader>to",  "<cmd>TSToolsOrganizeImports<cr>",     ft = { "typescript", "typescriptreact", "javascript" }, desc = "📘 TS: Organize imports"        },
        { "<leader>ts",  "<cmd>TSToolsSortImports<cr>",         ft = { "typescript", "typescriptreact", "javascript" }, desc = "📘 TS: Sort imports"            },
        { "<leader>tu",  "<cmd>TSToolsRemoveUnusedImports<cr>", ft = { "typescript", "typescriptreact", "javascript" }, desc = "📘 TS: Remove unused imports"   },
        { "<leader>tU",  "<cmd>TSToolsRemoveUnused<cr>",        ft = { "typescript", "typescriptreact", "javascript" }, desc = "📘 TS: Remove unused variables"  },
        { "<leader>ta",  "<cmd>TSToolsAddMissingImports<cr>",   ft = { "typescript", "typescriptreact", "javascript" }, desc = "📘 TS: Add missing imports"     },
        { "<leader>tf",  "<cmd>TSToolsFixAll<cr>",              ft = { "typescript", "typescriptreact", "javascript" }, desc = "📘 TS: Fix all"                 },
        { "<leader>tg",  "<cmd>TSToolsGoToSourceDefinition<cr>",ft = { "typescript", "typescriptreact", "javascript" }, desc = "📘 TS: Go to source definition" },
        { "<leader>tr",  "<cmd>TSToolsRenameFile<cr>",          ft = { "typescript", "typescriptreact", "javascript" }, desc = "📘 TS: Rename file"             },
        { "<leader>tR",  "<cmd>TSToolsFileReferences<cr>",      ft = { "typescript", "typescriptreact", "javascript" }, desc = "📘 TS: File references"         },
  
        -- ── Info ───────────────────────────────────────────────────────────────
        {
          "<leader>ti",
          function()
            local fw = detect_framework()
            local tsv = get_ts_version()
            local tsc = get_tsconfig()
            vim.notify(
              table.concat({
                "📘 TypeScript Environment",
                "──────────────────────────────────",
                string.format("  TypeScript: %s", tsv),
                string.format("  Framework:  %s", fw or "(none)"),
                string.format("  tsconfig:   %s", tsc and vim.fn.fnamemodify(tsc, ":t") or "(not found)"),
                string.format("  Node:       %s", vim.fn.trim(vim.fn.system("node --version 2>/dev/null"))),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "TypeScript" }
            )
          end,
          ft  = { "typescript", "typescriptreact" },
          desc = "📘 TS: Environment info",
        },
      },
  
      opts = {
        on_attach = function(client, bufnr)
          -- Disable tsserver formatting in favour of prettier
          client.server_capabilities.documentFormattingProvider      = false
          client.server_capabilities.documentRangeFormattingProvider = false
  
          -- Format on save via conform
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer   = bufnr,
            callback = function()
              local ok_conform, conform = pcall(require, "conform")
              if ok_conform then
                conform.format({ bufnr = bufnr, async = false, timeout_ms = 3000 })
              end
            end,
          })
  
          local global = _G.AshLspOnAttach
          if global then global(client, bufnr) end
        end,
  
        settings = {
          -- ── Separate diagnostic mode ────────────────────────────────────────
          separate_diagnostic_server = true,
          publish_diagnostic_on = "insert_leave",
  
          -- ── Performance ────────────────────────────────────────────────────
          tsserver_max_memory       = "auto",
          tsserver_file_preferences = {
            includeInlayParameterNameHints           = "all",
            includeInlayParameterNameHintsWhenArgumentMatchesName = false,
            includeInlayFunctionParameterTypeHints   = true,
            includeInlayVariableTypeHints            = true,
            includeInlayVariableTypeHintsWhenTypeMatchesName = false,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints  = true,
            includeInlayEnumMemberValueHints         = true,
  
            importModuleSpecifierPreference   = "non-relative",
            quotePreference                   = "auto",
            allowTextChangesInNewFiles        = true,
            providePrefixAndSuffixTextForRename = true,
            allowRenameOfImportPath           = true,
            includeAutomaticOptionalChainCompletions = true,
            provideRefactorNotApplicableReason = true,
            generateReturnInDocTemplate       = true,
            includeCompletionsForImportStatements = true,
            includeCompletionsWithSnippetText = true,
            allowIncompleteCompletions        = true,
            displayPartsForJSDoc              = true,
            disableLineTextInReferences       = true,
          },
  
          tsserver_format_options = {
            allowIncompleteCompletions = false,
            allowRenameOfImportPath    = true,
            insertSpaceAfterCommaDelimiter = true,
            insertSpaceAfterSemicolonInForStatements = true,
            insertSpaceBeforeAndAfterBinaryOperators = true,
            insertSpaceAfterConstructor = false,
            insertSpaceAfterKeywordsInControlFlowStatements = true,
            insertSpaceAfterFunctionKeywordForAnonymousFunctions = true,
            insertSpaceAfterOpeningAndBeforeClosingNonemptyParenthesis = false,
            insertSpaceAfterOpeningAndBeforeClosingNonemptyBrackets = false,
            insertSpaceAfterOpeningAndBeforeClosingNonemptyBraces = true,
            insertSpaceAfterOpeningAndBeforeClosingEmptyBraces = true,
            insertSpaceAfterOpeningAndBeforeClosingTemplateStringBraces = false,
            insertSpaceAfterOpeningAndBeforeClosingJsxExpressionBraces = false,
            insertSpaceBeforeFunctionParenthesis = false,
            placeOpenBraceOnNewLineForFunctions = false,
            placeOpenBraceOnNewLineForControlBlocks = false,
            semicolons = "insert",
            trimTrailingWhitespace = true,
          },
  
          -- ── Expose complete paths ──────────────────────────────────────────
          expose_as_code_action = "all",
  
          -- ── tsserver path ─────────────────────────────────────────────────
          tsserver_path = nil,     -- auto-detect from node_modules
  
          -- ── Plugins ───────────────────────────────────────────────────────
          tsserver_plugins  = {},
          complete_function_calls = true,
          include_completions_with_insert_text = true,
  
          -- ── Code lens ─────────────────────────────────────────────────────
          code_lens = "all",
  
          -- ── Disable member code lens ───────────────────────────────────────
          disable_member_code_lens = true,
  
          -- ── JSX close tag ─────────────────────────────────────────────────
          jsx_close_tag = {
            enable    = true,
            filetypes = { "javascriptreact", "typescriptreact" },
          },
        },
      },
  
      config = function(_, opts)
        require("typescript-tools").setup(opts)
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshTypeScript", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
          callback = function()
            vim.opt_local.expandtab   = true
            vim.opt_local.shiftwidth  = 2
            vim.opt_local.tabstop     = 2
            vim.opt_local.softtabstop = 2
            vim.opt_local.textwidth   = 100
            vim.opt_local.colorcolumn = "101"
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
            vim.notify("📘 TypeScript highlights synced", vim.log.levels.INFO,
              { title = "ASH TS", timeout = 1200 })
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            string.format("📘 TypeScript loaded — TS %s | %s",
              get_ts_version(), detect_framework() or "no framework"),
            vim.log.levels.DEBUG,
            { title = "ASH TypeScript" }
          )
        end
      end,
    },
  }