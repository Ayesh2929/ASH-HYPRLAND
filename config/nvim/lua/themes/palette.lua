-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🎨 ASH PALETTE — MULTI-THEME COLOUR CATALOGUE v5.0 OMEGA                 ║
-- ║   Canonical colour tables for 40+ themes · auto-extraction fallback            ║
-- ║   Catppuccin · TokyoNight · Gruvbox · Nord · and more                         ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 COLOUR HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Mix two hex colours by ratio t (0=c1, 1=c2)
local function mix(c1, c2, t)
  local function h2r(h)
    h = h:gsub("^#", "")
    return {
      tonumber(h:sub(1,2),16) or 128,
      tonumber(h:sub(3,4),16) or 128,
      tonumber(h:sub(5,6),16) or 128,
    }
  end
  local r1, r2 = h2r(c1), h2r(c2)
  t = math.max(0, math.min(1, t))
  return string.format("#%02x%02x%02x",
    math.floor(r1[1] + (r2[1]-r1[1])*t + 0.5),
    math.floor(r1[2] + (r2[2]-r1[2])*t + 0.5),
    math.floor(r1[3] + (r2[3]-r1[3])*t + 0.5)
  )
end

-- Extend a palette with derived colours
local function extend(p)
  p.none        = "NONE"
  p.selection   = mix(p.base, p.blue or p.accent or "#89b4fa", 0.15)
  p.float_bg    = mix(p.base, p.surface0 or p.base, 0.5)
  p.cursorline  = mix(p.base, p.surface0 or p.base, 0.7)
  p.statusline  = mix(p.base, p.surface0 or p.base, 0.4)
  p.border      = p.surface1 or p.overlay0 or p.surface0 or "#45475a"
  p.diff_add    = mix(p.base, p.green  or "#a6e3a1", 0.15)
  p.diff_delete = mix(p.base, p.red    or "#f38ba8", 0.15)
  p.diff_change = mix(p.base, p.yellow or "#f9e2af", 0.12)
  p.diff_text   = mix(p.base, p.yellow or "#f9e2af", 0.20)
  p.error_bg    = mix(p.base, p.red    or "#f38ba8", 0.10)
  p.warning_bg  = mix(p.base, p.yellow or "#f9e2af", 0.10)
  p.info_bg     = mix(p.base, p.blue   or "#89b4fa", 0.10)
  p.hint_bg     = mix(p.base, p.teal   or "#94e2d5", 0.10)
  -- Aliases
  p.accent      = p.accent  or p.blue  or "#89b4fa"
  p.error       = p.error   or p.red   or "#f38ba8"
  p.warning     = p.warning or p.yellow or "#f9e2af"
  p.info        = p.info    or p.blue   or "#89b4fa"
  p.hint        = p.hint    or p.teal   or "#94e2d5"
  p.orange      = p.orange  or p.peach  or "#fab387"
  p.cyan        = p.cyan    or p.teal   or "#94e2d5"
  p.purple      = p.purple  or p.mauve  or "#cba6f7"
  p.indent_guide= mix(p.base, p.surface1 or "#45475a", 0.4)
  return p
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗂️  THEME PALETTES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local PALETTES = {}

-- ── Catppuccin Mocha ──────────────────────────────────────────────────────────
PALETTES["catppuccin-mocha"] = extend({
  base      = "#1e1e2e",  mantle    = "#181825",  crust     = "#11111b",
  surface0  = "#313244",  surface1  = "#45475a",  surface2  = "#585b70",
  overlay0  = "#6c7086",  overlay1  = "#7f849c",  overlay2  = "#9399b2",
  text      = "#cdd6f4",  subtext0  = "#a6adc8",  subtext1  = "#bac2de",
  lavender  = "#b4befe",  blue      = "#89b4fa",  sapphire  = "#74c7ec",
  sky       = "#89dceb",  teal      = "#94e2d5",  green     = "#a6e3a1",
  yellow    = "#f9e2af",  peach     = "#fab387",  maroon    = "#eba0ac",
  red       = "#f38ba8",  mauve     = "#cba6f7",  pink      = "#f5c2e7",
  flamingo  = "#f2cdcd",  rosewater = "#f5e0dc",
})

