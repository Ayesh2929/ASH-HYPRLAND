-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🤝 CODECOMPANION — ULTRA AI CODING ASSISTANT v5.0 OMEGA                  ║
-- ║   Inline AI · chat · actions · slash commands · tools · agents                ║
-- ║   multi-provider · streaming · ASH theme-synced glass UI                      ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — glassmorphism AI interface
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
  local hl = vim.api.nvim_set_hl

  -- ── Chat interface ────────────────────────────────────────────────────────
  hl(0, "CodeCompanionChat",           { link = "NormalFloat"   })
  hl(0, "CodeCompanionChatHeader",     { bold = true,   fg = "#89b4fa" })
  hl(0, "CodeCompanionChatSeparator",  { fg = "#313244"               })
  hl(0, "CodeCompanionChatTokens",     { italic = true, fg = "#9399b2" })
  hl(0, "CodeCompanionChatTool",       { bold = true,   fg = "#fab387" })
  hl(0, "CodeCompanionChatVariable",   { bold = true,   fg = "#cba6f7" })

  -- ── Virtual text ──────────────────────────────────────────────────────────
  hl(0, "CodeCompanionVirtualText",    { italic = true, fg = "#6e738d" })

  -- ── Token counter ─────────────────────────────────────────────────────────
  hl(0, "CodeCompanionTokenCount",     { italic = true, fg = "#9399b2" })
  hl(0, "CodeCompanionTokenHigh",      { bold = true,   fg = "#f38ba8" })
  hl(0, "CodeCompanionTokenMed",       { bold = true,   fg = "#f9e2af" })
  hl(0, "CodeCompanionTokenLow",       { bold = true,   fg = "#9ece6a" })

  -- ── Actions ───────────────────────────────────────────────────────────────
  hl(0, "CodeCompanionActionNormal",   { link = "NormalFloat"   })
  hl(0, "CodeCompanionActionBorder",   { link = "FloatBorder"   })
  hl(0, "CodeCompanionActionTitle",    { bold = true,   fg = "#89b4fa" })
  hl(0, "CodeCompanionActionSelected", { link = "PmenuSel"      })

  -- ── Streaming indicator ────────────────────────────────────────────────────
  hl(0, "CodeCompanionStreaming",      {
    bold      = true,
    italic    = true,
    fg        = "#cba6f7",
  })

  -- ── Roles ─────────────────────────────────────────────────────────────────
  hl(0, "CodeCompanionRoleUser",       { bold = true,   fg = "#7aa2f7" })
  hl(0, "CodeCompanionRoleAssistant",  { bold = true,   fg = "#cba6f7" })
  hl(0, "CodeCompanionRoleSystem",     { bold = true,   fg = "#f9e2af" })
  hl(0, "CodeCompanionRoleTool",       { bold = true,   fg = "#fab387" })

  -- ── ASH palette sync ──────────────────────────────────────────────────────
  local ok, ash = pcall(require, "ash.theme")
  if ok and ash.palette then
    local p = ash.palette
    if p.blue   then
      hl(0, "CodeCompanionChatHeader",    { bold = true, fg = p.blue })
      hl(0, "CodeCompanionActionTitle",   { bold = true, fg = p.blue })
      hl(0, "CodeCompanionRoleUser",      { bold = true, fg = p.blue })
    end
    if p.mauve  then
      hl(0, "CodeCompanionStreaming",     { bold = true, italic = true, fg = p.mauve })
      hl(0, "CodeCompanionRoleAssistant", { bold = true, fg = p.mauve })
      hl(0, "CodeCompanionChatVariable",  { bold = true, fg = p.mauve })
    end
    if p.peach  then
      hl(0, "CodeCompanionChatTool",      { bold = true, fg = p.peach })
      hl(0, "CodeCompanionRoleTool",      { bold = true, fg = p.peach })
    end
    if p.yellow then hl(0, "CodeCompanionRoleSystem",  { bold = true, fg = p.yellow }) end
    if p.green  then hl(0, "CodeCompanionTokenLow",    { bold = true, fg = p.green  }) end
    if p.yellow then hl(0, "CodeCompanionTokenMed",    { bold = true, fg = p.yellow }) end
    if p.red    then hl(0, "CodeCompanionTokenHigh",   { bold = true, fg = p.red    }) end
    local dim = p.overlay0 or "#6e738d"
    hl(0, "CodeCompanionVirtualText",    { italic = true, fg = dim })
    hl(0, "CodeCompanionTokenCount",     { italic = true, fg = dim })
    hl(0, "CodeCompanionChatSeparator",  { fg = p.surface2 or "#313244" })
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📦 PLUGIN SPEC
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {
  {
    "olimorris/codecompanion.nvim",
    version      = false,
    event        = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      { "hrsh7th/nvim-cmp",               optional = true },
      { "nvim-telescope/telescope.nvim",   optional = true },
      { "stevearc/dressing.nvim",          optional = true },
      { "MeanderingProgrammer/render-markdown.nvim", optional = true },
    },

    keys = {
      -- ── Chat ─────────────────────────────────────────────────────────────
      { "<leader>ac",  "<cmd>CodeCompanionChat Toggle<cr>",       mode = { "n", "v" }, desc = "🤝 AI: Chat toggle"           },
      { "<leader>acn", "<cmd>CodeCompanionChat<cr>",              mode = { "n", "v" }, desc = "🤝 AI: New chat"              },
      { "<leader>aca", "<cmd>CodeCompanionActions<cr>",           mode = { "n", "v" }, desc = "🤝 AI: Actions"               },
      { "<leader>acc", "<cmd>CodeCompanionChat Add<cr>",          mode = "v",          desc = "🤝 AI: Add selection to chat"  },

      -- ── Inline ───────────────────────────────────────────────────────────
      {
        "<leader>aci",
        function()
          vim.ui.input({ prompt = "🤝 Inline prompt: " }, function(input)
            if input and input ~= "" then
              require("codecompanion").inline({ prompt = input })
            end
          end)
        end,
        mode   = { "n", "v" },
        desc   = "🤝 AI: Inline",
        silent = true,
      },

      -- ── Quick actions ─────────────────────────────────────────────────────
      {
        "<leader>ace",
        function()
          require("codecompanion").prompt("explain", {})
        end,
        mode   = { "n", "v" },
        desc   = "🤝 AI: Explain",
        silent = true,
      },
      {
        "<leader>acf",
        function()
          require("codecompanion").prompt("fix", {})
        end,
        mode   = { "n", "v" },
        desc   = "🤝 AI: Fix",
        silent = true,
      },
      {
        "<leader>act",
        function()
          require("codecompanion").prompt("tests", {})
        end,
        mode   = { "n", "v" },
        desc   = "🤝 AI: Tests",
        silent = true,
      },
      {
        "<leader>acd",
        function()
          require("codecompanion").prompt("docstring", {})
        end,
        mode   = { "n", "v" },
        desc   = "🤝 AI: Docstring",
        silent = true,
      },

      -- ── History ───────────────────────────────────────────────────────────
      { "<leader>ach", "<cmd>CodeCompanionHistory<cr>", desc = "🤝 AI: Chat history" },

      -- ── Provider ──────────────────────────────────────────────────────────
      {
        "<leader>acp",
        function()
          local ok, cc = pcall(require, "codecompanion")
          if not ok then return end
          vim.notify("🤝 Current adapter: " .. tostring(cc.current_adapter()),
            vim.log.levels.INFO, { title = "CodeCompanion" })
        end,
        desc = "🤝 AI: Show provider",
      },
    },

    opts = {
      -- ── Adapters ─────────────────────────────────────────────────────────
      adapters = {
        -- Anthropic Claude
        anthropic = function()
          return require("codecompanion.adapters").extend("anthropic", {
            env = { api_key = "ANTHROPIC_API_KEY" },
            schema = {
              model = {
                default = "claude-3-5-sonnet-20241022",
              },
              max_tokens = { default = 8096 },
            },
          })
        end,

        -- OpenAI GPT-4
        openai = function()
          return require("codecompanion.adapters").extend("openai", {
            env = { api_key = "OPENAI_API_KEY" },
            schema = {
              model = {
                default = "gpt-4o",
              },
              max_tokens = { default = 8096 },
            },
          })
        end,

        -- Google Gemini
        gemini = function()
          return require("codecompanion.adapters").extend("gemini", {
            env = { api_key = "GEMINI_API_KEY" },
            schema = {
              model = {
                default = "gemini-2.0-flash-exp",
              },
            },
          })
        end,

        -- GitHub Copilot
        copilot = function()
          return require("codecompanion.adapters").extend("copilot", {
            schema = {
              model = {
                default = "gpt-4o-2024-08-06",
              },
              max_tokens = { default = 8096 },
            },
          })
        end,

        -- Local Ollama
        ollama = function()
          return require("codecompanion.adapters").extend("ollama", {
            name    = "ollama",
            schema  = {
              model = {
                default = "codestral:latest",
              },
              num_ctx = { default = 32768 },
              num_batch = { default = 512 },
            },
            url     = os.getenv("OLLAMA_HOST") or "http://localhost:11434",
          })
        end,
      },

      -- ── Strategy ─────────────────────────────────────────────────────────
      strategies = {
        -- Default chat adapter
        chat = {
          adapter = (function()
            local key_map = {
              ANTHROPIC_API_KEY = "anthropic",
              OPENAI_API_KEY    = "openai",
              GEMINI_API_KEY    = "gemini",
              GITHUB_TOKEN      = "copilot",
            }
            for env, adapter in pairs(key_map) do
              if os.getenv(env) and os.getenv(env) ~= "" then
                return adapter
              end
            end
            return "ollama"
          end)(),
          slash_commands = {
            ["buffer"]  = { opts = { provider = "telescope" } },
            ["file"]    = { opts = { provider = "telescope" } },
            ["help"]    = { opts = { provider = "telescope" } },
            ["symbols"] = { opts = { provider = "telescope" } },
          },
          roles = {
            llm  = "  CodeCompanion",
            user = "  You",
          },
          keymaps = {
            send               = { modes = { n = "<CR>", i = "<C-s>" } },
            regenerate         = { modes = { n = "gr" } },
            close              = { modes = { n = "q", i = "<C-c>" } },
            stop               = { modes = { n = "<C-c>" } },
            clear              = { modes = { n = "gc" } },
            codeblock          = { modes = { n = "gc" } },
            yank_code          = { modes = { n = "gy" } },
            next_chat          = { modes = { n = "}" } },
            previous_chat      = { modes = { n = "{" } },
            next_header        = { modes = { n = "]]" } },
            previous_header    = { modes = { n = "[[" } },
            change_adapter     = { modes = { n = "ga" } },
            fold_code          = { modes = { n = "gf" } },
            debug              = { modes = { n = "gd" } },
            system_prompt      = { modes = { n = "gs" } },
            pin                = { modes = { n = "gp" } },
            watch              = { modes = { n = "gw" } },
          },
        },

        inline = {
          adapter = "copilot",
          keymaps = {
            accept_change = { modes = { n = "ga" }, description = "Accept change" },
            reject_change = { modes = { n = "gr" }, description = "Reject change" },
          },
        },

        agent  = { adapter = "anthropic" },
      },

      -- ── Default prompts ───────────────────────────────────────────────────
      prompt_library = {
        ["ASH Config"] = {
          strategy  = "chat",
          description = "Help with ASH dotfiles configuration",
          opts = {
            index    = 11,
            is_default = true,
            user_prompt= false,
          },
          prompts  = {
            { role = "system", content = [[You are an ASH OMEGA v5.0 dotfiles expert.
You help configure and optimise Neovim, Hyprland, and related tools.
Always provide working Lua/Bash/Nix code with clear explanations.]] },
            { role = "user", content = "How can I help with your ASH config?" },
          },
        },

        ["Explain Code"] = {
          strategy = "chat",
          description = "Explain how code works",
          opts = {
            index    = 5,
            is_default = true,
            modes    = { "v" },
          },
          prompts = {
            {
              role    = "system",
              content = "You are an expert programmer. Explain code clearly and concisely.",
            },
            {
              role    = "user",
              content = function(ctx)
                local code = require("codecompanion.helpers.actions").get_code(
                  ctx.start_line, ctx.end_line
                )
                return "Explain this " .. ctx.filetype .. " code:\n\n```" .. ctx.filetype .. "\n" .. code .. "\n```"
              end,
            },
          },
        },

        ["Fix Bugs"] = {
          strategy  = "chat",
          description = "Fix bugs in selected code",
          opts = {
            index    = 6,
            is_default = true,
            modes    = { "v" },
          },
          prompts = {
            {
              role    = "system",
              content = "You are an expert debugger. Find and fix all bugs. Return only corrected code.",
            },
            {
              role    = "user",
              content = function(ctx)
                local code = require("codecompanion.helpers.actions").get_code(
                  ctx.start_line, ctx.end_line
                )
                return "Fix all bugs in this " .. ctx.filetype .. " code:\n\n```" .. ctx.filetype .. "\n" .. code .. "\n```"
              end,
            },
          },
        },

        ["Write Tests"] = {
          strategy  = "chat",
          description = "Write unit tests for code",
          opts = {
            index    = 7,
            is_default = true,
            modes    = { "v" },
          },
          prompts = {
            {
              role    = "system",
              content = "You are a testing expert. Write comprehensive tests covering edge cases and error handling.",
            },
            {
              role    = "user",
              content = function(ctx)
                local code = require("codecompanion.helpers.actions").get_code(
                  ctx.start_line, ctx.end_line
                )
                return "Write tests for this " .. ctx.filetype .. " code:\n\n```" .. ctx.filetype .. "\n" .. code .. "\n```"
              end,
            },
          },
        },
      },

      -- ── Display ────────────────────────────────────────────────────────────
      display = {
        action_palette = {
          width    = 95,
          height   = 10,
          provider = "telescope",
          opts     = {
            show_default_actions = true,
            show_default_prompt_library = true,
          },
        },
        chat  = {
          window  = {
            layout   = "vertical",
            border   = "rounded",
            height   = 0.8,
            width    = 0.45,
            relative = "editor",
          },
          render_headers        = true,
          show_settings         = true,
          show_token_count      = true,
          show_references       = true,
          start_in_insert_mode  = false,
          buf_options           = { buflisted = false, bufhidden = "wipe" },
        },
        diff  = {
          enabled    = true,
          close_chat_at = 240,
          layout     = "vertical",
          opts       = { "internal", "filler", "closeoff", "algorithm:patience", "followwrap", "linematch:120" },
        },
        inline= {
          layout = "vertical",
        },
      },

      -- ── Log ────────────────────────────────────────────────────────────────
      log_level = "ERROR",
    },

    config = function(_, opts)
      require("codecompanion").setup(opts)

      setup_highlights()

      -- ── Expand 'cc' shortcut in cmdline ───────────────────────────────────
      vim.cmd([[cab cc CodeCompanion]])
      vim.cmd([[cab ccc CodeCompanionChat]])
      vim.cmd([[cab cca CodeCompanionActions]])

      local aug = vim.api.nvim_create_augroup("AshCodeCompanion", { clear = true })

      vim.api.nvim_create_autocmd("FileType", {
        group   = aug,
        pattern = "codecompanion",
        callback = function(ev)
          vim.b[ev.buf].miniindentscope_disable = true
          vim.b[ev.buf].minianimate_disable     = true
          vim.opt_local.spell        = true
          vim.opt_local.wrap         = true
          vim.opt_local.linebreak    = true
          vim.opt_local.conceallevel = 2
        end,
      })

      vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
      vim.api.nvim_create_autocmd("User", {
        group   = aug,
        pattern = "AshThemeChanged",
        callback = function()
          setup_highlights()
          vim.notify("🤝 CodeCompanion highlights synced", vim.log.levels.INFO,
            { title = "ASH CodeCompanion", timeout = 1200 })
        end,
      })

      -- ── Streaming indicator in statusline ─────────────────────────────────
      local _is_streaming = false
      local _stream_frames = { "⠋", "⠙", "⠹", "⠸", "⼼", "⠴", "⠦", "⠧", "⠇", "⠏" }
      local _frame_idx     = 1

      vim.api.nvim_create_autocmd("User", {
        group   = aug,
        pattern = { "CodeCompanionRequestStarted", "CodeCompanionRequestFinished" },
        callback = function(ev)
          _is_streaming = ev.match == "CodeCompanionRequestStarted"
        end,
      })

      _G.AshCodeCompanionStatus = function()
        if _is_streaming then
          _frame_idx = (_frame_idx % #_stream_frames) + 1
          return " 🤝 " .. _stream_frames[_frame_idx] .. " "
        end
        return ""
      end
    end,
  },
}
