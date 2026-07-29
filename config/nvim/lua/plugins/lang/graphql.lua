-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🔷 GRAPHQL — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                           ║
-- ║   graphql-lsp · prettier · schema validation · introspection · ASH theme      ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "@lsp.type.type.graphql",      { bold = true,   fg = "#f9e2af" })
    hl(0, "@lsp.type.interface.graphql", { italic = true, fg = "#94e2d5" })
    hl(0, "@lsp.type.enum.graphql",      { fg = "#89dceb"                })
    hl(0, "@lsp.type.field.graphql",     { fg = "#89b4fa"                })
    hl(0, "@lsp.type.argument.graphql",  { italic = true, fg = "#c8c8c8" })
    hl(0, "@lsp.type.keyword.graphql",   { bold = true,   fg = "#f38ba8" })
    hl(0, "@lsp.type.variable.graphql",  { fg = "#cba6f7"                })
    hl(0, "@lsp.type.string.graphql",    { fg = "#a6e3a1"                })
    hl(0, "@lsp.type.number.graphql",    { fg = "#fab387"                })
    hl(0, "@lsp.type.comment.graphql",   { italic = true, fg = "#9399b2" })
    hl(0, "@lsp.type.directive.graphql", { bold = true,   fg = "#cba6f7" })
    hl(0, "@lsp.type.fragment.graphql",  { italic = true, fg = "#94e2d5" })
  
    hl(0, "@type.graphql",               { bold = true,   fg = "#f9e2af" })
    hl(0, "@keyword.graphql",            { bold = true,   fg = "#f38ba8" })
    hl(0, "@field.graphql",              { fg = "#89b4fa"                })
    hl(0, "@variable.graphql",           { fg = "#cba6f7"                })
    hl(0, "@punctuation.special.graphql",{ bold = true,   fg = "#cba6f7" })  -- @
    hl(0, "@string.graphql",             { fg = "#a6e3a1"                })
  
    hl(0, "GraphqlQuery",      { bold = true,   fg = "#89b4fa" })
    hl(0, "GraphqlMutation",   { bold = true,   fg = "#f38ba8" })
    hl(0, "GraphqlSubscription",{ bold = true,  fg = "#9ece6a" })
    hl(0, "GraphqlFragment",   { italic = true, fg = "#94e2d5" })
    hl(0, "GraphqlDirective",  { bold = true,   fg = "#cba6f7" })
    hl(0, "GraphqlScalar",     { italic = true, fg = "#fab387" })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.yellow then hl(0, "@lsp.type.type.graphql",  { bold = true, fg = p.yellow }) end
      if p.blue   then
        hl(0, "@lsp.type.field.graphql",  { fg = p.blue })
        hl(0, "GraphqlQuery",             { bold = true, fg = p.blue })
      end
      if p.teal   then
        hl(0, "@lsp.type.interface.graphql",{ italic = true, fg = p.teal })
        hl(0, "GraphqlFragment",           { italic = true, fg = p.teal })
      end
      if p.red    then
        hl(0, "@lsp.type.keyword.graphql", { bold = true, fg = p.red })
        hl(0, "GraphqlMutation",           { bold = true, fg = p.red })
      end
      if p.green  then hl(0, "GraphqlSubscription", { bold = true, fg = p.green }) end
      if p.mauve  then
        hl(0, "@lsp.type.directive.graphql",{ bold = true, fg = p.mauve })
        hl(0, "GraphqlDirective",           { bold = true, fg = p.mauve })
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
        vim.list_extend(opts.ensure_installed, { "graphql" })
      end,
    },
  
    {
      "neovim/nvim-lspconfig",
      ft   = { "graphql", "gql" },
      opts = {
        servers = {
          graphql = {
            on_attach = function(client, bufnr)
              -- Disable formatting (use prettier)
              client.server_capabilities.documentFormattingProvider = false
              local global = _G.AshLspOnAttach
              if global then global(client, bufnr) end
            end,
            filetypes = { "graphql", "gql", "typescriptreact", "javascriptreact", "typescript", "javascript" },
            root_dir  = require("lspconfig.util").root_pattern(
              ".graphqlrc", ".graphqlrc.json", ".graphqlrc.yaml", ".graphqlrc.yml",
              ".graphqlrc.js", ".graphqlrc.ts",
              "graphql.config.js", "graphql.config.json", "graphql.config.yaml", "graphql.config.ts"
            ),
            settings  = {
              graphql = {
                useSchemaFileDefinitions = true,
              },
            },
          },
        },
      },
    },
  
    {
      "nvim-lua/plenary.nvim",
      ft = { "graphql", "gql" },
  
      keys = {
        {
          "<leader>gqf",
          function()
            local ok, conform = pcall(require, "conform")
            if ok then
              conform.format({ async = true, formatters = { "prettierd", "prettier" } })
            else
              vim.lsp.buf.format({ async = true })
            end
          end,
          ft   = { "graphql", "gql" },
          desc = "🔷 GraphQL: Format",
        },
        {
          "<leader>gqi",
          function()
            local gql_v = vim.fn.trim(vim.fn.system("graphql --version 2>/dev/null"))
            vim.notify(
              table.concat({
                "🔷 GraphQL Environment",
                "──────────────────────────────────",
                string.format("  graphql-cli:  %s", gql_v ~= "" and gql_v or "⭕"),
                string.format("  LSP:          %s", vim.fn.executable("graphql-lsp") == 1 and "✅" or "⭕"),
                string.format("  .graphqlrc:   %s",
                  vim.fn.filereadable(vim.fn.getcwd() .. "/.graphqlrc.json") == 1
                    or vim.fn.filereadable(vim.fn.getcwd() .. ".graphqlrc") == 1
                    and "✅" or "⭕"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "GraphQL Info" }
            )
          end,
          ft   = { "graphql", "gql" },
          desc = "🔷 GraphQL: Info",
        },
      },
  
      config = function()
        setup_highlights()
  
        vim.filetype.add({ extension = { gql = "graphql", graphql = "graphql" } })
  
        local aug = vim.api.nvim_create_augroup("AshGraphQL", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = { "graphql", "gql" },
          callback = function()
            vim.opt_local.expandtab   = true
            vim.opt_local.shiftwidth  = 2
            vim.opt_local.tabstop     = 2
            vim.opt_local.softtabstop = 2
            vim.opt_local.commentstring = "# %s"
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🔷 GraphQL highlights synced", vim.log.levels.INFO,
              { title = "ASH GraphQL", timeout = 1200 })
          end,
        })
      end,
    },
  }