-- ── Catppuccin Macchiato ──────────────────────────────────────────────────────
PALETTES["catppuccin-macchiato"] = extend({
  base      = "#24273a",  mantle    = "#1e2030",  crust     = "#181926",
  surface0  = "#363a4f",  surface1  = "#494d64",  surface2  = "#5b6078",
  overlay0  = "#6e738d",  overlay1  = "#8087a2",  overlay2  = "#939ab7",
  text      = "#cad3f5",  subtext0  = "#a5adcb",  subtext1  = "#b8c0e0",
  lavender  = "#b7bdf8",  blue      = "#8aadf4",  sapphire  = "#7dc4e4",
  sky       = "#91d7e3",  teal      = "#8bd5ca",  green     = "#a6da95",
  yellow    = "#eed49f",  peach     = "#f5a97f",  maroon    = "#ee99a0",
  red       = "#ed8796",  mauve     = "#c6a0f6",  pink      = "#f5bde6",
  flamingo  = "#f0c6c6",  rosewater = "#f4dbd6",
})

-- ── Catppuccin Frappe ────────────────────────────────────────────────────────
PALETTES["catppuccin-frappe"] = extend({
  base      = "#303446",  mantle    = "#292c3c",  crust     = "#232634",
  surface0  = "#414559",  surface1  = "#51576d",  surface2  = "#626880",
  overlay0  = "#737994",  overlay1  = "#838ba7",  overlay2  = "#949cbb",
  text      = "#c6d0f5",  subtext0  = "#a5adce",  subtext1  = "#b5bfe2",
  lavender  = "#babbf1",  blue      = "#8caaee",  sapphire  = "#85c1dc",
  sky       = "#99d1db",  teal      = "#81c8be",  green     = "#a6d189",
  yellow    = "#e5c890",  peach     = "#ef9f76",  maroon    = "#ea999c",
  red       = "#e78284",  mauve     = "#ca9ee6",  pink      = "#f4b8e4",
  flamingo  = "#eebebe",  rosewater = "#f2d5cf",
})

-- ── Catppuccin Latte ─────────────────────────────────────────────────────────
PALETTES["catppuccin-latte"] = extend({
  base      = "#eff1f5",  mantle    = "#e6e9ef",  crust     = "#dce0e8",
  surface0  = "#ccd0da",  surface1  = "#bcc0cc",  surface2  = "#acb0be",
  overlay0  = "#9ca0b0",  overlay1  = "#8c8fa1",  overlay2  = "#7c7f93",
  text      = "#4c4f69",  subtext0  = "#6c6f85",  subtext1  = "#5c5f77",
  lavender  = "#7287fd",  blue      = "#1e66f5",  sapphire  = "#209fb5",
  sky       = "#04a5e5",  teal      = "#179299",  green     = "#40a02b",
  yellow    = "#df8e1d",  peach     = "#fe640b",  maroon    = "#e64553",
  red       = "#d20f39",  mauve     = "#8839ef",  pink      = "#ea76cb",
  flamingo  = "#dd7878",  rosewater = "#dc8a78",
})

-- ── TokyoNight Night ──────────────────────────────────────────────────────────
PALETTES["tokyonight"] = extend({
  base      = "#1a1b26",  mantle    = "#16161e",  crust     = "#13131a",
  surface0  = "#1f2335",  surface1  = "#24283b",  surface2  = "#292e42",
  overlay0  = "#414868",  overlay1  = "#565f89",  overlay2  = "#7081b7",
  text      = "#c0caf5",  subtext0  = "#9aa5ce",  subtext1  = "#a9b1d6",
  lavender  = "#7aa2f7",  blue      = "#7aa2f7",  sapphire  = "#2ac3de",
  sky       = "#7dcfff",  teal      = "#73daca",  green     = "#9ece6a",
  yellow    = "#e0af68",  peach     = "#ff9e64",  maroon    = "#db4b4b",
  red       = "#f7768e",  mauve     = "#bb9af7",  pink      = "#ff007c",
  flamingo  = "#ff6e6e",  rosewater = "#ffb3a7",
})
PALETTES["tokyonight-night"] = PALETTES["tokyonight"]

