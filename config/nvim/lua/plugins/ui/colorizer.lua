-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/ui/colorizer.lua — Inline Colour Highlighting                  ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: NvChad/nvim-colorizer.lua  (maintained fork)                       ║
-- ║                                                                              ║
-- ║  Features:                                                                   ║
-- ║    • Inline swatches for #RRGGBB, #RGB, rgb(), hsl(), oklch()               ║
-- ║    • Tailwind CSS class colour preview                                       ║
-- ║    • CSS named colour support                                                ║
-- ║    • ANSI colour code highlighting in terminals / log files                 ║
-- ║    • Virtual-text mode (icon swatch) + background mode                     ║
-- ║    • Per-filetype overrides                                                  ║
-- ║    • Toggle keymap with status notification                                 ║
-- ║    • Auto-enable on colour-heavy filetypes                                  ║
-- ║    • :ColorizerAttachToBuffer / :ColorizerDetachFromBuffer                  ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPost", "BufNewFile" },
    cmd   = {
      "ColorizerAttachToBuffer",
      "ColorizerDetachFromBuffer",
      "ColorizerReloadAllBuffers",
      "ColorizerToggle",
    },
    keys = {
      {
        "<leader>uC",
        function()
          local ok, col = pcall(require, "colorizer")
          if not ok then return end
          col.toggle()
          local state = col.is_buffer_attached(0)
          vim.notify(
            (state and "󰏘 " or "󰏘 ") .. "Colorizer " .. (state and "enabled" or "disabled"),
            vim.log.levels.INFO,
            { title = "ASH NeoVim" }
          )
        end,
        desc = "󰏘  Toggle colorizer",
      },
      {
        "<leader>uCr",
        "<Cmd>ColorizerReloadAllBuffers<CR>",
        desc = "󰑓  Reload colorizer",
      },
    },
  
    opts = function()
      local icons = Ash.icons
  
      -- ── Shared colour options ─────────────────────────────────────────────
      ---@class ColorizerOpts
      local base_opts = {
        RGB      = true,        -- #RGB hex
        RRGGBB   = true,        -- #RRGGBB hex
        RRGGBBAA = true,        -- #RRGGBBAA hex with alpha
        AARRGGBB = false,       -- 0xAARRGGBB (Android / Java style)
        rgb_fn   = true,        -- rgb() and rgba()
        hsl_fn   = true,        -- hsl() and hsla()
        css      = true,        -- enable all CSS colour features
        css_fn   = true,        -- css colour functions
        -- Display mode
        mode     = "background", -- "background" | "foreground" | "virtualtext"
        -- Virtual-text swatch icon (used when mode = "virtualtext")
        virtualtext      = "■",
        virtualtext_inline = false,
        always_update    = false,
      }
  
      -- ── Tailwind-specific opts ────────────────────────────────────────────
      local tailwind_opts = vim.tbl_extend("force", base_opts, {
        tailwind = true,         -- enable Tailwind CSS class colours
        mode     = "background",
      })
  
      -- ── Virtual-text mode (for log files, terminals) ──────────────────────
      local vt_opts = vim.tbl_extend("force", base_opts, {
        mode             = "virtualtext",
        virtualtext      = icons.ui.Circle,
        virtualtext_inline = true,
        always_update    = true,
        RRGGBBAA         = true,
      })
  
      -- ── Foreground mode (for dark backgrounds) ────────────────────────────
      local fg_opts = vim.tbl_extend("force", base_opts, {
        mode = "foreground",
      })
  
      -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      -- Per-filetype configuration
      -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
      ---@type table<string, table>
      local filetypes = {
        -- ── Web (full CSS + Tailwind) ────────────────────────────────────
        css             = tailwind_opts,
        scss            = tailwind_opts,
        less            = tailwind_opts,
        html            = tailwind_opts,
        javascript      = tailwind_opts,
        javascriptreact = tailwind_opts,
        typescript      = tailwind_opts,
        typescriptreact = tailwind_opts,
        svelte          = tailwind_opts,
        vue             = tailwind_opts,
        astro           = tailwind_opts,
        templ           = tailwind_opts,
        -- ── Config / data ────────────────────────────────────────────────
        json            = base_opts,
        jsonc           = base_opts,
        yaml            = base_opts,
        toml            = base_opts,
        -- ── Lua / Vim (theme files) ──────────────────────────────────────
        lua             = vim.tbl_extend("force", base_opts, {
          mode = "background",
          -- Extra: match 0xRRGGBB Lua hex literals
          custom_matchers = {
            function(line)
              local results = {}
              for start, r, g, b in line:gmatch("0x(%x%x)(%x%x)(%x%x)()") do
                results[#results + 1] = {
                  start   = start,
                  color   = string.format("#%s%s%s", r, g, b),
                }
              end
              return results
            end,
          },
        }),
        vim             = base_opts,
        -- ── Shell / logs (virtual-text swatch, non-intrusive) ─────────────
        sh              = vt_opts,
        bash            = vt_opts,
        fish            = vt_opts,
        zsh             = vt_opts,
        log             = vt_opts,
        -- ── Kitty / Hyprland configs ─────────────────────────────────────
        kitty           = base_opts,
        hyprlang        = base_opts,
        -- ── Markdown (inline colour preview) ─────────────────────────────
        markdown        = vim.tbl_extend("force", base_opts, {
          mode = "foreground",
        }),
        -- ── Nix ──────────────────────────────────────────────────────────
        nix             = base_opts,
        -- ── Rust / Go / Python (hex literals) ───────────────────────────
        rust            = vt_opts,
        go              = vt_opts,
        python          = vt_opts,
        -- ── Telescope / notify buffers (auto) ────────────────────────────
        TelescopeResults = vt_opts,
      }
  
      -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      -- Excluded filetypes
      -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
      local exclude_ft = {
        "alpha", "dashboard", "neo-tree",
        "lazy", "mason", "lspinfo",
        "checkhealth", "help", "man",
        "aerial", "Trouble",
        "toggleterm",
      }
  
      return {
        -- Apply to all filetypes listed above
        filetypes      = filetypes,
        -- User-commands enabled
        user_commands  = true,
        -- Default opts for any filetype NOT in the table
        default_options = base_opts,
      }
    end,
  
    config = function(_, opts)
      local colorizer = require("colorizer")
      colorizer.setup(opts)
  
      -- ── Auto-attach to colour-heavy filetypes ─────────────────────────────
      -- Already handled by `filetypes` table; but we re-attach after
      -- LSP attaches (e.g. Tailwind LSP triggers re-render)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client and client.name == "tailwindcss" then
            -- Tailwind LSP active → re-attach colorizer with tailwind mode
            pcall(colorizer.attach_to_buffer, ev.buf, {
              tailwind = true,
              mode     = "background",
              css      = true,
              css_fn   = true,
            })
          end
        end,
      })
  
      -- ── Detach from excluded filetypes ────────────────────────────────────
      local exclude_ft = {
        "alpha", "dashboard", "neo-tree",
        "lazy", "mason", "lspinfo",
        "checkhealth", "help", "man",
        "aerial", "Trouble", "toggleterm",
      }
  
      vim.api.nvim_create_autocmd("FileType", {
        pattern  = exclude_ft,
        callback = function(ev)
          pcall(colorizer.detach_from_buffer, ev.buf)
        end,
      })
  
      -- ── Detach from large files ───────────────────────────────────────────
      vim.api.nvim_create_autocmd("BufReadPre", {
        callback = function(ev)
          local stat = vim.uv.fs_stat(ev.match)
          if stat and stat.size > Ash.perf.bigfile_size then
            pcall(colorizer.detach_from_buffer, ev.buf)
          end
        end,
      })
  
      -- ── Re-attach after colorscheme change ───────────────────────────────
      -- Colour swatches need to be redrawn when the theme changes
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          -- Reload attached buffers
          pcall(colorizer.reload_all_buffers)
        end,
      })
  
      -- ── User command: show active colorizer state ─────────────────────────
      vim.api.nvim_create_user_command("ColorizerStatus", function()
        local attached = colorizer.is_buffer_attached(0)
        local ft       = vim.bo.filetype
        vim.notify(
          string.format(
            "󰏘 Colorizer — filetype: %s  attached: %s",
            ft,
            attached and "✅ yes" or "❌ no"
          ),
          vim.log.levels.INFO,
          { title = "ASH NeoVim" }
        )
      end, { desc = "Show colorizer status for current buffer" })
  
      -- ── User command: pick colour under cursor ────────────────────────────
      -- Leverages snacks or hyprpicker if available
      vim.api.nvim_create_user_command("ColorizerPick", function()
        if vim.fn.executable("hyprpicker") == 1 then
          vim.fn.jobstart({ "hyprpicker", "--autocopy" }, {
            on_exit = function(_, code)
              if code == 0 then
                local colour = vim.fn.getreg("+"):gsub("%s+", "")
                if colour ~= "" then
                  vim.notify(
                    "󰏘 Colour picked: " .. colour,
                    vim.log.levels.INFO,
                    { title = "ASH Colour Picker" }
                  )
                end
              end
            end,
          })
        else
          vim.notify(
            "hyprpicker not found — install it for screen colour picking",
            vim.log.levels.WARN,
            { title = "ASH Colour Picker" }
          )
        end
      end, { desc = "Pick colour with hyprpicker (Wayland)" })
    end,
  }