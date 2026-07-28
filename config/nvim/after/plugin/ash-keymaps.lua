-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       ⌨️  ASH KEYMAPS — GLOBAL BINDINGS v5.0 OMEGA                              ║
-- ║   Theme · mode · snapshot · doctor · wallpaper · shot · plugin · analytics    ║
-- ║   Which-key groups · Telescope pickers · terminal runners · ASH CLI bridge     ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔒 GUARD
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if vim.g.ash_keymaps_loaded then return end
vim.g.ash_keymaps_loaded = true

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function map(mode, lhs, rhs, desc, opts)
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", {
    silent  = true,
    noremap = true,
    desc    = "🔥 ASH: " .. desc,
  }, opts or {}))
end

local function run_ash(cmd, title)
  local ok, term = pcall(require, "toggleterm.terminal")
  if ok then
    term.Terminal:new({
      cmd          = "ash " .. cmd,
      direction    = "float",
      display_name = "🔥 ash " .. (title or cmd:match("^%S+")),
      float_opts   = { border = "rounded" },
      close_on_exit = false,
    }):toggle()
  else
    vim.fn.jobstart({ "ash" } .. vim.split(cmd, " "), { detach = true })
  end
end

local function ash_picker(subcmd, prompt_title)
  -- Try Telescope picker first
  local ok_tele, tele = pcall(require, "telescope.builtin")
  if ok_tele then
    local ok_ext, _ = pcall(function()
      require("telescope").extensions.ash[subcmd]({
        prompt_title = prompt_title or "🔥 ASH: " .. subcmd,
      })
    end)
    if ok_ext then return end
  end

  -- Fallback: run directly
  run_ash(subcmd, subcmd)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 THEME KEYMAPS — <leader>at*
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Theme picker (Telescope or interactive)
map("n", "<leader>atp", function()
  local ok_engine, engine = pcall(require, "themes.init")
  if ok_engine and engine.list then
    local ok_tele, tele = pcall(require, "telescope.builtin")
    if ok_tele then
      tele.colorscheme({
        prompt_title   = "🎨 ASH Themes",
        enable_preview = true,
      })
      return
    end
    -- Fallback: ui.select
    vim.ui.select(engine.list(), {
      prompt = "🎨 ASH Theme: ",
    }, function(theme)
      if theme then engine.apply(theme) end
    end)
  else
    run_ash("theme pick", "theme picker")
  end
end, "Theme picker")

-- Quick apply by name
map("n", "<leader>ata", function()
  vim.ui.input({ prompt = "🎨 Theme name: " }, function(name)
    if not name or name == "" then return end
    local ok, engine = pcall(require, "themes.init")
    if ok then engine.apply(name)
    else run_ash("theme apply " .. name, "apply") end
  end)
end, "Theme apply (input)")

-- Random theme
map("n", "<leader>atR", function()
  local ok, engine = pcall(require, "themes.init")
  if ok and engine.random then engine.random()
  else run_ash("theme random", "random") end
end, "Theme random")

-- Next / Prev theme cycle
map("n", "<leader>atn", function()
  local ok, engine = pcall(require, "themes.init")
  if ok and engine.next then engine.next()
  else run_ash("theme apply --next", "next") end
end, "Theme next")

map("n", "<leader>atP", function()
  local ok, engine = pcall(require, "themes.init")
  if ok and engine.prev then engine.prev()
  else run_ash("theme apply --prev", "prev") end
end, "Theme prev")

-- Undo last theme change
map("n", "<leader>atu", function()
  local ok, engine = pcall(require, "themes.init")
  if ok and engine.undo then engine.undo() end
end, "Theme undo")

-- Theme info
map("n", "<leader>ati", function()
  local ok, engine = pcall(require, "themes.init")
  if ok and engine.stats then engine.stats()
  else run_ash("theme info", "info") end
end, "Theme info")

-- Sync from ASH CLI
map("n", "<leader>ats", function()
  local ok, engine = pcall(require, "themes.init")
  if ok and engine.sync_from_ash then engine.sync_from_ash()
  else vim.cmd("AshSync") end
end, "Theme sync from ASH")

-- AI theme generation
map("n", "<leader>atg", function()
  vim.ui.input({ prompt = "🤖 Describe your theme: " }, function(desc)
    if desc and desc ~= "" then
      run_ash("theme ai-generate " .. vim.fn.shellescape(desc), "AI generate")
    end
  end)
end, "Theme AI generate")

-- Store browse
map("n", "<leader>atb", function()
  run_ash("theme store-browse", "store browse")
end, "Theme store browse")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎭 MODE KEYMAPS — <leader>am*
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Mode picker
map("n", "<leader>amp", function()
  local modes = {
    "default", "focus", "game", "cinema", "present",
    "work", "stream", "privacy", "battery", "accessibility",
  }
  vim.ui.select(modes, { prompt = "🎭 ASH Mode: " }, function(mode)
    if mode then run_ash("mode " .. mode, mode) end
  end)
end, "Mode picker")

