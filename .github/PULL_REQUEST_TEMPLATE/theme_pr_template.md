Markdown

<!--
╔══════════════════════════════════════════════════════════════════════════════════════════╗
║      🎨 ASH DOTFILES v5.0 OMEGA — THEME PULL REQUEST TEMPLATE                         ║
║      Ultra-Premium Theme Contribution System • Color Science • WCAG • Preview Gen      ║
║      Automated Validation • Schema Compliance • Multi-App Coverage • Store Ready       ║
╚══════════════════════════════════════════════════════════════════════════════════════════╝
-->

<div align="center">
████████╗██╗ ██╗███████╗███╗ ███╗███████╗ ██████╗ ██████╗
╚══██╔══╝██║ ██║██╔════╝████╗ ████║██╔════╝ ██╔══██╗██╔══██╗
██║ ███████║█████╗ ██╔████╔██║█████╗ ██████╔╝██████╔╝
██║ ██╔══██║██╔══╝ ██║╚██╔╝██║██╔══╝ ██╔═══╝ ██╔══██╗
██║ ██║ ██║███████╗██║ ╚═╝ ██║███████╗ ██║ ██║ ██║
╚═╝ ╚═╝ ╚═╝╚══════╝╚═╝ ╚═╝╚══════╝ ╚═╝ ╚═╝ ╚═╝

text


# 🎨 Theme Pull Request — ASH Dotfiles v5.0 OMEGA

> *"Color is the keyboard, the eyes are the harmonies, the soul is the piano with many strings"*
> — Wassily Kandinsky

</div>

---

> [!IMPORTANT]
> **Run automated validation BEFORE opening this PR:**
> ```bash
> # Full validation suite — ALL must pass:
> ash theme validate --strict --accessibility --schema ./themes/your-theme/
>
> # Generate preview screenshots automatically:
> ash theme preview --generate --output ./themes/your-theme/screenshots/
>
> # Check color harmony:
> ash theme validate --color-harmony ./themes/your-theme/colors.json
>
> # Test all target applications:
> ash theme test --all-targets ./themes/your-theme/
> ```
> **PRs that fail automated validation will be closed without review.**

---

## 🎨 Theme Identity

<!--
Complete every field — this becomes the theme store listing metadata.
-->

| Property | Value |
|----------|-------|
| **Theme Name** | <!-- e.g., Aurora Borealis --> |
| **Theme ID** | <!-- e.g., aurora-borealis (kebab-case, unique) --> |
| **Version** | <!-- e.g., 1.0.0 --> |
| **Category** | <!-- dark / light / neon / nature / space / pastel / anime / retro / gradient / seasonal / mood / gaming / minimal / special --> |
| **Style Tags** | <!-- e.g., cool, atmospheric, blue-toned, zen --> |
| **Author** | <!-- Your Name (@github-handle) --> |
| **License** | <!-- MIT / CC0 / CC-BY-4.0 / Apache-2.0 --> |
| **Repository** | <!-- https://github.com/you/ash-theme-aurora-borealis --> |

---

## 🌟 Theme Showcase

<!--
The MOST IMPORTANT section — beautiful screenshots get themes accepted faster.
High-quality visuals are mandatory for acceptance.
-->

### 🖥️ Full Desktop Preview

<!-- REQUIRED: Drag your highest-quality 1920×1080+ desktop screenshot here -->
<!-- Command: ash shot full --quality max -->

> **📐 Minimum:** 1920×1080 | **🏆 Recommended:** 3840×2160 (4K)

<!-- [DRAG FULL DESKTOP SCREENSHOT HERE] -->

---

### 📸 Component Gallery

<table>
<tr>
<th align="center">📝 Neovim + Code</th>
<th align="center">🖥️ Terminal + Prompt</th>
</tr>
<tr>
<td align="center">

<!-- [DRAG NEOVIM SCREENSHOT] -->
<!-- Show: syntax highlighting, LSP hints, file tree -->

</td>
<td align="center">

