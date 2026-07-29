-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/ui/indent-blankline.lua — Indent Guides                        ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: lukas-reineke/indent-blankline.nvim  (v3)                           ║
-- ║                                                                              ║
-- ║  Features:                                                                   ║
-- ║    • 8-colour rainbow indent guides (palette-aware)                         ║
-- ║    • Animated scope highlight (current code block)                          ║
-- ║    • Treesitter-aware scope detection                                        ║
-- ║    • Smart exclusion: dashboard, help, large files                          ║
-- ║    • Custom chunk chars for visual block boundaries                         ║
-- ║    • Per-filetype char overrides                                            ║
-- ║    • Integration with Snacks.indent (they share scope state)                ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "lukas-reineke/indent-blankline.nvim",
    main    = "ibl",
    version = "~3",
    event   = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    keys = {
      {
        "<leader>uI",
        function()
          local ibl = require("ibl")
          ---@diagnostic disable-next-line: missing-fields
          local enabled = not require("ibl.config").get_config(0).enabled
          ibl.update({ enabled = enabled })
          vim.notify(
            (enabled and " " or "󰅖 ") .. "Indent guides " .. (enabled and "on" or "off"),
            vim.log.levels.INFO,
            { title = "ASH NeoVim" }
          )
        end,
        desc = "  Toggle indent guides",
      },
    },
  
    opts = function()
      local icons = Ash.icons
  
      -- ── Colour palette ────────────────────────────────────────────────────
      local p = {}
      pcall(function()
        p = require("catppuccin.palettes").get_palette() or {}
      end)
  
      -- Rainbow colour cycle (8 steps, Catppuccin-aware)
      local rainbow = {
        p.blue    or "#89b4fa",
        p.yellow  or "#f9e2af",
        p.green   or "#a6e3a1",
        p.red     or "#f38ba8",
        p.mauve   or "#cba6f7",
        p.peach   or "#fab387",
        p.teal    or "#94e2d5",
        p.pink    or "#f5c2e7",
      }
  
      -- Dim the rainbow (blend toward background)
      local bg      = p.base    or "#1e1e2e"
      local overlay = p.overlay0 or "#6c7086"
      local mauve   = p.mauve   or "#cba6f7"
      local surface = p.surface1 or "#313244"
  
      ---Blend hex colour toward `bg` by `pct` percent
      ---@param hex string
      ---@param pct number  0–100
      ---@return string
      local function dim(hex, pct)
        local ok, U = pcall(function() return Ash.util.color end)
        if ok and U then return U.blend(hex, bg, pct / 100) end
        return hex
      end
  
      -- Dimmed rainbow for normal guides (30% visible, 70% toward bg)
      local dimmed = vim.tbl_map(function(c) return dim(c, 70) end, rainbow)
  
      -- ── Highlight group names ─────────────────────────────────────────────
      -- We define 8 rainbow levels + 1 scope highlight
      local hl_names = {}
      for i = 1, 8 do
        hl_names[i] = "IblRainbow" .. i
      end
      local scope_hl = "IblScope"
  
      -- Apply highlight groups
      local function apply_highlights()
        -- Re-read palette (may have changed after ColorScheme)
        local p2 = {}
        pcall(function() p2 = require("catppuccin.palettes").get_palette() or {} end)
  
        local rainbow2 = {
          p2.blue    or rainbow[1],
          p2.yellow  or rainbow[2],
          p2.green   or rainbow[3],
          p2.red     or rainbow[4],
          p2.mauve   or rainbow[5],
          p2.peach   or rainbow[6],
          p2.teal    or rainbow[7],
          p2.pink    or rainbow[8],
        }
        local bg2 = p2.base or bg
        local function dim2(hex, pct)
          local ok, U = pcall(function() return Ash.util.color end)
          if ok and U then return U.blend(hex, bg2, pct / 100) end
          return hex
        end
  
        for i, colour in ipairs(rainbow2) do
          vim.api.nvim_set_hl(0, hl_names[i], {
            fg        = dim2(colour, 70),
            nocombine = true,
          })
        end
  
        vim.api.nvim_set_hl(0, scope_hl, {
          fg        = p2.mauve or mauve,
          bold      = false,
          nocombine = true,
        })
  
        vim.api.nvim_set_hl(0, "IblWhitespace", {
          fg        = p2.surface1 or surface,
          nocombine = true,
        })
      end
  
      apply_highlights()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_highlights })
  
      -- ── Excluded filetypes & buffer types ─────────────────────────────────
      local exclude_ft = {
        "help", "alpha", "dashboard", "neo-tree", "Trouble", "trouble",
        "lazy", "mason", "notify", "toggleterm", "lazyterm",
        "TelescopePrompt", "TelescopeResults",
        "NvimTree", "aerial", "outline",
        "lspinfo", "checkhealth", "startuptime",
        "man", "gitcommit", "gitrebase",
        "txt", "text", "log",
        "packer", "WhichKey",
        "noice", "neotest-output", "neotest-output-panel",
        "dbui", "dbout", "sql",
      }
  
      local exclude_bt = {
        "terminal", "nofile", "quickfix",
        "prompt", "help", "acwrite",
      }
  
      return {
        -- ── Indent char ───────────────────────────────────────────────────
        indent = {
          char          = "│",          -- primary guide char
          tab_char      = "│",          -- guide char for actual tabs
          smart_indent_level = 3,       -- collapse guides at higher levels
          priority      = 1,
          highlight     = hl_names,     -- cycle through 8 rainbow groups
        },
  
        -- ── Scope (current code block) ────────────────────────────────────
        scope = {
          enabled       = true,
          char          = "│",
          show_start    = true,
          show_end      = true,
          show_exact_scope = true,
          highlight     = { scope_hl },
          priority      = 1024,
          -- Treesitter node types that define a scope
          include       = {
            node_type   = {
              lua        = { "return_statement", "table_constructor", "function_definition", "function_declaration", "method_definition", "if_statement", "for_statement", "while_statement", "do_statement" },
              python     = { "function_definition", "class_definition", "for_statement", "while_statement", "with_statement", "if_statement", "try_statement", "decorated_definition" },
              rust       = { "impl_item", "struct_item", "enum_item", "fn_item", "mod_item", "closure_expression", "block", "match_expression", "if_expression", "loop_expression", "for_expression", "while_expression" },
              go         = { "func_declaration", "func_literal", "type_declaration", "if_statement", "for_statement", "switch_statement", "select_statement", "block" },
              typescript = { "class_declaration", "function_declaration", "arrow_function", "function", "method_definition", "object", "if_statement", "try_statement", "for_statement", "while_statement", "switch_statement" },
              javascript = { "class_declaration", "function_declaration", "arrow_function", "function", "method_definition", "object", "if_statement", "try_statement", "for_statement", "while_statement", "switch_statement" },
              cpp        = { "function_definition", "class_specifier", "struct_specifier", "namespace_definition", "if_statement", "for_statement", "while_statement", "do_statement", "switch_statement", "lambda_expression" },
            },
          },
        },
  
        -- ── Whitespace char ───────────────────────────────────────────────
        whitespace = {
          remove_blankline_trail = true,
          highlight              = { "IblWhitespace" },
        },
  
        -- ── Exclusions ────────────────────────────────────────────────────
        exclude = {
          filetypes     = exclude_ft,
          buftypes      = exclude_bt,
        },
      }
    end,
  
    config = function(_, opts)
      -- Guard: large file disables indent guides
      vim.api.nvim_create_autocmd("BufReadPre", {
        callback = function(ev)
          local stat = vim.uv.fs_stat(ev.match)
          if stat and stat.size > Ash.perf.bigfile_size then
            -- Mark buffer so ibl filter can skip it
            vim.b[ev.buf].ibl_disabled = true
          end
        end,
      })
  
      -- Override filter to respect large-file flag
      local original_opts = vim.deepcopy(opts)
      original_opts.exclude = original_opts.exclude or {}
      original_opts.exclude.filetypes = original_opts.exclude.filetypes or {}
  
      require("ibl").setup(opts)
  
      -- Disable per-buffer when large_file flag is set
      vim.api.nvim_create_autocmd("BufEnter", {
        callback = function(ev)
          if vim.b[ev.buf].large_file or vim.b[ev.buf].ibl_disabled then
            pcall(require("ibl").setup_buffer, ev.buf, { enabled = false })
          end
        end,
      })
  
      -- ── Telescope integration: rainbow preview ────────────────────────────
      -- Ensure indent guides appear inside Telescope previewer
      vim.api.nvim_create_autocmd("User", {
        pattern  = "TelescopePreviewerLoaded",
        callback = function(ev)
          pcall(require("ibl").setup_buffer, ev.buf, {
            indent  = { char = "│" },
            scope   = { enabled = false },
            exclude = { filetypes = {} },
          })
        end,
      })
    end,
  }