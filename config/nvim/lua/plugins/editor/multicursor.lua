-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║     🖱️  MULTICURSOR — ULTRA MULTI-CURSOR ENGINE v5.0 OMEGA                     ║
-- ║   VS Code-style multi-cursors · visual selection · pattern matching             ║
-- ║   word-under-cursor · regex · line anchors · ASH theme-synced cursors          ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📖 OPERATION REFERENCE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
--  <C-n>          Add cursor at word under cursor / next match (normal)
--  <C-n>          Add cursor at visual selection (visual)
--  <C-p>          Remove last cursor / skip to prev
--  <C-x>          Skip current match, go to next
--  <M-n>          Select all matches of word under cursor
--  <M-N>          Select all matches in buffer (regex input)
--  <leader>mca    Select all occurrences (visual selection)
--  <leader>mcl    Add cursor to each line in selection
--  <leader>mcc    Add cursor at column position for each line
--  <leader>mcm    Match & add cursors by regex
--  <leader>mcs    Start multicursor in find mode
--  <Esc>          Quit multicursor mode → back to normal

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — premium cursor styling
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Main cursor (primary edit point) ────────────────────────────────────
    hl(0, "MultiCursor",           {
      bold      = true,
      bg        = "#7aa2f7",
      fg        = "#1a1b26",
    })
  
    -- ── Additional cursors (secondary edit points) ──────────────────────────
    hl(0, "MultiCursorCursor",     {
      bold      = true,
      reverse   = true,
    })
  
    -- ── Visual selection under multi-cursor ─────────────────────────────────
    hl(0, "MultiCursorVisual",     {
      bg        = "#2d4a7a",
      fg        = "NONE",
    })
  
    -- ── Sign column indicators ───────────────────────────────────────────────
    hl(0, "MultiCursorSign",       {
      bold      = true,
      fg        = "#7aa2f7",
    })
  
    -- ── Match highlight (non-active matches) ─────────────────────────────────
    hl(0, "MultiCursorMatch",      {
      bg        = "#1e2d45",
      fg        = "NONE",
      underline = true,
      sp        = "#7aa2f7",
    })
  
    -- ── Disabled/skipped match ───────────────────────────────────────────────
    hl(0, "MultiCursorDisabled",   {
      fg        = "#545c7e",
      strikethrough = false,
    })
  
    -- ── Flash indicator when adding cursor ─────────────────────────────────
    hl(0, "MultiCursorFlash",      {
      bold      = true,
      bg        = "#ff9e64",
      fg        = "#1a1b26",
    })
  
    -- ── ASH palette sync ────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue then
        hl(0, "MultiCursor", {
          bold = true,
          bg   = p.blue,
          fg   = p.base or "#1a1b26",
        })
        hl(0, "MultiCursorSign",  { bold = true, fg = p.blue })
        hl(0, "MultiCursorMatch", {
          underline = true,
          sp        = p.blue,
          bg        = (p.surface1 or "#1e2d45"),
        })
      end
      if p.orange then
        hl(0, "MultiCursorFlash", {
          bold = true,
          bg   = p.orange,
          fg   = p.base or "#1a1b26",
        })
      end
      if p.overlay0 then
        hl(0, "MultiCursorDisabled", { fg = p.overlay0 })
      end
      if p.surface1 then
        hl(0, "MultiCursorVisual", { bg = p.surface1 })
      end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 SMART ACTION HELPERS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Add cursor at each line in a visual range
  local function add_cursors_to_lines()
    return function()
      local mc = require("multicursor-nvim")
      -- Get visual range
      local s = vim.fn.line("'<")
      local e = vim.fn.line("'>")
      if s == e then
        vim.notify(
          "🖱️  Select multiple lines first",
          vim.log.levels.WARN,
          { title = "Multicursor" }
        )
        return
      end
      mc.lineAddCursors()
    end
  end
  
  -- Add cursors matching a regex pattern (prompted)
  local function add_cursors_by_pattern()
    return function()
      vim.ui.input(
        { prompt = "🖱️  Pattern to match: " },
        function(pattern)
          if not pattern or pattern == "" then return end
          local mc = require("multicursor-nvim")
          mc.matchAddCursors(1, pattern)
          vim.notify(
            string.format("🖱️  Adding cursors for pattern: %s", pattern),
            vim.log.levels.INFO,
            { title = "Multicursor", timeout = 1500 }
          )
        end
      )
    end
  end
  
  -- Show cursor count status
  local function show_cursor_status()
    local ok, mc = pcall(require, "multicursor-nvim")
    if not ok then return end
    local count = mc.numCursors and mc.numCursors() or 0
    if count <= 1 then
      vim.notify(
        "🖱️  No multi-cursors active",
        vim.log.levels.INFO,
        { title = "Multicursor", timeout = 1200 }
      )
    else
      vim.notify(
        string.format("🖱️  %d cursors active", count),
        vim.log.levels.INFO,
        { title = "Multicursor", timeout = 1200 }
      )
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "jake-stewart/multicursor.nvim",
      branch = "1.0",
      event  = { "BufReadPre", "BufNewFile" },
  
      keys = {
        -- ── Word-under-cursor: add next / prev ────────────────────────────────
        {
          "<C-n>",
          function() require("multicursor-nvim").addCursor("*") end,
          mode  = { "n", "v" },
          desc  = "🖱️  MC: Add cursor (next match)",
          silent = true,
        },
        {
          "<C-p>",
          function() require("multicursor-nvim").addCursor("#") end,
          mode  = { "n", "v" },
          desc  = "🖱️  MC: Add cursor (prev match)",
          silent = true,
        },
        {
          "<C-x>",
          function() require("multicursor-nvim").skipCursor("*") end,
          mode  = { "n", "v" },
          desc  = "🖱️  MC: Skip + next match",
          silent = true,
        },
  
        -- ── Select all matches ────────────────────────────────────────────────
        {
          "<M-n>",
          function() require("multicursor-nvim").matchAllAddCursors() end,
          mode  = { "n", "v" },
          desc  = "🖱️  MC: Select ALL matches",
          silent = true,
        },
  
        -- ── Up / down line cursors ────────────────────────────────────────────
        {
          "<up>",
          function() require("multicursor-nvim").lineAddCursor(-1) end,
          mode  = { "n", "v" },
          desc  = "🖱️  MC: Add cursor above",
          silent = true,
        },
        {
          "<down>",
          function() require("multicursor-nvim").lineAddCursor(1) end,
          mode  = { "n", "v" },
          desc  = "🖱️  MC: Add cursor below",
          silent = true,
        },
        {
          "<leader>mcj",
          function() require("multicursor-nvim").lineAddCursor(1) end,
          mode  = { "n", "v" },
          desc  = "🖱️  MC: Add cursor below (leader)",
          silent = true,
        },
        {
          "<leader>mck",
          function() require("multicursor-nvim").lineAddCursor(-1) end,
          mode  = { "n", "v" },
          desc  = "🖱️  MC: Add cursor above (leader)",
          silent = true,
        },
  
        -- ── Skip up / down ────────────────────────────────────────────────────
        {
          "<leader>mcJ",
          function() require("multicursor-nvim").lineSkipCursor(1) end,
          mode  = { "n", "v" },
          desc  = "🖱️  MC: Skip cursor down",
          silent = true,
        },
        {
          "<leader>mcK",
          function() require("multicursor-nvim").lineSkipCursor(-1) end,
          mode  = { "n", "v" },
          desc  = "🖱️  MC: Skip cursor up",
          silent = true,
        },
  
        -- ── Visual: add cursor per line ───────────────────────────────────────
        {
          "<leader>mcl",
          add_cursors_to_lines(),
          mode  = "v",
          desc  = "🖱️  MC: Cursor per line",
          silent = true,
        },
  
        -- ── Pattern matching ─────────────────────────────────────────────────
        {
          "<leader>mcm",
          add_cursors_by_pattern(),
          mode  = { "n", "v" },
          desc  = "🖱️  MC: Add cursors by pattern",
          silent = true,
        },
  
        -- ── Column cursors ────────────────────────────────────────────────────
        {
          "<leader>mcc",
          function()
            local mc = require("multicursor-nvim")
            mc.matchAddCursors(1, [[\%]] .. vim.fn.virtcol(".") .. [[v]])
          end,
          mode  = "n",
          desc  = "🖱️  MC: Add cursors at column",
          silent = true,
        },
  
        -- ── Select visual & rotate ────────────────────────────────────────────
        {
          "<leader>mct",
          function() require("multicursor-nvim").transposeCursors(1) end,
          mode  = "v",
          desc  = "🖱️  MC: Transpose cursors →",
          silent = true,
        },
        {
          "<leader>mcT",
          function() require("multicursor-nvim").transposeCursors(-1) end,
          mode  = "v",
          desc  = "🖱️  MC: Transpose cursors ←",
          silent = true,
        },
  
        -- ── Restore / escape ─────────────────────────────────────────────────
        {
          "<Esc>",
          function()
            local mc = require("multicursor-nvim")
            if not mc.cursorsEnabled() then
              mc.enableCursors()
            elseif mc.hasCursors() then
              mc.clearCursors()
            else
              -- Normal <Esc> behaviour
              vim.cmd("nohlsearch")
            end
          end,
          mode  = "n",
          desc  = "🖱️  MC: Clear / Escape",
          silent = true,
        },
  
        -- ── Toggle cursor enable/disable (freeze secondary cursors) ───────────
        {
          "<leader>mcd",
          function()
            local mc = require("multicursor-nvim")
            if mc.cursorsEnabled() then
              mc.disableCursors()
              vim.notify(
                "🖱️  Secondary cursors  frozen",
                vim.log.levels.INFO,
                { title = "Multicursor", timeout = 1200 }
              )
            else
              mc.enableCursors()
              vim.notify(
                "🖱️  Secondary cursors  active",
                vim.log.levels.INFO,
                { title = "Multicursor", timeout = 1200 }
              )
            end
          end,
          mode  = "n",
          desc  = "🖱️  MC: Toggle cursor activity",
          silent = true,
        },
  
        -- ── Status info ───────────────────────────────────────────────────────
        {
          "<leader>mci",
          show_cursor_status,
          mode  = "n",
          desc  = "🖱️  MC: Cursor info",
          silent = true,
        },
  
        -- ── Align cursors (insert spaces to align at cursor column) ───────────
        {
          "<leader>mca",
          function()
            local mc = require("multicursor-nvim")
            mc.alignCursors()
          end,
          mode  = "n",
          desc  = "🖱️  MC: Align cursors",
          silent = true,
        },
  
        -- ── First / last cursor ───────────────────────────────────────────────
        {
          "<leader>mc<",
          function() require("multicursor-nvim").firstCursor() end,
          mode  = { "n", "v" },
          desc  = "🖱️  MC: Go to first cursor",
          silent = true,
        },
        {
          "<leader>mc>",
          function() require("multicursor-nvim").lastCursor() end,
          mode  = { "n", "v" },
          desc  = "🖱️  MC: Go to last cursor",
          silent = true,
        },
  
        -- ── Insert / append at all cursors ────────────────────────────────────
        {
          "<leader>mci",
          function() require("multicursor-nvim").insertVisual() end,
          mode  = "v",
          desc  = "🖱️  MC: Insert before selection",
          silent = true,
        },
        {
          "<leader>mcA",
          function() require("multicursor-nvim").appendVisual() end,
          mode  = "v",
          desc  = "🖱️  MC: Append after selection",
          silent = true,
        },
      },
  
      config = function()
        local mc = require("multicursor-nvim")
        mc.setup()
  
        setup_highlights()
  
        -- ── Cursor mode visual indicator in statusline ──────────────────────
        -- Expose for lualine / statusline integration
        _G.AshMulticursorStatus = function()
          if not package.loaded["multicursor-nvim"] then return "" end
          local ok2, mc2 = pcall(require, "multicursor-nvim")
          if not ok2 then return "" end
          local count = mc2.numCursors and mc2.numCursors() or 0
          if count > 1 then
            return string.format(" 🖱️  ×%d ", count)
          end
          return ""
        end
  
        local aug = vim.api.nvim_create_augroup("AshMulticursor", { clear = true })
  
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
              "🖱️  Multicursor highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH Multicursor", timeout = 1200 }
            )
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            "🖱️  Multicursor.nvim loaded",
            vim.log.levels.DEBUG,
            { title = "ASH Multicursor" }
          )
        end
      end,
    },
  }