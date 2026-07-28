-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       󰊢 GITCOMMIT FTPLUGIN — ASH v5.0 OMEGA                                   ║
-- ║   Conventional commits · subject line · word count · spell check              ║
-- ║   gitmoji · coauthor · breaking change · diff stats preview                   ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local buf = vim.api.nvim_get_current_buf()
local opt = vim.opt_local

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ⚙️  EDITOR OPTIONS — optimised for commit writing
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

opt.expandtab    = true
opt.shiftwidth   = 2
opt.tabstop      = 2
opt.softtabstop  = 2
opt.textwidth    = 72          -- Conventional commits: subject ≤72 chars
opt.colorcolumn  = "73,51"     -- 72 = hard limit, 50 = subject sweet spot
opt.wrap         = true
opt.linebreak    = true
opt.spell        = true
opt.spelllang    = "en_us"
opt.conceallevel = 0
opt.number       = false        -- no line numbers in commit
opt.relativenumber = false
opt.signcolumn   = "no"

-- Start in insert mode at the beginning
vim.api.nvim_create_autocmd("BufEnter", {
  buffer = buf,
  once   = true,
  callback = function()
    -- Only go to insert mode if first line is empty
    local first = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
    if first == "" then
      vim.cmd("startinsert")
    end
  end,
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, {
    buffer  = buf,
    silent  = true,
    noremap = true,
    desc    = "󰊢 Commit: " .. desc,
  })
end

-- Get subject line (first non-comment, non-blank line)
local function get_subject()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for _, line in ipairs(lines) do
    if line ~= "" and not line:match("^#") then
      return line
    end
  end
  return ""
end

-- Check conventional commit format
local function check_conventional(subject)
  local types = {
    "feat", "fix", "docs", "style", "refactor", "perf",
    "test", "build", "ci", "chore", "revert", "wip",
    -- ASH custom
    "ash", "theme", "config",
  }

  -- Pattern: type[(scope)][!]: description
  local pattern = "^([a-z]+)(%(([^%)]+)%))?(!)?: (.+)$"
  local t, _, scope, bang, desc = subject:match(pattern)

  if not t then
    return {
      valid   = false,
      error   = "Not a conventional commit: type[(scope)][!]: description",
      type    = nil,
      scope   = nil,
      breaking= false,
      desc    = nil,
    }
  end

  local known = vim.tbl_contains(types, t)

  return {
    valid    = true,
    known    = known,
    type     = t,
    scope    = scope,
    breaking = bang == "!",
    desc     = desc,
    error    = not known and ("Unknown type: " .. t) or nil,
  }
end

-- Count commit subject characters (excluding type/scope prefix)
local function subject_stats()
  local subject = get_subject()
  if subject == "" then return nil end

  local total = #subject
  local info  = check_conventional(subject)

  return {
    total    = total,
    ok       = total <= 72,
    sweet    = total <= 50,
    info     = info,
  }
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎯 CONVENTIONAL COMMIT TYPE PICKER
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Conventional commit types with icons and descriptions
local COMMIT_TYPES = {
  { type = "feat",     icon = "✨", desc = "A new feature"                          },
  { type = "fix",      icon = "🐛", desc = "A bug fix"                              },
  { type = "docs",     icon = "📖", desc = "Documentation only changes"             },
  { type = "style",    icon = "💎", desc = "Formatting, missing semi-colons, etc."  },
  { type = "refactor", icon = "♻️ ", desc = "Code change that is neither fix nor feat" },
  { type = "perf",     icon = "🚀", desc = "Performance improvement"                },
  { type = "test",     icon = "🧪", desc = "Adding or correcting tests"             },
  { type = "build",    icon = "🏗️ ", desc = "Build system or dependencies"          },
  { type = "ci",       icon = "🤖", desc = "CI/CD changes"                          },
  { type = "chore",    icon = "🔧", desc = "Other changes (no src/test change)"     },
  { type = "revert",   icon = "⏪", desc = "Revert a previous commit"              },
  { type = "wip",      icon = "🚧", desc = "Work in progress (not for main)"        },
  -- ASH-specific
  { type = "theme",    icon = "🎨", desc = "ASH theme change"                       },
  { type = "config",   icon = "⚙️ ", desc = "Configuration change"                  },
  { type = "ash",      icon = "🔥", desc = "ASH dotfiles specific change"           },
}

-- Gitmoji map
local GITMOJI = {
  feat     = "✨",  fix      = "🐛",  docs     = "📖",
  style    = "💎",  refactor = "♻️ ",  perf     = "🚀",
  test     = "🧪",  build    = "🏗️ ",  ci       = "🤖",
  chore    = "🔧",  revert   = "⏪",  wip      = "🚧",
  theme    = "🎨",  config   = "⚙️ ",  ash      = "🔥",
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗺️  KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── Conventional commit type picker ──────────────────────────────────────────
map("n", "<leader>ct", function()
  local items = vim.tbl_map(function(t)
    return string.format("%-12s %s  %s", t.type, t.icon, t.desc)
  end, COMMIT_TYPES)

  vim.ui.select(items, { prompt = "󰊢 Commit type: " }, function(_, idx)
    if not idx then return end
    local selected = COMMIT_TYPES[idx]

    -- Ask for scope (optional)
    vim.ui.input(
      { prompt = "󰊢 Scope (optional, e.g. 'api', 'ui'): " },
      function(scope)
        -- Ask for breaking change
        local breaking
        vim.ui.input(
          { prompt = "󰊢 Breaking change? (y/N): " },
          function(bc)
            breaking = bc and bc:lower() == "y"

            local prefix = selected.type
            if scope and scope ~= "" then
              prefix = prefix .. "(" .. scope .. ")"
            end
            if breaking then prefix = prefix .. "!" end
            prefix = prefix .. ": "

            -- Place cursor on line 1, insert prefix
            local line1 = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
            if line1:match("^%s*$") then
              -- Empty first line: set it
              vim.api.nvim_buf_set_lines(buf, 0, 1, false, { prefix })
              vim.api.nvim_win_set_cursor(0, { 1, #prefix })
            else
              -- Prepend to existing content
              vim.api.nvim_buf_set_lines(buf, 0, 1, false, { prefix .. line1 })
              vim.api.nvim_win_set_cursor(0, { 1, #prefix })
            end

            vim.cmd("startinsert!")
          end
        )
      end
    )
  end)
end, "Pick commit type")

-- ── Add gitmoji ──────────────────────────────────────────────────────────────
map("n", "<leader>cg", function()
  local subject = get_subject()
  local t       = subject:match("^([a-z]+)")

  if t and GITMOJI[t] then
    -- Auto-insert matching emoji
    local emoji = GITMOJI[t]
    local line1  = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
    vim.api.nvim_buf_set_lines(buf, 0, 1, false, { emoji .. " " .. line1 })
    vim.notify("󰊢 Added: " .. emoji, vim.log.levels.INFO,
      { title = "Commit", timeout = 1000 })
  else
    -- Manual emoji picker
    local emojis = {
      "✨ feat", "🐛 fix", "📖 docs", "💎 style", "♻️  refactor",
      "🚀 perf", "🧪 test", "🏗️  build", "🤖 ci", "🔧 chore",
      "⏪ revert", "🚧 wip", "🎨 theme", "🔥 ash", "💥 BREAKING",
      "🔒 security", "⬆️  deps", "⬇️  deps", "📦 release", "🗑️  remove",
    }
    vim.ui.select(emojis, { prompt = "󰊢 Gitmoji: " }, function(choice)
      if not choice then return end
      local emoji = choice:match("^(%S+%s?%S*)")
      local line1 = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
      vim.api.nvim_buf_set_lines(buf, 0, 1, false,
        { vim.fn.trim(emoji) .. " " .. line1 })
    end)
  end
end, "Add gitmoji")

-- ── Validate commit ────────────────────────────────────────────────────────────
map("n", "<leader>cv", function()
  local subject = get_subject()
  if subject == "" then
    vim.notify("󰊢 Empty subject line", vim.log.levels.WARN, { title = "Commit" })
    return
  end

  local stats  = subject_stats()
  local info   = stats and stats.info or {}

  local lines  = {
    "󰊢 Commit Validation",
    "──────────────────────────────────",
    string.format("  Subject:   %q", subject:sub(1, 60) .. (#subject > 60 and "…" or "")),
    string.format("  Length:    %d/72 %s", stats.total,
      stats.ok and "✅" or "❌ TOO LONG"),
    string.format("  Sweet spot:%s", stats.sweet and "✅ ≤50" or "⚠️  >50 chars"),
  }

  if info.valid then
    table.insert(lines, string.format("  Type:      %s %s",
      info.type, info.known and "✅" or "⚠️ unknown"))
    if info.scope then
      table.insert(lines, string.format("  Scope:     %s", info.scope))
    end
    if info.breaking then
      table.insert(lines, "  ⚠️  BREAKING CHANGE")
    end
    table.insert(lines, string.format("  Desc:      %s",
      info.desc and info.desc:sub(1, 40) or ""))
  else
    table.insert(lines, "  Format:    ❌ " .. (info.error or "invalid"))
  end

  local level = (stats.ok and info.valid and info.known)
    and vim.log.levels.INFO or vim.log.levels.WARN

  vim.notify(table.concat(lines, "\n"), level, { title = "Commit" })
end, "Validate commit")

-- ── Insert co-author ──────────────────────────────────────────────────────────
map("n", "<leader>coa", function()
  vim.ui.input({ prompt = "󰊢 Co-author name: " }, function(name)
    if not name or name == "" then return end
    vim.ui.input({ prompt = "󰊢 Co-author email: " }, function(email)
      if not email or email == "" then return end

      -- Find the end of the commit body (before or at # comments)
      local lines  = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local insert_at = #lines

      for i, line in ipairs(lines) do
        if line:match("^#") then
          insert_at = i - 1
          break
        end
      end

      -- Ensure blank line before trailer
      local prev = lines[insert_at] or ""
      if prev ~= "" then
        vim.api.nvim_buf_set_lines(buf, insert_at, insert_at, false, { "" })
        insert_at = insert_at + 1
      end

      vim.api.nvim_buf_set_lines(buf, insert_at, insert_at, false, {
        "Co-authored-by: " .. name .. " <" .. email .. ">",
      })

      vim.notify("󰊢 Added co-author: " .. name, vim.log.levels.INFO,
        { title = "Commit", timeout = 1200 })
    end)
  end)
end, "Add co-author")

-- ── Breaking change footer ─────────────────────────────────────────────────────
map("n", "<leader>cbr", function()
  local lines     = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local insert_at = #lines

  for i, line in ipairs(lines) do
    if line:match("^#") then
      insert_at = i - 1
      break
    end
  end

  local prev = lines[insert_at] or ""
  if prev ~= "" then
    vim.api.nvim_buf_set_lines(buf, insert_at, insert_at, false, { "" })
    insert_at = insert_at + 1
  end

  vim.api.nvim_buf_set_lines(buf, insert_at, insert_at, false, {
    "BREAKING CHANGE: ",
  })

  vim.api.nvim_win_set_cursor(0, { insert_at + 1, 17 })
  vim.cmd("startinsert!")
end, "Insert BREAKING CHANGE footer")

-- ── Word / character count ────────────────────────────────────────────────────
map("n", "<leader>cw", function()
  local subject = get_subject()
  local lines   = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local body_words = 0
  local in_body    = false

  for _, line in ipairs(lines) do
    if line:match("^#") then break end
    if line == "" and not in_body then
      in_body = true
    elseif in_body then
      for _ in line:gmatch("%S+") do body_words = body_words + 1 end
    end
  end

  local stats = subject_stats()
  vim.notify(
    table.concat({
      "󰊢 Commit Stats",
      "──────────────────────────────────",
      string.format("  Subject length: %d/72 %s",
        stats and stats.total or 0,
        (stats and stats.ok) and "✅" or "❌"),
      string.format("  Body words:     %d", body_words),
      string.format("  Subject:        %s",
        subject:sub(1, 55) .. (#subject > 55 and "…" or "")),
    }, "\n"),
    vim.log.levels.INFO,
    { title = "Commit Stats" }
  )
end, "Commit stats")

-- ── Diff preview ──────────────────────────────────────────────────────────────
map("n", "<leader>cd", function()
  -- Show git diff --stat in a float
  local result = vim.fn.system("git diff --cached --stat 2>/dev/null")
  if vim.v.shell_error ~= 0 or result == "" then
    result = vim.fn.system("git diff --stat 2>/dev/null")
  end

  if result == "" then
    vim.notify("󰊢 No staged changes", vim.log.levels.INFO,
      { title = "Git Diff" })
    return
  end

  -- Show in a floating window
  local lines = vim.split(vim.fn.trim(result), "\n")
  local new_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, lines)
  vim.bo[new_buf].buftype   = "nofile"
  vim.bo[new_buf].filetype  = "diff"

  local width  = math.min(80, math.max(40, vim.o.columns - 10))
  local height = math.min(#lines + 2, 20)
  vim.api.nvim_open_win(new_buf, true, {
    relative = "editor",
    width    = width,
    height   = height,
    col      = math.floor((vim.o.columns - width)  / 2),
    row      = math.floor((vim.o.lines   - height) / 2),
    style    = "minimal",
    border   = "rounded",
    title    = " 󰊢 Staged changes ",
    title_pos= "center",
  })

  -- Close on q
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = new_buf, silent = true })
end, "Preview diff stats")

-- ── Quick conventional prefixes ────────────────────────────────────────────────
local function prepend_type(t)
  return function()
    local line1 = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
    -- If already has a type, replace it
    local new_line = line1:match("^[a-z]+[%(!)]*:%s*.+")
      and line1:gsub("^[a-z]+[%(!)]*:%s*", t .. ": ")
      or t .. ": " .. line1

    vim.api.nvim_buf_set_lines(buf, 0, 1, false, { new_line })
    vim.api.nvim_win_set_cursor(0, { 1, #new_line })
    vim.cmd("startinsert!")
  end
end

map("n", "<leader>cft", prepend_type("feat"),     "Type: feat")
map("n", "<leader>cfx", prepend_type("fix"),      "Type: fix")
map("n", "<leader>cfd", prepend_type("docs"),     "Type: docs")
map("n", "<leader>cfr", prepend_type("refactor"), "Type: refactor")
map("n", "<leader>cfp", prepend_type("perf"),     "Type: perf")
map("n", "<leader>cfc", prepend_type("chore"),    "Type: chore")
map("n", "<leader>cfi", prepend_type("ci"),       "Type: ci")
map("n", "<leader>cfe", prepend_type("test"),     "Type: test")
map("n", "<leader>cfs", prepend_type("style"),    "Type: style")
map("n", "<leader>cfb", prepend_type("build"),    "Type: build")
map("n", "<leader>cfa", prepend_type("ash"),      "Type: ash")
map("n", "<leader>cfw", prepend_type("wip"),      "Type: wip")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 💡 VIRTUAL TEXT — subject length indicator
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local ns = vim.api.nvim_create_namespace("ash_gitcommit")

local function update_subject_hint()
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, 1)
  local subject = get_subject()
  if subject == "" then return end

  local len = #subject
  local ok  = len <= 72
  local sweet = len <= 50

  local text = string.format(" %d/72", len)
  local hl   = ok and (sweet and "Comment" or "DiagnosticWarn")
    or "DiagnosticError"

  vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
    virt_text       = { { text, hl } },
    virt_text_pos   = "right_align",
    priority        = 200,
  })

  -- Also show conventional commit type
  local info = check_conventional(subject)
  if info.valid and info.type then
    local type_icon = GITMOJI[info.type] or "●"
    local type_hl   = info.known and "DiagnosticInfo" or "DiagnosticWarn"
    vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
      sign_text     = type_icon,
      sign_hl_group = type_hl,
      priority      = 10,
    })
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshFtGitcommit_" .. buf, { clear = true })

-- Update subject hint on every change
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave" }, {
  group  = aug,
  buffer = buf,
  callback = function()
    vim.defer_fn(update_subject_hint, 50)
  end,
})

-- Initial hint
vim.defer_fn(update_subject_hint, 100)

-- Warn on close if subject is invalid
vim.api.nvim_create_autocmd("BufWritePre", {
  group  = aug,
  buffer = buf,
  callback = function()
    local subject = get_subject()
    if subject == "" then return end

    local stats = subject_stats()
    if not stats then return end

    if not stats.ok then
      vim.notify(
        string.format(
          "󰊢 ⚠️  Subject too long: %d/72 chars\n%s",
          stats.total,
          subject:sub(1, 72) .. "…"
        ),
        vim.log.levels.WARN,
        { title = "Git Commit" }
      )
    end

    if stats.info and not stats.info.valid and vim.g.ash_strict_commits then
      vim.notify(
        "󰊢 ⚠️  Not a conventional commit:\n" .. (stats.info.error or ""),
        vim.log.levels.WARN,
        { title = "Git Commit" }
      )
    end
  end,
})