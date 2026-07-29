-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       ⚡ ZIG — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                               ║
-- ║   zls · zigfmt · build system · test runner · comptime · ASH theme-synced     ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "@lsp.type.type.zig",            { bold = true,   fg = "#f9e2af" })
    hl(0, "@lsp.type.struct.zig",          { bold = true,   fg = "#f9e2af" })
    hl(0, "@lsp.type.enum.zig",            { fg = "#89dceb"                })
    hl(0, "@lsp.type.enumMember.zig",      { fg = "#89dceb"                })
    hl(0, "@lsp.type.function.zig",        { fg = "#89b4fa"                })
    hl(0, "@lsp.type.method.zig",          { fg = "#89b4fa"                })
    hl(0, "@lsp.type.variable.zig",        { fg = "#cdd6f4"                })
    hl(0, "@lsp.type.parameter.zig",       { italic = true, fg = "#c8c8c8" })
    hl(0, "@lsp.type.typeParameter.zig",   { italic = true, fg = "#94e2d5" })
    hl(0, "@lsp.type.keyword.zig",         { bold = true,   fg = "#cba6f7" })
    hl(0, "@lsp.type.operator.zig",        { fg = "#89b4fa"                })
    hl(0, "@lsp.type.namespace.zig",       { italic = true, fg = "#89b4fa" })
    hl(0, "@lsp.type.errorTag.zig",        { bold = true,   fg = "#f38ba8" })
    hl(0, "@lsp.type.builtinFunction.zig", { bold = true,   fg = "#7dcfff" })
  
    -- ── Zig-specific concepts ─────────────────────────────────────────────────
    hl(0, "ZigComptime",     { bold = true,   fg = "#cba6f7" })
    hl(0, "ZigBuiltin",      { bold = true,   fg = "#7dcfff" })
    hl(0, "ZigErrorSet",     { bold = true,   fg = "#f38ba8" })
    hl(0, "ZigPointer",      { fg = "#94e2d5"                })
    hl(0, "ZigSlice",        { fg = "#94e2d5"                })
    hl(0, "ZigTestPass",     { bold = true,   fg = "#9ece6a" })
    hl(0, "ZigTestFail",     { bold = true,   fg = "#f38ba8" })
    hl(0, "ZigBuildStep",    { italic = true, fg = "#89b4fa" })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.yellow then hl(0, "@lsp.type.type.zig",   { bold = true, fg = p.yellow }) end
      if p.blue   then hl(0, "@lsp.type.function.zig",{ fg = p.blue               }) end
      if p.teal   then hl(0, "@lsp.type.typeParameter.zig", { italic = true, fg = p.teal }) end
      if p.mauve  then
        hl(0, "@lsp.type.keyword.zig", { bold = true, fg = p.mauve })
        hl(0, "ZigComptime",           { bold = true, fg = p.mauve })
      end
      if p.red    then
        hl(0, "@lsp.type.errorTag.zig",{ bold = true, fg = p.red })
        hl(0, "ZigErrorSet",           { bold = true, fg = p.red })
      end
      if p.cyan   then
        hl(0, "@lsp.type.builtinFunction.zig",{ bold = true, fg = p.cyan })
        hl(0, "ZigBuiltin",                   { bold = true, fg = p.cyan })
      end
      if p.teal   then
        hl(0, "ZigPointer", { fg = p.teal })
        hl(0, "ZigSlice",   { fg = p.teal })
      end
      if p.green  then hl(0, "ZigTestPass", { bold = true, fg = p.green }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 ZIG UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function find_zls()
    local mason = vim.fn.stdpath("data") .. "/mason/bin/zls"
    if vim.fn.executable(mason) == 1 then return mason end
    local which = vim.fn.trim(vim.fn.system("which zls 2>/dev/null"))
    return which ~= "" and which or "zls"
  end
  
  local function get_zig_version()
    return vim.fn.trim(vim.fn.system("zig version 2>/dev/null"))
  end
  
  local function get_build_steps()
    local result = vim.fn.systemlist("zig build --list-steps 2>/dev/null")
    local steps  = {}
    for _, line in ipairs(result) do
      local step = line:match("^%s*([%w_%-]+)%s*:")
      if step then table.insert(steps, step) end
    end
    return steps
  end
  
  local function run_zig(cmd)
    local ok_term, term = pcall(require, "toggleterm.terminal")
    if ok_term then
      term.Terminal:new({
        cmd          = "zig " .. cmd,
        direction    = "float",
        display_name = "⚡ zig " .. cmd:match("^%S+"),
        float_opts   = { border = "rounded" },
        close_on_exit = false,
      }):toggle()
    else
      vim.cmd("split term://zig " .. cmd)
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
        vim.list_extend(opts.ensure_installed, { "zig" })
      end,
    },
  
    {
      "neovim/nvim-lspconfig",
      ft   = "zig",
      opts = {
        servers = {
          zls = {
            cmd     = { find_zls() },
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
            settings = {
              zls = {
                enable_inlay_hints                   = true,
                enable_snippets                       = true,
                enable_ast_check_diagnostics          = true,
                enable_autofix                        = true,
                enable_import_embedfile_argument_hints= true,
                warn_style                            = true,
                highlight_global_var_declarations     = true,
                include_at_in_builtins                = true,
                skip_std_references                   = false,
                max_detail_length                     = 4096,
                record_session                        = false,
                builtin_error_message                 = "This is likely a bug in ZLS.",
                dangerous_comptime_experiments_do_not_enable = false,
                zig_exe_path                          = vim.fn.exepath("zig"),
              },
            },
          },
        },
      },
    },
  
    {
      "nvim-lua/plenary.nvim",
      ft = "zig",
  
      keys = {
        { "<leader>zb",  function() run_zig("build") end,               ft = "zig", desc = "⚡ Zig: Build"              },
        { "<leader>zr",  function() run_zig("build run") end,           ft = "zig", desc = "⚡ Zig: Build & Run"        },
        { "<leader>zt",  function() run_zig("build test") end,          ft = "zig", desc = "⚡ Zig: Build test"         },
        { "<leader>ztf", function() run_zig("test " .. vim.api.nvim_buf_get_name(0)) end, ft = "zig", desc = "⚡ Zig: Test file" },
        { "<leader>zc",  function() run_zig("build clean") end,         ft = "zig", desc = "⚡ Zig: Clean"              },
        { "<leader>zf",  function() run_zig("fmt " .. vim.api.nvim_buf_get_name(0)) end, ft = "zig", desc = "⚡ Zig: Format file" },
        { "<leader>zF",  function() run_zig("fmt .") end,               ft = "zig", desc = "⚡ Zig: Format all"         },
        {
          "<leader>zs",
          function()
            local steps = get_build_steps()
            if #steps == 0 then
              vim.notify("⚡ No build.zig found", vim.log.levels.WARN, { title = "Zig" })
              return
            end
            vim.ui.select(steps, { prompt = "⚡ Zig build step: " }, function(step)
              if step then run_zig("build " .. step) end
            end)
          end,
          ft   = "zig",
          desc = "⚡ Zig: Select build step",
        },
        {
          "<leader>zi",
          function()
            local ver = get_zig_version()
            local zls = find_zls()
            vim.notify(
              table.concat({
                "⚡ Zig Environment",
                "──────────────────────────────────",
                string.format("  Zig:  %s", ver),
                string.format("  ZLS:  %s", vim.fn.executable(zls) == 1 and zls or "⭕ not found"),
                string.format("  build.zig: %s", vim.fn.filereadable(vim.fn.getcwd() .. "/build.zig") == 1 and "✅" or "⭕"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "Zig Info" }
            )
          end,
          ft   = "zig",
          desc = "⚡ Zig: Environment info",
        },
      },
  
      config = function()
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshZig", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = "zig",
          callback = function()
            vim.opt_local.expandtab   = true
            vim.opt_local.shiftwidth  = 4
            vim.opt_local.tabstop     = 4
            vim.opt_local.softtabstop = 4
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
            vim.notify("⚡ Zig highlights synced", vim.log.levels.INFO,
              { title = "ASH Zig", timeout = 1200 })
          end,
        })
      end,
    },
  }