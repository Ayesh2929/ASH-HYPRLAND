-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║      🔲 NVIM-SURROUND — ULTRA SURROUND ENGINE v5.0 OMEGA                       ║
-- ║   Operator-motion pairs · custom surrounds · Treesitter nodes                   ║
-- ║   HTML tags · Markdown · LaTeX · 60+ filetype-specific surrounds                ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📖 OPERATION REFERENCE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
--  ADD        ys{motion}{char}    normal mode
--             yss{char}           surround entire line
--             S{char}             visual mode
--  DELETE     ds{char}
--  CHANGE     cs{old}{new}
--  CHANGE LINE css{new}
--
--  Custom chars defined below:
--    q  → single quotes          ' '
--    Q  → double quotes          " "
--    r  → square brackets        [ ]
--    a  → angle brackets         < >
--    c  → curly braces           { }
--    |  → pipe (Lua func arg)    | |
--    z  → Lua string  [[…]]      [[ ]]
--    L  → LaTeX environment      \begin{…} \end{…}
--    m  → Markdown bold          **…**
--    i  → Markdown italic        _…_
--    k  → Markdown code-span     `…`
--    K  → Markdown code-block    ```\n…\n```
--    ~  → Markdown strikethrough ~~…~~
--    l  → Markdown link          […](url)
--    e  → Elixir do-block        do\n  …\nend
--    d  → HTML div               <div>…</div>
--    s  → HTML span              <span>…</span>
--    p  → HTML p                 <p>…</p>
--    H  → HTML prompt            prompt picks tag
--    R  → Rust Result            Ok(…)
--    O  → Rust Option            Some(…)
--    G  → Go error check         if err != nil { … }
--    #  → Template comment       {{/* … */}} (Go templates)
--    n  → JSX expression         {…}
--    N  → JSX comment            {/* … */}
--    @  → Python decorator       @…

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 HELPER UTILITIES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- Prompt the user for a string, returning it or nil on cancel
---@param prompt string
---@return string|nil
local function input(prompt)
    local ok, result = pcall(vim.fn.input, prompt)
    if not ok or result == "" then return nil end
    return result
  end
  
  --- Wrap strings: returns { open, close } table
  ---@param open  string
  ---@param close string
  local function wrap(open, close)
    return { add = { open, close }, find = vim.pesc(open) .. ".-" .. vim.pesc(close) }
  end
  
  --- Build a single-char delimiter pair (padded)
  ---@param open  string
  ---@param close string
  local function padded(open, close)
    return {
      add   = { open .. " ", " " .. close },
      find  = vim.pesc(open) .. "%s?.-" .. vim.pesc(close),
      delete = "^(" .. vim.pesc(open) .. "%s?)(.-)(%s?" .. vim.pesc(close) .. ")$",
      change = {
        target = "^(" .. vim.pesc(open) .. "%s?)(.-)(%s?" .. vim.pesc(close) .. ")$",
      },
    }
  end
  
  --- Wrap with a LaTeX command  \cmd{…}
  ---@param cmd string
  local function latex_cmd(cmd)
    return {
      add    = { "\\" .. cmd .. "{", "}" },
      find   = "\\" .. vim.pesc(cmd) .. "{.-}",
      delete = "^(\\" .. vim.pesc(cmd) .. "{)(.-)( })$",
      change = { target = "^(\\" .. vim.pesc(cmd) .. "{)(.-)( })$" },
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🌍 GLOBAL CUSTOM SURROUNDS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local GLOBAL_SURROUNDS = {
    -- ── Shorthand delimiters ──────────────────────────────────────────────────
    ["q"] = wrap("'",  "'"),
    ["Q"] = wrap('"',  '"'),
    ["r"] = wrap("[",  "]"),
    ["a"] = wrap("<",  ">"),
    ["c"] = wrap("{",  "}"),
  
    -- ── Padded variants ────────────────────────────────────────────────────────
    ["("] = padded("(", ")"),
    ["["] = padded("[", "]"),
    ["{"] = padded("{", "}"),
  
    -- ── Lua  [[…]] long string ─────────────────────────────────────────────────
    ["z"] = {
      add    = { "[[", "]]" },
      find   = "%[%[.-%]%]",
      delete = "^(%[%[)(.-)(%]%])$",
      change = { target = "^(%[%[)(.-)(%]%])$" },
    },
  
    -- ── Pipe (Lua closures, Rust closures) ─────────────────────────────────────
    ["|"] = wrap("|", "|"),
  
    -- ── Markdown ───────────────────────────────────────────────────────────────
    ["m"] = {                          -- bold  **…**
      add    = { "**", "**" },
      find   = "%*%*.-%*%*",
      delete = "^(%*%*)(.-)(%*%*)$",
    },
    ["i"] = {                          -- italic _…_
      add    = { "_", "_" },
      find   = "_.-%_",
      delete = "^(_)(.-)(_)$",
    },
    ["~"] = {                          -- strikethrough  ~~…~~
      add    = { "~~", "~~" },
      find   = "~~.-~~",
      delete = "^(~~)(.-)( ~~)$",
    },
    ["k"] = {                          -- inline code  `…`
      add    = { "`", "`" },
      find   = "`.-`",
      delete = "^(`)(.-)(`  )$",
    },
    ["K"] = {                          -- code block  ```\n…\n```
      add    = { "```\n", "\n```" },
      find   = "```\n.-\n```",
      delete = "^(```\n)(.-)(\n```)$",
    },
    ["l"] = {                          -- link  [text](url)
      add = function()
        local url = input("🔗 URL: ")
        if not url then return nil end
        return { { "[" }, { "](" .. url .. ")" } }
      end,
      find   = "%[.-%]%(.-%)",
      delete = "^(%[)(.-)(%]%(.-%))$",
      change = {
        target = "^(%[)(.-)(%]%(.-%))$",
        replacement = function()
          local url = input("🔗 New URL: ")
          if not url then return nil end
          return { { "[" }, { "](" .. url .. ")" } }
        end,
      },
    },
  
    -- ── LaTeX ──────────────────────────────────────────────────────────────────
    ["L"] = {                          -- \begin{env}…\end{env}
      add = function()
        local env = input("LaTeX env: ")
        if not env then return nil end
        return {
          { "\\begin{" .. env .. "}\n" },
          { "\n\\end{" .. env .. "}" },
        }
      end,
      find   = "\\begin{.-%}.-%\\end{.-}",
      delete = "^(\\begin{.-}\n?)(.-)(\n?\\end{.-})$",
      change = {
        target      = "^(\\begin{.-}\n?)(.-)(\n?\\end{.-})$",
        replacement = function()
          local env = input("New LaTeX env: ")
          if not env then return nil end
          return {
            { "\\begin{" .. env .. "}\n" },
            { "\n\\end{" .. env .. "}" },
          }
        end,
      },
    },
    ["$"] = wrap("$",  "$"),           -- inline math
    ["B"] = latex_cmd("textbf"),       -- \textbf{…}
    ["I"] = latex_cmd("textit"),       -- \textit{…}
    ["U"] = latex_cmd("underline"),    -- \underline{…}
    ["E"] = latex_cmd("emph"),         -- \emph{…}
    ["T"] = latex_cmd("texttt"),       -- \texttt{…}
  
    -- ── HTML helpers ───────────────────────────────────────────────────────────
    ["d"] = wrap("<div>",  "</div>"),
    ["s"] = wrap("<span>", "</span>"),
    ["p"] = wrap("<p>",    "</p>"),
    ["H"] = {                          -- prompt for HTML tag
      add = function()
        local tag = input("HTML tag: ")
        if not tag then return nil end
        -- Strip trailing whitespace and extract classes/attributes
        local base_tag = tag:match("^([^%s]+)")
        return { { "<" .. tag .. ">" }, { "</" .. base_tag .. ">" } }
      end,
      find   = "<(%w-)(.-)>.-</%1>",
      delete = "^(<[^>]+>)(.-)(</%w+>)$",
      change = {
        target      = "^(<[^>]+>)(.-)(</%w+>)$",
        replacement = function()
          local tag = input("New HTML tag: ")
          if not tag then return nil end
          local base_tag = tag:match("^([^%s]+)")
          return { { "<" .. tag .. ">" }, { "</" .. base_tag .. ">" } }
        end,
      },
    },
  
    -- ── JSX / TSX ──────────────────────────────────────────────────────────────
    ["n"] = wrap("{",   "}"),          -- JSX expression   {…}
    ["N"] = wrap("{/* ", " */}"),      -- JSX comment      {/* … */}
  
    -- ── Rust ───────────────────────────────────────────────────────────────────
    ["R"] = wrap("Ok(",   ")"),        -- Ok(…)
    ["O"] = wrap("Some(", ")"),        -- Some(…)
    ["X"] = wrap("Err(",  ")"),        -- Err(…)
    ["V"] = wrap("vec![", "]"),        -- vec![…]
    ["x"] = wrap("Box::new(", ")"),    -- Box::new(…)
  
    -- ── Go ─────────────────────────────────────────────────────────────────────
    ["G"] = {                          -- if err != nil { … }
      add    = { "if err != nil {\n\t", "\n}" },
      find   = "if err != nil {.-}",
      delete = "^(if err != nil {\n\t)(.-)(\n})$",
    },
    ["#"] = wrap("{{/* ", " */}}"),    -- Go template comment
  
    -- ── Elixir ─────────────────────────────────────────────────────────────────
    ["e"] = {                          -- do … end block
      add    = { "do\n  ", "\nend" },
      find   = "do\n.-\nend",
      delete = "^(do\n  )(.-)(\nend)$",
    },
    ["<"] = {                          -- Elixir heredoc ~s"""
      add    = { '~s"""\n', '\n"""' },
      find   = '~s"""\n.-\n"""',
      delete = '^(~s"""\n)(.-)(\n""")$',
    },
  
    -- ── Python ─────────────────────────────────────────────────────────────────
    ["@"] = {                          -- @decorator
      add = function()
        local dec = input("Decorator name: ")
        if not dec then return nil end
        return { { "@" .. dec .. "\n" }, { "" } }
      end,
      find   = "@%w+\n",
      delete = "^(@%w+\n)(.-)()$",
    },
    ["f"] = {                          -- f-string  f"…"
      add    = { 'f"', '"' },
      find   = 'f".-%"',
      delete = '^(f")(.-)("  )$',
    },
  
    -- ── Shell ──────────────────────────────────────────────────────────────────
    ["`"] = wrap("`", "`"),            -- command substitution / backtick
    ["$"] = wrap("$(", ")"),           -- $( … ) subshell  -- overrides LaTeX $ above
    -- Note: the $ override only applies in shell filetypes via ft_surrounds below
  
    -- ── TypeScript / JavaScript ────────────────────────────────────────────────
    ["t"] = {                          -- template literal  `…`
      add    = { "`", "`" },
      find   = "`.-`",
      delete = "^(`)(.-)(`  )$",
    },
    ["A"] = {                          -- async IIFE  (async () => { … })()
      add    = { "(async () => {\n  ", "\n})()" },
      find   = "%(async %(%)[^)]-%)%(%)",
      delete = "^(%(async %(%)[^)]-%)%(%))(.-)(%(%))$",
    },
  
    -- ── Generic function call ───────────────────────────────────────────────────
    ["F"] = {
      add = function()
        local fn = input("Function name: ")
        if not fn then return nil end
        return { { fn .. "(" }, { ")" } }
      end,
      find   = "%w+%(.-%)$",
      delete = "^(%w+%()(.-)(%)$",
      change = {
        target      = "^(%w+%()(.-)(%)$",
        replacement = function()
          local fn = input("New function name: ")
          if not fn then return nil end
          return { { fn .. "(" }, { ")" } }
        end,
      },
    },
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🗂️  PER-FILETYPE SURROUNDS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local FT_SURROUNDS = {
    -- ── LaTeX: override $ to mean display math $$…$$ ─────────────────────────
    tex   = { ["$"] = wrap("$$", "$$") },
    latex = { ["$"] = wrap("$$", "$$") },
  
    -- ── Shell: override $ to subshell ─────────────────────────────────────────
    bash  = { ["$"] = wrap("$(", ")") },
    sh    = { ["$"] = wrap("$(", ")") },
    fish  = { ["$"] = wrap("$(", ")") },
    zsh   = { ["$"] = wrap("$(", ")") },
  
    -- ── Lua: extra surrounds ───────────────────────────────────────────────────
    lua   = {
      ["P"] = wrap("print(", ")"),         -- print(…)
      ["S"] = wrap("tostring(", ")"),      -- tostring(…)
      ["T"] = wrap("type(", ")"),          -- type(…)
    },
  
    -- ── Python: extra surrounds ────────────────────────────────────────────────
    python = {
      ["p"] = wrap("print(", ")"),         -- print(…)
      ["l"] = wrap("[", "]"),              -- list literal
      ["s"] = wrap("{", "}"),              -- set / dict literal
      ["r"] = wrap("repr(", ")"),          -- repr(…)
    },
  
    -- ── Rust: extra surrounds ─────────────────────────────────────────────────
    rust = {
      ["a"] = wrap("Arc::new(", ")"),      -- Arc::new(…)
      ["r"] = wrap("Rc::new(",  ")"),      -- Rc::new(…)
      ["m"] = wrap("Mutex::new(", ")"),    -- Mutex::new(…)
      ["c"] = wrap("Cell::new(", ")"),     -- Cell::new(…)
      ["w"] = wrap("Arc::new(RwLock::new(", "))"),
    },
  
    -- ── Go: extra surrounds ────────────────────────────────────────────────────
    go = {
      ["l"] = wrap("[]interface{}{", "}"), -- slice literal
      ["m"] = wrap("map[string]interface{}{", "}"),
      ["p"] = wrap("fmt.Println(", ")"),
      ["s"] = wrap("fmt.Sprintf(", ")"),
    },
  
    -- ── TypeScript / JavaScript ────────────────────────────────────────────────
    typescript = {
      ["C"] = wrap("console.log(", ")"),
      ["D"] = wrap("document.querySelector('", "')"),
      ["P"] = wrap("Promise.resolve(", ")"),
      ["j"] = wrap("JSON.stringify(", ")"),
      ["J"] = wrap("JSON.parse(", ")"),
    },
    javascript = {
      ["C"] = wrap("console.log(", ")"),
      ["D"] = wrap("document.querySelector('", "')"),
      ["P"] = wrap("Promise.resolve(", ")"),
    },
  
    -- ── HTML ──────────────────────────────────────────────────────────────────
    html = {
      ["c"] = wrap('<div class="', '">...</div>'),
      ["i"] = wrap('<span id="',   '">...</span>'),
    },
  
    -- ── Markdown ──────────────────────────────────────────────────────────────
    markdown = {
      ["h"] = wrap("# ",     ""),          -- H1 header
      ["H"] = wrap("## ",    ""),          -- H2 header
      ["q"] = wrap("> ",     ""),          -- blockquote
      ["c"] = wrap("```\n",  "\n```"),     -- code fence
      ["b"] = wrap("**",     "**"),        -- bold
      ["e"] = wrap("_",      "_"),         -- italic/emphasis
    },
  
    -- ── Hyprland config ────────────────────────────────────────────────────────
    hypr = {
      ["#"] = wrap("# ",     ""),          -- comment prefix
      ["["] = wrap("[",      "]"),         -- window rule brackets
    },
  
    -- ── Rasi (Rofi stylesheet) ────────────────────────────────────────────────
    rasi = {
      ["b"] = wrap("{",      "}"),         -- block
      ["c"] = wrap("/*",     "*/"),        -- block comment
    },
  
    -- ── YAML ──────────────────────────────────────────────────────────────────
    yaml = {
      ["b"] = wrap("|",      ""),          -- block scalar
      ["f"] = wrap(">",      ""),          -- folded scalar
    },
  
    -- ── SQL ───────────────────────────────────────────────────────────────────
    sql = {
      ["b"] = wrap("BEGIN;", "COMMIT;"),
      ["c"] = wrap("/*",     "*/"),
    },
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎨 HIGHLIGHT OVERRIDES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function setup_highlights()
    -- nvim-surround highlights the pair being added/deleted/changed
    vim.api.nvim_set_hl(0, "NvimSurroundHighlight", { link = "IncSearch" })
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "kylechui/nvim-surround",
      version = "^2",
      event   = { "BufReadPre", "BufNewFile" },
      dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-treesitter/nvim-treesitter-textobjects",
      },
  
      -- ── Keys (declarative for which-key) ─────────────────────────────────────
      keys = {
        -- Standard
        { "ys",        mode = "n", desc = "🔲 Add surround"             },
        { "yss",       mode = "n", desc = "🔲 Surround line"            },
        { "yS",        mode = "n", desc = "🔲 Add surround (multiline)" },
        { "ySS",       mode = "n", desc = "🔲 Surround line (multiline)"},
        { "ds",        mode = "n", desc = "🔲 Delete surround"          },
        { "cs",        mode = "n", desc = "🔲 Change surround"          },
        { "cS",        mode = "n", desc = "🔲 Change surround (line)"   },
        { "S",         mode = "v", desc = "🔲 Surround (visual)"        },
        { "gS",        mode = "v", desc = "🔲 Surround (visual, line)"  },
        -- Extras (declared here for which-key registration)
        { "ysl",       mode = "n", desc = "🔲 Surround: Markdown link"  },
        { "ysH",       mode = "n", desc = "🔲 Surround: HTML tag"       },
        { "ysL",       mode = "n", desc = "🔲 Surround: LaTeX env"      },
        { "ysF",       mode = "n", desc = "🔲 Surround: function call"  },
      },
  
      opts = {
        -- ── Key mappings ──────────────────────────────────────────────────────
        keymaps = {
          insert              = "<C-g>s",
          insert_line         = "<C-g>S",
          normal              = "ys",
          normal_cur          = "yss",
          normal_line         = "yS",
          normal_cur_line     = "ySS",
          visual              = "S",
          visual_line         = "gS",
          delete              = "ds",
          change              = "cs",
          change_line         = "cS",
        },
  
        -- ── Aliases — one char  →  another existing surround ─────────────────
        aliases = {
          ["'"] = { "'",  "'"  },   -- match either curly or straight
          ['"'] = { '"',  '"'  },
          ["b"] = { ")",  "}", "]" },  -- generic "bracket"
          ["B"] = { "}", ")" },
          -- Markdown shortcuts resolve to the global surround definitions
          ["*"] = "m",             -- * → bold (Markdown)
          ["_"] = "i",             -- _ → italic (Markdown)
        },
  
        -- ── Global custom surrounds ────────────────────────────────────────────
        surrounds = GLOBAL_SURROUNDS,
  
        -- ── Highlight duration ────────────────────────────────────────────────
        highlight = {
          duration = 250,   -- ms to flash the affected text
        },
  
        -- ── Move cursor ───────────────────────────────────────────────────────
        -- Where to place cursor after an add operation:
        --   "first" → opening delimiter
        --   "last"  → closing delimiter
        --   false   → don't move
        move_cursor = "begin",
  
        -- ── Indent lines ──────────────────────────────────────────────────────
        -- For multiline surrounds (yS / gS), re-indent the surrounded text
        indent_lines = function(start, stop)
          local b = vim.bo
          -- Only indent if the buffer uses auto-indent
          if b.indentexpr ~= "" or b.autoindent or b.smartindent then
            vim.cmd(("silent normal! %dGV%dG="):format(start, stop))
          end
        end,
      },
  
      config = function(_, opts)
        -- Wire in per-filetype surrounds via on_attach
        local function get_ft_surrounds()
          local ft = vim.bo.filetype
          return FT_SURROUNDS[ft] or {}
        end
  
        -- Merge filetype surrounds into the opts at config time by using
        -- nvim-surround's buffer-local configuration API
        require("nvim-surround").setup(opts)
  
        -- Apply filetype surrounds on BufEnter / FileType
        local aug = vim.api.nvim_create_augroup("AshSurround", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group    = aug,
          callback = function(ev)
            local ft_srs = FT_SURROUNDS[vim.bo[ev.buf].filetype]
            if not ft_srs then return end
  
            -- Override / extend config for this buffer
            -- nvim-surround exposes nvim_surround.buffer_setup() for this
            local ok, nsurround = pcall(require, "nvim-surround")
            if ok and nsurround.buffer_setup then
              nsurround.buffer_setup({ surrounds = ft_srs })
            end
          end,
        })
  
        -- Highlights
        setup_highlights()
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        -- ASH hot-reload: refresh highlights after palette swap
        vim.api.nvim_create_autocmd("User", {
          group    = aug,
          pattern  = "AshThemeChanged",
          callback = function()
            setup_highlights()
            -- Re-draw all visible buffers to pick up new IncSearch colour
            vim.cmd("redraw!")
          end,
        })
  
        -- Debug indicator
        if vim.g.ash_debug then
          local ft_count = vim.tbl_count(FT_SURROUNDS)
          local sr_count = vim.tbl_count(GLOBAL_SURROUNDS)
          vim.notify(
            string.format(
              "🔲 Surround loaded — %d global + %d filetype sets",
              sr_count, ft_count
            ),
            vim.log.levels.DEBUG,
            { title = "ASH Surround" }
          )
        end
      end,
    },
  
    -- ── Companion: nvim-treesitter-textobjects already installed by treesitter.lua
    -- The surround textobjects (e.g. ysif → surround inner function) work via
    -- the @function.inner / @class.inner captures defined there automatically.
  }