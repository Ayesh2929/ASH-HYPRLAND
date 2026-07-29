-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📄 JSON — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                              ║
-- ║   jsonls · schemastore · jsonc · json5 · sort keys · format · ASH theme       ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "@lsp.type.property.json",     { fg = "#89b4fa"                })
    hl(0, "@lsp.type.string.json",       { fg = "#a6e3a1"                })
    hl(0, "@lsp.type.number.json",       { fg = "#fab387"                })
    hl(0, "@lsp.type.boolean.json",      { bold = true, fg = "#fab387"   })
    hl(0, "@lsp.type.null.json",         { fg = "#9399b2"                })
    hl(0, "@lsp.type.keyword.json",      { fg = "#f38ba8"                })
  
    hl(0, "@property.json",              { fg = "#89b4fa"                })
    hl(0, "@string.json",                { fg = "#a6e3a1"                })
    hl(0, "@number.json",                { fg = "#fab387"                })
    hl(0, "@boolean.json",               { bold = true, fg = "#fab387"   })
    hl(0, "@constant.builtin.json",      { fg = "#9399b2"                })
    hl(0, "@punctuation.bracket.json",   { fg = "#cdd6f4"                })
    hl(0, "@punctuation.delimiter.json", { fg = "#9399b2"                })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then hl(0, "@property.json",  { fg = p.blue   }) end
      if p.green  then hl(0, "@string.json",    { fg = p.green  }) end
      if p.peach  then hl(0, "@number.json",    { fg = p.peach  }) end
      local dim = p.overlay0 or "#9399b2"
      hl(0, "@constant.builtin.json",  { fg = dim })
      hl(0, "@punctuation.delimiter.json", { fg = dim })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 JSON UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Pretty-print / minify toggle
  local function toggle_json_format()
    local bufnr  = vim.api.nvim_get_current_buf()
    local lines  = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local content= table.concat(lines, "\n")
  
    local is_minified = #lines <= 3
  
    if is_minified then
      -- Expand: run jq
      local result = vim.fn.system("echo " .. vim.fn.shellescape(content) .. " | jq '.'")
      if vim.v.shell_error == 0 then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(result, "\n"))
        vim.notify("📄 JSON expanded", vim.log.levels.INFO, { title = "JSON", timeout = 1000 })
      end
    else
      -- Minify
      local result = vim.fn.system("echo " .. vim.fn.shellescape(content) .. " | jq -c '.'")
      if vim.v.shell_error == 0 then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { vim.fn.trim(result) })
        vim.notify("📄 JSON minified", vim.log.levels.INFO, { title = "JSON", timeout = 1000 })
      end
    end
  end
  
  -- Sort JSON keys
  local function sort_json_keys()
    if vim.fn.executable("jq") ~= 1 then
      vim.notify("📄 jq not found", vim.log.levels.WARN, { title = "JSON" })
      return
    end
    local bufnr  = vim.api.nvim_get_current_buf()
    local lines  = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local content= table.concat(lines, "\n")
    local result = vim.fn.system("echo " .. vim.fn.shellescape(content) .. " | jq '. | walk(if type == \"object\" then to_entries | sort_by(.key) | from_entries else . end)'")
    if vim.v.shell_error == 0 then
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(vim.fn.trim(result), "\n"))
      vim.notify("📄 JSON keys sorted", vim.log.levels.INFO, { title = "JSON", timeout = 1200 })
    end
  end
  
  -- Validate JSON
  local function validate_json()
    local bufnr  = vim.api.nvim_get_current_buf()
    local lines  = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local content= table.concat(lines, "\n")
    local result = vim.fn.system("echo " .. vim.fn.shellescape(content) .. " | jq '.' 2>&1")
    if vim.v.shell_error == 0 then
      vim.notify("📄 ✅ Valid JSON", vim.log.levels.INFO, { title = "JSON", timeout = 1500 })
    else
      vim.notify("📄 ❌ Invalid JSON:\n" .. result, vim.log.levels.ERROR, { title = "JSON" })
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
        vim.list_extend(opts.ensure_installed, { "json", "json5", "jsonc" })
      end,
    },
  
    {
      "b0o/schemastore.nvim",
      lazy = true,
    },
  
    {
      "neovim/nvim-lspconfig",
      ft   = { "json", "jsonc", "json5" },
      opts = {
        servers = {
          jsonls = {
            on_attach = function(client, bufnr)
              local global = _G.AshLspOnAttach
              if global then global(client, bufnr) end
            end,
            settings = {
              json = {
                validate  = { enable = true },
                format    = { enable = true },
                schemas   = function()
                  local ok, ss = pcall(require, "schemastore")
                  if ok then
                    return ss.json.schemas({
                      extra = {
                        {
                          description = "ASH Dotfiles Config",
                          fileMatch   = { "ash.conf", "ash.json" },
                          name        = "ASH Dotfiles",
                          url         = "",
                        },
                      },
                    })
                  end
                  return {}
                end,
              },
            },
            setup = {
              commands = {
                Format = {
                  function()
                    vim.lsp.buf.range_formatting({}, { 0, 0 }, { vim.fn.line("$"), 0 })
                  end,
                },
              },
            },
          },
        },
      },
    },
  
    {
      "nvim-lua/plenary.nvim",
      ft = { "json", "jsonc", "json5" },
  
      keys = {
        { "<leader>jf",  toggle_json_format, ft = { "json", "jsonc" }, desc = "📄 JSON: Format / Minify toggle" },
        { "<leader>js",  sort_json_keys,     ft = { "json", "jsonc" }, desc = "📄 JSON: Sort keys"              },
        { "<leader>jv",  validate_json,      ft = { "json", "jsonc" }, desc = "📄 JSON: Validate"               },
        {
          "<leader>jq",
          function()
            vim.ui.input({ prompt = "📄 jq query: " }, function(query)
              if not query or query == "" then return end
              local bufnr  = vim.api.nvim_get_current_buf()
              local lines  = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
              local content= table.concat(lines, "\n")
              local result = vim.fn.system(
                "echo " .. vim.fn.shellescape(content) .. " | jq " .. vim.fn.shellescape(query)
              )
              if vim.v.shell_error == 0 then
                vim.notify("📄 Query result:\n" .. vim.fn.trim(result), vim.log.levels.INFO,
                  { title = "jq" })
              else
                vim.notify("📄 jq error:\n" .. result, vim.log.levels.ERROR, { title = "jq" })
              end
            end)
          end,
          ft   = { "json", "jsonc" },
          desc = "📄 JSON: Run jq query",
        },
      },
  
      config = function()
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshJson", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = { "json", "jsonc", "json5" },
          callback = function()
            vim.opt_local.expandtab   = true
            vim.opt_local.shiftwidth  = 2
            vim.opt_local.tabstop     = 2
            vim.opt_local.softtabstop = 2
            vim.opt_local.foldmethod  = "expr"
            vim.opt_local.foldexpr    = "v:lua.vim.treesitter.foldexpr()"
            vim.opt_local.foldlevel   = 99
            vim.opt_local.conceallevel= 0
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("📄 JSON highlights synced", vim.log.levels.INFO,
              { title = "ASH JSON", timeout = 1200 })
          end,
        })
      end,
    },
  }