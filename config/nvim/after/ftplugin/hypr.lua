-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       󰣇 HYPRLAND FTPLUGIN — ASH v5.0 OMEGA                                    ║
-- ║   Config reload · hyprctl commands · keyword set · monitor/workspace info     ║
-- ║   Animation presets · bind helpers · ASH theme sync · window rules            ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local buf = vim.api.nvim_get_current_buf()
local opt = vim.opt_local

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ⚙️  EDITOR OPTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

opt.expandtab    = true
opt.shiftwidth   = 4
opt.tabstop      = 4
opt.softtabstop  = 4
opt.textwidth    = 100
opt.colorcolumn  = "101"
opt.commentstring= "# %s"

-- Treesitter folding
opt.foldmethod   = "expr"
opt.foldexpr     = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel    = 99
opt.foldenable   = true

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, {
    buffer  = buf,
    silent  = true,
    noremap = true,
    desc    = "󰣇 Hypr: " .. desc,
  })
end

local function is_hyprland()
  return os.getenv("HYPRLAND_INSTANCE_SIGNATURE") ~= nil
    or vim.fn.executable("hyprctl") == 1
end

local function hyprctl(args, title)
  if not is_hyprland() then
    vim.notify("󰣇 hyprctl not available (not in Hyprland?)", vim.log.levels.WARN,
      { title = "Hyprland" })
    return nil
  end

  local result = vim.fn.system("hyprctl " .. args .. " 2>&1")
  if title then
    vim.notify(result, vim.log.levels.INFO, { title = "hyprctl: " .. title })
  end
  return result
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗺️  KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── Config management ─────────────────────────────────────────────────────────
map("n", "<leader>hyR", function()
  vim.cmd("write")
  vim.fn.system("hyprctl reload 2>&1")
  vim.notify("󰣇 Hyprland config reloaded", vim.log.levels.INFO,
    { title = "Hyprland", timeout = 1500 })
end, "Reload config")

map("n", "<leader>hyr", function()
  -- Reload without saving
  vim.fn.system("hyprctl reload 2>&1")
  vim.notify("󰣇 Hyprland reloaded (unsaved changes may not apply)",
    vim.log.levels.INFO, { title = "Hyprland", timeout = 1500 })
end, "Reload without save")

-- ── Auto-reload on save toggle ─────────────────────────────────────────────────
map("n", "<leader>hyu", function()
  vim.g.ash_hypr_autoreload = not vim.g.ash_hypr_autoreload
  vim.notify(
    string.format("󰣇 Auto-reload: %s",
      vim.g.ash_hypr_autoreload and "✅ ON" or "⭕ OFF"),
    vim.log.levels.INFO,
    { title = "Hyprland", timeout = 1200 }
  )
end, "Toggle auto-reload")

-- ── Open config files ─────────────────────────────────────────────────────────
map("n", "<leader>hyc", function()
  vim.cmd("edit ~/.config/hypr/hyprland.conf")
end, "Open main config")

map("n", "<leader>hyk", function()
  local kf = vim.fn.expand("~/.config/hypr/keybinds/default.conf")
  if vim.fn.filereadable(kf) == 1 then
    vim.cmd("edit " .. kf)
  else
    vim.cmd("edit ~/.config/hypr/keybinds.conf")
  end
end, "Open keybinds")

map("n", "<leader>hyt", function()
  vim.cmd("edit ~/.config/hypr/themes/colors.conf")
end, "Open theme colors")

-- ── hyprctl commands ──────────────────────────────────────────────────────────
map("n", "<leader>hym", function()
  hyprctl("monitors", "Monitors")
end, "Show monitors")

map("n", "<leader>hyw", function()
  hyprctl("workspaces", "Workspaces")
end, "Show workspaces")

map("n", "<leader>hyW", function()
  hyprctl("clients", "Clients")
end, "Show clients")

map("n", "<leader>hyd", function()
  vim.ui.input({ prompt = "󰣇 dispatch: " }, function(cmd)
    if cmd and cmd ~= "" then
      local result = vim.fn.system("hyprctl dispatch " .. cmd .. " 2>&1")
      vim.notify(result ~= "" and result or "OK", vim.log.levels.INFO,
        { title = "dispatch" })
    end
  end)
end, "Dispatch command")

