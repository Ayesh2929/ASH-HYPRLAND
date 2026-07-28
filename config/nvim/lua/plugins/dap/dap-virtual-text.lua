-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║     👁️  DAP-VIRTUAL-TEXT — ULTRA INLINE DEBUG VALUES v5.0 OMEGA                ║
-- ║   Inline variable values during debugging · changed highlighting                ║
-- ║   treesitter-aware · per-type colouring · ASH theme-synced                     ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — virtual text value colours
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Standard inline value ─────────────────────────────────────────────────
    hl(0, "NvimDapVirtualText",         {
      italic    = true,
      fg        = "#9399b2",
    })
  
    -- ── Changed value (different from previous step) ──────────────────────────
    hl(0, "NvimDapVirtualTextChanged",  {
      bold      = true,
      italic    = true,
      fg        = "#f9e2af",
      bg        = "#2d2a1e",
    })
  
    -- ── Error retrieving value ─────────────────────────────────────────────────
    hl(0, "NvimDapVirtualTextError",    {
      italic    = true,
      fg        = "#f38ba8",
    })
  
    -- ── Info / special values ─────────────────────────────────────────────────
    hl(0, "NvimDapVirtualTextInfo",     {
      italic    = true,
      fg        = "#89b4fa",
    })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p   = ash.palette
      local dim = p.overlay0 or p.subtext0 or "#9399b2"
      hl(0, "NvimDapVirtualText", { italic = true, fg = dim })
      if p.yellow then
        hl(0, "NvimDapVirtualTextChanged", {
          bold   = true,
          italic = true,
          fg     = p.yellow,
          bg     = p.surface0 or "#2d2a1e",
        })
      end
      if p.red  then hl(0, "NvimDapVirtualTextError", { italic = true, fg = p.red  }) end
      if p.blue then hl(0, "NvimDapVirtualTextInfo",  { italic = true, fg = p.blue }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 VALUE FORMATTERS — per-type display formatting
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Format displayed variable value
  local function format_value(value, variable)
    if not value then return "" end
  
    -- Truncate long strings
    local max_len = 60
    if #value > max_len then
      value = value:sub(1, max_len - 1) .. "…"
    end
  
    -- Add type hint for common types
    local type_name = variable and variable.type
    if type_name then
      -- Remove module prefix (e.g. "std::string::String" → "String")
      local short_type = type_name:match("[^:]+$") or type_name
      if #short_type <= 20 then
        return string.format("(%s) %s", short_type, value)
      end
    end
  
    return value
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "theHamsta/nvim-dap-virtual-text",
      dependencies = {
        "mfussenegger/nvim-dap",
        "nvim-treesitter/nvim-treesitter",
      },
      event = "VeryLazy",
  
      keys = {
        {
          "<leader>dv",
          function()
            local ok, vt = pcall(require, "nvim-dap-virtual-text")
            if ok then
              vt.toggle()
              vim.notify(
                "👁️  DAP virtual text toggled",
                vim.log.levels.INFO,
                { title = "DAP", timeout = 1000 }
              )
            end
          end,
          desc   = "👁️  DAP: Toggle Virtual Text",
          silent = true,
        },
      },
  
      opts = {
        -- ── Enable ───────────────────────────────────────────────────────────
        enabled                   = true,
        enabled_commands          = true,
  
        -- ── Treesitter integration ────────────────────────────────────────────
        -- Show text for each variable assignment node
        highlight_changed_variables = true,
        highlight_new_as_changed    = false,
        show_stop_reason            = true,
  
        -- ── Display mode ─────────────────────────────────────────────────────
        -- "single" | "multiple" (show multiple values per variable)
        commented                   = false,
  
        -- ── Evaluation options ────────────────────────────────────────────────
        -- Only evaluate variables that are in scope
        only_first_definition       = false,
        all_references              = false,
        all_frames                  = false,
        filter_references_pattern   = "<module",
  
        -- ── Formatting ───────────────────────────────────────────────────────
        -- Separator between variable name and value
        display_callback = function(variable, _buf, _stackframe, _node, options)
          -- options.commented determines placement
          local value = format_value(variable.value, variable)
  
          -- Add indicator for complex/structured values
          if variable.value and (
            variable.value:sub(1, 1) == "{"
            or variable.value:sub(1, 1) == "["
            or variable.value:sub(1, 1) == "("
          ) then
            return string.format("  = %s", value)
          end
  
          return string.format("  %s", value)
        end,
  
        -- ── Highlight groups ──────────────────────────────────────────────────
        virt_text_pos            = "eol",         -- "eol" | "inline" | "right_align"
        virt_text_win_col        = nil,
        virt_lines               = false,
        virt_lines_above         = false,
        virt_text_hide           = false,
  
        -- ── Priority ────────────────────────────────────────────────────────
        priority                 = 2000,
  
        -- ── Delay (ms) before showing values ─────────────────────────────────
        delay                    = 0,
  
        -- ── Clear on run ─────────────────────────────────────────────────────
        clear_on_continue        = false,
      },
  
      config = function(_, opts)
        require("nvim-dap-virtual-text").setup(opts)
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshDapVirtualText", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify(
              "👁️  DAP virtual text highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH DAP", timeout = 1200 }
            )
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            "👁️  DAP virtual text loaded",
            vim.log.levels.DEBUG,
            { title = "ASH DAP" }
          )
        end
      end,
    },
  }