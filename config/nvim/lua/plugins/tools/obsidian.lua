-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🔮 OBSIDIAN — ULTRA KNOWLEDGE BASE v5.0 OMEGA                            ║
-- ║   Vault management · daily notes · templates · backlinks · tags               ║
-- ║   search · graph · canvas · Telescope integration · ASH theme-synced          ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Note links ────────────────────────────────────────────────────────────
    hl(0, "ObsidianTodo",          { bold = true,   fg = "#f9e2af" })
    hl(0, "ObsidianDone",          { bold = true,   fg = "#9ece6a" })
    hl(0, "ObsidianRightArrow",    { bold = true,   fg = "#fab387" })
    hl(0, "ObsidianTilde",         { bold = true,   fg = "#f38ba8" })
    hl(0, "ObsidianImportant",     { bold = true,   fg = "#f38ba8" })
    hl(0, "ObsidianBullet",        { bold = true,   fg = "#89b4fa" })
  
    -- ── Internal links ────────────────────────────────────────────────────────
    hl(0, "ObsidianRef",           { underline = true, fg = "#89b4fa" })
    hl(0, "ObsidianExtLinkIcon",   { fg = "#89b4fa"                   })
    hl(0, "ObsidianTag",           {
      italic    = true,
      bold      = false,
      fg        = "#cba6f7",
    })
    hl(0, "ObsidianBlockID",       { italic = true, fg = "#9399b2"    })
    hl(0, "ObsidianHighlightText", {
      bold   = false,
      bg     = "#2d2a1e",
      fg     = "#f9e2af",
    })
  
    -- ── Timestamp ─────────────────────────────────────────────────────────────
    hl(0, "ObsidianDate",          { italic = true, fg = "#7dcfff"    })
  
    -- ── Frontmatter ───────────────────────────────────────────────────────────
    hl(0, "ObsidianFrontMatterKey",{ bold = true,   fg = "#89b4fa"    })
    hl(0, "ObsidianFrontMatterValue",{ fg = "#a6e3a1"                 })
  
    -- ── Callout notes ─────────────────────────────────────────────────────────
    hl(0, "ObsidianCalloutNote",   { bold = true,   fg = "#89b4fa"    })
    hl(0, "ObsidianCalloutInfo",   { bold = true,   fg = "#89b4fa"    })
    hl(0, "ObsidianCalloutTip",    { bold = true,   fg = "#9ece6a"    })
    hl(0, "ObsidianCalloutWarn",   { bold = true,   fg = "#f9e2af"    })
    hl(0, "ObsidianCalloutDanger", { bold = true,   fg = "#f38ba8"    })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.yellow then
        hl(0, "ObsidianTodo",          { bold = true, fg = p.yellow })
        hl(0, "ObsidianHighlightText", { bg = p.surface0 or "#2d2a1e", fg = p.yellow })
      end
      if p.green  then hl(0, "ObsidianDone",       { bold = true, fg = p.green  }) end
      if p.red    then
        hl(0, "ObsidianImportant",     { bold = true, fg = p.red })
        hl(0, "ObsidianTilde",         { bold = true, fg = p.red })
      end
      if p.blue   then
        hl(0, "ObsidianRef",           { underline = true, fg = p.blue })
        hl(0, "ObsidianBullet",        { bold = true,      fg = p.blue })
        hl(0, "ObsidianFrontMatterKey",{ bold = true,      fg = p.blue })
      end
      if p.mauve  then hl(0, "ObsidianTag", { italic = true, fg = p.mauve }) end
      if p.green  then hl(0, "ObsidianFrontMatterValue", { fg = p.green   }) end
      if p.cyan   then hl(0, "ObsidianDate",             { italic = true, fg = p.cyan }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 VAULT CONFIGURATION
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local HOME       = os.getenv("HOME") or vim.fn.expand("~")
  local VAULT_DIR  = HOME .. "/Notes/vault"
  local VAULT_DIRS = {
    { path = VAULT_DIR,           label = "🔮 Main Vault"    },
    { path = HOME .. "/Work",     label = "💼 Work Notes"    },
    { path = HOME .. "/Projects", label = "🚀 Projects"      },
  }
  
  local function get_current_vault()
    local buf_path = vim.api.nvim_buf_get_name(0)
    for _, v in ipairs(VAULT_DIRS) do
      if buf_path:find(v.path, 1, true) then
        return v
      end
    end
    return VAULT_DIRS[1]
  end
  
  -- Smart note create: prompt for title and template
  local function new_note_smart()
    local ok, obsidian = pcall(require, "obsidian")
    if not ok then return end
  
    vim.ui.input({ prompt = "🔮 Note title: " }, function(title)
      if not title or title == "" then return end
  
      -- Choose template
      local templates = {
        "Default",
        "Daily Note",
        "Meeting",
        "Project",
        "Research",
        "Person",
      }
  
      vim.ui.select(templates, { prompt = "🔮 Template: " }, function(tmpl)
        local cmd = "ObsidianNew " .. title
        vim.cmd(cmd)
      end)
    end)
  end
  
  -- Quick capture: append to inbox
  local function quick_capture()
    vim.ui.input({ prompt = "🔮 Capture: " }, function(text)
      if not text or text == "" then return end
  
      local inbox = VAULT_DIR .. "/Inbox/inbox.md"
      local timestamp = os.date("%Y-%m-%d %H:%M")
      local line = string.format("- [ ] %s <!-- %s -->", text, timestamp)
  
      -- Ensure inbox exists
      if vim.fn.filereadable(inbox) == 0 then
        local dir = vim.fn.fnamemodify(inbox, ":h")
        vim.fn.mkdir(dir, "p")
        local f = io.open(inbox, "w")
        if f then
          f:write("# 📥 Inbox\n\n")
          f:close()
        end
      end
  
      -- Append to inbox
      local f = io.open(inbox, "a")
      if f then
        f:write(line .. "\n")
        f:close()
        vim.notify(
          "🔮 Captured: " .. text,
          vim.log.levels.INFO,
          { title = "Obsidian", timeout = 1500 }
        )
      end
    end)
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "epwalsh/obsidian.nvim",
      version      = "*",
      lazy         = true,
      ft           = "markdown",
      event        = {
        "BufReadPre " .. VAULT_DIR .. "/**.md",
        "BufNewFile "  .. VAULT_DIR .. "/**.md",
      },
      dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-telescope/telescope.nvim", optional = true },
        { "hrsh7th/nvim-cmp",             optional = true },
        { "nvim-treesitter/nvim-treesitter", optional = true },
      },
  
      keys = {
        -- ── Core operations ───────────────────────────────────────────────────
        { "<leader>on",  new_note_smart,                     desc = "🔮 Obsidian: New note"         },
        { "<leader>oN",  "<cmd>ObsidianNew<cr>",             desc = "🔮 Obsidian: New (quick)"      },
        { "<leader>oc",  quick_capture,                      desc = "🔮 Obsidian: Capture to inbox" },
        { "<leader>od",  "<cmd>ObsidianToday<cr>",           desc = "🔮 Obsidian: Daily note"       },
        { "<leader>oy",  "<cmd>ObsidianYesterday<cr>",       desc = "🔮 Obsidian: Yesterday"        },
        { "<leader>otm", "<cmd>ObsidianTomorrow<cr>",        desc = "🔮 Obsidian: Tomorrow"         },
  
        -- ── Navigation ────────────────────────────────────────────────────────
        { "<leader>oo",  "<cmd>ObsidianOpen<cr>",            desc = "🔮 Obsidian: Open in app"      },
        { "<leader>of",  "<cmd>ObsidianQuickSwitch<cr>",     desc = "🔮 Obsidian: Quick switch"     },
        { "<leader>os",  "<cmd>ObsidianSearch<cr>",          desc = "🔮 Obsidian: Search"           },
        { "<leader>oF",  "<cmd>ObsidianFollowLink<cr>",      desc = "🔮 Obsidian: Follow link"      },
        { "<leader>ob",  "<cmd>ObsidianBacklinks<cr>",       desc = "🔮 Obsidian: Backlinks"        },
        { "<leader>ot",  "<cmd>ObsidianTags<cr>",            desc = "🔮 Obsidian: Tags"             },
        { "<leader>ol",  "<cmd>ObsidianLinks<cr>",           desc = "🔮 Obsidian: Links in note"    },
        { "<leader>og",  "<cmd>ObsidianLinkNew<cr>", mode = "v", desc = "🔮 Obsidian: Link (visual)" },
  
        -- ── Templates ─────────────────────────────────────────────────────────
        { "<leader>oT",  "<cmd>ObsidianTemplate<cr>",        desc = "🔮 Obsidian: Insert template"  },
  
        -- ── Workspace ─────────────────────────────────────────────────────────
        { "<leader>ow",  "<cmd>ObsidianWorkspace<cr>",       desc = "🔮 Obsidian: Switch workspace" },
  
        -- ── Paste image ───────────────────────────────────────────────────────
        { "<leader>opi", "<cmd>ObsidianPasteImg<cr>",        desc = "🔮 Obsidian: Paste image"      },
  
        -- ── Rename ────────────────────────────────────────────────────────────
        { "<leader>or",  "<cmd>ObsidianRename<cr>",          desc = "🔮 Obsidian: Rename note"      },
  
        -- ── Extras ────────────────────────────────────────────────────────────
        { "<leader>ox",  "<cmd>ObsidianExtractNote<cr>", mode = "v", desc = "🔮 Obsidian: Extract to note" },
        {
          "<leader>oi",
          function()
            local vault = get_current_vault()
            local all_notes = vim.fn.systemlist("find " .. vim.fn.shellescape(vault.path) .. " -name '*.md' | wc -l 2>/dev/null")
            local count    = vim.v.shell_error == 0 and (all_notes[1] or "?") or "?"
            vim.notify(
              table.concat({
                "🔮 Obsidian Info",
                "──────────────────────────────────",
                string.format("  Vault:  %s", vault.label),
                string.format("  Path:   %s", vault.path),
                string.format("  Notes:  %s", vim.fn.trim(count)),
                string.format("  App:    %s", vim.fn.executable("obsidian") == 1 and "✅" or "⭕"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "Obsidian" }
            )
          end,
          desc = "🔮 Obsidian: Info",
        },
      },
  
      opts = {
        -- ── Workspaces ─────────────────────────────────────────────────────────
        workspaces = (function()
          local ws = {}
          for _, v in ipairs(VAULT_DIRS) do
            if vim.fn.isdirectory(v.path) == 1 then
              table.insert(ws, { name = v.label, path = v.path })
            end
          end
          if #ws == 0 then
            vim.fn.mkdir(VAULT_DIR, "p")
            table.insert(ws, { name = "🔮 Main Vault", path = VAULT_DIR })
          end
          return ws
        end)(),
  
        -- ── Daily notes ────────────────────────────────────────────────────────
        daily_notes = {
          folder        = "Daily",
          date_format   = "%Y-%m-%d",
          alias_format  = "%B %-d, %Y",
          template      = "daily_note.md",
          default_tags  = { "daily" },
        },
  
        -- ── Completion ─────────────────────────────────────────────────────────
        completion = {
          nvim_cmp         = true,
          min_chars        = 2,
          wiki_link_func   = "use_alias_only",
        },
  
        -- ── Note ID function ───────────────────────────────────────────────────
        note_id_func = function(title)
          local suffix = ""
          if title ~= nil then
            suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
          else
            for _ = 1, 4 do
              suffix = suffix .. string.char(math.random(65, 90))
            end
          end
          return tostring(os.time()) .. "-" .. suffix
        end,
  
        -- ── Note path function ─────────────────────────────────────────────────
        note_path_func = function(spec)
          local path = spec.dir / tostring(spec.id)
          return path:with_suffix(".md")
        end,
  
        -- ── Wiki links ─────────────────────────────────────────────────────────
        wiki_link_func = function(opts)
          if opts.id == nil then
            return string.format("[[%s]]", opts.label)
          elseif opts.label ~= opts.id then
            return string.format("[[%s|%s]]", opts.id, opts.label)
          else
            return string.format("[[%s]]", opts.id)
          end
        end,
  
        -- ── Markdown links ─────────────────────────────────────────────────────
        markdown_link_func = function(opts)
          return string.format("[%s](%s)", opts.label, opts.path)
        end,
  
        -- ── Preferred link style ───────────────────────────────────────────────
        preferred_link_style = "wiki",
  
        -- ── Picker ─────────────────────────────────────────────────────────────
        picker = {
          name    = "telescope.nvim",
          note_mappings = {
            new   = "<C-x>",
            insert_link = "<C-l>",
          },
          tag_mappings = {
            tag_note   = "<C-x>",
            insert_tag = "<C-l>",
          },
        },
  
        -- ── Sort ──────────────────────────────────────────────────────────────
        sort_by           = "modified",
        sort_reversed     = true,
        search_max_lines  = 1000,
        open_notes_in     = "current",
  
        -- ── UI ────────────────────────────────────────────────────────────────
        ui = {
          enable         = true,
          update_debounce= 200,
          max_file_length= 5000,
          checkboxes     = {
            [" "] = { char = "󰄱",  hl_group = "ObsidianTodo"        },
            ["x"] = { char = "",  hl_group = "ObsidianDone"         },
            [">"] = { char = "",  hl_group = "ObsidianRightArrow"   },
            ["~"] = { char = "󰰱",  hl_group = "ObsidianTilde"       },
            ["!"] = { char = "",  hl_group = "ObsidianImportant"   },
          },
          bullets = {
            char     = "•",
            hl_group = "ObsidianBullet",
          },
          external_link_icon = {
            char     = "",
            hl_group = "ObsidianExtLinkIcon",
          },
          reference_text = {
            hl_group = "ObsidianRef",
          },
          highlight_text = {
            hl_group = "ObsidianHighlightText",
          },
          tags = {
            hl_group = "ObsidianTag",
          },
          block_ids = {
            hl_group = "ObsidianBlockID",
          },
          hl_groups = {
            ObsidianTodo          = { bold = true,   fg = "#f9e2af" },
            ObsidianDone          = { bold = true,   fg = "#9ece6a" },
            ObsidianRightArrow    = { bold = true,   fg = "#fab387" },
            ObsidianTilde         = { bold = true,   fg = "#f38ba8" },
            ObsidianImportant     = { bold = true,   fg = "#f38ba8" },
            ObsidianBullet        = { bold = true,   fg = "#89b4fa" },
            ObsidianRef           = { underline = true, fg = "#89b4fa" },
            ObsidianExtLinkIcon   = { fg = "#89b4fa"                   },
            ObsidianTag           = { italic = true, fg = "#cba6f7"    },
            ObsidianBlockID       = { italic = true, fg = "#9399b2"    },
            ObsidianHighlightText = { bg = "#2d2a1e", fg = "#f9e2af"   },
          },
        },
  
        -- ── Attachments ────────────────────────────────────────────────────────
        attachments = {
          img_folder          = "assets/images",
          img_name_func       = function()
            return string.format("%s-", os.date("%Y%m%d%H%M%S"))
          end,
          img_text_func       = function(client, path)
            local link_path
            local vault_relative = client:vault_relative_path(path)
            link_path = vault_relative and ("/" .. tostring(vault_relative)) or tostring(path)
            return string.format("![%s](%s)", path.name, link_path)
          end,
        },
  
        -- ── Templates ─────────────────────────────────────────────────────────
        templates = {
          folder            = "Templates",
          date_format       = "%Y-%m-%d",
          time_format       = "%H:%M",
          substitutions     = {
            yesterday = function()
              return os.date("%Y-%m-%d", os.time() - 86400)
            end,
            tomorrow = function()
              return os.date("%Y-%m-%d", os.time() + 86400)
            end,
          },
        },
  
        -- ── Note frontmatter function ──────────────────────────────────────────
        note_frontmatter_func = function(note)
          if note.title then
            note:add_alias(note.title)
          end
          local out = {
            id       = note.id,
            aliases  = note.aliases,
            tags     = note.tags,
            created  = os.date("%Y-%m-%d"),
            modified = os.date("%Y-%m-%d"),
          }
          if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
            for k, v in pairs(note.metadata) do
              out[k] = v
            end
          end
          return out
        end,
  
        -- ── Callbacks ─────────────────────────────────────────────────────────
        callbacks = {
          post_setup       = function(_) end,
          enter_note       = function(_, note)
            -- Set spell check when entering a note
            vim.opt_local.spell    = true
            vim.opt_local.spelllang= "en_us"
            if vim.g.ash_debug then
              vim.notify("🔮 " .. note.id, vim.log.levels.DEBUG, { title = "Obsidian" })
            end
          end,
          leave_note       = function(_, _) end,
          pre_write_note   = function(_, note)
            -- Update modified date in frontmatter
            note.metadata = note.metadata or {}
            note.metadata.modified = os.date("%Y-%m-%d")
          end,
          post_set_workspace = function(_, workspace)
            vim.notify(
              "🔮 Switched to: " .. workspace.name,
              vim.log.levels.INFO,
              { title = "Obsidian", timeout = 1200 }
            )
          end,
        },
  
        -- ── Follow URL ─────────────────────────────────────────────────────────
        follow_url_func = function(url)
          local open_cmd = vim.fn.has("mac") == 1 and "open"
            or (vim.fn.executable("xdg-open") == 1 and "xdg-open" or "start")
          vim.fn.jobstart({ open_cmd, url })
        end,
  
        -- ── Image namespacing ─────────────────────────────────────────────────
        image_name_func = function()
          return string.format("Pasted-%s", os.date("%Y%m%d-%H%M%S"))
        end,
  
        -- ── Disable for non-vault files ────────────────────────────────────────
        disable_frontmatter = function(fname)
          return fname:match("_templates") ~= nil
        end,
      },
  
      config = function(_, opts)
        require("obsidian").setup(opts)
  
        setup_highlights()
  
        -- ── nvim-cmp source ────────────────────────────────────────────────────
        local ok_cmp, cmp = pcall(require, "cmp")
        if ok_cmp then
          cmp.setup.filetype("markdown", {
            sources = cmp.config.sources({
              { name = "obsidian",         priority = 1200 },
              { name = "obsidian_new",     priority = 1100 },
              { name = "obsidian_tags",    priority = 1000 },
              { name = "buffer",           priority = 500  },
              { name = "path",             priority = 400  },
              { name = "spell",            priority = 300  },
              { name = "emoji",            priority = 200  },
            }),
          })
        end
  
        local aug = vim.api.nvim_create_augroup("AshObsidian", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🔮 Obsidian highlights synced", vim.log.levels.INFO,
              { title = "ASH Obsidian", timeout = 1200 })
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            string.format("🔮 Obsidian loaded — vault: %s", VAULT_DIR),
            vim.log.levels.DEBUG,
            { title = "ASH Obsidian" }
          )
        end
      end,
    },
  }