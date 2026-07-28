-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                                                                              ║
-- ║   ██╗░█████╗░░█████╗░███╗░░██╗░██████╗                                      ║
-- ║   ██║██╔══██╗██╔══██╗████╗░██║██╔════╝                                      ║
-- ║   ██║██║░░╚═╝██║░░██║██╔██╗██║╚█████╗░                                      ║
-- ║   ██║██║░░██╗██║░░██║██║╚████║░╚═══██╗                                      ║
-- ║   ██║╚█████╔╝╚█████╔╝██║░╚███║██████╔╝                                      ║
-- ║   ╚═╝░╚════╝░░╚════╝░╚═╝░░╚══╝╚═════╝░                                      ║
-- ║                                                                              ║
-- ║   lua/core/icons.lua — Nerd Font Icon Registry                               ║
-- ║   ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║   Single source of truth for every icon used across the entire config.       ║
-- ║   Organised into semantic namespaces — import once, reference everywhere.    ║
-- ║                                                                              ║
-- ║   Requirements: Nerd Font v3+ (any patched font)                            ║
-- ║   Fallback:     ASCII equivalents when g.have_nerd_font = false              ║
-- ║                                                                              ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@class AshIcons
local M = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 00  CAPABILITY CHECK
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local HAS_NERD = vim.g.have_nerd_font ~= false