-- ── TokyoNight Storm ─────────────────────────────────────────────────────────
PALETTES["tokyonight-storm"] = extend({
  base      = "#24283b",  mantle    = "#1f2335",  crust     = "#1a1b26",
  surface0  = "#292e42",  surface1  = "#2f3549",  surface2  = "#3b4261",
  overlay0  = "#414868",  overlay1  = "#565f89",  overlay2  = "#7081b7",
  text      = "#c0caf5",  subtext0  = "#9aa5ce",  subtext1  = "#a9b1d6",
  lavender  = "#7aa2f7",  blue      = "#7aa2f7",  sapphire  = "#2ac3de",
  sky       = "#7dcfff",  teal      = "#73daca",  green     = "#9ece6a",
  yellow    = "#e0af68",  peach     = "#ff9e64",  maroon    = "#db4b4b",
  red       = "#f7768e",  mauve     = "#bb9af7",  pink      = "#ff007c",
  flamingo  = "#ff6e6e",  rosewater = "#ffb3a7",
})

-- ── TokyoNight Moon ───────────────────────────────────────────────────────────
PALETTES["tokyonight-moon"] = extend({
  base      = "#222436",  mantle    = "#1e2030",  crust     = "#191b28",
  surface0  = "#2f334d",  surface1  = "#383c5a",  surface2  = "#444a73",
  overlay0  = "#636ca2",  overlay1  = "#737cac",  overlay2  = "#858cb8",
  text      = "#c8d3f5",  subtext0  = "#a9b8e8",  subtext1  = "#b4c2f0",
  lavender  = "#82aaff",  blue      = "#82aaff",  sapphire  = "#4fd6be",
  sky       = "#86e1fc",  teal      = "#4fd6be",  green     = "#c3e88d",
  yellow    = "#ffc777",  peach     = "#ff966c",  maroon    = "#ff5370",
  red       = "#ff757f",  mauve     = "#c099ff",  pink      = "#fca7ea",
  flamingo  = "#ff98a4",  rosewater = "#ffd2d2",
})

-- ── Gruvbox Dark ─────────────────────────────────────────────────────────────
PALETTES["gruvbox"] = extend({
  base      = "#282828",  mantle    = "#1d2021",  crust     = "#141617",
  surface0  = "#3c3836",  surface1  = "#504945",  surface2  = "#665c54",
  overlay0  = "#7c6f64",  overlay1  = "#928374",  overlay2  = "#a89984",
  text      = "#ebdbb2",  subtext0  = "#d5c4a1",  subtext1  = "#bdae93",
  lavender  = "#d3869b",  blue      = "#83a598",  sapphire  = "#76b6b4",
  sky       = "#8ec07c",  teal      = "#8ec07c",  green     = "#b8bb26",
  yellow    = "#fabd2f",  peach     = "#fe8019",  maroon    = "#cc241d",
  red       = "#fb4934",  mauve     = "#d3869b",  pink      = "#d3869b",
  flamingo  = "#d65d0e",  rosewater = "#ebdbb2",
})
PALETTES["gruvbox-dark"]  = PALETTES["gruvbox"]

-- ── Gruvbox Light ─────────────────────────────────────────────────────────────
PALETTES["gruvbox-light"] = extend({
  base      = "#fbf1c7",  mantle    = "#f2e5bc",  crust     = "#ebdbb2",
  surface0  = "#d5c4a1",  surface1  = "#bdae93",  surface2  = "#a89984",
  overlay0  = "#928374",  overlay1  = "#7c6f64",  overlay2  = "#665c54",
  text      = "#3c3836",  subtext0  = "#504945",  subtext1  = "#665c54",
  lavender  = "#8f3f71",  blue      = "#076678",  sapphire  = "#427b58",
  sky       = "#427b58",  teal      = "#427b58",  green     = "#79740e",
  yellow    = "#b57614",  peach     = "#af3a03",  maroon    = "#9d0006",
  red       = "#cc241d",  mauve     = "#8f3f71",  pink      = "#8f3f71",
  flamingo  = "#af3a03",  rosewater = "#3c3836",
})

