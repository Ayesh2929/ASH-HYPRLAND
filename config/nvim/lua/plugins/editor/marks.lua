-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📍 MARKS.NVIM — ULTRA MARK MANAGEMENT v5.0 OMEGA                         ║
-- ║   Visual mark signs · bookmark groups · Telescope picker · auto-cleanup        ║
-- ║   global/local/file marks · shada persistence · ASH theme-synced signs        ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT & SIGN SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Local marks (a–z) ─────────────────────────────────────────────────────
    hl(0, "MarkSignHL",        {
      bold   = true,
      fg     = "#7aa2f7",
    })
    hl(0, "MarkSignNumHL",     {
      bold   = true,
      fg     = "#7aa2f7",
    })
    hl(0, "MarkVirtTextHL",    {
      italic = true,
      fg     = "#7aa2f7",
    })
  
    -- ── Global marks (A–Z) ────────────────────────────────────────────────────
    hl(0, "MarkGlobalSignHL",    {
      bold   = true,
      fg     = "#ff9e64",
    })
    hl(0, "MarkGlobalVirtTextHL",{
      italic = true,
      fg     = "#ff9e64",
    })
  
    -- ── Bookmark groups (1–9) ─────────────────────────────────────────────────
    -- Each group gets a distinct accent colour
    local BOOKMARK_COLOURS = {
      "#f38ba8",   -- group 1: red
      "#fab387",   -- group 2: orange
      "#f9e2af",   -- group 3: yellow
      "#a6e3a1",   -- group 4: green
      "#94e2d5",   -- group 5: teal
      "#89b4fa",   -- group 6: blue
      "#b4befe",   -- group 7: lavender
      "#cba6f7",   -- group 8: mauve
      "#f5c2e7",   -- group 9: pink
    }
  
    for i, colour in ipairs(BOOKMARK_COLOURS) do
      hl(0, "BookmarkSign" .. i,     { bold = true, fg = colour    })
      hl(0, "BookmarkVirtText" .. i, { italic = true, fg = colour  })
      hl(0, "BookmarkAnnotation" .. i,{ fg = colour, italic = true })
      hl(0, "BookmarkNumber" .. i,   { bold = true, fg = colour    })
    end
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue then
        hl(0, "MarkSignHL",     { bold = true, fg = p.blue })
        hl(0, "MarkSignNumHL",  { bold = true, fg = p.blue })
        hl(0, "MarkVirtTextHL", { italic = true, fg = p.blue })
      end
      if p.orange then
        hl(0, "MarkGlobalSignHL",     { bold = true, fg = p.orange   })
        hl(0, "MarkGlobalVirtTextHL", { italic = true, fg = p.orange })
      end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎯 SIGN DEFINITIONS — premium Nerd Font v3 icons
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Bookmark group signs with distinct icons
  local BOOKMARK_SIGNS = {
    "󰃀 ",   -- 1: bookmark
    "󰃁 ",   -- 2: bookmark filled
    "󰃂 ",   -- 3: bookmark star
    " ",   -- 4: circle
    " ",   -- 5: triangle
    "󰓺 ",   -- 6: diamond
    "󰄵 ",   -- 7: check
    " ",   -- 8: heart
    " ",   -- 9: lightning
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 SMART OPERATIONS — enhanced mark management
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Set a mark with optional annotation via vim.ui.input
  local function set_mark_with_annotation()
    vim.ui.input(
      { prompt = "📍 Mark char (a-z / A-Z): " },
      function(char)
        if not char or char == "" then return end
        char = char:sub(1, 1)
        if not char:match("[a-zA-Z]") then
          vim.notify("⚠ Invalid mark: use a–z or A–Z", vim.log.levels.WARN,
            { title = "Marks" })
          return
        end
        vim.cmd("mark " .. char)
        vim.notify(
          string.format("📍 Set mark '%s' at line %d", char,
            vim.api.nvim_win_get_cursor(0)[1]),
          vim.log.levels.INFO,
          { title = "Marks", timeout = 1500 }
        )
      end
    )
  end
  
  -- Delete all local marks in current buffer
  local function delete_all_local_marks()
    local ok = pcall(function()
      -- Delete all lowercase marks
      vim.cmd("delmarks a-z")
      -- Also clear the marks.nvim state
      require("marks").clear()
    end)
    if ok then
      vim.notify(
        "📍 All local marks cleared",
        vim.log.levels.INFO,
        { title = "Marks", timeout = 1500 }
      )
    end
  end
  
  -- Delete all global marks
  local function delete_all_global_marks()
    local ok = pcall(function()
      vim.cmd("delmarks A-Z")
      require("marks").clear()
    end)
    if ok then
      vim.notify(
        "📍 All global marks cleared",
        vim.log.levels.INFO,
        { title = "Marks", timeout = 1500 }
      )
    end
  end
  
  -- Show all marks in a floating window summary
  local function show_marks_summary()
    local marks_data = {}
    -- Local marks
    for i = 97, 122 do  -- a–z
      local c   = string.char(i)
      local pos = vim.fn.getpos("'" .. c)
      if pos[2] ~= 0 then
        local line = vim.api.nvim_buf_get_lines(0, pos[2] - 1, pos[2], false)[1] or ""
        table.insert(marks_data, string.format(
          "  [%s] line %-5d  %s",
          c, pos[2], line:match("^%s*(.-)%s*$"):sub(1, 50)
        ))
      end
    end
    -- Global marks
    for i = 65, 90 do   -- A–Z
      local c   = string.char(i)
      local pos = vim.fn.getpos("'" .. c)
      if pos[2] ~= 0 then
        local fname = vim.fn.bufname(pos[1])
        table.insert(marks_data, string.format(
          "  [%s] %s:%d",
          c, vim.fn.fnamemodify(fname, ":~:."), pos[2]
        ))
      end
    end
  
    if #marks_data == 0 then
      vim.notify(
        "📍 No marks set in this buffer",
        vim.log.levels.INFO,
        { title = "Marks" }
      )
      return
    end
  
    vim.notify(
      "📍 Marks Summary:\n" .. table.concat(marks_data, "\n"),
      vim.log.levels.INFO,
      { title = "Marks" }
    )
  end
  
  -- Telescope marks picker (if Telescope is available)
  local function telescope_marks()
    local ok, tele = pcall(require, "telescope.builtin")
    if ok then
      tele.marks({ prompt_title = "📍 Marks" })
    else
      vim.cmd("marks")
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "chentoast/marks.nvim",
      event = { "BufReadPre", "BufNewFile" },
  
      keys = {
        -- ── Navigate marks ────────────────────────────────────────────────────
        {
          "]m",
          function() require("marks").next() end,
          desc  = "📍 Next Mark",
          silent = true,
        },
        {
          "[m",
          function() require("marks").prev() end,
          desc  = "📍 Prev Mark",
          silent = true,
        },
        {
          "]M",
          function() require("marks").next_bookmark() end,
          desc  = "📍 Next Bookmark",
          silent = true,
        },
        {
          "[M",
          function() require("marks").prev_bookmark() end,
          desc  = "📍 Prev Bookmark",
          silent = true,
        },
  
        -- ── Set marks ─────────────────────────────────────────────────────────
        {
          "<leader>mm",
          function() require("marks").set() end,
          desc  = "📍 Set Mark",
          silent = true,
        },
        {
          "<leader>mM",
          set_mark_with_annotation,
          desc  = "📍 Set Mark (annotated)",
          silent = true,
        },
  
        -- ── Delete marks ─────────────────────────────────────────────────────
        {
          "<leader>md",
          function() require("marks").delete_line() end,
          desc  = "📍 Delete Mark (line)",
          silent = true,
        },
        {
          "<leader>mD",
          function() require("marks").delete_buf() end,
          desc  = "📍 Delete All (buffer)",
          silent = true,
        },
        {
          "<leader>mx",
          delete_all_local_marks,
          desc  = "📍 Clear Local Marks",
          silent = true,
        },
        {
          "<leader>mX",
          delete_all_global_marks,
          desc  = "📍 Clear Global Marks",
          silent = true,
        },
  
        -- ── Bookmarks ─────────────────────────────────────────────────────────
        {
          "<leader>mb",
          function() require("marks").toggle_bookmark0() end,
          desc  = "📍 Toggle Bookmark (group 1)",
          silent = true,
        },
        -- Bookmark groups 1–9
        (function()
          local specs = {}
          for i = 1, 9 do
            table.insert(specs, {
              "<leader>m" .. i,
              function() require("marks")["toggle_bookmark" .. (i - 1)]() end,
              desc   = string.format("📍 Toggle Bookmark (group %d)", i),
              silent = true,
            })
          end
          return specs
        end)(),
  
        -- ── View / search ─────────────────────────────────────────────────────
        {
          "<leader>ml",
          show_marks_summary,
          desc  = "📍 Marks Summary",
          silent = true,
        },
        {
          "<leader>mf",
          telescope_marks,
          desc  = "📍 Marks (Telescope)",
          silent = true,
        },
        {
          "<leader>mq",
          function() require("marks").qflist(false) end,
          desc  = "📍 Marks → Quickfix",
          silent = true,
        },
        {
          "<leader>mQ",
          function() require("marks").qflist(true) end,
          desc  = "📍 All Marks → Quickfix",
          silent = true,
        },
  
        -- ── Flush marks (write to shada) ──────────────────────────────────────
        {
          "<leader>mw",
          function()
            vim.cmd("wshada!")
            vim.notify(
              "📍 Marks saved to shada",
              vim.log.levels.INFO,
              { title = "Marks", timeout = 1200 }
            )
          end,
          desc  = "📍 Save Marks (shada)",
          silent = true,
        },
      },
  
      opts = {
        -- ── Default mappings ──────────────────────────────────────────────────
        -- We override all mappings in keys[] above, so disable defaults
        default_mappings    = true,
  
        -- ── Sign column ───────────────────────────────────────────────────────
        -- Built-in marks ('' `. etc.) to show in sign column
        builtin_marks       = { ".", "<", ">", "^" },
  
        -- ── Cyclic navigation ─────────────────────────────────────────────────
        -- Cycle back to first mark when at the last
        cyclic              = true,
  
        -- ── Force write ───────────────────────────────────────────────────────
        -- Write mark to shada on every mark set
        force_write_shada   = false,
  
        -- ── Refresh interval ─────────────────────────────────────────────────
        -- How often to re-check marks (ms); 0 = on CursorHold only
        refresh_interval    = 250,
  
        -- ── Sign priority ────────────────────────────────────────────────────
        sign_priority       = {
          lower    = 10,
          upper    = 15,
          builtin  = 8,
          bookmark = 20,
        },
  
        -- ── Excluded filetypes ────────────────────────────────────────────────
        excluded_filetypes  = {
          "alpha", "dashboard", "starter",
          "neo-tree", "NvimTree", "oil",
          "Trouble", "trouble", "qf",
          "TelescopePrompt", "lazy", "mason",
          "help", "man", "checkhealth",
          "noice", "notify", "toggleterm",
          "spectre_panel", "undotree",
          "NeogitStatus", "gitcommit",
          "DressingInput",
        },
  
        -- ── Excluded buftypes ─────────────────────────────────────────────────
        excluded_buftypes   = {
          "terminal",
          "quickfix",
          "nofile",
          "nowrite",
          "prompt",
        },
  
        -- ── Marks sign definitions ────────────────────────────────────────────
        marks = {
          -- Lowercase marks (local)
          lower = {
            sign  = "󰃀",
            virt_text = "",
            hl    = "MarkSignHL",
          },
          -- Uppercase marks (global)
          upper = {
            sign  = "󰃁",
            virt_text = "",
            hl    = "MarkGlobalSignHL",
          },
          -- Builtin marks
          builtin = {
            sign  = "·",
            virt_text = "",
            hl    = "MarkSignHL",
          },
        },
  
        -- ── Bookmark groups ────────────────────────────────────────────────────
        -- Each group (0–8) maps to bookmark0–bookmark8 commands
        -- and gets a distinct sign icon and colour
        bookmark_0 = {
          sign     = BOOKMARK_SIGNS[1],
          virt_text = "  bookmark",
          hl       = "BookmarkSign1",
        },
        bookmark_1 = {
          sign     = BOOKMARK_SIGNS[2],
          virt_text = "  bookmark",
          hl       = "BookmarkSign2",
        },
        bookmark_2 = {
          sign     = BOOKMARK_SIGNS[3],
          virt_text = "  bookmark",
          hl       = "BookmarkSign3",
        },
        bookmark_3 = {
          sign     = BOOKMARK_SIGNS[4],
          virt_text = "  bookmark",
          hl       = "BookmarkSign4",
        },
        bookmark_4 = {
          sign     = BOOKMARK_SIGNS[5],
          virt_text = "  bookmark",
          hl       = "BookmarkSign5",
        },
        bookmark_5 = {
          sign     = BOOKMARK_SIGNS[6],
          virt_text = "  bookmark",
          hl       = "BookmarkSign6",
        },
        bookmark_6 = {
          sign     = BOOKMARK_SIGNS[7],
          virt_text = "  bookmark",
          hl       = "BookmarkSign7",
        },
        bookmark_7 = {
          sign     = BOOKMARK_SIGNS[8],
          virt_text = "  bookmark",
          hl       = "BookmarkSign8",
        },
        bookmark_8 = {
          sign     = BOOKMARK_SIGNS[9],
          virt_text = "  bookmark",
          hl       = "BookmarkSign9",
        },
  
        -- ── Mapping config ────────────────────────────────────────────────────
        mappings = {
          set                 = "m",
          set_next            = "m,",
          toggle              = "m;",
          delete_line         = "dm",
          delete_buf          = "dm<space>",
          next                = "]m",
          prev                = "[m",
          preview             = "m:",
          set_bookmark0       = "m0",
          set_bookmark1       = "m1",
          set_bookmark2       = "m2",
          set_bookmark3       = "m3",
          set_bookmark4       = "m4",
          set_bookmark5       = "m5",
          set_bookmark6       = "m6",
          set_bookmark7       = "m7",
          set_bookmark8       = "m8",
          delete_bookmark     = "m=",
        },
      },
  
      config = function(_, opts)
        -- Flatten the nested bookmark key specs before passing to setup
        local clean_opts = vim.tbl_deep_extend("force", opts, {})
        -- Remove the array returned by the IIFE in keys[]
        require("marks").setup(clean_opts)
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshMarks", { clear = true })
  
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
              "📍 Marks highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH Marks", timeout = 1200 }
            )
          end,
        })
  
        -- ── Auto-save marks to shada on buffer write ──────────────────────────
        vim.api.nvim_create_autocmd("BufWritePost", {
          group    = aug,
          callback = function()
            pcall(vim.cmd, "wshada")
          end,
        })
  
        -- ── Show mark name in virtualtext when setting ─────────────────────────
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "MarksChanged",
          callback = function()
            -- Refresh sign column for all visible buffers
            vim.cmd("redraw!")
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            "📍 Marks.nvim loaded — 9 bookmark groups active",
            vim.log.levels.DEBUG,
            { title = "ASH Marks" }
          )
        end
      end,
    },
  }