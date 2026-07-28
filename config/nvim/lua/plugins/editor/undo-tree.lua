-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🌳 UNDO-TREE — ULTRA HISTORY NAVIGATOR v5.0 OMEGA                        ║
-- ║   Visual undo graph · time-travel · diff preview · persistent undo              ║
-- ║   ASH theme-synced · animated transitions · custom signs · smart layout        ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — ASH palette-aware
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Tree graph ────────────────────────────────────────────────────────────
    hl(0, "UndotreeSavedBig",        { bold = true, fg = "#9ece6a" })
    hl(0, "UndotreeSavedSmall",      { fg = "#9ece6a"              })
    hl(0, "UndotreeNode",            { bold = true, fg = "#7aa2f7" })
    hl(0, "UndotreeNodeCurrent",     {
      bold      = true,
      italic    = true,
      fg        = "#ff9e64",
      bg        = "#2b1d0e",
    })
    hl(0, "UndotreeTimeStamp",       { fg = "#9399b2", italic = true })
    hl(0, "UndotreeFirstNode",       { bold = true, fg = "#bb9af7" })
    hl(0, "UndotreeBranch",          { fg = "#7dcfff"              })
    hl(0, "UndotreeHead",            {
      bold      = true,
      fg        = "#ff9e64",
      underline = true,
    })
  
    -- ── Seq node (sequential undo state) ─────────────────────────────────────
    hl(0, "UndotreeSeq",             { fg = "#e0af68"              })
    hl(0, "UndotreeNext",            { fg = "#9ece6a"              })
    hl(0, "UndotreeCurrent",         { bold = true, fg = "#ff9e64" })
  
    -- ── Diff window inside undotree ───────────────────────────────────────────
    hl(0, "UndotreeDiffAdd",         { link = "DiffAdd"            })
    hl(0, "UndotreeDiffDelete",      { link = "DiffDelete"         })
    hl(0, "UndotreeDiffText",        { link = "DiffText"           })
    hl(0, "UndotreeDiffChange",      { link = "DiffChange"         })
  
    -- ── Panel chrome ──────────────────────────────────────────────────────────
    hl(0, "UndotreeHelp",            { link = "Comment"            })
    hl(0, "UndotreeHelpKey",         { bold = true, link = "Keyword" })
    hl(0, "UndotreeHelpTitle",       { bold = true, link = "Title"   })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.green  then
        hl(0, "UndotreeSavedBig",   { bold = true, fg = p.green })
        hl(0, "UndotreeSavedSmall", { fg = p.green })
      end
      if p.blue   then hl(0, "UndotreeNode",    { bold = true, fg = p.blue })   end
      if p.orange then
        hl(0, "UndotreeNodeCurrent", { bold = true, italic = true, fg = p.orange })
        hl(0, "UndotreeHead",        { bold = true, underline = true, fg = p.orange })
        hl(0, "UndotreeCurrent",     { bold = true, fg = p.orange })
      end
      if p.mauve  then hl(0, "UndotreeFirstNode", { bold = true, fg = p.mauve }) end
      if p.cyan   then hl(0, "UndotreeBranch",   { fg = p.cyan })               end
      if p.yellow then hl(0, "UndotreeSeq",      { fg = p.yellow })             end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 PERSISTENT UNDO SETUP — cross-session undo history
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function setup_persistent_undo()
    local undo_dir = vim.fn.stdpath("data") .. "/undo"
  
    -- Create undo directory if it doesn't exist
    if vim.fn.isdirectory(undo_dir) == 0 then
      vim.fn.mkdir(undo_dir, "p", 448)
    end
  
    vim.opt.undodir     = undo_dir
    vim.opt.undofile    = true
    vim.opt.undolevels  = 10000
    vim.opt.undoreload  = 10000
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  SMART TOGGLE — open with intelligent sizing
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function smart_toggle()
    local width = vim.o.columns
    -- On narrow terminals use a smaller panel
    if width < 120 then
      vim.g.undotree_SplitWidth = 28
    else
      vim.g.undotree_SplitWidth = 35
    end
    vim.cmd("UndotreeToggle")
  end
  
  -- Focus undotree panel if open, else open it
  local function smart_focus()
    local wins = vim.api.nvim_list_wins()
    for _, win in ipairs(wins) do
      local buf  = vim.api.nvim_win_get_buf(win)
      local name = vim.api.nvim_buf_get_name(buf)
      if name:match("undotree_") then
        vim.api.nvim_set_current_win(win)
        return
      end
    end
    smart_toggle()
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "mbbill/undotree",
      cmd   = { "UndotreeToggle", "UndotreeFocus", "UndotreeShow", "UndotreeHide" },
      event = { "BufReadPre" },
  
      keys = {
        {
          "<leader>zu",
          smart_toggle,
          desc  = "🌳 Toggle Undotree",
          silent = true,
        },
        {
          "<leader>zU",
          smart_focus,
          desc  = "🌳 Focus Undotree",
          silent = true,
        },
        {
          "<leader>zc",
          "<cmd>UndotreeHide<cr>",
          desc  = "🌳 Close Undotree",
          silent = true,
        },
      },
  
      init = function()
        -- ── Global options (must be set before plugin loads) ─────────────────
  
        -- Layout: 1 = left tree, 2 = left tree + diff below,
        --         3 = right tree + diff below, 4 = right tree
        vim.g.undotree_WindowLayout = 2
  
        -- Panel width in columns
        vim.g.undotree_SplitWidth = 35
  
        -- Diff window height in rows (0 = auto)
        vim.g.undotree_DiffpanelHeight = 12
  
        -- Auto-open diff when tree is opened
        vim.g.undotree_DiffAutoOpen = 1
  
        -- Focus undotree panel after toggle
        vim.g.undotree_SetFocusWhenToggle = 1
  
        -- Use short timestamps (relative time strings)
        vim.g.undotree_ShortIndicators = 0
  
        -- Custom relative time display
        vim.g.undotree_RelativeTimestamp = 1
  
        -- Highlight changed text in the buffer when moving in tree
        vim.g.undotree_HighlightChangedText = 1
  
        -- Duration of flash highlight on changed text (ms)
        vim.g.undotree_HighlightChangedWithSign = 1
        vim.g.undotree_HighlightSyntaxAdd       = "UndotreeNode"
        vim.g.undotree_HighlightSyntaxChange    = "UndotreeNodeCurrent"
        vim.g.undotree_HighlightSyntaxDel       = "UndotreeDiffDelete"
  
        -- Show help at top of tree panel
        vim.g.undotree_HelpLine = 1
  
        -- Custom tree node characters (Nerd Font v3)
        vim.g.undotree_TreeNodeShape    = "◉"
        vim.g.undotree_TreeVertShape    = "│"
        vim.g.undotree_TreeSplitShape   = "╠"
        vim.g.undotree_TreeReturnShape  = "╙"
  
        -- Save indicator for undo states that correspond to a :write
        vim.g.undotree_TreeValShape     = "★"
        vim.g.undotree_TreeCurrentShape = "◆"
  
        -- Enable persistent undo storage
        setup_persistent_undo()
  
        -- Apply highlights immediately
        setup_highlights()
      end,
  
      config = function()
        local aug = vim.api.nvim_create_augroup("AshUndotree", { clear = true })
  
        -- Re-apply highlights on colorscheme change
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        -- ASH hot-reload
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify(
              "🌳 Undotree highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH Undotree", timeout = 1200 }
            )
          end,
        })
  
        -- ── Buffer-local config for undotree panels ──────────────────────────
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = "undotree",
          callback = function(ev)
            vim.b[ev.buf].miniindentscope_disable = true
            vim.b[ev.buf].minianimate_disable     = true
            vim.opt_local.number         = false
            vim.opt_local.relativenumber = false
            vim.opt_local.signcolumn     = "no"
            vim.opt_local.cursorline     = true
            vim.opt_local.wrap           = false
  
            -- Help popup
            vim.keymap.set("n", "?", function()
              vim.notify(
                table.concat({
                  "🌳 Undotree Navigation",
                  "──────────────────────────────",
                  "j / k       Navigate up/down",
                  "J / K       Jump to save state",
                  "p           Preview diff",
                  "P           Focus diff window",
                  "u / <C-R>   Undo / Redo",
                  "q           Close",
                  "?           This help",
                }, "\n"),
                vim.log.levels.INFO,
                { title = "Undotree Help" }
              )
            end, { buffer = ev.buf, desc = "🌳 Undotree help", silent = true })
  
            -- Quick close
            vim.keymap.set("n", "q", "<cmd>UndotreeHide<cr>",
              { buffer = ev.buf, desc = "🌳 Close Undotree", silent = true })
          end,
        })
  
        -- ── Diff window settings ─────────────────────────────────────────────
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = "diff",
          callback = function(ev)
            -- Only for undotree diff windows
            local name = vim.api.nvim_buf_get_name(ev.buf)
            if name:match("undotree") then
              vim.opt_local.number         = false
              vim.opt_local.relativenumber = false
              vim.opt_local.signcolumn     = "no"
              vim.opt_local.wrap           = false
            end
          end,
        })
  
        if vim.g.ash_debug then
          local undo_dir = vim.fn.stdpath("data") .. "/undo"
          local count    = #vim.fn.glob(undo_dir .. "/*", false, true)
          vim.notify(
            string.format("🌳 Undotree loaded — %d undo files in store", count),
            vim.log.levels.DEBUG,
            { title = "ASH Undotree" }
          )
        end
      end,
    },
  }