-- ── Gruvbox Material ──────────────────────────────────────────────────────────
PALETTES["gruvbox-material"] = extend({
  base      = "#282828",  mantle    = "#1d2021",  crust     = "#141617",
  surface0  = "#32302f",  surface1  = "#3c3836",  surface2  = "#504945",
  overlay0  = "#7c6f64",  overlay1  = "#928374",  overlay2  = "#a89984",
  text      = "#d4be98",  subtext0  = "#c5b394",  subtext1  = "#bdae93",
  lavender  = "#d3869b",  blue      = "#7daea3",  sapphire  = "#89b482",
  sky       = "#89b482",  teal      = "#89b482",  green     = "#a9b665",
  yellow    = "#d8a657",  peach     = "#e78a4e",  maroon    = "#ea6962",
  red       = "#ea6962",  mauve     = "#d3869b",  pink      = "#d3869b",
  flamingo  = "#e78a4e",  rosewater = "#d4be98",
})

-- ── Nord ──────────────────────────────────────────────────────────────────────
PALETTES["nord"] = extend({
  base      = "#2e3440",  mantle    = "#272c36",  crust     = "#242932",
  surface0  = "#3b4252",  surface1  = "#434c5e",  surface2  = "#4c566a",
  overlay0  = "#616e88",  overlay1  = "#6e7d9d",  overlay2  = "#7b8da6",
  text      = "#eceff4",  subtext0  = "#d8dee9",  subtext1  = "#e5e9f0",
  lavender  = "#b48ead",  blue      = "#5e81ac",  sapphire  = "#81a1c1",
  sky       = "#88c0d0",  teal      = "#8fbcbb",  green     = "#a3be8c",
  yellow    = "#ebcb8b",  peach     = "#d08770",  maroon    = "#bf616a",
  red       = "#bf616a",  mauve     = "#b48ead",  pink      = "#b48ead",
  flamingo  = "#d08770",  rosewater = "#eceff4",
})

-- ── Dracula ───────────────────────────────────────────────────────────────────
PALETTES["dracula"] = extend({
  base      = "#282a36",  mantle    = "#21222c",  crust     = "#191a21",
  surface0  = "#373844",  surface1  = "#44475a",  surface2  = "#6272a4",
  overlay0  = "#6272a4",  overlay1  = "#7281b4",  overlay2  = "#8290c4",
  text      = "#f8f8f2",  subtext0  = "#e2e2de",  subtext1  = "#f0f0ec",
  lavender  = "#bd93f9",  blue      = "#6272a4",  sapphire  = "#8be9fd",
  sky       = "#8be9fd",  teal      = "#50fa7b",  green     = "#50fa7b",
  yellow    = "#f1fa8c",  peach     = "#ffb86c",  maroon    = "#ff5555",
  red       = "#ff5555",  mauve     = "#bd93f9",  pink      = "#ff79c6",
  flamingo  = "#ffb86c",  rosewater = "#f8f8f2",
})

-- ── Onedark ───────────────────────────────────────────────────────────────────
PALETTES["onedark"] = extend({
  base      = "#282c34",  mantle    = "#21252b",  crust     = "#1a1d24",
  surface0  = "#31363f",  surface1  = "#3e4451",  surface2  = "#4b5263",
  overlay0  = "#5c6370",  overlay1  = "#6d7787",  overlay2  = "#7e889a",
  text      = "#abb2bf",  subtext0  = "#9aa3b0",  subtext1  = "#a5aebe",
  lavender  = "#c678dd",  blue      = "#61afef",  sapphire  = "#56b6c2",
  sky       = "#56b6c2",  teal      = "#56b6c2",  green     = "#98c379",
  yellow    = "#e5c07b",  peach     = "#d19a66",  maroon    = "#be5046",
  red       = "#e06c75",  mauve     = "#c678dd",  pink      = "#c678dd",
  flamingo  = "#d19a66",  rosewater = "#abb2bf",
})

-- ── Everforest Dark ───────────────────────────────────────────────────────────
PALETTES["everforest"] = extend({
  base      = "#2d353b",  mantle    = "#272e33",  crust     = "#1e2326",
  surface0  = "#3d484d",  surface1  = "#475258",  surface2  = "#514b4b",
  overlay0  = "#859289",  overlay1  = "#9da9a0",  overlay2  = "#a7c080",
  text      = "#d3c6aa",  subtext0  = "#c5b99c",  subtext1  = "#c9cece",
  lavender  = "#d699b6",  blue      = "#7fbbb3",  sapphire  = "#83c092",
  sky       = "#83c092",  teal      = "#83c092",  green     = "#a7c080",
  yellow    = "#dbbc7f",  peach     = "#e69875",  maroon    = "#e67e80",
  red       = "#e67e80",  mauve     = "#d699b6",  pink      = "#d699b6",
  flamingo  = "#e69875",  rosewater = "#d3c6aa",
})
PALETTES["everforest-dark"] = PALETTES["everforest"]