-- Quick mode switches
local MODES = {
  { key = "mf", mode = "focus",  icon = "🎯" },
  { key = "mg", mode = "game",   icon = "🎮" },
  { key = "mc", mode = "cinema", icon = "🎬" },
  { key = "mp", mode = "present",icon = "📊" },
  { key = "mw", mode = "work",   icon = "💼" },
  { key = "ms", mode = "stream", icon = "📡" },
  { key = "mb", mode = "battery",icon = "🔋" },
  { key = "md", mode = "default",icon = "🏠" },
}

for _, m in ipairs(MODES) do
  map("n", "<leader>a" .. m.key, function()
    run_ash("mode " .. m.mode, m.mode)
  end, string.format("Mode: %s %s", m.icon, m.mode))
end

-- Mode status
map("n", "<leader>ami", function()
  run_ash("mode status", "mode status")
end, "Mode info")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📸 SNAPSHOT KEYMAPS — <leader>as*
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Create snapshot
map("n", "<leader>asc", function()
  vim.ui.input({ prompt = "📸 Snapshot name: " }, function(name)
    if name and name ~= "" then
      run_ash("snapshot create " .. vim.fn.shellescape(name), "snapshot create")
    else
      run_ash("snapshot create", "snapshot create")
    end
  end)
end, "Snapshot create")

-- List snapshots
map("n", "<leader>asl", function()
  run_ash("snapshot list", "snapshot list")
end, "Snapshot list")

-- Restore snapshot
map("n", "<leader>asr", function()
  run_ash("snapshot restore", "snapshot restore")
end, "Snapshot restore")

-- Diff snapshots
map("n", "<leader>asd", function()
  run_ash("snapshot diff", "snapshot diff")
end, "Snapshot diff")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🖼️  WALLPAPER KEYMAPS — <leader>aw*
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

map("n", "<leader>awp", function() run_ash("wallpaper pick", "pick")     end, "Wallpaper pick")
map("n", "<leader>awr", function() run_ash("wallpaper random", "random") end, "Wallpaper random")
map("n", "<leader>aws", function() run_ash("wallpaper slideshow", "slideshow") end, "Wallpaper slideshow")
map("n", "<leader>awg", function()
  vim.ui.input({ prompt = "🤖 Wallpaper description: " }, function(desc)
    if desc and desc ~= "" then
      run_ash("wallpaper generate-ai " .. vim.fn.shellescape(desc), "AI wallpaper")
    end
  end)
end, "Wallpaper AI generate")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📷 SCREENSHOT KEYMAPS — <leader>ax*
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

map("n", "<leader>axf", function() run_ash("shot full", "full shot")     end, "Screenshot full")
map("n", "<leader>axa", function() run_ash("shot area", "area shot")     end, "Screenshot area")
map("n", "<leader>axw", function() run_ash("shot window", "window shot") end, "Screenshot window")
map("n", "<leader>axr", function() run_ash("shot record", "record")      end, "Screen record")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔌 PLUGIN KEYMAPS — <leader>app*
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

map("n", "<leader>appl", function() run_ash("plugin list", "plugin list")     end, "Plugin list")
map("n", "<leader>appb", function() run_ash("plugin browse", "plugin browse") end, "Plugin browse")
map("n", "<leader>appi", function()
  vim.ui.input({ prompt = "🔌 Plugin name: " }, function(name)
    if name and name ~= "" then
      run_ash("plugin install " .. name, "install: " .. name)
    end
  end)
end, "Plugin install")
map("n", "<leader>appu", function() run_ash("plugin update-all", "update all") end, "Plugin update all")
map("n", "<leader>appr", function()
  vim.ui.input({ prompt = "🔌 Plugin to remove: " }, function(name)
    if name and name ~= "" then
      run_ash("plugin remove " .. name, "remove")
    end
  end)
end, "Plugin remove")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 DOCTOR / SYSTEM — <leader>aD*
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

map("n", "<leader>aDd", function() run_ash("doctor", "doctor")           end, "Doctor full check")
map("n", "<leader>aDq", function() run_ash("doctor quick", "quick check") end, "Doctor quick")
map("n", "<leader>aDf", function() run_ash("doctor fix", "auto-fix")      end, "Doctor fix")
map("n", "<leader>aDh", function() run_ash("hw full-report", "hardware")  end, "Hardware report")
map("n", "<leader>aDn", function() run_ash("net status", "network")       end, "Network status")
map("n", "<leader>aDD", function()
  vim.cmd("AshHealth")
end, "Neovim ASH health")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔄 UPDATE — <leader>aU*
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

map("n", "<leader>aUd", function() run_ash("update dotfiles", "update dotfiles") end, "Update dotfiles")
map("n", "<leader>aUs", function() run_ash("update system", "update system")     end, "Update system")
map("n", "<leader>aUa", function() run_ash("update all", "update all")           end, "Update everything")
map("n", "<leader>aUc", function() run_ash("update check", "check updates")      end, "Check for updates")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📊 ANALYTICS — <leader>aA*
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