map("n", "<leader>hys", function()
  vim.ui.input({ prompt = "󰣇 keyword (key val): " }, function(kw)
    if kw and kw ~= "" then
      local result = vim.fn.system("hyprctl keyword " .. kw .. " 2>&1")
      vim.notify(result ~= "" and result or "Set: " .. kw, vim.log.levels.INFO,
        { title = "keyword" })
    end
  end)
end, "Set keyword")

-- ── Keyword under cursor ──────────────────────────────────────────────────────
map("n", "<leader>hye", function()
  -- Send current line as keyword to hyprctl
  local row  = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""

  -- Strip comments and trim
  local kw = line:gsub("#.*$", ""):match("^%s*(.-)%s*$")

  if kw == "" then
    vim.notify("󰣇 Empty line", vim.log.levels.WARN, { title = "Hyprland" })
    return
  end

  local result = vim.fn.system("hyprctl keyword " .. kw .. " 2>&1")
  vim.notify(
    string.format("󰣇 keyword %s\n%s", kw, result ~= "" and result or "OK"),
    vim.log.levels.INFO,
    { title = "Hyprland", timeout = 2000 }
  )
end, "Apply line as keyword")

-- ── ASH integration ───────────────────────────────────────────────────────────
map("n", "<leader>hya", function()
  if vim.fn.executable("ash") == 1 then
    vim.notify("󰣇 Triggering ASH theme sync…", vim.log.levels.INFO,
      { title = "Hyprland + ASH", timeout = 800 })
    vim.fn.system("ash theme apply --reload 2>&1")
  else
    vim.notify("󰣇 ash CLI not found", vim.log.levels.WARN, { title = "Hyprland" })
  end
end, "ASH theme apply")

-- ── Section header navigation ─────────────────────────────────────────────────
map("n", "]s", function()
  -- Jump to next section (line starting with identifier{)
  vim.fn.search("^[a-zA-Z_]\\+\\s*{", "W")
end, "Next section")

map("n", "[s", function()
  vim.fn.search("^[a-zA-Z_]\\+\\s*{", "Wb")
end, "Prev section")

-- ── Validate ──────────────────────────────────────────────────────────────────
map("n", "<leader>hyv", function()
  -- Basic: reload dry-run not supported; use hyprctl to check
  local result = vim.fn.system("hyprctl reload 2>&1")
  if result:match("[Ee]rror") or result:match("[Ff]ailed") then
    vim.notify("󰣇 Config error:\n" .. result, vim.log.levels.ERROR,
      { title = "Hyprland" })
  else
    vim.notify("󰣇 ✅ Config applied", vim.log.levels.INFO,
      { title = "Hyprland", timeout = 1200 })
  end
end, "Validate & apply")

-- ── Info ─────────────────────────────────────────────────────────────────────
map("n", "<leader>hyi", function()
  local hypr_v  = vim.fn.trim(vim.fn.system("hyprctl version 2>/dev/null | head -1"))
  local hl_count = #vim.fn.glob(
    vim.fn.expand("~/.config/hypr") .. "/**/*.conf", false, true
  )

  vim.notify(
    table.concat({
      "󰣇 Hyprland Info",
      "──────────────────────────────────",
      string.format("  Version:     %s", hypr_v),
      string.format("  hyprctl:     %s", vim.fn.executable("hyprctl") == 1 and "✅" or "⭕"),
      string.format("  Config files:%d", hl_count),
      string.format("  Auto-reload: %s", vim.g.ash_hypr_autoreload and "✅ ON" or "⭕ OFF"),
      string.format("  ASH:         %s", vim.fn.executable("ash") == 1 and "✅" or "⭕"),
      string.format("  In Hyprland: %s", is_hyprland() and "✅" or "⭕"),
    }, "\n"),
    vim.log.levels.INFO,
    { title = "Hyprland" }
  )
end, "Environment info")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshFtHypr_" .. buf, { clear = true })

-- Auto-reload on save if enabled
vim.api.nvim_create_autocmd("BufWritePost", {
  group  = aug,
  buffer = buf,
  callback = function()
    if vim.g.ash_hypr_autoreload then
      vim.fn.system("hyprctl reload 2>&1")
      vim.notify("󰣇 Hyprland reloaded", vim.log.levels.INFO,
        { title = "Hyprland", timeout = 800 })
    end
  end,
})