-- ── Everforest Light ─────────────────────────────────────────────────────────
PALETTES["everforest-light"] = extend({
  base      = "#fdf6e3",  mantle    = "#f4eddb",  crust     = "#eae4d0",
  surface0  = "#e0dace",  surface1  = "#c9c39b",  surface2  = "#a6b0a0",
  overlay0  = "#939f91",  overlay1  = "#829181",  overlay2  = "#708071",
  text      = "#5c6a72",  subtext0  = "#708d81",  subtext1  = "#657a74",
  lavender  = "#df69ba",  blue      = "#3a94c5",  sapphire  = "#35a77c",
  sky       = "#35a77c",  teal      = "#35a77c",  green     = "#8da101",
  yellow    = "#dfa000",  peach     = "#f57d26",  maroon    = "#f85552",
  red       = "#f85552",  mauve     = "#df69ba",  pink      = "#df69ba",
  flamingo  = "#f57d26",  rosewater = "#5c6a72",
})

-- ── Kanagawa ──────────────────────────────────────────────────────────────────
PALETTES["kanagawa"] = extend({
  base      = "#1f1f28",  mantle    = "#16161d",  crust     = "#0d0c0c",
  surface0  = "#2a2a37",  surface1  = "#363646",  surface2  = "#54546d",
  overlay0  = "#727169",  overlay1  = "#9cabca",  overlay2  = "#a3b3c2",
  text      = "#dcd7ba",  subtext0  = "#c8c093",  subtext1  = "#d5cea3",
  lavender  = "#957fb8",  blue      = "#7e9cd8",  sapphire  = "#7fb4ca",
  sky       = "#7fb4ca",  teal      = "#6a9589",  green     = "#76946a",
  yellow    = "#c0a36e",  peach     = "#ffa066",  maroon    = "#c34043",
  red       = "#e82424",  mauve     = "#957fb8",  pink      = "#d27e99",
  flamingo  = "#e46876",  rosewater = "#ff5d62",
})

-- ── Rose Pine ────────────────────────────────────────────────────────────────
PALETTES["rose-pine"] = extend({
  base      = "#191724",  mantle    = "#1f1d2e",  crust     = "#26233a",
  surface0  = "#1f1d2e",  surface1  = "#26233a",  surface2  = "#6e6a86",
  overlay0  = "#6e6a86",  overlay1  = "#908caa",  overlay2  = "#e0def4",
  text      = "#e0def4",  subtext0  = "#908caa",  subtext1  = "#c4bfe0",
  lavender  = "#c4a7e7",  blue      = "#9ccfd8",  sapphire  = "#9ccfd8",
  sky       = "#9ccfd8",  teal      = "#31748f",  green     = "#31748f",
  yellow    = "#f6c177",  peach     = "#ea9a97",  maroon    = "#b4637a",
  red       = "#eb6f92",  mauve     = "#c4a7e7",  pink      = "#eb6f92",
  flamingo  = "#ea9a97",  rosewater = "#ebbcba",
})

-- ── Rose Pine Moon ────────────────────────────────────────────────────────────
PALETTES["rose-pine-moon"] = extend({
  base      = "#232136",  mantle    = "#2a273f",  crust     = "#393552",
  surface0  = "#2a273f",  surface1  = "#393552",  surface2  = "#817c9c",
  overlay0  = "#817c9c",  overlay1  = "#9893a5",  overlay2  = "#e0def4",
  text      = "#e0def4",  subtext0  = "#9893a5",  subtext1  = "#b9b1d0",
  lavender  = "#c4a7e7",  blue      = "#9ccfd8",  sapphire  = "#9ccfd8",
  sky       = "#9ccfd8",  teal      = "#3e8fb0",  green     = "#3e8fb0",
  yellow    = "#f6c177",  peach     = "#ea9a97",  maroon    = "#b4637a",
  red       = "#eb6f92",  mauve     = "#c4a7e7",  pink      = "#eb6f92",
  flamingo  = "#ea9a97",  rosewater = "#ebbcba",
})