<!-- [DRAG TERMINAL SCREENSHOT] -->
<!-- Show: fish prompt, ls output, git status -->

</td>
</tr>
<tr>
<th align="center">📊 Waybar</th>
<th align="center">🚀 Rofi Launcher</th>
</tr>
<tr>
<td align="center">

<!-- [DRAG WAYBAR SCREENSHOT] -->
<!-- Show: full bar with all modules -->

</td>
<td align="center">

<!-- [DRAG ROFI SCREENSHOT] -->
<!-- Show: app launcher with theme applied -->

</td>
</tr>
<tr>
<th align="center">🔔 Dunst Notification</th>
<th align="center">🔒 Hyprlock Screen</th>
</tr>
<tr>
<td align="center">

<!-- [DRAG DUNST SCREENSHOT] -->

</td>
<td align="center">

<!-- [DRAG HYPRLOCK SCREENSHOT] -->

</td>
</tr>
</table>

### 🎬 Transition Animation

<!-- STRONGLY RECOMMENDED: Show the theme being applied with smooth transition -->
<!-- Command: ash shot record --output theme-transition.gif --duration 5 -->

<!-- [DRAG TRANSITION GIF HERE] -->

---

## 🎨 Color Palette Specification

<!--
REQUIRED: Complete color palette. Run `ash theme validate --colors` to verify.
ALL hex values must be valid #RRGGBB format.
-->

### Visual Palette Swatch

<!-- Include a color swatch image showing your full palette -->
<!-- Generate with: ash theme palette-image --output palette.png ./themes/your-theme/ -->

<!-- [DRAG PALETTE SWATCH IMAGE HERE] -->

### Color Definitions

