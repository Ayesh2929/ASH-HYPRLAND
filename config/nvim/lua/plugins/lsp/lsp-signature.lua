-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║     ✍️  LSP-SIGNATURE — ULTRA SIGNATURE HELP ENGINE v5.0 OMEGA                  ║
-- ║   Real-time function signature · parameter highlighting · smart positioning    ║
-- ║   virtual text fallback · floating window · ASH theme-synced · multi-server   ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — signature window colours
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Signature floating window ─────────────────────────────────────────────
    hl(0, "LspSignatureActiveParameter", {
      bold      = true,
      underline = true,
      sp        = "#7aa2f7",
      fg        = "#c0caf5",
      bg        = "#1e2030",
    })
  
    -- ── Label / hint text ─────────────────────────────────────────────────────
    hl(0, "LspSignatureHintLabel", {
      italic    = true,
      fg        = "#9399b2",
    })
  
    -- ── Doc text ──────────────────────────────────────────────────────────────
    hl(0, "LspSignatureDoc", {
      fg        = "#cdd6f4",
    })
  
    -- ── Selected overload ─────────────────────────────────────────────────────
    hl(0, "LspSignatureSelected", {
      bold      = true,
      fg        = "#9ece6a",
    })
  
    -- ── Floating window chrome ────────────────────────────────────────────────
    hl(0, "LspSignatureNormal", { link = "NormalFloat"  })
    hl(0, "LspSignatureBorder", { link = "FloatBorder"  })
  
    -- ── Trigger character highlight ────────────────────────────────────────────
    hl(0, "LspSignatureTrigger", {
      bold      = true,
      fg        = "#ff9e64",
    })
  
    -- ── Return type annotation ────────────────────────────────────────────────
    hl(0, "LspSignatureReturn", {
      italic    = true,
      fg        = "#94e2d5",
    })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then
        hl(0, "LspSignatureActiveParameter", {
          bold      = true,
          underline = true,
          sp        = p.blue,
          fg        = p.text or "#c0caf5",
          bg        = p.surface1 or "#1e2030",
        })
      end
      if p.teal   then hl(0, "LspSignatureReturn",  { italic = true, fg = p.teal  }) end
      if p.green  then hl(0, "LspSignatureSelected",{ bold = true,   fg = p.green }) end
      if p.orange then hl(0, "LspSignatureTrigger", { bold = true,   fg = p.orange}) end
      local dim = p.overlay1 or p.subtext0 or "#9399b2"
      hl(0, "LspSignatureHintLabel", { italic = true, fg = dim })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 STATE MANAGEMENT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local _sig_enabled = true
  
  local function toggle_signature()
    local ok, sig = pcall(require, "lsp_signature")
    if not ok then return end
  
    if _sig_enabled then
      sig.toggle_float_win()
      _sig_enabled = false
      vim.notify(
        "✍️  Signature help  disabled",
        vim.log.levels.INFO,
        { title = "lsp-signature", timeout = 1200 }
      )
    else
      sig.toggle_float_win()
      _sig_enabled = true
      vim.notify(
        "✍️  Signature help  enabled",
        vim.log.levels.INFO,
        { title = "lsp-signature", timeout = 1200 }
      )
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "ray-x/lsp_signature.nvim",
      event        = "LspAttach",
      dependencies = { "neovim/nvim-lspconfig" },
  
      keys = {
        {
          "<C-k>",
          function()
            require("lsp_signature").toggle_float_win()
          end,
          mode   = { "n", "i" },
          desc   = "✍️  Toggle signature help",
          silent = true,
        },
        {
          "<leader>us",
          toggle_signature,
          desc   = "✍️  Toggle signature help",
          silent = true,
        },
        {
          "<M-n>",
          function()
            local ok, sig = pcall(require, "lsp_signature")
            if ok then sig.signature() end
          end,
          mode   = "i",
          desc   = "✍️  Show signature",
          silent = true,
        },
        -- Cycle through overloads
        {
          "<M-j>",
          function()
            local ok, sig = pcall(require, "lsp_signature")
            if ok and sig.on_InsertModeLeave then
              vim.cmd("normal! j")
            end
          end,
          mode   = "i",
          desc   = "✍️  Next signature overload",
          silent = true,
        },
        {
          "<M-k>",
          function()
            local ok, sig = pcall(require, "lsp_signature")
            if ok and sig.on_InsertModeLeave then
              vim.cmd("normal! k")
            end
          end,
          mode   = "i",
          desc   = "✍️  Prev signature overload",
          silent = true,
        },
      },
  
      opts = {
        -- ── Display mode ──────────────────────────────────────────────────────
        -- "virtual_text" | "floating" | "none"
        mode             = "floating",
  
        -- ── Floating window ────────────────────────────────────────────────────
        floating_window   = true,
        floating_window_above_cur_line = true,
        floating_window_off_x = 1,
        floating_window_off_y = function()
          local pumheight  = vim.o.pumheight
          local winline    = vim.fn.winline()
          local winheight  = vim.fn.winheight(0)
          if winline - 1 < pumheight then
            return pumheight
          elseif winheight - winline < pumheight then
            return -pumheight
          end
          return 0
        end,
  
        -- ── Auto trigger ──────────────────────────────────────────────────────
        -- When to trigger: automatically on trigger chars
        auto_close_after  = nil,
        close_timeout     = 4000,
        always_trigger    = false,
        check_completion_visible = true,
        select_signature_key     = "<M-n>",
        move_cursor_key          = nil,
  
        -- ── Active parameter styling ───────────────────────────────────────────
        hi_parameter      = "LspSignatureActiveParameter",
        max_height        = 12,
        max_width         = 80,
  
        -- ── Behaviour ─────────────────────────────────────────────────────────
        hint_enable       = true,
        hint_prefix       = {
          above            = "↙ ",   -- hint for parameter above current line
          current          = "← ",   -- hint for current parameter
          below            = "↖ ",   -- hint for next parameter
        },
        hint_scheme       = "LspSignatureHintLabel",
        hint_inline       = function() return false end,
  
        -- ── Cursorhold delay ──────────────────────────────────────────────────
        cursorhold_update = true,
  
        -- ── Window style ──────────────────────────────────────────────────────
        handler_opts      = {
          border           = "rounded",
        },
        border            = "rounded",
        shadow_blend      = 36,
        shadow_guibg      = "Black",
        padding           = " ",
  
        -- ── Transparency ──────────────────────────────────────────────────────
        transparency      = 10,
        shadow            = false,
  
        -- ── Timer ─────────────────────────────────────────────────────────────
        timer_interval    = 200,
  
        -- ── Toggle keys ───────────────────────────────────────────────────────
        toggle_key        = nil,        -- managed via our own keymaps
        toggle_key_flip_floatwin_setting = false,
  
        -- ── Debug ─────────────────────────────────────────────────────────────
        debug             = vim.g.ash_debug or false,
        log_path          = vim.fn.stdpath("data") .. "/lsp_signature.log",
        verbose           = false,
  
        -- ── Wrap ─────────────────────────────────────────────────────────────
        wrap              = true,
        wrap_at           = 80,
  
        -- ── Fix pos ──────────────────────────────────────────────────────────
        fix_pos           = false,
  
        -- ── zindex ───────────────────────────────────────────────────────────
        zindex            = 200,
  
        -- ── Trigger on new line ───────────────────────────────────────────────
        trigger_on_newline = false,
  
        -- ── Doc lines ────────────────────────────────────────────────────────
        -- Number of documentation lines to show
        doc_lines         = 10,
  
        -- ── Signature on every character ─────────────────────────────────────
        -- true = always show; false = only on trigger chars
        keymaps           = {},
  
        -- ── Extra trigger chars ───────────────────────────────────────────────
        extra_trigger_chars = {},
  
        -- ── Filter signatures ─────────────────────────────────────────────────
        -- Custom function to filter which signatures to show
        signature_selector = function(err, result, ctx, config)
          -- Return all signatures
          return result
        end,
      },
  
      config = function(_, opts)
        require("lsp_signature").setup(opts)
  
        setup_highlights()
  
        -- ── Hook into LspAttach to configure per-buffer ───────────────────────
        local aug = vim.api.nvim_create_augroup("AshLspSignature", { clear = true })
  
        vim.api.nvim_create_autocmd("LspAttach", {
          group    = aug,
          callback = function(ev)
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if not client then return end
  
            -- Only attach if server supports signature help
            if not client.supports_method("textDocument/signatureHelp") then return end
  
            -- Per-buffer signature setup with server-specific tweaks
            local buf_opts = vim.tbl_deep_extend("force", opts, {})
  
            -- Server-specific overrides
            if client.name == "lua_ls" then
              buf_opts.max_height = 4  -- lua_ls signatures can be verbose
            elseif client.name == "rust_analyzer" then
              buf_opts.doc_lines = 5   -- rust docs are detailed
            elseif client.name == "pyright" then
              buf_opts.hint_enable = true
            elseif client.name == "clangd" then
              buf_opts.max_width  = 100  -- C++ templates can be wide
            elseif client.name == "ts_ls" then
              buf_opts.doc_lines  = 8
            end
  
            require("lsp_signature").on_attach(buf_opts, ev.buf)
          end,
        })
  
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
              "✍️  lsp-signature highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH lsp-signature", timeout = 1200 }
            )
          end,
        })
  
        -- ── Enhanced insert-mode trigger ──────────────────────────────────────
        -- Show signature when typing trigger chars
        vim.api.nvim_create_autocmd("InsertCharPre", {
          group    = aug,
          callback = function()
            local char = vim.v.char
            local triggers = { "(", ",", " " }
            if vim.tbl_contains(triggers, char) then
              -- Defer to let the char be inserted first
              vim.defer_fn(function()
                local ok, sig = pcall(require, "lsp_signature")
                if ok and _sig_enabled then
                  pcall(sig.signature)
                end
              end, 50)
            end
          end,
        })
  
        -- ── Virtual text fallback for terminals without float support ──────────
        -- Expose a statusline-friendly signature hint
        _G.AshSignatureHint = function()
          local ok, sig = pcall(require, "lsp_signature")
          if not ok or not _sig_enabled then return "" end
          local cur_sig = sig.status_line(40)
          if cur_sig and cur_sig.hint and cur_sig.hint ~= "" then
            return " ✍️  " .. cur_sig.hint
          end
          return ""
        end
  
        if vim.g.ash_debug then
          vim.notify(
            "✍️  lsp-signature loaded — floating: true, hint: true",
            vim.log.levels.DEBUG,
            { title = "ASH lsp-signature" }
          )
        end
      end,
    },
  }