-- ── Rose Pine Dawn ────────────────────────────────────────────────────────────
PALETTES["rose-pine-dawn"] = extend({
  base      = "#faf4ed",  mantle    = "#fffaf3",  crust     = "#f2e9e1",
  surface0  = "#f2e9e1",  surface1  = "#ede0d5",  surface2  = "#b4829a",
  overlay0  = "#b4829a",  overlay1  = "#9e7a8a",  overlay2  = "#575279",
  text      = "#575279",  subtext0  = "#9e7a8a",  subtext1  = "#6f6a86",
  lavender  = "#907aa9",  blue      = "#286983",  sapphire  = "#286983",
  sky       = "#286983",  teal      = "#56949f",  green     = "#56949f",
  yellow    = "#ea9d34",  peach     = "#d7827e",  maroon    = "#b4637a",
  red       = "#b4637a",  mauve     = "#907aa9",  pink      = "#b4637a",
  flamingo  = "#d7827e",  rosewater = "#907aa9",
})

-- ── Oxocarbon ─────────────────────────────────────────────────────────────────
PALETTES["oxocarbon"] = extend({
  base      = "#161616",  mantle    = "#101010",  crust     = "#0a0a0a",
  surface0  = "#262626",  surface1  = "#393939",  surface2  = "#525252",
  overlay0  = "#6f6f6f",  overlay1  = "#8d8d8d",  overlay2  = "#a8a8a8",
  text      = "#f2f4f8",  subtext0  = "#dde1e6",  subtext1  = "#e5e8ed",
  lavender  = "#be95ff",  blue      = "#78a9ff",  sapphire  = "#82cfff",
  sky       = "#82cfff",  teal      = "#3ddbd9",  green     = "#42be65",
  yellow    = "#ffe97b",  peach     = "#ff832b",  maroon    = "#ee5396",
  red       = "#ff7eb6",  mauve     = "#be95ff",  pink      = "#ee5396",
  flamingo  = "#ff832b",  rosewater = "#f2f4f8",
})

-- ── Nightfox ──────────────────────────────────────────────────────────────────
PALETTES["nightfox"] = extend({
  base      = "#192330",  mantle    = "#131a24",  crust     = "#0d1117",
  surface0  = "#212e3f",  surface1  = "#29394f",  surface2  = "#384d68",
  overlay0  = "#71839b",  overlay1  = "#7f93ab",  overlay2  = "#8dafc4",
  text      = "#cdcecf",  subtext0  = "#aeafb0",  subtext1  = "#b7b8b9",
  lavender  = "#9d79d6",  blue      = "#6d91de",  sapphire  = "#719cd6",
  sky       = "#63cdcf",  teal      = "#63cdcf",  green     = "#81b29a",
  yellow    = "#dbc074",  peach     = "#c9826b",  maroon    = "#d67ad2",
  red       = "#c94f6d",  mauve     = "#9d79d6",  pink      = "#d67ad2",
  flamingo  = "#c9826b",  rosewater = "#cdcecf",
})

-- ── Carbonfox ─────────────────────────────────────────────────────────────────
PALETTES["carbonfox"] = extend({
  base      = "#161616",  mantle    = "#101010",  crust     = "#0a0a0a",
  surface0  = "#1c1c1c",  surface1  = "#282828",  surface2  = "#3d3d3d",
  overlay0  = "#6e6e6e",  overlay1  = "#888888",  overlay2  = "#a2a2a2",
  text      = "#f2f4f8",  subtext0  = "#dde1e6",  subtext1  = "#e5e8ed",
  lavender  = "#be95ff",  blue      = "#78a9ff",  sapphire  = "#82cfff",
  sky       = "#82cfff",  teal      = "#3ddbd9",  green     = "#42be65",
  yellow    = "#ffe97b",  peach     = "#ff832b",  maroon    = "#ee5396",
  red       = "#ff7eb6",  mauve     = "#be95ff",  pink      = "#ee5396",
  flamingo  = "#ff832b",  rosewater = "#f2f4f8",
})

