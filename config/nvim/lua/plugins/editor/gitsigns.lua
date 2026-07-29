-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🔀 GITSIGNS.NVIM — ULTRA GIT DECORATION ENGINE v5.0 OMEGA               ║
-- ║   Inline diff signs · blame · hunk navigation · staging · word diff            ║
-- ║   Lazyloaded · async · Treesitter-aware · ASH theme-synced sign column        ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 SIGN DEFINITIONS — premium Nerd Font v3 glyphs
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local SIGNS = {
    -- ── Standard signs ────────────────────────────────────────────────────────
    add             = { text = "▎" },
    change          = { text = "▎" },
    delete          = { text = "" },
    topdelete       = { text = "" },
    changedelete    = { text = "▎" },
    untracked       = { text = "▎" },
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎨 HIGHLIGHT SETUP — ASH palette-aware
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Sign column ───────────────────────────────────────────────────────────
    hl(0, "GitSignsAdd",             { fg = "#9ece6a" })
    hl(0, "GitSignsChange",          { fg = "#e0af68" })
    hl(0, "GitSignsDelete",          { fg = "#f38ba8" })
    hl(0, "GitSignsTopdelete",       { fg = "#f38ba8" })
    hl(0, "GitSignsChangedelete",    { fg = "#e0af68" })
    hl(0, "GitSignsUntracked",       { fg = "#7aa2f7" })
  
    -- ── Number column (when numhl = true) ────────────────────────────────────
    hl(0, "GitSignsAddNr",           { link = "GitSignsAdd"      })
    hl(0, "GitSignsChangeNr",        { link = "GitSignsChange"   })
    hl(0, "GitSignsDeleteNr",        { link = "GitSignsDelete"   })
  
    -- ── Line highlight (when linehl = true) ──────────────────────────────────
    hl(0, "GitSignsAddLn",           { link = "DiffAdd"          })
    hl(0, "GitSignsChangeLn",        { link = "DiffChange"       })
    hl(0, "GitSignsDeleteLn",        { link = "DiffDelete"       })
  
    -- ── Inline word diff ──────────────────────────────────────────────────────
    hl(0, "GitSignsAddInline",       { link = "DiffAdd"          })
    hl(0, "GitSignsChangeInline",    { link = "DiffText"         })
    hl(0, "GitSignsDeleteInline",    { link = "DiffDelete"       })
  
    -- ── Preview window ────────────────────────────────────────────────────────
    hl(0, "GitSignsAddPreview",      { link = "DiffAdd"          })
    hl(0, "GitSignsDeletePreview",   { link = "DiffDelete"       })
  
    -- ── Blame virtual text ────────────────────────────────────────────────────
    hl(0, "GitSignsCurrentLineBlame",{ italic = true, link = "Comment" })
    hl(0, "GitSignsCurrentLineBlameNC", { italic = true, link = "Comment" })
  
    -- ── Staged signs (when show_staged = true) ────────────────────────────────
    hl(0, "GitSignsStagedAdd",        { fg = "#9ece6a", italic = true })
    hl(0, "GitSignsStagedChange",     { fg = "#e0af68", italic = true })
    hl(0, "GitSignsStagedDelete",     { fg = "#f38ba8", italic = true })
    hl(0, "GitSignsStagedChangedelete",{ fg = "#e0af68", italic = true })
    hl(0, "GitSignsStagedTopdelete",  { fg = "#f38ba8", italic = true })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.green  then hl(0, "GitSignsAdd",    { fg = p.green  }) end
      if p.yellow then hl(0, "GitSignsChange", { fg = p.yellow }) end
      if p.red    then
        hl(0, "GitSignsDelete",    { fg = p.red })
        hl(0, "GitSignsTopdelete", { fg = p.red })
      end
      if p.blue   then hl(0, "GitSignsUntracked", { fg = p.blue }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 ON_ATTACH — per-buffer keymaps
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function on_attach(bufnr)
    local gs   = require("gitsigns")
    local map  = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, {
        buffer  = bufnr,
        silent  = true,
        noremap = true,
        desc    = "  " .. desc,
      })
    end
  
    -- ── 🧭 Hunk navigation ────────────────────────────────────────────────────
    map("n", "]h", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gs.next_hunk()
      end
    end, "Next hunk")
  
    map("n", "[h", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gs.prev_hunk()
      end
    end, "Prev hunk")
  
    map("n", "]H", function() gs.next_hunk({ preview = true }) end, "Next hunk (preview)")
    map("n", "[H", function() gs.prev_hunk({ preview = true }) end, "Prev hunk (preview)")
  
    -- ── 📋 Staging ────────────────────────────────────────────────────────────
    map({ "n", "v" }, "<leader>ghs", function()
      if vim.fn.mode() == "v" then
        -- Stage selection in visual mode
        local s = vim.api.nvim_buf_get_mark(0, "<")
        local e = vim.api.nvim_buf_get_mark(0, ">")
        gs.stage_hunk({ s[1], e[1] })
      else
        gs.stage_hunk()
      end
    end, "Stage hunk")
  
    map({ "n", "v" }, "<leader>ghu", function()
      if vim.fn.mode() == "v" then
        local s = vim.api.nvim_buf_get_mark(0, "<")
        local e = vim.api.nvim_buf_get_mark(0, ">")
        gs.reset_hunk({ s[1], e[1] })
      else
        gs.reset_hunk()
      end
    end, "Reset hunk")
  
    map("n", "<leader>ghS", gs.stage_buffer,               "Stage buffer")
    map("n", "<leader>ghR", gs.reset_buffer,               "Reset buffer")
    map("n", "<leader>ghu", gs.undo_stage_hunk,            "Undo stage hunk")
    map("n", "<leader>ghU", gs.reset_buffer_index,         "Unstage buffer")
  
    -- ── 🔍 Preview / Diff ─────────────────────────────────────────────────────
    map("n", "<leader>ghp", gs.preview_hunk,               "Preview hunk")
    map("n", "<leader>ghP", gs.preview_hunk_inline,        "Preview hunk inline")
    map("n", "<leader>ghd", gs.diffthis,                   "Diff this (index)")
    map("n", "<leader>ghD", function() gs.diffthis("~")    end, "Diff this (last commit)")
    map("n", "<leader>ghv", function() gs.diffthis("HEAD") end, "Diff this (HEAD)")
  
    -- ── 👁️  Blame ─────────────────────────────────────────────────────────────
    map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame line (full)")
    map("n", "<leader>ghB", gs.toggle_current_line_blame, "Toggle line blame")
  
    -- ── 🔀 Word diff ──────────────────────────────────────────────────────────
    map("n", "<leader>ghw", gs.toggle_word_diff,           "Toggle word diff")
    map("n", "<leader>ghl", gs.toggle_linehl,              "Toggle line highlight")
    map("n", "<leader>ghn", gs.toggle_numhl,               "Toggle number highlight")
    map("n", "<leader>ghi", gs.toggle_signs,               "Toggle signs")
    map("n", "<leader>ghx", gs.toggle_deleted,             "Toggle deleted lines")
    map("n", "<leader>ghX", gs.toggle_signs,               "Toggle all signs")
  
    -- ── 📦 Quickfix / Loclist ─────────────────────────────────────────────────
    map("n", "<leader>ghq", gs.setqflist,                  "Hunks → quickfix")
    map("n", "<leader>ghQ", function()
      gs.setqflist("all")
    end, "All hunks → quickfix")
    map("n", "<leader>ghl", gs.setloclist,                 "Hunks → loclist")
  
    -- ── 📝 Text objects ────────────────────────────────────────────────────────
    map({ "o", "x" }, "ih", gs.select_hunk,               "Select hunk")
    map({ "o", "x" }, "ah", gs.select_hunk,               "Select hunk (around)")
  
    -- ── 🔍 Telescope integration ──────────────────────────────────────────────
    map("n", "<leader>ghf", function()
      require("telescope.builtin").git_bcommits({
        prompt_title = "  Buffer Commits",
      })
    end, "File commit history (telescope)")
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "lewis6991/gitsigns.nvim",
      event = { "BufReadPre", "BufNewFile" },
  
      opts = {
        -- ── Signs ─────────────────────────────────────────────────────────────
        signs               = SIGNS,
        signs_staged        = {
          add           = { text = "▎" },
          change        = { text = "▎" },
          delete        = { text = "" },
          topdelete     = { text = "" },
          changedelete  = { text = "▎" },
          untracked     = { text = "▎" },
        },
        signs_staged_enable = true,
  
        -- ── Sign column options ────────────────────────────────────────────────
        signcolumn      = true,
        numhl           = false,
        linehl          = false,
        word_diff       = false,
        watch_gitdir    = { follow_files = true },
  
        -- ── Auto-attach ────────────────────────────────────────────────────────
        auto_attach     = true,
        attach_to_untracked = false,
  
        -- ── Blame ─────────────────────────────────────────────────────────────
        current_line_blame = false,      -- toggled via <leader>ghB
        current_line_blame_opts = {
          virt_text          = true,
          virt_text_pos      = "eol",
          delay              = 1000,
          ignore_whitespace  = false,
          virt_text_priority = 100,
          use_focus          = true,
        },
        current_line_blame_formatter = function(name, blame_info, _opts)
          if blame_info.author == "Not Committed Yet" then
            return {
              { " 󰊢 Not committed yet", "GitSignsCurrentLineBlame" },
            }
          end
          local date     = blame_info["author_time"]
          local rel_time = os.difftime(os.time(), date)
          local time_str
          if rel_time < 3600 then
            time_str = math.floor(rel_time / 60) .. "m ago"
          elseif rel_time < 86400 then
            time_str = math.floor(rel_time / 3600) .. "h ago"
          elseif rel_time < 2592000 then
            time_str = math.floor(rel_time / 86400) .. "d ago"
          else
            time_str = os.date("%Y-%m-%d", date)
          end
          return {
            { string.format(
                "  %s • %s • %s",
                blame_info.author == name and "You" or blame_info.author,
                blame_info.summary:sub(1, 50),
                time_str
              ),
              "GitSignsCurrentLineBlame" },
          }
        end,
  
        -- ── Sign priority ──────────────────────────────────────────────────────
        sign_priority   = 6,
  
        -- ── Update debounce ────────────────────────────────────────────────────
        update_debounce = 100,
  
        -- ── Status column ─────────────────────────────────────────────────────
        status_formatter = nil,
        max_file_length  = 40000,    -- lines; disable for huge files
  
        -- ── Preview window ────────────────────────────────────────────────────
        preview_config   = {
          border   = "rounded",
          style    = "minimal",
          relative = "cursor",
          row      = 0,
          col      = 1,
        },
  
        -- ── Diff algorithm ────────────────────────────────────────────────────
        diff_opts = {
          algorithm       = "histogram",
          internal        = true,
          indent_heuristic= true,
          linematch       = 60,
        },
  
        -- ── Trouble integration ────────────────────────────────────────────────
        trouble         = true,
  
        -- ── Per-buffer keymaps ─────────────────────────────────────────────────
        on_attach       = on_attach,
      },
  
      config = function(_, opts)
        require("gitsigns").setup(opts)
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshGitsigns", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            -- Refresh gitsigns rendering in all attached buffers
            vim.cmd("GitSignsDetachAll")
            vim.defer_fn(function()
              for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(buf) then
                  pcall(require("gitsigns").attach, buf)
                end
              end
            end, 200)
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify("  Gitsigns loaded", vim.log.levels.DEBUG, { title = "ASH Gitsigns" })
        end
      end,
    },
  }