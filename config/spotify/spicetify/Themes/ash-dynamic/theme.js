// ash dotfiles — spicetify ash-dynamic theme.js (dynamic loader)
// Reads ~/.local/share/ash-dotfiles/state/current-theme.json (or ash_theme_colors env),
// injects ASH palette as CSS variables, and hot-reloads on changes (ash:theme-change).
//
// Usage: spicetify config current_theme ash-dynamic
//        spicetify config color_scheme dark
//        spicetify apply

(() => {
  if (!Spicetify) return;

  const { LocalStorage, Platform, URI } = Spicetify;

  /* ── ASH palette (Catppuccin Mocha base, fallback) ── */
  const ASH_PALETTES = {
    dark: {
      rosewater: "#f5e0dc", flamingo: "#f2cdcd", pink: "#f5c2e7",
      mauve: "#cba6f7", red: "#f38ba8", maroon: "#eba0ac",
      peach: "#fab387", yellow: "#f9e2af", green: "#a6e3a1",
      teal: "#94e2d5", sky: "#89dceb", sapphire: "#74c7ec",
      blue: "#89b4fa", lavender: "#b4befe",
      text: "#cdd6f4", subtext1: "#bac2de", subtext0: "#a6adc8",
      overlay2: "#9399b2", overlay1: "#7f849c", overlay0: "#6c7086",
      surface2: "#585b70", surface1: "#45475a", surface0: "#313244",
      base: "#1e1e2e", mantle: "#181825", crust: "#11111b",
    },
    light: {
      rosewater: "#dc8a78", flamingo: "#dd7878", pink: "#ea76cb",
      mauve: "#8839ef", red: "#d20f39", maroon: "#e64553",
      peach: "#fe640b", yellow: "#df8e1d", green: "#40a02b",
      teal: "#179299", sky: "#04a5e5", sapphire: "#209fb5",
      blue: "#1e66f5", lavender: "#7287fd",
      text: "#4c4f69", subtext1: "#5c5f77", subtext0: "#6c6f85",
      overlay2: "#7c7f93", overlay1: "#8c8fa1", overlay0: "#9ca0b0",
      surface2: "#acb0be", surface1: "#bcc0cc", surface0: "#ccd0da",
      base: "#eff1f5", mantle: "#e6e9ef", crust: "#dce0e8",
    },
    neon: {
      mauve: "#ff6ec7", sky: "#00f0ff", blue: "#3b9cff",
      green: "#a3ff6e", yellow: "#fff06e", peach: "#ff9e5e",
      red: "#ff3b7a", teal: "#00f0ff",
      text: "#e0e0ff", subtext1: "#b8b8ff", subtext0: "#8a8ab8",
      base: "#0d0221", mantle: "#150a33", surface0: "#1d0f4d",
      crust: "#000000",
    },
    nature: {
      mauve: "#a6e3a1", sky: "#94e2d5", blue: "#89b4fa",
      green: "#7ed684", yellow: "#f9e2af", peach: "#fab387",
      red: "#f38ba8", teal: "#94e2d5",
      text: "#dcebe0", subtext1: "#b9d0bf", subtext0: "#8aa08f",
      base: "#0f1a11", mantle: "#16241a", surface0: "#1e2f22",
      crust: "#060b07",
    },
    sakura: {
      mauve: "#f5c2e7", sky: "#94e2d5", blue: "#89b4fa",
      green: "#a6e3a1", yellow: "#f9e2af", peach: "#fab387",
      red: "#f38ba8", teal: "#94e2d5",
      text: "#f3e5ee", subtext1: "#d9bcd4", subtext0: "#a98aa4",
      base: "#1d1120", mantle: "#29182d", surface0: "#38203d",
      crust: "#0f0811",
    },
  };

  const DEFAULTS = ASH_PALETTES.dark;
  const STATE_PATH = "/.local/share/ash-dotfiles/state/current-theme.json";
  const ENV_VAR = "ASH_THEME_COLORS";

  /* ── helpers ── */
  const hex = (c) =>
    typeof c === "string" && c.startsWith("#")
      ? c
      : (DEFAULTS[c] || DEFAULTS.mauve);

  const toRgb = (hexStr) => {
    const h = hexStr.replace("#", "");
    const n = parseInt(h.length === 3 ? h.split("").map((x) => x + x).join("") : h, 16);
    return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
  };

  const rgba = (color, a) => {
    const [r, g, b] = toRgb(hex(color));
    return `rgba(${r}, ${g}, ${b}, ${a})`;
  };

  const mix = (a, b, t) => {
    const [r1, g1, b1] = toRgb(hex(a));
    const [r2, g2, b2] = toRgb(hex(b));
    const r = Math.round(r1 + (r2 - r1) * t);
    const g = Math.round(g1 + (g2 - g1) * t);
    const bl = Math.round(b1 + (b2 - b1) * t);
    return `rgb(${r}, ${g}, ${bl})`;
  };

  /* ── read state ── */
  function readAshTheme() {
    let variant = "dark";
    let colors = {};
    try {
      const raw = LocalStorage.get("ash_theme_colors");
      if (raw) colors = JSON.parse(raw);
    } catch (_) {}
    try {
      const envColors = new URLSearchParams(location.search).get(ENV_VAR);
      if (envColors) colors = JSON.parse(decodeURIComponent(envColors));
    } catch (_) {}
    try {
      variant = LocalStorage.get("ash_variant") || variant;
    } catch (_) {}
    return { variant, colors: { ...ASH_PALETTES[variant], ...colors } };
  }

  /* ── build CSS vars ── */
  function buildCssVariables(theme) {
    const { colors } = theme;
    return {
      "--ash-accent1": hex(colors.mauve || colors.accent1),
      "--ash-accent2": hex(colors.sky || colors.teal || colors.accent2),
      "--ash-text": hex(colors.text),
      "--ash-subtext": hex(colors.subtext0 || colors.subtext1),
      "--ash-base": hex(colors.base),
      "--ash-surface": hex(colors.surface0 || colors.mantle),
      "--ash-surface-hover": mix(colors.surface0 || colors.mantle, colors.text, 0.12),
      "--ash-glass-border": rgba(colors.text || "#cdd6f4", 0.12),
      "--ash-bg-accent": rgba(colors.mauve || "#cba6f7", 0.14),
      "--ash-mauve": hex(colors.mauve),
      "--ash-sky": hex(colors.sky),
      "--ash-blue": hex(colors.blue),
      "--ash-green": hex(colors.green),
      "--ash-yellow": hex(colors.yellow),
      "--ash-red": hex(colors.red),
      "--accent-color": hex(colors.mauve),
      "--bg-accent-color": rgba(colors.mauve || "#cba6f7", 0.35),
      "--bg-tinted-highlight": rgba(colors.mauve || "#cba6f7", 0.18),
      "--bg-tinted-base": rgba(colors.mauve || "#cba6f7", 0.1),
    };
  }

  /* ── inject ── */
  function injectCssVariables(theme) {
    const vars = buildCssVariables(theme);
    const css = Object.entries(vars)
      .map(([k, v]) => `${k}: ${v};`)
      .join("\n");
    Spicetify.CSS.register(`:root { ${css} }`);
  }

  /* ── album art accent (dominant color → glow) ── */
  function extractAlbumAccent() {
    const art = document.querySelector(".cover-art-image, .main-coverSlotCollapsed-container img, .now-playing img");
    if (!art || !art.complete) return;
    const cv = document.createElement("canvas");
    cv.width = cv.height = 16;
    const ctx = cv.getContext("2d");
    try {
      ctx.drawImage(art, 0, 0, 16, 16);
      const d = ctx.getImageData(0, 0, 16, 16).data;
      let r = 0, g = 0, b = 0, n = 0;
      for (let i = 0; i < d.length; i += 4) {
        if (d[i + 3] < 200) continue;
        r += d[i]; g += d[i + 1]; b += d[i + 2]; n++;
      }
      if (!n) return;
      const accent = `rgb(${Math.round(r / n)}, ${Math.round(g / n)}, ${Math.round(b / n)})`;
      Spicetify.CSS.register(`:root { --nowplaying-accent: ${accent}; }`);
    } catch (_) {}
  }

  /* ── hot reload ── */
  function watchTheme() {
    window.setInterval(() => {
      try {
        const raw = LocalStorage.get("ash_theme_colors");
        if (raw && raw !== LAST) {
          LAST = raw;
          injectCssVariables(readAshTheme());
        }
      } catch (_) {}
    }, 2500);
  }
  let LAST = null;

  /* ── load ── */
  const theme = readAshTheme();
  injectCssVariables(theme);
  watchTheme();
  window.setTimeout(extractAlbumAccent, 4000);
  window.setInterval(extractAlbumAccent, 15000);

  document.addEventListener("DOMContentLoaded", () => {
    extractAlbumAccent();
  });

  // React to song change → re-sample accent
  try {
    Spicetify.Player.addEventListener("songchange", extractAlbumAccent);
    Spicetify.Player.addEventListener("appchange", () => window.setTimeout(extractAlbumAccent, 1200));
  } catch (_) {}
})();