-- ── Dayfox ────────────────────────────────────────────────────────────────────
PALETTES["dayfox"] = extend({
  base      = "#e4d4c8",  mantle    = "#dbcbbf",  crust     = "#d3c0b4",
  surface0  = "#ede0d4",  surface1  = "#dfd3c7",  surface2  = "#b5a7a0",
  overlay0  = "#a1948e",  overlay1  = "#8e8180",  overlay2  = "#7b6f6e",
  text      = "#3d2b5e",  subtext0  = "#55485a",  subtext1  = "#4b3f56",
  lavender  = "#8c6ec6",  blue      = "#2b6cc4",  sapphire  = "#287980",
  sky       = "#287980",  teal      = "#287980",  green     = "#567a30",
  yellow    = "#8e6a05",  peach     = "#b15c00",  maroon    = "#894f5a",
  red       = "#a12f64",  mauve     = "#8c6ec6",  pink      = "#a12f64",
  flamingo  = "#b15c00",  rosewater = "#3d2b5e",
})

-- ── Dawnfox ───────────────────────────────────────────────────────────────────
PALETTES["dawnfox"] = extend({
  base      = "#faf4ed",  mantle    = "#f0ead9",  crust     = "#e8e1ce",
  surface0  = "#f7f0e7",  surface1  = "#edddd0",  surface2  = "#c8bcb0",
  overlay0  = "#a09088",  overlay1  = "#8c7c74",  overlay2  = "#786c66",
  text      = "#575279",  subtext0  = "#726b8f",  subtext1  = "#6a6384",
  lavender  = "#907aa9",  blue      = "#286983",  sapphire  = "#286983",
  sky       = "#286983",  teal      = "#56949f",  green     = "#56949f",
  yellow    = "#ea9d34",  peach     = "#d7827e",  maroon    = "#b4637a",
  red       = "#b4637a",  mauve     = "#907aa9",  pink      = "#b4637a",
  flamingo  = "#d7827e",  rosewater = "#575279",
})

-- ── Material Ocean ────────────────────────────────────────────────────────────
PALETTES["material"] = extend({
  base      = "#0f111a",  mantle    = "#090b10",  crust     = "#050608",
  surface0  = "#1a1c25",  surface1  = "#292d3e",  surface2  = "#434758",
  overlay0  = "#676e95",  overlay1  = "#7d8cba",  overlay2  = "#939dca",
  text      = "#eeffff",  subtext0  = "#b0bec5",  subtext1  = "#cdd3de",
  lavender  = "#c792ea",  blue      = "#82aaff",  sapphire  = "#89ddff",
  sky       = "#89ddff",  teal      = "#89ddff",  green     = "#c3e88d",
  yellow    = "#ffcb6b",  peach     = "#f78c6c",  maroon    = "#f07178",
  red       = "#ff5370",  mauve     = "#c792ea",  pink      = "#f07178",
  flamingo  = "#f78c6c",  rosewater = "#eeffff",
})

-- ── Ayu Dark ────────────────────────────────────────────────────────────────
PALETTES["ayu-dark"] = extend({
  base      = "#0a0e14",  mantle    = "#07090d",  crust     = "#040507",
  surface0  = "#0d1017",  surface1  = "#11151c",  surface2  = "#1c2128",
  overlay0  = "#3e4b59",  overlay1  = "#4d5b6a",  overlay2  = "#5c6b7a",
  text      = "#b3b1ad",  subtext0  = "#9d9b97",  subtext1  = "#a8a6a3",
  lavender  = "#5ccfe6",  blue      = "#39bae6",  sapphire  = "#5ccfe6",
  sky       = "#5ccfe6",  teal      = "#95e6cb",  green     = "#c2d94c",
  yellow    = "#ffb454",  peach     = "#ff8f40",  maroon    = "#ff3333",
  red       = "#f07178",  mauve     = "#d2a6ff",  pink      = "#f07178",
  flamingo  = "#ff8f40",  rosewater = "#b3b1ad",
})