---Return nerd-font glyph or ascii fallback depending on terminal capability
---@param nerd string   Nerd Font codepoint / glyph
---@param ascii string  ASCII fallback
---@return string
local function icon(nerd, ascii)
  return HAS_NERD and nerd or ascii
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 01  DIAGNOSTICS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---@class AshIcons.Diagnostics
M.diagnostics = {
  Error       = icon("󰅚 ", "E "),
  Warn        = icon("󰀪 ", "W "),
  Info        = icon(" ",  "I "),
  Hint        = icon("󰌶 ", "H "),
  -- Variants used in sign column (no trailing space)
  signs = {
    Error     = icon("󰅚", "E"),
    Warn      = icon("󰀪", "W"),
    Info      = icon("", "I"),
    Hint      = icon("󰌶", "H"),
  },
  -- Diff style (used in some plugins)
  ok          = icon("󰄳 ", "OK"),
  loading     = icon("󱙿 ", ".."),
  deprecated  = icon("󰅀 ", "D "),
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 02  GIT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---@class AshIcons.Git
M.git = {
  -- Status
  added           = icon(" ",  "+"),
  changed         = icon(" ",  "~"),
  removed         = icon(" ",  "-"),
  renamed         = icon("󰁕 ",  "R"),
  untracked       = icon("󰙴 ",  "?"),
  unmerged        = icon(" ",  "!"),
  ignored         = icon("󰄮 ",  "i"),
  -- Conflict
  conflict        = icon("󱖷 ",  "C"),
  -- Diff symbols
  diff_add        = icon("", "+"),
  diff_change     = icon("", "~"),
  diff_delete     = icon("", "-"),
  -- Branch / repo
  branch          = icon(" ",  "br:"),
  repo            = icon(" ",  "repo"),
  commit          = icon(" ",  "co:"),
  tag             = icon(" ",  "tag:"),
  stash           = icon("󰆓 ",  "st:"),
  -- Log graph chars
  node            = icon("●",   "o"),
  edge            = icon("│",   "|"),
  -- Actions
  push            = icon("󰶣 ",  "↑"),
  pull            = icon("󰶡 ",  "↓"),
  fetch           = icon("󰑓 ",  "f"),
  merge           = icon("󰘭 ",  "m"),
  rebase          = icon("󰑑 ",  "r"),
  cherry_pick     = icon(" ",  "cp"),
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 03  LSP / COMPLETION KINDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---@class AshIcons.Kinds
M.kinds = {
  Array           = icon("󰅪 ", "[]"),
  Boolean         = icon("󰨙 ", "b "),
  Class           = icon("󰆧 ", "c "),
  Color           = icon("󰏘 ", "# "),
  Constant        = icon("󰏿 ", "K "),
  Constructor     = icon(" ",  "C "),
  Copilot         = icon(" ",  "AI"),
  Codeium         = icon("󱜙 ", "AI"),
  Enum            = icon(" ",  "E "),
  EnumMember      = icon(" ",  "Em"),
  Event           = icon(" ",  "Ev"),
  Field           = icon("󰜢 ", "f "),
  File            = icon("󰈙 ", "F "),
  Folder          = icon("󰉋 ", "D "),
  Function        = icon("󰊕 ", "fn"),
  Interface       = icon(" ",  "I "),
  Key             = icon("󰌋 ", "k "),
  Keyword         = icon("󰌋 ", "kw"),
  Method          = icon("󰆧 ", "m "),
  Module          = icon("󰏗 ", "M "),
  Namespace       = icon("󰌗 ", "N "),
  Null            = icon("󰟢 ", "∅ "),
  Number          = icon("󰎠 ", "n "),
  Object          = icon("󰅩 ", "o "),
  Operator        = icon("󰆕 ", "op"),
  Package         = icon("󰏗 ", "P "),
  Property        = icon("󰜢 ", "p "),
  Reference       = icon("󰈇 ", "& "),
  Snippet         = icon(" ",  "S "),
  String          = icon("󰉾 ", "s "),
  Struct          = icon("󱡠 ", "St"),
  Text            = icon("󰉿 ", "t "),
  TypeParameter   = icon("󰊄 ", "T "),
  Unit            = icon("󰑭 ", "u "),
  Value           = icon("󰎠 ", "v "),
  Variable        = icon("󰀫 ", "x "),
  -- Extra AI sources
  Supermaven      = icon("󱙺 ", "SM"),
  TabNine         = icon("󰏚 ", "T9"),
  -- Path / buffer
  Path            = icon("󰉋 ", "/ "),
  Buffer          = icon("󰈚 ", "B "),
  Calc            = icon("󰃬 ", "= "),
  Emoji           = icon("󰞅 ", ": "),
  nvim_lua        = icon(" ",  "NL"),
  luasnip         = icon("󱄽 ", "SN"),
  luasnip_choice  = icon("󱄿 ", "SC"),
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 04  FILE / FOLDER UI
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---@class AshIcons.UI
M.ui = {
  -- Arrows & chevrons
  ArrowLeft         = icon(" ",   "<"),
  ArrowRight        = icon(" ",   ">"),
  ArrowUp           = icon(" ",   "^"),
  ArrowDown         = icon(" ",   "v"),
  BoldArrowLeft     = icon("",    "<"),
  BoldArrowRight    = icon("",    ">"),
  BoldArrowUp       = icon("",    "^"),
  BoldArrowDown     = icon("",    "v"),
  ChevronRight      = icon(" ",   ">"),
  ChevronLeft       = icon(" ",   "<"),
  ChevronUp         = icon(" ",   "^"),
  ChevronDown       = icon(" ",   "v"),
  DoubleChevronRight = icon("»",  ">>"),
  -- Symbols
  Circle            = icon(" ",   "o"),
  CircleFilled      = icon(" ",   "@"),
  Diamond           = icon("◆",   "*"),
  Square            = icon("■",   "#"),
  Triangle          = icon("▶",   ">"),
  Dot               = icon("●",   "."),
  DotSmall          = icon("·",   "."),
  Ellipsis          = icon("󰇘",   "..."),
  -- Files & folders
  File              = icon(" ",   "f"),
  FileNew           = icon(" ",   "+f"),
  FileSymlink       = icon(" ",   "lf"),
  Files             = icon(" ",   "ff"),
  Folder            = icon("󰉋 ",  "D/"),
  FolderOpen        = icon(" ",   "D/"),
  FolderEmpty       = icon(" ",   "d/"),
  FolderEmptyOpen   = icon(" ",   "d/"),
  FolderSymlink     = icon(" ",   "lD"),
  -- Actions
  Add               = icon(" ",   "+"),
  Remove            = icon(" ",   "-"),
  Edit              = icon("󰏫 ",  "e"),
  Rename            = icon("󰑕 ",  "r"),
  Close             = icon("󰅖 ",  "x"),
  CloseAlt          = icon("󰅙 ",  "X"),
  Confirm           = icon("󰄳 ",  "Y"),
  Check             = icon("󰄳 ",  "✓"),
  CheckAll          = icon("󰄬 ",  "✓✓"),
  Copy              = icon("󰆏 ",  "c"),
  Paste             = icon("󰆒 ",  "p"),
  Cut               = icon("󰆐 ",  "x"),
  Undo              = icon("󰕍 ",  "u"),
  Redo              = icon("󰑎 ",  "r"),
  Refresh           = icon("󰑓 ",  "~"),
  Download          = icon(" ",   "↓"),
  Upload            = icon(" ",   "↑"),
  CloudDownload     = icon(" ",   "↓c"),
  CloudUpload       = icon(" ",   "↑c"),
  -- Navigation
  Search            = icon(" ",   "/"),
  FindFile          = icon("󰈞 ",  "ff"),
  FindText          = icon("󰊄 ",  "ft"),
  Forward           = icon(" ",   "→"),
  Back              = icon(" ",   "←"),
  BookMark          = icon("󰃃 ",  "bm"),
  History           = icon(" ",   "h"),
  -- System
  Terminal          = icon(" ",   "T"),
  Code              = icon(" ",   "<>"),
  Bug               = icon("󰃤 ",  "~b"),
  Gear              = icon(" ",   ":"),
  Settings          = icon(" ",   "S"),
  Lock              = icon("󰌾 ",  "#"),
  Unlock            = icon("󰍰 ",  "#"),
  Key               = icon("󰌋 ",  "k"),
  Shield            = icon("󰡷 ",  "sh"),
  ShieldCheck       = icon("󰪍 ",  "OK"),
  Eye               = icon(" ",   "o"),
  EyeOff            = icon("󰈉 ",  "-o"),
  Power             = icon("⏻ ",   "pw"),
  Plug              = icon("󰚥 ",  "pl"),
  -- Info & status
  Info              = icon(" ",   "i"),
  Warning           = icon("󰀪 ",  "!"),
  Error             = icon("󰅚 ",  "E"),
  Question          = icon(" ",   "?"),
  Note              = icon("󰎞 ",  "N"),
  Pin               = icon("󰐃 ",  "p"),
  Tag               = icon(" ",   "#"),
  Label             = icon("󰍎 ",  "L"),
  Bell              = icon(" ",   "B"),
  BellOff           = icon("󰂛 ",  "-B"),
  Calendar          = icon(" ",   "Cal"),
  Clock             = icon(" ",   "Clk"),
  Watch             = icon("󰥔 ",  "W"),
  Timer             = icon("󰔛 ",  "T"),
  -- Project / workflow
  Project           = icon(" ",   "Proj"),
  Dashboard         = icon(" ",   "Dash"),
  Package           = icon(" ",   "Pkg"),
  Inbox             = icon("󰚇 ",  "In"),
  Outbox            = icon("󰚋 ",  "Out"),
  List              = icon(" ",   "ls"),
  Table             = icon(" ",   "tb"),
  Tree              = icon(" ",   "tr"),
  Stacks            = icon(" ",   "sk"),
  Graph             = icon("󱇬 ",  "gr"),
  Target            = icon("󰀘 ",  "tg"),
  Telescope         = icon(" ",   "ts"),
  Lightbulb         = icon("󰌵 ",  "lb"),
  Fire              = icon(" ",   "🔥"),
  Rocket            = icon(" ",   "🚀"),
  Star              = icon("󰓎 ",  "*"),
  StarFilled        = icon("󰓎 ",  "★"),
  Heart             = icon("󰣑 ",  "♥"),
  Trophy            = icon(" ",   "🏆"),
  Crown             = icon("󱇢 ",  "👑"),
  Hammer            = icon(" ",   "H"),
  Wrench            = icon(" ",   "W"),
  Scissors          = icon("󰆐 ",  "sc"),
  Trash             = icon("󰆴 ",  "del"),
  -- Separators
  sep = {
    powerline    = { left = icon("",  ">"), right = icon("",  "<") },
    powerline_thin = { left = icon("", ">"), right = icon("", "<") },
    round        = { left = icon("",  "("), right = icon("",  ")") },
    block        = { left = "█",             right = "█"             },
    arrow        = { left = icon("",  ">"), right = icon("",  "<") },
    arrow_thin   = { left = icon("",  ">"), right = icon("",  "<") },
    slant        = { left = icon("",  "/"), right = icon("",  "\\")},
    slant_inv    = { left = icon("",  "\\"),right = icon("",  "/") },
    pipe         = { left = "│",             right = "│"             },
    dot          = { left = "•",             right = "•"             },
  },
  -- Tab line
  tab = {
    left         = icon("▎",  "|"),
    right        = icon("▐",  "|"),
    modified     = icon("●",  "*"),
    close        = icon("󰅖",  "x"),
    padding      = " ",
  },
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 05  LANGUAGES & FILE TYPES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---@class AshIcons.Lang
M.lang = {
  lua          = icon(" ",  "Lua"),
  python       = icon(" ",  "Py"),
  rust         = icon(" ",  "Rs"),
  go           = icon("󰟓 ", "Go"),
  typescript   = icon(" ",  "TS"),
  javascript   = icon(" ",  "JS"),
  jsx          = icon(" ",  "JSX"),
  tsx          = icon(" ",  "TSX"),
  html         = icon(" ",  "HTM"),
  css          = icon(" ",  "CSS"),
  scss         = icon(" ",  "SCSS"),
  json         = icon("󰘦 ", "JSON"),
  jsonc        = icon("󰘦 ", "JSONC"),
  yaml         = icon(" ",  "YML"),
  toml         = icon(" ",  "TOML"),
  markdown     = icon(" ",  "MD"),
  bash         = icon(" ",  "SH"),
  fish         = icon(" ",  "FISH"),
  zsh          = icon(" ",  "ZSH"),
  vim          = icon(" ",  "VIM"),
  cpp          = icon(" ",  "C++"),
  c            = icon(" ",  "C"),
  java         = icon(" ",  "Java"),
  kotlin       = icon(" ",  "Kt"),
  swift        = icon(" ",  "Sw"),
  ruby         = icon(" ",  "Rb"),
  php          = icon("󰌟 ", "PHP"),
  haskell      = icon(" ",  "Hs"),
  elixir       = icon(" ",  "Ex"),
  erlang       = icon(" ",  "Erl"),
  clojure      = icon(" ",  "Clj"),
  scala        = icon(" ",  "Sc"),
  dart         = icon(" ",  "Dart"),
  zig          = icon(" ",  "Zig"),
  nix          = icon(" ",  "Nix"),
  docker       = icon("󰡨 ", "Dk"),
  terraform    = icon("󱁢 ", "TF"),
  sql          = icon(" ",  "SQL"),
  graphql      = icon("󰡷 ", "GQL"),
  latex        = icon(" ",  "LaTeX"),
  r            = icon("󰟔 ", "R"),
  julia        = icon(" ",  "Jl"),
  gleam        = icon("⬡ ",  "Gleam"),
  svelte       = icon(" ",  "Sv"),
  vue          = icon("󰡱 ", "Vue"),
  astro        = icon(" ",  "Astro"),
  prisma       = icon(" ",  "Prisma"),
  -- Config / data
  env          = icon(" ",  "ENV"),
  git          = icon(" ",  "GIT"),
  gitignore    = icon(" ",  ".gi"),
  license      = icon("󰿃 ", "LIC"),
  readme       = icon(" ",  "README"),
  makefile     = icon(" ",  "Make"),
  hyprland     = icon(" ",  "Hypr"),
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 06  STATUS LINE COMPONENTS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---@class AshIcons.Status
M.status = {
  -- Vim modes
  modes = {
    NORMAL        = icon("󰋜 NORMAL",   "NORMAL"),
    INSERT        = icon("󰏪 INSERT",   "INSERT"),
    VISUAL        = icon("󰈈 VISUAL",   "VISUAL"),
    V_LINE        = icon("󰈈 V-LINE",   "V-LINE"),
    V_BLOCK       = icon("󰈈 V-BLOCK",  "V-BLOCK"),
    SELECT        = icon("󰒅 SELECT",   "SELECT"),
    REPLACE       = icon("󰬲 REPLACE",  "REPLACE"),
    COMMAND       = icon("󰘳 COMMAND",  "COMMAND"),
    TERMINAL      = icon(" TERMINAL", "TERMINAL"),
    EX            = icon(" EX",        "EX"),
  },
  -- LSP
  lsp_active        = icon("󰄭 ",   "LSP"),
  lsp_inactive      = icon("󰅚 ",   "!LSP"),
  formatter         = icon("󰉿 ",   "fmt"),
  linter            = icon("󱉶 ",   "lint"),
  -- File info
  encoding          = icon("󰁦 ",   "enc"),
  line_ending_unix  = icon("  ",  "LF"),
  line_ending_win   = icon("󰌬  ", "CRLF"),
  line_ending_mac   = icon("  ",  "CR"),
  file_modified     = icon("●",    "*"),
  file_readonly     = icon("󰌾 ",   "[RO]"),
  file_new          = icon(" ",   "[NEW]"),
  -- Position
  line              = icon("󰦥 ",   "L:"),
  col               = icon("󰐅 ",   "C:"),
  percent           = icon("󰏰 ",   "%"),
  -- Hardware / env
  battery = {
    full    = icon("󱟦 ", "BAT100"),
    high    = icon("󱟤 ", "BAT75"),
    mid     = icon("󱟣 ", "BAT50"),
    low     = icon("󱟡 ", "BAT25"),
    empty   = icon("󱟠 ", "BAT0"),
    charging = icon("󱐋 ", "CHG"),
  },
  -- Misc
  clock             = icon(" ",   ""),
  os_linux          = icon(" ",   "Lin"),
  os_mac            = icon(" ",   "Mac"),
  os_win            = icon("󰖳 ",  "Win"),
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 07  DAP (debugger)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---@class AshIcons.Dap
M.dap = {
  Stopped             = icon("󰁕 ", "→"),
  Breakpoint          = icon("●",  "B"),
  BreakpointCondition = icon("󰯲 ", "C"),
  BreakpointRejected  = icon("○",  "b"),
  LogPoint            = icon("◆",  "L"),
  BreakpointDisabled  = icon("○",  "-"),
  -- Controls
  play                = icon(" ",  "▶"),
  pause               = icon(" ",  "⏸"),
  step_into           = icon("󰆹 ", "↓"),
  step_over           = icon("󰆸 ", "→"),
  step_out            = icon("󰆸 ", "↑"),
  step_back           = icon(" ",  "←"),
  run_last            = icon("󰑙 ", "↺"),
  terminate           = icon("󰓛 ", "✗"),
  restart             = icon("󰑓 ", "↺"),
  disconnect          = icon("󰈻 ", "~"),
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 08  TESTING
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---@class AshIcons.Test
M.test = {
  passed   = icon("󰄳 ", "✓"),
  failed   = icon("󰅚 ", "✗"),
  running  = icon("󱙿 ", "~"),
  skipped  = icon("󰒲 ", "-"),
  unknown  = icon(" ",  "?"),
  watching = icon(" ",  "W"),
  suite    = icon(" ",  "S"),
  file     = icon(" ",  "F"),
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 09  MISC / SPECIAL
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---@class AshIcons.Misc
M.misc = {
  -- Alpha dashboard
  header_lines  = icon("━", "-"),
  -- Notifications
  debug         = icon("󰃤 ", "[DEBUG]"),
  trace         = icon("󰡚 ", "[TRACE]"),
  info          = icon(" ",  "[INFO]"),
  warn          = icon("󰀪 ", "[WARN]"),
  error         = icon("󰅚 ", "[ERR]"),
  -- Plugin-specific
  lazy          = icon("󰒲 ", "Lazy"),
  mason         = icon(" ",  "Mason"),
  telescope     = icon(" ",  "Scope"),
  treesitter    = icon(" ",  "TS"),
  neotree       = icon("󰙅 ", "Tree"),
  trouble       = icon("󱖫 ", "Trouble"),
  harpoon       = icon(" ",  "Harpoon"),
  which_key     = icon("󰌌 ", "Keys"),
  copilot       = icon(" ",  "Copilot"),
  codeium       = icon("󱜙 ", "Codeium"),
  ai            = icon("󰚩 ", "AI"),
  gpt           = icon("󱓓 ", "GPT"),
  -- Arrows for animation
  spinner = {
    "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏",
  },
  spinner_dots = {
    "󰪞", "󰪟", "󰪠", "󰪡", "󰪢", "󰪣", "󰪤", "󰪥",
  },
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 10  SYNC INTO GLOBAL ASH NAMESPACE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Merge our canonical icon tables into the Ash global so every module
-- can do: Ash.icons.kinds.Function  etc.
if Ash then
  Ash.icons = vim.tbl_deep_extend("force", Ash.icons or {}, M)
end

return M