-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       💬 COMMENT.NVIM — ULTRA SMART COMMENTER v5.0 OMEGA                       ║
-- ║   Treesitter-aware · embedded language support · custom operators               ║
-- ║   ASH config syntax · todo-integration · dot-repeat · 60+ filetypes            ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗣️  FILETYPE COMMENT STRINGS — for languages not detected by ts-comment-string
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local COMMENT_STRINGS = {
    -- ASH dotfile formats
    hypr         = "# %s",
    rasi         = "// %s",
    fish         = "# %s",
    kdl          = "// %s",
    conf         = "# %s",
    ini          = "; %s",
    dosini       = "; %s",
    properties   = "# %s",
  
    -- Web
    astro        = "<!-- %s -->",
    svelte       = "<!-- %s -->",
    vue          = "<!-- %s -->",
    html         = "<!-- %s -->",
    handlebars   = "{{!-- %s --}}",
    hbs          = "{{!-- %s --}}",
    heex         = "<%!-- %s --%>",
    htmldjango   = "{# %s #}",
    jinja        = "{# %s #}",
    twig         = "{# %s #}",
    liquid       = "{% comment %} %s {% endcomment %}",
    css          = "/* %s */",
    scss         = "// %s",
    less         = "// %s",
  
    -- Query / Config
    graphql      = "# %s",
    prisma       = "// %s",
    terraform    = "# %s",
    hcl          = "# %s",
    nix          = "# %s",
    nickel       = "# %s",
    dhall        = "--| %s",
    cabal        = "-- %s",
    ron          = "// %s",
    jsonc        = "// %s",
    toml         = "# %s",
  
    -- Shells
    sh           = "# %s",
    bash         = "# %s",
    zsh          = "# %s",
    awk          = "# %s",
    tcl          = "# %s",
    perl         = "# %s",
    ruby         = "# %s",
    python       = "# %s",
    r            = "# %s",
    julia        = "# %s",
  
    -- System
    c            = "// %s",
    cpp          = "// %s",
    cuda         = "// %s",
    glsl         = "// %s",
    wgsl         = "// %s",
    hlsl         = "// %s",
    zig          = "// %s",
    odin         = "// %s",
    carbon       = "// %s",
  
    -- Functional
    haskell      = "-- %s",
    elm          = "-- %s",
    purescript   = "-- %s",
    fsharp       = "// %s",
    ocaml        = "(* %s *)",
    reason       = "// %s",
    sml          = "(* %s *)",
    erlang       = "%% %s",
  
    -- Markup
    markdown     = "<!-- %s -->",
    rst          = ".. %s",
    tex          = "% %s",
    latex        = "% %s",
    org          = "# %s",
    neorg        = "% %s",
    asciidoc     = "// %s",
  
    -- Data
    sql          = "-- %s",
    mysql        = "-- %s",
    plpgsql      = "-- %s",
    yaml         = "# %s",
    xml          = "<!-- %s -->",
    csv          = "# %s",
  
    -- Misc
    vim          = '" %s',
    vimscript    = '" %s',
    proto        = "// %s",
    thrift       = "// %s",
    solidity     = "// %s",
    move         = "// %s",
    gleam        = "// %s",
    elixir       = "# %s",
    ex           = "# %s",
    exs          = "# %s",
    swift        = "// %s",
    kotlin       = "// %s",
    scala        = "// %s",
    groovy       = "// %s",
    dart         = "// %s",
    v            = "// %s",
    nim          = "# %s",
    crystal      = "# %s",
    d            = "// %s",
    ada          = "-- %s",
    fortran      = "! %s",
    cobol        = "      * %s",
    pascal       = "{ %s }",
    delphi       = "// %s",
    lisp         = "; %s",
    scheme       = "; %s",
    clojure      = "; %s",
    fennel       = "; %s",
    racket       = "; %s",
    janet        = "# %s",
    carp         = "; %s",
    smalltalk    = '"  %s "',
    apl          = "⍝ %s",
    q            = "/ %s",
    j            = "NB. %s",
    matlab       = "%% %s",
    octave       = "%% %s",
    mathematica  = "(* %s *)",
    dockerfile   = "# %s",
    makefile     = "# %s",
    cmake        = "# %s",
    meson        = "# %s",
    bazel        = "# %s",
    starlark     = "# %s",
    nginx        = "# %s",
    apache       = "# %s",
    gitconfig    = "# %s",
    gitignore    = "# %s",
    gitattributes= "# %s",
    ssh_config   = "# %s",
    passwd       = "# %s",
    fstab        = "# %s",
    crontab      = "# %s",
    hosts        = "# %s",
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 TODO ANNOTATION INJECTORS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  --- Insert an annotated comment at end of current line
  ---@param tag  string   e.g. "TODO", "FIXME", "HACK", "NOTE", "PERF", "WARN"
  ---@param icon string   emoji prefix
  local function insert_annotation(tag, icon)
    return function()
      local api    = require("Comment.api")
      local ok, cfg = pcall(require, "Comment.config")
  
      -- Get the commentstring for the current buffer
      local cs     = vim.bo.commentstring
      if cs == "" then cs = "# %s" end
  
      local lnum   = vim.api.nvim_win_get_cursor(0)[1]
      local indent = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
                       :match("^(%s*)")
  
      local body   = string.format("%s %s(%s): ", icon, tag, vim.env.USER or "ash")
      local text   = cs:format(body)
      local full   = indent .. text
  
      -- Insert new line below, then enter insert mode at end
      vim.api.nvim_buf_set_lines(0, lnum, lnum, false, { full })
      vim.api.nvim_win_set_cursor(0, { lnum + 1, #full })
      vim.cmd("startinsert!")
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔌 EXTRA OPERATORS — extend Comment.nvim with custom motions
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function setup_extra_keymaps()
    local api = require("Comment.api")
  
    -- ── Annotation shortcuts ────────────────────────────────────────────────────
    local annotations = {
      { "<leader>ct",  "TODO",  "✅",  "Insert TODO comment"  },
      { "<leader>cf",  "FIXME", "🐛",  "Insert FIXME comment" },
      { "<leader>ch",  "HACK",  "⚡",  "Insert HACK comment"  },
      { "<leader>cn",  "NOTE",  "📝",  "Insert NOTE comment"  },
      { "<leader>cp",  "PERF",  "🚀",  "Insert PERF comment"  },
      { "<leader>cw",  "WARN",  "⚠️ ", "Insert WARN comment"  },
      { "<leader>cd",  "DOCS",  "📖",  "Insert DOCS comment"  },
      { "<leader>cz",  "ASH",   "🔥",  "Insert ASH comment"   },
    }
  
    for _, ann in ipairs(annotations) do
      local lhs, tag, icon, desc = ann[1], ann[2], ann[3], ann[4]
      vim.keymap.set("n", lhs, insert_annotation(tag, icon), {
        desc   = "💬 " .. desc,
        silent = true,
      })
    end
  
    -- ── Toggle comment on current line (faster than gcc in normal mode) ────────
    vim.keymap.set("n", "<C-/>",
      api.toggle.linewise.current,
      { desc = "💬 Toggle line comment", silent = true, noremap = true })
  
    vim.keymap.set("i", "<C-/>",
      function()
        -- Exit insert, toggle, re-enter insert at end of line
        vim.cmd("stopinsert")
        api.toggle.linewise.current()
      end,
      { desc = "💬 Toggle comment (insert)", silent = true, noremap = true })
  
    vim.keymap.set("v", "<C-/>",
      "<Plug>(comment_toggle_linewise_visual)",
      { desc = "💬 Toggle comment (visual)", silent = true })
  
    -- ── Block-comment visual selection ─────────────────────────────────────────
    vim.keymap.set("v", "gb",
      "<Plug>(comment_toggle_blockwise_visual)",
      { desc = "💬 Toggle block comment (visual)" })
  
    -- ── Duplicate-and-comment (yank, paste below, comment original) ────────────
    vim.keymap.set("n", "<leader>cy",
      function()
        local lnum = vim.api.nvim_win_get_cursor(0)[1]
        local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
        -- Yank current line
        vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { line, line })
        -- Comment the original (now at lnum - 1)
        vim.api.nvim_win_set_cursor(0, { lnum, 0 })
        api.toggle.linewise.current()
        -- Move cursor to the duplicate below
        vim.api.nvim_win_set_cursor(0, { lnum + 1, 0 })
      end,
      { desc = "💬 Duplicate & comment line", silent = true }
    )
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "numToStr/Comment.nvim",
      event = { "BufReadPre", "BufNewFile" },
      dependencies = {
        -- Treesitter-powered commentstring (handles embedded languages)
        {
          "JoosepAlviste/nvim-ts-context-commentstring",
          lazy = true,
          opts = {
            enable_autocmd = false, -- we call the hook manually
            languages      = COMMENT_STRINGS,
          },
        },
      },
  
      -- ── Keys (declarative, for which-key registration) ───────────────────────
      keys = {
        -- Normal mode: line / block
        { "gcc",        mode = "n", desc = "💬 Toggle line comment"     },
        { "gbc",        mode = "n", desc = "💬 Toggle block comment"    },
        { "gcO",        mode = "n", desc = "💬 Add comment above"       },
        { "gco",        mode = "n", desc = "💬 Add comment below"       },
        { "gcA",        mode = "n", desc = "💬 Add comment at EOL"      },
        -- Visual mode
        { "gc",         mode = "v", desc = "💬 Toggle line comment"     },
        { "gb",         mode = "v", desc = "💬 Toggle block comment"    },
        -- Count support: 3gcc → comment 3 lines
        { "gc",         mode = "n", desc = "💬 Line comment (operator)" },
        { "gb",         mode = "n", desc = "💬 Block comment (operator)"},
        -- ASH annotations
        { "<leader>ct", mode = "n", desc = "💬 TODO comment"            },
        { "<leader>cf", mode = "n", desc = "💬 FIXME comment"           },
        { "<leader>ch", mode = "n", desc = "💬 HACK comment"            },
        { "<leader>cn", mode = "n", desc = "💬 NOTE comment"            },
        { "<leader>cp", mode = "n", desc = "💬 PERF comment"            },
        { "<leader>cw", mode = "n", desc = "💬 WARN comment"            },
        { "<leader>cd", mode = "n", desc = "💬 DOCS comment"            },
        { "<leader>cz", mode = "n", desc = "💬 ASH comment"             },
        { "<leader>cy", mode = "n", desc = "💬 Duplicate & comment"     },
        -- Quick toggle
        { "<C-/>",      mode = { "n", "i", "v" }, desc = "💬 Toggle comment" },
      },
  
      opts = {
        -- ── Mappings ─────────────────────────────────────────────────────────
        toggler = {
          line  = "gcc",   -- toggle line comment
          block = "gbc",   -- toggle block comment
        },
        opleader = {
          line  = "gc",    -- line comment operator
          block = "gb",    -- block comment operator
        },
        extra = {
          above = "gcO",   -- insert comment line above
          below = "gco",   -- insert comment line below
          eol   = "gcA",   -- append comment at end of line
        },
  
        -- ── Behaviour ─────────────────────────────────────────────────────────
        -- Pad the comment delimiter with a space
        padding = true,
  
        -- Enable sticky cursor after commenting (cursor stays on same line)
        sticky  = true,
  
        -- Ignore blank lines during line-wise motions
        ignore  = "^$",
  
        -- ── Hooks — integrate ts-context-commentstring ────────────────────────
        pre_hook = function(ctx)
          -- Use ts-context-commentstring to get the correct commentstring
          -- for embedded languages (e.g., JS inside <script> in HTML)
          local ok, ts_ctx = pcall(require, "ts_context_commentstring.integrations.comment_nvim")
          if ok then
            return ts_ctx.create_pre_hook()(ctx)
          end
        end,
  
        post_hook = function(ctx)
          -- Optional: flash the commented region using Snacks / notify
          if vim.g.ash_comment_flash and ctx.range then
            local ok, snacks = pcall(require, "snacks")
            if ok and snacks.animate then
              -- Brief highlight flash on the commented lines
              local ns = vim.api.nvim_create_namespace("ash_comment_flash")
              local start_line = ctx.range.srow - 1
              local end_line   = ctx.range.erow - 1
              for ln = start_line, end_line do
                vim.api.nvim_buf_add_highlight(0, ns, "Search", ln, 0, -1)
              end
              vim.defer_fn(function()
                vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
              end, 250)
            end
          end
        end,
      },
  
      config = function(_, opts)
        require("Comment").setup(opts)
  
        -- Register extra keymaps (annotations, C-/, duplicate-comment)
        setup_extra_keymaps()
  
        -- ── Filetype overrides: set commentstring for custom filetypes ────────
        local aug = vim.api.nvim_create_augroup("AshComment", { clear = true })
        vim.api.nvim_create_autocmd("FileType", {
          group    = aug,
          callback = function(ev)
            local ft = vim.bo[ev.buf].filetype
            local cs = COMMENT_STRINGS[ft]
            if cs then
              vim.bo[ev.buf].commentstring = cs
            end
          end,
        })
  
        -- ── ASH hot-reload: flash toggle when theme changes ──────────────────
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            -- Enable flash effect after theme switch for 5 seconds then restore
            local prev = vim.g.ash_comment_flash
            vim.g.ash_comment_flash = true
            vim.defer_fn(function()
              vim.g.ash_comment_flash = prev
            end, 5000)
          end,
        })
  
        -- Debug indicator
        if vim.g.ash_debug then
          vim.notify(
            "💬 Comment.nvim loaded — ts-context-commentstring active",
            vim.log.levels.DEBUG,
            { title = "ASH Comment" }
          )
        end
      end,
    },
  }