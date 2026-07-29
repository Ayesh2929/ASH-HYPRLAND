-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📋 YANKY.NVIM — ULTRA YANK RING v5.0 OMEGA                               ║
-- ║   Persistent yank history · ring cycling · Telescope/FZF picker                ║
-- ║   system clipboard sync · highlight on yank · put operators · SQLite backend    ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — animated yank flash
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Yank flash highlight (shown briefly after y/Y) ───────────────────────
    hl(0, "YankyYanked", {
      bold   = true,
      bg     = "#2d4a1e",
      fg     = "NONE",
    })
  
    -- ── Put flash highlight (shown briefly after p/P) ────────────────────────
    hl(0, "YankyPut", {
      bold   = true,
      bg     = "#1e2d4a",
      fg     = "NONE",
    })
  
    -- ── ASH palette sync ────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.green  then hl(0, "YankyYanked", { bold = true, bg = p.surface1 or "#2d4a1e" }) end
      if p.blue   then hl(0, "YankyPut",    { bold = true, bg = p.surface1 or "#1e2d4a" }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 SMART PICKERS — Telescope & FZF-Lua yank ring browsers
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function pick_yanky()
    -- Try Telescope first, then fzf-lua, then built-in
    local ok_t, tele = pcall(require, "telescope")
    if ok_t and tele.extensions and tele.extensions.yank_history then
      tele.extensions.yank_history.yank_history()
      return
    end
  
    local ok_f, fzf = pcall(require, "fzf-lua")
    if ok_f then
      -- Use fzf-lua with yanky integration if available
      local ok_y, yh = pcall(require, "yanky.utils")
      if ok_y then
        local items = vim.fn.systemlist("true")  -- placeholder
        -- Use built-in picker as fallback
      end
    end
  
    -- Final fallback: use vim.ui.select over yank history
    local ok_y, yanky = pcall(require, "yanky.history")
    if not ok_y then return end
  
    local history = yanky.all()
    if not history or #history == 0 then
      vim.notify("📋 Yank history is empty", vim.log.levels.INFO, { title = "Yanky" })
      return
    end
  
    local items = {}
    for i, entry in ipairs(history) do
      local text = entry.regcontents
      if type(text) == "table" then text = table.concat(text, "\\n") end
      table.insert(items, string.format("[%2d] %s", i, text:sub(1, 80)))
    end
  
    vim.ui.select(items, { prompt = "📋 Yank History" }, function(_, idx)
      if idx then
        require("yanky").put("p", false)
      end
    end)
  end
  
  -- Clear yank history with confirmation
  local function clear_yank_history()
    vim.ui.input(
      { prompt = "📋 Clear yank history? (y/N): " },
      function(input)
        if input and input:lower() == "y" then
          local ok, yanky_hist = pcall(require, "yanky.history")
          if ok then
            yanky_hist.clear()
            vim.notify(
              "📋 Yank history cleared",
              vim.log.levels.INFO,
              { title = "Yanky", timeout = 1500 }
            )
          end
        end
      end
    )
  end
  
  -- Show yank ring stats
  local function show_yanky_stats()
    local ok, hist = pcall(require, "yanky.history")
    if not ok then return end
    local all = hist.all()
    vim.notify(
      string.format("📋 Yank ring: %d / %d entries", #(all or {}), 100),
      vim.log.levels.INFO,
      { title = "Yanky Stats", timeout = 2000 }
    )
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "gbprod/yanky.nvim",
      event        = { "BufReadPre", "BufNewFile" },
      dependencies = {
        { "kkharji/sqlite.lua", enabled = vim.fn.executable("sqlite3") == 1 },
        { "nvim-telescope/telescope.nvim", optional = true },
        { "ibhagwan/fzf-lua",             optional = true },
      },
  
      keys = {
        -- ── Core yank / put ──────────────────────────────────────────────────
        {
          "y",
          "<Plug>(YankyYank)",
          mode  = { "n", "x" },
          desc  = "📋 Yanky: Yank",
        },
        {
          "Y",
          "<Plug>(YankyYank)$",
          mode  = "n",
          desc  = "📋 Yanky: Yank to EOL",
        },
  
        -- ── Put after cursor ──────────────────────────────────────────────────
        {
          "p",
          "<Plug>(YankyPutAfter)",
          mode  = { "n", "x" },
          desc  = "📋 Yanky: Put after",
        },
        {
          "P",
          "<Plug>(YankyPutBefore)",
          mode  = { "n", "x" },
          desc  = "📋 Yanky: Put before",
        },
  
        -- ── Indented put (like ]p / [p) ───────────────────────────────────────
        {
          "gp",
          "<Plug>(YankyGPutAfter)",
          mode  = { "n", "x" },
          desc  = "📋 Yanky: GPut after (cursor after)",
        },
        {
          "gP",
          "<Plug>(YankyGPutBefore)",
          mode  = { "n", "x" },
          desc  = "📋 Yanky: GPut before (cursor after)",
        },
  
        -- ── Ring cycling ──────────────────────────────────────────────────────
        {
          "<M-p>",
          "<Plug>(YankyCycleForward)",
          desc  = "📋 Yanky: Cycle ring forward",
          silent = true,
        },
        {
          "<M-P>",
          "<Plug>(YankyCycleBackward)",
          desc  = "📋 Yanky: Cycle ring backward",
          silent = true,
        },
  
        -- ── Put in line (above / below) ───────────────────────────────────────
        {
          "]p",
          "<Plug>(YankyPutIndentAfterLinewise)",
          desc  = "📋 Yanky: Put below (indented)",
          silent = true,
        },
        {
          "[p",
          "<Plug>(YankyPutIndentBeforeLinewise)",
          desc  = "📋 Yanky: Put above (indented)",
          silent = true,
        },
        {
          "]P",
          "<Plug>(YankyPutAfterLinewise)",
          desc  = "📋 Yanky: Put below (linewise)",
          silent = true,
        },
        {
          "[P",
          "<Plug>(YankyPutBeforeLinewise)",
          desc  = "📋 Yanky: Put above (linewise)",
          silent = true,
        },
  
        -- ── Yank history pickers ──────────────────────────────────────────────
        {
          "<leader>fy",
          function()
            local ok, tele = pcall(require, "telescope")
            if ok and tele.extensions and tele.extensions.yank_history then
              tele.extensions.yank_history.yank_history({
                prompt_title = "📋 Yank History",
              })
            else
              pick_yanky()
            end
          end,
          desc  = "📋 Yanky: History (Telescope)",
          silent = true,
        },
        {
          "<leader>Fy",
          function()
            local ok, fzf = pcall(require, "fzf-lua")
            if ok then
              local ok2, ext = pcall(require, "yanky.integrations.fzf-lua")
              if ok2 then
                ext.yank_history()
                return
              end
            end
            pick_yanky()
          end,
          desc  = "📋 Yanky: History (FZF-Lua)",
          silent = true,
        },
  
        -- ── Management ────────────────────────────────────────────────────────
        {
          "<leader>yc",
          clear_yank_history,
          desc  = "📋 Yanky: Clear history",
          silent = true,
        },
        {
          "<leader>ys",
          show_yanky_stats,
          desc  = "📋 Yanky: Ring stats",
          silent = true,
        },
      },
  
      opts = {
        -- ── Ring ──────────────────────────────────────────────────────────────
        ring = {
          -- Maximum history size
          history_length    = 100,
  
          -- Storage backend: "shada" | "sqlite"
          -- Use SQLite if available for persistence across sessions
          storage           = vim.fn.executable("sqlite3") == 1
                              and "sqlite"
                              or  "shada",
  
          -- SQLite database path
          storage_path      = vim.fn.stdpath("data") .. "/databases/yanky.db",
  
          -- Sync with system clipboard on focus regain
          sync_with_unnamed = true,
  
          -- Cancel if text has not changed (avoids duplicates)
          cancel_event      = "update",
  
          -- Ignore small yanks (single chars)
          ignore_registers  = { "_" },
  
          -- Update register on yank: true keeps unnamed register synced
          update_register_on_cycle = false,
        },
  
        -- ── Picker ────────────────────────────────────────────────────────────
        picker = {
          select = {
            action = nil,   -- nil = default (paste after)
          },
          telescope = {
            use_default_mappings = true,
            mappings = nil,
          },
        },
  
        -- ── System clipboard ──────────────────────────────────────────────────
        system_clipboard = {
          sync_with_ring = true,
        },
  
        -- ── Highlight flash ───────────────────────────────────────────────────
        highlight = {
          -- Duration of the flash highlight (ms); 0 = disable
          on_put  = true,
          on_yank = true,
          timer   = 200,
        },
  
        -- ── Preserve cursor position on put ───────────────────────────────────
        preserve_cursor_position = {
          enabled = true,
        },
  
        -- ── Text object for last yank ─────────────────────────────────────────
        textobj = {
          enabled = true,
        },
      },
  
      config = function(_, opts)
        require("yanky").setup(opts)
  
        setup_highlights()
  
        -- ── Telescope extension ────────────────────────────────────────────────
        local ok_tele, tele = pcall(require, "telescope")
        if ok_tele then
          pcall(tele.load_extension, "yank_history")
        end
  
        -- ── FZF-Lua integration ────────────────────────────────────────────────
        local ok_fzf = pcall(require, "fzf-lua")
        if ok_fzf then
          pcall(function()
            require("yanky.integrations.fzf-lua").init()
          end)
        end
  
        local aug = vim.api.nvim_create_augroup("AshYanky", { clear = true })
  
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
              "📋 Yanky highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH Yanky", timeout = 1200 }
            )
          end,
        })
  
        if vim.g.ash_debug then
          local backend = vim.fn.executable("sqlite3") == 1 and "SQLite" or "shada"
          vim.notify(
            string.format("📋 Yanky loaded — backend: %s", backend),
            vim.log.levels.DEBUG,
            { title = "ASH Yanky" }
          )
        end
      end,
    },
  }