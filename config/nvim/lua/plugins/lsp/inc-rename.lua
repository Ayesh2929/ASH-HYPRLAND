-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       ✏️  INC-RENAME — ULTRA INCREMENTAL RENAME v5.0 OMEGA                      ║
-- ║   Live preview of renames as you type · all references highlighted             ║
-- ║   cmdline UX · noice integration · undo-safe · ASH theme-synced               ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — live rename preview colours
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Rename reference highlights (all occurrences) ─────────────────────────
    hl(0, "IncRenamePreviewReference",  {
      bold      = false,
      underline = true,
      sp        = "#7aa2f7",
      bg        = "#1e2d4a",
    })
  
    -- ── Active rename input highlight (the word being renamed) ────────────────
    hl(0, "IncRenameCurrentWord",       {
      bold      = true,
      underline = true,
      sp        = "#ff9e64",
      bg        = "#2b1d0e",
      fg        = "#ff9e64",
    })
  
    -- ── Renamed text (preview of new name) ────────────────────────────────────
    hl(0, "IncRenameNewWord",           {
      bold      = true,
      fg        = "#9ece6a",
      bg        = "#1a2b1a",
    })
  
    -- ── Command line prompt styling ───────────────────────────────────────────
    hl(0, "IncRenamePrompt",            {
      bold      = true,
      fg        = "#7aa2f7",
    })
  
    -- ── Error state (invalid name) ────────────────────────────────────────────
    hl(0, "IncRenameError",             {
      bold      = true,
      fg        = "#f38ba8",
      bg        = "#2d1b1e",
    })
  
    -- ── Counter badge (N references) ─────────────────────────────────────────
    hl(0, "IncRenameCount",             {
      bold      = true,
      fg        = "#7dcfff",
    })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then
        hl(0, "IncRenamePreviewReference", {
          underline = true,
          sp        = p.blue,
          bg        = p.surface1 or "#1e2d4a",
        })
        hl(0, "IncRenamePrompt", { bold = true, fg = p.blue })
        hl(0, "IncRenameCount",  { bold = true, fg = p.blue })
      end
      if p.orange then
        hl(0, "IncRenameCurrentWord", {
          bold      = true,
          underline = true,
          sp        = p.orange,
          fg        = p.orange,
          bg        = p.surface0 or "#2b1d0e",
        })
      end
      if p.green then
        hl(0, "IncRenameNewWord", {
          bold = true,
          fg   = p.green,
          bg   = p.surface0 or "#1a2b1a",
        })
      end
      if p.red then
        hl(0, "IncRenameError", {
          bold = true,
          fg   = p.red,
          bg   = p.surface0 or "#2d1b1e",
        })
      end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 SMART RENAME TRIGGER — with noice & feedback
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Build the rename command string (pre-fills current word)
  local function rename_cmd()
    -- Get word under cursor
    local cword = vim.fn.expand("<cword>")
  
    -- Check if any LSP client supports rename
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    local has_rename_support = vim.iter(clients):any(function(c)
      return c.server_capabilities.renameProvider ~= nil
    end)
  
    if not has_rename_support then
      vim.notify(
        "✏️  No LSP server supports rename in this buffer",
        vim.log.levels.WARN,
        { title = "inc-rename" }
      )
      return
    end
  
    -- Check for noice integration
    local ok_noice, noice = pcall(require, "noice")
    if ok_noice then
      -- noice will render the cmdline with inc-rename UI
      return ":" .. "IncRename " .. cword
    end
  
    -- Standard: open cmdline pre-filled
    return ":" .. "IncRename " .. cword
  end
  
  -- Full rename with confirmation summary
  local function do_rename()
    local cword = vim.fn.expand("<cword>")
  
    -- Show pre-rename notification
    vim.notify(
      string.format("✏️  Renaming: '%s'  →  ?", cword),
      vim.log.levels.INFO,
      { title = "inc-rename", timeout = 800 }
    )
  
    -- Feed the :IncRename command into cmdline
    local cmd = "IncRename " .. cword
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes(":" .. cmd, true, false, true),
      "n",
      false
    )
  end
  
  -- Rename via input prompt (alternative UX for terminals without cmdline support)
  local function do_rename_input()
    local cword = vim.fn.expand("<cword>")
    vim.ui.input(
      {
        prompt  = string.format("✏️  Rename '%s' → ", cword),
        default = cword,
      },
      function(new_name)
        if not new_name or new_name == "" or new_name == cword then
          vim.notify(
            "✏️  Rename cancelled",
            vim.log.levels.INFO,
            { title = "inc-rename", timeout = 800 }
          )
          return
        end
  
        -- Apply via LSP
        local params = vim.lsp.util.make_position_params()
        params.newName = new_name
        vim.lsp.buf_request(
          0,
          "textDocument/rename",
          params,
          function(err, result)
            if err then
              vim.notify(
                "✏️  Rename failed: " .. err.message,
                vim.log.levels.ERROR,
                { title = "inc-rename" }
              )
              return
            end
            if result then
              vim.lsp.util.apply_workspace_edit(result, "utf-8")
              -- Count changed files
              local changed = result.changes or result.documentChanges or {}
              local count   = vim.tbl_count(changed)
              vim.notify(
                string.format(
                  "✏️  Renamed '%s' → '%s' in %d file(s)",
                  cword, new_name, count
                ),
                vim.log.levels.INFO,
                { title = "Rename Complete" }
              )
            end
          end
        )
      end
    )
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "smjonas/inc-rename.nvim",
      event        = { "LspAttach" },
      dependencies = { "neovim/nvim-lspconfig" },
      cmd          = "IncRename",
  
      keys = {
        -- ── Primary rename: incremental cmdline ──────────────────────────────
        {
          "<leader>rn",
          function()
            -- Check for noice integration
            local ok_noice = pcall(require, "noice")
            if ok_noice then
              return ":IncRename " .. vim.fn.expand("<cword>")
            end
            do_rename()
          end,
          expr   = true,           -- expr = true allows returning a keystring
          mode   = "n",
          desc   = "✏️  Rename (incremental)",
          silent = true,
        },
  
        -- ── Alternative: input dialog rename ─────────────────────────────────
        {
          "<leader>rN",
          do_rename_input,
          mode   = "n",
          desc   = "✏️  Rename (input dialog)",
          silent = true,
        },
  
        -- ── Direct command (no pre-fill) ──────────────────────────────────────
        {
          "<leader>R",
          ":IncRename ",
          mode   = "n",
          desc   = "✏️  Rename (manual)",
          silent = false,    -- show cmdline
        },
      },
  
      opts = {
        -- ── Cmdline prefix ────────────────────────────────────────────────────
        -- The text shown in the command line before the new name
        cmd_name         = "IncRename",
  
        -- ── Highlight group for preview ───────────────────────────────────────
        hl_group         = "IncRenamePreviewReference",
  
        -- ── Multi-file support ────────────────────────────────────────────────
        -- If true, show file counts and names during rename
        multibuf_auto_save = false,   -- false = require explicit save
  
        -- ── Pre-fill current word in cmdline ─────────────────────────────────
        input_buffer_type  = nil,
  
        -- ── Post-rename notification ──────────────────────────────────────────
        -- Hook fires after a successful rename
        post_hook          = function(result)
          if not result then return end
  
          local changed   = result.changes or result.documentChanges or {}
          local file_count = vim.tbl_count(changed)
          local ref_count  = 0
  
          for _, edits in pairs(changed) do
            if type(edits) == "table" then
              ref_count = ref_count + #edits
            end
          end
  
          vim.notify(
            string.format(
              "✏️  Renamed %d reference(s) across %d file(s)",
              ref_count, file_count
            ),
            vim.log.levels.INFO,
            { title = "Rename Complete ✅", timeout = 3000 }
          )
        end,
  
        -- ── Save on rename ────────────────────────────────────────────────────
        -- Automatically save modified buffers after rename
        save_in_cmdline_win = true,
  
        -- ── Keymap to accept during preview ──────────────────────────────────
        keys               = {
          quit             = "<Esc>",
          accept           = "<CR>",
        },
      },
  
      config = function(_, opts)
        require("inc_rename").setup(opts)
  
        setup_highlights()
  
        -- ── noice.nvim integration: render inc-rename via noice cmdline ────────
        local ok_noice, noice = pcall(require, "noice")
        if ok_noice then
          -- Register inc-rename as a noice cmdline route
          pcall(function()
            noice.setup_command_extras({
              inc_rename = {
                input  = { icon = "✏️ ", icon_hl = "IncRenamePrompt", relative = "cursor" },
              },
            })
          end)
        end
  
        local aug = vim.api.nvim_create_augroup("AshIncRename", { clear = true })
  
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
              "✏️  inc-rename highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH inc-rename", timeout = 1200 }
            )
          end,
        })
  
        -- ── Show reference count before renaming ──────────────────────────────
        vim.api.nvim_create_autocmd("CmdlineChanged", {
          group    = aug,
          pattern  = "*",
          callback = function()
            -- Check if we're in an IncRename command
            local line = vim.fn.getcmdline()
            if not line:match("^IncRename%s") then return end
  
            -- Update the statusline component with live rename state
            _G.AshIncRenameActive = true
          end,
        })
  
        vim.api.nvim_create_autocmd("CmdlineLeave", {
          group    = aug,
          pattern  = "*",
          callback = function()
            _G.AshIncRenameActive = false
          end,
        })
  
        -- ── Statusline / winbar component ─────────────────────────────────────
        _G.AshRenameStatus = function()
          if _G.AshIncRenameActive then
            return " ✏️  Renaming… "
          end
          return ""
        end
  
        if vim.g.ash_debug then
          vim.notify(
            "✏️  inc-rename loaded — <leader>rn to rename",
            vim.log.levels.DEBUG,
            { title = "ASH inc-rename" }
          )
        end
      end,
    },
  }