```json
{
  "$schema": "https://ash-dotfiles.github.io/schemas/colors-v2.json",
  "meta": {
    "theme_id": "aurora-borealis",
    "version": "1.0.0",
    "generated": "2024-01-15T14:32:00Z",
    "color_space": "sRGB"
  },
  "base": {
    "background":      "#0a0f1a",
    "background_alt":  "#121923",
    "background_dark": "#06090f",
    "surface":         "#1a2233",
    "overlay":         "#1e2840",
    "border":          "#2d3f5c"
  },
  "text": {
    "primary":    "#e8f0fe",
    "secondary":  "#8ba0c4",
    "disabled":   "#4a5a72",
    "inverse":    "#0a0f1a"
  },
  "accent": {
    "primary":   "#39d353",
    "secondary": "#58a6ff",
    "tertiary":  "#bc8cff",
    "warning":   "#e3b341",
    "error":     "#f85149",
    "success":   "#3fb950",
    "info":      "#388bfd"
  },
  "syntax": {
    "keyword":     "#ff7b72",
    "string":      "#a5d6ff",
    "function":    "#d2a8ff",
    "variable":    "#ffa657",
    "comment":     "#8b949e",
    "constant":    "#79c0ff",
    "type":        "#7ee787",
    "operator":    "#ff7b72",
    "punctuation": "#8b949e",
    "markup_tag":  "#7ee787"
  },
  "terminal": {
    "black":          "#484f58",
    "red":            "#ff7b72",
    "green":          "#3fb950",
    "yellow":         "#d29922",
    "blue":           "#58a6ff",
    "magenta":        "#bc8cff",
    "cyan":           "#56d364",
    "white":          "#b1bac4",
    "bright_black":   "#6e7681",
    "bright_red":     "#ffa198",
    "bright_green":   "#56d364",
    "bright_yellow":  "#e3b341",
    "bright_blue":    "#79c0ff",
    "bright_magenta": "#d2a8ff",
    "bright_cyan":    "#56d364",
    "bright_white":   "#f0f6fc"
  }
}
Contrast Ratios (WCAG 2.1 Compliance)
<!-- Run: ash theme validate --wcag ./themes/your-theme/ All REQUIRED pairs must achieve WCAG AA (4.5:1) minimum. -->
Color Pair	Ratio	WCAG Level	Status
text.primary on base.background	X.X:1	<!-- AAA/AA/FAIL -->	<!-- ✅/❌ -->
text.secondary on base.background	X.X:1	<!-- AAA/AA/FAIL -->	<!-- ✅/❌ -->
text.primary on base.surface	X.X:1	<!-- AAA/AA/FAIL -->	<!-- ✅/❌ -->
accent.primary on base.background	X.X:1	<!-- AAA/AA/FAIL -->	<!-- ✅/❌ -->
accent.secondary on base.background	X.X:1	<!-- AAA/AA/FAIL -->	<!-- ✅/❌ -->
accent.error on base.background	X.X:1	<!-- AAA/AA/FAIL -->	<!-- ✅/❌ -->
accent.warning on base.background	X.X:1	<!-- AAA/AA/FAIL -->	<!-- ✅/❌ -->
accent.success on base.background	X.X:1	<!-- AAA/AA/FAIL -->	<!-- ✅/❌ -->
Full WCAG report:

text

$ ash theme validate --wcag ./themes/aurora-borealis/
[Paste complete WCAG validation output here]
Color Blindness Simulation
<!-- Run: ash theme validate --colorblind ./themes/your-theme/ Ensures theme is usable by color-blind users. -->
Condition	Readable?	Notes
Deuteranopia (red-green, 8% of men)	<!-- ✅/⚠️/❌ -->	
Protanopia (red, 1% of men)	<!-- ✅/⚠️/❌ -->	
Tritanopia (blue-yellow, rare)	<!-- ✅/⚠️/❌ -->	
Achromatopsia (complete, very rare)	<!-- ✅/⚠️/❌ -->	
📁 File Structure
<!-- Confirm your theme directory structure is complete and correct. -->
text

themes/presets/[category]/[theme-id]/
├── ✅ theme.conf          — Main theme configuration
├── ✅ colors.json         — Complete color palette (schema v2)
├── ✅ metadata.json       — Store metadata (author, tags, etc.)
├── ✅ preview.webp        — Full desktop screenshot (≥1920×1080)
├── ✅ wallpaper.jpg       — Matching wallpaper (≥1920×1080)
├── ✅ LICENSE             — License file
├── ✅ README.md           — Theme documentation
└── screenshots/
    ├── ✅ neovim.webp     — Neovim with syntax highlighting
    ├── ✅ terminal.webp   — Terminal with prompt
    ├── ✅ waybar.webp     — Status bar
    ├── ✅ rofi.webp       — App launcher
    └── 🔄 transition.gif — Theme transition (recommended)
Files missing (justify if any):

<!-- List any missing files and why they're not included -->
🎯 Target Application Coverage
<!-- Check all applications you've tested this theme with. REQUIRED apps must be checked for PR acceptance. -->
Required (All Must Pass)
 🪟 Hyprland — Window border colors, workspace colors
 📊 Waybar — Bar background, module colors, active states
 🚀 Rofi — Launcher background, text, selection, border
 🔔 Dunst — Notification background, text, urgency colors
 🖥️ Kitty — Terminal foreground, background, 16 ANSI colors
 🐟 Fish Shell — Prompt colors, syntax highlighting
 📝 Neovim — Editor theme (via ash-dynamic.lua integration)
 🎭 GTK 3 — Application window chrome and widgets
 🎭 GTK 4 — Modern GTK4/libadwaita applications
Recommended (Include If Possible)
 🔒 Hyprlock — Lock screen layout and colors
 📊 AGS — Alternative bar widgets
 ⭐ Starship — Prompt preset colors
 💻 btop — System monitor color scheme
 🎵 cava — Audio visualizer colors
 🔓 wlogout — Logout menu styling
 🦇 bat — Syntax highlighting colors
 ⏱️ tmux — Multiplexer status bar
Optional (Bonus Points)
 📝 Helix — Alternative editor
 📝 Zed — Alternative editor
 📝 VSCode — VS Code color theme
 🌐 Firefox — Browser userChrome.css
 💬 Discord — BetterDiscord/Vencord theme
 🎵 Spotify — Spicetify theme
 🖥️ SDDM — Login screen
🎨 Design Philosophy & Inspiration
<!-- Tell the story of your theme. Great themes have a soul. This appears in the theme store description. -->
🌟 Concept & Inspiration
<!-- What inspired this theme? What emotion/aesthetic does it evoke? Where do the colors come from? Why these specific hues? -->
🎯 Design Goals
<!-- What were you trying to achieve? What makes this theme unique compared to existing themes? -->
Primary goal:
Secondary goal:
Unique differentiator:
🖼️ Best Paired With
<!-- What wallpapers, fonts, and workflows complement this theme? -->
Category	Recommendation
Wallpaper style	<!-- e.g., Dark nature photography, Aurora borealis -->
Font recommendation	<!-- e.g., JetBrains Mono, Iosevka -->
Cursor	<!-- e.g., Breeze Dark, Vimix -->
Icon theme	<!-- e.g., Papirus Dark -->
Best use case	<!-- e.g., Late-night coding, Productivity -->
Avoid for	<!-- e.g., Bright room use (too dark) -->
🌓 Variants Included / Planned
Variant	Status	Notes
Dark (this PR)	✅ Included	Primary variant
Light	<!-- ✅/🔜/❌ -->	
OLED (pure black bg)	<!-- ✅/🔜/❌ -->	
High Contrast	<!-- ✅/🔜/❌ -->	
🖼️ Wallpaper Details
<!-- REQUIRED: At minimum one matching wallpaper. -->
Property	Value
Filename	<!-- e.g., aurora-borealis.jpg -->
Resolution	<!-- e.g., 3840×2160 -->
Format	<!-- JPEG / PNG / WebP -->
File Size	<!-- e.g., 6.2 MB -->
Source	<!-- Self-created / Unsplash / AI-generated / etc. -->
License	<!-- CC0 / CC-BY / MIT / etc. -->
Author	<!-- Your name / Original photographer -->
Original URL	<!-- If from external source -->
Additional Variants
Filename	Resolution	Aspect	Purpose
[name]-fhd.jpg	1920×1080	16:9	FHD displays
[name]-uw.jpg	3440×1440	21:9	Ultrawide
[name]-light.jpg	1920×1080	16:9	Light variant
✅ Validation Results
<!-- REQUIRED: Paste complete output from all validation commands. PRs with failed validations will not be reviewed. --><details> <summary>🧪 Full Validation Output (click to expand — REQUIRED)</summary>
Schema Validation
Bash

$ ash theme validate --strict ./themes/aurora-borealis/
[PASTE COMPLETE OUTPUT HERE]
Accessibility (WCAG) Validation
Bash

$ ash theme validate --accessibility ./themes/aurora-borealis/
[PASTE COMPLETE OUTPUT HERE]
Color Harmony Check
Bash

$ ash theme validate --color-harmony ./themes/aurora-borealis/
[PASTE COMPLETE OUTPUT HERE]
Target Application Test
Bash

$ ash theme test --all-targets ./themes/aurora-borealis/
[PASTE COMPLETE OUTPUT HERE]
Expected Passing Output
text

🎨 ASH Theme Validator v5.0 — STRICT MODE
══════════════════════════════════════════════════
Theme: Aurora Borealis v1.0.0

✅ Schema validation:        PASS (colors-v2.json)
✅ Required colors:          PASS (52/52 defined)
✅ Color format:             PASS (all valid #RRGGBB)
✅ WCAG AA contrast:         PASS (8/8 required pairs)
✅ Color blindness:          PASS (4/4 simulations)
✅ Color harmony:            PASS (analogous + complementary)
✅ Metadata completeness:    PASS (all required fields)
✅ Preview image:            PASS (3840×2160, WebP)
✅ Wallpaper:                PASS (3840×2160, JPEG, CC0)
✅ License:                  PASS (MIT)
✅ Required templates:       PASS (9/9 required targets)
✅ Dark theme check:         PASS (bg luminance: 0.18 < 0.3)

Results: 12/12 checks PASSED ✅
Theme is ready for submission! 🎉
</details>
📊 metadata.json
<!-- Paste your complete metadata.json for review. This is what appears in the theme store. --><details> <summary>📋 Complete metadata.json (click to expand)</summary>
JSON

{
  "$schema": "https://ash-dotfiles.github.io/schemas/metadata-v1.json",
  "id": "aurora-borealis",
  "name": "Aurora Borealis",
  "version": "1.0.0",
  "description": "A deep atmospheric dark theme inspired by the northern lights",
  "category": "nature",
  "style": ["dark", "cool", "atmospheric", "blue-toned"],
  "tags": ["aurora", "northern-lights", "dark", "green", "blue", "nature", "night"],
  "author": {
    "name": "Your Name",
    "github": "yourgithubhandle",
    "email": "optional@example.com",
    "website": "https://optional.dev"
  },
  "license": "MIT",
  "homepage": "https://github.com/yourgithubhandle/ash-theme-aurora-borealis",
  "supports_dark": true,
  "supports_light": false,
  "supports_auto": false,
  "min_ash_version": "5.0.0",
  "colors": {
    "primary": "#39d353",
    "secondary": "#58a6ff",
    "background": "#0a0f1a",
    "foreground": "#e8f0fe"
  },
  "screenshots": {
    "preview":   "preview.webp",
    "neovim":    "screenshots/neovim.webp",
    "terminal":  "screenshots/terminal.webp",
    "waybar":    "screenshots/waybar.webp",
    "desktop":   "screenshots/desktop.webp"
  },
  "wallpaper": {
    "file":       "wallpaper.jpg",
    "resolution": "3840x2160",
    "license":    "CC0",
    "source":     "Self-created"
  }
}
</details>
🔗 Related Issues & Attribution
Item	Details
Closes issue	<!-- Closes #XXX (if from theme submission issue) -->
Inspiration	<!-- Links to color scheme, photography, art that inspired this -->
Based on	<!-- If port/derivative: original theme name + author + license -->
Companion theme PR	<!-- If submitting dark+light together -->
✅ Theme PR Submission Checklist
<!-- ALL items required. Unchecked mandatory items = PR will be closed. -->
Mandatory (Hard Requirements)
 🏷️ Theme ID is unique — verified against theme registry
 ✅ ash theme validate --strict — ALL 12 checks pass
 ♿ WCAG AA contrast — all required pairs pass (4.5:1 minimum)
 📸 preview.webp — included at ≥ 1920×1080
 🖼️ wallpaper.jpg/png — included at ≥ 1920×1080
 📝 metadata.json — complete with all required fields
 🎯 All 9 required target applications tested and working
 ⚖️ I own the rights to all included assets (colors, wallpaper, icons)
 📄 LICENSE file present in theme directory
 🚫 Theme does NOT infringe on copyrights or trademarks
Quality Bar
 📸 All 4 required component screenshots included (neovim, terminal, waybar, rofi)
 🎨 Color harmony passes validation (no jarring color combinations)
 🌈 Colors are internally consistent across all targets (same accent everywhere)
 🌓 Theme looks polished in both active and inactive window states
Legal & Attribution
 🌐 I have not violated any service's terms of service
 👤 I have properly attributed any third-party assets
 ⚖️ I agree to release under the stated license
 📖 I agree to the Code of Conduct
<div align="center">
🎨 Theme Review Process
text

Submit PR → Auto-Validation → Preview Generation → Curation Review → Merge → Store
   now        ~2 min           ~5 min               1-3 days         auto    instant
Review Criteria	Weight
🎨 Visual Quality & Polish	35%
♿ Accessibility (WCAG AA)	25%
🎯 Application Coverage	20%
⚖️ License & Rights Clarity	15%
🌟 Uniqueness & Originality	5%
Your theme will be featured in:
ash theme store • The README gallery • Discord #new-themes • Twitter

— The ASH Dotfiles Theme Curation Team 🎨

</div> 