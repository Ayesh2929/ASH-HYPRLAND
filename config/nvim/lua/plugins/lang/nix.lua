-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       ❄️  NIX — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                              ║
-- ║   nil_ls · nixfmt · alejandra · statix · deadnix · flakes · home-manager      ║
-- ║   NixOS modules · derivations · ASH theme-synced                               ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "@lsp.type.function.nix",      { fg = "#89b4fa"                })
    hl(0, "@lsp.type.keyword.nix",       { bold = true,   fg = "#f38ba8" })
    hl(0, "@lsp.type.variable.nix",      { fg = "#cdd6f4"                })
    hl(0, "@lsp.type.string.nix",        { fg = "#a6e3a1"                })
    hl(0, "@lsp.type.number.nix",        { fg = "#fab387"                })
    hl(0, "@lsp.type.boolean.nix",       { bold = true,   fg = "#fab387" })
    hl(0, "@lsp.type.null.nix",          { fg = "#9399b2"                })
    hl(0, "@lsp.type.operator.nix",      { fg = "#89b4fa"                })
    hl(0, "@lsp.type.path.nix",          { fg = "#9ece6a"                })
    hl(0, "@lsp.type.parameter.nix",     { italic = true, fg = "#c8c8c8" })
    hl(0, "@lsp.type.attribute.nix",     { fg = "#89b4fa"                })
    hl(0, "@lsp.type.comment.nix",       { italic = true, fg = "#9399b2" })
  
    -- ── Nix-specific concepts ─────────────────────────────────────────────────
    hl(0, "@string.special.path.nix",    { fg = "#9ece6a", italic = true })
    hl(0, "@string.special.uri.nix",     { underline = true, fg = "#89b4fa" })
    hl(0, "@punctuation.special.nix",    { bold = true,   fg = "#cba6f7" })  -- ${}
    hl(0, "@operator.nix",               { fg = "#89b4fa"                })
  
    hl(0, "NixDerivation",    { bold = true,   fg = "#f9e2af" })
    hl(0, "NixBuiltin",       { bold = true,   fg = "#7dcfff" })
    hl(0, "NixAttrSet",       { fg = "#cdd6f4"                })
    hl(0, "NixInherit",       { bold = true,   fg = "#cba6f7" })
    hl(0, "NixLet",           { bold = true,   fg = "#cba6f7" })
    hl(0, "NixWith",          { bold = true,   fg = "#cba6f7" })
    hl(0, "NixFlake",         { bold = true,   fg = "#7aa2f7" })
    hl(0, "NixOption",        { italic = true, fg = "#94e2d5" })
    hl(0, "NixModule",        { bold = true,   fg = "#f9e2af" })
    hl(0, "NixPackage",       { italic = true, fg = "#9ece6a" })
    hl(0, "NixPath",          { fg = "#9ece6a"                })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then
        hl(0, "@lsp.type.function.nix",  { fg = p.blue })
        hl(0, "NixFlake",                { bold = true, fg = p.blue })
      end
      if p.green  then
        hl(0, "@lsp.type.path.nix",      { fg = p.green })
        hl(0, "NixPath",                 { fg = p.green })
        hl(0, "NixPackage",              { italic = true, fg = p.green })
      end
      if p.mauve  then
        hl(0, "@punctuation.special.nix",{ bold = true, fg = p.mauve })
        hl(0, "NixInherit",              { bold = true, fg = p.mauve })
        hl(0, "NixLet",                  { bold = true, fg = p.mauve })
        hl(0, "NixWith",                 { bold = true, fg = p.mauve })
      end
      if p.yellow then
        hl(0, "NixDerivation",           { bold = true, fg = p.yellow })
        hl(0, "NixModule",               { bold = true, fg = p.yellow })
      end
      if p.cyan   then hl(0, "NixBuiltin", { bold = true, fg = p.cyan }) end
      if p.teal   then hl(0, "NixOption",  { italic = true, fg = p.teal }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 NIX UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function get_formatter()
    if vim.fn.executable("alejandra") == 1 then return "alejandra" end
    if vim.fn.executable("nixfmt")    == 1 then return "nixfmt"    end
    return nil
  end
  
  local function is_flake()
    return vim.fn.filereadable(vim.fn.getcwd() .. "/flake.nix") == 1
  end
  
  local function run_nix(cmd, title)
    local ok_term, term = pcall(require, "toggleterm.terminal")
    if ok_term then
      term.Terminal:new({
        cmd          = "nix " .. cmd,
        direction    = "float",
        display_name = "❄️  nix " .. (title or cmd:match("^%S+")),
        float_opts   = { border = "rounded" },
        close_on_exit = false,
      }):toggle()
    else
      vim.cmd("split term://nix " .. cmd)
    end
  end
  
  local function lint_nix()
    local statix_ok  = vim.fn.executable("statix")  == 1
    local deadnix_ok = vim.fn.executable("deadnix") == 1
  
    if not statix_ok and not deadnix_ok then
      vim.notify("❄️  Neither statix nor deadnix found", vim.log.levels.WARN,
        { title = "Nix" })
      return
    end
  
    local file    = vim.api.nvim_buf_get_name(0)
    local qflist  = {}
  
    if statix_ok then
      local result = vim.fn.systemlist(
        "statix check " .. vim.fn.shellescape(file) .. " 2>&1"
      )
      for _, line in ipairs(result) do
        local lnum, msg = line:match("(%d+):.*warning: (.+)")
        if lnum then
          table.insert(qflist, {
            filename = file,
            lnum     = tonumber(lnum),
            type     = "W",
            text     = "[statix] " .. msg,
          })
        end
      end
    end
  
    if deadnix_ok then
      local result = vim.fn.systemlist(
        "deadnix " .. vim.fn.shellescape(file) .. " 2>&1"
      )
      for _, line in ipairs(result) do
        local lnum, msg = line:match("(%d+):%d+: (.+)")
        if lnum then
          table.insert(qflist, {
            filename = file,
            lnum     = tonumber(lnum),
            type     = "W",
            text     = "[deadnix] " .. msg,
          })
        end
      end
    end
  
    if #qflist > 0 then
      vim.fn.setqflist(qflist)
      vim.cmd("copen")
      vim.notify(string.format("❄️  %d Nix lint issue(s)", #qflist), vim.log.levels.WARN,
        { title = "Nix Lint" })
    else
      vim.notify("❄️  ✅ No Nix issues found", vim.log.levels.INFO,
        { title = "Nix Lint", timeout = 1500 })
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
        vim.list_extend(opts.ensure_installed, { "nix" })
      end,
    },
  
    {
      "neovim/nvim-lspconfig",
      ft   = "nix",
      opts = {
        servers = {
          nil_ls = {
            on_attach = function(client, bufnr)
              -- Format on save using alejandra or nixfmt
              vim.api.nvim_create_autocmd("BufWritePre", {
                buffer   = bufnr,
                callback = function()
                  local fmt = get_formatter()
                  if fmt then
                    local file = vim.api.nvim_buf_get_name(bufnr)
                    vim.fn.system(fmt .. " " .. vim.fn.shellescape(file))
                    vim.cmd("checktime")
                  else
                    vim.lsp.buf.format({ bufnr = bufnr, async = false })
                  end
                end,
              })
              local global = _G.AshLspOnAttach
              if global then global(client, bufnr) end
            end,
            settings = {
              ["nil"] = {
                formatting   = {
                  command = (function()
                    local fmt = get_formatter()
                    return fmt and { fmt } or nil
                  end)(),
                },
                diagnostics  = { ignored  = {}, excludedFiles = {} },
                nix          = {
                  binary       = "nix",
                  maxMemoryMB  = 2560,
                  flake        = {
                    autoArchive    = false,
                    autoEvalInputs = false,
                    nixpkgsInputName = "nixpkgs",
                  },
                },
              },
            },
          },
        },
      },
    },
  
    {
      "nvim-lua/plenary.nvim",
      ft = "nix",
  
      keys = {
        { "<leader>nxl", lint_nix,                                         ft = "nix", desc = "❄️  Nix: Lint (statix + deadnix)" },
        { "<leader>nxf", function()
            local fmt = get_formatter()
            if fmt then
              local file = vim.api.nvim_buf_get_name(0)
              vim.fn.system(fmt .. " " .. vim.fn.shellescape(file))
              vim.cmd("checktime")
              vim.notify("❄️  Formatted with " .. fmt, vim.log.levels.INFO,
                { title = "Nix", timeout = 1000 })
            else
              vim.notify("❄️  No formatter found (install alejandra or nixfmt)",
                vim.log.levels.WARN, { title = "Nix" })
            end
          end,                                                               ft = "nix", desc = "❄️  Nix: Format" },
        { "<leader>nxb", function() run_nix("build", "build")             end, ft = "nix", desc = "❄️  Nix: Build"             },
        { "<leader>nxr", function() run_nix("run .#", "run")              end, ft = "nix", desc = "❄️  Nix: Run"               },
        { "<leader>nxd", function() run_nix("develop", "develop")         end, ft = "nix", desc = "❄️  Nix: Develop shell"     },
        { "<leader>nxc", function() run_nix("flake check", "check")       end, ft = "nix", desc = "❄️  Nix: Flake check"       },
        { "<leader>nxu", function() run_nix("flake update", "update")     end, ft = "nix", desc = "❄️  Nix: Flake update"      },
        { "<leader>nxs", function() run_nix("flake show", "show")         end, ft = "nix", desc = "❄️  Nix: Flake show"        },
        {
          "<leader>nxi",
          function()
            local nix_v   = vim.fn.trim(vim.fn.system("nix --version 2>/dev/null"))
            local fmt     = get_formatter() or "⭕ none"
            vim.notify(
              table.concat({
                "❄️  Nix Environment",
                "──────────────────────────────────",
                string.format("  Nix:       %s", nix_v),
                string.format("  Formatter: %s", fmt),
                string.format("  statix:    %s", vim.fn.executable("statix")   == 1 and "✅" or "⭕"),
                string.format("  deadnix:   %s", vim.fn.executable("deadnix")  == 1 and "✅" or "⭕"),
                string.format("  nil_ls:    %s", vim.fn.executable("nil")       == 1 and "✅" or "⭕"),
                string.format("  flake:     %s", is_flake() and "✅ flake.nix found" or "⭕"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "Nix Info" }
            )
          end,
          ft   = "nix",
          desc = "❄️  Nix: Environment info",
        },
      },
  
      config = function()
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshNix", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = "nix",
          callback = function()
            vim.opt_local.expandtab   = true
            vim.opt_local.shiftwidth  = 2
            vim.opt_local.tabstop     = 2
            vim.opt_local.softtabstop = 2
            vim.opt_local.textwidth   = 100
            vim.opt_local.commentstring = "# %s"
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("❄️  Nix highlights synced", vim.log.levels.INFO,
              { title = "ASH Nix", timeout = 1200 })
          end,
        })
      end,
    },
  }