-- ── Ayu Light ─────────────────────────────────────────────────────────────────
PALETTES["ayu-light"] = extend({
  base      = "#fafafa",  mantle    = "#f0f0f0",  crust     = "#e6e6e6",
  surface0  = "#f3f3f3",  surface1  = "#e8e8e8",  surface2  = "#d4d4d4",
  overlay0  = "#abb0b6",  overlay1  = "#959da6",  overlay2  = "#818b95",
  text      = "#575f66",  subtext0  = "#6d7880",  subtext1  = "#636d76",
  lavender  = "#35a4c8",  blue      = "#36a3d9",  sapphire  = "#35a4c8",
  sky       = "#35a4c8",  teal      = "#4cbf99",  green     = "#86b300",
  yellow    = "#f29718",  peach     = "#fa8d3e",  maroon    = "#ff3333",
  red       = "#f07171",  mauve     = "#a37acc",  pink      = "#f07171",
  flamingo  = "#fa8d3e",  rosewater = "#575f66",
})

-- ── ASH Dynamic ───────────────────────────────────────────────────────────────
PALETTES["ash-dynamic"] = nil  -- loaded dynamically at runtime

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🌐 PUBLIC API
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---Get the palette for a given theme name
---@param name string
---@return table|nil
function M.get(name)
  if not name then return nil end

  -- ash-dynamic: load from the dynamic module
  if name == "ash-dynamic" then
    local ok, dyn = pcall(require, "themes.ash-dynamic")
    if ok then return dyn.get_palette() end
    return nil
  end

  -- Exact match
  if PALETTES[name] then
    return vim.deepcopy(PALETTES[name])
  end

  -- Prefix match (e.g. "tokyonight" → "tokyonight-night")
  for k, v in pairs(PALETTES) do
    if k:find("^" .. vim.pesc(name)) then
      return vim.deepcopy(v)
    end
  end

  -- Extract from active Neovim colorscheme
  return M.extract_from_colorscheme()
end

---Extract a palette from the currently active Neovim colorscheme
---@return table
function M.extract_from_colorscheme()
  local function get(group, attr)
    local ok, info = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    if ok and info and info[attr] then
      return string.format("#%06x", info[attr])
    end
    return nil
  end

  local base    = get("Normal", "bg")    or "#1e1e2e"
  local text    = get("Normal", "fg")    or "#cdd6f4"
  local blue    = get("Function", "fg")  or "#89b4fa"
  local green   = get("String", "fg")    or "#a6e3a1"
  local red     = get("Error", "fg")     or "#f38ba8"
  local yellow  = get("Type", "fg")      or "#f9e2af"
  local mauve   = get("Keyword", "fg")   or "#cba6f7"
  local teal    = get("Special", "fg")   or "#94e2d5"
  local peach   = get("Constant", "fg")  or "#fab387"
  local comment = get("Comment", "fg")   or "#6c7086"
  local cursor  = get("CursorLine", "bg") or "#313244"
  local border  = get("FloatBorder", "fg") or "#45475a"

  return extend({
    base      = base,   mantle    = mix(base, "#000000", 0.3),
    crust     = mix(base, "#000000", 0.5),
    surface0  = cursor, surface1  = mix(base, cursor, 0.5),
    surface2  = mix(cursor, comment, 0.5),
    overlay0  = comment, overlay1 = mix(comment, text, 0.3),
    overlay2  = mix(comment, text, 0.6),
    text      = text,   subtext0  = mix(text, comment, 0.3),
    subtext1  = mix(text, comment, 0.1),
    lavender  = mix(blue, mauve, 0.5),
    blue      = blue,   sapphire  = mix(blue, teal, 0.5),
    sky       = mix(blue, teal, 0.3),
    teal      = teal,   green     = green,
    yellow    = yellow, peach     = peach,
    maroon    = mix(red, peach, 0.5),
    red       = red,    mauve     = mauve,
    pink      = mix(red, mauve, 0.5),
    flamingo  = mix(peach, red, 0.5),
    rosewater = mix(text, peach, 0.3),
    border    = border,
  })
end

---List all theme names that have known palettes
---@return string[]
function M.list()
  local names = {}
  for k in pairs(PALETTES) do
    if k ~= "ash-dynamic" then
      table.insert(names, k)
    end
  end
  table.insert(names, "ash-dynamic")
  table.sort(names)
  return names
end

---Register a custom palette for a theme name
---@param name    string
---@param palette table
function M.register(name, palette)
  PALETTES[name] = extend(vim.deepcopy(palette))
end

---Check if a palette exists for the given name
---@param name string
---@return boolean
function M.has(name)
  return PALETTES[name] ~= nil or name == "ash-dynamic"
end

return M