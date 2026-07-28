-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🔧 TOML — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                              ║
-- ║   taplo · Cargo.toml · pyproject.toml · format · validate · ASH theme         ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Treesitter TOML tokens ────────────────────────────────────────────────
    hl(0, "@property.toml",           { bold = true,   fg = "#89b4fa" })
    hl(0, "@string.toml",             { fg = "#a6e3a1"                })
    hl(0, "@number.toml",             { fg = "#fab387"                })
    hl(0, "@boolean.toml",            { bold = true,   fg = "#fab387" })
    hl(0, "@type.toml",               { bold = true,   fg = "#f9e2af" })   -- [table] / [[array]]
    hl(0, "@comment.toml",            { italic = true, fg = "#9399b2" })
    hl(0, "@string.special.toml",     { fg = "#7dcfff"                })   -- datetime literals
    hl(0, "@punctuation.bracket.toml",{ fg = "#cdd6f4"                })
    hl(0, "@punctuation.special.toml",{ fg = "#cba6f7"                })   -- [[ ]] markers
  
    -- ── LSP tokens ────────────────────────────────────────────────────────────
    hl(0, "@lsp.type.tableHeader.toml",    { bold = true, fg = "#f9e2af" })
    hl(0, "@lsp.type.arrayTableHeader.toml",{ bold = true, fg = "#fab387" })
    hl(0, "@lsp.type.key.toml",            { fg = "#89b4fa"               })
    hl(0, "@lsp.type.string.toml",         { fg = "#a6e3a1"               })
    hl(0, "@lsp.type.integer.toml",        { fg = "#fab387"               })
    hl(0, "@lsp.type.float.toml",          { fg = "#fab387"               })
    hl(0, "@lsp.type.bool.toml",           { bold = true, fg = "#fab387"  })
    hl(0, "@lsp.type.datetime.toml",       { fg = "#7dcfff"               })
    hl(0, "@lsp.type.comment.toml",        { italic = true, fg = "#9399b2" })
  
    -- ── Cargo.toml-specific (via crates.nvim — defined in rust.lua) ──────────
    -- Extra TOML semantic highlights
    hl(0, "TomlTableHeader",      { bold = true, fg = "#f9e2af", bg = "#2d2a1e"  })
    hl(0, "TomlArrayHeader",      { bold = true, fg = "#fab387", bg = "#2d1b10"  })
    hl(0, "TomlKey",              { bold = true, fg = "#89b4fa"                  })
    hl(0, "TomlValue",            { fg = "#a6e3a1"                               })
    hl(0, "TomlDate",             { italic = true, fg = "#7dcfff"                })
    hl(0, "TomlInlineTable",      { fg = "#cdd6f4"                               })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then
        hl(0, "@property.toml",  { bold = true, fg = p.blue })
        hl(0, "TomlKey",         { bold = true, fg = p.blue })
      end
      if p.green  then
        hl(0, "@string.toml",    { fg = p.green })
        hl(0, "TomlValue",       { fg = p.green })
      end
      if p.peach  then
        hl(0, "@number.toml",    { fg = p.peach })
        hl(0, "@boolean.toml",   { bold = true, fg = p.peach })
      end
      if p.yellow then
        hl(0, "@type.toml",         { bold = true, fg = p.yellow })
        hl(0, "TomlTableHeader",    { bold = true, fg = p.yellow, bg = p.surface0 or "#2d2a1e" })
      end
      if p.peach  then
        hl(0, "TomlArrayHeader",    { bold = true, fg = p.peach, bg = p.surface0 or "#2d1b10" })
      end
      if p.cyan   then
        hl(0, "@string.special.toml",{ fg = p.cyan })
        hl(0, "TomlDate",            { italic = true, fg = p.cyan })
      end
      if p.mauve  then hl(0, "@punctuation.special.toml", { fg = p.mauve }) end
      local dim = p.overlay0 or "#9399b2"
      hl(0, "@comment.toml", { italic = true, fg = dim })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 TOML UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Detect TOML file type
  local function detect_toml_type()
    local file = vim.api.nvim_buf_get_name(0)
    local name = vim.fn.fnamemodify(file, ":t")
  
    if name == "Cargo.toml"     then return "cargo"      end
    if name == "pyproject.toml" then return "pyproject"  end
    if name == "config.toml"    then return "config"     end
    if name == "Taskfile.toml"  then return "taskfile"   end
    if name == "flake.toml"     then return "flake"      end
    if name == "stylua.toml"    then return "stylua"     end
    if name == "selene.toml"    then return "selene"     end
    if name == "rustfmt.toml"   then return "rustfmt"    end
    return "generic"
  end
  
  -- Format with taplo
  local function format_toml()
    if vim.fn.executable("taplo") ~= 1 then
      vim.lsp.buf.format({ async = true })
      return
    end
    local file = vim.api.nvim_buf_get_name(0)
    if file == "" then
      vim.notify("🔧 Save file first", vim.log.levels.WARN, { title = "TOML" })
      return
    end
    vim.fn.system("taplo fmt " .. vim.fn.shellescape(file))
    vim.cmd("checktime")
    vim.notify("🔧 TOML formatted", vim.log.levels.INFO, { title = "TOML", timeout = 1000 })
  end
  
  -- Validate with taplo
  local function validate_toml()
    if vim.fn.executable("taplo") ~= 1 then
      vim.notify("🔧 taplo not found", vim.log.levels.WARN, { title = "TOML" })
      return
    end
    local file   = vim.api.nvim_buf_get_name(0)
    local result = vim.fn.system("taplo check " .. vim.fn.shellescape(file) .. " 2>&1")
    if vim.v.shell_error == 0 then
      vim.notify("🔧 ✅ Valid TOML", vim.log.levels.INFO, { title = "TOML", timeout = 1500 })
    else
      vim.notify("🔧 ❌ TOML errors:\n" .. result, vim.log.levels.ERROR, { title = "TOML" })
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
        vim.list_extend(opts.ensure_installed, { "toml" })
      end,
    },
  
    {
      "neovim/nvim-lspconfig",
      ft   = { "toml" },
      opts = {
        servers = {
          taplo = {
            on_attach = function(client, bufnr)
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
            settings = {
              evenBetterToml = {
                schema         = {
                  enabled              = true,
                  repositoryEnabled    = true,
                  associations         = {
                    ["Cargo.toml"]     = "https://raw.githubusercontent.com/SchemaStore/schemastore/master/src/schemas/json/cargo.json",
                    ["pyproject.toml"] = "https://json.schemastore.org/pyproject.json",
                    ["stylua.toml"]    = "https://raw.githubusercontent.com/JohnnyMorganz/StyLua/main/schemas/v0-stylua.json",
                    ["selene.toml"]    = "https://raw.githubusercontent.com/Kampfkarren/selene/master/selene.schema.json",
                  },
                },
                formatter      = {
                  alignEntries           = false,
                  arrayTrailingComma     = true,
                  arrayAutoExpand        = true,
                  arrayAutoCollapse      = true,
                  compactArrays          = true,
                  compactInlineTables    = false,
                  compactEntries         = false,
                  columnWidth            = 80,
                  indentTables           = false,
                  indentEntries          = false,
                  indentString           = "  ",
                  reorderKeys            = false,
                  reorderArrays          = false,
                  allowedBlankLines      = 2,
                  trailingNewline        = true,
                  crlf                   = false,
                },
                actions        = {
                  ignoreDeprecatedAssociations = false,
                },
                completion     = { maxResults = 30 },
                diagnostics    = { enabled = true },
                syntax         = { enabled = true },
              },
            },
          },
        },
      },
    },
  
    {
      "nvim-lua/plenary.nvim",
      ft = "toml",
  
      keys = {
        { "<leader>tf",  format_toml,   ft = "toml", desc = "🔧 TOML: Format"        },
        { "<leader>tv",  validate_toml, ft = "toml", desc = "🔧 TOML: Validate"       },
        {
          "<leader>tt",
          function()
            local t     = detect_toml_type()
            local icons = {
              cargo      = "🦀 Cargo.toml",
              pyproject  = "🐍 pyproject.toml",
              config     = "⚙️  config.toml",
              stylua     = "🌙 stylua.toml",
              selene     = "🌙 selene.toml",
              rustfmt    = "🦀 rustfmt.toml",
              generic    = "🔧 TOML",
            }
            vim.notify(
              string.format("🔧 TOML Type: %s", icons[t] or t),
              vim.log.levels.INFO,
              { title = "TOML", timeout = 1500 }
            )
          end,
          ft   = "toml",
          desc = "🔧 TOML: Detect type",
        },
        {
          "<leader>ti",
          function()
            local taplo_ver = vim.fn.trim(vim.fn.system("taplo --version 2>/dev/null"))
            vim.notify(
              table.concat({
                "🔧 TOML Environment",
                "──────────────────────────────────",
                string.format("  taplo:   %s", taplo_ver ~= "" and taplo_ver or "⭕ not found"),
                string.format("  Type:    %s", detect_toml_type()),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "TOML Info" }
            )
          end,
          ft   = "toml",
          desc = "🔧 TOML: Environment info",
        },
      },
  
      config = function()
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshToml", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = "toml",
          callback = function()
            vim.opt_local.expandtab   = true
            vim.opt_local.shiftwidth  = 2
            vim.opt_local.tabstop     = 2
            vim.opt_local.softtabstop = 2
            vim.opt_local.textwidth   = 80
            vim.opt_local.foldmethod  = "expr"
            vim.opt_local.foldexpr    = "v:lua.vim.treesitter.foldexpr()"
            vim.opt_local.foldlevel   = 99
  
            -- Show table header highlights via extmarks (optional enhancement)
            local bufnr = vim.api.nvim_get_current_buf()
            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
            local ns    = vim.api.nvim_create_namespace("AshTomlHeaders")
  
            vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  
            for i, line in ipairs(lines) do
              if line:match("^%[%[.-%]%]") then
                vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, {
                  hl_group   = "TomlArrayHeader",
                  hl_eol     = false,
                  priority   = 100,
                })
              elseif line:match("^%[.-%]") then
                vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, {
                  hl_group   = "TomlTableHeader",
                  hl_eol     = false,
                  priority   = 100,
                })
              end
            end
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🔧 TOML highlights synced", vim.log.levels.INFO,
              { title = "ASH TOML", timeout = 1200 })
          end,
        })
      end,
    },
  }