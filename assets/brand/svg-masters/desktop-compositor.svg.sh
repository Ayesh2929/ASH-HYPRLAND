#!/usr/bin/env bash
# Renders a pixel-perfect desktop SVG for any theme

render_desktop_svg() {
  local theme=$1
  local k
  k="${theme}.bg";        local bg="${THEME_COLORS[$k]-}";        bg="${bg:-#1e1e2e}"
  k="${theme}.bg_dim";    local bg_dim="${THEME_COLORS[$k]-}";    bg_dim="${bg_dim:-#181825}"
  k="${theme}.bg1";       local bg1="${THEME_COLORS[$k]-}";       bg1="${bg1:-#313244}"
  k="${theme}.bg2";       local bg2="${THEME_COLORS[$k]-}";       bg2="${bg2:-#45475a}"
  k="${theme}.fg";        local fg="${THEME_COLORS[$k]-}";        fg="${fg:-#cdd6f4}"
  k="${theme}.fg_dim";    local fg_dim="${THEME_COLORS[$k]-}";    fg_dim="${fg_dim:-#a6adc8}"
  k="${theme}.red";       local red="${THEME_COLORS[$k]-}";       red="${red:-#f38ba8}"
  k="${theme}.orange";    local orange="${THEME_COLORS[$k]-}";    orange="${orange:-#fab387}"
  k="${theme}.yellow";    local yellow="${THEME_COLORS[$k]-}";    yellow="${yellow:-#f9e2af}"
  k="${theme}.green";     local green="${THEME_COLORS[$k]-}";     green="${green:-#a6e3a1}"
  k="${theme}.aqua";      local aqua="${THEME_COLORS[$k]-}";      aqua="${aqua:-#94e2d5}"
  k="${theme}.blue";      local blue="${THEME_COLORS[$k]-}";      blue="${blue:-#89b4fa}"
  k="${theme}.purple";    local purple="${THEME_COLORS[$k]-}";    purple="${purple:-#cba6f7}"
  k="${theme}.accent";    local accent="${THEME_COLORS[$k]-}";    accent="${accent:-#89b4fa}"
  k="${theme}.shadow";    local shadow="${THEME_COLORS[$k]-}";    shadow="${shadow:-rgba(0,0,0,0.45)}"
  k="${theme}.glass";     local glass="${THEME_COLORS[$k]-}";     glass="${glass:-rgba(30,30,46,0.72)}"
  k="${theme}.border";    local border="${THEME_COLORS[$k]-}";    border="${border:-rgba(137,180,250,0.30)}"
  k="${theme}.glow";      local glow="${THEME_COLORS[$k]-}";      glow="${glow:-rgba(137,180,250,0.15)}"

  cat <<SVG
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg"
     xmlns:xlink="http://www.w3.org/1999/xlink"
     viewBox="0 0 2560 1440"
     width="2560" height="1440">

  <defs>
    <!-- ── Gradients ─────────────────────────────────────────────────── -->
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%"   stop-color="${bg_dim}"/>
      <stop offset="40%"  stop-color="${bg}"/>
      <stop offset="100%" stop-color="${bg1}"/>
    </linearGradient>

    <linearGradient id="waybarGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%"   stop-color="${bg_dim}" stop-opacity="0.98"/>
      <stop offset="100%" stop-color="${bg}"     stop-opacity="0.95"/>
    </linearGradient>

    <linearGradient id="accentGrad" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%"   stop-color="${accent}"/>
      <stop offset="100%" stop-color="${blue}"/>
    </linearGradient>

    <linearGradient id="windowTitleGrad" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%"   stop-color="${bg1}"  stop-opacity="0.95"/>
      <stop offset="100%" stop-color="${bg2}"  stop-opacity="0.90"/>
    </linearGradient>

    <linearGradient id="sidebarGrad" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%"   stop-color="${bg_dim}" stop-opacity="0.97"/>
      <stop offset="100%" stop-color="${bg}"     stop-opacity="0.93"/>
    </linearGradient>

    <linearGradient id="terminalGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%"   stop-color="${bg}"     stop-opacity="0.96"/>
      <stop offset="100%" stop-color="${bg_dim}" stop-opacity="0.98"/>
    </linearGradient>

    <radialGradient id="accentGlow" cx="50%" cy="50%" r="50%">
      <stop offset="0%"   stop-color="${accent}" stop-opacity="0.25"/>
      <stop offset="100%" stop-color="${accent}" stop-opacity="0"/>
    </radialGradient>

    <radialGradient id="focusGlow" cx="50%" cy="50%" r="50%">
      <stop offset="0%"   stop-color="${accent}" stop-opacity="0.18"/>
      <stop offset="100%" stop-color="${accent}" stop-opacity="0"/>
    </radialGradient>

    <radialGradient id="wallpaperVignette" cx="50%" cy="50%" r="70%">
      <stop offset="0%"   stop-color="${bg_dim}" stop-opacity="0"/>
      <stop offset="100%" stop-color="${bg_dim}" stop-opacity="0.65"/>
    </radialGradient>

    <!-- ── Filters ───────────────────────────────────────────────────── -->
    <filter id="glassBlur" x="-5%" y="-5%" width="110%" height="110%">
      <feGaussianBlur stdDeviation="18" result="blur"/>
      <feComposite in="SourceGraphic" in2="blur" operator="over"/>
    </filter>

    <filter id="windowShadow" x="-8%" y="-8%" width="120%" height="130%">
      <feDropShadow dx="0" dy="12" stdDeviation="28"
                    flood-color="${shadow}" flood-opacity="1"/>
    </filter>

    <filter id="waybarShadow" x="-2%" y="-2%" width="104%" height="140%">
      <feDropShadow dx="0" dy="4" stdDeviation="16"
                    flood-color="${shadow}" flood-opacity="0.8"/>
    </filter>

    <filter id="iconGlow" x="-30%" y="-30%" width="160%" height="160%">
      <feGaussianBlur stdDeviation="6" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>

    <filter id="textGlow" x="-20%" y="-50%" width="140%" height="200%">
      <feGaussianBlur stdDeviation="4" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>

    <filter id="softShadow">
      <feDropShadow dx="0" dy="2" stdDeviation="6"
                    flood-color="${shadow}" flood-opacity="0.6"/>
    </filter>

    <filter id="innerGlow" x="-10%" y="-10%" width="120%" height="120%">
      <feGaussianBlur stdDeviation="3" result="blur"/>
      <feComposite in="SourceGraphic" in2="blur" operator="over"/>
    </filter>

    <!-- ── Clip Paths ────────────────────────────────────────────────── -->
    <clipPath id="windowClip">
      <rect x="240" y="60" width="1560" height="1040" rx="12"/>
    </clipPath>

    <clipPath id="terminalClip">
      <rect x="1460" y="400" width="820" height="560" rx="12"/>
    </clipPath>

    <clipPath id="sidebarClip">
      <rect x="240" y="60" width="260" height="1040" rx="12 0 0 12"/>
    </clipPath>

    <clipPath id="waybarClip">
      <rect x="0" y="0" width="2560" height="52"/>
    </clipPath>

    <clipPath id="notifClip">
      <rect x="2200" y="70" width="340" height="220" rx="14"/>
    </clipPath>

    <!-- ── Patterns ──────────────────────────────────────────────────── -->
    <pattern id="dotGrid" x="0" y="0" width="32" height="32" patternUnits="userSpaceOnUse">
      <circle cx="16" cy="16" r="1.2" fill="${fg_dim}" opacity="0.08"/>
    </pattern>

    <pattern id="codeLines" x="0" y="0" width="600" height="20" patternUnits="userSpaceOnUse">
      <rect x="0" y="8" width="380" height="3" rx="1.5" fill="${fg_dim}" opacity="0.12"/>
    </pattern>

    <!-- ── Markers ───────────────────────────────────────────────────── -->
    <marker id="arrowHead" markerWidth="8" markerHeight="6"
            refX="8" refY="3" orient="auto">
      <polygon points="0 0, 8 3, 0 6" fill="${accent}" opacity="0.7"/>
    </marker>
  </defs>

  <!-- ════════════════════════════════════════════════════════════════════
       LAYER 00 — WALLPAPER / BACKGROUND
       ════════════════════════════════════════════════════════════════════ -->
  <rect width="2560" height="1440" fill="url(#bgGrad)"/>
  <rect width="2560" height="1440" fill="url(#dotGrid)" opacity="0.6"/>

  <!-- Atmospheric depth elements -->
  <ellipse cx="640"  cy="720"  rx="520" ry="340" fill="${accent}"   opacity="0.025"/>
  <ellipse cx="1920" cy="360"  rx="480" ry="320" fill="${purple}"   opacity="0.030"/>
  <ellipse cx="1280" cy="1100" rx="600" ry="280" fill="${blue}"     opacity="0.020"/>
  <ellipse cx="320"  cy="280"  rx="280" ry="200" fill="${green}"    opacity="0.022"/>
  <ellipse cx="2300" cy="1100" rx="320" ry="240" fill="${aqua}"     opacity="0.020"/>

  <!-- Wallpaper vignette -->
  <rect width="2560" height="1440" fill="url(#wallpaperVignette)"/>

  <!-- Subtle noise texture -->
  <rect width="2560" height="1440" fill="${bg_dim}" opacity="0.08"/>

  <!-- ════════════════════════════════════════════════════════════════════
       LAYER 01 — WAYBAR (Top Status Bar)
       ════════════════════════════════════════════════════════════════════ -->
  <g filter="url(#waybarShadow)">
    <rect x="0" y="0" width="2560" height="52"
          fill="url(#waybarGrad)"
          clip-path="url(#waybarClip)"/>
    <!-- Glass border bottom -->
    <rect x="0" y="51" width="2560" height="1.5"
          fill="url(#accentGrad)" opacity="0.45"/>
  </g>

  <!-- ·· Workspace Buttons ·· -->
  <g id="workspaces" transform="translate(16, 8)">
    <!-- WS 1 — Active -->
    <rect x="0" y="0" width="36" height="36" rx="8"
          fill="${accent}" opacity="0.92"/>
    <text x="18" y="24" font-family="JetBrainsMono Nerd Font, monospace"
          font-size="14" font-weight="700"
          text-anchor="middle" fill="${bg_dim}">1</text>

    <!-- WS 2 — Occupied -->
    <rect x="44" y="0" width="36" height="36" rx="8"
          fill="${bg2}" opacity="0.80"/>
    <rect x="44" y="0" width="36" height="36" rx="8"
          fill="none" stroke="${accent}" stroke-width="1.5" opacity="0.45"/>
    <text x="62" y="24" font-family="JetBrainsMono Nerd Font, monospace"
          font-size="14" font-weight="600"
          text-anchor="middle" fill="${fg_dim}">2</text>

    <!-- WS 3 — Occupied -->
    <rect x="88" y="0" width="36" height="36" rx="8"
          fill="${bg2}" opacity="0.80"/>
    <rect x="88" y="0" width="36" height="36" rx="8"
          fill="none" stroke="${blue}" stroke-width="1.5" opacity="0.30"/>
    <text x="106" y="24" font-family="JetBrainsMono Nerd Font, monospace"
          font-size="14" font-weight="600"
          text-anchor="middle" fill="${fg_dim}">3</text>

    <!-- WS 4-9 — Empty -->
    $(for i in 4 5 6 7 8 9; do
      local x=$(( (i-1) * 44 ))
      echo "<rect x='${x}' y='0' width='36' height='36' rx='8' fill='${bg1}' opacity='0.50'/>"
      echo "<text x='$(( x + 18 ))' y='24' font-family='JetBrainsMono Nerd Font, monospace' font-size='14' text-anchor='middle' fill='${fg_dim}' opacity='0.35'>${i}</text>"
    done)
  </g>

  <!-- ·· Active Window Title ·· -->
  <g transform="translate(480, 10)">
    <text font-family="JetBrainsMono Nerd Font, monospace" font-size="13"
          fill="${fg_dim}" opacity="0.55">
      <tspan>  </tspan>
      <tspan fill="${fg}" opacity="0.85" font-weight="500"> nvim</tspan>
      <tspan fill="${fg_dim}" opacity="0.45"> — </tspan>
      <tspan fill="${fg_dim}" opacity="0.60">ash-dotfiles</tspan>
    </text>
  </g>

  <!-- ·· Center Clock ·· -->
  <g transform="translate(1280, 26)" text-anchor="middle">
    <text font-family="JetBrainsMono Nerd Font, monospace"
          font-size="15" font-weight="700"
          fill="${fg}" filter="url(#textGlow)">
      <tspan fill="${accent}"> </tspan>
      <tspan> 14:32</tspan>
      <tspan fill="${fg_dim}" opacity="0.60" font-size="12"> :45</tspan>
    </text>
  </g>

  <!-- ·· Date (near clock) ·· -->
  <g transform="translate(1380, 26)">
    <text font-family="JetBrainsMono Nerd Font, monospace"
          font-size="12" fill="${fg_dim}" opacity="0.55">
      <tspan> </tspan><tspan>Friday, Jan 17</tspan>
    </text>
  </g>

  <!-- ·· Right Modules ·· -->
  <!-- System Tray area -->
  <g transform="translate(2100, 10)">
    <!-- VPN indicator -->
    <rect x="0" y="4" width="48" height="28" rx="6"
          fill="${bg1}" opacity="0.70"/>
    <text x="24" y="22" font-family="JetBrainsMono Nerd Font, monospace"
          font-size="12" text-anchor="middle" fill="${green}" opacity="0.85">󰖂 </text>

    <!-- Network -->
    <rect x="56" y="4" width="48" height="28" rx="6"
          fill="${bg1}" opacity="0.70"/>
    <text x="80" y="22" font-family="JetBrainsMono Nerd Font, monospace"
          font-size="12" text-anchor="middle" fill="${blue}" opacity="0.85">󰖩 </text>

    <!-- Bluetooth -->
    <rect x="112" y="4" width="48" height="28" rx="6"
          fill="${bg1}" opacity="0.70"/>
    <text x="136" y="22" font-family="JetBrainsMono Nerd Font, monospace"
          font-size="12" text-anchor="middle" fill="${blue}" opacity="0.85">󰂱 </text>

    <!-- Volume -->
    <rect x="168" y="4" width="80" height="28" rx="6"
          fill="${bg1}" opacity="0.70"/>
    <text x="180" y="22" font-family="JetBrainsMono Nerd Font, monospace"
          font-size="11" fill="${aqua}" opacity="0.85">󰕾 74%</text>

    <!-- Battery -->
    <rect x="256" y="4" width="80" height="28" rx="6"
          fill="${bg1}" opacity="0.70"/>
    <text x="268" y="22" font-family="JetBrainsMono Nerd Font, monospace"
          font-size="11" fill="${green}" opacity="0.85">󰁹 87%</text>
  </g>

  <!-- System theme indicator pill -->
  <g transform="translate(2410, 8)">
    <rect x="0" y="0" width="130" height="36" rx="18"
          fill="${accent}" opacity="0.18"/>
    <rect x="0" y="0" width="130" height="36" rx="18"
          fill="none" stroke="${accent}" stroke-width="1.5" opacity="0.50"/>
    <text x="65" y="23" font-family="JetBrainsMono Nerd Font, monospace"
          font-size="11" font-weight="600" text-anchor="middle"
          fill="${accent}"> Everforest</text>
  </g>

  <!-- ════════════════════════════════════════════════════════════════════
       LAYER 02 — MAIN WINDOW (Neovim IDE)
       ════════════════════════════════════════════════════════════════════ -->
  <g filter="url(#windowShadow)">

    <!-- Window background -->
    <rect x="240" y="60" width="1560" height="1040" rx="12"
          fill="${bg}" opacity="0.97"/>

    <!-- Glass overlay -->
    <rect x="240" y="60" width="1560" height="1040" rx="12"
          fill="${glass}" opacity="0.08"/>

    <!-- Window border -->
    <rect x="240" y="60" width="1560" height="1040" rx="12"
          fill="none" stroke="${border}" stroke-width="1.5"/>

    <!-- Accent glow on focused window border -->
    <rect x="239" y="59" width="1562" height="1042" rx="13"
          fill="none" stroke="${accent}" stroke-width="2.5" opacity="0.20"/>

    <!-- ·· Titlebar ·· -->
    <rect x="240" y="60" width="1560" height="42" rx="12"
          fill="url(#windowTitleGrad)" clip-path="url(#windowClip)"/>
    <rect x="240" y="92" width="1560" height="10"
          fill="url(#windowTitleGrad)" opacity="0.5"/>
    <rect x="240" y="101" width="1560" height="1"
          fill="${accent}" opacity="0.20"/>

    <!-- Traffic lights -->
    <circle cx="268" cy="81" r="8" fill="#FF5F57" opacity="0.90"/>
    <circle cx="292" cy="81" r="8" fill="#FEBC2E" opacity="0.90"/>
    <circle cx="316" cy="81" r="8" fill="#28C840" opacity="0.90"/>

    <!-- Window title -->
    <text x="840" y="87" font-family="JetBrainsMono Nerd Font, monospace"
          font-size="13" font-weight="600" fill="${fg_dim}" opacity="0.70"
          text-anchor="middle">
      󰣩  NVIM — lua/core/options.lua [+]
    </text>

    <!-- ·· File Explorer Sidebar ·· -->
    <rect x="240" y="102" width="220" height="998"
          fill="${bg_dim}" opacity="0.95" clip-path="url(#sidebarClip)"/>
    <rect x="459" y="102" width="1" height="998"
          fill="${accent}" opacity="0.15"/>

    <!-- Sidebar title -->
    <rect x="240" y="102" width="220" height="36"
          fill="${bg1}" opacity="0.60"/>
    <text x="340" y="125" font-family="JetBrainsMono Nerd Font, monospace"
          font-size="11" font-weight="700" fill="${fg_dim}" opacity="0.70"
          text-anchor="middle">EXPLORER</text>

    <!-- File tree items -->
    <g transform="translate(248, 155)" font-family="JetBrainsMono Nerd Font, monospace" font-size="12">
      <!-- Root folder -->
      <text y="0" fill="${blue}">󰉋 ash-dotfiles</text>

      <!-- lua/ folder — expanded -->
      <text y="26" fill="${yellow}" opacity="0.85">  󰉁 lua</text>

      <!-- core/ — active -->
      <rect x="12" y="34" width="196" height="22" rx="4"
            fill="${accent}" opacity="0.18"/>
      <rect x="12" y="34" width="3" height="22" rx="1.5"
            fill="${accent}" opacity="0.85"/>
      <text x="20" y="49" fill="${fg}" opacity="0.95">    󰉋 core</text>

      <!-- files under core -->
      <text x="20" y="75" fill="${fg_dim}" opacity="0.65">      󰈙 init.lua</text>

      <!-- Active file highlight -->
      <rect x="20" y="82" width="188" height="22" rx="4"
            fill="${accent}" opacity="0.22"/>
      <rect x="20" y="82" width="3" height="22" rx="1.5"
            fill="${accent}" opacity="0.95"/>
      <text x="28" y="97" fill="${accent}" font-weight="600">      󰈙 options.lua</text>

      <text x="20" y="123" fill="${fg_dim}" opacity="0.65">      󰈙 keymaps.lua</text>
      <text x="20" y="149" fill="${fg_dim}" opacity="0.65">      󰈙 autocmds.lua</text>
      <text x="20" y="175" fill="${fg_dim}" opacity="0.65">      󰈙 lazy.lua</text>
      <text x="20" y="201" fill="${fg_dim}" opacity="0.65">      󰈙 utils.lua</text>

      <!-- plugins/ folder -->
      <text x="8"  y="234" fill="${yellow}" opacity="0.75">    󰉁 plugins</text>
      <text x="20" y="260" fill="${fg_dim}" opacity="0.55">      󰉁 ui</text>
      <text x="20" y="286" fill="${fg_dim}" opacity="0.55">      󰉁 editor</text>
      <text x="20" y="312" fill="${fg_dim}" opacity="0.55">      󰉁 lsp</text>
      <text x="20" y="338" fill="${fg_dim}" opacity="0.55">      󰉁 completion</text>
      <text x="20" y="364" fill="${fg_dim}" opacity="0.55">      󰉁 dap</text>

      <!-- themes/ folder -->
      <text x="8"  y="398" fill="${yellow}" opacity="0.75">    󰉁 themes</text>
      <text x="8"  y="424" fill="${yellow}" opacity="0.75">    󰉁 config</text>
    </g>

    <!-- ·· Buffer Line (tabs) ·· -->
    <rect x="460" y="102" width="1340" height="36"
          fill="${bg_dim}" opacity="0.98"/>
    <rect x="460" y="137" width="1340" height="1"
          fill="${bg2}" opacity="0.60"/>

    <!-- Active buffer tab -->
    <g transform="translate(460, 102)">
      <rect x="0" y="0" width="176" height="36"
            fill="${bg}" opacity="0.98"/>
      <rect x="0" y="33" width="176" height="3"
            fill="${accent}" opacity="0.90"/>
      <text x="12" y="24" font-family="JetBrainsMono Nerd Font, monospace"
            font-size="12" fill="${fg}" opacity="0.90">
        <tspan fill="${green}">󰈙 </tspan>
        <tspan>options.lua</tspan>
        <tspan fill="${red}" font-size="10"> ●</tspan>
      </text>

      <!-- Inactive tabs -->
      <text x="196" y="24" font-family="JetBrainsMono Nerd Font, monospace"
            font-size="12" fill="${fg_dim}" opacity="0.55">
        <tspan fill="${yellow}">󰈙 </tspan>keymaps.lua
      </text>
      <text x="376" y="24" font-family="JetBrainsMono Nerd Font, monospace"
            font-size="12" fill="${fg_dim}" opacity="0.55">
        <tspan fill="${blue}">󰈙 </tspan>init.lua
      </text>
      <text x="524" y="24" font-family="JetBrainsMono Nerd Font, monospace"
            font-size="12" fill="${fg_dim}" opacity="0.55">
        <tspan fill="${purple}">󰈙 </tspan>lazy.lua
      </text>
    </g>

    <!-- ·· Code Editor Area ·· -->
    <g id="codeArea" clip-path="url(#windowClip)">

      <!-- Line number gutter -->
      <rect x="460" y="138" width="56" height="998"
            fill="${bg_dim}" opacity="0.70"/>
      <rect x="515" y="138" width="1" height="998"
            fill="${bg2}" opacity="0.35"/>

      <!-- Code content area -->
      <rect x="516" y="138" width="1284" height="998"
            fill="${bg}" opacity="0.97"/>

      <!-- ·· Syntax-highlighted code rendering ·· -->
      <g font-family="JetBrainsMono Nerd Font, monospace"
         font-size="14" transform="translate(0, 0)">

        <!-- Helper: line numbers -->
        <g fill="${fg_dim}" opacity="0.35" font-size="13" text-anchor="end">
          $(for i in $(seq 1 40); do
            local y=$(( 138 + i * 21 + 10 ))
            echo "<text x='508' y='${y}'>${i}</text>"
          done)
        </g>

        <!-- ·· Code Lines (options.lua) ·· -->
        <!-- Line 1: comment header -->
        <text x="528" y="159" fill="${fg_dim}" opacity="0.45" font-style="italic">
          -- ── Core Options ─────────────────────────────────────────────
        </text>

        <!-- Line 2: blank -->

        <!-- Line 3: vim.g -->
        <text x="528" y="201">
          <tspan fill="${purple}">vim</tspan>
          <tspan fill="${fg}" opacity="0.80">.</tspan>
          <tspan fill="${blue}">g</tspan>
          <tspan fill="${fg}" opacity="0.80">.</tspan>
          <tspan fill="${fg}">mapleader</tspan>
          <tspan fill="${fg_dim}" opacity="0.70"> = </tspan>
          <tspan fill="${green}">" "</tspan>
        </text>

        <text x="528" y="222">
          <tspan fill="${purple}">vim</tspan>
          <tspan fill="${fg}" opacity="0.80">.</tspan>
          <tspan fill="${blue}">g</tspan>
          <tspan fill="${fg}" opacity="0.80">.</tspan>
          <tspan fill="${fg}">maplocalleader</tspan>
          <tspan fill="${fg_dim}" opacity="0.70"> = </tspan>
          <tspan fill="${green}">"\\"</tspan>
        </text>

        <!-- Line separator comment -->
        <text x="528" y="243" fill="${fg_dim}" opacity="0.40" font-style="italic">
          -- ── UI Settings ──────────────────────────────────────────────
        </text>

        <!-- opt block -->
        <text x="528" y="264">
          <tspan fill="${orange}">local </tspan>
          <tspan fill="${fg}">opt </tspan>
          <tspan fill="${fg_dim}">= </tspan>
          <tspan fill="${purple}">vim</tspan>
          <tspan fill="${fg_dim}">.</tspan>
          <tspan fill="${blue}">opt</tspan>
        </text>

        <!-- Current line highlight -->
        <rect x="516" y="270" width="1284" height="22"
              fill="${accent}" opacity="0.10"/>
        <rect x="516" y="270" width="2" height="22"
              fill="${accent}" opacity="0.70"/>
        <text x="528" y="286">
          <tspan fill="${fg}">opt</tspan>
          <tspan fill="${fg_dim}">.</tspan>
          <tspan fill="${blue}">number</tspan>
          <tspan fill="${fg_dim}"> = </tspan>
          <tspan fill="${orange}">true</tspan>
          <tspan fill="${fg_dim}" opacity="0.40" font-style="italic">          -- absolute line numbers</tspan>
        </text>

        <!-- Cursor block -->
        <rect x="528" y="271" width="9" height="19"
              fill="${accent}" opacity="0.85"/>
        <text x="528" y="286" fill="${bg_dim}" font-weight="700">o</text>

        <text x="528" y="307">
          <tspan fill="${fg}">opt</tspan>
          <tspan fill="${fg_dim}">.</tspan>
          <tspan fill="${blue}">relativenumber</tspan>
          <tspan fill="${fg_dim}"> = </tspan>
          <tspan fill="${orange}">true</tspan>
        </text>

        <text x="528" y="328">
          <tspan fill="${fg}">opt</tspan>
          <tspan fill="${fg_dim}">.</tspan>
          <tspan fill="${blue}">cursorline</tspan>
          <tspan fill="${fg_dim}"> = </tspan>
          <tspan fill="${orange}">true</tspan>
        </text>

        <text x="528" y="349">
          <tspan fill="${fg}">opt</tspan>
          <tspan fill="${fg_dim}">.</tspan>
          <tspan fill="${blue}">signcolumn</tspan>
          <tspan fill="${fg_dim}"> = </tspan>
          <tspan fill="${green}">"yes"</tspan>
        </text>

        <text x="528" y="370">
          <tspan fill="${fg}">opt</tspan>
          <tspan fill="${fg_dim}">.</tspan>
          <tspan fill="${blue}">termguicolors</tspan>
          <tspan fill="${fg_dim}"> = </tspan>
          <tspan fill="${orange}">true</tspan>
        </text>

        <text x="528" y="391">
          <tspan fill="${fg}">opt</tspan>
          <tspan fill="${fg_dim}">.</tspan>
          <tspan fill="${blue}">laststatus</tspan>
          <tspan fill="${fg_dim}"> = </tspan>
          <tspan fill="${orange}">3</tspan>
          <tspan fill="${fg_dim}" opacity="0.40" font-style="italic">              -- global statusline</tspan>
        </text>

        <text x="528" y="412">
          <tspan fill="${fg}">opt</tspan>
          <tspan fill="${fg_dim}">.</tspan>
          <tspan fill="${blue}">fillchars</tspan>
          <tspan fill="${fg_dim}"> = { </tspan>
          <tspan fill="${fg}">eob</tspan>
          <tspan fill="${fg_dim}"> = </tspan>
          <tspan fill="${green}">" "</tspan>
          <tspan fill="${fg_dim}">, </tspan>
          <tspan fill="${fg}">fold</tspan>
          <tspan fill="${fg_dim}"> = </tspan>
          <tspan fill="${green}">"·"</tspan>
          <tspan fill="${fg_dim}"> }</tspan>
        </text>

        <!-- Section comment -->
        <text x="528" y="433" fill="${fg_dim}" opacity="0.40" font-style="italic">
          -- ── Editor Behavior ─────────────────────────────────────────
        </text>

        <text x="528" y="454">
          <tspan fill="${fg}">opt</tspan>
          <tspan fill="${fg_dim}">.</tspan>
          <tspan fill="${blue}">expandtab</tspan>
          <tspan fill="${fg_dim}"> = </tspan>
          <tspan fill="${orange}">true</tspan>
        </text>

        <text x="528" y="475">
          <tspan fill="${fg}">opt</tspan>
          <tspan fill="${fg_dim}">.</tspan>
          <tspan fill="${blue}">tabstop</tspan>
          <tspan fill="${fg_dim}"> = </tspan>
          <tspan fill="${orange}">2</tspan>
        </text>

        <text x="528" y="496">
          <tspan fill="${fg}">opt</tspan>
          <tspan fill="${fg_dim}">.</tspan>
          <tspan fill="${blue}">shiftwidth</tspan>
          <tspan fill="${fg_dim}"> = </tspan>
          <tspan fill="${orange}">2</tspan>
        </text>

        <text x="528" y="517">
          <tspan fill="${fg}">opt</tspan>
          <tspan fill="${fg_dim}">.</tspan>
          <tspan fill="${blue}">smartindent</tspan>
          <tspan fill="${fg_dim}"> = </tspan>
          <tspan fill="${orange}">true</tspan>
        </text>

        <text x="528" y="538">
          <tspan fill="${fg}">opt</tspan>
          <tspan fill="${fg_dim}">.</tspan>
          <tspan fill="${blue}">wrap</tspan>
          <tspan fill="${fg_dim}"> = </tspan>
          <tspan fill="${orange}">false</tspan>
        </text>

        <!-- Indent guides (visual) -->
        $(for col in 528 556 584 612; do
          echo "<rect x='${col}' y='160' width='1' height='800' fill='${fg_dim}' opacity='0.06'/>"
        done)

        <!-- LSP diagnostic indicators in gutter -->
        <text x="462" y="286" font-family="JetBrainsMono Nerd Font, monospace"
              font-size="13" fill="${yellow}"> </text>
        <text x="462" y="412" font-family="JetBrainsMono Nerd Font, monospace"
              font-size="13" fill="${blue}"> </text>

        <!-- ·· LSP Hover Popup ·· -->
        <g transform="translate(700, 300)" filter="url(#windowShadow)">
          <rect x="0" y="0" width="480" height="120" rx="10"
                fill="${bg_dim}" opacity="0.97"/>
          <rect x="0" y="0" width="480" height="120" rx="10"
                fill="none" stroke="${border}" stroke-width="1.5"/>
          <rect x="0" y="0" width="480" height="32" rx="10"
                fill="${bg1}" opacity="0.80"
                clip-path="url(#terminalClip)"/>

          <!-- Hover content -->
          <text x="14" y="20" font-family="JetBrainsMono Nerd Font, monospace"
                font-size="11" fill="${blue}" opacity="0.80">󰋖 </text>
          <text x="28" y="20" font-family="JetBrainsMono Nerd Font, monospace"
                font-size="11" fill="${fg_dim}" opacity="0.70">boolean option</text>

          <text x="14" y="50" font-family="JetBrainsMono Nerd Font, monospace"
                font-size="12" fill="${purple}">number</text>
          <text x="14" y="70" font-family="JetBrainsMono Nerd Font, monospace"
                font-size="12" fill="${fg_dim}" opacity="0.65">
            Print the line number in front of each line.
          </text>
          <text x="14" y="90" font-family="JetBrainsMono Nerd Font, monospace"
                font-size="12" fill="${fg_dim}" opacity="0.45">
            When combined with relativenumber, shows current line.
          </text>

          <!-- Documentation tag -->
          <rect x="380" y="8" width="88" height="18" rx="4"
                fill="${accent}" opacity="0.20"/>
          <text x="424" y="21" font-family="JetBrainsMono Nerd Font, monospace"
                font-size="10" text-anchor="middle" fill="${accent}" opacity="0.80">󰘦 vim.opt</text>
        </g>
      </g>

      <!-- ·· Completion Menu (CMP) ·· -->
      <g transform="translate(528, 490)" filter="url(#softShadow)">
        <rect x="0" y="0" width="420" height="200" rx="10"
              fill="${bg_dim}" opacity="0.98"/>
        <rect x="0" y="0" width="420" height="200" rx="10"
              fill="none" stroke="${border}" stroke-width="1.5"/>

        <!-- Scrollbar -->
        <rect x="408" y="4" width="6" height="192" rx="3"
              fill="${bg2}" opacity="0.50"/>
        <rect x="408" y="4" width="6" height="60" rx="3"
              fill="${accent}" opacity="0.60"/>

        <!-- Selected item -->
        <rect x="0" y="0" width="408" height="36" rx="10 0 0 0"
              fill="${accent}" opacity="0.22"/>
        <rect x="0" y="0" width="4" height="36" rx="2"
              fill="${accent}" opacity="0.90"/>

        <!-- Completion items -->
        <g font-family="JetBrainsMono Nerd Font, monospace" font-size="12">
          <!-- Item 1 — selected -->
          <text x="14" y="23" fill="${fg}" font-weight="600">
            <tspan fill="${blue}" font-size="10">󰀫 </tspan>number
          </text>
          <text x="310" y="23" fill="${fg_dim}" opacity="0.45" font-size="11">boolean</text>
          <text x="370" y="23" fill="${green}" opacity="0.60" font-size="10">opt</text>

          <!-- Items 2-7 -->
          $(for label in "relativenumber" "numberwidth  " "nrformats    " "noremap      " "noswapfile   " "nobackup     "; do
            local idx=$((RANDOM % 6 + 2))
            local y=$(( idx * 36 - 13 ))
            local kind_color="${fg_dim}"
            echo "<text x='14' y='${y}' fill='${fg_dim}' opacity='0.65'><tspan fill='${purple}' font-size='10'>󰊕 </tspan>${label}</text>"
          done)
        </g>
      </g>

      <!-- ·· Statusline ·· -->
      <rect x="460" y="1094" width="1340" height="44"
            fill="${bg_dim}" opacity="0.98"/>
      <rect x="460" y="1094" width="1340" height="1"
            fill="${accent}" opacity="0.20"/>

      <!-- Mode indicator -->
      <rect x="460" y="1095" width="80" height="43"
            fill="${accent}" opacity="0.90"/>
      <text x="500" y="1121" font-family="JetBrainsMono Nerd Font, monospace"
            font-size="13" font-weight="800" text-anchor="middle"
            fill="${bg_dim}">NORMAL</text>

      <!-- Git branch -->
      <text x="560" y="1122" font-family="JetBrainsMono Nerd Font, monospace"
            font-size="12" fill="${purple}" opacity="0.85">  main</text>

      <!-- Git stats -->
      <text x="660" y="1122" font-family="JetBrainsMono Nerd Font, monospace"
            font-size="12">
        <tspan fill="${green}">+12</tspan>
        <tspan fill="${yellow}"> ~3</tspan>
        <tspan fill="${red}"> -1</tspan>
      </text>

      <!-- LSP status -->
      <text x="800" y="1122" font-family="JetBrainsMono Nerd Font, monospace"
            font-size="12">
        <tspan fill="${red}"> 0</tspan>
        <tspan fill="${yellow}">  2</tspan>
        <tspan fill="${blue}">  5</tspan>
        <tspan fill="${green}">  12</tspan>
      </text>

      <!-- File info (right aligned) -->
      <text x="1750" y="1122" font-family="JetBrainsMono Nerd Font, monospace"
            font-size="12" fill="${fg_dim}" opacity="0.60">Lua  UTF-8  LF</text>

      <!-- Cursor position -->
      <rect x="1740" y="1095" width="60" height="43"
            fill="${accent}" opacity="0.18"/>
      <text x="1770" y="1122" font-family="JetBrainsMono Nerd Font, monospace"
            font-size="12" fill="${accent}" text-anchor="middle">14:9</text>

      <!-- Percentage -->
      <text x="1800" y="1122" font-family="JetBrainsMono Nerd Font, monospace"
            font-size="12" fill="${fg_dim}" opacity="0.50"> 35%</text>
    </g>
  </g>

  <!-- ════════════════════════════════════════════════════════════════════
       LAYER 03 — FLOATING TERMINAL (Kitty)
       ════════════════════════════════════════════════════════════════════ -->
  <g filter="url(#windowShadow)" transform="translate(0, 0)">
    <rect x="1460" y="400" width="820" height="560" rx="12"
          fill="url(#terminalGrad)" opacity="0.97"/>
    <rect x="1460" y="400" width="820" height="560" rx="12"
          fill="none" stroke="${border}" stroke-width="1.5"/>
    <!-- Accent border glow -->
    <rect x="1459" y="399" width="822" height="562" rx="13"
          fill="none" stroke="${blue}" stroke-width="2" opacity="0.18"/>

    <!-- Terminal titlebar -->
    <rect x="1460" y="400" width="820" height="38" rx="12"
          fill="${bg_dim}" opacity="0.98"/>
    <rect x="1460" y="428" width="820" height="10"
          fill="${bg_dim}" opacity="0.60"/>
    <rect x="1460" y="437" width="820" height="1"
          fill="${blue}" opacity="0.25"/>

    <!-- Traffic lights -->
    <circle cx="1482" cy="419" r="7" fill="#FF5F57" opacity="0.85"/>
    <circle cx="1502" cy="419" r="7" fill="#FEBC2E" opacity="0.85"/>
    <circle cx="1522" cy="419" r="7" fill="#28C840" opacity="0.85"/>

    <!-- Tab bar -->
    <g transform="translate(1540, 405)">
      <rect x="0" y="0" width="120" height="28" rx="6"
            fill="${bg1}" opacity="0.80"/>
      <rect x="0" y="25" width="120" height="3"
            fill="${blue}" opacity="0.70"/>
      <text x="60" y="19" font-family="JetBrainsMono Nerd Font, monospace"
            font-size="12" text-anchor="middle" fill="${fg}" opacity="0.85">
         dev
      </text>

      <text x="140" y="19" font-family="JetBrainsMono Nerd Font, monospace"
            font-size="12" fill="${fg_dim}" opacity="0.45"> git</text>
      <text x="196" y="19" font-family="JetBrainsMono Nerd Font, monospace"
            font-size="12" fill="${fg_dim}" opacity="0.45"> run</text>
    </g>

    <!-- Terminal content -->
    <g transform="translate(1474, 456)"
       font-family="JetBrainsMono Nerd Font, monospace" font-size="13">

      <!-- Shell prompt line 1 -->
      <text y="0">
        <tspan fill="${green}" font-weight="700"> </tspan>
        <tspan fill="${green}" font-weight="700">ash </tspan>
        <tspan fill="${blue}">~/projects/ash-dotfiles </tspan>
        <tspan fill="${purple}"> main </tspan>
        <tspan fill="${yellow}">+12 </tspan>
        <tspan fill="${aqua}">󱑎 1.2s </tspan>
        <tspan fill="${fg_dim}" opacity="0.50"> </tspan>
      </text>

      <!-- Command output -->
      <text y="24" fill="${fg_dim}" opacity="0.60">
        ❯ ash theme apply dark-everforest
      </text>

      <!-- Progress output -->
      <text y="50">
        <tspan fill="${blue}">  </tspan>
        <tspan fill="${fg_dim}" opacity="0.70"> Extracting colors from wallpaper...</tspan>
      </text>

      <text y="74">
        <tspan fill="${green}">  </tspan>
        <tspan fill="${fg_dim}" opacity="0.70"> Generated 16-color palette</tspan>
      </text>

      <text y="98">
        <tspan fill="${blue}">  </tspan>
        <tspan fill="${fg_dim}" opacity="0.70"> Applying theme to 18 applications...</tspan>
      </text>

      <!-- Progress bar -->
      <rect x="16" y="108" width="760" height="8" rx="4"
            fill="${bg2}" opacity="0.60"/>
      <rect x="16" y="108" width="608" height="8" rx="4"
            fill="url(#accentGrad)" opacity="0.85"/>
      <text x="785" y="118" font-size="11" fill="${fg_dim}" opacity="0.60"
            text-anchor="end">80%</text>

      <text y="138">
        <tspan fill="${green}">  </tspan>
        <tspan fill="${fg_dim}" opacity="0.70"> Reloading: hyprland, waybar, kitty</tspan>
      </text>

      <text y="162">
        <tspan fill="${yellow}">  </tspan>
        <tspan fill="${fg_dim}" opacity="0.70"> Reloading: rofi, dunst, swaync</tspan>
      </text>

      <text y="186">
        <tspan fill="${green}">  </tspan>
        <tspan fill="${fg_dim}" opacity="0.70"> Applied GTK-3.0 and GTK-4.0 themes</tspan>
      </text>

      <text y="210">
        <tspan fill="${green}">  </tspan>
        <tspan fill="${fg_dim}" opacity="0.70"> Updated spicetify and cursor themes</tspan>
      </text>

      <!-- Success line -->
      <rect x="0" y="222" width="776" height="26" rx="6"
            fill="${green}" opacity="0.10"/>
      <text y="239">
        <tspan fill="${green}" font-weight="700">  </tspan>
        <tspan fill="${green}" font-weight="600"> Theme applied in 1.24s — Everforest Dark active</tspan>
      </text>

      <!-- New prompt line -->
      <text y="272">
        <tspan fill="${green}" font-weight="700"> </tspan>
        <tspan fill="${green}" font-weight="700">ash </tspan>
        <tspan fill="${blue}">~/projects/ash-dotfiles </tspan>
        <tspan fill="${purple}"> main </tspan>
        <tspan fill="${fg_dim}" opacity="0.50"> </tspan>
      </text>

      <!-- Cursor blink -->
      <rect x="157" y="258" width="9" height="18" rx="1"
            fill="${green}" opacity="0.85"/>

      <!-- Scrollbar -->
      <rect x="766" y="0" width="5" height="480" rx="2.5"
            fill="${bg2}" opacity="0.40"/>
      <rect x="766" y="120" width="5" height="160" rx="2.5"
            fill="${fg_dim}" opacity="0.35"/>
    </g>
  </g>

  <!-- ════════════════════════════════════════════════════════════════════
       LAYER 04 — NOTIFICATION POPUP
       ════════════════════════════════════════════════════════════════════ -->
  <g filter="url(#windowShadow)" clip-path="url(#notifClip)">
    <rect x="2200" y="70" width="340" height="100" rx="14"
          fill="${bg_dim}" opacity="0.96"/>
    <rect x="2200" y="70" width="340" height="100" rx="14"
          fill="none" stroke="${border}" stroke-width="1.5"/>
    <rect x="2200" y="70" width="5" height="100" rx="3 0 0 3"
          fill="${green}" opacity="0.85"/>

    <!-- Notification icon -->
    <circle cx="2228" cy="120" r="18" fill="${bg1}" opacity="0.80"/>
    <text x="2228" y="126" font-family="JetBrainsMono Nerd Font, monospace"
          font-size="16" text-anchor="middle" fill="${green}"></text>

    <!-- Notification text -->
    <text x="2256" y="108" font-family="JetBrainsMono Nerd Font, monospace"
          font-size="13" font-weight="700" fill="${fg}" opacity="0.90">
      ASH Dotfiles
    </text>
    <text x="2256" y="126" font-family="JetBrainsMono Nerd Font, monospace"
          font-size="11" fill="${fg_dim}" opacity="0.65">
      Theme applied successfully
    </text>
    <text x="2256" y="142" font-family="JetBrainsMono Nerd Font, monospace"
          font-size="11" fill="${green}" opacity="0.70">
      Everforest Dark • 1.24s
    </text>

    <!-- Timestamp -->
    <text x="2524" y="82" font-family="JetBrainsMono Nerd Font, monospace"
          font-size="10" fill="${fg_dim}" opacity="0.40" text-anchor="end">
      just now
    </text>
  </g>

  <!-- ════════════════════════════════════════════════════════════════════
       LAYER 05 — DOCK / APP LAUNCHER (bottom left)
       ════════════════════════════════════════════════════════════════════ -->
  <g filter="url(#windowShadow)" transform="translate(20, 1100)">
    <rect x="0" y="0" width="200" height="310" rx="16"
          fill="${glass}" opacity="0.92"/>
    <rect x="0" y="0" width="200" height="310" rx="16"
          fill="none" stroke="${border}" stroke-width="1.5"/>

    <!-- Dock items -->
    <g transform="translate(10, 10)"
       font-family="JetBrainsMono Nerd Font, monospace">

      <!-- App icons with labels -->
      $(declare -a dock_apps=("" "" "󰈹" "" "󰚄" "" "󰋊" "" "󱁆")
        declare -a dock_labels=("Neovim" "Kitty" "Firefox" "Files" "Spotify" "Discord" "btop" "Lazygit" "Docker")
        declare -a dock_colors=("${green}" "${blue}" "${orange}" "${yellow}" "${green}" "${purple}" "${red}" "${orange}" "${blue}")

        for i in "${!dock_apps[@]}"; do
          local y=$(( i * 32 + 12 ))
          local is_active=0
          if [[ $i -eq 0 || $i -eq 1 ]]; then
            is_active=1
          fi

          if [[ $is_active -eq 1 ]]; then
            echo "<rect x='0' y='$(( y - 10 ))' width='180' height='26' rx='6' fill='${accent}' opacity='0.18'/>"
            echo "<rect x='0' y='$(( y - 10 ))' width='3' height='26' rx='1.5' fill='${accent}' opacity='0.85'/>"
          fi

          echo "<text x='10' y='${y}' font-size='16' fill='${dock_colors[$i]}'>${dock_apps[$i]}</text>"
          echo "<text x='38' y='${y}' font-size='12' fill='${fg_dim}' opacity='0.70'>${dock_labels[$i]}</text>"
        done)
    </g>
  </g>

  <!-- ════════════════════════════════════════════════════════════════════
       LAYER 06 — CORNER DECORATIONS & BRAND WATERMARK
       ════════════════════════════════════════════════════════════════════ -->

  <!-- Bottom right: ASH version pill -->
  <g transform="translate(2380, 1390)">
    <rect x="0" y="0" width="160" height="32" rx="16"
          fill="${bg_dim}" opacity="0.80"/>
    <rect x="0" y="0" width="160" height="32" rx="16"
          fill="none" stroke="${border}" stroke-width="1"/>
    <text x="80" y="21" font-family="JetBrainsMono Nerd Font, monospace"
          font-size="11" font-weight="600" text-anchor="middle"
          fill="${fg_dim}" opacity="0.50">
       ASH v5.0 OMEGA
    </text>
  </g>

  <!-- Wallpaper attribution (bottom left) -->
  <text x="24" y="1428" font-family="JetBrainsMono Nerd Font, monospace"
        font-size="10" fill="${fg_dim}" opacity="0.25">
    github.com/yourusername/ash-dotfiles
  </text>

</svg>
SVG
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  render_desktop_svg "$@"
fi