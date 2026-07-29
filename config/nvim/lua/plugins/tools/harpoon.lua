-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🎣 HARPOON — ULTRA FILE NAVIGATOR v5.0 OMEGA                             ║
-- ║   Harpoon 2 · marks · quick switch · terminal · Telescope · ASH theme-synced   ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Menu window ───────────────────────────────────────────────────────────
    hl(0, "HarpoonNormal",         { link = "NormalFloat"   })
    hl(0, "HarpoonBorder",         { link = "FloatBorder"   })
    hl(0, "HarpoonTitle",          { bold = true, fg = "#7aa2f7" })
  
    -- ── List items ────────────────────────────────────────────────────────────
    hl(0, "HarpoonNumberActive",   { bold = true, fg = "#ff9e64", bg = "#2b1d0e" })
    hl(0, "HarpoonNumberInactive", { fg = "#9399b2"              })
    hl(0, "HarpoonFileActive",     { bold = true, fg = "#7aa2f7" })
    hl(0, "HarpoonFileInactive",   { fg = "#cdd6f4"              })
    hl(0, "HarpoonFilePath",       { italic = true, fg = "#9399b2" })
    hl(0, "HarpoonMarked",         { bold = true, fg = "#9ece6a" })
    hl(0, "HarpoonCurrent",        { bold = true, underline = true, fg = "#7aa2f7" })
    hl(0, "HarpoonPosition",       { bold = true, fg = "#cba6f7" })
  
    -- ── Gutter indicators ─────────────────────────────────────────────────────
    hl(0, "HarpoonGutter",         { bold = true, fg = "#ff9e64" })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then
        hl(0, "HarpoonTitle",      { bold = true, fg = p.blue })
        hl(0, "HarpoonFileActive", { bold = true, fg = p.blue })
        hl(0, "HarpoonCurrent",    { bold = true, underline = true, fg = p.blue })
      end
      if p.orange then
        hl(0, "HarpoonNumberActive",{ bold = true, fg = p.orange, bg = p.surface0 or "#2b1d0e" })
        hl(0, "HarpoonGutter",      { bold = true, fg = p.orange })
      end
      if p.green  then hl(0, "HarpoonMarked",  { bold = true, fg = p.green  }) end
      if p.mauve  then hl(0, "HarpoonPosition",{ bold = true, fg = p.mauve  }) end
      local dim = p.overlay0 or "#9399b2"
      hl(0, "HarpoonNumberInactive", { fg = dim })
      hl(0, "HarpoonFilePath",       { italic = true, fg = dim })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 HARPOON UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Add file with notification
  local function add_file()
    local harpoon = require("harpoon")
    harpoon:list():add()
  
    local file  = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
    local count = harpoon:list():length()
  
    vim.notify(
      string.format("🎣 Added: %s  [%d in list]", file, count),
      vim.log.levels.INFO,
      { title = "Harpoon", timeout = 1200 }
    )
  end
  
  -- Remove current file from list
  local function remove_file()
    local harpoon = require("harpoon")
    local list    = harpoon:list()
  
    -- Find current file in list
    local current = vim.api.nvim_buf_get_name(0)
    local found   = false
  
    for i = 1, list:length() do
      local item = list:get(i)
      if item and item.value then
        local item_path = vim.fn.fnamemodify(item.value, ":p")
        local cur_path  = vim.fn.fnamemodify(current, ":p")
        if item_path == cur_path then
          list:removeAt(i)
          found = true
          vim.notify(
            "🎣 Removed from list",
            vim.log.levels.INFO,
            { title = "Harpoon", timeout = 1000 }
          )
          break
        end
      end
    end
  
    if not found then
      vim.notify("🎣 File not in list", vim.log.levels.WARN, { title = "Harpoon" })
    end
  end
  
  -- Clear all marks
  local function clear_all()
    vim.ui.input({ prompt = "🎣 Clear all marks? (y/N): " }, function(input)
      if input and input:lower() == "y" then
        require("harpoon"):list():clear()
        vim.notify("🎣 All marks cleared", vim.log.levels.INFO,
          { title = "Harpoon", timeout = 1000 })
      end
    end)
  end
  
  -- Telescope picker for harpoon list
  local function telescope_harpoon()
    local harpoon = require("harpoon")
    local list    = harpoon:list()
    local items   = {}
  
    for i = 1, list:length() do
      local item = list:get(i)
      if item and item.value then
        table.insert(items, {
          index = i,
          value = item.value,
          display = string.format("[%d] %s", i, item.value),
        })
      end
    end
  
    if #items == 0 then
      vim.notify("🎣 No harpooned files", vim.log.levels.INFO, { title = "Harpoon" })
      return
    end
  
    local ok, tele = pcall(require, "telescope.pickers")
    if not ok then
      -- Fallback: ui.select
      vim.ui.select(
        vim.tbl_map(function(it) return it.display end, items),
        { prompt = "🎣 Harpoon: " },
        function(_, idx)
          if idx then
            list:select(items[idx].index)
          end
        end
      )
      return
    end
  
    local finders = require("telescope.finders")
    local conf    = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
  
    tele.new({
      prompt_title = "🎣 Harpoon",
      finder       = finders.new_table({
        results     = items,
        entry_maker = function(entry)
          return {
            value   = entry,
            display = entry.display,
            ordinal = entry.value,
            path    = vim.fn.fnamemodify(entry.value, ":p"),
          }
        end,
      }),
      sorter    = conf.generic_sorter({}),
      previewer = conf.file_previewer({}),
      attach_mappings = function(prompt_bufnr, map2)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            list:select(selection.value.index)
          end
        end)
  
        -- Delete mark
        map2("i", "<C-d>", function()
          local selection = action_state.get_selected_entry()
          if selection then
            list:removeAt(selection.value.index)
            actions.close(prompt_bufnr)
            vim.notify("🎣 Removed: " .. selection.value.value, vim.log.levels.INFO,
              { title = "Harpoon", timeout = 1000 })
          end
        end)
  
        return true
      end,
    }):find()
  end
  
  -- Quick jump with visual indicator
  local function jump_to(idx)
    return function()
      local harpoon = require("harpoon")
      local list    = harpoon:list()
  
      if idx > list:length() then
        vim.notify(
          string.format("🎣 No file at position %d (list has %d)", idx, list:length()),
          vim.log.levels.WARN,
          { title = "Harpoon" }
        )
        return
      end
  
      local item = list:get(idx)
      if item then
        list:select(idx)
        vim.notify(
          string.format("🎣 [%d] %s", idx, vim.fn.fnamemodify(item.value, ":t")),
          vim.log.levels.INFO,
          { title = "Harpoon", timeout = 600 }
        )
      end
    end
  end
  
  -- Show current list status
  local function show_status()
    local harpoon = require("harpoon")
    local list    = harpoon:list()
    local count   = list:length()
  
    if count == 0 then
      vim.notify("🎣 Harpoon list is empty", vim.log.levels.INFO, { title = "Harpoon" })
      return
    end
  
    local lines = { string.format("🎣 Harpoon — %d file(s)", count), "─────────────────────────────────" }
    local current = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")
  
    for i = 1, count do
      local item = list:get(i)
      if item and item.value then
        local path     = vim.fn.fnamemodify(item.value, ":p")
        local rel      = vim.fn.fnamemodify(item.value, ":~:.")
        local is_cur   = path == current
        local icon     = is_cur and "▸" or " "
        table.insert(lines, string.format("  %s [%d] %s", icon, i, rel))
      end
    end
  
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Harpoon" })
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "ThePrimeagen/harpoon",
      branch       = "harpoon2",
      event        = "VeryLazy",
      dependencies = { "nvim-lua/plenary.nvim" },
  
      keys = {
        -- ── Core ──────────────────────────────────────────────────────────────
        {
          "<leader>ha",
          add_file,
          desc   = "🎣 Harpoon: Add file",
          silent = true,
        },
        {
          "<leader>hd",
          remove_file,
          desc   = "🎣 Harpoon: Remove file",
          silent = true,
        },
        {
          "<leader>hh",
          function()
            local harpoon = require("harpoon")
            local list    = harpoon:list()
            harpoon.ui:toggle_quick_menu(list, {
              title   = "  🎣 Harpoon",
              border  = "rounded",
              ui_width_ratio = 0.50,
              ui_max_width   = 60,
              ui_fallback_width = 40,
            })
          end,
          desc   = "🎣 Harpoon: Quick menu",
          silent = true,
        },
        {
          "<leader>hf",
          telescope_harpoon,
          desc   = "🎣 Harpoon: Telescope picker",
          silent = true,
        },
        {
          "<leader>hx",
          clear_all,
          desc   = "🎣 Harpoon: Clear all",
          silent = true,
        },
        {
          "<leader>hs",
          show_status,
          desc   = "🎣 Harpoon: Status",
          silent = true,
        },
  
        -- ── Jump to position 1–9 ─────────────────────────────────────────────
        { "<leader>h1", jump_to(1), desc = "🎣 Harpoon: File 1", silent = true },
        { "<leader>h2", jump_to(2), desc = "🎣 Harpoon: File 2", silent = true },
        { "<leader>h3", jump_to(3), desc = "🎣 Harpoon: File 3", silent = true },
        { "<leader>h4", jump_to(4), desc = "🎣 Harpoon: File 4", silent = true },
        { "<leader>h5", jump_to(5), desc = "🎣 Harpoon: File 5", silent = true },
        { "<leader>h6", jump_to(6), desc = "🎣 Harpoon: File 6", silent = true },
        { "<leader>h7", jump_to(7), desc = "🎣 Harpoon: File 7", silent = true },
        { "<leader>h8", jump_to(8), desc = "🎣 Harpoon: File 8", silent = true },
        { "<leader>h9", jump_to(9), desc = "🎣 Harpoon: File 9", silent = true },
  
        -- ── Ctrl + number shortcuts (ultra-fast) ─────────────────────────────
        { "<C-F1>", jump_to(1), desc = "🎣 Harpoon: Quick 1", silent = true },
        { "<C-F2>", jump_to(2), desc = "🎣 Harpoon: Quick 2", silent = true },
        { "<C-F3>", jump_to(3), desc = "🎣 Harpoon: Quick 3", silent = true },
        { "<C-F4>", jump_to(4), desc = "🎣 Harpoon: Quick 4", silent = true },
  
        -- ── Cycle through marks ───────────────────────────────────────────────
        {
          "<M-n>",
          function() require("harpoon"):list():next() end,
          desc   = "🎣 Harpoon: Next file",
          silent = true,
        },
        {
          "<M-p>",
          function() require("harpoon"):list():prev() end,
          desc   = "🎣 Harpoon: Prev file",
          silent = true,
        },
  
        -- ── Terminal integration ──────────────────────────────────────────────
        {
          "<leader>ht",
          function()
            local harpoon = require("harpoon")
            -- Switch between file and terminal lists
            local term_list = harpoon:list("terminal")
            harpoon.ui:toggle_quick_menu(term_list, {
              title  = " 🎣 Harpoon Terminals",
              border = "rounded",
            })
          end,
          desc   = "🎣 Harpoon: Terminal menu",
          silent = true,
        },
        {
          "<leader>hT",
          function()
            local harpoon = require("harpoon")
            -- Add current terminal to harpoon
            local ok, term = pcall(require, "toggleterm.terminal")
            if ok then
              local id = vim.b.toggle_number or 1
              harpoon:list("terminal"):add({ value = tostring(id) })
              vim.notify("🎣 Terminal " .. id .. " added", vim.log.levels.INFO,
                { title = "Harpoon", timeout = 1000 })
            end
          end,
          desc   = "🎣 Harpoon: Add terminal",
          silent = true,
        },
      },
  
      opts = {
        -- ── Global settings ────────────────────────────────────────────────────
        settings = {
          -- Save and restore harpoon state across sessions
          save_on_toggle  = true,
          sync_on_ui_close= false,
          save_on_change  = true,
          enter_on_sendcmd= false,
          tmux_autoclose_windows = false,
          excluded_filetypes     = {
            "harpoon",
            "alpha",
            "dashboard",
            "starter",
            "neo-tree",
            "NvimTree",
            "Trouble",
            "quickfix",
            "loclist",
            "nofile",
            "terminal",
          },
          mark_branch      = false,
          key              = function()
            -- Use git root as the project key for isolation
            local root = vim.fn.trim(vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"))
            if vim.v.shell_error == 0 and root ~= "" then
              return root
            end
            return vim.fn.getcwd()
          end,
        },
      },
  
      config = function(_, opts)
        local harpoon = require("harpoon")
        harpoon:setup(opts)
  
        setup_highlights()
  
        -- ── Sign column indicator ──────────────────────────────────────────────
        local function update_signs()
          -- Clear existing harpoon signs
          local ns  = vim.api.nvim_create_namespace("harpoon_signs")
          local buf  = vim.api.nvim_get_current_buf()
          vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  
          local list    = harpoon:list()
          local current = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":p")
  
          for i = 1, list:length() do
            local item = list:get(i)
            if item and item.value then
              local path = vim.fn.fnamemodify(item.value, ":p")
              if path == current then
                -- Show harpoon index in sign column
                vim.fn.sign_place(0, "harpoon", "HarpoonSign" .. i, buf, {
                  lnum     = 1,
                  priority = 15,
                })
                break
              end
            end
          end
        end
  
        -- Register harpoon signs
        for i = 1, 9 do
          vim.fn.sign_define("HarpoonSign" .. i, {
            text   = tostring(i) .. " ",
            texthl = "HarpoonGutter",
          })
        end
  
        -- ── Expose for statusline ──────────────────────────────────────────────
        _G.AshHarpoonStatus = function()
          local ok, hp = pcall(require, "harpoon")
          if not ok then return "" end
  
          local list    = hp:list()
          local count   = list:length()
          if count == 0 then return "" end
  
          local current = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")
          local idx     = nil
  
          for i = 1, count do
            local item = list:get(i)
            if item and item.value then
              local path = vim.fn.fnamemodify(item.value, ":p")
              if path == current then idx = i break end
            end
          end
  
          if idx then
            return string.format(" 🎣 %d/%d ", idx, count)
          end
          return string.format(" 🎣 %d ", count)
        end
  
        local aug = vim.api.nvim_create_augroup("AshHarpoon", { clear = true })
  
        vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
          group    = aug,
          callback = update_signs,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🎣 Harpoon highlights synced", vim.log.levels.INFO,
              { title = "ASH Harpoon", timeout = 1200 })
          end,
        })
  
        -- ── Which-key group registration ───────────────────────────────────────
        local ok_wk, wk = pcall(require, "which-key")
        if ok_wk then
          wk.add({
            { "<leader>h", group = "🎣 Harpoon", mode = { "n" } },
          })
        end
  
        if vim.g.ash_debug then
          local count = harpoon:list():length()
          vim.notify(
            string.format("🎣 Harpoon loaded — %d file(s) marked", count),
            vim.log.levels.DEBUG,
            { title = "ASH Harpoon" }
          )
        end
      end,
    },
  }