map("n", "<leader>aAs", function() run_ash("analytics dashboard", "analytics")  end, "Analytics dashboard")
map("n", "<leader>aAt", function() run_ash("analytics theme-stats", "theme stats") end, "Theme stats")
map("n", "<leader>aAn", function() vim.cmd("AshAnalytics") end, "Neovim analytics")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔒 BACKUP — <leader>aB*
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

map("n", "<leader>aBc", function() run_ash("backup create", "backup create")   end, "Backup create")
map("n", "<leader>aBr", function() run_ash("backup restore", "backup restore") end, "Backup restore")
map("n", "<leader>aBl", function() run_ash("backup list", "backup list")       end, "Backup list")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🤖 AI — <leader>aI*
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

map("n", "<leader>aIc", function() run_ash("ai chat", "AI chat")       end, "AI chat")
map("n", "<leader>aIs", function()
  vim.ui.input({ prompt = "🤖 Suggest theme for: " }, function(q)
    if q and q ~= "" then
      run_ash("ai suggest-theme " .. vim.fn.shellescape(q), "AI suggest")
    end
  end)
end, "AI suggest theme")
map("n", "<leader>aIo", function() run_ash("ai optimize-config", "AI optimize") end, "AI optimize config")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 THEME ENGINE DIRECT KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Force full reload of theme highlights in Neovim
map("n", "<leader>atL", function()
  -- Fire the reload event manually
  vim.api.nvim_exec_autocmds("User", {
    pattern  = "AshThemeChanged",
    data     = { source = "manual_reload" },
    modeline = false,
  })
  vim.notify("🔥 Theme highlights reloaded", vim.log.levels.INFO,
    { title = "ASH", timeout = 1000 })
end, "Theme reload (Neovim)")

-- Open ASH config dir in file manager
map("n", "<leader>aOf", function()
  local cfg_dir = vim.fn.expand("~/.config/ash")
  local ok, _ = pcall(vim.cmd, "edit " .. cfg_dir)
  if not ok then
    vim.notify("🔥 Config dir: " .. cfg_dir, vim.log.levels.INFO,
      { title = "ASH" })
  end
end, "Open ASH config dir")

-- Quick ASH command input
map("n", "<leader>a:", function()
  vim.ui.input({ prompt = "🔥 ash " }, function(cmd)
    if cmd and cmd ~= "" then
      run_ash(cmd, cmd:match("^%S+"))
    end
  end)
end, "Run ash command")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗺️  WHICH-KEY GROUP REGISTRATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vim.api.nvim_create_autocmd("VimEnter", {
  once     = true,
  callback = function()
    local ok, wk = pcall(require, "which-key")
    if not ok then return end

    wk.add({
      -- Root group
      { "<leader>a",   group = "🔥 ASH"               },

      -- Subgroups
      { "<leader>at",  group = "🎨 Theme"              },
      { "<leader>am",  group = "🎭 Mode"               },
      { "<leader>as",  group = "📸 Snapshot"           },
      { "<leader>aw",  group = "🖼️  Wallpaper"         },
      { "<leader>ax",  group = "📷 Screenshot"         },
      { "<leader>app", group = "🔌 Plugin"             },
      { "<leader>aD",  group = "🏥 Doctor"             },
      { "<leader>aU",  group = "🔄 Update"             },
      { "<leader>aA",  group = "📊 Analytics"          },
      { "<leader>aB",  group = "🔒 Backup"             },
      { "<leader>aI",  group = "🤖 AI"                 },
      { "<leader>aO",  group = "📁 Open"               },
    })
  end,
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🚀 REGISTER USER COMMANDS (for :commands completion)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vim.api.nvim_create_user_command("AshThemePick", function()
  vim.fn.feedkeys("<leader>atp", "t")
end, { desc = "🎨 ASH: Theme picker" })

vim.api.nvim_create_user_command("AshModeSet", function(args)
  if args.args ~= "" then
    run_ash("mode " .. args.args, args.args)
  end
end, {
  nargs = "?",
  complete = function()
    return { "default", "focus", "game", "cinema", "present",
             "work", "stream", "privacy", "battery", "accessibility" }
  end,
  desc = "🎭 ASH: Set mode",
})

vim.api.nvim_create_user_command("AshRun", function(args)
  if args.args ~= "" then
    run_ash(args.args, args.args:match("^%S+"))
  end
end, {
  nargs = "+",
  desc  = "🔥 ASH: Run ash command",
  complete = function()
    return {
      "theme pick", "theme random", "theme apply",
      "mode focus", "mode game", "mode default",
      "snapshot create", "snapshot list", "snapshot restore",
      "wallpaper pick", "wallpaper random",
      "shot full", "shot area",
      "doctor", "doctor quick",
      "plugin list", "plugin browse",
      "update all", "update dotfiles",
      "analytics dashboard",
    }
  end,
})