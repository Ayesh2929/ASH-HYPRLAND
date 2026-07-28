-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📋 YAML — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                              ║
-- ║   yamlls · schemastore · kubernetes · GH Actions · docker-compose · fold      ║
-- ║   anchor/alias · validate · ASH theme-synced                                   ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "@lsp.type.property.yaml",     { fg = "#89b4fa"                })
    hl(0, "@lsp.type.string.yaml",       { fg = "#a6e3a1"                })
    hl(0, "@lsp.type.number.yaml",       { fg = "#fab387"                })
    hl(0, "@lsp.type.boolean.yaml",      { bold = true, fg = "#fab387"   })
    hl(0, "@lsp.type.null.yaml",         { fg = "#9399b2"                })
  
    hl(0, "@property.yaml",              { bold = true, fg = "#89b4fa"   })
    hl(0, "@string.yaml",                { fg = "#a6e3a1"                })
    hl(0, "@number.yaml",                { fg = "#fab387"                })
    hl(0, "@boolean.yaml",               { bold = true, fg = "#fab387"   })
    hl(0, "@constant.yaml",              { fg = "#fab387"                })
    hl(0, "@punctuation.special.yaml",   { bold = true, fg = "#cba6f7"   })   -- anchors/aliases &/*
    hl(0, "@type.yaml",                  { italic = true, fg = "#94e2d5" })   -- !!type tags
    hl(0, "@constant.builtin.yaml",      { fg = "#9399b2"                })
  
    -- ── Kubernetes-specific ────────────────────────────────────────────────────
    hl(0, "YamlKubeApiVersion",  { bold = true, fg = "#7aa2f7"   })
    hl(0, "YamlKubeKind",        { bold = true, fg = "#f9e2af"   })
    hl(0, "YamlAnchor",          { bold = true, fg = "#cba6f7"   })
    hl(0, "YamlAlias",           { italic = true, fg = "#cba6f7" })
    hl(0, "YamlTag",             { italic = true, fg = "#94e2d5" })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then hl(0, "@property.yaml",  { bold = true, fg = p.blue }) end
      if p.green  then hl(0, "@string.yaml",    { fg = p.green             }) end
      if p.peach  then hl(0, "@number.yaml",    { fg = p.peach             }) end
      if p.mauve  then
        hl(0, "@punctuation.special.yaml", { bold = true, fg = p.mauve })
        hl(0, "YamlAnchor",               { bold = true, fg = p.mauve })
        hl(0, "YamlAlias",                { italic = true, fg = p.mauve })
      end
      if p.teal   then
        hl(0, "@type.yaml",  { italic = true, fg = p.teal })
        hl(0, "YamlTag",     { italic = true, fg = p.teal })
      end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 YAML UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Detect YAML file type from content / filename
  local function detect_yaml_type()
    local file = vim.api.nvim_buf_get_name(0)
    local name = vim.fn.fnamemodify(file, ":t")
  
    if name:match("docker%-compose") then return "docker-compose" end
    if name:match("%.github/workflows/") or file:match("%.github/workflows/") then
      return "github-actions"
    end
  
    local lines = vim.api.nvim_buf_get_lines(0, 0, 10, false)
    for _, line in ipairs(lines) do
      if line:match("^apiVersion:") then return "kubernetes" end
      if line:match("^kind:") then return "kubernetes" end
      if line:match("docker%-compose") then return "docker-compose" end
      if line:match("on:%s*push") or line:match("on:%s*pull_request") then
        return "github-actions"
      end
    end
    return "generic"
  end
  
  -- Validate YAML with yamllint
  local function validate_yaml()
    local file = vim.api.nvim_buf_get_name(0)
    if file == "" then
      vim.notify("📋 Save file first", vim.log.levels.WARN, { title = "YAML" })
      return
    end
  
    if vim.fn.executable("yamllint") ~= 1 then
      vim.notify("📋 yamllint not found", vim.log.levels.WARN, { title = "YAML" })
      return
    end
  
    local result = vim.fn.system("yamllint -d '{extends: relaxed, rules: {line-length: {max: 120}}}' " .. vim.fn.shellescape(file) .. " 2>&1")
  
    if vim.v.shell_error == 0 then
      vim.notify("📋 ✅ Valid YAML", vim.log.levels.INFO, { title = "YAML", timeout = 1500 })
    else
      local qflist = {}
      for line in result:gmatch("[^\n]+") do
        local lnum, col, sev, msg = line:match(":(%d+):(%d+): (%w+) (.+)$")
        if lnum then
          table.insert(qflist, {
            filename = file,
            lnum     = tonumber(lnum),
            col      = tonumber(col),
            type     = sev == "error" and "E" or "W",
            text     = msg,
          })
        end
      end
      if #qflist > 0 then
        vim.fn.setqflist(qflist)
        vim.cmd("copen")
      end
      vim.notify("📋 YAML issues found", vim.log.levels.WARN, { title = "YAML" })
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
        vim.list_extend(opts.ensure_installed, { "yaml" })
      end,
    },
  
    {
      "b0o/schemastore.nvim", lazy = true,
    },
  
    {
      "neovim/nvim-lspconfig",
      ft   = { "yaml", "yaml.docker-compose", "yaml.ansible" },
      opts = {
        servers = {
          yamlls = {
            capabilities = {
              textDocument = {
                foldingRange = { dynamicRegistration = false, lineFoldingOnly = true },
              },
            },
            on_attach = function(client, bufnr)
              -- Disable yamlls formatting (use prettier)
              client.server_capabilities.documentFormattingProvider = false
              local global = _G.AshLspOnAttach
              if global then global(client, bufnr) end
            end,
            settings = {
              redhat  = { telemetry = { enabled = false } },
              yaml    = {
                keyOrdering   = false,
                format        = { enable = true, singleQuote = false },
                hover         = true,
                completion    = true,
                validate      = true,
                schemas       = function()
                  local ok, ss = pcall(require, "schemastore")
                  if ok then return ss.yaml.schemas() end
                  return {}
                end,
                schemaStore   = {
                  enable = false,
                  url    = "",
                },
                customTags    = {
                  "!reference sequence",    -- GitLab CI
                  "!Ref",                   -- CloudFormation
                  "!Sub",                   -- CloudFormation
                  "!GetAtt",                -- CloudFormation
                  "!If sequence",           -- CloudFormation
                  "!Select sequence",       -- CloudFormation
                  "!Join sequence",         -- CloudFormation
                  "!And sequence",          -- CloudFormation
                  "!Or sequence",           -- CloudFormation
                },
              },
            },
          },
        },
      },
    },
  
    {
      "nvim-lua/plenary.nvim",
      ft = { "yaml", "yaml.docker-compose" },
  
      keys = {
        { "<leader>yv",  validate_yaml, ft = { "yaml" }, desc = "📋 YAML: Validate" },
        {
          "<leader>yt",
          function()
            local yaml_type = detect_yaml_type()
            local type_icons = {
              kubernetes      = "☸️  Kubernetes",
              ["docker-compose"] = "🐳 Docker Compose",
              ["github-actions"] = " GitHub Actions",
              generic         = "📋 Generic YAML",
            }
            vim.notify(
              string.format("📋 YAML Type: %s", type_icons[yaml_type] or yaml_type),
              vim.log.levels.INFO,
              { title = "YAML", timeout = 1500 }
            )
          end,
          ft   = { "yaml" },
          desc = "📋 YAML: Detect type",
        },
        {
          "<leader>yk",
          function()
            local ok_term, term = pcall(require, "toggleterm.terminal")
            local file = vim.api.nvim_buf_get_name(0)
            if vim.fn.executable("kubectl") ~= 1 then
              vim.notify("📋 kubectl not found", vim.log.levels.WARN, { title = "YAML" })
              return
            end
            if ok_term then
              term.Terminal:new({
                cmd          = "kubectl apply -f " .. vim.fn.shellescape(file) .. " --dry-run=client",
                direction    = "float",
                display_name = "☸️  kubectl dry-run",
                float_opts   = { border = "rounded" },
                close_on_exit = false,
              }):toggle()
            end
          end,
          ft   = { "yaml" },
          desc = "📋 YAML: kubectl dry-run",
        },
      },
  
      config = function()
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshYaml", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = { "yaml", "yaml.docker-compose", "yaml.ansible" },
          callback = function()
            vim.opt_local.expandtab   = true
            vim.opt_local.shiftwidth  = 2
            vim.opt_local.tabstop     = 2
            vim.opt_local.softtabstop = 2
            vim.opt_local.textwidth   = 120
            vim.opt_local.foldmethod  = "expr"
            vim.opt_local.foldexpr    = "v:lua.vim.treesitter.foldexpr()"
            vim.opt_local.foldlevel   = 99
  
            -- Auto-detect schema based on content
            vim.defer_fn(function()
              local yaml_type = detect_yaml_type()
              if yaml_type ~= "generic" and vim.g.ash_debug then
                vim.notify(
                  string.format("📋 Detected: %s", yaml_type),
                  vim.log.levels.DEBUG,
                  { title = "YAML" }
                )
              end
            end, 500)
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("📋 YAML highlights synced", vim.log.levels.INFO,
              { title = "ASH YAML", timeout = 1200 })
          end,
        })
      end,
    },
  }